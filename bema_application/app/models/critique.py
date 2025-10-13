from pydantic import BaseModel

from typing import Literal

class Critique(BaseModel):
    critique: Literal["search_web", "sufficient"]