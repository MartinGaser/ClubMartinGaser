"""
Acceso a datos de tokens Firebase Cloud Messaging.
"""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.device_token import DeviceToken


class DeviceTokenRepository:
    """Consultas y modificaciones de tokens FCM."""

    @staticmethod
    def get_by_token(
        db: Session,
        token: str,
    ) -> DeviceToken | None:
        statement = select(DeviceToken).where(
            DeviceToken.token == token
        )

        return db.scalar(statement)

    @staticmethod
    def get_active_by_user_id(
        db: Session,
        user_id: int,
    ) -> list[DeviceToken]:
        statement = select(DeviceToken).where(
            DeviceToken.user_id == user_id,
            DeviceToken.is_active.is_(True),
        )

        return list(db.scalars(statement).all())

    @staticmethod
    def create_or_update(
        db: Session,
        user_id: int,
        token: str,
    ) -> DeviceToken:
        device_token = DeviceTokenRepository.get_by_token(
            db=db,
            token=token,
        )

        if device_token is None:
            device_token = DeviceToken(
                user_id=user_id,
                token=token,
                is_active=True,
            )
        else:
            device_token.user_id = user_id
            device_token.is_active = True

        db.add(device_token)
        db.flush()
        db.refresh(device_token)

        return device_token

    @staticmethod
    def deactivate(
        db: Session,
        device_token: DeviceToken,
    ) -> None:
        """Desactiva un token que Firebase ya no reconoce."""

        device_token.is_active = False
        db.add(device_token)
        db.flush()
