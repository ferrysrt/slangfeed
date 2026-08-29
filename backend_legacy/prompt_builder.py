"""
Prompt Builder — constructs system and user prompts for LLM batch generation.
Implements few-shot prompting, dataset context injection, and random theme support.
"""
import json
import random
from config import FEW_SHOT_COUNT

# ============================================================
# Few-shot examples (high-quality reference posts for the LLM)
# ============================================================
FEW_SHOT_EXAMPLES = [
    {
        "post_id": 1,
        "author": {
            "username": "@midnightcoder",
            "display_name": "Alex Chen"
        },
        "content": "Interview went so well today, the manager said I'll hear back by Friday. Lowkey nervous but I think I ate that 🔥",
        "likes": 1243,
        "comments_count": 24,
        "timestamp": "3h ago",
        "filler_comments": [
            {"user": "@sarah_k", "text": "you got this!! 💪"},
            {"user": "@devjosh", "text": "let's gooo 🎉"},
            {"user": "@maya.writes", "text": "manifesting for you ✨"}
        ],
        "question_comment": {
            "user": "@newbie_netizen",
            "text": "what does 'ate that' mean here? 🤔"
        },
        "slang_tested": "ate that",
        "options": [
            "A. Actually ate food during the interview",
            "B. Performed exceptionally well",
            "C. Was very nervous and stressed",
            "D. Made a mistake but recovered"
        ],
        "correct_answer": "B",
        "explanation": "'Ate that' means someone performed exceptionally well or nailed something.",
        "correct_response": {
            "user": "@newbie_netizen",
            "text": "ohh so it's like saying they killed it! thanks! 😊"
        },
        "wrong_response": {
            "corrector_user": "@slang_guru",
            "corrector_text": "not quite! 'ate that' means they performed really well, like they totally nailed it 💅"
        }
    },
    {
        "post_id": 2,
        "author": {
            "username": "@campus_chronicles",
            "display_name": "Aisha Patel"
        },
        "content": "My professor showed up to lecture in a full suit and sneakers. No cap that fit was fire 🔥👟",
        "likes": 4521,
        "comments_count": 35,
        "timestamp": "2h ago",
        "filler_comments": [
            {"user": "@fashion_forward", "text": "professors with drip >> 😂"},
            {"user": "@study_buddy", "text": "iconic behavior honestly"},
            {"user": "@campus_style", "text": "need to know what sneakers those were 👀"}
        ],
        "question_comment": {
            "user": "@new_here",
            "text": "what does 'no cap' mean? 🤔"
        },
        "slang_tested": "no cap",
        "options": [
            "A. Without wearing a hat",
            "B. Without any money",
            "C. For real; not lying",
            "D. Without permission"
        ],
        "correct_answer": "C",
        "explanation": "'No cap' means 'for real' or 'I'm not lying.' 'Cap' means a lie, so 'no cap' = no lie.",
        "correct_response": {
            "user": "@new_here",
            "text": "ooh so it's like saying 'I'm being serious'! got it, thanks! 😊"
        },
        "wrong_response": {
            "corrector_user": "@slang_sensei",
            "corrector_text": "'no cap' means 'for real' or 'I'm not lying' — nothing to do with hats 😂"
        }
    },
    {
        "post_id": 3,
        "author": {
            "username": "@foodie_mike",
            "display_name": "Mike Thompson"
        },
        "content": "Made homemade ramen from scratch today and oh my god this is bussin fr fr 🍜✨",
        "likes": 3421,
        "comments_count": 31,
        "timestamp": "5h ago",
        "filler_comments": [
            {"user": "@chef_anna", "text": "drop the recipe!! 🙏"},
            {"user": "@hungryhippo", "text": "this looks incredible omg"},
            {"user": "@noodlelover", "text": "I need this in my life rn 😍"}
        ],
        "question_comment": {
            "user": "@confused_carl",
            "text": "what does 'bussin' mean? never heard that before 🤔"
        },
        "slang_tested": "bussin",
        "options": [
            "A. Traveling by bus",
            "B. Looking messy or unorganized",
            "C. Extremely good, especially food",
            "D. Being very busy"
        ],
        "correct_answer": "C",
        "explanation": "'Bussin' means something is extremely good, especially used for delicious food.",
        "correct_response": {
            "user": "@confused_carl",
            "text": "ohh so it's like saying it's really delicious! got it, thanks! 😄"
        },
        "wrong_response": {
            "corrector_user": "@word_wizard",
            "corrector_text": "nah, 'bussin' means something is extremely good, mostly used for food that's really delicious 🍕"
        }
    },
]


def build_system_prompt() -> str:
    """Build the system prompt with few-shot examples embedded."""

    # Select few-shot examples
    examples = FEW_SHOT_EXAMPLES[:FEW_SHOT_COUNT]
    examples_json = json.dumps(examples, indent=2)

    return f"""You are a content generator for an Instagram-like social media simulation game called SlangFeed. Your job is to generate realistic Instagram posts that naturally contain internet slang.

RULES:
1. Generate exactly 5 Instagram posts per request.
2. Each post must feel like a real Instagram post — natural, casual, relatable.
3. Each post must contain ONE specific internet slang term that a "confused user" will ask about in the comments.
4. The slang MUST be used naturally in the post content — not forced or out of place.
5. You MUST ONLY use slangs from the provided "retrieved_slangs" list. Do NOT invent new slangs.
6. Use the provided Definition and Origin/Context for each slang to ensure accuracy.
7. Each post needs:
   - A realistic username and display name
   - Natural post content using the target slang
   - Realistic like count (500-10000) and comment count (5-50)
   - A realistic timestamp (1h ago, 3h ago, 5h ago, etc.)
   - 3 filler comments that react naturally to the post
   - 1 question comment from a confused user asking what the slang means
   - 4 multiple choice options (A, B, C, D) where only one is correct
   - The correct answer letter
   - A brief explanation of the slang
   - A response for when the player answers correctly (the confused user thanks them)
   - A response for when the player answers wrong (another user corrects them)

8. WRONG OPTIONS must be plausible but clearly incorrect. They should not be obviously absurd.
9. NEVER use the same slang twice in the batch.
10. All content must be SFW (safe for work). No profanity, no NSFW content, no hate speech.
11. All posts in this batch must follow the given THEME to make the feed feel cohesive.

REFERENCE EXAMPLES:
Below are {FEW_SHOT_COUNT} high-quality example posts. Follow their format, tone, and quality closely:

{examples_json}

OUTPUT FORMAT:
You MUST respond with ONLY a valid JSON object (no markdown, no explanation, no code blocks). The JSON must follow this exact structure:

{{
  "adaptation_note": "Brief note about theme and slangs used",
  "posts": [
    {{
      "post_id": 1,
      "author": {{
        "username": "@example_user",
        "display_name": "Display Name"
      }},
      "content": "Post content with slang naturally used...",
      "likes": 2847,
      "comments_count": 14,
      "timestamp": "2h ago",
      "filler_comments": [
        {{"user": "@user1", "text": "comment text"}},
        {{"user": "@user2", "text": "comment text"}},
        {{"user": "@user3", "text": "comment text"}}
      ],
      "question_comment": {{
        "user": "@curious_user",
        "text": "what does 'slang_term' mean here? 🤔"
      }},
      "slang_tested": "slang_term",
      "options": [
        "A. Option text",
        "B. Option text",
        "C. Option text",
        "D. Option text"
      ],
      "correct_answer": "B",
      "explanation": "Brief explanation of the slang",
      "correct_response": {{
        "user": "@curious_user",
        "text": "ohh that makes sense! thanks!! 😊"
      }},
      "wrong_response": {{
        "corrector_user": "@slang_expert",
        "corrector_text": "not quite — 'slang_term' actually means..."
      }}
    }}
  ]
}}

IMPORTANT: Respond with ONLY the JSON. No markdown code blocks, no extra text."""


def build_user_prompt(
    session_context: dict,
    retrieved_slangs: list[dict],
    theme: str,
) -> str:
    """
    Build the user prompt with sampled slangs and random theme.

    Args:
        session_context: Player's current session data
        retrieved_slangs: Slangs randomly sampled from the curated dataset
        theme: The randomly chosen theme for this batch
    """
    # Format retrieved slangs for clarity
    formatted_slangs = []
    for s in retrieved_slangs:
        formatted_slangs.append({
            "slang": s.get("Slang", ""),
            "definition": s.get("Definition", ""),
            "origin_context": s.get("Origin/Context", ""),
        })

    prompt_data = {
        "theme": theme,
        "session_context": session_context,
        "retrieved_slangs": formatted_slangs,
    }

    return f"""Generate 5 Instagram posts for the SlangFeed game.

THEME FOR THIS BATCH: "{theme}"
All 5 posts should be set in the world of "{theme}" — the stories, scenarios, and situations should relate to this topic.

SLANGS TO USE (you MUST use exactly 5 from this list):
{json.dumps(formatted_slangs, indent=2)}

IMPORTANT — SLANG ≠ THEME:
The slangs above may NOT be directly related to the theme "{theme}" — that's intentional!
Your job is to CREATIVELY weave each slang into a {theme}-related scenario.
Examples of this cross-context usage:
- Slang "AFK" + Theme "Food": "Left my pasta boiling and went AFK... came back to a kitchen disaster 😭🍝"
- Slang "cook" + Theme "Gaming": "Our mid laner really cooked that entire team in the finals 🔥🎮"
- Slang "ghosting" + Theme "Work": "My coworker ghosted the entire team meeting, classic Monday move 👻💼"

SESSION CONTEXT (for reference, do NOT include in output):
{json.dumps(session_context, indent=2)}

INSTRUCTIONS:
- Pick exactly 5 slangs from the list above.
- Use each slang's definition to ensure the meaning is CORRECT in your post.
- The POST CONTENT (story/scenario) must follow the theme "{theme}".
- The SLANG can be from any domain — just make it fit naturally in the themed post.
- Craft natural Instagram posts where the slang fits organically.
- Make the question_comment feel like a genuinely confused follower.
- Ensure all 4 options are plausible — wrong ones should be believable but incorrect.

Remember: Output ONLY valid JSON, no markdown, no extra text."""

