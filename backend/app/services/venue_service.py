"""
Servicio de sedes.

Esta capa aplica las reglas del negocio antes de llamar
al repositorio y modificar PostgreSQL.
"""

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.venue import Venue
from app.repositories.venue_repository import VenueRepository
from app.schemas.venue import VenueCreate, VenueUpdate


class VenueService:
    """Reglas de negocio relacionadas con las sedes."""

    @staticmethod
    def list_venues(
        db: Session,
        active_only: bool = True,
    ) -> list[Venue]:
        """Devuelve las sedes disponibles."""

        return VenueRepository.get_all(
            db=db,
            active_only=active_only,
        )

    @staticmethod
    def get_venue(
        db: Session,
        venue_id: int,
    ) -> Venue:
        """
        Obtiene una sede.

        Si no existe, responde con código HTTP 404.
        """

        venue = VenueRepository.get_by_id(
            db=db,
            venue_id=venue_id,
        )

        if venue is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="La sede solicitada no existe.",
            )

        return venue

    @staticmethod
    def create_venue(
        db: Session,
        venue_data: VenueCreate,
    ) -> Venue:
        """Valida y crea una sede nueva."""

        existing_venue = VenueRepository.get_by_name(
            db=db,
            name=venue_data.name,
        )

        if existing_venue is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Ya existe una sede con ese nombre.",
            )

        try:
            venue = VenueRepository.create(
                db=db,
                venue_data=venue_data,
            )

            # Confirma definitivamente el INSERT.
            db.commit()

            return venue

        except Exception:
            # Si ocurre un error, revierte toda la transacción.
            db.rollback()
            raise

    @staticmethod
    def update_venue(
        db: Session,
        venue_id: int,
        venue_data: VenueUpdate,
    ) -> Venue:
        """Valida y actualiza una sede existente."""

        venue = VenueService.get_venue(
            db=db,
            venue_id=venue_id,
        )

        # Si se envía un nombre nuevo, verifica que no pertenezca
        # a otra sede.
        if venue_data.name is not None:
            existing_venue = VenueRepository.get_by_name(
                db=db,
                name=venue_data.name,
            )

            if (
                existing_venue is not None
                and existing_venue.id != venue.id
            ):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Ya existe otra sede con ese nombre.",
                )

        # Para una actualización parcial, combina los horarios nuevos
        # con los horarios existentes antes de validarlos.
        opening_time = (
            venue_data.opening_time
            if venue_data.opening_time is not None
            else venue.opening_time
        )

        closing_time = (
            venue_data.closing_time
            if venue_data.closing_time is not None
            else venue.closing_time
        )

        if closing_time <= opening_time:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "El horario de cierre debe ser posterior "
                    "al horario de apertura."
                ),
            )

        try:
            updated_venue = VenueRepository.update(
                db=db,
                venue=venue,
                venue_data=venue_data,
            )

            db.commit()

            return updated_venue

        except Exception:
            db.rollback()
            raise

    @staticmethod
    def delete_venue(
        db: Session,
        venue_id: int,
    ) -> None:
        """Realiza la baja lógica de una sede."""

        venue = VenueService.get_venue(
            db=db,
            venue_id=venue_id,
        )

        if not venue.is_active:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="La sede ya se encuentra dada de baja.",
            )

        try:
            VenueRepository.soft_delete(
                db=db,
                venue=venue,
            )

            db.commit()

        except Exception:
            db.rollback()
            raise
