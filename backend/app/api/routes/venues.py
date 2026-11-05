"""Endpoints de las sedes deportivas."""

from fastapi import APIRouter


router = APIRouter()


@router.get("")
def list_venues() -> list[dict[str, str]]:
    """
    Devuelve provisoriamente una lista vacía.

    Después consultará las sedes activas en PostgreSQL.
    """

    return []
