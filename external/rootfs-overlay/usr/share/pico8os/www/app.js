// PICO8-OS web management page (index.html). Kept out of the page so the
// Content-Security-Policy can forbid inline scripts: no event handler
// attributes, and names from the console (carts, screenshots, Bluetooth
// devices) only ever become text or data of DOM nodes built here, never
// markup or code.
'use strict';
const $ = id => document.getElementById(id);
const esc = s => String(s).replace(/[&<>"']/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));
function el(tag, props = {}, ...kids) {
  const e = document.createElement(tag);
  Object.assign(e, props);
  for (const k of kids) e.append(k);
  return e;
}
function toast(m) { const t = $('toast'); t.textContent = m; t.style.display = 'block'; clearTimeout(t._h); t._h = setTimeout(() => t.style.display = 'none', 4000); }

// Read-only actions are GET; everything else is POST + X-Pico8os (the
// console rejects state changes without both: CSRF protection).
const READ_ONLY = ['status', 'conf_get', 'carts', 'shots', 'shot', 'log', 'bt_list', 'wifi_scan', 'policy'];
async function api(a, params = {}, opts = {}) {
  const q = new URLSearchParams({a, ...params});
  if (!READ_ONLY.includes(a)) opts = {method: 'POST', ...opts, headers: {'X-Pico8os': '1', ...(opts.headers || {})}};
  const r = await fetch('/cgi-bin/api?' + q, opts);
  const ct = r.headers.get('content-type') || '';
  const d = ct.includes('json') ? await r.json() : await r.text();
  if (d && d.code === 'login_required') { showLogin(); throw new Error('login'); }
  if (!r.ok && d && typeof d === 'object') toast(msgText(d));
  return d;
}
function upload(a, params, file, bar) {
  return new Promise(res => {
    const x = new XMLHttpRequest();
    x.open('POST', '/cgi-bin/api?' + new URLSearchParams({a, ...params}));
    x.setRequestHeader('X-Pico8os', '1');
    if (bar) { bar.hidden = false; x.upload.onprogress = e => { if (e.lengthComputable) bar.value = e.loaded / e.total; }; }
    x.onload = () => { if (bar) bar.hidden = true; let d; try { d = JSON.parse(x.responseText); } catch (e) { d = {ok: false, code: 'upload_failed'}; } res(d); };
    x.onerror = () => { if (bar) bar.hidden = true; res({ok: false, code: 'upload_failed'}); };
    x.send(file);
  });
}

let curTab = 'home';
function show(tab) {
  curTab = tab;
  document.querySelectorAll('#nav button').forEach(b => b.classList.toggle('on', b.dataset.t === tab));
  document.querySelectorAll('section').forEach(s => s.classList.toggle('on', s.id === tab));
  ({home: status, carts: loadCarts, shots: loadShots, settings: loadConf, net: loadNet, update: status, logs: loadLog})[tab]();
}
// Table rows: text cells only (esc() for the few HTML snippets below).
const row = (k, v) => `<tr><td>${esc(k)}</td><td>${v}</td></tr>`;
async function status() {
  const s = await api('status');
  $('hdr').textContent = `${s.board} · ${s.version} · ${t('slot')} ${s.slot}`;
  $('st').innerHTML = row(t('r_ip'), esc(s.ip || '-')) + row(t('r_wifi'), esc(wifiText(s.wifi))) + row(t('r_pico8'), esc(p8Text(s.pico8)) + ' ' + esc(p8Verify(s.pico8_verify))) +
    row(t('r_free'), esc(s.data_free)) + row(t('r_uptime'), esc(s.uptime));
  const o = s.ota || {};
  $('otast').innerHTML = row(t('r_version'), esc(o.version || s.version)) + row(t('r_board'), esc(s.board)) + row(t('r_slot'), esc(o.slot || s.slot)) +
    (o.pending ? row(t('r_pending'), esc(o.pending) + ' <span class="muted">' + esc(t('r_pending_note')) + '</span>') : '') +
    (o.available ? row(t('r_new'), esc(o.available)) : '') + (o.progress ? row(t('r_progress'), esc(otaText(o.progress))) : '');
  return s;
}

// A list row: name cell + optional extra text + a delete button whose
// handler gets the name as data (never through markup).
function itemRow(label, extra, onDelete) {
  const btn = el('button', {className: 'b s', textContent: t('btn_delete')});
  btn.addEventListener('click', onDelete);
  return el('tr', {}, el('td', {textContent: label}), el('td', {}, extra ? extra + ' ' : '', btn));
}
function emptyRow(text) { return el('tr', {}, el('td', {textContent: text}), el('td')); }

async function loadCarts() {
  const l = await api('carts');
  $('cartlist').replaceChildren(...(l.length ? l.map(c =>
    itemRow(c.name, (c.size / 1024).toFixed(1) + ' KB', () => delCart(c.name))) : [emptyRow(t('no_carts'))]));
}
async function delCart(n) { if (!confirm(t('c_delete', n))) return; toast(msgText(await api('cart_del', {name: n}))); loadCarts(); }
async function upCarts(files) {
  for (const f of files) { const r = await upload('cart_put', {name: f.name}, f, $('cartprog')); toast(msgText(r)); }
  loadCarts();
}

async function loadShots() {
  const l = await api('shots');
  if (!l.length) { $('shotgrid').replaceChildren(el('p', {className: 'muted', textContent: t('none_yet')})); return; }
  $('shotgrid').replaceChildren(...l.map(n => {
    const url = '/cgi-bin/api?' + new URLSearchParams({a: 'shot', name: n});
    const a = el('a', {href: url, download: n}, el('img', {src: url, loading: 'lazy', alt: n}));
    const btn = el('button', {className: 'b s', textContent: t('btn_delete')});
    btn.addEventListener('click', () => delShot(n));
    return el('figure', {}, a, n, el('br'), btn);
  }));
}
async function delShot(n) { if (!confirm(t('c_delete', n))) return; await api('shot_del', {name: n}); loadShots(); }

const KEYMAPS = ['us', 'uk', 'de', 'de-latin1', 'fr', 'fr-latin1', 'es', 'it', 'se-latin1', 'no', 'dk', 'fi', 'pt-latin1', 'br-abnt2', 'ch-de_nodeadkeys', 'jp106', 'dvorak'];
async function loadConf() {
  const txt = await api('conf_get'); $('conf').value = txt;
  const get = k => { const m = txt.match(new RegExp('^\\s*' + k + '\\s*=\\s*"?([^"#\\r\\n]*)', 'm')); return m ? m[1].trim() : ''; };
  $('q_KEYMAP').replaceChildren(...KEYMAPS.map(k => el('option', {textContent: k})));
  for (const id of ['KEYMAP', 'PICO8_MODE', 'EXIT_ACTION', 'BLUETOOTH', 'HOTKEY', 'OTA_URL']) { const v = get(id); if (v) $('q_' + id).value = v; }
  const p = await api('policy');
  for (const id of ['PICO8_VERIFY', 'DEBUG']) if (p && p[id]) $('p_' + id).value = p[id];
}
async function setq(e) { const r = await api('set', {k: e.id.slice(2), v: e.value}); toast(msgText(r)); }
async function saveConf() { const r = await upload('conf_put', {}, $('conf').value); toast(msgText(r)); }

async function loadNet() {
  const s = await status();
  $('wifist').innerHTML = row(t('r_state'), esc(wifiText(s.wifi))) + row(t('r_ip'), esc(s.ip || '-'));
  scanWifi();
  const bt = await api('bt_list');
  $('btlist').replaceChildren(...(bt.length ? bt.map(l => {
    const [m, n] = l.split('\t');
    return itemRow(n || m, m, () => btRemove(m));
  }) : [emptyRow(t('no_pads'))]));
}
async function btRemove(m) { await api('bt_remove', {mac: m}); loadNet(); }
async function scanWifi() {
  const l = await api('wifi_scan');
  $('ssidsel').replaceChildren(el('option', {value: '', textContent: t('sel_net')}), ...l.map(n => el('option', {value: n, textContent: n})));
}
async function setWifi() {
  const b = new URLSearchParams({ssid: $('ssid').value, psk: $('psk').value});
  const r = await upload('wifi_set', {}, b.toString()); toast(msgText(r));
}
async function upPico8(f) { if (!f) return; const r = await upload('pico8_put', {name: f.name}, f, $('p8prog')); toast(msgText(r)); }
async function upOta(f) {
  if (!f) return; toast(t('uploading_verify'));
  const r = await upload('ota_put', {}, f, $('otaprog')); toast(msgText(r)); $('otaapply').hidden = !r.ok; status();
}
async function otaApply() { if (!confirm(t('c_install'))) return; await api('ota_apply'); $('otaapply').hidden = true; pollOta(); }
function pollOta() {
  const h = setInterval(async () => {
    const s = await status(); const p = (s.ota || {}).progress || '';
    if (/^(ready|error|updated|uptodate|available)\b/.test(p)) {
      clearInterval(h); toast(otaText(p));
      if (p.startsWith('ready') && confirm(t('c_reboot_now'))) power('reboot');
    }
  }, 2000);
}
async function power(d) {
  if ((d === 'reboot' || d === 'poweroff') && !confirm(t(d === 'reboot' ? 'c_reboot' : 'c_poweroff'))) return;
  toast(msgText(await api('power', {do: d})));
}
async function loadLog() { $('logtxt').textContent = await api('log', {f: $('logsel').value}) || t('empty'); }
function showLogin() { $('login').hidden = false; $('logoutbtn').hidden = true; setTimeout(() => $('loginpw').focus(), 50); }
async function login() {
  const r = await upload('login', {}, new URLSearchParams({pw: $('loginpw').value}).toString());
  $('loginpw').value = '';
  if (r.ok) { $('login').hidden = true; $('logoutbtn').hidden = false; $('loginmsg').textContent = ''; show(curTab); }
  else $('loginmsg').textContent = msgText(r);
}
async function logout() { await api('logout').catch(() => {}); showLogin(); }

// Buttons name their action in data-act (argument in data-arg).
const ACTIONS = {
  logout, power, saveConf, setWifi, scanWifi, otaApply,
  setWebPw: async () => {
    const v = $('webpw').value;
    if (v && (v.length < 8 || v.length > 64)) { toast(t('api_bad_value', t('q_webpw'))); return; }
    if (!confirm(t('c_webpw'))) return;
    // in the body, not the URL
    const r = await upload('set', {}, new URLSearchParams({k: 'WEB_PASSWORD', v}).toString());
    $('webpw').value = ''; toast(msgText(r));
  },
  btPair: () => api('bt_pair').then(r => toast(msgText(r))),
  otaCheck: () => api('ota_check').then(r => { toast(msgText(r)); status(); }),
  otaDownload: () => api('ota_download').then(r => { toast(msgText(r)); pollOta(); }),
  otaRollback: () => { if (confirm(t('c_rollback'))) api('ota_rollback').then(r => toast(msgText(r))); },
};
document.addEventListener('click', e => {
  const b = e.target.closest('[data-act]');
  if (b && ACTIONS[b.dataset.act]) ACTIONS[b.dataset.act](b.dataset.arg);
});
document.querySelectorAll('#nav button').forEach(b => b.addEventListener('click', () => show(b.dataset.t)));
document.querySelectorAll('select.q, input.q').forEach(e => e.addEventListener('change', () => setq(e)));
document.querySelectorAll('select.qp').forEach(e => e.addEventListener('change', async () => {
  if (e.id === 'p_DEBUG' && e.value === 'on' && !confirm(t('c_debug'))) { e.value = 'off'; return; }
  toast(msgText(await api('set', {k: e.id.slice(2), v: e.value})));
}));
$('loginform').addEventListener('submit', e => { e.preventDefault(); login(); });
$('p8file').addEventListener('change', e => upPico8(e.target.files[0]));
$('cartfile').addEventListener('change', e => upCarts(e.target.files));
$('otafile').addEventListener('change', e => upOta(e.target.files[0]));
$('logsel').addEventListener('change', loadLog);
$('ssidsel').addEventListener('change', e => { if (e.target.value) $('ssid').value = e.target.value; });
const drop = $('cartdrop');
drop.addEventListener('dragover', e => { e.preventDefault(); drop.classList.add('over'); });
drop.addEventListener('dragleave', () => drop.classList.remove('over'));
drop.addEventListener('drop', e => { e.preventDefault(); drop.classList.remove('over'); upCarts(e.dataTransfer.files); });
$('langsel').innerHTML = langSelect();
$('langsel').addEventListener('change', e => { applyLang(e.target.value); api('set', {k: 'LANGUAGE', v: e.target.value}); show(curTab); });
window.addEventListener('unhandledrejection', e => { if (e.reason && e.reason.message === 'login') e.preventDefault(); });
applyLang(pickLang());
status().then(s => { $('logoutbtn').hidden = false; return s; }).then(s => { if (s && s.lang) { const l = pickLang(s.lang); if (l !== LANG) { applyLang(l); show(curTab); } } });
