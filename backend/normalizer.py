"""
SlangFeed Pipeline — Normalizer (LLM#1)
Ekstrak kandidat entri slang dari teks hasil scraping -> list dict
{slang, definition, origin_context}. Prompt menyertakan instruksi menolak
entri vulgar/ofensif (FIX #2B: lapisan penyaring pertama).
"""
import json
import os
import re

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
OPENROUTER_MODEL = os.getenv("OPENROUTER_MODEL", "openai/gpt-oss-120b")

SYSTEM_PROMPT = """You are a lexicographer building a dataset of English internet slang for an educational game.
From the provided web page texts, extract slang terms that are:
- Currently in active use on social media (TikTok, Instagram, X, Reddit)
- Safe for a learning context: NO profanity, NO sexual content, NO slurs, NO hate speech — refuse such entries
- Not brand names, not celebrity names, not emojis-only

For each slang, output: slang (lowercase), definition (5+ words, no commas), origin_context (1-2 sentences, no commas).
NEVER invent slang that does not appear in the texts. Output ONLY a JSON array."""


def normalize(raw_texts: list[str]) -> list[dict]:
    import requests

    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        raise RuntimeError("OPENROUTER_API_KEY tidak tersedia")

    combined = "\n\n---\n\n".join(raw_texts)[:60000]  # batasi konteks

    body = {
        "model": OPENROUTER_MODEL,
        "temperature": 0.3,
        "max_tokens": 4000,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"Extract slang entries from these texts:\n\n{combined}"},
        ],
    }
    resp = requests.post(
        OPENROUTER_URL,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json=body,
        timeout=120,
    )
    resp.raise_for_status()
    content = resp.json()["choices"][0]["message"]["content"]

    start, end = content.find("["), content.rfind("]")
    if start == -1 or end == -1 or end <= start:
        print("[NORMALIZER] Tidak ada JSON array di respons LLM#1")
        return []
    try:
        arr = json.loads(content[start:end + 1])
    except json.JSONDecodeError as e:
        print(f"[NORMALIZER] JSON parse gagal: {e}")
        return []

    out = []
    for item in arr:
        if not isinstance(item, dict):
            continue
        slang = _sanitize(str(item.get("slang", "")))
        definition = _sanitize(str(item.get("definition", "")))
        origin = _sanitize(str(item.get("origin_context", "")))
        if slang and definition:
            out.append({"slang": slang, "definition": definition, "origin_context": origin})
    print(f"[NORMALIZER] Kandidat entri: {len(out)}")
    return out


def _sanitize(s: str) -> str:
    """FIX #9: garansi comma-free & quote-free (parser klien cukup split(',')).
    Security: neutralisasi karakter formula-injection CSV (audit fix #2)
    dan strip markdown link/image syntax untuk membatasi prompt injection
    (audit fix #3 — blast radius)."""
    s = str(s)
    # Neutralisasi formula injection: awalan berbahaya diganti dengan apostrof safety
    if s and s[0] in ("=", "+", "-", "@"):
        s = "'" + s
    # Strip markdown links/images [text](url) dan ![alt](url) dari konten web
    s = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", s)
    s = s.replace('"', "").replace(",", " ").replace("\r", " ").replace("\n", " ")
    return re.sub(r"\s+", " ", s).strip()
