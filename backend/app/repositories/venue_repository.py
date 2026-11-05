"""
Repositorio de sedes.

Esta capa contiene exclusivamente consultas a PostgreSQL.
No maneja respuestas HTTP ni decisiones de presentación.
"""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.venue import Venue
from app.schemas.venue import VenueCreate, VenueUpdate


class VenueRepository:
    """Operaciones de acceso a datos para la tabla venues."""

    @staticmethod
    def get_all(
        db: Session,
        active_only: bool = True,
    ) -> list[Venue]:
        """
        Obtiene todas las sedes.

        Si active_only es verdadero, devuelve solamente las sedes
        que todavía se encuentran habilitadas.
        """

        statement = select(Venue)

        if active_only:
            statement = statement.where(Venue.is_active.is_(True))

        # Ordena las sedes alfabéticamente para mantener
        # una presentación consistente en la aplicación.
        statement = statement.order_by(Venue.name.asc())

        return list(db.scalars(statement).all())

    @staticmethod
    def get_by_id(
        db: Session,
        venue_id: int,
    ) -> Venue | None:
        """Busca una sede mediante su identificador."""

        return db.get(Venue, venue_id)

    @staticmethod
    def get_by_name(
        db: Session,
        name: str,
    ) -> Venue | None:
        """
        Busca una sede por nombre ignorando mayúsculas y minúsculas.

        Esto se utiliza para evitar nombres duplicados.
        """

        statement = select(Venue).where(
            Venue.name.ilike(name.strip())
        )

        return db.scalar(statement)

    @staticmethod
    def create(
        db: Session,
        venue_data: VenueCreate,
    ) -> Venue:
        """Crea una sede nueva en PostgreSQL."""

        venue = Venue(
            name=venue_data.name.strip(),
            address=venue_data.address.strip(),
            opening_time=venue_data.opening_time,
            closing_time=venue_data.closing_time,
            is_active=True,
        )

        db.add(venue)

        # flush envía el INSERT a PostgreSQL sin cerrar
        # todavía la transacción.
        db.flush()

        # refresh obtiene los valores generados por PostgreSQL,
        # como el id y las fechas de creación.
        db.refresh(venue)

        return venue

    @staticmethod
    def update(
        db: Session,
        venue: Venue,
        venue_data: VenueUpdate,
    ) -> Venue:
        """Modifica únicamente los campos enviados por el cliente."""

        # exclude_unset evita reemplazar campos que no fueron enviados.
        changes = venue_data.model_dump(exclude_unset=True)

        for field_name, field_value in changes.items():
            # Elimina espacios sobrantes en campos de texto.
            if isinstance(field_value, str):
                field_value = field_value.strip()

            setattr(venue, field_name, field_value)

        db.add(venue)
        db.flush()
        db.refresh(venue)

        return venue

    @staticmethod
    def soft_delete(
        db: Session,
        venue: Venue,
    ) -> Venue:
        """
        Realiza una baja lógica.

        La sede no se elimina físicamente porque sus espacios
        y reservas deben conservarse para el historial.
        """

        venue.is_active = False

        db.add(venue)
        db.flush()
        db.refresh(venue)

        return venue
