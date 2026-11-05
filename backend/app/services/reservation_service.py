"""
Servicio de reservas.

Aplica las reglas principales del trabajo práctico:
- Usuario existente y activo.
- Espacio y sede activos.
- Reserva futura.
- Horas exactas.
- Duración mínima de una hora.
- Reserva dentro del horario de la sede.
- Ausencia de superposiciones.
- Cancelación de reservas futuras.
"""

from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.enums import ReservationStatus
from app.models.reservation import Reservation
from app.models.sports_space import SportsSpace
from app.models.user import User
from app.models.venue import Venue
from app.repositories.reservation_repository import ReservationRepository
from app.repositories.space_repository import SportsSpaceRepository
from app.repositories.venue_repository import VenueRepository
from app.schemas.reservation import (
    AvailabilitySlot,
    ReservationCreate,
    SpaceAvailabilityRead,
)


# Zona horaria correspondiente a Morón y Buenos Aires.
ARGENTINA_TIMEZONE = ZoneInfo("America/Argentina/Buenos_Aires")


class ReservationService:
    """Reglas de negocio correspondientes a las reservas."""

    @staticmethod
    def get_active_user(
        db: Session,
        user_id: int,
    ) -> User:
        """Comprueba que el usuario exista y se encuentre activo."""

        user = db.get(User, user_id)

        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El usuario indicado no existe.",
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El usuario se encuentra desactivado.",
            )

        return user

    @staticmethod
    def get_available_space_and_venue(
        db: Session,
        sports_space_id: int,
    ) -> tuple[SportsSpace, Venue]:
        """Comprueba que el espacio y su sede estén habilitados."""

        sports_space = SportsSpaceRepository.get_by_id(
            db=db,
            space_id=sports_space_id,
        )

        if sports_space is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El espacio deportivo no existe.",
            )

        if not sports_space.is_active:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El espacio deportivo está dado de baja.",
            )

        venue = VenueRepository.get_by_id(
            db=db,
            venue_id=sports_space.venue_id,
        )

        if venue is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="La sede del espacio no existe.",
            )

        if not venue.is_active:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="La sede del espacio está dada de baja.",
            )

        return sports_space, venue

    @staticmethod
    def validate_venue_hours(
        venue: Venue,
        start_datetime: datetime,
        end_datetime: datetime,
    ) -> None:
        """Comprueba que la reserva esté dentro del horario de la sede."""

        # Convierte el intervalo a la hora local de Argentina.
        local_start = start_datetime.astimezone(ARGENTINA_TIMEZONE)
        local_end = end_datetime.astimezone(ARGENTINA_TIMEZONE)

        # Por el momento, una reserva debe comenzar y terminar
        # dentro del mismo día calendario.
        if local_start.date() != local_end.date():
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "La reserva debe comenzar y terminar "
                    "en el mismo día."
                ),
            )

        if (
            local_start.time().replace(tzinfo=None) < venue.opening_time
            or local_end.time().replace(tzinfo=None) > venue.closing_time
        ):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "La reserva debe estar dentro del horario "
                    "de funcionamiento de la sede."
                ),
            )

    @staticmethod
    def create_reservation(
        db: Session,
        user_id: int,
        reservation_data: ReservationCreate,
    ) -> Reservation:
        """Valida y crea una reserva."""

        ReservationService.get_active_user(
            db=db,
            user_id=user_id,
        )

        sports_space, venue = (
            ReservationService.get_available_space_and_venue(
                db=db,
                sports_space_id=reservation_data.sports_space_id,
            )
        )

        current_time = datetime.now(timezone.utc)

        start_utc = reservation_data.start_datetime.astimezone(
            timezone.utc
        )
        end_utc = reservation_data.end_datetime.astimezone(
            timezone.utc
        )

        if start_utc <= current_time:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="La reserva debe comenzar en el futuro.",
            )

        ReservationService.validate_venue_hours(
            venue=venue,
            start_datetime=start_utc,
            end_datetime=end_utc,
        )

        overlapping_reservation = ReservationRepository.find_overlap(
            db=db,
            sports_space_id=sports_space.id,
            start_datetime=start_utc,
            end_datetime=end_utc,
        )

        if overlapping_reservation is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "El espacio ya se encuentra reservado "
                    "en ese intervalo."
                ),
            )

        try:
            reservation = ReservationRepository.create(
                db=db,
                user_id=user_id,
                sports_space_id=sports_space.id,
                start_datetime=start_utc,
                end_datetime=end_utc,
            )

            db.commit()
            db.refresh(reservation)

            return reservation

        except Exception:
            db.rollback()
            raise

    @staticmethod
    def get_reservation(
        db: Session,
        user_id: int,
        reservation_id: int,
    ) -> Reservation:
        """Obtiene una reserva perteneciente al usuario."""

        reservation = ReservationRepository.get_by_id(
            db=db,
            reservation_id=reservation_id,
        )

        if reservation is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="La reserva solicitada no existe.",
            )

        if reservation.user_id != user_id:
            # No se revela información sobre reservas ajenas.
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="La reserva solicitada no existe.",
            )

        return reservation

    @staticmethod
    def cancel_reservation(
        db: Session,
        user_id: int,
        reservation_id: int,
    ) -> Reservation:
        """
        Cancela una reserva futura y libera el horario.

        La reserva no se elimina de PostgreSQL porque debe
        conservarse en el historial del usuario.
        """

        # Busca la reserva y comprueba que pertenezca al usuario.
        reservation = ReservationService.get_reservation(
            db=db,
            user_id=user_id,
            reservation_id=reservation_id,
        )

        # Una reserva cancelada no puede volver a cancelarse.
        if reservation.status == ReservationStatus.CANCELLED:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="La reserva ya se encuentra cancelada.",
            )

        # Obtiene el momento actual en UTC.
        current_time = datetime.now(timezone.utc)

        # Normaliza el comienzo de la reserva a UTC.
        # Esto evita errores al comparar fechas con y sin zona horaria.
        reservation_start = reservation.start_datetime

        if reservation_start.tzinfo is None:
            reservation_start = reservation_start.replace(
                tzinfo=timezone.utc,
            )
        else:
            reservation_start = reservation_start.astimezone(
                timezone.utc,
            )

        # Solo se permite cancelar una reserva que todavía no comenzó.
        if reservation_start <= current_time:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "No se puede cancelar una reserva "
                    "que ya comenzó o finalizó."
                ),
            )

        try:
            # Cambia el estado a CANCELLED y registra la fecha.
            cancelled_reservation = ReservationRepository.cancel(
                db=db,
                reservation=reservation,
                cancelled_at=current_time,
            )

            # Confirma definitivamente la modificación.
            db.commit()

            # Actualiza el objeto con los datos guardados.
            db.refresh(cancelled_reservation)

            return cancelled_reservation

        except Exception:
            # Si PostgreSQL genera un error, deshace la operación.
            db.rollback()
            raise

    @staticmethod
    def list_future_reservations(
        db: Session,
        user_id: int,
    ) -> list[Reservation]:
        """
        Lista las reservas futuras y confirmadas del usuario.
        """

        # Comprueba que el usuario exista y esté activo.
        ReservationService.get_active_user(
            db=db,
            user_id=user_id,
        )

        # Consulta reservas cuyo inicio sea posterior
        # o igual al momento actual.
        return ReservationRepository.get_user_future_reservations(
            db=db,
            user_id=user_id,
            current_time=datetime.now(timezone.utc),
        )

    @staticmethod
    def list_history(
        db: Session,
        user_id: int,
    ) -> list[Reservation]:
        """
        Lista las reservas finalizadas o canceladas del usuario.
        """

        # Comprueba que el usuario exista y se encuentre activo.
        ReservationService.get_active_user(
            db=db,
            user_id=user_id,
        )

        # Consulta las reservas pasadas y las reservas canceladas.
        return ReservationRepository.get_user_history(
            db=db,
            user_id=user_id,
            current_time=datetime.now(timezone.utc),
        )

    @staticmethod
    def get_availability(
        db: Session,
        sports_space_id: int,
        requested_date: date,
    ) -> SpaceAvailabilityRead:
        """Calcula intervalos disponibles de una hora."""

        sports_space, venue = (
            ReservationService.get_available_space_and_venue(
                db=db,
                sports_space_id=sports_space_id,
            )
        )

        local_start = datetime.combine(
            requested_date,
            venue.opening_time,
            tzinfo=ARGENTINA_TIMEZONE,
        )

        local_end = datetime.combine(
            requested_date,
            venue.closing_time,
            tzinfo=ARGENTINA_TIMEZONE,
        )

        range_start_utc = local_start.astimezone(timezone.utc)
        range_end_utc = local_end.astimezone(timezone.utc)

        reservations = (
            ReservationRepository.get_space_reservations_between(
                db=db,
                sports_space_id=sports_space.id,
                range_start=range_start_utc,
                range_end=range_end_utc,
            )
        )

        available_slots: list[AvailabilitySlot] = []
        current_slot = local_start
        current_time = datetime.now(ARGENTINA_TIMEZONE)

        while current_slot + timedelta(hours=1) <= local_end:
            slot_end = current_slot + timedelta(hours=1)

            # Evita ofrecer horarios que ya comenzaron.
            slot_is_future = current_slot > current_time

            slot_is_occupied = any(
                current_slot.astimezone(timezone.utc)
                < reservation.end_datetime
                and slot_end.astimezone(timezone.utc)
                > reservation.start_datetime
                for reservation in reservations
            )

            if slot_is_future and not slot_is_occupied:
                available_slots.append(
                    AvailabilitySlot(
                        start_datetime=current_slot,
                        end_datetime=slot_end,
                    )
                )

            current_slot = slot_end

        return SpaceAvailabilityRead(
            sports_space_id=sports_space.id,
            requested_date=requested_date,
            opening_time=venue.opening_time.isoformat(),
            closing_time=venue.closing_time.isoformat(),
            available_slots=available_slots,
        )
