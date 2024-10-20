from http.client import HTTPException
import json
from langchain_groq import ChatGroq
from langchain_huggingface import HuggingFaceEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain.chains import create_retrieval_chain
from langchain_chroma import Chroma
from langchain_community.document_loaders import PyPDFDirectoryLoader
from dotenv import load_dotenv
import os
import time
from app.models.user_health import UserHealthProfile
from app.models.suggestion import Suggestion
import re
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

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
        loader = PyPDFDirectoryLoader('../../data')
        docs = loader.load()
        
        # Split documents into chunks
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
        final_documents = text_splitter.split_documents(docs)
        
        # Create Vector Store using ChromaDB
        state.vectors = Chroma.from_documents(final_documents, state.embeddings)
        print("Vector Store DB is ready")


# def get_response(user_health_profile: UserHealthProfile):
#     if state.vectors is None:
#         raise HTTPException(400, "Vectors not initialized. Please initialize embeddings first.")

#     try:
#         system_prompt = '''You are an AI assistant doctor. Based on the user's health profile, provide personalized recommendations for the following 11 topics. Return your response as a JSON object with the following structure:

#         {{
#           "water_intake": {{"title": "", "detail": "", "type": "", "total": null}},
#           "walking_duration": {{"title": "", "detail": "", "type": "", "total": null}},
#           "stretching_time": {{"title": "", "detail": "", "type": "", "total": null}},
#           "stretching_duration": {{"title": "", "detail": "", "type": "", "total": null}},
#           "mindfulness_exercise": {{"title": "", "detail": "", "type": "", "total": null}},
#           "nutrition_tip": {{"title": "", "detail": "", "type": "", "total": null}},
#           "sleep_reminder": {{"title": "", "detail": "", "type": "", "total": null}},
#           "screen_time_break": {{"title": "", "detail": "", "type": "", "total": null}},
#           "special_task": {{"title": "", "detail": "", "type": "", "total": null}},
#           "social_interaction": {{"title": "", "detail": "", "type": "", "total": null}},
#           "posture_reminder": {{"title": "", "detail": "", "type": "", "total": null}}
#         }}

#         Ensure that the JSON is properly formatted without any additional text or line breaks.

#         For each topic:
#         - title: A concise, descriptive title for the task
#         - detail: A brief description or instructions for the task
#         - type: Either "stepwise" (for progress-based tasks) or "regular" (for single-action tasks)
#         - total: The target value for stepwise tasks (null for regular tasks)

#         Tailor your recommendations to the user's health profile, considering factors such as age, gender, weight, height, exercise habits, and any health conditions mentioned.

#         User Health Profile: {context}'''

#         prompt = ChatPromptTemplate.from_messages([
#             ("system", system_prompt),
#             ("human", "Please provide personalized health recommendations based on the given profile. Return your response as a properly formatted JSON object without any additional text.")
#         ])

#         chain = prompt | llm | StrOutputParser()

#         response = chain.invoke({"context": json.dumps(user_health_profile.dict())})
        
#         # Clean up the response
#         cleaned_response = re.sub(r'[\n\r\t]', '', response)
#         cleaned_response = re.sub(r',\s*}', '}', cleaned_response)
        
#         # Extract JSON from the response
#         json_match = re.search(r'\{.*\}', cleaned_response, re.DOTALL)
#         if json_match:
#             json_str = json_match.group()
#         else:
#             raise ValueError("No JSON object found in the response")

#         # Try to parse the JSON response
#         try:
#             parsed_response = json.loads(json_str)
#             # Convert the parsed JSON to a Suggestion object
#             suggestion = Suggestion(**parsed_response)
#             return suggestion
#         except json.JSONDecodeError as e:
#             # If JSON parsing fails, return an error message
#             raise HTTPException(500, f"Failed to parse LLM response: {str(e)}. Raw response: {response}")
        
#     except Exception as e:
#         raise HTTPException(500, f"An error occurred: {str(e)}")


def get_response(user_health_profile: UserHealthProfile):
    if state.vectors is None:
        raise HTTPException(400, "Vectors not initialized. Please initialize embeddings first.")

    try:
        system_prompt = '''You are an AI assistant doctor. Based on the user's health profile and the provided context, provide personalized recommendations for the following 11 topics. Return your response as a JSON object with the following structure:

        {{
          "water_intake": {{"title": "", "detail": "", "type": "", "total": null}},
          "walking_duration": {{"title": "", "detail": "", "type": "", "total": null}},
          "stretching_time": {{"title": "", "detail": "", "type": "", "total": null}},
          "stretching_duration": {{"title": "", "detail": "", "type": "", "total": null}},
          "mindfulness_exercise": {{"title": "", "detail": "", "type": "", "total": null}},
          "nutrition_tip": {{"title": "", "detail": "", "type": "", "total": null}},
          "sleep_reminder": {{"title": "", "detail": "", "type": "", "total": null}},
          "screen_time_break": {{"title": "", "detail": "", "type": "", "total": null}},
          "special_task": {{"title": "", "detail": "", "type": "", "total": null}},
          "social_interaction": {{"title": "", "detail": "", "type": "", "total": null}},
          "posture_reminder": {{"title": "", "detail": "", "type": "", "total": null}}
        }}

        Ensure that the JSON is properly formatted without any additional text or line breaks.

        For each topic:
        - title: A concise, descriptive title for the task
        - detail: A brief description or instructions for the task
        - type: Either "stepwise" (for progress-based tasks) or "regular" (for single-action tasks)
        - total: The target value for stepwise tasks (null for regular tasks)

        Tailor your recommendations to the user's health profile, considering factors such as age, gender, weight, height, exercise habits, and any health conditions mentioned.

        Use the following context to provide more informed and specific recommendations:
        {context}

        User Health Profile: {health_profile}'''

        prompt = ChatPromptTemplate.from_messages([
            ("system", system_prompt),
            ("human", "Please provide personalized health recommendations based on the given profile and context. Return your response as a properly formatted JSON object without any additional text.")
        ])

        # Create a retrieval chain
        retriever = state.vectors.as_retriever()
        retrieval_chain = create_retrieval_chain(retriever, create_stuff_documents_chain(llm, prompt))

        # Invoke the retrieval chain
        response = retrieval_chain.invoke({
            "health_profile": json.dumps(user_health_profile.dict()),
            "input": "Provide personalized health recommendations"
        })
        
        # Extract the answer from the response
        raw_output = response['answer']
        
        # Clean up the response
        cleaned_response = re.sub(r'[\n\r\t]', '', raw_output)
        cleaned_response = re.sub(r',\s*}', '}', cleaned_response)
        
        # Extract JSON from the response
        json_match = re.search(r'\{.*\}', cleaned_response, re.DOTALL)
        if json_match:
            json_str = json_match.group()
        else:
            raise ValueError("No JSON object found in the response")

        # Try to parse the JSON response
        try:
            parsed_response = json.loads(json_str)
            # Convert the parsed JSON to a Suggestion object
            suggestion = Suggestion(**parsed_response)
            return suggestion
        except json.JSONDecodeError as e:
            # If JSON parsing fails, return an error message
            raise HTTPException(500, f"Failed to parse LLM response: {str(e)}. Raw response: {raw_output}")
        
    except Exception as e:
        raise HTTPException(500, f"An error occurred: {str(e)}")