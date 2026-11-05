"""Registro central de repositorios."""

from app.repositories.space_repository import SportsSpaceRepository
from app.repositories.venue_repository import VenueRepository


__all__ = [
    "VenueRepository",
    "SportsSpaceRepository",
]
