extends Node
## Config — central configuration autoload (NFR-8: single source of constants).
## Autoloaded as "Config". Sumber: plan1-revisi v2 / SRS v2.0.

# ===== Rantai Provider LLM#2 (proposal Batasan #3 dikembalikan) =====
## Tier 1: Groq LPU  (primary — narasi latensi rendah, 500+ t/s, TTFT kecil)
## Tier 2: OpenRouter (fallback — agregator, model sama gpt-oss-120b)
## Tier 3: fallback.json statis (di api_client, kurasi manual)
## Tiap provider: 1 percobaan + 1 retry; gagal permanen (401/403) langsung ke tier berikut.
const LLM_PROVIDERS := [
	{
		"name": "groq",
		"url": "https://api.groq.com/openai/v1/chat/completions",
		"model": "openai/gpt-oss-120b",
		"key_file": "groq_key.txt",
		"env_var": "GROQ_API_KEY",
	},
	{
		"name": "openrouter",
		"url": "https://openrouter.ai/api/v1/chat/completions",
		"model": "openai/gpt-oss-120b",
		"key_file": "openrouter_key.txt",
		"env_var": "OPENROUTER_API_KEY",
	},
]

const LLM_TIMEOUT_SEC := 10.0        # SRS FR-C4: timeout keras per percobaan
const LLM_MAX_TOKENS := 2000
const LLM_TEMPERATURE := 0.7

# ===== Dataset (FIX #1: runtime fetch, bukan bundle) =====
const DATASET_URL := "https://raw.githubusercontent.com/ferrysrt/slangfeed/main/data/slang_dataset.csv"
const DATASET_TIMEOUT_SEC := 5.0     # SRS FR-B4: timeout keras loader
const DATASET_MAX_ENTRIES := 200     # SRS FR-A10

# ===== Kunci API (SRS NFR-5: TIDAK dibundle ke paket ekspor) =====
## Kunci dibaca dari user://<key_file> (git-ignored) → fallback env var.
## Windows: %APPDATA%\Godot\app_userdata\SlangFeed\<key_file>
const API_KEY_DIR := "user://"

# ===== Batch =====
const BATCH_SIZE := 5
