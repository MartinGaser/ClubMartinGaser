"""
Procesamiento y envío de recordatorios de reservas mediante
Firebase Cloud Messaging.
"""

from datetime import datetime, timedelta, timezone

from firebase_admin import messaging
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.enums import ReservationStatus
from app.models.reservation import Reservation
from app.notifications.firebase import initialize_firebase
from app.repositories.device_token_repository import (
    DeviceTokenRepository,
)


class NotificationService:
    """Envía recordatorios pendientes de reservas."""

    @staticmethod
    def process_reservation_reminders(
        db: Session,
    ) -> dict[str, int]:
        """
        Busca reservas confirmadas dentro de las próximas 24 horas.

        Envía un recordatorio de 24 horas o de 1 hora y registra
        la fecha para evitar notificaciones duplicadas.
        """

        initialize_firebase()

        now = datetime.now(timezone.utc)
        one_hour_limit = now + timedelta(hours=1)
        twenty_four_hour_limit = now + timedelta(hours=24)

        summary = {
            "checked": 0,
            "sent_24h": 0,
            "sent_1h": 0,
            "without_tokens": 0,
            "failed": 0,
        }

        statement = (
            select(Reservation)
            .where(
                Reservation.status
                == ReservationStatus.CONFIRMED,
                Reservation.start_datetime > now,
                Reservation.start_datetime
                <= twenty_four_hour_limit,
            )
            .order_by(
                Reservation.start_datetime.asc(),
            )
        )

        reservations = list(
            db.scalars(statement).all()
        )

        for reservation in reservations:
            summary["checked"] += 1

            device_tokens = (
                DeviceTokenRepository.get_active_by_user_id(
                    db=db,
                    user_id=reservation.user_id,
                )
            )

            if not device_tokens:
                summary["without_tokens"] += 1
                continue

            # Reserva dentro de la próxima hora.
            if reservation.start_datetime <= one_hour_limit:
                if reservation.reminder_1h_sent_at is not None:
                    continue

                delivered = (
                    NotificationService._send_to_devices(
                        db=db,
                        device_tokens=device_tokens,
                        title="Tu reserva comienza pronto",
                        body=(
                            "Tu reserva deportiva comienza "
                            "dentro de aproximadamente una hora."
                        ),
                        reservation_id=reservation.id,
                    )
                )

                if delivered:
                    reservation.reminder_1h_sent_at = now
                    db.add(reservation)
                    db.commit()
                    summary["sent_1h"] += 1
                else:
                    db.rollback()
                    summary["failed"] += 1

                continue

            # Reserva entre 1 y 24 horas.
            if reservation.reminder_24h_sent_at is not None:
                continue

            delivered = NotificationService._send_to_devices(
                db=db,
                device_tokens=device_tokens,
                title="Recordatorio de reserva",
                body=(
                    "Tenés una reserva deportiva "
                    "dentro de las próximas 24 horas."
                ),
                reservation_id=reservation.id,
            )

            if delivered:
                reservation.reminder_24h_sent_at = now
                db.add(reservation)
                db.commit()
                summary["sent_24h"] += 1
            else:
                db.rollback()
                summary["failed"] += 1

        return summary

    @staticmethod
    def _send_to_devices(
        db: Session,
        device_tokens: list,
        title: str,
        body: str,
        reservation_id: int,
    ) -> bool:
        """
        Envía una notificación a cada dispositivo activo.

        Los tokens que Firebase ya no reconoce se desactivan.
        """

        delivered = False

        for device_token in device_tokens:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data={
                    "type": "reservation_reminder",
                    "reservation_id": str(reservation_id),
                },
                token=device_token.token,
            )

            try:
                messaging.send(message)
                delivered = True

            except messaging.UnregisteredError:
                DeviceTokenRepository.deactivate(
                    db=db,
                    device_token=device_token,
                )

            except Exception as error:
                print(
                    "No se pudo enviar al dispositivo "
                    f"{device_token.id}: "
                    f"{type(error).__name__}: {error}"
                )

        return delivered
