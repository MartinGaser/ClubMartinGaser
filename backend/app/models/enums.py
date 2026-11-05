"""
Enumeraciones utilizadas por los modelos.

Las enumeraciones limitan los valores permitidos y evitan guardar
distintas variantes para un mismo dato.
"""

from enum import Enum


class ReservationStatus(str, Enum):
    """Estados permitidos para una reserva."""

    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"


class SportType(str, Enum):
    """Deportes admitidos inicialmente por la aplicación."""

    FOOTBALL = "FOOTBALL"
    TENNIS = "TENNIS"
    PADEL = "PADEL"
    BASKETBALL = "BASKETBALL"
    VOLLEYBALL = "VOLLEYBALL"
    SWIMMING = "SWIMMING"
    OTHER = "OTHER"
