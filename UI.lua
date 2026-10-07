--[[
    SORU HUB UI v3.1  (API 100% kompatibel dengan v2.x)

    BARU DI v3.1
      Accordion : Tab:Accordion({Title, Desc, Open}) -> isinya komponen apa saja (Acc:Toggle, Acc:Button, Acc:Slider, dst)
      Sound     : suara khas SORU, disintesis sendiri (tanpa asset id), diatur di Dashboard > Sound
      Visual    : kartu glass (highlight atas + stroke gradient), shine sweep, tooltip slider, ring burst toggle

    BARU DI v3.0
      Komponen  : Textbox, Dropdown (single/multi + search), Keybind, ColorPicker,
                  Paragraph, Divider  (+ Button, Toggle, Slider, Section, Label dari v2)
      Visual    : splash/boot screen, chip FPS di header, profil di sidebar,
                  kartu lebih bulat, transisi tab sesuai arah, ikon tab custom
      Animasi   : dropdown expand + stagger, underline fokus textbox, keybind "listening",
                  picker warna drag, dll.
      Menu key  : bisa diganti lewat Keybind di Dashboard (tersimpan di config)

    API
      local Window = SORU:CreateWindow({
          Title = "SORU HUB", SupportedGames = {123}, KickIfNotSupported = true,
          ReferenceSize = Vector2.new(1280, 720), Scale = 1,
          ToggleKey = Enum.KeyCode.RightShift,
          Demo = false, -- true = tambah tab "Showcase" berisi semua komponen
      })
      local Tab = Window:Tab({Title = "Main", Icon = "M"})
      Tab:Button({Title, Desc, Callback = function() end})
      Tab:Toggle({Title, Flag, Default, Desc, Callback = function(v) end})
      Tab:Slider({Title, Flag, Min, Max, Step, Default, Suffix, Callback = function(v) end})
      Tab:Textbox({Title, Flag, Default, Placeholder, Numeric, Min, Max, Live, ClearOnFocus, Callback = function(text|number) end})
      Tab:Dropdown({Title, Flag, Options = {}, Default, Multi, Callback = function(value|array) end})  -- :Set(v) :Get() :Refresh(opts)
      Tab:Keybind({Title, Flag, Default = Enum.KeyCode.X, Callback = function(key) end, OnChange = function(key) end})
      Tab:ColorPicker({Title, Flag, Default = Color3, Callback = function(color) end})
      Tab:Paragraph({Title, Desc})
      Tab:Section("Judul") / Tab:Divider() / Tab:Label("Teks")
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
-- motif: arpeggio A major (A - C# - E) bernada lonceng kaca
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
    on       = {0.4, {{0, 0.25, 880, 880, 0.5, "bell", 16}, {0.07, 0.3, 1318.5, 1318.5, 0.5, "bell", 14}}},
    off      = {0.4, {{0, 0.25, 740, 740, 0.45, "bell", 16}, {0.07, 0.3, 554.4, 554.4, 0.45, "bell", 14}}},
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
-- THEME
----------------------------------------------------------------------
local T = {
    ink       = Color3.fromRGB(10, 9, 17),
    panel     = Color3.fromRGB(18, 16, 30),
    card      = Color3.fromRGB(26, 23, 42),
    cardHover = Color3.fromRGB(38, 34, 62),
    cardDown  = Color3.fromRGB(56, 46, 102),
    stroke    = Color3.fromRGB(64, 58, 98),
    text      = Color3.fromRGB(244, 242, 255),
    dim       = Color3.fromRGB(148, 140, 180),
    accent    = Color3.fromRGB(139, 92, 246),
    accent2   = Color3.fromRGB(99, 102, 241),
    cyan      = Color3.fromRGB(56, 189, 248),
    pink      = Color3.fromRGB(236, 72, 153),
    ok        = Color3.fromRGB(74, 222, 128),
    warn      = Color3.fromRGB(250, 204, 21),
    bad       = Color3.fromRGB(248, 113, 113),
    off       = Color3.fromRGB(52, 50, 74),
    input     = Color3.fromRGB(14, 12, 24),
}
local ACCENT, ACCENT2, DIM = T.accent, T.accent2, T.dim
local WHITE = Color3.new(1, 1, 1)
local VERSION = "3.1"
local SHADOW_ID = "6014261993" -- kosongkan ("") kalau shadow tidak muncul
local FULL = UDim.new(1, 0)
local RING = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.35, T.cyan), ColorSequenceKeypoint.new(0.7, T.pink), ColorSequenceKeypoint.new(1, T.accent)}
local RING2 = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.5, T.cyan), ColorSequenceKeypoint.new(1, T.accent)}

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
        if s then play(s, {Color = ACCENT, Transparency = 0.25}, 0.18) end
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

    local toggleKey = C.ToggleKey or Enum.KeyCode.RightShift
    do local mk = Data.Features["MenuKey"] if type(mk) == "string" then toggleKey = toKey(mk) or toggleKey end end
    local binding = false
    local booting = false

    -- SOUND
    local sndOn = (Data.Features["UISound"] ~= false)
    local sndVol = (type(Data.Features["UIVol"]) == "number") and math.clamp(Data.Features["UIVol"], 0, 100) / 100 or 0.6
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
        if not sndOn or not b then return end
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
    -- TOAST
    ------------------------------------------------------------------
    local toastHolder = new("Frame", {Name = "Toasts", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.new(0, 310, 1, -28), BackgroundTransparency = 1, ZIndex = 200}, root)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right}, toastHolder)
    local toastN = 0
    local function notify(title, msg, color, dur)
        color = color or ACCENT
        dur = dur or 3
        toastN = toastN + 1
        sfx(color == T.bad and "error" or "notify")
        local glyph = "i"
        if color == T.ok then glyph = "✓" elseif color == T.bad then glyph = "✕" elseif color == T.warn then glyph = "!" end
        local wrap = new("Frame", {Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, LayoutOrder = toastN, ZIndex = 201}, toastHolder)
        local f = new("Frame", {Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(350, 0), BackgroundColor3 = Color3.fromRGB(20, 18, 32), BorderSizePixel = 0, ZIndex = 202}, wrap)
        corner(f, 14) stroke(f, color, 1, 0.5)
        local sheen = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 202}, f)
        corner(sheen, 14)
        new("UIGradient", {Transparency = NumberSequence.new(0.8, 1)}, sheen)
        local ic = new("Frame", {Size = UDim2.fromOffset(30, 30), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(27, 33), BackgroundColor3 = color, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 203}, f)
        corner(ic, FULL) stroke(ic, color, 1.2, 0.4)
        local icS = new("UIScale", {Scale = 0}, ic)
        label(ic, {Text = glyph, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = color, ZIndex = 204})
        label(f, {Text = tostring(title or ""), Position = UDim2.fromOffset(52, 11), Size = UDim2.new(1, -62, 0, 14), Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 203})
        label(f, {Text = tostring(msg or ""), Position = UDim2.fromOffset(52, 27), Size = UDim2.new(1, -62, 0, 28), TextSize = 11, TextColor3 = DIM, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 203})
        local prog = new("Frame", {Size = UDim2.new(1, -24, 0, 2), Position = UDim2.new(0, 12, 1, -5), BackgroundColor3 = color, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 203}, f)
        corner(prog, FULL)
        play(f, {Position = UDim2.fromOffset(0, 0)}, 0.55, Enum.EasingStyle.Back)
        task.delay(0.2, function() if ic.Parent then play(icS, {Scale = 1}, 0.45, Enum.EasingStyle.Back) end end)
        play(prog, {Size = UDim2.new(0, 0, 0, 2)}, dur, Enum.EasingStyle.Linear)
        task.delay(dur, function()
            if not f.Parent then return end
            play(f, {Position = UDim2.fromOffset(350, 0)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            task.wait(0.28)
            if not wrap.Parent then return end
            play(wrap, {Size = UDim2.new(1, 0, 0, 0)}, 0.22)
            task.wait(0.24)
            wrap:Destroy()
        end)
    end

    local function showNotSupportedBadge(kickAfter)
        local badge = new("CanvasGroup", {Size = UDim2.fromOffset(360, 72), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -100), BackgroundColor3 = Color3.fromRGB(28, 24, 42), BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 300}, root)
        corner(badge, 14) stroke(badge, T.bad, 1.2, 0.2)
        new("ImageLabel", {Size = UDim2.fromOffset(42, 42), Position = UDim2.new(0, 16, 0.5, -21), BackgroundTransparency = 1, Image = ICON}, badge)
        label(badge, {Text = "Game not supported", Position = UDim2.fromOffset(70, 16), Size = UDim2.new(1, -80, 0, 18), Font = Enum.Font.GothamBold, TextSize = 14})
        label(badge, {Text = "Place ID "..tostring(game.PlaceId), Position = UDim2.fromOffset(70, 37), Size = UDim2.new(1, -80, 0, 14), TextSize = 11, TextColor3 = DIM})
        play(badge, {GroupTransparency = 0}, 0.25)
        play(badge, {Position = UDim2.new(0.5, 0, 0, 24)}, 0.5, Enum.EasingStyle.Back)
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
    local function regTrans(inst, off) transTargets[#transTargets + 1] = {inst = inst, off = off or 0} end

    local tabs = {}
    local cur = "Dashboard"
    local entranceLists = setmetatable({}, {__mode = "k"})
    local function entrance(scroll)
        local list = entranceLists[scroll]
        if not list then return end
        for _, body in ipairs(list) do
            if body.Parent then body.Position = UDim2.fromOffset(-30, 0) end
        end
        for i, body in ipairs(list) do
            task.delay(math.min(i - 1, 14) * 0.04, function()
                if body.Parent then play(body, {Position = UDim2.fromOffset(0, 0)}, 0.55, Enum.EasingStyle.Back) end
            end)
        end
    end

    ------------------------------------------------------------------
    -- WINDOW SHELL
    ------------------------------------------------------------------
    local shell = new("Frame", {Name = "Shell", BackgroundTransparency = 1, Size = UDim2.fromOffset(winSize.X, winSize.Y), Visible = false, ZIndex = 10}, root)
    local shadow = nil
    if SHADOW_ID ~= "" then
        shadow = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.new(1, 64, 1, 64), BackgroundTransparency = 1, Image = "rbxassetid://"..SHADOW_ID, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 1}, shell)
    end

    local win = new("CanvasGroup", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.ink, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 2}, shell)
    corner(win, 20)
    local winStroke = stroke(win, WHITE, 1.6, 0.35)
    local wsGrad = new("UIGradient", {Color = RING}, winStroke)
    spin(wsGrad, 8)
    local winScale = new("UIScale", {Scale = 0.12}, win)

    local tint = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, win)
    new("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(20, 17, 36), Color3.fromRGB(8, 7, 14)), Rotation = 125}, tint)
    local bgImg = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = BG, ImageTransparency = 0.82, ScaleType = Enum.ScaleType.Crop, ZIndex = 2}, win)
    local bgS = new("UIScale", {Scale = 1.05}, bgImg)
    local glow = new("Frame", {Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, win)
    new("UIGradient", {Color = ColorSequence.new(T.accent, T.accent2), Transparency = NumberSequence.new(0.78, 1), Rotation = 90}, glow)

    -- aurora orb + partikel
    local ambientOn = (Data.Features["UIAnim"] ~= false)
    local ambient = new("Frame", {Name = "Ambient", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4, Visible = ambientOn}, win)
    local function orb(col, size, px, py, dx, dy, secs)
        local o = new("Frame", {Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(px, py), BackgroundTransparency = 1, ZIndex = 4}, ambient)
        local layers = 7
        for i = 1, layers do
            local s = 1 - (i - 1) / layers * 0.9
            local c = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s), BackgroundColor3 = col, BackgroundTransparency = 0.94, BorderSizePixel = 0, ZIndex = 4}, o)
            corner(c, FULL)
        end
        TweenService:Create(o, TweenInfo.new(secs, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.fromScale(px + dx, py + dy)}):Play()
    end
    orb(T.accent, 340, 0.15, 0.2, 0.25, 0.15, 9)
    orb(T.cyan, 300, 0.9, 0.85, -0.22, -0.2, 11)
    orb(T.pink, 240, 0.75, 0.05, -0.3, 0.3, 13)
    for i = 1, 14 do
        local col = (i % 3 == 0) and T.cyan or ((i % 3 == 1) and T.accent or WHITE)
        local p = new("Frame", {Size = UDim2.fromOffset(3, 3), BackgroundColor3 = col, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4}, ambient)
        corner(p, FULL)
        task.spawn(function()
            task.wait(i * 0.45)
            while gui.Parent do
                if isOpen and ambientOn then
                    local dur = math.random(60, 120) / 10
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

    local accentLine = new("Frame", {Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 15}, win)
    local ag = new("UIGradient", {Color = RING2}, accentLine)
    ag.Offset = Vector2.new(-1, 0)
    TweenService:Create(ag, TweenInfo.new(3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(1, 0)}):Play()

    local zoomFixed = Data.Features and type(Data.Features["BGZoom"]) == "number"
    if zoomFixed then
        bgS.Scale = Data.Features["BGZoom"]
    else
        TweenService:Create(bgS, TweenInfo.new(14, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.13}):Play()
    end

    local function applyTrans(t)
        t = math.clamp(t, 0, 0.7)
        for _, e in ipairs(transTargets) do
            if e.inst and e.inst.Parent then e.inst.BackgroundTransparency = math.clamp(t + e.off, 0, 1) end
        end
        bgImg.ImageTransparency = math.clamp(0.9 - t * 0.8, 0.3, 1)
    end

    ------------------------------------------------------------------
    -- RIPPLE
    ------------------------------------------------------------------
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
            play(shell, {Size = UDim2.fromOffset(sz.X, sz.Y), Position = UDim2.fromOffset(x, y)}, 0.4)
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
    local launcher = new("Frame", {Name = "Launcher", Size = UDim2.fromOffset(LAUNCH, LAUNCH), BackgroundColor3 = Color3.fromRGB(20, 18, 32), BorderSizePixel = 0, Active = true, ZIndex = 99}, root)
    corner(launcher, 16)
    local lStroke = stroke(launcher, WHITE, 1.8, 0)
    local lGrad = new("UIGradient", {Color = RING2}, lStroke)
    spin(lGrad, 4)
    local pulse = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(LAUNCH, LAUNCH), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 98, Visible = true}, launcher)
    corner(pulse, 18)
    local pulseS = stroke(pulse, ACCENT, 2, 0.2)
    local pInfo = TweenInfo.new(2.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, -1, false, 0.3)
    TweenService:Create(pulse, pInfo, {Size = UDim2.fromOffset(LAUNCH + 34, LAUNCH + 34)}):Play()
    TweenService:Create(pulseS, pInfo, {Transparency = 1}):Play()
    local lIcon = new("ImageLabel", {Size = UDim2.fromOffset(32, 32), Position = UDim2.new(0.5, -16, 0.5, -16), BackgroundTransparency = 1, Image = ICON, ScaleType = Enum.ScaleType.Fit, ZIndex = 100}, launcher)
    local iScale = new("UIScale", {Scale = 1}, lIcon)
    TweenService:Create(iScale, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.1}):Play()
    local lScale = new("UIScale", {Scale = 1}, launcher)
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
    local blurOn = (Data.Features["UIBlur"] ~= false)
    local blur = nil
    pcall(function()
        blur = Instance.new("BlurEffect")
        blur.Name = "SORU_BLUR"
        blur.Size = 0
        blur.Parent = Lighting
    end)
    local function updateBlur()
        if blur and blur.Parent then play(blur, {Size = (isOpen and blurOn) and 12 or 0}, 0.45) end
    end
    gui.Destroying:Connect(function() if blur then pcall(function() blur:Destroy() end) end end)

    local function launcherOffset()
        local sz = effSize()
        local sc = Vector2.new(curPos.X + sz.X / 2, curPos.Y + sz.Y / 2)
        local lp = launchPos or Vector2.new(14, 14)
        return Vector2.new(lp.X + LAUNCH / 2 - sc.X, lp.Y + LAUNCH / 2 - sc.Y)
    end

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
        play(win, {Position = UDim2.fromScale(0.5, 0.5)}, 0.55, Enum.EasingStyle.Quint)
        play(winScale, {Scale = 1}, 0.65, Enum.EasingStyle.Back)
        play(win, {GroupTransparency = 0}, 0.3)
        if shadow then play(shadow, {ImageTransparency = 0.55}, 0.45) end
        updateBlur()
        local t = tabs[cur]
        if t then task.delay(0.15, function() if isOpen then entrance(t.scroll) end end) end
    end
    local function closeA()
        if not isOpen then return end
        isOpen = false
        sfx("close")
        local tok = openTok
        local off = launcherOffset()
        pulse.Visible = true
        play(win, {Position = UDim2.new(0.5, off.X, 0.5, off.Y)}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        play(winScale, {Scale = 0.12}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        play(win, {GroupTransparency = 1}, 0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        if shadow then play(shadow, {ImageTransparency = 1}, 0.22) end
        updateBlur()
        task.delay(0.45, function() if not isOpen and tok == openTok then shell.Visible = false end end)
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
            play(lScale, {Scale = 1}, 0.35, Enum.EasingStyle.Back)
            if not moved then toggleWin() end
        end)

    ------------------------------------------------------------------
    -- HEADER
    ------------------------------------------------------------------
    local tb = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Active = true, ZIndex = 10}, win)
    local logo = new("Frame", {Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, 14, 0.5, -18), BackgroundColor3 = Color3.fromRGB(26, 24, 42), BorderSizePixel = 0}, tb)
    corner(logo, 12)
    local logoS = stroke(logo, WHITE, 1.4, 0.2)
    local logoG = new("UIGradient", {Color = RING2}, logoS)
    spin(logoG, 5)
    new("ImageLabel", {Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, Image = ICON}, logo)
    local titleL = label(tb, {Text = C.Title or "SORU HUB", Position = UDim2.fromOffset(60, 10), Size = UDim2.new(1, -250, 0, 18), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = WHITE})
    local tg = new("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, T.text), ColorSequenceKeypoint.new(0.35, T.text), ColorSequenceKeypoint.new(0.5, T.cyan), ColorSequenceKeypoint.new(0.65, T.text), ColorSequenceKeypoint.new(1, T.text)}, Offset = Vector2.new(-1, 0)}, titleL)
    TweenService:Create(tg, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 2.4), {Offset = Vector2.new(1, 0)}):Play()
    label(tb, {Text = "v"..VERSION.."  "..gameName, Position = UDim2.fromOffset(60, 29), Size = UDim2.new(1, -250, 0, 14), TextSize = 10, TextColor3 = DIM})
    local sepL = new("Frame", {Position = UDim2.fromOffset(10, 56), Size = UDim2.new(1, -20, 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 10}, win)
    new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 1)}}, sepL)

    -- chip FPS
    local chip = new("Frame", {Size = UDim2.fromOffset(78, 22), Position = UDim2.new(1, -170, 0.5, -11), BackgroundColor3 = Color3.fromRGB(28, 25, 44), BorderSizePixel = 0, ZIndex = 11}, tb)
    corner(chip, FULL) stroke(chip, T.stroke, 1, 0.6)
    local cdot = new("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(10, 8), BackgroundColor3 = T.ok, BorderSizePixel = 0, ZIndex = 12}, chip)
    corner(cdot, FULL)
    TweenService:Create(cdot, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.7}):Play()
    local chipL = label(chip, {Text = "-- fps", Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -26, 1, 0), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = DIM, ZIndex = 12})

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
    local TAB_H, TAB_P = 38, 44
    local side = new("Frame", {Position = UDim2.fromOffset(10, 58), Size = UDim2.new(0, SIDE_W, 1, -68), BackgroundColor3 = T.panel, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 5}, win)
    corner(side, 16) stroke(side, T.stroke, 1, 0.65) regTrans(side, 0.05)
    local tabList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -52), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.fromOffset(0, 0), ZIndex = 6}, side)

    -- profil mini di sidebar
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

    local pill = new("Frame", {Size = UDim2.new(1, -12, 0, TAB_H), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = WHITE, BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 5}, tabList)
    corner(pill, 11) stroke(pill, ACCENT, 1, 0.45)
    grad(pill, T.accent, T.accent2, 0)
    local ind = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 18), BackgroundColor3 = WHITE, BorderSizePixel = 0}, pill)
    corner(ind, FULL)
    grad(ind, T.cyan, T.accent, 90)

    local content = new("Frame", {Position = UDim2.new(0, SIDE_W + 20, 0, 58), Size = UDim2.new(1, -(SIDE_W + 30), 1, -68), BackgroundColor3 = T.panel, BackgroundTransparency = 0.25, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 5}, win)
    corner(content, 16) stroke(content, T.stroke, 1, 0.7) regTrans(content, 0.1)

    local rh = new("Frame", {Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -28, 1, -28), BackgroundTransparency = 1, Active = true, ZIndex = 30}, win)
    local rhL = label(rh, {Text = "⋰", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(-4, -2), TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Bottom, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(100, 94, 130)})
    rh.MouseEnter:Connect(function() play(rhL, {TextColor3 = ACCENT}, 0.15) end)
    rh.MouseLeave:Connect(function() play(rhL, {TextColor3 = Color3.fromRGB(100, 94, 130)}, 0.2) end)

    track(tb,
        function()
            winPos = curPos
            if isOpen then play(winScale, {Scale = 1.012}, 0.18) end
            return curPos
        end,
        function(dx, dy, st, moved)
            if moved and st then
                local s = rootScale.Scale
                winPos = Vector2.new(st.X + dx / s, st.Y + dy / s)
                layoutWin(false)
            end
        end,
        function() if isOpen then play(winScale, {Scale = 1}, 0.4, Enum.EasingStyle.Back) end end)
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

    local function movePill(y)
        pillTok = pillTok + 1
        local tok = pillTok
        local y0 = pill.Position.Y.Offset
        local top = math.min(y0, y)
        local span = math.abs(y - y0) + TAB_H
        play(pill, {Position = UDim2.fromOffset(6, top), Size = UDim2.new(1, -12, 0, span)}, 0.18, Enum.EasingStyle.Quad)
        task.delay(0.16, function()
            if tok ~= pillTok then return end
            play(pill, {Position = UDim2.fromOffset(6, y), Size = UDim2.new(1, -12, 0, TAB_H)}, 0.38, Enum.EasingStyle.Back)
        end)
    end

    local function switchTab(n)
        if cur == n or not tabs[n] then return end
        local oldName = cur
        local old = tabs[oldName]
        local ne = tabs[n]
        local dir = (ne.index > (old and old.index or 0)) and 1 or -1
        cur = n
        sfx("tab")
        if old then
            play(old.label, {TextColor3 = DIM}, 0.2)
            play(old.badge, {BackgroundTransparency = 0.82}, 0.2)
            play(old.frame, {GroupTransparency = 1, Position = UDim2.fromOffset(0, -12 * dir)}, 0.18)
            task.delay(0.19, function() if cur ~= oldName then old.frame.Visible = false end end)
        end
        ne.frame.Visible = true
        ne.frame.GroupTransparency = 1
        ne.frame.Position = UDim2.fromOffset(0, 18 * dir)
        play(ne.frame, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, 0.45, Enum.EasingStyle.Quint)
        entrance(ne.scroll)
        play(ne.label, {TextColor3 = T.text}, 0.2)
        play(ne.badge, {BackgroundTransparency = 0}, 0.2)
        play(ne.btn, {BackgroundTransparency = 1}, 0.1)
        movePill(ne.y)
    end

    local function createTab(name, active, icon)
        tabOrder = tabOrder + 1
        local idx = tabOrder
        local y = 6 + (idx - 1) * TAB_P
        local b = new("TextButton", {Name = name, Size = UDim2.new(1, -12, 0, TAB_H), Position = UDim2.fromOffset(6, y), BackgroundColor3 = ACCENT, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 6}, tabList)
        corner(b, 11)
        local badge = new("Frame", {Size = UDim2.fromOffset(24, 24), Position = UDim2.new(0, 8, 0.5, -12), BackgroundColor3 = WHITE, BackgroundTransparency = active and 0 or 0.82, BorderSizePixel = 0, ZIndex = 7}, b)
        corner(badge, 8)
        grad(badge, T.accent, T.accent2, 45)
        label(badge, {Text = icon and tostring(icon) or string.upper(string.sub(name, 1, 1)), Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 8, TextTruncate = Enum.TextTruncate.None})
        local tx = label(b, {Text = name, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -46, 1, 0), Font = Enum.Font.GothamSemibold, TextColor3 = active and T.text or DIM, ZIndex = 7})
        tabList.CanvasSize = UDim2.fromOffset(0, 6 + idx * TAB_P)

        local page = new("CanvasGroup", {Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = active, GroupTransparency = active and 0 or 1, ZIndex = 6}, content)
        local scroll = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT, ScrollBarImageTransparency = 0.3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 7}, page)
        new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
        new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12)}, scroll)

        tabs[name] = {btn = b, frame = page, scroll = scroll, label = tx, badge = badge, index = idx, y = y}
        b.MouseEnter:Connect(function()
            if cur ~= name then
                play(b, {BackgroundTransparency = 0.9}, 0.15)
                play(tx, {Position = UDim2.fromOffset(45, 0)}, 0.2)
            end
        end)
        b.MouseLeave:Connect(function()
            play(b, {BackgroundTransparency = 1}, 0.2)
            play(tx, {Position = UDim2.fromOffset(40, 0)}, 0.25)
        end)
        b.MouseButton1Click:Connect(function() switchTab(name) end)
        return scroll
    end

    ------------------------------------------------------------------
    -- KOMPONEN
    ------------------------------------------------------------------
    local function buildComponents(scroll, container, nested)
        container = container or scroll
        local K = {}
        local order = 0
        local list = {}
        if not nested then entranceLists[scroll] = list end
        K._kids = list
        local function nextOrder() order = order + 1 return order end
        K._next = nextOrder

        local function holder(h, auto)
            local hf = new("Frame", {Name = "Holder", Size = UDim2.new(1, 0, 0, h or 0), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder()}, container)
            if auto then hf.AutomaticSize = Enum.AutomaticSize.Y end
            return hf
        end
        local function enter(body) list[#list + 1] = body end
        K._holder, K._enter = holder, enter

        local function card(h, clickable)
            local hf = holder(h)
            local f = new(clickable and "TextButton" or "Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.card, BackgroundTransparency = 0.15, BorderSizePixel = 0})
            if clickable then f.Text = "" f.AutoButtonColor = false end
            f.Parent = hf
            corner(f, nested and 10 or 12)
            local s = stroke(f, T.stroke, 1, 0.55)
            new("UIGradient", {Transparency = NumberSequence.new(0, 0.55), Rotation = 90}, s)
            grad(f, WHITE, Color3.fromRGB(200, 196, 222), 90)
            if nested then f.BackgroundTransparency = 0.4 end
            gloss(f)
            regTrans(f, nested and 0.25 or 0)
            enter(f)
            if clickable then
                ripple(f)
                local bar = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
                corner(bar, FULL)
                grad(bar, T.cyan, T.accent, 90)
                local sc = new("UIScale", {Scale = 1}, f)
                local shine = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 46, 2, 0), Position = UDim2.new(-0.2, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 0}, f)
                new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(1, 1)}}, shine)
                f.MouseEnter:Connect(function()
                    play(bar, {Size = UDim2.new(0, 3, 0.55, 0)}, 0.25, Enum.EasingStyle.Back)
                    shine.Position = UDim2.new(-0.15, 0, 0.5, 0)
                    play(shine, {Position = UDim2.new(1.15, 0, 0.5, 0)}, 0.6, Enum.EasingStyle.Quad)
                end)
                f.MouseLeave:Connect(function()
                    play(bar, {Size = UDim2.new(0, 3, 0, 0)}, 0.2)
                    play(sc, {Scale = 1}, 0.2)
                end)
                f.MouseButton1Down:Connect(function() play(sc, {Scale = 0.98}, 0.08) end)
                f.MouseButton1Up:Connect(function() play(sc, {Scale = 1}, 0.35, Enum.EasingStyle.Back) end)
            end
            return f, s, hf
        end
        K._card = card

        -- input kecil: kotak gelap dengan underline fokus
        local function inputBox(parent, props)
            local wrap = new("Frame", {BackgroundColor3 = T.input, BorderSizePixel = 0, ClipsDescendants = true}, parent)
            for k, v in pairs(props.wrap or {}) do wrap[k] = v end
            corner(wrap, 8)
            local ws = stroke(wrap, T.stroke, 1, 0.4)
            local box = new("TextBox", {Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = props.text or "", PlaceholderText = props.placeholder or "", PlaceholderColor3 = Color3.fromRGB(100, 94, 130), TextColor3 = T.text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = props.clear or false, ClipsDescendants = true}, wrap)
            local ul = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0}, wrap)
            grad(ul, T.accent, T.cyan, 0)
            box.Focused:Connect(function()
                sfx("tick", 1.4)
                play(ws, {Color = ACCENT, Transparency = 0.1, Thickness = 1.5}, 0.2)
                play(ul, {Size = UDim2.new(1, 0, 0, 2)}, 0.35)
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
        function K:Section(text)
            if type(text) == "table" then text = text.Title or text.Text end
            text = string.upper(tostring(text or ""))
            local hf = holder(24)
            local f = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
            enter(f)
            local dot = new("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(6, 10), BackgroundColor3 = WHITE, BorderSizePixel = 0, Rotation = 45}, f)
            grad(dot, T.accent, T.cyan, 45)
            TweenService:Create(dot, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.55}):Play()
            local w = textW(text, 12)
            label(f, {Text = text, Position = UDim2.fromOffset(18, 4), Size = UDim2.fromOffset(w + 4, 16), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(196, 176, 255), TextTruncate = Enum.TextTruncate.None})
            local lx = 18 + w + 14
            local line = new("Frame", {Position = UDim2.new(0, lx, 0, 12), Size = UDim2.new(1, -(lx + 6), 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new(0.3, 1)}, line)
            return f
        end

        function K:Divider()
            local hf = holder(10)
            local f = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
            enter(f)
            local line = new("Frame", {Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.new(1, -12, 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1)}}, line)
        end

        function K:Label(text)
            if type(text) == "table" then text = text.Text or text.Title end
            local hf = holder(0, true)
            local f = new("Frame", {Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.card, BackgroundTransparency = 0.35, BorderSizePixel = 0}, hf)
            corner(f, 12) regTrans(f, 0.2) enter(f)
            new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, f)
            local t = label(f, {Text = tostring(text or ""), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 12, TextColor3 = DIM, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None})
            return {Set = function(_, s) t.Text = tostring(s) end}
        end

        function K:Paragraph(o)
            o = o or {}
            local hf = holder(0, true)
            local f = new("Frame", {Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.card, BackgroundTransparency = 0.15, BorderSizePixel = 0}, hf)
            corner(f, 12) stroke(f, T.stroke, 1, 0.55) regTrans(f, 0) enter(f)
            new("UIPadding", {PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}, f)
            new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, f)
            local t = label(f, {Text = tostring(o.Title or ""), Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.GothamBold, TextSize = 13, LayoutOrder = 1})
            local d = label(f, {Text = tostring(o.Desc or ""), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 11, TextColor3 = DIM, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2})
            return {Set = function(_, title, desc) if title then t.Text = tostring(title) end if desc then d.Text = tostring(desc) end end}
        end

        function K:Button(o)
            o = o or {}
            local hasDesc = o.Desc ~= nil
            local h = hasDesc and 54 or 40
            local bt, st = card(h, true)
            label(bt, {Text = o.Title or "Button", Position = UDim2.fromOffset(14, hasDesc and 9 or 0), Size = UDim2.new(1, -52, 0, hasDesc and 18 or 40), Font = Enum.Font.GothamBold, TextSize = 13})
            if hasDesc then
                label(bt, {Text = o.Desc, Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -52, 0, 16), TextSize = 11, TextColor3 = DIM})
            end
            local badge = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.85, BorderSizePixel = 0}, bt)
            corner(badge, FULL)
            local arrow = label(badge, {Text = "›", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, -1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = ACCENT})
            hover(bt, st)
            bt.MouseEnter:Connect(function()
                play(badge, {BackgroundTransparency = 0.25}, 0.2)
                play(arrow, {Position = UDim2.fromOffset(2, -1), TextColor3 = WHITE}, 0.2)
            end)
            bt.MouseLeave:Connect(function()
                play(badge, {BackgroundTransparency = 0.85}, 0.2)
                play(arrow, {Position = UDim2.fromOffset(0, -1), TextColor3 = ACCENT}, 0.2)
            end)
            bt.MouseButton1Click:Connect(function() sfx("click") if o.Callback then o.Callback() end end)
            return bt
        end

        function K:Toggle(o)
            local flag = o.Flag or o.Title local def = o.Default or false local curV = Data.Features[flag] if curV == nil then curV = def end
            local hasDesc = o.Desc ~= nil
            local h = hasDesc and 54 or 42
            local fr, st = card(h, true)
            label(fr, {Text = o.Title or flag, Position = UDim2.fromOffset(14, hasDesc and 9 or 0), Size = UDim2.new(1, -78, 0, hasDesc and 18 or h), Font = Enum.Font.GothamBold, TextSize = 13})
            if hasDesc then
                label(fr, {Text = o.Desc, Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -78, 0, 16), TextSize = 11, TextColor3 = DIM})
            end
            local tgb = new("Frame", {Size = UDim2.fromOffset(46, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = T.off, BorderSizePixel = 0}, fr)
            corner(tgb, FULL)
            local tst = stroke(tgb, ACCENT, 2, curV and 0.45 or 1)
            local onF = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = curV and 0 or 1, BorderSizePixel = 0}, tgb)
            corner(onF, FULL)
            grad(onF, T.accent, T.cyan, 0)
            local dot = new("Frame", {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0, 0.5), Position = curV and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, tgb)
            corner(dot, FULL)
            hover(fr, st)
            local function upd(v, ns)
                if not ns then
                    sfx(v and "on" or "off")
                    local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = v and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3}, tgb)
                    corner(ring, FULL)
                    local rst = stroke(ring, v and T.cyan or T.dim, 2, 0.2)
                    play(ring, {Size = UDim2.fromOffset(48, 48)}, 0.5)
                    play(rst, {Transparency = 1}, 0.5)
                    task.delay(0.55, function() ring:Destroy() end)
                end
                play(onF, {BackgroundTransparency = v and 0 or 1}, 0.25)
                play(tst, {Transparency = v and 0.45 or 1}, 0.25)
                play(dot, {Position = v and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, 0.4, Enum.EasingStyle.Back)
                play(dot, {Size = UDim2.fromOffset(22, 18)}, 0.1)
                task.delay(0.1, function() play(dot, {Size = UDim2.fromOffset(18, 18)}, 0.3, Enum.EasingStyle.Back) end)
                if not ns and not loading then Data.Features[flag] = v saveN(curName) end
                if o.Callback and not ns then o.Callback(v) end
            end
            Reg[flag] = {Set = function(v, ns) curV = v upd(v, ns) end, Get = function() return curV end}
            fr.MouseButton1Click:Connect(function() curV = not curV upd(curV) end)
            if o.Callback then task.spawn(function() o.Callback(curV) end) end
            Data.Features[flag] = curV
            return {Set = function(_, v) curV = v upd(v, true) end, Get = function() return curV end}
        end

        function K:Slider(o)
            o = o or {}
            local flag = o.Flag
            local mn, mx, step = o.Min or 0, o.Max or 100, o.Step or 1
            local val = o.Default or mn
            if flag and type(Data.Features[flag]) == "number" then val = Data.Features[flag] end
            val = math.clamp(val, mn, mx)
            local f = card(58)
            label(f, {Text = o.Title or flag or "Slider", Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -110, 0, 18), Font = Enum.Font.GothamBold, TextSize = 13})
            local chipV = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 7), Size = UDim2.fromOffset(48, 22), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.82, BorderSizePixel = 0}, f)
            corner(chipV, FULL) stroke(chipV, ACCENT, 1, 0.55)
            local vl = label(chipV, {Text = "", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextTruncate = Enum.TextTruncate.None})
            local hit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 0, 24)}, f)
            local bar = new("Frame", {Position = UDim2.new(0, 6, 0.5, -3), Size = UDim2.new(1, -12, 0, 6), BackgroundColor3 = Color3.fromRGB(42, 39, 64), BorderSizePixel = 0}, hit)
            corner(bar, FULL)
            local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, bar)
            corner(fill, FULL)
            grad(fill, T.accent2, T.cyan, 0)
            local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, bar)
            corner(knob, FULL)
            local kst = stroke(knob, ACCENT, 0, 1)
            local tip = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -8), Size = UDim2.fromOffset(44, 20), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5}, knob)
            corner(tip, 7) grad(tip, T.accent, T.cyan, 0)
            local tipL = label(tip, {Text = "", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextTransparency = 1, TextTruncate = Enum.TextTruncate.None, ZIndex = 6})

            local function fmt(v)
                local s = (v == math.floor(v)) and tostring(math.floor(v)) or tostring(v)
                return s..(o.Suffix or "")
            end
            local function render(v, animate)
                local a = (mx == mn) and 0 or (v - mn) / (mx - mn)
                if animate then
                    play(fill, {Size = UDim2.fromScale(a, 1)}, 0.2)
                    play(knob, {Position = UDim2.fromScale(a, 0.5)}, 0.2)
                else
                    fill.Size = UDim2.fromScale(a, 1)
                    knob.Position = UDim2.fromScale(a, 0.5)
                end
                local txt = fmt(v)
                vl.Text = txt
                tipL.Text = txt
                tip.Size = UDim2.fromOffset(math.max(40, textW(txt, 11) + 16), 20)
                chipV.Size = UDim2.fromOffset(math.max(48, textW(txt, 11) + 22), 22)
                chipV.BackgroundTransparency = 0.6
                play(chipV, {BackgroundTransparency = 0.82}, 0.25)
            end
            local function set(v, silent, animate)
                v = math.clamp(math.floor(v / step + 0.5) * step, mn, mx)
                v = math.floor(v * 1000 + 0.5) / 1000
                if not silent and v ~= val then sfx("tick", 0.75 + ((mx == mn) and 0 or (v - mn) / (mx - mn)) * 0.9) end
                val = v
                render(v, animate)
                if not silent and o.Callback then o.Callback(v) end
            end
            local function fromX(px, animate)
                local aw = bar.AbsoluteSize.X
                if aw <= 0 then return end
                local a = math.clamp((px - bar.AbsolutePosition.X) / aw, 0, 1)
                set(mn + (mx - mn) * a, false, animate)
            end
            track(hit,
                function(pos)
                    scroll.ScrollingEnabled = false
                    play(knob, {Size = UDim2.fromOffset(18, 18)}, 0.12)
                    play(kst, {Thickness = 6, Transparency = 0.6}, 0.18)
                    play(tip, {BackgroundTransparency = 0}, 0.15)
                    play(tipL, {TextTransparency = 0}, 0.15)
                    fromX(pos.X, true)
                    return true
                end,
                function(dx, dy, st, moved, pos) fromX(pos.X, false) end,
                function()
                    scroll.ScrollingEnabled = true
                    play(knob, {Size = UDim2.fromOffset(14, 14)}, 0.25, Enum.EasingStyle.Back)
                    play(kst, {Thickness = 0, Transparency = 1}, 0.25)
                    play(tip, {BackgroundTransparency = 1}, 0.2)
                    play(tipL, {TextTransparency = 1}, 0.2)
                    sfx("pop")
                    if flag and not loading then Data.Features[flag] = val saveN(curName) end
                    if o.OnRelease then o.OnRelease(val) end
                end)

            set(val, true, false)
            if flag then Data.Features[flag] = val end
            if o.Callback then task.spawn(function() o.Callback(val) end) end
            return {Set = function(_, v) set(v, true, true) end, Get = function() return val end}
        end

        ----------------------------------------------------------------
        -- TEXTBOX
        ----------------------------------------------------------------
        function K:Textbox(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local val = (o.Default ~= nil) and tostring(o.Default) or ""
            if flag and type(Data.Features[flag]) == "string" then val = Data.Features[flag] end
            local hasDesc = o.Desc ~= nil
            local h = hasDesc and 54 or 42
            local f = card(h)
            label(f, {Text = o.Title or flag or "Textbox", Position = UDim2.fromOffset(14, hasDesc and 9 or 0), Size = UDim2.new(0.55, -20, 0, hasDesc and 18 or h), Font = Enum.Font.GothamBold, TextSize = 13})
            if hasDesc then
                label(f, {Text = o.Desc, Position = UDim2.fromOffset(14, 28), Size = UDim2.new(0.55, -20, 0, 16), TextSize = 11, TextColor3 = DIM})
            end
            local wrap, box = inputBox(f, {text = val, placeholder = o.Placeholder or "Type here...", clear = o.ClearOnFocus,
                wrap = {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.42, 0, 0, 28)}})
            local function out(s) if o.Numeric then return tonumber(s) end return s end
            local function norm(s)
                if not o.Numeric then return s end
                local n = tonumber(s) or tonumber(val) or o.Min or 0
                if o.Min then n = math.max(n, o.Min) end
                if o.Max then n = math.min(n, o.Max) end
                return tostring(n)
            end
            if o.Numeric then
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    local t = (box.Text:gsub("[^%d%.%-]", ""))
                    if t ~= box.Text then box.Text = t end
                end)
            end
            if o.Live and o.Callback then
                box:GetPropertyChangedSignal("Text"):Connect(function() o.Callback(out(box.Text)) end)
            end
            local before = val
            box.Focused:Connect(function() before = box.Text end)
            box.FocusLost:Connect(function(enterPressed)
                local nv = norm(box.Text)
                box.Text = nv
                val = nv
                if enterPressed then sfx("pop") end
                if flag and not loading then Data.Features[flag] = nv saveN(curName) end
                if o.Callback and (enterPressed or nv ~= before) and not o.Live then o.Callback(out(nv)) end
            end)
            if flag then Data.Features[flag] = val end
            if o.Callback and val ~= "" then task.spawn(function() o.Callback(out(val)) end) end
            return {
                Set = function(_, v) val = tostring(v) box.Text = val if flag then Data.Features[flag] = val end end,
                Get = function() return out(box.Text) end,
            }
        end
        K.TextBox = K.Textbox
        K.Input = K.Textbox

        ----------------------------------------------------------------
        -- DROPDOWN (single / multi, search otomatis kalau opsi > 6)
        ----------------------------------------------------------------
        function K:Dropdown(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local multi = o.Multi and true or false
            local opts = o.Options or {}
            local hasDesc = o.Desc ~= nil
            local H0 = hasDesc and 54 or 42
            local chosen, single = {}, nil
            local rows, expanded, open = {}, H0, false

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

            local f, st, hf = card(H0)
            f.ClipsDescendants = true
            local head = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, H0)}, f)
            ripple(head)
            label(head, {Text = o.Title or flag or "Dropdown", Position = UDim2.fromOffset(14, hasDesc and 9 or 0), Size = UDim2.new(1, -160, 0, hasDesc and 18 or H0), Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 2})
            if hasDesc then
                label(head, {Text = o.Desc, Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -160, 0, 16), TextSize = 11, TextColor3 = DIM, ZIndex = 2})
            end
            local valL = label(head, {Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -36, 0, 0), Size = UDim2.fromOffset(120, H0), TextXAlignment = Enum.TextXAlignment.Right, TextSize = 11, TextColor3 = T.cyan, ZIndex = 2})
            local arrow = label(head, {Text = "›", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, H0 / 2), Size = UDim2.fromOffset(20, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = ACCENT, Rotation = 90, ZIndex = 2})

            local sbW, sb = inputBox(f, {placeholder = "Search...", wrap = {Size = UDim2.new(1, -16, 0, 26), Visible = false}})
            local listF = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = ACCENT, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, f)
            new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, listF)

            local function paint(anim)
                for _, r in ipairs(rows) do
                    local on = isSel(r.name)
                    local bt = on and 0.8 or 1
                    if anim then
                        play(r.btn, {BackgroundTransparency = bt}, 0.2)
                        play(r.txt, {TextColor3 = on and T.text or DIM}, 0.2)
                        play(r.ck, {TextTransparency = on and 0 or 1}, 0.2)
                    else
                        r.btn.BackgroundTransparency = bt
                        r.txt.TextColor3 = on and T.text or DIM
                        r.ck.TextTransparency = on and 0 or 1
                    end
                end
                local txt
                if multi then
                    local v = getVal()
                    txt = (#v == 0) and "None" or ((#v <= 2) and table.concat(v, ", ") or (#v.." selected"))
                else
                    txt = single or "Select..."
                end
                valL.Text = txt
            end
            local function commit()
                local v = getVal()
                if flag and not loading then Data.Features[flag] = v saveN(curName) end
                if o.Callback then o.Callback(v) end
            end
            local function layout()
                local show = #opts > 6
                sbW.Visible = show
                local sbH = show and 32 or 0
                local lh = math.max(0, math.min(#opts, 5) * 30 - 2)
                sbW.Position = UDim2.fromOffset(8, H0 + 4)
                listF.Position = UDim2.fromOffset(8, H0 + 4 + sbH)
                listF.Size = UDim2.new(1, -16, 0, lh)
                expanded = H0 + 4 + sbH + lh + 8
                if open then play(hf, {Size = UDim2.new(1, 0, 0, expanded)}, 0.3) end
            end
            local setOpen
            local function pick(name)
                if multi then
                    if chosen[name] then chosen[name] = nil else chosen[name] = true end
                else
                    single = name
                end
                sfx("pop")
                paint(true)
                commit()
                if not multi then task.delay(0.12, function() setOpen(false) end) end
            end
            local function build()
                for _, r in ipairs(rows) do r.btn:Destroy() end
                rows = {}
                for i, n in ipairs(opts) do
                    local name = tostring(n)
                    local b = new("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, -4, 0, 28), BackgroundColor3 = ACCENT, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = i}, listF)
                    corner(b, 8)
                    local t = label(b, {Text = name, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0), TextSize = 12, TextColor3 = DIM})
                    local ck = label(b, {Text = "✓", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(16, 16), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.cyan, TextTransparency = 1})
                    rows[i] = {btn = b, txt = t, ck = ck, name = name}
                    b.MouseEnter:Connect(function() if not isSel(name) then play(b, {BackgroundTransparency = 0.9}, 0.12) end end)
                    b.MouseLeave:Connect(function() if not isSel(name) then play(b, {BackgroundTransparency = 1}, 0.15) end end)
                    b.MouseButton1Click:Connect(function() pick(name) end)
                end
                layout()
                paint(false)
            end
            sb:GetPropertyChangedSignal("Text"):Connect(function()
                local q = sb.Text:lower()
                for _, r in ipairs(rows) do r.btn.Visible = (q == "") or (r.name:lower():find(q, 1, true) ~= nil) end
            end)
            setOpen = function(v)
                open = v
                sfx(v and "expand" or "collapse")
                play(arrow, {Rotation = v and -90 or 90}, 0.3, Enum.EasingStyle.Back)
                play(hf, {Size = UDim2.new(1, 0, 0, v and expanded or H0)}, 0.38, Enum.EasingStyle.Quint)
                play(st, {Color = v and ACCENT or T.stroke, Transparency = v and 0.25 or 0.55}, 0.2)
                if v then
                    for i, r in ipairs(rows) do
                        if i <= 8 then
                            r.txt.TextTransparency = 1
                            task.delay(0.05 + i * 0.03, function() if open and r.txt.Parent then play(r.txt, {TextTransparency = 0}, 0.25) end end)
                        end
                    end
                end
            end
            head.MouseEnter:Connect(function() if not open then play(st, {Color = ACCENT, Transparency = 0.35}, 0.18) end end)
            head.MouseLeave:Connect(function() if not open then play(st, {Color = T.stroke, Transparency = 0.55}, 0.22) end end)
            head.MouseButton1Click:Connect(function() setOpen(not open) end)

            build()
            if flag then Data.Features[flag] = getVal() end
            if o.Callback and (multi or single ~= nil) then task.spawn(function() o.Callback(getVal()) end) end
            local api = {}
            function api:Set(v, fire)
                setFrom(v) paint(true)
                if flag then Data.Features[flag] = getVal() end
                if fire and o.Callback then o.Callback(getVal()) end
            end
            function api:Get() return getVal() end
            function api:Refresh(newOpts) opts = newOpts or {} build() end
            return api
        end

        ----------------------------------------------------------------
        -- KEYBIND
        ----------------------------------------------------------------
        function K:Keybind(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local key = o.Default
            if type(key) == "string" then key = toKey(key) end
            local sv = flag and Data.Features[flag]
            if type(sv) == "string" then key = (sv ~= "None") and toKey(sv) or nil end
            local hasDesc = o.Desc ~= nil
            local h = hasDesc and 54 or 42
            local fr, st = card(h, true)
            label(fr, {Text = o.Title or flag or "Keybind", Position = UDim2.fromOffset(14, hasDesc and 9 or 0), Size = UDim2.new(1, -120, 0, hasDesc and 18 or h), Font = Enum.Font.GothamBold, TextSize = 13})
            if hasDesc then
                label(fr, {Text = o.Desc, Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -120, 0, 16), TextSize = 11, TextColor3 = DIM})
            end
            local pillF = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(64, 24), BackgroundColor3 = Color3.fromRGB(38, 34, 60), BorderSizePixel = 0}, fr)
            corner(pillF, 8)
            local ps = stroke(pillF, ACCENT, 1, 0.7)
            local kl = label(pillF, {Text = "", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextTruncate = Enum.TextTruncate.None})
            hover(fr, st)
            local listening = false
            local function show()
                local txt = listening and "..." or (key and key.Name or "None")
                kl.Text = txt
                play(pillF, {Size = UDim2.fromOffset(math.max(56, textW(txt, 11) + 22), 24)}, 0.3, Enum.EasingStyle.Back)
                play(ps, {Transparency = listening and 0.05 or 0.7}, 0.2)
                play(kl, {TextColor3 = listening and T.cyan or T.text}, 0.2)
            end
            show()
            fr.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                binding = true
                sfx("click")
                show()
            end)
            bind(UIS.InputBegan, function(i, gp)
                if listening then
                    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    listening = false
                    local changed = true
                    if i.KeyCode == Enum.KeyCode.Escape then changed = false
                    elseif i.KeyCode == Enum.KeyCode.Backspace then key = nil
                    else key = i.KeyCode end
                    show()
                    if changed then
                        if flag and not loading then Data.Features[flag] = key and key.Name or "None" saveN(curName) end
                        sfx("pop")
                        if o.OnChange then o.OnChange(key) end
                    end
                    task.delay(0.1, function() binding = false end)
                    return
                end
                if not gp and key and i.KeyCode == key and o.Callback then o.Callback(key) end
            end)
            if flag then Data.Features[flag] = key and key.Name or "None" end
            return {
                Set = function(_, k) if type(k) == "string" then k = toKey(k) end key = k show() end,
                Get = function() return key end,
            }
        end
        K.Bind = K.Keybind

        ----------------------------------------------------------------
        -- COLOR PICKER
        ----------------------------------------------------------------
        function K:ColorPicker(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local col = (typeof(o.Default) == "Color3") and o.Default or T.accent
            local sv = flag and Data.Features[flag]
            if type(sv) == "table" and #sv == 3 then col = Color3.fromRGB(sv[1], sv[2], sv[3]) end
            local hh, ss, vv = col:ToHSV()
            local H0, EXP, PH = 42, 160, 104
            local open = false
            local f, st, hf = card(H0)
            f.ClipsDescendants = true
            local head = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, H0)}, f)
            ripple(head)
            label(head, {Text = o.Title or flag or "Color", Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -140, 0, H0), Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 2})
            local hexL = label(head, {Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -50, 0, 0), Size = UDim2.fromOffset(70, H0), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code, TextSize = 11, TextColor3 = DIM, ZIndex = 2})
            local sw = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(28, 20), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 2}, head)
            corner(sw, 7) stroke(sw, WHITE, 1, 0.6)

            local svBox = new("Frame", {Position = UDim2.fromOffset(12, H0 + 4), Size = UDim2.new(1, -52, 0, PH), BackgroundColor3 = Color3.fromHSV(hh, 1, 1), BorderSizePixel = 0}, f)
            corner(svBox, 8)
            local wf = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, svBox)
            corner(wf, 8) new("UIGradient", {Transparency = NumberSequence.new(0, 1)}, wf)
            local bf = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, svBox)
            corner(bf, 8) new("UIGradient", {Transparency = NumberSequence.new(1, 0), Rotation = 90}, bf)
            local pt = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3}, svBox)
            corner(pt, FULL) stroke(pt, WHITE, 2, 0)
            local svHit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4}, svBox)

            local hue = new("Frame", {Position = UDim2.new(1, -34, 0, H0 + 4), Size = UDim2.fromOffset(20, PH), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
            corner(hue, 8)
            local ks = {}
            for i = 0, 6 do ks[#ks + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)) end
            new("UIGradient", {Color = ColorSequence.new(ks), Rotation = 90}, hue)
            local hp = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, hh, 0), Size = UDim2.new(1, 6, 0, 6), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, hue)
            corner(hp, 3) stroke(hp, Color3.new(0, 0, 0), 1, 0.5)
            local hHit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4}, hue)

            local function hex(c) return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
            local function apply(anim, silent)
                col = Color3.fromHSV(hh, ss, vv)
                sw.BackgroundColor3 = col
                svBox.BackgroundColor3 = Color3.fromHSV(hh, 1, 1)
                hexL.Text = hex(col)
                local p1, p2 = UDim2.fromScale(ss, 1 - vv), UDim2.new(0.5, 0, hh, 0)
                if anim then play(pt, {Position = p1}, 0.15) play(hp, {Position = p2}, 0.15)
                else pt.Position = p1 hp.Position = p2 end
                if not silent and o.Callback then o.Callback(col) end
            end
            local function persist()
                if flag and not loading then
                    Data.Features[flag] = {math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)}
                    saveN(curName)
                end
            end
            local function yOf(pos) return pos.Y + GuiService:GetGuiInset().Y end
            local function svFrom(pos)
                local ap, asz = svBox.AbsolutePosition, svBox.AbsoluteSize
                if asz.X <= 0 or asz.Y <= 0 then return end
                ss = math.clamp((pos.X - ap.X) / asz.X, 0, 1)
                vv = 1 - math.clamp((yOf(pos) - ap.Y) / asz.Y, 0, 1)
                apply(false)
            end
            local function hueFrom(pos)
                local ap, asz = hue.AbsolutePosition, hue.AbsoluteSize
                if asz.Y <= 0 then return end
                hh = math.clamp((yOf(pos) - ap.Y) / asz.Y, 0, 1)
                apply(false)
            end
            track(svHit,
                function(pos) scroll.ScrollingEnabled = false play(pt, {Size = UDim2.fromOffset(16, 16)}, 0.12) svFrom(pos) return true end,
                function(_, _, _, _, pos) svFrom(pos) end,
                function() scroll.ScrollingEnabled = true play(pt, {Size = UDim2.fromOffset(12, 12)}, 0.25, Enum.EasingStyle.Back) persist() end)
            track(hHit,
                function(pos) scroll.ScrollingEnabled = false play(hp, {Size = UDim2.new(1, 10, 0, 8)}, 0.12) hueFrom(pos) return true end,
                function(_, _, _, _, pos) hueFrom(pos) end,
                function() scroll.ScrollingEnabled = true play(hp, {Size = UDim2.new(1, 6, 0, 6)}, 0.25, Enum.EasingStyle.Back) persist() end)

            local function setOpen(v)
                open = v
                sfx(v and "expand" or "collapse")
                play(hf, {Size = UDim2.new(1, 0, 0, v and EXP or H0)}, 0.4, Enum.EasingStyle.Quint)
                play(st, {Color = v and ACCENT or T.stroke, Transparency = v and 0.25 or 0.55}, 0.2)
            end
            head.MouseEnter:Connect(function() if not open then play(st, {Color = ACCENT, Transparency = 0.35}, 0.18) end end)
            head.MouseLeave:Connect(function() if not open then play(st, {Color = T.stroke, Transparency = 0.55}, 0.22) end end)
            head.MouseButton1Click:Connect(function() setOpen(not open) end)

            apply(false, true)
            if flag then Data.Features[flag] = {math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)} end
            if o.Callback then task.spawn(function() o.Callback(col) end) end
            return {
                Set = function(_, c) if typeof(c) == "Color3" then hh, ss, vv = c:ToHSV() apply(true, true) end end,
                Get = function() return col end,
            }
        end
        ----------------------------------------------------------------
        -- ACCORDION: grup buka/tutup, isinya komponen apa saja
        --   local A = Tab:Accordion({Title = "Farm", Desc = "opsional", Open = false})
        --   A:Toggle({...}) A:Slider({...}) A:Button({...}) A:Dropdown({...}) dst
        --   A:Expand() A:Collapse() A:SetOpen(bool) A:IsOpen()
        ----------------------------------------------------------------
        function K:Accordion(o)
            o = o or {}
            local hasDesc = o.Desc ~= nil
            local HEAD = hasDesc and 54 or 44
            local PADT, PADB = 4, 10
            local open, animating, tok = false, false, 0
            local f, st, hf = card(HEAD)
            f.ClipsDescendants = true
            local head = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, HEAD)}, f)
            ripple(head)
            local rail = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, head)
            corner(rail, FULL) grad(rail, T.cyan, T.accent, 90)
            label(head, {Text = o.Title or "Accordion", Position = UDim2.fromOffset(14, hasDesc and 9 or 0), Size = UDim2.new(1, -56, 0, hasDesc and 18 or HEAD), Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 2})
            if hasDesc then
                label(head, {Text = o.Desc, Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -56, 0, 16), TextSize = 11, TextColor3 = DIM, ZIndex = 2})
            end
            local badge = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 2}, head)
            corner(badge, FULL)
            local arrow = label(badge, {Text = "›", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = WHITE, Rotation = 90, ZIndex = 3})

            local body = new("Frame", {Position = UDim2.fromOffset(0, HEAD), Size = UDim2.new(1, 0, 1, -HEAD), BackgroundTransparency = 1, BorderSizePixel = 0}, f)
            local tree = new("Frame", {Position = UDim2.fromOffset(14, 2), Size = UDim2.new(0, 2, 1, -10), BackgroundColor3 = WHITE, BorderSizePixel = 0}, body)
            corner(tree, FULL)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new(0.35, 1), Rotation = 90}, tree)
            local inner = new("Frame", {Position = UDim2.fromOffset(24, PADT), Size = UDim2.new(1, -34, 1, -(PADT + PADB)), BackgroundTransparency = 1, BorderSizePixel = 0}, body)
            local lay = new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, inner)
            local sub = buildComponents(scroll, inner, true)

            local function contentH()
                local fac = head.AbsoluteSize.Y / HEAD
                if fac < 0.01 then fac = math.max(rootScale.Scale * winScale.Scale, 0.01) end
                return math.floor(lay.AbsoluteContentSize.Y / fac + 0.5) + PADT + PADB
            end
            local function target() return UDim2.new(1, 0, 0, open and (HEAD + contentH()) or HEAD) end
            local function setOpen(v, instant)
                if v == open then return end
                open = v
                tok = tok + 1
                local my = tok
                if not instant then sfx(v and "expand" or "collapse") end
                play(arrow, {Rotation = v and -90 or 90}, 0.35, Enum.EasingStyle.Back)
                play(badge, {BackgroundTransparency = v and 0.2 or 0.85}, 0.25)
                play(rail, {Size = UDim2.new(0, 3, v and 0.7 or 0, 0)}, 0.3, Enum.EasingStyle.Back)
                play(st, {Color = v and ACCENT or T.stroke, Transparency = v and 0.25 or 0.55}, 0.25)
                if instant then hf.Size = target() return end
                animating = true
                play(hf, {Size = target()}, 0.42, Enum.EasingStyle.Quint)
                task.delay(0.45, function()
                    if tok == my then
                        animating = false
                        if open then hf.Size = target() end
                    end
                end)
                if v then
                    for i, b in ipairs(sub._kids) do
                        if b.Parent then
                            b.Position = UDim2.fromOffset(-24, 0)
                            task.delay(0.05 + math.min(i - 1, 8) * 0.045, function()
                                if open and b.Parent then play(b, {Position = UDim2.fromOffset(0, 0)}, 0.5, Enum.EasingStyle.Back) end
                            end)
                        end
                    end
                end
            end
            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if open and not animating then
                    local h = HEAD + contentH()
                    if math.abs(hf.Size.Y.Offset - h) > 1 then hf.Size = UDim2.new(1, 0, 0, h) end
                end
            end)
            head.MouseEnter:Connect(function()
                sfx("hover")
                if not open then
                    play(rail, {Size = UDim2.new(0, 3, 0.55, 0)}, 0.25, Enum.EasingStyle.Back)
                    play(st, {Color = ACCENT, Transparency = 0.35}, 0.18)
                end
            end)
            head.MouseLeave:Connect(function()
                if not open then
                    play(rail, {Size = UDim2.new(0, 3, 0, 0)}, 0.2)
                    play(st, {Color = T.stroke, Transparency = 0.55}, 0.22)
                end
            end)
            head.MouseButton1Click:Connect(function() setOpen(not open) end)

            function sub:Expand() setOpen(true) end
            function sub:Collapse() setOpen(false) end
            function sub:SetOpen(v) setOpen(v and true or false) end
            function sub:IsOpen() return open end
            if o.Open then setOpen(true, true) end
            return sub
        end
        K.Group = K.Accordion

        K.Color = K.ColorPicker

        return K
    end

    ------------------------------------------------------------------
    -- DASHBOARD
    ------------------------------------------------------------------
    local dashScroll = createTab("Dashboard", true)
    local D = buildComponents(dashScroll)
    local xyv, fpsV, pingV, fpsPush

    do -- profil
        local c = D._card(78)
        c.ClipsDescendants = true
        local sheen = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, c)
        corner(sheen, 12)
        new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new(0.86, 1), Rotation = 20}, sheen)
        local sweep = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 70, 2, 0), Position = UDim2.new(-0.2, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, c)
        new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.88), NumberSequenceKeypoint.new(1, 1)}}, sweep)
        TweenService:Create(sweep, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, 3.2), {Position = UDim2.new(1.2, 0, 0.5, 0)}):Play()
        local ring = new("Frame", {Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(14, 13), BackgroundColor3 = T.panel, BorderSizePixel = 0}, c)
        corner(ring, FULL)
        local rs = stroke(ring, WHITE, 2.2, 0)
        local rg = new("UIGradient", {Color = RING2}, rs)
        spin(rg, 3)
        local av = new("ImageLabel", {Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1}, ring)
        corner(av, FULL)
        task.spawn(function()
            local ok, img = pcall(function() return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
            if ok and av.Parent then av.Image = img end
        end)
        label(c, {Text = pl.DisplayName, Position = UDim2.fromOffset(80, 13), Size = UDim2.new(1, -94, 0, 20), Font = Enum.Font.GothamBold, TextSize = 15})
        label(c, {Text = "@"..pl.Name.."  •  "..tostring(placeId), Position = UDim2.fromOffset(80, 34), Size = UDim2.new(1, -94, 0, 14), TextSize = 11, TextColor3 = DIM})
        local sd = new("Frame", {Size = UDim2.fromOffset(7, 7), Position = UDim2.fromOffset(81, 58), BackgroundColor3 = T.ok, BorderSizePixel = 0}, c)
        corner(sd, FULL)
        TweenService:Create(sd, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.75}):Play()
        label(c, {Text = "Online", Position = UDim2.fromOffset(94, 54), Size = UDim2.fromOffset(80, 14), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.ok})
    end

    do -- statistik
        local hf = D._holder(58)
        local row = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
        D._enter(row)
        new("UIGridLayout", {CellSize = UDim2.new(1 / 3, -6, 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder}, row)
        local function stat(title, value, col, ord)
            local f = new("Frame", {BackgroundColor3 = T.card, BackgroundTransparency = 0.15, BorderSizePixel = 0, LayoutOrder = ord}, row)
            corner(f, 12) stroke(f, col, 1, 0.65) regTrans(f, 0) gloss(f)
            grad(f, WHITE, Color3.fromRGB(200, 196, 222), 90)
            local line = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0.5, 0, 0, 2), BackgroundColor3 = col, BorderSizePixel = 0}, f)
            corner(line, FULL)
            label(f, {Text = title, Position = UDim2.fromOffset(12, 9), Size = UDim2.new(1, -20, 0, 12), TextSize = 11, TextColor3 = DIM})
            return label(f, {Text = value, Position = UDim2.fromOffset(12, 25), Size = UDim2.new(1, -20, 0, 22), Font = Enum.Font.GothamBold, TextSize = 16})
        end
        fpsV = stat("FPS", "--", T.accent, 1)
        pingV = stat("Ping", "--", T.cyan, 2)
        stat("Build", "v"..VERSION, T.ok, 3)
    end

    do -- grafik FPS
        local c = D._card(92)
        label(c, {Text = "Frame rate history", Position = UDim2.fromOffset(14, 9), Size = UDim2.new(0.5, -14, 0, 14), TextSize = 11, TextColor3 = DIM})
        local avgL = label(c, {Text = "avg --  •  low --", Position = UDim2.new(0.5, 0, 0, 9), Size = UDim2.new(0.5, -14, 0, 14), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.cyan})
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
            corner(b, 2)
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
                play(bars[i], {Size = barSize(x), BackgroundColor3 = col}, 0.3)
                if x > 0 then
                    sum = sum + x cnt = cnt + 1
                    if x < low then low = x end
                end
            end
            if cnt > 0 then avgL.Text = "avg "..math.floor(sum / cnt + 0.5).."  •  low "..low end
        end
    end

    do -- info game
        local c, cs = D._card(56)
        c.BackgroundColor3 = Color3.fromRGB(36, 31, 20)
        cs.Color = T.warn cs.Transparency = 0.6
        label(c, {Text = gameName, Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -28, 0, 18), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255, 220, 90)})
        label(c, {Text = tostring(placeId).."  •  "..tostring(gameId), Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -28, 0, 16), TextSize = 11, TextColor3 = Color3.fromRGB(230, 210, 150)})
    end

    do -- tombol copy id
        local hf = D._holder(34)
        local row = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
        D._enter(row)
        new("UIGridLayout", {CellSize = UDim2.new(0.5, -4, 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder}, row)
        local function copyBtn(txt, val, ord)
            local b = new("TextButton", {Text = txt, Font = Enum.Font.GothamBold, TextSize = 12, BackgroundColor3 = T.card, BackgroundTransparency = 0.1, TextColor3 = T.text, AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = ord}, row)
            corner(b, 10) local s = stroke(b, ACCENT, 1, 0.65) regTrans(b, 0)
            hover(b, s)
            ripple(b)
            b.MouseButton1Click:Connect(function()
                local sv = tostring(val)
                copy(sv)
                notify("Copied", sv, ACCENT, 1.6)
                b.Text = "Copied"
                task.wait(1)
                b.Text = txt
            end)
        end
        copyBtn("Copy place ID", placeId, 1)
        copyBtn("Copy game ID", gameId, 2)
    end

    do -- koordinat
        local c = D._card(54)
        label(c, {Text = "Live coordinates", Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -90, 0, 14), TextSize = 11, TextColor3 = DIM})
        xyv = label(c, {Text = "X:0  Y:0  Z:0", Position = UDim2.fromOffset(14, 26), Size = UDim2.new(1, -90, 0, 20), Font = Enum.Font.Code, TextSize = 13, TextColor3 = Color3.fromRGB(130, 160, 255)})
        local cp = new("TextButton", {Text = "Copy", Size = UDim2.fromOffset(58, 28), Position = UDim2.new(1, -70, 0.5, -14), Font = Enum.Font.GothamBold, TextSize = 12, BackgroundColor3 = Color3.fromRGB(42, 38, 62), TextColor3 = T.text, AutoButtonColor = false, BorderSizePixel = 0}, c)
        corner(cp, FULL)
        hover(cp, nil, Color3.fromRGB(58, 52, 88), T.cardDown)
        ripple(cp)
        cp.MouseButton1Click:Connect(function()
            local t = xyv.Text
            copy(t)
            notify("Copied", t, ACCENT, 1.5)
            cp.Text = "Copied"
            task.wait(1)
            cp.Text = "Copy"
        end)
    end

    D:Section("Interface")
    local scaleSlider = D:Slider({
        Title = "UI scale", Min = 60, Max = 150, Step = 5, Suffix = "%",
        Default = math.floor(userScale * 100 + 0.5),
        OnRelease = function(v)
            userScale = v / 100
            applyScale()
            saveUI()
        end,
    })
    local initTrans = (type(Data.Features["UITrans"]) == "number") and Data.Features["UITrans"] or 0.15
    D:Slider({
        Title = "Panel transparency", Min = 0, Max = 60, Step = 5, Suffix = "%",
        Default = math.floor(initTrans * 100 + 0.5),
        Callback = function(v) applyTrans(v / 100) end,
        OnRelease = function(v) Data.Features["UITrans"] = v / 100 saveN(curName) end,
    })
    D:Toggle({
        Title = "Background blur", Desc = "Blur the game behind the menu", Flag = "UIBlur", Default = true,
        Callback = function(v) blurOn = v updateBlur() end,
    })
    D:Toggle({
        Title = "Animated background", Desc = "Aurora glow and floating particles", Flag = "UIAnim", Default = true,
        Callback = function(v) ambientOn = v ambient.Visible = v end,
    })
    D:Keybind({
        Title = "Menu key", Desc = "Show or hide the interface", Flag = "MenuKey", Default = toggleKey,
        OnChange = function(k) if k then toggleKey = k end end,
    })
    D:Button({
        Title = "Reset UI size", Desc = "Back to the default size and scale",
        Callback = function()
            winSize = DEFAULT_SIZE
            winPos = nil
            userScale = 1
            scaleSlider:Set(100)
            applyScale()
            layoutWin(true)
            saveUI()
            notify("UI reset", "Size and scale restored", ACCENT, 2)
        end,
    })

    D:Section("Sound")
    D:Toggle({
        Title = "UI sounds", Desc = "SORU signature sound effects", Flag = "UISound", Default = true,
        Callback = function(v) sndOn = v end,
    })
    D:Slider({
        Title = "Sound volume", Flag = "UIVol", Min = 0, Max = 100, Step = 5, Default = 60, Suffix = "%",
        Callback = function(v) sndVol = v / 100 end,
    })

    do -- discord
        local hf = D._holder(40)
        local d = new("TextButton", {Name = "Body", Size = UDim2.fromScale(1, 1), Text = "Join our Discord", Font = Enum.Font.GothamBold, TextSize = 13, BackgroundColor3 = Color3.fromRGB(88, 101, 242), TextColor3 = WHITE, AutoButtonColor = false, BorderSizePixel = 0}, hf)
        D._enter(d)
        corner(d, 12)
        grad(d, WHITE, Color3.fromRGB(205, 205, 235), 90)
        hover(d, nil, Color3.fromRGB(106, 118, 255), Color3.fromRGB(70, 82, 210))
        ripple(d)
        d.MouseButton1Click:Connect(function()
            copy("https://discord.gg/cHsx3RFYb")
            notify("Discord", "Invite copied to clipboard", Color3.fromRGB(88, 101, 242), 2)
            local old = d.Text
            d.Text = "Invite copied ✓"
            task.wait(1.5)
            d.Text = old
        end)
    end

    ------------------------------------------------------------------
    -- MODAL TUTUP
    ------------------------------------------------------------------
    local modalTok = 0
    local over = new("Frame", {Name = "Modal", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 100}, root)
    local dia = new("CanvasGroup", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(330, 190), BackgroundColor3 = Color3.fromRGB(28, 25, 44), BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 101}, over)
    corner(dia, 18) stroke(dia, T.stroke, 1, 0.3)
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
        play(over, {BackgroundTransparency = 0.5}, 0.22)
        play(diaScale, {Scale = 1}, 0.45, Enum.EasingStyle.Back)
        play(dia, {GroupTransparency = 0}, 0.2)
        play(iw, {Rotation = 0}, 0.7, Enum.EasingStyle.Elastic)
    end
    local function hideC()
        modalTok = modalTok + 1
        local tok = modalTok
        play(diaScale, {Scale = 0.94}, 0.18)
        play(dia, {GroupTransparency = 1}, 0.18)
        play(over, {BackgroundTransparency = 1}, 0.2)
        task.delay(0.22, function() if tok == modalTok then over.Visible = false end end)
    end
    local function delA()
        hideC()
        closeA()
        task.delay(0.55, function() gui:Destroy() end)
    end
    minB.MouseButton1Click:Connect(closeA)
    xB.MouseButton1Click:Connect(showC)
    no.MouseButton1Click:Connect(hideC)
    yes.MouseButton1Click:Connect(delA)

    ------------------------------------------------------------------
    -- LOOP LIVE (FPS, ping, koordinat) + input
    ------------------------------------------------------------------
    local fc, lfT = 0, os.clock()
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
            end
        end
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
        if binding or gp then return end
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
        corner(sp, 20)
        local sps = stroke(sp, WHITE, 1.5, 0.3)
        spin(new("UIGradient", {Color = RING}, sps), 3)
        local sc = new("UIScale", {Scale = 0.8}, sp)
        local ringF = new("Frame", {Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0.5, -30, 0, 20), BackgroundColor3 = T.panel, BorderSizePixel = 0}, sp)
        corner(ringF, FULL)
        local rs = stroke(ringF, WHITE, 2.4, 0)
        spin(new("UIGradient", {Color = RING2}, rs), 1.4)
        local ico = new("ImageLabel", {Size = UDim2.new(1, -18, 1, -18), Position = UDim2.fromOffset(9, 9), BackgroundTransparency = 1, Image = ICON}, ringF)
        local icoS = new("UIScale", {Scale = 1}, ico)
        TweenService:Create(icoS, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.12}):Play()
        label(sp, {Text = C.Title or "SORU HUB", Position = UDim2.new(0, 0, 0, 92), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = WHITE})
        local stL = label(sp, {Text = "Initializing...", Position = UDim2.new(0, 0, 0, 114), Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 11, TextColor3 = DIM})
        local barBg = new("Frame", {Position = UDim2.new(0, 30, 1, -26), Size = UDim2.new(1, -60, 0, 4), BackgroundColor3 = T.off, BorderSizePixel = 0}, sp)
        corner(barBg, FULL)
        local barF = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, barBg)
        corner(barF, FULL) grad(barF, T.accent, T.cyan, 0)
        play(sp, {GroupTransparency = 0}, 0.25)
        play(sc, {Scale = 1}, 0.5, Enum.EasingStyle.Back)
        task.spawn(function()
            local steps = {{"Loading assets...", 0.35}, {"Loading config...", 0.7}, {"Ready", 1}}
            for _, s in ipairs(steps) do
                stL.Text = s[1]
                play(barF, {Size = UDim2.fromScale(s[2], 1)}, 0.3)
                task.wait(0.32)
            end
            task.wait(0.15)
            play(sc, {Scale = 1.12}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            play(sp, {GroupTransparency = 1}, 0.3)
            task.wait(0.3)
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
    applyTrans(initTrans)

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
    Window.Notify = notify
    Window.ShowBadge = showNotSupportedBadge
    function Window:IsGame(id) return placeId == id or gameId == id end
    function Window:Toggle() toggleWin() end
    function Window:SetScale(pct) userScale = math.clamp((tonumber(pct) or 100) / 100, 0.6, 1.5) applyScale() saveUI() end
    function Window:SetBlur(b) blurOn = b and true or false updateBlur() end
    function Window:SetSound(b) sndOn = b and true or false end
    function Window:Destroy() delA() end

    if not isSupported then
        launcher.Visible = false
        task.spawn(function()
            task.wait(0.5)
            showNotSupportedBadge(kickOnFail)
            if not kickOnFail then notify("Blocked", "Game not supported", T.bad, 4) end
        end)
        function Window:Tab()
            local function dummy() return {Set = function() end, Get = function() return false end, Refresh = function() end} end
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
        S:Section("Basic")
        S:Button({Title = "Button", Desc = "Click me", Callback = function() notify("Button", "Clicked", ACCENT, 1.5) end})
        S:Toggle({Title = "Toggle", Desc = "On / off", Flag = "Demo_Toggle", Default = true})
        S:Slider({Title = "Slider", Flag = "Demo_Slider", Min = 0, Max = 100, Default = 40, Suffix = "%"})
        S:Section("Input")
        S:Textbox({Title = "Textbox", Flag = "Demo_Text", Placeholder = "Type here...", Callback = function(v) notify("Textbox", tostring(v), ACCENT, 1.5) end})
        S:Textbox({Title = "Number", Desc = "0 - 200", Flag = "Demo_Num", Numeric = true, Default = 16, Min = 0, Max = 200})
        S:Dropdown({Title = "Dropdown", Flag = "Demo_DD", Options = {"Alpha", "Beta", "Gamma"}, Default = "Alpha"})
        S:Dropdown({Title = "Multi dropdown", Flag = "Demo_MD", Multi = true, Options = {"One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"}, Default = {"One"}})
        S:Keybind({Title = "Keybind", Flag = "Demo_Key", Default = Enum.KeyCode.F, Callback = function(k) notify("Keybind", k.Name.." pressed", ACCENT, 1.2) end})
        S:ColorPicker({Title = "Color picker", Flag = "Demo_Col", Default = T.accent})
        S:Section("Accordion")
        local A = S:Accordion({Title = "Auto farm group", Desc = "Isinya bisa komponen apa saja", Open = true})
        A:Toggle({Title = "Auto farm", Flag = "Demo_AF", Default = false})
        A:Slider({Title = "Farm speed", Flag = "Demo_FS", Min = 1, Max = 10, Default = 5})
        A:Dropdown({Title = "Target", Flag = "Demo_TG", Options = {"Nearest", "Strongest", "Weakest"}, Default = "Nearest"})
        A:Button({Title = "Run once", Callback = function() notify("Accordion", "Button di dalam accordion", ACCENT, 1.5) end})
        S:Divider()
        S:Paragraph({Title = "Paragraph", Desc = "Teks panjang akan otomatis wrap ke bawah dan tinggi kartu menyesuaikan isi."})
        S:Label("Label biasa")
    end

    boot(function()
        openA(true)
        notify("SORU HUB v"..VERSION, "Loaded successfully", ACCENT, 3.5)
    end)
    return Window
end

return SORU
