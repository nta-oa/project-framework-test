"""User application making up."""


import logging

from fastapi import FastAPI
from google.cloud import error_reporting
from loreal.fastapi_commons.app_builder import BTDPFastAPI
from loreal.fastapi_commons.formatter import get_request_uid
from loreal.helpers.logging import setup_logging
from loreal.helpers.token_validation import SecretTokenPermissionChecker
from loreal.wrappers.sessions import RefreshableOAuth2Session

# Import managers & controllers
from api.default import controller as default_controller
from api.default.service import DefaultService
from api.default.validators import DefaultValidator
from helpers.constants import (
    API_VERSION,
    API_TITLE,
    API_DESCRIPTION,
    APIGEE_SA,
    APIGEE_ACCESS_SECRET_ID,
    API_VERSION_PATH,
)

LOGGER = logging.getLogger(__name__)


def make_app(is_local_runtime: bool = False) -> FastAPI:  # pragma: no cover
    """Set up API blueprint, controllers, services, providers and ORM.

    Returns:
        The API configured blueprint.
    """
    setup_logging(is_local_runtime=is_local_runtime, get_request_uid=get_request_uid)
    LOGGER.info("Creating FastAPI app.")
    app = BTDPFastAPI(
        title=API_TITLE,
        description=API_DESCRIPTION,
        version=API_VERSION,
        error_reporting_client=error_reporting.Client(),
        is_local_runtime=is_local_runtime,
        apigee_sa=APIGEE_SA,
        apigee_permission_checker=SecretTokenPermissionChecker(
            secret_id=APIGEE_ACCESS_SECRET_ID,
        ),
    )

    # Instantiate clients and wrappers
    requester = RefreshableOAuth2Session()

    # Instantiate validators and providers
    default_validator = DefaultValidator(set())

    # Instantiate services
    default_service = DefaultService(
        requester=requester,
    )

    # Build controllers
    app.add_controller(
        "/say-hello",
        default_controller.build,
        service=default_service,
        validator=default_validator,
    )

    # Mount versioned app
    main_app = FastAPI()
    main_app.mount(f"/{API_VERSION_PATH}", app)

    return main_app
