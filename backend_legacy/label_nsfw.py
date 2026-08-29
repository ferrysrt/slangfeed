"""
NSFW Labeler — Pre-labels all slangs in the dataset using LLM.
Adds 'is_nsfw' column to the CSV (true/false).

Usage: python label_nsfw.py
Output: Overwrites final_slang_cleaned_v3.csv with new 'is_nsfw' column.

Rate limiting: 10s pause every 50 calls to stay within Groq RPM limits.
"""
import pandas as pd
import os
import time
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

# === Config ===
CSV_PATH = os.path.join(os.path.dirname(__file__), "data", "final_slang_cleaned_v3.csv")
MODEL = "openai/gpt-oss-120b"  # Strong model for accurate labeling
BATCH_PAUSE_EVERY = 50          # Pause every N calls
BATCH_PAUSE_SECONDS = 10        # Seconds to pause

client = Groq(api_key=os.getenv("GROQ_API_KEY"))

SYSTEM_PROMPT = """You are a content moderator. Your job is to classify internet slang terms as NSFW or safe.

A slang is NSFW if it:
- Has explicit sexual meaning (e.g. "DTF", "bussy", "smash" in sexual context)
- Refers to genitalia or sexual acts
- Is a vulgar/crude term that would be inappropriate in an educational game for teenagers

A slang is NOT NSFW if it:
- Is general internet slang (e.g. "GOAT", "no cap", "salty")
- Has mild connotation but is commonly used in everyday social media (e.g. "sus", "simp")
- Is about emotions, lifestyle, or general culture

Respond with ONLY "true" or "false". Nothing else.
true = NSFW (inappropriate)
false = safe (appropriate)

Examples:
- "DTF" (Down To F***) → true
- "GOAT" (Greatest Of All Time) → false
- "pussy" (vulgar term) → true
- "salty" (being upset) → false
- "bussy" (vulgar slang) → true
- "ghosting" (cutting off communication) → false"""


def classify_slang(slang: str, definition: str) -> str:
    """Call LLM to classify a single slang as NSFW or not."""
    try:
        response = client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": f'Slang: "{slang}"\nDefinition: "{definition}"\n\nIs this NSFW? Reply only "true" or "false".'},
            ],
            temperature=0,
            max_tokens=200,  # Reasoning models need more tokens
        )
        choice = response.choices[0]
        # Get content, fallback to reasoning field for reasoning models
        answer = ""
        if choice.message.content:
            answer = choice.message.content.strip().lower()
        elif hasattr(choice.message, 'reasoning') and choice.message.reasoning:
            # Reasoning model: extract true/false from reasoning text
            reasoning = choice.message.reasoning.strip().lower()
            if "true" in reasoning.split()[-5:] or reasoning.endswith("true"):
                answer = "true"
            elif "false" in reasoning.split()[-5:] or reasoning.endswith("false"):
                answer = "false"
        # Normalize response
        if "true" in answer:
            return "true"
        elif "false" in answer:
            return "false"
        else:
            print(f"  ⚠️ Unexpected response for '{slang}': '{answer}' → defaulting to false")
            return "false"
    except Exception as e:
        print(f"  ❌ Error for '{slang}': {e} → defaulting to false")
        return "false"


def main():
    print(f"Loading dataset: {CSV_PATH}")
    df = pd.read_csv(CSV_PATH)
    df.columns = [c.strip() for c in df.columns]
    total = len(df)
    print(f"Total slangs: {total}\n")

    # Check if is_nsfw column already exists
    if "is_nsfw" in df.columns:
        already_labeled = df["is_nsfw"].notna().sum()
        print(f"Column 'is_nsfw' already exists ({already_labeled} labeled)")
        remaining = df[df["is_nsfw"].isna()].index.tolist()
        if not remaining:
            print("All slangs already labeled! Nothing to do.")
            return
        print(f"Resuming from {len(remaining)} unlabeled slangs...\n")
    else:
        df["is_nsfw"] = None
        remaining = list(range(total))
        print("Created new 'is_nsfw' column\n")

    nsfw_count = 0
    start_time = time.time()

    for i, idx in enumerate(remaining):
        row = df.iloc[idx]
        slang = str(row["Slang"]).strip()
        definition = str(row["Definition"]).strip()

        result = classify_slang(slang, definition)
        df.at[idx, "is_nsfw"] = result

        marker = "🔴 NSFW" if result == "true" else "✅ safe"
        if result == "true":
            nsfw_count += 1

        progress = i + 1
        print(f"[{progress}/{len(remaining)}] {slang:<30} → {marker}")

        # Rate limiting: pause every N calls
        if progress % BATCH_PAUSE_EVERY == 0 and progress < len(remaining):
            print(f"\n⏸️  Pausing {BATCH_PAUSE_SECONDS}s (rate limit)... {progress}/{len(remaining)} done\n")
            # Save progress so far
            df.to_csv(CSV_PATH, index=False)
            print(f"💾 Progress saved to CSV")
            time.sleep(BATCH_PAUSE_SECONDS)

    # Final save
    df.to_csv(CSV_PATH, index=False)

    elapsed = time.time() - start_time
    total_nsfw = (df["is_nsfw"] == "true").sum()
    total_safe = (df["is_nsfw"] == "false").sum()

    print(f"\n{'='*50}")
    print(f"✅ DONE in {elapsed:.1f}s")
    print(f"   Total:  {total}")
    print(f"   Safe:   {total_safe}")
    print(f"   NSFW:   {total_nsfw}")
    print(f"   Saved:  {CSV_PATH}")
    print(f"{'='*50}")


if __name__ == "__main__":
    main()
