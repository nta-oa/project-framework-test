"""Common configuration for API tests.

Please do not modify this file, or at your own risk.
"""
from unittest.mock import create_autospec

import pytest
from fastapi import FastAPI
from google.cloud import error_reporting
from loreal.fastapi_commons.app_builder import BTDPFastAPI

from helpers.constants import (
    API_VERSION,
    API_TITLE,
    API_DESCRIPTION,
)


# -- fixtures
@pytest.fixture(name="app")
def app_fixture() -> FastAPI:
    """Set up testing FastAPI app."""

    fastapi_app = BTDPFastAPI(
        title=API_TITLE,
        description=API_DESCRIPTION,
        version=API_VERSION,
        error_reporting_client=create_autospec(error_reporting.Client),
    )

    yield fastapi_app
