"""
Modelo de sede deportiva.

Una sede contiene uno o varios espacios deportivos.
"""

from datetime import datetime, time
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, String, Time, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


if TYPE_CHECKING:
    from app.models.sports_space import SportsSpace


class Venue(Base):
    """Representa una sede deportiva."""

    __tablename__ = "venues"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True,
    )

    name: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
        index=True,
    )

    address: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    # Horario general de apertura de la sede.
    opening_time: Mapped[time] = mapped_column(
        Time,
        nullable=False,
    )

    # Horario general de cierre de la sede.
    closing_time: Mapped[time] = mapped_column(
        Time,
        nullable=False,
    )

    # Una sede inactiva deja de mostrarse sin perder su historial.
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

    # Una sede puede contener varios espacios deportivos.
    sports_spaces: Mapped[list["SportsSpace"]] = relationship(
        back_populates="venue",
        cascade="all, delete-orphan",
    )
