--[[
    SORU HUB UI v5.0  -  REDESIGN TOTAL  (hanya Dropdown + Notify)

    DIHAPUS  : Button, Toggle, Slider, Textbox, Keybind, ColorPicker, Accordion, Paragraph, Section, Divider, Label
    DISISAKAN: Dropdown, Notify (keduanya didesain ulang)

    BARU DI v5.0
      Tema      : sistem palet hidup - ganti tema = semua warna (termasuk gradien) bergeser halus, tanpa "snap"
      Window    : header + sidebar + konten dirapikan, tab pindah dengan fade/slide, pill "liquid", neon bernapas
      Dropdown  : kartu baru (aksen header, value pill, chevron), baris dengan radio/checkbox animasi,
                  search otomatis + tinggi list mengikuti hasil, klik di luar = tutup, hanya satu terbuka
      Notify    : toast glass (icon glow, shine, progress bar), jeda saat di-hover, klik untuk tutup,
                  tumpukan bergeser halus, maksimal 5 toast
      Dashboard : profil, FPS/Ping/Session, grafik FPS, info game (copy ID), koordinat, pengaturan (semua via Dropdown)

    API
      local Window = SORU:CreateWindow({
          Title = "SORU HUB", SupportedGames = {123}, KickIfNotSupported = true,
          ReferenceSize = Vector2.new(1280, 720), Scale = 1,
          ToggleKey = Enum.KeyCode.RightShift,
          Demo = false, -- true = tambah tab "Showcase" berisi contoh Dropdown + tes Notify
      })
      local Tab = Window:Tab({Title = "Main", Icon = "M"})
      local DD = Tab:Dropdown({
          Title = "Mode", Desc = "opsional", Flag = "Mode",
          Options = {"A", "B", "C"}, Default = "A",
          Multi = false,        -- true = pilih banyak (Default & Callback berupa array)
          Search = nil,         -- true/false, default otomatis kalau opsi > 7
          NoSave = false,       -- true = tidak disimpan ke config
          NoInit = false,       -- true = Callback tidak dipanggil saat dibuat
          Callback = function(value|array) end,
      })  -- DD:Set(v, fire)  DD:Get()  DD:Refresh(opts)  DD:Open()  DD:Close()

      Window:Notify("Judul", "Pesan", "info"|"success"|"warn"|"error"|Color3, 3.5)
      Window.Notify("Judul", "Pesan", "success", 3)          -- format lama juga bisa
      Window:Notify({Title = "Judul", Content = "Pesan", Type = "success", Duration = 4})
      Window:SetTheme("Ocean")  Window:Toggle()  Window:Destroy()
]]

local SORU = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Market = game:GetService("MarketplaceService")
local Http = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

local CFG = "SORU_HUB" local CFGS = CFG.."/configs"
pcall(function() if makefolder then if not isfolder(CFG) then makefolder(CFG) end if not isfolder(CFGS) then makefolder(CFGS) end end end)
local SIZE_FILE = "soru.size"
local SIZE_FILE2 = CFG.."/soru.size"

local URLS = {
    ICON = "https://raw.githubusercontent.com/dam45383-netizen/UI/main/SORU_S_ICON_1024.png",
    BG = "https://raw.githubusercontent.com/dam45383-netizen/UI/main/SORU_THEME_1024.png"
}
local function getAsset(name, url)
    local path = CFG.."/"..name
    if isfile and isfile(path) and getcustomasset then return getcustomasset(path) end
    if url and writefile then
        pcall(function() writefile(path, game:HttpGet(url)) end)
        task.wait(0.1)
        if isfile and isfile(path) and getcustomasset then return getcustomasset(path) end
    end
    return "rbxassetid://0"
end
local ICON = getAsset("SORU_S_ICON_1024.png", URLS.ICON)
local BG = getAsset("SORU_THEME_1024.png", URLS.BG)

----------------------------------------------------------------------
-- SOUND KHAS SORU (disintesis sendiri -> .wav -> getcustomasset, tanpa asset id)
----------------------------------------------------------------------
local sfxFn = function() end
local function sfx(...) return sfxFn(...) end
-- bagian: {mulai, durasi, freq0, freq1, volume, jenis, peluruhan}
local SFX_DEFS = {
    boot     = {1.6, {{0, 0.7, 440, 440, 0.45, "bell", 5}, {0.12, 0.7, 659.3, 659.3, 0.42, "bell", 5}, {0.24, 0.8, 880, 880, 0.42, "bell", 4.5}, {0.36, 0.9, 1108.7, 1108.7, 0.4, "bell", 4}, {0.5, 1.1, 1318.5, 1318.5, 0.5, "bell", 3.2}}},
    open     = {0.8, {{0, 0.5, 880, 880, 0.5, "bell", 8}, {0.07, 0.5, 1108.7, 1108.7, 0.45, "bell", 8}, {0.14, 0.6, 1318.5, 1318.5, 0.5, "bell", 7}}},
    close    = {0.6, {{0, 0.4, 1318.5, 1318.5, 0.45, "bell", 10}, {0.08, 0.5, 880, 880, 0.5, "bell", 9}}},
    click    = {0.12, {{0, 0.1, 1500, 650, 0.6, "sine", 38}, {0, 0.05, 3000, 3000, 0.18, "bell", 70}}},
    hover    = {0.06, {{0, 0.05, 2600, 2600, 0.14, "sine", 70}}},
    tab      = {0.3, {{0, 0.14, 500, 900, 0.45, "sine", 22}, {0.02, 0.22, 1760, 1760, 0.2, "bell", 30}}},
    tick     = {0.05, {{0, 0.035, 1800, 1800, 0.45, "sine", 90}}},
    pop      = {0.3, {{0, 0.12, 700, 1100, 0.5, "sine", 28}, {0.03, 0.22, 1568, 1568, 0.22, "bell", 25}}},
    expand   = {0.3, {{0, 0.16, 420, 850, 0.4, "sine", 18}, {0.03, 0.22, 1568, 1568, 0.2, "bell", 24}}},
    collapse = {0.3, {{0, 0.16, 850, 420, 0.4, "sine", 18}, {0.03, 0.22, 1174.7, 1174.7, 0.2, "bell", 24}}},
    notify   = {0.9, {{0, 0.5, 1174.7, 1174.7, 0.5, "bell", 8}, {0.1, 0.6, 1568, 1568, 0.5, "bell", 7}}},
    error    = {0.5, {{0, 0.28, 196, 150, 0.45, "buzz", 8}, {0.13, 0.3, 185, 140, 0.45, "buzz", 8}}},
}
local function buildSfx()
    local out = {}
    if not (writefile and isfile and getcustomasset) then return out end
    local RATE, TAU = 22050, math.pi * 2
    local function le(x, n)
        local t = {}
        for i = 1, n do t[i] = string.char(x % 256) x = math.floor(x / 256) end
        return table.concat(t)
    end
    for name, def in pairs(SFX_DEFS) do
        pcall(function()
            local file = CFG.."/sfx_k1_"..name..".wav"
            if not isfile(file) then
                local n = math.floor(def[1] * RATE)
                local buf = table.create(n, 0)
                for _, p in ipairs(def[2]) do
                    local s0, cnt = math.floor(p[1] * RATE), math.floor(p[2] * RATE)
                    local f0, f1, vol, kind, dec = p[3], p[4], p[5], p[6], p[7]
                    local ph = 0
                    for i = 0, cnt - 1 do
                        local idx = s0 + i + 1
                        if idx > n then break end
                        local tt = i / RATE
                        ph = ph + TAU * (f0 + (f1 - f0) * i / cnt) / RATE
                        local env = math.min(1, tt / 0.004) * math.exp(-tt * dec) * math.min(1, (cnt - i) / (0.008 * RATE))
                        local v
                        if kind == "bell" then
                            v = math.sin(ph) + 0.4 * math.sin(ph * 2.76) * math.exp(-tt * dec * 1.5) + 0.18 * math.sin(ph * 5.4) * math.exp(-tt * dec * 3)
                        elseif kind == "buzz" then
                            v = math.clamp(math.sin(ph) * 2.2, -1, 1) * 0.7
                        else
                            v = math.sin(ph)
                        end
                        buf[idx] = buf[idx] + v * env * vol
                    end
                end
                local bytes = table.create(n)
                for i = 1, n do
                    local v = math.floor(math.clamp(buf[i], -1, 1) * 30000)
                    if v < 0 then v = v + 65536 end
                    bytes[i] = string.char(v % 256, math.floor(v / 256))
                end
                local data = table.concat(bytes)
                writefile(file, "RIFF"..le(36 + #data, 4).."WAVEfmt "..le(16, 4)..le(1, 2)..le(1, 2)..le(RATE, 4)..le(RATE * 2, 4)..le(2, 2)..le(16, 2).."data"..le(#data, 4)..data)
            end
            out[name] = {id = getcustomasset(file), dur = def[1]}
        end)
    end
    return out
end

----------------------------------------------------------------------
-- THEME  (palet hidup: semua elemen beraksen terdaftar, ganti tema = lerp halus)
----------------------------------------------------------------------
local T = {
    ink       = Color3.fromRGB(8, 7, 15),
    panel     = Color3.fromRGB(15, 13, 27),
    card      = Color3.fromRGB(24, 21, 40),
    cardHover = Color3.fromRGB(38, 33, 66),
    cardDown  = Color3.fromRGB(58, 46, 108),
    stroke    = Color3.fromRGB(68, 61, 106),
    text      = Color3.fromRGB(246, 244, 255),
    dim       = Color3.fromRGB(150, 142, 186),
    ok        = Color3.fromRGB(74, 222, 128),
    warn      = Color3.fromRGB(250, 204, 21),
    bad       = Color3.fromRGB(248, 113, 113),
    off       = Color3.fromRGB(52, 50, 74),
    input     = Color3.fromRGB(13, 11, 23),
}
local DIM = T.dim
local WHITE = Color3.new(1, 1, 1)
local VERSION = "5.0"
local SHADOW_ID = "6014261993" -- kosongkan ("") kalau shadow/neon tidak muncul
local FULL = UDim.new(1, 0)

local THEMES = {
    Violet  = {accent = Color3.fromRGB(145, 96, 255), accent2 = Color3.fromRGB(94, 106, 255), cyan = Color3.fromRGB(56, 200, 255), pink = Color3.fromRGB(245, 80, 165)},
    Ocean   = {accent = Color3.fromRGB(40, 160, 255), accent2 = Color3.fromRGB(56, 112, 255), cyan = Color3.fromRGB(45, 230, 205), pink = Color3.fromRGB(120, 130, 255)},
    Crimson = {accent = Color3.fromRGB(255, 70, 100), accent2 = Color3.fromRGB(220, 38, 80), cyan = Color3.fromRGB(255, 160, 70), pink = Color3.fromRGB(255, 90, 170)},
    Emerald = {accent = Color3.fromRGB(45, 212, 150), accent2 = Color3.fromRGB(16, 170, 120), cyan = Color3.fromRGB(60, 190, 255), pink = Color3.fromRGB(190, 235, 80)},
    Sunset  = {accent = Color3.fromRGB(255, 150, 60), accent2 = Color3.fromRGB(240, 70, 90), cyan = Color3.fromRGB(255, 205, 70), pink = Color3.fromRGB(255, 90, 170)},
}
local THEME_ORDER = {"Violet", "Ocean", "Crimson", "Emerald", "Sunset"}
local PAL = {}
for k, v in pairs(THEMES.Violet) do PAL[k] = v end

local themeReg = {}
local function themed(fn) -- fn(PAL) -> false kalau instance sudah hancur (otomatis dibuang)
    themeReg[#themeReg + 1] = fn
    fn(PAL)
end
local function applyThemeAll()
    local i = 1
    while i <= #themeReg do
        local ok, keep = pcall(themeReg[i], PAL)
        if ok and keep ~= false then i = i + 1 else table.remove(themeReg, i) end
    end
end
-- ikat properti warna ke kunci palet ("accent" | "accent2" | "cyan" | "pink")
local function tcol(inst, prop, key)
    themed(function(P)
        if not inst.Parent then return false end
        inst[prop] = P[key]
    end)
end
-- ikat UIGradient ke daftar kunci palet / Color3 (tersebar rata dari 0 sampai 1)
local function tgrad(g, keys)
    themed(function(P)
        if not g.Parent then return false end
        local n = #keys
        local kp = {}
        for i, k in ipairs(keys) do
            local c = (typeof(k) == "Color3") and k or P[k]
            kp[i] = ColorSequenceKeypoint.new((n == 1) and 0 or (i - 1) / (n - 1), c)
        end
        if n == 1 then kp[2] = ColorSequenceKeypoint.new(1, kp[1].Value) end
        g.Color = ColorSequence.new(kp)
    end)
end
-- ikat ke kunci palet kalau string, kalau Color3 langsung pasang
local function pc(inst, prop, key)
    if type(key) == "string" then tcol(inst, prop, key) else inst[prop] = key end
end

local themeTok = 0
local function setTheme(name, instant)
    local to = THEMES[name]
    if not to then return end
    themeTok = themeTok + 1
    local my = themeTok
    if instant then
        for k, v in pairs(to) do PAL[k] = v end
        applyThemeAll()
        return
    end
    local from = {}
    for k in pairs(to) do from[k] = PAL[k] end
    task.spawn(function()
        local t0 = os.clock()
        while my == themeTok do
            local a = math.clamp((os.clock() - t0) / 0.65, 0, 1)
            local e = 1 - (1 - a) ^ 3
            for k, v in pairs(to) do PAL[k] = from[k]:Lerp(v, e) end
            applyThemeAll()
            if a >= 1 then break end
            RunService.RenderStepped:Wait()
        end
    end)
end

----------------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------------
local function new(class, props, parent)
    local o = Instance.new(class)
    if props then for k, v in pairs(props) do o[k] = v end end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r)
    local rad = (typeof(r) == "UDim") and r or UDim.new(0, r or 10)
    return new("UICorner", {CornerRadius = rad}, o)
end

local function stroke(o, color, th, tr)
    return new("UIStroke", {Color = color or T.stroke, Thickness = th or 1, Transparency = tr or 0.5}, o)
end

local function grad(o, c0, c1, rot)
    return new("UIGradient", {Color = ColorSequence.new(c0, c1), Rotation = rot or 0}, o)
end

local function label(parent, props)
    local d = {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }
    for k, v in pairs(props) do d[k] = v end
    return new("TextLabel", d, parent)
end

-- kilau kaca: garis highlight tipis di sisi atas kartu
local function gloss(f)
    local hl = new("Frame", {Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, f)
    new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.78), NumberSequenceKeypoint.new(1, 1)}}, hl)
end

local function tw(o, p, t, s, d)
    return TweenService:Create(o, TweenInfo.new(t or 0.3, s or Enum.EasingStyle.Quint, d or Enum.EasingDirection.Out), p)
end
local function play(o, p, t, s, d) local x = tw(o, p, t, s, d) x:Play() return x end

local function spin(g, secs)
    local t = TweenService:Create(g, TweenInfo.new(secs or 4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = g.Rotation + 360})
    t:Play()
    return t
end

local function copy(s)
    if setclipboard then setclipboard(s) elseif toclipboard then toclipboard(s) end
end

local function toKey(n)
    local ok, v = pcall(function() return Enum.KeyCode[n] end)
    if ok then return v end
    return nil
end

local function textW(txt, size, font)
    local w = #tostring(txt) * (size * 0.6)
    pcall(function() w = TextService:GetTextSize(tostring(txt), size, font or Enum.Font.GothamBold, Vector2.new(800, 40)).X end)
    return w
end

local function hover(b, s, hoverC, downC)
    local bg0 = b.BackgroundColor3
    hoverC = hoverC or T.cardHover
    downC = downC or T.cardDown
    local c0, t0 = nil, nil
    if s then c0, t0 = s.Color, s.Transparency end
    b.MouseEnter:Connect(function()
        sfx("hover")
        play(b, {BackgroundColor3 = hoverC}, 0.18)
        if s then play(s, {Color = PAL.accent, Transparency = 0.25}, 0.18) end
    end)
    b.MouseLeave:Connect(function()
        play(b, {BackgroundColor3 = bg0}, 0.22)
        if s then play(s, {Color = c0, Transparency = t0}, 0.22) end
    end)
    b.MouseButton1Down:Connect(function() play(b, {BackgroundColor3 = downC}, 0.08) end)
    b.MouseButton1Up:Connect(function() play(b, {BackgroundColor3 = hoverC}, 0.2) end)
end

-- drag generik: onBegin(pos) -> state, onMove(dx, dy, state, moved, pos), onEnd(moved, state)
local function track(handle, onBegin, onMove, onEnd)
    handle.InputBegan:Connect(function(input)
        local ut = input.UserInputType
        if ut ~= Enum.UserInputType.MouseButton1 and ut ~= Enum.UserInputType.Touch then return end
        local start = input.Position
        local state = nil
        if onBegin then state = onBegin(start) end
        local moved = false
        local ended = false
        local conn
        conn = UIS.InputChanged:Connect(function(i)
            local it = i.UserInputType
            if it == Enum.UserInputType.MouseMovement or it == Enum.UserInputType.Touch then
                local dx, dy = i.Position.X - start.X, i.Position.Y - start.Y
                if not moved and (math.abs(dx) > 4 or math.abs(dy) > 4) then moved = true end
                if onMove then onMove(dx, dy, state, moved, i.Position) end
            end
        end)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End and not ended then
                ended = true
                if conn then conn:Disconnect() end
                if onEnd then onEnd(moved, state) end
            end
        end)
    end)
end

----------------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------------
function SORU:CreateWindow(C)
    C = C or {}
    local pl = Players.LocalPlayer
    local pg = pl:WaitForChild("PlayerGui")
    local prev = pg:FindFirstChild("SORU_HUB")
    if prev then prev:Destroy() end
    pcall(function() local ob = Lighting:FindFirstChild("SORU_BLUR") if ob then ob:Destroy() end end)

    local gui = new("ScreenGui", {Name = "SORU_HUB", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 100})
    gui.Parent = pg

    local conns = {}
    local function bind(sig, fn) local c = sig:Connect(fn) conns[#conns + 1] = c return c end
    gui.Destroying:Connect(function() for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end end)

    -- CONFIG SYSTEM - DO NOT TOUCH
    local placeId=game.PlaceId local gameId=game.GameId
    local Data={AutoSave=true,Features={}} local Reg={} local curName=tostring(placeId) local loading=false
    local function path(n) return CFGS.."/"..tostring(n)..".json" end
    local function saveN(n) if not n or n=="" then n=curName end n=tostring(n):gsub("^%s*(.-)%s*$","%1") curName=n pcall(function() writefile(path(n),Http:JSONEncode(Data)) end) return n end
    pcall(function()
    if isfile then
    if isfile(path(curName)) then
    local d=Http:JSONDecode(readfile(path(curName))) if d and type(d)=="table" then Data=d if not Data.Features then Data.Features={} end end
    elseif isfile(path("default")) then
    local d=Http:JSONDecode(readfile(path("default"))) if d and type(d)=="table" then Data=d if not Data.Features then Data.Features={} end pcall(function() writefile(path(curName),Http:JSONEncode(Data)) end) end
    end
    end
    end)

    -- tema tersimpan dipakai sebelum UI dibuat
    local curTheme = "Violet"
    do
        local th = Data.Features["UITheme"]
        if type(th) == "string" and THEMES[th] then curTheme = th end
    end
    setTheme(curTheme, true)

    local toggleKey = C.ToggleKey or Enum.KeyCode.RightShift
    do local mk = Data.Features["MenuKey"] if type(mk) == "string" then toggleKey = toKey(mk) or toggleKey end end
    local booting = false

    -- pengaturan tersimpan (semua lewat Dropdown)
    local SND_LEVELS = {Off = 0, Low = 0.3, Medium = 0.6, High = 0.9}
    local sndLevel = Data.Features["UISoundLevel"]
    if SND_LEVELS[sndLevel] == nil then sndLevel = "Medium" end
    local sndVol = SND_LEVELS[sndLevel]
    local PANEL = {Solid = 0, Soft = 0.15, Glass = 0.3, Crystal = 0.45}
    local panelName = Data.Features["UIPanel"]
    if PANEL[panelName] == nil then panelName = "Soft" end
    local curTrans = PANEL[panelName]
    local blurOn = (Data.Features["UIBlurMode"] ~= "Off")
    local ambientOn = (Data.Features["UIAnimMode"] ~= "Off")

    -- SOUND
    local sndBase, sndLast = {}, {}
    pcall(function()
        for name, def in pairs(buildSfx()) do
            local s = Instance.new("Sound")
            s.Name = name s.SoundId = def.id s.Volume = 1 s.Parent = gui
            sndBase[name] = {snd = s, dur = def.dur}
        end
    end)
    sfxFn = function(name, speed, vol)
        local b = sndBase[name]
        if sndVol <= 0 or not b then return end
        local now = os.clock()
        local gap = (name == "hover" or name == "tick") and 0.045 or 0.03
        if sndLast[name] and now - sndLast[name] < gap then return end
        sndLast[name] = now
        local c = b.snd:Clone()
        c.Volume = sndVol * 1.5 * (vol or 1)
        c.PlaybackSpeed = speed or 1
        c.Parent = gui
        c:Play()
        task.delay(b.dur / math.max(speed or 1, 0.3) + 0.4, function() c:Destroy() end)
    end

    local gameName = "Unknown"
    pcall(function() local i = Market:GetProductInfo(placeId) if i and i.Name then gameName = i.Name end end)

    ------------------------------------------------------------------
    -- ROOT + SISTEM SKALA (anti-DPI)
    ------------------------------------------------------------------
    local REF = C.ReferenceSize or Vector2.new(1280, 720)
    local rootScale
    local root = new("Frame", {Name = "Root", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, gui)
    rootScale = new("UIScale", {Scale = 1}, root)

    local userScale = math.clamp(C.Scale or 1, 0.6, 1.5)
    local virt = Vector2.new(REF.X, REF.Y)

    local DEFAULT_SIZE = Vector2.new(640, 420)
    local minSize = Vector2.new(480, 320)
    local maxSize = Vector2.new(960, 640)
    local winSize = DEFAULT_SIZE
    local winPos = nil
    local curPos = Vector2.new(0, 0)

    local function saveUI()
        pcall(function()
            local js = Http:JSONEncode({V = 2, W = math.floor(winSize.X), H = math.floor(winSize.Y), S = userScale})
            writefile(SIZE_FILE, js)
            writefile(SIZE_FILE2, js)
        end)
    end
    local function loadUI()
        if not isfile then return nil end
        local function tryRead(p)
            if isfile(p) then
                local ok, d = pcall(function() return Http:JSONDecode(readfile(p)) end)
                if ok and type(d) == "table" and d.V == 2 and d.W and d.H then return d end
            end
            return nil
        end
        return tryRead(SIZE_FILE) or tryRead(SIZE_FILE2)
    end
    do
        local sv = loadUI()
        if sv then
            winSize = Vector2.new(math.clamp(sv.W, minSize.X, maxSize.X), math.clamp(sv.H, minSize.Y, maxSize.Y))
            userScale = math.clamp(tonumber(sv.S) or userScale, 0.6, 1.5)
        end
    end

    local layoutWin, layoutLauncher

    local function viewport()
        local s = gui.AbsoluteSize
        if s.X < 10 or s.Y < 10 then
            local cam = workspace.CurrentCamera
            s = cam and cam.ViewportSize or Vector2.new(REF.X, REF.Y)
        end
        return s
    end

    local function applyScale()
        local vp = viewport()
        local fit = math.clamp(math.min(vp.X / REF.X, vp.Y / REF.Y), 0.4, 5)
        local s = math.clamp(fit * userScale, 0.3, 6)
        rootScale.Scale = s
        virt = Vector2.new(vp.X / s, vp.Y / s)
        root.Size = UDim2.fromOffset(virt.X, virt.Y)
        if layoutWin then layoutWin(false) end
        if layoutLauncher then layoutLauncher() end
    end

    ------------------------------------------------------------------
    -- NOTIFY  (toast glass)
    ------------------------------------------------------------------
    local TOAST_W = 320
    local toastHolder = new("Frame", {Name = "Toasts", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16), Size = UDim2.new(0, TOAST_W, 1, -32), BackgroundTransparency = 1, ZIndex = 200}, root)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right}, toastHolder)
    local toastN, toasts = 0, {}

    local function notify(title, msg, kind, dur)
        if type(title) == "table" then
            local o = title
            title = o.Title or o.Name
            msg = o.Content or o.Desc or o.Message or o.Text
            kind = o.Type or o.Kind or o.Color
            dur = o.Duration or o.Time
        end
        dur = tonumber(dur) or 3.5
        local col, glyph = PAL.accent, "i"
        if typeof(kind) == "Color3" then
            col = kind
            if kind == T.ok then glyph = "✓" elseif kind == T.bad then glyph = "✕" elseif kind == T.warn then glyph = "!" end
        elseif kind == "success" then col, glyph = T.ok, "✓"
        elseif kind == "error" then col, glyph = T.bad, "✕"
        elseif kind == "warn" or kind == "warning" then col, glyph = T.warn, "!" end

        toastN = toastN + 1
        sfx(glyph == "✕" and "error" or "notify")

        -- batasi maksimal 5 toast sekaligus
        if #toasts >= 5 then
            local oldest = toasts[1]
            if oldest then oldest.Close() end
        end

        local msgText = tostring(msg or "")
        local textX = 62
        local textWd = TOAST_W - textX - 18
        local mh = 14
        pcall(function() mh = TextService:GetTextSize(msgText, 11, Enum.Font.Gotham, Vector2.new(textWd, 200)).Y end)
        mh = math.clamp(mh, 14, 44)
        local H = math.max(62, 31 + mh + 16)

        local wrap = new("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = -toastN, ZIndex = 201}, toastHolder)
        local f = new("CanvasGroup", {Size = UDim2.new(1, 0, 0, H), Position = UDim2.fromOffset(TOAST_W + 40, 0), BackgroundColor3 = Color3.fromRGB(17, 15, 30), BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 202}, wrap)
        corner(f, 16)
        local fs = stroke(f, col, 1.2, 0.55)
        local tintF = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 1}, f)
        new("UIGradient", {Transparency = NumberSequence.new(0.8, 1)}, tintF)
        new("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 2}, f)

        local icg = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 31, 0.5, 0), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = col, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 3}, f)
        corner(icg, FULL)
        local ic = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 31, 0.5, 0), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = col, BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 4}, f)
        corner(ic, FULL) stroke(ic, col, 1.2, 0.4)
        local icS = new("UIScale", {Scale = 0}, ic)
        label(ic, {Text = glyph, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = col, TextTruncate = Enum.TextTruncate.None, ZIndex = 5})
        label(f, {Text = tostring(title or ""), Position = UDim2.fromOffset(textX, 12), Size = UDim2.fromOffset(textWd, 16), Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 4})
        label(f, {Text = msgText, Position = UDim2.fromOffset(textX, 31), Size = UDim2.fromOffset(textWd, mh), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = DIM, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 4})

        local progBg = new("Frame", {Position = UDim2.new(0, 14, 1, -6), Size = UDim2.new(1, -28, 0, 2), BackgroundColor3 = col, BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 3}, f)
        corner(progBg, FULL)
        local prog = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = col, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 4}, progBg)
        corner(prog, FULL)

        local shine = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 56, 2.4, 0), Position = UDim2.new(-0.2, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6}, f)
        new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.86), NumberSequenceKeypoint.new(1, 1)}}, shine)
        local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5}, ic)
        corner(ring, FULL)
        local ringS = stroke(ring, col, 1.5, 0.2)

        local gone = false
        local handle = {}
        local ptw = tw(prog, {Size = UDim2.fromScale(0, 1)}, dur, Enum.EasingStyle.Linear)
        local function leave()
            if gone then return end
            gone = true
            for i, t in ipairs(toasts) do if t == handle then table.remove(toasts, i) break end end
            pcall(function() ptw:Cancel() end)
            if not f.Parent then return end
            play(f, {Position = UDim2.fromOffset(TOAST_W + 40, 0), GroupTransparency = 1}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            task.delay(0.22, function()
                if wrap.Parent then play(wrap, {Size = UDim2.new(1, 0, 0, 0)}, 0.32, Enum.EasingStyle.Quint) end
            end)
            task.delay(0.65, function() if wrap.Parent then wrap:Destroy() end end)
        end
        handle.Close = leave
        toasts[#toasts + 1] = handle

        local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 10}, f)
        hit.MouseButton1Click:Connect(function() sfx("click") leave() end)
        hit.MouseEnter:Connect(function()
            if gone then return end
            pcall(function() ptw:Pause() end)
            play(fs, {Transparency = 0.15}, 0.2)
        end)
        hit.MouseLeave:Connect(function()
            if gone then return end
            pcall(function() ptw:Play() end)
            play(fs, {Transparency = 0.55}, 0.25)
        end)

        -- masuk
        play(wrap, {Size = UDim2.new(1, 0, 0, H)}, 0.45, Enum.EasingStyle.Quint)
        play(f, {Position = UDim2.fromOffset(0, 0), GroupTransparency = 0}, 0.6, Enum.EasingStyle.Quint)
        task.delay(0.2, function() if ic.Parent then play(icS, {Scale = 1}, 0.55, Enum.EasingStyle.Back) end end)
        task.delay(0.3, function()
            if shine.Parent then play(shine, {Position = UDim2.new(1.2, 0, 0.5, 0)}, 0.75, Enum.EasingStyle.Quad) end
            if ring.Parent then play(ring, {Size = UDim2.fromScale(2.2, 2.2)}, 0.8) play(ringS, {Transparency = 1}, 0.8) end
        end)
        ptw.Completed:Connect(function(state)
            if state == Enum.PlaybackState.Completed then leave() end
        end)
        ptw:Play()
        return handle
    end

    local function showNotSupportedBadge(kickAfter)
        local badge = new("CanvasGroup", {Size = UDim2.fromOffset(360, 72), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -100), BackgroundColor3 = Color3.fromRGB(26, 22, 40), BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 300}, root)
        corner(badge, 16) stroke(badge, T.bad, 1.2, 0.2)
        new("ImageLabel", {Size = UDim2.fromOffset(42, 42), Position = UDim2.new(0, 16, 0.5, -21), BackgroundTransparency = 1, Image = ICON}, badge)
        label(badge, {Text = "Game not supported", Position = UDim2.fromOffset(70, 16), Size = UDim2.new(1, -80, 0, 18), Font = Enum.Font.GothamBold, TextSize = 14})
        label(badge, {Text = "Place ID "..tostring(game.PlaceId), Position = UDim2.fromOffset(70, 37), Size = UDim2.new(1, -80, 0, 14), TextSize = 11, TextColor3 = DIM})
        play(badge, {GroupTransparency = 0}, 0.25)
        play(badge, {Position = UDim2.new(0.5, 0, 0, 24)}, 0.55, Enum.EasingStyle.Back)
        task.wait(5)
        play(badge, {Position = UDim2.new(0.5, 0, 0, -100)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        play(badge, {GroupTransparency = 1}, 0.25)
        task.wait(0.35)
        badge:Destroy()
        if kickAfter then pcall(function() pl:Kick("NOT SUPPORTED - SORU HUB\n"..game.PlaceId) end) end
    end

    ------------------------------------------------------------------
    -- STATE + ENTRANCE
    ------------------------------------------------------------------
    local isOpen = false
    local openTok = 0
    local transTargets = {}
    local function regTrans(inst, off)
        off = off or 0
        transTargets[#transTargets + 1] = {inst = inst, off = off}
        inst.BackgroundTransparency = math.clamp(curTrans + off, 0, 1)
    end

    local tabs = {}
    local cur = "Dashboard"
    local entranceLists = setmetatable({}, {__mode = "k"})
    local function entrance(scroll)
        local list = entranceLists[scroll]
        if not list then return end
        for _, body in ipairs(list) do
            if body.Parent then body.Position = UDim2.fromOffset(-26, 0) end
        end
        for i, body in ipairs(list) do
            task.delay(math.min(i - 1, 14) * 0.04, function()
                if body.Parent then play(body, {Position = UDim2.fromOffset(0, 0)}, 0.65, Enum.EasingStyle.Quint) end
            end)
        end
    end

    ------------------------------------------------------------------
    -- WINDOW SHELL
    ------------------------------------------------------------------
    local shell = new("Frame", {Name = "Shell", BackgroundTransparency = 1, Size = UDim2.fromOffset(winSize.X, winSize.Y), Visible = false, ZIndex = 10}, root)
    local shadow, neon = nil, nil
    if SHADOW_ID ~= "" then
        shadow = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.new(1, 64, 1, 64), BackgroundTransparency = 1, Image = "rbxassetid://"..SHADOW_ID, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 1}, shell)
        -- neon: bayangan aksen yang "bernapas"
        neon = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 30, 1, 30), BackgroundTransparency = 1, Image = "rbxassetid://"..SHADOW_ID, ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 1}, shell)
        tcol(neon, "ImageColor3", "accent")
        TweenService:Create(neon, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.new(1, 58, 1, 58)}):Play()
    end

    local win = new("CanvasGroup", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.ink, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 2}, shell)
    corner(win, 20)
    local winStroke = stroke(win, WHITE, 1.6, 0.35)
    local wsGrad = new("UIGradient", {}, winStroke)
    tgrad(wsGrad, {"accent", "cyan", "pink", "accent"})
    spin(wsGrad, 8)
    local winScale = new("UIScale", {Scale = 0.12}, win)

    local tint = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, win)
    new("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(19, 16, 34), Color3.fromRGB(7, 6, 13)), Rotation = 125}, tint)
    local bgImg = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = BG, ImageTransparency = 0.82, ScaleType = Enum.ScaleType.Crop, ZIndex = 2}, win)
    local bgS = new("UIScale", {Scale = 1.05}, bgImg)
    local topGlow = new("Frame", {Size = UDim2.new(1, 0, 0, 170), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, win)
    tgrad(new("UIGradient", {Transparency = NumberSequence.new(0.8, 1), Rotation = 90}, topGlow), {"accent", "accent2"})

    -- aurora orb + partikel
    local ambient = new("Frame", {Name = "Ambient", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4, Visible = ambientOn}, win)
    do
        local function orb(key, size, px, py, dx, dy, secs)
            local o = new("Frame", {Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(px, py), BackgroundTransparency = 1, ZIndex = 4}, ambient)
            local layers = 6
            for i = 1, layers do
                local s = 1 - (i - 1) / layers * 0.9
                local c = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s), BackgroundTransparency = 0.94, BorderSizePixel = 0, ZIndex = 4}, o)
                corner(c, FULL)
                tcol(c, "BackgroundColor3", key)
            end
            TweenService:Create(o, TweenInfo.new(secs, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.fromScale(px + dx, py + dy)}):Play()
        end
        orb("accent", 340, 0.15, 0.2, 0.25, 0.15, 9)
        orb("cyan", 300, 0.9, 0.85, -0.22, -0.2, 11)
        orb("pink", 240, 0.75, 0.05, -0.3, 0.3, 13)
        for i = 1, 10 do
            local p = new("Frame", {Size = UDim2.fromOffset(3, 3), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4}, ambient)
            corner(p, FULL)
            if i % 3 == 0 then tcol(p, "BackgroundColor3", "cyan") elseif i % 3 == 1 then tcol(p, "BackgroundColor3", "accent") end
            task.spawn(function()
                task.wait(i * 0.5)
                while gui.Parent do
                    if isOpen and ambientOn then
                        local dur = math.random(70, 130) / 10
                        local x = math.random(5, 95) / 100
                        local sz = math.random(2, 4)
                        p.Size = UDim2.fromOffset(sz, sz)
                        p.Position = UDim2.fromScale(x, 1.03)
                        p.BackgroundTransparency = 1
                        play(p, {Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.2, -0.05)}, dur, Enum.EasingStyle.Linear)
                        play(p, {BackgroundTransparency = 0.45}, dur * 0.3, Enum.EasingStyle.Sine)
                        task.wait(dur * 0.7)
                        play(p, {BackgroundTransparency = 1}, dur * 0.3, Enum.EasingStyle.Sine)
                        task.wait(dur * 0.3)
                    else
                        task.wait(0.6)
                    end
                end
            end)
        end
    end

    local accentLine = new("Frame", {Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 15}, win)
    local ag = new("UIGradient", {Offset = Vector2.new(-1, 0)}, accentLine)
    tgrad(ag, {"accent", "cyan", "accent"})
    TweenService:Create(ag, TweenInfo.new(3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(1, 0)}):Play()

    local zoomFixed = Data.Features and type(Data.Features["BGZoom"]) == "number"
    if zoomFixed then
        bgS.Scale = Data.Features["BGZoom"]
    else
        TweenService:Create(bgS, TweenInfo.new(14, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.13}):Play()
    end

    local function applyTrans(t)
        t = math.clamp(t, 0, 0.7)
        curTrans = t
        for _, e in ipairs(transTargets) do
            if e.inst and e.inst.Parent then play(e.inst, {BackgroundTransparency = math.clamp(t + e.off, 0, 1)}, 0.35) end
        end
        play(bgImg, {ImageTransparency = math.clamp(0.9 - t * 0.8, 0.3, 1)}, 0.35)
    end

    ------------------------------------------------------------------
    -- RIPPLE + SPOTLIGHT
    ------------------------------------------------------------------
    -- spotlight: cahaya lembut yang mengikuti kursor di dalam kartu
    local function spotlight(f, src)
        src = src or f
        local box, layers
        local function build()
            box = new("Frame", {Name = "Spot", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(180, 180), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0}, f)
            layers = {}
            for i = 1, 4 do
                local z = 1 - (i - 1) * 0.22
                local c = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(z, z), BackgroundColor3 = (i % 2 == 0) and PAL.cyan or PAL.accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0}, box)
                corner(c, FULL)
                layers[i] = c
            end
        end
        local function follow()
            if not box then return end
            local m = UIS:GetMouseLocation()
            local s = math.max(rootScale.Scale * winScale.Scale, 0.01)
            local ap = f.AbsolutePosition
            box.Position = UDim2.fromOffset((m.X - ap.X) / s, (m.Y - ap.Y) / s)
        end
        src.MouseEnter:Connect(function()
            if not box then build() end
            follow()
            for i, c in ipairs(layers) do
                c.BackgroundColor3 = (i % 2 == 0) and PAL.cyan or PAL.accent
                play(c, {BackgroundTransparency = 0.955}, 0.3)
            end
        end)
        src.MouseMoved:Connect(follow)
        src.MouseLeave:Connect(function()
            if not layers then return end
            for _, c in ipairs(layers) do play(c, {BackgroundTransparency = 1}, 0.35) end
        end)
    end

    local function ripple(btn, col)
        btn.ClipsDescendants = true
        btn.MouseButton1Down:Connect(function()
            pcall(function()
                local m = UIS:GetMouseLocation()
                local s = math.max(rootScale.Scale * winScale.Scale, 0.01)
                local ap, asz = btn.AbsolutePosition, btn.AbsoluteSize
                local w, h = asz.X / s, asz.Y / s
                local x = math.clamp((m.X - ap.X) / s, 0, w)
                local y = math.clamp((m.Y - ap.Y) / s, 0, h)
                local r = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = col or WHITE, BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 0}, btn)
                corner(r, FULL)
                local d = math.max(w, h) * 2.4
                play(r, {Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1}, 0.6, Enum.EasingStyle.Quint)
                task.delay(0.65, function() r:Destroy() end)
            end)
        end)
    end

    ------------------------------------------------------------------
    -- LAYOUT WINDOW
    ------------------------------------------------------------------
    local function effSize()
        return Vector2.new(math.min(winSize.X, virt.X - 16), math.min(winSize.Y, virt.Y - 16))
    end
    layoutWin = function(animate)
        local sz = effSize()
        local x, y
        if winPos then x, y = winPos.X, winPos.Y else x, y = (virt.X - sz.X) / 2, (virt.Y - sz.Y) / 2 end
        x = math.clamp(x, 8, math.max(8, virt.X - sz.X - 8))
        y = math.clamp(y, 8, math.max(8, virt.Y - sz.Y - 8))
        if winPos then winPos = Vector2.new(x, y) end
        curPos = Vector2.new(x, y)
        if animate then
            play(shell, {Size = UDim2.fromOffset(sz.X, sz.Y), Position = UDim2.fromOffset(x, y)}, 0.45)
        else
            shell.Size = UDim2.fromOffset(sz.X, sz.Y)
            shell.Position = UDim2.fromOffset(x, y)
        end
    end

    ------------------------------------------------------------------
    -- LAUNCHER
    ------------------------------------------------------------------
    local LAUNCH = 54
    local launchPos = nil
    local launcher = new("Frame", {Name = "Launcher", Size = UDim2.fromOffset(LAUNCH, LAUNCH), BackgroundColor3 = Color3.fromRGB(18, 16, 30), BorderSizePixel = 0, Active = true, ZIndex = 99}, root)
    corner(launcher, 18)
    local pulse = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(LAUNCH, LAUNCH), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 98, Visible = true}, launcher)
    local lIcon = new("ImageLabel", {Size = UDim2.fromOffset(32, 32), Position = UDim2.new(0.5, -16, 0.5, -16), BackgroundTransparency = 1, Image = ICON, ScaleType = Enum.ScaleType.Fit, ZIndex = 100}, launcher)
    local lScale = new("UIScale", {Scale = 1}, launcher)
    do
        local lStroke = stroke(launcher, WHITE, 1.8, 0)
        local lGrad = new("UIGradient", {}, lStroke)
        tgrad(lGrad, {"accent", "cyan", "accent"})
        spin(lGrad, 4)
        corner(pulse, 20)
        local pulseS = stroke(pulse, PAL.accent, 2, 0.2)
        tcol(pulseS, "Color", "accent")
        local pInfo = TweenInfo.new(2.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, -1, false, 0.3)
        TweenService:Create(pulse, pInfo, {Size = UDim2.fromOffset(LAUNCH + 34, LAUNCH + 34)}):Play()
        TweenService:Create(pulseS, pInfo, {Transparency = 1}):Play()
        local iScale = new("UIScale", {Scale = 1}, lIcon)
        TweenService:Create(iScale, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.1}):Play()
        -- dua titik kecil mengorbit launcher
        for k = 1, 2 do
            local oh = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(LAUNCH + 12, LAUNCH + 12), BackgroundTransparency = 1, BorderSizePixel = 0, Rotation = (k - 1) * 180, ZIndex = 101}, launcher)
            local od = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, ZIndex = 101}, oh)
            corner(od, FULL)
            tcol(od, "BackgroundColor3", (k == 1) and "cyan" or "pink")
            spin(oh, 5)
        end
    end
    layoutLauncher = function()
        if not launchPos then launchPos = Vector2.new(14, math.floor(virt.Y / 2 - LAUNCH / 2)) end
        local x = math.clamp(launchPos.X, 4, math.max(4, virt.X - LAUNCH - 4))
        local y = math.clamp(launchPos.Y, 4, math.max(4, virt.Y - LAUNCH - 4))
        launchPos = Vector2.new(x, y)
        launcher.Position = UDim2.fromOffset(x, y)
    end

    ------------------------------------------------------------------
    -- BLUR + OPEN / CLOSE (genie)
    ------------------------------------------------------------------
    local blur = nil
    pcall(function()
        blur = Instance.new("BlurEffect")
        blur.Name = "SORU_BLUR"
        blur.Size = 0
        blur.Parent = Lighting
    end)
    local function updateBlur()
        if blur and blur.Parent then play(blur, {Size = (isOpen and blurOn) and 12 or 0}, 0.5) end
    end
    gui.Destroying:Connect(function() if blur then pcall(function() blur:Destroy() end) end end)

    local function launcherOffset()
        local sz = effSize()
        local sc = Vector2.new(curPos.X + sz.X / 2, curPos.Y + sz.Y / 2)
        local lp = launchPos or Vector2.new(14, 14)
        return Vector2.new(lp.X + LAUNCH / 2 - sc.X, lp.Y + LAUNCH / 2 - sc.Y)
    end

    local openFx = nil -- diisi setelah sidebar + konten dibuat
    local function openA(quiet)
        if isOpen then return end
        isOpen = true
        openTok = openTok + 1
        if not quiet then sfx("open") end
        layoutWin(false)
        local off = launcherOffset()
        shell.Visible = true
        pulse.Visible = false
        win.Position = UDim2.new(0.5, off.X, 0.5, off.Y)
        winScale.Scale = 0.12
        win.GroupTransparency = 1
        play(win, {Position = UDim2.fromScale(0.5, 0.5)}, 0.6, Enum.EasingStyle.Quint)
        play(winScale, {Scale = 1}, 0.7, Enum.EasingStyle.Back)
        play(win, {GroupTransparency = 0}, 0.35)
        if shadow then play(shadow, {ImageTransparency = 0.55}, 0.5) end
        if neon then play(neon, {ImageTransparency = 0.72}, 0.7) end
        if openFx then openFx() end
        updateBlur()
        local t = tabs[cur]
        if t then task.delay(0.2, function() if isOpen then entrance(t.scroll) end end) end
    end
    local ddClose = nil -- fungsi penutup dropdown yang sedang terbuka (hanya satu pada satu waktu)
    local function closeA()
        if not isOpen then return end
        isOpen = false
        sfx("close")
        if ddClose then ddClose() end
        local tok = openTok
        local off = launcherOffset()
        pulse.Visible = true
        play(win, {Position = UDim2.new(0.5, off.X, 0.5, off.Y)}, 0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        play(winScale, {Scale = 0.12}, 0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        play(win, {GroupTransparency = 1}, 0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        if shadow then play(shadow, {ImageTransparency = 1}, 0.25) end
        if neon then play(neon, {ImageTransparency = 1}, 0.28) end
        updateBlur()
        task.delay(0.48, function() if not isOpen and tok == openTok then shell.Visible = false end end)
    end
    local function toggleWin() if booting then return end if isOpen then closeA() else openA() end end

    launcher.MouseEnter:Connect(function() play(lScale, {Scale = 1.07}, 0.2) end)
    launcher.MouseLeave:Connect(function() play(lScale, {Scale = 1}, 0.2) end)
    track(launcher,
        function() play(lScale, {Scale = 0.9}, 0.12) return launchPos end,
        function(dx, dy, st, moved)
            if moved and st then
                local s = rootScale.Scale
                launchPos = Vector2.new(st.X + dx / s, st.Y + dy / s)
                layoutLauncher()
            end
        end,
        function(moved)
            play(lScale, {Scale = 1}, 0.4, Enum.EasingStyle.Back)
            if not moved then toggleWin() end
        end)

    ------------------------------------------------------------------
    -- HEADER
    ------------------------------------------------------------------
    local tb = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Active = true, ZIndex = 10}, win)
    local chipL, cdot, titleL
    do
        local logo = new("Frame", {Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, 14, 0.5, -18), BackgroundColor3 = Color3.fromRGB(24, 22, 40), BorderSizePixel = 0}, tb)
        corner(logo, 12)
        local logoS = stroke(logo, WHITE, 1.4, 0.2)
        local logoG = new("UIGradient", {}, logoS)
        tgrad(logoG, {"accent", "cyan", "accent"})
        spin(logoG, 5)
        new("ImageLabel", {Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, Image = ICON}, logo)
        titleL = label(tb, {Text = C.Title or "SORU HUB", Position = UDim2.fromOffset(60, 10), Size = UDim2.new(1, -250, 0, 18), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = WHITE})
        local tg = new("UIGradient", {Offset = Vector2.new(-1, 0)}, titleL)
        tgrad(tg, {T.text, T.text, "cyan", T.text, T.text})
        TweenService:Create(tg, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 2.4), {Offset = Vector2.new(1, 0)}):Play()
        label(tb, {Text = "v"..VERSION.."  •  "..gameName, Position = UDim2.fromOffset(60, 29), Size = UDim2.new(1, -250, 0, 14), TextSize = 10, TextColor3 = DIM})
        local sepL = new("Frame", {Position = UDim2.fromOffset(10, 56), Size = UDim2.new(1, -20, 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 10}, win)
        local sg = new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 1)}}, sepL)
        tgrad(sg, {"accent", "cyan"})

        -- chip FPS
        local chip = new("Frame", {Size = UDim2.fromOffset(78, 22), Position = UDim2.new(1, -170, 0.5, -11), BackgroundColor3 = Color3.fromRGB(28, 25, 44), BorderSizePixel = 0, ZIndex = 11}, tb)
        corner(chip, FULL) stroke(chip, T.stroke, 1, 0.6)
        cdot = new("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(10, 8), BackgroundColor3 = T.ok, BorderSizePixel = 0, ZIndex = 12}, chip)
        corner(cdot, FULL)
        TweenService:Create(cdot, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.7}):Play()
        chipL = label(chip, {Text = "-- fps", Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -26, 1, 0), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = DIM, ZIndex = 12})
    end

    local function hbtn(xOff, txt, col, hoverC)
        local b = new("TextButton", {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, xOff, 0.5, -15), Text = txt, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = col or DIM, BackgroundColor3 = Color3.fromRGB(28, 25, 44), AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 11}, tb)
        corner(b, FULL)
        hover(b, nil, hoverC or Color3.fromRGB(42, 38, 66), T.cardDown)
        return b
    end
    local minB = hbtn(-78, "–")
    local xB = hbtn(-42, "✕", T.bad, Color3.fromRGB(82, 36, 50))

    ------------------------------------------------------------------
    -- SIDEBAR + CONTENT
    ------------------------------------------------------------------
    local SIDE_W = 150
    local TAB_H, TAB_P = 40, 46
    local side = new("Frame", {Position = UDim2.fromOffset(10, 58), Size = UDim2.new(0, SIDE_W, 1, -68), BackgroundColor3 = T.panel, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 5}, win)
    corner(side, 16) stroke(side, T.stroke, 1, 0.65) regTrans(side, 0.05)
    local tabList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -52), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.fromOffset(0, 0), ZIndex = 6}, side)

    -- profil mini di sidebar
    do
        local foot = new("Frame", {Position = UDim2.new(0, 6, 1, -44), Size = UDim2.new(1, -12, 0, 38), BackgroundColor3 = T.card, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 6}, side)
        corner(foot, 12) regTrans(foot, 0.1)
        local fav = new("ImageLabel", {Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(5, 5), BackgroundColor3 = T.off, BorderSizePixel = 0, ZIndex = 7}, foot)
        corner(fav, FULL)
        task.spawn(function()
            local ok, img = pcall(function() return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
            if ok and fav.Parent then fav.Image = img end
        end)
        label(foot, {Text = pl.DisplayName, Position = UDim2.fromOffset(40, 5), Size = UDim2.new(1, -46, 0, 14), Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 7})
        label(foot, {Text = "SORU HUB v"..VERSION, Position = UDim2.fromOffset(40, 20), Size = UDim2.new(1, -46, 0, 12), TextSize = 9, TextColor3 = Color3.fromRGB(110, 104, 145), ZIndex = 7})
    end

    local pill = new("Frame", {Size = UDim2.new(1, -12, 0, TAB_H), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = WHITE, BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 5}, tabList)
    corner(pill, 12)
    do
        local ps = stroke(pill, PAL.accent, 1, 0.45)
        tcol(ps, "Color", "accent")
        tgrad(new("UIGradient", {}, pill), {"accent", "accent2"})
        local ind = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 18), BackgroundColor3 = WHITE, BorderSizePixel = 0}, pill)
        corner(ind, FULL)
        tgrad(new("UIGradient", {Rotation = 90}, ind), {"cyan", "accent"})
    end

    local content = new("Frame", {Position = UDim2.new(0, SIDE_W + 20, 0, 58), Size = UDim2.new(1, -(SIDE_W + 30), 1, -68), BackgroundColor3 = T.panel, BackgroundTransparency = 0.25, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 5}, win)
    corner(content, 16) stroke(content, T.stroke, 1, 0.7) regTrans(content, 0.1)

    local rh = new("Frame", {Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -28, 1, -28), BackgroundTransparency = 1, Active = true, ZIndex = 30}, win)
    local rhL = label(rh, {Text = "⋰", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(-4, -2), TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Bottom, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(100, 94, 130)})
    rh.MouseEnter:Connect(function() play(rhL, {TextColor3 = PAL.accent}, 0.15) end)
    rh.MouseLeave:Connect(function() play(rhL, {TextColor3 = Color3.fromRGB(100, 94, 130)}, 0.2) end)

    -- animasi masuk: header turun, sidebar + konten menyusul, glint menyapu window
    openFx = function()
        side.Position = UDim2.fromOffset(-30, 58)
        content.Position = UDim2.new(0, SIDE_W + 50, 0, 58)
        tb.Position = UDim2.fromOffset(0, -16)
        play(tb, {Position = UDim2.fromOffset(0, 0)}, 0.7, Enum.EasingStyle.Quint)
        play(side, {Position = UDim2.fromOffset(10, 58)}, 0.8, Enum.EasingStyle.Quint)
        task.delay(0.08, function() play(content, {Position = UDim2.new(0, SIDE_W + 20, 0, 58)}, 0.8, Enum.EasingStyle.Quint) end)
        local gl = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 110, 2.4, 0), Position = UDim2.new(-0.3, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 40}, win)
        new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.88), NumberSequenceKeypoint.new(1, 1)}}, gl)
        task.delay(0.25, function() play(gl, {Position = UDim2.new(1.3, 0, 0.5, 0)}, 0.95, Enum.EasingStyle.Quad) end)
        task.delay(1.4, function() gl:Destroy() end)
    end

    -- drag window: miring halus mengikuti arah gerak, lalu memantul balik
    local dragging, lastDX = false, 0
    bind(RunService.RenderStepped, function()
        if dragging and win.Rotation ~= 0 then win.Rotation = win.Rotation * 0.9 end
    end)
    track(tb,
        function()
            winPos = curPos
            dragging, lastDX = true, 0
            if isOpen then play(winScale, {Scale = 1.015}, 0.18) end
            return curPos
        end,
        function(dx, dy, st, moved)
            if moved and st then
                local s = rootScale.Scale
                winPos = Vector2.new(st.X + dx / s, st.Y + dy / s)
                layoutWin(false)
                local vx = (dx - lastDX) / s
                lastDX = dx
                win.Rotation = math.clamp(win.Rotation + vx * 0.12, -2.4, 2.4)
            end
        end,
        function()
            dragging = false
            if isOpen then
                play(winScale, {Scale = 1}, 0.45, Enum.EasingStyle.Back)
                play(win, {Rotation = 0}, 0.8, Enum.EasingStyle.Elastic)
            end
        end)
    track(rh,
        function() winPos = curPos return effSize() end,
        function(dx, dy, st, moved)
            if not st then return end
            local s = rootScale.Scale
            local mxW = math.max(minSize.X, math.min(maxSize.X, virt.X - 8 - curPos.X))
            local mxH = math.max(minSize.Y, math.min(maxSize.Y, virt.Y - 8 - curPos.Y))
            winSize = Vector2.new(math.clamp(st.X + dx / s, minSize.X, mxW), math.clamp(st.Y + dy / s, minSize.Y, mxH))
            layoutWin(false)
        end,
        function(moved) if moved then saveUI() end end)

    ------------------------------------------------------------------
    -- TAB SYSTEM
    ------------------------------------------------------------------
    local Window = {Tabs = tabs}
    local tabOrder = 0
    local pillTok = 0

    -- pill "liquid": melar ke tujuan dulu, lalu mengerut ke ukuran normal
    local function movePill(y)
        pillTok = pillTok + 1
        local tok = pillTok
        local y0 = pill.Position.Y.Offset
        local top = math.min(y0, y)
        local span = math.abs(y - y0) + TAB_H
        play(pill, {Position = UDim2.fromOffset(6, top), Size = UDim2.new(1, -12, 0, span)}, 0.2, Enum.EasingStyle.Quad)
        task.delay(0.18, function()
            if tok ~= pillTok then return end
            play(pill, {Position = UDim2.fromOffset(6, y), Size = UDim2.new(1, -12, 0, TAB_H)}, 0.42, Enum.EasingStyle.Back)
        end)
    end

    local function switchTab(n)
        if cur == n or not tabs[n] then return end
        if ddClose then ddClose() end
        local oldName = cur
        local old = tabs[oldName]
        local ne = tabs[n]
        local dir = (ne.index > (old and old.index or 0)) and 1 or -1
        cur = n
        sfx("tab")
        if old then
            play(old.label, {TextColor3 = DIM}, 0.2)
            play(old.badge, {BackgroundTransparency = 0.82}, 0.2)
            play(old.frame, {GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -14 * dir)}, 0.22)
            play(old.zoom, {Scale = 0.97}, 0.22)
            task.delay(0.23, function() if cur ~= oldName then old.frame.Visible = false end end)
        end
        ne.frame.Visible = true
        ne.frame.GroupTransparency = 1
        ne.frame.Position = UDim2.new(0.5, 0, 0.5, 24 * dir)
        ne.zoom.Scale = 1.03
        play(ne.frame, {GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)}, 0.55, Enum.EasingStyle.Quint)
        play(ne.zoom, {Scale = 1}, 0.6, Enum.EasingStyle.Quint)
        entrance(ne.scroll)
        play(ne.label, {TextColor3 = T.text}, 0.2)
        play(ne.badge, {BackgroundTransparency = 0}, 0.2)
        play(ne.btn, {BackgroundTransparency = 1}, 0.1)
        ne.badge.Rotation = -28
        play(ne.badge, {Rotation = 0}, 0.7, Enum.EasingStyle.Elastic)
        movePill(ne.y)
    end

    local function createTab(name, active, icon)
        tabOrder = tabOrder + 1
        local idx = tabOrder
        local y = 6 + (idx - 1) * TAB_P
        local b = new("TextButton", {Name = name, Size = UDim2.new(1, -12, 0, TAB_H), Position = UDim2.fromOffset(6, y), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 6}, tabList)
        corner(b, 12)
        tcol(b, "BackgroundColor3", "accent")
        local badge = new("Frame", {Size = UDim2.fromOffset(26, 26), Position = UDim2.new(0, 8, 0.5, -13), BackgroundColor3 = WHITE, BackgroundTransparency = active and 0 or 0.82, BorderSizePixel = 0, ZIndex = 7}, b)
        corner(badge, 9)
        tgrad(new("UIGradient", {Rotation = 45}, badge), {"accent", "accent2"})
        label(badge, {Text = icon and tostring(icon) or string.upper(string.sub(name, 1, 1)), Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 8, TextTruncate = Enum.TextTruncate.None})
        local tx = label(b, {Text = name, Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -48, 1, 0), Font = Enum.Font.GothamSemibold, TextColor3 = active and T.text or DIM, ZIndex = 7})
        tabList.CanvasSize = UDim2.fromOffset(0, 6 + idx * TAB_P)

        local page = new("CanvasGroup", {Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = active, GroupTransparency = active and 0 or 1, ZIndex = 6}, content)
        local zoom = new("UIScale", {Scale = 1}, page)
        local scroll = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageTransparency = 0.3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 7}, page)
        tcol(scroll, "ScrollBarImageColor3", "accent")
        new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
        new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12)}, scroll)

        tabs[name] = {btn = b, frame = page, scroll = scroll, label = tx, badge = badge, index = idx, y = y, zoom = zoom}
        b.MouseEnter:Connect(function()
            if cur ~= name then
                play(b, {BackgroundTransparency = 0.9}, 0.15)
                play(tx, {Position = UDim2.fromOffset(47, 0)}, 0.22)
                badge.Rotation = -16
                play(badge, {Rotation = 0}, 0.6, Enum.EasingStyle.Elastic)
            end
        end)
        b.MouseLeave:Connect(function()
            play(b, {BackgroundTransparency = 1}, 0.2)
            play(tx, {Position = UDim2.fromOffset(42, 0)}, 0.26)
        end)
        b.MouseButton1Click:Connect(function() switchTab(name) end)
        return scroll
    end

    ------------------------------------------------------------------
    -- KOMPONEN  (hanya Dropdown)
    ------------------------------------------------------------------
    local function buildComponents(scroll)
        local K = {}
        local order = 0
        local list = {}
        entranceLists[scroll] = list
        local function nextOrder() order = order + 1 return order end

        local function holder(h)
            return new("Frame", {Name = "Holder", Size = UDim2.new(1, 0, 0, h or 0), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder()}, scroll)
        end
        local function enter(body) list[#list + 1] = body end
        K._holder, K._enter = holder, enter

        -- kartu kaca dasar
        local function card(h)
            local hf = holder(h)
            local f = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.card, BackgroundTransparency = 0.15, BorderSizePixel = 0, ClipsDescendants = true}, hf)
            corner(f, 14)
            local s = stroke(f, T.stroke, 1, 0.5)
            new("UIGradient", {Transparency = NumberSequence.new(0, 0.6), Rotation = 90}, s)
            grad(f, WHITE, Color3.fromRGB(196, 192, 222), 90)
            gloss(f)
            regTrans(f, 0)
            enter(f)
            return f, s, hf
        end
        K._card = card

        -- kotak input kecil (dipakai search dropdown)
        local function inputBox(parent, props)
            local wrap = new("Frame", {BackgroundColor3 = T.input, BorderSizePixel = 0, ClipsDescendants = true}, parent)
            for k, v in pairs(props.wrap or {}) do wrap[k] = v end
            corner(wrap, 9)
            local ws = stroke(wrap, T.stroke, 1, 0.4)
            local box = new("TextBox", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", PlaceholderText = props.placeholder or "", PlaceholderColor3 = Color3.fromRGB(100, 94, 130), TextColor3 = T.text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ClipsDescendants = true}, wrap)
            local ul = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0}, wrap)
            tgrad(new("UIGradient", {}, ul), {"accent", "cyan"})
            box.Focused:Connect(function()
                sfx("tick", 1.4)
                play(ws, {Color = PAL.accent, Transparency = 0.1, Thickness = 1.5}, 0.2)
                play(ul, {Size = UDim2.new(1, 0, 0, 2)}, 0.4)
                play(wrap, {BackgroundColor3 = Color3.fromRGB(22, 19, 38)}, 0.2)
            end)
            box.FocusLost:Connect(function()
                play(ws, {Color = T.stroke, Transparency = 0.4, Thickness = 1}, 0.25)
                play(ul, {Size = UDim2.new(0, 0, 0, 2)}, 0.25)
                play(wrap, {BackgroundColor3 = T.input}, 0.25)
            end)
            return wrap, box
        end

        ----------------------------------------------------------------
        -- DROPDOWN (single / multi, search otomatis kalau opsi > 7)
        ----------------------------------------------------------------
        function K:Dropdown(o)
            o = o or {}
            local flag = (not o.NoSave) and (o.Flag or o.Title) or nil
            local multi = o.Multi and true or false
            local opts = o.Options or {}
            local hasDesc = o.Desc ~= nil
            local H0 = hasDesc and 58 or 46
            local ROW, MAXV = 32, 5
            local chosen, single = {}, nil
            local rows, open, expanded = {}, false, H0

            local function wantSearch()
                if o.Search ~= nil then return o.Search and true or false end
                return #opts > 7
            end
            local function setFrom(v)
                chosen, single = {}, nil
                if multi then
                    if type(v) == "table" then for _, n in ipairs(v) do chosen[tostring(n)] = true end
                    elseif v ~= nil then chosen[tostring(v)] = true end
                else
                    if type(v) == "table" then v = v[1] end
                    if v ~= nil then single = tostring(v) end
                end
            end
            local saved = flag and Data.Features[flag]
            if saved ~= nil then setFrom(saved) else setFrom(o.Default) end

            local function getVal()
                if multi then
                    local r = {}
                    for _, n in ipairs(opts) do if chosen[tostring(n)] then r[#r + 1] = tostring(n) end end
                    return r
                end
                return single
            end
            local function isSel(name) if multi then return chosen[name] == true end return single == name end
            local function summary()
                if multi then
                    local v = getVal()
                    if #v == 0 then return "None" end
                    if #v <= 2 then return table.concat(v, ", ") end
                    return #v.." selected"
                end
                return single or "Select..."
            end

            ----------------------------------------------------------
            -- kartu + header
            ----------------------------------------------------------
            local f, st, hf = card(H0)
            local hglow = new("Frame", {Size = UDim2.new(1, 0, 0, H0), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0}, f)
            corner(hglow, 14)
            tgrad(new("UIGradient", {Transparency = NumberSequence.new(0, 1)}, hglow), {"accent", "cyan"})

            local head = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, H0), ZIndex = 2}, f)
            ripple(head)
            spotlight(f, head)

            local rail = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, head)
            corner(rail, FULL)
            tgrad(new("UIGradient", {Rotation = 90}, rail), {"cyan", "accent"})

            local titleL = label(head, {Text = o.Title or flag or "Dropdown", Position = UDim2.fromOffset(16, hasDesc and 10 or 0), Size = UDim2.new(1, -150, 0, hasDesc and 18 or H0), Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 3})
            local descL
            if hasDesc then
                descL = label(head, {Text = o.Desc, Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -150, 0, 16), TextSize = 11, TextColor3 = DIM, ZIndex = 3})
            end

            -- value pill + chevron
            local valF = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -46, 0.5, 0), Size = UDim2.fromOffset(70, 24), BackgroundColor3 = T.input, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 3}, head)
            corner(valF, FULL) stroke(valF, T.stroke, 1, 0.5)
            local valL = label(valF, {Text = "", Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = PAL.cyan, ZIndex = 4})
            tcol(valL, "TextColor3", "cyan")
            local chev = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 3}, head)
            corner(chev, FULL)
            tcol(chev, "BackgroundColor3", "accent")
            local arrow = label(chev, {Text = "›", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(1, -1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 19, TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.None, Rotation = 90, ZIndex = 4})

            local sep = new("Frame", {Position = UDim2.fromOffset(14, H0), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, f)
            tgrad(new("UIGradient", {}, sep), {"accent", "cyan"})

            ----------------------------------------------------------
            -- search + list
            ----------------------------------------------------------
            local sbW, sb = inputBox(f, {placeholder = "Search...", wrap = {Size = UDim2.new(1, -20, 0, 28), Visible = false}})
            local listF = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageTransparency = 0.2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 2}, f)
            tcol(listF, "ScrollBarImageColor3", "accent")
            new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, listF)
            local noRes = label(listF, {Text = "No results", Size = UDim2.new(1, -4, 0, 28), LayoutOrder = 1000000, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 12, TextColor3 = Color3.fromRGB(110, 104, 145), Visible = false})

            local function rowState(r, on, anim)
                local function p(obj, props, t, s)
                    if anim then play(obj, props, t, s) else for k, v in pairs(props) do obj[k] = v end end
                end
                p(r.btn, {BackgroundTransparency = on and 0.84 or 1}, 0.25)
                p(r.txt, {TextColor3 = on and T.text or DIM}, 0.25)
                p(r.ind, {Size = UDim2.fromOffset(3, on and 16 or 0)}, 0.4, Enum.EasingStyle.Back)
                p(r.fill, {BackgroundTransparency = on and 0 or 1}, 0.2)
                p(r.fs, {Scale = on and 1 or 0.4}, 0.4, Enum.EasingStyle.Back)
                p(r.ms, {Color = on and PAL.accent or T.stroke, Transparency = on and 0.1 or 0.2}, 0.25)
                if r.ck then p(r.ck, {TextTransparency = on and 0 or 1}, 0.2) end
            end
            local function paint(anim)
                for _, r in ipairs(rows) do rowState(r, isSel(r.name), anim) end
                local txt = summary()
                valL.Text = txt
                local pw = math.clamp(textW(txt, 11) + 26, 60, 150)
                if anim then play(valF, {Size = UDim2.fromOffset(pw, 24)}, 0.35, Enum.EasingStyle.Quint) else valF.Size = UDim2.fromOffset(pw, 24) end
                titleL.Size = UDim2.new(1, -(pw + 78), 0, hasDesc and 18 or H0)
                if descL then descL.Size = UDim2.new(1, -(pw + 78), 0, 16) end
            end
            local function commit()
                local v = getVal()
                if flag and not loading then Data.Features[flag] = v saveN(curName) end
                if o.Callback then o.Callback(v) end
            end
            local function visCount()
                local n = 0
                for _, r in ipairs(rows) do if r.btn.Visible then n = n + 1 end end
                return n
            end
            local function layout(anim)
                local show = wantSearch()
                sbW.Visible = show
                local sbH = show and 34 or 0
                local n = visCount()
                noRes.Visible = (n == 0)
                local lh = (n == 0) and 30 or (math.min(n, MAXV) * (ROW + 2) - 2)
                sbW.Position = UDim2.fromOffset(10, H0 + 6)
                listF.Position = UDim2.fromOffset(10, H0 + 6 + sbH)
                local sz = UDim2.new(1, -20, 0, lh)
                if anim and open then play(listF, {Size = sz}, 0.28) else listF.Size = sz end
                expanded = H0 + 6 + sbH + lh + 10
                if open then play(hf, {Size = UDim2.new(1, 0, 0, expanded)}, anim and 0.32 or 0.05) end
            end

            local setOpen
            local function myClose() setOpen(false) end
            local function pick(name)
                if multi then
                    if chosen[name] then chosen[name] = nil else chosen[name] = true end
                else
                    single = name
                end
                sfx("pop")
                paint(true)
                commit()
                if not multi then task.delay(0.16, function() setOpen(false) end) end
            end
            local function build()
                for _, r in ipairs(rows) do r.btn:Destroy() end
                rows = {}
                sb.Text = ""
                for i, n in ipairs(opts) do
                    local name = tostring(n)
                    local b = new("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, -4, 0, ROW), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = i, ZIndex = 3}, listF)
                    corner(b, 10)
                    tgrad(new("UIGradient", {}, b), {"accent", "accent2"})
                    local ind = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4}, b)
                    corner(ind, FULL)
                    tgrad(new("UIGradient", {Rotation = 90}, ind), {"cyan", "accent"})
                    local t = label(b, {Text = name, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -46, 1, 0), TextSize = 12, TextColor3 = DIM, ZIndex = 4})
                    local mark = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(17, 17), BackgroundColor3 = T.input, BorderSizePixel = 0, ZIndex = 4}, b)
                    corner(mark, multi and 6 or FULL)
                    local ms = stroke(mark, T.stroke, 1.2, 0.2)
                    local fillS = multi and 1 or 0.55
                    local fill = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(fillS, fillS), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5}, mark)
                    corner(fill, multi and 6 or FULL)
                    tgrad(new("UIGradient", {Rotation = 45}, fill), {"accent", "cyan"})
                    local fs = new("UIScale", {Scale = 0.4}, fill)
                    local ck
                    if multi then
                        ck = label(fill, {Text = "✓", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = WHITE, TextTransparency = 1, TextTruncate = Enum.TextTruncate.None, ZIndex = 6})
                    end
                    local r = {btn = b, txt = t, ind = ind, fill = fill, fs = fs, ms = ms, ck = ck, name = name}
                    rows[i] = r
                    b.MouseEnter:Connect(function()
                        sfx("hover")
                        if not isSel(name) then play(b, {BackgroundTransparency = 0.92}, 0.15) end
                        play(t, {Position = UDim2.fromOffset(18, 0)}, 0.22)
                    end)
                    b.MouseLeave:Connect(function()
                        if not isSel(name) then play(b, {BackgroundTransparency = 1}, 0.2) end
                        play(t, {Position = UDim2.fromOffset(14, 0)}, 0.26)
                    end)
                    b.MouseButton1Click:Connect(function() pick(name) end)
                end
                layout(false)
                paint(false)
            end
            sb:GetPropertyChangedSignal("Text"):Connect(function()
                local q = sb.Text:lower()
                for _, r in ipairs(rows) do r.btn.Visible = (q == "") or (r.name:lower():find(q, 1, true) ~= nil) end
                listF.CanvasPosition = Vector2.new(0, 0)
                layout(true)
            end)

            setOpen = function(v)
                if v == open then return end
                open = v
                if v then
                    if ddClose and ddClose ~= myClose then ddClose() end
                    ddClose = myClose
                elseif ddClose == myClose then
                    ddClose = nil
                end
                sfx(v and "expand" or "collapse")
                play(arrow, {Rotation = v and -90 or 90}, 0.5, Enum.EasingStyle.Back)
                play(chev, {BackgroundTransparency = v and 0.15 or 0.85}, 0.3)
                play(rail, {Size = UDim2.new(0, 3, v and 0.6 or 0, 0)}, 0.4, Enum.EasingStyle.Back)
                play(hglow, {BackgroundTransparency = v and 0.82 or 1}, 0.4)
                play(sep, {BackgroundTransparency = v and 0.72 or 1}, 0.3)
                play(st, {Color = v and PAL.accent or T.stroke, Transparency = v and 0.2 or 0.5}, 0.3)
                play(hf, {Size = UDim2.new(1, 0, 0, v and expanded or H0)}, v and 0.5 or 0.4, Enum.EasingStyle.Quint)
                if v then
                    listF.CanvasPosition = Vector2.new(0, 0)
                    for i, r in ipairs(rows) do
                        if i <= 8 then
                            r.txt.TextTransparency = 1
                            r.txt.Position = UDim2.fromOffset(4, 0)
                            task.delay(0.06 + i * 0.035, function()
                                if open and r.txt.Parent then
                                    play(r.txt, {TextTransparency = 0, Position = UDim2.fromOffset(14, 0)}, 0.4, Enum.EasingStyle.Quint)
                                end
                            end)
                        end
                    end
                else
                    for _, r in ipairs(rows) do r.txt.TextTransparency = 0 end
                end
            end

            head.MouseEnter:Connect(function()
                sfx("hover")
                if not open then
                    play(st, {Color = PAL.accent, Transparency = 0.35}, 0.2)
                    play(rail, {Size = UDim2.new(0, 3, 0.4, 0)}, 0.3, Enum.EasingStyle.Back)
                    play(hglow, {BackgroundTransparency = 0.94}, 0.3)
                end
            end)
            head.MouseLeave:Connect(function()
                if not open then
                    play(st, {Color = T.stroke, Transparency = 0.5}, 0.25)
                    play(rail, {Size = UDim2.new(0, 3, 0, 0)}, 0.25)
                    play(hglow, {BackgroundTransparency = 1}, 0.3)
                end
            end)
            head.MouseButton1Click:Connect(function() sfx("click") setOpen(not open) end)

            -- klik di luar kartu = tutup
            bind(UIS.InputBegan, function(i)
                if not open then return end
                local ut = i.UserInputType
                if ut ~= Enum.UserInputType.MouseButton1 and ut ~= Enum.UserInputType.Touch then return end
                local pos
                if ut == Enum.UserInputType.Touch then
                    pos = Vector2.new(i.Position.X, i.Position.Y + GuiService:GetGuiInset().Y)
                else
                    pos = UIS:GetMouseLocation()
                end
                local ap, asz = f.AbsolutePosition, f.AbsoluteSize
                if pos.X < ap.X or pos.X > ap.X + asz.X or pos.Y < ap.Y or pos.Y > ap.Y + asz.Y then
                    setOpen(false)
                end
            end)

            build()
            if flag then Data.Features[flag] = getVal() end
            if (not o.NoInit) and o.Callback and (multi or single ~= nil) then task.spawn(function() o.Callback(getVal()) end) end

            local api = {}
            function api:Set(v, fire)
                setFrom(v) paint(true)
                if flag then Data.Features[flag] = getVal() end
                if fire and o.Callback then o.Callback(getVal()) end
            end
            function api:Get() return getVal() end
            function api:Refresh(newOpts)
                opts = newOpts or {}
                -- buang pilihan yang sudah tidak ada di opsi baru
                local valid = {}
                for _, n in ipairs(opts) do valid[tostring(n)] = true end
                for k in pairs(chosen) do if not valid[k] then chosen[k] = nil end end
                if single and not valid[single] then single = nil end
                build()
                if open then setOpen(false) end
            end
            function api:Open() setOpen(true) end
            function api:Close() setOpen(false) end
            return api
        end

        return K
    end

    ------------------------------------------------------------------
    -- DASHBOARD  (info + pengaturan; semua pengaturan lewat Dropdown)
    ------------------------------------------------------------------
    local dashScroll = createTab("Dashboard", true)
    local D = buildComponents(dashScroll)
    local xyv, fpsV, pingV, sessV, fpsPush

    -- judul seksi internal (bukan bagian API)
    local function secTitle(Kb, text)
        text = string.upper(tostring(text))
        local hf = Kb._holder(26)
        local f = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
        Kb._enter(f)
        local dot = new("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(6, 11), BackgroundColor3 = WHITE, BorderSizePixel = 0, Rotation = 45}, f)
        tgrad(new("UIGradient", {Rotation = 45}, dot), {"accent", "cyan"})
        TweenService:Create(dot, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.55}):Play()
        local w = textW(text, 11)
        local sl = label(f, {Text = text, Position = UDim2.fromOffset(18, 5), Size = UDim2.fromOffset(w + 4, 16), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.None})
        tgrad(new("UIGradient", {}, sl), {Color3.fromRGB(232, 224, 255), "cyan"})
        local lx = 18 + w + 14
        local line = new("Frame", {Position = UDim2.new(0, lx, 0, 13), Size = UDim2.new(1, -(lx + 6), 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
        tgrad(new("UIGradient", {Transparency = NumberSequence.new(0.3, 1)}, line), {"accent", "cyan"})
    end

    -- pill kecil (aksi salin) di dalam kartu info
    local function copyPill(parent, text, right, w, getText, what)
        local b = new("TextButton", {Text = text, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.text, AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(38, 34, 60), BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -right, 0.5, 0), Size = UDim2.fromOffset(w, 26), ZIndex = 4}, parent)
        corner(b, FULL)
        local s = stroke(b, T.stroke, 1, 0.4)
        hover(b, s, Color3.fromRGB(56, 50, 88), T.cardDown)
        ripple(b)
        local busy = false
        b.MouseButton1Click:Connect(function()
            local sv = tostring(getText())
            copy(sv)
            sfx("click")
            notify(what or "Copied", sv, "success", 1.8)
            if busy then return end
            busy = true
            b.Text = "✓"
            task.wait(1)
            b.Text = text
            busy = false
        end)
        return b
    end

    do -- profil
        local c = D._card(80)
        local sheen = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, c)
        corner(sheen, 14)
        tgrad(new("UIGradient", {Transparency = NumberSequence.new(0.86, 1), Rotation = 20}, sheen), {"accent", "cyan"})
        local sweep = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 70, 2, 0), Position = UDim2.new(-0.2, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, c)
        new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.88), NumberSequenceKeypoint.new(1, 1)}}, sweep)
        TweenService:Create(sweep, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, 3.2), {Position = UDim2.new(1.2, 0, 0.5, 0)}):Play()
        local ring = new("Frame", {Size = UDim2.fromOffset(54, 54), Position = UDim2.fromOffset(14, 13), BackgroundColor3 = T.panel, BorderSizePixel = 0, ZIndex = 3}, c)
        corner(ring, FULL)
        local rs = stroke(ring, WHITE, 2.2, 0)
        local rg = new("UIGradient", {}, rs)
        tgrad(rg, {"accent", "cyan", "accent"})
        spin(rg, 3)
        local av = new("ImageLabel", {Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, ZIndex = 4}, ring)
        corner(av, FULL)
        task.spawn(function()
            local ok, img = pcall(function() return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
            if ok and av.Parent then av.Image = img end
        end)
        label(c, {Text = pl.DisplayName, Position = UDim2.fromOffset(82, 14), Size = UDim2.new(1, -96, 0, 20), Font = Enum.Font.GothamBold, TextSize = 15, ZIndex = 3})
        label(c, {Text = "@"..pl.Name.."  •  "..tostring(placeId), Position = UDim2.fromOffset(82, 36), Size = UDim2.new(1, -96, 0, 14), TextSize = 11, TextColor3 = DIM, ZIndex = 3})
        local sd = new("Frame", {Size = UDim2.fromOffset(7, 7), Position = UDim2.fromOffset(83, 59), BackgroundColor3 = T.ok, BorderSizePixel = 0, ZIndex = 3}, c)
        corner(sd, FULL)
        TweenService:Create(sd, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.75}):Play()
        label(c, {Text = "Online", Position = UDim2.fromOffset(96, 55), Size = UDim2.fromOffset(80, 14), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.ok, ZIndex = 3})
    end

    do -- statistik
        local hf = D._holder(58)
        local row = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
        D._enter(row)
        new("UIGridLayout", {CellSize = UDim2.new(1 / 3, -6, 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder}, row)
        local function stat(title, value, key, ord)
            local f = new("Frame", {BackgroundColor3 = T.card, BackgroundTransparency = 0.15, BorderSizePixel = 0, LayoutOrder = ord}, row)
            corner(f, 14)
            local s = stroke(f, WHITE, 1, 0.65)
            pc(s, "Color", key)
            regTrans(f, 0) gloss(f)
            grad(f, WHITE, Color3.fromRGB(200, 196, 222), 90)
            local line = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0.5, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
            corner(line, FULL)
            pc(line, "BackgroundColor3", key)
            label(f, {Text = title, Position = UDim2.fromOffset(12, 9), Size = UDim2.new(1, -20, 0, 12), TextSize = 11, TextColor3 = DIM})
            return label(f, {Text = value, Position = UDim2.fromOffset(12, 25), Size = UDim2.new(1, -20, 0, 22), Font = Enum.Font.GothamBold, TextSize = 16})
        end
        fpsV = stat("FPS", "--", "accent", 1)
        pingV = stat("Ping", "--", "cyan", 2)
        sessV = stat("Session", "00:00", T.ok, 3)
    end

    do -- grafik FPS
        local c = D._card(92)
        label(c, {Text = "Frame rate history", Position = UDim2.fromOffset(14, 9), Size = UDim2.new(0.5, -14, 0, 14), TextSize = 11, TextColor3 = DIM})
        local avgL = label(c, {Text = "avg --  •  low --", Position = UDim2.new(0.5, 0, 0, 9), Size = UDim2.new(0.5, -14, 0, 14), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right})
        tcol(avgL, "TextColor3", "cyan")
        local area = new("Frame", {Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -28, 1, -40), BackgroundTransparency = 1}, c)
        local N = 30
        local bars, hist = {}, {}
        local function barSize(v)
            if v <= 0 then return UDim2.new(1 / N, -2, 0, 3) end
            return UDim2.new(1 / N, -2, math.clamp(v / 90, 0.06, 1), 0)
        end
        for i = 1, N do
            hist[i] = 0
            local b = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / N, 1, 1, 0), Size = barSize(0), BackgroundColor3 = T.off, BorderSizePixel = 0}, area)
            corner(b, 3)
            grad(b, WHITE, Color3.fromRGB(165, 160, 200), 90)
            bars[i] = b
        end
        fpsPush = function(v)
            table.remove(hist, 1)
            hist[#hist + 1] = v
            if not isOpen then return end
            local sum, cnt, low = 0, 0, math.huge
            for i = 1, N do
                local x = hist[i]
                local col = (x >= 50 and T.ok) or (x >= 30 and T.warn) or T.bad
                if x <= 0 then col = T.off end
                play(bars[i], {Size = barSize(x), BackgroundColor3 = col}, 0.35)
                if x > 0 then
                    sum = sum + x cnt = cnt + 1
                    if x < low then low = x end
                end
            end
            if cnt > 0 then avgL.Text = "avg "..math.floor(sum / cnt + 0.5).."  •  low "..low end
        end
    end

    do -- info game + salin ID
        local c, cs = D._card(64)
        c.BackgroundColor3 = Color3.fromRGB(34, 29, 20)
        cs.Color = T.warn cs.Transparency = 0.6
        label(c, {Text = gameName, Position = UDim2.fromOffset(14, 11), Size = UDim2.new(1, -150, 0, 18), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255, 220, 90), ZIndex = 3})
        label(c, {Text = tostring(placeId).."  •  "..tostring(gameId), Position = UDim2.fromOffset(14, 33), Size = UDim2.new(1, -150, 0, 16), TextSize = 11, TextColor3 = Color3.fromRGB(230, 210, 150), ZIndex = 3})
        copyPill(c, "Place", 76, 54, function() return placeId end, "Place ID copied")
        copyPill(c, "Game", 14, 54, function() return gameId end, "Game ID copied")
    end

    do -- koordinat
        local c = D._card(56)
        label(c, {Text = "Live coordinates", Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -90, 0, 14), TextSize = 11, TextColor3 = DIM})
        xyv = label(c, {Text = "X:0  Y:0  Z:0", Position = UDim2.fromOffset(14, 27), Size = UDim2.new(1, -90, 0, 20), Font = Enum.Font.Code, TextSize = 13, TextColor3 = Color3.fromRGB(130, 160, 255)})
        copyPill(c, "Copy", 12, 54, function() return xyv.Text end, "Coordinates copied")
    end

    -- PENGATURAN: semuanya Dropdown
    secTitle(D, "Appearance")
    D:Dropdown({
        Title = "Theme", Desc = "Accent color preset", Flag = "UITheme", Options = THEME_ORDER, Default = "Violet", NoInit = true,
        Callback = function(v)
            if type(v) ~= "string" or v == curTheme or not THEMES[v] then return end
            curTheme = v
            setTheme(v)
            sfx("pop")
            notify("Theme", v.." applied", THEMES[v].accent, 2)
        end,
    })
    D:Dropdown({
        Title = "Panel style", Desc = "Opacity of the glass panels", Flag = "UIPanel", Options = {"Solid", "Soft", "Glass", "Crystal"}, Default = "Soft", NoInit = true,
        Callback = function(v) if PANEL[v] then applyTrans(PANEL[v]) end end,
    })
    local SCALE_OPTS = {"75%", "90%", "100%", "110%", "125%", "150%"}
    local function scaleLabel()
        local best, bd = "100%", 1e9
        for _, s in ipairs(SCALE_OPTS) do
            local d = math.abs((tonumber(s:match("%d+")) or 100) / 100 - userScale)
            if d < bd then best, bd = s, d end
        end
        return best
    end
    D:Dropdown({
        Title = "UI scale", Desc = "Overall interface size", Options = SCALE_OPTS, Default = scaleLabel(), NoSave = true, NoInit = true,
        Callback = function(v)
            local n = tonumber(tostring(v):match("%d+"))
            if not n then return end
            userScale = math.clamp(n / 100, 0.6, 1.5)
            applyScale()
            saveUI()
        end,
    })
    D:Dropdown({
        Title = "Window size", Desc = "Preset size of the window", Options = {"Compact", "Default", "Large"}, Default = "Default", NoSave = true, NoInit = true,
        Callback = function(v)
            local sizes = {Compact = Vector2.new(520, 340), Default = DEFAULT_SIZE, Large = Vector2.new(800, 520)}
            if not sizes[v] then return end
            winSize = sizes[v]
            winPos = nil
            layoutWin(true)
            saveUI()
        end,
    })

    secTitle(D, "Effects")
    D:Dropdown({
        Title = "Background blur", Desc = "Blur the game behind the menu", Flag = "UIBlurMode", Options = {"On", "Off"}, Default = "On", NoInit = true,
        Callback = function(v) blurOn = (v == "On") updateBlur() end,
    })
    D:Dropdown({
        Title = "Animated background", Desc = "Aurora glow and floating particles", Flag = "UIAnimMode", Options = {"On", "Off"}, Default = "On", NoInit = true,
        Callback = function(v) ambientOn = (v == "On") ambient.Visible = ambientOn end,
    })
    D:Dropdown({
        Title = "Sound", Desc = "SORU signature sound effects", Flag = "UISoundLevel", Options = {"Off", "Low", "Medium", "High"}, Default = "Medium", NoInit = true,
        Callback = function(v) if SND_LEVELS[v] ~= nil then sndVol = SND_LEVELS[v] end end,
    })

    secTitle(D, "Controls")
    do
        local KEY_OPTS = {"RightShift", "RightControl", "Insert", "Delete", "Home", "K"}
        local tkName = toggleKey.Name
        local found = false
        for _, k in ipairs(KEY_OPTS) do if k == tkName then found = true end end
        if not found then table.insert(KEY_OPTS, tkName) end
        D:Dropdown({
            Title = "Menu key", Desc = "Show or hide the interface", Flag = "MenuKey", Options = KEY_OPTS, Default = tkName, NoInit = true,
            Callback = function(v) local k = toKey(tostring(v)) if k then toggleKey = k end end,
        })
    end

    do -- discord
        local hf = D._holder(42)
        local d = new("TextButton", {Name = "Body", Size = UDim2.fromScale(1, 1), Text = "Join our Discord", Font = Enum.Font.GothamBold, TextSize = 13, BackgroundColor3 = Color3.fromRGB(88, 101, 242), TextColor3 = WHITE, AutoButtonColor = false, BorderSizePixel = 0}, hf)
        D._enter(d)
        corner(d, 14)
        grad(d, WHITE, Color3.fromRGB(205, 205, 235), 90)
        hover(d, nil, Color3.fromRGB(106, 118, 255), Color3.fromRGB(70, 82, 210))
        ripple(d)
        local busy = false
        d.MouseButton1Click:Connect(function()
            sfx("click")
            copy("https://discord.gg/cHsx3RFYb")
            notify("Discord", "Invite copied to clipboard", Color3.fromRGB(88, 101, 242), 2.2)
            if busy then return end
            busy = true
            local old = d.Text
            d.Text = "Invite copied ✓"
            task.wait(1.5)
            d.Text = old
            busy = false
        end)
    end

    ------------------------------------------------------------------
    -- MODAL TUTUP
    ------------------------------------------------------------------
    local modalTok = 0
    local over = new("Frame", {Name = "Modal", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 100}, root)
    local dia = new("CanvasGroup", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(330, 190), BackgroundColor3 = Color3.fromRGB(26, 23, 42), BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 101}, over)
    corner(dia, 20) stroke(dia, T.stroke, 1, 0.3)
    local diaScale = new("UIScale", {Scale = 0.92}, dia)
    local iw = new("Frame", {Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0.5, -22, 0, 16), BackgroundColor3 = Color3.fromRGB(52, 28, 38), BorderSizePixel = 0}, dia)
    corner(iw, FULL) stroke(iw, T.bad, 1, 0.4)
    label(iw, {Text = "!", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = T.bad})
    label(dia, {Text = "Close SORU Hub?", Position = UDim2.new(0, 10, 0, 68), Size = UDim2.new(1, -20, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 15})
    label(dia, {Text = "The interface will be closed. Re-execute the script to open it again.", Position = UDim2.new(0, 24, 0, 92), Size = UDim2.new(1, -48, 0, 32), TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, TextSize = 12, TextColor3 = Color3.fromRGB(170, 165, 190)})
    local no = new("TextButton", {Size = UDim2.new(0.5, -22, 0, 38), Position = UDim2.new(0, 16, 1, -54), Text = "Cancel", Font = Enum.Font.GothamBold, TextSize = 13, BackgroundColor3 = Color3.fromRGB(42, 38, 62), TextColor3 = T.text, AutoButtonColor = false, BorderSizePixel = 0}, dia)
    corner(no, FULL) hover(no, nil, Color3.fromRGB(56, 50, 84), T.cardDown)
    local yes = new("TextButton", {Size = UDim2.new(0.5, -22, 0, 38), Position = UDim2.new(0.5, 6, 1, -54), Text = "Close", Font = Enum.Font.GothamBold, TextSize = 13, BackgroundColor3 = Color3.fromRGB(210, 60, 70), TextColor3 = WHITE, AutoButtonColor = false, BorderSizePixel = 0}, dia)
    corner(yes, FULL) hover(yes, nil, Color3.fromRGB(230, 78, 88), Color3.fromRGB(180, 44, 54))

    local function showC()
        modalTok = modalTok + 1
        over.Visible = true
        sfx("expand")
        diaScale.Scale = 0.9
        dia.GroupTransparency = 1
        iw.Rotation = -18
        play(over, {BackgroundTransparency = 0.5}, 0.25)
        play(diaScale, {Scale = 1}, 0.5, Enum.EasingStyle.Back)
        play(dia, {GroupTransparency = 0}, 0.22)
        play(iw, {Rotation = 0}, 0.7, Enum.EasingStyle.Elastic)
    end
    local function hideC()
        modalTok = modalTok + 1
        local tok = modalTok
        play(diaScale, {Scale = 0.94}, 0.2)
        play(dia, {GroupTransparency = 1}, 0.2)
        play(over, {BackgroundTransparency = 1}, 0.22)
        task.delay(0.24, function() if tok == modalTok then over.Visible = false end end)
    end
    local function delA()
        hideC()
        closeA()
        task.delay(0.6, function() gui:Destroy() end)
    end
    minB.MouseButton1Click:Connect(function() sfx("click") closeA() end)
    xB.MouseButton1Click:Connect(showC)
    no.MouseButton1Click:Connect(hideC)
    yes.MouseButton1Click:Connect(delA)

    ------------------------------------------------------------------
    -- LOOP LIVE (FPS, ping, koordinat, parallax) + input
    ------------------------------------------------------------------
    local fc, lfT = 0, os.clock()
    local sessStart = os.clock()
    bind(RunService.RenderStepped, function()
        fc = fc + 1
        local now = os.clock()
        if now - lfT >= 1 then
            local fps = math.floor(fc / (now - lfT) + 0.5)
            fc = 0 lfT = now
            if fpsPush then fpsPush(fps) end
            if isOpen then
                local fcol = (fps >= 50 and T.ok) or (fps >= 30 and T.warn) or T.bad
                fpsV.Text = tostring(fps)
                fpsV.TextColor3 = fcol
                chipL.Text = fps.." fps"
                play(cdot, {BackgroundColor3 = fcol}, 0.3)
                pcall(function() pingV.Text = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5).." ms" end)
                local sec = math.floor(now - sessStart)
                if sec >= 3600 then
                    sessV.Text = string.format("%d:%02d:%02d", math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60)
                else
                    sessV.Text = string.format("%02d:%02d", math.floor(sec / 60), sec % 60)
                end
            end
        end
    end)
    -- parallax halus: gambar background bergeser tipis mengikuti mouse
    local pxx, pyy = 0.5, 0.5
    bind(RunService.RenderStepped, function()
        if not isOpen then return end
        local sz, ap = win.AbsoluteSize, win.AbsolutePosition
        if sz.X <= 0 or sz.Y <= 0 then return end
        local m = UIS:GetMouseLocation()
        pxx = pxx + (math.clamp((m.X - ap.X) / sz.X, 0, 1) - pxx) * 0.08
        pyy = pyy + (math.clamp((m.Y - ap.Y) / sz.Y, 0, 1) - pyy) * 0.08
        bgImg.Position = UDim2.new(0.5, (0.5 - pxx) * 22, 0.5, (0.5 - pyy) * 14)
    end)
    local acc = 0
    bind(RunService.Heartbeat, function(dt)
        acc = acc + dt
        if acc < 0.1 then return end
        acc = 0
        if not isOpen or cur ~= "Dashboard" then return end
        local ch = pl.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if hrp then
            local p = hrp.Position
            xyv.Text = string.format("X:%.1f  Y:%.1f  Z:%.1f", p.X, p.Y, p.Z)
        end
    end)
    bind(UIS.InputBegan, function(i, gp)
        if gp then return end
        if i.KeyCode == toggleKey then toggleWin() end
    end)
    bind(gui:GetPropertyChangedSignal("AbsoluteSize"), applyScale)

    ------------------------------------------------------------------
    -- SPLASH / BOOT
    ------------------------------------------------------------------
    local function boot(cb)
        booting = true
        sfx("boot")
        launcher.Visible = false
        local sp = new("CanvasGroup", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(260, 170), BackgroundColor3 = T.ink, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 150}, root)
        corner(sp, 22)
        local sps = stroke(sp, WHITE, 1.5, 0.3)
        local spg = new("UIGradient", {}, sps)
        tgrad(spg, {"accent", "cyan", "pink", "accent"})
        spin(spg, 3)
        local sc = new("UIScale", {Scale = 0.8}, sp)
        -- gelombang kejut saat "Ready"
        local function shock(key)
            local r = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(70, 70), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 151}, root)
            corner(r, FULL)
            local rs2 = stroke(r, PAL[key], 2.5, 0.1)
            play(r, {Size = UDim2.fromOffset(440, 440)}, 0.9, Enum.EasingStyle.Quint)
            play(rs2, {Transparency = 1, Thickness = 0.5}, 0.9)
            task.delay(0.95, function() r:Destroy() end)
        end
        local ringF = new("Frame", {Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0.5, -30, 0, 20), BackgroundColor3 = T.panel, BorderSizePixel = 0}, sp)
        corner(ringF, FULL)
        local rs = stroke(ringF, WHITE, 2.4, 0)
        local rsg = new("UIGradient", {}, rs)
        tgrad(rsg, {"accent", "cyan", "accent"})
        spin(rsg, 1.4)
        local ico = new("ImageLabel", {Size = UDim2.new(1, -18, 1, -18), Position = UDim2.fromOffset(9, 9), BackgroundTransparency = 1, Image = ICON}, ringF)
        local icoS = new("UIScale", {Scale = 1}, ico)
        TweenService:Create(icoS, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.12}):Play()
        label(sp, {Text = C.Title or "SORU HUB", Position = UDim2.new(0, 0, 0, 92), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = WHITE})
        local stL = label(sp, {Text = "Initializing...", Position = UDim2.new(0, 0, 0, 114), Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 11, TextColor3 = DIM})
        local barBg = new("Frame", {Position = UDim2.new(0, 30, 1, -26), Size = UDim2.new(1, -60, 0, 4), BackgroundColor3 = T.off, BorderSizePixel = 0}, sp)
        corner(barBg, FULL)
        local barF = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, barBg)
        corner(barF, FULL)
        tgrad(new("UIGradient", {}, barF), {"accent", "cyan"})
        play(sp, {GroupTransparency = 0}, 0.25)
        play(sc, {Scale = 1}, 0.55, Enum.EasingStyle.Back)
        task.spawn(function()
            local steps = {{"Loading assets...", 0.35}, {"Loading config...", 0.7}, {"Ready", 1}}
            for _, s in ipairs(steps) do
                stL.Text = s[1]
                if s[2] >= 1 then shock("cyan") task.delay(0.12, function() shock("accent") end) sfx("pop") end
                play(barF, {Size = UDim2.fromScale(s[2], 1)}, 0.32)
                task.wait(0.34)
            end
            task.wait(0.15)
            play(sc, {Scale = 1.12}, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            play(sp, {GroupTransparency = 1}, 0.32)
            task.wait(0.32)
            if not gui.Parent then return end
            sp:Destroy()
            launcher.Visible = true
            booting = false
            cb()
        end)
    end

    ------------------------------------------------------------------
    -- FINALISASI
    ------------------------------------------------------------------
    applyScale()

    local supported = C.SupportedGames
    local kickOnFail = C.KickIfNotSupported
    if kickOnFail == nil then kickOnFail = true end
    local isSupported = true
    if supported and #supported > 0 then
        isSupported = false
        for _, id in ipairs(supported) do if id == placeId or id == gameId then isSupported = true break end end
    end

    Window.Gui = gui
    Window.PlaceId = placeId Window.GameId = gameId Window.GameName = gameName
    Window.IsSupported = isSupported
    -- Window:Notify(...) dan Window.Notify(...) dua-duanya bisa
    Window.Notify = function(a, b, c, d)
        if a == Window then return notify(b, c, d, nil) end
        return notify(a, b, c, d)
    end
    do
        local raw = Window.Notify
        Window.Notify = function(a, b, c, d, e)
            if a == Window then return notify(b, c, d, e) end
            return notify(a, b, c, d)
        end
        raw = nil
    end
    Window.ShowBadge = showNotSupportedBadge
    function Window:IsGame(id) return placeId == id or gameId == id end
    function Window:Toggle() toggleWin() end
    function Window:SetTheme(n) if THEMES[n] then curTheme = n setTheme(n) end end
    function Window:SetScale(pct) userScale = math.clamp((tonumber(pct) or 100) / 100, 0.6, 1.5) applyScale() saveUI() end
    function Window:SetBlur(b) blurOn = b and true or false updateBlur() end
    function Window:SetSound(b) sndVol = b and (SND_LEVELS[sndLevel] > 0 and SND_LEVELS[sndLevel] or 0.6) or 0 end
    function Window:Destroy() delA() end

    if not isSupported then
        launcher.Visible = false
        task.spawn(function()
            task.wait(0.5)
            showNotSupportedBadge(kickOnFail)
            if not kickOnFail then notify("Blocked", "Game not supported", "error", 4) end
        end)
        function Window:Tab()
            local function dummy() return {Set = function() end, Get = function() return false end, Refresh = function() end, Open = function() end, Close = function() end} end
            return setmetatable({}, {__index = function() return dummy end})
        end
        return Window
    end

    function Window:Tab(c)
        c = c or {}
        local scroll = createTab(c.Title or "Tab", false, c.Icon)
        return buildComponents(scroll)
    end

    if C.Demo then
        local S = Window:Tab({Title = "Showcase", Icon = "★"})
        S:Dropdown({Title = "Single dropdown", Desc = "Pilih satu opsi", Flag = "Demo_DD", Options = {"Alpha", "Beta", "Gamma"}, Default = "Alpha"})
        S:Dropdown({Title = "Multi dropdown", Desc = "Pilih banyak, search otomatis", Flag = "Demo_MD", Multi = true, Options = {"One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"}, Default = {"One"}})
        S:Dropdown({
            Title = "Notify test", Desc = "Pilih jenis toast untuk ditampilkan", NoSave = true, NoInit = true,
            Options = {"Info", "Success", "Warning", "Error"},
            Callback = function(v)
                local kinds = {Info = "info", Success = "success", Warning = "warn", Error = "error"}
                notify(v, "Ini contoh notifikasi bertipe "..tostring(v):lower()..".", kinds[v], 3.5)
            end,
        })
    end

    boot(function()
        openA(true)
        notify("SORU HUB v"..VERSION, "Loaded successfully", "success", 3.5)
    end)
    return Window
end

return SORU
