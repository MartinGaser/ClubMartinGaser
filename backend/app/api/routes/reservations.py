"""Endpoints de las reservas deportivas."""

from fastapi import APIRouter


router = APIRouter()


@router.get("/me")
def list_my_reservations() -> list[dict[str, str]]:
    """
    Devuelve provisoriamente las reservas del usuario.

    Posteriormente consultará PostgreSQL utilizando la identidad
    obtenida desde Firebase.
    """

    return []
