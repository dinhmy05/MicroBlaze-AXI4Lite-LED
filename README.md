# MicroBlaze AXI4-Lite LED Controller on ZedBoard

Hệ thống SoC sử dụng bộ xử lý mềm **MicroBlaze** triển khai trong **Programmable Logic (PL)** của ZedBoard để điều khiển **4 LED** qua ngoại vi ánh xạ bộ nhớ **AXI4-Lite**. Thiết kế **không sử dụng ARM Processing System (PS)** để chạy chương trình ứng dụng.

> **Trạng thái kiểm chứng:** Repository mô tả kiến trúc, source và **kịch bản mô phỏng dự kiến**. Chuỗi LED bên dưới là kết quả mong đợi, **không phải** xác nhận rằng mô phỏng end-to-end đã PASS. Cần bổ sung waveform/log trước khi công bố kết quả.

## 1. Cấu hình hệ thống

| Thành phần | Cấu hình |
|---|---|
| Board | ZedBoard |
| FPGA part | `xc7z020clg484-1` |
| Bộ xử lý | MicroBlaze (soft-core trong PL) |
| Bộ nhớ cục bộ | BRAM 16 KB, ILMB/DLMB |
| Bus ngoại vi | AXI4-Lite qua AXI SmartConnect |
| Clock hệ thống | 100 MHz |
| Đầu ra | `led_out[3:0]` (4 LED) |
| Phần mềm | C / MicroBlaze GCC / Vitis Unified IDE 2025.1 |
| Phần cứng | Vivado; cần mở với phiên bản tương thích project/IP (ghi nhận thiết kế ở Vivado 2025.1) |

## 2. Kiến trúc

```text
main.c -> MicroBlaze GCC -> microblaze_led_test.elf -> BRAM (16 KB)
                                                    |
                                                    v
MicroBlaze (M_AXI_DP) -> AXI SmartConnect -> AXI4-Lite Slave
                                               (IP bên thứ ba)
                                                     |
                                                     v
                                             led_reg_bridge.v
                                                     |
                                                     v
                                             led_controller.v
                                                     |
                                                     v
                                               led_out[3:0]
```

- **MicroBlaze:** thực thi firmware từ BRAM; phát giao dịch đọc/ghi ngoại vi.
- **AXI SmartConnect:** định tuyến yêu cầu truy cập thanh ghi.
- **AXI4-Lite Slave:** xử lý năm kênh giao thức AW, W, B, AR và R (IP bên thứ ba).
- **`led_reg_bridge.v`:** giải mã offset, lưu/đọc thanh ghi LED.
- **`led_controller.v`:** điều khiển LED theo `led_data`, `enable`, `blink_mode`; hỗ trợ chế độ nhấp nháy.
- **Clock Wizard / Processor System Reset:** cung cấp clock và reset đồng bộ.

## 3. Bản đồ địa chỉ

| Vùng / thanh ghi | Địa chỉ | Ý nghĩa |
|---|---|---|
| Local BRAM | `0x00000000–0x00003FFF` | 16 KB cho chương trình và dữ liệu |
| AXI4-Lite Slave | `0x44A00000–0x44A0FFFF` | Cửa sổ ánh xạ địa chỉ 64 KB; **không phải** RAM 64 KB |
| `LED_DATA` | `0x44A00000` (offset `0x00`) | Bit `[3:0]`: mẫu dữ liệu LED |
| `LED_CTRL` | `0x44A00004` (offset `0x04`) | Bit `0`: `enable`; bit `1`: `blink_mode` |

Khi `enable = 0`, LED tắt. Với cấu hình clock 100 MHz và ngưỡng đếm 50.000.000 chu kỳ, mỗi pha nhấp nháy xấp xỉ **0,5 giây** (chu kỳ sáng–tắt khoảng 1 giây).

**Giới hạn RTL hiện tại:** `led_reg_bridge.v` chỉ cập nhật thanh ghi khi `write && write_strobe[0]`; chưa hỗ trợ cập nhật từng byte độc lập theo toàn bộ `write_strobe[3:0]`. Các tín hiệu `write_done/read_done` được gán `1`, còn `write_error/read_error` được gán `0` tại giao diện nội bộ; không được xem đây là chứng nhận tuân thủ đầy đủ AXI4-Lite.

## 4. Source cần lưu trong repository

Cấu trúc các file đã được trích xuất và đóng gói trong repository này:

```text
MicroBlaze-AXI4Lite-LED/
├── hardware/
│   ├── rtl/
│   │   ├── led_reg_bridge.v
│   │   └── led_controller.v
│   ├── block_design/
│   │   ├── Microblaze_Controller.bd
│   │   └── Microblaze_Controller.tcl      # Nếu đã xuất
│   └── constraints/
│       └── main.xdc
├── simulation/
│   └── tb_microblaze_led_system.v
├── software/
│   ├── main.c
│   ├── lscript.ld                    # Lấy từ Vitis
│   └── microblaze_led_test.elf       # Tùy chọn: ELF cho mô phỏng
├── docs/
│   └── MicroBlaze_AXI4Lite_LED_ZedBoard_FullFlow_Report.txt
├── README.md
└── .gitignore
```

`Microblaze_Controller.bd` **không đủ để tái tạo project một cách độc lập** nếu thiếu source, dependency/IP Repository hoặc cấu hình phù hợp. Nên lưu thêm Tcl xuất từ Vivado và đường dẫn/phương pháp cài IP bên thứ ba.

## 5. Cài đặt IP AXI4-Lite Slave bên thứ ba

Thiết kế sử dụng IP **AXI-Lite Slave** của **Yiğit Süoğlu**:

- Repository: <https://github.com/suoglu/AXI-lite-slave>
- Thư mục IP: `Sources/ip_repo/axi_lite_slave_1.0/`
- HDL nguồn tham khảo: `Sources/ip_repo/axi_lite_slave_1.0/hdl/axi_lite_slave_v1_0.v`

Tải repository của tác giả rồi vào **Vivado → Settings / Project Settings → IP → Repository**, bổ sung thư mục `Sources/ip_repo`. Sau đó kiểm tra IP đã nhận đúng trước khi mở/tái tạo Block Design.

Nếu phân phối lại mã nguồn IP trong repository của nhóm, cần giữ thông báo bản quyền và tuân thủ giấy phép áp dụng ở repository gốc. Không nhận phần mã AXI-Lite Slave là do nhóm tự viết.

## 6. Build firmware bằng Vitis

1. Từ Vivado, xuất **XSA** của cấu hình phần cứng tương ứng.
2. Trong **Vitis Unified IDE 2025.1**, tạo **Platform** từ XSA, chọn processor `microblaze_0` và domain **standalone**.
3. Tạo **Application** sử dụng `main.c` và `lscript.ld` tương ứng với BRAM.
4. Kiểm tra cấu hình linker theo ghi chú thiết kế: `ORIGIN = 0x00000050`, `LENGTH = 0x00003FB0`, stack `0x400`, heap `0x800`. **Đối chiếu với `lscript.ld` thật trước khi build.**
5. Build application để tạo `microblaze_led_test.elf`.

Khi thay đổi địa chỉ, bộ nhớ hoặc cấu hình processor, cần xuất lại XSA, cập nhật Platform và build lại Application.

## 7. Mô phỏng hệ thống (kịch bản kiểm tra)

1. Trong Vivado, mở **Tools → Associate ELF Files**, chọn ELF tương ứng cho `microblaze_0` tại **Simulation Sources**.
2. Thêm `tb_microblaze_led_system.v` vào **Simulation Sources** và đặt làm simulation top.
3. Chọn **Run Behavioral Simulation**, sau đó **Run All** theo thời gian yêu cầu của testbench.
4. Kiểm tra `sys_clock`, `sys_reset_n`, các tín hiệu reset nội bộ và `led_out[3:0]`.
5. Quan sát các cặp handshake **AWVALID/AWREADY, WVALID/WREADY, BVALID/BREADY, ARVALID/ARREADY, RVALID/RREADY**, cùng `BRESP`, `RRESP`, `RDATA`.

**Chuỗi LED kỳ vọng từ firmware:**

```text
0101 -> 1010 -> 0000 -> 1111
```

Trong đó `0000` ở bước thứ ba đến từ việc ghi `LED_CTRL = 0` (disable), không nhất thiết do ghi `LED_DATA = 0`.

Firmware có thể đọc lại hai thanh ghi và ghi bit lỗi vào biến `test_result`. Việc đọc lại thanh ghi **chưa thay thế** kiểm chứng thực tế `led_out[3:0]` và AXI waveform.

> Chỉ ghi PASS khi đã có log/waveform xác nhận. Chưa đính kèm bằng chứng kết quả thực nghiệm trong README này.

## 8. Tài liệu tham khảo

Các nguồn tham khảo sử dụng để tìm hiểu kiến trúc hệ thống và tích hợp IP (không phải toàn bộ mã nguồn do nhóm tự phát triển):

1. **AMD**, *MicroBlaze Processor Reference Guide* (UG984, 2024.1): <https://docs.amd.com/r/2024.1-English/ug984-vivado-microblaze-ref> — kiến trúc MicroBlaze và các giao diện bộ nhớ/bus.
2. **Arm**, *AMBA AXI and ACE Protocol Specification* (IHI 0022H): <https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/IHI0022H_amba_axi_protocol_spec.pdf> — các kênh giao tiếp và quy tắc handshake AXI/AXI4-Lite.
3. **Nguyễn Trí Phúc**, *Thiết kế IP Core reset nguồn*, báo cáo học phần Thiết kế hệ thống nhúng, Học viện Kỹ thuật Mật mã, 2026: <https://fr.scribd.com/document/1050129253/thktn> — tài liệu tham khảo phương pháp tích hợp IP, **không phải** source ngoại vi LED của nhóm.
4. **Yiğit Süoğlu**, *AXI-Lite Slave* (mã nguồn IP dùng trong project): <https://github.com/suoglu/AXI-lite-slave>.
5. **AMD**, *Vivado Design Suite Tutorial: Creating and Packaging Custom IP* (UG1119, 2024.2): <https://docs.amd.com/r/2024.2-English/ug1119-vivado-creating-packaging-ip-tutorial> — quy trình đóng gói và tích hợp IP vào Vivado.

## 8. Tài liệu chi tiết và ghi nhận đóng góp

- Quy trình thiết kế và checklist mô phỏng: `docs/MicroBlaze_AXI4Lite_LED_ZedBoard_FullFlow_Report.txt`.
- IP AXI-Lite Slave của Yiğit Süoğlu: <https://github.com/suoglu/AXI-lite-slave>.
- Hai module ứng dụng của nhóm: `led_reg_bridge.v`, `led_controller.v`.

**Lưu ý khi công khai source:** kiểm tra đường dẫn máy cá nhân trong `.xpr`, Tcl và các file cấu hình trước khi commit; không đưa các thư mục Vivado tự sinh (`.Xil/`, `*.cache/`, `*.runs/`, `*.gen/`, `*.sim/`) nếu không cần thiết.


## Lưu ý khi sử dụng gói GitHub

- Các file RTL, `.bd`, `.xdc`, testbench được trích xuất nguyên bản từ `MicroBlaze_Controller(2).rar`.
- `software/main.c`, `software/microblaze_led_test.elf` và tài liệu trong `docs/` lấy từ các file người thực hiện cung cấp. Chưa xác nhận ELF được build từ đúng bản `main.c` này.
- **Chưa có `lscript.ld` và Tcl tái tạo project.** Cần bổ sung từ Vitis/Vivado nếu muốn dựng lại chính xác.
- **Phụ thuộc bên ngoài:** tải AXI-Lite Slave tại https://github.com/suoglu/AXI-lite-slave và khai báo IP Repository tương ứng trước khi phục hồi Block Design.
- `main.xdc` là constraints gốc được gửi, có ghi chú *proposed constraints* và lưu ý kiểm tra VADJ/IOSTANDARD trước khi dùng trên phần cứng thật.
- Gói này **không bảo đảm** mở độc lập thành project hoàn chỉnh nếu thiếu custom IP, wrapper hoặc IP configuration cần thiết.
