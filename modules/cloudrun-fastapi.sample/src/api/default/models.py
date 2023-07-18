"""Common models for payload and response."""
from loreal.fastapi_commons.models import OutputModel
from pydantic import BaseModel, Field  # pylint: disable=no-name-in-module
from pydantic.config import Extra  # pylint: disable=no-name-in-module


# -- inputs
# payload
class InputModel(BaseModel, extra=Extra.forbid):  # prevent unwanted fields in input
    """Input model."""

    name: str = Field(
        description="Someone to say hello to.",
        example="toto",
    )


# -- output models
class MessageModel(BaseModel):
    """Message model."""

    message: str = Field(
        description="Message to say hello to people.",
    )


MessageOutputModel = OutputModel[MessageModel]
