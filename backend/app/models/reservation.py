"""
Modelo de reserva.

Una reserva relaciona un usuario con un espacio deportivo
durante un intervalo determinado.
"""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import ReservationStatus


if TYPE_CHECKING:
    from app.models.sports_space import SportsSpace
    from app.models.user import User


class Reservation(Base):
    """Representa una reserva deportiva."""

    __tablename__ = "reservations"

    __table_args__ = (
        # La finalización debe ser posterior al inicio.
        CheckConstraint(
            "end_datetime > start_datetime",
            name="ck_reservation_end_after_start",
        ),

        # Este índice acelera la búsqueda de disponibilidad.
        Index(
            "ix_reservations_space_datetime",
            "sports_space_id",
            "start_datetime",
            "end_datetime",
        ),
    )

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True,
    )

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    sports_space_id: Mapped[int] = mapped_column(
        ForeignKey("sports_spaces.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    # La fecha y la hora se almacenan juntas para facilitar comparaciones.
    start_datetime: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        index=True,
    )

    end_datetime: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        index=True,
    )

    status: Mapped[ReservationStatus] = mapped_column(
        Enum(
            ReservationStatus,
            name="reservation_status",
            native_enum=True,
        ),
        default=ReservationStatus.CONFIRMED,
        nullable=False,
        index=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Solo tendrá valor cuando la reserva sea cancelada.
    cancelled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    user: Mapped["User"] = relationship(
        back_populates="reservations",
    )

    sports_space: Mapped["SportsSpace"] = relationship(
        back_populates="reservations",
    )
