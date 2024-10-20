from typing import Optional
from pydantic import BaseModel

class SuggestionItem(BaseModel):
    title: str
    detail: str
    type: str
    total: Optional[int] = None