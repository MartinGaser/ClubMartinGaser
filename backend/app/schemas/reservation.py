"""
Esquemas Pydantic para las reservas deportivas.

Las validaciones estructurales se realizan aquí.
La disponibilidad y la superposición se comprobarán posteriormente
en ReservationService, consultando PostgreSQL.
"""

from datetime import datetime, timezone

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models.enums import ReservationStatus


class ReservationCreate(BaseModel):
    """Información necesaria para solicitar una reserva."""

    sports_space_id: int = Field(
        gt=0,
        description="Identificador del espacio que será reservado.",
    )
    start_datetime: datetime
    end_datetime: datetime

    @model_validator(mode="after")
    def validate_reservation_dates(self):
        """Comprueba las reglas básicas de fecha, horario y duración."""

        # La hora final siempre debe ser posterior a la inicial.
        if self.end_datetime <= self.start_datetime:
            raise ValueError(
                "La fecha y hora de finalizacion deben ser posteriores al inicio."
            )

        # El trabajo práctico exige que los horarios comiencen
        # y terminen exactamente en minuto 00.
        if (
            self.start_datetime.minute != 0
            or self.end_datetime.minute != 0
            or self.start_datetime.second != 0
            or self.end_datetime.second != 0
            or self.start_datetime.microsecond != 0
            or self.end_datetime.microsecond != 0
        ):
            raise ValueError(
                "La reserva debe comenzar y terminar en una hora exacta."
            )

        # Calcula la duración total del intervalo.
        duration = self.end_datetime - self.start_datetime

        # La duración mínima permitida es de una hora.
        if duration.total_seconds() < 3600:
            raise ValueError(
                "La reserva debe tener una duracion minima de una hora."
            )

        # Comprueba que la reserva sea futura.
        # Si la fecha tiene zona horaria, utiliza UTC.
        if self.start_datetime.tzinfo is not None:
            current_time = datetime.now(timezone.utc)
            comparable_start = self.start_datetime.astimezone(timezone.utc)
        else:
            current_time = datetime.now()
            comparable_start = self.start_datetime

        if comparable_start <= current_time:
            raise ValueError(
                "La reserva debe comenzar en una fecha y hora futuras."
            )

        return self


class ReservationRead(BaseModel):
    """Información completa de una reserva devuelta por la API."""

    id: int
    user_id: int
    sports_space_id: int
    start_datetime: datetime
    end_datetime: datetime
    status: ReservationStatus
    created_at: datetime
    cancelled_at: datetime | None

    model_config = ConfigDict(from_attributes=True)


class ReservationCancel(BaseModel):
    """
    Respuesta que puede utilizarse al cancelar una reserva.

    La identificación del usuario se obtendrá desde Firebase,
    no desde el cuerpo de la petición.
    """

    reservation_id: int = Field(gt=0)
