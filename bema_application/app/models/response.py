from pydantic import BaseModel
from bema_application_backend.app.models.suggestion import DailyHealthRecommendations

class ResponseTemplate(BaseModel):
    status: bool = True
    message: str = "Data successfully retrieved!"
    status_code: int = 200
    data: DailyHealthRecommendations