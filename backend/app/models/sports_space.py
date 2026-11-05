"""
Modelo de espacio deportivo.

Un espacio deportivo pertenece a una sede y puede recibir reservas.
"""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import SportType


if TYPE_CHECKING:
    from app.models.reservation import Reservation
    from app.models.venue import Venue


class SportsSpace(Base):
    """Representa una cancha, pileta u otro espacio reservable."""

    __tablename__ = "sports_spaces"

    # No permite repetir el nombre de un espacio dentro de la misma sede.
    __table_args__ = (
        UniqueConstraint(
            "venue_id",
            "name",
            name="uq_sports_space_venue_name",
        ),
    )

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True,
    )

    # Identifica la sede a la que pertenece el espacio.
    venue_id: Mapped[int] = mapped_column(
        ForeignKey("venues.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    name: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
    )

    sport_type: Mapped[SportType] = mapped_column(
        Enum(
            SportType,
            name="sport_type",
            native_enum=True,
        ),
        nullable=False,
        index=True,
    )

    description: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
        index=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Permite acceder a la sede desde el espacio.
    venue: Mapped["Venue"] = relationship(
        back_populates="sports_spaces",
    )

    # Un espacio puede tener varias reservas en diferentes horarios.
    reservations: Mapped[list["Reservation"]] = relationship(
        back_populates="sports_space",
    )
