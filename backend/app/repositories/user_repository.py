"""
Repositorio de usuarios.

Esta capa contiene las consultas y modificaciones directas
sobre la tabla users de PostgreSQL.
"""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.user import UserUpdate


class UserRepository:
    """Operaciones de acceso a datos relacionadas con usuarios."""

    @staticmethod
    def get_by_id(
        db: Session,
        user_id: int,
    ) -> User | None:
        """Busca un usuario mediante su identificador interno."""

        return db.get(User, user_id)

    @staticmethod
    def get_by_firebase_uid(
        db: Session,
        firebase_uid: str,
    ) -> User | None:
        """Busca un usuario mediante el uid generado por Firebase."""

        statement = select(User).where(
            User.firebase_uid == firebase_uid
        )

        return db.scalar(statement)

    @staticmethod
    def get_by_email(
        db: Session,
        email: str,
    ) -> User | None:
        """Busca un usuario mediante su correo electrónico."""

        statement = select(User).where(
            User.email.ilike(email.strip())
        )

        return db.scalar(statement)

    @staticmethod
    def update(
        db: Session,
        user: User,
        user_data: UserUpdate,
    ) -> User:
        """
        Modifica solamente los campos enviados por el cliente.

        El correo y firebase_uid no forman parte de UserUpdate,
        por lo tanto no pueden modificarse desde este método.
        """

        changes = user_data.model_dump(
            exclude_unset=True,
        )

        for field_name, field_value in changes.items():
            # Elimina espacios sobrantes en nombre y apellido.
            if isinstance(field_value, str):
                field_value = field_value.strip()

            setattr(
                user,
                field_name,
                field_value,
            )

        db.add(user)

        # Envía el UPDATE a PostgreSQL sin cerrar la transacción.
        db.flush()

        # Recupera los valores actualizados, incluido updated_at.
        db.refresh(user)

        return user
