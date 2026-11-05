"""Registro central de servicios."""

from app.services.space_service import SportsSpaceService
from app.services.venue_service import VenueService


__all__ = [
    "VenueService",
    "SportsSpaceService",
]
