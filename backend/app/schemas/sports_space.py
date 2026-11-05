"""
Esquemas Pydantic para los espacios deportivos.
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import SportType


class SportsSpaceBase(BaseModel):
    """Datos comunes de un espacio deportivo."""

    venue_id: int = Field(
        gt=0,
        description="Identificador de la sede.",
    )
    name: str = Field(
        min_length=2,
        max_length=150,
        examples=["Cancha de futbol 1"],
    )
    sport_type: SportType
    description: str | None = Field(
        default=None,
        max_length=500,
    )


class SportsSpaceCreate(SportsSpaceBase):
    """Datos necesarios para crear un espacio deportivo."""

    pass


class SportsSpaceUpdate(BaseModel):
    """Datos que pueden modificarse en el espacio."""

    venue_id: int | None = Field(
        default=None,
        gt=0,
    )
    name: str | None = Field(
        default=None,
        min_length=2,
        max_length=150,
    )
    sport_type: SportType | None = None
    description: str | None = Field(
        default=None,
        max_length=500,
    )
    is_active: bool | None = None


class SportsSpaceRead(SportsSpaceBase):
    """Información del espacio devuelta por la API."""

    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
