import os
import json
import re
from pydantic import BaseModel
import requests
from langchain_core.vectorstores import VectorStoreRetriever
from langchain_community.tools import BraveSearch
from langgraph.graph import StateGraph, END
from dotenv import load_dotenv
from models.rag_state import RagState
from models.suggestion import Suggestion

load_dotenv()

NGROK_URL = os.getenv("NGROK_URL")
BRAVE_API_KEY = os.getenv("BRAVE_API_KEY")


class RagAgent:
    """Encapsulates the logic for the RAG recommendation agent with a self-correction loop."""

    def __init__(self, retriever: VectorStoreRetriever):
        if not NGROK_URL or not BRAVE_API_KEY:
            raise ValueError("NGROK_URL and BRAVE_API_KEY must be set in your .env file.")
        self.retriever = retriever
        self.web_search_tool = BraveSearch(api_key=BRAVE_API_KEY)
        self.max_retries = 3

    def _call_ollama_llm(self, prompt: str, format: type[BaseModel] = Suggestion) -> str:
        """Helper function to call the Ollama model via ngrok."""
        payload = {
            "model": "qwen3:8b",
            "prompt": prompt,
            "stream": False,
            "options": {"temperature": 0.2},
            "format": format.model_json_schema()
        }
        
        try:
            res = requests.post(
                f"{NGROK_URL}/api/generate",
                headers={"Content-Type": "application/json"},
                json=payload,
                timeout=90 # Increased timeout slightly for complex generation
            )
            print(f"❇️ Ollama API response status: {res}")
            res.raise_for_status()
            
            raw_response = res.json().get('response', '')
            print(f"--- Raw LLM Response ---\n{raw_response}\n--------------------")
            # remove think tags 
            cleaned_response = re.sub(r'<think>.*?</think>', '', raw_response, flags=re.DOTALL).strip()
            return cleaned_response
        except requests.RequestException as e:
            print(f"❌ Error calling Ollama API: {e}")
            return f'{{"error": "Could not get a response from the LLM: {e}"}}'

    def retrieve_context(self, state: RagState) -> dict:
        print("--- Node: Retrieve Context ---")
        question = state.question
        documents = self.retriever.invoke(question)
        context = "\n\n".join([doc.page_content for doc in documents])
        state.context = context
        return {"context": context, "web_context": ""} # Initialize web_context as empty

    def generate(self, state: RagState) -> dict:
        print("--- Node: Generate Recommendations ---")
        prompt = f'''You are an AI assistant doctor. Based on the user's health profile and the provided context, you must generate exactly 11 personalized health recommendations. Your response must be **only** a single, valid JSON object. 
        Do not include any surrounding text, markdown, or explanations. The `total` key within each suggestion must be an **integer**.
            **--- EXAMPLE ---**
            **INPUT:**
            * **User Health Profile:**
                {{
                    "age": 45,
                    "gender": "Male",
                    "weight": 85,
                    "weightUnit": "kg",
                    "height": 175,
                    "heightUnit": "cm",
                    "profession": "Software Developer",
                    "hasHighBloodPressure": true,
                    "highBloodPressureTreatmentYears": 5,
                    "hasCholesterol": true,
                    "cholesterolTreatmentYears": 3,
                    "exercises": false,
                    "smokes": false,
                    "drinks": true,
                    "glassesPerWeek": "3-5",
                    "hasDiabetes": false,
                    "hasAllergies": false,
                    "hasDisabilitiesOrSpecialNeeds": false,
                    "hadSurgeries": false,
                    "hasFamilyMedicalHistory": true,
                    "familyMedicalHistoryDiscription": "Father had a heart attack at age 55."
                }}
                
            * **Context:**
                * **Internal Documents:** "The user's recent check-up indicates a blood pressure of 145/90 mmHg and an LDL cholesterol level of 160 mg/dL. The user reports a sedentary lifestyle due to their desk job and seeks actionable advice to improve cardiovascular health."
                * **Web Search:** "The American Heart Association recommends at least 150 minutes of moderate-intensity aerobic activity per week and limiting sodium intake to less than 1500 mg per day for individuals with hypertension."

            **REQUIRED JSON OUTPUT:**
            {{
            "water_intake": {{
                "title": "Stay Hydrated for Heart Health",
                "detail": "Drink at least 8 glasses (around 2 liters) of water daily. Proper hydration supports blood circulation and cardiovascular function, which is crucial given your high blood pressure.",
                "type": "diet",
                "total": 8
            }},
            "walking_duration": {{
                "title": "Brisk Walking",
                "detail": "Aim for a 30-minute brisk walk. This helps lower blood pressure, manage cholesterol, and counteracts the effects of your sedentary job. Consistency is key to improving heart health.",
                "type": "exercise",
                "total": 30
            }},
            "stretching_time": {{
                "title": "Morning Stretch",
                "detail": "Start your day with a 10-minute stretching routine focusing on your back, neck, and legs to improve flexibility and reduce stiffness from sitting.",
                "type": "exercise",
                "total": 10
            }},
            "stretching_duration": {{
                "title": "Desk De-Stressing",
                "detail": "Take a 5-minute break every hour to stretch your neck, shoulders, and wrists at your desk. This helps prevent repetitive strain and improves blood flow.",
                "type": "exercise",
                "total": 5
            }},
            "mindfulness_exercise": {{
                "title": "Mindful Breathing",
                "detail": "Practice 5 minutes of deep, mindful breathing. This can help lower stress levels, which is a known contributor to high blood pressure. Inhale for 4 seconds, hold for 4, and exhale for 6.",
                "type": "wellness",
                "total": 5
            }},
            "nutrition_tip": {{
                "title": "Reduce Sodium Intake",
                "detail": "To manage your hypertension, limit sodium to under 1,500 mg per day. Check food labels, avoid processed foods, and cook with herbs and spices instead of salt.",
                "type": "diet",
                "total": 1500
            }},
            "sleep_reminder": {{
                "title": "Prioritize Sleep",
                "detail": "Aim for 7-8 hours of quality sleep per night. Consistent sleep is vital for blood pressure regulation and overall cardiovascular recovery. The minimum target is 7 hours.",
                "type": "wellness",
                "total": 7
            }},
            "screen_time_break": {{
                "title": "20-20-20 Rule",
                "detail": "As a Software Developer, it's important to protect your eyes. Every 20 minutes, look at something 20 feet away for at least 20 seconds to reduce eye strain.",
                "type": "wellness",
                "total": 20
            }},
            "special_task": {{
                "title": "Monitor Blood Pressure",
                "detail": "Check and log your blood pressure at home at least twice a week. This data is valuable for you and your doctor to track your progress and adjust treatment if needed.",
                "type": "monitoring",
                "total": 2
            }},
            "social_interaction": {{
                "title": "Connect with Family",
                "detail": "Given your family history of heart disease, have an open conversation with your family about shared health risks and support each other in making healthier lifestyle choices.",
                "type": "social",
                "total": 1
            }},
            "posture_reminder": {{
                "title": "Ergonomic Check",
                "detail": "Ensure your desk setup is ergonomic. Your monitor should be at eye level and your chair should support your lower back to prevent posture-related issues. Perform one thorough check today.",
                "type": "wellness",
                "total": 1
            }}
            }}
            **--- END EXAMPLE ---**
        '''
        generation = self._call_ollama_llm(prompt)
        state.generation = generation
        return {"generation": generation, "retries": state.retries + 1}

    def validate_json(self, state: RagState) -> str:
        print("--- Node: Validate JSON Structure ---")
        generation_str = state.generation
        if state.retries >= self.max_retries:
            print("Validation Error: Max retries reached.")
            return "end_error"
        try:
            parsed_json = json.loads(generation_str)
            Suggestion(**parsed_json) # Validate against the Pydantic model
            print("Validation Success: JSON structure is valid.")
            return "parse_generation" # Proceed to parse the content
        except (json.JSONDecodeError, ValueError) as e:
            print(f"Validation Error: {e}. Retrying generation...")
            error_message = f"You previously failed to generate a valid JSON. Error: {e}. Please correct the output and ensure it is a single, complete JSON object with all 11 required keys."
            # Note: The state update happens in the graph, we just provide the error message
            return "retry"

    # def grade_generation(self, state: RagState) -> dict:
    #     """
    #     Grades the generated answer. If it's generic or insufficient for complex cases,
    #     it triggers a web search. Otherwise, it ends the process.
    #     """
    #     print("--- Node: Grade Generation Content ---")
    #     profile = state.health_profile
    #     question = state.question
    #     generation = state.generation # This is the validated JSON string

    #     # If the user has no complex conditions, the RAG output is likely sufficient.
    #     if not profile.hasFamilyMedicalHistory and not profile.hasDisabilitiesOrSpecialNeeds:
    #         print("Decision: User profile is simple. Generation is sufficient.")
    #         state.decision = "sufficient"
    #         return {"decision": "sufficient"}

    #     prompt = f"""You are an expert medical reviewer. Your task is to assess an AI-generated health recommendation based on a user's profile.
        
    #     User's Request: "{question}"
    #     User's Health Profile: {profile.model_dump_json(indent=2)}
    #     Generated Recommendation (JSON): {generation}

    #     Critique the recommendation:
    #     1. Does the recommendation seem too generic?
    #     2. Does it adequately address the specific complexities mentioned in the user's profile (like family history or special needs)?
    #     3. Could the recommendation be significantly improved with more current or specific information from the web?

    #     Based on your critique, decide if a web search is necessary.
    #     Importantly, Respond with ONLY one of the following two words: 'search_web' or 'sufficient'.
    #     """
    #     decision = self._call_ollama_llm(prompt,format=Critique).strip().lower()
    #     parsed_decision = Critique(**json.loads(decision))
    #     print("Grade generation State:", state)
    #     if "search_web" in parsed_decision.critique:
    #         print("Decision: Generation is insufficient. Proceeding to web search.")
    #         state.decision = "search_web"
    #         return {"decision": "search_web"}
    #     else:
    #         print("Decision: Generation is sufficient.")
    #         state.decision = "sufficient"
    #         return {"decision": "sufficient"}

    def web_search(self, state: RagState) -> dict:
        print("--- Node: Web Search (Direct API Call) ---")
        question = state.question
        print(f"Performing web search for: {question}")
        
        search_url = "https://api.search.brave.com/res/v1/web/search"
        headers = {
            "Accept": "application/json",
            "X-Subscription-Token": BRAVE_API_KEY
        }
        params = {"q": question}
        
        search_results_context = ""
        try:
            response = requests.get(search_url, headers=headers, params=params, timeout=30)
            response.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)
            
            data = response.json()
            results = data.get("web", {}).get("results", [])
            
            if not results:
                print("⚠️ Web search returned no results.")
                return {"web_context": ""}
            
            # Process the top 5 results to create a context string
            context_list = []
            for i, result in enumerate(results[:5]):
                title = result.get("title", "No Title")
                description = result.get("description", "No Description Available.")
                context_list.append(f"Result {i+1}: {title}\nSummary: {description}")
            
            search_results_context = "\n\n".join(context_list)
            
        except requests.RequestException as e:
            print(f"❌ Error during web search: {e}")
            # Return empty context on error to allow the agent to proceed without it
            return {"web_context": ""}

        state.web_context = search_results_context
        return {"web_context": search_results_context}

    def parse_generation(self, state: RagState) -> dict:
        print("--- Node: Parse Final Generation ---")
        generation_str = state.generation
        parsed_json = json.loads(generation_str)
        suggestion_obj = Suggestion(**parsed_json)
        state.generation = suggestion_obj
        return {"generation": suggestion_obj}


def create_recommendation_workflow(retriever: VectorStoreRetriever):
    """Builds and compiles the LangGraph workflow for the RAG agent."""
    agent = RagAgent(retriever)
    
    workflow = StateGraph(RagState)
    
    # Add nodes to the graph
    workflow.add_node("retrieve_context", agent.retrieve_context)
    workflow.add_node("generate", agent.generate)
    workflow.add_node("web_search", agent.web_search)
    workflow.add_node("parse_generation", agent.parse_generation)

    # Set the entry point
    workflow.set_entry_point("retrieve_context")
    
    # Define the graph edges
    workflow.add_edge("retrieve_context", "web_search")
    workflow.add_edge("web_search", "generate")
    
    # Conditional edge for JSON validation after generation
    workflow.add_conditional_edges(
        "generate",
        agent.validate_json,
        {
            "retry": "generate",
            "parse_generation": "parse_generation",
            "end_error": END
        }
    )
    workflow.add_edge("parse_generation", END)
    
    return workflow.compile()