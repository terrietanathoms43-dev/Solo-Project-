"""Simple tests run before any container image is published."""
import pytest

from app import app


@pytest.fixture()
def client():
    app.config.update(TESTING=True)
    with app.test_client() as test_client:
        yield test_client


def test_home_returns_welcome(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.json["service"] == "tidewater-tours"


def test_list_tours_returns_three(client):
    response = client.get("/tours")
    assert response.status_code == 200
    assert response.json["count"] == 3
    assert len(response.json["tours"]) == 3


def test_get_existing_tour(client):
    response = client.get("/tours/1")
    assert response.status_code == 200
    assert response.json["id"] == 1


def test_unknown_tour_is_404(client):
    response = client.get("/tours/999")
    assert response.status_code == 404
    assert response.json["error"] == "Tour not found"


def test_health_check_returns_status_and_version(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json["status"] == "ok"
    assert response.json["service"] == "tidewater-tours"
    assert "version" in response.json
