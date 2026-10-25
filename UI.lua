local SORU = {Version = "8.0"}
local Players, TweenService, UIS, RunService = game:GetService("Players"), game:GetService("TweenService"), game:GetService("UserInputService"), game:GetService("RunService")
local Http, TextService, GuiService, Lighting = game:GetService("HttpService"), game:GetService("TextService"), game:GetService("GuiService"), game:GetService("Lighting")

local VERSION, CFG = SORU.Version, "SORU_HUB"
local CFGS = CFG .. "/configs"
pcall(function()
    if makefolder then for _, p in ipairs({CFG, CFGS}) do if not isfolder(p) then makefolder(p) end end end
end)

-- ICON (diunduh sekali, disimpan di folder SORU_HUB)
local ICON_URL = "https://raw.githubusercontent.com/dam45383-netizen/UI/main/SORU_S_ICON_1024.png"
local function getIcon()
    if not (isfile and getcustomasset and writefile) then return "" end
    local p = CFG .. "/SORU_S_ICON_1024.png"
    local function asset() local ok, a = pcall(getcustomasset, p) return (ok and type(a) == "string" and a ~= "") and a or nil end
    local ok, has = pcall(isfile, p)
    if ok and has and asset() then return asset() end
    local ok2, data = pcall(function() return game:HttpGet(ICON_URL) end)
    if ok2 and type(data) == "string" and #data > 64 and not data:find("^404") then
        pcall(writefile, p, data)
        task.wait(0.05)
        return asset() or ""
    end
    return ""
end
local ICON = getIcon()
local LOGO = (ICON ~= "") and ICON or "rbxassetid://119521146805131" -- logo Vora kalau ICON gagal diunduh

SORU.Icons = {
    home = "home", player = "rbxassetid://12120698352", web = "rbxassetid://137601480983962", bag = "rbxassetid://8601111810",
    shop = "rbxassetid://4985385964", cart = "rbxassetid://128874923961846", plug = "rbxassetid://137601480983962",
    settings = "rbxassetid://70386228443175", loop = "rbxassetid://122032243989747", gps = "rbxassetid://17824309485",
    compas = "rbxassetid://125300760963399", gamepad = "rbxassetid://84173963561612", boss = "rbxassetid://13132186360",
    scroll = "rbxassetid://114127804740858", menu = "rbxassetid://6340513838", crosshair = "rbxassetid://12614416478",
    user = "rbxassetid://108483430622128", stat = "rbxassetid://12094445329", eyes = "rbxassetid://14321059114",
    sword = "rbxassetid://82472368671405", discord = "rbxassetid://94434236999817", star = "rbxassetid://107005941750079",
    skeleton = "rbxassetid://17313330026", payment = "rbxassetid://18747025078", scan = "rbxassetid://109869955247116",
    alert = "rbxassetid://73186275216515", question = "rbxassetid://17510196486", idea = "rbxassetid://16833255748",
    strom = "rbxassetid://13321880293", water = "rbxassetid://13321880293", dcs = "rbxassetid://15310731934",
    start = "rbxassetid://108886429866687", next = "rbxassetid://12662718374", rod = "rbxassetid://103247953194129",
    fish = "rbxassetid://97167558235554", bell = "rbxassetid://73186275216515",
}

----------------------------------------------------------------------
-- THEME: palet Vora. Aksen bisa diganti lewat Settings (45 preset)
----------------------------------------------------------------------
local T = {
    bg = Color3.fromRGB(10, 12, 25), side = Color3.fromRGB(15, 18, 32), el = Color3.fromRGB(25, 30, 50),
    hover = Color3.fromRGB(35, 45, 70), outline = Color3.fromRGB(40, 60, 90), text = Color3.fromRGB(255, 255, 255),
    dim = Color3.fromRGB(180, 200, 230), off = Color3.fromRGB(45, 45, 50),
    ok = Color3.fromRGB(46, 204, 113), warn = Color3.fromRGB(241, 196, 15), bad = Color3.fromRGB(231, 76, 60),
    accent = Color3.fromRGB(0, 140, 210), accent2 = Color3.fromRGB(0, 100, 180),
}
local WHITE = Color3.new(1, 1, 1)
local QUINT, BACK = Enum.EasingStyle.Quint, Enum.EasingStyle.Back
local XL, XC, XR = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right
local NOTRUNC = Enum.TextTruncate.None
local H1, H2 = 38, 50 -- tinggi elemen: satu baris / dengan deskripsi

local THEMES, ORDER = {}, {}
local function hx(s)
    s = s:gsub("#", "")
    return Color3.fromRGB(tonumber(s:sub(1, 2), 16), tonumber(s:sub(3, 4), 16), tonumber(s:sub(5, 6), 16))
end
function SORU.AddTheme(name, a, b)
    if not THEMES[name] then ORDER[#ORDER + 1] = name end
    THEMES[name] = {hx(a), hx(b)}
end
for _, s in ipairs({
    "Vora 008CD2 0064B4", "Violet 9160FF 5E6AFF", "Ocean 28A0FF 3870FF", "Crimson FF4664 DC2650", "Emerald 2DD496 10AA78",
    "Sunset FF963C F0465A", "Rose FF6996 E63C78", "Sakura FF96BE DC6ED2", "Mint 50E6BE 28BEAA", "Aqua 1ED2E6 2896EB",
    "Ice 82C8FF 648CFF", "Midnight 5A6EFF 3C46C8", "Gold FABE28 EB8C1E", "Lava FF5F32 E12D2D", "Toxic A0F028 5AC83C",
    "Cyber FF28C8 8C3CFF", "Orchid D26EFF A050E6", "Forest 50BE64 288C5A", "Coffee D29664 AA6E46", "Peach FFA078 F56E64",
    "Steel 7896BE 506EA0", "Mono BEC2D6 787EA0", "Ruby E0314B B3203F", "Coral FF6F61 F2496B", "Amber FFB000 E08700",
    "Lime B6F03C 7CCB2B", "Jade 2FBF8F 1F8F6B", "Teal 14B8A6 0E8F83", "Cobalt 3D6BFF 2447D6", "Indigo 6366F1 4338CA",
    "Grape 9B4DE0 6A2FB8", "Lavender B49CFF 8E78E6", "Bubblegum FF7EC8 E255A8", "HotPink FF2E93 D6106F",
    "Synthwave FF2E97 7B2FF7", "Vaporwave FF71CE B967FF", "Tokyo F72585 7209B7", "Dracula BD93F9 6272A4",
    "Nord 88C0D0 5E81AC", "Mocha CBA6F7 89B4FA", "Matrix 00FF66 00B347", "Aurora 4DE8B0 5C7CFA",
    "Nebula 7B5CFF 4A2FBF", "Cyan 00D8FF 0094E0", "Ember FF7A18 E0401C",
}) do SORU.AddTheme(s:match("(%S+)%s+(%x+)%s+(%x+)")) end

-- elemen berwarna aksen didaftarkan di sini; ganti tema = tulis ulang semuanya
local skins, themeFns = {}, {}
local NOANIM = false
local function skin(o, prop, key)
    skins[#skins + 1] = {o, prop, key}
    o[prop] = T[key]
    return o
end
local function applyTheme(name)
    local p = THEMES[name]
    if not p then return false end
    T.accent, T.accent2 = p[1], p[2]
    for i = #skins, 1, -1 do
        local e = skins[i]
        if e[1].Parent == nil then table.remove(skins, i) else e[1][e[2]] = T[e[3]] end
    end
    for _, fn in ipairs(themeFns) do pcall(fn) end
    return true
end

----------------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------------
-- W: 1 = Gotham (isi), 2 = GothamMedium (label), 3 = GothamBold (judul)
local FONT = {Font.fromEnum(Enum.Font.Gotham), Font.fromEnum(Enum.Font.GothamMedium), Font.fromEnum(Enum.Font.GothamBold)}

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return new("UICorner", {CornerRadius = (r == "full") and UDim.new(1, 0) or UDim.new(0, r or 6)}, o) end
local function stroke(o, col, th, tr)
    return new("UIStroke", {Color = col or T.outline, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
end
-- shadow lembut ala Vora: dibuat SEBELUM elemen yang dibayangi (sibling di belakangnya)
local function shadow(parent, z)
    return new("ImageLabel", {Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 34, 1, 34),
        BackgroundTransparency = 1, Image = "rbxassetid://6015897843", ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = z or 0}, parent)
end
local function text(parent, p)
    local d = {BackgroundTransparency = 1, BorderSizePixel = 0, FontFace = FONT[2], TextSize = 14, TextColor3 = T.text, TextXAlignment = XL, TextTruncate = Enum.TextTruncate.AtEnd}
    for k, v in pairs(p) do
        if k == "W" then d.FontFace = FONT[v] else d[k] = v end
    end
    return new("TextLabel", d, parent)
end
local function logoImg(parent, props)
    props.BackgroundTransparency = 1
    props.Image = LOGO
    local img = new("ImageLabel", props, parent)
    if ICON == "" then skin(img, "ImageColor3", "accent") end
    return img
end
local function play(o, p, t, style, dir)
    if NOANIM then for k, v in pairs(p) do o[k] = v end return end
    TweenService:Create(o, TweenInfo.new(t or 0.2, style or QUINT, dir or Enum.EasingDirection.Out), p):Play()
end
local function safe(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[SORU HUB] " .. tostring(err)) end
end
local function copy(s) if setclipboard then setclipboard(s) elseif toclipboard then toclipboard(s) end end
local function toKey(n)
    local ok, v = pcall(function() return Enum.KeyCode[n] end)
    return ok and v or nil
end
local function textW(s, size)
    local ok, v = pcall(function() return TextService:GetTextSize(tostring(s), size, Enum.Font.GothamBold, Vector2.new(1000, 100)).X end)
    return ok and v or (#tostring(s) * size * 0.6)
end

-- drag generik: onBegin(pos) -> state, onMove(dx, dy, state, moved, pos), onEnd(moved, state)
local function track(handle, onBegin, onMove, onEnd)
    handle.InputBegan:Connect(function(input)
        local ut = input.UserInputType
        if ut ~= Enum.UserInputType.MouseButton1 and ut ~= Enum.UserInputType.Touch then return end
        local start = input.Position
        local state = onBegin and onBegin(start) or nil
        local moved, ended, conn = false, false, nil
        conn = UIS.InputChanged:Connect(function(i)
            local it = i.UserInputType
            if it == Enum.UserInputType.MouseMovement or it == Enum.UserInputType.Touch then
                local dx, dy = i.Position.X - start.X, i.Position.Y - start.Y
                if not moved and (math.abs(dx) > 4 or math.abs(dy) > 4) then moved = true end
                if onMove then onMove(dx, dy, state, moved, i.Position) end
            end
        end)
        input.Changed:Connect(function()
            local st = input.UserInputState
            if (st == Enum.UserInputState.End or st == Enum.UserInputState.Cancel) and not ended then
                ended = true
                conn:Disconnect()
                if onEnd then onEnd(moved, state) end
            end
        end)
    end)
end

-- judul + deskripsi di sisi kiri elemen (rpad = ruang kosong di kanan, wfrac = lebar relatif)
local function rowText(f, title, desc, rpad, wfrac)
    local w = wfrac or 1
    local t = text(f, {Text = tostring(title), Position = UDim2.fromOffset(12, desc and 8 or 0),
        Size = desc and UDim2.new(w, -(12 + rpad), 0, 20) or UDim2.new(w, -(12 + rpad), 1, 0), W = desc and 3 or 2})
    local d = desc and text(f, {Text = tostring(desc), Position = UDim2.fromOffset(12, 26), Size = UDim2.new(w, -(12 + rpad), 0, 14), TextSize = 12, TextColor3 = T.dim, W = 1})
    return t, d
end

-- kotak input: fill sidebar, outline tipis, outline aksen saat fokus
local function inputBox(parent, p)
    local wrap = new("Frame", {BackgroundColor3 = T.side, BorderSizePixel = 0, ClipsDescendants = true}, parent)
    corner(wrap, 4)
    local st = stroke(wrap, T.outline, 1, 0.7)
    for k, v in pairs(p.wrap or {}) do wrap[k] = v end
    local box = new("TextBox", {Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        Text = p.text or "", PlaceholderText = p.placeholder or "", PlaceholderColor3 = T.dim, TextColor3 = T.text, FontFace = FONT[1], TextSize = 13,
        TextXAlignment = XL, ClearTextOnFocus = p.clear or false}, wrap)
    box.Focused:Connect(function() play(st, {Color = T.accent, Transparency = 0}, 0.2) end)
    box.FocusLost:Connect(function() play(st, {Color = T.outline, Transparency = 0.7}, 0.2) end)
    return wrap, box
end

-- ikon tab: "home" (digambar) | gambar (nama di SORU.Icons / rbxassetid / id angka) | huruf / simbol. Return fungsi pewarna
local function tabIcon(b, icon)
    local ic = icon and (SORU.Icons[icon] or tostring(icon)) or nil
    if ic == nil or ic == "" then return nil end
    local box = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1}, b)
    if ic == "home" then
        local parts = {}
        for _, d in ipairs({{11, 11, -3, 45}, {13, 8, 4, 0}}) do
            local p = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, d[3]), Size = UDim2.fromOffset(d[1], d[2]), Rotation = d[4], BackgroundColor3 = T.dim, BorderSizePixel = 0}, box)
            corner(p, 2)
            parts[#parts + 1] = p
        end
        return function(c) for _, f in ipairs(parts) do f.BackgroundColor3 = c end end
    elseif ic:match("^rbxasset") or ic:match("^%d%d%d+$") then
        local img = new("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = ic:match("^%d+$") and ("rbxassetid://" .. ic) or ic, ImageColor3 = T.dim}, box)
        return function(c) play(img, {ImageColor3 = c}, 0.2) end
    end
    local gl = text(box, {Text = ic, Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 16, TextColor3 = T.dim, TextTruncate = NOTRUNC})
    return function(c) gl.TextColor3 = c end
end

----------------------------------------------------------------------
-- DRAWER: dropdown = panel geser di sisi kanan window (satu per host, dibuat saat pertama dipakai)
----------------------------------------------------------------------
local function makeDrawer(host, rad)
    local D, spec, rows, tok = {}, nil, {}, 0
    local ov = new("TextButton", {Name = "Drawer", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, Visible = false, ClipsDescendants = true, ZIndex = 500, BorderSizePixel = 0}, host)
    corner(ov, rad)
    local dr = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 200, 0.5, 0), Size = UDim2.new(0, 180, 1, -20), BackgroundTransparency = 1, Active = true}, ov)
    shadow(dr)
    local body = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.side, BorderSizePixel = 0, Active = true}, dr)
    corner(body, 6)
    skin(stroke(body, T.accent, 1, 0.5), "Color", "accent")
    local _, box = inputBox(body, {placeholder = "Search...", wrap = {Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 0, 28), BackgroundColor3 = T.bg, BackgroundTransparency = 0.5}})
    local list = new("ScrollingFrame", {Position = UDim2.fromOffset(5, 38), Size = UDim2.new(1, -10, 1, -43), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, body)
    skin(list, "ScrollBarImageColor3", "accent")
    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)

    local function repaint() for _, r in ipairs(rows) do r.paint() end end
    function D.close()
        if not ov.Visible then return end
        spec = nil
        tok = tok + 1
        local my = tok
        play(ov, {BackgroundTransparency = 1}, 0.25)
        play(dr, {Position = UDim2.new(1, 200, 0.5, 0)}, 0.25, QUINT, Enum.EasingDirection.In)
        task.delay(NOANIM and 0 or 0.27, function() if tok == my then ov.Visible = false end end)
    end
    function D.open(sp)
        spec = sp
        tok = tok + 1
        box.Text = ""
        list.CanvasPosition = Vector2.new(0, 0)
        for _, r in ipairs(rows) do r.btn:Destroy() end
        rows = {}
        for i, n in ipairs(sp.options) do
            local name = tostring(n)
            local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i}, list)
            local tx, cbox, mark = 8, nil, nil
            if sp.multi then
                cbox = new("Frame", {Position = UDim2.new(0, 8, 0.5, -7), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.bg, BorderSizePixel = 0}, b)
                corner(cbox, 3)
                mark = new("ImageLabel", {BackgroundTransparency = 1, Image = "rbxassetid://6031094667", Size = UDim2.new(1, 2, 1, 2), Position = UDim2.fromOffset(-1, -1), ImageTransparency = 1}, cbox)
                tx = 30
            end
            local sc = sp.swatch and sp.swatch(name)
            if sc then
                local dot = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, tx, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = sc, BorderSizePixel = 0}, b)
                corner(dot, "full")
                tx = tx + 20
            end
            local lb = text(b, {Text = name, Position = UDim2.fromOffset(tx, 0), Size = UDim2.new(1, -(tx + 6), 1, 0), W = 3, TextSize = 13, TextColor3 = T.dim})
            local r = {btn = b, name = name}
            function r.paint()
                local on = sp.isSel(name)
                if sp.multi then
                    cbox.BackgroundColor3 = on and T.accent or T.bg
                    mark.ImageTransparency = on and 0 or 1
                    lb.TextColor3 = on and T.text or T.dim
                    lb.FontFace = on and FONT[3] or FONT[2]
                else
                    lb.TextColor3 = on and T.accent or T.dim
                end
            end
            b.MouseEnter:Connect(function() if not sp.isSel(name) then lb.TextColor3 = T.text end end)
            b.MouseLeave:Connect(r.paint)
            b.MouseButton1Click:Connect(function()
                sp.pick(name)
                repaint()
                if not sp.multi then D.close() end
            end)
            r.paint()
            rows[i] = r
        end
        ov.Visible = true
        play(ov, {BackgroundTransparency = 0.5}, 0.25)
        dr.Position = UDim2.new(1, 200, 0.5, 0)
        play(dr, {Position = UDim2.new(1, -16, 0.5, 0)}, 0.25)
    end
    box:GetPropertyChangedSignal("Text"):Connect(function()
        local q = box.Text:lower()
        for _, r in ipairs(rows) do r.btn.Visible = (q == "") or (r.name:lower():find(q, 1, true) ~= nil) end
    end)
    ov.MouseButton1Click:Connect(D.close)
    return D
end

local function newCtx(hostF, rad)
    local c = {}
    function c.drawer()
        if not c.d then c.d = makeDrawer(hostF, rad) end
        return c.d
    end
    return c
end

----------------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------------
function SORU:CreateWindow(C)
    C = C or {}
    skins, themeFns = {}, {}
    local pl = Players.LocalPlayer
    local pg = pl:WaitForChild("PlayerGui")
    local host = pg
    pcall(function() if gethui then host = gethui() end end)
    for _, h in ipairs({host, pg}) do
        local old = h:FindFirstChild("SORU_HUB")
        if old then old:Destroy() end
    end
    pcall(function()
        local ob = Lighting:FindFirstChild("SORU_Blur")
        if ob then ob:Destroy() end
    end)
    local gui = new("ScreenGui", {Name = "SORU_HUB", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 100})
    gui.Parent = host

    local conns = {}
    local function bind(sig, fn) local c = sig:Connect(fn) conns[#conns + 1] = c return c end
    local blurFx = nil
    gui.Destroying:Connect(function()
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        if blurFx then pcall(function() blurFx:Destroy() end) end
    end)

    -- CONFIG: nilai komponen ber-Flag disimpan otomatis per game
    local placeId, gameId = game.PlaceId, game.GameId
    local curName = tostring(placeId)
    local Data, Reg = {Features = {}}, {}
    local function cpath(n) return CFGS .. "/" .. tostring(n) .. ".json" end
    local function readCfg(n)
        if not (isfile and readfile) then return nil end
        local ok, d = pcall(function() if isfile(cpath(n)) then return Http:JSONDecode(readfile(cpath(n))) end end)
        if ok and type(d) == "table" and type(d.Features) == "table" then return d end
        return nil
    end
    local function saveCfg(n) pcall(function() writefile(cpath(n or curName), Http:JSONEncode(Data)) end) end
    Data = readCfg(curName) or readCfg("default") or Data
    local F, saveQ = Data.Features, false
    local function persist()
        if saveQ then return end
        saveQ = true
        task.delay(0.5, function() saveQ = false saveCfg() end)
    end

    NOANIM = (C.NoAnim == true) or (F.UINoAnim == true)
    local curTheme = (type(F.UITheme) == "string" and THEMES[F.UITheme]) and F.UITheme or "Vora"
    applyTheme(curTheme)
    local toggleKey = C.ToggleKey or Enum.KeyCode.RightControl
    if type(F.MenuKey) == "string" then toggleKey = toKey(F.MenuKey) or toggleKey end
    local binding, activeStop = false, nil

    ------------------------------------------------------------------
    -- ROOT + SKALA (anti-DPI)
    ------------------------------------------------------------------
    local REF = C.ReferenceSize or Vector2.new(1280, 720)
    local root = new("Frame", {Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)
    local rootScale = new("UIScale", {}, root)
    local DEFAULT, MINS, MAXS = Vector2.new(700, 450), Vector2.new(400, 300), Vector2.new(980, 640)
    local winSize = Vector2.new(math.clamp(tonumber(F.UIW) or DEFAULT.X, MINS.X, MAXS.X), math.clamp(tonumber(F.UIH) or DEFAULT.Y, MINS.Y, MAXS.Y))
    local winPos, curPos, virt = nil, Vector2.new(), Vector2.new(REF.X, REF.Y)
    local layoutWin, layoutLauncher

    local function viewport()
        local s = gui.AbsoluteSize
        if s.X < 10 or s.Y < 10 then
            local cam = workspace.CurrentCamera
            s = cam and cam.ViewportSize or REF
        end
        return s
    end
    local function fitOf(vp) return math.clamp(math.min(vp.X / REF.X, vp.Y / REF.Y), 0.4, 5) end
    local function autoScale() -- HP/tablet: window ~82% tinggi layar
        if not UIS.TouchEnabled then return 1 end
        local vp = viewport()
        return math.clamp(0.82 * vp.Y / (winSize.Y * fitOf(vp)), 0.6, 1.5)
    end
    local userScale = math.clamp(C.Scale or ((tonumber(F.UIScale) or (autoScale() * 100)) / 100), 0.6, 1.5)
    local function applyScale()
        local vp = viewport()
        local s = math.clamp(fitOf(vp) * userScale, 0.3, 6)
        rootScale.Scale = s
        virt = Vector2.new(vp.X / s, vp.Y / s)
        root.Size = UDim2.fromOffset(virt.X, virt.Y)
        if layoutWin then layoutWin() end
        if layoutLauncher then layoutLauncher() end
    end

    -- ripple klik ala Vora (posisi diambil dari kursor / sentuhan terakhir)
    local function ripple(f, size)
        if NOANIM then return end
        local loc = UIS:GetMouseLocation()
        local s = math.max(rootScale.Scale, 0.01)
        local ap, asz = f.AbsolutePosition, f.AbsoluteSize
        local x = math.clamp((loc.X - ap.X) / s, 0, asz.X / s)
        local y = math.clamp((loc.Y - ap.Y) / s, 0, asz.Y / s)
        local r = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.8, BorderSizePixel = 0}, f)
        corner(r, "full")
        play(r, {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1}, 0.45, Enum.EasingStyle.Quad)
        task.delay(0.5, function() r:Destroy() end)
    end

    ------------------------------------------------------------------
    -- BLUR (BlurEffect di Lighting, hanya aktif saat window terbuka)
    ------------------------------------------------------------------
    local isOpen = false
    local blurOn = F.UIBlur == true
    local blurSize = math.clamp(tonumber(F.UIBlurSize) or 18, 0, 56)
    local function ensureBlur()
        if blurFx and blurFx.Parent then return blurFx end
        blurFx = Instance.new("BlurEffect")
        blurFx.Name = "SORU_Blur"
        blurFx.Size = 0
        blurFx.Enabled = false
        blurFx.Parent = Lighting
        return blurFx
    end
    local function blurUpdate()
        if blurOn and isOpen then
            local b = ensureBlur()
            b.Enabled = true
            play(b, {Size = blurSize}, 0.3)
        elseif blurFx and blurFx.Parent then
            local b = blurFx
            play(b, {Size = 0}, 0.25)
            task.delay(NOANIM and 0 or 0.28, function()
                if not (blurOn and isOpen) and b.Parent then b.Enabled = false end
            end)
        end
    end

    ------------------------------------------------------------------
    -- TOAST (kanan bawah, maksimal 5, klik untuk menutup)
    ------------------------------------------------------------------
    local toastHolder = new("Frame", {Name = "Toasts", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.new(0, 300, 1, -20), BackgroundTransparency = 1, ZIndex = 200}, root)
    new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom}, toastHolder)
    local toasts, toastN = {}, 0
    local function notify(title, msg, color, dur, img)
        color, dur = color or T.accent, dur or 3
        toastN = toastN + 1
        local wrap = new("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, LayoutOrder = toastN}, toastHolder)
        local m = new("Frame", {Position = UDim2.fromOffset(330, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.side, BackgroundTransparency = 0.1, BorderSizePixel = 0, ClipsDescendants = true}, wrap)
        corner(m, 8)
        stroke(m, T.outline, 1, 0)
        local ic = new("ImageLabel", {Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 1, Image = img or "rbxassetid://112067161065104", ImageColor3 = color}, m)
        corner(ic, 6)
        text(m, {Text = tostring(title or ""), Position = UDim2.fromOffset(58, 10), Size = UDim2.new(1, -68, 0, 20), W = 3})
        text(m, {Text = tostring(msg or ""), Position = UDim2.fromOffset(58, 30), Size = UDim2.new(1, -68, 0, 26), TextSize = 12, W = 1, TextColor3 = T.dim, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top})
        local pr = new("Frame", {Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = color, BorderSizePixel = 0}, m)
        local gone, entry = false, {}
        local function leave()
            if gone then return end
            gone = true
            for i, e in ipairs(toasts) do if e == entry then table.remove(toasts, i) break end end
            play(m, {Position = UDim2.fromOffset(330, 0)}, 0.5, QUINT, Enum.EasingDirection.In)
            task.delay(NOANIM and 0 or 0.52, function() wrap:Destroy() end)
        end
        entry.leave = leave
        toasts[#toasts + 1] = entry
        if #toasts > 5 then task.spawn(toasts[1].leave) end
        new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5}, m).MouseButton1Click:Connect(leave)
        play(m, {Position = UDim2.fromOffset(0, 0)}, 0.5)
        play(pr, {Size = UDim2.new(0, 0, 0, 2)}, dur, Enum.EasingStyle.Linear)
        task.delay(dur, leave)
    end

    ------------------------------------------------------------------
    -- SHELL + WINDOW + HEADER (gaya Vora)
    ------------------------------------------------------------------
    local Window = {Tabs = {}, Flags = Reg, Gui = gui, PlaceId = placeId, GameId = gameId}
    local shell = new("Frame", {Name = "Shell", BackgroundTransparency = 1, Visible = false}, root)
    local wsh = shadow(shell)
    local win = new("Frame", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.05, BorderSizePixel = 0, ClipsDescendants = true, Active = true}, shell)
    corner(win, 10)
    stroke(win, T.outline, 1, 0)
    local winScale = new("UIScale", {Scale = 1}, win)
    local ctxWin = newCtx(win, 10)
    new("ImageLabel", {Name = "Pattern", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://2151741365", ImageTransparency = 0.95,
        TileSize = UDim2.fromOffset(20, 20), ScaleType = Enum.ScaleType.Tile, ZIndex = 1}, win)

    layoutWin = function(anim)
        local sz = Vector2.new(math.min(winSize.X, virt.X - 20), math.min(winSize.Y, virt.Y - 20))
        local x, y
        if winPos then x, y = winPos.X, winPos.Y else x, y = (virt.X - sz.X) / 2, (virt.Y - sz.Y) / 2 end
        x = math.clamp(x, 10, math.max(10, virt.X - sz.X - 10))
        y = math.clamp(y, 10, math.max(10, virt.Y - sz.Y - 10))
        if winPos then winPos = Vector2.new(x, y) end
        curPos = Vector2.new(x, y)
        shell.Size = UDim2.fromOffset(sz.X, sz.Y)
        if anim then play(shell, {Position = UDim2.fromOffset(x, y)}, anim == true and 0.5 or anim) else shell.Position = UDim2.fromOffset(x, y) end
    end

    local HDR = 38
    local hd = new("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, HDR), BackgroundColor3 = T.side, BorderSizePixel = 0, Active = true}, win)
    corner(hd, 10)
    new("Frame", {Name = "BottomFiller", Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = T.side, BorderSizePixel = 0, ZIndex = 1}, hd)
    new("Frame", {Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.outline, BorderSizePixel = 0, ZIndex = 2}, hd)
    logoImg(hd, {Name = "Logo", Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(25, 25), ZIndex = 2})
    local titleText = tostring(C.Title or C.Name or "SORU HUB")
    local tw = math.ceil(textW(titleText, 16))
    text(hd, {Name = "Title", Text = titleText, Position = UDim2.fromOffset(45, 0), Size = UDim2.new(1, -160, 1, 0), W = 3, TextSize = 16, ZIndex = 2})
    if C.Subtitle then
        text(hd, {Text = tostring(C.Subtitle), Position = UDim2.fromOffset(45 + tw + 8, 2), Size = UDim2.new(1, -(45 + tw + 8 + 120), 1, 0), W = 1, TextSize = 11, TextColor3 = T.dim, ZIndex = 2})
    end

    local controls = new("Frame", {Name = "Controls", Position = UDim2.new(1, -100, 0, 0), Size = UDim2.new(0, 100, 1, 0), BackgroundTransparency = 1, ZIndex = 2}, hd)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8)}, controls)
    new("UIPadding", {PaddingRight = UDim.new(0, 15)}, controls)
    local function ctrlBtn(name, id, order)
        local b = new("ImageButton", {Name = name, LayoutOrder = order, Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Image = "rbxassetid://" .. id, ImageColor3 = T.dim, AutoButtonColor = false}, controls)
        b.MouseEnter:Connect(function() play(b, {ImageColor3 = T.text}, 0.2) end)
        b.MouseLeave:Connect(function() play(b, {ImageColor3 = T.dim}, 0.2) end)
        return b
    end
    local minB, maxB, xB = ctrlBtn("Minimize", "71686683787518", 1), ctrlBtn("Maximize", "135582116755237", 2), ctrlBtn("Close", "121948938505669", 3)

    ------------------------------------------------------------------
    -- SIDEBAR + CONTENT
    ------------------------------------------------------------------
    local SIDE_W, FOOT_H, TAB_H, TAB_GAP = 160, 56, 36, 5
    local bar = new("Frame", {Name = "Sidebar", Position = UDim2.fromOffset(0, HDR), Size = UDim2.new(0, SIDE_W, 1, -HDR), BackgroundTransparency = 1, BorderSizePixel = 0}, win)
    new("Frame", {Name = "Separator", Position = UDim2.new(1, -2, 0, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = T.outline, BorderSizePixel = 0}, bar)
    local tabList = new("ScrollingFrame", {Name = "TabContainer", Active = true, Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, -2, 1, -(12 + FOOT_H)), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y}, bar)
    skin(tabList, "ScrollBarImageColor3", "accent")
    local btnHolder = new("Frame", {Name = "ButtonsHolder", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.Y}, tabList)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, TAB_GAP)}, btnHolder)
    new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, btnHolder)
    local indicator = new("Frame", {Name = "SlidingIndicator", Position = UDim2.fromOffset(0, 8), Size = UDim2.fromOffset(3, 20), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, tabList)
    skin(indicator, "BackgroundColor3", "accent")
    corner(indicator, "full")

    -- footer sidebar: avatar + nama + tombol Settings (kanan avatar)
    local foot = new("Frame", {Name = "Footer", Position = UDim2.new(0, 0, 1, -FOOT_H), Size = UDim2.new(1, -2, 0, FOOT_H), BackgroundTransparency = 1}, bar)
    new("Frame", {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 0, 1), BackgroundColor3 = T.outline, BorderSizePixel = 0}, foot)
    local av = new("ImageLabel", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = T.el, BorderSizePixel = 0}, foot)
    corner(av, "full")
    stroke(av, T.outline, 1, 0)
    local dot = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 34, 0.5, 18), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = T.ok, BorderSizePixel = 0}, foot)
    corner(dot, "full")
    stroke(dot, T.side, 2, 0)
    text(foot, {Text = pl.DisplayName, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 52, 0.5, 0), Size = UDim2.new(1, -100, 0, 16), W = 3, TextSize = 12})
    text(foot, {Text = "Online", Position = UDim2.new(0, 52, 0.5, 1), Size = UDim2.new(1, -100, 0, 14), TextSize = 11, W = 1, TextColor3 = T.dim})
    task.spawn(function()
        local ok, img = pcall(function() return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
        if ok and av.Parent then av.Image = img end
    end)
    local setBtn = new("TextButton", {Name = "SettingsButton", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = T.el, BackgroundTransparency = 0.2, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ClipsDescendants = true}, foot)
    corner(setBtn, 6)
    local setStroke = stroke(setBtn, T.outline, 1, 0.5)
    local setImg = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Image = SORU.Icons.settings, ImageColor3 = T.dim}, setBtn)

    local CONT_X = SIDE_W
    local content = new("Frame", {Name = "ContentContainer", Position = UDim2.fromOffset(CONT_X, 45), Size = UDim2.new(1, -CONT_X, 1, -45), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true}, win)

    -- resize handle: tiga garis diagonal (Vora)
    local rh = new("TextButton", {Name = "ResizeHandle", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -4), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 100}, win)
    local rLines = {}
    for _, cfg in ipairs({{6, -2, -2}, {10, -2, -6}, {14, -2, -10}}) do
        local ln = new("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, cfg[2], 1, cfg[3]), Size = UDim2.fromOffset(cfg[1], 2), Rotation = -45, BackgroundColor3 = T.dim, BorderSizePixel = 0, ZIndex = 101}, rh)
        corner(ln, "full")
        rLines[#rLines + 1] = ln
    end
    rh.MouseEnter:Connect(function() for _, l in ipairs(rLines) do play(l, {BackgroundColor3 = T.accent}, 0.2) end end)
    rh.MouseLeave:Connect(function() for _, l in ipairs(rLines) do play(l, {BackgroundColor3 = T.dim}, 0.2) end end)

    ------------------------------------------------------------------
    -- OPEN / CLOSE + LAUNCHER + DRAG / RESIZE
    ------------------------------------------------------------------
    local function openA()
        if isOpen then return end
        isOpen = true
        layoutWin()
        shell.Visible = true
        winScale.Scale, wsh.ImageTransparency = 0.05, 1
        play(winScale, {Scale = 1}, 0.3, BACK)
        play(wsh, {ImageTransparency = 0.5}, 0.3)
        blurUpdate()
    end
    local function closeA()
        if not isOpen then return end
        isOpen = false
        if ctxWin.d then ctxWin.d.close() end
        blurUpdate()
        if NOANIM then shell.Visible = false return end
        play(winScale, {Scale = 0.05}, 0.3, BACK, Enum.EasingDirection.In)
        play(wsh, {ImageTransparency = 1}, 0.25)
        task.delay(0.3, function() if not isOpen then shell.Visible = false end end)
    end
    local function toggleWin() if isOpen then closeA() else openA() end end

    local LAUNCH, launchPos = 50, nil
    local launcher = new("Frame", {Name = "Launcher", Size = UDim2.fromOffset(LAUNCH, LAUNCH), BackgroundColor3 = T.bg, BorderSizePixel = 0, Active = true, ZIndex = 90}, root)
    corner(launcher, 10)
    local lst = stroke(launcher, WHITE, 2, 0)
    new("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 190, 255))}), Rotation = 45}, lst)
    logoImg(launcher, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78), ScaleType = Enum.ScaleType.Fit})
    layoutLauncher = function()
        if not launchPos then launchPos = Vector2.new(math.floor(virt.X * 0.1), math.floor(virt.Y * 0.1)) end
        launchPos = Vector2.new(math.clamp(launchPos.X, 4, math.max(4, virt.X - LAUNCH - 8)), math.clamp(launchPos.Y, 4, math.max(4, virt.Y - LAUNCH - 8)))
        launcher.Position = UDim2.fromOffset(launchPos.X, launchPos.Y)
    end
    track(launcher,
        function() return launchPos end,
        function(dx, dy, st, moved)
            if moved and st then
                launchPos = Vector2.new(st.X + dx / rootScale.Scale, st.Y + dy / rootScale.Scale)
                layoutLauncher()
            end
        end,
        function(moved) if not moved then toggleWin() end end)
    track(hd,
        function() winPos = curPos return curPos end,
        function(dx, dy, st, moved)
            if moved and st then
                winPos = Vector2.new(st.X + dx / rootScale.Scale, st.Y + dy / rootScale.Scale)
                layoutWin(0.15)
            end
        end)

    local sizeUI = {} -- slider ukuran di Settings (diisi nanti) supaya ikut berubah saat window di-resize
    local function syncSizeUI()
        if sizeUI.w then sizeUI.w:Set(math.floor(winSize.X + 0.5)) end
        if sizeUI.h then sizeUI.h:Set(math.floor(winSize.Y + 0.5)) end
    end
    track(rh,
        function() winPos = curPos return winSize end,
        function(dx, dy, st)
            if not st then return end
            local s = rootScale.Scale
            local mxW = math.max(MINS.X, math.min(MAXS.X, virt.X - 10 - curPos.X))
            local mxH = math.max(MINS.Y, math.min(MAXS.Y, virt.Y - 10 - curPos.Y))
            winSize = Vector2.new(math.clamp(st.X + dx / s, MINS.X, mxW), math.clamp(st.Y + dy / s, MINS.Y, mxH))
            layoutWin()
        end,
        function(moved)
            if moved then
                F.UIW, F.UIH = math.floor(winSize.X), math.floor(winSize.Y)
                syncSizeUI()
                persist()
            end
        end)

    ------------------------------------------------------------------
    -- PAGE + TAB SYSTEM (tab biasa + halaman Settings tersembunyi)
    ------------------------------------------------------------------
    local tabs = Window.Tabs
    local cur, lastTab, tabN = nil, nil, 0
    local SETTINGS = "\0settings"
    local setPage

    local function newPage(name)
        local page = new("ScrollingFrame", {Name = name, Active = true, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false}, content)
        skin(page, "ScrollBarImageColor3", "accent")
        new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
        new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 10)}, page)
        text(page, {Name = "TabTitle", Text = name, Size = UDim2.new(1, 0, 0, 40), W = 3, TextSize = 26, LayoutOrder = -1})
        return page
    end

    local function paintTab(t, instant)
        local d = instant and 0 or (t.on and 0.3 or 0.2)
        play(t.btn, {BackgroundTransparency = t.on and 0.85 or 1}, d)
        play(t.label, {TextColor3 = t.on and T.accent or T.dim}, d)
        t.setIc(t.on and T.accent or T.dim)
    end
    local function paintSettingsBtn(on)
        play(setBtn, {BackgroundColor3 = on and T.accent or T.el, BackgroundTransparency = on and 0.8 or 0.2}, 0.2)
        play(setStroke, {Color = on and T.accent or T.outline, Transparency = on and 0.2 or 0.5}, 0.2)
        play(setImg, {ImageColor3 = on and T.accent or T.dim}, 0.2)
    end
    local function showPage(p)
        p.Visible = true
        p.Position = UDim2.fromOffset(15, 0)
        play(p, {Position = UDim2.fromOffset(0, 0)}, 0.35)
    end
    local function go(n)
        if n == cur then return end
        local old = tabs[cur]
        if cur == SETTINGS then
            if setPage then setPage.Visible = false end
            paintSettingsBtn(false)
        elseif old then
            old.on = false
            old.page.Visible = false
            paintTab(old)
        end
        local snap = (cur == nil) or (cur == SETTINGS)
        cur = n
        if n == SETTINGS then
            showPage(setPage)
            paintSettingsBtn(true)
            play(indicator, {BackgroundTransparency = 1}, 0.2)
        else
            local ne = tabs[n]
            ne.on = true
            paintTab(ne)
            showPage(ne.page)
            lastTab = n
            if snap then indicator.Position = UDim2.fromOffset(0, ne.y + 8) end
            play(indicator, {Position = UDim2.fromOffset(0, ne.y + 8), BackgroundTransparency = 0}, 0.35)
        end
    end
    local function switchTab(n) if tabs[n] then go(n) end end
    setBtn.MouseEnter:Connect(function()
        if cur ~= SETTINGS then
            play(setBtn, {BackgroundColor3 = T.hover, BackgroundTransparency = 0.1}, 0.2)
            play(setStroke, {Color = T.accent, Transparency = 0.2}, 0.2)
            play(setImg, {ImageColor3 = T.text}, 0.2)
        end
    end)
    setBtn.MouseLeave:Connect(function() if cur ~= SETTINGS then paintSettingsBtn(false) end end)
    setBtn.MouseButton1Click:Connect(function()
        ripple(setBtn, 70)
        if cur == SETTINGS then
            if lastTab then go(lastTab) end
        else
            go(SETTINGS)
        end
    end)

    local function createTab(name, icon)
        tabN = tabN + 1
        local y = (tabN - 1) * (TAB_H + TAB_GAP)
        local b = new("TextButton", {Name = name .. "Button", LayoutOrder = tabN, Size = UDim2.new(1, 0, 0, TAB_H), BackgroundColor3 = T.el, BackgroundTransparency = 1,
            BorderSizePixel = 0, AutoButtonColor = false, ClipsDescendants = true, Text = ""}, btnHolder)
        corner(b, 6)
        stroke(b, T.outline, 1, 0.8)
        local setIc = tabIcon(b, icon)
        local lb = text(b, {Text = name, Position = UDim2.fromOffset(setIc and 40 or 15, 0), Size = UDim2.new(1, setIc and -40 or -15, 1, 0), TextColor3 = T.dim})
        local page = newPage(name)
        local t = {name = name, btn = b, page = page, y = y, on = false, label = lb, setIc = setIc or function() end}
        tabs[name] = t
        b.MouseEnter:Connect(function()
            if not t.on then
                play(b, {BackgroundTransparency = 0.9}, 0.2)
                play(lb, {TextColor3 = T.text}, 0.2)
                t.setIc(T.text)
            end
        end)
        b.MouseLeave:Connect(function()
            if not t.on then
                play(b, {BackgroundTransparency = 1}, 0.2)
                play(lb, {TextColor3 = T.dim}, 0.2)
                t.setIc(T.dim)
            end
        end)
        b.MouseButton1Click:Connect(function()
            ripple(b, 150)
            go(name)
        end)
        if tabN == 1 then go(name) end
        return page
    end
    themeFns[#themeFns + 1] = function()
        for _, t in pairs(tabs) do
            t.label.TextColor3 = t.on and T.accent or T.dim
            t.setIc(t.on and T.accent or T.dim)
        end
        if cur == SETTINGS then paintSettingsBtn(true) end
    end

    ------------------------------------------------------------------
    -- KOMPONEN
    ------------------------------------------------------------------
    local function buildComponents(scroll, container, ctx)
        container = container or scroll
        local K = {}
        local order = 0
        local function nextOrder() order = order + 1 return order end

        -- elemen dasar ala Vora: fill el (alpha 0.2), corner 6, outline tipis
        local function elem(h)
            local f = new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.el, BackgroundTransparency = 0.2, BorderSizePixel = 0, LayoutOrder = nextOrder()}, K._cur or container)
            corner(f, 6)
            local st = stroke(f, T.outline, 1, 0.5)
            return f, st
        end
        local function overlay(f)
            return new("TextButton", {Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2}, f)
        end
        local function sideIcon(f, icon)
            local ic = SORU.Icons[icon] or tostring(icon)
            if ic:match("^rbxasset") or ic:match("^%d%d%d+$") then
                return new("ImageLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
                    Image = ic:match("^%d+$") and ("rbxassetid://" .. ic) or ic, ImageColor3 = T.dim}, f)
            end
            return text(f, {Text = ic, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(20, 20), TextXAlignment = XC, W = 3, TextColor3 = T.dim, TextTruncate = NOTRUNC})
        end

        ----------------------------------------------------------------
        -- SECTION / DIVIDER / LABEL / PARAGRAPH / INFO
        ----------------------------------------------------------------
        function K:Section(t)
            if type(t) == "table" then t = t.Title or t.Name or t.Text end
            t = string.upper(tostring(t or ""))
            local hf = new("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, K._cur or container)
            local w = math.ceil(textW(t, 12))
            local bar2 = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(3, 12), BorderSizePixel = 0}, hf)
            skin(bar2, "BackgroundColor3", "accent")
            corner(bar2, "full")
            text(hf, {Text = t, Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(w + 8, 24), W = 3, TextSize = 12, TextColor3 = T.dim, TextTruncate = NOTRUNC})
            new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14 + w + 14, 0.5, 0), Size = UDim2.new(1, -(14 + w + 20), 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 0.3, BorderSizePixel = 0}, hf)
        end

        function K:Divider()
            local hf = new("Frame", {Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, K._cur or container)
            new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(1, -8, 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 0.3, BorderSizePixel = 0}, hf)
        end

        function K:Label(t)
            if type(t) == "table" then t = t.Text or t.Title or t.Name end
            local hf = new("Frame", {Size = UDim2.new(1, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder()}, K._cur or container)
            local l = text(hf, {Text = tostring(t or ""), Position = UDim2.fromOffset(5, 0), Size = UDim2.new(1, -10, 0, 26), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextTruncate = NOTRUNC})
            return {Set = function(_, s) l.Text = tostring(s) end, SetText = function(_, s) l.Text = tostring(s) end, Get = function() return l.Text end}
        end

        function K:Paragraph(o)
            o = o or {}
            local f = new("Frame", {Name = "ParagraphFrame", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.el, BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = nextOrder()}, K._cur or container)
            corner(f, 6)
            stroke(f, T.outline, 1, 0.6)
            local tl = text(f, {Text = tostring(o.Title or o.Name or "Paragraph"), Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 20), W = 3})
            local dl = text(f, {Text = tostring(o.Desc or o.Content or ""), Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -24, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true, TextSize = 13, W = 1, TextColor3 = T.dim, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = NOTRUNC, RichText = true})
            new("UIPadding", {PaddingBottom = UDim.new(0, 12)}, f)
            local obj = {Title = tl.Text, Desc = dl.Text}
            function obj:Set(title, desc) if title then tl.Text = tostring(title) obj.Title = tl.Text end if desc then dl.Text = tostring(desc) obj.Desc = dl.Text end end
            function obj:SetTitle(s) tl.Text = tostring(s) obj.Title = tl.Text end
            function obj:SetDesc(s) dl.Text = tostring(s) obj.Desc = dl.Text end
            function obj:GetTitle() return obj.Title end
            function obj:GetDesc() return obj.Desc end
            return obj
        end

        -- baris informasi: judul kiri, nilai kanan. Copy = true -> klik untuk menyalin nilai
        function K:Info(o)
            if type(o) ~= "table" then o = {Title = tostring(o)} end
            local clickable = (o.Copy or o.Callback) and true or false
            local f, st = elem(H1)
            text(f, {Text = tostring(o.Title or o.Name or "Info"), Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.42, -12, 1, 0), W = 2})
            local v = text(f, {Text = tostring(o.Value or "-"), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.58, -12, 1, 0), TextXAlignment = XR, TextSize = 13, W = 1, TextColor3 = T.dim})
            if clickable then
                local hit = overlay(f)
                hit.MouseEnter:Connect(function()
                    play(f, {BackgroundColor3 = T.hover, BackgroundTransparency = 0.1}, 0.2)
                    play(st, {Color = T.accent, Transparency = 0.2}, 0.2)
                end)
                hit.MouseLeave:Connect(function()
                    play(f, {BackgroundColor3 = T.el, BackgroundTransparency = 0.2}, 0.2)
                    play(st, {Color = T.outline, Transparency = 0.5}, 0.2)
                end)
                hit.MouseButton1Click:Connect(function()
                    if o.Copy then copy(v.Text) notify("Copied", v.Text, T.accent, 1.4) end
                    safe(o.Callback, v.Text)
                end)
            end
            return {Set = function(_, t, col) v.Text, v.TextColor3 = tostring(t), col or T.dim end, Get = function() return v.Text end}
        end

        ----------------------------------------------------------------
        -- BUTTON
        ----------------------------------------------------------------
        function K:Button(o)
            o = o or {}
            local title, desc = o.Title or o.Name or "Button", o.Desc or o.SubText
            local f, st = elem(desc and H2 or H1)
            f.ClipsDescendants = true
            local tl, dl
            if desc then
                tl, dl = rowText(f, title, desc, o.Icon and 44 or 12)
            else
                tl = text(f, {Text = tostring(title), Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 2})
            end
            if o.Icon then sideIcon(f, o.Icon) end
            local hit = overlay(f)
            local hov = false
            local function rest()
                play(f, {BackgroundColor3 = hov and T.hover or T.el, BackgroundTransparency = hov and 0.1 or 0.2}, 0.3)
                play(st, {Color = hov and T.accent or T.outline, Transparency = hov and 0.2 or 0.5}, 0.2)
            end
            hit.MouseEnter:Connect(function() hov = true rest() end)
            hit.MouseLeave:Connect(function() hov = false rest() end)
            hit.MouseButton1Click:Connect(function()
                ripple(f, 200)
                play(f, {BackgroundColor3 = T.accent, BackgroundTransparency = 0}, 0.1)
                task.delay(0.1, rest)
                safe(o.Callback)
            end)
            return {
                SetTitle = function(_, s) tl.Text = tostring(s) end,
                SetDesc = function(_, s) if dl then dl.Text = tostring(s) end end,
                Fire = function() safe(o.Callback) end,
            }
        end

        ----------------------------------------------------------------
        -- TOGGLE
        ----------------------------------------------------------------
        function K:Toggle(o)
            o = o or {}
            local title = o.Title or o.Name or o.Flag or "Toggle"
            local flag = o.Flag or title
            local desc = o.Desc or o.SubText
            local v = F[flag]
            if type(v) ~= "boolean" then v = (o.Default == true) or (o.Value == true) end
            local f = elem(desc and H2 or H1)
            rowText(f, title, desc, 60)
            local sw = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(42, 22), BackgroundColor3 = v and T.accent or T.off, BorderSizePixel = 0}, f)
            corner(sw, "full")
            local function kpos(x) return UDim2.new(0, x and 22 or 2, 0.5, 0) end
            local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = kpos(v), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = WHITE, BorderSizePixel = 0}, sw)
            corner(knob, "full")
            local hit = overlay(f)
            local obj = {Value = v}
            local function upd(nv, silent)
                v, obj.Value = nv, nv
                play(sw, {BackgroundColor3 = v and T.accent or T.off}, 0.3)
                play(knob, {Position = kpos(v)}, 0.3)
                F[flag] = v
                if not silent then persist() safe(o.Callback, v) end
            end
            hit.MouseButton1Click:Connect(function() upd(not v) end)
            themeFns[#themeFns + 1] = function() sw.BackgroundColor3 = v and T.accent or T.off end
            function obj:Set(nv, fire) upd(nv and true or false, not fire) end
            function obj:Get() return v end
            F[flag], Reg[flag] = v, obj
            if o.Callback then task.spawn(safe, o.Callback, v) end
            return obj
        end

        ----------------------------------------------------------------
        -- SLIDER
        ----------------------------------------------------------------
        function K:Slider(o)
            o = o or {}
            local flag = o.Flag
            local mn, mx, step = o.Min or 0, o.Max or 100, o.Step or 1
            if mx < mn then mn, mx = mx, mn end
            if step <= 0 then step = 1 end
            local val = o.Default or o.Value or mn
            if flag and type(F[flag]) == "number" then val = F[flag] end
            local f = elem(55)
            text(f, {Text = tostring(o.Title or o.Name or flag or "Slider"), Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -100, 0, 20), W = 2})
            local vl = text(f, {Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 20), TextXAlignment = XR, W = 1, TextColor3 = T.dim, TextTruncate = NOTRUNC})
            local sbar = new("Frame", {Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -24, 0, 5), BackgroundColor3 = Color3.fromRGB(50, 50, 55), BorderSizePixel = 0}, f)
            corner(sbar, "full")
            local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BorderSizePixel = 0}, sbar)
            skin(fill, "BackgroundColor3", "accent")
            corner(fill, "full")
            local knob = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, sbar)
            corner(knob, "full")
            local hit = new("TextButton", {Position = UDim2.fromOffset(6, 28), Size = UDim2.new(1, -12, 0, 24), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3}, f)
            local function quant(x)
                x = math.clamp(mn + math.floor((x - mn) / step + 0.5) * step, mn, mx)
                return math.floor(x * 1000 + 0.5) / 1000
            end
            local function render(x)
                local a = (mx == mn) and 0 or (x - mn) / (mx - mn)
                play(fill, {Size = UDim2.fromScale(a, 1)}, 0.05)
                play(knob, {Position = UDim2.fromScale(a, 0.5)}, 0.05)
                vl.Text = tostring(x) .. (o.Suffix or "")
            end
            val = quant(val)
            render(val)
            local obj = {Value = val}
            local function set(x, silent)
                x = quant(x)
                if x == val then return end
                val, obj.Value = x, x
                render(x)
                if flag then F[flag] = x end
                if not silent then safe(o.Callback, x) end
            end
            local function fromX(px)
                local aw = sbar.AbsoluteSize.X
                if aw > 0 then set(mn + (mx - mn) * math.clamp((px - sbar.AbsolutePosition.X) / aw, 0, 1)) end
            end
            track(hit,
                function(pos)
                    scroll.ScrollingEnabled = false
                    play(knob, {Size = UDim2.fromOffset(18, 18)}, 0.15)
                    fromX(pos.X)
                    return true
                end,
                function(dx, dy, st, moved, pos) fromX(pos.X) end,
                function()
                    scroll.ScrollingEnabled = true
                    play(knob, {Size = UDim2.fromOffset(14, 14)}, 0.15)
                    if flag then F[flag] = val persist() end
                    safe(o.OnRelease, val)
                end)
            function obj:Set(x, fire) set(x, not fire) if flag then F[flag] = val end end
            function obj:Get() return val end
            if flag then F[flag], Reg[flag] = val, obj end
            if o.Callback then task.spawn(safe, o.Callback, val) end
            return obj
        end

        ----------------------------------------------------------------
        -- TEXTBOX
        ----------------------------------------------------------------
        function K:Textbox(o)
            o = o or {}
            local title = o.Title or o.Name or o.Flag or "Textbox"
            local flag = o.Flag or title
            local desc = o.Desc or o.SubText
            local val = (o.Default ~= nil) and tostring(o.Default) or ""
            if type(F[flag]) == "string" then val = F[flag] end
            local f = elem(desc and H2 or H1 + 2)
            rowText(f, title, desc, 8, 0.5)
            local wrap, box = inputBox(f, {text = val, placeholder = o.Placeholder or "Type here...", clear = o.ClearOnFocus,
                wrap = {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0.42, 0, 0, 28)}})
            new("UISizeConstraint", {MinSize = Vector2.new(96, 0), MaxSize = Vector2.new(200, 1000)}, wrap)
            local function out(x) if o.Numeric then return tonumber(x) end return x end
            local function norm(x)
                if not o.Numeric then return x end
                local n = tonumber(x) or tonumber(val) or o.Min or 0
                if o.Min then n = math.max(n, o.Min) end
                if o.Max then n = math.min(n, o.Max) end
                return tostring(n)
            end
            if o.Numeric then
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    local t = box.Text:gsub("[^%d%.%-]", "")
                    if t ~= box.Text then box.Text = t end
                end)
            end
            local before, lastLive = val, nil
            box.Focused:Connect(function() before = box.Text end)
            if o.Live and o.Callback then
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    local v = out(box.Text)
                    if v ~= nil and box.Text ~= lastLive then lastLive = box.Text safe(o.Callback, v) end
                end)
            end
            box.FocusLost:Connect(function(enter)
                local nv = norm(box.Text)
                box.Text, val, F[flag] = nv, nv, nv
                persist()
                if o.Callback and not o.Live and (enter or nv ~= before) then
                    local v = out(nv)
                    if v ~= nil then safe(o.Callback, v) end
                end
            end)
            F[flag] = val
            local obj = {Value = val}
            function obj:Set(v, fire)
                val = tostring(v)
                box.Text, obj.Value, F[flag] = val, val, val
                if fire then local r = out(val) if r ~= nil then safe(o.Callback, r) end end
            end
            function obj:Get() return out(box.Text) end
            Reg[flag] = obj
            if o.Callback and val ~= "" then
                local v = out(val)
                if v ~= nil then task.spawn(safe, o.Callback, v) end
            end
            return obj
        end
        K.TextBox, K.Input = K.Textbox, K.Textbox

        ----------------------------------------------------------------
        -- DROPDOWN: klik membuka drawer di sisi kanan (Single / Multi)
        ----------------------------------------------------------------
        function K:Dropdown(o)
            o = o or {}
            local title = o.Title or o.Name or o.Flag or "Dropdown"
            local flag = o.Flag or title
            local desc = o.Desc or o.SubText
            local multi = o.Multi and true or false
            local opts = o.Options or o.Items or o.Values or {}
            local chosen, single = {}, nil
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
            if F[flag] ~= nil then setFrom(F[flag]) else setFrom(o.Default or o.Value) end
            local function getVal()
                if not multi then return single end
                local r = {}
                for _, n in ipairs(opts) do if chosen[tostring(n)] then r[#r + 1] = tostring(n) end end
                return r
            end
            local function isSel(n) if multi then return chosen[n] == true end return single == n end

            local f = elem(desc and H2 or H1)
            rowText(f, title, desc, 0, 0.5)
            local vl = text(f, {Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -34, 1, 0), TextXAlignment = XR, TextSize = 13, W = 1, TextColor3 = T.dim})
            new("ImageLabel", {Position = UDim2.new(1, -26, 0.5, -8), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Image = "rbxassetid://6031091004", ImageColor3 = T.dim, Rotation = -90}, f)
            local hit = overlay(f)
            local function refresh()
                if multi then
                    local v = getVal()
                    vl.Text = (#v == 0) and "None" or ((#v == 1) and v[1] or (#v .. " Selected"))
                else
                    vl.Text = single or "Select..."
                end
            end
            local function commit()
                local v = getVal()
                F[flag] = v
                persist()
                safe(o.Callback, v)
            end
            hit.MouseButton1Click:Connect(function()
                ctx.drawer().open({
                    title = title, options = opts, multi = multi, swatch = o.Swatch, isSel = isSel,
                    pick = function(n)
                        if multi then chosen[n] = (not chosen[n]) and true or nil else single = n end
                        refresh()
                        commit()
                    end,
                })
            end)
            refresh()
            F[flag] = getVal()
            local api = {Value = getVal()}
            function api:Set(v, fire)
                setFrom(v)
                refresh()
                F[flag], api.Value = getVal(), getVal()
                if fire then safe(o.Callback, getVal()) end
            end
            function api:Get() return getVal() end
            function api:Refresh(n) opts = n or {} refresh() end
            Reg[flag] = api
            if o.Callback and (multi or single ~= nil) then task.spawn(safe, o.Callback, getVal()) end
            return api
        end
        function K:MultiDropdown(o) o = o or {} o.Multi = true return K.Dropdown(self, o) end

        ----------------------------------------------------------------
        -- KEYBIND
        ----------------------------------------------------------------
        function K:Keybind(o)
            o = o or {}
            local title = o.Title or o.Name or o.Flag or "Keybind"
            local flag = o.Flag or title
            local desc = o.Desc or o.SubText
            local key = o.Default
            if type(key) == "string" then key = toKey(key) end
            if type(F[flag]) == "string" then key = (F[flag] ~= "None") and toKey(F[flag]) or nil end
            local f = elem(desc and H2 or H1)
            rowText(f, title, desc, 100)
            local cap = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(85, 24), BackgroundColor3 = T.bg, BackgroundTransparency = 0.5,
                BorderSizePixel = 0, FontFace = FONT[1], TextSize = 13, TextColor3 = T.dim, Text = "", ClipsDescendants = true, AutoButtonColor = false}, f)
            corner(cap, 4)
            stroke(cap, T.outline, 1, 0.7)
            local listening, lastCancel = false, 0
            local function show()
                local t = listening and "..." or (key and key.Name or "None")
                cap.Text = t
                cap.Size = UDim2.fromOffset(math.max(85, textW(t, 13) + 24), 24)
                play(cap, {TextColor3 = listening and T.accent or T.dim}, 0.2)
            end
            local function stop()
                listening = false
                lastCancel = os.clock()
                if activeStop == stop then activeStop = nil end
                show()
                task.delay(0.1, function() binding = false end)
            end
            show()
            cap.MouseButton2Click:Connect(function()
                key = nil
                F[flag] = "None"
                persist()
                if listening then stop() else show() end
                safe(o.OnChange, nil)
            end)
            cap.MouseButton1Click:Connect(function()
                if listening or os.clock() - lastCancel < 0.35 then return end
                ripple(cap, 100)
                if activeStop then activeStop() end
                activeStop = stop
                listening, binding = true, true
                show()
            end)
            bind(UIS.InputBegan, function(i, gp)
                if listening then
                    local ut = i.UserInputType
                    if ut == Enum.UserInputType.Keyboard then
                        if i.KeyCode == Enum.KeyCode.Escape then
                            stop()
                        else
                            key = (i.KeyCode ~= Enum.KeyCode.Backspace) and i.KeyCode or nil
                            F[flag] = key and key.Name or "None"
                            persist()
                            stop()
                            safe(o.OnChange, key)
                        end
                    elseif ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.Touch then
                        stop()
                    end
                    return
                end
                if not gp and key and i.KeyCode == key and o.Callback then safe(o.Callback, key) end
            end)
            F[flag] = key and key.Name or "None"
            local obj = {Value = key}
            function obj:Set(k)
                if type(k) == "string" then k = toKey(k) end
                key, obj.Value = k, k
                show()
                F[flag] = key and key.Name or "None"
            end
            function obj:Get() return key end
            Reg[flag] = obj
            return obj
        end
        K.Bind = K.Keybind

        ----------------------------------------------------------------
        -- COLOR PICKER (elemen mengembang: kotak SV + hue horizontal + input hex)
        ----------------------------------------------------------------
        function K:ColorPicker(o)
            o = o or {}
            local title = o.Title or o.Name or o.Flag or "Color"
            local flag = o.Flag or title
            local col = (typeof(o.Default) == "Color3") and o.Default or T.accent
            local sv = F[flag]
            if type(sv) == "table" and #sv == 3 then col = Color3.fromRGB(sv[1], sv[2], sv[3]) end
            local hh, ss, vv = col:ToHSV()
            local OPEN_H, open = 232, false
            local f = elem(H1)
            f.ClipsDescendants = true
            text(f, {Text = tostring(title), Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -60, 0, H1), W = 2})
            local sw = new("Frame", {Position = UDim2.new(1, -40, 0, 9), Size = UDim2.fromOffset(28, 20), BackgroundColor3 = col, BorderSizePixel = 0}, f)
            corner(sw, 4)
            local head = new("TextButton", {Size = UDim2.new(1, 0, 0, H1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2}, f)

            local pop = new("Frame", {Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -24, 0, 182), BackgroundTransparency = 1}, f)
            local svBox = new("Frame", {Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = Color3.fromHSV(hh, 1, 1), BorderSizePixel = 0}, pop)
            corner(svBox, 4)
            local wf = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, svBox)
            corner(wf, 4)
            new("UIGradient", {Transparency = NumberSequence.new(0, 1)}, wf)
            local bf = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, svBox)
            corner(bf, 4)
            new("UIGradient", {Transparency = NumberSequence.new(1, 0), Rotation = 90}, bf)
            local pt = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, svBox)
            corner(pt, "full")
            stroke(pt, Color3.new(0, 0, 0), 1, 0)
            local svHit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4}, svBox)

            local hue = new("Frame", {Position = UDim2.fromOffset(0, 128), Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = WHITE, BorderSizePixel = 0}, pop)
            corner(hue, 4)
            local ks = {}
            for i = 0, 6 do ks[#ks + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)) end
            new("UIGradient", {Color = ColorSequence.new(ks)}, hue)
            local hp = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 6, 1, 6), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, hue)
            corner(hp, 2)
            stroke(hp, Color3.new(0, 0, 0), 1, 0)
            local hHit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4}, hue)
            local _, hexBox = inputBox(pop, {placeholder = "#RRGGBB", wrap = {Position = UDim2.fromOffset(0, 154), Size = UDim2.new(1, 0, 0, 28)}})

            local function hex(c) return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
            local function rgbOf() return {math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)} end
            local function apply(silent, exact)
                col = exact or Color3.fromHSV(hh, ss, vv)
                sw.BackgroundColor3 = col
                svBox.BackgroundColor3 = Color3.fromHSV(hh, 1, 1)
                if not hexBox:IsFocused() then hexBox.Text = hex(col) end
                pt.Position = UDim2.fromScale(ss, 1 - vv)
                hp.Position = UDim2.new(hh, 0, 0.5, 0)
                if not silent then safe(o.Callback, col) end
            end
            local function save() F[flag] = rgbOf() persist() end
            local function yOf(pos) return pos.Y + GuiService:GetGuiInset().Y end
            track(svHit,
                function() scroll.ScrollingEnabled = false return true end,
                function(dx, dy, st, moved, pos)
                    local ap, asz = svBox.AbsolutePosition, svBox.AbsoluteSize
                    if asz.X <= 0 or asz.Y <= 0 then return end
                    ss = math.clamp((pos.X - ap.X) / asz.X, 0, 1)
                    vv = 1 - math.clamp((yOf(pos) - ap.Y) / asz.Y, 0, 1)
                    apply()
                end,
                function() scroll.ScrollingEnabled = true save() end)
            track(hHit,
                function() scroll.ScrollingEnabled = false return true end,
                function(dx, dy, st, moved, pos)
                    local ap, asz = hue.AbsolutePosition, hue.AbsoluteSize
                    if asz.X <= 0 then return end
                    hh = math.clamp((pos.X - ap.X) / asz.X, 0, 1)
                    apply()
                end,
                function() scroll.ScrollingEnabled = true save() end)
            hexBox.FocusLost:Connect(function()
                local x = tostring(hexBox.Text):gsub("[%s#]", "")
                if #x == 3 then x = x:gsub(".", "%0%0") end
                if #x == 6 and not x:find("%X") then
                    local c = hx(x)
                    hh, ss, vv = c:ToHSV()
                    apply(false, c)
                    save()
                else
                    hexBox.Text = hex(col)
                end
            end)
            head.MouseButton1Click:Connect(function()
                open = not open
                play(f, {Size = UDim2.new(1, 0, 0, open and OPEN_H or H1)}, 0.3)
            end)
            apply(true)
            F[flag] = rgbOf()
            local obj = {Value = col}
            function obj:Set(c, fire)
                if type(c) == "table" and #c == 3 then c = Color3.fromRGB(c[1], c[2], c[3]) end
                if typeof(c) ~= "Color3" then return end
                hh, ss, vv = c:ToHSV()
                apply(not fire, c)
                obj.Value, F[flag] = c, rgbOf()
            end
            function obj:Get() return col end
            Reg[flag] = obj
            if o.Callback then task.spawn(safe, o.Callback, col) end
            return obj
        end
        K.Color = K.ColorPicker

        ----------------------------------------------------------------
        -- ACCORDION (= CreateSection ): klik header = buka / tutup, tinggi mengikuti isi
        ----------------------------------------------------------------
        function K:Accordion(o)
            o = o or {}
            local desc = o.Desc or o.SubText
            local HEAD = desc and 44 or 32
            local open, animating, tok = false, false, 0
            local box = new("Frame", {Name = "SectionContainer", Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder()}, K._cur or container)
            local hd2 = new("TextButton", {Name = "SectionHeader", Size = UDim2.new(1, 0, 0, HEAD), BackgroundColor3 = T.el, BackgroundTransparency = 0.5, AutoButtonColor = false, Text = "", BorderSizePixel = 0}, box)
            corner(hd2, 6)
            stroke(hd2, T.outline, 1, 0.6)
            text(hd2, {Text = tostring(o.Title or o.Name or "Section"), Position = UDim2.fromOffset(10, desc and 5 or 0), Size = UDim2.new(1, -40, 0, desc and 20 or HEAD), W = 3, TextSize = 13})
            if desc then text(hd2, {Text = tostring(desc), Position = UDim2.fromOffset(10, 24), Size = UDim2.new(1, -40, 0, 14), TextSize = 11, W = 1, TextColor3 = T.dim}) end
            local chev = new("ImageLabel", {Position = UDim2.new(1, -26, 0.5, -8), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Image = "rbxassetid://6031091004", ImageColor3 = T.dim, Rotation = -90}, hd2)

            local wrap = new("Frame", {Position = UDim2.fromOffset(0, HEAD + 4), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Visible = false}, box)
            local cont = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0}, wrap)
            new("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}, cont)
            local lay = new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, cont)

            local sub = buildComponents(scroll, cont, ctx)
            sub._content = cont

            local function paintHead(instant)
                play(hd2, {BackgroundColor3 = open and T.accent or T.el, BackgroundTransparency = open and 0.8 or 0.5}, instant and 0 or 0.2)
            end
            themeFns[#themeFns + 1] = function() hd2.BackgroundColor3 = open and T.accent or T.el end
            local function contentH()
                local ah = lay.AbsoluteContentSize.Y
                if ah <= 0 then return 0 end
                local fac = hd2.AbsoluteSize.Y / HEAD
                if fac < 0.01 then fac = math.max(rootScale.Scale, 0.01) end
                return math.floor(ah / fac + 0.5) + 10
            end
            local function setH(h)
                wrap.Size = UDim2.new(1, 0, 0, h)
                box.Size = UDim2.new(1, 0, 0, h > 0 and (HEAD + 4 + h) or HEAD)
            end
            local function setOpen(v, instant)
                if v == open then return end
                open = v
                tok = tok + 1
                local my = tok
                play(chev, {Rotation = v and 0 or -90}, 0.3)
                paintHead(instant)
                if v then wrap.Visible = true end
                if instant or NOANIM then
                    wrap.Visible = v
                    setH(v and contentH() or 0)
                    return
                end
                animating = true
                task.spawn(function()
                    if v then RunService.Heartbeat:Wait() end
                    if tok ~= my then return end
                    local h = v and contentH() or 0
                    play(wrap, {Size = UDim2.new(1, 0, 0, h)}, 0.35)
                    play(box, {Size = UDim2.new(1, 0, 0, h > 0 and (HEAD + 4 + h) or HEAD)}, 0.35)
                    task.wait(0.38)
                    if tok ~= my then return end
                    animating = false
                    if open then setH(contentH()) else wrap.Visible = false end
                end)
            end
            -- isi berubah saat terbuka (dropdown, komponen baru, accordion di dalam): tinggi ikut
            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if open and not animating then
                    local h = contentH()
                    if math.abs(wrap.Size.Y.Offset - h) > 1 then setH(h) end
                end
            end)
            hd2.MouseEnter:Connect(function() if not open then play(hd2, {BackgroundTransparency = 0.3}, 0.2) end end)
            hd2.MouseLeave:Connect(function() if not open then play(hd2, {BackgroundTransparency = 0.5}, 0.2) end end)
            hd2.MouseButton1Click:Connect(function() setOpen(not open) end)

            function sub:Expand() setOpen(true) end
            function sub:Collapse() setOpen(false) end
            function sub:SetOpen(v) setOpen(v and true or false) end
            function sub:IsOpen() return open end
            if o.Open then setOpen(true, true) end
            return sub
        end
        K.Group = K.Accordion

        function K:Panel(o) return Window:Panel(o) end

        -- alias gaya . CreateSection = accordion; komponen sesudahnya masuk ke dalamnya
        function K:CreateSection(o)
            if type(o) ~= "table" then o = {Name = tostring(o)} end
            K._cur = nil
            local A = K:Accordion({Title = o.Name or o.Title, Desc = o.Desc, Open = o.Open})
            K._cur = A._content
            return A
        end
        for a, b in pairs({CreateButton = "Button", CreateToggle = "Toggle", CreateSlider = "Slider", CreateInput = "Textbox",
            CreateDropdown = "Dropdown", CreateMultiDropdown = "MultiDropdown", CreateColorPicker = "ColorPicker",
            CreateKeybind = "Keybind", CreateParagraph = "Paragraph", CreateLabel = "Label"}) do
            K[a] = function(self, o) return K[b](self, o) end
        end
        return K
    end

    ------------------------------------------------------------------
    -- WINDOW API
    ------------------------------------------------------------------
    function Window.Notify(a, b, c, d, e)
        if a == Window then a, b, c, d, e = b, c, d, e, nil end
        if type(a) == "table" then
            local img = a.Image or a.Icon
            if img and SORU.Icons[img] then img = SORU.Icons[img] end
            return notify(a.Title or a.Name, a.Content or a.Desc or a.Message, a.Color, a.Duration, img)
        end
        return notify(a, b, c, d, e)
    end
    function Window:IsGame(id) return placeId == id or gameId == id end
    function Window:Toggle() toggleWin() end
    function Window:Open() openA() end
    function Window:Close() closeA() end
    function Window:OpenSettings() if isOpen == false then openA() end go(SETTINGS) end
    function Window:SetScale(pct) userScale = math.clamp((tonumber(pct) or 100) / 100, 0.6, 1.5) F.UIScale = math.floor(userScale * 100 + 0.5) applyScale() persist() end
    function Window:SaveConfig(name) saveCfg(name or curName) return true end
    function Window:LoadConfig(name)
        local d = readCfg(name or curName)
        if not d then return false, "config not found" end
        for flag, val in pairs(d.Features) do
            local r = Reg[flag]
            if r then pcall(function() r:Set(val, true) end) end
        end
        return true
    end
    function Window:Destroy() gui:Destroy() end
    function Window:Tab(c)
        c = c or {}
        return buildComponents(createTab(c.Title or c.Name or "Tab", c.Icon), nil, ctxWin)
    end
    function Window:CreateTab(c) c = c or {} return Window:Tab({Title = c.Name or c.Title, Icon = c.Icon}) end

    -- kontrol header
    minB.MouseButton1Click:Connect(toggleWin)
    xB.MouseButton1Click:Connect(function()
        play(win, {BackgroundTransparency = 1}, 0.3)
        closeA()
        task.delay(0.35, function() gui:Destroy() end)
    end)
    local maxed, prevSize = false, nil
    maxB.MouseButton1Click:Connect(function()
        maxed = not maxed
        if maxed then
            prevSize = winSize
            winSize = Vector2.new(math.min(900, virt.X - 20), math.min(600, virt.Y - 20))
            winPos = nil
        else
            winSize = prevSize or DEFAULT
        end
        syncSizeUI()
        layoutWin(true)
    end)

    bind(UIS.InputBegan, function(i, gp)
        if binding or gp then return end
        if i.KeyCode == toggleKey then toggleWin() end
    end)
    bind(gui:GetPropertyChangedSignal("AbsoluteSize"), applyScale)
    applyScale()

    -- support game
    local supported, kickOnFail = C.SupportedGames, C.KickIfNotSupported
    if kickOnFail == nil then kickOnFail = true end
    local isSupported = true
    if supported and #supported > 0 then
        isSupported = false
        for _, id in ipairs(supported) do if id == placeId or id == gameId then isSupported = true break end end
    end
    Window.IsSupported = isSupported
    if not isSupported then
        launcher.Visible = false
        notify("Game not supported", "Place ID " .. tostring(placeId), T.bad, 5)
        task.delay(5, function()
            if kickOnFail then pcall(function() pl:Kick("NOT SUPPORTED - SORU HUB\n" .. placeId) end) end
        end)
        local function dummy()
            local d = {}
            return setmetatable(d, {__index = function() return function() return d end end})
        end
        function Window:Tab() return dummy() end
        function Window:Panel() return dummy() end
        Window.CreateTab = Window.Tab
        return Window
    end

    ------------------------------------------------------------------
    -- PANEL SAMPING: tap grip = buka / tutup, tarik grip = geser
    ------------------------------------------------------------------
    function Window:Panel(o)
        o = o or {}
        local W = math.clamp(tonumber(o.Width) or 300, 220, 520)
        local GRIP, M, HEADP = 28, 12, 52
        local dockL = tostring(o.OpenDrag or "Left"):lower() == "right"
        local AX = dockL and 0 or 1
        local isP, destroyed, prog = false, false, 0
        local holder = new("Frame", {Name = "SORU_Panel", AnchorPoint = Vector2.new(AX, 0), Size = UDim2.new(0, W + GRIP, 1, -28), BackgroundTransparency = 1, ZIndex = 60}, root)
        local function pos(p)
            local x = (1 - p) * W - p * M
            return UDim2.new(AX, dockL and -x or x, 0, 14)
        end
        holder.Position = pos(0)
        local bh = new("Frame", {Name = "BodyHolder", AnchorPoint = Vector2.new(AX, 0), Position = UDim2.new(AX, 0, 0, 0), Size = UDim2.new(0, W, 1, 0), BackgroundTransparency = 1}, holder)
        local psh = shadow(bh)
        psh.ImageTransparency = 1
        local body = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.side, BackgroundTransparency = 0.05, BorderSizePixel = 0, Active = true, ClipsDescendants = true}, bh)
        corner(body, 10)
        stroke(body, T.outline, 1, 0)
        local hasSub = o.Subtitle ~= nil and tostring(o.Subtitle) ~= ""
        local tl = text(body, {Text = tostring(o.Title or "Panel"), Position = UDim2.fromOffset(16, hasSub and 8 or 0), Size = UDim2.new(1, -64, 0, hasSub and 24 or HEADP), W = 3, TextSize = 17})
        local sl = text(body, {Text = tostring(o.Subtitle or ""), Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -64, 0, 14), TextSize = 11, W = 1, TextColor3 = T.dim, Visible = hasSub})
        local cb = new("TextButton", {Position = UDim2.new(1, -42, 0, 12), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = T.el, BackgroundTransparency = 0.2, Text = dockL and "‹" or "›",
            FontFace = FONT[3], TextSize = 20, TextColor3 = T.dim, AutoButtonColor = false, BorderSizePixel = 0}, body)
        corner(cb, 6)
        stroke(cb, T.outline, 1, 0.5)
        cb.MouseEnter:Connect(function() play(cb, {TextColor3 = T.text, BackgroundColor3 = T.hover}, 0.2) end)
        cb.MouseLeave:Connect(function() play(cb, {TextColor3 = T.dim, BackgroundColor3 = T.el}, 0.2) end)
        new("Frame", {Position = UDim2.fromOffset(0, HEADP), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.outline, BorderSizePixel = 0}, body)
        local pscroll = new("ScrollingFrame", {Position = UDim2.fromOffset(0, HEADP + 1), Size = UDim2.new(1, 0, 1, -(HEADP + 1)), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, body)
        skin(pscroll, "ScrollBarImageColor3", "accent")
        new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, pscroll)
        new("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}, pscroll)
        local pctx = newCtx(body, 10)
        local K = buildComponents(pscroll, nil, pctx)

        local grip = new("Frame", {Name = "Grip", AnchorPoint = Vector2.new(1 - AX, 0.5), Position = UDim2.new(1 - AX, 0, math.clamp(tonumber(o.GripY) or 0.3, 0.1, 0.9), 0),
            Size = UDim2.fromOffset(GRIP, 124), BorderSizePixel = 0, Active = true}, holder)
        skin(grip, "BackgroundColor3", "accent")
        corner(grip, 8)
        stroke(grip, T.outline, 1, 0)
        local gt = text(grip, {Text = string.upper(tostring(o.Title or "Panel")), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(104, 16),
            Rotation = dockL and -90 or 90, TextXAlignment = XC, W = 3, TextSize = 11})

        local function goTo(open)
            local was = isP
            isP = open and true or false
            prog = isP and 1 or 0
            if not isP and pctx.d then pctx.d.close() end
            play(holder, {Position = pos(prog)}, 0.4, QUINT)
            play(psh, {ImageTransparency = isP and 0.5 or 1}, 0.4)
            if was ~= isP and o.Callback then task.spawn(safe, o.Callback, isP) end
        end
        cb.MouseButton1Click:Connect(function() goTo(false) end)
        track(grip,
            function() return prog end,
            function(dx, dy, p0, moved)
                if not moved then return end
                local d = dx / math.max(rootScale.Scale, 0.01)
                if dockL then d = -d end
                prog = math.clamp(p0 - d / (W + M), 0, 1)
                holder.Position = pos(prog)
                psh.ImageTransparency = 1 - 0.5 * prog
            end,
            function(moved) if not moved then goTo(not isP) else goTo(prog > 0.5) end end)

        function K:Show() goTo(true) end
        function K:Hide() goTo(false) end
        function K:Switch() goTo(not isP) end
        function K:IsOpen() return isP end
        function K:SetTitle(t) tl.Text, gt.Text = tostring(t), string.upper(tostring(t)) end
        function K:SetSubtitle(t)
            local s = (t == nil) and "" or tostring(t)
            sl.Text, sl.Visible = s, s ~= ""
            tl.Position = UDim2.fromOffset(16, s ~= "" and 8 or 0)
            tl.Size = UDim2.new(1, -64, 0, s ~= "" and 24 or HEADP)
        end
        function K:SetVisible(v) holder.Visible = v and true or false end
        function K:SetWidth(w)
            W = math.clamp(tonumber(w) or W, 220, 520)
            holder.Size = UDim2.new(0, W + GRIP, 1, -28)
            bh.Size = UDim2.new(0, W, 1, 0)
            holder.Position = pos(prog)
        end
        function K:Destroy() if not destroyed then destroyed = true holder:Destroy() end end
        if o.Open then
            isP, prog = true, 1
            holder.Position = pos(1)
            psh.ImageTransparency = 0.5
        end
        return K
    end

    ------------------------------------------------------------------
    -- SETTINGS (halaman tersembunyi, dibuka lewat tombol di kanan avatar)
    ------------------------------------------------------------------
    setPage = newPage("Settings")
    do
        local S = buildComponents(setPage, nil, ctxWin)

        local AP = S:Accordion({Title = "Theme", Desc = "Accent color preset", Open = true})
        AP:Dropdown({Title = "Theme", Desc = "Pick an accent color", Flag = "UITheme", Options = ORDER, Default = curTheme,
            Swatch = function(n) return THEMES[n] and THEMES[n][1] or nil end,
            Callback = function(v)
                if type(v) == "string" and THEMES[v] then
                    curTheme = v
                    applyTheme(v)
                end
            end})

        local WS = S:Accordion({Title = "Window size", Desc = "Width, height and UI scale", Open = true})
        sizeUI.w = WS:Slider({Title = "Width", Flag = "UIW", Min = MINS.X, Max = MAXS.X, Step = 5, Suffix = " px", Default = math.floor(winSize.X + 0.5),
            Callback = function(v)
                winSize = Vector2.new(v, winSize.Y)
                layoutWin()
            end})
        sizeUI.h = WS:Slider({Title = "Height", Flag = "UIH", Min = MINS.Y, Max = MAXS.Y, Step = 5, Suffix = " px", Default = math.floor(winSize.Y + 0.5),
            Callback = function(v)
                winSize = Vector2.new(winSize.X, v)
                layoutWin()
            end})
        local scaleS = WS:Slider({Title = "UI scale", Flag = "UIScale", Min = 60, Max = 150, Step = 5, Suffix = "%", Default = math.floor(userScale * 100 + 0.5),
            OnRelease = function(v) userScale = v / 100 applyScale() end})
        WS:Button({Title = "Reset window", Desc = "Back to the default size and scale", Callback = function()
            winSize, winPos = DEFAULT, nil
            userScale = autoScale()
            maxed = false
            sizeUI.w:Set(DEFAULT.X)
            sizeUI.h:Set(DEFAULT.Y)
            scaleS:Set(math.floor(userScale * 100 + 0.5))
            F.UIW, F.UIH = nil, nil
            applyScale()
            layoutWin(true)
            persist()
            notify("Window reset", "Size and scale restored", T.accent, 2)
        end})

        local BL = S:Accordion({Title = "Blur", Desc = "Blur the game behind the menu", Open = true})
        BL:Toggle({Title = "Background blur", Desc = "Only active while the menu is open", Flag = "UIBlur", Default = false,
            Callback = function(v)
                blurOn = v and true or false
                blurUpdate()
            end})
        BL:Slider({Title = "Blur intensity", Flag = "UIBlurSize", Min = 2, Max = 56, Step = 1, Default = blurSize,
            Callback = function(v)
                blurSize = v
                if blurOn and isOpen and blurFx and blurFx.Parent then blurFx.Size = v end
            end})

        local GN = S:Accordion({Title = "General", Desc = "Menu key and animation"})
        GN:Keybind({Title = "Menu key", Desc = "Show or hide the interface", Flag = "MenuKey", Default = toggleKey,
            OnChange = function(k) if k then toggleKey = k end end})
        GN:Toggle({Title = "Reduce animation", Desc = "Instant changes, lightest on weak devices", Flag = "UINoAnim", Default = NOANIM,
            Callback = function(v) NOANIM = v and true or false end})
    end

    if C.Demo then
        local S = Window:Tab({Title = "Showcase", Icon = "star"})
        S:Section("Basic")
        S:Button({Title = "Button", Desc = "Click me", Callback = function() notify("Button", "Clicked", T.accent, 1.5) end})
        S:Toggle({Title = "Toggle", Flag = "Demo_Toggle", Default = true})
        S:Slider({Title = "Slider", Flag = "Demo_Slider", Min = 0, Max = 100, Default = 40, Suffix = "%"})
        S:Section("Input")
        S:Textbox({Title = "Textbox", Flag = "Demo_Text"})
        S:Dropdown({Title = "Dropdown", Flag = "Demo_DD", Options = {"Alpha", "Beta", "Gamma"}, Default = "Alpha"})
        S:Keybind({Title = "Keybind", Flag = "Demo_Key", Default = Enum.KeyCode.F})
        S:ColorPicker({Title = "Color picker", Flag = "Demo_Col", Default = T.accent})
        local A = S:Accordion({Title = "Accordion", Desc = "Any component works inside", Open = true})
        A:Toggle({Title = "Auto farm", Flag = "Demo_AF"})
        A:Slider({Title = "Farm speed", Flag = "Demo_FS", Min = 1, Max = 10, Default = 5})
    end

    openA()
    notify("SORU HUB v" .. VERSION, "Loaded successfully", T.accent, 3)
    return Window
end

return SORU
