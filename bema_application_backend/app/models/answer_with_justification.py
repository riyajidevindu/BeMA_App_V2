from dataclasses import Field
from typing import Optional
from pydantic import BaseModel


class AnswerWithJustification(BaseModel):
    answer: str 
    justification: str 