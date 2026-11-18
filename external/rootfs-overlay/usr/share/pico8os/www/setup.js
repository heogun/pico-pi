// Wi-Fi setup page (setup.html), served on the setup access point.
// External so the Content-Security-Policy can forbid inline scripts.
'use strict';
const $=id=>document.getElementById(id);
const COUNTRY={en:'US',ko:'KR',zh:'CN',ja:'JP',fr:'FR',es:'ES',ru:'RU',it:'IT',de:'DE'};
let nets=null;
function render(){
  document.title=t('setup_title');
  if(!$('country').value)$('country').value=COUNTRY[LANG]||'';
  if(nets===null)return;
  $('sel').innerHTML='';
  const first=document.createElement('option');first.value='';
  first.textContent=nets.length?t('sel_net'):t('setup_none');$('sel').appendChild(first);
  for(const n of nets){const o=document.createElement('option');o.textContent=n;$('sel').appendChild(o)}
}
$('langsel').innerHTML=langSelect();
$('langsel').onchange=e=>{applyLang(e.target.value);render()};
applyLang(pickLang());render();
fetch('/cgi-bin/api?a=status').then(r=>r.json()).then(s=>{const l=pickLang(s.lang);if(l!==LANG){applyLang(l);render()}}).catch(()=>{});
fetch('/cgi-bin/api?a=wifi_scan').then(r=>r.json()).then(l=>{nets=l;render()}).catch(()=>{nets=[];render()});
$('sel').onchange=e=>{if(e.target.value)$('ssid').value=e.target.value};
async function save(){
  if(!$('ssid').value){$('msg').textContent=t('setup_need_ssid');return}
  const body=new URLSearchParams({ssid:$('ssid').value,psk:$('psk').value,country:$('country').value}).toString();
  const r=await fetch('/cgi-bin/api?a=wifi_set',{method:'POST',body,headers:{'X-Pico8os':'1'}}).then(r=>r.json()).catch(()=>({ok:false,code:'upload_failed'}));
  $('msg').textContent=r.ok?t('setup_ok'):msgText(r);
}
$('save').addEventListener('click', save);
