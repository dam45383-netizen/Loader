--[[
    SORU HUB UI v2.2  (Neon Glass redesign + komponen lengkap, API kompatibel dengan v2.1)

    BARU DI v2.2
      Komponen : Textbox, Dropdown (single/multi), Keybind, ColorPicker
      Visual   : palet baru, kartu glass + highlight atas, sweep kilau saat hover,
                 toggle dengan glow ring, ikon tab opsional, window lebih bulat
      Animasi  : kartu masuk dari bawah (stagger), dropdown/colorpicker membal,
                 underline fokus di textbox, chip keybind melar

    API
      local Window = SORU:CreateWindow({Title = "SORU HUB", SupportedGames = {123}, KickIfNotSupported = true,
          ReferenceSize = Vector2.new(1280, 720), Scale = 1, ToggleKey = Enum.KeyCode.RightShift})
      local Tab = Window:Tab({Title = "Main", Icon = "★"})       -- Icon opsional
      Tab:Button({Title = "", Desc = "", Callback = function() end})
      Tab:Toggle({Title = "", Flag = "", Default = false, Desc = "", Callback = function(v) end})
      Tab:Slider({Title = "", Flag = "", Min = 0, Max = 100, Step = 1, Default = 50, Suffix = "%", Callback = function(v) end})
      Tab:Textbox({Title = "", Flag = "", Default = "", Placeholder = "", Numeric = false, Callback = function(text, enter) end})
      Tab:Dropdown({Title = "", Flag = "", Options = {"A", "B"}, Default = "A", Multi = false, Callback = function(v) end})
          -- Multi = true -> Default & Callback berupa tabel {"A","B"}; :Set(v) :Get() :Refresh(newOptions)
      Tab:Keybind({Title = "", Flag = "", Default = Enum.KeyCode.F, Callback = function(key) end})  -- Esc = hapus bind
      Tab:ColorPicker({Title = "", Flag = "", Default = Color3.fromRGB(255, 0, 0), Callback = function(c3) end})
      Tab:Section("Judul")
      Tab:Label("Teks")
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
-- THEME (Neon Glass)
----------------------------------------------------------------------
local T = {
    ink       = Color3.fromRGB(7, 6, 14),
    panel     = Color3.fromRGB(14, 12, 26),
    card      = Color3.fromRGB(23, 20, 40),
    cardHover = Color3.fromRGB(36, 31, 64),
    cardDown  = Color3.fromRGB(58, 46, 110),
    stroke    = Color3.fromRGB(70, 62, 112),
    text      = Color3.fromRGB(246, 244, 255),
    dim       = Color3.fromRGB(150, 144, 190),
    accent    = Color3.fromRGB(150, 98, 255),
    accent2   = Color3.fromRGB(96, 84, 255),
    cyan      = Color3.fromRGB(45, 212, 255),
    pink      = Color3.fromRGB(255, 92, 170),
    ok        = Color3.fromRGB(74, 222, 128),
    warn      = Color3.fromRGB(250, 204, 21),
    bad       = Color3.fromRGB(248, 113, 113),
    off       = Color3.fromRGB(52, 50, 74),
}
local ACCENT, ACCENT2, DIM = T.accent, T.accent2, T.dim
local WHITE = Color3.new(1, 1, 1)
local VERSION = "2.2"
local SHADOW_ID = "6014261993" -- kosongkan ("") kalau shadow tidak muncul
local FULL = UDim.new(1, 0)

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

local function textW(txt, size, font)
    local w = #tostring(txt) * (size * 0.6)
    pcall(function() w = TextService:GetTextSize(tostring(txt), size, font or Enum.Font.GothamBold, Vector2.new(800, 40)).X end)
    return w
end

-- hover + press untuk tombol (desktop & mobile)
local function hover(b, s, hoverC, downC)
    local bg0 = b.BackgroundColor3
    hoverC = hoverC or T.cardHover
    downC = downC or T.cardDown
    local c0, t0 = nil, nil
    if s then c0, t0 = s.Color, s.Transparency end
    b.MouseEnter:Connect(function()
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
    -- STATE + ENTRANCE (kartu masuk berurutan dari bawah)
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
            if body.Parent then body.Position = UDim2.fromOffset(0, 28) end
        end
        for i, body in ipairs(list) do
            task.delay(math.min(i - 1, 14) * 0.045, function()
                if body.Parent then play(body, {Position = UDim2.fromOffset(0, 0)}, 0.6, Enum.EasingStyle.Back).Completed:Connect(function() if body.Parent then body.Position = UDim2.fromOffset(0, 0) end end) end
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
    corner(win, 22)
    local winStroke = stroke(win, WHITE, 1.6, 0.35)
    local wsGrad = new("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.35, T.cyan), ColorSequenceKeypoint.new(0.7, T.pink), ColorSequenceKeypoint.new(1, T.accent)}}, winStroke)
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
    local ag = new("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.5, T.cyan), ColorSequenceKeypoint.new(1, T.accent)}}, accentLine)
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
    -- RIPPLE (klik) + SWEEP (kilau hover)
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

    local function sweepFx(btn)
        btn.ClipsDescendants = true
        local sw = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(-0.2, 0, 0.5, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 5}, btn)
        new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.75), NumberSequenceKeypoint.new(1, 1)}}, sw)
        btn.MouseEnter:Connect(function()
            sw.Position = UDim2.new(-0.2, 0, 0.5, 0)
            play(sw, {Position = UDim2.new(1.2, 0, 0.5, 0)}, 0.7, Enum.EasingStyle.Quint)
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
    local lGrad = new("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.5, T.cyan), ColorSequenceKeypoint.new(1, T.accent)}}, lStroke)
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

    local function openA()
        if isOpen then return end
        isOpen = true
        openTok = openTok + 1
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
    local function toggleWin() if isOpen then closeA() else openA() end end

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
    corner(logo, 11)
    local logoS = stroke(logo, WHITE, 1.4, 0.2)
    local logoG = new("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.5, T.cyan), ColorSequenceKeypoint.new(1, T.accent)}}, logoS)
    spin(logoG, 5)
    new("ImageLabel", {Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, Image = ICON}, logo)
    local titleL = label(tb, {Text = C.Title or "SORU HUB", Position = UDim2.fromOffset(60, 10), Size = UDim2.new(1, -170, 0, 18), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = WHITE})
    local tg = new("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, T.text), ColorSequenceKeypoint.new(0.35, T.text), ColorSequenceKeypoint.new(0.5, T.cyan), ColorSequenceKeypoint.new(0.65, T.text), ColorSequenceKeypoint.new(1, T.text)}, Offset = Vector2.new(-1, 0)}, titleL)
    TweenService:Create(tg, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 2.4), {Offset = Vector2.new(1, 0)}):Play()
    label(tb, {Text = "v"..VERSION.."  "..gameName, Position = UDim2.fromOffset(60, 29), Size = UDim2.new(1, -170, 0, 14), TextSize = 10, TextColor3 = DIM})
    local sepL = new("Frame", {Position = UDim2.fromOffset(10, 56), Size = UDim2.new(1, -20, 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 10}, win)
    new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 1)}}, sepL)

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
    local tabList = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -28), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.fromOffset(0, 0), ZIndex = 6}, side)
    label(side, {Text = "SORU HUB v"..VERSION, Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 10, TextColor3 = Color3.fromRGB(100, 94, 130)})
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
        cur = n
        if old then
            play(old.label, {TextColor3 = DIM}, 0.2)
            play(old.badge, {BackgroundTransparency = 0.82}, 0.2)
            play(old.frame, {GroupTransparency = 1}, 0.15)
            task.delay(0.17, function() if cur ~= oldName then old.frame.Visible = false end end)
        end
        local ne = tabs[n]
        ne.frame.Visible = true
        ne.frame.GroupTransparency = 1
        ne.frame.Position = UDim2.fromOffset(0, 14)
        play(ne.frame, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, 0.4)
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
        label(badge, {Text = icon or string.upper(string.sub(name, 1, 1)), Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.None, ZIndex = 8})
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
    local function buildComponents(scroll)
        local K = {}
        local order = 0
        local list = {}
        entranceLists[scroll] = list
        local function nextOrder() order = order + 1 return order end
        K._next = nextOrder

        local function holder(h, auto)
            local hf = new("Frame", {Name = "Holder", Size = UDim2.new(1, 0, 0, h or 0), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder()}, scroll)
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
            f.AnchorPoint = Vector2.new(0, 0)
            f.Position = UDim2.fromOffset(0, 0)
            corner(f, 12)
            local s = stroke(f, T.stroke, 1, 0.55)
            grad(f, WHITE, Color3.fromRGB(200, 196, 222), 90)
            local shine = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.8, 0, 0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 2}, f)
            new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)}}, shine)
            regTrans(f, 0)
            enter(f)
            if clickable then
                ripple(f)
                local bar = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
                corner(bar, FULL)
                grad(bar, T.cyan, T.accent, 90)
                local sc = new("UIScale", {Scale = 1}, f)
                f.MouseEnter:Connect(function() play(bar, {Size = UDim2.new(0, 3, 0.55, 0)}, 0.25, Enum.EasingStyle.Back) end)
                f.MouseLeave:Connect(function()
                    play(bar, {Size = UDim2.new(0, 3, 0, 0)}, 0.2)
                    play(sc, {Scale = 1}, 0.2)
                end)
                f.MouseButton1Down:Connect(function() play(sc, {Scale = 0.98}, 0.08) end)
                f.MouseButton1Up:Connect(function() play(sc, {Scale = 1}, 0.35, Enum.EasingStyle.Back) end)
            end
            return f, s
        end
        K._card = card

        function K:Section(text)
            if type(text) == "table" then text = text.Title or text.Text end
            text = tostring(text or "")
            local hf = holder(24)
            local f = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
            enter(f)
            local dot = new("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(6, 10), BackgroundColor3 = WHITE, BorderSizePixel = 0, Rotation = 45}, f)
            grad(dot, T.accent, T.cyan, 45)
            local w = textW(text, 12)
            label(f, {Text = text, Position = UDim2.fromOffset(18, 4), Size = UDim2.fromOffset(w + 4, 16), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(196, 176, 255), TextTruncate = Enum.TextTruncate.None})
            local lx = 18 + w + 14
            local line = new("Frame", {Position = UDim2.new(0, lx, 0, 12), Size = UDim2.new(1, -(lx + 6), 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new(0.3, 1)}, line)
            return f
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
            bt.MouseButton1Click:Connect(function() if o.Callback then o.Callback() end end)
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
            local tst = stroke(tgb, ACCENT, 4, curV and 0.6 or 1)
            local onF = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = curV and 0 or 1, BorderSizePixel = 0}, tgb)
            corner(onF, FULL)
            grad(onF, T.accent, T.cyan, 0)
            local dot = new("Frame", {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0, 0.5), Position = curV and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, tgb)
            corner(dot, FULL)
            hover(fr, st)
            local function upd(v, ns)
                play(onF, {BackgroundTransparency = v and 0 or 1}, 0.25)
                play(tst, {Transparency = v and 0.6 or 1}, 0.25)
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
            local chip = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 7), Size = UDim2.fromOffset(48, 22), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.82, BorderSizePixel = 0}, f)
            corner(chip, FULL) stroke(chip, ACCENT, 1, 0.55)
            local vl = label(chip, {Text = "", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextTruncate = Enum.TextTruncate.None})
            local hit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 0, 24)}, f)
            local bar = new("Frame", {Position = UDim2.new(0, 6, 0.5, -3), Size = UDim2.new(1, -12, 0, 6), BackgroundColor3 = Color3.fromRGB(42, 39, 64), BorderSizePixel = 0}, hit)
            corner(bar, FULL)
            local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, bar)
            corner(fill, FULL)
            grad(fill, T.accent2, T.cyan, 0)
            local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, bar)
            corner(knob, FULL)
            local kst = stroke(knob, ACCENT, 0, 1)

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
                chip.Size = UDim2.fromOffset(math.max(48, textW(txt, 11) + 22), 22)
                chip.BackgroundTransparency = 0.6
                play(chip, {BackgroundTransparency = 0.82}, 0.25)
            end
            local function set(v, silent, animate)
                v = math.clamp(math.floor(v / step + 0.5) * step, mn, mx)
                v = math.floor(v * 1000 + 0.5) / 1000
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
                    fromX(pos.X, true)
                    return true
                end,
                function(dx, dy, st, moved, pos) fromX(pos.X, false) end,
                function()
                    scroll.ScrollingEnabled = true
                    play(knob, {Size = UDim2.fromOffset(14, 14)}, 0.25, Enum.EasingStyle.Back)
                    play(kst, {Thickness = 0, Transparency = 1}, 0.25)
                    if flag and not loading then Data.Features[flag] = val saveN(curName) end
                    if o.OnRelease then o.OnRelease(val) end
                end)

            set(val, true, false)
            if flag then Data.Features[flag] = val end
            if o.Callback then task.spawn(function() o.Callback(val) end) end
            return {Set = function(_, v) set(v, true, true) end, Get = function() return val end}
        end

        ----------------------------------------------------------
        -- v2.2: Textbox, Dropdown, Keybind, ColorPicker
        ----------------------------------------------------------
        local function store(flag, v, nosave)
            if not flag then return end
            Data.Features[flag] = v
            if not nosave and not loading then saveN(curName) end
        end

        local function expandable(HEAD, titleText)
            local f, st = card(HEAD)
            f.ClipsDescendants = true
            local hf = f.Parent
            local head = new("TextButton", {Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3}, f)
            label(head, {Text = titleText, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.5, -14, 1, 0), Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 3})
            local arrow = label(head, {Text = "›", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(20, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = ACCENT, Rotation = 90, ZIndex = 3})
            local opened = false
            local function setOpen(v, fullH, onOpen)
                opened = v
                play(hf, {Size = UDim2.new(1, 0, 0, v and fullH or HEAD)}, 0.45, v and Enum.EasingStyle.Back or Enum.EasingStyle.Quint)
                play(arrow, {Rotation = v and 270 or 90}, 0.4, Enum.EasingStyle.Back)
                play(st, {Color = v and ACCENT or T.stroke, Transparency = v and 0.2 or 0.55}, 0.25)
                if v and onOpen then onOpen() end
            end
            head.MouseEnter:Connect(function() if not opened then play(st, {Color = ACCENT, Transparency = 0.25}, 0.18) end end)
            head.MouseLeave:Connect(function() if not opened then play(st, {Color = T.stroke, Transparency = 0.55}, 0.22) end end)
            ripple(head) sweepFx(head)
            return f, head, setOpen, function() return opened end
        end

        function K:Textbox(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local val = o.Default or ""
            if flag and type(Data.Features[flag]) == "string" then val = Data.Features[flag] end
            local f = card(58)
            label(f, {Text = o.Title or flag or "Textbox", Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 16), Font = Enum.Font.GothamBold, TextSize = 13})
            local box = new("Frame", {Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 24), BackgroundColor3 = Color3.fromRGB(10, 9, 20), BorderSizePixel = 0}, f)
            corner(box, 8)
            local bs = stroke(box, T.stroke, 1, 0.4)
            local tbx = new("TextBox", {Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = val, PlaceholderText = o.Placeholder or "Type here...", PlaceholderColor3 = Color3.fromRGB(100, 94, 130), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = o.ClearOnFocus == true, ClipsDescendants = true}, box)
            local ul = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0}, box)
            corner(ul, FULL) grad(ul, T.accent, T.cyan, 0)
            tbx.Focused:Connect(function()
                play(bs, {Color = ACCENT, Transparency = 0}, 0.2)
                play(ul, {Size = UDim2.new(1, -16, 0, 2)}, 0.4)
            end)
            tbx.FocusLost:Connect(function(enter)
                play(bs, {Color = T.stroke, Transparency = 0.4}, 0.25)
                play(ul, {Size = UDim2.new(0, 0, 0, 2)}, 0.25)
                local t = tbx.Text
                if o.Numeric and not tonumber(t) then tbx.Text = val return end
                val = t
                store(flag, val)
                if o.Callback then o.Callback(o.Numeric and tonumber(val) or val, enter) end
            end)
            store(flag, val, true)
            if o.Callback and val ~= "" then task.spawn(function() o.Callback(o.Numeric and tonumber(val) or val, false) end) end
            return {Set = function(_, s) val = tostring(s) tbx.Text = val store(flag, val) end, Get = function() return val end}
        end
        K.TextBox, K.Input = K.Textbox, K.Textbox

        function K:Dropdown(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local opts = o.Options or o.Values or {}
            local multi = o.Multi == true
            local HEAD, ROW, MAXV = 42, 28, 6
            local f, head, setOpen, isOpened = expandable(HEAD, o.Title or flag or "Dropdown")
            local vchip = label(head, {Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -38, 0.5, 0), Size = UDim2.new(0.5, -48, 0, 20), TextXAlignment = Enum.TextXAlignment.Right, TextSize = 12, TextColor3 = Color3.fromRGB(196, 176, 255), ZIndex = 3})
            local lst = new("ScrollingFrame", {Position = UDim2.fromOffset(8, HEAD), Size = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = ACCENT, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 3}, f)
            new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, lst)
            local sel, single = {}, nil
            local saved = flag and Data.Features[flag]
            if multi then
                local src = (type(saved) == "table" and saved) or (type(o.Default) == "table" and o.Default) or {}
                for _, n in ipairs(src) do sel[n] = true end
            else
                single = (type(saved) == "string" and saved) or o.Default
            end
            local rows = {}
            local function isSel(n) if multi then return sel[n] == true end return single == n end
            local function snapshot()
                if not multi then return single end
                local t = {}
                for _, n in ipairs(opts) do if sel[n] then t[#t + 1] = n end end
                return t
            end
            local function refreshText()
                if multi then
                    local t = snapshot()
                    vchip.Text = (#t == 0) and "None" or table.concat(t, ", ")
                else
                    vchip.Text = single or "Select..."
                end
            end
            local function paint(n)
                local r = rows[n]
                if not r then return end
                local on = isSel(n)
                play(r.bg, {BackgroundTransparency = on and 0.72 or 1}, 0.2)
                play(r.txt, {TextColor3 = on and WHITE or DIM}, 0.2)
                play(r.mark, {Size = UDim2.fromOffset(3, on and 14 or 0)}, 0.3, Enum.EasingStyle.Back)
            end
            local function listH() return math.min(#opts, MAXV) * (ROW + 2) end
            local function toggleOpen(v)
                setOpen(v, HEAD + listH() + 8, function()
                    for i, n in ipairs(opts) do
                        local r = rows[n]
                        if r then
                            r.txt.TextTransparency = 1
                            r.txt.Position = UDim2.fromOffset(2, 0)
                            task.delay(0.05 + i * 0.03, function() play(r.txt, {TextTransparency = 0, Position = UDim2.fromOffset(16, 0)}, 0.35, Enum.EasingStyle.Back) end)
                        end
                    end
                end)
                play(lst, {Size = UDim2.new(1, -16, 0, v and listH() or 0)}, 0.4)
            end
            local function choose(n)
                if multi then sel[n] = (not sel[n]) or nil else single = n end
                for _, x in ipairs(opts) do paint(x) end
                refreshText()
                store(flag, snapshot())
                if o.Callback then o.Callback(snapshot()) end
                if not multi then toggleOpen(false) end
            end
            local function build()
                for _, c in ipairs(lst:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                rows = {}
                for i, n in ipairs(opts) do
                    local b = new("TextButton", {Size = UDim2.new(1, -4, 0, ROW), BackgroundColor3 = ACCENT, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i, ZIndex = 4}, lst)
                    corner(b, 8)
                    local mark = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 5, 0.5, 0), Size = UDim2.fromOffset(3, 0), BackgroundColor3 = T.cyan, BorderSizePixel = 0, ZIndex = 5}, b)
                    corner(mark, FULL)
                    local tx = label(b, {Text = tostring(n), Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -24, 1, 0), TextSize = 12, TextColor3 = DIM, ZIndex = 5})
                    rows[n] = {bg = b, txt = tx, mark = mark}
                    b.MouseEnter:Connect(function() if not isSel(n) then play(b, {BackgroundTransparency = 0.88}, 0.12) end end)
                    b.MouseLeave:Connect(function() if not isSel(n) then play(b, {BackgroundTransparency = 1}, 0.18) end end)
                    b.MouseButton1Click:Connect(function() choose(n) end)
                    paint(n)
                end
                refreshText()
            end
            build()
            head.MouseButton1Click:Connect(function() toggleOpen(not isOpened()) end)
            store(flag, snapshot(), true)
            if o.Callback and (single ~= nil or next(sel) ~= nil) then task.spawn(function() o.Callback(snapshot()) end) end
            local api = {}
            function api:Set(v)
                if multi then
                    sel = {}
                    for _, n in ipairs(type(v) == "table" and v or {}) do sel[n] = true end
                else
                    single = v
                end
                for _, x in ipairs(opts) do paint(x) end
                refreshText()
            end
            function api:Get() return snapshot() end
            function api:Refresh(newOpts, keep)
                opts = newOpts or {}
                if not keep then sel = {} single = nil end
                build()
                if isOpened() then toggleOpen(true) end
            end
            return api
        end

        function K:Keybind(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local key = o.Default
            local sv = flag and Data.Features[flag]
            if type(sv) == "string" then
                local ok, k = pcall(function() return Enum.KeyCode[sv] end)
                if ok and k then key = k end
            end
            local f, st = card(42, true)
            label(f, {Text = o.Title or flag or "Keybind", Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -110, 1, 0), Font = Enum.Font.GothamBold, TextSize = 13})
            local chip = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(56, 24), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.82, BorderSizePixel = 0}, f)
            corner(chip, 8)
            local cs = stroke(chip, ACCENT, 1, 0.55)
            local kl = label(chip, {Text = "", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextTruncate = Enum.TextTruncate.None})
            hover(f, st)
            local listening = false
            local function show()
                local n = (key and key ~= Enum.KeyCode.Unknown) and key.Name or "None"
                kl.Text = n
                play(chip, {Size = UDim2.fromOffset(math.max(56, textW(n, 11) + 24), 24)}, 0.3, Enum.EasingStyle.Back)
            end
            show()
            f.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                kl.Text = "Press a key..."
                play(chip, {Size = UDim2.fromOffset(textW("Press a key...", 11) + 24, 24), BackgroundTransparency = 0.5}, 0.25, Enum.EasingStyle.Back)
                play(cs, {Color = T.cyan, Transparency = 0}, 0.2)
            end)
            bind(UIS.InputBegan, function(i, gp)
                if listening then
                    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    listening = false
                    key = (i.KeyCode == Enum.KeyCode.Escape) and Enum.KeyCode.Unknown or i.KeyCode
                    show()
                    play(chip, {BackgroundTransparency = 0.82}, 0.25)
                    play(cs, {Color = ACCENT, Transparency = 0.55}, 0.25)
                    store(flag, key.Name)
                    if o.OnChanged then o.OnChanged(key) end
                    return
                end
                if not gp and key and key ~= Enum.KeyCode.Unknown and i.KeyCode == key and o.Callback then o.Callback(key) end
            end)
            store(flag, key and key.Name or "Unknown", true)
            return {Set = function(_, k) key = k show() end, Get = function() return key end}
        end

        function K:ColorPicker(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local col = o.Default or T.accent
            local sv = flag and Data.Features[flag]
            if type(sv) == "table" and sv[1] and sv[2] and sv[3] then col = Color3.fromRGB(sv[1], sv[2], sv[3]) end
            local h, s, v = col:ToHSV()
            local HEAD, PH = 42, 96
            local f, head, setOpen, isOpened = expandable(HEAD, o.Title or flag or "Color")
            local sw = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -38, 0.5, 0), Size = UDim2.fromOffset(34, 22), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 3}, head)
            corner(sw, 8) stroke(sw, WHITE, 1, 0.6)
            local pad = new("Frame", {Position = UDim2.fromOffset(12, HEAD + 4), Size = UDim2.new(1, -52, 0, PH), BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, ZIndex = 3}, f)
            corner(pad, 8)
            local wh = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, pad)
            corner(wh, 8) new("UIGradient", {Transparency = NumberSequence.new(0, 1)}, wh)
            local bl = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 3}, pad)
            corner(bl, 8) new("UIGradient", {Transparency = NumberSequence.new(1, 0), Rotation = 90}, bl)
            local padCur = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6}, pad)
            corner(padCur, FULL) stroke(padCur, Color3.new(0, 0, 0), 1.5, 0.3)
            local hue = new("Frame", {Position = UDim2.new(1, -34, 0, HEAD + 4), Size = UDim2.fromOffset(22, PH), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, f)
            corner(hue, 8)
            local ks = {}
            for i = 0, 6 do ks[#ks + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i % 6) / 6, 1, 1)) end
            new("UIGradient", {Color = ColorSequence.new(ks), Rotation = 90}, hue)
            local hueCur = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 6, 0, 4), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6}, hue)
            corner(hueCur, FULL) stroke(hueCur, Color3.new(0, 0, 0), 1, 0.3)
            local function apply(fire)
                col = Color3.fromHSV(h, s, v)
                pad.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                sw.BackgroundColor3 = col
                padCur.Position = UDim2.fromScale(s, 1 - v)
                hueCur.Position = UDim2.fromScale(0.5, h)
                if fire and o.Callback then o.Callback(col) end
            end
            local function rgbT() return {math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)} end
            local function save() store(flag, rgbT()) end
            local function hit(parent) return new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 8}, parent) end
            local function padSet(pos)
                local ap, asz = pad.AbsolutePosition, pad.AbsoluteSize
                if asz.X <= 0 or asz.Y <= 0 then return end
                s = math.clamp((pos.X - ap.X) / asz.X, 0, 1)
                v = 1 - math.clamp((pos.Y - ap.Y) / asz.Y, 0, 1)
                apply(true)
            end
            local function hueSet(pos)
                local ap, asz = hue.AbsolutePosition, hue.AbsoluteSize
                if asz.Y <= 0 then return end
                h = math.clamp((pos.Y - ap.Y) / asz.Y, 0, 1)
                apply(true)
            end
            track(hit(pad), function(pos) scroll.ScrollingEnabled = false padSet(pos) return true end, function(dx, dy, st, moved, pos) padSet(pos) end, function() scroll.ScrollingEnabled = true save() end)
            track(hit(hue), function(pos) scroll.ScrollingEnabled = false hueSet(pos) return true end, function(dx, dy, st, moved, pos) hueSet(pos) end, function() scroll.ScrollingEnabled = true save() end)
            head.MouseButton1Click:Connect(function() setOpen(not isOpened(), HEAD + PH + 14) end)
            apply(false)
            store(flag, rgbT(), true)
            if o.Callback then task.spawn(function() o.Callback(col) end) end
            return {Set = function(_, c3) h, s, v = c3:ToHSV() apply(false) save() end, Get = function() return col end}
        end
        K.Colorpicker = K.ColorPicker

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
        local rg = new("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.5, T.cyan), ColorSequenceKeypoint.new(1, T.accent)}}, rs)
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
            corner(f, 12) stroke(f, col, 1, 0.65) regTrans(f, 0)
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
            ripple(b) sweepFx(b)
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

    do -- discord
        local hf = D._holder(40)
        local d = new("TextButton", {Name = "Body", Size = UDim2.fromScale(1, 1), Text = "Join our Discord", Font = Enum.Font.GothamBold, TextSize = 13, BackgroundColor3 = Color3.fromRGB(88, 101, 242), TextColor3 = WHITE, AutoButtonColor = false, BorderSizePixel = 0}, hf)
        D._enter(d)
        corner(d, 12)
        grad(d, WHITE, Color3.fromRGB(205, 205, 235), 90)
        hover(d, nil, Color3.fromRGB(106, 118, 255), Color3.fromRGB(70, 82, 210))
        ripple(d) sweepFx(d)
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
                fpsV.Text = tostring(fps)
                fpsV.TextColor3 = (fps >= 50 and T.ok) or (fps >= 30 and T.warn) or T.bad
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
    local toggleKey = C.ToggleKey or Enum.KeyCode.RightShift
    bind(UIS.InputBegan, function(i, gp)
        if not gp and i.KeyCode == toggleKey then toggleWin() end
    end)
    bind(gui:GetPropertyChangedSignal("AbsoluteSize"), applyScale)

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
    function Window:Destroy() delA() end

    if not isSupported then
        launcher.Visible = false
        task.spawn(function()
            task.wait(0.5)
            showNotSupportedBadge(kickOnFail)
            if not kickOnFail then notify("Blocked", "Game not supported", T.bad, 4) end
        end)
        -- stub supaya script yang memanggil Window:Tab() tidak error
        function Window:Tab()
            local function dummy() return {Set = function() end, Get = function() return false end} end
            return setmetatable({}, {__index = function() return dummy end})
        end
        return Window
    end

    function Window:Tab(c)
        c = c or {}
        local scroll = createTab(c.Title or "Tab", false, c.Icon)
        return buildComponents(scroll)
    end

    openA()
    notify("SORU HUB v"..VERSION, "Loaded successfully", ACCENT, 3.5)
    return Window
end

return SORU
