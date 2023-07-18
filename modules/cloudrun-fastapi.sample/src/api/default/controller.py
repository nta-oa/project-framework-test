"""Default API."""
import logging

from fastapi import APIRouter
from starlette.responses import JSONResponse

from loreal.fastapi_commons.formatter import json_response
from loreal.fastapi_commons.models import ErrorModel

from .models import InputModel, MessageOutputModel
from .service import DefaultService
from .validators import validate_consistency_with_payload, DefaultValidator

LOGGER = logging.getLogger(__name__)


def build(
    router: APIRouter, service: DefaultService, validator: DefaultValidator
) -> None:
    """Build a dummy controller that says hello using various routes."""
    LOGGER.debug("Create %s controller", __name__)

    @router.get(
        "",
        response_model=MessageOutputModel,
        responses={
            500: {
                "description": "Server error",
                "model": ErrorModel,
            },
        },
    )
    async def say_hello_with_query_param(name: str | None = "World") -> JSONResponse:
        """Say hello to the world or to someone if provided."""
        LOGGER.debug("controller.get: say hello %s", name)
        # process
        people = service.upper(name)
        return json_response({"message": f"Hello {people}!"}, 200)

    @router.post(
        "",
        response_model=MessageOutputModel,
        responses={
            400: {
                "description": "Bad Request",
                "model": ErrorModel,
            },
            500: {
                "description": "Server error",
                "model": ErrorModel,
            },
        },
    )
    async def say_hello_with_body(payload: InputModel) -> JSONResponse:
        """Say hello to the person provided in payload."""
        name = payload.name
        LOGGER.debug("controller.post: say hello to %s", name)
        # validate
        validator.validate_names(name)
        # process
        people = service.upper(name)
        return json_response({"message": f"Hello {people}!"}, 200)

    @router.get(
        "/name/{name}",
        response_model=MessageOutputModel,
        responses={
            500: {
                "description": "Server error",
                "model": ErrorModel,
            },
        },
    )
    async def say_hello_with_path_param(name: str) -> JSONResponse:
        """Say hello to someone."""
        LOGGER.debug("controller.get: say hello to %s", name)
        # validate
        validator.validate_names(name)
        # process
        people = service.upper(name)
        return json_response({"message": f"Hello {people}!"}, 200)

    @router.post(
        "/name/{name}",
        response_model=MessageOutputModel,
        responses={
            400: {
                "description": "Bad Request",
                "model": ErrorModel,
            },
            500: {
                "description": "Server error",
                "model": ErrorModel,
            },
        },
    )
    async def say_hello_with_body_and_path_param(
        name: str, payload: InputModel
    ) -> JSONResponse:
        """Say hello to the person provided in payload."""
        LOGGER.debug("controller.put: say hello to %s", name)
        # validate
        validate_consistency_with_payload(name, payload.name)

        validator.validate_names(name)
        # process
        people = service.upper(payload.name)
        return json_response({"message": f"Hello {people}!"}, 200)
