"""
SlangFeed Backend Configuration
"""
import os
from dotenv import load_dotenv

load_dotenv()

# Groq API
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GROQ_MODEL = "openai/gpt-oss-120b"
TEMPERATURE = 0.7
MAX_TOKENS = 4000

# Batch settings
BATCH_SIZE = 5
SLANG_SAMPLE_COUNT = 7  # Number of slangs to sample per batch
FEW_SHOT_COUNT = 2      # Number of example posts in the prompt

# Server
HOST = "0.0.0.0"
PORT = 8000

# Random Themes for post generation
THEMES = [
    "Campus & School Life",
    "Dating & Relationships",
    "Food & Cooking",
    "Gaming & Esports",
    "Work & Career",
    "Music & Entertainment",
    "Fitness & Health",
    "Fashion & Style",
    "Social Media & Internet Culture",
    "Travel & Adventure",
    "Friendship & Social Life",
    "Movies & TV Shows",
    "Daily Life & Struggles",
    "Sports & Athletics",
    "Tech & Gadgets",
]

