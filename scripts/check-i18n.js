// Checks the web UI translation table: every key has all languages, and every
// key the pages use (data-i18n, t('..'), api_/ota_ codes) exists.
const fs = require('fs');
const path = require('path');
const www = path.join(__dirname, '..', 'external/rootfs-overlay/usr/share/pico8os/www');
const src = fs.readFileSync(path.join(www, 'i18n.js'), 'utf8') + ';module.exports={S,LANGS};';
const m = { exports: {} };
new Function('module', 'localStorage', 'navigator', 'document', src)(m, {}, { language: 'en' }, {});
const { S, LANGS } = m.exports;
let bad = 0;
for (const [k, v] of Object.entries(S)) {
  if (v.length !== LANGS.length || v.some(x => typeof x !== 'string' || !x)) {
    console.log(`bad row ${k}: ${v.length} entries`); bad++;
  }
}
const used = new Set();
for (const f of ['index.html', 'setup.html']) {
  const h = fs.readFileSync(path.join(www, f), 'utf8');
  for (const r of h.matchAll(/data-i18n(?:-ph)?="([a-z0-9_]+)"/g)) used.add(r[1]);
  for (const r of h.matchAll(/\bt\('([a-z0-9_]+)'/g)) used.add(r[1]);
  // inline scripts and handlers are forbidden by the CSP (pico8os-web)
  if (/<script>|\son[a-z]+=/i.test(h)) { console.log(`${f}: inline script or event handler`); bad++; }
}
for (const f of ['app.js', 'setup.js']) {
  const js = fs.readFileSync(path.join(www, f), 'utf8');
  try { new Function(js); } catch (e) { console.log(`${f}: script syntax: ${e.message}`); bad++; }
  for (const r of js.matchAll(/\bt\('([a-z0-9_]+)'/g)) used.add(r[1]);
}
// message codes produced by the device
const api = fs.readFileSync(path.join(www, 'cgi-bin/api'), 'utf8');
for (const r of api.matchAll(/\b(?:ok|fail) ([a-z_]+)\b/g)) if (!['ota'].includes(r[1])) used.add('api_' + r[1]);
const ota = fs.readFileSync(path.join(www, '../../../sbin/pico8os-ota'), 'utf8');
for (const r of ota.matchAll(/\bprogress ([a-z]+)\b/g)) used.add('ota_' + r[1]);
for (const r of ota.matchAll(/\bdie ([a-z]+)\b/g)) used.add('ota_err_' + r[1]);
const missing = [...used].filter(k => !(k in S));
if (missing.length) { console.log('missing keys: ' + missing.join(', ')); bad++; }
console.log(`${Object.keys(S).length} keys x ${LANGS.length} languages, ${used.size} used, ${bad ? 'FAILED' : 'ok'}`);
process.exit(bad ? 1 : 0);
