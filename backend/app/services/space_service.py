"""
Servicio de espacios deportivos.

Aplica las reglas del negocio antes de modificar PostgreSQL.
"""

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.enums import SportType
from app.models.sports_space import SportsSpace
from app.repositories.space_repository import SportsSpaceRepository
from app.repositories.venue_repository import VenueRepository
from app.schemas.sports_space import SportsSpaceCreate, SportsSpaceUpdate


class SportsSpaceService:
    """Reglas de negocio de los espacios deportivos."""

    @staticmethod
    def list_spaces(
        db: Session,
        venue_id: int | None = None,
        sport_type: SportType | None = None,
        active_only: bool = True,
    ) -> list[SportsSpace]:
        """Lista espacios y aplica filtros opcionales."""

        # Si se filtra por sede, primero comprobamos que exista.
        if venue_id is not None:
            venue = VenueRepository.get_by_id(
                db=db,
                venue_id=venue_id,
            )

            if venue is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="La sede solicitada no existe.",
                )

        return SportsSpaceRepository.get_all(
            db=db,
            venue_id=venue_id,
            sport_type=sport_type,
            active_only=active_only,
        )

    @staticmethod
    def get_space(
        db: Session,
        space_id: int,
    ) -> SportsSpace:
        """Obtiene un espacio o responde 404."""

        sports_space = SportsSpaceRepository.get_by_id(
            db=db,
            space_id=space_id,
        )

        if sports_space is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El espacio deportivo solicitado no existe.",
            )

        return sports_space

    @staticmethod
    def validate_active_venue(
        db: Session,
        venue_id: int,
    ) -> None:
        """Comprueba que la sede exista y se encuentre activa."""

        venue = VenueRepository.get_by_id(
            db=db,
            venue_id=venue_id,
        )

        if venue is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="La sede indicada no existe.",
            )

        if not venue.is_active:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "No se puede utilizar una sede "
                    "que se encuentra dada de baja."
                ),
            )

    @staticmethod
    def create_space(
        db: Session,
        space_data: SportsSpaceCreate,
    ) -> SportsSpace:
        """Valida y crea un espacio deportivo."""

        SportsSpaceService.validate_active_venue(
            db=db,
            venue_id=space_data.venue_id,
        )

        existing_space = (
            SportsSpaceRepository.get_by_venue_and_name(
                db=db,
                venue_id=space_data.venue_id,
                name=space_data.name,
            )
        )

        if existing_space is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "Ya existe un espacio con ese nombre "
                    "dentro de la sede."
                ),
            )

        try:
            sports_space = SportsSpaceRepository.create(
                db=db,
                space_data=space_data,
            )

            db.commit()

            return sports_space

        except Exception:
            db.rollback()
            raise

    @staticmethod
    def update_space(
        db: Session,
        space_id: int,
        space_data: SportsSpaceUpdate,
    ) -> SportsSpace:
        """Valida y actualiza un espacio deportivo."""

        sports_space = SportsSpaceService.get_space(
            db=db,
                )

        # Determina la sede final, tanto si cambia como si no.
        target_venue_id = (
            space_data.venue_id
            if space_data.venue_id is not None
            else sports_space.venue_id
        )

        SportsSpaceService.validate_active_venue(
            db=db,
            venue_id=target_venue_id,
        )

        # Determina el nombre final para comprobar duplicados.
        target_name = (
            space_data.name
            if space_data.name is not None
            else sports_space.name
        )

        existing_space = (
            SportsSpaceRepository.get_by_venue_and_name(
                db=db,
                venue_id=target_venue_id,
                name=target_name,
            )
        )

        if (
            existing_space is not None
            and existing_space.id != sports_space.id
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "Ya existe otro espacio con ese nombre "
                    "dentro de la sede."
                ),
            )

        try:
            updated_space = SportsSpaceRepository.update(
                db=db,
                sports_space=sports_space,
                space_data=space_data,
            )

            db.commit()

            return updated_space

        except Exception:
            db.rollback()
            raise

    @staticmethod
    def delete_space(
        db: Session,
        space_id: int,
    ) -> None:
        """Realiza la baja lógica de un espacio."""

        sports_space = SportsSpaceService.get_space(
            db=db,
            space_id=space_id,
        )

        if not sports_space.is_active:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "El espacio deportivo ya se encuentra "
                    "dado de baja."
                ),
            )

        try:
            SportsSpaceRepository.soft_delete(
                db=db,
                sports_space=sports_space,
            )

            db.commit()

        except Exception:
            db.rollback()
            raise
