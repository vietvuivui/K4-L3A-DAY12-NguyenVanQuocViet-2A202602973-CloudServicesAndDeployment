# Phiếu Phản Ánh — K4 Level 3A, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng trả lời mẫu dưới mỗi câu bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Nguyễn Văn Quốc Việt Mã học viên: 2A202602973

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> *Một tình huống cụ thể là khi deploy app lên Railway nhưng tôi quên đặt biến môi trường `AGENT_API_KEY`. Nếu `agent_api_key` có giá trị mặc định là `"changeme"`, app vẫn khởi động bình thường và có thể nhận request. Nếu `"changeme"` bị đoán hoặc bị sử dụng, người khác có thể gọi `/ask` bằng API key này và làm phát sinh chi phí LLM mà tôi không biết ngay. Ngược lại, khi không có giá trị mặc định, `Settings()` sẽ ném `ValidationError` ngay lúc khởi động. Deployment fail ngay và tôi nhìn thấy lỗi trong log, từ đó biết ngay rằng biến môi trường đang bị thiếu. Vì vậy, fail fast giúp phát hiện lỗi cấu hình ngay tại thời điểm deploy thay vì để ứng dụng chạy với một cấu hình nguy hiểm.*

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> *Một dòng log JSON tôi thu được là: `{"event":"ask_completed","level":"info","timestamp":"2026-09-28T09:04:36.807418+00:00","user_id":"sv01","tokens_in":48,"tokens_out":52,"cost_usd":3.84e-05}` Với log dạng JSON, tôi có thể: 1. **Lọc hoặc truy vấn theo từng trường**, ví dụ tìm tất cả request của `user_id="sv01"` hoặc tất cả log có `level="error"` trong một khoảng thời gian. 2. **Cộng dồn và phân tích số liệu**, ví dụ tính tổng `cost_usd` theo từng user trong ngày để theo dõi chi phí. `print("đã trả lời xong")` chỉ cho biết một sự kiện đã xảy ra, nhưng không chứa các trường có cấu trúc để máy có thể dễ dàng lọc, thống kê hoặc phân tích.*

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ... MB |
| Multi-stage | 271 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> *Kích thước image: Sau khi build hai phiên bản Docker, bản multi-stage có dung lượng 271 MB, còn bản 1-stage cần được build và đo thực tế 1,1 GB. Sự chênh lệch dung lượng chủ yếu đến từ việc bản 1-stage vẫn giữ lại các thành phần chỉ phục vụ quá trình build như compiler, header, build tools và các dependency trung gian. Nếu build context không được loại trừ bằng `.dockerignore`, các file không cần thiết như `.git`, `.venv`, test hoặc file tạm cũng có thể làm image lớn hơn. Trong khi đó, multi-stage chỉ giữ lại những thành phần cần thiết cho runtime như môi trường Python, các package đã cài và source code của ứng dụng.*

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> *Dockerfile hiện tại đặt các bước theo thứ tự `COPY requirements.txt`, sau đó `RUN pip install`, rồi mới `COPY app` và `COPY utils`. Vì vậy, khi tôi chỉ sửa một ký tự trong `app/main.py`, các layer trước đó như base image, `useradd`, `COPY requirements.txt` và `RUN pip install` vẫn được Docker lấy lại từ cache, chỉ layer `COPY app` và các layer phía sau phải chạy lại. Trong lần build ban đầu, `pip install` mất khoảng 140 giây, nhưng sau khi chỉ sửa source code thì build lại chỉ mất vài giây. Nếu đặt `COPY . .` trước `RUN pip install`, mỗi thay đổi trong source code có thể làm layer `COPY` thay đổi và khiến Docker phải chạy lại `pip install`, dẫn đến thời gian build tăng đáng kể.*

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> *Một chuỗi tấn công có thể bắt đầu từ việc ứng dụng Python có một lỗ hổng cho phép attacker thực thi mã từ xa. Attacker có thể lợi dụng lỗ hổng để chạy lệnh bên trong container. Nếu application đang chạy bằng `root`, các lệnh đó cũng có quyền root bên trong container, cho phép attacker đọc hoặc sửa nhiều file và thực hiện nhiều thao tác nguy hiểm hơn. Nếu container còn có thêm lỗ hổng kernel/runtime hoặc cấu hình nguy hiểm như mount Docker socket thì attacker có thể tìm cách thoát container và tác động tới host. Việc dùng `USER appuser` với UID như `10001` khiến process ứng dụng chạy bằng user thường, do đó nếu bị khai thác thì attacker chỉ có quyền hạn chế thay vì root. Như vậy, `USER` cắt giảm quyền của attacker ngay tại bước thực thi lệnh bên trong container và làm giảm đáng kể tác động của một lỗ hổng.*

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> *Với fixed-window rate limit là 10 request mỗi phút, một người dùng có thể gửi tối đa 20 request trong khoảng gần 2 giây. Ví dụ, người dùng gửi 10 request ngay trước thời điểm `10:01:00`, chẳng hạn lúc `10:00:59`. Khi đồng hồ chuyển sang `10:01:00`, bộ đếm của phút mới được reset nên người dùng có thể gửi tiếp 10 request trong khoảng `10:01:00` đến `10:01:01`. Như vậy có thể có 20 request trong khoảng thời gian rất ngắn dù mỗi phút riêng biệt đều không vượt quá giới hạn 10 request. Với sliding window thì khác, vì hệ thống luôn xét 60 giây gần nhất nên 10 request ở cuối phút trước vẫn được tính khi bước sang phút mới.*

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> *Rate limit và cost guard bảo vệ hai loại tài nguyên khác nhau. Rate limit giới hạn số lượng request trong một khoảng thời gian, ví dụ tối đa 10 request trong 60 giây, trong khi cost guard giới hạn tổng chi phí sử dụng, ví dụ tối đa 10 USD mỗi tháng. Một trường hợp rate limit cho qua nhưng cost guard phải chặn là khi user gửi request với tốc độ thấp, chẳng hạn 5 request mỗi phút, nhưng mỗi request chứa prompt rất lớn và tiêu tốn nhiều token, khiến tổng chi phí sau một thời gian vượt ngân sách. Ngược lại, cost guard có thể cho qua nhưng rate limit chặn khi user gửi 50 request trong vài giây nhưng mỗi request chỉ chứa `"hi"`, vì tổng chi phí vẫn rất nhỏ nhưng tốc độ request đã vượt quá giới hạn.*

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> *Nếu gộp `/health` và `/ready` thành một endpoint và endpoint đó kiểm tra Redis, khi Redis mất kết nối thì cả 3 container đều có thể trả `503`. Nếu hệ thống orchestration được cấu hình dựa trên endpoint này để xác định tình trạng container, nó có thể coi cả 3 container là không healthy và restart chúng. Nếu cả 3 container bị restart cùng lúc thì trong khoảng thời gian đó không còn instance nào phục vụ request, khiến toàn bộ service có thể bị gián đoạn dù application process thực tế vẫn hoạt động bình thường. Khi tách hai endpoint, `/health` chỉ kiểm tra application process nên vẫn trả `200`, còn `/ready` kiểm tra Redis và trả `503` khi Redis mất kết nối. Khi đó load balancer chỉ ngừng gửi traffic tới instance chưa ready thay vì restart container, và khi Redis hoạt động trở lại thì `/ready` trở về `200`. Thực tế khi chạy `docker compose stop redis`, tôi quan sát được `/health` vẫn trả `200` trong khi `/ready` trả `503` với `{"redis":false}`.*

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> *Khi sử dụng Redis để lưu history, request có thể đi vào bất kỳ container nào nhưng tất cả container đều đọc cùng một trạng thái từ Redis. Với cùng `X-User-Id: sv01`, tôi đã thử gọi `/ask` hai lần và quan sát `history_length` tăng từ `0` lên `2`, vì lần thứ hai đã nhìn thấy câu hỏi và câu trả lời của lần trước. Nếu chạy nhiều container thì giá trị vẫn có thể tiếp tục tăng `0 → 2 → 4 → 6...` vì tất cả đều dùng chung Redis. Ngược lại, nếu lưu history trong một `dict` Python thì mỗi container có một bộ nhớ riêng. Khi load balancer phân phối request tới các container khác nhau, `history_length` có thể thay đổi không liên tục, chẳng hạn `0 → 0 → 0 → 2 → 2 → 2 → 4...`, vì mỗi container chỉ nhớ những request đã được xử lý bởi chính nó. Ngoài ra, khi container restart thì history trong `dict` cũng bị mất*

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> *Một lỗi tôi gặp là container không tắt graceful khi chạy `docker compose stop agent`. Container kết thúc với trạng thái `Exited (137)` và log không xuất hiện dòng `Shutting down`. Tôi kiểm tra mã exit và nhận thấy `137 = 128 + 9`, tương ứng với process bị kết thúc bởi `SIGKILL`. Sau đó tôi kiểm tra Dockerfile và phát hiện `CMD ["sh", "-c", "uvicorn ..."]` khiến `sh` trở thành PID 1 thay vì `uvicorn`. Khi Docker gửi `SIGTERM` để dừng container, signal không được chuyển đúng tới process `uvicorn`, nên application không có cơ hội shutdown graceful trước khi bị kill. Tôi sửa command thành dạng sử dụng `exec` để `uvicorn` trở thành process chính, sau đó container kết thúc với `Exited (0)` và log xuất hiện đầy đủ quá trình `Shutting down → service_stopped`. Thời gian shutdown sau khi sửa cũng giảm xuống khoảng 0,7 giây. Ngoài ra, tôi phải bỏ `startCommand` trong `railway.toml` vì dòng này ghi đè command được khai báo trong Dockerfile.*
