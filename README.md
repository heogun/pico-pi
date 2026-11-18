# PICO8-OS

라즈베리파이를 켜면 바로 PICO-8(Splore)이 뜨는 전용 OS. Buildroot 2026.02.3 LTS 기반의 `BR2_EXTERNAL` 트리입니다.

> **비공식 프로젝트입니다.** PICO8-OS는 개인이 만든 커뮤니티 프로젝트로, PICO-8을 만든 [Lexaloffle Games](https://www.lexaloffle.com/)와 관련이 없고 Lexaloffle의 승인이나 지원을 받지 않습니다. "PICO-8"은 Lexaloffle Games의 제품 이름이며, 이 프로젝트는 PICO-8을 포함하거나 배포하지 않습니다. PICO-8은 [lexaloffle.com](https://www.lexaloffle.com/pico-8.php)에서 직접 구입하세요. 이 프로젝트에 관한 문의는 Lexaloffle이 아닌 이 저장소의 [Issues](https://github.com/heogun/pico8-os/issues)로 해 주세요.
>
> *PICO8-OS is an unofficial community project. It is not affiliated with, endorsed by, or supported by Lexaloffle Games. "PICO-8" is a product of Lexaloffle Games; this project does not include or distribute PICO-8 — buy it at [lexaloffle.com](https://www.lexaloffle.com/pico-8.php).*

- 부팅 → busybox init → tty1에서 `pico8-session` → PICO-8 (SDL2 **kmsdrm**, X11/Wayland 없음)
- PICO-8은 유료 소프트웨어라 이미지에 포함하지 않습니다. 사용자가 산 `pico-8_x.y.z_raspi.zip`(또는 압축을 푼 `pico-8` 폴더)을
  SD카드의 **PICO8DATA** 드라이브나 USB 메모리에 넣으면 부팅할 때 `/opt/pico8`에 설치합니다.
- 설정, 카트, 세이브, 스크린샷, 로그는 모두 FAT32 데이터 파티션에 있어서 PC에서 바로 편집할 수 있습니다.
- 시스템은 읽기 전용이어서 전원을 그냥 뽑아도 깨지지 않습니다.
- **SD카드를 빼지 않고 씁니다.** 같은 네트워크의 폰이나 PC에서 웹 관리 페이지로 카트, 설정, Wi-Fi, 블루투스, 업데이트를 다룹니다.
  콘솔 화면에서는 설정 카트(`Ctrl+Alt+S` / 패드 `SELECT` 2초)를 씁니다. 처음 켤 때 Wi-Fi가 없으면 설정용 AP를 엽니다.
- **OTA 업데이트:** A/B 시스템 슬롯, 서명된 업데이트 파일, 3번 부팅에 실패하면 자동으로 되돌아갑니다.
- **9개 언어:** 한국어, English, 中文, 日本語, Français, Español, Русский, Italiano, Deutsch (웹 관리 페이지와 콘솔 설정 화면).
- 이전 프로젝트(gamaral의 PICOPi)를 분석한 결과와 유사 프로젝트 조사는 [docs/survey.md](docs/survey.md)에 있습니다.

## 지원 보드

| 타깃 | 보드 | 유저랜드 | 실행 파일 |
|---|---|---|---|
| `rpi0` | Pi 1 A/B/A+/B+, Zero, Zero W, CM1 | 32-bit ARMv6 | `pico8_dyn` |
| `rpi2` | Pi 2 B | 32-bit ARMv7 | `pico8_dyn` |
| `rpi3` | Pi 3 A+/B/B+, Zero 2 W, CM3 | 32-bit ARMv7 | `pico8_dyn` |
| `rpi4` | Pi 4 B, Pi 400, CM4 | 32-bit ARMv7 | `pico8_dyn` |
| `rpi5` | Pi 5, Pi 500 | 64-bit | `pico8_64` (PICO-8 0.2.4+) |
| `qemu` | QEMU `virt` (테스트용) | 32-bit ARMv7 | `pico8_dyn` |

Buildroot는 이미지 하나에 커널 하나만 넣기 때문에 SoC 계열마다 이미지가 따로 나옵니다.
Pi 0–4는 공식 라즈베리파이용 PICO-8과 같은 armhf ABI를 씁니다. Pi 5는 Buildroot가 64-bit만 지원하므로 `pico8_64`를 씁니다.

## 빌드

Buildroot는 Linux에서만 빌드됩니다. macOS에서는 Docker(Docker Desktop, colima 등)를 쓰세요.

```bash
make docker-rpi4
```

Linux 호스트라면 바로 빌드할 수 있습니다(Buildroot 소스는 처음 실행할 때 자동으로 받습니다).

```bash
make rpi4
```

결과물은 `dist/pico8os-<board>.img`(SD카드 이미지)와 `dist/pico8os-<board>-<버전>.pico8os-update`(OTA 업데이트 파일)입니다.
이미지는 Raspberry Pi Imager나 `dd`로 SD카드에 씁니다.

처음 빌드하면 `keys/ota-private.pem`(업데이트 서명 키)이 만들어집니다. **이 파일을 안전하게 보관하세요.**
이 키로 서명한 업데이트만 콘솔에 설치되고(이미지에는 공개 키만 들어감), 키를 잃어버리면 이미 만든 콘솔은 SD카드를 다시 굽는 방법으로만 업데이트할 수 있습니다.
버전은 빌드 시각(`YYYY.MM.DD-HHMM`, UTC)이며 `make PICO8OS_VERSION=... rpi4`로 바꿀 수 있습니다.
처음 빌드할 때는 툴체인, 커널, Mesa를 받아서 빌드하므로 수십 분에서 1시간 넘게 걸립니다.

- 설정 변경: `make menuconfig-rpi4`
- 빌드 없이 빠른 검사: `scripts/check.sh` (스크립트 문법, 실행 권한, 6개 보드 Buildroot 옵션, 카트 Lua, 웹 번역)
- **빌드 속도:**
  - Pi 커널 설정에서 쓰지 않는 서브시스템을 끕니다(`external/board/rpi/linux-trim.fragment`). 카메라와 영상, 방화벽과 트래픽 제어, NFS/CIFS 등 쓰지 않는 파일시스템, USB 가젯, 다른 회사 Wi-Fi, 오디오 HAT이 대상이고, 모듈이 약 1,250개에서 약 600개로 줄어듭니다.
    `scripts/check-kernel-trim.py <커널 소스>`가 Kconfig 의존 관계를 분석해, 필요한 드라이버(vc4/v3d, HDMI 오디오, 게임패드, 블루투스, Broadcom Wi-Fi, 이더넷, USB 저장장치, 워치독 등)가 하나도 꺼지지 않았는지 확인합니다(CI `check` 워크플로에도 포함).
  - `BR2_PER_PACKAGE_DIRECTORIES`로 서로 관계없는 패키지를 동시에 빌드합니다(`make -j$(BR_JOBS)`, 기본값은 CPU 수).

### GitHub Actions

| 워크플로 | 실행 시점 | 하는 일 |
|---|---|---|
| `check` | `main` 푸시, PR | `scripts/check.sh` (몇 분) |
| `build` | `v*` 태그 푸시, 또는 Actions 탭에서 수동 실행(보드 선택 가능) | 보드마다 별도 작업으로 전체 이미지 빌드 → 아티팩트(14일 보관). 태그일 때는 GitHub Release도 만듦 |

- 결과물(보드마다): `pico8os-<보드>-<버전>.img.xz`(SD카드 이미지), `pico8os-<보드>-<버전>.pico8os-update`(OTA), `latest-<보드>.txt`, SHA256SUMS
- 다운로드, Buildroot 소스, ccache는 Actions 캐시로 재사용합니다(`EXTRA_CONFIG`로 CI에서만 ccache를 켬). 빌드는 러너의 큰 `/mnt` 디스크에서 합니다.
- **OTA 서명 키:** 저장소 시크릿 `OTA_PRIVATE_KEY`에 `keys/ota-private.pem` 내용을 넣으세요.
  ```bash
  make keys
  ```
  ```bash
  gh secret set OTA_PRIVATE_KEY < keys/ota-private.pem
  ```
  시크릿이 없으면 수동 빌드는 일회용 키로 만들어집니다(그 이미지로 구운 콘솔은 OTA 업데이트를 받을 수 없음). 태그 빌드는 시크릿이 없으면 실패합니다.
- **릴리스 만들기:**
  ```bash
  git tag v0.1.0 && git push origin v0.1.0
  ```
- **사용 시간:** 보드 하나의 첫 빌드는 1~2시간 이상 걸릴 수 있습니다(툴체인, 커널, Mesa). 6개 보드 전체 빌드는 Actions 사용 시간을 많이 씁니다. 비공개 저장소의 무료 사용량은 월 2,000분이므로 필요한 보드만 수동으로 빌드하는 것이 좋습니다. 공개 저장소는 무료입니다.
- 이미지에 PICO-8 미리 넣기: `pico8/`에 zip(또는 `pico-8/` 폴더)을 두고 빌드합니다. **이렇게 만든 이미지는 배포하면 안 됩니다** (Lexaloffle 라이선스).
- 기본 카트 넣기: `carts/`에 `.p8`이나 `.p8.png`를 둡니다.

## 사용법

SD카드 파티션 구성:

| 파티션 | 형식 | 용도 | 런타임 |
|---|---|---|---|
| p1 `PICOBOOT` | FAT, 128M | 펌웨어, `slot.txt`, 슬롯별 `a/` `b/`(커널, DTB, 오버레이, cmdline) | 평소엔 마운트하지 않음 (OTA 때만 잠깐) |
| p2 rootfs-a | ext4, 256M | 시스템 슬롯 A + `/opt/pico8` | 읽기 전용 (PICO-8 설치 때만 잠깐 rw) |
| p3 rootfs-b | ext4, 256M | 시스템 슬롯 B (OTA가 씀) | 읽기 전용 |
| p4 | 확장 파티션 | | |
| p5 `PICO8DATA` | FAT32, 512M | 아래 내용 | `/data`, 쓰기 가능 (`flush`) |
| p6 `picostate` | ext4, 16M | 블루투스 페어링 키, OTA 상태, 웹 비밀번호 | `/state`, 쓰기 가능 (`commit=5`) |

```
PICO8DATA/
  pico-8_0.2.x_raspi.zip   ← 또는 압축을 푼 pico-8/ 폴더. 다음 부팅 때 설치/업데이트
  pico8os.txt              ← 설정
  carts/                   ← 카트 (PICO-8의 루트 폴더)
  pico8/                   ← PICO-8 home (config.txt, cdata 세이브, Splore 캐시)
  screenshots/
  logs/                    ← pico8.log (비정상 종료), kernel.log (전원 부족, SD 오류 등), bluetooth.log
```

`pico8os.txt` 주요 항목:

| 키 | 값 |
|---|---|
| `PICO8_MODE` | `splore` (기본) / `run` / `editor` |
| `PICO8_CART` | `run` 모드에서 실행할 카트 (`carts/` 기준 경로) |
| `EXIT_ACTION` | PICO-8 종료 시 `restart` / `poweroff` / `shell` |
| `LANGUAGE` | 설정 화면과 웹 관리 페이지 언어: `en` `ko` `zh` `ja` `fr` `es` `ru` `it` `de` |
| `KEYMAP` | 키보드 레이아웃 (`us`, `uk`, `de`, `fr`, `jp106` …). 한국어 키보드는 `us` |
| `WATCHDOG` | `on` (기본): 시스템이 멈추면 하드웨어 워치독이 재부팅 / `off` |
| `HOTKEY` | `on` (기본): PICO-8 강제 재시작 단축키 사용 / `off` |
| `PICO8_VERIFY` | `strict` (기본): 검증 목록에 있는 PICO-8만 설치 / `warn`: 목록에 없는 버전도 경고와 함께 설치. 파일이 손상되거나 변조된 경우는 항상 거부 |
| `CPU_GOVERNOR` | 게임 중 CPU 클럭 정책: `performance` (기본) / `ondemand` / `schedutil` |
| `DEBUG` | `off` (기본) / `on`: 시리얼 콘솔과 tty1에 root 셸 (문제 해결용, 재부팅 후 적용) |
| `BLUETOOTH` | `on` (기본) / `off` |
| `BT_PAIR_SECONDS` | 부팅 후 자동 페어링 시간(초, 기본 60). `0`이면 부팅 때 페어링하지 않음 |
| `PICO8_ARGS` | PICO-8에 넘길 추가 옵션 |
| `AUDIO_CARD` | `auto` (HDMI 우선) / `none` / ALSA 카드 번호 |
| `WIFI_SSID`, `WIFI_PSK`, `WIFI_COUNTRY` | Wi-Fi (보통은 웹이나 설정 카트, 설정용 AP에서 입력) |
| `WEB_PASSWORD` | 웹 관리 페이지 비밀번호. 비우면 처음 부팅 때 만든 비밀번호 사용(설정 카트에 표시) |
| `OTA_URL` | 온라인 업데이트 서버 주소 (아래 [OTA 업데이트](#ota-업데이트)) |

- **게임패드:** 아래 [게임패드](#게임패드) 참조.
- **콘솔 설정 화면:** 키보드 `Ctrl + Alt + S`, 게임패드 `SELECT`만 2초 → 아래 [설정 카트](#설정-카트).
- **PICO-8 강제 재시작:** 키보드는 `Ctrl + Alt + Backspace`, 게임패드는 `SELECT + START`를 3초 누릅니다.
  PICO-8과 멈춘 wget을 종료하고 바로 다시 시작합니다(`EXIT_ACTION`과 상관없이 재시작). 기록은 `logs/pico8.log`에 남습니다.
- 시리얼 콘솔(UART, Pi 5는 디버그 UART): 로그인 프롬프트가 없습니다. `DEBUG=on`일 때만 root 셸이 열립니다(아래 [보안](#보안))
- PICO-8이 비정상 종료하면 `logs/pico8.log`에 기록하고 다시 시작합니다. 5초 안에 3번 연속 비정상 종료하면 로그를 보여주고 tty1에 로그인 셸을 띄웁니다.

## SD카드를 빼지 않고 쓰기

### 웹 관리 페이지
콘솔과 같은 네트워크의 브라우저에서 `https://<콘솔 IP>`로 접속합니다(`http://`로 들어가도 HTTPS로 넘어감). 비밀번호와 IP는 설정 카트의 **info** 화면에 나옵니다. 처음 접속할 때 자체 서명 인증서 경고가 나오면 PICO8DATA의 `web-certificate.txt` 지문과 비교한 뒤 진행하세요.

| 탭 | 기능 |
|---|---|
| 상태 | 버전, 슬롯, IP, Wi-Fi, PICO-8 버전, 여유 공간 / PICO-8 재시작, 콘솔에서 설정 열기, 재부팅, 전원 끄기 / **PICO-8 zip 올려서 설치** |
| 카트 | `.p8`, `.p8.png` 끌어 놓아 올리기, 삭제 |
| 스크린샷 | PICO-8에서 저장한 PNG, GIF 보기, 받기, 삭제 |
| 설정 | 키보드, 시작 화면, 종료 동작, 블루투스, 단축키, OTA_URL 빠른 설정 / `pico8os.txt` 직접 편집(저장하면 바로 적용) |
| Wi-Fi·블루투스 | 주변 네트워크 검색과 연결 / 패드 페어링 시작, 페어링 목록, 삭제 |
| 업데이트 | 업데이트 파일 올리기 → 서명 확인 → 설치 → 재부팅, 온라인 확인/설치, 이전 시스템으로 되돌리기 |
| 로그 | PICO-8, 커널 경고, 업데이트, 블루투스, dmesg |

- lighttpd와 셸 CGI(`/cgi-bin/api`)로 만들었습니다. 업로드는 multipart가 아니라 파일을 요청 본문 그대로 보내고, lighttpd는 이를 메모리에 쌓지 않고 바로 CGI로 넘깁니다.
- 이 페이지에서 고친 설정은 바로 적용됩니다. Wi-Fi 설정은 Wi-Fi를 다시 연결하고, PICO-8 관련 설정은 PICO-8을 다시 시작합니다.

### 처음 Wi-Fi 설정 (설정용 AP)
Wi-Fi 설정이 없거나 40초 안에 연결하지 못하고 유선 연결도 없으면, 콘솔이 **`PICO8-OS-xxxx`** 라는 **WPA2** Wi-Fi를 엽니다.
비밀번호는 콘솔의 설정 카트 info 화면(`Ctrl+Alt+S` / 패드 `SELECT` 2초)과 PICO8DATA 드라이브의 `wifi-setup.txt`에 있습니다. 처음 부팅할 때 무작위로 만들어 상태 파티션에 보관합니다.
폰으로 접속하면 어떤 주소로 가든 Wi-Fi 설정 페이지가 뜹니다(캡티브 포털). 네트워크를 고르고 비밀번호를 넣으면 콘솔이 그 네트워크에 연결하고 AP를 끕니다.
- AP 모드에서는 웹 API가 Wi-Fi 설정 기능만 허용합니다(AP 자체가 WPA2로 보호됨).
- 설정된 네트워크가 잠시 꺼져 있어 AP 모드로 들어갔다면, AP에 접속한 기기가 없을 때 5분마다 원래 네트워크로 다시 연결을 시도합니다.
- 접속한 기기 없이 30분이 지나면 AP를 끕니다(설정 카트의 Wi-Fi 메뉴로 다시 검색, 연결할 수 있음).
- 내장 Wi-Fi가 없는 Pi 1/2는 유선 연결을 쓰면 됩니다.

### 설정 카트
`Ctrl + Alt + S` 또는 패드의 `SELECT`만 2초 누르면 PICO-8이 PICO8-OS 설정 카트로 다시 시작합니다(웹 상태 탭의 "콘솔에서 설정 열기"도 같음).
- 항목: info(버전, 슬롯, IP, 웹 주소와 비밀번호, Wi-Fi, 업데이트) / Wi-Fi 선택 + 화면 키보드로 비밀번호 입력 / 패드 페어링 / 키보드 레이아웃 / 시작 화면 / 종료 동작 / 업데이트 확인·설치 / PICO-8 재시작 / 재부팅 / 전원 끄기
- 조작: ↑↓ 이동, ←→ 값 바꾸기, 🅾️ 선택, ❎ 뒤로/나가기. 나가면 PICO-8이 원래 모드로 다시 시작하며 바뀐 설정이 적용됩니다.
- 카트와 OS 사이 통신: 카트가 `printh("<번호> <명령>", "pico8os_req.txt")`로 요청을 쓰면, `pico8os-agent`가 처리합니다. 결과는 `pico8os_status.p8`(스프라이트 메모리에 `key=value` 텍스트를 넣은 카트)에 쓰고, 카트가 `reload()`로 읽습니다.
  두 파일은 tmpfs(`/run/pico8os/cart`)를 `carts/pico8os/`에 바인드 마운트한 곳에 있어서 SD카드에 쓰지 않습니다.
  macOS용 PICO-8에서 헤드리스(`-x`)로 이 방식을 확인했습니다. `printh` 파일은 실행 방법에 따라 `carts/pico8os/`나 `carts/`에 생기므로 에이전트는 두 곳을 모두 봅니다.

## 언어

| 어디 | 방식 |
|---|---|
| 웹 관리 페이지 / 설정용 AP 페이지 | `www/i18n.js`에 키마다 9개 언어 배열을 둡니다. 오른쪽 위 언어 선택은 브라우저에 기억되고 콘솔의 `LANGUAGE`도 바꿉니다. 처음에는 콘솔 설정, 그다음 브라우저 언어 순서로 고릅니다 |
| 콘솔 설정 카트 | PICO-8 기본 글꼴은 ASCII와 가나만 있어서, 언어마다 **`lang_<코드>.p8` 데이터 카트**를 둡니다. 이 카트에는 그 언어 문구에 쓰이는 글자만 담은 PICO-8 사용자 글꼴(8×8, `0x5600`, 최대 240자)과, 그 글꼴 인코딩으로 쓴 `key=value` 문구가 들어 있습니다 |

- 설정 카트는 `reload()`로 언어 카트를 읽고 글꼴을 `0x5600`에 복사합니다. 번역된 문구는 `\014`(사용자 글꼴)로 출력하고, Wi-Fi 이름이나 IP 같은 값은 PICO-8 기본 글꼴로 출력합니다. 메뉴의 **Language** 항목에서 바로 바꿀 수 있습니다.
- 글자 모양은 [Fusion Pixel Font](https://github.com/TakWolf/fusion-pixel-font) 8px(SIL OFL 1.1)의 ko/zh_hans/ja/latin 변형에서 가져옵니다. Fusion에는 키릴 문자가 없어서, 러시아어는 Fusion 라틴 글자체에 맞춰 직접 그린 [tools/i18n/cyrillic-8px.txt](tools/i18n/cyrillic-8px.txt)를 씁니다. 라틴과 모양이 같은 글자는 라틴 글자를 그대로 씁니다.
- 문구 수정: [tools/i18n/cart-strings.json](tools/i18n/cart-strings.json)을 고치고 `make i18n`을 실행합니다(글꼴을 받아 sha256 확인 후 `lang_*.p8` 다시 생성). 화면 폭을 넘거나 글자 수가 240자를 넘으면 생성기가 멈추고 알려 줍니다. 생성된 카트는 저장소에 들어 있어서 일반 빌드에는 글꼴이 필요 없습니다.
- 현재 글자 수: 한국어 112, 중국어 113, 일본어 113, 러시아어 52자.
- 콘솔 시스템은 문장 대신 **메시지 코드**를 보냅니다(OTA 상태 `ready 2026.12.01-0900`, `error board rpi3 rpi4`, 웹 API `{"code":"connecting","arg":"MyNet"}`, Wi-Fi 상태 `ap:…`/`on:…`/`off`). 웹 페이지(`api_*`, `ota_*`, `ota_err_*`)와 설정 카트(`o_*`, `m_*`)가 각 언어로 바꿔 보여 줍니다.
- 설정 카트는 글자 수 제한 때문에 업데이트 오류의 자세한 이유 없이 "업데이트 오류"만 보여 줍니다. 이유는 웹 업데이트 탭과 `logs/ota.log`에 있습니다.
- 영어로 남는 것: 로그 파일 내용, PICO-8이 설치되기 전 텍스트 콘솔(tty1) 안내 화면과 크래시 안내. 리눅스 텍스트 콘솔 글꼴로는 한중일 문자를 표시할 수 없습니다.

### 웹 글꼴
웹 페이지는 시스템 글꼴 대신 이미지에 넣은 **Noto Sans**(SIL OFL 1.1)로 그립니다. 설정용 AP처럼 인터넷이 없는 곳에서도 같은 모양으로 보입니다.
- `www/fonts/pico8os-latin.woff2`(66 KB)는 라틴, 키릴 등 영역 전체를 담습니다.
- `pico8os-kr`(144 KB), `pico8os-sc`(140 KB), `pico8os-jp`(238 KB)는 페이지에 쓰인 한중일 글자만 담고, JP에는 가나 전체도 넣었습니다. 두께는 400–700입니다.
- 브라우저는 필요한 글꼴만 받습니다(영어 페이지는 라틴 66 KB만). 중국어·일본어 페이지는 한자 모양이 맞도록 해당 글꼴을 먼저 씁니다.
- 부분 글꼴에 없는 글자(예: 한글 Wi-Fi 이름)는 브라우저의 시스템 글꼴로 표시됩니다.
- 문구를 바꾼 뒤 `make webfonts`를 실행하면 다시 만듭니다. google/fonts 커밋과 sha256을 고정해 받고, fontTools는 `.cache/venv`에 설치합니다. 라이선스는 `www/fonts/OFL.txt`에 있습니다.

## OTA 업데이트

```
PICOBOOT/
  config.txt   ... include slot.txt
  slot.txt     os_prefix=a/        ← 이 한 줄로 슬롯을 고름 (Pi 펌웨어 기능, 모든 모델)
  a/  zImage(또는 Image), *.dtb, overlays/(+README), cmdline.txt (root=…p2 pico8os.slot=a)
  b/  같은 구성, root=…p3 pico8os.slot=b
```

1. **업데이트 파일:** 빌드할 때 `pico8os-<보드>-<버전>.pico8os-update`가 함께 나옵니다. tar 하나에 `manifest`, `manifest.sig`, `cmdline.txt.in`, `boot.tar.gz`, `rootfs.ext4.gz`가 들어 있습니다.
   `manifest`에는 보드, 버전, 각 파일의 sha256이 있고, 이 `manifest`만 ECDSA P-256으로 서명합니다.
2. **설치(`pico8os-ota apply`):** 서명 → 보드 → **버전(지금보다 새 버전만, 다운그레이드 거부)** → 파일 해시 → 슬롯 크기를 확인합니다. 그다음 쓰지 않는 슬롯에 rootfs를 기록하고, 커널 파일을 `b.new/`에 풀어 `b/`로 바꿉니다. 마지막으로 `slot.txt`를 새 이름으로 쓴 뒤 바꿔치기합니다.
3. **확인과 되돌리기:** 새 슬롯으로 부팅할 때마다 `S06ota`가 시도 횟수를 셉니다. PICO-8 세션이 45초 이상 돌면 `S99otagood`이 확정합니다. 3번 안에 확정되지 않으면 이전 슬롯으로 `slot.txt`를 되돌리고 재부팅합니다.
4. **설치 경로:**
   - 웹 업데이트 탭에 파일 올리기
   - `PICO8DATA/`나 `PICO8DATA/ota/`에 `.pico8os-update` 넣고 재부팅(설치 후 `.installed`로 이름이 바뀜)
   - 온라인: `OTA_URL`을 설정하면 `<OTA_URL>/latest-<보드>.txt`(`version=…`, `url=…`)를 확인해 받아 설치(웹 또는 설정 카트)
5. **업데이트 서버:** 정적 파일 서버면 충분합니다. 예: `latest-rpi4.txt`와 `pico8os-rpi4-2026.12.01-0900.pico8os-update`를 한 폴더에 둡니다.
   **GitHub Release를 그대로 서버로 쓸 수 있습니다:** `OTA_URL=https://github.com/<계정>/<저장소>/releases/latest/download`.
   단, 공개 저장소일 때만 됩니다. 비공개 저장소의 릴리스 파일은 로그인해야 받을 수 있어서 콘솔이 받지 못합니다.
   ```
   version=2026.12.01-0900
   url=pico8os-rpi4-2026.12.01-0900.pico8os-update
   ```
- 펌웨어 파일(`start*.elf`, `bootcode.bin`)은 업데이트하지 않습니다. 커널, DTB, 오버레이, rootfs만 바뀝니다.
- QEMU에서도 같은 방식으로 동작합니다. `run-qemu.sh`가 `slot.txt`를 읽어 해당 슬롯의 커널과 cmdline으로 부팅합니다.

## 게임패드

PICO-8은 SDL2 게임 컨트롤러 매핑을 씁니다. 이미지에는 [SDL_GameControllerDB](https://github.com/mdqinc/SDL_GameControllerDB)의 Linux 매핑(2026-11-17 커밋 고정)이 들어 있습니다.
직접 만든 매핑은 `PICO8DATA/pico8/sdl_controllers.txt`에 한 줄에 하나씩 넣습니다(PICO-8이 직접 읽음).

SDL2는 **HIDAPI 드라이버를 켜서** 빌드합니다. Buildroot 기본값은 꺼져 있어서 `external.mk`에서 `--enable-hidapi-joystick --enable-hidapi-libusb`로 덮어씁니다.
그러면 PlayStation, Switch, Xbox, Steam 패드 등을 커널 드라이버를 거치지 않고 SDL이 hidraw/libusb로 직접 다룹니다(USB, 블루투스 모두).
버튼 배치가 더 정확해지고, libusb가 필요한 GameCube 정품 USB 어댑터(WUP-028)도 쓸 수 있습니다.
SDL이 처리하지 못하는 패드는 커널 드라이버 경로로 계속 동작합니다.

| 패드 | USB | 블루투스 | 비고 |
|---|---|---|---|
| Xbox 360 / One / Series | ✅ `xpad` | ✅ One/Series (BLE 펌웨어) | Xbox Wireless 어댑터 동글은 미지원 |
| PS3 / PS4 / PS5 | ✅ | ✅ | PS3는 처음 한 번 USB로 연결해야 페어링됨 |
| Switch Pro / Joy-Con | ✅ | ✅ | Joy-Con은 한 짝씩 별도 패드로 동작 |
| 8BitDo 등 서드파티 | ✅ | ✅ | X-input 또는 Switch 모드 권장 |
| 범용 USB 패드 | ✅ | — | 매핑이 없으면 `sdl_controllers.txt` |
| GameCube 정품 USB 어댑터 | ✅ HIDAPI(libusb) | — | 실기기 미검증 |

- **페어링:** 전원을 켠 뒤 60초 안에 패드를 페어링 모드로 두면 자동으로 페어링, 신뢰 등록, 연결합니다.
  키보드에서 `Ctrl + Alt + P`를 누르면 언제든 90초 동안 페어링 창이 열립니다.
  게임패드로 보이는 기기만 페어링합니다(아이콘이 `input-gaming`이거나 이름이 패드처럼 생긴 경우). 결과는 `logs/bluetooth.log`에 남습니다.
- 한 번 페어링한 패드는 다음부터 홈/PS 버튼만 누르면 다시 연결됩니다. 페어링 키는 숨겨진 ext4 상태 파티션에 저장됩니다.
- 블루투스가 안정적으로 동작하도록 PL011 UART를 블루투스에 돌려주고(`miniuart-bt` 오버레이 제거), 시리얼 콘솔은 mini UART(`serial0`, `enable_uart=1`)로 옮겼습니다.
- Pi 0/1/2처럼 블루투스가 내장되지 않은 보드는 USB 블루투스 동글(`btusb`)을 쓰면 됩니다. Broadcom 칩이 아닌 동글은 펌웨어가 따로 필요할 수 있습니다.
- 강제 재시작 단축키(`SELECT + START` 3초)는 SELECT/START를 `BASE3`/`BASE4`로 보내는 범용 패드에서도 동작합니다.

## 보안

| 영역 | 방식 |
|---|---|
| 권한 분리 | PICO-8은 일반 계정 `pico`로 실행합니다(화면, 렌더, 입력, 오디오 장치만 사용 가능). 웹 서버와 CGI도 일반 계정 `www`로 실행합니다(lighttpd). root 권한이 필요한 동작(재부팅, Wi-Fi, 블루투스, OTA, 설정 적용)은 `pico8os-agent`(root)가 정해진 명령만 받아 처리합니다. 명령마다 인자를 검사하고, 통로는 `/run/pico8os/priv`(root:www 0730)입니다. `pico`는 `www` 그룹에 없어서, 카트는 이 통로에 접근할 수 없습니다 |
| 로그인 | root 비밀번호 로그인과 로그인 프롬프트(getty)가 없습니다. `DEBUG=on`일 때만 시리얼 콘솔과 tty1에 root 셸이 열립니다(`pico8os-debugsh`) |
| 웹 HTTPS | lighttpd가 443번 포트에서 TLS 1.2 이상으로 서비스합니다. 인증서는 첫 부팅 때 콘솔에서 만든 자체 서명(P-256) 인증서이고, SHA-256 지문은 PICO8DATA의 `web-certificate.txt`에 있습니다. 처음 접속할 때 브라우저가 경고하면 이 지문과 비교하세요. 80번 포트는 HTTPS로 넘기기만 합니다(설정용 AP 모드만 예외로 HTTP). 응답마다 보안 헤더(CSP, `X-Frame-Options: DENY`, `nosniff`, `no-referrer`, HSTS)를 붙입니다 |
| 웹 로그인 | 브라우저 기본 인증 대신 로그인 화면과 세션 쿠키를 씁니다(192비트 무작위, `HttpOnly; Secure; SameSite=Strict`, 12시간 동안 쓰지 않으면 만료). **비밀번호 대입 방지:** 한 주소에서 5번 틀리면 60초 잠기고, 더 틀릴 때마다 두 배로 늘어 최대 1시간까지 잠깁니다. 전체 주소를 합쳐 20번 틀려도 잠깁니다. 시도마다 1초씩 늦춥니다. 웹 서버(`www`)는 비밀번호 원문을 볼 수 없고, 솔트를 넣은 SHA-256만 받습니다 |
| 웹 CSRF | 상태를 바꾸는 요청은 모두 POST에 `X-Pico8os: 1` 헤더가 있어야 받습니다. 다른 사이트는 CORS 사전 확인 없이 이 헤더를 보낼 수 없고, 이 서버는 사전 확인을 허용하지 않습니다. 브라우저가 보내는 `Origin`도 콘솔 주소와 같아야 합니다 |
| DNS 리바인딩 | 웹 API는 `Host`가 IP 주소나 `pico8os`/`pico8os.local`일 때만 응답합니다 |
| 설정 카트 | 카트가 보내는 요청은 시스템이 설정 카트를 띄웠을 때(단축키나 웹)만 받습니다. 웹 비밀번호가 들어 있는 상태 카트도 그때만 만듭니다. 그래서 인터넷에서 받은 카트는 설정을 바꾸거나 비밀번호를 읽을 수 없습니다. 심볼릭 링크로 된 요청 파일은 거부합니다 |
| OTA | ECDSA P-256 서명 확인, 보드 확인, **다운그레이드 거부**, 3회 부팅 실패 시 자동 롤백 |
| PICO-8 파일 검증 | Lexaloffle은 체크섬을 공개하지 않습니다. 그래서 이 프로젝트가 **검증된 빌드의 파일별 SHA-256 목록**(`pico8-hashes.txt`)을 OTA 키로 서명해 관리합니다. 이미지에 목록 사본이 들어 있고, 콘솔이 GitHub에서 최신 목록을 받아 서명을 확인한 뒤에만 사용합니다. 설치할 때 zip CRC(압축 해제), ELF 형식과 CPU 종류(32비트 ARM / AArch64), 버전, 파일 해시를 확인합니다. **변조되거나 손상된 파일은 항상 거부**하고, 목록에 없는 버전은 `PICO8_VERIFY`에 따라 처리합니다. 이미지에 PICO-8을 미리 넣을 때도 같은 검사를 거칩니다 |
| 설정용 AP | WPA2(무작위 비밀번호), 30분 동안 접속한 기기가 없으면 꺼짐 |
| 저장소 | 시스템 읽기 전용, PICO8DATA는 `pico`(소유자)와 `www`(그룹)만 접근, 그 외 계정은 읽기도 불가. 쓰기 가능한 마운트(PICO8DATA, 상태 파티션, tmpfs)는 모두 `nosuid,nodev`이고 데이터 파티션은 `noexec`까지 걸어서, 실행 파일을 올려도 실행되지 않습니다 |
| 커널 하드닝 | `linux-harden.fragment`: `/dev/mem`·`/dev/port`, kexec, 최대 절전, 사용자 네임스페이스, io_uring, binfmt_misc, uselib을 빼고 커널 로그를 root 전용으로 둡니다. `/etc/sysctl.d/90-pico8os.conf`: 커널 포인터 숨김, dmesg 제한, SysRq 끔, BPF 제한, 링크·FIFO 보호, setuid 코어 덤프 금지, oops 때 재부팅, ICMP 리다이렉트·소스 라우팅 거부, SYN 쿠키 등 |
| 공격 표면 | 열려 있는 포트는 웹(443, 80은 HTTPS로 넘기기만 함)뿐입니다. dnsmasq는 설정용 AP일 때만 실행합니다. 커널에서 쓰지 않는 서브시스템(네트워크 필터, 원격 파일시스템, 미디어 등)은 뺐습니다 |

**PICO-8 검증 목록에 새 버전 추가하기:** Lexaloffle에서 직접 받은 zip으로 아래처럼 실행한 뒤 `pico8-hashes.txt`와 `.sig`를 커밋합니다. 콘솔은 다음 확인 때 새 목록을 받아 씁니다.

```bash
scripts/pico8-hashes.sh add pico-8_0.2.8_raspi.zip
```

```bash
scripts/pico8-hashes.sh sign
```

**하지 않은 것:**
- Pi 4/5의 하드웨어 보안 부팅(secure boot): 보드 OTP에 한 번 쓰면 되돌릴 수 없어서 자동으로 켜지 않습니다.
- 웹 페이지의 인라인 스크립트 때문에 CSP에 `'unsafe-inline'`이 남아 있습니다. 스크립트를 별도 파일로 옮기면 뺄 수 있습니다.
- 공인 인증서가 아닌 자체 서명 인증서라서, 처음 접속할 때 브라우저 경고가 나옵니다(가정 내 네트워크에서는 피할 수 없음).

## 부팅 속도

- **2단계 부팅:** `rcS`는 S00–S20만 실행합니다(데이터 마운트, OTA 부팅 확인, udev, 워치독, 단축키). 곧바로 PICO-8을 띄우고, 나머지(네트워크, Wi-Fi, 블루투스, 웹, 시간 동기화, 상태 감시)는 `rc.late`가 **동시에** 뒤에서 시작합니다. 빌드할 때 post-build가 S21 이상을 `/etc/init.d/late/`로 옮깁니다.
- **커널:** 쓰지 않는 서브시스템을 빼서 모듈이 절반으로 줄었습니다. 화면 드라이버 vc4와 사운드 코어는 커널에 직접 넣습니다(`linux-fastboot.fragment`). 커널 의존성 때문에 넣지 못하면 모듈로 남고, 빌드 로그에 결과가 나옵니다.
- **측정:** 부팅마다 `logs/boot.log`에 커널 부팅 시간(init 시작 시각)과 PICO-8 시작 시각을 남깁니다(최근 50회).
- **펌웨어와 커널 옵션:** `initial_turbo=60`(처음 60초는 최고 클럭으로 부팅), Pi 4 `arm_boost=1`, 부팅 옵션 `rootfstype=ext4`(파일시스템 종류를 추측하지 않음)를 씁니다.
- **실행 속도:** 게임 중 CPU 정책을 `performance`로 둡니다(`CPU_GOVERNOR`). 발열이나 전원 부족 때 펌웨어가 클럭을 낮추는 것은 그대로입니다.

## 안정성 (PICOPi에서 프리징이 나던 원인과 대책)

| 원인 | 대책 |
|---|---|
| Splore 다운로드에서 멈춤 (TLS 없는 busybox wget, 타임아웃 없음, Wi-Fi와 시계 없음) | GNU wget + OpenSSL + CA 인증서, `/etc/wgetrc`에 `timeout=15 tries=2`, ntpd, Wi-Fi |
| FAT를 `sync`로 마운트해서 쓰기마다 I/O 대기 | 데이터 파티션을 `flush`로 마운트, 시스템은 읽기 전용 |
| 커널이 멈춰도 복구 수단 없음 | 하드웨어 워치독, `panic=10 softlockup_panic=1` |
| PICO-8만 멈춤 (커널은 정상) | 강제 재시작 단축키 (`pico8-hotkey`), 종료 후 VT 키보드 복구 |
| 원인을 알 수 없음 | `logs/kernel.log`에 under-voltage, 스로틀링, SD 오류, OOM, lockup 기록 |
| 키보드 레이아웃이 PICO-8에 반영되지 않음 (SDL 2.0.7은 콘솔 키맵을 무시) | 최신 SDL2는 VT 키맵으로 문자를 만듦 + `kbd` 키맵 전체 + `KEYMAP=` |

## QEMU 에뮬레이션

**QEMU로 테스트할 수는 있지만, 라즈베리파이 머신 에뮬레이션(`-M raspi*`)으로는 PICO-8 화면을 띄울 수 없습니다.**
QEMU의 `raspi0/1ap/2b/3b/4b`는 VC4/V3D GPU와 HVS 디스플레이 파이프라인을 에뮬레이션하지 않아서
KMS(`/dev/dri`)가 생기지 않고, PICO-8이 쓰는 SDL2 kmsdrm도 동작하지 않습니다(펌웨어 프레임버퍼 `/dev/fb0`만 있음).

그래서 `qemu` 타깃은 **같은 armhf ABI의 유저랜드를 QEMU `virt` 머신에 올립니다.**
virtio-gpu, 키보드, 태블릿, sound를 붙여서 설치기, 런처, SDL2 kmsdrm, ALSA까지 실제와 같은 경로로 시험할 수 있습니다
(GPU가 없으므로 Mesa softpipe로 소프트웨어 렌더링).

```bash
make docker-qemu
```

```bash
./scripts/run-qemu.sh --zip ~/Downloads/pico-8_0.2.6b_raspi.zip
```

- `--zip`은 PICO8DATA 파티션에 zip을 복사합니다. 이 스크립트는 `mtools`가 필요합니다(`sudo port install mtools`).
- 웹 관리 페이지는 `http://localhost:8080`으로 열립니다.
- 게스트가 재부팅하면 QEMU를 끝내고 `slot.txt`를 다시 읽어 부팅합니다(OTA 시험용).
- `--fresh`는 깨끗한 이미지로 다시 시작합니다.
- 이 터미널이 시리얼 콘솔입니다. 종료하려면 `Ctrl-A X`를 누르세요.

QEMU로 확인할 수 없는 것: 라즈베리파이 펌웨어 부팅(`config.txt`), vc4/v3d 드라이버, HDMI 오디오, Wi-Fi. 이 부분은 실기기에서 확인해야 합니다.

## 구조

```
Makefile                      보드별: upstream raspberrypiN_defconfig + fragments → defconfig → 빌드
external/                     BR2_EXTERNAL (name: PICO8OS)
  fragments/                  common / rpi-common / 보드별 Kconfig 조각
  board/rpi/                  config.txt, cmdline.txt, genimage, post-image
  board/qemu/                 커널 virtio 조각, genimage, post-image
  board/common/               post-build (tty1 세션, PICO-8 굽기, 보드/버전/공개 키), 부트 파티션(A/B) 구성,
                              데이터 파티션 내용, OTA 번들 생성(make-update.sh), busybox(ntpd, httpd)
  rootfs-overlay/
    usr/bin/pico8-session     런처 (키맵/바이너리/오디오/비디오 선택, 종료 동작, 크래시 가드, 로그)
    usr/bin/pico8-install     zip/폴더 설치 (PICO8DATA / USB), 없으면 안내 화면
    usr/lib/pico8os/lib.sh    설정 파서(화이트리스트, eval 없음), 설치 함수
    etc/init.d/S05picodata    PICO8DATA를 /data에 마운트 (fsck 포함)
    etc/init.d/S15watchdog    하드웨어 워치독
    etc/init.d/S41wifi        Wi-Fi 연결
    etc/init.d/S49ntp         시간 동기화 (RTC 없음 → HTTPS용)
    etc/init.d/S60healthmon   커널 경고를 logs/kernel.log에 기록
    etc/init.d/S45btpair      블루투스 끄기 / 부팅 후 자동 페어링 창
    etc/init.d/S16hotkey      강제 재시작 / 페어링 / 설정 단축키 데몬 시작
    etc/init.d/rc.late        2단계 부팅: S21 이상을 PICO-8과 동시에 시작
    usr/sbin/pico8os-debugsh  시리얼 콘솔 (DEBUG=on일 때만 root 셸)
    usr/bin/pico8-btpair      주변 게임패드 자동 페어링
    etc/bluetooth/            BlueZ 설정 (AutoEnable, 재연결, ClassicBondedOnly=false)
    etc/wgetrc                Splore 다운로드 타임아웃
    etc/init.d/S06ota         새 슬롯 부팅 횟수 확인/되돌리기, 넣어 둔 업데이트 파일 설치
    etc/init.d/S80pico8os      웹 서버 + 설정 카트 에이전트
    etc/init.d/S99otagood     정상 동작 확인 후 새 슬롯 확정
    usr/sbin/pico8os-ota       OTA (verify/apply/check/download/boot-check/mark-good/rollback)
    usr/sbin/pico8os-web       웹 서버 시작 (인증 / AP 모드)
    usr/sbin/pico8os-wifi      Wi-Fi 클라이언트 / 설정용 AP / 검색
    usr/sbin/pico8os-agent     설정 카트 요청 처리, 상태 카트 생성
    usr/sbin/pico8os-apply     바뀐 설정 즉시 적용
    usr/share/pico8os/www/     웹 페이지(index.html, setup.html, i18n.js, fonts.css, fonts/), cgi-bin/api
    usr/share/pico8os/cart/    설정 카트 pico8os.p8, 언어 카트 lang_*.p8, 글꼴 라이선스
  package/pico8-hotkey/       단축키 데몬 (C, evdev, 키보드/게임패드 핫플러그 지원)
  package/sdl-gamecontrollerdb/  SDL_GameControllerDB (커밋 고정, sha256 검증)
  boot-files/                 PICO8DATA에 처음 들어가는 pico8os.txt, README.txt
pico8-hashes.txt(.sig)        검증된 PICO-8 빌드의 파일별 SHA-256 (OTA 키로 서명, scripts/pico8-hashes.sh)
external/board/common/users.table   계정: pico(PICO-8), www(웹)
external/board/rpi/linux-fastboot.fragment  화면 드라이버를 커널에 직접 넣음
external/board/rpi/linux-harden.fragment    커널 하드닝 (/dev/mem, kexec, user ns, io_uring 등 제거)
external/rootfs-overlay/etc/sysctl.d/90-pico8os.conf  sysctl 하드닝
tools/gen-cart-lang.py        언어 카트 생성기 (make i18n)
tools/gen-webfonts.py         웹 글꼴 부분 집합 생성기 (make webfonts)
tools/i18n/                   설정 카트 문구(cart-strings.json), 키릴 문자 글리프
docs/survey.md                PICOPi 분석과 유사 프로젝트 조사
docker/Dockerfile, scripts/   Docker 빌드, QEMU 실행
```

## 아직 확인되지 않은 것 / TODO

- 실제 전체 빌드와 실기기 부팅은 아직 해보지 않았습니다. 6개 타깃 모두 Buildroot `defconfig` 단계에서 옵션이 빠짐없이 해석되는 것까지만 확인했습니다.
- 32-bit 정적 `pico8`과 `pico8_64`는 `SDL_DYNAMIC_API`로 시스템 SDL2(kmsdrm)를 쓰게 했지만, 실제로 동작하는지는 확인하지 않았습니다.
- `pico8-hotkey`는 ARM 32/64비트용으로 경고 없이 컴파일되는 것까지만 확인했고, 실기기에서 눌러 보지는 않았습니다.
- 블루투스 페어링은 가짜 `bluetoothctl`로 스크립트 흐름만 시험했습니다. 실제 패드와의 페어링, UART 블루투스(`hci_uart`) 초기화는 실기기에서 확인해야 합니다.
- SDL HIDAPI는 Buildroot 변수 전개로 옵션과 빌드 순서(libusb가 먼저 빌드됨)까지만 확인했습니다. 실제 빌드와 패드 동작은 확인하지 않았습니다.
  Buildroot를 올리면서 `sdl2.mk`가 바뀌면 `external.mk`의 덮어쓰기 부분을 다시 확인해야 합니다.
- OTA, 웹 API, 설정 카트는 이 Mac에서 다음까지 시험했습니다.
  - OTA: 테스트 번들로 서명/보드/변조 거부, 슬롯 기록, 슬롯 전환, 3회 실패 후 되돌리기, 정상 확정
  - 웹 API: 가짜 명령으로 JSON, URL 디코딩, 경로 공격 차단, AP 모드 제한
  - 설정 카트: macOS용 PICO-8 헤드리스로 `printh`/`reload` 통신
  - 언어: 4개 언어(ko, zh, ja, ru) 설정 카트 화면을 PICO-8 헤드리스로 그려 확인, 웹 9개 언어 키 누락 검사
  genimage의 확장 파티션 생성은 첫 CI 빌드 이미지에서 확인했습니다. 실제 Pi에서의 `os_prefix` 슬롯 전환, hostapd AP, lighttpd(HTTPS, 큰 파일 업로드)는 실기기에서 확인해야 합니다.
- 보안·부팅 1·2차 변경(권한 분리, CSRF, HTTPS 로그인과 대입 방지, 2단계 부팅, PICO-8 검증, 커널 하드닝 등)은 이 Mac에서 스크립트 단위로만 시험했습니다(웹 API 요청 규칙, 에이전트 명령 검사, PICO-8 0.2.7 실제 파일 검증, inittab 변환). 실제 Pi에서 `pico` 계정으로 PICO-8이 화면, 입력, 소리를 정상적으로 쓰는지는 빌드 후 확인해야 합니다.
- 앞으로 할 일: SSH, 게임패드 매핑(`gamecontrollerdb.txt`), 부팅 스플래시, 전원 버튼(GPIO) 종료.
