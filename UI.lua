
-- Tambahan API: Window:Group(), Page:SubTab() (chip di atas konten), K:Accordion = kartu 2 kolom, K:Buttons({...}).
-- Dashboard OTOMATIS: grup "Loaded" > tab "Dashboard" langsung ada begitu CreateWindow jalan (tidak perlu dipanggil). Akses isinya lewat Window.Dashboard.
--   Opsi: AutoDashboard = false (matikan), DashboardGroup = "Nama Grup" (ganti nama grup, default "Loaded").
local SORU = {Version = "1.2.1"}
local Players, TweenService, UIS, RunService = game:GetService("Players"), game:GetService("TweenService"), game:GetService("UserInputService"), game:GetService("RunService")
local Http, TextService, GuiService, Lighting = game:GetService("HttpService"), game:GetService("TextService"), game:GetService("GuiService"), game:GetService("Lighting")

local VERSION, CFG = SORU.Version, "SORU_HUB"
local CFGS = CFG .. "/configs"
pcall(function()
    if makefolder then for _, p in ipairs({CFG, CFGS}) do if not isfolder(p) then makefolder(p) end end end
end)

-- LOGO: isi C.Logo = "rbxassetid://..." / id angka, atau C.LogoUrl = link PNG (diunduh sekali ke folder SORU_HUB).
-- Kalau dua-duanya kosong, logo dibuat dari teks (huruf besar bergradien + nama) supaya tetap mirip.
local function fetchImage(url, fname)
    if not (isfile and getcustomasset and writefile) then return "" end
    local p = CFG .. "/" .. fname
    local function asset() local ok, a = pcall(getcustomasset, p) return (ok and type(a) == "string" and a ~= "") and a or nil end
    local ok, has = pcall(isfile, p)
    if ok and has and asset() then return asset() end
    local ok2, data = pcall(function() return game:HttpGet(url) end)
    if ok2 and type(data) == "string" and #data > 64 and not data:find("^404") then
        pcall(writefile, p, data)
        task.wait(0.05)
        return asset() or ""
    end
    return ""
end
local LOGO, LOGOCHAR, LOGONAME = "", "N", "NEMESIS"

----------------------------------------------------------------------
-- THEME: palet gelap ala Nemesis (hampir hitam + ungu). Aksen bisa diganti lewat UI Settings (45 preset)
----------------------------------------------------------------------
local WHITE = Color3.new(1, 1, 1)
local T = {
    bg = Color3.fromRGB(12, 12, 16), side = Color3.fromRGB(8, 8, 11), el = Color3.fromRGB(21, 20, 27), field = Color3.fromRGB(30, 29, 37),
    hover = Color3.fromRGB(38, 36, 47), chip = Color3.fromRGB(29, 28, 36), outline = Color3.fromRGB(42, 40, 53), text = Color3.fromRGB(255, 255, 255),
    mid = Color3.fromRGB(160, 160, 171), dim = Color3.fromRGB(134, 134, 146), faint = Color3.fromRGB(102, 102, 115), off = Color3.fromRGB(52, 50, 63),
    ok = Color3.fromRGB(46, 204, 113), warn = Color3.fromRGB(241, 196, 15), bad = Color3.fromRGB(235, 80, 70),
    accent = Color3.fromRGB(129, 61, 195), accent2 = Color3.fromRGB(94, 47, 158),
}
local function derive()
    T.accentL = T.accent:Lerp(WHITE, 0.42) -- judul halaman, angka slider
    T.accentH = T.accent:Lerp(WHITE, 0.24) -- ujung terang gradien slider
    T.chipOn = T.bg:Lerp(T.accent:Lerp(WHITE, 0.1), 0.5) -- chip sub-tab aktif
end
derive()
local QUINT, BACK = Enum.EasingStyle.Quint, Enum.EasingStyle.Back
local XL, XC, XR = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right
local YC = Enum.TextYAlignment.Center
local NOTRUNC = Enum.TextTruncate.None

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
    "Nemesis 813DC3 5E2F9E", "Violet 9160FF 5E6AFF", "Ocean 28A0FF 3870FF", "Crimson FF4664 DC2650", "Emerald 2DD496 10AA78",
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
    derive()
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
-- W: 1 = Regular (isi), 2 = Medium (label), 3 = SemiBold (judul), 4 = Bold. Font Nemesis = Montserrat
local MONT = "rbxasset://fonts/families/Montserrat.json"
local function mkFont(w, italic)
    local ok, f = pcall(function() return Font.new(MONT, w, italic and Enum.FontStyle.Italic or Enum.FontStyle.Normal) end)
    if ok and f then return f end
    return Font.fromEnum(Enum.Font.GothamMedium)
end
local FONT = {mkFont(Enum.FontWeight.Regular), mkFont(Enum.FontWeight.Medium), mkFont(Enum.FontWeight.SemiBold), mkFont(Enum.FontWeight.Bold)}
local FONT_I = mkFont(Enum.FontWeight.Bold, true)

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
-- bayangan lembut: dibuat SEBELUM elemen yang dibayangi (sibling di belakangnya)
local function shadow(parent, z)
    return new("ImageLabel", {Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 34, 1, 34),
        BackgroundTransparency = 1, Image = "rbxassetid://6015897843", ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = z or 0}, parent)
end
local function text(parent, p)
    local d = {BackgroundTransparency = 1, BorderSizePixel = 0, FontFace = FONT[2], TextSize = 11, TextColor3 = T.text, TextXAlignment = XL, TextTruncate = Enum.TextTruncate.AtEnd}
    for k, v in pairs(p) do
        if k == "W" then d.FontFace = FONT[v] else d[k] = v end
    end
    return new("TextLabel", d, parent)
end
local function play(o, p, t, style, dir)
    if NOANIM then for k, v in pairs(p) do o[k] = v end return end
    TweenService:Create(o, TweenInfo.new(t or 0.2, style or QUINT, dir or Enum.EasingDirection.Out), p):Play()
end
local function safe(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[NEMESIS] " .. tostring(err)) end
end
local function copy(s) if setclipboard then setclipboard(s) elseif toclipboard then toclipboard(s) end end
local function toKey(n)
    local ok, v = pcall(function() return Enum.KeyCode[n] end)
    return ok and v or nil
end
local function textW(s, size)
    local ok, v = pcall(function() return TextService:GetTextSize(tostring(s), size, Enum.Font.Montserrat, Vector2.new(1000, 100)).X end)
    return ok and v or (#tostring(s) * size * 0.62)
end

-- IKON. Nama ikon (gaya Lucide) -> gambar kalau kamu isi SORU.Icons["nama"] = "rbxassetid://ID", kalau tidak -> glyph teks.
-- Bisa juga langsung kasih "rbxassetid://ID" / angka ID di Icon = ... pada Tab / SubTab / Accordion / Group.
SORU.Icons = {settings = "rbxassetid://70386228443175", chevron = "rbxassetid://6031091004"}
local GLYPH = {
    grid = "▦", home = "⌂", sprout = "✿", sliders = "☰", pickaxe = "⚒", hammer = "⚒", zap = "ϟ", wrench = "✎", save = "▣", eraser = "▱",
    box = "◧", layers = "≋", wheat = "✾", gauge = "◔", activity = "∿", target = "◎", star = "☆", starfill = "★", sort = "⇅", crosshair = "⌖",
    user = "☺", info = "ⓘ", palette = "◐", dot = "•", close = "✕", check = "✓", settings = "⚙", folder = "▤", list = "≡", play = "▶", eye = "◉",
}
local function mkIcon(parent, name, size, color, props)
    local ic = {}
    name = tostring(name or "dot")
    local src = SORU.Icons[name] or name
    local o
    if src:match("^rbxasset") or src:match("^%d%d%d+$") then
        o = new("ImageLabel", {BackgroundTransparency = 1, Image = src:match("^%d+$") and ("rbxassetid://" .. src) or src, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromOffset(size, size)}, parent)
        function ic.tint(c, t) play(o, {ImageColor3 = c}, t or 0.2) end
    elseif name == "search" then -- lensa dibuat dari Frame (lingkaran + gagang)
        o = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size)}, parent)
        local ring = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(size * 0.66, size * 0.66)}, o)
        corner(ring, "full")
        local rs = stroke(ring, color, 1.5, 0)
        local h = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(size * 0.82, size * 0.82), Size = UDim2.fromOffset(size * 0.4, 1.5), Rotation = 45, BackgroundColor3 = color, BorderSizePixel = 0}, o)
        corner(h, "full")
        function ic.tint(c, t) play(rs, {Color = c}, t or 0.2) play(h, {BackgroundColor3 = c}, t or 0.2) end
    elseif name == "bell" then -- lonceng dibuat dari Frame (kubah + dasar + pemukul)
        o = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size)}, parent)
        local parts = {}
        local function part(x, y, w, h, r)
            local f = new("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = color, BorderSizePixel = 0}, o)
            corner(f, r)
            parts[#parts + 1] = f
        end
        part(size * 0.2, size * 0.08, size * 0.6, size * 0.6, "full")
        part(size * 0.2, size * 0.4, size * 0.6, size * 0.28, 1)
        part(size * 0.08, size * 0.64, size * 0.84, math.max(1.5, size * 0.12), "full")
        part(size * 0.38, size * 0.82, size * 0.24, size * 0.16, "full")
        function ic.tint(c, t) for _, f in ipairs(parts) do play(f, {BackgroundColor3 = c}, t or 0.2) end end
    else
        o = text(parent, {Text = GLYPH[name] or name, Size = UDim2.fromOffset(size, size), TextXAlignment = XC, TextYAlignment = YC, W = 3, TextSize = math.floor(size * 1.05), TextColor3 = color, TextTruncate = NOTRUNC})
        function ic.tint(c, t) play(o, {TextColor3 = c}, t or 0.2) end
    end
    for k, v in pairs(props or {}) do o[k] = v end
    ic.inst = o
    return ic
end

-- logo: gambar (kalau LOGO diisi) atau huruf besar italic bergradien aksen
local function logoImg(parent, props)
    props.BackgroundTransparency = 1
    if LOGO ~= "" then
        props.Image = LOGO
        return new("ImageLabel", props, parent)
    end
    props.Text, props.FontFace, props.TextScaled, props.TextColor3, props.TextTruncate = LOGOCHAR, FONT_I, true, WHITE, NOTRUNC
    props.ScaleType = nil
    local l = new("TextLabel", props, parent)
    local g = new("UIGradient", {Rotation = 90}, l)
    local function paint() g.Color = ColorSequence.new(T.accentL, T.accent) end
    paint()
    themeFns[#themeFns + 1] = paint
    return l
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

-- kotak input: fill field gelap tanpa outline, outline aksen muncul saat fokus
local function inputBox(parent, p)
    local wrap = new("Frame", {BackgroundColor3 = T.field, BorderSizePixel = 0, ClipsDescendants = true}, parent)
    corner(wrap, 6)
    local st = stroke(wrap, T.outline, 1, 0.45)
    for k, v in pairs(p.wrap or {}) do wrap[k] = v end
    local box = new("TextBox", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        Text = p.text or "", PlaceholderText = p.placeholder or "", PlaceholderColor3 = T.faint, TextColor3 = T.text, FontFace = FONT[2], TextSize = 11,
        TextXAlignment = XL, ClearTextOnFocus = p.clear or false}, wrap)
    box.Focused:Connect(function() play(st, {Color = T.accent, Transparency = 0.25}, 0.2) end)
    box.FocusLost:Connect(function() play(st, {Color = T.outline, Transparency = 0.45}, 0.2) end)
    return wrap, box
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
    local body = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.el, BorderSizePixel = 0, Active = true}, dr)
    corner(body, 12)
    stroke(body, T.outline, 1, 0.2)
    local dtitle = text(body, {Text = "", Position = UDim2.fromOffset(12, 9), Size = UDim2.new(1, -24, 0, 18), W = 3, TextSize = 12})
    local _, box = inputBox(body, {placeholder = "Search...", wrap = {Position = UDim2.fromOffset(8, 32), Size = UDim2.new(1, -16, 0, 28), BackgroundColor3 = T.field}})
    local list = new("ScrollingFrame", {Position = UDim2.fromOffset(6, 68), Size = UDim2.new(1, -12, 1, -74), BackgroundTransparency = 1, BorderSizePixel = 0,
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
        dtitle.Text = tostring(sp.title or "")
        list.CanvasPosition = Vector2.new(0, 0)
        for _, r in ipairs(rows) do r.btn:Destroy() end
        rows = {}
        for i, n in ipairs(sp.options) do
            local name = tostring(n)
            local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.field, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i}, list)
            corner(b, 7)
            local tx, cbox, mark, tick = 8, nil, nil, nil
            if sp.multi then
                cbox = new("Frame", {Position = UDim2.new(0, 8, 0.5, -7), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.off, BorderSizePixel = 0}, b)
                corner(cbox, 4)
                stroke(cbox, T.outline, 1, 0.1)
                mark = new("ImageLabel", {BackgroundTransparency = 1, Image = "rbxassetid://6031094667", Size = UDim2.new(1, 2, 1, 2), Position = UDim2.fromOffset(-1, -1), ImageTransparency = 1}, cbox)
                tx = 30
            end
            if not sp.multi then
                tick = new("ImageLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1,
                    Image = "rbxassetid://6031094667", ImageColor3 = T.accent, ImageTransparency = 1}, b)
            end
            local sc = sp.swatch and sp.swatch(name)
            if sc then
                local dot = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, tx, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = sc, BorderSizePixel = 0}, b)
                corner(dot, "full")
                tx = tx + 20
            end
            local lb = text(b, {Text = name, Position = UDim2.fromOffset(tx, 0), Size = UDim2.new(1, -(tx + (tick and 26 or 6)), 1, 0), W = 2, TextSize = 11, TextColor3 = T.mid})
            local r = {btn = b, name = name}
            function r.paint()
                local on = sp.isSel(name)
                b.BackgroundColor3 = on and T.accent or T.field
                b.BackgroundTransparency = on and 0.84 or 1
                if sp.multi then
                    cbox.BackgroundColor3 = on and T.accent or T.off
                    mark.ImageTransparency = on and 0 or 1
                    lb.TextColor3 = on and T.text or T.dim
                    lb.FontFace = on and FONT[3] or FONT[2]
                else
                    lb.TextColor3 = on and T.text or T.dim
                    tick.ImageColor3 = T.accent
                    tick.ImageTransparency = on and 0 or 1
                end
            end
            b.MouseEnter:Connect(function()
                if not sp.isSel(name) then
                    lb.TextColor3 = T.text
                    b.BackgroundColor3, b.BackgroundTransparency = T.hover, 0
                end
            end)
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
    LOGONAME = string.upper(tostring(C.Title or C.Name or "NEMESIS"))
    LOGOCHAR = LOGONAME:sub(1, 1)
    LOGO = ""
    if type(C.Icons) == "table" then for k, v in pairs(C.Icons) do SORU.Icons[k] = tostring(v) end end
    if C.Logo then
        LOGO = tostring(C.Logo)
        if LOGO:match("^%d+$") then LOGO = "rbxassetid://" .. LOGO end
    elseif C.LogoUrl then
        local u = tostring(C.LogoUrl)
        LOGO = fetchImage(u, "logo_" .. #u .. "_" .. (u:sub(-14):gsub("%W", "")) .. ".png")
    end

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
    local curTheme = (type(F.UITheme) == "string" and THEMES[F.UITheme]) and F.UITheme or ORDER[1]
    applyTheme(curTheme)
    local toggleKey = C.ToggleKey or Enum.KeyCode.RightControl
    if type(F.MenuKey) == "string" then toggleKey = toKey(F.MenuKey) or toggleKey end
    local binding, activeStop = false, nil

    ------------------------------------------------------------------
    -- ROOT + SKALA (anti-DPI)
    ------------------------------------------------------------------
    local REF = C.ReferenceSize or Vector2.new(1280, 650)
    local root = new("Frame", {Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)
    local rootScale = new("UIScale", {}, root)
    local DEFAULT, MINS, MAXS = Vector2.new(640, 410), Vector2.new(500, 330), Vector2.new(1000, 660)
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

    -- ripple klik halus (posisi dari kursor / sentuhan terakhir)
    local function ripple(f, size)
        if NOANIM then return end
        local loc = UIS:GetMouseLocation()
        local s = math.max(rootScale.Scale, 0.01)
        local ap, asz = f.AbsolutePosition, f.AbsoluteSize
        local x = math.clamp((loc.X - ap.X) / s, 0, asz.X / s)
        local y = math.clamp((loc.Y - ap.Y) / s, 0, asz.Y / s)
        local r = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, BorderSizePixel = 0}, f)
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
    -- TOAST (kanan bawah, maksimal 5, klik untuk menutup) + riwayat untuk lonceng
    ------------------------------------------------------------------
    local toastHolder = new("Frame", {Name = "Toasts", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.new(0, 280, 1, -20), BackgroundTransparency = 1, ZIndex = 200}, root)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom}, toastHolder)
    local toasts, toastN = {}, 0
    local notifs, unread, notifHook = {}, 0, nil
    local function notify(title, msg, color, dur, img)
        color, dur = color or T.accent, dur or 3
        toastN = toastN + 1
        notifs[#notifs + 1] = {t = tostring(title or ""), m = tostring(msg or ""), c = color, at = os.time()}
        if #notifs > 30 then table.remove(notifs, 1) end
        unread = unread + 1
        if notifHook then notifHook() end
        local wrap = new("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, LayoutOrder = toastN}, toastHolder)
        local m = new("Frame", {Position = UDim2.fromOffset(310, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.el, BackgroundTransparency = 0.02, BorderSizePixel = 0, ClipsDescendants = true}, wrap)
        corner(m, 9)
        stroke(m, color, 1, 0.7)
        local ic = new("Frame", {Position = UDim2.fromOffset(10, 11), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = color, BackgroundTransparency = 0.82, BorderSizePixel = 0}, m)
        corner(ic, 8)
        if img then
            new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Image = img, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit}, ic)
        else
            logoImg(ic, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20), ScaleType = Enum.ScaleType.Fit})
        end
        text(m, {Text = tostring(title or ""), Position = UDim2.fromOffset(52, 9), Size = UDim2.new(1, -62, 0, 16), W = 3})
        text(m, {Text = tostring(msg or ""), Position = UDim2.fromOffset(52, 26), Size = UDim2.new(1, -62, 0, 24), TextSize = 10, W = 1, TextColor3 = T.dim, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top})
        local pr = new("Frame", {Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = color, BorderSizePixel = 0}, m)
        local gone, entry = false, {}
        local function leave()
            if gone then return end
            gone = true
            for i, e in ipairs(toasts) do if e == entry then table.remove(toasts, i) break end end
            play(m, {Position = UDim2.fromOffset(310, 0)}, 0.5, QUINT, Enum.EasingDirection.In)
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
    -- SHELL + WINDOW
    ------------------------------------------------------------------
    local Window = {Tabs = {}, Flags = Reg, Gui = gui, PlaceId = placeId, GameId = gameId}
    local shell = new("Frame", {Name = "Shell", BackgroundTransparency = 1, Visible = false}, root)
    local wsh = shadow(shell)
    local win = new("Frame", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = WHITE, BorderSizePixel = 0, ClipsDescendants = true, Active = true}, shell)
    corner(win, 12)
    stroke(win, T.outline, 1, 0.1)
    local winG = new("UIGradient", {Rotation = 135}, win)
    local function paintWin()
        winG.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, T.bg:Lerp(T.accent, 0.1)), ColorSequenceKeypoint.new(0.6, T.bg), ColorSequenceKeypoint.new(1, T.bg)})
    end
    paintWin()
    themeFns[#themeFns + 1] = paintWin
    local winScale = new("UIScale", {Scale = 1}, win)
    local ctxWin = newCtx(win, 12)

    layoutWin = function(anim)
        local sz = Vector2.new(math.min(winSize.X, virt.X - 20), math.min(winSize.Y, virt.Y - 20))
        local x, y
        if winPos then x, y = winPos.X, winPos.Y else x, y = (virt.X - sz.X) / 2, (virt.Y - sz.Y) / 2 + 12 end
        x = math.clamp(x, 10, math.max(10, virt.X - sz.X - 10))
        y = math.clamp(y, 10, math.max(10, virt.Y - sz.Y - 10))
        if winPos then winPos = Vector2.new(x, y) end
        curPos = Vector2.new(x, y)
        shell.Size = UDim2.fromOffset(sz.X, sz.Y)
        if anim then play(shell, {Position = UDim2.fromOffset(x, y)}, anim == true and 0.5 or anim) else shell.Position = UDim2.fromOffset(x, y) end
    end

    ------------------------------------------------------------------
    -- SIDEBAR: logo, grup navigasi (ikon + nama + panah urut), item halaman, tombol UI Settings
    ------------------------------------------------------------------
    local SIDE_W, LOGO_H, FOOT_H = 156, 58, 40
    local sbg = new("Frame", {Name = "Sidebar", Size = UDim2.new(0, SIDE_W, 1, 0), BackgroundColor3 = T.side, BorderSizePixel = 0, ClipsDescendants = true}, win)
    corner(sbg, 12)
    new("Frame", {Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0, 12, 1, 0), BackgroundColor3 = T.side, BorderSizePixel = 0}, sbg) -- luruskan sisi kanan
    new("Frame", {Name = "Separator", Position = UDim2.fromOffset(SIDE_W - 1, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.outline, BackgroundTransparency = 0.55, BorderSizePixel = 0}, win)

local dragLogo = new("Frame", {Name = "LogoArea", Size = UDim2.new(0, SIDE_W - 1, 0, LOGO_H), BackgroundTransparency = 1, Active = true}, win)
    local BS = 32                                    -- ukuran badge (px)
    local BX, BY = 14, math.floor((LOGO_H - BS) / 2) -- posisi badge: kiri, tengah vertikal

    -- glow aksen berlapis di belakang badge (berdenyut pelan, diam kalau "Reduce animation" aktif)
    for i, pad in ipairs({5, 10, 15, 20}) do
        local base = 0.74 + i * 0.05
        local gl = new("Frame", {Name = "Glow" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(BX + BS / 2, BY + BS / 2),
            Size = UDim2.fromOffset(BS + pad, BS + pad), BackgroundTransparency = base, BorderSizePixel = 0, ZIndex = 1}, dragLogo)
        corner(gl, 11 + pad / 2)
        skin(gl, "BackgroundColor3", "accent")
        if not NOANIM then
            TweenService:Create(gl, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = math.min(1, base + 0.08)}):Play()
        end
    end

    local bgG, chG -- gradien badge & huruf; dicat ulang saat tema berganti
    if LOGO ~= "" then
        -- kalau C.Logo / C.LogoUrl diisi, gambarnya dipakai sebagai ikon di kiri
        new("ImageLabel", {Name = "Logo", Position = UDim2.fromOffset(BX, BY), Size = UDim2.fromOffset(BS, BS), BackgroundTransparency = 1,
            Image = LOGO, ScaleType = Enum.ScaleType.Fit, ZIndex = 2}, dragLogo)
    else
        local badge = new("Frame", {Name = "Badge", Position = UDim2.fromOffset(BX, BY), Size = UDim2.fromOffset(BS, BS), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, dragLogo)
        corner(badge, 11)
        bgG = new("UIGradient", {Rotation = 90}, badge)
        skin(stroke(badge, T.accentL, 1, 0.3), "Color", "accentL") -- garis tepi lavender tipis
        local gloss = new("Frame", {Name = "Gloss", Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 0.55, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, badge)
        corner(gloss, 10)
        new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.76), NumberSequenceKeypoint.new(1, 1)})}, gloss)
        local ch = text(badge, {Name = "Letter", Text = LOGOCHAR, Size = UDim2.fromScale(1, 1), TextXAlignment = XC, TextYAlignment = YC,
            FontFace = FONT_I, TextSize = 26, TextTruncate = NOTRUNC, ZIndex = 4})
        chG = new("UIGradient", {Rotation = 90}, ch)
    end

    -- nama: putih -> lavender muda, otomatis mengecil kalau namanya panjang
    local NX = BX + BS + 10
    local nm = text(dragLogo, {Name = "LogoName", Text = LOGONAME, Position = UDim2.fromOffset(NX, 0), Size = UDim2.new(1, -(NX + 8), 1, 0),
        W = 3, TextSize = 15, TextScaled = true, TextTruncate = NOTRUNC, ZIndex = 2})
    new("UITextSizeConstraint", {MinTextSize = 7, MaxTextSize = 15}, nm)
    local ng = new("UIGradient", {}, nm)

    -- garis pemisah tipis di bawah banner (nuansa ungu)
    local ll = new("Frame", {Name = "LogoLine", Position = UDim2.fromOffset(0, LOGO_H), Size = UDim2.new(0, SIDE_W - 1, 0, 1), BackgroundTransparency = 0.4, BorderSizePixel = 0}, win)

    local function paintBanner()
        if bgG then bgG.Color = ColorSequence.new(T.accent:Lerp(WHITE, 0.12), T.accent2) end
        if chG then chG.Color = ColorSequence.new(WHITE, T.accentL) end
        ng.Color = ColorSequence.new(WHITE, T.accentL:Lerp(WHITE, 0.5))
        ll.BackgroundColor3 = T.accent:Lerp(T.outline, 0.55)
    end
    paintBanner()
    themeFns[#themeFns + 1] = paintBanner
    
    local NAV_Y = LOGO_H + 5
    local nav = new("ScrollingFrame", {Name = "Nav", Active = true, Position = UDim2.fromOffset(0, NAV_Y), Size = UDim2.new(1, -1, 1, -(NAV_Y + FOOT_H)), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y}, sbg)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)}, nav)
    new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 2)}, nav)

    -- tombol UI Settings (kiri bawah)
    local setBtn = new("TextButton", {Name = "UISettings", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -9), Size = UDim2.new(1, -25, 0, 24), BackgroundColor3 = T.chip,
        Text = "", AutoButtonColor = false, BorderSizePixel = 0}, sbg)
    corner(setBtn, 7)
    local setIc = mkIcon(setBtn, "settings", 11, T.mid, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0)})
    local setLb = text(setBtn, {Text = "UI Settings", Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -34, 1, 0), W = 2, TextSize = 11, TextColor3 = T.mid, TextTruncate = NOTRUNC})

    ------------------------------------------------------------------
    -- MAIN: judul halaman + subjudul, tombol bintang / lonceng / pencarian, chip sub-tab, konten
    ------------------------------------------------------------------
    local main = new("Frame", {Name = "Main", Position = UDim2.fromOffset(SIDE_W, 0), Size = UDim2.new(1, -SIDE_W, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true}, win)
    local dragMain = new("Frame", {Name = "DragZone", Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Active = true}, main)
    local titleL = text(main, {Name = "Title", Text = "", Position = UDim2.fromOffset(14, 11), Size = UDim2.new(1, -270, 0, 18), W = 3, TextSize = 14})
    skin(titleL, "TextColor3", "accentL")
    local subL = text(main, {Name = "Subtitle", Text = "", Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -270, 0, 12), TextSize = 10, W = 1, TextColor3 = T.faint})
    local hl = new("Frame", {Name = "HeaderLine", Position = UDim2.fromOffset(14, 47), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 0.35, BorderSizePixel = 0}, main)
    new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.55), NumberSequenceKeypoint.new(1, 1)})}, hl)

    local SEARCH_W = 170
    local function hdrBtn(name, xOff)
        local b = new("TextButton", {Name = name, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, xOff, 0, 13), Size = UDim2.fromOffset(25, 23), BackgroundColor3 = T.chip, Text = "", AutoButtonColor = false, BorderSizePixel = 0}, main)
        corner(b, 6)
        stroke(b, T.outline, 1, 0.45)
        b.MouseEnter:Connect(function() play(b, {BackgroundColor3 = T.hover}, 0.15) end)
        b.MouseLeave:Connect(function() play(b, {BackgroundColor3 = T.chip}, 0.15) end)
        return b
    end
    local starB = hdrBtn("Favorite", -(14 + SEARCH_W + 6 + 25 + 6))
    local starIc = mkIcon(starB, "star", 13, T.mid, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
    local bellB = hdrBtn("Notifications", -(14 + SEARCH_W + 6))
    local bellIc = mkIcon(bellB, "bell", 12, T.mid, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
    local badge = new("Frame", {Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -1, 0, 2), Size = UDim2.fromOffset(13, 13), BackgroundColor3 = T.bad, BorderSizePixel = 0, ZIndex = 5, Visible = false}, bellB)
    corner(badge, "full")
    local badgeL = text(badge, {Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 8, TextTruncate = NOTRUNC, ZIndex = 6, Text = "0"})

    local sBox = new("Frame", {Name = "Search", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 13), Size = UDim2.fromOffset(SEARCH_W, 23), BackgroundColor3 = T.chip, BorderSizePixel = 0}, main)
    corner(sBox, 6)
    local sStroke = stroke(sBox, T.outline, 1, 0.45)
    mkIcon(sBox, "search", 11, T.mid, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0)})
    local sInput = new("TextBox", {Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(28, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", PlaceholderText = "Search tabs/groups...",
        PlaceholderColor3 = T.faint, TextColor3 = T.text, FontFace = FONT[2], TextSize = 10, TextXAlignment = XL, ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd}, sBox)
    sInput.Focused:Connect(function() play(sStroke, {Color = T.accent, Transparency = 0.3}, 0.2) end)
    sInput.FocusLost:Connect(function() play(sStroke, {Color = T.outline, Transparency = 0.45}, 0.2) end)

    -- resize handle: tiga garis diagonal samar
    local rh = new("TextButton", {Name = "ResizeHandle", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 100}, win)
    local rLines = {}
    for _, cfg in ipairs({{6, -2, -2}, {10, -2, -6}, {14, -2, -10}}) do
        local ln = new("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, cfg[2], 1, cfg[3]), Size = UDim2.fromOffset(cfg[1], 1), Rotation = -45, BackgroundColor3 = T.faint, BorderSizePixel = 0, ZIndex = 101}, rh)
        corner(ln, "full")
        rLines[#rLines + 1] = ln
    end
    rh.MouseEnter:Connect(function() for _, l in ipairs(rLines) do play(l, {BackgroundColor3 = T.accent}, 0.2) end end)
    rh.MouseLeave:Connect(function() for _, l in ipairs(rLines) do play(l, {BackgroundColor3 = T.faint}, 0.2) end end)

    ------------------------------------------------------------------
    -- PILL DI ATAS (launcher): logo + nama + FPS live. Tap = buka/tutup window, tarik = pindah posisi.
    ------------------------------------------------------------------
    local launchPos = nil -- (x tengah, y atas) dalam koordinat virtual
        local launcher = new("Frame", {Name = "Launcher", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = WHITE, BackgroundTransparency = 0.04, BorderSizePixel = 0, Active = true, ZIndex = 90}, root)
    corner(launcher, "full")
    -- latar gradien gelap dengan semburat warna tema
    local bgG = new("UIGradient", {Rotation = 90}, launcher)
    -- border gradien yang berputar pelan (cahaya jalan)
    local edge = stroke(launcher, WHITE, 1.2, 0)
    local edgeG = new("UIGradient", {Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(1, 0.05)})}, edge)
    local function paintLauncher()
        bgG.Color = ColorSequence.new(T.bg:Lerp(T.accent, 0.22), T.side:Lerp(T.accent, 0.06))
        edgeG.Color = ColorSequence.new(T.accentL, T.accent2)
    end
    paintLauncher()
    themeFns[#themeFns + 1] = paintLauncher
    bind(RunService.Heartbeat, function()
        if NOANIM or not launcher.Visible then return end
        edgeG.Rotation = (os.clock() * 70) % 360
    end)
    launcher.MouseEnter:Connect(function() play(edge, {Thickness = 1.8}, 0.2) end)
    launcher.MouseLeave:Connect(function() play(edge, {Thickness = 1.2}, 0.2) end)

    new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 13)}, launcher)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 7)}, launcher)
    logoImg(launcher, {Name = "Mark", Size = UDim2.fromOffset(14, 14), LayoutOrder = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 91})
    local pillName = text(launcher, {Name = "Name", Text = LOGONAME, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 14), W = 4, TextSize = 9, TextTruncate = NOTRUNC, LayoutOrder = 2, ZIndex = 91})
    skin(pillName, "TextColor3", "accentL")
    new("Frame", {Name = "Divider", Size = UDim2.fromOffset(1, 10), BackgroundColor3 = WHITE, BackgroundTransparency = 0.82, BorderSizePixel = 0, LayoutOrder = 3, ZIndex = 91}, launcher)

    -- bar sinyal: jumlah bar menyala + warna mengikuti FPS (hijau / kuning / merah)
    local bars = new("Frame", {Name = "Bars", Size = UDim2.fromOffset(14, 12), BackgroundTransparency = 1, LayoutOrder = 4, ZIndex = 91}, launcher)
    local sig = {}
    for i, h in ipairs({4, 6, 9, 12}) do
        sig[i] = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, (i - 1) * 4, 1, 0), Size = UDim2.fromOffset(2, h), BackgroundColor3 = T.off, BorderSizePixel = 0, ZIndex = 92}, bars)
        corner(sig[i], "full")
    end
    local fpsL = text(launcher, {Name = "FPS", Text = "--", Size = UDim2.fromOffset(24, 14), W = 4, TextSize = 9, TextTruncate = NOTRUNC, LayoutOrder = 5, ZIndex = 91})
    do
        local frames, acc = 0, 0
        bind(RunService.Heartbeat, function(dt)
            frames = frames + 1
            acc = acc + dt
            if acc < 0.5 then return end
            local fps = math.floor(frames / acc + 0.5)
            frames, acc = 0, 0
            fpsL.Text = tostring(fps)
            local lit, col = 1, T.bad
            if fps >= 50 then lit, col = 4, T.ok elseif fps >= 35 then lit, col = 3, T.ok elseif fps >= 20 then lit, col = 2, T.warn end
            fpsL.TextColor3 = col
            for i, b in ipairs(sig) do b.BackgroundColor3 = (i <= lit) and col or T.off end
        end)
    end
    layoutLauncher = function()
        if not launchPos then launchPos = Vector2.new(virt.X / 2, 8) end
        launchPos = Vector2.new(math.clamp(launchPos.X, 40, math.max(40, virt.X - 40)), math.clamp(launchPos.Y, 2, math.max(2, virt.Y - 30)))
        launcher.Position = UDim2.fromOffset(launchPos.X, launchPos.Y)
    end

    ------------------------------------------------------------------
    -- BUKA / TUTUP: window "keluar" dari pill di atas dan kembali masuk ke pill saat ditutup
    ------------------------------------------------------------------
    local function pillCenter()
        if launchPos then return Vector2.new(launchPos.X, launchPos.Y + 11) end
        return Vector2.new(virt.X / 2, 19)
    end
    local function openA()
        if isOpen then return end
        isOpen = true
        layoutWin()
        shell.Visible = true
        if NOANIM then return blurUpdate() end
        local pc, sz = pillCenter(), shell.Size
        shell.Position = UDim2.fromOffset(pc.X - sz.X.Offset / 2, pc.Y - sz.Y.Offset / 2)
        winScale.Scale, wsh.ImageTransparency = 0.06, 1
        play(shell, {Position = UDim2.fromOffset(curPos.X, curPos.Y)}, 0.45, QUINT)
        play(winScale, {Scale = 1}, 0.45, QUINT)
        play(wsh, {ImageTransparency = 0.5}, 0.4)
        blurUpdate()
    end
    local function closeA()
        if not isOpen then return end
        isOpen = false
        if ctxWin.d then ctxWin.d.close() end
        blurUpdate()
        if NOANIM then shell.Visible = false return end
        local pc, sz = pillCenter(), shell.Size
        play(shell, {Position = UDim2.fromOffset(pc.X - sz.X.Offset / 2, pc.Y - sz.Y.Offset / 2)}, 0.34, QUINT, Enum.EasingDirection.In)
        play(winScale, {Scale = 0.06}, 0.34, QUINT, Enum.EasingDirection.In)
        play(wsh, {ImageTransparency = 1}, 0.25)
        task.delay(0.36, function() if not isOpen then shell.Visible = false end end)
    end
    local function toggleWin() if isOpen then closeA() else openA() end end

    track(launcher,
        function() return launchPos end,
        function(dx, dy, st, moved)
            if moved and st then
                launchPos = Vector2.new(st.X + dx / rootScale.Scale, st.Y + dy / rootScale.Scale)
                layoutLauncher()
            end
        end,
        function(moved) if not moved then toggleWin() end end)
    local function dragWin(h)
        track(h,
            function() winPos = curPos return curPos end,
            function(dx, dy, st, moved)
                if moved and st then
                    winPos = Vector2.new(st.X + dx / rootScale.Scale, st.Y + dy / rootScale.Scale)
                    layoutWin(0.15)
                end
            end)
    end
    dragWin(dragMain)
    dragWin(dragLogo)

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
    -- NAVIGASI: grup (header + item halaman) -> halaman -> sub-tab (chip) -> kolom kartu
    ------------------------------------------------------------------
    local GH, IH, IGAP, HGAP = 26, 22, 4, 4 -- tinggi header grup, tinggi item, jarak antar item, jarak header -> item
    local TOP0, TOP1 = 50, 82 -- awal konten tanpa / dengan baris chip
    local groups, glist, pages = {}, {}, {}
    local cur, lastPage, searching = nil, nil, false
    local SETTINGS = "\0settings"
    local favs = type(F.UIFavs) == "table" and F.UIFavs or {}
    F.UIFavs = favs

    local function itemsH(g)
        local n = 0
        for _, p in ipairs(g.pages) do if p.item.Visible then n = n + 1 end end
        return (n > 0) and (n * IH + (n - 1) * IGAP) or 0
    end
    local function relayoutGroup(g, anim)
        local ih = itemsH(g)
        local open = g.open or searching
        g.items.Size = UDim2.new(1, 0, 0, ih)
        local h = (g.vis == false) and 0 or (GH + ((open and ih > 0) and (ih + HGAP + 2) or 0))
        g.holder.Visible = g.vis ~= false
        if anim then play(g.holder, {Size = UDim2.new(1, 0, 0, h)}, 0.25) else g.holder.Size = UDim2.new(1, 0, 0, h) end
    end

    local function createGroup(name, icon)
        if groups[name] then return groups[name] end
        local g = {name = name, pages = {}, open = true}
        groups[name] = g
        glist[#glist + 1] = g
        g.holder = new("Frame", {Name = name .. "Group", Size = UDim2.new(1, 0, 0, GH), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = #glist}, nav)
        g.head = new("TextButton", {Name = "Header", Size = UDim2.new(1, 0, 0, GH), BackgroundColor3 = T.el, BorderSizePixel = 0, AutoButtonColor = false, Text = ""}, g.holder)
        corner(g.head, 7)
        g.icon = mkIcon(g.head, icon or "dot", 12, T.text, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0)})
        text(g.head, {Text = name, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -52, 1, 0), W = 3, TextSize = 11})
        local sortIc = mkIcon(g.head, "sort", 11, T.mid, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0)})
        g.items = new("Frame", {Name = "Items", Position = UDim2.fromOffset(0, GH + HGAP), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0}, g.holder)
        new("UIListLayout", {Padding = UDim.new(0, IGAP), SortOrder = Enum.SortOrder.LayoutOrder}, g.items)
        new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, g.items)
        g.head.MouseEnter:Connect(function() play(g.head, {BackgroundColor3 = T.hover}, 0.15) end)
        g.head.MouseLeave:Connect(function() play(g.head, {BackgroundColor3 = T.el}, 0.15) end)
        g.head.MouseButton1Click:Connect(function()
            g.open = not g.open
            sortIc.tint(g.open and T.mid or T.accentL)
            relayoutGroup(g, true)
        end)
        relayoutGroup(g)
        return g
    end

    -- area scroll 2 kolom (kartu masuk bergantian kiri / kanan, atau pilih lewat Column = 1 / 2)
    local function newScroll(parent, columns)
        local scroll = new("ScrollingFrame", {Name = "Scroll", Active = true, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageTransparency = 0.3,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false}, parent)
        skin(scroll, "ScrollBarImageColor3", "accent")
        new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}, scroll)
        local holder = new("Frame", {Name = "Columns", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0}, scroll)
        new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top}, holder)
        local single = (columns == 1)
        local function col(i)
            local c = new("Frame", {Name = "Col" .. i, Size = single and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = i}, holder)
            new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, c)
            return c
        end
        local cL = col(1)
        return scroll, cL, (not single) and col(2) or nil
    end

    local buildComponents, go -- didefinisikan di bawah
    local function paintChip(s, on)
        play(s.chip, {BackgroundColor3 = on and T.chipOn or T.chip}, 0.2)
        if s.chipSt then play(s.chipSt, {Transparency = on and 0.4 or 1}, 0.2) end
        play(s.chipLb, {TextColor3 = on and T.text or T.mid}, 0.2)
        if s.chipIc then s.chipIc.tint(on and T.text or T.mid) end
    end
    local function pillCols()
        local h, s, v = T.accent:ToHSV()
        return Color3.fromHSV((h - 0.06) % 1, math.clamp(s * 1.25, 0, 1), math.min(v * 0.92, 0.72)),
            Color3.fromHSV((h + 0.06) % 1, math.clamp(s * 1.15, 0, 1), math.min(v * 0.75, 0.6))
    end
    local function paintItem(p, on, instant)
        p.on = on
        local function set(o, props, t)
            if instant then for k, v in pairs(props) do o[k] = v end else play(o, props, t or 0.22) end
        end
        set(p.pill, {BackgroundTransparency = on and 0 or 1})
        set(p.pillSt, {Transparency = on and 0.5 or 1})
        set(p.item, {BackgroundTransparency = 1})
        set(p.label, {TextColor3 = on and T.text or T.faint})
        p.icon.tint(on and WHITE or T.faint, instant and 0 or 0.22)
        set(p.bar, {Size = UDim2.fromOffset(3, on and 12 or 0)})
        set(p.barGlow, {Size = UDim2.fromOffset(7, on and 18 or 0), BackgroundTransparency = on and 0.7 or 1})
        if p.iconGlow then set(p.iconGlow, {Transparency = on and 0.55 or 1}) end
        if on and not instant and not NOANIM then -- kilau gradien saat tab dipilih
            p.pillG.Offset = Vector2.new(-0.3, 0)
            play(p.pillG, {Offset = Vector2.new(0, 0)}, 0.4)
        end
    end
    local function paintSettingsBtn(on)
        play(setBtn, {BackgroundColor3 = on and T.accent or T.chip}, 0.2)
        play(setLb, {TextColor3 = on and T.text or T.mid}, 0.2)
        setIc.tint(on and T.text or T.mid)
    end
    local function updateStar()
        local p = pages[cur]
        local on = p ~= nil and not p.hidden and favs[p.key] == true
        if starIc.inst:IsA("TextLabel") then starIc.inst.Text = on and "★" or "☆" end
        starIc.tint(on and T.accentL or T.mid)
    end

    local function createPage(gname, name, icon, subtitle, columns, hidden)
        local key = hidden and SETTINGS or (gname .. "/" .. name)
        local p = {key = key, name = name, subtitle = subtitle, subs = {}, hidden = hidden, top = TOP0, on = false}
        pages[key] = p
        if not hidden then
            local g = createGroup(gname, nil)
            p.group = g
            p.item = new("TextButton", {Name = name .. "Button", LayoutOrder = #g.pages + 1, Size = UDim2.new(1, 0, 0, IH), BackgroundColor3 = T.el, BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = ""}, g.items)
            corner(p.item, 8)
            -- pil aktif (gradien horizontal), hanya tampil saat tab dipilih
            p.pill = new("Frame", {Name = "Pill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0}, p.item)
            corner(p.pill, 8)
            p.pillG = new("UIGradient", {Rotation = 0}, p.pill)
            p.pillSt = skin(stroke(p.pill, T.accentL, 1, 1), "Color", "accentL")
            p.icon = mkIcon(p.item, icon or "dot", 12, T.faint, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0)})
            if p.icon.inst:IsA("TextLabel") then -- ikon teks: outline lembut supaya terlihat bercahaya saat aktif
                p.iconGlow = skin(new("UIStroke", {Thickness = 1.5, Transparency = 1}, p.icon.inst), "Color", "accentL")
            end
            p.label = text(p.item, {Text = name, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -48, 1, 0), W = 2, TextSize = 11, TextColor3 = T.faint})
            -- garis glow di tepi kiri pil
            p.barGlow = new("Frame", {Name = "IndicatorGlow", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(7, 0), BackgroundTransparency = 1, BorderSizePixel = 0}, p.item)
            corner(p.barGlow, "full")
            p.bar = new("Frame", {Name = "Indicator", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(3, 0), BorderSizePixel = 0}, p.item)
            corner(p.bar, "full")
            p.star = text(p.item, {Text = "★", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -7, 0.5, 0), Size = UDim2.fromOffset(12, 12), TextXAlignment = XC, TextSize = 9, TextTruncate = NOTRUNC, Visible = favs[key] == true})
            skin(p.star, "TextColor3", "accentL")
            local function paintPill()
                local l, r = pillCols()
                p.pillG.Color = ColorSequence.new(l, r)
                local bc = T.accentL:Lerp(WHITE, 0.55)
                p.bar.BackgroundColor3, p.barGlow.BackgroundColor3 = bc, bc
            end
            paintPill()
            themeFns[#themeFns + 1] = function() -- jalan SETELAH callback tema bawaan, jadi warna di sini yang menang
                p.item.BackgroundColor3 = T.el
                paintPill()
                paintItem(p, p.on, true)
            end
            g.pages[#g.pages + 1] = p
            relayoutGroup(g)
            p.item.MouseEnter:Connect(function()
                if not p.on then
                    play(p.item, {BackgroundTransparency = 0.35}, 0.15)
                    play(p.label, {TextColor3 = T.mid}, 0.15)
                    p.icon.tint(T.mid, 0.15)
                end
            end)
            p.item.MouseLeave:Connect(function()
                if not p.on then
                    play(p.item, {BackgroundTransparency = 1}, 0.15)
                    play(p.label, {TextColor3 = T.faint}, 0.15)
                    p.icon.tint(T.faint, 0.15)
                end
            end)
            p.item.MouseButton1Click:Connect(function()
                if ctxWin.d then ctxWin.d.close() end
                if cur ~= key then ripple(p.item, 120) end
                go(key)
            end)
        end
        p.frame = new("Frame", {Name = name, Position = UDim2.fromOffset(0, TOP0), Size = UDim2.new(1, 0, 1, -TOP0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Visible = false}, main)
        p.chips = new("ScrollingFrame", {Name = name .. "Chips", Active = true, Position = UDim2.fromOffset(14, 55), Size = UDim2.new(1, -28, 0, 24), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, Visible = false}, main)
        new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center}, p.chips)
        new("UIPadding", {PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 1)}, p.chips)
        p.dScroll, p.dL, p.dR = newScroll(p.frame, columns)
        p.K = buildComponents(p.dScroll, p.dL, ctxWin, {p.dL, p.dR})
        p.K.Page = p

        function p.setSub(i, instant)
            local s = p.subs[i]
            if not s or p.curSub == i then return end
            local old = p.subs[p.curSub]
            if old then old.scroll.Visible = false paintChip(old, false) end
            p.curSub = i
            paintChip(s, true)
            s.scroll.Visible = true
            if not instant and not NOANIM then
                s.scroll.Position = UDim2.fromOffset(10, 0)
                play(s.scroll, {Position = UDim2.fromOffset(0, 0)}, 0.3)
            end
        end
        function p.addSub(c)
            if type(c) ~= "table" then c = {Title = tostring(c)} end
            local s = {name = tostring(c.Title or c.Name or ("Tab " .. (#p.subs + 1)))}
            local i = #p.subs + 1
            p.subs[i] = s
            if i == 1 then -- sub-tab pertama: tampilkan baris chip, konten bawaan halaman disembunyikan
                p.top = TOP1
                p.frame.Position, p.frame.Size = UDim2.fromOffset(0, TOP1), UDim2.new(1, 0, 1, -TOP1)
                p.dScroll.Visible = false
                p.chips.Visible = (cur == key)
            end
            s.chip = new("TextButton", {Name = s.name, LayoutOrder = i, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), BackgroundColor3 = T.chip, BorderSizePixel = 0, AutoButtonColor = false, Text = ""}, p.chips)
            corner(s.chip, 10)
            s.chipSt = skin(stroke(s.chip, T.accent, 1, 1), "Color", "accent")
            new("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 11)}, s.chip)
            new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5)}, s.chip)
            if c.Icon then s.chipIc = mkIcon(s.chip, c.Icon, 11, T.mid, {LayoutOrder = 1}) end
            s.chipLb = text(s.chip, {Text = s.name, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 14), W = 2, TextSize = 10, TextColor3 = T.mid, TextTruncate = NOTRUNC, LayoutOrder = 2})
            s.chip.MouseEnter:Connect(function() if p.curSub ~= i then play(s.chipLb, {TextColor3 = T.text}, 0.15) play(s.chip, {BackgroundColor3 = T.hover}, 0.15) end end)
            s.chip.MouseLeave:Connect(function() if p.curSub ~= i then play(s.chipLb, {TextColor3 = T.mid}, 0.15) play(s.chip, {BackgroundColor3 = T.chip}, 0.15) end end)
            s.chip.MouseButton1Click:Connect(function() p.setSub(i) end)
            local cL, cR
            s.scroll, cL, cR = newScroll(p.frame, c.Columns or columns)
            s.K = buildComponents(s.scroll, cL, ctxWin, {cL, cR})
            if i == 1 then p.setSub(1, true) end
            return s.K
        end
        p.K.SubTab = function(_, c) return p.addSub(c) end
        return p
    end

    local function showPage(p)
        p.frame.Visible = true
        p.chips.Visible = #p.subs > 0
        if #p.subs == 0 then p.dScroll.Visible = true end
        if not NOANIM then
            p.frame.Position = UDim2.fromOffset(12, p.top)
            play(p.frame, {Position = UDim2.fromOffset(0, p.top)}, 0.32)
        end
    end
    go = function(key)
        if key == cur or not pages[key] then return end
        local old = pages[cur]
        if old then
            old.frame.Visible = false
            old.chips.Visible = false
            if old.hidden then paintSettingsBtn(false) else paintItem(old, false) end
        end
        cur = key
        local p = pages[key]
        if p.hidden then paintSettingsBtn(true) else paintItem(p, true) lastPage = key end
        titleL.Text = p.title or p.name
        subL.Text = p.subtitle or ""
        showPage(p)
        updateStar()
    end

    themeFns[#themeFns + 1] = function()
        for _, p in pairs(pages) do
            if not p.hidden then
                p.item.BackgroundColor3 = T.accent
                p.label.TextColor3 = p.on and T.text or T.faint
                p.icon.tint(p.on and T.accentL or T.faint, 0)
            end
            for i, s in ipairs(p.subs) do
                s.chip.BackgroundColor3 = (p.curSub == i) and T.chipOn or T.chip
            end
        end
        if cur == SETTINGS then paintSettingsBtn(true) end
        updateStar()
    end

    setBtn.MouseEnter:Connect(function() if cur ~= SETTINGS then play(setBtn, {BackgroundColor3 = T.hover}, 0.15) end end)
    setBtn.MouseLeave:Connect(function() if cur ~= SETTINGS then play(setBtn, {BackgroundColor3 = T.chip}, 0.15) end end)
    setBtn.MouseButton1Click:Connect(function()
        if ctxWin.d then ctxWin.d.close() end
        if cur == SETTINGS then
            if lastPage then go(lastPage) end
        else
            go(SETTINGS)
        end
    end)

    -- pencarian tab / grup di sidebar
    sInput:GetPropertyChangedSignal("Text"):Connect(function()
        local q = sInput.Text:lower()
        searching = q ~= ""
        for _, g in ipairs(glist) do
            local gm = (q == "") or (g.name:lower():find(q, 1, true) ~= nil)
            local any = false
            for _, p in ipairs(g.pages) do
                local vis = gm or (p.name:lower():find(q, 1, true) ~= nil)
                p.item.Visible = vis
                if vis then any = true end
            end
            g.vis = any or gm
            relayoutGroup(g, true)
        end
    end)

    -- bintang = tandai halaman favorit (bintang kecil muncul di sidebar, tersimpan di config)
    starB.MouseButton1Click:Connect(function()
        local p = pages[cur]
        if not p or p.hidden then return end
        favs[p.key] = (not favs[p.key]) and true or nil
        p.star.Visible = favs[p.key] == true
        updateStar()
        persist()
    end)

    -- lonceng = riwayat notifikasi (badge merah = jumlah yang belum dibaca)
    local bellShade = new("TextButton", {Name = "NotifShade", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 59}, win)
    local bellPop = new("Frame", {Name = "NotifPanel", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 42), Size = UDim2.fromOffset(236, 176), BackgroundColor3 = T.el, BorderSizePixel = 0, Visible = false, ZIndex = 60}, win)
    corner(bellPop, 9)
    stroke(bellPop, T.outline, 1, 0.05)
    text(bellPop, {Text = "Notifications", Position = UDim2.fromOffset(12, 9), Size = UDim2.new(1, -80, 0, 16), W = 3, TextSize = 11})
    local clearN = new("TextButton", {Text = "Clear", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 9), Size = UDim2.fromOffset(44, 16), BackgroundTransparency = 1, FontFace = FONT[2], TextSize = 10, TextColor3 = T.mid, AutoButtonColor = false}, bellPop)
    local nList = new("ScrollingFrame", {Position = UDim2.fromOffset(6, 32), Size = UDim2.new(1, -12, 1, -38), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, bellPop)
    skin(nList, "ScrollBarImageColor3", "accent")
    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, nList)
    local nEmpty = text(bellPop, {Text = "No notifications", Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = XC, TextSize = 10, W = 1, TextColor3 = T.faint})
    local function ago(t)
        local d = math.max(0, os.time() - t)
        if d < 60 then return "now" elseif d < 3600 then return math.floor(d / 60) .. "m" end
        return math.floor(d / 3600) .. "h"
    end
    local function rebuildNotifs()
        for _, c in ipairs(nList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        nEmpty.Visible = #notifs == 0
        for i = #notifs, 1, -1 do
            local n = notifs[i]
            local r = new("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.field, BorderSizePixel = 0, LayoutOrder = #notifs - i}, nList)
            corner(r, 6)
            local d = new("Frame", {Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = n.c, BorderSizePixel = 0}, r)
            corner(d, "full")
            text(r, {Text = n.t, Position = UDim2.fromOffset(22, 4), Size = UDim2.new(1, -66, 0, 15), W = 3, TextSize = 10})
            text(r, {Text = n.m, Position = UDim2.fromOffset(22, 19), Size = UDim2.new(1, -30, 0, 14), W = 1, TextSize = 9, TextColor3 = T.faint})
            text(r, {Text = ago(n.at), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 5), Size = UDim2.fromOffset(34, 12), TextXAlignment = XR, W = 1, TextSize = 9, TextColor3 = T.faint})
        end
    end
    local function updateBadge()
        badge.Visible = unread > 0
        badgeL.Text = (unread > 9) and "9+" or tostring(unread)
    end
    local function setBell(on)
        bellPop.Visible, bellShade.Visible = on, on
        if on then
            unread = 0
            updateBadge()
            rebuildNotifs()
        end
    end
    notifHook = function() updateBadge() if bellPop.Visible then rebuildNotifs() end end
    bellB.MouseButton1Click:Connect(function() setBell(not bellPop.Visible) end)
    bellShade.MouseButton1Click:Connect(function() setBell(false) end)
    clearN.MouseButton1Click:Connect(function() notifs = {} rebuildNotifs() end)

    ------------------------------------------------------------------
    -- KOMPONEN (baris datar di dalam kartu: judul abu-abu, deskripsi lebih gelap, kontrol di kanan)
    ------------------------------------------------------------------
    buildComponents = function(scroll, container, ctx, cols)
        container = container or scroll
        local K = {}
        local order = 0
        local function nextOrder() order = order + 1 return order end
        local glass = ctx and ctx.glass -- mode kaca (dipakai Panel): kartu dibuat lebih bening
        local colN = 0
        local function pickCol(want)
            if not cols then return nil end
            if want == 1 then return cols[1] end
            if want == 2 and cols[2] then return cols[2] end
            colN = colN + 1
            return (cols[2] and colN % 2 == 0) and cols[2] or cols[1]
        end
        local BODY = Color3.fromRGB(205, 205, 210)

        local function row(h)
            return new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder()}, K._cur or container)
        end
        local function overlay(f)
            return new("TextButton", {Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2}, f)
        end
        -- judul + deskripsi di sisi kiri baris (rpad = ruang kosong di kanan)
        local function rowText(f, title, desc, rpad)
            local t = text(f, {Text = tostring(title), Position = UDim2.fromOffset(0, desc and 1 or 0), Size = desc and UDim2.new(1, -rpad, 0, 14) or UDim2.new(1, -rpad, 1, 0), W = 2, TextSize = 11, TextColor3 = T.mid})
            local d = desc and text(f, {Text = tostring(desc), Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, -rpad, 0, 12), TextSize = 9, W = 1, TextColor3 = T.faint})
            return t, d
        end
        -- judul menyala putih saat kursor di atas baris (dilewati di layar sentuh)
        local function hoverRow(hit, tl)
            if UIS.TouchEnabled and not UIS.MouseEnabled then return end
            hit.MouseEnter:Connect(function() play(tl, {TextColor3 = T.text}, 0.15) end)
            hit.MouseLeave:Connect(function() play(tl, {TextColor3 = T.mid}, 0.15) end)
        end

        ----------------------------------------------------------------
        -- SECTION / DIVIDER / LABEL / PARAGRAPH / INFO
        ----------------------------------------------------------------
        function K:Section(t)
            if type(t) == "table" then t = t.Title or t.Name or t.Text end
            local f = row(18)
            text(f, {Text = tostring(t or ""), Size = UDim2.fromScale(1, 1), W = 3, TextSize = 11, TextTruncate = NOTRUNC})
        end

        function K:Divider()
            local f = row(7)
            new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 0.3, BorderSizePixel = 0}, f)
        end

        function K:Label(t)
            if type(t) == "table" then t = t.Text or t.Title or t.Name end
            local f = new("Frame", {Size = UDim2.new(1, 0, 0, 15), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder()}, K._cur or container)
            local l = text(f, {Text = tostring(t or ""), Size = UDim2.new(1, 0, 0, 15), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextTruncate = NOTRUNC, TextSize = 11, W = 2, TextColor3 = BODY})
            return {Set = function(_, s) l.Text = tostring(s) end, SetText = function(_, s) l.Text = tostring(s) end, Get = function() return l.Text end}
        end

        function K:Paragraph(o)
            o = o or {}
            local f = new("Frame", {Name = "ParagraphFrame", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder()}, K._cur or container)
            local tl = text(f, {Text = tostring(o.Title or o.Name or "Paragraph"), Size = UDim2.new(1, 0, 0, 15), W = 3, TextSize = 11})
            local dl = text(f, {Text = tostring(o.Desc or o.Content or ""), Position = UDim2.fromOffset(0, 17), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true, TextSize = 10, W = 1, TextColor3 = T.mid, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = NOTRUNC, RichText = true})
            new("UIPadding", {PaddingBottom = UDim.new(0, 2)}, f)
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
            local f = row(18)
            local tl = text(f, {Text = tostring(o.Title or o.Name or "Info"), Size = UDim2.new(0.45, 0, 1, 0), W = 2, TextColor3 = T.mid})
            local v = text(f, {Text = tostring(o.Value or "-"), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.55, 0, 1, 0), TextXAlignment = XR, TextSize = 10, W = 1, TextColor3 = T.faint})
            if clickable then
                local hit = overlay(f)
                hoverRow(hit, tl)
                hit.MouseButton1Click:Connect(function()
                    if o.Copy then copy(v.Text) notify("Copied", v.Text, T.accent, 1.4) end
                    safe(o.Callback, v.Text)
                end)
            end
            return {Set = function(_, t, col) v.Text, v.TextColor3 = tostring(t), col or T.faint end, Get = function() return v.Text end}
        end

        ----------------------------------------------------------------
        -- BUTTON: "filled" (judul + deskripsi, latar abu) atau "outline" (teks tengah, garis tipis)
        ----------------------------------------------------------------
        local function makeButton(f, o, style)
            local title, desc = o.Title or o.Name or "Button", o.Desc or o.SubText
            local outlined = (style == "outline")
            local base = outlined and T.el or T.field
            local b = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = base, BorderSizePixel = 0, ClipsDescendants = true}, f)
            corner(b, 6)
            local st = stroke(b, T.outline, 1, outlined and 0.1 or 0.6)
            local tl, dl
            if desc then
                tl = text(b, {Text = tostring(title), Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 14), W = 2, TextSize = 11, TextColor3 = T.mid})
                dl = text(b, {Text = tostring(desc), Position = UDim2.fromOffset(10, 18), Size = UDim2.new(1, -20, 0, 12), TextSize = 9, W = 1, TextColor3 = T.faint})
            else
                tl = text(b, {Text = tostring(title), Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 2, TextSize = 11, TextColor3 = BODY})
            end
            local hit = overlay(b)
            local hov = false
            local function rest()
                play(b, {BackgroundColor3 = hov and T.hover or base}, 0.2)
                play(st, {Color = hov and T.accent or T.outline, Transparency = outlined and (hov and 0.35 or 0.1) or (hov and 0.45 or 0.6)}, 0.2)
            end
            hit.MouseEnter:Connect(function() hov = true rest() end)
            hit.MouseLeave:Connect(function() hov = false rest() end)
            hit.MouseButton1Click:Connect(function()
                ripple(b, 160)
                play(b, {BackgroundColor3 = T.accent:Lerp(T.bg, 0.45)}, 0.08)
                task.delay(0.1, rest)
                safe(o.Callback)
            end)
            return {
                SetTitle = function(_, s) tl.Text = tostring(s) end,
                SetDesc = function(_, s) if dl then dl.Text = tostring(s) end end,
                Fire = function() safe(o.Callback) end,
            }
        end
        function K:Button(o)
            o = o or {}
            local desc = o.Desc or o.SubText
            return makeButton(row(desc and 32 or 24), o, o.Style or (desc and "filled" or "outline"))
        end
        -- beberapa tombol sebaris (rata lebar): K:Buttons({{Title = "Add", Callback = f}, {Title = "Clear", Callback = g}})
        function K:Buttons(list)
            list = list or {}
            local n, gap = math.max(#list, 1), 6
            local f = row(24)
            local objs = {}
            for i, o in ipairs(list) do
                local slot = new("Frame", {Position = UDim2.new((i - 1) / n, (i - 1) * gap / n, 0, 0), Size = UDim2.new(1 / n, -gap * (n - 1) / n, 1, 0), BackgroundTransparency = 1}, f)
                objs[i] = makeButton(slot, o, o.Style or "outline")
            end
            return objs
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
            local f = row(desc and 30 or 22)
            local tl = rowText(f, title, desc, 40)
            local sw = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(30, 16), BackgroundColor3 = v and T.accent or T.off, BorderSizePixel = 0}, f)
            corner(sw, "full")
            local function kpos(x) return UDim2.new(0, x and 16 or 2, 0.5, 0) end
            local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = kpos(v), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = v and WHITE or T.dim, BorderSizePixel = 0}, sw)
            corner(knob, "full")
            local hit = overlay(f)
            hoverRow(hit, tl)
            local obj = {Value = v}
            local function upd(nv, silent)
                v, obj.Value = nv, nv
                play(sw, {BackgroundColor3 = v and T.accent or T.off}, 0.25)
                play(knob, {Position = kpos(v), BackgroundColor3 = v and WHITE or T.dim}, 0.25)
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
        -- SLIDER: judul kiri + nilai berwarna aksen di kanan, track tipis dengan isi gradien ungu dan knob putih
        ----------------------------------------------------------------
        function K:Slider(o)
            o = o or {}
            local flag = o.Flag
            local mn, mx, step = o.Min or 0, o.Max or 100, o.Step or 1
            if mx < mn then mn, mx = mx, mn end
            if step <= 0 then step = 1 end
            local val = o.Default or o.Value or mn
            if flag and type(F[flag]) == "number" then val = F[flag] end
            local desc = o.Desc or o.SubText
            local f = row(desc and 38 or 28)
            local tl = text(f, {Text = tostring(o.Title or o.Name or flag or "Slider"), Position = UDim2.fromOffset(0, desc and 1 or 0), Size = UDim2.new(1, -56, 0, 14), W = 2, TextSize = 11, TextColor3 = T.mid})
            if desc then text(f, {Text = tostring(desc), Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, -56, 0, 12), TextSize = 9, W = 1, TextColor3 = T.faint}) end
            local vl = text(f, {Position = UDim2.fromOffset(0, desc and 1 or 0), Size = UDim2.new(1, 0, 0, 14), TextXAlignment = XR, W = 3, TextSize = 10, TextTruncate = NOTRUNC})
            skin(vl, "TextColor3", "accentL")
            local ty = desc and 30 or 20
            local sbar = new("Frame", {Position = UDim2.fromOffset(0, ty), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = T.off, BorderSizePixel = 0}, f)
            corner(sbar, "full")
            local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, sbar)
            corner(fill, "full")
            local fg = new("UIGradient", {}, fill)
            local function paintFill() fg.Color = ColorSequence.new(T.accent, T.accentH) end
            paintFill()
            themeFns[#themeFns + 1] = paintFill
            local knob = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, sbar)
            corner(knob, "full")
            skin(stroke(knob, T.accent, 2, 0.55), "Color", "accent")
            local hit = new("TextButton", {Position = UDim2.fromOffset(0, ty - 9), Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3}, f)
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
                    play(knob, {Size = UDim2.fromOffset(16, 16)}, 0.12)
                    play(tl, {TextColor3 = T.text}, 0.12)
                    fromX(pos.X)
                    return true
                end,
                function(dx, dy, st, moved, pos) fromX(pos.X) end,
                function()
                    scroll.ScrollingEnabled = true
                    play(knob, {Size = UDim2.fromOffset(12, 12)}, 0.12)
                    play(tl, {TextColor3 = T.mid}, 0.12)
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
        -- TEXTBOX: label abu di atas, kotak input gelap di bawah
        ----------------------------------------------------------------
        function K:Textbox(o)
            o = o or {}
            local title = o.Title or o.Name or o.Flag or "Textbox"
            local flag = o.Flag or title
            local desc = o.Desc or o.SubText
            local val = (o.Default ~= nil) and tostring(o.Default) or ""
            if type(F[flag]) == "string" then val = F[flag] end
            local f = row(desc and 58 or 46)
            text(f, {Text = tostring(title), Size = UDim2.new(1, 0, 0, 14), W = 2, TextSize = 11, TextColor3 = T.mid})
            local fy = 20
            if desc then
                text(f, {Text = tostring(desc), Position = UDim2.fromOffset(0, 15), Size = UDim2.new(1, 0, 0, 12), TextSize = 9, W = 1, TextColor3 = T.faint})
                fy = 33
            end
            local _, box = inputBox(f, {text = val, placeholder = o.Placeholder or "Type here...", clear = o.ClearOnFocus,
                wrap = {Position = UDim2.fromOffset(0, fy), Size = UDim2.new(1, 0, 0, 24)}})
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
        -- DROPDOWN: judul tebal di atas, kotak nilai di bawah. Klik membuka drawer di sisi kanan window (Single / Multi)
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

            local f = row(desc and 60 or 48)
            text(f, {Text = tostring(title), Size = UDim2.new(1, 0, 0, 14), W = 3, TextSize = 11})
            local fy = 22
            if desc then
                text(f, {Text = tostring(desc), Position = UDim2.fromOffset(0, 15), Size = UDim2.new(1, 0, 0, 12), TextSize = 9, W = 1, TextColor3 = T.faint})
                fy = 35
            end
            local fld = new("Frame", {Position = UDim2.fromOffset(0, fy), Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.field, BorderSizePixel = 0}, f)
            corner(fld, 6)
            local fst = stroke(fld, T.outline, 1, 0.45)
            local vl = text(fld, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0), TextSize = 10, W = 2, TextColor3 = T.mid})
            local dIc = mkIcon(fld, "crosshair", 12, T.faint, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0)})
            local hit = overlay(fld)
            if not (UIS.TouchEnabled and not UIS.MouseEnabled) then
                hit.MouseEnter:Connect(function() play(fld, {BackgroundColor3 = T.hover}, 0.15) play(fst, {Color = T.accent, Transparency = 0.4}, 0.15) dIc.tint(T.accentL) end)
                hit.MouseLeave:Connect(function() play(fld, {BackgroundColor3 = T.field}, 0.15) play(fst, {Color = T.outline, Transparency = 0.45}, 0.15) dIc.tint(T.faint) end)
            end
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
            local f = row(desc and 30 or 24)
            local tl = rowText(f, title, desc, 90)
            local cap = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.field,
                BorderSizePixel = 0, FontFace = FONT[2], TextSize = 10, TextColor3 = T.mid, Text = "", AutoButtonColor = false}, f)
            corner(cap, 6)
            new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, cap)
            local capSt = stroke(cap, T.outline, 1, 0.45)
            local listening, lastCancel = false, 0
            local function show()
                cap.Text = listening and "..." or (key and key.Name or "None")
                play(cap, {TextColor3 = listening and T.accentL or T.mid}, 0.2)
                play(capSt, {Color = listening and T.accent or T.outline, Transparency = listening and 0.2 or 0.45}, 0.2)
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
        -- COLOR PICKER (baris mengembang: kotak SV + hue horizontal + input hex)
        ----------------------------------------------------------------
        function K:ColorPicker(o)
            o = o or {}
            local title = o.Title or o.Name or o.Flag or "Color"
            local flag = o.Flag or title
            local col = (typeof(o.Default) == "Color3") and o.Default or T.accent
            local sv = F[flag]
            if type(sv) == "table" and #sv == 3 then col = Color3.fromRGB(sv[1], sv[2], sv[3]) end
            local hh, ss, vv = col:ToHSV()
            local OPEN_H, open = 214, false
            local f = row(24)
            f.ClipsDescendants = true
            local tl = text(f, {Text = tostring(title), Size = UDim2.new(1, -40, 0, 24), W = 2, TextSize = 11, TextColor3 = T.mid})
            local sw = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 5), Size = UDim2.fromOffset(28, 14), BackgroundColor3 = col, BorderSizePixel = 0}, f)
            corner(sw, 4)
            stroke(sw, WHITE, 1, 0.8)
            local head = new("TextButton", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2}, f)
            hoverRow(head, tl)

            local pop = new("Frame", {Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 182), BackgroundTransparency = 1}, f)
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

            local hue = new("Frame", {Position = UDim2.fromOffset(0, 128), Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = WHITE, BorderSizePixel = 0}, pop)
            corner(hue, 4)
            local ks = {}
            for i = 0, 6 do ks[#ks + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)) end
            new("UIGradient", {Color = ColorSequence.new(ks)}, hue)
            local hp = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 6, 1, 6), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, hue)
            corner(hp, 2)
            stroke(hp, Color3.new(0, 0, 0), 1, 0)
            local hHit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4}, hue)
            local _, hexBox = inputBox(pop, {placeholder = "#RRGGBB", wrap = {Position = UDim2.fromOffset(0, 154), Size = UDim2.new(1, 0, 0, 24)}})

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
                play(f, {Size = UDim2.new(1, 0, 0, open and OPEN_H or 24)}, 0.3)
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
        -- ACCORDION = KARTU: header (ikon + judul + panah), klik = buka / tutup, tinggi mengikuti isi.
        -- Di halaman, kartu masuk bergantian ke kolom kiri / kanan (Column = 1 / 2 untuk memilih). Terbuka secara bawaan.
        ----------------------------------------------------------------
        function K:Accordion(o)
            o = o or {}
            local HEAD = 30
            local open, animating, tok = false, false, 0
            local nested = (cols == nil)
            local parent = K._cur or pickCol(o.Column) or container
            local box = new("Frame", {Name = "Card", Size = UDim2.new(1, 0, 0, HEAD), BackgroundColor3 = nested and T.field or T.el, BackgroundTransparency = glass and 0.45 or 0,
                BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = nextOrder()}, parent)
            corner(box, nested and 7 or 10)
            stroke(box, T.outline, 1, nested and 0.6 or 0.4)
            local hd2 = new("TextButton", {Name = "CardHeader", Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", BorderSizePixel = 0, ZIndex = 2}, box)
            local tx = 12
            if o.Icon then
                local cic = mkIcon(hd2, o.Icon, 13, T.accentL, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0)})
                themeFns[#themeFns + 1] = function() cic.tint(T.accentL, 0) end
                tx = 32
            end
            text(hd2, {Text = tostring(o.Title or o.Name or "Card"), Position = UDim2.fromOffset(tx, 0), Size = UDim2.new(1, -(tx + 30), 1, 0), W = 3, TextSize = 12})
            local chev = new("ImageLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0), Size = UDim2.fromOffset(15, 15), BackgroundTransparency = 1, Image = "rbxassetid://6031091004", ImageColor3 = T.dim, Rotation = -90, ZIndex = 3}, hd2)

            local hdl = new("Frame", {Name = "HeaderLine", Position = UDim2.fromOffset(10, HEAD - 1), Size = UDim2.new(1, -20, 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, box)
            local wrap = new("Frame", {Position = UDim2.fromOffset(0, HEAD), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Visible = false}, box)
            local cont = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0}, wrap)
            new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, cont)
            local lay = new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, cont)

            local sub = buildComponents(scroll, cont, ctx, nil)
            sub._content = cont

            local function contentH()
                local ah = lay.AbsoluteContentSize.Y
                if ah <= 0 then return 0 end
                local fac = hd2.AbsoluteSize.Y / HEAD
                if fac < 0.01 then fac = math.max(rootScale.Scale, 0.01) end
                return math.floor(ah / fac + 0.5) + 12
            end
            local function setH(h)
                wrap.Size = UDim2.new(1, 0, 0, h)
                box.Size = UDim2.new(1, 0, 0, HEAD + h)
            end
            local function setOpen(v, instant)
                if v == open then return end
                open = v
                tok = tok + 1
                local my = tok
                play(hdl, {BackgroundTransparency = v and 0.5 or 1}, 0.25)
                play(chev, {Rotation = v and 0 or -90}, 0.25)
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
                    play(wrap, {Size = UDim2.new(1, 0, 0, h)}, 0.3)
                    play(box, {Size = UDim2.new(1, 0, 0, HEAD + h)}, 0.3)
                    task.wait(0.33)
                    if tok ~= my then return end
                    animating = false
                    if open then setH(contentH()) else wrap.Visible = false end
                end)
            end
            -- isi berubah saat terbuka (komponen baru, dropdown, kartu di dalam kartu): tinggi ikut
            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if open and not animating then
                    local h = contentH()
                    if math.abs(wrap.Size.Y.Offset - h) > 1 then setH(h) end
                end
            end)
            hd2.MouseEnter:Connect(function() play(chev, {ImageColor3 = T.text}, 0.15) end)
            hd2.MouseLeave:Connect(function() play(chev, {ImageColor3 = T.dim}, 0.15) end)
            hd2.MouseButton1Click:Connect(function() setOpen(not open) end)

            function sub:Expand() setOpen(true) end
            function sub:Collapse() setOpen(false) end
            function sub:SetOpen(v) setOpen(v and true or false) end
            function sub:IsOpen() return open end
            if o.Open ~= false then setOpen(true, true) end
            return sub
        end
        K.Group, K.Card = K.Accordion, K.Accordion

        function K:Panel(o) return Window:Panel(o) end

        -- alias gaya lama: CreateSection = kartu; komponen sesudahnya masuk ke dalamnya
        function K:CreateSection(o)
            if type(o) ~= "table" then o = {Name = tostring(o)} end
            K._cur = nil
            local A = K:Accordion({Title = o.Name or o.Title, Icon = o.Icon, Open = o.Open, Column = o.Column})
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

    -- Window:Group({Title, Icon}) -> grup di sidebar (header + panah). G:Tab({Title, Icon, Subtitle}) -> halaman di bawah grup.
    -- Hasil Tab = pembuat komponen; K:SubTab({Title, Icon}) menambah chip di atas konten dan mengembalikan pembuat komponennya.
    local buildDashboard
    do
        local LP = Players.LocalPlayer
        local SF = CFG .. "/dashboard.json"
        local stats = {exec = 0, secs = 0}
        pcall(function()
            if isfile and isfile(SF) then
                local d = Http:JSONDecode(readfile(SF))
                if type(d) == "table" then stats.exec, stats.secs = tonumber(d.exec) or 0, tonumber(d.secs) or 0 end
            end
        end)
        stats.exec = stats.exec + 1
        local function saveStats() pcall(function() if writefile then writefile(SF, Http:JSONEncode(stats)) end end) end
        saveStats()

        local LV = {"Newbie", "Rookie", "Regular", "Veteran", "Elite", "Master", "Legend"}
        local function lvStart(n) return 50 * n * (n - 1) end -- Lv2 mulai 100 XP, Lv3 300 XP, Lv4 600 XP ...
        local function lvInfo()
            local xp = stats.exec * 10 + math.floor(stats.secs / 60)
            local n = 1
            while lvStart(n + 1) <= xp do n = n + 1 end
            return xp, n
        end
        local function fmtT(s)
            s = math.floor(tonumber(s) or 0)
            if s >= 3600 then return math.floor(s / 3600) .. "h " .. math.floor(s % 3600 / 60) .. "m" end
            if s >= 60 then return math.floor(s / 60) .. "m " .. (s % 60) .. "s" end
            return s .. "s"
        end

        buildDashboard = function(p)
            local root, N = p.dL, 40
            local ord = -100 -- negatif: isi Dashboard selalu di atas komponen lain yang ditambahkan user
            local function nextO() ord = ord + 1 return ord end
            local function rowF(h) return new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextO()}, root) end
            local function card(parent, size, pos)
                local f = new("Frame", {Size = size, Position = pos or UDim2.new(), BackgroundColor3 = T.el, BorderSizePixel = 0}, parent)
                corner(f, 10)
                stroke(f, T.outline, 1, 0.4)
                return f
            end
            local function lb(parent, txt, x, y, w, h, o) -- label kecil; w boleh UDim2
                o = o or {}
                o.Text, o.Position = txt, UDim2.fromOffset(x, y)
                o.Size = (typeof(w) == "UDim2") and w or UDim2.fromOffset(w, h)
                return text(parent, o)
            end
            local function chip(parent, glyph, x, y) -- kotak ikon ungu tipis
                local b = new("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 0.82, BorderSizePixel = 0}, parent)
                skin(b, "BackgroundColor3", "accent")
                corner(b, 6)
                local ic = mkIcon(b, glyph, 11, T.accentL, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
                themeFns[#themeFns + 1] = function() ic.tint(T.accentL, 0) end
                return b
            end
            local function pill(parent, txt, col, x, y, themed) -- badge kecil, mengembalikan x berikutnya
                local w = textW(txt, 9) + 18
                local f = new("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 18), BackgroundColor3 = col, BackgroundTransparency = 0.8, BorderSizePixel = 0}, parent)
                corner(f, 5)
                local l = text(f, {Text = txt, Size = UDim2.fromScale(1, 1), TextXAlignment = XC, TextColor3 = col, W = 4, TextSize = 9, TextTruncate = NOTRUNC})
                if themed then skin(f, "BackgroundColor3", "accent") skin(l, "TextColor3", "accentL") end
                return x + w + 6
            end

            ---------------- BARIS 1: profil + level ----------------
            local r1 = rowF(88)
            local pc = card(r1, UDim2.new(0.6, -5, 1, 0))
            local av = new("ImageLabel", {Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = T.field, BorderSizePixel = 0,
                Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(LP.UserId)}, pc)
            corner(av, "full")
            skin(stroke(av, T.accent, 2, 0.2), "Color", "accent")
            lb(pc, "WELCOME BACK", 66, 8, 120, 10, {W = 2, TextSize = 8, TextColor3 = T.faint})
            lb(pc, LP.DisplayName, 66, 19, 110, 18, {W = 3, TextSize = 14})
            lb(pc, "👑 🔮", 66 + math.min(textW(LP.DisplayName, 14), 108) + 6, 19, 40, 18, {TextSize = 11, TextTruncate = NOTRUNC})
            lb(pc, "@" .. LP.Name, 66, 38, 150, 12, {W = 1, TextSize = 9, TextColor3 = T.faint})
            local bx = pill(pc, tostring(C.Role or "OWNER"):upper(), T.warn, 12, 64)
            bx = pill(pc, tostring(C.Version or "V1.0"), T.accent, bx, 64, true)
            pill(pc, tostring(C.Plan or "Lifetime"), Color3.fromRGB(110, 118, 255), bx, 64)

            local lc = card(r1, UDim2.new(0.4, -5, 1, 0), UDim2.new(0.6, 5, 0, 0))
            lb(lc, "≋", 10, 12, 30, 30, {TextSize = 24, TextColor3 = T.warn, TextXAlignment = XC, W = 3, TextTruncate = NOTRUNC})
            local lvTop = lb(lc, "", 46, 10, 110, 10, {W = 2, TextSize = 8, TextColor3 = T.faint})
            local lvName = lb(lc, "", 46, 20, 110, 18, {W = 3, TextSize = 14})
            local lvNext = lb(lc, "", 46, 39, 110, 12, {W = 1, TextSize = 9, TextColor3 = T.faint})
            local track = new("Frame", {Position = UDim2.fromOffset(12, 62), Size = UDim2.new(1, -24, 0, 5), BackgroundColor3 = T.field, BorderSizePixel = 0}, lc)
            corner(track, "full")
            local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, track)
            corner(fill, "full")
            local fillG = new("UIGradient", {}, fill)
            local lvL = lb(lc, "", 12, 71, 80, 11, {W = 1, TextSize = 8, TextColor3 = T.faint})
            local lvR = lb(lc, "", 0, 71, UDim2.new(1, -12, 0, 11), nil, {W = 1, TextSize = 8, TextColor3 = T.faint, TextXAlignment = XR})
            local function updLevel()
                local xp, lv = lvInfo()
                local lo, hi = lvStart(lv), lvStart(lv + 1)
                lvTop.Text = "LEVEL " .. lv
                lvName.Text = LV[math.min(lv, #LV)]
                lvNext.Text = "Next: " .. LV[math.min(lv + 1, #LV)]
                lvL.Text = xp .. " XP"
                lvR.Text = hi .. " XP · Lv " .. (lv + 1)
                fill.Size = UDim2.fromScale(math.clamp((xp - lo) / (hi - lo), 0.03, 1), 1)
            end

            ---------------- BARIS 2: executions + time spent ----------------
            local r2 = rowF(70)
            local ec = card(r2, UDim2.new(0.34, -5, 1, 0))
            chip(ec, "play", 12, 10)
            lb(ec, "Executions", 40, 10, UDim2.new(1, -44, 0, 22), nil, {W = 2, TextSize = 11})
            local exN = lb(ec, "0", 14, 36, UDim2.new(1, -20, 0, 28), nil, {W = 4, TextSize = 22, TextTruncate = NOTRUNC})
            local tc = card(r2, UDim2.new(0.66, -5, 1, 0), UDim2.new(0.34, 5, 0, 0))
            chip(tc, "gauge", 12, 10)
            lb(tc, "Time spent", 40, 10, 90, 22, {W = 2, TextSize = 11})
            lb(tc, "Total usage", 14, 40, 90, 12, {W = 1, TextSize = 9, TextColor3 = T.faint})
            local cnt = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.55, 0, 0, 46), BackgroundColor3 = T.bg, BorderSizePixel = 0}, tc)
            corner(cnt, 8)
            local cells = {}
            for i, nmv in ipairs({"DAY", "HOUR", "MIN", "SEC"}) do
                local cf = new("Frame", {Position = UDim2.fromScale((i - 1) / 4, 0), Size = UDim2.fromScale(0.25, 1), BackgroundTransparency = 1, BorderSizePixel = 0}, cnt)
                local num = text(cf, {Text = "00", Position = UDim2.fromOffset(0, 7), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = XC, W = 4, TextSize = 15, TextTruncate = NOTRUNC})
                local tag = text(cf, {Text = nmv, Position = UDim2.fromOffset(0, 29), Size = UDim2.new(1, 0, 0, 10), TextXAlignment = XC, W = 2, TextSize = 7, TextColor3 = T.faint, TextTruncate = NOTRUNC})
                if i > 1 then new("Frame", {Position = UDim2.fromOffset(0, 8), Size = UDim2.new(0, 1, 1, -16), BackgroundColor3 = T.outline, BorderSizePixel = 0}, cf) end
                if i == 4 then
                    skin(num, "TextColor3", "accentL")
                    skin(tag, "TextColor3", "accentL")
                    skin(new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(14, 2), BorderSizePixel = 0}, cf), "BackgroundColor3", "accent")
                end
                cells[i] = num
            end
            local function updTime()
                local s = stats.secs
                local v = {math.floor(s / 86400), math.floor(s % 86400 / 3600), math.floor(s % 3600 / 60), math.floor(s % 60)}
                for i = 1, 4 do cells[i].Text = ("%02d"):format(v[i]) end
            end

            ---------------- BARIS 3: performance ----------------
            local r3 = rowF(134)
            local pf = card(r3, UDim2.new(1, 0, 1, 0))
            chip(pf, "activity", 12, 10)
            lb(pf, "Performance", 40, 10, 120, 22, {W = 2, TextSize = 11})
            lb(pf, "Current FPS", 14, 40, 100, 11, {W = 1, TextSize = 9, TextColor3 = T.faint})
            local fpsL = lb(pf, "-- fps", 14, 52, UDim2.new(0.38, -14, 0, 28), nil, {W = 4, TextSize = 21, TextTruncate = NOTRUNC})
            local function stat(y, tag)
                local f = new("Frame", {Position = UDim2.fromOffset(12, y), Size = UDim2.new(0.36, -12, 0, 21), BackgroundColor3 = T.field, BorderSizePixel = 0}, pf)
                corner(f, 6)
                local v = text(f, {Text = "--", Position = UDim2.fromOffset(26, 0), Size = UDim2.new(0.6, -26, 1, 0), W = 3, TextSize = 9, TextTruncate = NOTRUNC})
                new("Frame", {Position = UDim2.new(0.6, 0, 0, 4), Size = UDim2.new(0, 1, 1, -8), BackgroundColor3 = T.outline, BorderSizePixel = 0}, f)
                local t = text(f, {Text = tag, Position = UDim2.fromScale(0.6, 0), Size = UDim2.fromScale(0.4, 1), TextXAlignment = XC, W = 3, TextSize = 8, TextTruncate = NOTRUNC})
                return f, v, t
            end
            local pingF, pingV, pingT = stat(86, "LIVE")
            local memF, memV, memT = stat(110, "MEM")
            skin(memT, "TextColor3", "accentL")
            local bars = {}
            for i = 1, 3 do -- ikon sinyal (3 batang)
                bars[i] = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(8 + (i - 1) * 4, 15), Size = UDim2.fromOffset(2, 3 + i * 2), BackgroundColor3 = T.ok, BorderSizePixel = 0}, pingF)
            end
            local mic = mkIcon(memF, "save", 11, T.accentL, {Position = UDim2.fromOffset(7, 5)})
            themeFns[#themeFns + 1] = function() mic.tint(T.accentL, 0) end

            local plot = new("Frame", {Position = UDim2.new(0.4, 0, 0, 14), Size = UDim2.new(0.6, -12, 0, 100), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true}, pf)
            local ax = new("Frame", {Position = UDim2.new(0.4, 0, 0, 118), Size = UDim2.new(0.6, -12, 0, 11), BackgroundTransparency = 1, BorderSizePixel = 0}, pf)
            for i, s in ipairs({"20s", "15s", "10s", "5s", "Now"}) do
                local l = text(ax, {Text = s, AnchorPoint = Vector2.new((i == 1) and 0 or ((i == 5) and 1 or 0.5), 0), Position = UDim2.fromScale((i - 1) / 4, 0), Size = UDim2.fromOffset(30, 11),
                    TextXAlignment = (i == 1) and XL or ((i == 5) and XR or XC), W = (i == 5) and 3 or 1, TextSize = 8, TextColor3 = T.faint, TextTruncate = NOTRUNC})
                if i == 5 then skin(l, "TextColor3", "accentL") end
            end
            local fpsS, pingS, fills, segs, psegs = {}, {}, {}, {}, {}
            for i = 1, N do fpsS[i], pingS[i] = 60, 40 end
            local fadeSeq = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)})
            for i = 1, N do -- isi area di bawah garis FPS (gradien memudar ke bawah)
                local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), BorderSizePixel = 0}, plot)
                skin(f, "BackgroundColor3", "accent")
                new("UIGradient", {Rotation = 90, Transparency = fadeSeq}, f)
                fills[i] = f
            end
            for i = 1, N do psegs[i] = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.dim, BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false}, plot) end
            for i = 1, N do segs[i] = skin(new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}, plot), "BackgroundColor3", "accentL") end
            local function seg(f, x1, y1, x2, y2) -- garis dari dua titik (frame dirotasi)
                local dx, dy = x2 - x1, y2 - y1
                f.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, 2)
                f.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
                f.Rotation = math.deg(math.atan2(dy, dx))
                f.Visible = true
            end
            local function norm(a, span) -- skala otomatis, 0 = atas, 1 = bawah
                local lo, hi = math.huge, -math.huge
                for _, v in ipairs(a) do lo, hi = math.min(lo, v), math.max(hi, v) end
                local sp, mid = math.max(hi - lo, span), (hi + lo) / 2
                return function(v) return 0.5 - (v - mid) / sp * 0.78 end
            end
            local function redraw()
                local s = math.max(rootScale.Scale, 0.01)
                local aw, ah = plot.AbsoluteSize.X / s, plot.AbsoluteSize.Y / s
                if aw < 20 then return end
                local step = aw / (N - 1)
                local fy, py = norm(fpsS, 30), norm(pingS, 40)
                local ox, oy, opy
                for i = 1, N do
                    local x, y, yp = (i - 1) * step, fy(fpsS[i]) * ah, py(pingS[i]) * ah
                    fills[i].Position = UDim2.fromOffset(x, y)
                    fills[i].Size = UDim2.fromOffset(step + 1, math.max(ah - y, 1))
                    if i > 1 then seg(segs[i], ox, oy, x, y) seg(psegs[i], ox, opy, x, yp) end
                    ox, oy, opy = x, y, yp
                end
            end
            -- hover grafik: garis vertikal + titik + tooltip "64 fps · 91 ms"
            local cursorL = new("Frame", {Size = UDim2.new(0, 1, 1, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false}, plot)
            skin(cursorL, "BackgroundColor3", "accentL")
            local dot = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false}, plot)
            corner(dot, "full")
            local tip = text(plot, {Text = "", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), BackgroundTransparency = 0.1, BackgroundColor3 = T.bg, W = 2, TextSize = 9, TextTruncate = NOTRUNC, Visible = false, ZIndex = 3})
            corner(tip, 5)
            new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, tip)
            plot.InputChanged:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local s = math.max(rootScale.Scale, 0.01)
                local aw, ah = plot.AbsoluteSize.X / s, plot.AbsoluteSize.Y / s
                if aw < 20 then return end
                local step = aw / (N - 1)
                local idx = math.clamp(math.floor((i.Position.X - plot.AbsolutePosition.X) / s / step + 0.5) + 1, 1, N)
                local x, y = (idx - 1) * step, norm(fpsS, 30)(fpsS[idx]) * ah
                cursorL.Position, cursorL.Visible = UDim2.fromOffset(x, 0), true
                dot.Position, dot.Visible = UDim2.fromOffset(x, y), true
                tip.Text = ("%d fps · %d ms"):format(fpsS[idx], pingS[idx])
                tip.Position = UDim2.fromOffset(math.clamp(x - 40, 2, math.max(aw - 96, 2)), 2)
                tip.Visible = true
            end)
            plot.MouseLeave:Connect(function() cursorL.Visible, dot.Visible, tip.Visible = false, false, false end)

            local Stats = game:GetService("Stats")
            local function getPing()
                local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
                if ok and tonumber(v) then return v end
                ok, v = pcall(function() return LP:GetNetworkPing() * 1000 end)
                return (ok and tonumber(v)) or 0
            end
            local acc, frames, primed = 0, 0, false
            bind(RunService.Heartbeat, function(dt)
                acc, frames = acc + dt, frames + 1
                if acc < 0.5 then return end
                local fps, ping = math.floor(frames / acc + 0.5), math.floor(getPing() + 0.5)
                acc, frames = 0, 0
                if not primed then
                    primed = true
                    for i = 1, N do fpsS[i], pingS[i] = fps, ping end
                else
                    table.remove(fpsS, 1)
                    table.remove(pingS, 1)
                    fpsS[N], pingS[N] = fps, ping
                end
                fpsL.Text = fps .. " fps"
                pingV.Text = ping .. " ms"
                local q = (ping < 120) and T.ok or ((ping < 250) and T.warn or T.bad)
                pingT.TextColor3 = q
                for _, b in ipairs(bars) do b.BackgroundColor3 = q end
                local ok, mem = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
                memV.Text = (ok and math.floor(mem + 0.5) or 0) .. " MB"
                if p.frame.Visible then pcall(redraw) end
            end)

            ---------------- BARIS 4: now playing + info ----------------
            local r4 = rowF(100)
            local np = card(r4, UDim2.new(0.5, -5, 1, 0))
            local gi = new("ImageLabel", {Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = T.field, BorderSizePixel = 0,
                Image = ("rbxthumb://type=GameIcon&id=%d&w=150&h=150"):format(game.GameId)}, np)
            corner(gi, 8)
            lb(np, "NOW PLAYING", 60, 11, 100, 10, {W = 2, TextSize = 8, TextColor3 = T.faint})
            local gname = lb(np, game.Name, 60, 23, UDim2.new(1, -108, 0, 16), nil, {W = 3, TextSize = 12})
            local live = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(60 + textW(game.Name, 12) + 6, 31), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = T.ok, BorderSizePixel = 0}, np)
            corner(live, "full")
            local ob = new("TextButton", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = T.field, AutoButtonColor = false, Text = "", BorderSizePixel = 0}, np)
            corner(ob, "full")
            local oi = mkIcon(ob, "play", 8, T.mid, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Rotation = -45})
            ob.MouseEnter:Connect(function() play(ob, {BackgroundColor3 = T.hover}, 0.15) oi.tint(T.text, 0.15) end)
            ob.MouseLeave:Connect(function() play(ob, {BackgroundColor3 = T.field}, 0.15) oi.tint(T.mid, 0.15) end)
            ob.MouseButton1Click:Connect(function()
                copy("https://www.roblox.com/games/" .. game.PlaceId)
                Window.Notify("Copied", "Game link copied", T.accent, 2)
            end)
            new("Frame", {Position = UDim2.fromOffset(12, 62), Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 0.4, BorderSizePixel = 0}, np)
            chip(np, "user", 12, 70)
            lb(np, "Players online", 40, 70, 100, 22, {W = 1, TextSize = 10, TextColor3 = T.faint})
            local plN = lb(np, "0", 0, 70, UDim2.new(1, -14, 0, 22), nil, {W = 3, TextSize = 11, TextXAlignment = XR})
            local infoV = {}
            for i, d in ipairs({{">_", "Executor"}, {"target", "Region"}, {"gauge", "Time"}}) do
                local c = card(r4, UDim2.new(0.5, -5, 0, 30), UDim2.new(0.5, 5, 0, (i - 1) * 35))
                chip(c, d[1], 8, 4)
                lb(c, d[2], 36, 0, 80, 30, {W = 1, TextSize = 10, TextColor3 = T.faint})
                infoV[i] = lb(c, "--", 0, 0, UDim2.new(1, -12, 1, 0), nil, {W = 3, TextSize = 11, TextXAlignment = XR})
            end
            local exName = "Unknown"
            pcall(function() exName = tostring((identifyexecutor or getexecutorname)()) end)
            infoV[1].Text = exName
            task.spawn(function()
                local ok, rg = pcall(function() return game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LP) end)
                infoV[2].Text = ok and tostring(rg) or "--"
            end)
            task.spawn(function()
                local ok, inf = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
                if ok and type(inf) == "table" and inf.Name then
                    gname.Text = inf.Name
                    live.Position = UDim2.fromOffset(60 + math.min(textW(inf.Name, 12), gname.AbsoluteSize.X / math.max(rootScale.Scale, 0.01)) + 6, 31)
                end
            end)

            ---------------- BARIS 5: community (leaderboard / changelogs) ----------------
            local cm = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.el, BorderSizePixel = 0, LayoutOrder = nextO()}, root)
            corner(cm, 10)
            stroke(cm, T.outline, 1, 0.4)
            new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, cm)
            new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, cm)
            local hd = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1}, cm)
            chip(hd, "user", 0, 2)
            lb(hd, "Community", 30, 0, 100, 26, {W = 3, TextSize = 12})
            local tg = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(170, 24), BackgroundColor3 = T.field, BorderSizePixel = 0}, hd)
            corner(tg, 8)
            local function listF(o, vis) -- wadah daftar yang tingginya mengikuti isi
                local f = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = o, Visible = vis}, cm)
                new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
                return f
            end
            local views, tabs = {lb = listF(2, true), log = listF(3, false)}, {}
            local showView
            local function mkTab(k, txt, x)
                local b = new("TextButton", {Position = UDim2.fromOffset(x, 2), Size = UDim2.fromOffset(82, 20), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", BorderSizePixel = 0}, tg)
                skin(b, "BackgroundColor3", "accent")
                corner(b, 6)
                local st = skin(stroke(b, T.accent, 1, 1), "Color", "accent")
                local l = text(b, {Text = txt, Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 10, TextColor3 = T.mid, TextTruncate = NOTRUNC})
                tabs[k] = {b, l, st}
                b.MouseButton1Click:Connect(function() showView(k) end)
            end
            mkTab("lb", "Leaderboard", 2)
            mkTab("log", "Changelogs", 86)
            showView = function(k)
                for key, t in pairs(tabs) do
                    local on = key == k
                    play(t[1], {BackgroundTransparency = on and 0.78 or 1}, 0.15)
                    play(t[2], {TextColor3 = on and T.text or T.mid}, 0.15)
                    play(t[3], {Transparency = on and 0.45 or 1}, 0.15)
                    views[key].Visible = on
                end
            end

            -- toolbar: search + pager
            local bar = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1}, views.lb)
            local sf = new("Frame", {Size = UDim2.new(1, -86, 1, 0), BackgroundColor3 = T.field, BorderSizePixel = 0}, bar)
            corner(sf, 7)
            mkIcon(sf, "search", 12, T.faint, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0)})
            local sb = new("TextBox", {Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -34, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", PlaceholderText = "Search player...",
                PlaceholderColor3 = T.faint, TextColor3 = T.text, FontFace = FONT[2], TextSize = 10, TextXAlignment = XL, ClearTextOnFocus = false}, sf)
            local pg = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(78, 26), BackgroundTransparency = 1, BorderSizePixel = 0}, bar)
            local function pbtn(txt, x)
                local b = new("TextButton", {Position = UDim2.fromOffset(x, 2), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = T.field, AutoButtonColor = false, Text = txt, FontFace = FONT[3], TextSize = 12, TextColor3 = T.mid, BorderSizePixel = 0}, pg)
                corner(b, 6)
                return b
            end
            local pPrev, pNext = pbtn("<", 0), pbtn(">", 56)
            local pLbl = text(pg, {Text = "1/1", Position = UDim2.fromOffset(22, 0), Size = UDim2.fromOffset(34, 26), TextXAlignment = XC, W = 2, TextSize = 10, TextColor3 = T.mid, TextTruncate = NOTRUNC})
            -- header kolom
            local hdr = new("Frame", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 2}, views.lb)
            local usersL = lb(hdr, "Users 0", 6, 0, 100, 14, {W = 2, TextSize = 9, TextColor3 = T.faint})
            local function hcol(txt, x, w, al) text(hdr, {Text = txt, Position = UDim2.fromScale(x, 0), Size = UDim2.fromScale(w, 1), TextXAlignment = al, W = 2, TextSize = 9, TextColor3 = T.faint, TextTruncate = NOTRUNC}) end
            hcol("Score", 0.44, 0.18, XL)
            hcol("Executed", 0.64, 0.14, XC)
            hcol("Time", 0.8, 0.185, XR)
            local rowsF = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 3}, views.lb)
            new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, rowsF)

            local lbData = (type(C.Leaderboard) == "table") and C.Leaderboard or {}
            local logs = (type(C.Changelogs) == "table") and C.Changelogs or {{Version = tostring(C.Version or "V1.0"), Date = os.date("%Y-%m-%d"), Items = {"Initial release"}}}
            local page, PAGE = 1, 10
            local function entries()
                local list, hasMe = {}, false
                for _, e in ipairs(lbData) do
                    local c = {Name = tostring(e.Name or "?"), UserId = tonumber(e.UserId), Score = tonumber(e.Score) or 0, Executed = tonumber(e.Executed) or 0,
                        Time = tonumber(e.Time) or 0, Level = tonumber(e.Level) or 1, Crown = e.Crown == true}
                    if (c.UserId and c.UserId == LP.UserId) or c.Name == LP.Name then c.Me, hasMe = true, true end
                    list[#list + 1] = c
                end
                if not hasMe then
                    local xp, lv = lvInfo()
                    list[#list + 1] = {Name = LP.DisplayName, UserId = LP.UserId, Score = xp, Executed = stats.exec, Time = stats.secs, Level = lv, Me = true,
                        Crown = tostring(C.Role or "OWNER"):upper() == "OWNER"}
                end
                table.sort(list, function(a, b) return a.Score > b.Score end)
                for i, e in ipairs(list) do e.Rank = i end
                return list
            end
            local medals = {Color3.fromRGB(255, 196, 61), Color3.fromRGB(190, 196, 215), Color3.fromRGB(235, 130, 70)}
            local function refreshLB()
                local q, all, list = sb.Text:lower(), entries(), {}
                for _, e in ipairs(all) do if q == "" or e.Name:lower():find(q, 1, true) then list[#list + 1] = e end end
                local pages = math.max(1, math.ceil(#list / PAGE))
                page = math.clamp(page, 1, pages)
                usersL.Text = "Users " .. #all
                pLbl.Text = page .. "/" .. pages
                for _, c in ipairs(rowsF:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                local top = (all[1] and all[1].Score > 0) and all[1].Score or 1
                for i = (page - 1) * PAGE + 1, math.min(page * PAGE, #list) do
                    local e = list[i]
                    local r = new("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = e.Me and T.accent or T.field, BackgroundTransparency = e.Me and 0.82 or 0, BorderSizePixel = 0, LayoutOrder = i}, rowsF)
                    corner(r, 8)
                    if e.Me then stroke(r, T.accent, 1, 0.55) end
                    local medal = medals[e.Rank]
                    local rk = new("Frame", {Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = medal or T.bg, BackgroundTransparency = medal and 0.8 or 0.2, BorderSizePixel = 0}, r)
                    corner(rk, 7)
                    text(rk, {Text = tostring(e.Rank), Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 4, TextSize = 10, TextColor3 = medal or T.faint, TextTruncate = NOTRUNC})
                    local a = new("ImageLabel", {Position = UDim2.fromOffset(36, 5), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = T.outline, BorderSizePixel = 0,
                        Image = e.UserId and ("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60"):format(e.UserId) or ""}, r)
                    corner(a, "full")
                    text(r, {Text = e.Name .. (e.Crown and " 👑" or ""), Position = UDim2.fromOffset(66, 3), Size = UDim2.new(0.42, -66, 0, 16), W = 3, TextSize = 11})
                    text(r, {Text = (e.Me and "You · " or "") .. "Rank #" .. e.Rank .. " · Lv " .. e.Level, Position = UDim2.fromOffset(66, 18), Size = UDim2.new(0.42, -66, 0, 12), W = 1, TextSize = 8,
                        TextColor3 = e.Me and T.accentL or T.faint})
                    local tr = new("Frame", {Position = UDim2.new(0.44, 0, 0.5, -2), Size = UDim2.new(0.18, 0, 0, 4), BackgroundColor3 = T.outline, BorderSizePixel = 0}, r)
                    corner(tr, "full")
                    local fl = new("Frame", {Size = UDim2.fromScale(math.clamp(e.Score / top, 0.04, 1), 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, tr)
                    corner(fl, "full")
                    new("UIGradient", {Color = ColorSequence.new(T.accent2, T.accentL)}, fl)
                    text(r, {Text = tostring(e.Executed), Position = UDim2.fromScale(0.64, 0), Size = UDim2.fromScale(0.14, 1), TextXAlignment = XC, W = 3, TextSize = 10, TextTruncate = NOTRUNC})
                    text(r, {Text = fmtT(e.Time), Position = UDim2.fromScale(0.8, 0), Size = UDim2.fromScale(0.185, 1), TextXAlignment = XR, W = 2, TextSize = 10, TextColor3 = T.mid, TextTruncate = NOTRUNC})
                end
            end
            pPrev.MouseButton1Click:Connect(function() page = page - 1 refreshLB() end)
            pNext.MouseButton1Click:Connect(function() page = page + 1 refreshLB() end)
            sb:GetPropertyChangedSignal("Text"):Connect(function() page = 1 refreshLB() end)

            local function refreshLog()
                for _, c in ipairs(views.log:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                if #logs == 0 then
                    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.field, BorderSizePixel = 0, LayoutOrder = 1}, views.log)
                    corner(f, 8)
                    text(f, {Text = "No changelogs yet.", Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 1, TextSize = 10, TextColor3 = T.faint})
                end
                for i, e in ipairs(logs) do
                    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.field, BorderSizePixel = 0, LayoutOrder = i}, views.log)
                    corner(f, 8)
                    new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, f)
                    new("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, f)
                    local top = new("Frame", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1}, f)
                    pill(top, tostring(e.Version or "V?"), T.accent, 0, 0, true)
                    text(top, {Text = tostring(e.Date or ""), Size = UDim2.fromScale(1, 1), TextXAlignment = XR, W = 1, TextSize = 9, TextColor3 = T.faint})
                    local items = {}
                    for _, it in ipairs(e.Items or {}) do items[#items + 1] = "• " .. tostring(it) end
                    text(f, {Text = table.concat(items, "\n"), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
                        W = 1, TextSize = 10, TextColor3 = T.mid, TextTruncate = NOTRUNC, LayoutOrder = 2})
                end
            end
            function Window:SetLeaderboard(list) lbData = (type(list) == "table") and list or {} refreshLB() end
            function Window:SetChangelogs(list) logs = (type(list) == "table") and list or {} refreshLog() end

            ---------------- isi awal + pembaruan berkala ----------------
            local function paintFill() fillG.Color = ColorSequence.new(T.accent2, T.accentL) end
            paintFill()
            themeFns[#themeFns + 1] = function() paintFill() refreshLB() refreshLog() end
            showView("lb")
            exN.Text = tostring(stats.exec)
            plN.Text = tostring(#Players:GetPlayers())
            infoV[3].Text = os.date("%H:%M:%S")
            updLevel()
            updTime()
            refreshLB()
            refreshLog()
            task.spawn(function()
                local n = 0
                while gui.Parent do
                    task.wait(1)
                    n = n + 1
                    stats.secs = stats.secs + 1
                    updTime()
                    infoV[3].Text = os.date("%H:%M:%S")
                    if n % 5 == 0 then plN.Text = tostring(#Players:GetPlayers()) end
                    if n % 10 == 0 then
                        updLevel()
                        if p.frame.Visible and views.lb.Visible then refreshLB() end
                    end
                    if n % 15 == 0 then saveStats() end
                end
                saveStats()
            end)
        end
    end

    local dashGroup -- nama grup Dashboard otomatis (diisi setelah cek support game)
    local function addTab(gname, c)
        c = (type(c) == "table") and c or {Title = tostring(c)}
        local title = tostring(c.Title or c.Name or "Tab")
        local dash = title:lower() == "dashboard" and c.Dashboard ~= false
        if dash and Window.Dashboard then return Window.Dashboard end -- sudah ada otomatis, jangan dobel
        local p = createPage(gname, title, c.Icon, dash and "Overview, leaderboard and changelogs" or (c.Subtitle or c.Desc), dash and 1 or c.Columns)
        Window.Tabs[p.key] = p
        if dash then buildDashboard(p) end
        if cur == nil or dash then go(p.key) end
        return p.K
    end
    function Window:Group(c)
        if type(c) ~= "table" then c = {Title = tostring(c)} end
        local gname = tostring(c.Title or c.Name or "Menu")
        if dashGroup and gname:lower() == "dashboard" then gname = dashGroup end -- kode lama: Group "Dashboard" ikut masuk grup otomatis
        createGroup(gname, c.Icon)
        local G = {}
        function G:Tab(tc) return addTab(gname, tc) end
        G.CreateTab = function(self, tc) tc = tc or {} return addTab(gname, {Title = tc.Name or tc.Title, Icon = tc.Icon, Subtitle = tc.Subtitle, Columns = tc.Columns}) end
        return G
    end
    -- gaya lama (tanpa grup): halaman masuk ke grup "Menu" (atau c.Group)
    function Window:Tab(c)
        c = (type(c) == "table") and c or {Title = tostring(c)}
        if Window.Dashboard and tostring(c.Title or c.Name or ""):lower() == "dashboard" and c.Dashboard ~= false then return Window.Dashboard end
        local gname = tostring(c.Group or "Menu")
        if not groups[gname] then createGroup(gname, c.GroupIcon or ((gname == "Menu") and "grid" or nil)) end
        return addTab(gname, c)
    end
    function Window:CreateTab(c) c = c or {} return Window:Tab({Title = c.Name or c.Title, Icon = c.Icon, Group = c.Group, Subtitle = c.Subtitle}) end

    -- kontrol window: tombol kosong di video, jadi tutup lewat pill / tombol menu
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
            if kickOnFail then pcall(function() pl:Kick("NOT SUPPORTED - " .. LOGONAME .. "\n" .. placeId) end) end
        end)
        local function dummy()
            local d = {}
            return setmetatable(d, {__index = function() return function() return d end end})
        end
        function Window:Tab() return dummy() end
        function Window:Group() return dummy() end
        function Window:Panel() return dummy() end
        Window.CreateTab = Window.Tab
        return Window
    end

    -- DASHBOARD OTOMATIS: grup "Loaded" > tab "Dashboard", dibuat langsung di sini (pertama di sidebar, jadi halaman awal).
    -- Tidak perlu Window:Group / :Tab dari script kamu. Isi tambahan: Window.Dashboard:Accordion({...}), dst.
    if C.AutoDashboard ~= false then
        dashGroup = tostring(C.DashboardGroup or "Loaded")
        local dg = Window:Group({Title = dashGroup, Icon = "grid"})
        Window.Dashboard = dg:Tab({Title = "Dashboard", Icon = "grid"})
    end

    ------------------------------------------------------------------
    -- PANEL SAMPING glassmorphism (ala iOS "Slide Over"): kaca bergradien yang melayang 10px dari tepi layar.
    -- Lapisan dari belakang: kaca bergradien > aurora aksen > butiran frost > kilap atas > isi > tepi kaca bercahaya.
    -- Handle = pil kaca tipis. Tap = buka / tutup, tarik handle atau header = geser (kibas cepat = langsung buka / tutup).
    -- Opsi: Title, Subtitle, Width (300), Glass (0.34 = tingkat bening kaca, 0.05 - 0.75), OpenDrag ("Left" / "Right"),
    --       GripY (0.5), Open, Callback(isOpen). Baris komponen di dalam panel ikut jadi kaca (ctx.glass).
    ------------------------------------------------------------------
    function Window:Panel(o)
        o = o or {}
        local COMPACT = 0.76 -- Width (default 300) diperkecil jadi ~228px. Naikkan kalau mau lebih lebar
        local function calcW(w) return math.clamp(math.floor((tonumber(w) or 300) * COMPACT + 0.5), 190, 400) end
        local W = calcW(o.Width)
        local GL = math.clamp(tonumber(o.Glass) or 0.34, 0.05, 0.75)
        local touchOnly = UIS.TouchEnabled and not UIS.MouseEnabled
        local HZ, HH = UIS.TouchEnabled and 26 or 18, UIS.TouchEnabled and 120 or 92 -- zona sentuh handle (lebar, tinggi)
        local M, HEADP, RAD = 10, 48, 20 -- jarak panel ke tepi layar, tinggi header, radius sudut
        local PADT, PADB, FOOT = 10, 12, 8 -- padding isi atas / bawah, jarak viewport ke tepi bawah (supaya baris tidak keluar dari sudut membulat)
        local dockL = tostring(o.OpenDrag or "Left"):lower() == "right"
        local AX = dockL and 0 or 1
        local isP, destroyed, prog = false, false, 0
        local hovering, pressing = false, false
        local title0 = tostring(o.Title or "Panel")
        local minH = 130
        local function kp(t, v) return NumberSequenceKeypoint.new(t, math.clamp(v, 0, 1)) end
        local function ck(t, c) return ColorSequenceKeypoint.new(t, c) end
        local function ns(...) return NumberSequence.new({...}) end

        -- holder: nempel di tengah layar (vertikal), tinggi diatur fit() mengikuti isi
        local holder = new("Frame", {Name = "NEMESIS_Panel", AnchorPoint = Vector2.new(AX, 0.5), Size = UDim2.fromOffset(W + HZ, 200), BackgroundTransparency = 1, ZIndex = 60}, root)
        local function pos(p)
            local x = (1 - p) * W - p * M
            return UDim2.new(AX, dockL and -x or x, 0.5, 0)
        end
        holder.Position = pos(0)

        ------------------------------------------------------------------
        -- HANDLE: pil kaca tipis + dua lapis cahaya aksen. Ukuran & kecerahan berubah menurut keadaan
        ------------------------------------------------------------------
        local gy = math.clamp(tonumber(o.GripY) or 0.5, 0.12, 0.88)
        local grip = new("TextButton", {Name = "Handle", AnchorPoint = Vector2.new(1 - AX, gy), Position = UDim2.new(1 - AX, 0, gy, 0), Size = UDim2.fromOffset(HZ, HH),
            BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Active = true, ZIndex = 5}, holder)
        local function halo(extra, tr)
            local h = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(5 + extra, 46 + extra),
                BackgroundTransparency = tr, BorderSizePixel = 0, ZIndex = 6}, grip)
            skin(h, "BackgroundColor3", "accent")
            corner(h, "full")
            return h
        end
        local halo1, halo2 = halo(14, 0.93), halo(7, 0.85)
        local pill = new("Frame", {Name = "Pill", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(5, 46),
            BackgroundColor3 = WHITE, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 7}, grip)
        corner(pill, "full")
        local pillG = new("UIGradient", {Rotation = 90}, pill)
        stroke(pill, WHITE, 1, 0.6)

        local PS = { -- keadaan handle: lebar, tinggi, transparansi pil, transparansi dua lapis cahaya
            closed = {w = 5, h = 46, pt = 0.05, t1 = 0.93, t2 = 0.85},
            open = {w = 5, h = 30, pt = 0.4, t1 = 1, t2 = 1},
            hover = {w = 6, h = 56, pt = 0, t1 = 0.86, t2 = 0.72},
            press = {w = 7, h = 62, pt = 0, t1 = 0.8, t2 = 0.64},
        }
        local function pillFx()
            local s = (pressing and PS.press) or (hovering and PS.hover) or (isP and PS.open) or PS.closed
            play(pill, {Size = UDim2.fromOffset(s.w, s.h), BackgroundTransparency = s.pt}, 0.25)
            play(halo1, {Size = UDim2.fromOffset(s.w + 14, s.h + 14), BackgroundTransparency = s.t1}, 0.25)
            play(halo2, {Size = UDim2.fromOffset(s.w + 7, s.h + 7), BackgroundTransparency = s.t2}, 0.25)
        end
        if not touchOnly then
            grip.MouseEnter:Connect(function() hovering = true pillFx() end)
            grip.MouseLeave:Connect(function() hovering = false pillFx() end)
        end

        ------------------------------------------------------------------
        -- BODY: kaca bergradien (warna + tingkat bening ikut diagonal) + aurora aksen + frost + kilap + tepi kaca bercahaya
        -- Catatan: sudut membulat TIDAK otomatis memotong anak-anaknya, jadi setiap lapisan penuh diberi corner sendiri.
        ------------------------------------------------------------------
        local bh = new("Frame", {Name = "BodyHolder", AnchorPoint = Vector2.new(AX, 0), Position = UDim2.new(AX, 0, 0, 0), Size = UDim2.new(0, W, 1, 0), BackgroundTransparency = 1}, holder)
        local aura = new("ImageLabel", {Name = "Aura", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 80, 1, 80), BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843", ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 0}, bh)
        skin(aura, "ImageColor3", "accent") -- cahaya ambient di sekeliling panel saat terbuka
        local psh = shadow(bh)
        psh.Size = UDim2.new(1, 44, 1, 44)
        psh.ImageTransparency = 1
        local body = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Active = true, ClipsDescendants = true}, bh)
        corner(body, RAD)
        local bgG = new("UIGradient", {Rotation = 55, Transparency = ns(kp(0, GL + 0.1), kp(0.5, GL + 0.02), kp(1, GL - 0.06))}, body)
        local rimG = new("UIGradient", {Rotation = 45, Transparency = ns(kp(0, 0.05), kp(0.3, 0.55), kp(0.65, 0.8), kp(1, 0.45))}, stroke(body, WHITE, 1.5, 0))

        local function layer(name, z)
            local f = new("Frame", {Name = name, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = z}, body)
            corner(f, RAD)
            return f
        end
        -- aurora: dua sapuan gradien aksen dari sudut berlawanan (pelan bergeser saat panel terbuka)
        local wash1G = new("UIGradient", {Rotation = 40, Transparency = ns(kp(0, 0.6), kp(0.4, 0.88), kp(0.8, 1), kp(1, 1))}, layer("AuroraA", 0))
        local wash2G = new("UIGradient", {Rotation = 220, Transparency = ns(kp(0, 0.72), kp(0.35, 0.93), kp(0.7, 1), kp(1, 1))}, layer("AuroraB", 0))
        local function orb(px, py, w, h, tr, key)
            local f = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(px, py), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1,
                Image = "rbxassetid://6015897843", ImageTransparency = tr, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 0}, body)
            skin(f, "ImageColor3", key)
        end
        orb(0.2, 0.06, 190, 120, 0.7, "accent")
        orb(0.85, 0.96, 200, 130, 0.74, "accent2")
        -- butiran frost (pola yang sama dengan window)
        local frost = new("ImageLabel", {Name = "Frost", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://2151741365", ImageTransparency = 0.93,
            TileSize = UDim2.fromOffset(20, 20), ScaleType = Enum.ScaleType.Tile, ZIndex = 1}, body)
        corner(frost, RAD)
        -- kilap cahaya dari atas
        local gloss = new("Frame", {Name = "Gloss", Size = UDim2.new(1, 0, 0.55, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, body)
        corner(gloss, RAD)
        new("UIGradient", {Rotation = 90, Transparency = ns(kp(0, 0.8), kp(0.5, 0.94), kp(1, 1))}, gloss)
        -- kilau tipis di tepi atas
        local spec = new("Frame", {Position = UDim2.fromOffset(RAD, 0), Size = UDim2.new(1, -RAD * 2, 0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 4}, body)
        new("UIGradient", {Transparency = ns(kp(0, 1), kp(0.25, 0), kp(0.75, 0), kp(1, 1))}, spec)
        -- tepi dalam bercahaya (kaca punya dua tepi: luar terang, dalam samar)
        local inner = new("Frame", {Name = "InnerEdge", Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7}, body)
        corner(inner, RAD - 2)
        local innerG = new("UIGradient", {Rotation = 45, Transparency = ns(kp(0, 0.7), kp(0.5, 0.93), kp(1, 0.8))}, stroke(inner, WHITE, 1, 0))

        ------------------------------------------------------------------
        -- HEADER: badge logo + judul bergradien + subjudul + tombol tutup kaca, garis aksen yang memudar di bawah
        ------------------------------------------------------------------
        local hdr = new("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, HEADP), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 2}, body)
        local sep = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 2}, hdr)
        new("UIGradient", {Transparency = ns(kp(0, 1), kp(0.2, 0), kp(0.8, 0), kp(1, 1))}, sep)
        local hline = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, ZIndex = 3}, hdr)
        skin(hline, "BackgroundColor3", "accent")
        new("UIGradient", {Transparency = ns(kp(0, 1), kp(0.18, 0.15), kp(0.55, 0.6), kp(1, 1))}, hline)
        -- kilau yang menyapu satu kali di garis aksen setiap kali panel dibuka
        local shim = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4}, hdr)
        local sg = new("UIGradient", {Offset = Vector2.new(-1, 0), Transparency = ns(kp(0, 1), kp(0.42, 1), kp(0.5, 0.2), kp(0.58, 1), kp(1, 1))}, shim)
        local sweep = TweenService:Create(sg, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Offset = Vector2.new(1, 0)})
        local function shine()
            sg.Offset = Vector2.new(-1, 0)
            if NOANIM then sweep:Cancel() else sweep:Play() end
        end
        -- aurora hidup: gradien pelan bergeser bolak-balik selama panel terbuka (mati kalau animasi dimatikan)
        local drift1 = TweenService:Create(wash1G, TweenInfo.new(5.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0.25, 0.2)})
        local drift2 = TweenService:Create(wash2G, TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(-0.25, -0.2)})
        local function ambient(on)
            if on and not NOANIM then
                drift1:Play()
                drift2:Play()
            else
                drift1:Cancel()
                drift2:Cancel()
                wash1G.Offset, wash2G.Offset = Vector2.new(0, 0), Vector2.new(0, 0)
            end
        end

        -- badge logo: halo aksen + kotak kaca dengan outline gradien
        local bw = new("Frame", {Name = "LogoHolder", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, -1), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, ZIndex = 2}, hdr)
        for _, hh in ipairs({{14, 0.94, 14}, {7, 0.86, 11}}) do
            local hl = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, hh[1], 1, hh[1]), BackgroundTransparency = hh[2], BorderSizePixel = 0, ZIndex = 1}, bw)
            skin(hl, "BackgroundColor3", "accent")
            corner(hl, hh[3])
        end
        local badge = new("Frame", {Name = "Badge", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 2}, bw)
        corner(badge, 8)
        local bsg = new("UIGradient", {Rotation = 45}, stroke(badge, WHITE, 1.5, 0))
        logoImg(badge, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16), ScaleType = Enum.ScaleType.Fit, ZIndex = 3})

        local hasSub = o.Subtitle ~= nil and tostring(o.Subtitle) ~= ""
        local TXW, TXR = 46, 44
        local tl = text(hdr, {Text = title0, Position = UDim2.fromOffset(TXW, hasSub and 8 or 0), Size = UDim2.new(1, -(TXW + TXR), 0, hasSub and 19 or HEADP - 2), W = 3, TextSize = 14, ZIndex = 2})
        local tG = new("UIGradient", {}, tl) -- judul memudar dari putih ke aksen
        local sl = text(hdr, {Text = tostring(o.Subtitle or ""), Position = UDim2.fromOffset(TXW, 26), Size = UDim2.new(1, -(TXW + TXR), 0, 14), TextSize = 11, W = 1, TextColor3 = T.dim, Visible = hasSub, ZIndex = 2})

        -- tombol tutup: lingkaran kaca kecil, panah menunjuk ke tepi layar
        local cb = new("TextButton", {Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, -1), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = WHITE,
            Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 4}, hdr)
        corner(cb, "full")
        new("UIGradient", {Rotation = 45, Transparency = ns(kp(0, 0.8), kp(1, 0.94))}, cb)
        local cst = stroke(cb, WHITE, 1, 0.72)
        local cic = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
            Image = "rbxassetid://6031091004", ImageColor3 = T.dim, Rotation = dockL and 90 or -90, ZIndex = 5}, cb)
        cb.MouseEnter:Connect(function()
            play(cb, {BackgroundColor3 = T.accent}, 0.2)
            play(cst, {Color = T.accent, Transparency = 0.2}, 0.2)
            play(cic, {ImageColor3 = T.text}, 0.2)
        end)
        cb.MouseLeave:Connect(function()
            play(cb, {BackgroundColor3 = WHITE}, 0.2)
            play(cst, {Color = WHITE, Transparency = 0.72}, 0.2)
            play(cic, {ImageColor3 = T.dim}, 0.2)
        end)

        ------------------------------------------------------------------
        -- ISI: daftar komponen yang bisa di-scroll. Viewport berhenti FOOT px di atas tepi bawah supaya baris
        -- yang ter-scroll tidak menembus sudut membulat. Pudar tipis di bawah = penanda masih ada isi.
        ------------------------------------------------------------------
        local pscroll = new("ScrollingFrame", {Name = "Content", Active = true, Position = UDim2.fromOffset(0, HEADP), Size = UDim2.new(1, 0, 1, -(HEADP + FOOT)), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageTransparency = 0.25, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 2}, body)
        skin(pscroll, "ScrollBarImageColor3", "accent")
        local plist = new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, pscroll)
        new("UIPadding", {PaddingTop = UDim.new(0, PADT), PaddingBottom = UDim.new(0, PADB), PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)}, pscroll)
        local pfade = new("Frame", {Name = "Fade", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -FOOT), Size = UDim2.new(1, 0, 0, PADB), BackgroundColor3 = T.bg, BorderSizePixel = 0, ZIndex = 5}, body)
        new("UIGradient", {Rotation = 90, Transparency = ns(kp(0, 1), kp(1, 0.55))}, pfade)

        -- tinggi panel = header + isi (maks 70% tinggi layar). Ikut berubah saat accordion buka/tutup & saat layar di-resize
        local function fit(anim)
            if destroyed then return end
            local s = math.max(rootScale.Scale, 0.01)
            local maxH = math.max(minH, gui.AbsoluteSize.Y / s * 0.7)
            local want = HEADP + PADT + PADB + FOOT + plist.AbsoluteContentSize.Y / s
            local sz = UDim2.fromOffset(W + HZ, math.floor(math.clamp(want, minH, maxH)))
            if anim then play(holder, {Size = sz}, 0.2) else holder.Size = sz end
        end
        bind(plist:GetPropertyChangedSignal("AbsoluteContentSize"), function() fit() end)
        bind(rootScale:GetPropertyChangedSignal("Scale"), function() fit() end)
        fit()

        -- drawer dropdown butuh ruang: begitu dipakai pertama kali, tinggi minimum panel dinaikkan
        local pctx = newCtx(body, RAD)
        pctx.glass = true -- baris komponen di panel ini dibuat lebih bening (dibaca buildComponents)
        local rawDrawer = pctx.drawer
        pctx.drawer = function()
            local fresh = pctx.d == nil
            local d = rawDrawer()
            if fresh then
                minH = math.max(minH, 260)
                fit(true)
            end
            return d
        end
        local K = buildComponents(pscroll, nil, pctx)

        ------------------------------------------------------------------
        -- BUKA / TUTUP + GESER
        ------------------------------------------------------------------
        local function goTo(open)
            if destroyed then return end
            local was = isP
            isP = open and true or false
            prog = isP and 1 or 0
            if not isP and pctx.d then pctx.d.close() end
            play(holder, {Position = pos(prog)}, isP and 0.55 or 0.4, isP and BACK or QUINT) -- buka: pegas sedikit, tutup: mulus
            play(psh, {ImageTransparency = isP and 0.45 or 1}, 0.4)
            play(aura, {ImageTransparency = isP and 0.82 or 1}, 0.5)
            pillFx()
            ambient(isP)
            if isP then shine() end
            if was ~= isP and o.Callback then task.spawn(safe, o.Callback, isP) end
        end
        cb.MouseButton1Click:Connect(function() goTo(false) end)

        -- tarik: panel ikut jari; saat dilepas, kibasan cepat menentukan arah, kalau pelan lihat posisinya (lewat setengah = buka)
        local vel, lastX, lastT = 0, nil, 0
        local function dragBegin()
            pressing, vel, lastX = true, 0, nil
            pillFx()
            return prog
        end
        local function dragMove(dx, dy, p0, moved, ip)
            if not moved then return end
            local now = os.clock()
            if lastX and now > lastT then
                vel = vel * 0.6 + ((ip.X - lastX) / (now - lastT)) * 0.4
            end
            lastX, lastT = ip.X, now
            local d = dx / math.max(rootScale.Scale, 0.01)
            if dockL then d = -d end
            prog = math.clamp(p0 - d / (W + M), 0, 1)
            holder.Position = pos(prog)
            psh.ImageTransparency = 1 - 0.55 * prog
            aura.ImageTransparency = 1 - 0.18 * prog
        end
        local function release(moved, tapToggles)
            pressing = false
            if not moved then
                pillFx()
                if tapToggles then goTo(not isP) end
                return
            end
            local openV = (os.clock() - lastT < 0.1) and (dockL and vel or -vel) or 0
            if math.abs(openV) > 350 then goTo(openV > 0) else goTo(prog > 0.5) end
        end
        track(grip, dragBegin, dragMove, function(moved) release(moved, true) end)
        track(hdr, dragBegin, dragMove, function(moved) release(moved, false) end)

        -- ikut ganti tema
        local function paint()
            local a, b = T.accent, T.accent2
            bgG.Color = ColorSequence.new({ck(0, T.side:Lerp(a, 0.4)), ck(0.5, T.side:Lerp(b, 0.14)), ck(1, T.bg:Lerp(b, 0.12))})
            wash1G.Color = ColorSequence.new(a, b)
            wash2G.Color = ColorSequence.new(b, a)
            rimG.Color = ColorSequence.new({ck(0, WHITE), ck(0.35, WHITE:Lerp(a, 0.55)), ck(0.7, b), ck(1, WHITE:Lerp(b, 0.4))})
            innerG.Color = ColorSequence.new(WHITE:Lerp(a, 0.4), b)
            pillG.Color = ColorSequence.new(a, b)
            bsg.Color = ColorSequence.new(a, b)
            tG.Color = ColorSequence.new({ck(0, WHITE), ck(0.35, WHITE:Lerp(a, 0.5)), ck(1, WHITE:Lerp(a, 0.7))})
        end
        paint()
        themeFns[#themeFns + 1] = paint

        function K:Show() goTo(true) end
        function K:Hide() goTo(false) end
        function K:Switch() goTo(not isP) end
        function K:IsOpen() return isP end
        function K:SetTitle(t) tl.Text = tostring(t) end
        function K:SetSubtitle(t)
            local s = (t == nil) and "" or tostring(t)
            sl.Text, sl.Visible = s, s ~= ""
            tl.Position = UDim2.fromOffset(TXW, s ~= "" and 8 or 0)
            tl.Size = UDim2.new(1, -(TXW + TXR), 0, s ~= "" and 19 or HEADP - 2)
        end
        function K:SetVisible(v) holder.Visible = v and true or false end
        function K:SetWidth(w)
            W = calcW(w)
            bh.Size = UDim2.new(0, W, 1, 0)
            fit()
            holder.Position = pos(prog)
        end
        function K:Destroy()
            if destroyed then return end
            destroyed = true
            ambient(false)
            holder:Destroy()
        end
        if o.Open then
            isP, prog = true, 1
            holder.Position = pos(1)
            psh.ImageTransparency = 0.45
            aura.ImageTransparency = 0.82
            pillFx()
            ambient(true)
        end
        return K
    end


    ------------------------------------------------------------------
    -- UI SETTINGS (halaman tersembunyi, dibuka lewat tombol "UI Settings" di kiri bawah)
    ------------------------------------------------------------------
    do
        local sp = createPage(nil, "Settings", nil, "Theme, window size, blur and keys", nil, true)
        sp.title = "UI Settings"
        local S = sp.K

        local AP = S:Accordion({Title = "Theme", Icon = "palette"})
        AP:Dropdown({Title = "Accent color", Desc = "Pick an accent color preset", Flag = "UITheme", Options = ORDER, Default = curTheme,
            Swatch = function(n) return THEMES[n] and THEMES[n][1] or nil end,
            Callback = function(v)
                if type(v) == "string" and THEMES[v] then
                    curTheme = v
                    applyTheme(v)
                end
            end})
        AP:Toggle({Title = "Top pill", Desc = "Show the name + FPS pill at the top", Flag = "UIPill", Default = true,
            Callback = function(v) launcher.Visible = v and true or false end})

        local WS = S:Accordion({Title = "Window size", Icon = "sliders"})
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
            sizeUI.w:Set(DEFAULT.X)
            sizeUI.h:Set(DEFAULT.Y)
            scaleS:Set(math.floor(userScale * 100 + 0.5))
            F.UIW, F.UIH = nil, nil
            applyScale()
            layoutWin(true)
            persist()
            notify("Window reset", "Size and scale restored", T.accent, 2)
        end})

        local BL = S:Accordion({Title = "Blur", Icon = "eye"})
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

        local GN = S:Accordion({Title = "General", Icon = "settings"})
        GN:Keybind({Title = "Menu key", Desc = "Show or hide the interface", Flag = "MenuKey", Default = toggleKey,
            OnChange = function(k) if k then toggleKey = k end end})
        GN:Toggle({Title = "Reduce animation", Desc = "Instant changes, lightest on weak devices", Flag = "UINoAnim", Default = NOANIM,
            Callback = function(v) NOANIM = v and true or false end})
    end
    if F.UIPill == false then launcher.Visible = false end

    ------------------------------------------------------------------
    -- DEMO: tiruan isi video (C.Demo = true). Dashboard / GrowBlox (Farm + 6 sub-tab) / Settings
    ------------------------------------------------------------------
    if C.Demo then
        local dash = Window.Dashboard or Window:Group({Title = "Dashboard", Icon = "grid"}):Tab({Title = "Dashboard", Icon = "grid"}) -- sudah otomatis di grup "Loaded"
        local c1 = dash:Accordion({Title = "Components", Icon = "layers", Column = 1})
        c1:Button({Title = "Button", Desc = "Click me", Callback = function() notify("Button", "Clicked", T.accent, 1.5) end})
        c1:Toggle({Title = "Toggle", Desc = "Switch with a description", Flag = "Demo_Toggle", Default = true})
        c1:Slider({Title = "Slider", Desc = "Drag the knob", Flag = "Demo_Slider", Min = 0, Max = 100, Default = 40, Suffix = "%"})
        c1:Textbox({Title = "Textbox", Flag = "Demo_Text", Placeholder = "Type here..."})
        local c2 = dash:Accordion({Title = "Inputs", Icon = "sliders", Column = 2})
        c2:Dropdown({Title = "Dropdown", Flag = "Demo_DD", Options = {"Alpha", "Beta", "Gamma"}, Default = "Alpha"})
        c2:Keybind({Title = "Keybind", Flag = "Demo_Key", Default = Enum.KeyCode.F})
        c2:ColorPicker({Title = "Color picker", Flag = "Demo_Col", Default = T.accent})
        c2:Info({Title = "Version", Value = "v" .. VERSION})
        local c3 = dash:Accordion({Title = "About", Icon = "info", Column = 1})
        c3:Paragraph({Title = "Nemesis style", Desc = "Dark cards, purple accent, pill launcher at the top. Tap the pill to open or close."})

        local GB = Window:Group({Title = "GrowBlox", Icon = "sprout"})
        local farm = GB:Tab({Title = "Farm", Icon = "pickaxe", Subtitle = "Clear, mine, farm, loot"})
        local cw = farm:SubTab({Title = "Clear World", Icon = "eraser"})
        local a = cw:Accordion({Title = "Clear World", Icon = "eraser", Column = 1})
        a:Toggle({Title = "Auto Clear World", Desc = "Break every tile, row by row", Flag = "CW_Auto", Default = false})
        a:Dropdown({Title = "Targets", Flag = "CW_Targets", Options = {"Everything", "Blocks", "Background", "Hazards"}, Default = "Everything"})
        a:Toggle({Title = "Clear background", Desc = "Also break the cave layer", Flag = "CW_Bg", Default = true})
        a:Toggle({Title = "Break lava / spikes", Desc = "Hit them from a safe distance", Flag = "CW_Lava", Default = true})
        a:Toggle({Title = "Break trees", Desc = "Planted trees are skipped by default", Flag = "CW_Trees", Default = false})
        local pr = cw:Accordion({Title = "Progress", Icon = "activity", Column = 1})
        pr:Section("Clear")
        pr:Label("Idle")
        local pc = cw:Accordion({Title = "Pace", Icon = "gauge", Column = 2})
        pc:Dropdown({Title = "Hit method", Flag = "CW_Method", Options = {"Hold", "Tap", "Burst"}, Default = "Hold"})
        pc:Slider({Title = "Hit interval", Desc = "Act call only, game cooldown 0.22s", Flag = "CW_Interval", Min = 0.05, Max = 1, Step = 0.01, Default = 0.25, Suffix = "s"})
        pc:Button({Title = "Test one hit", Desc = "Checks the server keeps the break", Callback = function() notify("Test", "One hit sent", T.accent, 1.5) end})
        pc:Toggle({Title = "Pick up drops", Desc = "Take drops while clearing", Flag = "CW_Drops", Default = true})
        pc:Slider({Title = "Pickup radius", Desc = "Tiles around you", Flag = "CW_Radius", Min = 1, Max = 8, Step = 0.1, Default = 2.2})

        local mine = farm:SubTab({Title = "Mine", Icon = "pickaxe"})
        local am = mine:Accordion({Title = "Auto Mine", Icon = "pickaxe", Column = 1})
        am:Toggle({Title = "Auto Mine", Desc = "Break matching blocks nearby", Flag = "M_Auto"})
        am:Textbox({Title = "Filter", Flag = "M_Filter", Placeholder = "name or id, comma separated"})
        am:Slider({Title = "Radius", Desc = "Tiles from where you stand", Flag = "M_Radius", Min = 1, Max = 12, Default = 3})
        am:Toggle({Title = "Single block", Desc = "Stop after one block", Flag = "M_Single"})
        am:Toggle({Title = "Whole world", Desc = "Ignore radius, farm until gone", Flag = "M_World"})
        local dd = mine:Accordion({Title = "Auto Dig Down", Icon = "pickaxe", Column = 2})
        dd:Toggle({Title = "Auto Dig Down", Desc = "Break the block below, fall, repeat", Flag = "M_Dig"})
        dd:Toggle({Title = "Stop before hazards", Desc = "Act call only, game cooldown 0.22s", Flag = "M_Haz", Default = true})
        local fs = mine:Accordion({Title = "Farm Selected", Icon = "target", Column = 1})
        fs:Textbox({Title = "Block", Flag = "FS_Block", Default = "Rock"})
        fs:Buttons({{Title = "Add"}, {Title = "Clear"}})
        fs:Section("Targets")
        fs:Label("Lava #4, Rock #10")
        fs:Toggle({Title = "Auto Farm Selected", Desc = "Digs top-down to every target", Flag = "FS_Auto"})
        fs:Toggle({Title = "Collect drops", Desc = "Pick up seeds / gems / blocks after a break", Flag = "FS_Drops", Default = true})
        fs:Slider({Title = "Collect range", Desc = "Tiles to walk for a drop", Flag = "FS_Range", Min = 1, Max = 12, Default = 6})
        fs:Section("Status")
        fs:Label("Off")
        fs:Label("Targets broken 0 | Dug 0 | Left ?")

        for _, nm in ipairs({{"Farm", "sprout"}, {"Loot", "box"}, {"Dirt Farm", "layers"}, {"Harvest", "wheat"}}) do
            local st = farm:SubTab({Title = nm[1], Icon = nm[2]})
            local card = st:Accordion({Title = nm[1], Icon = nm[2], Column = 1})
            card:Toggle({Title = "Auto " .. nm[1], Desc = "Turn the " .. nm[1]:lower() .. " routine on", Flag = "T_" .. nm[1]})
            card:Slider({Title = "Delay", Desc = "Seconds between actions", Flag = "T_" .. nm[1] .. "_D", Min = 0, Max = 2, Step = 0.05, Default = 0.2, Suffix = "s"})
        end
        GB:Tab({Title = "Move", Icon = "zap", Subtitle = "Movement helpers"}):Accordion({Title = "Movement", Icon = "zap"}):Toggle({Title = "Fast walk", Desc = "Move quicker than normal", Flag = "Mv_Fast"})
        GB:Tab({Title = "Utility", Icon = "wrench", Subtitle = "Small tools"}):Accordion({Title = "Utility", Icon = "wrench"}):Toggle({Title = "Anti AFK", Desc = "Prevent the idle kick", Flag = "Ut_AFK", Default = true})

        local SG = Window:Group({Title = "Settings", Icon = "sliders"})
        local cfg = SG:Tab({Title = "Config", Icon = "save", Subtitle = "Save and load your settings"})
        local cc = cfg:Accordion({Title = "Configs", Icon = "save", Column = 1})
        local cname = cc:Textbox({Title = "Config name", Flag = "Cfg_Name", Default = "default"})
        cc:Buttons({
            {Title = "Save", Callback = function() Window:SaveConfig(cname:Get()) notify("Config", "Saved " .. tostring(cname:Get()), T.ok, 2) end},
            {Title = "Load", Callback = function()
                local ok, err = Window:LoadConfig(cname:Get())
                notify("Config", ok and ("Loaded " .. tostring(cname:Get())) or tostring(err), ok and T.ok or T.bad, 2)
            end},
        })
    end

    openA()
    notify(LOGONAME .. " v" .. VERSION, "Loaded successfully", T.accent, 3)
    return Window
end

return SORU
