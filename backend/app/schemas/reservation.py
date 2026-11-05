"""
Esquemas Pydantic de reservas.

Estos esquemas validan los datos recibidos desde Flutter o Swagger
antes de ejecutar las reglas de negocio y consultar PostgreSQL.
"""

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models.enums import ReservationStatus


class ReservationCreate(BaseModel):
    """Datos necesarios para solicitar una reserva."""

    sports_space_id: int = Field(
        gt=0,
        description="Identificador del espacio deportivo.",
    )

    start_datetime: datetime = Field(
        description=(
            "Fecha y hora de inicio. Debe incluir zona horaria, "
            "por ejemplo 2026-11-10T18:00:00-03:00."
        ),
    )

    end_datetime: datetime = Field(
        description=(
            "Fecha y hora de finalización. Debe incluir zona horaria."
        ),
    )

    @model_validator(mode="after")
    def validate_reservation_dates(self):
        """Valida formato, duración y orden del intervalo."""

        # Exige zona horaria para evitar diferencias entre Flutter,
        # FastAPI, PostgreSQL y el servidor de Render.
        if (
            self.start_datetime.tzinfo is None
            or self.end_datetime.tzinfo is None
        ):
            raise ValueError(
                "Las fechas deben incluir zona horaria, por ejemplo -03:00."
            )

        # La finalización debe ocurrir después del inicio.
        if self.end_datetime <= self.start_datetime:
            raise ValueError(
                "La fecha de finalización debe ser posterior al inicio."
            )

        # El TP exige comenzar y finalizar en minuto 00.
        date_values = (
            self.start_datetime,
            self.end_datetime,
        )

        for date_value in date_values:
            if (
                date_value.minute != 0
                or date_value.second != 0
                or date_value.microsecond != 0
            ):
                raise ValueError(
                    "La reserva debe comenzar y terminar en una hora exacta."
                )

        duration = self.end_datetime - self.start_datetime

        # La duración mínima obligatoria es de 60 minutos.
        if duration.total_seconds() < 3600:
            raise ValueError(
                "La reserva debe durar al menos una hora."
            )

        return self


class ReservationRead(BaseModel):
    """Información de una reserva devuelta por la API."""

    id: int
    user_id: int
    sports_space_id: int
    start_datetime: datetime
    end_datetime: datetime
    status: ReservationStatus
    created_at: datetime
    cancelled_at: datetime | None

    model_config = ConfigDict(from_attributes=True)


class AvailabilitySlot(BaseModel):
    """Representa un intervalo de una hora disponible."""

    start_datetime: datetime
    end_datetime: datetime


class SpaceAvailabilityRead(BaseModel):
    """Disponibilidad completa de un espacio para una fecha."""

    sports_space_id: int
    requested_date: date
    opening_time: str
    closing_time: str
    available_slots: list[AvailabilitySlot]
