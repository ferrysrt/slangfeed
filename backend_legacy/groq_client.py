"""
Groq Client - handles LLM API calls and response parsing
"""
import json
import re
import time
import traceback
from groq import Groq
from config import GROQ_API_KEY, GROQ_MODEL, TEMPERATURE, MAX_TOKENS


print("=" * 60)
print("[GROQ_CLIENT] Initializing...")
print(f"[GROQ_CLIENT] Model: {GROQ_MODEL}")
print(f"[GROQ_CLIENT] Temperature: {TEMPERATURE}")
print(f"[GROQ_CLIENT] Max tokens: {MAX_TOKENS}")
print(f"[GROQ_CLIENT] API Key present: {bool(GROQ_API_KEY)}")
if GROQ_API_KEY:
    print(f"[GROQ_CLIENT] API Key (first 8 chars): {GROQ_API_KEY[:8]}...")
else:
    print("[GROQ_CLIENT] WARNING: NO API KEY SET!")
print("=" * 60)

client = Groq(api_key=GROQ_API_KEY)


def generate_batch(system_prompt: str, user_prompt: str, max_retries: int = 2) -> dict | None:
    """
    Call Groq API and parse the JSON response.
    Retries on JSON parse failure.
    
    Returns parsed dict or None on total failure.
    """
    print("\n" + "=" * 60)
    print("[GROQ] ========== LLM CALL START ==========")
    print(f"[GROQ] Model: {GROQ_MODEL}")
    print(f"[GROQ] System prompt length: {len(system_prompt)} chars")
    print(f"[GROQ] User prompt length: {len(user_prompt)} chars")
    print(f"[GROQ] Max retries: {max_retries}")
    print(f"[GROQ] System prompt (first 500 chars):")
    print(f"  {system_prompt[:500]}")
    print(f"[GROQ] User prompt (first 800 chars):")
    print(f"  {user_prompt[:800]}")
    print("=" * 60)

    for attempt in range(max_retries + 1):
        print(f"\n[GROQ] --- Attempt {attempt + 1}/{max_retries + 1} ---")
        start_time = time.time()
        
        try:
            print(f"[GROQ] Sending request to Groq API...")
            print(f"[GROQ] Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S')}")
            
            response = client.chat.completions.create(
                model=GROQ_MODEL,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=TEMPERATURE,
                max_tokens=MAX_TOKENS,
                response_format={"type": "json_object"}
            )
            
            elapsed = time.time() - start_time
            print(f"[GROQ] Response received!")
            print(f"[GROQ] Response time: {elapsed:.2f} seconds")
            print(f"[GROQ] Model used: {response.model}")
            print(f"[GROQ] Usage - prompt_tokens: {response.usage.prompt_tokens}")
            print(f"[GROQ] Usage - completion_tokens: {response.usage.completion_tokens}")
            print(f"[GROQ] Usage - total_tokens: {response.usage.total_tokens}")
            print(f"[GROQ] Finish reason: {response.choices[0].finish_reason}")
            
            content = response.choices[0].message.content
            print(f"[GROQ] Raw response length: {len(content)} chars")
            print(f"[GROQ] Raw response (first 500 chars):")
            print(f"  {content[:500]}")
            print(f"[GROQ] Raw response (last 200 chars):")
            print(f"  {content[-200:]}")
            
            # Try to parse JSON
            print(f"[GROQ] Parsing JSON...")
            parsed = _parse_json_response(content)
            
            if parsed is None:
                print(f"[GROQ] FAILED: Could not parse JSON from response!")
                print(f"[GROQ] Full raw response:")
                print(content)
                continue
            
            print(f"[GROQ] JSON parsed successfully!")
            print(f"[GROQ] Top-level keys: {list(parsed.keys())}")
            
            # Validate the parsed response
            print(f"[GROQ] Validating batch structure...")
            validation_error = _validate_batch(parsed)
            if validation_error:
                print(f"[GROQ] VALIDATION FAILED: {validation_error}")
                print(f"[GROQ] Parsed data structure:")
                print(f"  {json.dumps(parsed, indent=2)[:1000]}")
                continue
            
            posts = parsed.get("posts", [])
            print(f"[GROQ] VALIDATION PASSED! {len(posts)} posts generated:")
            for i, p in enumerate(posts):
                print(f"  Post {i+1}: slang='{p.get('slang_tested', '?')}' "
                      f"answer={p.get('correct_answer', '?')} "
                      f"author={p.get('author', {}).get('username', '?')}")
            
            print(f"[GROQ] ========== LLM CALL SUCCESS (took {elapsed:.2f}s) ==========\n")
            return parsed
            
        except Exception as e:
            elapsed = time.time() - start_time
            print(f"[GROQ] EXCEPTION after {elapsed:.2f}s!")
            print(f"[GROQ] Error type: {type(e).__name__}")
            print(f"[GROQ] Error message: {str(e)}")
            print(f"[GROQ] Full traceback:")
            traceback.print_exc()
            continue
    
    print(f"\n[GROQ] ========== ALL ATTEMPTS FAILED ==========")
    print(f"[GROQ] Returning None (will trigger fallback)")
    return None


def _parse_json_response(content: str) -> dict | None:
    """Parse JSON from LLM response, handling markdown code blocks."""
    # Remove markdown code blocks if present
    content = content.strip()
    if content.startswith("```"):
        content = re.sub(r"^```(?:json)?\s*", "", content)
        content = re.sub(r"\s*```$", "", content)
    
    try:
        return json.loads(content)
    except json.JSONDecodeError as e:
        print(f"[GROQ] Direct JSON parse failed: {e}")
        # Try to find JSON object in the content
        match = re.search(r"\{.*\}", content, re.DOTALL)
        if match:
            try:
                return json.loads(match.group())
            except json.JSONDecodeError as e2:
                print(f"[GROQ] Regex JSON parse also failed: {e2}")
    
    return None


def _validate_batch(data: dict) -> str | None:
    """
    Validate the batch response has all required fields.
    Auto-fixes minor issues where possible.
    Returns error message or None if valid.
    """
    if "posts" not in data:
        return "Missing 'posts' field"
    
    posts = data["posts"]
    if not isinstance(posts, list):
        return "'posts' is not a list"
    
    if len(posts) < 5:
        return f"Not enough posts: got {len(posts)}, need at least 5"
    
    # If LLM generated more than 5, just trim
    if len(posts) > 5:
        print(f"[GROQ] NOTE: Got {len(posts)} posts, trimming to 5")
        data["posts"] = posts[:5]
        posts = data["posts"]
    
    required_fields = [
        "post_id", "author", "content", "likes", "comments_count",
        "timestamp", "filler_comments", "question_comment",
        "slang_tested", "options", "correct_answer", "explanation",
        "correct_response", "wrong_response"
    ]
    
    for i, post in enumerate(posts):
        for field in required_fields:
            if field not in post:
                return f"Post {i + 1} missing field: {field}"
        
        # Validate author
        if "username" not in post["author"] or "display_name" not in post["author"]:
            return f"Post {i + 1} author missing username or display_name"
        
        # Validate options
        if not isinstance(post["options"], list) or len(post["options"]) != 4:
            return f"Post {i + 1} must have exactly 4 options"
        
        # Validate correct_answer
        if post["correct_answer"] not in ["A", "B", "C", "D"]:
            return f"Post {i + 1} correct_answer must be A, B, C, or D"
        
        # Validate filler_comments (accept 1+)
        if not isinstance(post["filler_comments"], list) or len(post["filler_comments"]) < 1:
            return f"Post {i + 1} needs at least 1 filler comment"
        
        # Validate question_comment
        if "user" not in post["question_comment"] or "text" not in post["question_comment"]:
            return f"Post {i + 1} question_comment missing user or text"
        
        # Validate correct_response
        if "user" not in post["correct_response"] or "text" not in post["correct_response"]:
            return f"Post {i + 1} correct_response missing user or text"
        
        # Validate wrong_response — auto-fix key variations
        wr = post["wrong_response"]
        if isinstance(wr, dict):
            # Fix: some LLMs use "user" instead of "corrector_user"
            if "corrector_user" not in wr and "user" in wr:
                wr["corrector_user"] = wr.pop("user")
                print(f"[GROQ] Auto-fixed wrong_response.user -> corrector_user in post {i+1}")
            if "corrector_text" not in wr and "text" in wr:
                wr["corrector_text"] = wr.pop("text")
                print(f"[GROQ] Auto-fixed wrong_response.text -> corrector_text in post {i+1}")
            
            if "corrector_user" not in wr or "corrector_text" not in wr:
                return f"Post {i + 1} wrong_response missing corrector_user or corrector_text (keys: {list(wr.keys())})"
        else:
            return f"Post {i + 1} wrong_response is not a dict"
    
    # Check for duplicate slangs
    slangs = [p["slang_tested"].lower() for p in posts]
    if len(set(slangs)) != len(slangs):
        return "Duplicate slangs in batch"
    
    return None

