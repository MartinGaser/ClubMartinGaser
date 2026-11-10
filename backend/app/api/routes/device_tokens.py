"""
Registro de dispositivos para notificaciones push.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.device_token import (
    DeviceTokenCreate,
    DeviceTokenRead,
)
from app.services.device_token_service import DeviceTokenService


router = APIRouter()


@router.post(
    "",
    response_model=DeviceTokenRead,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar dispositivo para notificaciones",
)
def register_device(
    token_data: DeviceTokenCreate,
    current_user: Annotated[
        User,
        Depends(get_current_user),
    ],
    db: Annotated[
        Session,
        Depends(get_db),
    ],
):
    return DeviceTokenService.register(
        db=db,
        current_user=current_user,
        token=token_data.token,
    )
