"""
Dependencias de autenticación de FastAPI.

Este módulo:
1. Obtiene el token Bearer enviado por Flutter.
2. Verifica el token mediante Firebase Admin.
3. Recupera el uid y el correo validados.
4. Busca o crea el perfil correspondiente en PostgreSQL.
"""

from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import (
    HTTPAuthorizationCredentials,
    HTTPBearer,
)
from firebase_admin import auth
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import User
from app.notifications.firebase import initialize_firebase


# Define el esquema de autenticación Bearer.
# Esto permite que Swagger muestre el botón Authorize.
bearer_scheme = HTTPBearer(
    auto_error=False,
    description="ID token generado por Firebase Authentication.",
)


def get_current_user(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None,
        Depends(bearer_scheme),
    ],
    db: Annotated[
        Session,
        Depends(get_db),
    ],
) -> User:
    """
    Devuelve el usuario autenticado almacenado en PostgreSQL.

    El identificador del usuario no se recibe manualmente.
    Se obtiene exclusivamente desde un token validado por Firebase.
    """

    # Si no se envió una cabecera Authorization, responde 401.
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Se requiere iniciar sesión.",
            headers={
                "WWW-Authenticate": "Bearer",
            },
        )

    # Comprueba que se utilice el esquema Bearer.
    if credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=(
                "El esquema de autenticación debe ser Bearer."
            ),
            headers={
                "WWW-Authenticate": "Bearer",
            },
        )

    try:
        # Inicializa Firebase Admin si todavía no fue inicializado.
        initialize_firebase()

        # Firebase verifica:
        # - Firma del token
        # - Vencimiento
        # - Proyecto de Firebase
        # - Audiencia del token
        decoded_token = auth.verify_id_token(
            credentials.credentials,
        )

    except (
        auth.InvalidIdTokenError,
        auth.ExpiredIdTokenError,
        auth.RevokedIdTokenError,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El token de Firebase es inválido o venció.",
            headers={
                "WWW-Authenticate": "Bearer",
            },
        )

    try:
        initialize_firebase()

        decoded_token = auth.verify_id_token(
            credentials.credentials,
        )

    except Exception as error:
        # No exponemos detalles internos de Firebase al cliente.
        raise HTTPException(
         status_code=status.HTTP_401_UNAUTHORIZED,
         detail="El token de Firebase es inválido o venció.",
         headers={
            "WWW-Authenticate": "Bearer",
        },
    ) from error

    # Extrae información que Firebase ya verificó.
    firebase_uid = decoded_token.get("uid")
    email = decoded_token.get("email")

    if not firebase_uid or not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=(
                "El token no contiene un uid y correo válidos."
            ),
        )

    # Busca el perfil local utilizando el uid estable de Firebase.
    statement = select(User).where(
        User.firebase_uid == firebase_uid
    )

    user = db.scalar(statement)

    # Si el usuario se registró en Firebase pero todavía no tiene
    # perfil local, crea automáticamente un registro en PostgreSQL.
    if user is None:
        user = User(
            firebase_uid=firebase_uid,
            email=email,
            first_name="Usuario",
            last_name="Pendiente",
            is_active=True,
        )

        try:
            db.add(user)
            db.commit()
            db.refresh(user)

        except Exception:
            db.rollback()
            raise

    # Un perfil desactivado no puede utilizar la aplicación.
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="El usuario se encuentra desactivado.",
        )

    return user
