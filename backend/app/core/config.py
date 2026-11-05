"""
Configuración general del backend.

La información sensible se obtiene desde variables de entorno
y no se escribe directamente en el código.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Contiene la configuración utilizada por la aplicación."""

    APP_NAME: str = "ClubMartinGaser"
    API_PREFIX: str = "/api"

    # Dirección de la base de datos PostgreSQL.
    DATABASE_URL: str = (
        "postgresql://postgres:postgres@localhost:5432/club_martin_gaser"
    )

    # Identificador del proyecto creado en Firebase.
    FIREBASE_PROJECT_ID: str = ""

    # Lee automáticamente las variables almacenadas en .env.
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


# Esta instancia se reutiliza en toda la aplicación.
settings = Settings()
