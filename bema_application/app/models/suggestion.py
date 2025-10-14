from pydantic import BaseModel
from models.suggestion_item import SuggestionItem

class Suggestion(BaseModel):
    water_intake: SuggestionItem
    walking_duration: SuggestionItem
    stretching_time: SuggestionItem
    stretching_duration: SuggestionItem
    mindfulness_exercise: SuggestionItem
    nutrition_tip: SuggestionItem
    sleep_reminder: SuggestionItem
    screen_time_break: SuggestionItem
    special_task: SuggestionItem
    social_interaction: SuggestionItem
    posture_reminder: SuggestionItem