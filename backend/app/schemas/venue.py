"""
Esquemas Pydantic de las sedes deportivas.
"""

from datetime import datetime, time

from pydantic import BaseModel, ConfigDict, Field, model_validator


class VenueBase(BaseModel):
    """Datos comunes de una sede."""

    name: str = Field(
        min_length=2,
        max_length=150,
        examples=["Sede Moron Centro"],
    )
    address: str = Field(
        min_length=5,
        max_length=255,
        examples=["Almirante Brown 1250, Moron"],
    )
    opening_time: time
    closing_time: time

    @model_validator(mode="after")
    def validate_opening_hours(self):
        """
        Comprueba que la sede cierre después de abrir.

        Por ejemplo, no acepta apertura 18:00 y cierre 08:00.
        """

        if self.closing_time <= self.opening_time:
            raise ValueError(
                "El horario de cierre debe ser posterior al horario de apertura."
            )

        return self


class VenueCreate(VenueBase):
    """Datos necesarios para crear una sede."""

    pass


class VenueUpdate(BaseModel):
    """Datos opcionales que pueden modificarse en una sede."""

    name: str | None = Field(
        default=None,
        min_length=2,
        max_length=150,
    )
    address: str | None = Field(
        default=None,
        min_length=5,
        max_length=255,
    )
    opening_time: time | None = None
    closing_time: time | None = None
    is_active: bool | None = None


class VenueRead(VenueBase):
    """Información de una sede devuelta por la API."""

    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
