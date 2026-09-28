# Thông Tin Deploy — Checkpoint 5

> `pytest tests/test_cp5.py` đọc file này để tìm địa chỉ service và gọi thử.
>
> **Chỉ ghi TÊN biến môi trường, tuyệt đối không dán giá trị API key vào đây.**

## Thông Tin Học Viên

| Mục | Nội dung |
|-----|----------|
| Họ và tên | Nguyễn Văn Quốc Việt |
| Mã học viên | 2A202602973 |
| Repo | https://github.com/vietvuivui/K4-L3A-DAY12-NguyenVanQuocViet-2A202602973-CloudServicesAndDeployment |

## Service

| Mục | Nội dung |
|-----|----------|
| Public URL | https://agent-production-d4ad.up.railway.app |
| Platform | Railway |
| Ngày deploy | 2026-09-28 |

Kiến trúc trên Railway: project `day12-agent` gồm 2 service

- `agent` — build từ `Dockerfile` của repo (`railway up`), chạy bằng user thường, uvicorn đọc `$PORT`
- `Redis` — Redis database add-on của Railway, nối với `agent` qua private network

## Biến Môi Trường Đã Set Trên Cloud

Ghi tên biến và **nguồn giá trị**, không ghi giá trị:

| Biến | Đã set | Ghi chú |
|------|--------|---------|
| `PORT` | ✅ | Railway tự gán — không set thủ công |
| `AGENT_API_KEY` | ✅ | sinh ngẫu nhiên, đặt qua `railway variable set --stdin`, không nằm trong repo; khác khóa dùng ở máy local |
| `REDIS_URL` | ✅ | biến tham chiếu `${{Redis.REDIS_URL}}` tới Redis add-on của Railway |
| `RATE_LIMIT_PER_MINUTE` | ✅ | 10 |
| `MONTHLY_BUDGET_USD` | ✅ | 10.0 |
| `LOG_LEVEL` | ✅ | INFO |

## Lệnh Kiểm Tra

```bash
URL=https://agent-production-d4ad.up.railway.app

# 1. Liveness — mong đợi 200 {"status":"ok"}
curl -i $URL/health

# 2. Readiness — mong đợi 200 {"status":"ready"} (đã nối được Redis)
curl -i $URL/ready

# 3. Không có API key — mong đợi 401
curl -i -X POST $URL/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Hello"}'

# 4. Có API key — mong đợi 200 kèm câu trả lời
curl -i -X POST $URL/ask \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $AGENT_API_KEY" \
  -H "X-User-Id: sv-test" \
  -d '{"question":"Deploy là gì?"}'

# 5. Rate limit — gọi 15 lần, những lần cuối phải trả 429
for i in $(seq 1 15); do
  curl -s -o /dev/null -w "%{http_code} " -X POST $URL/ask \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $AGENT_API_KEY" \
    -H "X-User-Id: sv-test" \
    -d '{"question":"test"}'
done; echo
```

## Kết Quả Chạy Thật

Chạy ngày 2026-09-28 vào `https://agent-production-d4ad.up.railway.app`:

```
# 1. /health
HTTP/1.1 200 OK
{"status":"ok","service":"day12-agent","version":"1.0.0"}

# 2. /ready
HTTP/1.1 200 OK
{"status":"ready","redis":true}

# 3. /ask không có key
HTTP/1.1 401 Unauthorized
{"detail":"invalid or missing API key"}

# 4. /ask có key
HTTP/1.1 200 OK
{"answer":"Ngắn gọn: Deploy la gi phụ thuộc vào ba yếu tố — cấu hình qua biến môi trường, health check để orchestrator biết trạng thái, và giới hạn tài nguyên.","user_id":"sv-test","history_length":0,"cost_usd":2.265e-05,"tokens":{"in":3,"out":37}}

# 5. Rate limit x15 (lệnh 4 đã dùng 1 lượt → 9 lượt 200 rồi 429)
200 200 200 200 200 200 200 200 200 429 429 429 429 429 429
```

## Ảnh Chụp Màn Hình

Ảnh trong thư mục `screenshots/`:

- `screenshots/dashboard.png` — trang quản lý project `day12-agent` trên Railway (service `agent` + `Redis`)
- `screenshots/health.png` — kết quả gọi `/health` của Public URL trên trình duyệt
