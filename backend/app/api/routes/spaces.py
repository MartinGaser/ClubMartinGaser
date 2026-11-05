"""
Endpoints de espacios deportivos.

Permiten listar, consultar, crear, modificar y dar de baja
espacios vinculados con una sede.
"""
from datetime import date

from app.schemas.reservation import SpaceAvailabilityRead
from app.services.reservation_service import ReservationService

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.enums import SportType
from app.schemas.sports_space import (
    SportsSpaceCreate,
    SportsSpaceRead,
    SportsSpaceUpdate,
)
from app.services.space_service import SportsSpaceService


router = APIRouter()


@router.get(
    "",
    response_model=list[SportsSpaceRead],
    summary="Listar espacios deportivos",
)
def list_spaces(
    venue_id: int | None = Query(
        default=None,
        gt=0,
        description="Filtra los espacios por sede.",
    ),
    sport_type: SportType | None = Query(
        default=None,
        description="Filtra los espacios por deporte.",
    ),
    active_only: bool = Query(
        default=True,
        description="Indica si solo se muestran espacios activos.",
    ),
    db: Session = Depends(get_db),
):
    """Lista los espacios y aplica los filtros recibidos."""

    return SportsSpaceService.list_spaces(
        db=db,
        venue_id=venue_id,
        sport_type=sport_type,
        active_only=active_only,
    )


@router.get(
    "/{space_id}",
    response_model=SportsSpaceRead,
    summary="Consultar un espacio deportivo",
)
def get_space(
    space_id: int,
    db: Session = Depends(get_db),
):
    """Obtiene un espacio mediante su identificador."""

    return SportsSpaceService.get_space(
        db=db,
        space_id=space_id,
    )


@router.post(
    "",
    response_model=SportsSpaceRead,
    status_code=status.HTTP_201_CREATED,
    summary="Crear un espacio deportivo",
)
def create_space(
    space_data: SportsSpaceCreate,
    db: Session = Depends(get_db),
):
    """
    Crea un espacio dentro de una sede activa.

    Más adelante este endpoint requerirá permisos administrativos.
    """

    return SportsSpaceService.create_space(
        db=db,
        space_data=space_data,
    )


@router.patch(
    "/{space_id}",
    response_model=SportsSpaceRead,
    summary="Actualizar un espacio deportivo",
)
def update_space(
    space_id: int,
    space_data: SportsSpaceUpdate,
    db: Session = Depends(get_db),
):
    """Modifica únicamente los campos enviados."""

    return SportsSpaceService.update_space(
        db=db,
        space_id=space_id,
        space_data=space_data,
    )


@router.delete(
    "/{space_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Dar de baja un espacio deportivo",
)
def delete_space(
    space_id: int,
    db: Session = Depends(get_db),
):
    """
    Realiza una baja lógica del espacio.

    El espacio permanece en PostgreSQL para conservar
    el historial de reservas.
    """

    # Llama al servicio encargado de validar y dar de baja el espacio.
    SportsSpaceService.delete_space(
        db=db,
        space_id=space_id,
    )

    # Un DELETE correcto devuelve 204 sin contenido.
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/{space_id}/availability",
    response_model=SpaceAvailabilityRead,
    summary="Consultar disponibilidad de un espacio",
)
def get_space_availability(
    space_id: int,
    requested_date: date = Query(
        description="Fecha consultada en formato YYYY-MM-DD.",
    ),
    db: Session = Depends(get_db),
):
    """
    Calcula intervalos disponibles de una hora.

    No devuelve horarios ocupados ni horarios que ya pasaron.
    """

    # El servicio consulta el horario de la sede y las reservas
    # confirmadas para calcular los turnos disponibles.
    return ReservationService.get_availability(
        db=db,
        sports_space_id=space_id,
        requested_date=requested_date,
    )