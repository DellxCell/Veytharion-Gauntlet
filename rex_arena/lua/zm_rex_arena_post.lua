-- Rex Arena 1.1 menu entry and start route (mods/rex_arena), without editing
-- Kronos' launcher. Two Survival rows, Rex Arena solo (1000000206) and squad
-- (1000000207), are placed like Ashes Arena's: copied from the launcher's Ashes
-- Survival rows (1000000008 / 1000000009), but with Rex Infernus' card, picture
-- and map name. Starting one runs the launcher's own Rex round-based start
-- (1000000006 / 1000000007, with its Rex steps); on that start's public request
-- the record is replaced by a copy with one added setting, the POI dvar
-- 0xdddf7dca1a52e591 = zone_boss_arena_ff, which only zm_rex_arena reads. The
-- launcher's records are not changed. Rex has no Survival mode of its own, so
-- the match is round-based. Lines go to poi_reg.log as "rex arena: ...".
-- The notes below are Ashes Arena's history for the shared lobby/loading code.
-- Ashes Arena 0.4.1 menu entry, without editing Kronos' launcher
-- (Assets/Lua/zm_local_start_post.lua). Everything here goes through what
-- the launcher already makes public or what the engine tables hold:
--   * LUMEN_ZM_LOCAL_START.catalogue (by_id / by_pair), the table the
--     launcher's own playlist hooks read;
--   * the frontEnd.playlists.category global model, where the launcher
--     writes its Survival rows;
--   * Playlist.DoPlaylistId and three Playlist/Lobby queries, hooked on top
--     of the launcher's hooks, the same way the launcher hooks the engine.
-- After each launcher publish, the rows for Ashes of the Damned Survival
-- (1000000008 solo, 1000000009 co-op) are copied as "Ashes Arena"
-- (Rex Arena: 1000000206 / 1000000207). Starting one runs the launcher's normal
-- Ashes Survival start; on that start's public request the record is
-- replaced by a copy whose POI setting is zone_boss_arena, which the
-- zm_ashes_arena script checks. The launcher's own records are not changed.
-- Progress lines go to poi_reg.log as "lua: ashes arena: ..." (KRONOS.log).
-- 0.4.35 lobby name (user: Exit 115's card switches to "EXIT 115 / SURVIVAL"
-- when the match is about to begin; ours kept "ASHES OF THE DAMNED", also with
-- 0.4.34): at that point MP 0xa781132808ca573a names the map with the title
-- (PLAY_MENU 0x9ae1e225e2dd2df4) of the current playlist's card (PLAY_MENU
-- 0x38eb2c388629179b). While the launcher's start request is an Ashes Arena
-- one (state.request.rex_arena, set below; the launcher keeps the request
-- from the start until it returns from gameplay or cancels), that card is our
-- titled view of the Ashes Survival card, so the picture is unchanged. 0.4.34
-- used its own flag, which a later DoPlaylistId could clear.
-- 0.4.36: the 0.4.35 log showed the lobby name "Ashes Arena" once, then "Ashes
-- of the Damned" for the rest of the start: the lobby stops asking for the
-- playlist card. The mode line under the name (Lobby 0x97043e05e1a83595) reads
-- "SURVIVAL" once the lobby's game type (frontEnd.lobby.gameType, or Lobby
-- 0xcfc38819ea2193ba) is the start record's game type (record.command,
-- zm_rb_survival). The map name (MP 0xa781132808ca573a) is now "Ashes Arena"
-- while the launcher's start request is an Ashes Arena one and the lobby's game
-- type is that one, so it changes together with the mode line, as for native
-- Survival POIs. Up to 40 changes of the lobby state are logged ("lobby: ...").
-- 0.4.37: the 0.4.36 log showed the lobby game type as an asset hash, not the
-- record's command: "xhash: #x475505f81616168a7" (sat_zm_rb, round based), then
-- "xhash: #x452dfe30a2cbf4de" (sat_zm_rb_survival, the record's asset). The
-- Survival test now compares with the record's asset, as an asset hash
-- (CLUA.PushXHashAsset) and by the hash digits of the known asset.
-- [rex arena bar2 begin]
-- Second boss health bar (0.3.4; since 0.3.6 a second copy of the game's own
-- boss bar). The game shows one boss bar: the widget ScriptedWidgetBossHealthBar
-- (type 0x92d2213283134045, ingame_zm). While Z-Rex and the Guardian are both
-- alive, zm_rex_arena writes the boss that bar is not following to the dvar
-- rex_arena_bar2 as "NAME|health|max|server time|bar list id". This block
-- builds a second instance of that widget, 76 units under the first and grown
-- 6.3% to match its size on screen (0.3.7), and feeds
-- it with the widget's own steps: name and icon from the bar list entry, the
-- health as a width of 0..500 set at once the first time and animated after.
-- If the widget cannot be built, the 0.3.5 drawn bar is used. What was used
-- goes to the dvar rex_arena_bar2_ui for the script's record. Empty, malformed
-- or no longer changing values remove it. It runs in its own protected call,
-- so a fault here cannot reach the menu code below.
-- 0.5.25: a value can end in a slot ("...|bar list id|slot"): 0 under the
-- game's bar (as before), -1 left of it, 1 right of it. The block is also
-- copied as the bar3 block, reading rex_arena_bar3.
-- 0.5.37: slot 2 is DROP units above the game's bar, slot 3 in its place. A
-- seventh field 1 plays the widget's own immune clip; back to 0, its
-- vulnerable clip and then its default one.
-- 0.5.39: slot 4 is under the game's bar like slot 0, at 94%.
pcall(function()
local G=_G
local C=rawget(G,"CLUA")
local H=rawget(G,"xhash") or rawget(G,"PushXHash") or (type(C)=="table" and C.PushXHash)
local HD=rawget(G,"xhashdvar") or rawget(G,"PushXHashDvar") or (type(C)=="table" and C.PushXHashDvar)
local HA=rawget(G,"xhashasset") or (type(C)=="table" and C.PushXHashAsset)
if type(H)~="function" or type(HD)~="function" then return end
local old=rawget(G,"REX_ARENA_BAR2")
if type(old)=="table" then old.enabled=false;if type(old.clear)=="function" then pcall(old.clear) end end
local B={enabled=true,ticks=0,still=0,visible=false,failures=0,slot=0,dx=0}
rawset(G,"REX_ARENA_BAR2",B)
local DVAR=HD("rex_arena_bar2")
local UI_DVAR=HD("rex_arena_bar2_ui")
-- the game's widget (1920x1080 units) draws its name from y=141 and its icon
-- down to y=210; the copy goes this far below it
local DROP=76
-- the copy is held in a box around its bar (widget y 123..231) grown about the
-- box's centre: drawn lower, the curved HUD shows it about 6% smaller than the
-- game's bar (0.3.6 screenshot: 504 against 536 px); the game sizes an element
-- 1 + scale times
local BAR_TOP,BAR_BOX,GROW=123,108,0.063
-- 0.5.25: a copy in slot -1 or 1 is level with the game's bar, SIDE units
-- left or right of its centre, at 85% size so three fit in a row
local SIDE,SIDE_GROW=590,-0.15
-- 0.5.37: a copy in slot 2 (above the game's bar) is a little smaller, the
-- curved HUD showing higher elements larger; slot 3 is the game's size.
-- After an immunity, the default clip comes CALM ticks after the vulnerable one.
local RISE_GROW,CALM=-0.06,45
-- 0.5.39: slot 4: under the game's bar like slot 0 but smaller (94%), for a
-- second boss under the main one (slot 0 looked 6% bigger than the main bar)
local UNDER_SMALL=-0.06
local WIDTH=500        -- the inner bar's width; the game writes 500 * health / max
local TRIES=3          -- failed builds of the copy before staying with the drawing
-- the game's keys (luafile_7aa61794fc16de36 / luafile_6e3d854c0b033738)
local K={widget="0x92d2213283134045",module="0x7aa61794fc16de36",bar="0xb0e6b8094f2f2b6b",
    setNow="0x1308fc7d3b941d09",setAnimated="0x468ab2aecc8d2221",first="0xccd7022c4ddd9e89",
    last="0x3662de31dab8f469",name="0x8d53be57673b8a44",icon="0xdbff4cc56c2092f0",
    list="0x9c9913488ca22949",entry="0x7a35b1d2343c2b34",bundle="0xf06093d047200548",
    localize="0xaed84c33ec5f01ea",title="0x8ed55aa074c2e0a7",
    immune="0xb1609ad657c4db1c",vulnerable="0x8755afbce28bd095",default="0xdef6c3ab55c07bef"}
-- 0.3.5 drawing, 1080p units
local LEFT,W,TOP,NAME_H,BOX_Y,BOX_H,PAD,BAND_H=-240,518,196,20,22,24,6,12
local BAND_W=W-2*PAD
local STALE=180

local function get(object,key)
    if object==nil then return nil end
    local plain,value=pcall(function()return object[key]end)
    if plain and value~=nil then return value end
    local ok,hashed=pcall(function()return object[H(key)]end)
    if ok then return hashed end
    return nil
end
local function put(object,key,value) object[H(key)]=value end
local function invoke(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(...) end
end
local function call(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(object,...) end
end
local function newElement(kind)
    local f=get(get(rawget(G,"LUI"),kind),"new")
    if type(f)~="function" then error("Native "..kind.." constructor unavailable",0) end
    return f()
end
local function passive(element)
    call(element,"SetHandleMouse",false);call(element,"setFocusable",false)
end
local function place(node,x,y,w,h)
    call(node,"SetAnchorsAndPosition",0,1,0,1,x,x+w,y,y+h)
end
local function rectangle(parent,x,y,w,h,rgb,alpha)
    local element=newElement("UIImage")
    place(element,x,y,w,h)
    call(element,"SetRGB",rgb);call(element,"SetAlpha",alpha)
    passive(element);call(parent,"addElement",element)
    return element
end

-- "NAME|health|max|time[|id[|slot]]" -> name, fraction 0..1, time, id, slot;
-- nil when not a bar. A slot other than -1 or 1 is 0.
local function parse(text)
    if type(text)~="string" or text=="" or #text>96 then return nil end
    local name,hp,max,stamp,id,slot,immune=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)|(%-?%d+)|([01])$")
    if not name then name,hp,max,stamp,id,slot=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)|(%-?%d+)$") end
    if not name then name,hp,max,stamp,id=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)$") end
    if not name then name,hp,max,stamp=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)$") end
    hp,max,id,slot=tonumber(hp),tonumber(max),tonumber(id),tonumber(slot)
    if not name or not hp or not max or max<=0 then return nil end
    local fraction=hp/max
    if fraction<0 then fraction=0 elseif fraction>1 then fraction=1 end
    if id and id<0 then id=nil end
    if slot~=-1 and slot~=1 and slot~=2 and slot~=3 and slot~=4 then slot=0 end
    return name,fraction,stamp,id,slot,immune=="1"
end
B.parse=parse

local function report(text)
    text=tostring(text):gsub("[^%w %-%.:;,_/()]","?"):sub(1,90)
    if text==B.reported then return end
    B.reported=text
    pcall(invoke,rawget(G,"Dvar"),"SetDvarString",UI_DVAR,text)
end
local function clear()
    if B.frame then pcall(call,B.frame,"closeTree") end
    B.frame=nil;B.parent=nil;B.widget=nil;B.bar=nil;B.mode=nil
    B.visible=false;B.width=nil;B.name=nil;B.id=nil;B.immune=nil;B.calm=nil
end
local function hide()
    if B.frame and B.visible then call(B.frame,"SetAlpha",0,0) end
    B.visible=false
end
local function displayParent()
    local root=invoke(get(rawget(G,"LUI"),"UIRoot"),"GetRootForControllerIndex",0)
    if type(get(root,"addElement"))~="function" then return nil end
    for _=1,16 do
        local parent=call(root,"getParent")
        if not parent or parent==root then break end
        root=parent
    end
    return root
end
local function holder(parent,y,h)
    local frame=newElement("UIElement")
    call(frame,"SetAnchorsAndPosition",.5,.5,0,1,-960+B.dx,960+B.dx,y,y+h)
    call(frame,"SetAlpha",0);call(frame,"setPriority",900);passive(frame);call(parent,"addElement",frame)
    B.frame=frame;B.parent=parent
    return frame
end

-- a second instance of the game's widget
local function buildCopy(parent)
    local build=get(rawget(G,"MenuBuilder"),"BuildRegisteredType")
    if type(build)~="function" then error("BuildRegisteredType unavailable",0) end
    local ok,widget=pcall(build,H(K.widget),{controllerIndex=0})
    if not ok or widget==nil then
        local load=rawget(G,"requireUnlessHotload")
        if type(load)=="function" and type(HA)=="function" then pcall(load,HA(K.module),H(K.widget)) end
        ok,widget=pcall(build,H(K.widget),{controllerIndex=0})
    end
    if not ok or widget==nil then error("widget not built: "..tostring(widget),0) end
    local bar=get(widget,K.bar)
    if type(get(bar,K.setNow))~="function" or type(get(bar,K.setAnimated))~="function"
        or get(widget,K.name)==nil then
        pcall(call,widget,"closeTree");error("widget without its bar or name",0)
    end
    local frame=holder(parent,(B.slot==0 or B.slot==4) and DROP+BAR_TOP or B.slot==2 and BAR_TOP-DROP or BAR_TOP,BAR_BOX)
    call(frame,"SetScale",B.slot==0 and GROW or B.slot==4 and UNDER_SMALL or B.slot==2 and RISE_GROW or B.slot==3 and 0 or SIDE_GROW)
    call(widget,"SetAnchorsAndPosition",0,1,0,1,0,1920,-BAR_TOP,1080-BAR_TOP)
    passive(widget);call(frame,"addElement",widget)
    B.widget=widget;B.bar=bar;B.mode="copy"
end
-- the widget's own name/icon step for a bar list entry; the script's name otherwise
local function identify(id,name)
    local named=false
    if id then
        pcall(function()
            local E=rawget(G,"Engine")
            local ref=invoke(E,K.entry,H(K.list),id)
            if ref==nil or ref=="" then return end
            local row=invoke(E,K.bundle,ref)
            if row==nil then return end
            local title=get(row,K.title)
            if title==nil or title=="" then return end
            call(get(B.widget,K.name),"setText",invoke(E,K.localize,title))
            named=true
            local material,register=get(row,K.icon),rawget(G,"RegisterMaterial")
            if material~=nil and material~="" and type(register)=="function" then
                call(get(B.widget,K.icon),"setImage",register(material))
            end
        end)
    end
    if not named then call(get(B.widget,K.name),"setText",name) end
    return named
end
-- the widget's own health step: width 0..500, at once the first time, animated after
local function health(fraction)
    local width=math.floor(WIDTH*fraction)
    if width==get(B.widget,K.last) or width<=0 then return end
    if get(B.widget,K.first) then
        call(B.bar,K.setNow,width);put(B.widget,K.first,false)
    else
        call(B.bar,K.setAnimated,width)
    end
    put(B.widget,K.last,width)
end
-- 0.5.37: the widget's own clips for immunity (the ones the game's bar plays
-- for the server's immune / vulnerable states), through ACTIONS.AnimateSequence
-- as the widget plays its default clip
local function clip(key)
    local f=get(rawget(G,"ACTIONS"),"AnimateSequence")
    if type(f)=="function" then pcall(f,B.widget,H(key)) end
end
local function immunity(on)
    if on then
        if not B.immune then clip(K.immune);B.immune=true;B.calm=nil end
    elseif B.immune then
        clip(K.vulnerable);B.immune=false;B.calm=B.ticks+CALM
    elseif B.calm and B.ticks>=B.calm then
        clip(K.default);B.calm=nil
    end
end

-- the 0.3.5 drawing
local function buildDrawn(parent)
    local top=(B.slot==0 or B.slot==4) and TOP or B.slot==2 and TOP-2*DROP or BAR_TOP
    local frame=holder(parent,top,BOX_Y+BOX_H)
    call(frame,"SetAnchorsAndPosition",.5,.5,0,1,LEFT+B.dx,LEFT+W+B.dx,top,top+BOX_Y+BOX_H)
    local text=newElement("UIStyledText")
    place(text,9,0,W-9,NAME_H)
    local fonts=rawget(G,"FONT_HANDLE")
    local font=get(fonts,"PrimaryBold") or get(fonts,"TertiaryMedium") or get(fonts,"PrimaryRegular")
    if font then call(text,"SetFont",font) end
    call(text,"SetFontSize",18*(tonumber(rawget(G,"_PT")) or 1))
    call(text,"SetRGB",0xffffff);call(text,"SetAlignment",0)
    passive(text);call(frame,"addElement",text)
    B.text=text
    local band=BOX_Y+(BOX_H-BAND_H)/2
    B.band=band
    rectangle(frame,1,BOX_Y+1,W-2,BOX_H-2,0x0a0408,.55)                 -- box
    for _,line in ipairs({{0,BOX_Y,W,1},{0,BOX_Y+BOX_H-1,W,1},{0,BOX_Y,1,BOX_H},{W-1,BOX_Y,1,BOX_H}}) do
        rectangle(frame,line[1],line[2],line[3],line[4],0x8f6bff,.85)   -- frame
    end
    rectangle(frame,PAD,band,BAND_W,BAND_H,0x2a0a10,.9)                 -- empty band
    B.fill=rectangle(frame,PAD,band,BAND_W,BAND_H/2,0xf23340,1)         -- two-tone red
    B.fill2=rectangle(frame,PAD,band+BAND_H/2,BAND_W,BAND_H/2,0xb81a26,1)
    for x=PAD+5,PAD+BAND_W-1,6 do rectangle(frame,x,band,1,BAND_H,0x000000,.35) end  -- segments
    B.mode="drawn"
end
local function drawn(name,fraction)
    if name~=B.name then call(B.text,"setText",name);B.name=name end
    local width=math.floor(BAND_W*fraction+.5)
    if width~=B.width then
        place(B.fill,PAD,B.band,width,BAND_H/2)
        place(B.fill2,PAD,B.band+BAND_H/2,width,BAND_H/2)
        call(B.fill,"SetAlpha",width>0 and 1 or 0)
        call(B.fill2,"SetAlpha",width>0 and 1 or 0)
        B.width=width
    end
end

local function tick()
    B.ticks=B.ticks+1
    if invoke(rawget(G,"Engine"),"InFrontend")~=false then if B.frame then clear() end;return end
    local value=invoke(rawget(G,"Dvar"),"GetDvarString",DVAR)
    local name,fraction,stamp,id,slot,immune=parse(value~=nil and tostring(value) or "")
    if stamp==B.stamp then B.still=B.still+1 else B.still=0;B.stamp=stamp end
    if not name or B.still>STALE then if B.frame then clear() end;return end
    if slot~=B.slot then if B.frame then clear() end;B.slot=slot;B.dx=(slot==-1 or slot==1) and slot*SIDE or 0 end
    if invoke(get(rawget(G,"LUI"),"FlowManager"),"IsInStack",H("MPPauseMenu"))==true then hide();return end
    local parent=displayParent()
    if not parent then return end
    if not B.frame or B.parent~=parent then
        clear()
        if B.failures<TRIES then
            local ok,why=pcall(buildCopy,parent)
            if not ok then clear();B.failures=B.failures+1;B.failure=tostring(why) end
        end
        if not B.frame then buildDrawn(parent) end
    end
    if B.mode=="copy" then
        if name~=B.name or id~=B.id then
            local named=identify(id,name)
            B.name=name;B.id=id
            report("copy; "..(named and "name and icon from bar entry "..id or "name from script"))
        end
        health(fraction)
        immunity(immune)
    else
        drawn(name,fraction)
        report("drawn; "..tostring(B.failure))
    end
    if not B.visible then call(B.frame,"SetAlpha",1,120);B.visible=true end
end
B.tick=tick

-- native UI timer: a hidden element's Wait(16), armed again after each tick
local function timerRoot()
    local L=rawget(G,"LUI")
    local ok,current=pcall(invoke,L,"GetRoot")
    if ok and current then return current end
    return get(L,"primaryRoot")
end
local function ensureTimer()
    if not B.enabled then return end
    local root=timerRoot()
    if not root then return end
    local okParent,parent=pcall(call,B.timer,"getParent")
    if okParent and parent==root then return end
    if B.timer then pcall(call,B.timer,"closeTree") end
    B.timer=nil
    pcall(function()
        local host=newElement("UIElement")
        passive(host);call(root,"addElement",host);B.timer=host
        local function schedule()
            if not B.enabled or B.timer~=host then return end
            local animation=call(host,"Wait",16)
            if not animation then B.timer=nil;return end
            animation.onComplete=function()
                if not B.enabled or B.timer~=host then return end
                local ok=pcall(tick)
                if not ok then clear() end
                pcall(schedule)
            end
        end
        schedule()
    end)
end
B.ensureTimer=ensureTimer;B.clear=clear

-- the timer dies when the UI root is rebuilt (map load): input events start it again
local hooked=setmetatable({},{__mode="k"})
local function install()
    local input=get(rawget(G,"LUI"),"UIRoot")
    local original=get(input,"QueueInput")
    if type(original)~="function" or hooked[input] then return end
    local wrapped=function(...)
        if B.enabled then pcall(ensureTimer) end
        return original(...)
    end
    hooked[input]=true
    input.QueueInput=wrapped;input[H("QueueInput")]=wrapped
end
pcall(ensureTimer)
pcall(install)
end)
-- [rex arena bar2 end]
-- [rex arena bar3 begin]
-- Second boss health bar (0.3.4; since 0.3.6 a second copy of the game's own
-- boss bar). The game shows one boss bar: the widget ScriptedWidgetBossHealthBar
-- (type 0x92d2213283134045, ingame_zm). While Z-Rex and the Guardian are both
-- alive, zm_rex_arena writes the boss that bar is not following to the dvar
-- rex_arena_bar3 as "NAME|health|max|server time|bar list id". This block
-- builds a second instance of that widget, 76 units under the first and grown
-- 6.3% to match its size on screen (0.3.7), and feeds
-- it with the widget's own steps: name and icon from the bar list entry, the
-- health as a width of 0..500 set at once the first time and animated after.
-- If the widget cannot be built, the 0.3.5 drawn bar is used. What was used
-- goes to the dvar rex_arena_bar3_ui for the script's record. Empty, malformed
-- or no longer changing values remove it. It runs in its own protected call,
-- so a fault here cannot reach the menu code below.
-- 0.5.25: a value can end in a slot ("...|bar list id|slot"): 0 under the
-- game's bar (as before), -1 left of it, 1 right of it. The block is also
-- copied as the bar3 block, reading rex_arena_bar3.
-- 0.5.37: slot 2 is DROP units above the game's bar, slot 3 in its place. A
-- seventh field 1 plays the widget's own immune clip; back to 0, its
-- vulnerable clip and then its default one.
-- 0.5.39: slot 4 is under the game's bar like slot 0, at 94%.
pcall(function()
local G=_G
local C=rawget(G,"CLUA")
local H=rawget(G,"xhash") or rawget(G,"PushXHash") or (type(C)=="table" and C.PushXHash)
local HD=rawget(G,"xhashdvar") or rawget(G,"PushXHashDvar") or (type(C)=="table" and C.PushXHashDvar)
local HA=rawget(G,"xhashasset") or (type(C)=="table" and C.PushXHashAsset)
if type(H)~="function" or type(HD)~="function" then return end
local old=rawget(G,"REX_ARENA_BAR3")
if type(old)=="table" then old.enabled=false;if type(old.clear)=="function" then pcall(old.clear) end end
local B={enabled=true,ticks=0,still=0,visible=false,failures=0,slot=0,dx=0}
rawset(G,"REX_ARENA_BAR3",B)
local DVAR=HD("rex_arena_bar3")
local UI_DVAR=HD("rex_arena_bar3_ui")
-- the game's widget (1920x1080 units) draws its name from y=141 and its icon
-- down to y=210; the copy goes this far below it
local DROP=76
-- the copy is held in a box around its bar (widget y 123..231) grown about the
-- box's centre: drawn lower, the curved HUD shows it about 6% smaller than the
-- game's bar (0.3.6 screenshot: 504 against 536 px); the game sizes an element
-- 1 + scale times
local BAR_TOP,BAR_BOX,GROW=123,108,0.063
-- 0.5.25: a copy in slot -1 or 1 is level with the game's bar, SIDE units
-- left or right of its centre, at 85% size so three fit in a row
local SIDE,SIDE_GROW=590,-0.15
-- 0.5.37: a copy in slot 2 (above the game's bar) is a little smaller, the
-- curved HUD showing higher elements larger; slot 3 is the game's size.
-- After an immunity, the default clip comes CALM ticks after the vulnerable one.
local RISE_GROW,CALM=-0.06,45
-- 0.5.39: slot 4: under the game's bar like slot 0 but smaller (94%), for a
-- second boss under the main one (slot 0 looked 6% bigger than the main bar)
local UNDER_SMALL=-0.06
local WIDTH=500        -- the inner bar's width; the game writes 500 * health / max
local TRIES=3          -- failed builds of the copy before staying with the drawing
-- the game's keys (luafile_7aa61794fc16de36 / luafile_6e3d854c0b033738)
local K={widget="0x92d2213283134045",module="0x7aa61794fc16de36",bar="0xb0e6b8094f2f2b6b",
    setNow="0x1308fc7d3b941d09",setAnimated="0x468ab2aecc8d2221",first="0xccd7022c4ddd9e89",
    last="0x3662de31dab8f469",name="0x8d53be57673b8a44",icon="0xdbff4cc56c2092f0",
    list="0x9c9913488ca22949",entry="0x7a35b1d2343c2b34",bundle="0xf06093d047200548",
    localize="0xaed84c33ec5f01ea",title="0x8ed55aa074c2e0a7",
    immune="0xb1609ad657c4db1c",vulnerable="0x8755afbce28bd095",default="0xdef6c3ab55c07bef"}
-- 0.3.5 drawing, 1080p units
local LEFT,W,TOP,NAME_H,BOX_Y,BOX_H,PAD,BAND_H=-240,518,196,20,22,24,6,12
local BAND_W=W-2*PAD
local STALE=180

local function get(object,key)
    if object==nil then return nil end
    local plain,value=pcall(function()return object[key]end)
    if plain and value~=nil then return value end
    local ok,hashed=pcall(function()return object[H(key)]end)
    if ok then return hashed end
    return nil
end
local function put(object,key,value) object[H(key)]=value end
local function invoke(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(...) end
end
local function call(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(object,...) end
end
local function newElement(kind)
    local f=get(get(rawget(G,"LUI"),kind),"new")
    if type(f)~="function" then error("Native "..kind.." constructor unavailable",0) end
    return f()
end
local function passive(element)
    call(element,"SetHandleMouse",false);call(element,"setFocusable",false)
end
local function place(node,x,y,w,h)
    call(node,"SetAnchorsAndPosition",0,1,0,1,x,x+w,y,y+h)
end
local function rectangle(parent,x,y,w,h,rgb,alpha)
    local element=newElement("UIImage")
    place(element,x,y,w,h)
    call(element,"SetRGB",rgb);call(element,"SetAlpha",alpha)
    passive(element);call(parent,"addElement",element)
    return element
end

-- "NAME|health|max|time[|id[|slot]]" -> name, fraction 0..1, time, id, slot;
-- nil when not a bar. A slot other than -1 or 1 is 0.
local function parse(text)
    if type(text)~="string" or text=="" or #text>96 then return nil end
    local name,hp,max,stamp,id,slot,immune=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)|(%-?%d+)|([01])$")
    if not name then name,hp,max,stamp,id,slot=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)|(%-?%d+)$") end
    if not name then name,hp,max,stamp,id=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)$") end
    if not name then name,hp,max,stamp=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)$") end
    hp,max,id,slot=tonumber(hp),tonumber(max),tonumber(id),tonumber(slot)
    if not name or not hp or not max or max<=0 then return nil end
    local fraction=hp/max
    if fraction<0 then fraction=0 elseif fraction>1 then fraction=1 end
    if id and id<0 then id=nil end
    if slot~=-1 and slot~=1 and slot~=2 and slot~=3 and slot~=4 then slot=0 end
    return name,fraction,stamp,id,slot,immune=="1"
end
B.parse=parse

local function report(text)
    text=tostring(text):gsub("[^%w %-%.:;,_/()]","?"):sub(1,90)
    if text==B.reported then return end
    B.reported=text
    pcall(invoke,rawget(G,"Dvar"),"SetDvarString",UI_DVAR,text)
end
local function clear()
    if B.frame then pcall(call,B.frame,"closeTree") end
    B.frame=nil;B.parent=nil;B.widget=nil;B.bar=nil;B.mode=nil
    B.visible=false;B.width=nil;B.name=nil;B.id=nil;B.immune=nil;B.calm=nil
end
local function hide()
    if B.frame and B.visible then call(B.frame,"SetAlpha",0,0) end
    B.visible=false
end
local function displayParent()
    local root=invoke(get(rawget(G,"LUI"),"UIRoot"),"GetRootForControllerIndex",0)
    if type(get(root,"addElement"))~="function" then return nil end
    for _=1,16 do
        local parent=call(root,"getParent")
        if not parent or parent==root then break end
        root=parent
    end
    return root
end
local function holder(parent,y,h)
    local frame=newElement("UIElement")
    call(frame,"SetAnchorsAndPosition",.5,.5,0,1,-960+B.dx,960+B.dx,y,y+h)
    call(frame,"SetAlpha",0);call(frame,"setPriority",900);passive(frame);call(parent,"addElement",frame)
    B.frame=frame;B.parent=parent
    return frame
end

-- a second instance of the game's widget
local function buildCopy(parent)
    local build=get(rawget(G,"MenuBuilder"),"BuildRegisteredType")
    if type(build)~="function" then error("BuildRegisteredType unavailable",0) end
    local ok,widget=pcall(build,H(K.widget),{controllerIndex=0})
    if not ok or widget==nil then
        local load=rawget(G,"requireUnlessHotload")
        if type(load)=="function" and type(HA)=="function" then pcall(load,HA(K.module),H(K.widget)) end
        ok,widget=pcall(build,H(K.widget),{controllerIndex=0})
    end
    if not ok or widget==nil then error("widget not built: "..tostring(widget),0) end
    local bar=get(widget,K.bar)
    if type(get(bar,K.setNow))~="function" or type(get(bar,K.setAnimated))~="function"
        or get(widget,K.name)==nil then
        pcall(call,widget,"closeTree");error("widget without its bar or name",0)
    end
    local frame=holder(parent,(B.slot==0 or B.slot==4) and DROP+BAR_TOP or B.slot==2 and BAR_TOP-DROP or BAR_TOP,BAR_BOX)
    call(frame,"SetScale",B.slot==0 and GROW or B.slot==4 and UNDER_SMALL or B.slot==2 and RISE_GROW or B.slot==3 and 0 or SIDE_GROW)
    call(widget,"SetAnchorsAndPosition",0,1,0,1,0,1920,-BAR_TOP,1080-BAR_TOP)
    passive(widget);call(frame,"addElement",widget)
    B.widget=widget;B.bar=bar;B.mode="copy"
end
-- the widget's own name/icon step for a bar list entry; the script's name otherwise
local function identify(id,name)
    local named=false
    if id then
        pcall(function()
            local E=rawget(G,"Engine")
            local ref=invoke(E,K.entry,H(K.list),id)
            if ref==nil or ref=="" then return end
            local row=invoke(E,K.bundle,ref)
            if row==nil then return end
            local title=get(row,K.title)
            if title==nil or title=="" then return end
            call(get(B.widget,K.name),"setText",invoke(E,K.localize,title))
            named=true
            local material,register=get(row,K.icon),rawget(G,"RegisterMaterial")
            if material~=nil and material~="" and type(register)=="function" then
                call(get(B.widget,K.icon),"setImage",register(material))
            end
        end)
    end
    if not named then call(get(B.widget,K.name),"setText",name) end
    return named
end
-- the widget's own health step: width 0..500, at once the first time, animated after
local function health(fraction)
    local width=math.floor(WIDTH*fraction)
    if width==get(B.widget,K.last) or width<=0 then return end
    if get(B.widget,K.first) then
        call(B.bar,K.setNow,width);put(B.widget,K.first,false)
    else
        call(B.bar,K.setAnimated,width)
    end
    put(B.widget,K.last,width)
end
-- 0.5.37: the widget's own clips for immunity (the ones the game's bar plays
-- for the server's immune / vulnerable states), through ACTIONS.AnimateSequence
-- as the widget plays its default clip
local function clip(key)
    local f=get(rawget(G,"ACTIONS"),"AnimateSequence")
    if type(f)=="function" then pcall(f,B.widget,H(key)) end
end
local function immunity(on)
    if on then
        if not B.immune then clip(K.immune);B.immune=true;B.calm=nil end
    elseif B.immune then
        clip(K.vulnerable);B.immune=false;B.calm=B.ticks+CALM
    elseif B.calm and B.ticks>=B.calm then
        clip(K.default);B.calm=nil
    end
end

-- the 0.3.5 drawing
local function buildDrawn(parent)
    local top=(B.slot==0 or B.slot==4) and TOP or B.slot==2 and TOP-2*DROP or BAR_TOP
    local frame=holder(parent,top,BOX_Y+BOX_H)
    call(frame,"SetAnchorsAndPosition",.5,.5,0,1,LEFT+B.dx,LEFT+W+B.dx,top,top+BOX_Y+BOX_H)
    local text=newElement("UIStyledText")
    place(text,9,0,W-9,NAME_H)
    local fonts=rawget(G,"FONT_HANDLE")
    local font=get(fonts,"PrimaryBold") or get(fonts,"TertiaryMedium") or get(fonts,"PrimaryRegular")
    if font then call(text,"SetFont",font) end
    call(text,"SetFontSize",18*(tonumber(rawget(G,"_PT")) or 1))
    call(text,"SetRGB",0xffffff);call(text,"SetAlignment",0)
    passive(text);call(frame,"addElement",text)
    B.text=text
    local band=BOX_Y+(BOX_H-BAND_H)/2
    B.band=band
    rectangle(frame,1,BOX_Y+1,W-2,BOX_H-2,0x0a0408,.55)                 -- box
    for _,line in ipairs({{0,BOX_Y,W,1},{0,BOX_Y+BOX_H-1,W,1},{0,BOX_Y,1,BOX_H},{W-1,BOX_Y,1,BOX_H}}) do
        rectangle(frame,line[1],line[2],line[3],line[4],0x8f6bff,.85)   -- frame
    end
    rectangle(frame,PAD,band,BAND_W,BAND_H,0x2a0a10,.9)                 -- empty band
    B.fill=rectangle(frame,PAD,band,BAND_W,BAND_H/2,0xf23340,1)         -- two-tone red
    B.fill2=rectangle(frame,PAD,band+BAND_H/2,BAND_W,BAND_H/2,0xb81a26,1)
    for x=PAD+5,PAD+BAND_W-1,6 do rectangle(frame,x,band,1,BAND_H,0x000000,.35) end  -- segments
    B.mode="drawn"
end
local function drawn(name,fraction)
    if name~=B.name then call(B.text,"setText",name);B.name=name end
    local width=math.floor(BAND_W*fraction+.5)
    if width~=B.width then
        place(B.fill,PAD,B.band,width,BAND_H/2)
        place(B.fill2,PAD,B.band+BAND_H/2,width,BAND_H/2)
        call(B.fill,"SetAlpha",width>0 and 1 or 0)
        call(B.fill2,"SetAlpha",width>0 and 1 or 0)
        B.width=width
    end
end

local function tick()
    B.ticks=B.ticks+1
    if invoke(rawget(G,"Engine"),"InFrontend")~=false then if B.frame then clear() end;return end
    local value=invoke(rawget(G,"Dvar"),"GetDvarString",DVAR)
    local name,fraction,stamp,id,slot,immune=parse(value~=nil and tostring(value) or "")
    if stamp==B.stamp then B.still=B.still+1 else B.still=0;B.stamp=stamp end
    if not name or B.still>STALE then if B.frame then clear() end;return end
    if slot~=B.slot then if B.frame then clear() end;B.slot=slot;B.dx=(slot==-1 or slot==1) and slot*SIDE or 0 end
    if invoke(get(rawget(G,"LUI"),"FlowManager"),"IsInStack",H("MPPauseMenu"))==true then hide();return end
    local parent=displayParent()
    if not parent then return end
    if not B.frame or B.parent~=parent then
        clear()
        if B.failures<TRIES then
            local ok,why=pcall(buildCopy,parent)
            if not ok then clear();B.failures=B.failures+1;B.failure=tostring(why) end
        end
        if not B.frame then buildDrawn(parent) end
    end
    if B.mode=="copy" then
        if name~=B.name or id~=B.id then
            local named=identify(id,name)
            B.name=name;B.id=id
            report("copy; "..(named and "name and icon from bar entry "..id or "name from script"))
        end
        health(fraction)
        immunity(immune)
    else
        drawn(name,fraction)
        report("drawn; "..tostring(B.failure))
    end
    if not B.visible then call(B.frame,"SetAlpha",1,120);B.visible=true end
end
B.tick=tick

-- native UI timer: a hidden element's Wait(16), armed again after each tick
local function timerRoot()
    local L=rawget(G,"LUI")
    local ok,current=pcall(invoke,L,"GetRoot")
    if ok and current then return current end
    return get(L,"primaryRoot")
end
local function ensureTimer()
    if not B.enabled then return end
    local root=timerRoot()
    if not root then return end
    local okParent,parent=pcall(call,B.timer,"getParent")
    if okParent and parent==root then return end
    if B.timer then pcall(call,B.timer,"closeTree") end
    B.timer=nil
    pcall(function()
        local host=newElement("UIElement")
        passive(host);call(root,"addElement",host);B.timer=host
        local function schedule()
            if not B.enabled or B.timer~=host then return end
            local animation=call(host,"Wait",16)
            if not animation then B.timer=nil;return end
            animation.onComplete=function()
                if not B.enabled or B.timer~=host then return end
                local ok=pcall(tick)
                if not ok then clear() end
                pcall(schedule)
            end
        end
        schedule()
    end)
end
B.ensureTimer=ensureTimer;B.clear=clear

-- the timer dies when the UI root is rebuilt (map load): input events start it again
local hooked=setmetatable({},{__mode="k"})
local function install()
    local input=get(rawget(G,"LUI"),"UIRoot")
    local original=get(input,"QueueInput")
    if type(original)~="function" or hooked[input] then return end
    local wrapped=function(...)
        if B.enabled then pcall(ensureTimer) end
        return original(...)
    end
    hooked[input]=true
    input.QueueInput=wrapped;input[H("QueueInput")]=wrapped
end
pcall(ensureTimer)
pcall(install)
end)
-- [rex arena bar3 end]
-- [rex arena bar4 begin]
-- Second boss health bar (0.3.4; since 0.3.6 a second copy of the game's own
-- boss bar). The game shows one boss bar: the widget ScriptedWidgetBossHealthBar
-- (type 0x92d2213283134045, ingame_zm). While Z-Rex and the Guardian are both
-- alive, zm_rex_arena writes the boss that bar is not following to the dvar
-- rex_arena_bar4 as "NAME|health|max|server time|bar list id". This block
-- builds a second instance of that widget, 76 units under the first and grown
-- 6.3% to match its size on screen (0.3.7), and feeds
-- it with the widget's own steps: name and icon from the bar list entry, the
-- health as a width of 0..500 set at once the first time and animated after.
-- If the widget cannot be built, the 0.3.5 drawn bar is used. What was used
-- goes to the dvar rex_arena_bar4_ui for the script's record. Empty, malformed
-- or no longer changing values remove it. It runs in its own protected call,
-- so a fault here cannot reach the menu code below.
-- 0.5.25: a value can end in a slot ("...|bar list id|slot"): 0 under the
-- game's bar (as before), -1 left of it, 1 right of it. The block is also
-- copied as the bar3 block, reading rex_arena_bar3.
-- 0.5.37: slot 2 is DROP units above the game's bar, slot 3 in its place. A
-- seventh field 1 plays the widget's own immune clip; back to 0, its
-- vulnerable clip and then its default one.
-- 0.5.39: slot 4 is under the game's bar like slot 0, at 94%.
pcall(function()
local G=_G
local C=rawget(G,"CLUA")
local H=rawget(G,"xhash") or rawget(G,"PushXHash") or (type(C)=="table" and C.PushXHash)
local HD=rawget(G,"xhashdvar") or rawget(G,"PushXHashDvar") or (type(C)=="table" and C.PushXHashDvar)
local HA=rawget(G,"xhashasset") or (type(C)=="table" and C.PushXHashAsset)
if type(H)~="function" or type(HD)~="function" then return end
local old=rawget(G,"REX_ARENA_BAR4")
if type(old)=="table" then old.enabled=false;if type(old.clear)=="function" then pcall(old.clear) end end
local B={enabled=true,ticks=0,still=0,visible=false,failures=0,slot=0,dx=0}
rawset(G,"REX_ARENA_BAR4",B)
local DVAR=HD("rex_arena_bar4")
local UI_DVAR=HD("rex_arena_bar4_ui")
-- the game's widget (1920x1080 units) draws its name from y=141 and its icon
-- down to y=210; the copy goes this far below it
local DROP=76
-- the copy is held in a box around its bar (widget y 123..231) grown about the
-- box's centre: drawn lower, the curved HUD shows it about 6% smaller than the
-- game's bar (0.3.6 screenshot: 504 against 536 px); the game sizes an element
-- 1 + scale times
local BAR_TOP,BAR_BOX,GROW=123,108,0.063
-- 0.5.25: a copy in slot -1 or 1 is level with the game's bar, SIDE units
-- left or right of its centre, at 85% size so three fit in a row
local SIDE,SIDE_GROW=590,-0.15
-- 0.5.37: a copy in slot 2 (above the game's bar) is a little smaller, the
-- curved HUD showing higher elements larger; slot 3 is the game's size.
-- After an immunity, the default clip comes CALM ticks after the vulnerable one.
local RISE_GROW,CALM=-0.06,45
-- 0.5.39: slot 4: under the game's bar like slot 0 but smaller (94%), for a
-- second boss under the main one (slot 0 looked 6% bigger than the main bar)
local UNDER_SMALL=-0.06
local WIDTH=500        -- the inner bar's width; the game writes 500 * health / max
local TRIES=3          -- failed builds of the copy before staying with the drawing
-- the game's keys (luafile_7aa61794fc16de36 / luafile_6e3d854c0b033738)
local K={widget="0x92d2213283134045",module="0x7aa61794fc16de36",bar="0xb0e6b8094f2f2b6b",
    setNow="0x1308fc7d3b941d09",setAnimated="0x468ab2aecc8d2221",first="0xccd7022c4ddd9e89",
    last="0x3662de31dab8f469",name="0x8d53be57673b8a44",icon="0xdbff4cc56c2092f0",
    list="0x9c9913488ca22949",entry="0x7a35b1d2343c2b34",bundle="0xf06093d047200548",
    localize="0xaed84c33ec5f01ea",title="0x8ed55aa074c2e0a7",
    immune="0xb1609ad657c4db1c",vulnerable="0x8755afbce28bd095",default="0xdef6c3ab55c07bef"}
-- 0.3.5 drawing, 1080p units
local LEFT,W,TOP,NAME_H,BOX_Y,BOX_H,PAD,BAND_H=-240,518,196,20,22,24,6,12
local BAND_W=W-2*PAD
local STALE=180

local function get(object,key)
    if object==nil then return nil end
    local plain,value=pcall(function()return object[key]end)
    if plain and value~=nil then return value end
    local ok,hashed=pcall(function()return object[H(key)]end)
    if ok then return hashed end
    return nil
end
local function put(object,key,value) object[H(key)]=value end
local function invoke(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(...) end
end
local function call(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(object,...) end
end
local function newElement(kind)
    local f=get(get(rawget(G,"LUI"),kind),"new")
    if type(f)~="function" then error("Native "..kind.." constructor unavailable",0) end
    return f()
end
local function passive(element)
    call(element,"SetHandleMouse",false);call(element,"setFocusable",false)
end
local function place(node,x,y,w,h)
    call(node,"SetAnchorsAndPosition",0,1,0,1,x,x+w,y,y+h)
end
local function rectangle(parent,x,y,w,h,rgb,alpha)
    local element=newElement("UIImage")
    place(element,x,y,w,h)
    call(element,"SetRGB",rgb);call(element,"SetAlpha",alpha)
    passive(element);call(parent,"addElement",element)
    return element
end

-- "NAME|health|max|time[|id[|slot]]" -> name, fraction 0..1, time, id, slot;
-- nil when not a bar. A slot other than -1 or 1 is 0.
local function parse(text)
    if type(text)~="string" or text=="" or #text>96 then return nil end
    local name,hp,max,stamp,id,slot,immune=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)|(%-?%d+)|([01])$")
    if not name then name,hp,max,stamp,id,slot=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)|(%-?%d+)$") end
    if not name then name,hp,max,stamp,id=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)$") end
    if not name then name,hp,max,stamp=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)$") end
    hp,max,id,slot=tonumber(hp),tonumber(max),tonumber(id),tonumber(slot)
    if not name or not hp or not max or max<=0 then return nil end
    local fraction=hp/max
    if fraction<0 then fraction=0 elseif fraction>1 then fraction=1 end
    if id and id<0 then id=nil end
    if slot~=-1 and slot~=1 and slot~=2 and slot~=3 and slot~=4 then slot=0 end
    return name,fraction,stamp,id,slot,immune=="1"
end
B.parse=parse

local function report(text)
    text=tostring(text):gsub("[^%w %-%.:;,_/()]","?"):sub(1,90)
    if text==B.reported then return end
    B.reported=text
    pcall(invoke,rawget(G,"Dvar"),"SetDvarString",UI_DVAR,text)
end
local function clear()
    if B.frame then pcall(call,B.frame,"closeTree") end
    B.frame=nil;B.parent=nil;B.widget=nil;B.bar=nil;B.mode=nil
    B.visible=false;B.width=nil;B.name=nil;B.id=nil;B.immune=nil;B.calm=nil
end
local function hide()
    if B.frame and B.visible then call(B.frame,"SetAlpha",0,0) end
    B.visible=false
end
local function displayParent()
    local root=invoke(get(rawget(G,"LUI"),"UIRoot"),"GetRootForControllerIndex",0)
    if type(get(root,"addElement"))~="function" then return nil end
    for _=1,16 do
        local parent=call(root,"getParent")
        if not parent or parent==root then break end
        root=parent
    end
    return root
end
local function holder(parent,y,h)
    local frame=newElement("UIElement")
    call(frame,"SetAnchorsAndPosition",.5,.5,0,1,-960+B.dx,960+B.dx,y,y+h)
    call(frame,"SetAlpha",0);call(frame,"setPriority",900);passive(frame);call(parent,"addElement",frame)
    B.frame=frame;B.parent=parent
    return frame
end

-- a second instance of the game's widget
local function buildCopy(parent)
    local build=get(rawget(G,"MenuBuilder"),"BuildRegisteredType")
    if type(build)~="function" then error("BuildRegisteredType unavailable",0) end
    local ok,widget=pcall(build,H(K.widget),{controllerIndex=0})
    if not ok or widget==nil then
        local load=rawget(G,"requireUnlessHotload")
        if type(load)=="function" and type(HA)=="function" then pcall(load,HA(K.module),H(K.widget)) end
        ok,widget=pcall(build,H(K.widget),{controllerIndex=0})
    end
    if not ok or widget==nil then error("widget not built: "..tostring(widget),0) end
    local bar=get(widget,K.bar)
    if type(get(bar,K.setNow))~="function" or type(get(bar,K.setAnimated))~="function"
        or get(widget,K.name)==nil then
        pcall(call,widget,"closeTree");error("widget without its bar or name",0)
    end
    local frame=holder(parent,(B.slot==0 or B.slot==4) and DROP+BAR_TOP or B.slot==2 and BAR_TOP-DROP or BAR_TOP,BAR_BOX)
    call(frame,"SetScale",B.slot==0 and GROW or B.slot==4 and UNDER_SMALL or B.slot==2 and RISE_GROW or B.slot==3 and 0 or SIDE_GROW)
    call(widget,"SetAnchorsAndPosition",0,1,0,1,0,1920,-BAR_TOP,1080-BAR_TOP)
    passive(widget);call(frame,"addElement",widget)
    B.widget=widget;B.bar=bar;B.mode="copy"
end
-- the widget's own name/icon step for a bar list entry; the script's name otherwise
local function identify(id,name)
    local named=false
    if id then
        pcall(function()
            local E=rawget(G,"Engine")
            local ref=invoke(E,K.entry,H(K.list),id)
            if ref==nil or ref=="" then return end
            local row=invoke(E,K.bundle,ref)
            if row==nil then return end
            local title=get(row,K.title)
            if title==nil or title=="" then return end
            call(get(B.widget,K.name),"setText",invoke(E,K.localize,title))
            named=true
            local material,register=get(row,K.icon),rawget(G,"RegisterMaterial")
            if material~=nil and material~="" and type(register)=="function" then
                call(get(B.widget,K.icon),"setImage",register(material))
            end
        end)
    end
    if not named then call(get(B.widget,K.name),"setText",name) end
    return named
end
-- the widget's own health step: width 0..500, at once the first time, animated after
local function health(fraction)
    local width=math.floor(WIDTH*fraction)
    if width==get(B.widget,K.last) or width<=0 then return end
    if get(B.widget,K.first) then
        call(B.bar,K.setNow,width);put(B.widget,K.first,false)
    else
        call(B.bar,K.setAnimated,width)
    end
    put(B.widget,K.last,width)
end
-- 0.5.37: the widget's own clips for immunity (the ones the game's bar plays
-- for the server's immune / vulnerable states), through ACTIONS.AnimateSequence
-- as the widget plays its default clip
local function clip(key)
    local f=get(rawget(G,"ACTIONS"),"AnimateSequence")
    if type(f)=="function" then pcall(f,B.widget,H(key)) end
end
local function immunity(on)
    if on then
        if not B.immune then clip(K.immune);B.immune=true;B.calm=nil end
    elseif B.immune then
        clip(K.vulnerable);B.immune=false;B.calm=B.ticks+CALM
    elseif B.calm and B.ticks>=B.calm then
        clip(K.default);B.calm=nil
    end
end

-- the 0.3.5 drawing
local function buildDrawn(parent)
    local top=(B.slot==0 or B.slot==4) and TOP or B.slot==2 and TOP-2*DROP or BAR_TOP
    local frame=holder(parent,top,BOX_Y+BOX_H)
    call(frame,"SetAnchorsAndPosition",.5,.5,0,1,LEFT+B.dx,LEFT+W+B.dx,top,top+BOX_Y+BOX_H)
    local text=newElement("UIStyledText")
    place(text,9,0,W-9,NAME_H)
    local fonts=rawget(G,"FONT_HANDLE")
    local font=get(fonts,"PrimaryBold") or get(fonts,"TertiaryMedium") or get(fonts,"PrimaryRegular")
    if font then call(text,"SetFont",font) end
    call(text,"SetFontSize",18*(tonumber(rawget(G,"_PT")) or 1))
    call(text,"SetRGB",0xffffff);call(text,"SetAlignment",0)
    passive(text);call(frame,"addElement",text)
    B.text=text
    local band=BOX_Y+(BOX_H-BAND_H)/2
    B.band=band
    rectangle(frame,1,BOX_Y+1,W-2,BOX_H-2,0x0a0408,.55)                 -- box
    for _,line in ipairs({{0,BOX_Y,W,1},{0,BOX_Y+BOX_H-1,W,1},{0,BOX_Y,1,BOX_H},{W-1,BOX_Y,1,BOX_H}}) do
        rectangle(frame,line[1],line[2],line[3],line[4],0x8f6bff,.85)   -- frame
    end
    rectangle(frame,PAD,band,BAND_W,BAND_H,0x2a0a10,.9)                 -- empty band
    B.fill=rectangle(frame,PAD,band,BAND_W,BAND_H/2,0xf23340,1)         -- two-tone red
    B.fill2=rectangle(frame,PAD,band+BAND_H/2,BAND_W,BAND_H/2,0xb81a26,1)
    for x=PAD+5,PAD+BAND_W-1,6 do rectangle(frame,x,band,1,BAND_H,0x000000,.35) end  -- segments
    B.mode="drawn"
end
local function drawn(name,fraction)
    if name~=B.name then call(B.text,"setText",name);B.name=name end
    local width=math.floor(BAND_W*fraction+.5)
    if width~=B.width then
        place(B.fill,PAD,B.band,width,BAND_H/2)
        place(B.fill2,PAD,B.band+BAND_H/2,width,BAND_H/2)
        call(B.fill,"SetAlpha",width>0 and 1 or 0)
        call(B.fill2,"SetAlpha",width>0 and 1 or 0)
        B.width=width
    end
end

local function tick()
    B.ticks=B.ticks+1
    if invoke(rawget(G,"Engine"),"InFrontend")~=false then if B.frame then clear() end;return end
    local value=invoke(rawget(G,"Dvar"),"GetDvarString",DVAR)
    local name,fraction,stamp,id,slot,immune=parse(value~=nil and tostring(value) or "")
    if stamp==B.stamp then B.still=B.still+1 else B.still=0;B.stamp=stamp end
    if not name or B.still>STALE then if B.frame then clear() end;return end
    if slot~=B.slot then if B.frame then clear() end;B.slot=slot;B.dx=(slot==-1 or slot==1) and slot*SIDE or 0 end
    if invoke(get(rawget(G,"LUI"),"FlowManager"),"IsInStack",H("MPPauseMenu"))==true then hide();return end
    local parent=displayParent()
    if not parent then return end
    if not B.frame or B.parent~=parent then
        clear()
        if B.failures<TRIES then
            local ok,why=pcall(buildCopy,parent)
            if not ok then clear();B.failures=B.failures+1;B.failure=tostring(why) end
        end
        if not B.frame then buildDrawn(parent) end
    end
    if B.mode=="copy" then
        if name~=B.name or id~=B.id then
            local named=identify(id,name)
            B.name=name;B.id=id
            report("copy; "..(named and "name and icon from bar entry "..id or "name from script"))
        end
        health(fraction)
        immunity(immune)
    else
        drawn(name,fraction)
        report("drawn; "..tostring(B.failure))
    end
    if not B.visible then call(B.frame,"SetAlpha",1,120);B.visible=true end
end
B.tick=tick

-- native UI timer: a hidden element's Wait(16), armed again after each tick
local function timerRoot()
    local L=rawget(G,"LUI")
    local ok,current=pcall(invoke,L,"GetRoot")
    if ok and current then return current end
    return get(L,"primaryRoot")
end
local function ensureTimer()
    if not B.enabled then return end
    local root=timerRoot()
    if not root then return end
    local okParent,parent=pcall(call,B.timer,"getParent")
    if okParent and parent==root then return end
    if B.timer then pcall(call,B.timer,"closeTree") end
    B.timer=nil
    pcall(function()
        local host=newElement("UIElement")
        passive(host);call(root,"addElement",host);B.timer=host
        local function schedule()
            if not B.enabled or B.timer~=host then return end
            local animation=call(host,"Wait",16)
            if not animation then B.timer=nil;return end
            animation.onComplete=function()
                if not B.enabled or B.timer~=host then return end
                local ok=pcall(tick)
                if not ok then clear() end
                pcall(schedule)
            end
        end
        schedule()
    end)
end
B.ensureTimer=ensureTimer;B.clear=clear

-- the timer dies when the UI root is rebuilt (map load): input events start it again
local hooked=setmetatable({},{__mode="k"})
local function install()
    local input=get(rawget(G,"LUI"),"UIRoot")
    local original=get(input,"QueueInput")
    if type(original)~="function" or hooked[input] then return end
    local wrapped=function(...)
        if B.enabled then pcall(ensureTimer) end
        return original(...)
    end
    hooked[input]=true
    input.QueueInput=wrapped;input[H("QueueInput")]=wrapped
end
pcall(ensureTimer)
pcall(install)
end)
-- [rex arena bar4 end]
-- [rex arena bar5 begin]
-- Second boss health bar (0.3.4; since 0.3.6 a second copy of the game's own
-- boss bar). The game shows one boss bar: the widget ScriptedWidgetBossHealthBar
-- (type 0x92d2213283134045, ingame_zm). While Z-Rex and the Guardian are both
-- alive, zm_rex_arena writes the boss that bar is not following to the dvar
-- rex_arena_bar5 as "NAME|health|max|server time|bar list id". This block
-- builds a second instance of that widget, 76 units under the first and grown
-- 6.3% to match its size on screen (0.3.7), and feeds
-- it with the widget's own steps: name and icon from the bar list entry, the
-- health as a width of 0..500 set at once the first time and animated after.
-- If the widget cannot be built, the 0.3.5 drawn bar is used. What was used
-- goes to the dvar rex_arena_bar5_ui for the script's record. Empty, malformed
-- or no longer changing values remove it. It runs in its own protected call,
-- so a fault here cannot reach the menu code below.
-- 0.5.25: a value can end in a slot ("...|bar list id|slot"): 0 under the
-- game's bar (as before), -1 left of it, 1 right of it. The block is also
-- copied as the bar3 block, reading rex_arena_bar3.
-- 0.5.37: slot 2 is DROP units above the game's bar, slot 3 in its place. A
-- seventh field 1 plays the widget's own immune clip; back to 0, its
-- vulnerable clip and then its default one.
-- 0.5.39: slot 4 is under the game's bar like slot 0, at 94%.
pcall(function()
local G=_G
local C=rawget(G,"CLUA")
local H=rawget(G,"xhash") or rawget(G,"PushXHash") or (type(C)=="table" and C.PushXHash)
local HD=rawget(G,"xhashdvar") or rawget(G,"PushXHashDvar") or (type(C)=="table" and C.PushXHashDvar)
local HA=rawget(G,"xhashasset") or (type(C)=="table" and C.PushXHashAsset)
if type(H)~="function" or type(HD)~="function" then return end
local old=rawget(G,"REX_ARENA_BAR5")
if type(old)=="table" then old.enabled=false;if type(old.clear)=="function" then pcall(old.clear) end end
local B={enabled=true,ticks=0,still=0,visible=false,failures=0,slot=0,dx=0}
rawset(G,"REX_ARENA_BAR5",B)
local DVAR=HD("rex_arena_bar5")
local UI_DVAR=HD("rex_arena_bar5_ui")
-- the game's widget (1920x1080 units) draws its name from y=141 and its icon
-- down to y=210; the copy goes this far below it
local DROP=76
-- the copy is held in a box around its bar (widget y 123..231) grown about the
-- box's centre: drawn lower, the curved HUD shows it about 6% smaller than the
-- game's bar (0.3.6 screenshot: 504 against 536 px); the game sizes an element
-- 1 + scale times
local BAR_TOP,BAR_BOX,GROW=123,108,0.063
-- 0.5.25: a copy in slot -1 or 1 is level with the game's bar, SIDE units
-- left or right of its centre, at 85% size so three fit in a row
local SIDE,SIDE_GROW=590,-0.15
-- 0.5.37: a copy in slot 2 (above the game's bar) is a little smaller, the
-- curved HUD showing higher elements larger; slot 3 is the game's size.
-- After an immunity, the default clip comes CALM ticks after the vulnerable one.
local RISE_GROW,CALM=-0.06,45
-- 0.5.39: slot 4: under the game's bar like slot 0 but smaller (94%), for a
-- second boss under the main one (slot 0 looked 6% bigger than the main bar)
local UNDER_SMALL=-0.06
local WIDTH=500        -- the inner bar's width; the game writes 500 * health / max
local TRIES=3          -- failed builds of the copy before staying with the drawing
-- the game's keys (luafile_7aa61794fc16de36 / luafile_6e3d854c0b033738)
local K={widget="0x92d2213283134045",module="0x7aa61794fc16de36",bar="0xb0e6b8094f2f2b6b",
    setNow="0x1308fc7d3b941d09",setAnimated="0x468ab2aecc8d2221",first="0xccd7022c4ddd9e89",
    last="0x3662de31dab8f469",name="0x8d53be57673b8a44",icon="0xdbff4cc56c2092f0",
    list="0x9c9913488ca22949",entry="0x7a35b1d2343c2b34",bundle="0xf06093d047200548",
    localize="0xaed84c33ec5f01ea",title="0x8ed55aa074c2e0a7",
    immune="0xb1609ad657c4db1c",vulnerable="0x8755afbce28bd095",default="0xdef6c3ab55c07bef"}
-- 0.3.5 drawing, 1080p units
local LEFT,W,TOP,NAME_H,BOX_Y,BOX_H,PAD,BAND_H=-240,518,196,20,22,24,6,12
local BAND_W=W-2*PAD
local STALE=180

local function get(object,key)
    if object==nil then return nil end
    local plain,value=pcall(function()return object[key]end)
    if plain and value~=nil then return value end
    local ok,hashed=pcall(function()return object[H(key)]end)
    if ok then return hashed end
    return nil
end
local function put(object,key,value) object[H(key)]=value end
local function invoke(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(...) end
end
local function call(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(object,...) end
end
local function newElement(kind)
    local f=get(get(rawget(G,"LUI"),kind),"new")
    if type(f)~="function" then error("Native "..kind.." constructor unavailable",0) end
    return f()
end
local function passive(element)
    call(element,"SetHandleMouse",false);call(element,"setFocusable",false)
end
local function place(node,x,y,w,h)
    call(node,"SetAnchorsAndPosition",0,1,0,1,x,x+w,y,y+h)
end
local function rectangle(parent,x,y,w,h,rgb,alpha)
    local element=newElement("UIImage")
    place(element,x,y,w,h)
    call(element,"SetRGB",rgb);call(element,"SetAlpha",alpha)
    passive(element);call(parent,"addElement",element)
    return element
end

-- "NAME|health|max|time[|id[|slot]]" -> name, fraction 0..1, time, id, slot;
-- nil when not a bar. A slot other than -1 or 1 is 0.
local function parse(text)
    if type(text)~="string" or text=="" or #text>96 then return nil end
    local name,hp,max,stamp,id,slot,immune=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)|(%-?%d+)|([01])$")
    if not name then name,hp,max,stamp,id,slot=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)|(%-?%d+)$") end
    if not name then name,hp,max,stamp,id=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)|(%-?%d+)$") end
    if not name then name,hp,max,stamp=text:match("^([%w %-]+)|(%-?%d+)|(%d+)|(%-?%d+)$") end
    hp,max,id,slot=tonumber(hp),tonumber(max),tonumber(id),tonumber(slot)
    if not name or not hp or not max or max<=0 then return nil end
    local fraction=hp/max
    if fraction<0 then fraction=0 elseif fraction>1 then fraction=1 end
    if id and id<0 then id=nil end
    if slot~=-1 and slot~=1 and slot~=2 and slot~=3 and slot~=4 then slot=0 end
    return name,fraction,stamp,id,slot,immune=="1"
end
B.parse=parse

local function report(text)
    text=tostring(text):gsub("[^%w %-%.:;,_/()]","?"):sub(1,90)
    if text==B.reported then return end
    B.reported=text
    pcall(invoke,rawget(G,"Dvar"),"SetDvarString",UI_DVAR,text)
end
local function clear()
    if B.frame then pcall(call,B.frame,"closeTree") end
    B.frame=nil;B.parent=nil;B.widget=nil;B.bar=nil;B.mode=nil
    B.visible=false;B.width=nil;B.name=nil;B.id=nil;B.immune=nil;B.calm=nil
end
local function hide()
    if B.frame and B.visible then call(B.frame,"SetAlpha",0,0) end
    B.visible=false
end
local function displayParent()
    local root=invoke(get(rawget(G,"LUI"),"UIRoot"),"GetRootForControllerIndex",0)
    if type(get(root,"addElement"))~="function" then return nil end
    for _=1,16 do
        local parent=call(root,"getParent")
        if not parent or parent==root then break end
        root=parent
    end
    return root
end
local function holder(parent,y,h)
    local frame=newElement("UIElement")
    call(frame,"SetAnchorsAndPosition",.5,.5,0,1,-960+B.dx,960+B.dx,y,y+h)
    call(frame,"SetAlpha",0);call(frame,"setPriority",900);passive(frame);call(parent,"addElement",frame)
    B.frame=frame;B.parent=parent
    return frame
end

-- a second instance of the game's widget
local function buildCopy(parent)
    local build=get(rawget(G,"MenuBuilder"),"BuildRegisteredType")
    if type(build)~="function" then error("BuildRegisteredType unavailable",0) end
    local ok,widget=pcall(build,H(K.widget),{controllerIndex=0})
    if not ok or widget==nil then
        local load=rawget(G,"requireUnlessHotload")
        if type(load)=="function" and type(HA)=="function" then pcall(load,HA(K.module),H(K.widget)) end
        ok,widget=pcall(build,H(K.widget),{controllerIndex=0})
    end
    if not ok or widget==nil then error("widget not built: "..tostring(widget),0) end
    local bar=get(widget,K.bar)
    if type(get(bar,K.setNow))~="function" or type(get(bar,K.setAnimated))~="function"
        or get(widget,K.name)==nil then
        pcall(call,widget,"closeTree");error("widget without its bar or name",0)
    end
    local frame=holder(parent,(B.slot==0 or B.slot==4) and DROP+BAR_TOP or B.slot==2 and BAR_TOP-DROP or BAR_TOP,BAR_BOX)
    call(frame,"SetScale",B.slot==0 and GROW or B.slot==4 and UNDER_SMALL or B.slot==2 and RISE_GROW or B.slot==3 and 0 or SIDE_GROW)
    call(widget,"SetAnchorsAndPosition",0,1,0,1,0,1920,-BAR_TOP,1080-BAR_TOP)
    passive(widget);call(frame,"addElement",widget)
    B.widget=widget;B.bar=bar;B.mode="copy"
end
-- the widget's own name/icon step for a bar list entry; the script's name otherwise
local function identify(id,name)
    local named=false
    if id then
        pcall(function()
            local E=rawget(G,"Engine")
            local ref=invoke(E,K.entry,H(K.list),id)
            if ref==nil or ref=="" then return end
            local row=invoke(E,K.bundle,ref)
            if row==nil then return end
            local title=get(row,K.title)
            if title==nil or title=="" then return end
            call(get(B.widget,K.name),"setText",invoke(E,K.localize,title))
            named=true
            local material,register=get(row,K.icon),rawget(G,"RegisterMaterial")
            if material~=nil and material~="" and type(register)=="function" then
                call(get(B.widget,K.icon),"setImage",register(material))
            end
        end)
    end
    if not named then call(get(B.widget,K.name),"setText",name) end
    return named
end
-- the widget's own health step: width 0..500, at once the first time, animated after
local function health(fraction)
    local width=math.floor(WIDTH*fraction)
    if width==get(B.widget,K.last) or width<=0 then return end
    if get(B.widget,K.first) then
        call(B.bar,K.setNow,width);put(B.widget,K.first,false)
    else
        call(B.bar,K.setAnimated,width)
    end
    put(B.widget,K.last,width)
end
-- 0.5.37: the widget's own clips for immunity (the ones the game's bar plays
-- for the server's immune / vulnerable states), through ACTIONS.AnimateSequence
-- as the widget plays its default clip
local function clip(key)
    local f=get(rawget(G,"ACTIONS"),"AnimateSequence")
    if type(f)=="function" then pcall(f,B.widget,H(key)) end
end
local function immunity(on)
    if on then
        if not B.immune then clip(K.immune);B.immune=true;B.calm=nil end
    elseif B.immune then
        clip(K.vulnerable);B.immune=false;B.calm=B.ticks+CALM
    elseif B.calm and B.ticks>=B.calm then
        clip(K.default);B.calm=nil
    end
end

-- the 0.3.5 drawing
local function buildDrawn(parent)
    local top=(B.slot==0 or B.slot==4) and TOP or B.slot==2 and TOP-2*DROP or BAR_TOP
    local frame=holder(parent,top,BOX_Y+BOX_H)
    call(frame,"SetAnchorsAndPosition",.5,.5,0,1,LEFT+B.dx,LEFT+W+B.dx,top,top+BOX_Y+BOX_H)
    local text=newElement("UIStyledText")
    place(text,9,0,W-9,NAME_H)
    local fonts=rawget(G,"FONT_HANDLE")
    local font=get(fonts,"PrimaryBold") or get(fonts,"TertiaryMedium") or get(fonts,"PrimaryRegular")
    if font then call(text,"SetFont",font) end
    call(text,"SetFontSize",18*(tonumber(rawget(G,"_PT")) or 1))
    call(text,"SetRGB",0xffffff);call(text,"SetAlignment",0)
    passive(text);call(frame,"addElement",text)
    B.text=text
    local band=BOX_Y+(BOX_H-BAND_H)/2
    B.band=band
    rectangle(frame,1,BOX_Y+1,W-2,BOX_H-2,0x0a0408,.55)                 -- box
    for _,line in ipairs({{0,BOX_Y,W,1},{0,BOX_Y+BOX_H-1,W,1},{0,BOX_Y,1,BOX_H},{W-1,BOX_Y,1,BOX_H}}) do
        rectangle(frame,line[1],line[2],line[3],line[4],0x8f6bff,.85)   -- frame
    end
    rectangle(frame,PAD,band,BAND_W,BAND_H,0x2a0a10,.9)                 -- empty band
    B.fill=rectangle(frame,PAD,band,BAND_W,BAND_H/2,0xf23340,1)         -- two-tone red
    B.fill2=rectangle(frame,PAD,band+BAND_H/2,BAND_W,BAND_H/2,0xb81a26,1)
    for x=PAD+5,PAD+BAND_W-1,6 do rectangle(frame,x,band,1,BAND_H,0x000000,.35) end  -- segments
    B.mode="drawn"
end
local function drawn(name,fraction)
    if name~=B.name then call(B.text,"setText",name);B.name=name end
    local width=math.floor(BAND_W*fraction+.5)
    if width~=B.width then
        place(B.fill,PAD,B.band,width,BAND_H/2)
        place(B.fill2,PAD,B.band+BAND_H/2,width,BAND_H/2)
        call(B.fill,"SetAlpha",width>0 and 1 or 0)
        call(B.fill2,"SetAlpha",width>0 and 1 or 0)
        B.width=width
    end
end

local function tick()
    B.ticks=B.ticks+1
    if invoke(rawget(G,"Engine"),"InFrontend")~=false then if B.frame then clear() end;return end
    local value=invoke(rawget(G,"Dvar"),"GetDvarString",DVAR)
    local name,fraction,stamp,id,slot,immune=parse(value~=nil and tostring(value) or "")
    if stamp==B.stamp then B.still=B.still+1 else B.still=0;B.stamp=stamp end
    if not name or B.still>STALE then if B.frame then clear() end;return end
    if slot~=B.slot then if B.frame then clear() end;B.slot=slot;B.dx=(slot==-1 or slot==1) and slot*SIDE or 0 end
    if invoke(get(rawget(G,"LUI"),"FlowManager"),"IsInStack",H("MPPauseMenu"))==true then hide();return end
    local parent=displayParent()
    if not parent then return end
    if not B.frame or B.parent~=parent then
        clear()
        if B.failures<TRIES then
            local ok,why=pcall(buildCopy,parent)
            if not ok then clear();B.failures=B.failures+1;B.failure=tostring(why) end
        end
        if not B.frame then buildDrawn(parent) end
    end
    if B.mode=="copy" then
        if name~=B.name or id~=B.id then
            local named=identify(id,name)
            B.name=name;B.id=id
            report("copy; "..(named and "name and icon from bar entry "..id or "name from script"))
        end
        health(fraction)
        immunity(immune)
    else
        drawn(name,fraction)
        report("drawn; "..tostring(B.failure))
    end
    if not B.visible then call(B.frame,"SetAlpha",1,120);B.visible=true end
end
B.tick=tick

-- native UI timer: a hidden element's Wait(16), armed again after each tick
local function timerRoot()
    local L=rawget(G,"LUI")
    local ok,current=pcall(invoke,L,"GetRoot")
    if ok and current then return current end
    return get(L,"primaryRoot")
end
local function ensureTimer()
    if not B.enabled then return end
    local root=timerRoot()
    if not root then return end
    local okParent,parent=pcall(call,B.timer,"getParent")
    if okParent and parent==root then return end
    if B.timer then pcall(call,B.timer,"closeTree") end
    B.timer=nil
    pcall(function()
        local host=newElement("UIElement")
        passive(host);call(root,"addElement",host);B.timer=host
        local function schedule()
            if not B.enabled or B.timer~=host then return end
            local animation=call(host,"Wait",16)
            if not animation then B.timer=nil;return end
            animation.onComplete=function()
                if not B.enabled or B.timer~=host then return end
                local ok=pcall(tick)
                if not ok then clear() end
                pcall(schedule)
            end
        end
        schedule()
    end)
end
B.ensureTimer=ensureTimer;B.clear=clear

-- the timer dies when the UI root is rebuilt (map load): input events start it again
local hooked=setmetatable({},{__mode="k"})
local function install()
    local input=get(rawget(G,"LUI"),"UIRoot")
    local original=get(input,"QueueInput")
    if type(original)~="function" or hooked[input] then return end
    local wrapped=function(...)
        if B.enabled then pcall(ensureTimer) end
        return original(...)
    end
    hooked[input]=true
    input.QueueInput=wrapped;input[H("QueueInput")]=wrapped
end
pcall(ensureTimer)
pcall(install)
end)
-- [rex arena bar5 end]
-- [rex arena hud begin]
-- 0.5.27: a HUD note for the boss fights, in its own protected call (0.5.28:
-- the Caltheris phase label is removed). The note (dvar rex_arena_note,
-- "TITLE|BODY|server time|seconds"): the fight summary (0.5.29: the round-500
-- warning is removed), centred near the top of the screen for that many seconds; a new
-- time shows it again. 0.5.30: on a dark panel sized to the text, with a thin
-- red-orange rule at its top and bottom. What was shown goes to the dvar
-- rex_arena_hud_ui for the script's record.
pcall(function()
local G=_G
local C=rawget(G,"CLUA")
local H=rawget(G,"xhash") or rawget(G,"PushXHash") or (type(C)=="table" and C.PushXHash)
local HD=rawget(G,"xhashdvar") or rawget(G,"PushXHashDvar") or (type(C)=="table" and C.PushXHashDvar)
if type(H)~="function" or type(HD)~="function" then return end
local old=rawget(G,"REX_ARENA_HUD")
if type(old)=="table" then old.enabled=false;if type(old.clear)=="function" then pcall(old.clear) end end
local U={enabled=true,ticks=0}
rawset(G,"REX_ARENA_HUD",U)
local NOTE_DVAR,UI_DVAR=HD("rex_arena_note"),HD("rex_arena_hud_ui")
local PER_SECOND=60       -- ticks run on a 16 ms UI timer
local NOTE_Y,TITLE_H,BODY_H,NOTE_W=262,40,30,1400
-- 0.5.30: the panel. Text widths from the 0.5.29 screenshot: about 18 units a
-- title character (size 34) and 10 a body character (size 22).
local TITLE_CHAR,BODY_CHAR,PAD_X,PAD_Y,MIN_W=18,10,40,10,360
local PANEL_RGB,PANEL_ALPHA,RULE_RGB,RULE_ALPHA,RULE_H=0x0a0608,.62,0xb8402a,.85,2

local function get(object,key)
    if object==nil then return nil end
    local plain,value=pcall(function()return object[key]end)
    if plain and value~=nil then return value end
    local ok,hashed=pcall(function()return object[H(key)]end)
    if ok then return hashed end
    return nil
end
local function invoke(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(...) end
end
local function call(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(object,...) end
end
local function newElement(kind)
    local f=get(get(rawget(G,"LUI"),kind),"new")
    if type(f)~="function" then error("Native "..kind.." constructor unavailable",0) end
    return f()
end
local function passive(element)
    call(element,"SetHandleMouse",false);call(element,"setFocusable",false)
end
local function report(text)
    text=tostring(text):gsub("[^%w %-%.:;,_/()]","?"):sub(1,90)
    if text==U.reported then return end
    U.reported=text
    pcall(invoke,rawget(G,"Dvar"),"SetDvarString",UI_DVAR,text)
end
local function dvar(name)
    local value=invoke(rawget(G,"Dvar"),"GetDvarString",name)
    return value~=nil and tostring(value) or ""
end
local function displayParent()
    local root=invoke(get(rawget(G,"LUI"),"UIRoot"),"GetRootForControllerIndex",0)
    if type(get(root,"addElement"))~="function" then return nil end
    for _=1,16 do
        local parent=call(root,"getParent")
        if not parent or parent==root then break end
        root=parent
    end
    return root
end

-- the note
local function parseNote(text)
    if text=="" or #text>160 then return nil end
    local title,body,stamp,seconds=text:match("^([%w %-:,%./()]*)|([%w %-:,%./()]*)|(%-?%d+)|(%d+)$")
    seconds=tonumber(seconds)
    if not title or title=="" or not seconds or seconds<=0 or seconds>30 then return nil end
    return title,body,stamp,seconds
end
local function noteClear()
    if U.note then pcall(call,U.note,"closeTree") end
    U.note=nil;U.noteParent=nil;U.noteShown=false
end
local function noteText(parent,y,h,size)
    local text=newElement("UIStyledText")
    call(text,"SetAnchorsAndPosition",0,1,0,1,0,NOTE_W,y,y+h)
    local fonts=rawget(G,"FONT_HANDLE")
    local font=get(fonts,"PrimaryBold") or get(fonts,"TertiaryMedium") or get(fonts,"PrimaryRegular")
    if font then call(text,"SetFont",font) end
    call(text,"SetFontSize",size*(tonumber(rawget(G,"_PT")) or 1))
    call(text,"SetRGB",0xffffff)
    local centre=get(get(rawget(G,"LUI"),"Alignment"),"Center")
    call(text,"SetAlignment",centre~=nil and centre or 1)
    passive(text);call(parent,"addElement",text)
    return text
end
local function noteImage(parent,rgb,alpha)
    local image=newElement("UIImage")
    call(image,"SetRGB",rgb);call(image,"SetAlpha",alpha)
    passive(image);call(parent,"addElement",image)
    return image
end
-- 0.5.30: the panel and its rules, sized to the text
local function notePanel(title,body)
    local w=math.max(#title*TITLE_CHAR,#body*BODY_CHAR)+2*PAD_X
    if w<MIN_W then w=MIN_W elseif w>NOTE_W then w=NOTE_W end
    local x,top=(NOTE_W-w)/2,-PAD_Y
    local h=TITLE_H+BODY_H+2*PAD_Y
    call(U.panel,"SetAnchorsAndPosition",0,1,0,1,x,x+w,top,top+h)
    call(U.ruleTop,"SetAnchorsAndPosition",0,1,0,1,x,x+w,top,top+RULE_H)
    call(U.ruleBottom,"SetAnchorsAndPosition",0,1,0,1,x,x+w,top+h-RULE_H,top+h)
    U.panelW=w
end
local function noteBuild(parent)
    local frame=newElement("UIElement")
    call(frame,"SetAnchorsAndPosition",.5,.5,0,1,-NOTE_W/2,NOTE_W/2,NOTE_Y,NOTE_Y+TITLE_H+BODY_H)
    call(frame,"SetAlpha",0);call(frame,"setPriority",901);passive(frame);call(parent,"addElement",frame)
    U.note=frame;U.noteParent=parent
    U.panel=noteImage(frame,PANEL_RGB,PANEL_ALPHA)
    U.ruleTop=noteImage(frame,RULE_RGB,RULE_ALPHA)
    U.ruleBottom=noteImage(frame,RULE_RGB,RULE_ALPHA)
    U.title=noteText(frame,0,TITLE_H,34)
    U.body=noteText(frame,TITLE_H,BODY_H,22)
end
local function noteTick(parent,paused)
    local title,body,stamp,seconds=parseNote(dvar(NOTE_DVAR))
    if not title then if U.note then noteClear() end;return end
    if stamp~=U.noteStamp then U.noteStamp=stamp;U.noteLeft=seconds*PER_SECOND;U.noteShown=false end
    if (U.noteLeft or 0)<=0 then if U.note then noteClear() end;return end
    U.noteLeft=U.noteLeft-1
    if paused or not parent then
        if U.note then call(U.note,"SetAlpha",0) end
        U.noteShown=false
        return
    end
    if not U.note or U.noteParent~=parent then noteClear();noteBuild(parent) end
    if not U.noteShown then
        call(U.title,"setText",title);call(U.body,"setText",body)
        notePanel(title,body)
        call(U.note,"SetAlpha",1,150);U.noteShown=true
        report("note: "..title)
    end
end

local function clear()
    noteClear()
end
local function tick()
    U.ticks=U.ticks+1
    if invoke(rawget(G,"Engine"),"InFrontend")~=false then
        clear()
        local _,_,stamp=parseNote(dvar(NOTE_DVAR))
        U.noteStamp=stamp;U.noteLeft=0
        return
    end
    local paused=invoke(get(rawget(G,"LUI"),"FlowManager"),"IsInStack",H("MPPauseMenu"))==true
    local parent=displayParent()
    noteTick(parent,paused)
end
U.tick=tick;U.clear=clear

-- native UI timer: a hidden element's Wait(16), armed again after each tick
local function timerRoot()
    local L=rawget(G,"LUI")
    local ok,current=pcall(invoke,L,"GetRoot")
    if ok and current then return current end
    return get(L,"primaryRoot")
end
local function ensureTimer()
    if not U.enabled then return end
    local root=timerRoot()
    if not root then return end
    local okParent,parent=pcall(call,U.timer,"getParent")
    if okParent and parent==root then return end
    if U.timer then pcall(call,U.timer,"closeTree") end
    U.timer=nil
    pcall(function()
        local host=newElement("UIElement")
        passive(host);call(root,"addElement",host);U.timer=host
        local function schedule()
            if not U.enabled or U.timer~=host then return end
            local animation=call(host,"Wait",16)
            if not animation then U.timer=nil;return end
            animation.onComplete=function()
                if not U.enabled or U.timer~=host then return end
                local ok=pcall(tick)
                if not ok then clear() end
                pcall(schedule)
            end
        end
        schedule()
    end)
end
U.ensureTimer=ensureTimer

-- the timer dies when the UI root is rebuilt (map load): input events start it again
local hooked=setmetatable({},{__mode="k"})
local function install()
    local input=get(rawget(G,"LUI"),"UIRoot")
    local original=get(input,"QueueInput")
    if type(original)~="function" or hooked[input] then return end
    local wrapped=function(...)
        if U.enabled then pcall(ensureTimer) end
        return original(...)
    end
    hooked[input]=true
    input.QueueInput=wrapped;input[H("QueueInput")]=wrapped
end
pcall(ensureTimer)
pcall(install)
end)
-- [rex arena hud end]
-- [rex arena ultra begin]
-- 0.5.87: the Arsenal's WEAPON RARITY row gets BO7's Ultra upgrade once the
-- round-75 Guardian has made Ultra available. zm_rex_arena adds the Ultra item
-- (scriptbundle 0x76b58e1ee1e4569d, the fifth item of BO7's Cursed rarity
-- list) to the Arsenal's server menu and writes the dvar rex_arena_ultra as
-- "server index|group position|Legendary's server index". This block wraps
-- the game's group list builder (PurchaseMenuUtils 0x249daa49174b1bec,
-- luafile_1c2e836a5250e14) and appends the Ultra entry to the rarity group
-- (the group with the Legendary entry, name 0x2a699cbbf39ea43b), built from
-- its bundle the way the game builds entries (0x768d835be8d75aa0), with the
-- server's index, only if the Legendary entry has the server's Legendary
-- index. Empty dvar: no change. The dvar is cleared in the frontend. What
-- happened goes to rex_arena_ultra_ui for the script's record.
pcall(function()
local G=_G
local C=rawget(G,"CLUA")
local H=rawget(G,"xhash") or rawget(G,"PushXHash") or (type(C)=="table" and C.PushXHash)
local HD=rawget(G,"xhashdvar") or rawget(G,"PushXHashDvar") or (type(C)=="table" and C.PushXHashDvar)
local HA=rawget(G,"xhashasset") or (type(C)=="table" and C.PushXHashAsset)
if type(H)~="function" or type(HD)~="function" or type(HA)~="function" then return end
local old=rawget(G,"REX_ARENA_ULTRA")
if type(old)=="table" then old.enabled=false end
local U={enabled=true,wrapped=setmetatable({},{__mode="k"}),hooked=setmetatable({},{__mode="k"})}
rawset(G,"REX_ARENA_ULTRA",U)
local DVAR,UI_DVAR=HD("rex_arena_ultra"),HD("rex_arena_ultra_ui")
-- the game's keys (luafile_1c2e836a5250e14)
local K={build="0x249daa49174b1bec",bundle="0xf06093d047200548",ultra="0x76b58e1ee1e4569d",
    rarity="0x2a699cbbf39ea43b",name="0x89e9c01960f4c582",items="0x3e7884bf4f412c6f",
    level="0x1e6f84ef2eb65989",index="0x30ba635b40657d07",position="0xb7f04639fd95bc39",
    ref="0xc93b8ebcc208569b",notFirst="0xaafcc2d7201b71ae",hidden="0xb32a46624ffc3379",
    itemType="0xde604bfe9c3ff46f",typeSource="0x2f313f8dd7e409d8",currency="0xd0967be97c125db6",
    currencySource="0x75a5fb9b890ad416",omnvar="0xbad3f6f2a679497d",getOmnvar="0x628624def6f708c8"}
-- entry fields the game copies from the item's bundle under the same key
local SAME={"0x0bef0691197c9f78","0x455f116bf695c8f6","0x9a661bb517690f26","0x0cc44970c8397929",
    "0x874d69d715905bd4","0x21b5434076368809","0x1e6f84ef2eb65989","0x0f89f7b9e5fc0544",
    "0x8b4fb25579c73f53","0x0bf57e3302012727","0xad7984ddeb5643a7","0x9e5f25925ec6d701",
    "0x02a2e4943d7e1743","0x88a0a36c6fd383e6","0x55a53b120ebfbdc4","0x5d3bf36cd0208187",
    "0xc7679b40127480c8","0xb7790affd384da77","0xbad3f6f2a679497d"}
-- and under another key {entry key, bundle key}
local MOVED={{"0x2ab612888528489a","0xdbff4cc56c2092f0"},{"0xc78f218425db9d53","0x2087b450e36ab8fb"}}
-- group and menu fields, the same on every entry of the group
local SHARED={"0x5bd2e7ffb1224e91","0x8ff238f7dff1082f","0x2687b2a9032d11af","0xedc07cb4fd262c1d",
    "0x98e6278c382f7ffc"}

local function get(object,key)
    if object==nil then return nil end
    local plain,value=pcall(function()return object[key]end)
    if plain and value~=nil then return value end
    local ok,hashed=pcall(function()return object[H(key)]end)
    if ok then return hashed end
    return nil
end
local function field(object,key)
    if object==nil then return nil end
    local ok,value=pcall(function()return object[H(key)]end)
    if ok then return value end
    return nil
end
local function invoke(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(...) end
end
local function report(text)
    text=tostring(text):gsub("[^%w %-%.:;,_/()|]","?"):sub(1,120)
    if text==U.reported then return end
    U.reported=text
    pcall(invoke,rawget(G,"Dvar"),"SetDvarString",UI_DVAR,text)
end
local function dvar(name)
    local value=invoke(rawget(G,"Dvar"),"GetDvarString",name)
    return value~=nil and tostring(value) or ""
end
local function same(a,b) return a==b or (a~=nil and b~=nil and tostring(a)==tostring(b)) end

local function addUltra(result)
    local value=dvar(DVAR)
    if value=="" or type(result)~="table" then return end
    local index,position,legendaryIndex=value:match("^(%d+)|(%d+)|(%d+)$")
    index,position,legendaryIndex=tonumber(index),tonumber(position),tonumber(legendaryIndex)
    if not index then report("ultra: bad value "..value);return end
    local groups=result
    if result[H(K.items)]~=nil then groups={result} end
    for _,group in ipairs(groups) do
        local items=type(group)=="table" and group[H(K.items)]
        local legendary
        if type(items)=="table" then
            for _,entry in ipairs(items) do
                if type(entry)=="table" and entry[H(K.level)]==4 then legendary=entry end
            end
        end
        if legendary then
            local how=same(group[H(K.name)],H(K.rarity)) and "rarity group" or "group with Legendary"
            for _,entry in ipairs(items) do
                if entry[H(K.level)]==5 or entry[H(K.index)]==index then
                    report("ultra: already in the "..how.." (slot "..tostring(entry[H(K.position)])..")");return
                end
            end
            if legendary[H(K.index)]~=legendaryIndex then
                report("ultra: Legendary index "..tostring(legendary[H(K.index)]).." here, "..legendaryIndex.." on the server; not added");return
            end
            local E=rawget(G,"Engine")
            local ref=HA(K.ultra)
            local bundle=invoke(E,K.bundle,ref)
            if bundle==nil then report("ultra: Ultra bundle not loaded here");return end
            local entry={}
            for _,key in ipairs(SAME) do entry[H(key)]=field(bundle,key) end
            for _,pair in ipairs(MOVED) do entry[H(pair[1])]=field(bundle,pair[2]) end
            for _,key in ipairs(SHARED) do entry[H(key)]=legendary[H(key)] end
            if entry[H(K.level)]~=5 then report("ultra: bundle level "..tostring(entry[H(K.level)]).."; not added");return end
            entry[H(K.ref)]=ref
            entry[H(K.notFirst)]=true
            entry[H(K.position)]=#items+1
            entry[H(K.index)]=index
            local source=field(bundle,K.typeSource)
            local LOOT=rawget(G,"LOOT")
            if source~=nil and type(LOOT)=="table" and type(LOOT.itemTypes)=="table" then
                entry[H(K.itemType)]=LOOT.itemTypes[source]
            end
            local currency=field(bundle,K.currencySource)
            entry[H(K.currency)]=(currency~=nil and invoke(E,K.bundle,currency)) or legendary[H(K.currency)]
            table.insert(items,entry)
            local omnvar="none"
            if entry[H(K.omnvar)]~=nil then
                local ok,on=pcall(invoke,rawget(G,"Game"),K.getOmnvar,0,entry[H(K.omnvar)])
                omnvar=ok and tostring(on) or "error"
            end
            report("ultra: added to the "..how.." at slot "..#items..", server index "..index
                ..(field(bundle,K.hidden)==true and "; bundle marked hidden" or "").."; omnvar "..omnvar)
            return
        end
    end
end

local function wrap(original)
    local wrapped=function(...)
        local result=original(...)
        if U.enabled then
            local ok,err=pcall(addUltra,result)
            if not ok then report("ultra: error "..tostring(err)) end
        end
        return result
    end
    U.wrapped[wrapped]=true
    return wrapped
end
-- wraps the builder, again after the game's file is loaded again
local function install()
    local P=rawget(G,"PurchaseMenuUtils")
    if type(P)~="table" then return end
    local key=H(K.build)
    local current=rawget(P,key)
    if type(current)~="function" or U.wrapped[current] then return end
    rawset(P,key,wrap(current))
end
-- the slot never carries into a later match: cleared in the frontend
local function frontend()
    if invoke(rawget(G,"Engine"),"InFrontend")~=true then U.cleared=false;return end
    if U.cleared then return end
    U.cleared=true
    if dvar(DVAR)~="" then pcall(invoke,rawget(G,"Dvar"),"SetDvarString",DVAR,"") end
end
-- input events (pressing the Arsenal's button too) check both
local function hookInput()
    local input=get(rawget(G,"LUI"),"UIRoot")
    local original=get(input,"QueueInput")
    if type(original)~="function" or U.hooked[input] then return end
    local wrapped=function(...)
        if U.enabled then pcall(frontend);pcall(install) end
        return original(...)
    end
    U.hooked[input]=true
    input.QueueInput=wrapped;input[H("QueueInput")]=wrapped
end
U.install=install;U.addUltra=addUltra
pcall(frontend)
pcall(install)
pcall(hookInput)
end)
-- [rex arena ultra end]
-- [rex arena splash begin]
-- 0.5.94: the Void Talon popup (user: "why not a game style pop up i even
-- made a pictue for it", "the pop up should say VOID TALON NOW AVAILABLE below
-- void talon"). 0.5.95: the boss-pedestal progress and the round-select
-- pedestal text use the same popup, text only (user: "i want the text to be
-- more authentic and not overlap", "no need for pictures, we can just use text
-- like kuwakujo does it"). 0.5.96 (user: "the pop up goes away while im still
-- looking at it", "this pop up should come exactly after the reward pop up
-- finishes, for some reason it has alittle bit of a delay rn, same for void
-- talon"):
--  - event popups are queued at once, priority 50 under the reward popups'
--    55, so the manager shows them the moment the reward popup ends (0.5.95
--    waited for 1.5 s of nothing on screen first);
--  - the round-select popup stays up while the player is at the pedestal: the
--    popup widget gets the end hook the game's DispatchMessage asks a widget
--    for (0x4343011e07ecc003: called with the "done" callback instead of the
--    display-time Wait). For the round-select popup "done" is kept and called
--    when the script says the player left (leave), another round-select popup
--    or a pick replaces it, or any other popup is waiting (it then comes back
--    after them); every other popup gets the game's own Wait(display time).
-- BO7's own reward popup, the one PACK-A-PUNCH IV / NOW AVAILABLE uses
-- (ZMColoredRewardSplash, luafile_36a44f542c9724de, splash type
-- "zmColoredRewardSplash"), queued on the HUD's splash manager
-- (luafile_5970d97855c6ba55 OnNewMessage), in the PaP IV popup's colour
-- (Rarity.Ultra). The manager shows one popup of its group at a time, so they
-- never overlap.
-- Two dvars, "kind|time|TITLE|LINE" (0.5.94's "void_talon|time" still works):
-- rex_arena_splash for events (void_talon with the user's picture
-- images/rex_arena_void_talon.png, pedestal), rex_arena_hint for the round
-- select (hint priority 45, pick priority 52, leave). A new time is handled
-- once. When an event popup is on screen its time goes to rex_arena_splash_ok;
-- what happened goes to rex_arena_splash_ui. A time already there when the
-- block loads, or seen in the frontend, is not shown.
pcall(function()
local G=_G
local C=rawget(G,"CLUA")
local H=rawget(G,"xhash") or rawget(G,"PushXHash") or (type(C)=="table" and C.PushXHash)
local HD=rawget(G,"xhashdvar") or rawget(G,"PushXHashDvar") or (type(C)=="table" and C.PushXHashDvar)
local HA=rawget(G,"xhashasset") or (type(C)=="table" and C.PushXHashAsset)
if type(H)~="function" or type(HD)~="function" then return end
local old=rawget(G,"REX_ARENA_SPLASH")
if type(old)=="table" then
    old.enabled=false
    -- a round-select popup the old block holds is let go
    if type(old.release)=="function" then pcall(old.release) end
end
local U={enabled=true,ticks=0,wrapped=setmetatable({},{__mode="k"}),hooked=setmetatable({},{__mode="k"}),
    pending={},seen={},shown={}}
rawset(G,"REX_ARENA_SPLASH",U)
local CHANNELS={HD("rex_arena_splash"),HD("rex_arena_hint")}
local OK_DVAR,UI_DVAR=HD("rex_arena_splash_ok"),HD("rex_arena_splash_ui")
local PER_SECOND=60          -- ticks run on a 16 ms UI timer
local GIVE_UP=60*60          -- not on screen a minute after it was asked for: reported
local HOLD_LIMIT=600*PER_SECOND   -- a round-select popup is held at most 10 minutes
local IMAGE_KEY="0xdbff4cc56c2092f0"   -- the popup's image element
local END_KEY="0x4343011e07ecc003"     -- the widget's end hook (DispatchMessage)
local KINDS={
    void_talon={header="VOID TALON",body="NOW AVAILABLE",picture="rex_arena_void_talon",priority=50,time=3600},
    pedestal={priority=50,time=3600},
    pick={priority=52,time=3600,round=true},
    hint={priority=45,time=3000,round=true,hold=true},
    leave={round=true},
}
local KIND="zmColoredRewardSplash"

local function get(object,key)
    if object==nil then return nil end
    local plain,value=pcall(function()return object[key]end)
    if plain and value~=nil then return value end
    local ok,hashed=pcall(function()return object[H(key)]end)
    if ok then return hashed end
    return nil
end
local function invoke(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(...) end
end
local function call(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(object,...) end
end
local function report(text)
    text=tostring(text):gsub("[^%w %-%.:;,_/()|]","?"):sub(1,120)
    if text==U.reported then return end
    U.reported=text
    pcall(invoke,rawget(G,"Dvar"),"SetDvarString",UI_DVAR,text)
end
local function dvar(name)
    local value=invoke(rawget(G,"Dvar"),"GetDvarString",name)
    return value~=nil and tostring(value) or ""
end
local function parse(text)
    local kind,stamp,header,body=text:match("^([%w_]+)|(%d+)|([%w %-:,%./()]*)|([%w %-:,%./()]*)$")
    if not kind then kind,stamp=text:match("^([%w_]+)|(%d+)$") end
    local k=kind and KINDS[kind]
    if not k then return nil end
    if kind=="leave" then return {kind=kind,stamp=stamp} end
    header=(header~=nil and header~="") and header or k.header
    body=(body~=nil and body~="") and body or k.body
    if not header then return nil end
    return {kind=kind,stamp=stamp,header=header:upper(),body=body and body:upper() or nil}
end
-- the picture from this mod's images folder
local function material(name)
    local register=rawget(G,"RegisterMaterial")
    if type(register)~="function" then return nil end
    if type(HA)=="function" then
        local ok,value=pcall(register,HA(name))
        if ok and value then return value end
    end
    local ok,value=pcall(register,name)
    if ok and value then return value end
    return nil
end
local function manager()
    local hud=get(invoke(get(rawget(G,"LUI"),"HudManager"),"GetInstance"),"activeHud")
    local sm=get(hud,"splashManager")
    if type(get(sm,"OnNewMessage"))~="function" then return nil end
    return sm
end
local function entry(sm)
    local map=get(sm,"widgetMap")
    return type(map)=="table" and map[KIND] or nil
end
-- any popup waiting in the manager's queue
local function waiting(sm)
    local queue=get(sm,"messageQueue")
    if type(queue)~="table" then return false end
    for _,message in ipairs(queue) do
        if type(message)=="table" and not message.processed then return true end
    end
    return false
end
-- the round-select popups still waiting in the manager's queue go, the game's way
local function dropWaiting(sm)
    local queue=get(sm,"messageQueue")
    if type(queue)~="table" then return end
    for i=#queue,1,-1 do
        local message=queue[i]
        local o=type(message)=="table" and message.options
        if type(o)=="table" and o.rexArenaKind=="hint" and not message.processed then
            if type(get(sm,"RemoveMessageAtIndex"))=="function" then call(sm,"RemoveMessageAtIndex",i)
            else table.remove(queue,i) end
        end
    end
end
-- the held round-select popup ends (the manager hides it and shows the next)
local function release()
    local held=U.held
    U.held=nil
    if held then
        local ok,err=pcall(held.done)
        if not ok then report("splash: release error "..tostring(err)) end
    end
end
U.release=release
-- after the game's own ShowSplash: the picture, untinted
local function dressed(widget,options)
    local picture
    if options.rexArenaPicture then
        local image=get(widget,IMAGE_KEY)
        picture=material(options.rexArenaPicture)
        if image and picture then call(image,"setImage",picture) end
        if image then call(image,"SetRGB",0xffffff) end
    end
    U.shown[options.rexArenaStamp]=true
    -- the script waits for the event popups only (a round-select popup must not overwrite it)
    if not KINDS[options.rexArenaKind].round then
        pcall(invoke,rawget(G,"Dvar"),"SetDvarString",OK_DVAR,options.rexArenaStamp)
        report("splash: "..options.rexArenaKind.." shown"
            ..((options.rexArenaPicture and not picture) and ", picture not loaded" or "")
            .." after "..math.floor((U.ticks-(options.rexArenaAsked or U.ticks))/PER_SECOND*10)/10 .." s")
    end
end
-- the widget's end hook: the round-select popup is held, the rest end after
-- their display time as the game's DispatchMessage does without the hook
local function ending(widget,done)
    local sm=U.sm
    local message=sm and get(sm,"currentSplashMessage")
    local o=type(message)=="table" and message.options
    if U.enabled and type(o)=="table" and o.rexArenaKind=="hint" then
        U.held={done=done,stamp=o.rexArenaStamp,since=U.ticks}
        return
    end
    local time=(type(message)=="table" and tonumber(message.displayTime)) or 3000
    local animation=call(widget,"Wait",time)
    if animation then animation.onComplete=done else done() end
end
local function wrapWidget(sm)
    local data=entry(sm)
    local widget=data and data.widget
    if not widget then return false end
    U.sm=sm
    local current=get(widget,"ShowSplash")
    if type(current)~="function" then return false end
    if not U.wrapped[current] then
        local wrapped=function(self,options,...)
            local result=current(self,options,...)
            if U.enabled and type(options)=="table" and options.rexArenaStamp then
                local ok,err=pcall(dressed,self,options)
                if not ok then report("splash: picture error "..tostring(err)) end
            end
            return result
        end
        U.wrapped[wrapped]=true
        widget.ShowSplash=wrapped
    end
    if not U.hooked[widget] or get(widget,END_KEY)~=U.hooked[widget] then
        local hook=function(self,done) return ending(self,done) end
        widget[H(END_KEY)]=hook
        U.hooked[widget]=hook
    end
    return true
end
local function queue(sm,p)
    local k=KINDS[p.kind]
    if k.round then dropWaiting(sm) end
    local options={displayLocation=KIND,controllerIndex=get(sm,"controller") or 0,
        headerText=p.header,bodyText=p.body or "",useHexDisplay="Rarity.Ultra",animOverride="",
        priority=k.priority,displayTimeOverride=k.time,nextMessageDelayOverride=0,
        rexArenaStamp=p.stamp,rexArenaKind=p.kind,rexArenaPicture=k.picture,rexArenaAsked=p.asked}
    call(sm,"OnNewMessage",options)
    p.queued=U.ticks
    if not k.round then report("splash: "..p.kind.." queued after "..math.floor((U.ticks-p.asked)/PER_SECOND*10)/10 .." s") end
end
-- one waiting popup; true when it is done with
local function step(sm,p)
    if p.queued then
        if KINDS[p.kind].round or U.shown[p.stamp] then return true end
        if U.ticks-p.queued>GIVE_UP then report("splash: "..p.kind.." queued but not shown after 60 s");return true end
        return false
    end
    local waited=U.ticks-p.asked
    if not sm then
        if KINDS[p.kind].round then return waited>PER_SECOND end
        if waited>GIVE_UP then report("splash: no HUD splash manager");return true end
        if waited%PER_SECOND==0 then report("splash: waiting for the HUD") end
        return false
    end
    if not wrapWidget(sm) then
        if waited>GIVE_UP then report("splash: no reward popup widget");return true end
        return false
    end
    queue(sm,p)
    return KINDS[p.kind].round
end

local function tick()
    U.ticks=U.ticks+1
    local front=invoke(rawget(G,"Engine"),"InFrontend")~=false
    for i,channel in ipairs(CHANNELS) do
        local p=parse(dvar(channel))
        local stamp=p and p.stamp
        if front then U.seen[i]=stamp
        elseif stamp and stamp~=U.seen[i] then
            U.seen[i]=stamp
            p.asked=U.ticks
            if KINDS[p.kind].round then
                -- a newer round-select message replaces one not yet queued
                U.round=p
                for j=#U.pending,1,-1 do
                    if KINDS[U.pending[j].kind].round and not U.pending[j].queued then table.remove(U.pending,j) end
                end
            end
            if p.kind~="leave" then table.insert(U.pending,p) end
        end
    end
    if front then U.pending={};U.round=nil;release();return end
    local sm=manager()
    if U.held then
        if not U.round or U.round.stamp~=U.held.stamp then
            -- the player left, or a newer round-select message
            release()
        elseif (sm and waiting(sm)) or U.ticks-U.held.since>HOLD_LIMIT then
            -- other popups first; the same round-select popup comes back after them
            release()
            if U.ticks-U.round.asked<=HOLD_LIMIT then
                table.insert(U.pending,{kind="hint",stamp=U.round.stamp,header=U.round.header,body=U.round.body,asked=U.ticks})
            end
        end
    end
    if U.round and U.round.kind=="leave" and sm then dropWaiting(sm) end
    for j=#U.pending,1,-1 do
        if step(sm,U.pending[j]) then table.remove(U.pending,j) end
    end
end
U.tick=tick

-- native UI timer: a hidden element's Wait(16), armed again after each tick
local function newElement(kind)
    local f=get(get(rawget(G,"LUI"),kind),"new")
    if type(f)~="function" then error("Native "..kind.." constructor unavailable",0) end
    return f()
end
local function timerRoot()
    local L=rawget(G,"LUI")
    local ok,current=pcall(invoke,L,"GetRoot")
    if ok and current then return current end
    return get(L,"primaryRoot")
end
local function ensureTimer()
    if not U.enabled then return end
    local root=timerRoot()
    if not root then return end
    local okParent,parent=pcall(call,U.timer,"getParent")
    if okParent and parent==root then return end
    if U.timer then pcall(call,U.timer,"closeTree") end
    U.timer=nil
    pcall(function()
        local host=newElement("UIElement")
        call(host,"SetHandleMouse",false);call(host,"setFocusable",false)
        call(root,"addElement",host);U.timer=host
        local function schedule()
            if not U.enabled or U.timer~=host then return end
            local animation=call(host,"Wait",16)
            if not animation then U.timer=nil;return end
            animation.onComplete=function()
                if not U.enabled or U.timer~=host then return end
                local ok,err=pcall(tick)
                if not ok then report("splash: error "..tostring(err));pcall(release) end
                pcall(schedule)
            end
        end
        schedule()
    end)
end
U.ensureTimer=ensureTimer

-- the timer dies when the UI root is rebuilt (map load): input events start it again
local inputs=setmetatable({},{__mode="k"})
local function install()
    local input=get(rawget(G,"LUI"),"UIRoot")
    local original=get(input,"QueueInput")
    if type(original)~="function" or inputs[input] then return end
    local wrapped=function(...)
        if U.enabled then pcall(ensureTimer) end
        return original(...)
    end
    inputs[input]=true
    input.QueueInput=wrapped;input[H("QueueInput")]=wrapped
end
-- popups already written when the block loads are not shown
for i,channel in ipairs(CHANNELS) do
    local p=parse(dvar(channel))
    U.seen[i]=p and p.stamp
end
pcall(ensureTimer)
pcall(install)
end)
-- [rex arena splash end]
-- [rex arena minimap begin]
-- 0.5.97: the minimap (top left) and the objective tracker under it (SURVIVE /
-- Holdout in Her House) are hidden in the arena match (user: "now we need to
-- remove the minimap in the left and the survive window"). BO7's ZM HUD
-- (luafile_64b63ace4ec0bd83, LUI.ZMHUD.init) adds them as its own children:
-- 0xc973fead0481b104 (the Minimap widget, left, 217x217) and
-- 0x7c702b2799dbe78a (ZMQuestTrackingWidget, left, 315 down), with the
-- tracker's splash 0xe8a2fb27a6f0ae79 (ZMQuestTrackingSplashWidget) in the same
-- place. The HUD's visibility states fade them out and in again (map open,
-- menus), so this block sets each of them, and the widget inside it
-- (GetWidgetInternal), to alpha 0 every tick while the script's arena-only
-- dvar rex_arena_minimap is "1". The dvar is cleared in the frontend, so other
-- matches keep them. What it found goes to rex_arena_minimap_ui.
pcall(function()
local G=_G
local C=rawget(G,"CLUA")
local H=rawget(G,"xhash") or rawget(G,"PushXHash") or (type(C)=="table" and C.PushXHash)
local HD=rawget(G,"xhashdvar") or rawget(G,"PushXHashDvar") or (type(C)=="table" and C.PushXHashDvar)
if type(H)~="function" or type(HD)~="function" then return end
local old=rawget(G,"REX_ARENA_MINIMAP")
if type(old)=="table" then old.enabled=false end
local U={enabled=true,ticks=0}
rawset(G,"REX_ARENA_MINIMAP",U)
local ON_DVAR,UI_DVAR=HD("rex_arena_minimap"),HD("rex_arena_minimap_ui")
local WIDGETS={
    {name="minimap",key="0xc973fead0481b104"},
    {name="tracker",key="0x7c702b2799dbe78a"},
    {name="tracker_splash",key="0xe8a2fb27a6f0ae79"},
}

local function get(object,key)
    if object==nil then return nil end
    local plain,value=pcall(function()return object[key]end)
    if plain and value~=nil then return value end
    local ok,hashed=pcall(function()return object[H(key)]end)
    if ok then return hashed end
    return nil
end
local function invoke(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(...) end
end
local function call(object,key,...)
    local f=get(object,key)
    if type(f)=="function" then return f(object,...) end
end
local function report(text)
    text=tostring(text):gsub("[^%w %-%.:;,_/()]","?"):sub(1,90)
    if text==U.reported then return end
    U.reported=text
    pcall(invoke,rawget(G,"Dvar"),"SetDvarString",UI_DVAR,text)
end
local function dvar(name)
    local ok,value=pcall(invoke,rawget(G,"Dvar"),"GetDvarString",name)
    return ok and value~=nil and tostring(value) or ""
end
local function hide(element)
    if element==nil then return false end
    return (pcall(call,element,"SetAlpha",0))
end

local function tick()
    U.ticks=U.ticks+1
    if invoke(rawget(G,"Engine"),"InFrontend")~=false then
        if dvar(ON_DVAR)~="" then pcall(invoke,rawget(G,"Dvar"),"SetDvarString",ON_DVAR,"") end
        return
    end
    if dvar(ON_DVAR)~="1" then return end
    local hud=get(invoke(get(rawget(G,"LUI"),"HudManager"),"GetInstance"),"activeHud")
    if hud==nil then report("minimap: waiting for the HUD");return end
    local found={}
    for _,w in ipairs(WIDGETS) do
        local holder=get(hud,w.key)
        if holder~=nil then
            local shown=hide(holder)
            local ok,inner=pcall(call,hud,"GetWidgetInternal",holder)
            if ok and inner~=nil and inner~=holder then shown=hide(inner) or shown end
            if shown then found[#found+1]=w.name end
        end
    end
    if #found>0 then report("minimap: hidden "..table.concat(found," "))
    else report("minimap: none of them on the HUD") end
end
U.tick=tick

-- native UI timer: a hidden element's Wait(16), armed again after each tick
local function newElement(kind)
    local f=get(get(rawget(G,"LUI"),kind),"new")
    if type(f)~="function" then error("Native "..kind.." constructor unavailable",0) end
    return f()
end
local function timerRoot()
    local L=rawget(G,"LUI")
    local ok,current=pcall(invoke,L,"GetRoot")
    if ok and current then return current end
    return get(L,"primaryRoot")
end
local function ensureTimer()
    if not U.enabled then return end
    local root=timerRoot()
    if not root then return end
    local okParent,parent=pcall(call,U.timer,"getParent")
    if okParent and parent==root then return end
    if U.timer then pcall(call,U.timer,"closeTree") end
    U.timer=nil
    pcall(function()
        local host=newElement("UIElement")
        call(host,"SetHandleMouse",false);call(host,"setFocusable",false)
        call(root,"addElement",host);U.timer=host
        local function schedule()
            if not U.enabled or U.timer~=host then return end
            local animation=call(host,"Wait",16)
            if not animation then U.timer=nil;return end
            animation.onComplete=function()
                if not U.enabled or U.timer~=host then return end
                local ok,err=pcall(tick)
                if not ok then report("minimap: error "..tostring(err)) end
                pcall(schedule)
            end
        end
        schedule()
    end)
end
U.ensureTimer=ensureTimer

-- the timer dies when the UI root is rebuilt (map load): input events start it again
local inputs=setmetatable({},{__mode="k"})
local function install()
    local input=get(rawget(G,"LUI"),"UIRoot")
    local original=get(input,"QueueInput")
    if type(original)~="function" or inputs[input] then return end
    local wrapped=function(...)
        if U.enabled then pcall(ensureTimer) end
        return original(...)
    end
    inputs[input]=true
    input.QueueInput=wrapped;input[H("QueueInput")]=wrapped
end
pcall(ensureTimer)
pcall(install)
end)
-- [rex arena minimap end]
-- [rex arena intro begin]
-- 0.7.8: the loading screen's intro slideshow (user: "lets make the slideshow
-- intro style like we did blackwater lake survival", "first photo should be map
-- 9 then map 1, then map 8, then last map 4"): the user's four screenshots of the
-- arena, images/rex_arena_intro_1..4.png in that order (2550x1380, the photo-mode
-- shots without the watermark), 3 s each, in a 12 s loop. Each shows
-- a 2400x1350 window that pans across the picture's 150x30 margin, as Blackwater
-- Lake's intro (0.2.125) does.
-- The picture is one UIImage put right after the loading screen's Bink movie
-- widget (LUI.LoadingScreenManager instance, _loadingScreen,
-- 0x4bb93bee689a4d0e), so it covers the movie and the game's title, hints and
-- tips stay above it. Only in the arena match (the launcher's start request
-- marked rex_arena, else the POI dvar on Rex, as the loading-name hook checks).
-- Any failure leaves the game's movie and is logged once.
pcall(function()
local G=_G
local C=rawget(G,"CLUA")
local H=rawget(G,"xhash") or rawget(G,"PushXHash") or (type(C)=="table" and C.PushXHash)
local HA=rawget(G,"xhashasset") or (type(C)=="table" and C.PushXHashAsset)
local HD=rawget(G,"xhashdvar") or rawget(G,"PushXHashDvar") or (type(C)=="table" and C.PushXHashDvar)
local engine,lui=rawget(G,"Engine"),rawget(G,"LUI")
if type(H)~="function" or type(HA)~="function" or type(engine)~="table" or type(lui)~="table" then return end
local old=rawget(G,"REX_ARENA_INTRO")
if type(old)=="table" then old.enabled=false end
local U={enabled=true,lines=0}
rawset(G,"REX_ARENA_INTRO",U)
local MAP,POI_KEY,POI="zm_sat_scarab","0xdddf7dca1a52e591","zone_boss_arena_ff"
local W,HGT,VIEW_W,VIEW_H,SHOW=2550,1380,2400,1350,3000
-- {picture, pan start x, y, pan end x, y}: inside the 150x30 margin
local SCENES={
    {"rex_arena_intro_1",0,0,150,30},
    {"rex_arena_intro_2",150,0,0,30},
    {"rex_arena_intro_3",0,30,150,0},
    {"rex_arena_intro_4",150,30,0,0},
}

local function get(object,key)
    if object==nil then return nil end
    local plain,value=pcall(function()return object[key]end)
    if plain and value~=nil then return value end
    local ok,hashed=pcall(function()return object[H(key)]end)
    if ok then return hashed end
    return nil
end
local function call(object,key,...)
    local f=get(object,key)
    if type(f)~="function" then error("missing "..key,0) end
    return f(object,...)
end
local function log(message)
    if U.lines>=24 then return end
    U.lines=U.lines+1
    local print=rawget(G,"DebugPrint")
    if type(print)=="function" then pcall(print,"k1 mod: rex arena: intro: "..tostring(message)) end
end
local function dvar(name)
    local f=get(rawget(G,"Dvar"),"0x254084d7ca2317bb")
    if type(f)~="function" or type(HD)~="function" then return nil end
    local ok,value=pcall(f,HD(name))
    if ok and type(value)=="string" then return value end
end
local function in_frontend()
    local f=get(engine,"InFrontend") or get(engine,"0x112586a3f4fb490e")
    if type(f)~="function" then return nil end
    local ok,value=pcall(f)
    if ok and type(value)=="boolean" then return value end
end
local function arena()
    if in_frontend()~=false then return false end
    local launcher=rawget(G,"LUMEN_ZM_LOCAL_START")
    local request=type(launcher)=="table" and rawget(launcher,"request") or nil
    if type(request)=="table" and request.rex_arena==true then return true end
    return dvar(POI_KEY)==POI and (dvar("ui_mapname")==MAP or dvar("mapname")==MAP)
end
local function screen()
    if not U.enabled or not arena() then return nil end
    local instance=get(get(lui,"LoadingScreenManager"),"0x862bc1029dcfe464")
    if type(instance)~="function" then return nil end
    local ok,manager=pcall(instance)
    if not ok or manager==nil then return nil end
    local widget=get(manager,"_loadingScreen")
    local video=get(widget,"0x4bb93bee689a4d0e")
    if widget~=nil and video~=nil then return widget,video end
end
local function clock()
    local f=get(engine,"0x06991337ae950f99")
    if type(f)~="function" then return nil end
    local ok,value=pcall(f)
    if ok and type(value)=="number" then return value end
end
local function clear()
    local image=U.image
    U.image=nil;U.screen=nil;U.scene=nil
    if image~=nil then pcall(call,image,"closeTree") end
end
local function attach(widget,video)
    local new=get(get(lui,"UIImage"),"new")
    local register=rawget(G,"RegisterMaterial")
    if type(new)~="function" or type(register)~="function" then error("image interface unavailable",0) end
    local materials={}
    for i,scene in ipairs(SCENES) do
        local asset=HA(scene[1])
        if asset==nil then error("asset hash unavailable: "..scene[1],0) end
        materials[i]=register(asset)
        if materials[i]==nil then error("picture unavailable: "..scene[1],0) end
    end
    local image=new()
    U.image=image
    call(image,"SetAnchorsAndPosition",0,0,0,0,0,0,0,0)
    pcall(call,image,"SetHandleMouse",false)
    pcall(call,image,"setFocusable",false)
    call(image,"setImage",materials[1],0)
    call(image,"SetAlpha",1,0)
    call(image,"addElementAfter",video)
    U.screen=widget;U.materials=materials;U.scene=nil
    U.start=clock();U.elapsed=0
    log("pictures on the loading screen ("..#SCENES..")")
end
local function render(waited)
    local now=clock()
    if U.start~=nil and now~=nil and now>=U.start then
        U.elapsed=now-U.start
    else
        U.elapsed=U.elapsed+waited
    end
    local t=U.elapsed%(SHOW*#SCENES)
    local index=math.floor(t/SHOW)+1
    local scene=SCENES[index]
    if U.scene~=index then
        call(U.image,"setImage",U.materials[index],0)
        U.scene=index
    end
    local p=(t%SHOW)/SHOW
    local x=scene[2]+(scene[4]-scene[2])*p
    local y=scene[3]+(scene[5]-scene[3])*p
    call(U.image,"SetUMin",x/W,0)
    call(U.image,"SetUMax",(x+VIEW_W)/W,0)
    call(U.image,"SetVMin",y/HGT,0)
    call(U.image,"SetVMax",(y+VIEW_H)/HGT,0)
end
local function tick(waited)
    local widget,video=screen()
    if U.screen~=widget then
        clear()
        if widget~=U.failed then U.failed=nil end
        if widget~=nil and U.failed~=widget then
            local ok,err=pcall(attach,widget,video)
            if not ok then clear();U.failed=widget;log("game movie kept: "..tostring(err)) end
        end
    end
    if U.image~=nil then render(waited) end
    if not U.enabled then clear();return end
    local delay=U.image~=nil and 16 or 100
    local animation=call(U.host,"Wait",delay)
    if animation==nil then error("timer unavailable",0) end
    animation.onComplete=function()
        local ok,err=pcall(tick,delay)
        if not ok then clear();log("stopped, game movie kept: "..tostring(err)) end
    end
end
local root=get(lui,"GetRoot")
local new=get(get(lui,"UIElement"),"new")
if type(root)~="function" or type(new)~="function" then log("UI root unavailable");return end
root=root()
if root==nil then log("UI root unavailable");return end
U.host=new()
pcall(call,U.host,"SetHandleMouse",false)
pcall(call,U.host,"setFocusable",false)
call(root,"addElement",U.host)
local ok,err=pcall(tick,0)
if not ok then clear();log("stopped, game movie kept: "..tostring(err)) end
end)
-- [rex arena intro end]
do
local G=_G
local old=rawget(G,"REX_ARENA_MENU")
if type(old)=="table" and old.installed then return end
local C=rawget(G,"CLUA")
local hash=type(C)=="table" and C.PushXHash or rawget(G,"xhash")
if type(hash)~="function" then return end

local A={version="1.1",installed=false,logged={},publishing=false}
rawset(G,"REX_ARENA_MENU",A)

local function log(message)
    local K=rawget(G,"KRONOS")
    if type(K)=="table" and type(K.log)=="function" and pcall(K.log,"rex arena: "..message) then return end
    local debug_print=rawget(G,"DebugPrint")
    if type(debug_print)=="function" then pcall(debug_print,"rex arena: "..message) end
end
local function once(key,message)
    if A.logged[key]~=message then A.logged[key]=message;log(message) end
end

-- id: our row; source: the launcher record that starts (Rex round-based);
-- menu: the launcher row we sit beside in Survival (Ashes Survival).
-- 0.1.1: the squad row has its own title so the two rows can be told apart.
-- 0.5.98: the name players see (user: "the map should be named to veytharion's gauntlet")
-- 0.7.5: the squad row too (user: "in squads it shouldnt say squads in it")
local ROWS={{id=1000000206,source=1000000006,menu=1000000008,title="Veytharion's Gauntlet"},
    {id=1000000207,source=1000000007,menu=1000000009,title="Veytharion's Gauntlet"}}
local SOURCE={}
local ROW_OF={}
for _,spec in ipairs(ROWS) do SOURCE[spec.id]=spec.source;ROW_OF[spec.source]=spec.id end
local OWNER="rex_arena_mod"
local TITLE="Veytharion's Gauntlet"
local DESC="Survive in Rex Infernus' copy of the Ashes boss arena."
-- The retail menu prefers the play-menu card's title over row.name. A private
-- ref lets us supply a titled view of the source card only for our own rows.
local CARD_PREFIX="rex_arena_mod_card_"
A.card_sources={}
A.card_titles={}
local MAP="zm_sat_scarab"
local POI_KEY,POI="0xdddf7dca1a52e591","zone_boss_arena_ff"
local BASE="frontEnd.playlists.category"
-- The launcher's playlist row fields (its data.fields).
local FIELDS={"name","desc","mapName","subCategoryName","image","index","minPlayerSize","maxPlayerSize",
    "minPartySize","maxPartySize","timeLimit","scoreLimit","numRounds","isNew","isFeatured","gamemodekey",
    "xpScale","weaponXpScale","battlePassXpScale","isLimitedTime","ID","playMenuRef","tags","missionName",
    "startTime","endTime","isTimerHidden","isOneParty","isRestrictF2P","isCasualQuickplay",
    "isZMSurvivalPlaylist","ZMCursedTierMin","ZMCursedTierMax","isOpen","isPersistentLobby","isExternal",
    "attestationPolicy"}

local function slot(t,s)
    if type(t)~="table" then return end
    local v=rawget(t,s);if v~=nil then return v,s end
    local k=hash(s);v=rawget(t,k);if v~=nil then return v,k end
end
local function member(t,s)
    local v=slot(t,s);if v~=nil then return v end
    if type(t)~="table" and type(t)~="userdata" then return end
    local ok;ok,v=pcall(function() return t[s] end)
    if ok and v~=nil then return v end
    ok,v=pcall(function() return t[hash(s)] end);if ok then return v end
end
local function path(t,...)
    for i=1,select("#",...) do t=member(t,select(i,...));if t==nil then return end end
    return t
end
local function pack(...) return {n=select("#",...),...} end
local function copy(t)
    local out={};for k,v in pairs(t) do out[k]=v end;return out
end
local function put(t,name,value)
    local _,key=slot(t,name)
    rawset(t,key or hash(name),value)
end
local function pair(c,p) return tostring(c)..":"..tostring(p) end
local function hook(owner,name,make)
    local original,key=slot(owner,name)
    if type(original)~="function" then error("missing original hook: "..name) end
    local replacement=make(original)
    rawset(owner,key,replacement)
    if rawget(owner,key)~=replacement then error("original table rejected hook: "..name) end
end
local function mine(entry) return type(entry)=="table" and entry.category_ref==OWNER end

-- A copy of the Rex round-based record with one added setting, the arena
-- marker (Rex's record has no POI setting). Same form as the launcher's own
-- POI entries; the launcher's record and its configuration are not changed.
local function arena_record(record)
    if type(record)~="table" or record.map~=MAP or record.asset~="sat_zm_rb"
        or type(record.configuration)~="table" then
        error("unexpected Rex round-based record")
    end
    local result=copy(record);local configuration={}
    for i,entry in ipairs(record.configuration) do
        if type(entry)=="table" and entry.key==POI_KEY then error("Rex record already has a POI setting") end
        configuration[i]=entry
    end
    configuration[#configuration+1]={key=POI_KEY,console_key="#x3dddf7dca1a52e591",value=POI,
        kind="string",consumer_default="null",required=true}
    result.configuration=configuration;result.poi=POI;result.rex_arena=true
    return result
end
A.arena_record=arena_record

-- The launcher normally sets ui_mapname through a command for solo and its
-- own native party_map step for shared starts. Reuse the latter for our Rex
-- solo request; keep every other step, delay, and the launcher's readback.
local function rex_route_steps(request)
    if type(request.steps)~="table" then error("launcher steps unavailable") end
    local steps=copy(request.steps)
    local found,method=0,nil
    for i,step in ipairs(request.steps) do
        if type(step)=="table" and step.command=="ui_mapname "..MAP then
            local replacement=copy(step)
            replacement.command=nil;replacement.kind="party_map"
            steps[i]=replacement;found=found+1;method="native setter"
        elseif type(step)=="table" and step.kind=="party_map" then
            found=found+1;method="existing native setter"
        end
    end
    if found~=1 then error("expected exactly one launcher map step, got "..found) end
    return steps,method
end
A.rex_route_steps=rex_route_steps

-- 0.4.39 loading screen (user: "ashes name should reflect in loading screen"):
-- the loading screen's header ("ASHES OF THE DAMNED | SURVIVAL | ROUND") and
-- big title both show load-screen field 0xb219b52e7aac6991, which the ingame
-- load-screen data (LoadingScreensDataSources) fills from MapInfo
-- 0x615ea1db2da9249a(). Outside the frontend, during an Ashes Arena match, that
-- call returns "Ashes Arena". The match is recognised as Blackwater Lake's
-- intro did: the launcher's start request when present (ours is marked
-- ashes_arena), otherwise the POI setting dvar 0xdddf7dca1a52e591 reading
-- zone_boss_arena on zm_sat_firefly.
local function dvar_text(name)
    local get=slot(rawget(G,"Dvar"),"0x254084d7ca2317bb")
    local push=type(C)=="table" and C.PushXHashDvar
    if type(get)~="function" or type(push)~="function" then return nil end
    local ok,value=pcall(function() return get(push(name)) end)
    if ok and type(value)=="string" then return value end
end
local function in_frontend()
    local engine=rawget(G,"Engine")
    local f=slot(engine,"InFrontend")
    if type(f)~="function" then return nil end
    local ok,value=pcall(f)
    if ok and type(value)=="boolean" then return value end
end
local function arena_match()
    if in_frontend()~=false then return false,"frontend" end
    local launcher=rawget(G,"LUMEN_ZM_LOCAL_START")
    local request=type(launcher)=="table" and rawget(launcher,"request") or nil
    if type(request)=="table" and request.rex_arena==true then return true,"request" end
    if dvar_text(POI_KEY)==POI and (dvar_text("ui_mapname")==MAP or dvar_text("mapname")==MAP) then
        return true,"poi"
    end
    return false,"other"
end
A.arena_match=arena_match
local function hook_loading_name()
    if A.loading_hooked then return true end
    local mapinfo=rawget(G,"MapInfo")
    local original,key=slot(mapinfo,"0x615ea1db2da9249a")
    if type(original)~="function" then return false end
    local replacement=function(...)
        local result=pack(original(...))
        local yes,why=arena_match()
        if yes and type(result[1])=="string" and result[1]~="" then
            once("loadname","loading screen map name "..TITLE.." ("..why..", was "..result[1]..")")
            result[1]=TITLE
        end
        return unpack(result,1,result.n)
    end
    rawset(mapinfo,key,replacement)
    A.loading_hooked=rawget(mapinfo,key)==replacement
    once("loadhook",A.loading_hooked and "loading screen name hook on" or "loading screen name hook rejected")
    return A.loading_hooked
end
A.hook_loading_name=hook_loading_name
pcall(hook_loading_name)

-- 0.4.41 (user: the top-left line still read "ASHES OF THE DAMNED | SURVIVAL |
-- ROUND" with 0.4.40; its log showed GameType 0x93281f321991cace is the mode
-- icon, sat_ui_icon_gamemode_zm_survival, so that wrap was removed): MapInfo
-- 0x5c034961620dbc3c(mapname, ...) is the game's Lua map-name lookup (global
-- zone; MapInfo 0x615ea1db2da9249a calls it, and the infil, scoreboard and
-- other widgets call it directly). During an Ashes Arena match it returns
-- "Ashes Arena" for zm_sat_firefly. Each new caller's map is logged once.
local function hook_map_lookup()
    if A.map_lookup_hooked then return true end
    local mapinfo=rawget(G,"MapInfo")
    local original,key=slot(mapinfo,"0x5c034961620dbc3c")
    if type(original)~="function" then return false end
    local replacement=function(map,...)
        local result=pack(original(map,...))
        if map==MAP and type(result[1])=="string" and result[1]~="" then
            local yes,why=arena_match()
            if yes then
                once("lookup","map name lookup "..TITLE.." ("..why..", was "..result[1]..")")
                result[1]=TITLE
            end
        end
        return unpack(result,1,result.n)
    end
    rawset(mapinfo,key,replacement)
    A.map_lookup_hooked=rawget(mapinfo,key)==replacement
    once("lookuphook",A.map_lookup_hooked and "map name lookup hook on" or "map name lookup hook rejected")
    return A.map_lookup_hooked
end
A.hook_map_lookup=hook_map_lookup
pcall(hook_map_lookup)
-- [rex arena loading mode begin]
-- 0.7.10: the loading screen's mode name (user: "oh yeah in the loading screen
-- it still says round based zombies"). The arena match is Rex round-based
-- (sat_zm_rb); 0.7.5 relabelled it Survival in the lobby only. In the match,
-- the loading screen's mode line and other in-match headers read the current
-- game type's name from GameType 0x615ea1db2da9249a() and its icon from
-- GameType 0x93281f321991cace() (global luafile_763c89d76e5625: name =
-- 0xc0f22a67428316fc(bundle), icon = 0xda3d20f1e41bc8ac(bundle) of the current
-- bundle). During the arena match (arena_match, as the loading-screen map name)
-- they answer for Survival: the same two lookups of Game 0x88546101f87a8455
-- (sat_zm_rb_survival), the bundle 0.7.5 shows in the lobby. Labels only; if
-- Survival's name or icon can't be had, the game's stays.
local function hook_loading_mode()
    if A.loading_mode_hooked then return true end
    local game_type,game=rawget(G,"GameType"),rawget(G,"Game")
    local name_now,name_key=slot(game_type,"0x615ea1db2da9249a")
    local icon_now,icon_key=slot(game_type,"0x93281f321991cace")
    local bundle_of=slot(game,"0x88546101f87a8455")
    local name_of=slot(game_type,"0xc0f22a67428316fc")
    local icon_of=slot(game_type,"0xda3d20f1e41bc8ac")
    if type(name_now)~="function" or type(bundle_of)~="function" or type(name_of)~="function" then return false end
    local function survival(what,lookup)
        local push=type(C)=="table" and C.PushXHashAsset
        if type(push)~="function" or type(lookup)~="function" then
            once("loadmode"..what,"loading screen mode "..what.." stays the game's: lookup unavailable")
            return nil
        end
        local ok,value=pcall(function() return lookup(bundle_of(push("sat_zm_rb_survival"))) end)
        if ok and value~=nil and value~="" then return value end
        once("loadmode"..what,"loading screen mode "..what.." stays the game's: "..tostring(value))
    end
    local name=function(...)
        local result=pack(name_now(...))
        local yes,why=arena_match()
        if yes and type(result[1])=="string" and result[1]~="" then
            local text=survival("name",name_of)
            if type(text)=="string" then
                once("loadmodename","loading screen mode "..text.." ("..why..", was "..result[1]..")")
                result[1]=text
            end
        end
        return unpack(result,1,result.n)
    end
    rawset(game_type,name_key,name)
    A.loading_mode_hooked=rawget(game_type,name_key)==name
    if A.loading_mode_hooked and type(icon_now)=="function" then
        local icon=function(...)
            local result=pack(icon_now(...))
            local yes,why=arena_match()
            if yes and result[1]~=nil and result[1]~="" then
                local picture=survival("icon",icon_of)
                if picture~=nil then
                    once("loadmodeicon","loading screen mode icon "..tostring(picture).." ("..why..", was "..tostring(result[1])..")")
                    result[1]=picture
                end
            end
            return unpack(result,1,result.n)
        end
        rawset(game_type,icon_key,icon)
    end
    once("loadmodehook",A.loading_mode_hooked and "loading screen mode hook on" or "loading screen mode hook rejected")
    return A.loading_mode_hooked
end
A.hook_loading_mode=hook_loading_mode
pcall(hook_loading_mode)
if not A.loading_mode_hooked then
    local K=rawget(G,"KRONOS")
    if type(K)=="table" and type(K.onRequire)=="function" then
        K.onRequire(function() if not A.loading_mode_hooked then pcall(hook_loading_mode) end end)
    end
end
-- [rex arena loading mode end]

local function install()
    if A.installed then return true end
    if rawget(G,"REX_ARENA_MENU")~=A then return false end
    local state=rawget(G,"LUMEN_ZM_LOCAL_START")
    local catalogue=type(state)=="table" and rawget(state,"catalogue")
    if type(catalogue)~="table" or type(catalogue.by_id)~="table" or type(catalogue.by_pair)~="table"
        or type(catalogue.publish)~="function" then
        return false
    end
    local engine,lobby,playlist=rawget(G,"Engine"),rawget(G,"Lobby"),rawget(G,"Playlist")
    local play_menu=rawget(G,"PLAY_MENU")
    local constructor=member(member(rawget(G,"LUI"),"DataSourceInGlobalModel"),"new")
    local frontend=slot(engine,"InFrontend")
    local party_id=member(member(lobby,"PartyUIData"),"PLAYLIST_ID")
    local required={{lobby,"0x10ee58fa8f81e28a"},{playlist,"DoPlaylistId"},{playlist,"0x2d93afc74cfe7ce0"},
        {lobby,"0xbe6e03a0292da533"},{play_menu,"0x15b97d8cf426b333"},
        {play_menu,"0x9ae1e225e2dd2df4"},{play_menu,"0x2792b7f52ad7cc62"}}
    for _,item in ipairs(required) do
        if type((slot(item[1],item[2])))~="function" then
            once("install","not installed: "..item[2].." is unavailable");return false
        end
    end
    if type(constructor)~="function" or type(frontend)~="function" or party_id==nil then
        once("install","not installed: model, frontend or party ID is unavailable");return false
    end

    local function read(p)
        local ds=constructor(p);local get=member(ds,"GetValue")
        if type(get)~="function" then error("global model reader unavailable") end
        return get(ds,0)
    end
    local function write(p,value)
        if value==nil then return end
        local ds=constructor(p);local set=member(ds,"SetValue")
        if type(set)~="function" then error("global model writer unavailable") end
        set(ds,0,value)
    end

    local function publish(base)
        if base~=BASE or A.publishing or frontend()~=true then return end
        A.publishing=true
        local ok,why=pcall(function()
            local by_id,by_pair=catalogue.by_id,catalogue.by_pair
            for _,spec in ipairs(ROWS) do
                local source=by_id[spec.menu]
                local start=by_id[spec.source]
                local current=by_id[spec.id]
                if type(source)~="table" or mine(source) or type(source.row)~="table"
                    or type(source.metadata)~="table" or type(start)~="table" or mine(start)
                    or type(start.row)~="table" then
                    if mine(current) then
                        by_id[spec.id]=nil
                        local key=pair(current.category,current.playlist_index)
                        if by_pair[key]==current then by_pair[key]=nil end
                    end
                    once("row"..spec.id,"row "..spec.id.." waiting for the launcher's "..spec.menu.." and "..spec.source)
                elseif current~=nil and not mine(current) then
                    once("row"..spec.id,"row "..spec.id.." is taken by another entry; not added")
                else
                    local prefix=source.prefix
                    local n=read(prefix..".count")
                    if type(n)~="number" or n<0 or n>512 or n%1~=0 then error("invalid row count at "..tostring(prefix)) end
                    local at
                    for p=0,n-1 do
                        if read(prefix..".ID."..p)==spec.id then
                            if at~=nil then error("duplicate row "..spec.id) end
                            at=p
                        end
                    end
                    local card_ref=CARD_PREFIX..spec.id
                    local source_ref=start.row.playMenuRef
                    if source_ref==nil or source_ref==card_ref then error("source card unavailable") end
                    A.card_sources[card_ref]=source_ref;A.card_titles[card_ref]=spec.title
                    local fresh=at~=nil and current~=nil and current.prefix==prefix and current.playlist_index==at
                        and current.template_id==source.template_id and current.category==source.category
                        and read(prefix..".name."..at)==spec.title and read(prefix..".playMenuRef."..at)==card_ref
                    if not fresh then
                        local position=at or n
                        local row={}
                        for _,field in ipairs(FIELDS) do row[field]=source.row[field] end
                        row.ID=spec.id;row.index=position;row.name=spec.title;row.desc=DESC;row.playMenuRef=card_ref
                        row.mapName=start.row.mapName or MAP;row.image=start.row.image or source.row.image
                        local metadata=copy(source.metadata)
                        put(metadata,"ID",spec.id);put(metadata,"name",spec.title);put(metadata,"desc",DESC)
                        put(metadata,"playMenuRef",card_ref)
                        for _,field in ipairs(FIELDS) do
                            if field~="ID" then write(prefix.."."..field.."."..position,row[field]) end
                        end
                        write(prefix..".lumenLocalOwner."..position,OWNER)
                        write(prefix..".ID."..position,spec.id)
                        if position>=n then write(prefix..".count",position+1) end
                        if mine(current) then
                            local key=pair(current.category,current.playlist_index)
                            if by_pair[key]==current then by_pair[key]=nil end
                        end
                        local entry={id=spec.id,source_id=spec.source,menu_id=spec.menu,template_id=source.template_id,
                            category=source.category,playlist_index=position,template_index=source.template_index,
                            source_category=source.source_category,prefix=prefix,row=row,metadata=metadata,
                            maps=start.maps or source.maps,category_ref=OWNER}
                        by_id[spec.id]=entry
                        by_pair[pair(source.category,position)]=entry
                        if type(catalogue.unavailable_pairs)=="table" then
                            catalogue.unavailable_pairs[pair(source.category,position)]=nil
                        end
                        once("row"..spec.id,"row "..spec.id.." written at "..tostring(prefix).." #"..position
                            .." beside "..spec.menu.." starting "..spec.source.." (template "..tostring(source.template_id)..")")
                    end
                end
            end
        end)
        A.publishing=false
        if not ok then once("publish","publish failed: "..tostring(why)) else A.logged.publish=nil end
    end
    A.publish=publish

    -- The launcher's map queries read data.records[row.id], which holds only
    -- its own IDs. During those calls our entry is shown with the source ID.
    -- Rex is round-based although its visible row uses an Ashes Survival template.
    -- The launcher's source record has no mode_override; project it on our
    -- returned rows without changing the launcher record or the native result.
    local function rex_map_mode(value)
        if type(value)~="table" then return value end
        local push=type(C)=="table" and C.PushXHashAsset
        if type(push)~="function" then error("Rex map mode asset hash unavailable") end
        local asset=push("sat_zm_rb")
        if asset==nil then error("Rex map mode asset hash unavailable") end
        local result=copy(value)
        for i,row in ipairs(value) do
            if type(row)=="table" then
                result[i]=copy(row)
                put(result[i],"gametypeAssetName",asset)
            end
        end
        return result
    end
    local function shielded_pair(original)
        return function(category,index,...)
            local by_pair=catalogue.by_pair;local key=pair(category,index);local entry=by_pair[key]
            if not mine(entry) then return original(category,index,...) end
            local proxy=copy(entry);proxy.id=entry.source_id;by_pair[key]=proxy
            local result=pack(pcall(original,category,index,...))
            if catalogue.by_pair[key]==proxy then catalogue.by_pair[key]=entry end
            if not result[1] then error(result[2],0) end
            result[2]=rex_map_mode(result[2])
            return unpack(result,2,result.n)
        end
    end
    local function shielded_id(original,project_mode)
        return function(id,...)
            local by_id=catalogue.by_id;local entry=by_id[id]
            if not mine(entry) then return original(id,...) end
            local proxy=copy(entry);proxy.id=entry.source_id;by_id[id]=proxy
            local result=pack(pcall(original,id,...))
            if catalogue.by_id[id]==proxy then catalogue.by_id[id]=entry end
            if not result[1] then error(result[2],0) end
            if project_mode then result[2]=rex_map_mode(result[2]) end
            return unpack(result,2,result.n)
        end
    end

    local function select_playlist(controller,id)
        local ds=path(rawget(G,"_DataSources"),"0xf71428806887f67d","0x1ccae3b6ef72f533","0xe14ec899fcdc838f")
        local set=member(ds,"SetValue")
        if type(set)~="function" then error("playlist selection source unavailable") end
        local party_set=slot(lobby,"0xbe6e03a0292da533")
        party_set(party_id,id)
        set(ds,controller,id)
    end

    -- Use the original Ashwood card for artwork and other data. The proxy
    -- retains its fields but is identifiable by the two text accessors.
    hook(play_menu,"0x15b97d8cf426b333",function(original)
        return function(ref,...)
            local source_ref=A.card_sources[ref]
            if source_ref==nil then return original(ref,...) end
            local card=original(source_ref,...)
            if type(card)~="table" and type(card)~="userdata" then return card end
            -- 0.1.1: a Rex-only marker. 0.1.0 used Ashes Arena's aa_arena_card, so
            -- this title hook also renamed the Ashes Arena rows to "Rex Arena".
            return setmetatable({rex_arena_card=true,rex_arena_title=A.card_titles[ref]},
                {__index=function(_,key) return card[key] end})
        end
    end)
    hook(play_menu,"0x9ae1e225e2dd2df4",function(original)
        return function(card,...)
            if type(card)=="table" and rawget(card,"rex_arena_card")==true then return rawget(card,"rex_arena_title") or TITLE end
            return original(card,...)
        end
    end)
    hook(play_menu,"0x2792b7f52ad7cc62",function(original)
        return function(card,...)
            if type(card)=="table" and rawget(card,"rex_arena_card")==true then return DESC end
            return original(card,...)
        end
    end)

    hook(playlist,"DoPlaylistId",function(original)
        return function(id,...)
            local source=SOURCE[id]
            if not source or not mine(catalogue.by_id[id]) then return original(id,...) end
            local controller=state.scope or state.controller or 0
            local ok,why=pcall(select_playlist,controller,source)
            if not ok then once("start","start not redirected: "..tostring(why));return end
            local before=state.request
            local result=pack(original(source,...))
            local request=state.request
            if type(request)=="table" and request~=before and request.id==source then
                local changed,record=pcall(arena_record,request.record)
                if changed then
                    local routed,steps,method=pcall(rex_route_steps,request)
                    if routed then
                        request.steps=steps;request.record=record;request.rex_arena=true
                        log("start "..id.." -> Rex round-based "..source.." with arena marker "..POI
                            .."; map step "..method)
                    else log("start "..id.." left as plain Rex round-based: "..tostring(steps)) end
                else log("start "..id.." left as plain Rex round-based: "..tostring(record)) end
            else
                pcall(select_playlist,controller,id)
                log("start "..id.." was not scheduled by the launcher")
            end
            return unpack(result,1,result.n)
        end
    end)
    -- The Ashes Arena start the launcher is running, if any.
    local function arena_row()
        local request=state.request
        if type(request)=="table" and request.rex_arena==true then return ROW_OF[request.id],request.id,request end
    end
    -- The lobby's game type, as the mode line reads it.
    local function lobby_gametype(controller)
        local conditions=rawget(G,"CONDITIONS")
        local online=slot(conditions,"0x112586a3f4fb490e")
        if type(online)=="function" then
            local ok,yes=pcall(online)
            if ok and yes then
                local ds=path(rawget(G,"DataSources"),"frontEnd","lobby","gameType")
                local get=member(ds,"GetValue")
                if type(get)=="function" then
                    local got,value=pcall(get,ds,controller)
                    if got then return value,"lobby" end
                end
            end
        end
        local current=slot(lobby,"0xcfc38819ea2193ba")
        if type(current)=="function" then
            local got,value=pcall(current)
            if got then return value,"current" end
        end
        return nil,"none"
    end
    -- Asset-hash digits of the Survival game types (as tostring shows them).
    -- Rex Arena: the start record is Rex round-based, sat_zm_rb (0x75505f81616168a7).
local ASSET_DIGITS={sat_zm_rb="75505f81616168a7"}
    local function survival_type(value,request)
        local record=request.record
        local asset=type(record)=="table" and record.asset
        if value==nil or type(asset)~="string" then return false end
        if value==asset or tostring(value)==asset then return true end
        local text=string.lower(tostring(value))
        local digits=ASSET_DIGITS[asset]
        if digits and string.sub(text,-#digits)==digits then return true end
        local push=type(C)=="table" and C.PushXHashAsset
        if type(push)=="function" then
            local ok,h=pcall(push,asset)
            if ok and h~=nil and (value==h or tostring(h)==tostring(value)) then return true end
        end
        return false
    end
    A.lobby_lines=0
    if type((slot(play_menu,"0x38eb2c388629179b")))=="function" then
        hook(play_menu,"0x38eb2c388629179b",function(original)
            return function(controller,...)
                local row,source,request=arena_row()
                if row and survival_type(lobby_gametype(controller),request) then
                    local get=slot(play_menu,"0x15b97d8cf426b333")
                    local card=type(get)=="function" and get(CARD_PREFIX..row)
                    if card~=nil then
                        once("lobbycard","lobby card titled "..TITLE.." for start "..tostring(source))
                        return card
                    end
                    once("lobbycard","lobby card for start "..tostring(source).." unavailable")
                else A.logged.lobbycard=nil end
                return original(controller,...)
            end
        end)
    else
        once("lobbyhook","lobby card query unavailable; the about-to-begin name stays the game's")
    end
    -- The lobby's map name during an Ashes Arena start.
    local mp=rawget(G,"MP")
    if type((slot(mp,"0xa781132808ca573a")))=="function" then
        hook(mp,"0xa781132808ca573a",function(original)
            return function(controller,...)
                local result=pack(original(controller,...))
                local row,source,request=arena_row()
                if not row then return unpack(result,1,result.n) end
                local value,from=lobby_gametype(controller)
                local survival=survival_type(value,request)
                local line="lobby: game type "..tostring(value).." ("..from..") survival "..tostring(survival)
                    .." name "..tostring(result[1]).." ui_mapname "..tostring(dvar_text("ui_mapname"))
                    .." wanted "..tostring(request.record.map).." step "..tostring(request.step)
                if A.logged.lobbystate~=line and A.lobby_lines<40 then
                    A.lobby_lines=A.lobby_lines+1;A.logged.lobbystate=line;log(line)
                end
                if survival and type(result[1])=="string" and result[1]~="" then
                    once("lobbyname","lobby map name "..TITLE.." for start "..tostring(source))
                    result[1]=TITLE
                end
                return unpack(result,1,result.n)
            end
        end)
    else
        once("lobbyname","lobby map name query unavailable")
    end
    -- [rex arena card begin]
    -- 0.7.9: the lobby card's picture (user: "the image card on the bottom should
    -- be swapped for map 9 pic"). The card's name and picture both come from
    -- Lobby 0xd09afe8ce7a0ee8a (frontend luafile_3479061555f4eb43); its callers
    -- show the picture with setImage(RegisterMaterial(picture)) or put it in the
    -- card's image data source. While the arena start runs and the card reads our
    -- name (the name hook above), the picture is the user's map 9 shot, the first
    -- intro picture (images/rex_arena_intro_1.png). If that picture can't be
    -- made, the game's stays.
    local CARD_PICTURE="rex_arena_intro_1"
    local function card_picture()
        if A.card_picture~=nil then return A.card_picture end
        local asset=rawget(G,"xhashasset") or (type(C)=="table" and C.PushXHashAsset)
        local register=rawget(G,"RegisterMaterial")
        if type(asset)~="function" or type(register)~="function" then
            once("lobbypicture","lobby card picture kept: image interface unavailable")
            return nil
        end
        local named,value=pcall(asset,CARD_PICTURE)
        if not named or value==nil then
            once("lobbypicture","lobby card picture kept: "..CARD_PICTURE.." not named: "..tostring(value))
            return nil
        end
        local made,why=pcall(register,value)
        if not made then
            once("lobbypicture","lobby card picture kept: "..CARD_PICTURE.." unavailable: "..tostring(why))
            return nil
        end
        A.card_picture=value
        return value
    end
    if type((slot(lobby,"0xd09afe8ce7a0ee8a")))=="function" then
        hook(lobby,"0xd09afe8ce7a0ee8a",function(original)
            return function(...)
                local result=pack(original(...))
                if result[1]==TITLE and arena_row() then
                    local picture=card_picture()
                    if picture~=nil then
                        result[2]=picture
                        if result.n<2 then result.n=2 end
                        once("lobbypicture","lobby card picture "..CARD_PICTURE.." (map 9)")
                    end
                end
                return unpack(result,1,result.n)
            end
        end)
    else
        once("lobbypicture","lobby card picture query unavailable; the game's picture stays")
    end
    -- [rex arena card end]
    hook(playlist,"0x2d93afc74cfe7ce0",shielded_pair)
    for _,key in ipairs({"0x3ea93feae1aa4d9e","0xda449b9851cf679e"}) do
        if type((slot(playlist,key)))=="function" then
            hook(playlist,key,function(original)
                return shielded_id(original,key=="0xda449b9851cf679e")
            end)
        end
    end
    hook(lobby,"0x10ee58fa8f81e28a",function(original)
        return function(base,...)
            local result=pack(original(base,...))
            publish(base)
            return unpack(result,1,result.n)
        end
    end)
    local utils=rawget(G,"PlaylistUtils")
    if type((slot(utils,"0xeda10385e76d30fe")))=="function" then
        hook(utils,"0xeda10385e76d30fe",function(original)
            return function(...)
                local result=pack(original(...))
                publish(BASE)
                return unpack(result,1,result.n)
            end
        end)
    end
    -- 0.6.5: the squad row in Play in a Squad (user: "on screenshot 3 and 4 u
    -- will se squad section"). The game's map list (Lobby 0x0abec982187838da)
    -- shows a squad row only while its isOneParty differs from the party
    -- setting. When that setting changes, the launcher re-makes its own rows
    -- (the Ashwood rows ours copy) from another template just before the list
    -- is built, in its wrap of the same function; ours were only re-made on the
    -- next category refresh, so the list hid them. Here ours are re-made before
    -- the list and, if the launcher's rows beside ours changed while it was
    -- built, re-made again and the list built again.
    local function menu_templates()
        local key=""
        for _,spec in ipairs(ROWS) do
            local source=catalogue.by_id[spec.menu]
            key=key..tostring(type(source)=="table" and source.template_id or "none")..";"
        end
        return key
    end
    if type((slot(lobby,"0x0abec982187838da")))=="function" then
        hook(lobby,"0x0abec982187838da",function(original)
            return function(...)
                local args=pack(...)
                publish(BASE)
                local before=menu_templates()
                local result=pack(original(unpack(args,1,args.n)))
                local after=menu_templates()
                if after~=before then
                    publish(BASE)
                    once("squadlist","map list built again: the launcher's rows changed template ("..before.." -> "..after..")")
                    result=pack(original(unpack(args,1,args.n)))
                end
                return unpack(result,1,result.n)
            end
        end)
    else
        once("squadlist","map list query unavailable; the squad row follows the launcher on category refresh only")
    end
    -- [rex arena mode begin]
    -- 0.7.5: the mode name (user: "and it still says round based"). The lobby's
    -- mode line (Lobby 0x97043e05e1a83595) and the screens' headers name the
    -- game type with GameType 0x5c034961620dbc3c (icon 0x8d19ab25b06cfdec, third
    -- 0xb306c7a7fa2e9fd8). During an arena start, asked about Rex round-based
    -- (the start record's asset), they answer for Survival (sat_zm_rb_survival).
    -- Labels only: the start and its record are unchanged.
    local game_type=rawget(G,"GameType")
    local SURVIVAL_ASSET="sat_zm_rb_survival"
    for _,key in ipairs({"0x5c034961620dbc3c","0x8d19ab25b06cfdec","0xb306c7a7fa2e9fd8"}) do
        if type((slot(game_type,key)))=="function" then
            local hooked,why=pcall(hook,game_type,key,function(original)
                return function(value,...)
                    local row,source,request=arena_row()
                    if row and survival_type(value,request) then
                        local push=type(C)=="table" and C.PushXHashAsset
                        local got,asset=false,nil
                        if type(push)=="function" then got,asset=pcall(push,SURVIVAL_ASSET) end
                        if got and asset~=nil then
                            once("mode"..key,"mode "..key.." as Survival for start "..tostring(source))
                            return original(asset,...)
                        end
                        once("mode"..key,"Survival asset hash unavailable; mode "..key.." stays the game's")
                    end
                    return original(value,...)
                end
            end)
            if not hooked then once("mode"..key,"mode hook "..key.." failed: "..tostring(why)) end
        else
            once("mode"..key,"mode query "..key.." unavailable")
        end
    end
    -- [rex arena mode end]
    A.installed=true
    log(A.version.." installed on launcher "..tostring(rawget(state,"version")))
    publish(BASE)
    return true
end

local function try_install()
    local ok,result=pcall(install)
    if not ok then once("install","install failed: "..tostring(result));return false end
    return result
end
A.try_install=try_install

if not A.loading_hooked or not A.map_lookup_hooked then
    local K=rawget(G,"KRONOS")
    if type(K)=="table" and type(K.onRequire)=="function" then
        K.onRequire(function()
            if not A.loading_hooked then pcall(hook_loading_name) end
            if not A.map_lookup_hooked then pcall(hook_map_lookup) end
        end)
    end
end
if not try_install() then
    local K=rawget(G,"KRONOS")
    if type(K)=="table" and type(K.onRequire)=="function" then
        K.onRequire(function() if not A.installed then try_install() end end)
    end
    once("wait","waiting for the Kronos launcher")
end
end
