from dotenv import load_dotenv
from models.answer_with_justification import AnswerWithJustification
import os
import json
import requests
import uuid
from langchain_huggingface import HuggingFaceEmbeddings
import chromadb
from chromadb.api.types import EmbeddingFunction, Documents


load_dotenv()
NGROK_URL = os.getenv("NGROK_URL")

PERSIST_DIRECTORY = os.getenv("PERSIST_DIRECTORY", "chroma_db")
EMBEDDING_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"

RAG_COLLECTION_NAME = "rag-chroma"
CHAT_HISTORY_COLLECTION_NAME = "chat-history"

# --- Custom Adapter Class ---
class LangChainEmbeddingAdapter(EmbeddingFunction[Documents]):
    """Adapter to convert LangChain embeddings to ChromaDB format."""
    def __init__(self, langchain_embeddings):
        self.langchain_embeddings = langchain_embeddings
    
    def __call__(self, input: Documents):
        return self.langchain_embeddings.embed_documents(input)

# --- Step 1: Initialize Embeddings and Chroma Client ---
print("Initializing embedding model...")
langchain_embeddings = HuggingFaceEmbeddings(model_name=EMBEDDING_MODEL_NAME)

# Wrap with adapter
print("Creating ChromaDB-compatible embedding function...")
chroma_embedding_function = LangChainEmbeddingAdapter(langchain_embeddings)

# 2. Create the native ChromaDB client
print(f"Initializing ChromaDB client for directory: {PERSIST_DIRECTORY}")
client = chromadb.PersistentClient(path=PERSIST_DIRECTORY)

# 3. Get or create collection with adapted embedding function
print(f"Getting or creating collection: '{CHAT_HISTORY_COLLECTION_NAME}'")
chat_history_collection = client.get_or_create_collection(
    name=CHAT_HISTORY_COLLECTION_NAME,
    embedding_function=chroma_embedding_function
)


def add_to_memory(text: str):
    """Adds a text entry (user query or AI response) to the chat history collection."""
    entry_id = str(uuid.uuid4())
    chat_history_collection.add(
        ids=[entry_id],
        documents=[text]
    )
    print(f"📝 Added to memory: '{text}'")


def get_relevant_history(question: str, k: int = 3) -> str:
    """Retrieves the k most relevant conversation snippets from memory."""
    if chat_history_collection.count() == 0:
        return ""

    results = chat_history_collection.query(
        query_texts=[question],
        n_results=k
    )
    
    retrieved_docs = results.get('documents', [[]])[0]
    
    if not retrieved_docs:
        return ""

    formatted_history = "\n".join(retrieved_docs)
    print(f"🧠 Retrieved history:\n{formatted_history}")
    return formatted_history


def answer_question_with_memory(question: str):
    """
    Answers a question by first retrieving relevant context from chat history,
    then calling the LLM, and finally saving the new exchange to memory.
    """
    
    # 1. Retrieve relevant chat history
    history = get_relevant_history(question)

    # 2. Create a new prompt with the retrieved history
    prompt = f"""You are an AI assistant doctor named BEMA who specializes in all kinds of health-related problems.
    Answer the following question based on the provided conversation history and your best knowledge. Be specific and accurate.
    Your response should be in JSON format with 'answer' and 'justification' as the main keys.

    Conversation History:
    {history}
    
    New Question: {question}
    
    Response format:
    {{
        "answer": "Very Simple answer to the question in text format.",
        "justification": "Your justification or explanation here in text format."
    }}
    """

    # 3. Call the LLM with the new prompt
    print("\n💬 Sending prompt to LLM...")
    try:
        res = requests.post(
            f"{NGROK_URL}/api/generate",
            headers={"Content-Type": "application/json"},
            json={
                "model": "qwen3:8b",
                "prompt": prompt,
                "stream": False,
                "options": {"temperature": 0.2},
                "format": AnswerWithJustification.model_json_schema()
            },
            timeout=60
        )
        res.raise_for_status()
        llm_response_json_str = res.json().get('response', '{}')
        
        # 4. Add the new exchange to memory
        try:
            llm_response_data = json.loads(llm_response_json_str)
            ai_answer = llm_response_data.get("answer", "No answer found.")
            
            add_to_memory(f"User asked: {question}")
            add_to_memory(f"BEMA answered: {ai_answer}")

        except json.JSONDecodeError:
            print("Warning: LLM response was not valid JSON. Storing raw response.")
            add_to_memory(f"User asked: {question}")
            add_to_memory(f"BEMA's raw response: {llm_response_json_str}")

        return json.loads(llm_response_json_str)
        
    except requests.RequestException as e:
        print(f"❌ Error calling Ollama API: {e}")
        return f'{{"error": "Could not get a response from the LLM: {e}"}}'
