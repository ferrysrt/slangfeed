---
description: Cara menjalankan backend SlangFeed (RAG + Few-Shot + Random Theme)
---

# Menjalankan Backend SlangFeed

## Prasyarat
- Python 3.11+ terinstall
- File `.env` berisi `GROQ_API_KEY` di folder `backend/`

## Langkah-langkah

### 1. Buka terminal, masuk ke folder backend
```
cd f:\Skripsi\slangfeed\backend
```

### 2. (Pertama kali saja) Install dependencies
// turbo
```
pip install -r requirements.txt
```

### 3. Pastikan file `.env` ada dan berisi API key
// turbo
```
type .env
```
Harus ada baris: `GROQ_API_KEY=gsk_xxxxxxx`

Jika belum ada, buat file `.env`:
```
echo GROQ_API_KEY=gsk_isi_api_key_mu_disini > .env
```

### 4. Jalankan server backend
```
python main.py
```

Tunggu sampai muncul output seperti ini:
```
[RAG] Loading dataset...
[RAG] Dataset loaded: 501 slangs
[RAG] Loading embedding model (all-MiniLM-L6-v2)...
[RAG] Embedding model loaded in X.XXs
[RAG] Building vector database...
[RAG] Embedding 501 slang documents...
[RAG] Vector database built in X.XXs
[RAG] ============ RAG SYSTEM READY ============

INFO:     Uvicorn running on http://0.0.0.0:8000
```

> **Catatan:** Startup pertama kali bisa lambat (~10-30 detik) karena harus download model embedding (~80MB). Setelah itu akan lebih cepat karena model sudah di-cache.

### 5. (Opsional) Test apakah server jalan
Buka terminal baru:
// turbo
```
curl http://localhost:8000/health
```
Atau buka browser ke: `http://localhost:8000/health`

Harusnya muncul:
```json
{
  "status": "ok",
  "message": "SlangFeed API is running (RAG + Few-Shot + Random Theme)",
  "dataset_stats": {"total_slangs": 501, ...}
}
```

### 6. Jalankan game dari Godot
- Buka project SlangFeed di Godot Editor
- Tekan **F5** (Play) atau klik tombol ▶
- Backend harus tetap berjalan di terminal

### 7. Untuk menghentikan server
Tekan `Ctrl+C` di terminal backend.

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `ModuleNotFoundError` | Jalankan `pip install -r requirements.txt` |
| `GROQ_API_KEY not found` | Pastikan file `.env` ada di folder `backend/` |
| Game selalu fallback | Cek terminal backend — lihat error `[GROQ]` |
| Port 8000 sudah dipakai | Kill proses lain: `netstat -ano | findstr :8000` lalu `taskkill /PID <nomor> /F` |
