"""
Configuración general del backend.

Los valores sensibles se obtienen desde el archivo .env
o desde variables de entorno configuradas en Render.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Contiene la configuración utilizada por FastAPI."""

    APP_NAME: str = "ClubMartinGaser"
    API_PREFIX: str = "/api"

    # Conexión con PostgreSQL.
    DATABASE_URL: str = (
        "postgresql://postgres:postgres@127.0.0.1:5432/"
        "club_martin_gaser"
    )

    # Identificador del proyecto Firebase.
    FIREBASE_PROJECT_ID: str = ""

    # Ruta relativa o absoluta de la cuenta de servicio.
    FIREBASE_CREDENTIALS_PATH: str = (
        "firebase-service-account.json"
    )

    # Lee automáticamente las variables almacenadas en .env.
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


# Instancia compartida por toda la aplicación.
settings = Settings()
