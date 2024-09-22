from http.client import HTTPException
from langchain_groq import ChatGroq
from langchain_huggingface import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate,HumanMessagePromptTemplate, AIMessagePromptTemplate
from langchain.chains import create_retrieval_chain
from langchain_chroma import Chroma
from langchain_community.document_loaders import PyPDFDirectoryLoader
from dotenv import load_dotenv

import os
import time
from app.models.query import QueryRequest,ResponseTemplate,DailyHealthRecommendations

# Load environment variables from .env file
load_dotenv()

# Load Groq API Key
groq_api_key = os.getenv('GROQ_API_KEY')

# Initialize the Groq model with the provided API key and model
llm = ChatGroq(groq_api_key=groq_api_key, model="llama3-70b-8192")


# In-memory state for embeddings and documents
class State:
    vectors = None

state = State()

def vector_embedding():
    """
    Prepares the document embeddings.
    Loads PDF documents, splits them into chunks, and creates document embeddings using ChromaDB.
    """
    if state.vectors is None:
        state.embeddings = HuggingFaceEmbeddings()
        
        # Load documents from the specified directory (update path as needed)
        loader = PyPDFDirectoryLoader("E:\AppsTechnologies\AI\BeMA\\bema-ai-snm\\bema_application_backend\data")
        docs = loader.load()
        
        # Split documents into chunks
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
        final_documents = text_splitter.split_documents(docs)
        
        # Create Vector Store using ChromaDB
        state.vectors = Chroma.from_documents(final_documents, state.embeddings)
        print("Vector Store DB is ready")


async def get_response(query_request: QueryRequest) -> ResponseTemplate:
    """
    Processes the user query and previous answers, returning structured health recommendations.
    """
    if state.vectors is None:
        raise HTTPException(400, "Vectors not initialized. Please initialize embeddings first.")

    try:
        # Define the chat prompt template with both human and AI parts
        prompt = ChatPromptTemplate(
            messages=[
                HumanMessagePromptTemplate.from_template("""
                    You are an AI assistant doctor. Based on the user's previous answers and your medical knowledge, answer the following 10 questions in JSON format:
                    
                    1. Recommend water intake
                    2. Recommend walking duration
                    3. Recommend stretching time
                    4. Recommend stretching duration
                    5. Recommend mindfulness exercise with time duration
                    6. Recommend nutrition tip (e.g., servings of fruits/vegetables)
                    7. Recommend sleep reminder (hours of sleep)
                    8. Recommend screen time break with duration
                    9. Recommend a special task or challenge for today (e.g., avoid sugary snacks)
                    10. Recommend social interaction suggestion (e.g., call or message a friend)
                    
                    User's previous answers:
                    {previous_answers}
                """)
            ]
        )

        # Convert previous_answers list to a string format suitable for display
        previous_answers_str = "\n".join(f"{idx + 1}. {answer}" for idx, answer in enumerate(query_request.previous_answers))

        # Format the prompt with the actual data
        formatted_prompt = prompt.format(previous_answers=previous_answers_str)

        # Create the LLM chain with the formatted chat prompt
        document_chain = create_stuff_documents_chain(llm, formatted_prompt)
        retriever = state.vectors.as_retriever()
        retrieval_chain = create_retrieval_chain(retriever, document_chain)

        # Invoke the chain and get the response
        response = await retrieval_chain.invoke({
            "input": query_request.query,
        })

        # Split response into lines and extract answers
        responses = response['text'].splitlines()

        if len(responses) < 10:
            raise IndexError("The LLM response did not contain enough lines to extract all recommendations.")

        # Extract answers based on the expected format
        recommendations = DailyHealthRecommendations(
            water_intake=responses[0].strip(),
            walking_duration=responses[1].strip(),
            stretching_time=responses[2].strip(),
            mindfulness_exercise=responses[3].strip(),
            nutrition_tip=responses[4].strip(),
            sleep_reminder=responses[5].strip(),
            screen_time_break=responses[6].strip(),
            daily_challenge=responses[7].strip(),
            social_interaction=responses[8].strip(),
            posture_reminder=responses[9].strip(),
        )

        response_template = ResponseTemplate(
            data=recommendations,
            message="Recommendations generated successfully!"
        )

        return response_template

    except IndexError as e:
        raise HTTPException(500, "The LLM response did not contain enough lines to extract all recommendations.") from e
    except Exception as e:
        raise HTTPException(500, f"An error occurred: {str(e)}")
