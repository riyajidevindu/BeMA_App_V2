from pydantic import BaseModel

class WorkoutPerDay(BaseModel):
    times_per_day: int
    reason_for_the_workout_plan: str


class WorkoutSummary(BaseModel):
    squats : WorkoutPerDay
    pushups : WorkoutPerDay
    plank : WorkoutPerDay