"""
Endpoints de reservas.

El parámetro user_id es temporal.
Cuando integremos Firebase, el usuario se obtendrá automáticamente
desde el token de autenticación.
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
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
    user_id: int = Query(
        gt=0,
        description=(
            "Usuario temporal para pruebas. "
            "Luego se obtendrá desde Firebase."
        ),
    ),
    db: Session = Depends(get_db),
):
    """Crea una reserva si el horario se encuentra disponible."""

    return ReservationService.create_reservation(
        db=db,
        user_id=user_id,
        reservation_data=reservation_data,
    )


@router.get(
    "/me",
    response_model=list[ReservationRead],
    summary="Listar reservas futuras",
)
def list_future_reservations(
    user_id: int = Query(gt=0),
    db: Session = Depends(get_db),
):
    """Devuelve reservas futuras y confirmadas del usuario."""

    return ReservationService.list_future_reservations(
        db=db,
        user_id=user_id,
    )


@router.get(
    "/me/history",
    response_model=list[ReservationRead],
    summary="Consultar historial de reservas",
)
def list_reservation_history(
    user_id: int = Query(gt=0),
    db: Session = Depends(get_db),
):
    """Devuelve reservas canceladas o finalizadas."""

    return ReservationService.list_history(
        db=db,
        user_id=user_id,
    )


@router.get(
    "/{reservation_id}",
    response_model=ReservationRead,
    summary="Consultar una reserva",
)
def get_reservation(
    reservation_id: int,
    user_id: int = Query(gt=0),
    db: Session = Depends(get_db),
):
    """Devuelve una reserva perteneciente al usuario."""

    return ReservationService.get_reservation(
        db=db,
        user_id=user_id,
        reservation_id=reservation_id,
    )


@router.delete(
    "/{reservation_id}",
    response_model=ReservationRead,
    summary="Cancelar una reserva",
)
def cancel_reservation(
    reservation_id: int,
    user_id: int = Query(gt=0),
    db: Session = Depends(get_db),
):
    """Cancela la reserva y libera el horario."""

    return ReservationService.cancel_reservation(
        db=db,
        user_id=user_id,
        reservation_id=reservation_id,
    )
