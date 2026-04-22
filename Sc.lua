-- ╔══════════════════════════════════════════════╗
-- ║         pev | STK  v5.0  — Master Loop       ║
-- ║   Sistem mandor: 1 controller, no conflict   ║
-- ╚══════════════════════════════════════════════╝

if _G.PevGui then _G.PevGui:Destroy() end
if _G.PevMasterRunning then _G.PevMasterRunning = false end
task.wait(0.1)

local player = game.Players.LocalPlayer
local char   = player.Character or player.CharacterAdded:Wait()
local hrp    = char:WaitForChild("HumanoidRootPart")
local hum    = char:WaitForChild("Humanoid")

-- ══════════════════════════════════════════════
--  GLOBAL FLAGS
-- ══════════════════════════════════════════════
local function gdef(k,v) if _G[k]==nil then _G[k]=v end end
gdef("FarmOn",       false)
gdef("EscapeOn",     false)
gdef("ReviveOn",     false)
gdef("SelfReviveOn", false)
gdef("KillOn",       false)
gdef("KillerSafeOn", false)
gdef("SpeedOn",      false)
gdef("JumpOn",       false)
gdef("DJOn",         false)
gdef("SpeedVal",     32)
gdef("JumpVal",      100)
gdef("WebhookURL",   "")
gdef("WhEv_Loot",    false)
gdef("WhEv_Batch",   false)

-- ══════════════════════════════════════════════
--  CONFIG SAVE / LOAD
-- ══════════════════════════════════════════════
local CFG = "pev_stk_v5.json"
local HS  = game:GetService("HttpService")

local function saveConfig()
    pcall(function()
        writefile(CFG, HS:JSONEncode({
            FarmOn=_G.FarmOn, EscapeOn=_G.EscapeOn,
            ReviveOn=_G.ReviveOn, SelfReviveOn=_G.SelfReviveOn,
            KillOn=_G.KillOn, KillerSafeOn=_G.KillerSafeOn,
            SpeedOn=_G.SpeedOn, JumpOn=_G.JumpOn, DJOn=_G.DJOn,
            SpeedVal=_G.SpeedVal, JumpVal=_G.JumpVal,
            WebhookURL=_G.WebhookURL,
            WhEv_Loot=_G.WhEv_Loot, WhEv_Batch=_G.WhEv_Batch,
        }))
    end)
end

local function loadConfig()
    pcall(function()
        if not isfile(CFG) then return end
        local d=HS:JSONDecode(readfile(CFG))
        local keys={"FarmOn","EscapeOn","ReviveOn","SelfReviveOn","KillOn",
                     "KillerSafeOn","SpeedOn","JumpOn","DJOn","SpeedVal",
                     "JumpVal","WebhookURL","WhEv_Loot","WhEv_Batch"}
        for _,k in ipairs(keys) do if d[k]~=nil then _G[k]=d[k] end end
    end)
end
loadConfig()

-- ══════════════════════════════════════════════
--  FORWARD DECLARATIONS
-- ══════════════════════════════════════════════
local setStatus   = function() end
local updateStats = function() end

-- ══════════════════════════════════════════════
--  GUI COLORS
-- ══════════════════════════════════════════════
local C = {
    bg     = Color3.fromRGB(10,10,14),
    panel  = Color3.fromRGB(18,18,26),
    card   = Color3.fromRGB(26,26,36),
    card2  = Color3.fromRGB(32,32,44),
    accent = Color3.fromRGB(120,86,255),
    accLt  = Color3.fromRGB(160,130,255),
    accDim = Color3.fromRGB(40,30,80),
    green  = Color3.fromRGB(80,220,140),
    red    = Color3.fromRGB(220,70,90),
    yellow = Color3.fromRGB(255,200,60),
    cyan   = Color3.fromRGB(80,200,230),
    text   = Color3.fromRGB(230,230,240),
    sub    = Color3.fromRGB(120,120,140),
    muted  = Color3.fromRGB(50,50,65),
    border = Color3.fromRGB(40,40,58),
}

-- ══════════════════════════════════════════════
--  GUI HELPERS
-- ══════════════════════════════════════════════
local function corner(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 8) end
local function stroke(p,col,th)
    local s=Instance.new("UIStroke",p)
    s.Color=col or C.border s.Thickness=th or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
end
local function lbl(par,txt,sz,col,bold,xa)
    local l=Instance.new("TextLabel")
    l.Parent=par l.BackgroundTransparency=1 l.Text=txt
    l.TextSize=sz or 12 l.TextColor3=col or C.text
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextXAlignment=xa or Enum.TextXAlignment.Center
    return l
end
local function onTap(btn,fn)
    btn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or
           i.UserInputType==Enum.UserInputType.MouseButton1 then fn() end
    end)
end
local function drag(frame,handle)
    local dragging,dragInput,dragStart,startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch then
            dragging=true dragStart=i.Position startPos=frame.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch then dragInput=i end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(i)
        if i==dragInput and dragging then
            local d=i.Position-dragStart
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

local function makeToggle(par,xOff,activeCol)
    local TW,TH,KS=46,26,20
    local track=Instance.new("TextButton",par)
    track.Size=UDim2.new(0,TW,0,TH)
    track.Position=UDim2.new(1,xOff or -(TW+10),0.5,-TH/2)
    track.BackgroundColor3=C.muted track.Text="" track.BorderSizePixel=0
    corner(track,99)
    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,KS,0,KS)
    knob.Position=UDim2.new(0,3,0.5,-KS/2)
    knob.BackgroundColor3=C.text knob.BorderSizePixel=0
    corner(knob,99)
    local state=false
    local function setState(v)
        state=v
        track.BackgroundColor3=v and (activeCol or C.green) or C.muted
        knob.Position=v and UDim2.new(1,-(KS+3),0.5,-KS/2) or UDim2.new(0,3,0.5,-KS/2)
    end
    return track,setState,function() return state end
end

-- ══════════════════════════════════════════════
--  MAIN WINDOW
-- ══════════════════════════════════════════════
local sg=Instance.new("ScreenGui")
_G.PevGui=sg
sg.Name="PevSTK" sg.ResetOnSpawn=false sg.IgnoreGuiInset=true
sg.Parent=player.PlayerGui

local win=Instance.new("Frame",sg)
win.Name="PevWin"
win.Size=UDim2.new(0,500,0,480)
win.Position=UDim2.new(0.02,0,0.03,0)
win.BackgroundColor3=C.panel win.BorderSizePixel=0
corner(win,14) stroke(win,C.border,1)

-- titlebar
local tb=Instance.new("Frame",win)
tb.Size=UDim2.new(1,0,0,46) tb.BackgroundColor3=C.bg tb.BorderSizePixel=0 corner(tb,12)
local tbFix=Instance.new("Frame",win)
tbFix.Size=UDim2.new(1,0,0,10) tbFix.Position=UDim2.new(0,0,0,36)
tbFix.BackgroundColor3=C.bg tbFix.BorderSizePixel=0

local brandDot=Instance.new("Frame",tb)
brandDot.Size=UDim2.new(0,8,0,8) brandDot.Position=UDim2.new(0,14,0.5,-4)
brandDot.BackgroundColor3=C.accent brandDot.BorderSizePixel=0 corner(brandDot,99)

local brandL=lbl(tb,"pev | STK",13,C.text,true,Enum.TextXAlignment.Left)
brandL.Size=UDim2.new(0,120,1,0) brandL.Position=UDim2.new(0,28,0,0)

local badge=Instance.new("Frame",tb)
badge.Size=UDim2.new(0,42,0,18) badge.Position=UDim2.new(0,152,0.5,-9)
badge.BackgroundColor3=C.accDim badge.BorderSizePixel=0 corner(badge,20)
lbl(badge,"v5.0",10,C.accLt,true).Size=UDim2.new(1,0,1,0)

local tbDot=Instance.new("Frame",tb)
tbDot.Size=UDim2.new(0,7,0,7) tbDot.Position=UDim2.new(1,-100,0.5,-3)
tbDot.BackgroundColor3=C.red tbDot.BorderSizePixel=0 corner(tbDot,99)
local tbTxt=lbl(tb,"Idle",10,C.sub,false,Enum.TextXAlignment.Left)
tbTxt.Size=UDim2.new(0,55,1,0) tbTxt.Position=UDim2.new(1,-90,0,0)

local minBtn=Instance.new("TextButton",tb)
minBtn.Size=UDim2.new(0,26,0,26) minBtn.Position=UDim2.new(1,-62,0.5,-13)
minBtn.BackgroundColor3=C.accDim minBtn.Text="—"
minBtn.TextColor3=C.sub minBtn.TextSize=11 minBtn.Font=Enum.Font.GothamBold
minBtn.BorderSizePixel=0 corner(minBtn,6) stroke(minBtn,C.border,1)

local closeBtn=Instance.new("TextButton",tb)
closeBtn.Size=UDim2.new(0,26,0,26) closeBtn.Position=UDim2.new(1,-32,0.5,-13)
closeBtn.BackgroundColor3=C.accDim closeBtn.Text="✕"
closeBtn.TextColor3=C.sub closeBtn.TextSize=11 closeBtn.Font=Enum.Font.GothamBold
closeBtn.BorderSizePixel=0 corner(closeBtn,6) stroke(closeBtn,C.border,1)

local div=Instance.new("Frame",win)
div.Size=UDim2.new(1,0,0,1) div.Position=UDim2.new(0,0,0,46)
div.BackgroundColor3=C.border div.BorderSizePixel=0

local bubble=Instance.new("TextButton",sg)
bubble.Size=UDim2.new(0,48,0,48) bubble.Position=UDim2.new(0,12,0.5,-24)
bubble.BackgroundColor3=C.accDim bubble.Text="P"
bubble.TextColor3=C.accLt bubble.TextSize=18 bubble.Font=Enum.Font.GothamBold
bubble.BorderSizePixel=0 bubble.Visible=false bubble.ZIndex=10
corner(bubble,99) stroke(bubble,C.accent,2)
drag(bubble,bubble) drag(win,tb)

-- body
local body=Instance.new("Frame",win)
body.Size=UDim2.new(1,0,1,-47) body.Position=UDim2.new(0,0,0,47)
body.BackgroundTransparency=1

-- sidebar
local SBW=110
local sb=Instance.new("Frame",body)
sb.Size=UDim2.new(0,SBW,1,0) sb.BackgroundColor3=C.bg sb.BorderSizePixel=0
local sbDiv=Instance.new("Frame",body)
sbDiv.Size=UDim2.new(0,1,1,0) sbDiv.Position=UDim2.new(0,SBW,0,0)
sbDiv.BackgroundColor3=C.border sbDiv.BorderSizePixel=0

local sbNav=Instance.new("Frame",sb)
sbNav.Size=UDim2.new(1,-12,1,-50) sbNav.Position=UDim2.new(0,6,0,6)
sbNav.BackgroundTransparency=1
local sbLayout=Instance.new("UIListLayout",sbNav)
sbLayout.SortOrder=Enum.SortOrder.LayoutOrder sbLayout.Padding=UDim.new(0,2)

local sbPill=Instance.new("Frame",sb)
sbPill.Size=UDim2.new(1,-12,0,34) sbPill.Position=UDim2.new(0,6,1,-40)
sbPill.BackgroundColor3=C.card sbPill.BorderSizePixel=0
corner(sbPill,8) stroke(sbPill,C.border,1)
local sbDot2=Instance.new("Frame",sbPill)
sbDot2.Size=UDim2.new(0,6,0,6) sbDot2.Position=UDim2.new(0,8,0.5,-3)
sbDot2.BackgroundColor3=C.red sbDot2.BorderSizePixel=0 corner(sbDot2,99)
local sbTxt=lbl(sbPill,"Idle",10,C.sub,false,Enum.TextXAlignment.Left)
sbTxt.Size=UDim2.new(1,-20,1,0) sbTxt.Position=UDim2.new(0,18,0,0)

local content=Instance.new("Frame",body)
content.Size=UDim2.new(1,-(SBW+1),1,0) content.Position=UDim2.new(0,SBW+1,0,0)
content.BackgroundTransparency=1

local phdr=Instance.new("Frame",content)
phdr.Size=UDim2.new(1,-16,0,36) phdr.Position=UDim2.new(0,8,0,4)
phdr.BackgroundTransparency=1
local panelTitle=lbl(phdr,"Main",13,C.text,true,Enum.TextXAlignment.Left)
panelTitle.Size=UDim2.new(1,0,0.5,0)
local panelSub=lbl(phdr,"Auto Farm & core features",10,C.sub,false,Enum.TextXAlignment.Left)
panelSub.Size=UDim2.new(1,0,0.5,0) panelSub.Position=UDim2.new(0,0,0.5,0)

local pdiv=Instance.new("Frame",content)
pdiv.Size=UDim2.new(1,-16,0,1) pdiv.Position=UDim2.new(0,8,0,42)
pdiv.BackgroundColor3=C.border pdiv.BorderSizePixel=0

local scroll=Instance.new("ScrollingFrame",content)
scroll.Size=UDim2.new(1,-8,1,-50) scroll.Position=UDim2.new(0,4,0,48)
scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0
scroll.ScrollBarThickness=2 scroll.ScrollBarImageColor3=C.accent
scroll.CanvasSize=UDim2.new(0,0,0,900)

-- ══════════════════════════════════════════════
--  NAV
-- ══════════════════════════════════════════════
local navItems={}
local TAB_DATA={
    {id="Main",   sym="AF", label="Main"},
    {id="Player", sym="PL", label="Player"},
    {id="Visual", sym="VS", label="Visual"},
    {id="Misc",   sym="MX", label="Misc"},
}
local TAB_INFO={
    Main  ={title="Main",   sub="Auto Farm & core features"},
    Player={title="Player", sub="Speed · Jump · Double Jump"},
    Visual={title="Visual", sub="ESP highlight & world scan"},
    Misc  ={title="Misc",   sub="AFK · Escape · Webhook"},
}
for i,td in ipairs(TAB_DATA) do
    local btn=Instance.new("TextButton",sbNav)
    btn.Size=UDim2.new(1,0,0,36) btn.LayoutOrder=i
    btn.BackgroundTransparency=1 btn.Text="" btn.BorderSizePixel=0 corner(btn,8)
    local bar=Instance.new("Frame",btn)
    bar.Size=UDim2.new(0,3,0.5,0) bar.Position=UDim2.new(0,0,0.25,0)
    bar.BackgroundColor3=C.accent bar.BorderSizePixel=0 corner(bar,3) bar.Visible=false
    local symL=lbl(btn,td.sym,9,C.accent,true)
    symL.Size=UDim2.new(0,22,1,0) symL.Position=UDim2.new(0,8,0,0)
    local labL=lbl(btn,td.label,11,C.sub,true,Enum.TextXAlignment.Left)
    labL.Size=UDim2.new(1,-34,1,0) labL.Position=UDim2.new(0,32,0,0)
    navItems[td.id]={btn=btn,bar=bar,symL=symL,labL=labL}
end

-- ══════════════════════════════════════════════
--  PAGES & ROW FACTORY
-- ══════════════════════════════════════════════
local pages={}
local function makePage()
    local f=Instance.new("Frame",scroll)
    f.Size=UDim2.new(1,0,0,700) f.Position=UDim2.new(10,0,0,0)
    f.BackgroundTransparency=1 return f
end
local function makeRow(par,yOff,sym,symCol,title,sub,soon,togCol)
    local row=Instance.new("Frame",par)
    row.Size=UDim2.new(1,-8,0,54) row.Position=UDim2.new(0,4,0,yOff)
    row.BackgroundColor3=C.card row.BorderSizePixel=0 corner(row,10) stroke(row,C.border,1)
    local ico=Instance.new("Frame",row)
    ico.Size=UDim2.new(0,32,0,32) ico.Position=UDim2.new(0,10,0.5,-16)
    ico.BackgroundColor3=C.accDim ico.BorderSizePixel=0 corner(ico,8)
    lbl(ico,sym,10,symCol or C.accLt,true).Size=UDim2.new(1,0,1,0)
    local tL=lbl(row,title,13,C.text,true,Enum.TextXAlignment.Left)
    tL.Size=UDim2.new(0,160,0,20) tL.Position=UDim2.new(0,50,0,8)
    local sL=lbl(row,sub,10,C.sub,false,Enum.TextXAlignment.Left)
    sL.Size=UDim2.new(0,165,0,15) sL.Position=UDim2.new(0,50,0,28)
    if soon then
        local sf=Instance.new("Frame",row)
        sf.Size=UDim2.new(0,60,0,22) sf.Position=UDim2.new(1,-68,0.5,-11)
        sf.BackgroundColor3=C.accDim sf.BorderSizePixel=0 corner(sf,20)
        lbl(sf,"Soon",10,C.sub,true).Size=UDim2.new(1,0,1,0)
        return row,nil,nil,nil
    end
    local tgl,setState,getState=makeToggle(row,-(40+10),togCol)
    return row,tgl,setState,getState
end

-- ══════════════════════════════════════════════
--  PAGE: MAIN
-- ══════════════════════════════════════════════
pages.Main=makePage()

local sPill=Instance.new("Frame",pages.Main)
sPill.Size=UDim2.new(1,-8,0,32) sPill.Position=UDim2.new(0,4,0,0)
sPill.BackgroundColor3=C.bg sPill.BorderSizePixel=0 corner(sPill,8) stroke(sPill,C.border,1)
local sDot=Instance.new("Frame",sPill)
sDot.Size=UDim2.new(0,8,0,8) sDot.Position=UDim2.new(0,10,0.5,-4)
sDot.BackgroundColor3=C.red sDot.BorderSizePixel=0 corner(sDot,99)
local statusLbl=lbl(sPill,"Idle — menunggu",12,C.sub,false,Enum.TextXAlignment.Left)
statusLbl.Size=UDim2.new(1,-26,1,0) statusLbl.Position=UDim2.new(0,24,0,0)

-- priority indicator — nampilin siapa yang lagi dikerjain mandor
local prioCard=Instance.new("Frame",pages.Main)
prioCard.Size=UDim2.new(1,-8,0,30) prioCard.Position=UDim2.new(0,4,0,36)
prioCard.BackgroundColor3=C.bg prioCard.BorderSizePixel=0 corner(prioCard,8) stroke(prioCard,C.border,1)
local prioDot=Instance.new("Frame",prioCard)
prioDot.Size=UDim2.new(0,6,0,6) prioDot.Position=UDim2.new(0,8,0.5,-3)
prioDot.BackgroundColor3=C.muted prioDot.BorderSizePixel=0 corner(prioDot,99)
local prioLbl=lbl(prioCard,"Mandor: Standby",10,C.sub,false,Enum.TextXAlignment.Left)
prioLbl.Size=UDim2.new(1,-20,1,0) prioLbl.Position=UDim2.new(0,18,0,0)

local statsRow=Instance.new("Frame",pages.Main)
statsRow.Size=UDim2.new(1,-8,0,72) statsRow.Position=UDim2.new(0,4,0,70)
statsRow.BackgroundTransparency=1 statsRow.BorderSizePixel=0

local function statBox(par,xPct,xOff,label,col,initVal)
    local GAP=4
    local f=Instance.new("Frame",par)
    f.Size=UDim2.new(0.333,-GAP,1,0) f.Position=UDim2.new(xPct,xOff+GAP/2,0,0)
    f.BackgroundColor3=C.card f.BorderSizePixel=0 corner(f,10) stroke(f,C.border,1)
    local bar=Instance.new("Frame",f)
    bar.Size=UDim2.new(1,-16,0,2) bar.Position=UDim2.new(0,8,0,0)
    bar.BackgroundColor3=col or C.accent bar.BorderSizePixel=0 corner(bar,2)
    local vl=lbl(f,initVal or "0",16,col or C.accent,true)
    vl.Size=UDim2.new(1,0,0,32) vl.Position=UDim2.new(0,0,0,8)
    local ll=lbl(f,label,9,C.sub,false)
    ll.Size=UDim2.new(1,0,0,18) ll.Position=UDim2.new(0,0,1,-20)
    return vl
end

local s1val=statBox(statsRow,0,0,"Collected",C.accent)
local s2val=statBox(statsRow,0.333,0,"Found",C.green)
local timerBox=Instance.new("Frame",statsRow)
timerBox.Size=UDim2.new(0.333,-4,1,0) timerBox.Position=UDim2.new(0.666,2,0,0)
timerBox.BackgroundColor3=C.card timerBox.BorderSizePixel=0 corner(timerBox,10) stroke(timerBox,C.border,1)
local tbBar=Instance.new("Frame",timerBox)
tbBar.Size=UDim2.new(1,-16,0,2) tbBar.Position=UDim2.new(0,8,0,0)
tbBar.BackgroundColor3=C.cyan tbBar.BorderSizePixel=0 corner(tbBar,2)
local timerVal=lbl(timerBox,"--:--",16,C.cyan,true)
timerVal.Size=UDim2.new(1,0,0,32) timerVal.Position=UDim2.new(0,0,0,8)
lbl(timerBox,"Timer",9,C.sub,false).Size=UDim2.new(1,0,0,18)

-- feature rows (Main)
local _,farmTgl,    setFarmCb,    getFarmCb    =makeRow(pages.Main,148,"AF",C.green, "Auto Farm",   "Kumpulin loot otomatis",      false,C.green)
local _,killerSTgl, setKillerSCb, getKillerSCb =makeRow(pages.Main,206,"KS",C.red,   "Killer Safe", "Hindari killer saat farm",    false,C.red)
local _,escapeTgl,  setEscapeCb,  getEscapeCb  =makeRow(pages.Main,264,"AE",C.cyan,  "Auto Escape", "Teleport ke exit saat waktunya",false,C.cyan)
local _,reviveTgl,  setReviveCb,  getReviveCb  =makeRow(pages.Main,322,"RV",C.yellow,"Auto Revive", "Revive teman knocked",        false,C.yellow)
local _,selfRvTgl,  setSelfRvCb,  getSelfRvCb  =makeRow(pages.Main,380,"SR",C.accLt, "Self Revive", "Revive diri sendiri",         false,C.accLt)
local _,killTgl,    setKillCb,    getKillCb    =makeRow(pages.Main,438,"KL",C.red,   "Auto Kill",   "Tarik survivor ke killer",    false,C.red)

-- escape status card
local escCard=Instance.new("Frame",pages.Main)
escCard.Size=UDim2.new(1,-8,0,52) escCard.Position=UDim2.new(0,4,0,500)
escCard.BackgroundColor3=C.card escCard.BorderSizePixel=0 corner(escCard,10) stroke(escCard,C.border,1)
local escDotDisp=Instance.new("Frame",escCard)
escDotDisp.Size=UDim2.new(0,10,0,10) escDotDisp.Position=UDim2.new(0,12,0,12)
escDotDisp.BackgroundColor3=C.muted escDotDisp.BorderSizePixel=0 corner(escDotDisp,99)
local escStatusLbl=lbl(escCard,"Menunggu round...",11,C.sub,true,Enum.TextXAlignment.Left)
escStatusLbl.Size=UDim2.new(1,-110,0,18) escStatusLbl.Position=UDim2.new(0,28,0,8)
local escTimerDisp=lbl(escCard,"--:--",22,C.cyan,true,Enum.TextXAlignment.Right)
escTimerDisp.Size=UDim2.new(0,88,1,0) escTimerDisp.Position=UDim2.new(1,-96,0,0)
local escSubLbl=lbl(escCard,"Timer saat ini",9,C.sub,false,Enum.TextXAlignment.Left)
escSubLbl.Size=UDim2.new(1,-110,0,14) escSubLbl.Position=UDim2.new(0,28,0,30)

-- ══════════════════════════════════════════════
--  PAGE: PLAYER
-- ══════════════════════════════════════════════
pages.Player=makePage()
local _,speedTgl,setSpeedCb,getSpeedCb=makeRow(pages.Player,0,"SP",C.green,"Speed Hack","WalkSpeed kustom",false,C.green)
local _,jumpTgl, setJumpCb, getJumpCb =makeRow(pages.Player,62,"JP",C.cyan,"Jump Hack","JumpPower kustom",false,C.cyan)
local _,djTgl,   setDJCb,   getDJCb   =makeRow(pages.Player,124,"DJ",C.yellow,"Double Jump","Lompat 2x",false,C.yellow)

local function makeSliderCard(par,yOff,label,initVal,minV,maxV,col,onChange)
    local card=Instance.new("Frame",par)
    card.Size=UDim2.new(1,-8,0,64) card.Position=UDim2.new(0,4,0,yOff)
    card.BackgroundColor3=C.card card.BorderSizePixel=0 corner(card,10) stroke(card,C.border,1)
    local lLeft=lbl(card,label,11,C.sub,false,Enum.TextXAlignment.Left)
    lLeft.Size=UDim2.new(0,54,0,20) lLeft.Position=UDim2.new(0,12,0,8)
    local valLbl=lbl(card,tostring(initVal),18,col,true,Enum.TextXAlignment.Right)
    valLbl.Size=UDim2.new(1,-12,0,20) valLbl.Position=UDim2.new(0,0,0,8)
    local slider=Instance.new("TextButton",card)
    slider.Size=UDim2.new(1,-24,0,18) slider.Position=UDim2.new(0,12,0,36)
    slider.BackgroundColor3=C.muted slider.Text="" slider.BorderSizePixel=0 corner(slider,6)
    local fill=Instance.new("Frame",slider)
    fill.Size=UDim2.new((initVal-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=col fill.BorderSizePixel=0 corner(fill,6)
    local dragging=false
    slider.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
    end)
    slider.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMove then
            local rel=math.clamp((i.Position.X-slider.AbsolutePosition.X)/slider.AbsoluteSize.X,0,1)
            local val=math.floor(minV+(maxV-minV)*rel)
            fill.Size=UDim2.new(rel,0,1,0) valLbl.Text=tostring(val)
            onChange(val)
        end
    end)
    return valLbl
end

makeSliderCard(pages.Player,186,"Speed",_G.SpeedVal,16,216,C.accent,function(v)
    _G.SpeedVal=v if getSpeedCb() and hum then hum.WalkSpeed=v end saveConfig()
end)
makeSliderCard(pages.Player,258,"Jump",_G.JumpVal,7,507,C.cyan,function(v)
    _G.JumpVal=v if getJumpCb() and hum then hum.JumpPower=v end saveConfig()
end)

-- ══════════════════════════════════════════════
--  PAGE: VISUAL (ESP)
-- ══════════════════════════════════════════════
pages.Visual=makePage()
local espActive={player=false,killer=false}
local espObjs  ={player={},killer={}}
local function clearESP(t)
    for _,v in ipairs(espObjs[t]) do pcall(function() v:Destroy() end) end espObjs[t]={}
end
local function makeHighlight(obj,col)
    local h=Instance.new("SelectionBox")
    h.Adornee=obj h.Color3=col h.LineThickness=0.05
    h.SurfaceColor3=col h.SurfaceTransparency=0.7 h.Parent=sg return h
end
local espConn=nil
local function startESP()
    if espConn then espConn:Disconnect() end
    espConn=game:GetService("RunService").Heartbeat:Connect(function()
        if espActive.player then
            clearESP("player")
            for _,p in ipairs(game.Players:GetPlayers()) do
                if p~=player and p.Character then
                    local ok,h=pcall(makeHighlight,p.Character,Color3.fromRGB(80,180,255))
                    if ok then table.insert(espObjs.player,h) end
                end
            end
        end
        if espActive.killer then
            clearESP("killer")
            for _,obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                    local n=obj.Name:lower()
                    if n:find("killer") or n:find("monster") then
                        local ok,h=pcall(makeHighlight,obj,Color3.fromRGB(255,60,60))
                        if ok then table.insert(espObjs.killer,h) end
                    end
                end
            end
        end
        if not espActive.player and not espActive.killer then
            if espConn then espConn:Disconnect() espConn=nil end
        end
    end)
end

local _,espPlrTgl,setEspPlrCb,getEspPlrCb=makeRow(pages.Visual,0,"EP",C.cyan,"Player ESP","Highlight semua player",false,C.cyan)
local _,espKillTgl,setEspKillCb,getEspKillCb=makeRow(pages.Visual,62,"EK",C.red,"Killer ESP","Highlight killer",false,C.red)
onTap(espPlrTgl,function()
    local v=not getEspPlrCb() setEspPlrCb(v) espActive.player=v
    if v then startESP() else clearESP("player") end
end)
onTap(espKillTgl,function()
    local v=not getEspKillCb() setEspKillCb(v) espActive.killer=v
    if v then startESP() else clearESP("killer") end
end)

-- ══════════════════════════════════════════════
--  PAGE: MISC
-- ══════════════════════════════════════════════
pages.Misc=makePage()
local afkConn=nil
local _,afkTgl,setAfkCb,getAfkCb=makeRow(pages.Misc,0,"AK",C.yellow,"AFK Mode","Anti kick AFK",false,C.yellow)

local whCard=Instance.new("Frame",pages.Misc)
whCard.Size=UDim2.new(1,-8,0,190) whCard.Position=UDim2.new(0,4,0,62)
whCard.BackgroundColor3=C.card whCard.BorderSizePixel=0 corner(whCard,10) stroke(whCard,C.border,1)
lbl(whCard,"🔔  Webhook Discord",13,C.text,true,Enum.TextXAlignment.Left).Size=UDim2.new(1,-16,0,24)
local wlb=whCard:FindFirstChildWhichIsA("TextLabel") wlb.Position=UDim2.new(0,12,0,10)
local whBg=Instance.new("Frame",whCard)
whBg.Size=UDim2.new(1,-24,0,30) whBg.Position=UDim2.new(0,12,0,40)
whBg.BackgroundColor3=C.bg whBg.BorderSizePixel=0 corner(whBg,8) stroke(whBg,C.border,1)
local webhookBox=Instance.new("TextBox",whBg)
webhookBox.Size=UDim2.new(1,-16,1,0) webhookBox.Position=UDim2.new(0,10,0,0)
webhookBox.BackgroundTransparency=1
webhookBox.PlaceholderText="https://discord.com/api/webhooks/..."
webhookBox.Text=_G.WebhookURL or ""
webhookBox.TextColor3=C.text webhookBox.PlaceholderColor3=C.sub
webhookBox.TextSize=10 webhookBox.Font=Enum.Font.Gotham
webhookBox.TextXAlignment=Enum.TextXAlignment.Left webhookBox.ClearTextOnFocus=false
local saveWhBtn=Instance.new("TextButton",whCard)
saveWhBtn.Size=UDim2.new(1,-24,0,32) saveWhBtn.Position=UDim2.new(0,12,0,78)
saveWhBtn.BackgroundColor3=C.accent saveWhBtn.Text="💾  Simpan Webhook"
saveWhBtn.TextColor3=C.text saveWhBtn.TextSize=13 saveWhBtn.Font=Enum.Font.GothamBold
saveWhBtn.BorderSizePixel=0 corner(saveWhBtn,8)
onTap(saveWhBtn,function()
    _G.WebhookURL=webhookBox.Text saveConfig()
    saveWhBtn.Text="✅  Tersimpan!"
    task.delay(2,function() if saveWhBtn and saveWhBtn.Parent then saveWhBtn.Text="💾  Simpan Webhook" end end)
end)
local chipsF=Instance.new("Frame",whCard)
chipsF.Size=UDim2.new(1,-24,0,30) chipsF.Position=UDim2.new(0,12,0,118)
chipsF.BackgroundTransparency=1
local chipLayout=Instance.new("UIListLayout",chipsF)
chipLayout.FillDirection=Enum.FillDirection.Horizontal chipLayout.Padding=UDim.new(0,8)
local function makeChip(par,label,acol,initState)
    local chip=Instance.new("TextButton",par)
    chip.Size=UDim2.new(0,90,0,28) chip.BackgroundColor3=initState and C.accDim or C.bg
    chip.Text=(initState and "✓ " or "")..label chip.TextColor3=initState and acol or C.sub
    chip.TextSize=11 chip.Font=Enum.Font.GothamBold chip.BorderSizePixel=0
    corner(chip,20) stroke(chip,initState and acol or C.border,1)
    local state=initState or false
    onTap(chip,function()
        state=not state
        chip.BackgroundColor3=state and C.accDim or C.bg chip.TextColor3=state and acol or C.sub
        chip.Text=(state and "✓ " or "")..label
        for _,ch in ipairs(chip:GetChildren()) do if ch:IsA("UIStroke") then ch:Destroy() end end
        stroke(chip,state and acol or C.border,1)
    end)
    return chip,function() return state end
end
local evLootChip,getEvLoot=makeChip(chipsF,"Per Loot",C.green,_G.WhEv_Loot)
local evBatchChip,getEvBatch=makeChip(chipsF,"Per Batch",C.yellow,_G.WhEv_Batch)
onTap(evLootChip,function() _G.WhEv_Loot=getEvLoot() saveConfig() end)
onTap(evBatchChip,function() _G.WhEv_Batch=getEvBatch() saveConfig() end)

-- ══════════════════════════════════════════════
--  TAB NAVIGATION
-- ══════════════════════════════════════════════
local function switchTab(name)
    for id,ni in pairs(navItems) do
        local on=id==name
        ni.btn.BackgroundColor3=on and C.accDim or Color3.new(0,0,0)
        ni.btn.BackgroundTransparency=on and 0 or 1
        ni.bar.Visible=on ni.labL.TextColor3=on and C.text or C.sub
        if on then stroke(ni.btn,C.border,1)
        else for _,ch in ipairs(ni.btn:GetChildren()) do if ch:IsA("UIStroke") then ch:Destroy() end end end
    end
    for n,page in pairs(pages) do
        page.Position=(n==name) and UDim2.new(0,0,0,0) or UDim2.new(10,0,0,0)
    end
    local info=TAB_INFO[name]
    if info then panelTitle.Text=info.title panelSub.Text=info.sub end
    scroll.CanvasPosition=Vector2.new(0,0)
end
for id,ni in pairs(navItems) do onTap(ni.btn,function() switchTab(id) end) end

-- ══════════════════════════════════════════════
--  STATUS HELPERS
-- ══════════════════════════════════════════════
setStatus=function(text,active)
    statusLbl.Text=text
    local col=active and C.green or C.red
    sDot.BackgroundColor3=col statusLbl.TextColor3=active and C.green or C.sub
    tbDot.BackgroundColor3=col tbTxt.Text=active and "ON" or "Idle"
    tbTxt.TextColor3=active and C.green or C.sub
    sbDot2.BackgroundColor3=col sbTxt.Text=active and "Running" or "Idle"
    sbTxt.TextColor3=active and C.green or C.sub
end
updateStats=function(col,found)
    s1val.Text=tostring(col) s2val.Text=tostring(found or 0)
end

-- ══════════════════════════════════════════════
--  ██████████████████████████████████████████
--       SISTEM MANDOR — PRIORITY CONTROLLER
--  ██████████████████████████████████████████
-- ══════════════════════════════════════════════

-- ── KILLER CACHE (satu mata-mata, semua baca di sini) ──
local KillerCache = {
    positions  = {},
    lastUpdate = 0,
    INTERVAL   = 0.2,
}
local function refreshKillerCache()
    if (tick()-KillerCache.lastUpdate) < KillerCache.INTERVAL then return end
    KillerCache.lastUpdate = tick()
    KillerCache.positions  = {}

    -- Metode 1: cari via Players list (paling reliable di STK)
    -- killer = player dengan team "Killer" atau attribute IsKiller
    for _,p in ipairs(game.Players:GetPlayers()) do
        local isKiller = false
        if p.Team then
            local tn = p.Team.Name:lower()
            if tn:find("killer") or tn:find("monster") then isKiller = true end
        end
        if p:GetAttribute("IsKiller") == true then isKiller = true end
        if p:GetAttribute("Role") then
            local r = tostring(p:GetAttribute("Role")):lower()
            if r:find("killer") or r:find("monster") then isKiller = true end
        end
        if isKiller and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then table.insert(KillerCache.positions, root.Position) end
        end
    end

    -- Metode 2: fallback scan workspace nama model (buat NPC killer)
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
            local n=obj.Name:lower()
            if n:find("killer") or n:find("monster") or n:find("enemy") then
                local root=obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if root then table.insert(KillerCache.positions,root.Position) end
            end
        end
    end
end

local function isNearKillerCached(pos,radius)
    for _,kpos in ipairs(KillerCache.positions) do
        if (pos-kpos).Magnitude <= radius then return true,kpos end
    end
    return false,nil
end

-- ── INTENT TABLE ──
-- Setiap fitur nulis targetPos & label ke sini, TIDAK teleport sendiri
local Intent = {
    -- priority 1 (paling darurat)
    selfRevive = { active=false, targetPos=nil, label="Self Revive" },
    -- priority 2
    escape     = { active=false, targetPos=nil, label="Escape" },
    -- priority 3
    revive     = { active=false, targetPos=nil, label="Revive" },
    -- priority 4 (terendah)
    farm       = { active=false, targetPos=nil, label="Farm" },
}

-- urutan prioritas dari tertinggi ke terendah
local PRIORITY_ORDER = {"selfRevive","escape","revive","farm"}

-- ── SHARED STATE ──
local totalCollected = 0
local masterRunning  = false
local lastTimerSecs  = nil
local hasEscaped     = false
local validTimerTick = 0
local escapeGuard    = false -- lagi proses escape, jangan teleport lain
local isReviving     = false -- flag: lagi proses revive, aktifkan auto flee realtime

-- ── TIMER READER ──
local function getDigitSTK(folder)
    local best={val=0,dist=math.huge}
    for _,v in pairs(folder:GetChildren()) do
        if v:IsA("TextLabel") then
            local cy=folder.AbsolutePosition.Y+folder.AbsoluteSize.Y/2
            local d=math.abs(v.AbsolutePosition.Y-cy)
            if d<best.dist then best.dist=d best.val=tonumber(v.Text) or 0 end
        end
    end
    return best.val
end
local function getRoundTimerSecs()
    local sisa=nil
    pcall(function()
        local t=player.PlayerGui.TopBar.RoundTimer
        local m1=getDigitSTK(t.Minute1.InnerBox.Numbers)
        local m2=getDigitSTK(t.Minute2.InnerBox.Numbers)
        local s1=getDigitSTK(t.Second1.InnerBox.Numbers)
        local s2=getDigitSTK(t.Second2.InnerBox.Numbers)
        sisa=(m1*10+m2)*60+(s1*10+s2)
    end)
    return sisa
end

-- ── EXIT DOOR FINDER ──
local function getExitDoorPos()
    for _,folder in ipairs(workspace:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            local exits=folder:FindFirstChild("Exits")
            if exits then
                local gw=exits:FindFirstChild("ExitGateway")
                if gw then
                    local dw=gw:FindFirstChild("Doorway")
                    if dw then
                        local dest=dw:FindFirstChild("Door1Destination")
                        if dest and dest:IsA("BasePart") then return dest.Position end
                    end
                end
            end
        end
    end
    return nil
end

-- ── LOOT SCANNER ──
local function isLootModel(obj)
    if not obj:IsA("Model") then return false end
    local p=obj.Parent if not p then return false end
    return p.Name:match("^%d+$") ~= nil
end
local function getLootObjects()
    local results,seen={},{}
    local myY=hrp and hrp.Position.Y or 0
    for _,obj in ipairs(workspace:GetDescendants()) do
        if isLootModel(obj) then
            local pos
            if obj.PrimaryPart then pos=obj.PrimaryPart.Position
            else
                local ok,cf=pcall(function() return obj:GetModelCFrame() end)
                if ok then pos=cf.Position end
            end
            if pos and math.abs(pos.Y-myY)<150 then
                local key=math.floor(pos.X)..math.floor(pos.Y)..math.floor(pos.Z)
                if not seen[key] then
                    seen[key]=true table.insert(results,{name=obj.Name,pos=pos})
                end
            end
        end
    end
    for i=#results,2,-1 do
        local j=math.random(1,i) results[i],results[j]=results[j],results[i]
    end
    return results
end

-- ── PLAYER ROLE HELPERS ──
local function isPlayerKiller(p)
    if p.Team then local tn=p.Team.Name:lower() if tn:find("killer") or tn:find("monster") then return true end end
    if p:GetAttribute("IsKiller")==true then return true end
    if p:GetAttribute("Role") then
        local r=tostring(p:GetAttribute("Role")):lower()
        if r:find("killer") or r:find("monster") then return true end
    end
    local pc=p.Character
    if pc then if pc.Name:lower():find("killer") or pc.Name:lower():find("monster") then return true end end
    return false
end
local function isKillerRole()
    if player.Team then local tn=player.Team.Name:lower() if tn:find("killer") or tn:find("monster") then return true end end
    if player:GetAttribute("IsKiller")==true then return true end
    return false
end

-- ── SELF KNOCKED DETECTOR ──
local function isSelfKnocked()
    char=player.Character if not char then return false end
    local myHum=char:FindFirstChild("Humanoid")
    local myHrp=char:FindFirstChild("HumanoidRootPart")

    -- Cek 1: Health 0
    if myHum and myHum.Health <= 0 then return true end

    -- Cek 2: Dead state
    if myHum and myHum:GetState()==Enum.HumanoidStateType.Dead then return true end

    -- Cek 3: BleedOutHealth di HumanoidRootPart
    if myHrp then
        local bleed=myHrp:FindFirstChild("BleedOutHealth")
        if bleed then
            if (bleed:IsA("BillboardGui") or bleed:IsA("ScreenGui") or bleed:IsA("Frame")) and bleed.Enabled then return true end
            if bleed:IsA("BoolValue") and bleed.Value then return true end
        end
    end

    -- Cek 4: BleedOutHealth di seluruh char (recursive)
    local bleed2=char:FindFirstChild("BleedOutHealth",true)
    if bleed2 then
        if (bleed2:IsA("BillboardGui") or bleed2:IsA("ScreenGui")) and bleed2.Enabled then return true end
        if bleed2:IsA("BoolValue") and bleed2.Value then return true end
    end

    -- Cek 5: GUI knocked di PlayerGui — scan semua nama yang mungkin
    local ok,bleedGui=pcall(function()
        local pg = player.PlayerGui
        for _,v in ipairs(pg:GetDescendants()) do
            if (v:IsA("ScreenGui") or v:IsA("Frame") or v:IsA("BillboardGui")) and v.Enabled then
                local n = v.Name:lower()
                if n:find("bleed") or n:find("knock") or n:find("down") or n:find("revive") then
                    return v
                end
            end
        end
        return nil
    end)
    if ok and bleedGui then return true end

    -- Cek 6: Attribute
    if player:GetAttribute("Knocked")==true then return true end
    if player:GetAttribute("IsKnocked")==true then return true end
    if char:GetAttribute("Knocked")==true then return true end

    return false
end

-- ── KNOCKED PLAYER FINDER ──
local function getKnockedPlayers()
    local list={}
    for _,p in ipairs(game.Players:GetPlayers()) do
        if p~=player and not isPlayerKiller(p) and p.Character then
            local ph=p.Character:FindFirstChild("HumanoidRootPart")
            if ph then
                local bleed=ph:FindFirstChild("BleedOutHealth")
                if bleed and bleed.Enabled then
                    table.insert(list,{plr=p,pHrp=ph})
                end
            end
        end
    end
    return list
end

-- ── TELEPORT AWAY FROM KILLER ──
local FLEE_RADIUS = 20
local function getTeleportFleePos(killerPos)
    if not hrp then return nil end
    local myPos=hrp.Position
    local awayDir=(myPos-killerPos)
    if awayDir.Magnitude < 0.1 then awayDir=Vector3.new(1,0,0) end
    awayDir=Vector3.new(awayDir.X,0,awayDir.Z).Unit
    local angle=math.rad(math.random(-45,45))
    local rotated=Vector3.new(
        awayDir.X*math.cos(angle)-awayDir.Z*math.sin(angle),
        0,
        awayDir.X*math.sin(angle)+awayDir.Z*math.cos(angle)
    )
    local dist=math.random(40,80)
    return myPos+rotated*dist+Vector3.new(0,3,0)
end

-- ════════════════════════════════════════════════
--  INTENT WRITERS — tiap fitur nulis ke Intent,
--  TIDAK ada teleport di sini
-- ════════════════════════════════════════════════

local farmBatch       = {}
local farmBatchIdx    = 0
local farmCooldownEnd = 0

local function writeFarmIntent()
    if not getFarmCb() then Intent.farm.active=false return end
    if not hrp or not hum or hum.Health<=0 then Intent.farm.active=false return end
    -- kalau lagi escape, mandor akan override, tapi kita tetap sediakan target
    -- refresh batch kalau kosong atau index habis
    if farmBatchIdx >= #farmBatch or #farmBatch==0 then
        farmBatch=getLootObjects()
        farmBatchIdx=0
        updateStats(totalCollected,#farmBatch)
        if _G.WhEv_Batch and _G.WebhookURL~="" and #farmBatch>0 then
            pcall(function()
                game:GetService("HttpService"):PostAsync(_G.WebhookURL,
                    HS:JSONEncode({content="📦 Batch baru: "..#farmBatch.." loot"}),
                    Enum.HttpContentType.ApplicationJson)
            end)
        end
    end
    if #farmBatch==0 then
        Intent.farm.active=false
        Intent.farm.label="Farm: loot habis"
        return
    end
    farmBatchIdx=farmBatchIdx+1
    if farmBatchIdx > #farmBatch then farmBatchIdx=1 end
    local loot=farmBatch[farmBatchIdx]
    if not loot then Intent.farm.active=false return end
    -- killer safe check untuk loot ini
    if getKillerSCb() then
        local tooClose,_=isNearKillerCached(loot.pos,FLEE_RADIUS)
        if tooClose then
            -- skip loot ini, cari next
            Intent.farm.active=false
            Intent.farm.label="Farm: skip (killer deket loot)"
            return
        end
    end
    Intent.farm.active    = true
    Intent.farm.targetPos = loot.pos + Vector3.new(0,3,0)
    Intent.farm.label     = "Farm "..farmBatchIdx.."/"..#farmBatch.." — "..loot.name
    Intent.farm.lootName  = loot.name
end

local function writeEscapeIntent()
    if not getEscapeCb() then Intent.escape.active=false return end
    if not hrp or not hum or hum.Health<=0 then Intent.escape.active=false return end
    local sisa=getRoundTimerSecs()
    -- update timer display selalu
    if sisa and sisa>0 then
        local col=sisa>=300 and C.green or sisa>=120 and C.yellow or sisa>=80 and Color3.fromRGB(255,140,80) or C.red
        timerVal.Text=string.format("%d:%02d",math.floor(sisa/60),sisa%60) timerVal.TextColor3=col
        escTimerDisp.Text=string.format("%d:%02d",math.floor(sisa/60),sisa%60)
        -- deteksi round baru
        if lastTimerSecs and sisa>(lastTimerSecs+30) then
            hasEscaped=false validTimerTick=0 escapeGuard=false
        end
        if lastTimerSecs and sisa<lastTimerSecs then
            validTimerTick=validTimerTick+1
        else
            validTimerTick=0
        end
        lastTimerSecs=sisa
    else
        timerVal.Text="--:--" timerVal.TextColor3=C.sub
        escTimerDisp.Text="--:--"
        lastTimerSecs=nil validTimerTick=0 hasEscaped=false
        Intent.escape.active=false return
    end
    if sisa<=59 and validTimerTick>=3 and not hasEscaped then
        local exitPos=getExitDoorPos()
        if exitPos then
            Intent.escape.active    = true
            Intent.escape.targetPos = exitPos + Vector3.new(0,0,0)
            Intent.escape.label     = "Escape! "..sisa.."s"
        else
            Intent.escape.active=false
            Intent.escape.label="Escape: exit ga ketemu"
        end
    else
        Intent.escape.active=false
    end
end

local REVIVE_SAFE_R   = 35
local REVIVE_BAIT_LIM = 5
local reviveBaitTimers= {}

local function writeReviveIntent()
    if not getReviveCb() then Intent.revive.active=false return end
    if not hrp or not hum or hum.Health<=0 then Intent.revive.active=false return end
    local knocked=getKnockedPlayers()
    if #knocked==0 then
        reviveBaitTimers={} Intent.revive.active=false return
    end
    local safeTarget=nil
    for _,t in ipairs(knocked) do
        local tName=t.plr.Name
        -- cek killer dari 2 sudut: posisi target DAN posisi kita sendiri
        local killerNearTarget,_=isNearKillerCached(t.pHrp.Position,REVIVE_SAFE_R)
        local killerNearMe,_=isNearKillerCached(hrp.Position,REVIVE_SAFE_R)
        local killerNear = killerNearTarget or killerNearMe
        if killerNear then
            -- catat kapan pertama kali killer deket target ini
            if not reviveBaitTimers[tName] then reviveBaitTimers[tName]=tick() end
            -- kalau killer udah nongkrong > REVIVE_BAIT_LIM detik, skip permanen
            if (tick()-reviveBaitTimers[tName]) > REVIVE_BAIT_LIM then
                reviveBaitTimers[tName]=tick() -- reset supaya nanti bisa dicoba lagi
            end
            -- tetap skip target ini, lanjut ke knocked player berikutnya
        else
            reviveBaitTimers[tName]=nil safeTarget=t break
        end
    end
    if not safeTarget then
        Intent.revive.active=false
        Intent.revive.label="Revive: semua dijaga killer"
        return
    end
    local dist=(hrp.Position-safeTarget.pHrp.Position).Magnitude
    local arrivalPos = safeTarget.pHrp.Position + Vector3.new(2,0,0)
    -- double check: posisi kita setelah teleport juga harus aman
    local arrivalDanger,_ = isNearKillerCached(arrivalPos, FLEE_RADIUS)
    if arrivalDanger then
        Intent.revive.active = false
        Intent.revive.label  = "Revive: arrival bahaya, skip"
        return
    end
    Intent.revive.active    = true
    Intent.revive.targetPos = arrivalPos
    Intent.revive.label     = "Revive "..safeTarget.plr.Name.." ("..math.floor(dist).." studs)"
end

local SELF_REVIVE_SAFE_R = 25

local function writeSelfReviveIntent()
    if not getSelfRvCb() then Intent.selfRevive.active=false return end
    if not isSelfKnocked() then Intent.selfRevive.active=false return end
    -- cari player hidup & aman
    local alive={}
    char=player.Character if not char then Intent.selfRevive.active=false return end
    local myHrp=char:FindFirstChild("HumanoidRootPart")
    if not myHrp then Intent.selfRevive.active=false return end
    local myPos=myHrp.Position
    for _,p in ipairs(game.Players:GetPlayers()) do
        if p~=player and not isPlayerKiller(p) and p.Character then
            local ph=p.Character:FindFirstChild("HumanoidRootPart")
            local phum=p.Character:FindFirstChild("Humanoid")
            if ph and phum and phum.Health>0 then
                -- filter lobby: skip kalau beda Y lebih dari 200 studs (lobby = area terpisah)
                -- DAN skip kalau total jarak > 500 studs
                local yDiff = math.abs(ph.Position.Y - myPos.Y)
                local totalDist = (ph.Position - myPos).Magnitude
                if yDiff > 200 or totalDist > 500 then continue end
                local kn,_=isNearKillerCached(ph.Position,SELF_REVIVE_SAFE_R)
                if not kn then table.insert(alive,{pHrp=ph,name=p.Name}) end
            end
        end
    end
    if #alive==0 then
        Intent.selfRevive.active=false
        Intent.selfRevive.label="SelfRev: semua deket killer"
        return
    end
    local t=alive[1]
    local arrivalPos = t.pHrp.Position + Vector3.new(2,0,0)
    -- double check arrival aman
    local arrivalDanger,_ = isNearKillerCached(arrivalPos, FLEE_RADIUS)
    if arrivalDanger then
        Intent.selfRevive.active = false
        Intent.selfRevive.label  = "SelfRev: arrival bahaya, skip"
        return
    end
    Intent.selfRevive.active    = true
    Intent.selfRevive.targetPos = arrivalPos
    Intent.selfRevive.label     = "SelfRev → "..t.name
end

-- ════════════════════════════════════════════════
--  MANDOR — MASTER CONTROLLER LOOP
--  Ini satu-satunya yang boleh teleport
-- ════════════════════════════════════════════════
local function updatePrioDisplay(name,col,labelText)
    prioDot.BackgroundColor3=col
    prioLbl.Text="Mandor: "..labelText
    prioLbl.TextColor3=col
end

_G.PevMasterRunning=true
task.spawn(function()
    while _G.PevMasterRunning and sg and sg.Parent do
        task.wait(0.15)

        -- refresh karakter
        char=player.Character
        if not char then task.wait(0.5) continue end
        hrp=char:FindFirstChild("HumanoidRootPart")
        hum=char:FindFirstChild("Humanoid")
        if not hrp or not hum then task.wait(0.5) continue end

        -- 1. Refresh killer cache (satu kali per tick)
        refreshKillerCache()

        -- 2. Cek apakah player sendiri terlalu dekat killer
        --    Aktif kalau: KillerSafe toggle ON, ATAU lagi proses revive/selfRevive
        local doFleeCheck = (getKillerSCb() or isReviving) and hum.Health>0
        if doFleeCheck then
            local fleeRadius = isReviving and REVIVE_FLEE_R or FLEE_RADIUS
            local tooClose,kpos=isNearKillerCached(hrp.Position,fleeRadius)
            if tooClose and kpos then
                isReviving = false -- reset flag
                local fleePos=getTeleportFleePos(kpos)
                if fleePos then
                    hrp.CFrame=CFrame.new(fleePos)
                    if isReviving then
                        setStatus("🚨 Killer dateng saat revive, kabur!",true)
                        updatePrioDisplay("FLEE",C.red,"Kabur saat Revive!")
                    else
                        setStatus("🚨 Kabur dari killer!",true)
                        updatePrioDisplay("FLEE",C.red,"Kabur dari Killer!")
                    end
                    task.wait(0.4)
                end
                continue -- skip tick ini, jangan ambil intent lain
            end
        end

        -- 3. Tulis semua intent (tiap fitur update target mereka)
        writeSelfReviveIntent()
        writeEscapeIntent()
        writeReviveIntent()
        writeFarmIntent()

        -- 4. Pilih intent prioritas tertinggi yang aktif
        local chosen=nil
        for _,key in ipairs(PRIORITY_ORDER) do
            if Intent[key].active and Intent[key].targetPos then
                chosen=Intent[key] break
            end
        end

        -- 5. Eksekusi — satu teleport, satu status
        if chosen then
            -- set flag reviving SEBELUM teleport
            if chosen==Intent.revive or chosen==Intent.selfRevive then
                isReviving = true
            else
                isReviving = false
            end

            hrp.CFrame=CFrame.new(chosen.targetPos)
            setStatus("▶ "..chosen.label,true)
            updatePrioDisplay(chosen.label,
                chosen==Intent.selfRevive and C.accLt or
                chosen==Intent.escape     and C.cyan  or
                chosen==Intent.revive     and C.yellow or C.green,
                chosen.label)

            -- POST-TELEPORT SAFETY CHECK — cek sekali lagi setelah tp
            if chosen==Intent.revive or chosen==Intent.selfRevive then
                task.wait(0.08)
                refreshKillerCache()
                local stillDanger,kpos2=isNearKillerCached(hrp.Position,REVIVE_FLEE_R)
                if stillDanger and kpos2 then
                    isReviving = false
                    local fleePos=getTeleportFleePos(kpos2)
                    if fleePos then
                        hrp.CFrame=CFrame.new(fleePos)
                        setStatus("🚨 Killer dateng saat revive, kabur!",true)
                        updatePrioDisplay("FLEE",C.red,"Kabur setelah Revive!")
                        task.wait(0.3)
                    end
                end
                -- isReviving tetap true kalau aman, akan di-reset di tick berikutnya
                -- kalau killer dateng → step 2 yang handle dan reset
            end
            -- kalau ini escape dan berhasil teleport, set flag
            if chosen==Intent.escape then
                hasEscaped=true escapeGuard=true
                setStatus("✅ Escaped — tunggu round berikut",false)
                updatePrioDisplay("Escaped",C.green,"Escaped ✓")
                -- webhook
                if _G.WebhookURL~="" then
                    pcall(function()
                        game:GetService("HttpService"):PostAsync(_G.WebhookURL,
                            HS:JSONEncode({content="🚪 Escaped! Sisa timer: "..math.floor(lastTimerSecs or 0).."s"}),
                            Enum.HttpContentType.ApplicationJson)
                    end)
                end
            end
            -- kalau farm, hitung collected & webhook per loot
            if chosen==Intent.farm then
                totalCollected=totalCollected+1
                updateStats(totalCollected,#farmBatch-farmBatchIdx)
                if _G.WhEv_Loot and _G.WebhookURL~="" then
                    pcall(function()
                        game:GetService("HttpService"):PostAsync(_G.WebhookURL,
                            HS:JSONEncode({content="✅ Loot: `"..(chosen.lootName or "?").."` | Total: "..totalCollected}),
                            Enum.HttpContentType.ApplicationJson)
                    end)
                end
            end
        else
            -- tidak ada yang aktif, pastikan flag reviving direset
            isReviving = false
            local anyOn = getFarmCb() or getEscapeCb() or getReviveCb() or getSelfRvCb()
            if anyOn then
                setStatus("⌛ Nunggu kondisi...",true)
                updatePrioDisplay("Wait",C.muted,"Nunggu kondisi...")
            else
                setStatus("Idle — menunggu",false)
                updatePrioDisplay("Idle",C.muted,"Standby")
            end
        end
    end
end)

-- ══════════════════════════════════════════════
--  TOGGLE HANDLERS
-- ══════════════════════════════════════════════
onTap(farmTgl,function()
    local v=not getFarmCb() setFarmCb(v) _G.FarmOn=v
    farmBatch={} farmBatchIdx=0
    if not v then Intent.farm.active=false end
    saveConfig()
end)
onTap(escapeTgl,function()
    local v=not getEscapeCb() setEscapeCb(v) _G.EscapeOn=v
    if not v then Intent.escape.active=false hasEscaped=false end
    saveConfig()
end)
onTap(reviveTgl,function()
    local v=not getReviveCb() setReviveCb(v) _G.ReviveOn=v
    if not v then Intent.revive.active=false end
    saveConfig()
end)
onTap(selfRvTgl,function()
    local v=not getSelfRvCb() setSelfRvCb(v) _G.SelfReviveOn=v
    if not v then Intent.selfRevive.active=false end
    saveConfig()
end)
onTap(killerSTgl,function()
    local v=not getKillerSCb() setKillerSCb(v) _G.KillerSafeOn=v saveConfig()
end)

-- ══════════════════════════════════════════════
--  AUTO KILL (tetap sendiri — tidak konflik
--  karena kill bukan teleport DIRI kita)
-- ══════════════════════════════════════════════
local killRunning=false
local function killLoop()
    while killRunning do
        task.wait(0.5)
        char=player.Character if not char then task.wait(1) end
        if not char then killRunning=not killRunning break end
        hrp=char:FindFirstChild("HumanoidRootPart")
        hum=char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health<=0 then task.wait(1)
        elseif not isKillerRole() then task.wait(1)
        else
            local targets={}
            for _,p in ipairs(game.Players:GetPlayers()) do
                if p~=player and not isPlayerKiller(p) and p.Character then
                    local ph=p.Character:FindFirstChild("HumanoidRootPart")
                    local phum=p.Character:FindFirstChild("Humanoid")
                    if ph and phum and phum.Health>0 then table.insert(targets,{pHrp=ph}) end
                end
            end
            if #targets>0 then
                local myLook=hrp.CFrame.LookVector
                local stackPos=hrp.Position+myLook*4+Vector3.new(0,0.5,0)
                for _,t in ipairs(targets) do
                    pcall(function() t.pHrp.CFrame=CFrame.new(stackPos,stackPos+myLook) end)
                end
            end
            task.wait(0.3)
        end
    end
end
onTap(killTgl,function()
    local v=not getKillCb() setKillCb(v) killRunning=v _G.KillOn=v
    if v then task.spawn(killLoop) end saveConfig()
end)

-- ══════════════════════════════════════════════
--  SPEED / JUMP / DOUBLE JUMP
-- ══════════════════════════════════════════════
local djConn=nil
onTap(speedTgl,function()
    local v=not getSpeedCb() setSpeedCb(v) _G.SpeedOn=v
    if hum then hum.WalkSpeed=v and _G.SpeedVal or 16 end saveConfig()
end)
onTap(jumpTgl,function()
    local v=not getJumpCb() setJumpCb(v) _G.JumpOn=v
    if hum then hum.JumpPower=v and _G.JumpVal or 7.2 end saveConfig()
end)
onTap(djTgl,function()
    local v=not getDJCb() setDJCb(v) _G.DJOn=v
    if djConn then djConn:Disconnect() djConn=nil end
    if v then
        djConn=game:GetService("UserInputService").JumpRequest:Connect(function()
            if hum and hum:GetState()==Enum.HumanoidStateType.Freefall then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
    saveConfig()
end)
if _G.SpeedOn then setSpeedCb(true) if hum then hum.WalkSpeed=_G.SpeedVal end end
if _G.JumpOn  then setJumpCb(true)  if hum then hum.JumpPower=_G.JumpVal  end end

-- ══════════════════════════════════════════════
--  AFK
--  Pake VirtualUser + Idled event — karakter diem,
--  ga jump, ga jalan, cukup simulate input biar ga ke-kick
-- ══════════════════════════════════════════════
local VU = game:GetService("VirtualUser")
onTap(afkTgl,function()
    local v=not getAfkCb() setAfkCb(v)
    if afkConn then afkConn:Disconnect() afkConn=nil end
    if v then
        afkConn=player.Idled:Connect(function()
            pcall(function()
                VU:CaptureController()
                VU:ClickButton2(Vector2.new(0,0))
            end)
        end)
    end
end)

-- ══════════════════════════════════════════════
--  AUTO FLEE REALTIME (saat reviving, tanpa toggle)
--  Killer mendekat saat kita revive → langsung kabur
-- ══════════════════════════════════════════════
local REVIVE_FLEE_R = 22  -- radius deteksi killer saat lagi reviving
task.spawn(function()
    while sg and sg.Parent do
        task.wait(0.1)
        if not isReviving then continue end
        char=player.Character if not char then continue end
        local myHrp=char:FindFirstChild("HumanoidRootPart") if not myHrp then continue end
        refreshKillerCache()
        local danger,kpos=isNearKillerCached(myHrp.Position,REVIVE_FLEE_R)
        if danger and kpos then
            isReviving=false  -- reset dulu biar ga loop
            local fleePos=getTeleportFleePos(kpos)
            if fleePos then
                myHrp.CFrame=CFrame.new(fleePos)
                setStatus("🚨 Kabur! Killer deket saat revive",true)
                updatePrioDisplay("FLEE",C.red,"Auto Flee — Revive interrupted")
            end
        end
    end
end)

-- ══════════════════════════════════════════════
--  AUTO BREAK TRAP (otomatis, tanpa toggle)
--  Deteksi jika kena perangkap killer STK
--  → spam teleport kecil + ChangeState buat lepas
-- ══════════════════════════════════════════════
local trapBreakActive = false
task.spawn(function()
    while sg and sg.Parent do
        task.wait(0.12)
        char=player.Character if not char then continue end
        local myHrp=char:FindFirstChild("HumanoidRootPart") if not myHrp then continue end
        local myHum=char:FindFirstChild("Humanoid") if not myHum or myHum.Health<=0 then continue end

        -- deteksi trap: cek attribute, gui, atau object trap di karakter
        local trapped=false
        -- metode 1: attribute
        if char:GetAttribute("Trapped")==true then trapped=true end
        if char:GetAttribute("IsCaught")==true then trapped=true end
        if player:GetAttribute("Trapped")==true then trapped=true end
        -- metode 2: BillboardGui trap di karakter
        if not trapped then
            for _,v in ipairs(char:GetDescendants()) do
                if (v:IsA("BillboardGui") or v:IsA("ScreenGui")) then
                    local n=v.Name:lower()
                    if (n:find("trap") or n:find("caught") or n:find("snare") or n:find("cage")) and v.Enabled then
                        trapped=true break
                    end
                end
            end
        end
        -- metode 3: cek object trap nempel di karakter (BasePart dengan nama trap)
        if not trapped then
            for _,v in ipairs(char:GetChildren()) do
                if v:IsA("BasePart") then
                    local n=v.Name:lower()
                    if n:find("trap") or n:find("snare") or n:find("net") then
                        trapped=true break
                    end
                end
            end
        end

        if trapped and not trapBreakActive then
            trapBreakActive=true
            setStatus("🪤 Kena trap! Lagi lepas...",true)
            updatePrioDisplay("TRAP",C.yellow,"Breaking trap...")
            -- spam escape: ChangeState + micro-teleport random buat lepas
            for i=1,8 do
                task.wait(0.05)
                pcall(function()
                    myHum:ChangeState(Enum.HumanoidStateType.Jumping)
                    local rng=Vector3.new(math.random(-3,3),2,math.random(-3,3))
                    myHrp.CFrame=CFrame.new(myHrp.Position+rng)
                end)
                -- cek lagi, kalau udah lepas stop
                char=player.Character if not char then break end
                myHrp=char:FindFirstChild("HumanoidRootPart") if not myHrp then break end
                myHum=char:FindFirstChild("Humanoid") if not myHum then break end
                if char:GetAttribute("Trapped")~=true and char:GetAttribute("IsCaught")~=true then break end
            end
            trapBreakActive=false
        end
    end
end)

-- ══════════════════════════════════════════════
--  CHARACTER RESPAWN
-- ══════════════════════════════════════════════
player.CharacterAdded:Connect(function(c)
    char=c hrp=c:WaitForChild("HumanoidRootPart") hum=c:WaitForChild("Humanoid")
    -- reset escape guard saat respawn (round baru)
    hasEscaped=false escapeGuard=false validTimerTick=0
    farmBatch={} farmBatchIdx=0
    if getSpeedCb() then task.wait(0.5) hum.WalkSpeed=_G.SpeedVal end
    if getJumpCb()  then task.wait(0.5) hum.JumpPower=_G.JumpVal  end
end)

-- ══════════════════════════════════════════════
--  ESCAPE STATUS DISPLAY LOOP (UI only, no tp)
-- ══════════════════════════════════════════════
task.spawn(function()
    while sg and sg.Parent do
        task.wait(0.5)
        local sisa=lastTimerSecs
        if sisa and sisa>0 then
            if hasEscaped then
                escDotDisp.BackgroundColor3=C.green escStatusLbl.Text="Sudah Escape ✓"
                escStatusLbl.TextColor3=C.green escTimerDisp.TextColor3=C.green
            elseif sisa<=59 then
                escDotDisp.BackgroundColor3=C.green escStatusLbl.Text="Waktunya Escape!"
                escStatusLbl.TextColor3=C.green escTimerDisp.TextColor3=C.green
            elseif sisa<=120 then
                escDotDisp.BackgroundColor3=C.yellow escStatusLbl.Text="Sebentar lagi..."
                escStatusLbl.TextColor3=C.yellow escTimerDisp.TextColor3=C.yellow
            else
                escDotDisp.BackgroundColor3=C.red escStatusLbl.Text="Belum Escape"
                escStatusLbl.TextColor3=C.sub escTimerDisp.TextColor3=C.cyan
            end
        else
            escDotDisp.BackgroundColor3=C.muted escStatusLbl.Text="Menunggu round..."
            escStatusLbl.TextColor3=C.sub escTimerDisp.TextColor3=C.sub
        end
    end
end)

-- ══════════════════════════════════════════════
--  RESTORE TOGGLES FROM CONFIG
-- ══════════════════════════════════════════════
if _G.FarmOn      then setFarmCb(true)    end
if _G.EscapeOn    then setEscapeCb(true)  end
if _G.ReviveOn    then setReviveCb(true)  end
if _G.SelfReviveOn then setSelfRvCb(true) end
if _G.KillerSafeOn then setKillerSCb(true) end
if _G.KillOn      then setKillCb(true) killRunning=true task.spawn(killLoop) end

-- ══════════════════════════════════════════════
--  MINIMIZE / CLOSE
-- ══════════════════════════════════════════════
onTap(minBtn,function() win.Visible=false bubble.Visible=true end)
onTap(bubble,function() bubble.Visible=false win.Visible=true end)
onTap(closeBtn,function()
    _G.PevMasterRunning=false killRunning=false
    if djConn  then djConn:Disconnect()  djConn=nil  end
    if afkConn then afkConn:Disconnect() afkConn=nil end
    if espConn then espConn:Disconnect() espConn=nil end
    for t in pairs(espActive) do espActive[t]=false clearESP(t) end
    local c=player.Character
    if c then
        local h=c:FindFirstChild("Humanoid") if h then
            if getSpeedCb() then h.WalkSpeed=16 end
            if getJumpCb()  then h.JumpPower=7.2 end
        end
    end
    sg:Destroy() _G.PevGui=nil
end)

-- ══════════════════════════════════════════════
--  INIT
-- ══════════════════════════════════════════════
switchTab("Main")
setStatus("Idle — menunggu",false)
updatePrioDisplay("Idle",C.muted,"Standby")
