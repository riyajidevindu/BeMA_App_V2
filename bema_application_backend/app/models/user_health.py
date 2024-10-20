from pydantic import BaseModel
from typing import Optional

class UserHealthProfile(BaseModel):
    age: int
    allergyType: Optional[str]
    cholesterolTreatmentYears: Optional[int]
    diabetesTreatmentYears: Optional[int]
    disabilityDiscription: Optional[str]
    drinks: bool
    exercises: bool
    familyMedicalHistoryDiscription: Optional[str]
    favoriteExercise: Optional[str]
    gender: str
    glassesPerWeek: Optional[int]
    hadSurgeries: bool
    hasAllergies: bool
    hasCholesterol: bool
    hasDiabetes: bool
    hasDisabilitiesOrSpecialNeeds: bool
    hasFamilyMedicalHistory: bool
    hasHighBloodPressure: bool
    height: float
    heightUnit: str
    highBloodPressureTreatmentYears: Optional[int]
    profession: str
    smokes: bool
    smokingFrequency: Optional[str]
    surgeryType: Optional[str]
    surgeryYear: Optional[int]
    userId: str
    weight: float
    weightUnit: str