from typing import TypedDict
from pydantic import BaseModel
from models.suggestion import Suggestion
from models.user_health import UserHealthProfile
from typing import Optional, Union

class RagState(BaseModel):
    """Represents the state of our RAG workflow."""
    health_profile: UserHealthProfile
    question: str
    retries: int
    context: Optional[str] = None
    web_context: Optional[str] = None
    generation: Optional[Union[str, Suggestion]] = None
    validation_error: Optional[str] = None
    decision: Optional[str] = None