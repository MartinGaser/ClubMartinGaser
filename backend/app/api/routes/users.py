"""
Endpoints del perfil del usuario autenticado.

La identidad del usuario se obtiene del token de Firebase.
El cliente nunca envía manualmente el identificador del usuario.
"""

from typing import Annotated

from fastapi import APIRouter, Depends

from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.user import UserRead


router = APIRouter()


@router.get(
    "/me",
    response_model=UserRead,
    summary="Consultar mi perfil",
)
def get_my_profile(
    current_user: Annotated[
        User,
        Depends(get_current_user),
    ],
):
    """
    Devuelve el perfil asociado al token validado por Firebase.

    Si el usuario de Firebase todavía no existe en PostgreSQL,
    la dependencia de autenticación crea el perfil automáticamente.
    """

    return current_user
