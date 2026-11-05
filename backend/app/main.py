"""
Punto de entrada principal del backend.

Este archivo crea la aplicación FastAPI, registra los endpoints
y habilita la documentación automática con Swagger.
"""

from fastapi import FastAPI

from app.api.router import api_router
from app.core.config import settings


# Crea la aplicación principal de FastAPI.
app = FastAPI(
    title=settings.APP_NAME,
    description="API REST para administrar espacios deportivos y reservas.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)


# Agrega los endpoints de usuarios, sedes, espacios y reservas.
app.include_router(api_router, prefix=settings.API_PREFIX)


@app.get("/", tags=["Sistema"])
def root() -> dict[str, str]:
    """
    Devuelve información básica para comprobar que la API funciona.
    """

    return {
        "application": settings.APP_NAME,
        "message": "API funcionando correctamente",
        "documentation": "/docs",
    }


@app.get("/health", tags=["Sistema"])
def health_check() -> dict[str, str]:
    """
    Permite comprobar si el servidor está activo.

    Render también puede utilizar este endpoint para revisar
    el estado del servicio.
    """

    return {"status": "healthy"}
