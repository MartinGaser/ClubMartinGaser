"""
Modelo de usuario.

Firebase administrará la autenticación y las contraseñas.
PostgreSQL almacenará los datos del perfil del usuario.
"""

from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


# Estas importaciones solo se utilizan para comprobar tipos.
# Evitan importaciones circulares al ejecutar la aplicación.
if TYPE_CHECKING:
    from app.models.device_token import DeviceToken
    from app.models.reservation import Reservation


class User(Base):
    """Representa un usuario registrado en la aplicación."""

    __tablename__ = "users"

    # Identificador interno generado por PostgreSQL.
    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True,
    )

    # Identificador único proporcionado por Firebase Authentication.
    firebase_uid: Mapped[str] = mapped_column(
        String(128),
        unique=True,
        nullable=False,
        index=True,
    )

    # La contraseña nunca se almacena en PostgreSQL.
    email: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )

    first_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    last_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    birth_date: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )

    # Permite desactivar al usuario sin eliminar sus reservas.
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
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

    # Relación de uno a muchos entre usuarios y reservas.
    reservations: Mapped[list["Reservation"]] = relationship(
        back_populates="user",
    )

    # Un usuario puede utilizar la aplicación en varios dispositivos.
    device_tokens: Mapped[list["DeviceToken"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )
