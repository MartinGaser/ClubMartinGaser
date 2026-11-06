"""
Endpoints de reservas del usuario autenticado.

La identidad se obtiene exclusivamente desde el token de Firebase.
El cliente no puede elegir manualmente otro user_id.
"""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.reservation import ReservationCreate, ReservationRead
from app.services.reservation_service import ReservationService


router = APIRouter()


@router.post(
    "",
    response_model=ReservationRead,
    status_code=201,
    summary="Crear una reserva",
)
def create_reservation(
    reservation_data: ReservationCreate,
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
    Crea una reserva para el usuario autenticado.

    El identificador se obtiene del token Firebase validado.
    """

    return ReservationService.create_reservation(
        db=db,
        user_id=current_user.id,
        reservation_data=reservation_data,
    )


@router.get(
    "/me",
    response_model=list[ReservationRead],
    summary="Listar mis reservas futuras",
)
def list_future_reservations(
    current_user: Annotated[
        User,
        Depends(get_current_user),
    ],
    db: Annotated[
        Session,
        Depends(get_db),
    ],
):
    """Devuelve las reservas futuras del usuario autenticado."""

    return ReservationService.list_future_reservations(
        db=db,
        user_id=current_user.id,
    )


@router.get(
    "/me/history",
    response_model=list[ReservationRead],
    summary="Consultar mi historial de reservas",
)
def list_reservation_history(
    current_user: Annotated[
        User,
        Depends(get_current_user),
    ],
    db: Annotated[
        Session,
        Depends(get_db),
    ],
):
    """Devuelve las reservas canceladas o finalizadas."""

    return ReservationService.list_history(
        db=db,
        user_id=current_user.id,
    )


@router.get(
    "/{reservation_id}",
    response_model=ReservationRead,
    summary="Consultar una reserva",
)
def get_reservation(
    reservation_id: int,
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
    Devuelve una reserva si pertenece al usuario autenticado.

    ReservationService devuelve 404 si la reserva pertenece
    a otra persona, evitando revelar información privada.
    """

    return ReservationService.get_reservation(
        db=db,
        user_id=current_user.id,
        reservation_id=reservation_id,
    )


@router.delete(
    "/{reservation_id}",
    response_model=ReservationRead,
    summary="Cancelar una reserva",
)
def cancel_reservation(
    reservation_id: int,
    current_user: Annotated[
        User,
        Depends(get_current_user),
    ],
    db: Annotated[
        Session,
        Depends(get_db),
    ],
):
    """Cancela una reserva futura del usuario autenticado."""

    return ReservationService.cancel_reservation(
        db=db,
        user_id=current_user.id,
        reservation_id=reservation_id,
    )
