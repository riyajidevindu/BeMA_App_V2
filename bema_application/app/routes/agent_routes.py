# app/routes/agent.py
from core.db import store_user_suggestions_with_suggestionItems, store_user_health_profile
from fastapi import APIRouter, HTTPException
from models.user_health import UserHealthProfile
from services.agent_service import create_recommendation_workflow
from models.rag_state import RagState
from models.suggestion import Suggestion
from utils.retriever import get_retriever
import os
from dotenv import load_dotenv

load_dotenv()

def get_response(user_health_profile: UserHealthProfile) -> Suggestion:
    """
    Initializes and runs the RAG agent workflow to get health recommendations.
    
    Args:
        user_health_profile (UserHealthProfile): The health profile of the user.
        
    Returns:
        Suggestion: A Pydantic object containing the personalized health suggestions.
        
    Raises:
        Exception: If the vector store is not found or the agent fails to generate a valid response.
    """
    # Path is relative to the root of the project where the main app is run
    PERSIST_DIRECTORY = os.getenv("PERSIST_DIRECTORY", "core/chroma_db")
    
    retriever = get_retriever(persist_directory=PERSIST_DIRECTORY)
    if not retriever:
        raise Exception("Vector store not found. Please ensure it has been created.")

    app = create_recommendation_workflow(retriever)
    
    # Dynamically create the question from the user profile for better context
    question = (
        f"Provide health recommendations for a {user_health_profile.age}-year-old "
        f"{user_health_profile.gender} {user_health_profile.profession}"
    )
    if user_health_profile.hasDisabilitiesOrSpecialNeeds:
        question += f" with {user_health_profile.disabilityDiscription}"
    if user_health_profile.hasFamilyMedicalHistory:
        question += f" and a family history of {user_health_profile.familyMedicalHistoryDiscription}"
    question += "."

    initial_state = RagState(
        health_profile=user_health_profile,
        question=question,
        retries=0
    )
    
    print("\n--- Running RAG Agent Workflow ---")
    final_state_data = app.invoke(initial_state.model_dump())
    final_state = RagState(**final_state_data)

    if isinstance(final_state.generation, Suggestion):
        print("\n--- Workflow Complete: Final Recommendations ---")
        # Store user profile and suggestions in the database
        store_user_health_profile(user_health_profile)
        store_user_suggestions_with_suggestionItems(final_state.health_profile.userId, final_state.generation)
        return final_state.generation
    else:
        error_message = f"Workflow finished with an error or no valid generation. Final state: {final_state.generation}"
        print(f"\n--- {error_message} ---")
        raise Exception(error_message)



router = APIRouter()


@router.post("/agent/")
async def rag_agent(user_health_profile: UserHealthProfile):
    """
    API endpoint to get personalized health recommendations from the RAG agent.
    """
    try:
        response = get_response(user_health_profile)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

