# 유사 프로젝트 조사 (2026-11-18)

## 1. 기존 프로젝트 `../picopi-rpi3` 분석

`../picopi-rpi3`는 **gamaral(Guillermo A. Amaral)의 PICOPi** rpi3 배포판입니다. `pico.pi` 파일의 SHA-1이
[keints/picopi](https://github.com/keints/picopi)에 보관된 `picopi-rpi3.zip` 속 파일과 같습니다. 여기에 PICO-8 0.2.7(2025-08)을 덮어 넣은 상태입니다.

| 항목 | PICOPi (2018-01) | 확인 방법 |
|---|---|---|
| 빌드 | Buildroot 2017.11.1, Linux 4.9.76, rootfs를 initramfs로 커널(`pico.pi`)에 내장 | 커널 압축 해제 → `Linux version` 문자열, cpio 추출 |
| 펌웨어 | 2018-01 `start.elf`, DTB는 `bcm2710-rpi-3-b`와 `cm3`뿐 (3B+는 2018-03 출시) | 파일 목록 |
| 그래픽 | SDL 2.0.7 RPI 백엔드 (dispmanx, 레거시 `libbrcmEGL`) | `libSDL2-2.0.so.0.7.0` 심볼 |
| 실행 | inittab `::sysinit:/usr/sbin/pico8` → 종료하면 `poweroff`(재시작 없음) | `/etc/inittab` |
| 저장소 | 단일 FAT 파티션을 `-o rw,exec,sync`로 `/mnt`에 마운트, PICO-8 home도 여기 | `/usr/sbin/preco8`, `/usr/sbin/pico8` |
| 네트워크 | Wi-Fi 없음(wpa_supplicant 없음), 시간 동기화 없음 | 파일 목록 |
| wget | busybox wget, TLS 없음 (`ssl_client`, libssl 없음) | 파일 목록 |
| 키맵 | `config.txt`의 `keymap=`로 `loadkeys` 실행 (keymap 216개 포함) | `/usr/sbin/pico8` |

### 키보드 레이아웃이 안 먹던 이유

- `loadkeys`는 **리눅스 콘솔 키맵**만 바꿉니다.
- SDL 2.0.7의 evdev 키보드는 콘솔 키맵을 읽지 않습니다. 라이브러리 안에 `/dev/tty`를 여는 코드가 없습니다.
  콘솔 키맵을 읽어 문자를 만드는 코드(`SDL_evdev_kbd`)는 그 뒤 버전에서 들어왔습니다.
  그래서 PICO-8 편집기와 콘솔에서는 레이아웃과 상관없이 US 배열로 입력됐을 가능성이 큽니다.
- 레이아웃 이름도 `config.txt`(펌웨어 설정 파일)에 섞어 넣는 방식이었습니다.

→ **PICO8-OS 조치:** 최신 SDL2(2.30대)를 씁니다. 이 버전은 VT의 커널 키맵을 읽어 문자를 만듭니다.
`kbd` 패키지로 키맵 전체를 넣고, `pico8os.txt`에 `KEYMAP=`을 두고, PICO-8을 시작할 때마다 tty1에서 `loadkeys`를 실행합니다.
이름이 틀리면 `us`로 돌아가고 로그를 남깁니다.

### 프리징 원인 후보 (영향이 큰 순서)

1. **Splore/BBS 다운로드:** PICO-8은 다운로드할 때 `wget`을 부릅니다(`readme_raspi.txt`).
   카트는 `https://carts.lexaloffle.com/...`에서 받는데, 이 이미지는 TLS가 없는 busybox wget에 네트워크도 시계도 없습니다.
   wget에 타임아웃도 없어서 연결이 멈추면 Splore가 같이 멈춥니다.
   포럼에서도 "Splore 메뉴에서 꽤 높은 확률로 그냥 멈춘다"는 보고가 있습니다.
2. **FAT `sync` 마운트:** 쓰기를 할 때마다 동기식으로 FAT를 갱신합니다.
   PICO-8이 세이브(cdata), 설정, BBS 캐시를 쓰는 동안 메인 스레드가 SD카드 I/O를 기다리며 멈춥니다.
3. **2018년 펌웨어/커널과 레거시 dispmanx 그래픽 스택**에 2025년 PICO-8 0.2.7을 올린 조합입니다.
   전원 부족(under-voltage)이나 발열로 인한 스로틀링이 생겨도 기록하거나 복구하는 장치가 없습니다.
4. **복구 장치 없음:** 하드웨어 워치독을 쓰지 않습니다. PICO-8이 죽으면 그대로 전원이 꺼집니다.

→ **PICO8-OS 조치:**
- GNU wget과 OpenSSL, CA 인증서를 넣고 `/etc/wgetrc`에 `timeout=15`, `tries=2`를 둡니다. busybox ntpd로 시계를 맞추고, Wi-Fi도 지원합니다.
- 3-파티션 구조로 바꿨습니다. 부트 파티션은 마운트하지 않고, rootfs는 읽기 전용입니다. 데이터는 FAT32로 따로 두고 `sync` 대신 `flush`로 마운트합니다.
- 하드웨어 워치독(`S15watchdog`)을 켜고, 커널에 `panic=10 softlockup_panic=1`을 줍니다.
- 커널 경고(under-voltage, 스로틀링, SD 오류, OOM, lockup)를 `PICO8DATA/logs/kernel.log`에 남깁니다.
- PICO-8 비정상 종료 로그를 남기고 자동으로 재시작하며, 연속으로 크래시하면 셸로 넘어갑니다.

## 2. 유사 프로젝트 전수조사

### A. 라즈베리파이를 PICO-8 전용으로 부팅하는 이미지/스크립트

| 프로젝트 | 최근 활동 | 기반 | 대상 | 특징 / 한계 |
|---|---|---|---|---|
| [PICOPi (gamaral)](https://github.com/keints/picopi) | 2018 (보관본 2021) | Buildroot 2017.11 | Pi 1/2/3 | 위 분석 참조. 원 사이트는 사라졌고 keints가 보관본을 올려 둠 |
| [paloblanco/rpi-buildroot](https://github.com/paloblanco/rpi-buildroot) | 2020-05 | gamaral rpi-buildroot 포크 | Pi 1/2/3 | PICOPi 빌드 산출물 재배포, 기능 변경 없음 |
| [billyohgren/pico-8-nano-2w](https://github.com/billyohgren/pico-8-nano-2w) | 2026-09 | Buildroot 2026.02.3 | Zero 2 W만 | 가장 유사함. armhf, SDL2 KMSDRM + vc4, **squashfs 읽기 전용 루트 + ext4 `/data`**, Wi-Fi(`wifi.txt`), SSH. 키맵 없음, busybox wget(HTTPS 미지원, Buildroot 기본 설정), "실기기 부팅 미검증"이라고 명시 |
| [georgduees/picoos](https://github.com/georgduees/picoos) | 2026-10 | Buildroot | Zero W / Zero 2 W | 초기 단계(계획 문서와 defconfig 정도). A/B 업데이트(SWUpdate), 설정용 AP, HUB75 매트릭스 UI 계획 |
| [anthonycaccese/pico8-desktop-console](https://github.com/anthonycaccese/pico8-desktop-console) | 2024-07 | Raspbian Buster Lite + 스크립트 | Pi Zero W | 첫 부팅 때 설정 후 Splore로 재부팅. 720x720 화면용 설정 |
| [Astorek86/Pico8-Script-for-GPi-Case](https://github.com/Astorek86/Pico8-Script-for-GPi-Case) | 2020-02 | Raspbian + 스크립트 | GPi Case (Zero) | 위 프로젝트의 원조 |
| [isacben/picoboy-dev](https://github.com/isacben/picoboy-dev) | 2024-01 | (하드웨어 개발 중) | Pi Zero | 휴대기기 하드웨어 개발 로그, OS 없음 |
| [Lexaloffle BBS 가이드](https://lexaloffle.com/bbs/?pid=145746) 외 | 다수 | Raspberry Pi OS Lite 자동 실행 | 전 기종 | 수동 설정. 부팅이 느리지만 안정적이라는 평 |
| [Pi Zero PICO-8 휴대기기 + 시계](https://www.lexaloffle.com/bbs/?pid=194905) | 2025 | Raspberry Pi OS | Zero | 커뮤니티 제작기 |

### B. PICO-8 전용 런처 / 다른 하드웨어용 최소 OS

| 프로젝트 | 내용 |
|---|---|
| [pex-labs/picolauncher](https://github.com/pex-labs/picolauncher) (2025-04) | PeX Console용 PICO-8 기반 런처와 "OS"(Rust). Splore를 새로 만들고 갤러리를 넣음. x86_64, aarch64, armv7 바이너리 제공. 현재 Chromium이 필요함 |
| [eczarny/picosh](https://github.com/eczarny/picosh) (2023-03) | ClockworkPi GameShell용 최소 PICO-8 OS (multistrap 기반) |

### C. PICO-8 정품 바이너리를 쓸 수 있는 범용 레트로 OS

| OS | PICO-8 지원 방식 |
|---|---|
| [Batocera](https://wiki.batocera.org/systems:pico8) | 정품 바이너리를 `bios`에 넣음. 오픈소스 코어(fake-08/retro8)도 있음 |
| [Recalbox](https://wiki.recalbox.com/en/emulators/fantasy/pico-8) | 정품 바이너리를 BIOS 폴더에 넣으면 사용 가능. 기본은 retro8, 대안은 fake-08 |
| RetroPie | 수동 설정 (EmulationStation 시스템 항목 추가) |
| [Knulli](https://knulli.org/systems/pico-8) / [muOS](https://muos.dev/systems/fantasy/pico8) / [ROCKNIX](https://rocknix.org/systems/pico-8/) | 휴대용 게임기용. 라즈베리파이용 zip의 `pico8_64`를 씀 |
| [Onion (Miyoo Mini)](https://onionui.github.io/docs/emulators/pico-8-standalone) / spruceOS | 라즈베리파이용 `pico8_dyn` 래퍼 |
| Lakka | 공식적인 정품 PICO-8 지원은 확인되지 않음 (retro8 libretro 코어만) |

### D. PICO-8을 기본 탑재한 상용 하드웨어

- **PocketCHIP** (Next Thing Co., 단종): PICO-8이 미리 설치돼 출시됐습니다.
- **ClockworkPi GameShell / DevTerm / uConsole**: 공식 위키에 PICO-8 설치 안내가 있습니다 ([wiki](https://wiki.clockworkpi.com/Pico-8)).
- **Pimoroni Picade**: PICO-8 라이선스가 동봉되지만 소프트웨어는 RetroPie를 권장합니다 ([shop](https://shop.pimoroni.com/products/picade)).

### E. 오픈소스 PICO-8 재구현 (정품 없이 실행)

- [fake-08](https://github.com/jtothebell/fake-08) (MIT, libretro 코어 있음): 호환성이 가장 넓다는 평이 많습니다.
- [retro8](https://github.com/libretro/retro8) (GPL-3.0): 가볍지만 오래되고 단순한 카트만 잘 돌아갑니다.
- [zepto8](https://github.com/samhocevar/zepto8): 정확도가 높다는 평이 있습니다. fake-08 오디오가 여기서 왔습니다.

## 3. PICO8-OS에 반영한 점과 차별점

- **pico-8-nano-2w에서 가져온 것:** 읽기 전용 루트와 쓰기용 데이터 파티션을 분리했습니다(전원을 그냥 뽑아도 시스템이 깨지지 않음).
  다만 데이터 파티션은 ext4가 아니라 **FAT32**로 만들어서 Windows나 macOS에서 바로 카트와 설정을 편집할 수 있게 했습니다.
  압축을 푼 `pico-8` 폴더를 그대로 넣어도 설치되게 했습니다.
- **PICOPi의 장점을 유지한 것:** zip이나 폴더만 넣으면 끝나는 설치, 빠른 부팅, 화면에는 PICO-8만 보이는 점, 종료 동작 설정.
- **다른 프로젝트에 없는 것:**
  - Pi 0/1부터 5까지 지원하는 6개 타깃과 QEMU 테스트 이미지
  - 키맵 설정
  - HTTPS가 되는 wget과 타임아웃
  - 워치독과 커널 경고 로그
  - 크래시 가드
  - USB 메모리로 설치
- **아직 다른 프로젝트보다 부족한 것:** SSH 접속(nano-2w), A/B 업데이트(picoos 계획), 새로 만든 Splore UI(picolauncher).
