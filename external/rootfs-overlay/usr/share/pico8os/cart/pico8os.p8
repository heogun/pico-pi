pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- pico8-os settings
-- talks to pico8os-agent:
--  requests: printh() lines to pico8os_req.txt
--  status:   reload() of pico8os_status.p8, whose sprite memory holds
--            "key=value" lines (nul terminated)
-- texts come from lang_<code>.p8: a custom font (copied to 0x5600) plus
-- "key=value" lines in that font's encoding. translated text is printed
-- with "\014" (custom font); values like wi-fi names use the normal font.

st={} t_={} curlang="" seq=flr(rnd(9000))*10
scr="menu" sel=1 top=1 t=0 confirm=nil
netsel=1 netidx=0 netname=""
kx=1 ky=1 shift=false pw=""

langs={"en","ko","zh","ja","fr","es","ru","it","de"}
keymaps={"us","uk","de","de-latin1","fr","fr-latin1","es","it","se-latin1","no","dk","fi","pt-latin1","br-abnt2","jp106","dvorak"}
modes={"splore","editor"}
exits={"restart","poweroff","shell"}
kb={"abcdefghijklm","nopqrstuvwxyz","0123456789-_.","!@#$%&*?+=/:~"}
kbs={"k_shift","k_space","k_del","k_done"}

-- printh appends a newline itself. it writes to pico-8's current folder:
-- carts/pico8os/ or the carts root, depending on how the cart was started;
-- the agent watches both.
function send(c)
 seq=seq+1
 printh(seq.." "..c,"pico8os_req.txt")
end

-- p8scii: a-z display as capitals, a-z (65-90) as small glyphs
function lc(s)
 local o=""
 for i=1,#s do
  local c=ord(s,i)
  if c>=65 and c<=90 then c=c+32 end
  o=o..chr(c)
 end
 return o
end

function splitc(s,d)
 local r,cur={},""
 for i=1,#s do
  local ch=sub(s,i,i)
  if ch==d then add(r,cur) cur="" else cur=cur..ch end
 end
 if cur~="" then add(r,cur) end
 return r
end

-- parse "key=value\n" lines from memory at a into a table
function parse_kv(a,last)
 local n,line={},""
 for p=a,last do
  local c=peek(p)
  if c==0 then break end
  if c==10 then
   for i=1,#line do
    if sub(line,i,i)=="=" then n[sub(line,1,i-1)]=sub(line,i+1) break end
   end
   line=""
  else
   line=line..chr(c)
  end
 end
 return n
end

function read_status()
 reload(0,0,0x2000,"pico8os_status.p8")
 local n=parse_kv(0,0x1fff)
 if n.ver then st=n end
 load_lang(g("lang"))
end

function load_lang(l)
 if l=="" then l="en" end
 if l==curlang then return end
 reload(0,0,0x2000,"lang_"..l..".p8")
 local n=parse_kv(0x800,0x1fff)
 if n.title then
  memcpy(0x5600,0,0x800)
  t_=n curlang=l
 end
end

function g(k) return st[k] or "" end
function tr(k) return t_[k] or k end

-- text segments: {str,custom}; custom=true uses the language font
function segs_w(sg)
 local x=0
 for s in all(sg) do x=x+txt(s,-200,-200,0) end
 return x
end
function txt(s,x,y,c)
 if s[2] then return print("\014"..s[1],x,y,c)-x end
 return print(lc(s[1]),x,y,c)-x
end
function draw_segs(sg,x,y,c)
 for s in all(sg) do x=x+txt(s,x,y,c) end
 return x
end
function T(k) return {tr(k),true} end
function V(s) return {s,false} end

function idx_of(l,v)
 for i=1,#l do if l[i]==v then return i end end
 return 1
end

function cycle(key,skey,l,dir)
 local i=idx_of(l,g(skey))+dir
 if i<1 then i=#l end
 if i>#l then i=1 end
 st[skey]=l[i]
 send("set "..key.." "..l[i])
 if key=="LANGUAGE" then load_lang(l[i]) end
end

function wifi_segs()
 local w=g("wifi")
 if sub(w,1,3)=="on:" then return {V(sub(w,4))} end
 if sub(w,1,3)=="ap:" then return {T("w_ap"),V(" "..sub(w,4))} end
 if w=="none" then return {T("w_none")} end
 return {T("w_off")}
end

-- ota status "<code> [args]" (see pico8os-ota) -> segments
function ota_segs(o)
 local w=splitc(o," ")
 local c=w[1] or ""
 if t_["o_"..c] then
  local sg={T("o_"..c)}
  -- errors: just "update error"; the web ui and ota.log give the reason
  if c~="error" and w[2] then
   add(sg,V(" "..w[#w]))
  end
  return sg
 end
 return {V(o)}
end

function msg_segs()
 if confirm then return {T("confirm")} end
 local m=g("msg")
 if m=="" then return {} end
 local k,a=m,""
 for i=1,#m do
  if sub(m,i,i)==" " then k=sub(m,1,i-1) a=sub(m,i+1) break end
 end
 if k=="raw" then return {V(a)} end
 if k=="ota" then return ota_segs(a) end
 if t_["m_"..k] then
  if a~="" then return {T("m_"..k),V(" "..a)} end
  return {T("m_"..k)}
 end
 return {V(m)}
end

-- label, value segments, action, cycler
items={
 {"info",nil,function() scr="info" end},
 {"wifi",wifi_segs,function() scr="wifi" netsel=1 send("wifi_scan") end},
 {"pair",nil,function() send("pair") end},
 {"language",function() return {T("n_"..(curlang~="" and curlang or "en"))} end,nil,
  function(d) cycle("LANGUAGE","lang",langs,d) end},
 {"keyboard",function() return {V(g("keymap"))} end,nil,
  function(d) cycle("KEYMAP","keymap",keymaps,d) end},
 {"start",function() return {T("v_"..g("mode"))} end,nil,
  function(d) cycle("PICO8_MODE","mode",modes,d) end},
 {"onquit",function() return {T("v_"..g("exit"))} end,nil,
  function(d) cycle("EXIT_ACTION","exit",exits,d) end},
 {"upd",nil,function()
   if g("avail")~="" then send("ota_install") else send("ota_check") end
  end},
 {"restart",nil,function() send("restart") end},
 {"reboot",nil,function() ask("reboot") end},
 {"poweroff",nil,function() ask("poweroff") end},
 {"back",nil,function() send("exit") end},
}

function label(it)
 if it[1]=="upd" then
  if g("avail")~="" then return {T("upd_install"),V(" "..g("avail"))} end
  return {T("upd_check")}
 end
 local sg={T(it[1])}
 if it[2] then
  add(sg,V(": "))
  for s in all(it[2]()) do add(sg,s) end
 end
 return sg
end

function ask(c)
 if confirm==c then send(c) confirm=nil
 else confirm=c end
end

function _init()
 send("refresh")
 read_status()
 load_lang(g("lang"))
end

function _update()
 t=t+1
 if t%60==0 then send("refresh") end
 if t%20==0 then read_status() end
 if scr=="menu" then upd_menu()
 elseif scr=="info" then if btnp(4) or btnp(5) then scr="menu" end
 elseif scr=="wifi" then upd_wifi()
 elseif scr=="kb" then upd_kb() end
end

function upd_menu()
 if btnp(2) then sel=sel-1 confirm=nil end
 if btnp(3) then sel=sel+1 confirm=nil end
 if sel<1 then sel=#items end
 if sel>#items then sel=1 end
 local it=items[sel]
 if it[4] then
  if btnp(0) then it[4](-1) end
  if btnp(1) or btnp(4) then it[4](1) end
 elseif btnp(4) and it[3] then it[3]() end
 if btnp(5) then send("exit") end
end

function nets() return splitc(g("nets"),"|") end

function upd_wifi()
 local l=nets()
 local n=#l+1
 if btnp(2) then netsel=netsel-1 end
 if btnp(3) then netsel=netsel+1 end
 if netsel<1 then netsel=n end
 if netsel>n then netsel=1 end
 if btnp(5) then scr="menu" end
 if btnp(4) then
  if netsel==n then send("wifi_scan") st.msg="scanning"
  else
   netidx=netsel netname=l[netsel] pw="" kx=1 ky=1 shift=false
   scr="kb"
  end
 end
end

function upd_kb()
 local rows=#kb+1
 if btnp(2) then ky=ky-1 end
 if btnp(3) then ky=ky+1 end
 if ky<1 then ky=rows end
 if ky>rows then ky=1 end
 local w=13
 if ky==rows then w=#kbs end
 if btnp(0) then kx=kx-1 end
 if btnp(1) then kx=kx+1 end
 if kx<1 then kx=w end
 if kx>w then kx=1 end
 if btnp(5) then
  if #pw>0 then pw=sub(pw,1,#pw-1) else scr="wifi" end
 end
 if btnp(4) then
  if ky==rows then
   local k=kbs[kx]
   if k=="k_shift" then shift=not shift
   elseif k=="k_space" then pw=pw.." "
   elseif k=="k_del" then pw=sub(pw,1,#pw-1)
   else
    send("wifi "..netidx.." "..pw)
    scr="menu" st.msg="connecting"
   end
  else
   local c=sub(kb[ky],kx,kx)
   local o=ord(c)
   if shift and o>=97 and o<=122 then c=chr(o-32) end
   if #pw<63 then pw=pw..c end
  end
 end
end

function header(sg)
 rectfill(0,0,127,9,8)
 draw_segs(sg,2,1,7)
end

function footer()
 rectfill(0,118,127,127,1)
 draw_segs(msg_segs(),1,119,6)
end

function _draw()
 cls(0)
 if scr=="menu" then
  header({T("title")})
  if sel<top then top=sel end
  if sel>top+10 then top=sel-10 end
  for i=top,min(#items,top+10) do
   local y=12+(i-top)*9
   if i==sel then
    rectfill(0,y-1,127,y+7,2)
    print(">",1,y+1,10)
    if items[i][4] then print("\139\145",112,y+1,10) end
   end
   draw_segs(label(items[i]),7,y,7)
  end
 elseif scr=="info" then
  header({T("info")})
  local l={
   {T("i_version"),V(" "..g("ver"))},
   {T("i_slot"),V(" "..g("slot"))},
   {T("i_ip"),V(" "..g("ip"))},
   {T("i_web"),V(" "..g("web"))},
   {T("i_login"),V(" pico / "..g("pw"))},
   {T("wifi"),V(" "),wifi_segs()[1],wifi_segs()[2]},
   {T("i_update"),V(" "),ota_segs(g("ota"))[1],ota_segs(g("ota"))[2]}}
  for i=1,#l do draw_segs(l[i],2,3+i*11,7) end
  draw_segs({T("i_hint1")},1,96,6)
  draw_segs({T("i_hint2")},1,106,6)
 elseif scr=="wifi" then
  header({T("choose_wifi")})
  local l=nets()
  for i=1,#l+1 do
   local y=4+i*9
   if i==netsel then rectfill(0,y-1,127,y+7,2) end
   if i<=#l then draw_segs({V(l[i])},4,y,7)
   else draw_segs({T("rescan")},4,y,7) end
  end
 elseif scr=="kb" then
  header({T("password"),V(" "..netname)})
  rectfill(2,12,125,20,1)
  local x=4
  for i=max(1,#pw-28),#pw do
   local o=ord(pw,i)
   local col=7
   if o>=65 and o<=90 then col=10 end
   print(lc(sub(pw,i,i)),x,14,col)
   x=x+4
  end
  for r=1,#kb do
   for c=1,13 do
    local ch=sub(kb[r],c,c)
    local o=ord(ch)
    local col=7
    if shift and o>=97 and o<=122 then col=10 end
    local x=6+(c-1)*9
    local y=26+(r-1)*12
    if r==ky and c==kx then rectfill(x-2,y-2,x+5,y+6,2) end
    print(ch,x,y,col)
   end
  end
  for c=1,#kbs do
   local x=3+(c-1)*31
   local y=25+#kb*12
   local col=7
   if kbs[c]=="k_shift" and shift then col=10 end
   if ky==#kb+1 and c==kx then rectfill(x-2,y-2,x+29,y+8,2) end
   draw_segs({T(kbs[c])},x,y,col)
  end
  local x=draw_segs({V("\142 ")},2,106,6)
  x=draw_segs({T("kb_type"),V("  \151 ")},x,106,6)
  draw_segs({T("kb_delete")},x,106,6)
 end
 footer()
end
