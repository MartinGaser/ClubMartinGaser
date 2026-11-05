"""
Repositorio de reservas.

Esta capa contiene las consultas directas a PostgreSQL.
Las reglas del negocio se encuentran en ReservationService.
"""

from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.enums import ReservationStatus
from app.models.reservation import Reservation


class ReservationRepository:
    """Operaciones de acceso a datos para reservas."""

    @staticmethod
    def get_by_id(
        db: Session,
        reservation_id: int,
    ) -> Reservation | None:
        """Busca una reserva mediante su identificador."""

        return db.get(Reservation, reservation_id)

    @staticmethod
    def get_user_future_reservations(
        db: Session,
        user_id: int,
        current_time: datetime,
    ) -> list[Reservation]:
        """Obtiene reservas futuras y confirmadas del usuario."""

        statement = (
            select(Reservation)
            .where(
                Reservation.user_id == user_id,
                Reservation.status == ReservationStatus.CONFIRMED,
                Reservation.start_datetime >= current_time,
            )
            .order_by(Reservation.start_datetime.asc())
        )

        return list(db.scalars(statement).all())

    @staticmethod
    def get_user_history(
        db: Session,
        user_id: int,
        current_time: datetime,
    ) -> list[Reservation]:
        """
        Obtiene el historial del usuario.

        Incluye reservas finalizadas y reservas canceladas.
        """

        statement = (
            select(Reservation)
            .where(
                Reservation.user_id == user_id,
                (
                    (Reservation.end_datetime < current_time)
                    | (
                        Reservation.status
                        == ReservationStatus.CANCELLED
                    )
                ),
            )
            .order_by(Reservation.start_datetime.desc())
        )

        return list(db.scalars(statement).all())

    @staticmethod
    def find_overlap(
        db: Session,
        sports_space_id: int,
        start_datetime: datetime,
        end_datetime: datetime,
    ) -> Reservation | None:
        """
        Busca una reserva confirmada que se superponga.

        Dos intervalos se superponen cuando:

        nuevo_inicio < reserva_existente_fin
        y
        nuevo_fin > reserva_existente_inicio
        """

        statement = select(Reservation).where(
            Reservation.sports_space_id == sports_space_id,
            Reservation.status == ReservationStatus.CONFIRMED,
            start_datetime < Reservation.end_datetime,
            end_datetime > Reservation.start_datetime,
        )

        return db.scalar(statement)

    @staticmethod
    def get_space_reservations_between(
        db: Session,
        sports_space_id: int,
        range_start: datetime,
        range_end: datetime,
    ) -> list[Reservation]:
        """Obtiene reservas confirmadas dentro de un intervalo."""

        statement = (
            select(Reservation)
            .where(
                Reservation.sports_space_id == sports_space_id,
                Reservation.status == ReservationStatus.CONFIRMED,
                Reservation.start_datetime < range_end,
                Reservation.end_datetime > range_start,
            )
            .order_by(Reservation.start_datetime.asc())
        )

        return list(db.scalars(statement).all())

    @staticmethod
    def create(
        db: Session,
        user_id: int,
        sports_space_id: int,
        start_datetime: datetime,
        end_datetime: datetime,
    ) -> Reservation:
        """Inserta una reserva nueva."""

        reservation = Reservation(
            user_id=user_id,
            sports_space_id=sports_space_id,
            start_datetime=start_datetime,
            end_datetime=end_datetime,
            status=ReservationStatus.CONFIRMED,
        )

        db.add(reservation)
        db.flush()
        db.refresh(reservation)

        return reservation

    @staticmethod
    def cancel(
        db: Session,
        reservation: Reservation,
        cancelled_at: datetime,
    ) -> Reservation:
        """Cambia el estado de la reserva a cancelada."""

        reservation.status = ReservationStatus.CANCELLED
        reservation.cancelled_at = cancelled_at

        db.add(reservation)
        db.flush()
        db.refresh(reservation)

        return reservation
