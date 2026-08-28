extends Node
## Config — central configuration autoload (NFR-8: single source of constants).
## Autoloaded as "Config". Sumber: plan1-revisi v2 / SRS v2.0.

# ===== OpenRouter / LLM#2 =====
const OPENROUTER_URL := "https://openrouter.ai/api/v1/chat/completions"
const OPENROUTER_MODEL := "openai/gpt-oss-120b"
const LLM_TIMEOUT_SEC := 10.0        # SRS FR-C4: timeout keras generasi soal
const LLM_MAX_TOKENS := 2000
const LLM_TEMPERATURE := 0.7

# ===== Dataset (FIX #1: runtime fetch, bukan bundle) =====
const DATASET_URL := "https://raw.githubusercontent.com/USERNAME/REPO/main/data/slang_dataset.csv"
const DATASET_TIMEOUT_SEC := 5.0     # SRS FR-B4: timeout keras loader
const DATASET_MAX_ENTRIES := 200     # SRS FR-A10

# ===== Kunci API =====
## API key dibaca dari user://openrouter_key.txt (git-ignored, TIDAK dibundle).
## Isi manual via: project settings > user data dir, atau tulis file di folder
## app userdata (di Windows: %APPDATA%/Godot/app_userdata/SlangFeed/openrouter_key.txt)
## Fallback: env var OPENROUTER_API_KEY. Kosong = LLM#2 selalu fallback (mode demo aman).
const API_KEY_FILENAME := "openrouter_key.txt"

# ===== Batch =====
const BATCH_SIZE := 5

# ===== Offline badges =====
const OFFLINE_BADGE_TEXT := "Offline Mode"
