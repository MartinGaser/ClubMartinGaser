"""
Registro central de esquemas Pydantic.

Permite importar los esquemas desde app.schemas.
"""

from app.schemas.device_token import DeviceTokenCreate, DeviceTokenRead
from app.schemas.reservation import (
    ReservationCancel,
    ReservationCreate,
    ReservationRead,
)
from app.schemas.sports_space import (
    SportsSpaceCreate,
    SportsSpaceRead,
    SportsSpaceUpdate,
)
from app.schemas.user import UserCreate, UserRead, UserUpdate
from app.schemas.venue import VenueCreate, VenueRead, VenueUpdate


__all__ = [
    "UserCreate",
    "UserUpdate",
    "UserRead",
    "VenueCreate",
    "VenueUpdate",
    "VenueRead",
    "SportsSpaceCreate",
    "SportsSpaceUpdate",
    "SportsSpaceRead",
    "ReservationCreate",
    "ReservationRead",
    "ReservationCancel",
    "DeviceTokenCreate",
    "DeviceTokenRead",
]
