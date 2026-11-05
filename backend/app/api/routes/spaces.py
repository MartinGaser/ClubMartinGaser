"""Endpoints de los espacios deportivos."""

from fastapi import APIRouter


router = APIRouter()


@router.get("")
def list_sports_spaces() -> list[dict[str, str]]:
    """
    Devuelve provisoriamente una lista vacía.

    Después permitirá filtrar los espacios por sede y deporte.
    """

    return []
