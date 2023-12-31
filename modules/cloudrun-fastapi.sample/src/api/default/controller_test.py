"""Default controller UT."""
# pylint: disable=invalid-name  # function names
from unittest.mock import create_autospec

import pytest
from fastapi.testclient import TestClient

from . import controller
from .service import DefaultService
from .validators import DefaultValidator


# -- fixtures
@pytest.fixture(name="mock_service")
def fix_mock_service():
    """Set up service fixture."""
    mock_service = create_autospec(DefaultService)
    mock_service.upper = lambda x: x.upper()
    yield mock_service


@pytest.fixture(autouse=True)
def fix_controller(app, mock_service):
    """Build the controller filled with mocked dependencies."""
    app.add_controller(
        "/say-hello",
        controller.build,
        service=mock_service,
        validator=create_autospec(DefaultValidator),
    )


# -- test functions
# /say-hello
@pytest.mark.parametrize(
    "name",
    [None, "Jimi", "Hendrix"],
)
def test_get_ok(app, name):
    """Test that GET returns (...)."""
    # GIVEN
    expected_name = name.upper() if name else "WORLD"
    with TestClient(app) as client:
        # WHEN
        response = client.get("/say-hello" + (f"?{name=!s}" if name else ""))
        # THEN
        assert response.status_code == 200
        assert "Content-Type" in response.headers
        assert response.headers.get("Content-Type") == "application/json"
        response_json = response.json()
        assert response_json["data"] == {"message": f"Hello {expected_name}!"}


@pytest.mark.parametrize(
    "name",
    ["Jimi", "Hendrix"],
)
def test_post_ok(app, name):
    """Test that POST returns (...)."""
    # GIVEN
    expected_name = name.upper()
    with TestClient(app) as client:
        # WHEN
        response = client.post("/say-hello", json={"name": name})
        # THEN
        assert response.status_code == 200
        assert "Content-Type" in response.headers
        assert response.headers.get("Content-Type") == "application/json"
        response_json = response.json()
        assert response_json["data"] == {"message": f"Hello {expected_name}!"}


@pytest.mark.parametrize(
    "name",
    ["Jimi", "Hendrix"],
)
def test_post_error_bad_payload(app, name):
    """Test that POST raises BadRequest."""
    # GIVEN
    with TestClient(app) as client:
        # WHEN
        response = client.post("/say-hello", json={"not_name": name})
        # THEN
        assert response.status_code == 400
        assert "Content-Type" in response.headers
        assert response.headers.get("Content-Type") == "application/json"


# /say-hello/name/{resource_id}
def test_get_name_ok(app):
    """Test that GET returns (...)."""
    # GIVEN
    with TestClient(app) as client:
        # WHEN
        response = client.get("/say-hello/name/toto")
        # THEN
        assert response.status_code == 200
        assert "Content-Type" in response.headers
        assert response.headers.get("Content-Type") == "application/json"
        response_json = response.json()
        assert response_json["data"] == {"message": "Hello TOTO!"}


def test_post_name_ok(app):
    """Test that PUT returns (...)."""
    # GIVEN
    with TestClient(app) as client:
        # WHEN
        response = client.post("/say-hello/name/toto", json={"name": "toto"})
        # THEN
        assert response.status_code == 200
        assert "Content-Type" in response.headers
        assert response.headers.get("Content-Type") == "application/json"
        response_json = response.json()
        assert response_json["data"] == {"message": "Hello TOTO!"}


def test_post_name_error_when_incoherence(app):
    """Test that PUT raises BadRequest when inputs are incoherent."""
    with TestClient(app) as client:
        # WHEN
        response = client.post("/say-hello/name/toto", json={"name": "TATA"})
        # THEN
        assert response.status_code == 400
        assert "Content-Type" in response.headers
        assert response.headers.get("Content-Type") == "application/json"
