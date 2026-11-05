"""
Configuración de SQLAlchemy para conectarse con PostgreSQL.
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.core.config import settings


# Crea el motor de conexión.
# pool_pre_ping comprueba que la conexión siga activa antes de utilizarla.
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
)


# Crea las sesiones utilizadas para hacer consultas.
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


class Base(DeclarativeBase):
    """
    Clase principal de los modelos de SQLAlchemy.

    Los modelos User, Venue, SportsSpace y Reservation
    deberán heredar de esta clase.
    """

    pass


def get_db():
    """
    Abre una sesión para cada solicitud y la cierra al terminar.
    """

    database = SessionLocal()

    try:
        yield database
    finally:
        database.close()
