# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization (production-ready)
#
#   Stage 1 `builder` : cài dependency vào /install (tách khỏi image cuối)
#   Stage 2 `runtime` : chỉ copy /install + source code, chạy bằng user thường
#
# Build:  docker build -t day12-agent:prod .
# Size:   docker images day12-agent:prod
# ═══════════════════════════════════════════════════════════════════

# ── Stage 1: builder ───────────────────────────────────────────────
FROM python:3.11-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Mọi thư viện trong requirements.txt đều có wheel dựng sẵn cho Linux nên
# không cần build-essential. Nếu sau này thêm thư viện phải biên dịch, cài
# compiler ở đây — nó chỉ nằm ở stage builder, không theo sang image cuối.

WORKDIR /build

# Copy requirements.txt riêng và cài TRƯỚC — sửa code không làm mất cache layer này
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt


# ── Stage 2: runtime ───────────────────────────────────────────────
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# User thường, UID cố định 10001
RUN useradd --create-home --uid 10001 appuser

WORKDIR /app

# Chỉ lấy KẾT QUẢ cài đặt từ builder
COPY --from=builder /install /usr/local

# Source code copy SAU dependency
COPY --chown=appuser:appuser app ./app
COPY --chown=appuser:appuser utils ./utils

USER appuser

EXPOSE 8000

# Shell form để ${PORT} được thay giá trị lúc chạy
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen(f'http://127.0.0.1:{os.environ.get(\"PORT\", \"8000\")}/health', timeout=4).read()" || exit 1

# 0.0.0.0: nhận kết nối từ ngoài container; ${PORT:-8000}: cloud tự gán cổng
# `exec` để uvicorn thay thế sh thành PID 1 → nhận được SIGTERM trực tiếp
# (thiếu exec thì sh nuốt SIGTERM, container bị SIGKILL sau 10 giây)
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
