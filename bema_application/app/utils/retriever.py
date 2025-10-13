import os
from typing import List
from langchain_community.document_loaders import WebBaseLoader, PyMuPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from langchain_core.vectorstores import VectorStoreRetriever
from functools import lru_cache

# --- NEW: Define paths using environment variables with sane defaults ---
# This is the path INSIDE the container where the volume will be mounted.
PERSIST_DIRECTORY = os.getenv("PERSIST_DIRECTORY", "core/chroma_db")
# This is the path INSIDE the container where your PDF data will be.
DATA_DIRECTORY = os.getenv("DATA_DIRECTORY", "data")
VECTORSTORE_HOST = os.getenv("VECTORSTORE_HOST", "localhost")
VECTORSTORE_PORT = os.getenv("VECTORSTORE_PORT", "8000")


def create_vector_store(
    urls: List[str],
    pdf_paths: List[str],
    embedding_model_name: str = "sentence-transformers/all-MiniLM-L6-v2",
    chunk_size: int = 1000,
    chunk_overlap: int = 200,
    persist_directory: str = PERSIST_DIRECTORY, # Use the global var
    collection_name: str = "rag-chroma"
) -> bool:
    """
    Loads documents, creates embeddings, and persists a new vector store.
    """
    print("--- Creating New Vector Store ---")
    all_docs = []

    # 1. Load from Web URLs
    if urls:
        print(f"Loading {len(urls)} document(s) from web URLs...")
        # ... (no changes in this block)
        for url in urls:
            try:
                loader = WebBaseLoader(url)
                loaded_docs = loader.load()
                all_docs.extend(loaded_docs)
                print(f"  Successfully loaded: {url}")
            except Exception as e:
                print(f"  Failed to load URL {url}: {e}")

    # 2. Load from Local PDFs
    if pdf_paths:
        print(f"\nLoading {len(pdf_paths)} document(s) from local PDF files...")
        # ... (no changes in this block)
        for pdf_path in pdf_paths:
            if not os.path.exists(pdf_path):
                print(f"  Warning: File not found at {pdf_path}, skipping.")
                continue
            try:
                loader = PyMuPDFLoader(pdf_path)
                loaded_docs = loader.load()
                all_docs.extend(loaded_docs)
                print(f"  Successfully loaded: {pdf_path}")
            except Exception as e:
                print(f"  Failed to load PDF {pdf_path}: {e}")
    
    if not all_docs:
        print("\nNo documents were loaded. Exiting vector store creation.")
        return False

    # 3. Split Documents into Chunks
    print(f"\nSplitting {len(all_docs)} loaded documents into chunks...")
    text_splitter = RecursiveCharacterTextSplitter.from_tiktoken_encoder(
        chunk_size=chunk_size, chunk_overlap=chunk_overlap
    )
    doc_splits = text_splitter.split_documents(all_docs)
    print(f"  Created {len(doc_splits)} document chunks.")

    # 4. Initialize Embedding Model
    print(f"\nInitializing embedding model: {embedding_model_name}...")
    embeddings = HuggingFaceEmbeddings(model_name=embedding_model_name)

    # 5. Create and Persist Vector Store
    print(f"\nCreating and persisting new vector store in '{persist_directory}'...")
    Chroma.from_documents(
        documents=doc_splits,
        embedding=embeddings,
        persist_directory=persist_directory,
        collection_name=collection_name,
    )
    print("  Vector store created and saved successfully.")
    return True


@lru_cache(maxsize=1)
def get_retriever(
    persist_directory: str = PERSIST_DIRECTORY, # Use the global var
    embedding_model_name: str = "sentence-transformers/all-MiniLM-L6-v2",
    collection_name: str = "rag-chroma"
) -> VectorStoreRetriever:
    """
    Loads an existing vector store from disk and returns a retriever.
    """
    print("--- Loading Retriever from Existing Vector Store ---")

    if not os.path.exists(persist_directory):
        print(f"Error: Persist directory '{persist_directory}' not found.")
        return None

    # ... (rest of the function is unchanged)
    print(f"\nInitializing embedding model: {embedding_model_name}...")
    embeddings = HuggingFaceEmbeddings(model_name=embedding_model_name)

    print(f"\nLoading existing vector store from '{persist_directory}'...")
    vectorstore = Chroma(
        collection_name=collection_name,
        persist_directory=persist_directory,
        embedding_function=embeddings
    )
    print("Vector store loaded successfully.")
    
    retriever = vectorstore.as_retriever()
    print("--- Retriever is ready. ---")
    return retriever

def check_and_create_vector_store():
    """Checks if the vector store exists, creates it if not."""
    print("\n---  Checking for Vector Store (ChromaDB) ---")
    if not os.path.exists(PERSIST_DIRECTORY) or not os.listdir(PERSIST_DIRECTORY):
        print(f"Vector store not found in '{PERSIST_DIRECTORY}'. Creating a new one.")
        
        URLS_TO_SCRAPE = [
            "https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/",
            "https://a2a-protocol.org/latest/",
        ]
        
        pdf_filenames = [
            "alzheimers_dementia.pdf", "home_care.pdf", "Daily_routine_DOC.pdf",
            "Life_Behavior_Monitoring_App_User_Responses.pdf", "LifestyleDiseasesEnglishFolder.pdf",
        ]
        
        # Create full paths
        LOCAL_PDF_PATHS = [os.path.join(DATA_DIRECTORY, fname) for fname in pdf_filenames]

        create_vector_store(urls=URLS_TO_SCRAPE, pdf_paths=LOCAL_PDF_PATHS)
    else:
        print(" ✅ Vector store already exists. Skipping creation.")



# --- Example Usage ---
# if __name__ == "__main__":
    
#     # Check if the vector store needs to be created
#     if not os.path.exists(PERSIST_DIRECTORY) or not os.listdir(PERSIST_DIRECTORY):
#         print(f"Vector store not found in '{PERSIST_DIRECTORY}'. Creating a new one.")
        
#         URLS_TO_SCRAPE = [
#             "https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/",
#             "https://a2a-protocol.org/latest/",
#             "https://a2a-protocol.org/latest/topics/what-is-a2a/",
#         ]
        
#         # --- NEW: Construct PDF paths dynamically ---
#         # List just the filenames. The script will look for them in DATA_DIRECTORY.
#         pdf_filenames = [
#             "alzheimers_dementia.pdf",
#             "home_care.pdf",
#             "Daily_routine_DOC.pdf",
#             "Life_Behavior_Monitoring_App_User_Responses.pdf",
#             "LifestyleDiseasesEnglishFolder.pdf",
#         ]
        
#         # Create full paths by joining the data directory and the filenames
#         LOCAL_PDF_PATHS = [os.path.join(DATA_DIRECTORY, fname) for fname in pdf_filenames]

#         create_vector_store(
#             urls=URLS_TO_SCRAPE,
#             pdf_paths=LOCAL_PDF_PATHS,
#         )

#     # --- Get the retriever ---
#     retriever = get_retriever()

#     if retriever:
#         print("\n--- Retriever is ready to be used for your RAG application. ---")