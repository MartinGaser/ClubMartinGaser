"""Endpoints del perfil del usuario."""

from fastapi import APIRouter


router = APIRouter()


@router.get("/me")
def get_current_user() -> dict[str, str]:
    """
    Devuelve un mensaje provisional.

    Más adelante, este endpoint identificará al usuario
    mediante el token generado por Firebase.
    """

    return {"message": "Perfil del usuario autenticado"}
