"""Registro central de esquemas Pydantic."""

from app.schemas.device_token import DeviceTokenCreate, DeviceTokenRead
from app.schemas.reservation import (
    AvailabilitySlot,
    ReservationCreate,
    ReservationRead,
    SpaceAvailabilityRead,
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
    "AvailabilitySlot",
    "SpaceAvailabilityRead",
    "DeviceTokenCreate",
    "DeviceTokenRead",
]
