"""
Endpoints de sedes deportivas.

El router recibe las peticiones HTTP, delega las reglas
al servicio y convierte los modelos en respuestas JSON.
"""

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.venue import VenueCreate, VenueRead, VenueUpdate
from app.services.venue_service import VenueService


router = APIRouter()


@router.get(
    "",
    response_model=list[VenueRead],
    summary="Listar sedes",
)
def list_venues(
    active_only: bool = Query(
        default=True,
        description="Indica si solo se muestran sedes activas.",
    ),
    db: Session = Depends(get_db),
):
    """
    Devuelve las sedes ordenadas alfabéticamente.

    Por defecto, no incluye sedes dadas de baja.
    """

    return VenueService.list_venues(
        db=db,
        active_only=active_only,
    )


@router.get(
    "/{venue_id}",
    response_model=VenueRead,
    summary="Consultar una sede",
)
def get_venue(
    venue_id: int,
    db: Session = Depends(get_db),
):
    """Devuelve los datos de una sede mediante su id."""

    return VenueService.get_venue(
        db=db,
        venue_id=venue_id,
    )


@router.post(
    "",
    response_model=VenueRead,
    status_code=status.HTTP_201_CREATED,
    summary="Crear una sede",
)
def create_venue(
    venue_data: VenueCreate,
    db: Session = Depends(get_db),
):
    """
    Crea una sede.

    Temporalmente este endpoint está abierto.
    Más adelante exigirá permisos administrativos.
    """

    return VenueService.create_venue(
        db=db,
        venue_data=venue_data,
    )


@router.patch(
    "/{venue_id}",
    response_model=VenueRead,
    summary="Actualizar una sede",
)
def update_venue(
    venue_id: int,
    venue_data: VenueUpdate,
    db: Session = Depends(get_db),
):
    """Modifica únicamente los campos enviados."""

    return VenueService.update_venue(
        db=db,
        venue_id=venue_id,
        venue_data=venue_data,
    )


@router.delete(
    "/{venue_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Dar de baja una sede",
)
def delete_venue(
    venue_id: int,
    db: Session = Depends(get_db),
):
    """
    Realiza una baja lógica.

    La sede permanece almacenada para mantener el historial.
    """

    VenueService.delete_venue(
        db=db,
        venue_id=venue_id,
    )

    return Response(status_code=status.HTTP_204_NO_CONTENT)
