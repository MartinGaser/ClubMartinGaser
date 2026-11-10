"""
Job programado para procesar los recordatorios de reservas.

Ejecución manual:
python -m app.jobs.send_reservation_reminders
"""

from app.core.database import SessionLocal
from app.services.notification_service import NotificationService


def main() -> None:
    """Procesa los recordatorios pendientes."""

    db = SessionLocal()

    try:
        summary = NotificationService.process_reservation_reminders(
            db=db,
        )

        print("Procesamiento de recordatorios completado:")
        print(summary)

    except Exception as error:
        db.rollback()
        print("No se pudieron procesar los recordatorios:")
        print(f"{type(error).__name__}: {error}")
        raise

    finally:
        db.close()


if __name__ == "__main__":
    main()
