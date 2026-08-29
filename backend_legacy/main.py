"""
SlangFeed Backend - FastAPI Server
Main entry point for the backend API.
Implements LLM-based dynamic content generation with Few-Shot Prompting + Random Theme.
"""
import json
import os
import random
import time
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from config import HOST, PORT, SLANG_SAMPLE_COUNT, THEMES
from dataset_sampler import sample_slangs, get_dataset_stats, get_all_slangs
from prompt_builder import build_system_prompt, build_user_prompt
from groq_client import generate_batch
from slangguru import chat as slangguru_chat, GREETING_MESSAGE

app = FastAPI(title="SlangFeed API", version="3.0.0")

# CORS - allow Godot to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load fallback posts
FALLBACK_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "fallback_posts.json")
_fallback_posts = None


def load_fallback_posts():
    global _fallback_posts
    if _fallback_posts is None:
        try:
            with open(FALLBACK_PATH, "r", encoding="utf-8") as f:
                _fallback_posts = json.load(f)
                print(f"[MAIN] Fallback loaded from: {FALLBACK_PATH} ({len(_fallback_posts.get('posts', []))} posts)")
        except FileNotFoundError:
            alt_path = os.path.join(os.path.dirname(__file__), "fallback_posts.json")
            try:
                with open(alt_path, "r", encoding="utf-8") as f:
                    _fallback_posts = json.load(f)
                    print(f"[MAIN] Fallback loaded from alt path: {alt_path}")
            except FileNotFoundError:
                print(f"[MAIN] WARNING: No fallback file found!")
                _fallback_posts = {"posts": [], "adaptation_note": "fallback"}
    return _fallback_posts


class PerformanceEntry(BaseModel):
    slang: str
    correct: bool


class SessionContext(BaseModel):
    total_answered: int = 0
    total_correct: int = 0
    recent_performance: list[PerformanceEntry] = []
    slangs_already_used: list[str] = []
    follower_count: int = 0


class BatchRequest(BaseModel):
    session_context: SessionContext


class ChatRequest(BaseModel):
    message: str


@app.post("/generate_batch")
async def generate_batch_endpoint(request: BatchRequest):
    """
    Generate a batch of 5 posts using LLM + Few-Shot Prompting + Random Theme.
    """
    request_start = time.time()
    ctx = request.session_context

    print("\n" + "#" * 70)
    print(f"[MAIN] ########## /generate_batch REQUEST RECEIVED ##########")
    print(f"[MAIN] Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"[MAIN] Session context:")
    print(f"[MAIN]   total_answered: {ctx.total_answered}")
    print(f"[MAIN]   total_correct: {ctx.total_correct}")
    print(f"[MAIN]   follower_count: {ctx.follower_count}")
    print(f"[MAIN]   slangs_already_used ({len(ctx.slangs_already_used)}): {ctx.slangs_already_used}")
    print(f"[MAIN]   recent_performance: {[(p.slang, p.correct) for p in ctx.recent_performance[-5:]]}")

    # Step 1: Pick a random theme
    theme = random.choice(THEMES)
    print(f"[MAIN] Step 1 - Selected theme: '{theme}'")

    # Step 2: Sample random slangs from dataset (excluding already-used)
    print(f"[MAIN] Step 2 - Sampling slangs (n={SLANG_SAMPLE_COUNT})...")
    sample_start = time.time()
    sampled_slangs = sample_slangs(
        n=SLANG_SAMPLE_COUNT,
        exclude_list=ctx.slangs_already_used,
    )
    sample_elapsed = time.time() - sample_start
    print(f"[MAIN] Sampling took: {sample_elapsed:.3f}s")
    print(f"[MAIN] Sampled {len(sampled_slangs)} slangs:")
    for s in sampled_slangs:
        print(f"[MAIN]   - {s['Slang']}")

    # Step 3: Build prompts (few-shot + theme + slang data)
    print(f"[MAIN] Step 3 - Building prompts...")
    prompt_start = time.time()
    system_prompt = build_system_prompt()

    session_context_dict = {
        "total_answered": ctx.total_answered,
        "total_correct": ctx.total_correct,
        "recent_performance": [
            {"slang": p.slang, "correct": p.correct}
            for p in ctx.recent_performance[-5:]
        ],
        "slangs_already_used": ctx.slangs_already_used,
        "follower_count": ctx.follower_count,
    }

    user_prompt = build_user_prompt(session_context_dict, sampled_slangs, theme)
    prompt_elapsed = time.time() - prompt_start
    print(f"[MAIN] Prompt build took: {prompt_elapsed:.3f}s")
    print(f"[MAIN] System prompt: {len(system_prompt)} chars")
    print(f"[MAIN] User prompt: {len(user_prompt)} chars")

    # Step 4: Call LLM
    print(f"[MAIN] Step 4 - Calling LLM...")
    llm_start = time.time()
    result = generate_batch(system_prompt, user_prompt)
    llm_elapsed = time.time() - llm_start
    print(f"[MAIN] LLM call took: {llm_elapsed:.2f}s")

    if result is not None:
        result["is_fallback"] = False
        result["theme"] = theme
        total_elapsed = time.time() - request_start
        print(f"[MAIN] SUCCESS! Returning LLM-generated posts")
        print(f"[MAIN] Total request time: {total_elapsed:.2f}s")
        print(f"[MAIN] Posts: {[p.get('slang_tested', '?') for p in result.get('posts', [])]}")
        print("#" * 70 + "\n")
        return result

    # Step 5: Fallback
    total_elapsed = time.time() - request_start
    print(f"[MAIN] FAILED! LLM returned None after {llm_elapsed:.2f}s")
    print(f"[MAIN] Step 5 - Using fallback posts...")
    fallback = load_fallback_posts()

    available = [
        p for p in fallback.get("posts", [])
        if p.get("slang_tested", "").lower() not in [s.lower() for s in ctx.slangs_already_used]
    ]

    if len(available) >= 5:
        selected = available[:5]
    elif len(available) > 0:
        selected = available
    else:
        selected = fallback.get("posts", [])[:5]

    print(f"[MAIN] Returning {len(selected)} fallback posts")
    print(f"[MAIN] Total request time: {total_elapsed:.2f}s")
    print("#" * 70 + "\n")

    return {
        "adaptation_note": "Fallback posts - LLM unavailable",
        "posts": selected,
        "is_fallback": True,
        "theme": "mixed",
    }


# ===== SLANGGURU CHAT ENDPOINTS =====

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    """
    SlangGuru interactive chat with dual-LLM verification.
    """
    result = slangguru_chat(request.message)
    return result


@app.get("/chat/greeting")
async def chat_greeting():
    """Get SlangGuru's greeting message."""
    return {"greeting": GREETING_MESSAGE}


@app.get("/health")
async def health_check():
    stats = get_dataset_stats()
    return {
        "status": "ok",
        "message": "SlangFeed API is running (LLM + Few-Shot + Random Theme)",
        "dataset_stats": stats,
    }


@app.on_event("startup")
async def startup_event():
    print("\n" + "=" * 70)
    print("[MAIN] SlangFeed API v3.0 Starting...")
    print(f"[MAIN] Host: {HOST}  Port: {PORT}")
    stats = get_dataset_stats()
    print(f"[MAIN] Dataset: {stats}")
    print(f"[MAIN] Themes available: {len(THEMES)}")
    print(f"[MAIN] Slang sample count: {SLANG_SAMPLE_COUNT}")
    load_fallback_posts()
    print("=" * 70 + "\n")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=HOST, port=PORT)
