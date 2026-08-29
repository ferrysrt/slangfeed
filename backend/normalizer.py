"""
SlangFeed Pipeline — Normalizer (LLM#1)
Ekstrak kandidat entri slang dari teks hasil scraping -> list dict
{slang, definition, origin_context}. Prompt menyertakan instruksi menolak
entri vulgar/ofensif (FIX #2B: lapisan penyaring pertama).

Catatan teknis (dari debugging run 2026-08-29):
- gpt-oss-120b adalah reasoning model -> reasoning effort "low" agar token
  tidak habis untuk chain-of-thought sebelum JSON selesai.
- Input dibatasi 30k chars; max_tokens 8000.
- Parser tahan JSON terpotong (ambil objek {..} yang lengkap saja).
"""
import json
import os
import re

import requests

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
OPENROUTER_MODEL = os.getenv("OPENROUTER_MODEL", "openai/gpt-oss-120b")
MAX_INPUT_CHARS = 30000
MAX_TOKENS = 8000

SYSTEM_PROMPT = """You are a lexicographer building a dataset of English internet slang for an educational game.
From the provided web page texts, extract slang terms that are:
- Currently in active use on social media (TikTok, Instagram, X, Reddit)
- Safe for a learning context: NO profanity, NO sexual content, NO slurs, NO hate speech — refuse such entries
- Not brand names, not celebrity names, not emojis-only

For each slang, output: slang (lowercase), definition (5+ words, NO commas allowed — rephrase), origin_context (1-2 sentences, NO commas allowed).
NEVER invent slang that does not appear in the texts. Extract at most 30 entries, the most useful ones.
Respond with ONLY a JSON array — no preamble, no explanations, no markdown fences."""


def normalize(raw_texts: list[str]) -> list[dict]:
    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        raise RuntimeError("OPENROUTER_API_KEY tidak tersedia")

    combined = "\n\n---\n\n".join(raw_texts)[:MAX_INPUT_CHARS]
    out = _call_llm(api_key, combined)

    # Retry 1x dengan input setengahnya kalau parse kosong
    if not out and len(combined) > 8000:
        print("[NORMALIZER] Retry dengan input setengah...")
        out = _call_llm(api_key, combined[: len(combined) // 2])

    print(f"[NORMALIZER] Kandidat entri: {len(out)}")
    return out


def _call_llm(api_key: str, combined: str) -> list[dict]:
    body = {
        "model": OPENROUTER_MODEL,
        "temperature": 0.3,
        "max_tokens": MAX_TOKENS,
        "reasoning": {"effort": "low"},  # gpt-oss: hemat token reasoning
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
        timeout=180,
    )
    if resp.status_code != 200:
        print(f"[NORMALIZER] HTTP {resp.status_code}: {resp.text[:300]}")
        return []
    content = resp.json()["choices"][0]["message"]["content"] or ""
    print(f"[NORMALIZER] Respons LLM#1: {len(content)} chars; awal: {content[:120]!r}")

    arr = _extract_entries(content)
    out = []
    for item in arr:
        if not isinstance(item, dict):
            continue
        slang = _sanitize(str(item.get("slang", "")))
        definition = _sanitize(str(item.get("definition", "")))
        origin = _sanitize(str(item.get("origin_context", "")))
        if slang and definition:
            out.append({"slang": slang, "definition": definition, "origin_context": origin})
    return out


def _extract_entries(content: str) -> list:
    """Tahan JSON utuh maupun terpotong: cari array, kalau gak ketemu
    tutup-nya, ambil objek {..} lengkap satu per satu."""
    start = content.find("[")
    if start == -1:
        return []
    end = content.rfind("]")
    candidate = content[start : end + 1] if end > start else content[start:]

    for attempt in (candidate, _close_truncated(candidate)):
        if not attempt:
            continue
        try:
            arr = json.loads(attempt)
            if isinstance(arr, list):
                return arr
        except json.JSONDecodeError:
            continue
    # Terakhir: regex semua objek lengkap
    return _salvage_objects(content)


def _close_truncated(s: str) -> str:
    """JSON terpotong: buang objek terakhir yang tidak lengkap, tutup array."""
    last_brace = s.rfind("}")
    if last_brace == -1:
        return ""
    return s[: last_brace + 1] + "]"


def _salvage_objects(text: str) -> list:
    objs = []
    depth = 0
    start = -1
    for i, ch in enumerate(text):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start != -1:
                try:
                    objs.append(json.loads(text[start : i + 1]))
                except json.JSONDecodeError:
                    pass
                start = -1
    return objs


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
