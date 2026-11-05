"""
Esquemas Pydantic del usuario.

Estos esquemas validan los datos recibidos y definen
qué información puede devolver la API.
"""

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserBase(BaseModel):
    """Datos comunes utilizados por los esquemas de usuario."""

    email: EmailStr
    first_name: str = Field(
        min_length=2,
        max_length=100,
        examples=["Martin"],
    )
    last_name: str = Field(
        min_length=2,
        max_length=100,
        examples=["Gaser"],
    )
    birth_date: date | None = None


class UserCreate(UserBase):
    """
    Datos necesarios para registrar un usuario en PostgreSQL.

    La contraseña no se incluye porque Firebase Authentication
    será responsable de administrarla.
    """

    firebase_uid: str = Field(
        min_length=1,
        max_length=128,
    )


class UserUpdate(BaseModel):
    """
    Datos que el usuario puede modificar.

    El correo no aparece porque el requerimiento establece
    que no debe modificarse desde el perfil.
    """

    first_name: str | None = Field(
        default=None,
        min_length=2,
        max_length=100,
    )
    last_name: str | None = Field(
        default=None,
        min_length=2,
        max_length=100,
    )
    birth_date: date | None = None


class UserRead(UserBase):
    """Información del usuario que devuelve la API."""

    id: int
    firebase_uid: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    # Permite convertir directamente un objeto SQLAlchemy
    # en una respuesta JSON de Pydantic.
    model_config = ConfigDict(from_attributes=True)
