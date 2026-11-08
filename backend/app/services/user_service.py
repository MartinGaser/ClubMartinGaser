"""
Servicio de usuarios.

Esta capa contiene las reglas de negocio relacionadas
con la consulta y edición del perfil autenticado.
"""

from datetime import date

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserUpdate


class UserService:
    """Reglas de negocio correspondientes al perfil."""

    @staticmethod
    def update_profile(
        db: Session,
        current_user: User,
        user_data: UserUpdate,
    ) -> User:
        """
        Actualiza el perfil del usuario autenticado.

        Solo permite modificar nombre, apellido y fecha
        de nacimiento. El correo permanece bloqueado.
        """

        changes = user_data.model_dump(
            exclude_unset=True,
        )

        # Evita ejecutar un UPDATE sin datos.
        if not changes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "Debe enviar al menos un campo "
                    "para actualizar."
                ),
            )

        # Valida el nombre después de quitar espacios.
        if user_data.first_name is not None:
            clean_first_name = user_data.first_name.strip()

            if len(clean_first_name) < 2:
                raise HTTPException(
                    status_code=(
                        status.HTTP_422_UNPROCESSABLE_ENTITY
                    ),
                    detail=(
                        "El nombre debe contener al menos "
                        "2 caracteres."
                    ),
                )

        # Valida el apellido después de quitar espacios.
        if user_data.last_name is not None:
            clean_last_name = user_data.last_name.strip()

            if len(clean_last_name) < 2:
                raise HTTPException(
                    status_code=(
                        status.HTTP_422_UNPROCESSABLE_ENTITY
                    ),
                    detail=(
                        "El apellido debe contener al menos "
                        "2 caracteres."
                    ),
                )

        # La fecha de nacimiento no puede estar en el futuro.
        if (
            user_data.birth_date is not None
            and user_data.birth_date > date.today()
        ):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "La fecha de nacimiento no puede "
                    "estar en el futuro."
                ),
            )

        try:
            updated_user = UserRepository.update(
                db=db,
                user=current_user,
                user_data=user_data,
            )

            # Confirma definitivamente el cambio.
            db.commit()

            # Actualiza nuevamente el objeto después del commit.
            db.refresh(updated_user)

            return updated_user

        except HTTPException:
            # Conserva las respuestas HTTP generadas por validaciones.
            raise

        except Exception:
            # Revierte cualquier cambio si PostgreSQL genera un error.
            db.rollback()
            raise
