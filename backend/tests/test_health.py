"""
Prueba automática para comprobar el estado de la API.
"""

from fastapi.testclient import TestClient

from app.main import app


# Permite probar FastAPI sin ejecutar un servidor externo.
client = TestClient(app)


def test_health_check() -> None:
    """Comprueba que /health responda correctamente."""

    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}
