#!/usr/bin/env python
"""
Joke Agent using AutoGen
A simple multi-agent system that tells and evaluates jokes using AutoGen.
"""

import asyncio
import os
import random
from dotenv import load_dotenv

from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.ui import Console
from autogen_ext.models.openai import AzureOpenAIChatCompletionClient
from autogen_core import CancellationToken
from autogen_core.tools import FunctionTool

# Load environment variables
load_dotenv()


def get_random_joke_topic() -> str:
    """Returns a random topic for jokes."""
    topics = [
        "programadores", "inteligencia artificial", "gatos",
        "café", "reuniones de trabajo", "bugs en el código",
        "machine learning", "la nube", "Python vs JavaScript",
        "Stack Overflow", "commits de Git", "debugging"
    ]
    return f"Tema seleccionado: {random.choice(topics)}"


def rate_joke(joke: str) -> str:
    """Rates a joke from 1 to 10."""
    rating = random.randint(5, 10)
    emojis = "😄" * (rating // 2)
    return f"Calificación: {rating}/10 {emojis}"


async def main():
    # Configure Azure OpenAI
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    api_key = os.getenv("AZURE_OPENAI_API_KEY")
    deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")
    
    if not endpoint or not api_key:
        print("Error: Configure AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_API_KEY")
        print("You can also set AZURE_OPENAI_DEPLOYMENT_NAME (default: gpt-4o)")
        return
    
    # Create the model client
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=deployment,
        model=deployment,
        api_version="2024-06-01",
        azure_endpoint=endpoint,
        api_key=api_key,
    )
    
    # Create tools
    topic_tool = FunctionTool(
        get_random_joke_topic,
        description="Obtiene un tema aleatorio para contar un chiste"
    )
    
    rate_tool = FunctionTool(
        rate_joke,
        description="Califica un chiste del 1 al 10"
    )
    
    # Create the comedian agent
    comedian_agent = AssistantAgent(
        name="Comediante",
        model_client=model_client,
        tools=[topic_tool],
        system_message="""
        Eres un comediante profesional que cuenta chistes muy divertidos en español.
        
        Cuando te pidan un chiste:
        1. Usa la herramienta get_random_joke_topic para obtener un tema
        2. Cuenta un chiste creativo y divertido sobre ese tema
        3. Termina tu turno para que el crítico evalúe tu chiste
        
        Sé creativo, usa juegos de palabras y humor inteligente.
        """,
    )
    
    # Create the critic agent
    critic_agent = AssistantAgent(
        name="Critico",
        model_client=model_client,
        tools=[rate_tool],
        system_message="""
        Eres un crítico de comedia que evalúa chistes.
        
        Cuando el comediante cuente un chiste:
        1. Usa la herramienta rate_joke para dar una calificación
        2. Proporciona una breve crítica constructiva
        3. Di "APROBADO" si el chiste merece más de 7 puntos, o "TERMINADO" para finalizar
        
        Sé justo pero divertido en tus críticas.
        """,
    )
    
    # Create termination condition
    termination = TextMentionTermination("TERMINADO")
    
    # Create the team with round-robin chat
    team = RoundRobinGroupChat(
        participants=[comedian_agent, critic_agent],
        termination_condition=termination,
        max_turns=6,
    )
    
    print("🎭 Sistema de Chistes con AutoGen")
    print("=" * 50)
    print("Agentes: Comediante 🎤 y Crítico 📝")
    print("Escribe 'salir' para terminar\n")
    
    while True:
        user_input = input("Tú: ").strip()
        
        if user_input.lower() in ['salir', 'exit', 'quit']:
            print("¡Hasta luego! 👋")
            break
        
        if not user_input:
            continue
        
        print("\n" + "=" * 50)
        
        # Run the team conversation
        result = await Console(
            team.run_stream(task=user_input, cancellation_token=CancellationToken())
        )
        
        # Reset the team for the next round
        await team.reset()
        
        print("=" * 50 + "\n")


if __name__ == "__main__":
    asyncio.run(main())
