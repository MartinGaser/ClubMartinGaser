"""
Repositorio de espacios deportivos.

Esta capa contiene las consultas directas a PostgreSQL.
Las reglas del negocio se aplican posteriormente en el servicio.
"""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.enums import SportType
from app.models.sports_space import SportsSpace
from app.schemas.sports_space import SportsSpaceCreate, SportsSpaceUpdate


class SportsSpaceRepository:
    """Operaciones de acceso a datos para espacios deportivos."""

    @staticmethod
    def get_all(
        db: Session,
        venue_id: int | None = None,
        sport_type: SportType | None = None,
        active_only: bool = True,
    ) -> list[SportsSpace]:
        """
        Obtiene los espacios deportivos.

        Permite filtrar por sede, deporte y estado.
        """

        statement = select(SportsSpace)

        # Si se envió una sede, limita los resultados a esa sede.
        if venue_id is not None:
            statement = statement.where(
                SportsSpace.venue_id == venue_id
            )

        # Si se envió un deporte, limita los resultados a ese tipo.
        if sport_type is not None:
            statement = statement.where(
                SportsSpace.sport_type == sport_type
            )

        # Por defecto, no muestra espacios dados de baja.
        if active_only:
            statement = statement.where(
                SportsSpace.is_active.is_(True)
            )

        statement = statement.order_by(
            SportsSpace.name.asc()
        )

        return list(db.scalars(statement).all())

    @staticmethod
    def get_by_id(
        db: Session,
        space_id: int,
    ) -> SportsSpace | None:
        """Busca un espacio mediante su identificador."""

        return db.get(SportsSpace, space_id)

    @staticmethod
    def get_by_venue_and_name(
        db: Session,
        venue_id: int,
        name: str,
    ) -> SportsSpace | None:
        """
        Busca un espacio por sede y nombre.

        Se utiliza para impedir que una misma sede tenga dos
        espacios con el mismo nombre.
        """

        statement = select(SportsSpace).where(
            SportsSpace.venue_id == venue_id,
            SportsSpace.name.ilike(name.strip()),
        )

        return db.scalar(statement)

    @staticmethod
    def create(
        db: Session,
        space_data: SportsSpaceCreate,
    ) -> SportsSpace:
        """Crea un espacio deportivo."""

        sports_space = SportsSpace(
            venue_id=space_data.venue_id,
            name=space_data.name.strip(),
            sport_type=space_data.sport_type,
            description=(
                space_data.description.strip()
                if space_data.description
                else None
            ),
            is_active=True,
        )

        db.add(sports_space)
        db.flush()
        db.refresh(sports_space)

        return sports_space

    @staticmethod
    def update(
        db: Session,
        sports_space: SportsSpace,
        space_data: SportsSpaceUpdate,
    ) -> SportsSpace:
        """Actualiza solamente los campos enviados."""

        changes = space_data.model_dump(exclude_unset=True)

        for field_name, field_value in changes.items():
            if isinstance(field_value, str):
                field_value = field_value.strip()

            setattr(sports_space, field_name, field_value)

        db.add(sports_space)
        db.flush()
        db.refresh(sports_space)

        return sports_space

    @staticmethod
    def soft_delete(
        db: Session,
        sports_space: SportsSpace,
    ) -> SportsSpace:
        """
        Realiza una baja lógica.

        El registro permanece almacenado para conservar
        el historial de reservas.
        """

        sports_space.is_active = False

        db.add(sports_space)
        db.flush()
        db.refresh(sports_space)

        return sports_space
