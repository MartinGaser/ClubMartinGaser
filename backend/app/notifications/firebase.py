"""
Inicialización de Firebase Admin SDK.

La cuenta de servicio contiene el identificador del proyecto.
Por eso no necesitamos proporcionar projectId manualmente.
"""

from pathlib import Path

import firebase_admin
from firebase_admin import credentials

from app.core.config import settings


def initialize_firebase() -> firebase_admin.App:
    """
    Inicializa Firebase Admin una sola vez.

    La aplicación existente se reutiliza para evitar
    una inicialización duplicada.
    """

    # Si Firebase ya fue inicializado, devuelve la instancia existente.
    if firebase_admin._apps:
        return firebase_admin.get_app()

    credentials_path = Path(
        settings.FIREBASE_CREDENTIALS_PATH
    )

    # Interpreta la ruta relativa desde la carpeta backend.
    if not credentials_path.is_absolute():
        backend_directory = Path(__file__).resolve().parents[2]
        credentials_path = backend_directory / credentials_path

    if not credentials_path.exists():
        raise RuntimeError(
            "No se encontró la cuenta de servicio en: "
            f"{credentials_path}"
        )

    firebase_credential = credentials.Certificate(
        str(credentials_path)
    )

    # Firebase obtiene project_id directamente
    # desde firebase-service-account.json.
    return firebase_admin.initialize_app(
        firebase_credential
    )