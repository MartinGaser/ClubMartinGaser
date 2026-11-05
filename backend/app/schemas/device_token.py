"""
Esquemas para registrar dispositivos en Firebase Cloud Messaging.
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class DeviceTokenCreate(BaseModel):
    """Token que envía la aplicación Flutter al iniciar sesión."""

    token: str = Field(
        min_length=10,
        max_length=512,
    )


class DeviceTokenRead(BaseModel):
    """Información del dispositivo devuelta por la API."""

    id: int
    user_id: int
    token: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
