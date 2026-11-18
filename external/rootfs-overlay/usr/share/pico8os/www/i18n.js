// PICO8-OS web UI translations. One array per key, languages in LANGS order.
// {0} is replaced by the first argument of t(key, arg).
const LANGS = ['en', 'ko', 'zh', 'ja', 'fr', 'es', 'ru', 'it', 'de'];
const LANG_NAMES = ['English', '한국어', '中文', '日本語', 'Français', 'Español', 'Русский', 'Italiano', 'Deutsch'];
const S = {
  nav_home: ['Status', '상태', '状态', '状態', 'État', 'Estado', 'Состояние', 'Stato', 'Status'],
  nav_carts: ['Carts', '카트', '卡带', 'カート', 'Cartouches', 'Cartuchos', 'Картриджи', 'Cartucce', 'Carts'],
  nav_shots: ['Screenshots', '스크린샷', '截图', 'スクリーンショット', "Captures", 'Capturas', 'Снимки', 'Screenshot', 'Screenshots'],
  nav_settings: ['Settings', '설정', '设置', '設定', 'Réglages', 'Ajustes', 'Настройки', 'Impostazioni', 'Einstellungen'],
  nav_net: ['Wi-Fi · Bluetooth', 'Wi-Fi·블루투스', 'Wi-Fi · 蓝牙', 'Wi-Fi・Bluetooth', 'Wi-Fi · Bluetooth', 'Wi-Fi · Bluetooth', 'Wi-Fi · Bluetooth', 'Wi-Fi · Bluetooth', 'WLAN · Bluetooth'],
  nav_update: ['Update', '업데이트', '更新', 'アップデート', 'Mise à jour', 'Actualización', 'Обновление', 'Aggiornamento', 'Update'],
  nav_logs: ['Logs', '로그', '日志', 'ログ', 'Journaux', 'Registros', 'Журналы', 'Log', 'Protokolle'],

  h_console: ['Console', '콘솔', '主机', '本体', 'Console', 'Consola', 'Консоль', 'Console', 'Konsole'],
  h_controls: ['Controls', '조작', '操作', '操作', 'Actions', 'Acciones', 'Действия', 'Azioni', 'Aktionen'],
  btn_restart: ['Restart PICO-8', 'PICO-8 재시작', '重启 PICO-8', 'PICO-8 再起動', 'Relancer PICO-8', 'Reiniciar PICO-8', 'Перезапуск PICO-8', 'Riavvia PICO-8', 'PICO-8 neu starten'],
  btn_settings: ['Open settings on the console', '콘솔에서 설정 열기', '在主机上打开设置', '本体で設定を開く', 'Ouvrir les réglages sur la console', 'Abrir ajustes en la consola', 'Открыть настройки на консоли', 'Apri impostazioni sulla console', 'Einstellungen auf der Konsole öffnen'],
  btn_reboot: ['Reboot', '재부팅', '重启主机', '再起動', 'Redémarrer', 'Reiniciar', 'Перезагрузить', 'Riavvia', 'Neustart'],
  btn_poweroff: ['Power off', '전원 끄기', '关机', '電源を切る', 'Éteindre', 'Apagar', 'Выключить', 'Spegni', 'Ausschalten'],
  h_pico8: ['Install / update PICO-8', 'PICO-8 설치 / 업데이트', '安装 / 更新 PICO-8', 'PICO-8 のインストール / 更新', 'Installer / mettre à jour PICO-8', 'Instalar / actualizar PICO-8', 'Установка / обновление PICO-8', 'Installa / aggiorna PICO-8', 'PICO-8 installieren / aktualisieren'],
  p_pico8: ['Upload the pico-8_x.y.z_raspi.zip from Lexaloffle; PICO-8 restarts and installs it.', 'Lexaloffle에서 받은 pico-8_x.y.z_raspi.zip을 올리면 PICO-8이 다시 시작하며 설치됩니다.', '上传从 Lexaloffle 下载的 pico-8_x.y.z_raspi.zip，PICO-8 会重启并安装。', 'Lexaloffle から入手した pico-8_x.y.z_raspi.zip をアップロードすると、PICO-8 が再起動してインストールします。', 'Envoyez le pico-8_x.y.z_raspi.zip de Lexaloffle ; PICO-8 redémarre et l\'installe.', 'Sube el pico-8_x.y.z_raspi.zip de Lexaloffle; PICO-8 se reinicia y lo instala.', 'Загрузите pico-8_x.y.z_raspi.zip от Lexaloffle — PICO-8 перезапустится и установит его.', 'Carica il pico-8_x.y.z_raspi.zip di Lexaloffle: PICO-8 si riavvia e lo installa.', 'Lade die pico-8_x.y.z_raspi.zip von Lexaloffle hoch; PICO-8 startet neu und installiert sie.'],
  btn_zip: ['Choose zip', 'zip 선택', '选择 zip', 'zip を選択', 'Choisir le zip', 'Elegir zip', 'Выбрать zip', 'Scegli zip', 'Zip wählen'],

  h_cart_up: ['Upload carts', '카트 올리기', '上传卡带', 'カートをアップロード', 'Envoyer des cartouches', 'Subir cartuchos', 'Загрузить картриджи', 'Carica cartucce', 'Carts hochladen'],
  p_cart_drop: ['Drop .p8 / .p8.png files here or', '.p8 / .p8.png 파일을 여기로 끌어 놓거나', '把 .p8 / .p8.png 文件拖到这里，或', '.p8 / .p8.png ファイルをここにドロップ、または', 'Déposez des fichiers .p8 / .p8.png ici ou', 'Suelta archivos .p8 / .p8.png aquí o', 'Перетащите сюда файлы .p8 / .p8.png или', 'Trascina qui i file .p8 / .p8.png oppure', '.p8- / .p8.png-Dateien hier ablegen oder'],
  btn_file: ['Choose files', '파일 선택', '选择文件', 'ファイルを選択', 'Choisir des fichiers', 'Elegir archivos', 'Выбрать файлы', 'Scegli file', 'Dateien wählen'],
  h_cart_list: ['Carts', '카트 목록', '卡带列表', 'カート一覧', 'Cartouches', 'Cartuchos', 'Картриджи', 'Cartucce', 'Carts'],
  no_carts: ['No carts yet', '카트가 없습니다', '还没有卡带', 'カートがありません', 'Aucune cartouche', 'No hay cartuchos', 'Картриджей нет', 'Nessuna cartuccia', 'Noch keine Carts'],
  btn_delete: ['Delete', '삭제', '删除', '削除', 'Supprimer', 'Borrar', 'Удалить', 'Elimina', 'Löschen'],

  h_shots: ['Screenshots · GIFs', '스크린샷 · GIF', '截图 · GIF', 'スクリーンショット・GIF', 'Captures · GIF', 'Capturas · GIF', 'Снимки · GIF', 'Screenshot · GIF', 'Screenshots · GIFs'],
  p_shots: ['Saved in PICO-8 with F6 (screenshot) and F8/F9 (GIF).', 'PICO-8에서 F6(스크린샷), F8/F9(GIF)로 저장한 파일입니다.', '在 PICO-8 中用 F6（截图）和 F8/F9（GIF）保存的文件。', 'PICO-8 で F6（スクリーンショット）、F8/F9（GIF）で保存したファイルです。', 'Enregistrés dans PICO-8 avec F6 (capture) et F8/F9 (GIF).', 'Guardados en PICO-8 con F6 (captura) y F8/F9 (GIF).', 'Сохранены в PICO-8 клавишами F6 (снимок) и F8/F9 (GIF).', 'Salvati in PICO-8 con F6 (screenshot) e F8/F9 (GIF).', 'In PICO-8 mit F6 (Screenshot) und F8/F9 (GIF) gespeichert.'],
  none_yet: ['Nothing yet.', '아직 없습니다.', '还没有。', 'まだありません。', 'Rien pour l\'instant.', 'Aún no hay nada.', 'Пока ничего нет.', 'Ancora niente.', 'Noch nichts.'],

  h_quick: ['Quick settings', '빠른 설정', '快速设置', 'クイック設定', 'Réglages rapides', 'Ajustes rápidos', 'Быстрые настройки', 'Impostazioni rapide', 'Schnelleinstellungen'],
  q_lang: ['Language', '언어', '语言', '言語', 'Langue', 'Idioma', 'Язык', 'Lingua', 'Sprache'],
  q_keymap: ['Keyboard layout', '키보드 레이아웃', '键盘布局', 'キーボード配列', 'Disposition du clavier', 'Distribución del teclado', 'Раскладка клавиатуры', 'Layout tastiera', 'Tastaturbelegung'],
  q_mode: ['Start screen', '시작 화면', '启动画面', '起動画面', 'Écran de démarrage', 'Pantalla de inicio', 'Стартовый экран', 'Schermata iniziale', 'Startbildschirm'],
  q_exit: ['When PICO-8 quits', 'PICO-8 종료 시', 'PICO-8 退出时', 'PICO-8 終了時', 'Quand PICO-8 quitte', 'Al salir de PICO-8', 'При выходе из PICO-8', 'All\'uscita di PICO-8', 'Wenn PICO-8 beendet wird'],
  q_bt: ['Bluetooth', '블루투스', '蓝牙', 'Bluetooth', 'Bluetooth', 'Bluetooth', 'Bluetooth', 'Bluetooth', 'Bluetooth'],
  q_hotkey: ['Restart hotkey', '강제 재시작 단축키', '强制重启快捷键', '強制再起動ショートカット', 'Raccourci de relance', 'Atajo de reinicio', 'Горячая клавиша перезапуска', 'Scorciatoia di riavvio', 'Neustart-Tastenkürzel'],
  q_ota: ['Update server (OTA_URL)', '업데이트 서버 (OTA_URL)', '更新服务器 (OTA_URL)', '更新サーバー (OTA_URL)', 'Serveur de mises à jour (OTA_URL)', 'Servidor de actualizaciones (OTA_URL)', 'Сервер обновлений (OTA_URL)', 'Server di aggiornamento (OTA_URL)', 'Update-Server (OTA_URL)'],
  h_conf: ['Edit pico8os.txt', 'pico8os.txt 직접 편집', '直接编辑 pico8os.txt', 'pico8os.txt を直接編集', 'Modifier pico8os.txt', 'Editar pico8os.txt', 'Редактировать pico8os.txt', 'Modifica pico8os.txt', 'pico8os.txt bearbeiten'],
  btn_save: ['Save and apply', '저장하고 적용', '保存并应用', '保存して適用', 'Enregistrer et appliquer', 'Guardar y aplicar', 'Сохранить и применить', 'Salva e applica', 'Speichern und anwenden'],

  h_wifi: ['Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'WLAN'],
  sel_net: ['Choose a nearby network…', '주변 네트워크 선택…', '选择附近的网络…', '近くのネットワークを選択…', 'Choisir un réseau proche…', 'Elige una red cercana…', 'Выберите сеть рядом…', 'Scegli una rete vicina…', 'Netzwerk in der Nähe wählen…'],
  ph_ssid: ['Network name (SSID)', '네트워크 이름 (SSID)', '网络名称 (SSID)', 'ネットワーク名 (SSID)', 'Nom du réseau (SSID)', 'Nombre de la red (SSID)', 'Имя сети (SSID)', 'Nome della rete (SSID)', 'Netzwerkname (SSID)'],
  ph_psk: ['Password (leave empty if none)', '비밀번호 (없으면 비워 두기)', '密码（没有则留空）', 'パスワード（なければ空欄）', 'Mot de passe (vide si aucun)', 'Contraseña (vacía si no hay)', 'Пароль (пусто, если нет)', 'Password (vuota se assente)', 'Passwort (leer, falls keins)'],
  btn_connect: ['Connect', '연결', '连接', '接続', 'Se connecter', 'Conectar', 'Подключить', 'Connetti', 'Verbinden'],
  btn_rescan: ['Scan again', '다시 검색', '重新搜索', '再検索', 'Rechercher à nouveau', 'Buscar de nuevo', 'Искать снова', 'Cerca di nuovo', 'Erneut suchen'],
  h_bt: ['Bluetooth controllers', '블루투스 게임패드', '蓝牙手柄', 'Bluetooth コントローラ', 'Manettes Bluetooth', 'Mandos Bluetooth', 'Bluetooth-геймпады', 'Controller Bluetooth', 'Bluetooth-Controller'],
  p_bt: ['Press the button, then put the controller in pairing mode within 90 s (PS: SHARE+PS, Switch: SYNC, Xbox: pair button).', '버튼을 누른 뒤 90초 안에 패드를 페어링 모드로 두세요. (PS: SHARE+PS, Switch: SYNC, Xbox: 페어링 버튼)', '按下按钮后，在 90 秒内让手柄进入配对模式（PS：SHARE+PS，Switch：SYNC，Xbox：配对键）。', 'ボタンを押してから 90 秒以内にコントローラをペアリングモードにしてください（PS: SHARE+PS、Switch: SYNC、Xbox: ペアリングボタン）。', 'Appuyez sur le bouton puis mettez la manette en mode jumelage dans les 90 s (PS : SHARE+PS, Switch : SYNC, Xbox : bouton de jumelage).', 'Pulsa el botón y pon el mando en modo emparejamiento en 90 s (PS: SHARE+PS, Switch: SYNC, Xbox: botón de emparejar).', 'Нажмите кнопку и в течение 90 с переведите геймпад в режим сопряжения (PS: SHARE+PS, Switch: SYNC, Xbox: кнопка сопряжения).', 'Premi il pulsante e metti il controller in modalità associazione entro 90 s (PS: SHARE+PS, Switch: SYNC, Xbox: tasto di associazione).', 'Taste drücken und den Controller innerhalb von 90 s in den Kopplungsmodus versetzen (PS: SHARE+PS, Switch: SYNC, Xbox: Kopplungstaste).'],
  btn_pair: ['Start pairing', '페어링 시작', '开始配对', 'ペアリング開始', 'Lancer le jumelage', 'Empezar a emparejar', 'Начать сопряжение', 'Avvia associazione', 'Kopplung starten'],
  no_pads: ['No paired controllers', '페어링된 패드 없음', '没有已配对的手柄', 'ペアリング済みのコントローラはありません', 'Aucune manette jumelée', 'No hay mandos emparejados', 'Нет сопряжённых геймпадов', 'Nessun controller associato', 'Keine gekoppelten Controller'],

  h_system: ['System', '시스템', '系统', 'システム', 'Système', 'Sistema', 'Система', 'Sistema', 'System'],
  h_upd_file: ['Install from an update file', '업데이트 파일로 설치', '用更新文件安装', '更新ファイルからインストール', 'Installer depuis un fichier', 'Instalar desde un archivo', 'Установить из файла обновления', 'Installa da un file di aggiornamento', 'Aus Update-Datei installieren'],
  p_upd_file: ['Upload a pico8os-<board>-<version>.pico8os-update from the build. Its signature and board are checked, then it is installed into the unused system slot. If the new system fails to start 3 times in a row, the console goes back to the previous one.', '빌드에서 나온 pico8os-<보드>-<버전>.pico8os-update를 올리세요. 서명과 보드를 확인한 뒤 쓰지 않는 시스템 슬롯에 설치합니다. 새 시스템이 3번 연속 정상 부팅하지 못하면 자동으로 이전 시스템으로 돌아갑니다.', '上传构建生成的 pico8os-<板型>-<版本>.pico8os-update。校验签名和板型后安装到未使用的系统槽。新系统连续 3 次无法正常启动时，会自动回到之前的系统。', 'ビルドで作られた pico8os-<ボード>-<バージョン>.pico8os-update をアップロードしてください。署名とボードを確認し、使っていないシステムスロットにインストールします。新しいシステムが 3 回続けて起動できないと、自動的に前のシステムに戻ります。', 'Envoyez un pico8os-<carte>-<version>.pico8os-update issu de la compilation. La signature et la carte sont vérifiées, puis il est installé dans l\'emplacement système libre. Si le nouveau système échoue 3 fois de suite, la console revient au précédent.', 'Sube un pico8os-<placa>-<versión>.pico8os-update de la compilación. Se comprueban la firma y la placa y se instala en la ranura de sistema libre. Si el nuevo sistema falla 3 veces seguidas, la consola vuelve al anterior.', 'Загрузите pico8os-<плата>-<версия>.pico8os-update из сборки. Подпись и плата проверяются, затем обновление ставится в свободный системный слот. Если новая система 3 раза подряд не запустится, консоль вернётся к прежней.', 'Carica un pico8os-<scheda>-<versione>.pico8os-update dalla build. Firma e scheda vengono verificate, poi viene installato nello slot di sistema libero. Se il nuovo sistema non si avvia per 3 volte di fila, la console torna al precedente.', 'Lade eine pico8os-<Board>-<Version>.pico8os-update aus dem Build hoch. Signatur und Board werden geprüft, dann wird sie in den freien Systemslot installiert. Startet das neue System 3-mal in Folge nicht, kehrt die Konsole zum vorherigen zurück.'],
  btn_install: ['Install', '설치', '安装', 'インストール', 'Installer', 'Instalar', 'Установить', 'Installa', 'Installieren'],
  h_upd_online: ['Online update', '온라인 업데이트', '在线更新', 'オンライン更新', 'Mise à jour en ligne', 'Actualización en línea', 'Обновление по сети', 'Aggiornamento online', 'Online-Update'],
  p_upd_online: ['Checks OTA_URL (in Settings) for a new version.', '설정의 OTA_URL에서 새 버전을 확인합니다.', '从设置中的 OTA_URL 检查新版本。', '設定の OTA_URL で新しいバージョンを確認します。', 'Cherche une nouvelle version sur OTA_URL (Réglages).', 'Busca una versión nueva en OTA_URL (Ajustes).', 'Проверяет новую версию по OTA_URL (Настройки).', 'Cerca una nuova versione su OTA_URL (Impostazioni).', 'Sucht unter OTA_URL (Einstellungen) nach einer neuen Version.'],
  btn_check: ['Check', '확인', '检查', '確認', 'Vérifier', 'Comprobar', 'Проверить', 'Controlla', 'Prüfen'],
  btn_dl: ['Download and install', '받아서 설치', '下载并安装', 'ダウンロードしてインストール', 'Télécharger et installer', 'Descargar e instalar', 'Скачать и установить', 'Scarica e installa', 'Herunterladen und installieren'],
  btn_rollback: ['Go back to previous system', '이전 시스템으로', '回到之前的系统', '前のシステムに戻す', 'Revenir au système précédent', 'Volver al sistema anterior', 'Вернуть прежнюю систему', 'Torna al sistema precedente', 'Zum vorherigen System'],

  h_logs: ['Logs', '로그', '日志', 'ログ', 'Journaux', 'Registros', 'Журналы', 'Log', 'Protokolle'],
  log_pico8: ['PICO-8', 'PICO-8', 'PICO-8', 'PICO-8', 'PICO-8', 'PICO-8', 'PICO-8', 'PICO-8', 'PICO-8'],
  log_kernel: ['Kernel warnings', '커널 경고', '内核警告', 'カーネル警告', 'Alertes du noyau', 'Avisos del kernel', 'Предупреждения ядра', 'Avvisi del kernel', 'Kernel-Warnungen'],
  log_ota: ['Updates', '업데이트', '更新', '更新', 'Mises à jour', 'Actualizaciones', 'Обновления', 'Aggiornamenti', 'Updates'],
  log_bt: ['Bluetooth', '블루투스', '蓝牙', 'Bluetooth', 'Bluetooth', 'Bluetooth', 'Bluetooth', 'Bluetooth', 'Bluetooth'],
  log_system: ['System (dmesg)', '시스템(dmesg)', '系统 (dmesg)', 'システム (dmesg)', 'Système (dmesg)', 'Sistema (dmesg)', 'Система (dmesg)', 'Sistema (dmesg)', 'System (dmesg)'],
  empty: ['(empty)', '(비어 있음)', '（空）', '（空）', '(vide)', '(vacío)', '(пусто)', '(vuoto)', '(leer)'],

  r_ip: ['IP', 'IP', 'IP', 'IP', 'IP', 'IP', 'IP', 'IP', 'IP'],
  r_wifi: ['Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'WLAN'],
  r_pico8: ['PICO-8', 'PICO-8', 'PICO-8', 'PICO-8', 'PICO-8', 'PICO-8', 'PICO-8', 'PICO-8', 'PICO-8'],
  r_free: ['Free data space', '데이터 여유 공간', '数据可用空间', 'データ空き容量', 'Espace libre', 'Espacio libre', 'Свободно места', 'Spazio libero', 'Freier Speicher'],
  r_uptime: ['Uptime', '가동 시간', '运行时间', '稼働時間', 'Allumée depuis', 'Tiempo encendida', 'Время работы', 'Acceso da', 'Laufzeit'],
  r_version: ['Version', '버전', '版本', 'バージョン', 'Version', 'Versión', 'Версия', 'Versione', 'Version'],
  r_board: ['Board', '보드', '板型', 'ボード', 'Carte', 'Placa', 'Плата', 'Scheda', 'Board'],
  r_slot: ['Running slot', '실행 중인 슬롯', '当前系统槽', '実行中のスロット', 'Emplacement actif', 'Ranura activa', 'Активный слот', 'Slot attivo', 'Aktiver Slot'],
  r_pending: ['Waiting for confirmation', '확인 대기', '等待确认', '確認待ち', 'En attente de confirmation', 'Pendiente de confirmar', 'Ожидает подтверждения', 'In attesa di conferma', 'Wartet auf Bestätigung'],
  r_pending_note: ['(kept once it runs fine)', '(정상 동작이 확인되면 확정)', '（正常运行后确认）', '（正常に動けば確定）', '(validé s\'il fonctionne)', '(se confirma si funciona)', '(закрепится после успешной работы)', '(confermato se funziona)', '(wird übernommen, wenn es läuft)'],
  r_new: ['New version', '새 버전', '新版本', '新しいバージョン', 'Nouvelle version', 'Versión nueva', 'Новая версия', 'Nuova versione', 'Neue Version'],
  r_progress: ['Progress', '진행', '进度', '進行状況', 'Progression', 'Progreso', 'Ход', 'Avanzamento', 'Fortschritt'],
  r_state: ['State', '상태', '状态', '状態', 'État', 'Estado', 'Состояние', 'Stato', 'Status'],
  slot: ['slot', '슬롯', '槽', 'スロット', 'emplacement', 'ranura', 'слот', 'slot', 'Slot'],

  c_delete: ['Delete {0}?', '{0} 삭제?', '删除 {0}？', '{0} を削除しますか？', 'Supprimer {0} ?', '¿Borrar {0}?', 'Удалить {0}?', 'Eliminare {0}?', '{0} löschen?'],
  c_reboot: ['Reboot the console?', '재부팅할까요?', '要重启主机吗？', '再起動しますか？', 'Redémarrer la console ?', '¿Reiniciar la consola?', 'Перезагрузить консоль?', 'Riavviare la console?', 'Konsole neu starten?'],
  c_poweroff: ['Power off the console?', '전원을 끌까요?', '要关机吗？', '電源を切りますか？', 'Éteindre la console ?', '¿Apagar la consola?', 'Выключить консоль?', 'Spegnere la console?', 'Konsole ausschalten?'],
  c_rollback: ['Go back to the system in the other slot? Takes effect after a reboot.', '다른 슬롯의 시스템으로 되돌릴까요? 재부팅해야 적용됩니다.', '要回到另一个槽中的系统吗？重启后生效。', 'もう一方のスロットのシステムに戻しますか？再起動後に反映されます。', 'Revenir au système de l\'autre emplacement ? Effectif après redémarrage.', '¿Volver al sistema de la otra ranura? Se aplica al reiniciar.', 'Вернуться к системе в другом слоте? Применится после перезагрузки.', 'Tornare al sistema dell\'altro slot? Ha effetto dopo il riavvio.', 'Zum System im anderen Slot zurück? Wirkt nach einem Neustart.'],
  c_install: ['Install this update?', '업데이트를 설치할까요?', '要安装此更新吗？', 'この更新をインストールしますか？', 'Installer cette mise à jour ?', '¿Instalar esta actualización?', 'Установить это обновление?', 'Installare questo aggiornamento?', 'Dieses Update installieren?'],
  c_reboot_now: ['Installed. Reboot now?', '설치가 끝났습니다. 지금 재부팅할까요?', '安装完成。现在重启吗？', 'インストールしました。今すぐ再起動しますか？', 'Installée. Redémarrer maintenant ?', 'Instalada. ¿Reiniciar ahora?', 'Установлено. Перезагрузить сейчас?', 'Installato. Riavviare ora?', 'Installiert. Jetzt neu starten?'],
  uploading_verify: ['Uploading… checking takes a while', '업로드 중… 확인까지 시간이 걸립니다', '上传中…校验需要一些时间', 'アップロード中…確認に時間がかかります', 'Envoi… la vérification prend du temps', 'Subiendo… la comprobación tarda', 'Загрузка… проверка займёт время', 'Caricamento… la verifica richiede tempo', 'Lade hoch… die Prüfung dauert etwas'],
  upload_failed: ['Upload failed', '업로드 실패', '上传失败', 'アップロード失敗', 'Échec de l\'envoi', 'Error al subir', 'Ошибка загрузки', 'Caricamento non riuscito', 'Upload fehlgeschlagen'],

  setup_title: ['PICO8-OS Wi-Fi setup', 'PICO8-OS Wi-Fi 설정', 'PICO8-OS Wi-Fi 设置', 'PICO8-OS Wi-Fi 設定', 'Configuration Wi-Fi PICO8-OS', 'Configuración Wi-Fi de PICO8-OS', 'Настройка Wi-Fi PICO8-OS', 'Configurazione Wi-Fi PICO8-OS', 'PICO8-OS WLAN-Einrichtung'],
  setup_intro: ['Choose the Wi-Fi for the console. Once saved, the console joins it and this setup network turns off.', '콘솔을 연결할 Wi-Fi를 고르세요. 저장하면 콘솔이 그 네트워크에 연결되고 이 설정용 네트워크는 꺼집니다.', '选择主机要连接的 Wi-Fi。保存后主机会连接该网络，这个设置用网络随即关闭。', '本体をつなぐ Wi-Fi を選んでください。保存すると本体がそのネットワークに接続し、この設定用ネットワークは切れます。', 'Choisissez le Wi-Fi de la console. Une fois enregistré, la console s\'y connecte et ce réseau de configuration s\'éteint.', 'Elige la Wi-Fi de la consola. Al guardar, la consola se conecta y esta red de configuración se apaga.', 'Выберите Wi-Fi для консоли. После сохранения консоль подключится к нему, а эта сеть настройки выключится.', 'Scegli la Wi-Fi per la console. Dopo il salvataggio la console si connette e questa rete di configurazione si spegne.', 'Wähle das WLAN für die Konsole. Nach dem Speichern verbindet sie sich damit und dieses Einrichtungsnetz schaltet sich ab.'],
  setup_searching: ['Searching for networks…', '네트워크 검색 중…', '正在搜索网络…', 'ネットワークを検索中…', 'Recherche des réseaux…', 'Buscando redes…', 'Поиск сетей…', 'Ricerca reti…', 'Suche Netzwerke…'],
  setup_none: ['No networks found', '검색 결과 없음', '未找到网络', 'ネットワークが見つかりません', 'Aucun réseau trouvé', 'No se encontraron redes', 'Сети не найдены', 'Nessuna rete trovata', 'Keine Netzwerke gefunden'],
  ph_country: ['Country code (e.g. KR)', '국가 코드 (예: KR)', '国家代码（如 CN）', '国コード（例: JP）', 'Code pays (ex. FR)', 'Código de país (p. ej. ES)', 'Код страны (напр. RU)', 'Codice paese (es. IT)', 'Ländercode (z. B. DE)'],
  setup_save: ['Save and connect', '저장하고 연결', '保存并连接', '保存して接続', 'Enregistrer et se connecter', 'Guardar y conectar', 'Сохранить и подключить', 'Salva e connetti', 'Speichern und verbinden'],
  setup_need_ssid: ['Enter the network name', '네트워크 이름을 입력하세요', '请输入网络名称', 'ネットワーク名を入力してください', 'Saisissez le nom du réseau', 'Escribe el nombre de la red', 'Введите имя сети', 'Inserisci il nome della rete', 'Netzwerknamen eingeben'],
  setup_ok: ['Connecting. This page will disconnect soon; switch your phone back to your usual Wi-Fi.', '연결 중입니다. 이 화면은 곧 끊깁니다. 휴대폰을 원래 Wi-Fi로 돌려 놓으세요.', '正在连接。此页面很快会断开，请把手机切回平常用的 Wi-Fi。', '接続中です。この画面はまもなく切れます。スマホをいつもの Wi-Fi に戻してください。', 'Connexion en cours. Cette page va se couper ; remettez votre téléphone sur votre Wi-Fi habituel.', 'Conectando. Esta página se cortará pronto; vuelve a poner el móvil en tu Wi-Fi habitual.', 'Подключение. Страница скоро отключится — верните телефон на обычную Wi-Fi.', 'Connessione in corso. Questa pagina si disconnetterà a breve: riporta il telefono sulla solita Wi-Fi.', 'Verbinde. Diese Seite trennt sich gleich; stelle dein Handy wieder auf dein gewohntes WLAN.'],
  setup_after: ['Once connected, open the console\'s IP from a device on the same network to manage carts, settings and updates. The IP and password appear in the console\'s settings screen (Ctrl+Alt+S or hold SELECT for 2 s).', '연결된 뒤에는 같은 네트워크에서 콘솔 IP로 접속해 카트, 설정, 업데이트를 관리할 수 있습니다. IP와 비밀번호는 콘솔의 설정 화면(Ctrl+Alt+S 또는 SELECT 2초)에 나옵니다.', '连接后，在同一网络的设备上打开主机 IP，即可管理卡带、设置和更新。IP 和密码显示在主机的设置画面（Ctrl+Alt+S 或按住 SELECT 2 秒）。', '接続後は、同じネットワークの端末から本体の IP を開いて、カート・設定・更新を管理できます。IP とパスワードは本体の設定画面（Ctrl+Alt+S または SELECT を 2 秒長押し）に表示されます。', 'Une fois connectée, ouvrez l\'IP de la console depuis un appareil du même réseau pour gérer cartouches, réglages et mises à jour. L\'IP et le mot de passe sont affichés dans les réglages de la console (Ctrl+Alt+S ou SELECT 2 s).', 'Una vez conectada, abre la IP de la consola desde un dispositivo de la misma red para gestionar cartuchos, ajustes y actualizaciones. La IP y la contraseña salen en los ajustes de la consola (Ctrl+Alt+S o SELECT 2 s).', 'После подключения откройте IP консоли с устройства в той же сети, чтобы управлять картриджами, настройками и обновлениями. IP и пароль показаны в настройках консоли (Ctrl+Alt+S или SELECT 2 с).', 'Una volta connessa, apri l\'IP della console da un dispositivo sulla stessa rete per gestire cartucce, impostazioni e aggiornamenti. IP e password sono nelle impostazioni della console (Ctrl+Alt+S o SELECT per 2 s).', 'Nach dem Verbinden die IP der Konsole von einem Gerät im selben Netz öffnen, um Carts, Einstellungen und Updates zu verwalten. IP und Passwort stehen in den Konsoleneinstellungen (Strg+Alt+S oder SELECT 2 s halten).'],
};

let LANG = 'en';
function pickLang(device) {
  let l = null;
  try { l = localStorage.getItem('pico8os-lang'); } catch (e) {}
  if (!LANGS.includes(l)) l = LANGS.includes(device) ? device : null;
  if (!l) { const b = (navigator.language || 'en').slice(0, 2).toLowerCase(); l = LANGS.includes(b) ? b : 'en'; }
  return l;
}
// Fill [data-i18n] text and [data-i18n-ph] placeholders.
function applyLang(l) {
  LANG = l;
  document.documentElement.lang = l;
  try { localStorage.setItem('pico8os-lang', l); } catch (e) {}
  document.querySelectorAll('[data-i18n]').forEach(e => { e.textContent = t(e.dataset.i18n); });
  document.querySelectorAll('[data-i18n-ph]').forEach(e => { e.placeholder = t(e.dataset.i18nPh); });
  const sel = document.getElementById('langsel');
  if (sel) sel.value = l;
}
function langSelect() {
  return LANGS.map((c, i) => `<option value="${c}">${LANG_NAMES[i]}</option>`).join('');
}

// ---- message codes from the device (API replies, OTA status, states) ----
Object.assign(S, {
  api_saved: ['Saved', '저장했습니다', '已保存', '保存しました', 'Enregistré', 'Guardado', 'Сохранено', 'Salvato', 'Gespeichert'],
  api_saved_key: ['Saved: {0}', '저장했습니다: {0}', '已保存：{0}', '保存しました：{0}', 'Enregistré : {0}', 'Guardado: {0}', 'Сохранено: {0}', 'Salvato: {0}', 'Gespeichert: {0}'],
  api_unknown_setting: ['Unknown setting {0}', '알 수 없는 설정 {0}', '未知设置 {0}', '不明な設定 {0}', 'Réglage inconnu {0}', 'Ajuste desconocido {0}', 'Неизвестная настройка {0}', 'Impostazione sconosciuta {0}', 'Unbekannte Einstellung {0}'],
  api_too_large: ['File is too large', '파일이 너무 큽니다', '文件太大', 'ファイルが大きすぎます', 'Fichier trop volumineux', 'El archivo es demasiado grande', 'Файл слишком большой', 'File troppo grande', 'Datei ist zu groß'],
  api_post_required: ['Invalid request', '잘못된 요청입니다', '请求无效', '不正なリクエストです', 'Requête invalide', 'Solicitud no válida', 'Неверный запрос', 'Richiesta non valida', 'Ungültige Anfrage'],
  api_bad_name: ['Invalid file name', '파일 이름이 올바르지 않습니다', '文件名无效', 'ファイル名が正しくありません', 'Nom de fichier invalide', 'Nombre de archivo no válido', 'Недопустимое имя файла', 'Nome file non valido', 'Ungültiger Dateiname'],
  api_only_carts: ['Only .p8 and .p8.png carts', '.p8, .p8.png 카트만 올릴 수 있습니다', '只能上传 .p8 和 .p8.png 卡带', '.p8 と .p8.png のカートのみ', 'Uniquement des cartouches .p8 et .p8.png', 'Solo cartuchos .p8 y .p8.png', 'Только картриджи .p8 и .p8.png', 'Solo cartucce .p8 e .p8.png', 'Nur .p8- und .p8.png-Carts'],
  api_uploaded: ['Uploaded {0}', '{0} 올림', '已上传 {0}', '{0} をアップロードしました', '{0} envoyé', '{0} subido', '{0} загружен', '{0} caricato', '{0} hochgeladen'],
  api_deleted: ['Deleted {0}', '{0} 삭제함', '已删除 {0}', '{0} を削除しました', '{0} supprimé', '{0} borrado', '{0} удалён', '{0} eliminato', '{0} gelöscht'],
  api_unknown_log: ['Unknown log', '알 수 없는 로그', '未知日志', '不明なログ', 'Journal inconnu', 'Registro desconocido', 'Неизвестный журнал', 'Log sconosciuto', 'Unbekanntes Protokoll'],
  api_expect_zip: ['Choose pico-8_x.y.z_raspi.zip', 'pico-8_x.y.z_raspi.zip을 골라 주세요', '请选择 pico-8_x.y.z_raspi.zip', 'pico-8_x.y.z_raspi.zip を選んでください', 'Choisissez pico-8_x.y.z_raspi.zip', 'Elige pico-8_x.y.z_raspi.zip', 'Выберите pico-8_x.y.z_raspi.zip', 'Scegli pico-8_x.y.z_raspi.zip', 'pico-8_x.y.z_raspi.zip wählen'],
  api_zip_installing: ['Uploaded {0}: installing', '{0} 올림: 설치 중', '已上传 {0}：正在安装', '{0} をアップロード：インストール中', '{0} envoyé : installation', '{0} subido: instalando', '{0} загружен: установка', '{0} caricato: installazione', '{0} hochgeladen: wird installiert'],
  api_pairing: ['Pairing for 90 s: put the controller in pairing mode', '90초 동안 페어링: 패드를 페어링 모드로 두세요', '配对 90 秒：请让手柄进入配对模式', '90 秒間ペアリング：コントローラをペアリングモードに', 'Jumelage 90 s : mettez la manette en mode jumelage', 'Emparejando 90 s: pon el mando en modo emparejamiento', 'Сопряжение 90 с: переведите геймпад в режим сопряжения', 'Associazione 90 s: metti il controller in modalità associazione', 'Kopplung 90 s: Controller in den Kopplungsmodus versetzen'],
  api_bad_address: ['Invalid address', '주소가 올바르지 않습니다', '地址无效', 'アドレスが正しくありません', 'Adresse invalide', 'Dirección no válida', 'Неверный адрес', 'Indirizzo non valido', 'Ungültige Adresse'],
  api_removed: ['Removed {0}', '{0} 삭제함', '已移除 {0}', '{0} を削除しました', '{0} retiré', '{0} eliminado', '{0} удалён', '{0} rimosso', '{0} entfernt'],
  api_ssid_missing: ['Enter the network name', '네트워크 이름을 입력하세요', '请输入网络名称', 'ネットワーク名を入力してください', 'Saisissez le nom du réseau', 'Escribe el nombre de la red', 'Введите имя сети', 'Inserisci il nome della rete', 'Netzwerknamen eingeben'],
  api_psk_len: ['The password must be 8–63 characters', '비밀번호는 8~63자여야 합니다', '密码必须为 8–63 个字符', 'パスワードは 8〜63 文字です', 'Le mot de passe doit faire 8 à 63 caractères', 'La contraseña debe tener 8–63 caracteres', 'Пароль должен быть от 8 до 63 символов', 'La password deve avere 8–63 caratteri', 'Das Passwort muss 8–63 Zeichen haben'],
  api_quotes: ["The name or password can't contain both ' and \"", "이름이나 비밀번호에 ' 와 \" 를 함께 쓸 수 없습니다", "名称或密码不能同时包含 ' 和 \"", "名前やパスワードに ' と \" を両方は使えません", "Le nom ou mot de passe ne peut pas contenir à la fois ' et \"", "El nombre o la contraseña no pueden tener ' y \" a la vez", "Имя или пароль не могут содержать одновременно ' и \"", "Nome o password non possono contenere sia ' che \"", "Name oder Passwort dürfen nicht ' und \" zugleich enthalten"],
  api_connecting: ['Connecting to {0}', '{0}에 연결 중', '正在连接 {0}', '{0} に接続中', 'Connexion à {0}', 'Conectando a {0}', 'Подключение к {0}', 'Connessione a {0}', 'Verbinde mit {0}'],
  api_upload_failed: ['Upload failed', '업로드 실패', '上传失败', 'アップロード失敗', 'Échec de l\'envoi', 'Error al subir', 'Ошибка загрузки', 'Caricamento non riuscito', 'Upload fehlgeschlagen'],
  api_no_update: ['No update file uploaded', '올린 업데이트 파일이 없습니다', '没有上传更新文件', '更新ファイルがアップロードされていません', 'Aucun fichier de mise à jour envoyé', 'No se ha subido ningún archivo de actualización', 'Файл обновления не загружен', 'Nessun file di aggiornamento caricato', 'Keine Update-Datei hochgeladen'],
  api_installing: ['Installing', '설치 중', '正在安装', 'インストール中', 'Installation', 'Instalando', 'Установка', 'Installazione', 'Wird installiert'],
  api_downloading: ['Downloading', '받는 중', '正在下载', 'ダウンロード中', 'Téléchargement', 'Descargando', 'Загрузка', 'Download in corso', 'Wird heruntergeladen'],
  api_restarting: ['Restarting PICO-8', 'PICO-8 재시작 중', '正在重启 PICO-8', 'PICO-8 を再起動中', 'Relance de PICO-8', 'Reiniciando PICO-8', 'Перезапуск PICO-8', 'Riavvio di PICO-8', 'PICO-8 wird neu gestartet'],
  api_settings: ['Opening settings on the console', '콘솔에서 설정을 여는 중', '正在主机上打开设置', '本体で設定を開いています', 'Ouverture des réglages sur la console', 'Abriendo ajustes en la consola', 'Открываю настройки на консоли', 'Apertura impostazioni sulla console', 'Einstellungen werden auf der Konsole geöffnet'],
  api_rebooting: ['Rebooting', '재부팅 중', '正在重启', '再起動中', 'Redémarrage', 'Reiniciando', 'Перезагрузка', 'Riavvio', 'Neustart'],
  api_powering_off: ['Powering off', '전원을 끄는 중', '正在关机', '電源を切っています', 'Extinction', 'Apagando', 'Выключение', 'Spegnimento', 'Wird ausgeschaltet'],
  api_unknown_action: ['Unknown action', '알 수 없는 동작', '未知操作', '不明な操作', 'Action inconnue', 'Acción desconocida', 'Неизвестное действие', 'Azione sconosciuta', 'Unbekannte Aktion'],
  api_ap_only: ['Wi-Fi setup mode: only Wi-Fi settings are available', 'Wi-Fi 설정 모드: Wi-Fi 설정만 할 수 있습니다', 'Wi-Fi 设置模式：只能设置 Wi-Fi', 'Wi-Fi 設定モード：Wi-Fi の設定のみ可能です', 'Mode configuration Wi-Fi : seuls les réglages Wi-Fi sont disponibles', 'Modo configuración Wi-Fi: solo ajustes de Wi-Fi', 'Режим настройки Wi-Fi: доступны только настройки Wi-Fi', 'Modalità configurazione Wi-Fi: solo impostazioni Wi-Fi', 'WLAN-Einrichtung: nur WLAN-Einstellungen verfügbar'],

  ota_verifying: ['Checking the update', '업데이트 확인 중', '正在校验更新', '更新を確認中', 'Vérification de la mise à jour', 'Comprobando la actualización', 'Проверка обновления', 'Verifica dell\'aggiornamento', 'Update wird geprüft'],
  ota_checking: ['Checking the files', '파일 확인 중', '正在校验文件', 'ファイルを確認中', 'Vérification des fichiers', 'Comprobando los archivos', 'Проверка файлов', 'Verifica dei file', 'Dateien werden geprüft'],
  ota_writing: ['Writing system {0} to slot {1}', '시스템 {0}을 슬롯 {1}에 쓰는 중', '正在把系统 {0} 写入槽 {1}', 'システム {0} をスロット {1} に書き込み中', 'Écriture du système {0} dans l\'emplacement {1}', 'Escribiendo el sistema {0} en la ranura {1}', 'Запись системы {0} в слот {1}', 'Scrittura del sistema {0} nello slot {1}', 'System {0} wird in Slot {1} geschrieben'],
  ota_kernel: ['Installing the kernel to slot {0}', '슬롯 {0}에 커널 설치 중', '正在把内核安装到槽 {0}', 'スロット {0} にカーネルをインストール中', 'Installation du noyau dans l\'emplacement {0}', 'Instalando el kernel en la ranura {0}', 'Установка ядра в слот {0}', 'Installazione del kernel nello slot {0}', 'Kernel wird in Slot {0} installiert'],
  ota_ready: ['Ready: reboot to start {0}', '준비 완료: 재부팅하면 {0}으로 시작합니다', '就绪：重启后启动 {0}', '準備完了：再起動すると {0} で起動します', 'Prêt : redémarrez pour lancer {0}', 'Listo: reinicia para iniciar {0}', 'Готово: перезагрузите, чтобы запустить {0}', 'Pronto: riavvia per avviare {0}', 'Bereit: Neustart startet {0}'],
  ota_valid: ['Valid update: {0}', '올바른 업데이트: {0}', '有效的更新：{0}', '有効な更新：{0}', 'Mise à jour valide : {0}', 'Actualización válida: {0}', 'Корректное обновление: {0}', 'Aggiornamento valido: {0}', 'Gültiges Update: {0}'],
  ota_updated: ['Updated to {0}', '{0}으로 업데이트됨', '已更新到 {0}', '{0} に更新しました', 'Mis à jour vers {0}', 'Actualizado a {0}', 'Обновлено до {0}', 'Aggiornato a {0}', 'Auf {0} aktualisiert'],
  ota_uptodate: ['Up to date ({0})', '최신 버전입니다 ({0})', '已是最新 ({0})', '最新です（{0}）', 'À jour ({0})', 'Actualizado ({0})', 'Последняя версия ({0})', 'Aggiornato ({0})', 'Aktuell ({0})'],
  ota_available: ['New version available: {0}', '새 버전 있음: {0}', '有新版本：{0}', '新しいバージョンがあります：{0}', 'Nouvelle version disponible : {0}', 'Nueva versión disponible: {0}', 'Доступна новая версия: {0}', 'Nuova versione disponibile: {0}', 'Neue Version verfügbar: {0}'],
  ota_downloading: ['Downloading {0}', '{0} 받는 중', '正在下载 {0}', '{0} をダウンロード中', 'Téléchargement de {0}', 'Descargando {0}', 'Загрузка {0}', 'Download di {0}', '{0} wird heruntergeladen'],
  ota_rolledback: ['Switched back: reboot to apply', '되돌림: 재부팅하면 적용됩니다', '已切换回去：重启后生效', '戻しました：再起動で反映されます', 'Retour effectué : redémarrez pour appliquer', 'Revertido: reinicia para aplicar', 'Возвращено: перезагрузите для применения', 'Ripristinato: riavvia per applicare', 'Zurückgesetzt: Neustart zum Anwenden'],
  ota_err_nofile: ['Update file not found', '업데이트 파일이 없습니다', '找不到更新文件', '更新ファイルが見つかりません', 'Fichier de mise à jour introuvable', 'No se encuentra el archivo de actualización', 'Файл обновления не найден', 'File di aggiornamento non trovato', 'Update-Datei nicht gefunden'],
  ota_err_notupdate: ['Not a PICO8-OS update file', 'PICO8-OS 업데이트 파일이 아닙니다', '不是 PICO8-OS 更新文件', 'PICO8-OS の更新ファイルではありません', 'Ce n\'est pas une mise à jour PICO8-OS', 'No es una actualización de PICO8-OS', 'Это не файл обновления PICO8-OS', 'Non è un aggiornamento PICO8-OS', 'Keine PICO8-OS-Update-Datei'],
  ota_err_unsigned: ['The update is not signed', '서명되지 않은 업데이트입니다', '更新未签名', '署名されていない更新です', 'La mise à jour n\'est pas signée', 'La actualización no está firmada', 'Обновление не подписано', 'L\'aggiornamento non è firmato', 'Das Update ist nicht signiert'],
  ota_err_badsig: ['Bad signature: not built with this console\'s key', '서명이 맞지 않습니다: 이 콘솔의 키로 만든 업데이트가 아닙니다', '签名错误：不是用这台主机的密钥构建的', '署名が違います：この本体の鍵で作られた更新ではありません', 'Signature incorrecte : pas compilée avec la clé de cette console', 'Firma incorrecta: no se creó con la clave de esta consola', 'Неверная подпись: собрано не с ключом этой консоли', 'Firma errata: non creato con la chiave di questa console', 'Falsche Signatur: nicht mit dem Schlüssel dieser Konsole gebaut'],
  ota_err_format: ['Unknown update format', '알 수 없는 업데이트 형식', '未知的更新格式', '不明な更新形式', 'Format de mise à jour inconnu', 'Formato de actualización desconocido', 'Неизвестный формат обновления', 'Formato di aggiornamento sconosciuto', 'Unbekanntes Update-Format'],
  ota_err_board: ['This update is for {0}; this console is {1}', '{0}용 업데이트입니다. 이 콘솔은 {1}입니다', '此更新适用于 {0}，这台主机是 {1}', '{0} 用の更新です。この本体は {1} です', 'Cette mise à jour est pour {0} ; cette console est {1}', 'Esta actualización es para {0}; esta consola es {1}', 'Обновление для {0}, а эта консоль — {1}', 'Questo aggiornamento è per {0}; questa console è {1}', 'Dieses Update ist für {0}; diese Konsole ist {1}'],
  ota_err_corrupt: ['{0} is corrupt', '{0} 파일이 손상되었습니다', '{0} 已损坏', '{0} が壊れています', '{0} est corrompu', '{0} está dañado', '{0} повреждён', '{0} è danneggiato', '{0} ist beschädigt'],
  ota_err_nofit: ['The system image does not fit the slot', '시스템 이미지가 슬롯보다 큽니다', '系统镜像放不进系统槽', 'システムイメージがスロットに収まりません', 'L\'image système ne tient pas dans l\'emplacement', 'La imagen del sistema no cabe en la ranura', 'Образ системы не помещается в слот', 'L\'immagine di sistema non entra nello slot', 'Das Systemabbild passt nicht in den Slot'],
  ota_err_write: ['Writing {0} failed', '{0} 쓰기 실패', '写入 {0} 失败', '{0} への書き込みに失敗しました', 'Échec de l\'écriture de {0}', 'Error al escribir {0}', 'Ошибка записи {0}', 'Scrittura di {0} non riuscita', 'Schreiben von {0} fehlgeschlagen'],
  ota_err_bootmount: ['Cannot open the boot partition', '부트 파티션을 열 수 없습니다', '无法打开启动分区', 'ブートパーティションを開けません', 'Impossible d\'ouvrir la partition de démarrage', 'No se puede abrir la partición de arranque', 'Не удаётся открыть загрузочный раздел', 'Impossibile aprire la partizione di avvio', 'Boot-Partition lässt sich nicht öffnen'],
  ota_err_bootfiles: ['Installing the boot files failed', '부트 파일 설치 실패', '安装启动文件失败', 'ブートファイルのインストールに失敗しました', 'Échec de l\'installation des fichiers de démarrage', 'Error al instalar los archivos de arranque', 'Ошибка установки загрузочных файлов', 'Installazione dei file di avvio non riuscita', 'Installation der Boot-Dateien fehlgeschlagen'],
  ota_err_nourl: ['OTA_URL is not set', 'OTA_URL이 설정되지 않았습니다', '未设置 OTA_URL', 'OTA_URL が設定されていません', 'OTA_URL n\'est pas défini', 'OTA_URL no está configurado', 'OTA_URL не задан', 'OTA_URL non impostato', 'OTA_URL ist nicht gesetzt'],
  ota_err_unreachable: ['Cannot reach the update server', '업데이트 서버에 연결할 수 없습니다', '无法连接更新服务器', '更新サーバーに接続できません', 'Serveur de mises à jour injoignable', 'No se puede contactar con el servidor', 'Сервер обновлений недоступен', 'Server di aggiornamento non raggiungibile', 'Update-Server nicht erreichbar'],
  ota_err_badlatest: ['The server\'s latest.txt is invalid', '서버의 latest.txt가 올바르지 않습니다', '服务器的 latest.txt 无效', 'サーバーの latest.txt が正しくありません', 'Le latest.txt du serveur est invalide', 'El latest.txt del servidor no es válido', 'latest.txt на сервере некорректен', 'Il latest.txt del server non è valido', 'latest.txt des Servers ist ungültig'],
  ota_err_download: ['Download failed', '다운로드 실패', '下载失败', 'ダウンロードに失敗しました', 'Échec du téléchargement', 'Error en la descarga', 'Ошибка загрузки', 'Download non riuscito', 'Download fehlgeschlagen'],
  ota_err: ['Error: {0}', '오류: {0}', '错误：{0}', 'エラー：{0}', 'Erreur : {0}', 'Error: {0}', 'Ошибка: {0}', 'Errore: {0}', 'Fehler: {0}'],

  wifi_ap: ['Setup network {0}', '설정용 네트워크 {0}', '设置用网络 {0}', '設定用ネットワーク {0}', 'Réseau de configuration {0}', 'Red de configuración {0}', 'Сеть настройки {0}', 'Rete di configurazione {0}', 'Einrichtungsnetz {0}'],
  wifi_off: ['Not connected', '연결 안 됨', '未连接', '未接続', 'Non connecté', 'Sin conexión', 'Не подключено', 'Non connesso', 'Nicht verbunden'],
  wifi_none: ['No Wi-Fi hardware', 'Wi-Fi 장치 없음', '没有无线网卡', 'Wi-Fi 機能なし', 'Pas de Wi-Fi', 'Sin Wi-Fi', 'Нет Wi-Fi', 'Nessun Wi-Fi', 'Kein WLAN'],
  api_bad_origin: ['Request refused (wrong address or origin)', '요청 거부됨 (주소나 출처가 맞지 않음)', '请求被拒绝（地址或来源不符）', 'リクエストを拒否しました（アドレスまたは送信元が不正）', 'Requête refusée (adresse ou origine incorrecte)', 'Solicitud rechazada (dirección u origen incorrectos)', 'Запрос отклонён (неверный адрес или источник)', 'Richiesta rifiutata (indirizzo o origine non validi)', 'Anfrage abgelehnt (falsche Adresse oder Herkunft)'],
  ota_err_older: ['Update {0} is not newer than the installed {1}', '업데이트 {0}이 설치된 {1}보다 새 버전이 아닙니다', '更新 {0} 不比已安装的 {1} 新', '更新 {0} はインストール済みの {1} より新しくありません', 'La mise à jour {0} n\'est pas plus récente que {1}', 'La actualización {0} no es más nueva que {1}', 'Обновление {0} не новее установленной {1}', 'L\'aggiornamento {0} non è più recente di {1}', 'Update {0} ist nicht neuer als {1}'],
  p8v_ok: ['verified', '검증됨', '已验证', '検証済み', 'vérifié', 'verificado', 'проверено', 'verificato', 'geprüft'],
  p8v_unknown: ['not verified (unlisted version)', '검증 안 됨 (목록에 없는 버전)', '未验证（未收录的版本）', '未検証（リストにないバージョン）', 'non vérifié (version non listée)', 'sin verificar (versión no incluida)', 'не проверено (версии нет в списке)', 'non verificato (versione non in elenco)', 'nicht geprüft (Version nicht gelistet)'],
  login_title: ['Log in', '로그인', '登录', 'ログイン', 'Connexion', 'Iniciar sesión', 'Вход', 'Accedi', 'Anmelden'],
  login_hint: ['The password is on the console: open the settings (Ctrl+Alt+S or hold SELECT for 2 s) and choose Info.', '비밀번호는 콘솔에 나옵니다. 설정(Ctrl+Alt+S 또는 SELECT 2초)을 열고 정보를 고르세요.', '密码显示在主机上：打开设置（Ctrl+Alt+S 或按住 SELECT 2 秒），选择“信息”。', 'パスワードは本体に表示されます。設定（Ctrl+Alt+S または SELECT を 2 秒長押し）を開き、「情報」を選んでください。', 'Le mot de passe est sur la console : ouvrez les réglages (Ctrl+Alt+S ou SELECT 2 s) puis Infos.', 'La contraseña está en la consola: abre los ajustes (Ctrl+Alt+S o mantén SELECT 2 s) y elige Información.', 'Пароль показан на консоли: откройте настройки (Ctrl+Alt+S или SELECT 2 с) и выберите «Сведения».', 'La password è sulla console: apri le impostazioni (Ctrl+Alt+S o tieni SELECT 2 s) e scegli Info.', 'Das Passwort steht auf der Konsole: Einstellungen öffnen (Strg+Alt+S oder SELECT 2 s halten) und Info wählen.'],
  login_pw: ['Password', '비밀번호', '密码', 'パスワード', 'Mot de passe', 'Contraseña', 'Пароль', 'Password', 'Passwort'],
  login_btn: ['Log in', '로그인', '登录', 'ログイン', 'Se connecter', 'Entrar', 'Войти', 'Accedi', 'Anmelden'],
  logout: ['Log out', '로그아웃', '退出登录', 'ログアウト', 'Déconnexion', 'Cerrar sesión', 'Выйти', 'Esci', 'Abmelden'],
  api_login_required: ['Please log in', '로그인하세요', '请登录', 'ログインしてください', 'Veuillez vous connecter', 'Inicia sesión', 'Войдите', 'Accedi', 'Bitte anmelden'],
  api_logged_in: ['Logged in', '로그인했습니다', '已登录', 'ログインしました', 'Connecté', 'Sesión iniciada', 'Вход выполнен', 'Accesso eseguito', 'Angemeldet'],
  api_logged_out: ['Logged out', '로그아웃했습니다', '已退出', 'ログアウトしました', 'Déconnecté', 'Sesión cerrada', 'Выход выполнен', 'Disconnesso', 'Abgemeldet'],
  api_bad_password: ['Wrong password', '비밀번호가 틀렸습니다', '密码错误', 'パスワードが違います', 'Mot de passe incorrect', 'Contraseña incorrecta', 'Неверный пароль', 'Password errata', 'Falsches Passwort'],
  api_locked: ['Too many attempts. Try again in {0} s.', '시도가 너무 많습니다. {0}초 뒤에 다시 시도하세요.', '尝试次数过多，请 {0} 秒后再试。', '試行回数が多すぎます。{0} 秒後に再試行してください。', 'Trop de tentatives. Réessayez dans {0} s.', 'Demasiados intentos. Vuelve a intentarlo en {0} s.', 'Слишком много попыток. Повторите через {0} с.', 'Troppi tentativi. Riprova tra {0} s.', 'Zu viele Versuche. In {0} s erneut versuchen.'],
  p8_installed: ['Installed', '설치됨', '已安装', 'インストール済み', 'Installé', 'Instalado', 'Установлено', 'Installato', 'Installiert'],
  p8_none: ['Not installed', '설치 안 됨', '未安装', '未インストール', 'Non installé', 'No instalado', 'Не установлено', 'Non installato', 'Nicht installiert'],
});

// t(key, arg0, arg1, ...): {0}, {1} ... are replaced in order.
function t(k, ...a) {
  const row = S[k];
  let s = row ? (row[LANGS.indexOf(LANG)] || row[0]) : k;
  a.forEach((v, i) => { s = s.split('{' + i + '}').join(v); });
  return s;
}
// OTA status line "code args..." -> text
function otaText(p) {
  if (!p) return '';
  const w = p.trim().split(/\s+/), c = w[0], a = w.slice(1);
  if (c === 'error') return S['ota_err_' + a[0]] ? t('ota_err_' + a[0], ...a.slice(1)) : t('ota_err', a.join(' '));
  return S['ota_' + c] ? t('ota_' + c, ...a) : p;
}
// API reply {code, arg} -> text
function msgText(r) {
  if (!r) return '';
  if (r.code === 'ota') return otaText(r.arg);
  if (r.code && S['api_' + r.code]) return t('api_' + r.code, r.arg || '');
  return r.msg || r.code || '';
}
function wifiText(w) {
  if (!w) return '';
  if (w.startsWith('on:')) return w.slice(3);
  if (w.startsWith('ap:')) return t('wifi_ap', w.slice(3));
  return w === 'none' ? t('wifi_none') : t('wifi_off');
}
// PICO-8 package check result ("ok 0.2.7" / "unknown 0.2.8")
function p8Verify(v) {
  if (!v) return '';
  const k = v.split(' ')[0];
  return S['p8v_' + k] ? '(' + t('p8v_' + k) + ')' : '';
}
function p8Text(v) {
  return v === '@installed' ? t('p8_installed') : v === '@none' ? t('p8_none') : v;
}
