"""
Registro central de los modelos del sistema.

Este archivo permite importar todos los modelos desde app.models.
También permite que Alembic descubra las tablas registradas.
"""

# Modelo que representa a los usuarios registrados.
from app.models.user import User

# Modelo que representa a las sedes deportivas.
from app.models.venue import Venue

# Modelo que representa canchas y otros espacios deportivos.
from app.models.sports_space import SportsSpace

# Modelo que representa las reservas realizadas.
from app.models.reservation import Reservation

# Modelo que almacena tokens para notificaciones de Firebase.
from app.models.device_token import DeviceToken


# Define explícitamente qué clases exporta el paquete app.models.
__all__ = [
    "User",
    "Venue",
    "SportsSpace",
    "Reservation",
    "DeviceToken",
]
