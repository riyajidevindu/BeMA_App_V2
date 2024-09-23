# app/routes/agent.py

from fastapi import APIRouter, HTTPException
from app.models.query import QueryRequest,ResponseTemplate
from app.services.embedding_service import vector_embedding, get_response

router = APIRouter()


@router.post("/query/", response_model=ResponseTemplate)
async def query_agent(request: QueryRequest):
    """
    Processes a user query against the loaded documents and returns structured health recommendations.
    """
    try:
        # Pass the entire request object to get_response
        recommendations = await get_response(request)  # This accepts QueryRequest type
        
        return recommendations  # FastAPI will automatically convert this to JSON
    
    except KeyError as e:
        raise HTTPException(status_code=500, detail=f"KeyError: {str(e)}. Ensure vectors are properly initialized.")
    
    except AttributeError as e:
        raise HTTPException(status_code=500, detail=f"AttributeError: {str(e)}. Ensure vectors and methods are properly initialized.")
    
    except Exception as e:
        # Catch any other exceptions that might arise
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")
