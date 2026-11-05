"""
Router principal de la API.

Agrupa los endpoints según la funcionalidad.
"""

from fastapi import APIRouter

from app.api.routes import reservations, spaces, users, venues


api_router = APIRouter()


# Endpoints del perfil del usuario.
api_router.include_router(
    users.router,
    prefix="/users",
    tags=["Usuarios"],
)

# Endpoints de las sedes.
api_router.include_router(
    venues.router,
    prefix="/venues",
    tags=["Sedes"],
)

# Endpoints de los espacios deportivos.
api_router.include_router(
    spaces.router,
    prefix="/spaces",
    tags=["Espacios deportivos"],
)

# Endpoints de las reservas.
api_router.include_router(
    reservations.router,
    prefix="/reservations",
    tags=["Reservas"],
)
