from http.client import HTTPException
import re
from langchain_groq import ChatGroq
from dotenv import load_dotenv
from app.models.answer_with_justification import AnswerWithJustification
import os
import json

load_dotenv()
groq_api_key = os.getenv('GROQ_API_KEY')

llm = ChatGroq(
    groq_api_key=groq_api_key,
    model="mixtral-8x7b-32768",
    temperature=0,
    max_tokens=None,
    timeout=None,
    max_retries=2,
)

async def answer_question(question: str):
    """
    Given a question, return the answer to the question
    """
    prompt = f"""You are an AI assistant doctor who specializes in all kinds of health-related problems. 
    Answer the following question based on your best knowledge and be specific and accurate. 
    Your response should be in JSON format with 'answer' and 'justification' as the main keys.
    
    Question: {question}
    
    Response format:
    {{
        "answer": "Your detailed answer here",
        "justification": "Your justification or explanation here"
    }}
    """

    try:
        response = llm.invoke(prompt)
        
        # Try to parse the JSON response
        try:
            parsed_response = json.loads(response.content)
            validated_response = AnswerWithJustification(**parsed_response)
            return {
                "raw": response.content,
                "parsed": validated_response.model_dump(),
                "parsing_error": None
            }
        except json.JSONDecodeError as e:
            # If JSON parsing fails, attempt to extract JSON from the response
            json_match = re.search(r'\{.*\}', response.content, re.DOTALL)
            if json_match:
                try:
                    parsed_response = json.loads(json_match.group())
                    validated_response = AnswerWithJustification(**parsed_response)
                    return {
                        "raw": response.content,
                        "parsed": validated_response.model_dump(),
                        "parsing_error": None
                    }
                except (json.JSONDecodeError, ValueError) as e:
                    return {
                        "raw": response.content,
                        "parsed": None,
                        "parsing_error": f"Failed to parse extracted JSON: {str(e)}"
                    }
            else:
                return {
                    "raw": response.content,
                    "parsed": None,
                    "parsing_error": f"Failed to parse JSON and no JSON object found in response: {str(e)}"
                }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")


