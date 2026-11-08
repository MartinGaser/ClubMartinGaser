"""
Endpoints del perfil del usuario autenticado.

La identidad se obtiene exclusivamente desde el token Firebase.
El cliente no envía manualmente el identificador del usuario.
"""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.user import UserRead, UserUpdate
from app.services.user_service import UserService


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
    Devuelve el perfil asociado al token de Firebase.

    Si el perfil todavía no existía en PostgreSQL,
    la dependencia de autenticación lo crea automáticamente.
    """

    return current_user


@router.put(
    "/me",
    response_model=UserRead,
    summary="Editar mi perfil",
)
def update_my_profile(
    user_data: UserUpdate,
    current_user: Annotated[
        User,
        Depends(get_current_user),
    ],
    db: Annotated[
        Session,
        Depends(get_db),
    ],
):
    """
    Modifica nombre, apellido y fecha de nacimiento.

    El correo y firebase_uid no pueden modificarse desde este endpoint.
    """

    return UserService.update_profile(
        db=db,
        current_user=current_user,
        user_data=user_data,
    )
