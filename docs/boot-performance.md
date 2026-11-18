# PICO8-OS 부팅 속도: 타 프로젝트 비교와 실험 계획

2026-11-19 조사. 목표는 **전원 인가부터 PICO-8 화면에서 첫 입력이 먹을 때까지**다. 스플래시 등장, 셸 프롬프트, PICO-8 프로세스 시작, Splore의 온라인 접속 완료는 각각 다른 시점이다. 일반 부팅, 최초 설치, OTA 적용·시험 부팅도 별도로 비교한다.

## 공개 사례 비교

기존 [유사 프로젝트 목록](survey.md)을 바탕으로 PICO-8 전용 배포판, 게임·미디어 OS, Pi 고속 부팅 데모, 현재 사용하는 Buildroot 버전의 초기화 스크립트를 대조했다. 아래 시간은 각 저자가 보고한 값이다. 동일한 보드·SD·HDMI로 여러 OS를 직접 측정한 결과가 아니다. 공개 프로젝트 전체를 망라하거나 이 표로 PICO8-OS의 시간을 산출할 수는 없다.

| 프로젝트·원자료 | 확인한 내용 | PICO8-OS에 적용할 판단 |
| --- | --- | --- |
| [PICO-8 Desktop Console](https://github.com/anthonycaccese/pico8-desktop-console#boot-time) | Zero W 기반 Raspbian Buster Lite → Splore. 작성자 후속 부팅 **30~40초**. 일회성 설치 스크립트는 다음 부팅에서 빠진다. 측정 종료점은 엄밀히 정의되지 않았다. | 같은 앱이라는 점에서 가장 가까운 시간 자료. 정상 부팅에서 설치가 끝난 작업을 빼는 구조가 유용하다. Pi 4의 예상치로 환산하지 않는다. |
| [PICOPi 보관본](https://github.com/keints/picopi), [기존 이미지 분석](survey.md) | Buildroot·내장 initramfs에서 PICO-8 직접 실행. 분석한 구버전에는 Wi-Fi와 현대식 KMS 스택이 없다. 비교 가능한 시간 없음. | 런처를 한 겹 더 두지 않는 장점은 이미 적용했다. 전체 rootfs를 RAM으로 옮기면 펌웨어가 먼저 읽을 바이트와 메모리 사용량도 늘어난다. |
| [pico-8-nano-2w](https://github.com/billyohgren/pico-8-nano-2w) | Zero 2 W, Buildroot, 읽기 전용 SquashFS와 별도 데이터 영역. README가 실기기 미부팅이라고 명시한다. | SquashFS는 SD 읽기가 병목일 때의 비교 후보. 지금은 `/opt/pico8` 설치 위치와 A/B 슬롯 형식까지 바꿔야 하므로 첫 실험으로 부적합하다. |
| [GPi Case용 PICO-8](https://github.com/Astorek86/Pico8-Script-for-GPi-Case), [picosh](https://github.com/eczarny/picosh) | 전자는 Pi용 설치 스크립트, 후자는 GameShell용 multistrap 기반 OS. 확인한 README에 동일 조건 측정 없음. | 설치 자동화와 OS 경량화 자체를 부팅 시간의 증거로 쓰지 않는다. |
| [RetroPie autostart](https://github.com/RetroPie/RetroPie-Setup/blob/master/scriptmodules/supplementary/autostart.sh), [Batocera ES 초기화](https://github.com/batocera-linux/batocera.linux/blob/master/package/batocera/emulationstation/batocera-emulationstation/S31emulationstation) | RetroPie에는 자동 로그인 뒤 프런트엔드를 띄우는 경로가 있다. Batocera는 ES를 별도 서비스로 관리하고 준비 상태를 나타내는 파일을 사용한다. | PICO8-OS는 직접 실행을 유지한다. 대신 **프로세스 생성과 UI 준비를 구분**하는 측정 방법을 차용한다. |
| [LibreELEC Kodi 서비스](https://github.com/LibreELEC/LibreELEC.tv/blob/master/packages/mediacenter/kodi/system.d/kodi.service) | Kodi에 `After=network-online.target graphical.target` 순서가 있다. `After` 자체가 네트워크를 필수로 활성화한다는 뜻은 아니다. | 오프라인 카트 첫 화면은 네트워크보다 앞서도 된다. 현재의 2단계 부팅을 유지하고 Wi-Fi 준비 시간을 별도로 기록한다. |
| [Furkan Tokaç의 Pi 3 Buildroot 실험](https://www.furkantokac.com/rpi3-fast-boot-less-than-2-seconds/) | 고속 촬영 기준 기본 이미지 **전원→Qt 앱 10.17초**, 최적화 **2.82초**, 최적화 셸 **1.75초**. 커널 구간 5.12→0.25초, init 구간 0.12→0초. USB·네트워크·사운드 등을 제거했다. | 차용할 것은 **구간을 나눠 실측하는 방법**이다. 이 사례에서 init 자체를 없애 얻은 것은 0.12초였다. 정품 PICO-8, 패드, HDMI 오디오, Splore를 유지하는 목표에 2.82초를 대입하면 안 된다. |
| [BMC64](https://github.com/randyrossi/bmc64), [Circle](https://github.com/rsta2/circle) | BMC64는 Linux 없는 베어메탈 에뮬레이터로 C64 화면까지 **컴포지트 출력 4.1초**를 보고한다(Pi 0/2/3 계열 한정 표기). Circle도 베어메탈 환경이다. | HDMI 표시 지연과 Linux 사용자 공간이 없는 수치다. 정품 Linux 바이너리를 실행해야 하는 프로젝트의 대체 OS가 아니다. |

## 적용 우선순위

1. **가장 먼저 잴 대기: `S10udevd`.** [Buildroot 2026.02.3 원본](https://github.com/buildroot/buildroot/blob/2026.02.3/package/eudev/S10udevd)은 모든 하위 시스템과 장치에 이벤트를 보내고 `udevadm settle`을 호출한다. 기본 30초는 **상한**이다. 현재 `post-build.sh`는 S20까지 첫 단계에 남기므로 이 호출은 PICO-8보다 앞선다. 실제 대기가 크면 udev 시작과 이벤트 발생은 유지하되, 전체 큐 대신 **실행 계정이 열 수 있는 DRM/KMS 장치, 오디오 선택, 입력 및 워치독 준비**만 필요한 시점에 기다리는 버전을 비교한다. `pico8-session`은 오디오 카드가 아직 없으면 해당 세션을 `dummy`로 고정하고, `S15watchdog`은 장치가 없으면 종료한다. 따라서 단순히 타임아웃을 0으로 바꾸면 기능이 달라진다.
2. **가장 먼저 고칠 저위험 비용: 설정 반복 파싱과 무변경 쓰기.** [Bootlin의 BusyBox 최적화 자료](https://github.com/bootlin/training-materials/blob/master/slides/boot-time-init-scripts/boot-time-init-scripts.tex)는 앱 시작 전 의존성만 남기고 셸에서 생성하는 외부 프로세스를 줄일 것을 권한다. 여기서는 `lib.sh:parse_conf`가 주석을 버리기 전부터 줄마다 `tr`을 실행하고 실제 키에는 `sed` 등을 더 실행한다. 워치독·핫키·런처·설치기가 각각 다시 읽는다. 한 번의 파싱으로 처리하거나 필요한 키만 읽고, `strip_conf`는 제거할 키가 없으면 임시 파일 생성과 `sync` 전에 반환하게 한다. CRLF, 인용부호, 주석, 중복 키, root 전용 정책의 분리, PC에서 편집한 설정의 다음 부팅 반영을 회귀 검사한다. 공유 설정 파일을 셸 코드로 실행하지 않는다.
3. **설치 완료 ZIP의 전체 읽기를 일반 부팅에서 제외.** `pico8-install`은 ZIP이 남아 있으면 설치가 끝난 뒤에도 전체 해시를 읽는다. 먼저 **동일 SD에서 설치 ZIP만 있는 경우/없는 경우**를 비교한다. 자동화하려면 정상 설치가 끝난 패키지를 후보 검색 밖에 보관하되, A/B 전환 후 새 슬롯에 PICO-8이 없으면 보관본으로 복구해야 한다. 새 ZIP, 폴더·USB 설치, 실패 후 재시도, 이전 슬롯 복귀까지 유지한다. 보관본을 다시 설치할 때도 서명 목록 검증을 그대로 적용한다.
4. **FAT 검사와 그래픽 대기를 따로 측정.** `S05picodata`의 `fsck.vfat -a -w`는 동기 실행이다. `pico8-session`의 커넥터 대기 상한은 약 5초지만 이미 준비됐으면 즉시 통과한다. 전자는 정상 종료와 전원 차단 후를 구분하고, 후자는 실제 `/dev/dri` 권한과 HDMI 오디오까지 확인한다. 복구 검사를 마운트된 FAT에서 백그라운드로 돌리거나 그래픽 타임아웃만 줄이지 않는다.
5. **펌웨어·커널 변경은 잔여 병목에만.** Pi 4 설정에는 이미 `boot_delay=0`, `disable_splash=1`, `initial_turbo=60`이 있다. 커널 fragment는 VC4·사운드 내장을 요청한다. 최종 보드 `.config`를 확인하고 진단 이미지에서만 [`initcall_debug`와 bootgraph](https://github.com/torvalds/linux/blob/master/scripts/bootgraph.pl) 또는 [커널 부팅 추적](https://docs.kernel.org/trace/boottime-trace.html)으로 느린 드라이버를 찾는다. SD 순차 읽기가 병목일 때만 압축 형식을 비교한다. Pi 3의 DTB·펌웨어 기법을 Pi 4/5 공통 기본값으로 옮기지 않는다.

## 다음 빌드의 측정과 채택 기준

- **시작·끝:** 같은 전원, SD 카드, HDMI 모니터, 입력 장치로 전원 인가→첫 프레임→입력 반응을 영상으로 기록한다. 첫 입력은 네트워크와 무관한 로컬 카트로 측정하고, 기본 Splore 모드도 별도 측정한다.
- **구간:** 기존 `logs/boot.log`의 커널 기준 시각에 `/proc/uptime` 마커를 추가한다. FAT 검사 전후, 설정 처리 전후, udev trigger/settle 전후, 설치 확인 전후, KMS·ALSA 준비, PICO-8 실행 직전을 구분한다. `/run`에 기록한 뒤 나중에 저장해 계측이 SD 쓰기 병목을 만들지 않게 한다.
- **비교:** 우선 Pi 4와 느린 보드 하나에서 기준 이미지와 변경 하나씩 각각 10회 이상 콜드 부팅해 중앙값·최솟값·최댓값을 보고한다. 정상 부팅과 최초 설치, OTA 적용, 전원 차단 후 복구의 시간은 섞지 않는다. 병렬로 진행된 시간은 더하지 않는다.
- **첫 목표 예시:** 기준이 실제로 15초라면 첫 단계 목표를 **12초(20% 단축)**로 잡는다. 이는 측정 후 조정할 목표이지 예상 실측값이 아니다. udev 대기가 0.1초라면 그 변경으로 수 초를 절약할 수 없다.
- **채택 조건:** 정상 부팅이 빨라지고 첫 프레임부터 입력·HDMI 오디오가 정상이어야 한다. 네트워크·웹·Bluetooth 준비가 무한정 늦어지지 않는지, 워치독·USB 핫플러그·설정 반영·OTA 롤백·전원 차단 복구가 동작하는지도 확인한다.
