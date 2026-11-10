"""
Servicio de dispositivos Firebase Cloud Messaging.
"""

from sqlalchemy.orm import Session

from app.models.device_token import DeviceToken
from app.models.user import User
from app.repositories.device_token_repository import (
    DeviceTokenRepository,
)


class DeviceTokenService:
    """Reglas para registrar tokens FCM."""

    @staticmethod
    def register(
        db: Session,
        current_user: User,
        token: str,
    ) -> DeviceToken:
        clean_token = token.strip()

        try:
            device_token = (
                DeviceTokenRepository.create_or_update(
                    db=db,
                    user_id=current_user.id,
                    token=clean_token,
                )
            )

            db.commit()
            db.refresh(device_token)

            return device_token

        except Exception:
            db.rollback()
            raise
