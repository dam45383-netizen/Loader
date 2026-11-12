
-- Tambahan API: Window:Group(), Page:SubTab() (chip di atas konten), K:Accordion = kartu 2 kolom, K:Buttons({...}).
-- Dashboard OTOMATIS: grup "Loaded" > tab "Dashboard" langsung ada begitu CreateWindow jalan (tidak perlu dipanggil). Akses isinya lewat Window.Dashboard.
--   Opsi: AutoDashboard = false (matikan), DashboardGroup = "Nama Grup" (ganti nama grup, default "Loaded").
-- NEXRIFT SKIN (1.3.0): tema merah-hitam, banner sidebar, pill atas, tab aktif, dan ikon grid digambar langsung lewat kode (tanpa gambar).
--   Opsi baru CreateWindow: Brand = "NEXRIFT", Tagline = "Play Smarter." (false = tanpa tagline), OldBanner = true (banner gambar lama), OldPill = true (pill gambar lama).
--   Pertama kali jalan, tema otomatis pindah ke "Nexrift" (sekali saja). Setelah itu pilihan tema di UI Settings tetap dihormati.
local SORU = {Version = "1.3.0"}
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
local LOGO, LOGOCHAR, LOGONAME = "", "S", "SoruHub"
-- CHAT: isi URL Firebase Realtime Database di sini (atau lewat CreateWindow({ChatUrl = "..."})). Contoh: "https://nama-project-default-rtdb.firebaseio.com"
local CHAT_URL = "https://chatting-soru-hub-default-rtdb.asia-southeast1.firebasedatabase.app/"

-- BANNER: logo SORU HUB utuh (huruf S + teks + kursor) di pojok kiri atas sidebar, WARNANYA IKUT TEMA.
-- Dibuat dari 2 lapis PNG (base64 di PALING BAWAH file): BANNER_B64 = lapisan bayangan yang di-tint warna aksen tema, BANNER_B64S = highlight putih + tulisan "SORU" (tetap).
-- Dipakai otomatis kalau C.Logo / C.LogoUrl kosong. Opsi: CreateWindow({Banner = false}) matikan, CreateWindow({Banner = "rbxassetid://ID"}) pakai gambar sendiri (warna tidak ikut tema).
local BANNER, BANNER2, BANNER_B64, BANNER_B64S = "", "", "", ""
local NEXBANNER = false -- true = banner NEXRIFT buatan kode (default)
local BN_HSHIFT, BN_SBOOST = -0.009577, 1.4552 -- hasil fitting: aksen tema -> warna tint banner (di tema Nemesis hasilnya = warna logo asli)
local function bannerTint(c)
    local h, s = c:ToHSV()
    return Color3.fromHSV((h + BN_HSHIFT) % 1, math.min(1, s * BN_SBOOST), 1)
end
local B64 = {}
for i = 1, 64 do B64[("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"):byte(i)] = i - 1 end
local function b64dec(s)
    s = s:gsub("[^%w%+/=]", "")
    local out, n = {}, 0
    for i = 1, #s, 4 do
        local a, b, c, d = s:byte(i, i + 3)
        local v = (B64[a] or 0) * 262144 + (B64[b] or 0) * 4096 + (B64[c] or 0) * 64 + (B64[d] or 0)
        local x, y, z = math.floor(v / 65536), math.floor(v / 256) % 256, v % 256
        n = n + 1
        out[n] = (c == 61) and string.char(x) or ((d == 61) and string.char(x, y) or string.char(x, y, z))
    end
    return table.concat(out)
end
local function loadB64(data, tag)
    local p = CFG .. "/soru_banner_" .. tag .. "_" .. #data .. ".png"
    local function asset() local ok, a = pcall(getcustomasset, p) return (ok and type(a) == "string" and a ~= "") and a or nil end
    local ok, has = pcall(isfile, p)
    if not (ok and has) then
        local ok2, bytes = pcall(b64dec, data)
        if not (ok2 and type(bytes) == "string" and #bytes > 64) then return "" end
        pcall(writefile, p, bytes)
        task.wait(0.05)
    end
    return asset() or ""
end
local function loadBanner() -- -> lapisan tint, lapisan highlight ("" kalau gagal)
    if BANNER_B64 == "" or BANNER_B64S == "" or not (isfile and getcustomasset and writefile) then return "", "" end
    local a, b = loadB64(BANNER_B64, "tint"), loadB64(BANNER_B64S, "shine")
    if a == "" or b == "" then return "", "" end
    return a, b
end

-- PILL (launcher di atas layar): gambar 3 lapis seperti banner. PILL.B = bentuk/body (warna gelap ikut tema), PILL.T = lapisan tint aksen (ikut tema, sama dengan banner),
-- PILL.S = highlight putih + tulisan SORU (tetap). Base64 ada di PALING BAWAH file. Bar sinyal + angka FPS digambar LIVE di atas gambar.
-- Opsi: CreateWindow({Pill = false}) = pakai pill lama (tanpa gambar). Kalau executor tidak punya writefile/getcustomasset, otomatis jatuh ke pill lama.
local PILL = {B = "", T = "", S = ""}
local PILL_H, PILL_ASPECT, PILL_OFF = 38, 749 / 120, Color3.fromRGB(65, 63, 74) -- tinggi pill (px), rasio gambar, warna bar yang mati
local function loadPill() -- -> body, tint, highlight ("" kalau gagal)
    if PILL.B == "" or PILL.T == "" or PILL.S == "" or not (isfile and getcustomasset and writefile) then return "", "", "" end
    local a, b, c = loadB64(PILL.B, "pillbody"), loadB64(PILL.T, "pilltint"), loadB64(PILL.S, "pillshine")
    if a == "" or b == "" or c == "" then return "", "", "" end
    return a, b, c
end

----------------------------------------------------------------------
-- THEME: palet gelap ala Nemesis (hampir hitam + ungu). Aksen bisa diganti lewat UI Settings (45 preset)
----------------------------------------------------------------------
local WHITE = Color3.new(1, 1, 1)
local T = {
    bg = Color3.fromRGB(10, 9, 11), side = Color3.fromRGB(6, 6, 8), el = Color3.fromRGB(20, 16, 19), field = Color3.fromRGB(29, 24, 28),
    hover = Color3.fromRGB(42, 31, 36), chip = Color3.fromRGB(26, 21, 25), outline = Color3.fromRGB(56, 36, 42), text = Color3.fromRGB(255, 255, 255),
    mid = Color3.fromRGB(166, 160, 164), dim = Color3.fromRGB(140, 134, 139), faint = Color3.fromRGB(108, 102, 107), off = Color3.fromRGB(58, 50, 56),
    ok = Color3.fromRGB(46, 204, 113), warn = Color3.fromRGB(241, 196, 15), bad = Color3.fromRGB(235, 80, 70),
    accent = Color3.fromRGB(255, 36, 56), accent2 = Color3.fromRGB(165, 16, 31),
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
    "Nexrift FF2438 A5101F", "Nemesis 813DC3 5E2F9E", "Violet 9160FF 5E6AFF", "Ocean 28A0FF 3870FF", "Crimson FF4664 DC2650", "Emerald 2DD496 10AA78",
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
    user = "☺", send = "➤", smile = "☺", info = "ⓘ", palette = "◐", dot = "•", close = "✕", check = "✓", settings = "⚙", folder = "▤", list = "≡", play = "▶", eye = "◉",
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
    elseif name == "grid" then -- ikon dashboard: 4 kotak membulat dari Frame
        o = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size)}, parent)
        local parts, cs = {}, size * 0.42
        for i = 0, 3 do
            local f = new("Frame", {Position = UDim2.fromOffset((i % 2) * (size - cs), math.floor(i / 2) * (size - cs)), Size = UDim2.fromOffset(cs, cs), BackgroundColor3 = color, BorderSizePixel = 0}, o)
            corner(f, math.max(1, size * 0.14))
            parts[#parts + 1] = f
        end
        function ic.tint(c, t) for _, f in ipairs(parts) do play(f, {BackgroundColor3 = c}, t or 0.2) end end
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

-- NEXRIFT: logo "N" siku (2 batang + diagonal, warna ikut tema) dan teks huruf renggang (huruf X diberi warna aksen)
local NEX = {Name = "NEXRIFT", Tag = "PLAY SMARTER."}
local function hexOf(c) return string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
local function spaced(s, hi, hex)
    local out, used = {}, false
    for i = 1, #s do
        local c = s:sub(i, i)
        if hex and not used and c == hi then
            used = true
            out[#out + 1] = '<font color="#' .. hex .. '">' .. c .. '</font>'
        else
            out[#out + 1] = c
        end
    end
    return table.concat(out, " ")
end
local function nexN(parent, S, props)
    local box = new("Frame", {Name = "NexN", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromOffset(S, S)}, parent)
    for k, v in pairs(props or {}) do box[k] = v end
    local bw, bh = math.max(2, math.floor(S * 0.2 + 0.5)), S * 0.84
    local function bar(x, w, h, rot, key)
        local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, S / 2), Size = UDim2.fromOffset(w, h), Rotation = rot, BorderSizePixel = 0}, box)
        return skin(f, "BackgroundColor3", key)
    end
    bar(bw / 2, bw, bh, 0, "accent")
    bar(S - bw / 2, bw, bh, 0, "accent")
    bar(S / 2, bw, math.sqrt((S - bw) ^ 2 + bh ^ 2) - bw * 0.3, -math.deg(math.atan2(S - bw, bh)), "accentL")
    return box
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
    LOGONAME = string.upper(tostring(C.Title or C.Name or "NEXRIFT"))
    LOGOCHAR = LOGONAME:sub(1, 1)
    NEX.Name = string.upper(tostring(C.Brand or "NEXRIFT"))
    NEX.Tag = (C.Tagline == false) and "" or string.upper(tostring(C.Tagline or "Play Smarter."))
    LOGO = ""
    if type(C.Icons) == "table" then for k, v in pairs(C.Icons) do SORU.Icons[k] = tostring(v) end end
    if C.Logo then
        LOGO = tostring(C.Logo)
        if LOGO:match("^%d+$") then LOGO = "rbxassetid://" .. LOGO end
    elseif C.LogoUrl then
        local u = tostring(C.LogoUrl)
        LOGO = fetchImage(u, "logo_" .. #u .. "_" .. (u:sub(-14):gsub("%W", "")) .. ".png")
    end
    BANNER, BANNER2 = "", ""
    NEXBANNER = false
    if LOGO == "" and C.Banner ~= false then
        if C.Banner then
            BANNER = tostring(C.Banner)
            if BANNER:match("^%d+$") then BANNER = "rbxassetid://" .. BANNER end
        else
            if C.OldBanner then BANNER, BANNER2 = loadBanner() else NEXBANNER = true end
        end
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
    if F.NexSkin ~= true then F.NexSkin, F.UITheme = true, "Nexrift" persist() end -- sekali saja: pindah ke tema Nexrift
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
    skin(stroke(win, T.accent, 1.2, 0.5), "Color", "accent") -- bingkai merah tipis ala NEXRIFT
    local winG = new("UIGradient", {Rotation = 135}, win)
    local function paintWin()
        winG.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, T.bg:Lerp(T.accent, 0.1)), ColorSequenceKeypoint.new(0.6, T.bg), ColorSequenceKeypoint.new(1, T.bg)})
    end
    paintWin()
    themeFns[#themeFns + 1] = paintWin
    -- garis diagonal merah di pojok kanan atas (nuansa NEXRIFT), diletakkan di belakang semua konten
    for _, d in ipairs({{150, 2, 0.15, 118, 30}, {84, 1, 0.45, 84, 56}}) do
        local ln = new("Frame", {Name = "Slash", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -d[4], 0, d[5]), Size = UDim2.fromOffset(d[1], d[2]), Rotation = -48, BackgroundTransparency = d[3], BorderSizePixel = 0}, win)
        skin(ln, "BackgroundColor3", "accent")
        new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})}, ln)
    end
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
    for i, pad in ipairs((BANNER ~= "" or NEXBANNER) and {} or {5, 10, 15, 20}) do
        local base = 0.74 + i * 0.05
        local gl = new("Frame", {Name = "Glow" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(BX + BS / 2, BY + BS / 2),
            Size = UDim2.fromOffset(BS + pad, BS + pad), BackgroundTransparency = base, BorderSizePixel = 0, ZIndex = 1}, dragLogo)
        corner(gl, 11 + pad / 2)
        skin(gl, "BackgroundColor3", "accent")
        if not NOANIM then
            TweenService:Create(gl, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = math.min(1, base + 0.08)}):Play()
        end
    end

    local bgG, chG, bnT -- gradien badge & huruf, lapisan banner yang di-tint; dicat ulang saat tema berganti
    if NEXBANNER then
        -- banner NEXRIFT: kartu gelap berbingkai aksen | logo N | wordmark renggang (X berwarna aksen) + tagline | strip diagonal di kanan bawah
        local card = new("Frame", {Name = "NexBanner", Position = UDim2.fromOffset(9, 7), Size = UDim2.new(1, -18, 1, -14), BackgroundColor3 = WHITE, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2}, dragLogo)
        corner(card, 9)
        skin(stroke(card, T.accent, 1, 0.4), "Color", "accent")
        local cardG = new("UIGradient", {Rotation = 15}, card)
        for _, d in ipairs({{64, 9, 0.5, -10, 2}, {64, 2, 0.15, -24, 6}}) do
            local s = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, d[4], 1, d[5]), Size = UDim2.fromOffset(d[1], d[2]), Rotation = -50, BackgroundTransparency = d[3], BorderSizePixel = 0, ZIndex = 2}, card)
            skin(s, "BackgroundColor3", "accent")
        end
        nexN(card, 22, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), ZIndex = 3})
        new("Frame", {Name = "Divider", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 40, 0.5, 0), Size = UDim2.fromOffset(1, 24), BackgroundColor3 = WHITE, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 3}, card)
        local wm = text(card, {Name = "Wordmark", Position = UDim2.fromOffset(48, 5), Size = UDim2.new(1, -54, 0, 20), W = 4, TextSize = 12, TextScaled = true, RichText = true, TextTruncate = NOTRUNC, ZIndex = 3})
        new("UITextSizeConstraint", {MinTextSize = 6, MaxTextSize = 12}, wm)
        local tg = text(card, {Name = "Tagline", Position = UDim2.fromOffset(48, 26), Size = UDim2.new(1, -54, 0, 9), W = 2, TextSize = 6, TextScaled = true, TextColor3 = T.dim, Text = spaced(NEX.Tag), TextTruncate = NOTRUNC, ZIndex = 3})
        new("UITextSizeConstraint", {MinTextSize = 4, MaxTextSize = 7}, tg)
        local function paintNex()
            cardG.Color = ColorSequence.new(T.bg:Lerp(T.accent, 0.22), T.side)
            wm.Text = spaced(NEX.Name, "X", hexOf(T.accent:Lerp(WHITE, 0.06)))
        end
        paintNex()
        themeFns[#themeFns + 1] = paintNex
    elseif BANNER ~= "" then
        -- banner SORU HUB: ukuran & posisi disamakan dengan referensi (kiri 12, atas 6, 137x47). Lapisan bawah = bayangan (di-tint warna tema), lapisan atas = highlight putih + tulisan SORU
        local bp = {Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(137, 47), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit}
        bp.Name, bp.Image, bp.ZIndex = "Banner", BANNER, 2
        local bi = new("ImageLabel", bp, dragLogo)
        if BANNER2 ~= "" then
            bnT = bi
            bp.Name, bp.Image, bp.ZIndex = "BannerShine", BANNER2, 3
            new("ImageLabel", bp, dragLogo)
        end
    elseif LOGO ~= "" then
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
    nm.Visible = BANNER == "" and not NEXBANNER -- teks nama sudah ada di dalam banner

    -- garis pemisah tipis di bawah banner (nuansa ungu)
    local ll = new("Frame", {Name = "LogoLine", Position = UDim2.fromOffset(0, LOGO_H), Size = UDim2.new(0, SIDE_W - 1, 0, 1), BackgroundTransparency = 0.4, BorderSizePixel = 0}, win)

    local function paintBanner()
        if bnT then bnT.ImageColor3 = bannerTint(T.accent) end
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
    local launcher
    do
        local pB, pT, pS = "", "", ""
        local NEXPILL = (C.Pill ~= false) and not C.OldPill
        if C.Pill ~= false and not NEXPILL then pB, pT, pS = loadPill() end
        if NEXPILL then
            -- PILL NEXRIFT: kapsul hitam berhalo aksen | logo N | wordmark | bar sinyal | FPS live (semua digambar lewat kode)
            local PW, PH = 240, 36
            launcher = new("Frame", {Name = "Launcher", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(PW, PH), BackgroundColor3 = WHITE, BorderSizePixel = 0, Active = true, ZIndex = 90}, root)
            corner(launcher, "full")
            local bodyG = new("UIGradient", {Rotation = 90}, launcher)
            local halo = stroke(launcher, T.accent, 6, 0.88)
            local edge = stroke(launcher, WHITE, 1.4, 0)
            local edgeG = new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 0.1)})}, edge)
            nexN(launcher, 21, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), ZIndex = 91})
            for _, x in ipairs({46, 146, 189}) do
                new("Frame", {Name = "Divider", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, x, 0.5, 0), Size = UDim2.fromOffset(1, 16), BackgroundColor3 = WHITE, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 91}, launcher)
            end
            local wm = text(launcher, {Name = "Wordmark", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 54, 0.5, 0), Size = UDim2.fromOffset(86, 18), W = 4, TextSize = 11, TextScaled = true, RichText = true, TextTruncate = NOTRUNC, ZIndex = 91})
            new("UITextSizeConstraint", {MinTextSize = 6, MaxTextSize = 11}, wm)
            local sig = {}
            for i, h in ipairs({6, 10, 14, 18}) do
                sig[i] = new("Frame", {Name = "Sig" .. i, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 156 + (i - 1) * 7, 0.5, 9), Size = UDim2.fromOffset(4, h), BackgroundColor3 = T.off, BorderSizePixel = 0, ZIndex = 91}, launcher)
                corner(sig[i], "full")
            end
            local fpsL = text(launcher, {Name = "FPS", Text = "--", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 195, 0.5, 0), Size = UDim2.fromOffset(36, 18), W = 4, TextSize = 13, TextXAlignment = XC, TextYAlignment = YC, TextTruncate = NOTRUNC, ZIndex = 91})
            local curFps = 0
            local function paintSig()
                local lit = curFps >= 50 and 4 or (curFps >= 35 and 3 or (curFps >= 20 and 2 or 1))
                local col = curFps >= 35 and T.accent or (curFps >= 20 and T.warn or T.bad)
                for i, b in ipairs(sig) do b.BackgroundColor3 = (i <= lit) and col or T.off end
            end
            local function paintNexPill()
                bodyG.Color = ColorSequence.new(T.side:Lerp(T.accent, 0.2), T.side)
                halo.Color = T.accent
                edgeG.Color = ColorSequence.new(T.accent:Lerp(WHITE, 0.12), T.accent2)
                wm.Text = spaced(NEX.Name, "X", hexOf(T.accent:Lerp(WHITE, 0.06)))
                paintSig()
            end
            paintNexPill()
            themeFns[#themeFns + 1] = paintNexPill
            launcher.MouseEnter:Connect(function() play(halo, {Transparency = 0.7}, 0.2) play(edge, {Thickness = 2}, 0.2) end)
            launcher.MouseLeave:Connect(function() play(halo, {Transparency = 0.88}, 0.2) play(edge, {Thickness = 1.4}, 0.2) end)
            local frames, acc = 0, 0
            bind(RunService.Heartbeat, function(dt)
                frames = frames + 1
                acc = acc + dt
                if acc < 0.5 then return end
                curFps = math.floor(frames / acc + 0.5)
                frames, acc = 0, 0
                fpsL.Text = tostring(curFps)
                paintSig()
            end)
        elseif pB ~= "" then
            -- PILL SORU HUB (gambar): body + tint aksen + highlight. Bar sinyal & angka FPS live di atasnya (posisi = fraksi ukuran pill, diukur dari gambar referensi).
            local PH = PILL_H
            local PW = math.floor(PH * PILL_ASPECT + 0.5)
            launcher = new("Frame", {Name = "Launcher", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(PW, PH),
                BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 90}, root)
            local function lay(name, img, z)
                return new("ImageLabel", {Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
                    Image = img, ScaleType = Enum.ScaleType.Stretch, ZIndex = z}, launcher)
            end
            local lBody, lTint = lay("PillBody", pB, 90), lay("PillTint", pT, 91)
            lay("PillShine", pS, 92)

            -- bar sinyal: titik (warna status FPS) + 3 bar. {x, y, tinggi} dalam fraksi pill, lebar 0.0165
            local sig = {}
            for i, g in ipairs({{0.6182, 0.6162, 0.1351}, {0.6459, 0.5243, 0.2270}, {0.6719, 0.4162, 0.3351}, {0.6978, 0.2811, 0.4649}}) do
                sig[i] = new("Frame", {Name = "Sig" .. i, Position = UDim2.fromScale(g[1], g[2]), Size = UDim2.fromScale(0.0165, g[3]),
                    BackgroundColor3 = PILL_OFF, BorderSizePixel = 0, ZIndex = 93}, launcher)
                corner(sig[i], "full")
            end
            local fpsL = text(launcher, {Name = "FPS", Text = "--", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.7596, 0.512),
                Size = UDim2.fromScale(0.17, 0.6), W = 4, TextSize = math.floor(PH * 0.37 + 0.5), TextYAlignment = YC, TextTruncate = NOTRUNC, ZIndex = 93})

            local curFps, hov = 0, false
            local BLACK = Color3.new(0, 0, 0)
            local function pCols() -- tint pill (sama dengan banner), warna bar, warna angka: semua diturunkan dari aksen tema
                local tc = bannerTint(T.accent)
                local h, s = tc:ToHSV()
                return tc, Color3.fromHSV((h + 0.0083) % 1, s, 0.85), Color3.fromHSV((h + 0.0083) % 1, s, 0.76), Color3.fromHSV((h + 0.035) % 1, math.min(1, s * 0.69), 0.94)
            end
            local function paintSig()
                local _, b2, b3, nc = pCols()
                sig[1].BackgroundColor3 = curFps >= 35 and T.ok or (curFps >= 20 and T.warn or T.bad)
                sig[2].BackgroundColor3 = b2
                sig[3].BackgroundColor3 = b3
                sig[4].BackgroundColor3 = curFps >= 50 and b3 or PILL_OFF
                fpsL.TextColor3 = nc
            end
            local function paintPill()
                local tc = pCols()
                lBody.ImageColor3 = T.accent2:Lerp(BLACK, 0.82)
                lTint.ImageColor3 = hov and tc:Lerp(WHITE, 0.22) or tc
                paintSig()
            end
            paintPill()
            themeFns[#themeFns + 1] = paintPill
            launcher.MouseEnter:Connect(function() hov = true play(lTint, {ImageColor3 = (pCols()):Lerp(WHITE, 0.22)}, 0.2) end)
            launcher.MouseLeave:Connect(function() hov = false play(lTint, {ImageColor3 = (pCols())}, 0.2) end)

            local frames, acc = 0, 0
            bind(RunService.Heartbeat, function(dt)
                frames = frames + 1
                acc = acc + dt
                if acc < 0.5 then return end
                curFps = math.floor(frames / acc + 0.5)
                frames, acc = 0, 0
                fpsL.Text = tostring(curFps)
                paintSig()
            end)
        else
            launcher = new("Frame", {Name = "Launcher", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(0, 35), AutomaticSize = Enum.AutomaticSize.X,
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

        new("UIPadding", {PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 22)}, launcher)
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
        end
    end
    layoutLauncher = function()
        if not launchPos then launchPos = Vector2.new(virt.X / 2, 8) end
        local hw = math.max(40, math.floor(launcher.Size.X.Offset / 2)) -- setengah lebar pill (pill lama auto-size -> 40)
        launchPos = Vector2.new(math.clamp(launchPos.X, hw, math.max(hw, virt.X - hw)), math.clamp(launchPos.Y, 2, math.max(2, virt.Y - 30)))
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
    local GH, IH, IGAP, HGAP = 26, 26, 5, 4 -- tinggi header grup, tinggi item, jarak antar item, jarak header -> item
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
    local function pillCols() -- kaca gelap bernuansa aksen (kiri lebih merah, kanan hampir hitam)
        return T.bg:Lerp(T.accent, 0.3), T.bg:Lerp(T.accent2, 0.07)
    end
    local function paintItem(p, on, instant)
        p.on = on
        local function set(o, props, t)
            if instant then for k, v in pairs(props) do o[k] = v end else play(o, props, t or 0.22) end
        end
        set(p.pill, {BackgroundTransparency = on and 0 or 1})
        set(p.pillSt, {Transparency = on and 0.08 or 1})
        if p.dot then set(p.dot, {BackgroundTransparency = on and 0 or 1}) end
        set(p.item, {BackgroundTransparency = 1})
        set(p.label, {TextColor3 = on and T.text or T.faint})
        p.icon.tint(on and WHITE or T.faint, instant and 0 or 0.22)
        set(p.bar, {Size = UDim2.fromOffset(3, 0)}) -- garis kiri dimatikan, diganti bingkai + titik merah
        set(p.barGlow, {Size = UDim2.fromOffset(7, 0), BackgroundTransparency = 1})
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
            p.pillSt = skin(stroke(p.pill, T.accent, 1.2, 1), "Color", "accent")
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
            p.star = text(p.item, {Text = "★", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(12, 12), TextXAlignment = XC, TextSize = 9, TextTruncate = NOTRUNC, Visible = favs[key] == true})
            skin(p.star, "TextColor3", "accentL")
            p.dot = new("Frame", {Name = "Dot", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0), Size = UDim2.fromOffset(6, 6), BackgroundTransparency = 1, BorderSizePixel = 0}, p.item)
            corner(p.dot, "full")
            skin(p.dot, "BackgroundColor3", "accent")
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

            ---------------- BARIS 4b: Join Small Server (cari server game ini yang paling sepi + ping rendah) ----------------
            do
                local PAGES, MIN_FPS = 6, 55 -- PAGES = maks halaman server (x100) | MIN_FPS = fps server minimal, tanpa data fps dianggap lolos | ping dari API sengaja tidak dipakai (itu ping pemain lain, bukan ping kamu ke server itu)
                local TeleportService = game:GetService("TeleportService")
                local httpReq = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
                local tried, busy = {}, false -- tried = server yang sudah pernah dicoba, supaya klik berikutnya pindah ke kandidat lain

                local function httpGet(url)
                    local ok, body = pcall(function() return game:HttpGet(url) end)
                    if ok and type(body) == "string" and body ~= "" then return body end
                    if httpReq then
                        local ok2, res = pcall(httpReq, {Url = url, Method = "GET"})
                        if ok2 and type(res) == "table" and res.Body and (res.StatusCode or 200) == 200 then return res.Body end
                    end
                end

                local sr = rowF(46)
                local c = card(sr, UDim2.fromScale(1, 1))
                c.ClipsDescendants = true
                local cst = c:FindFirstChildOfClass("UIStroke")
                chip(c, "search", 12, 12)
                lb(c, "Join Small Server", 44, 7, UDim2.new(1, -90, 0, 16), nil, {W = 3, TextSize = 12})
                local status = lb(c, "Emptiest server with good FPS", 44, 24, UDim2.new(1, -90, 0, 12), nil, {W = 1, TextSize = 9, TextColor3 = T.faint})
                local goB = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = T.field, BorderSizePixel = 0}, c)
                corner(goB, "full")
                mkIcon(goB, "play", 8, T.mid, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
                local function setStatus(s, col) status.Text, status.TextColor3 = s, col or T.faint end

                -- ambil server Public game ini (urut paling sedikit pemain), pilih yang paling sepi dengan fps bagus; seri diacak supaya tiap klik dapat server berbeda
                local function findServer()
                    local base = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"):format(game.PlaceId)
                    local best, bestScore, cursor
                    for page = 1, PAGES do
                        setStatus(("Searching servers... (%d/%d)"):format(page, PAGES), T.mid)
                        local body = httpGet(base .. (cursor and ("&cursor=" .. cursor) or ""))
                        if not body then break end
                        local ok, res = pcall(function() return Http:JSONDecode(body) end)
                        if not (ok and type(res) == "table" and type(res.data) == "table") then break end
                        for _, s in ipairs(res.data) do
                            local pl, mx = tonumber(s.playing) or 0, tonumber(s.maxPlayers) or 0
                            if s.id ~= game.JobId and pl < mx and (tonumber(s.fps) or 60) >= MIN_FPS and not tried[s.id] then
                                local score = pl + math.random()
                                if not bestScore or score < bestScore then best, bestScore = s, score end
                            end
                        end
                        cursor = res.nextPageCursor
                        if best or type(cursor) ~= "string" then break end -- sudah ada yang lolos / halaman habis
                        task.wait(0.4) -- jeda kecil supaya tidak kena rate limit
                    end
                    return best
                end

                local function joinSmall()
                    if busy then return end
                    if game.PrivateServerId ~= "" then
                        setStatus("Private server, can't search", T.bad)
                        Window.Notify("Join Small Server", "This is a private server", T.bad, 3)
                        return
                    end
                    busy = true
                    task.spawn(function()
                        local best = findServer()
                        if not best then
                            busy = false
                            setStatus(("No server ≥%dfps found, tap to retry"):format(MIN_FPS), T.bad)
                            Window.Notify("Join Small Server", ("No server with ≥%d fps found"):format(MIN_FPS), T.bad, 3)
                            return
                        end
                        tried[best.id] = true
                        local fps = tonumber(best.fps)
                        local info = ("%d/%d players%s"):format(best.playing, best.maxPlayers, fps and (" · " .. math.floor(fps + 0.5) .. " fps") or "")
                        setStatus("Joining " .. info, T.ok)
                        Window.Notify("Join Small Server", info, T.ok, 3)
                        local ok, err = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LP) end)
                        if ok then
                            task.delay(10, function() busy = false end)
                        else
                            busy = false
                            setStatus("Teleport failed, tap to retry", T.bad)
                            Window.Notify("Join Small Server", tostring(err), T.bad, 4)
                        end
                    end)
                end
                bind(TeleportService.TeleportInitFailed, function(plr, _, msg)
                    if plr ~= LP or not busy then return end
                    busy = false
                    setStatus("Teleport failed: " .. tostring(msg), T.bad)
                end)

                local hit = new("TextButton", {Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2}, c)
                local hov = false
                local function rest()
                    play(c, {BackgroundColor3 = hov and T.hover or T.el}, 0.2)
                    if cst then play(cst, {Color = hov and T.accent or T.outline, Transparency = hov and 0.45 or 0.4}, 0.2) end
                end
                hit.MouseEnter:Connect(function() hov = true rest() end)
                hit.MouseLeave:Connect(function() hov = false rest() end)
                hit.MouseButton1Click:Connect(function()
                    ripple(c, 220)
                    joinSmall()
                end)
            end

            ---------------- BARIS 5: community (leaderboard / changelogs) ----------------
            local cm = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.el, BorderSizePixel = 0, LayoutOrder = nextO()}, root)
            corner(cm, 10)
            stroke(cm, T.outline, 1, 0.4)
            new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, cm)
            new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, cm)
            local hd = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1}, cm)
            chip(hd, "user", 0, 2)
            lb(hd, "Community", 30, 0, 100, 26, {W = 3, TextSize = 12})
            local tg = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(250, 24), BackgroundColor3 = T.field, BorderSizePixel = 0}, hd)
            corner(tg, 8)
            local function listF(o, vis) -- wadah daftar yang tingginya mengikuti isi
                local f = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = o, Visible = vis}, cm)
                new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
                return f
            end
            local views, tabs = {lb = listF(2, true), log = listF(3, false), chat = listF(4, false)}, {}
            local onShow = {}
            local showView
            local function mkTab(k, txt, x, w)
                local b = new("TextButton", {Position = UDim2.fromOffset(x, 2), Size = UDim2.fromOffset(w or 82, 20), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", BorderSizePixel = 0}, tg)
                skin(b, "BackgroundColor3", "accent")
                corner(b, 6)
                local st = skin(stroke(b, T.accent, 1, 1), "Color", "accent")
                local l = text(b, {Text = txt, Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 10, TextColor3 = T.mid, TextTruncate = NOTRUNC})
                tabs[k] = {b, l, st}
                b.MouseButton1Click:Connect(function() showView(k) end)
            end
            mkTab("lb", "Papan Peringkat", 2, 90)
            mkTab("log", "Changelogs", 94, 76)
            mkTab("chat", "Chatting", 172, 76)
            showView = function(k)
                for key, t in pairs(tabs) do
                    local on = key == k
                    play(t[1], {BackgroundTransparency = on and 0.78 or 1}, 0.15)
                    play(t[2], {TextColor3 = on and T.text or T.mid}, 0.15)
                    play(t[3], {Transparency = on and 0.45 or 1}, 0.15)
                    views[key].Visible = on
                end
                if onShow[k] then task.spawn(onShow[k]) end
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

            ---------------- CHAT (Firebase Realtime Database, tanpa batas karakter) ----------------
            -- Setup 1x: console.firebase.google.com > buat project > Build > Realtime Database > Create > Rules jadi
            --   { "rules": { ".read": true, ".write": true } }  lalu Publish. Copy URL database ke CHAT_URL / C.ChatUrl. Selesai.
            do
                local NAME = LP.DisplayName -- hanya display name. Mau username? ganti jadi LP.Name
                local base = (tostring(C.ChatUrl or CHAT_URL or ""):gsub("/+$", ""))
                local httpReq = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
                local cv = views.chat
                local msgCol = Color3.fromRGB(214, 214, 224)

                new("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 0.4, BorderSizePixel = 0, LayoutOrder = 1}, cv)
                local ch = new("Frame", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 2}, cv)
                lb(ch, "Global chat", 6, 0, 120, 14, {W = 2, TextSize = 9, TextColor3 = T.faint})
                local onl = text(ch, {Text = "0 online", Size = UDim2.new(1, -6, 1, 0), TextXAlignment = XR, W = 2, TextSize = 9, TextColor3 = T.faint, TextTruncate = NOTRUNC})

                local area = new("Frame", {Size = UDim2.new(1, 0, 0, 250), BackgroundColor3 = T.field, BackgroundTransparency = 0.55, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = 3}, cv)
                corner(area, 8)
                local scr = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, area)
                skin(scr, "ScrollBarImageColor3", "accent")
                new("UIListLayout", {Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder}, scr)
                new("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}, scr)
                local note = text(area, {Text = "", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), TextXAlignment = XC, TextWrapped = true, W = 1, TextSize = 10,
                    TextColor3 = T.faint, TextTruncate = NOTRUNC})

                -- input
                local tray = new("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, LayoutOrder = 4}, cv)
                new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center}, tray)
                local ibar = new("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.field, BorderSizePixel = 0, LayoutOrder = 5}, cv)
                corner(ibar, 8)
                local emo = new("TextButton", {Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", BorderSizePixel = 0}, ibar)
                mkIcon(emo, "smile", 16, T.mid, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
                local box = new("TextBox", {Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -86, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", PlaceholderText = "Message the community...",
                    PlaceholderColor3 = T.faint, TextColor3 = T.text, FontFace = FONT[1], TextSize = 11, TextXAlignment = XL, ClearTextOnFocus = false, ClipsDescendants = true}, ibar)
                local sendB = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.fromOffset(30, 26), AutoButtonColor = false, Text = "", BorderSizePixel = 0}, ibar)
                skin(sendB, "BackgroundColor3", "accent")
                corner(sendB, 8)
                mkIcon(sendB, "send", 13, WHITE, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
                for i, e in ipairs({"😀", "😂", "😍", "😎", "😭", "😡", "👍", "🔥", "❤️", "🙏"}) do
                    local b = new("TextButton", {Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T.field, AutoButtonColor = false, Text = e, FontFace = FONT[2], TextSize = 14, BorderSizePixel = 0, LayoutOrder = i}, tray)
                    corner(b, 7)
                    b.MouseButton1Click:Connect(function() box.Text = box.Text .. e end)
                end
                emo.MouseButton1Click:Connect(function() tray.Visible = not tray.Visible end)

                -- http ke Firebase (REST): hasilnya true, data  / nil kalau gagal
                local function fb(method, path, body)
                    if base == "" or not httpReq then return nil end
                    local ok, res = pcall(httpReq, {Url = base .. "/" .. path, Method = method, Headers = {["Content-Type"] = "application/json"}, Body = body ~= nil and Http:JSONEncode(body) or nil})
                    if not ok or type(res) ~= "table" then return nil end
                    local sc = tonumber(res.StatusCode) or 0
                    if sc < 200 or sc >= 300 then return nil end
                    local ok2, d = pcall(function() return Http:JSONDecode(res.Body) end)
                    return true, ok2 and d or nil
                end

                -- render pesan
                local msgs, seen, lastKey, busy, seq, onlineN = {}, {}, nil, false, 0, 0
                local function clock(ms) return os.date("%H:%M", math.floor((tonumber(ms) or 0) / 1000)) end
                local function chunks(s, n) -- potong teks super panjang jadi beberapa label (aman buat batas render Roblox), tidak ada pesan yang dipotong/dibuang
                    local out, i = {}, 1
                    while i <= #s do
                        local j = i + n
                        if j <= #s then while j > i and (s:byte(j) or 0) >= 0x80 and (s:byte(j) or 0) < 0xC0 do j = j - 1 end end
                        out[#out + 1] = s:sub(i, j - 1)
                        i = j
                    end
                    if #out == 0 then out[1] = "" end
                    return out
                end
                local function addRow(m, prev)
                    local me = m.u == LP.UserId
                    local cont = prev ~= nil and prev.u == m.u and (m.t - prev.t) < 300000
                    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.accent, BackgroundTransparency = me and 0.9 or 1, BorderSizePixel = 0, LayoutOrder = m.i}, scr)
                    if not cont then
                        local a = new("ImageLabel", {Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = T.outline, BorderSizePixel = 0,
                            Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60"):format(m.u)}, row)
                        corner(a, "full")
                    end
                    local body = new("Frame", {Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -58, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0}, row)
                    new("UIPadding", {PaddingTop = UDim.new(0, cont and 1 or 6), PaddingBottom = UDim.new(0, cont and 3 or 6)}, body)
                    new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, body)
                    if not cont then
                        local top = new("Frame", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 0}, body)
                        text(top, {Text = m.n, Size = UDim2.new(1, -44, 1, 0), W = 3, TextSize = 11, TextColor3 = me and T.accentL or T.text})
                        text(top, {Text = clock(m.t), Size = UDim2.fromScale(1, 1), TextXAlignment = XR, W = 1, TextSize = 9, TextColor3 = T.faint, TextTruncate = NOTRUNC})
                    end
                    for i, part in ipairs(chunks(m.m, 4000)) do
                        text(body, {Text = part, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
                            W = 1, TextSize = 11, TextColor3 = msgCol, TextTruncate = NOTRUNC, LayoutOrder = i})
                    end
                end
                local function toBottom()
                    task.wait() task.wait()
                    scr.CanvasPosition = Vector2.new(0, math.max(0, scr.AbsoluteCanvasSize.Y - scr.AbsoluteWindowSize.Y))
                end
                local function rebuild()
                    local y = scr.CanvasPosition
                    for _, c in ipairs(scr:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                    local old = msgs
                    msgs = {}
                    for _, m in ipairs(old) do addRow(m, msgs[#msgs]) msgs[#msgs + 1] = m end
                    task.defer(function() scr.CanvasPosition = y end)
                end
                local function refreshNote()
                    if base == "" then note.Text = "Chat belum aktif.\nIsi CHAT_URL / C.ChatUrl dengan URL Firebase Realtime Database kamu."
                    elseif not httpReq then note.Text = "Executor kamu tidak support request()."
                    elseif #msgs == 0 then note.Text = "Belum ada pesan. Jadi yang pertama!"
                    end
                    note.Visible = #msgs == 0
                end
                local function push(list) -- list sudah urut dari lama ke baru
                    local near = scr.CanvasPosition.Y + scr.AbsoluteWindowSize.Y >= scr.AbsoluteCanvasSize.Y - 30
                    for _, m in ipairs(list) do
                        seq = seq + 1
                        m.i = seq
                        addRow(m, msgs[#msgs])
                        msgs[#msgs + 1] = m
                    end
                    if #msgs > 300 then msgs = table.move(msgs, #msgs - 149, #msgs, 1, {}) rebuild() end
                    refreshNote()
                    if near then task.spawn(toBottom) end
                end
                local function setStatus(ok)
                    onl.TextColor3 = ok and T.faint or T.bad
                    onl.Text = ok and (onlineN .. " online") or "offline"
                end

                -- ambil pesan baru (cuma yang setelah key terakhir, jadi hemat kuota)
                local function poll()
                    if busy or base == "" or not httpReq then return end
                    busy = true
                    local path = lastKey and ('chat.json?orderBy=%22%24key%22&startAt=%22' .. Http:UrlEncode(lastKey) .. '%22') or 'chat.json?orderBy=%22%24key%22&limitToLast=50'
                    local ok, data = fb("GET", path)
                    busy = false
                    setStatus(ok)
                    if not ok then return end
                    local list = {}
                    if type(data) == "table" then
                        for k, v in pairs(data) do
                            if not seen[k] and type(v) == "table" and v.m ~= nil then
                                list[#list + 1] = {k = k, u = tonumber(v.u) or 0, n = tostring(v.n or "?"), m = tostring(v.m), t = tonumber(v.t) or 0}
                            end
                            seen[k] = true
                            if not lastKey or k > lastKey then lastKey = k end
                        end
                    end
                    table.sort(list, function(a, b) if a.t ~= b.t then return a.t < b.t end return a.k < b.k end)
                    if #list > 0 then push(list) else refreshNote() end
                end

                -- online counter: tiap pemain nulis "denyut" tiap 20 dtk, yang denyutnya < 50 dtk lalu dihitung online
                local function beat() fb("PUT", "presence/" .. LP.UserId .. ".json", {t = os.time()}) end
                local function countOn()
                    local ok, d = fb("GET", "presence.json")
                    if not (ok and type(d) == "table") then return end
                    local n, now = 0, os.time()
                    for _, v in pairs(d) do if type(v) == "table" and now - (tonumber(v.t) or 0) < 50 then n = n + 1 end end
                    onlineN = math.max(n, 1)
                    setStatus(true)
                end

                local function send()
                    local msg = box.Text
                    if not msg:find("%S") or base == "" or not httpReq then return end
                    box.Text = ""
                    task.spawn(function()
                        local ok = fb("POST", "chat.json", {u = LP.UserId, n = NAME, m = msg, t = {[".sv"] = "timestamp"}})
                        if ok then poll() else
                            setStatus(false)
                            if box.Text == "" then box.Text = msg end
                        end
                    end)
                end
                sendB.MouseButton1Click:Connect(send)
                box.FocusLost:Connect(function(enter) if enter then send() task.defer(function() box:CaptureFocus() end) end end)

                onShow.chat = function() task.spawn(countOn) poll() toBottom() end
                themeFns[#themeFns + 1] = rebuild
                refreshNote()
                if base ~= "" and httpReq then
                    task.spawn(function()
                        local n = 0
                        while gui.Parent do
                            if n % 20 == 0 then task.spawn(beat) end
                            if p.frame.Visible and cv.Visible then
                                if n % 2 == 0 then task.spawn(poll) end
                                if n % 10 == 0 then task.spawn(countOn) end
                            end
                            n = n + 1
                            task.wait(1)
                        end
                        fb("DELETE", "presence/" .. LP.UserId .. ".json")
                    end)
                end
            end

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

-- DATA BANNER (2 lapis PNG transparan 480x164, base64). Jangan diedit.
BANNER_B64 = [[
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
6HSNoca+AAAAAElFTkSuQmCC
]]
BANNER_B64S = [[
iVBORw0KGgoAAAANSUhEUgAAAeAAAACkCAYAAABPav1bAABmhElEQVR42u392bNcWZbeB/7WPsfd74wZAUQggBgQU0ZGzllVmcyayGINpEoUq0iaRNEomWmw/i/EF+lJJrN+6BeZTLJuNptqsrusSarEKrJYWVNW
ZlbOQwwZIwIIIAIIzHf06+fs1Q97bfi+B8f9+p0BxF5mjgu/1/2M+6xvfWsUVSVLlixZsmTJsr/i8iXIkiVLlixZMgBnyZIlS5YsGYCzZMmSJUuWLHsjZb4EWfZZpOV3OREhS5YsGYCztIJFBoiti7Pr55Jr6ZLf
x+vqgTq5xt5eWbJkyZIB+BMsGXi3L4WtL7H/i73KxvWtkp8YGFcjtpmBOUuWLI8Ow8tlSFl2ie2mwFskLFc2Mfyqxnc1AeL498iQJYNwlixZMgA/wOf0gDDX5nGMc2c/KMc86jzS/0sLm5UR360bIDuJx6XtM5El
R/f1erLtLFmyZHko5VFxQcuI9zoC+PYa8GSTY9MH/Fpq8n+XMNyywW7rxs824NxMqk3el8l+CzsWtX3mGH2WLFkyA95HkNUWYNMJwUQP+LhlC8d7EIAdQS7u1zOM47Yx20lBtc3gi9djEpAuGwZA/O4A6JPd0lmy
ZMkM+IFgbYwA5oME3zYmzIjjbYL0Xh63S66dSximNI53q0y2nOB+bOXcmoA/ZftwBsCFgXBmwlmyZMkAvAeiY5jtw3LMkxgQe+0adwnQC9BlY2lQzdbiq0UC5vH73t43t+MbwE+DcTfBVjcB+y4wb0x4JT/OWbJk
yQC8v8B2UOx2p8e8k+PfrltaWlhumQCfjlkn2sLM01hsfF/Z+3rMfdKW7UuDxTZZeNECwBXQSxjwWn6ks2TJkgF450xtUmB6FNyOk5zvTlhy2QDc+L5qME5pAbvCPucaoNsGxrrNe1Ylvy+Scy1bWHHzOwDT9tna
2HCWLFmyZADeA7b4KMpuGRrN2ltn97iTsNIIuuUYhjtg2KVqMIb96i6ff2pkRGbtGmDcXLsxMatjbFg3YfNZsmTJkgE4y57cTzEw6iSstx5xz4sE7NIWkN6Aer+zi7UBxhFIO2wsf0rPpUwYcZkw4SxZsmTJALwF
edBrZB80ifHcJtvtsrHEJ4JXkQBdZLcRbLXxtwfFKxCPZ80YrkvAtmp83m3BW7Db65a8drNkyfIwA/CjrMB227iIGcxdNrZ/7Nur7dr6BtMcNMD3QRRP6HwVDYlOy2ciOPfY/2zo1E2eAThLliwPLQA/yrJbytkl
TLDH0OU6jhnG7OI6eT2MgJEOdmiu4wiEcgDH1GkYClmyZMmSAfgRko7dry7DJhTNZhkxmcoZGKwnDDfNXn5YJY4ubHbnKhNjZL8B2LUYPVmyZMmSAfgRuD8RVKKLtZuw2Kj4ows6gm50L6/zaLlF+8k1aUu2GhwQ
A54CVvNyzZIlSwbgh1/S+O68AW/Maq7s1UlY4boBQARgeDTjkbGDV8GwpCrNgq4OgOUXBsDZ/ZwlS5YMwDuU2BNZEoBLS3T2WqYIjSWmGbpVXeOeaQK2q4QkpE9KA4rYGMSzsfRI7DpUB7BeotGUs/izZMmSAXgb
gFs0lOh+Jik5huVD08Z60zhvmjTVB+4ydEOvfoKUfhr3bg5/GBwQC3VszETPTUCyZMmSAXiMzBrQzQBzpjhXgdvGovrsX6ZwB1gADjFsqegSxl0ZsKwYyAw+YYyXxCjqmocgjX+nr+ipcPvksSjtnkXjKTcByZIl
SwbgFpYSFfkscISNsdU4U3ZgQLwfSrRjx3DIjIDp5BgrO6YY111kY4LVJ41hpS02IwAvJ3+PLvnY0Wu/ErFmbQ3BMF7fz2olS5YsGYDhMHDcGOZh4IQpzBvAR8AV4I4pb79P4DZtinvejmnWDIQBQ5fywI7rDgfn
Wn2QxCcsOHb/irHg+Pc+GxuN7Id0zItCYkClx5UlS5YsnygA7hngHgNOAy8CZ+xvt4APDICv2c/1fbzWc8Ap4KQBcASP6FJesdei/VwjuzSbgKcNgEtHE+6nZyDGfqPHIrYB7WQAzpIly14D8IPU/zZ2IzoMvAy8
YMx3xo7vOvBT4DUD3f2eGzsDPAE8RnB/zxrgLhFcqYv2/1X7f0ys8nmJ3uc9UDZmOxfGfvUAjqXZgCPWaq9nwylLliz7wYAPuvTiDPB8Am5njGF64CLwQ+BnBJfz4gEA7zGC6/tpY+SVGQQfAR8TEr/SBCsy8I40
sOYYTkYqjIEucTD1v9MM3c1lcpzTdh+X823LkiXLXgHwQYLuUQO2k8CngC8Y+HZN8V1IgPdd9r9B/7Qd4xPAs/bTAZftdcVA+C7ZXTnpWhNCTDz2XRa712nG+n4Zg7EzWTNbHTMSKnL4IEuWLHsEwAfFemN898vA
zwFP2vuusY5bwDvAXwHfB27uM0sTY70vA18y5rtmYHvBjIFrBhy5VnRrEqc8uWQtFGZc6T4bhW3u5wjCU7YGbuRbliVLlt0G4BR89wuIZ4CXgF8wZjlvrHLKlN5t4D3g28CrBnL7HeedB87bcT5p4HsL+J6x8dt8
smp390oi+60PAHhjGdQcw+EWZQsIFwbSq+RwQpYsWUYpFNWJdVcTbPcDfKeBz9rrFUJ8NzbNWDEFeNdA97vA6+x/HaYQEr7OA18kuJxvAz+x4/mA/Y89P/Lrlo2tQvdLpswA7DbWfhOE42jIG7Y+s2TJkmVHAJwq
P/aYBZfAOQPdXyJkNXfZGDMVQpLVXwLfBD48gOs3DTxlBsKn7HdvAm8YI/8kuCF3o+mFPgTnGFuELowB/dQtXRBCDTcZZmnnsEOWLFl2FYB3W44AXzXgfYrgfq5NicWMUyHEer8B/DkhOecgWO9nCbHeI4SM5h8B
PzDg3e71ifWlHYbxTt/4md4DN+J+aOM72vh/fEnjdxwwWEjjpz+AfZOAaOx2NWU/Jz2ekmE5UkzKWmHYMlMfMiMkS5YsDwAA7yUIPw98DfgK8Lgpr1sM47lTBk4/Af6EUNu73y6+HsHd/ArwaVOmPyLUGL/H9mPP
HYJ786S9HjO2FccQuoRdDRLF3rwHVfK5fvJek/+nLTdjLDO+JPnsevJd3wLaTbCWFlBpAntTPMPuYC45z1sMS3n2azhGLHGKTTVKhuVOMgZoJ2H46ZjIPsPWohXtAxwOItciS5YsDwgA7+dDP0twM/8aIbt5wRTw
7QRM4hi+Nwjx3m+yv2UepR3XUwa8hwnZzd8FLrG1geyxhOW0be+obe8owy5eCwzrXntsnAVMA1jjfaoTgI7dtdJ2jbFX8oChW3TQAgIu2W7dAGptAcR0rRQt7LtKvk/jWOP1iH25B2bI/Ni8CtIwAHaT7cZXkXge
usn79O+jWPIkYFw2WPWavVa5f5CEZoacJcsnQ8pNGO5+gPAc8J8Av0LIHJ5i2Bkqst54LO8CXzcGvN+uyXPALxMSwW4Cf0pwgy9tYTunDLy/wLAd5TGGU35cYmikIBWBMgW1CBhpTDy2aowzhVOwbp5PzNatkn0V
jftdtLBrEoZcsnE8YBs7rpP9tYGvNN5/AFy1a+z3CIAKhm0jZ5LzjJ6GOjm/rey3GvFMpb+vGTbxmE72FT0TKTP2Ldc0S5YsjzgA75e1/TTw1wku53PGym6z0eUc5/S+aeD75j6D7zzwGXu9TEj8+hbB/T0pAz9p
3/0CIVP6KcIUJGcsaDVhRDWjex2TAHGzA1M1BiybCrxt1GLdAlJtoM2I/Yx6P8n6i+Bzk1CydYG97dEdDZrafkbG22kw33oM6y23CMJr9vspQiw4uqF94mVIvRSbue6zZMnyiALwfrDfp4D/GPhtY8G3jU1G12hs
tNAl1PV+C/gO+zc8oSC4hV8BftH+/wOCa3RS8D1nxsWTDN3NC6aAbzJ0/VZsdEnSAoxVg1VuBQSrMWAx7jPaYLjN3zePpdpkjTX/XybM/45d2++y93F9n1zbQYP9xthvl40x6XLC56YJxE3mv8wwIWs9AeFxz16O
AWfJ8gkD4L1UAC8Q3M6/agwzMsCYNFQkSv4aId77V/sIvmJg+TU71tvAvzN2dnVCxvsiIUP6ywbE8fyWGQ5hWG0o980Y5k7+vxVwbvtdPcZDUo1hiv3k/PoJs46D7COrv8BkSXV7BUZpvDvup8Mw8a9gcldwc0JT
jLvH2G8zln5QHqgsWbI8oADMGKW6E2D7NPB3DdxmCIk2d7g/WzfGF18luJ5v7dM1OUzIxv4yIT77BqHc6QM2b/LRI3TC+qqd31n7/V2G833jJJ9BC1uaBAjH/V4aAFWyMY7cxq63A2iSAKdMsEaaMdApe5V2Td8n
xPWvTQiU+yGaMNSOeS7G1QC3PVue4WjJyHT9No8lS5Ysn0AA3s2H/0XgbwA/b2B13dhl3XJcpYHze4Qs472WWAb0AiHeO2XM+3sGnJu5nLsEd/XfIbTMPGkM9zqhLjiOHayS/ekOwHYSME4To2TM96Tx+yYoN9nv
VuK81Yh7Gw2Qjwmu5ws8uG0bB3bvlJCx32W8uz0mb62wMaySJUuWLBMD8G66+6YICUhfNQW2aKDUBIIOIUFplWG8da/FEeK0nyXEai8kwLs2ATB0Ce703zYGXJrRsGwAnM6vLSc0bNpYcTMOWzfAtg0wYXwP6mYW
Mw3AHhWT3q53JAJwZeD7ljHgPg92rHOd4XAPaVyLsnHP1NbOIvvfkzxLliyPEAPeDZkhJDLFCUFVAkplQ6FH9+QiYZzg+3t8bAuEbOzzBlTfNtZ9cwvn9hvAbxp7jtOPmsC7HbZYjWG5fgR4jkvQqsaA76THoo33
4xpUVC1G2BRD9+7bZmCt7IG3Za9kjWFddt04zzL5zN2HwKjIkiXLAwzAu6U4niO4nl80hhvnuLYxqajQ3mFv+zs7QgJYdDnHyUVXtnDehwku5980Bh1dzld3ifmMAu+6BXiboJi6nwcjti0tgDwJGDdd0rLJdkuG
3a5KuzYfm6fhzkP2zMTxh4eStVo2rseqXXNPruHNkiXLATLgBeDz9jrKsMXgKAYVm0O8RRhevxdSMJxgdJbQ4ONNA07dwrX7MsHtHMH3pm1jaQvXthrBFjcDXlpYb5oc1Qae0vL9SUGXln3piM9qgxWWhFKzBfv9
NUJy24cHuPZ3wkzXDIDjWo33MHbyWmNj8luWLFmyHAgAnydkPj/GsAFBBMG2GtLYAegKw17Auw2+jxEynacJLtC3tsFYXwZ+l1CutGig8lGynWrEtd5K2U8xQpG3JUi1geGofekIcN4KEG/2nTQhaY7gqu+YAfYa
wf1cH+Da1x1+d0CI/acyYFjnm4E3S5YsBwrAJcH9fNaUclROo9yUsfRohZAdvduMp2PHciJhqzcZn6TUJscIcd+XDVAi+K6OAJXNgGZcRvIoIBz1flRC1qja3WqLx7QZuDdBOMZ9hZAN/oaB7/JD/uzEjlWxPjjN
fK6yasmSJct2AXi3EkeOEHonz5tiWkvYQRsAxx7G19j9WbrTxnynDdzfZ5j8sxXpEFpKftmU8DWCq3yphV3JGBDWEdc5Zacy4p6MmqBTj3kvbK1j1rg1MMl2UvAtCUlJbxC6iX38CDw7fTu3GXvvbG2vZ/abJUuW
B4EBHyHERzsMu12Nq1stTKktEdy6uyVThISpLsG1fYvt15y+SBjKMG0M+vIW2XrZAo464nqkMtgiM05HRm5WxzuqDWXb32TC6z1FcD0Xdj8vAd8nxH0fBYBaNxCOQx00g2+WLFkeJAB+DHjCwOpmA4CjIi8ajK1k
dGxxqxJ7+ca5uld2COzzhCYbLxBcqB8wHJlXcv+A+/ScxiU8tSVPpdcnbr9Z7tJsY5lORIr7Tsfpxf13Wo6vjfG21SLXLQy/2Sd5zgweDHw/IsxM/ugRAqg6Adw6AWCf1UqWLFl2AsC7pSSPE7JFo8KqRjCsFGzW
DLCP7gIL7hJchOsGBCs7vFYvErK5FwiJWzHpqmT88PRRwFq3AHE6ASc2xOhtAgQ09j/KJVy1HA9j2HC1CbOWEetpzu5734yeNwm11Y8aOKW9nNfJyVdZsmR5gBiwMkyuagJQyubShKABoV70ODtrwhFn69YGvjvN
uD1k4PsMweUcy406iXHRmdCAkU0YMcl1i+Uto7piCaMzrOM5R8bbSd43a4glMVqq5BrGMhvH/eVPJOy5w8ZEuthH+V1C1vPgEX2GlOHwkEFWKVmyZHlQAHiF4KrtEWKCy4yvQY2g0CMkb31vm/uNbtd1htmqO0ks
myL0eX7etnGdYRZvlTDaagsehAEbB9qn92Qq+cyS7W+JjX2aqzGAMGgB2CZj1ZZrFn9fs7GZR9Vg2tICwOn7mmHc/1X2b4rVfkvFMBlrwMGWVWXJkuUhB+Ddbpv3IcFV+5mEyfW53yWribLvE9zGzxJirtt1Q7cN
nd+uHDYAPkpwqcZOV3UCvm0AVbB5LFsawDtlBsNVgos7Tou6ZYAWS1/a7pewceJO3fAIbDZiss39HbcZx+q5EdvQxmfj31a3aDTVPDxu3Iph3Hc9q5MsWbLsBIB3W/F9QGh08ayBWOqmk5Z9RnfxEUKDi5PbBGDd
5XM5RcjmFjMqYp/nlPGNUtCjrm/KGlP37RKhReP3DXzjHOFHXTq2RoTg4n9Yzjk238jsN0uWLDsC4N2WW4SmC3cJzS/aXK5tILVqbPNThJ7QByk9MyCOmqL9iGHNbwr0KRvsjFDUTbaXZi7HmuK3CEMoPviErcV1
u76HCcluM2Z8XGayOcEHId7uWz8DcJYsWXYDgGWX2fBlA61zBma9FnYT58PGCTNrBPfz84RSpqsHeI2espczZrbE/TW5bQlS5SYMvWqAdZz+9GMzXD6JssywxeNZe9206/KRrYMHDegiAOfyoyxZsuwIgHcbfCF0
tPqJschjBjx32NjEPgJRBKVY2nMO+Arwrw9IwRWEUYVnDRTvMkxIKsaw+M2kyZbFWN7rn2DwTZnwe2aQrBPyB75sHoE/IWTG3+LBAbwYVsnlR1myZNkxA2aXWfFt4A8JzSu+RqjxjT2hSZhvKgOCG/oYYYZwnBu7
33IEeNzY7w1C7LdKmM9mmcXjrmXBMPFqzZjetbwk78l14I+Bi4TmJ58H/iHDQQ4XCPH4gy792e18gyxZsnwCAXhU3+HdYMRXge8QSovOMGxcUY8AYWXYkOMp4JcMoK7s8/U5RXCBrxnrWmRj16oy+X8nYcOjxgs2
s6OnCe7Wqwdwbg+DDMwrsEhw/f814FeAz5pB9iNCzPxWvlRZsmR5mAFY94gBR/mGsck5Qhw4DkWoRhgDtSneI8AXDaT+gP2bojNvxsKMgf9txvdQHtWreRSwpOd7gxDjzNIuHwB/RMgK/wphxOXX7P78kBA3v8zW
R0pmyZIlywMBwDDanbobLraPgT9nWFN7yIAqNphIW1KmnZ1WgdPAzxlIfZv9Gff2JCFuDcOyo93eb+z8FV3uWUbLLeBb9vOXCXHhz9l9+jmCa/rP2Fn3tCxZsmQ5MABu6++7m/IT2+cJQkw49omOIKwtbHLJvnMe
+JsGhj/b4+viCAlgz5rCv8MwMWwShls2QLbk/szoKjnPLu29obNslDUDWm/X8qvmVXmS0CL0CUKo4zVCfDhLlixZHhoATtnubnfFivJTY8JCiO8eboBwClgp0E0R6kM/R3BH397D63Lajm2aEJtdZWsTmka5qqvG
tY+s+oiBx3t5SW4qAwPY2Gr0i3b9Zgkx4ucI4Y4/J7ilV/Ily5Ily8MCwPuhQP8VIZb7twglPnMGRLdbgBdCneUSIXb8awbGv8fuzgyOUtgxPW7bv8HWYotliyEzCqRj9nPPGP6a7W87bQ1d8mom1Lnk57g2ltry
PRrb9Al7Xzsg1l4TYr/X7Hh+keEQiTl7/xzwV8Cf2jXOkiVLlocGgPeytKImxOsE+PUWJrzWAlZ3CC7ro8Z0lJCYs9vZw6cJ7syC4O6+PYL5lhOy382Ycm0GxWFCydUdQr1x7PkcgdAnwOgb4B4n8sQJUGkf56Lx
XhrgmgKu0D6nuWLYY3rNXit2rMtmMFRsHNqwH3LF1tEsoUwpNjjpmkFTELLTf0CIDed+zVmyZHnoGPBeNOhYJdR5rhgIf8aYYOyHnLqi+8nvIJQG/ZaB1u+xu20bj5lBoIQ44tIuAO1mIByZ2wIhPl7YtYgAAhvd
8s2ktUnuXbnFY27Gq2PDCc8wcWyN4RzcdTNWYsx8aZ/W8E8JmeqHCJ3T4nmu2318HPi0AfVfkl3SWbJkecgAeK+Ss9ZNMd41hf1ZwhzguQbwriVAcMN+HiLE/wD+LaEedKdywhT2IYL7+TbD5Ktqk2tYTXg9U9d0
us1F29ccw4lImjBabQB23cJUJ7mv1Tb+lp5/PJ6eMc/0Xi4Tst3v2uuOXcO97lr1A0LZ2Iwx30FisM0RcgemzMD5EQffXzxLlixZJgKMqPz30iX9Q4adpr5KqO9cJ5QdDbh/ZnDFsEb4C3Yef0iYPbsTeYKQnV0R
Er36DGuSJwGt7bLieE5rdl5xOtKo6UnN/RRb9F7ULQZB+rdR20tBP05visc6ZWB3jODeXgUuERppXN3j9TMgxHtPEhLnHrdjWrTjmLJ7+5v284+BN8hZ51myZHnAAVgnUOi7IZeAf2MM6tcJZUBHTElGcEqzieOY
vnljOBDit99je52RyuQ4riXstxpzvttJYqt26TOT3tNqF/fR9IQUbBylOGX3Y6oBhMcNhG/uIegtAv/Oju9vEMITa3Yfl42xzxAmbE0Twhh/zt62styrSoIsWbI8AlL8k3/yTyZVJNIA4L1wSS8zLDHqmyI/wXBg
QUwGqo1l1QwHop8xBlQkTHIrys8bW/rIjIAVhnHW9eQz8eUa7yd9tQGhG2P4pOftJjyPcfubFBx0AoMrzYiOzUTWGLp/pw2QjzBMHlvZQ1BaJbi+FwhtRDsM49Mxfj1DqBs+Zt+5Sk7OypIlywGIqG5ZF+4VA27K
UUIT/l83ZhtZTprgUyXsqyBkvw6AdwkuydfZXnvCwkBj2l69BrtMf04S+43Xaq/Y37iM7Ga70XoCdtt0VzebhBQt66HtmCIbLu37N+zefLjH6+czwD8iuJtXGU7fSl3lU2Zs/Vvgm/aZzISzZMnPwQMNwPsps4SY
7FcIrsNTpkhjpu1y44aWCeDcIiTbfIuddUVaMNY0Y0q7yzAzeVLRTYyZg5K25LqqAbI1o2PRbUZAs7d3xwBvOmGcb7K3tbkzhBrzXzHj7TrDHuKagHBpx/MXBPf10kEqIRERrwr0EXpUFVx11zjqTuJ1hVmdwQu4
Ohy5j64p9dS6RMECl9y7cpLH6OqsUi+DDpDO4e095GvXZW3qKCu142iBisg9feEHIB07mXWQbvs51fqxFHJiov1rOG0EVG+ui3SusjY/yypCdzDHbKejHiQuWrfRvFQRkbqv0K1wOBRHX6EryFJ9l7lbK+qOn9IJ
HgqR+57da3KNLic5vCsK09eviyuOsMIpLvnXZcZN8SRP+z1cc6lxrbuwvbb1rFv43iT6cT/Ioezy/re0rQcdgFM2/AVCg4UXTZnfYmOdbhrTnLZHs0+oFX3NXjtp3OFMaR+xnzM7BN+6BbhKxk9T2qvGKaOYsTYW
VdsClwmZ+by9IMTZ3ya4i/dKzgL/gNAzesX21TQmemZgfURIzPqLPQbh5rWSlVcHOvNy50AeQr39hmgH3OyLe7r/tdXXxPULt6Kn9PCRQwc2x3n9/auuOPeYfLCKnpvefmb+laWfyeNzL+gero/tbjt665r1/EWy
3RUzRv0WjsMZGYoVEK7FYyYEb2NKikrTk0p7L4IYXluyZ3PS849VGN3GsSgb+yfEPKFodEQvacnG5kTKsIlRqvt8yzVJGxLR8p2aYR+HPQHgg3IjdIGXCU0ynjU2PEdwMS7ZjU8TajoM3Z+3CBnSbxLmyFY7PI5p
W5BxnGDP9rcfQyI2K4mqtgDY41zSbQ+CtDDkSYE4MuF5ezDestderqWvAb9B6Ip1qwH48TyiO/oywRX9vT1m57LhIX73Zoen5p5QLU9LpdMq6hB1uKAQxCMIoqB4r4gqhXgqr6AatlRCUTh8VcjAF4hDy0LibrRW
0bL6iSvK94Tyvuvt1wenfemeL5Qj1IOEY6odqzrwgjovUtSK1KafFAoQFZACXIkTh6rDeyicIOWa+vpndXHngquX1mvt0i1PbTSE7qwc06ni0yCziC8Q6SEUqFMV8YJ6vIITUAVfC86ZUvXBEVA4hzo7Z6949Yid
iIhDihXFvbvurl8c/PTSwJ35lNydXfSnO8eHinLxYk/L458FOSHqVb13lJ0C1xEtpQDxDAY/urV66+LhQytayNOTh5RuXit1+vArIKekViidqKNEtBBxrsZ5HK8VTt5LDEW/xXV1yghCCoCS6MOK0DPh1oRMOOr6
kpC0OM+wD3v69+gR/NBIkU+M7lOmK9rArDQCdY2tJUMWdjwLDPN0pPF8iR3LjWTfXUKe0Azjyzib+q/m/kFBbdcqjpm9ZmSvmkSZ7wvV3g0DllDv+QO7+J8mTFU6awx5mmEtbZo5XZqS/XkD77iNlR0cx7q5wKOF
F5toFGxs21js8Jzb4stbqeOtJgDt1HqUBJSbnbCkBbjHtdtsNvJI9x+TpGK2+V7JXxAysZ+x9XEnefDiOcWEsZPA37aH9Pf3wQ3tqmpwwp079CK4rwr6NUo5jeDAOUQEVaeFXVsRcPGCq0iJBoBRjxI8s64r2tN7
20cRhEIKdx1f/E9rXL44zZnhfbhxddbPHz9Hp/wbhfLrOJ5X6ZUiGpS/WedikIyIKCJhf8F8R+99ziEUiBMVxInzigj46zj+2FWH/j/F7euvysqSX6lvlncWz1anP1MA0+rnp14WL/8djsfN1LCkS1XBhfMrfDgO
cUJZOltyiqqGwyAANKKiTrVQtcM2EGZZ8F+f8of+pXxq9gc91xtUd7oujIPpC/TU906cENf7vyD8oopfC8+yOEVwSE+Fy9rt/PfHFm9fUu2J3ZmJQLg+Mnvc+fK/QeQXveo6SCFCieBU6Ti4IqL/I8j7DYW/FcO8
vM/A2/j8r7AxCXLSRMzIEMsRRrkYEVphY5e+GK5r7qdMtjXYBnGJBn0EdmnoysKOZ7UB/B07prRDYBvYtnn/mp+TEb8vTed83DBGdg2AdZcV0Xa2d9VO8GeEGPHnCA0Y5hNG3BzuAKHBxucMsF8HLrKzDNjKWNWy
WZXRpTllr3rEooXtDXYot/CdcoJ9NRmwjvlOc0HqFo47SrwnHfMgHLf71d9DsHvNwhdP2z1ZThScJoZaz0D487YufrKH7NevLukLvZnyP5EwWvFphEMKHVFUnSQuOwHDFw2AKiKSKNl7IKMRkO6pIC8lyBLKv5dK
354uhuBbL68cdfNHfksKfhf0eRE5qTAbNo0PgVAxmh22bNzSgSCqoII4VcTZAYaDdaoYJqqgs6j+uiALevjZf+n00reLa8vrJ+YGvPua8synQMQfx8nzICdR7YsiKs5LcNBF7A+bl/SfYIFoYLoqaiICGpA8WbZe
4O+AO97Rzv96c4VvHD0kPhx2L1gs3p3QQj6F4xzi+naJxamKHcbril7l+AsD1i6WOvWRF06Nvd/rN19z3aOfqotKntOCL+HkvGgYPaoKEgwXFdXvar96X6a6a9vQi2LP05S9HzSM6bgiPmbY22CUTm/rCd+z16BB
LOpkfzcapKZrx9Nv6KNUL0WvlG4RL6LHsamLYtloj2GOEA3DvzOCbafg3VZ6qmP0WjRwtKHfVtkk7HkQwxiaVtB2h6h7c6dcs4V1mZD1GtkwiXJPGdgsIaHrBCEO+Y59fydAXCcW18BYcc8WYIxVbAd82cH3qgnd
11t50HdifKU13LFO+DGGcfq9yhB/21zdLxBqg/uJxZwqor7dvycIuQaLFq7YbfG3b+jTC4f4HYf+VyqcRO8pjvAs3COe96JM936himhEhgjBjgTwnCoE4BItBH1Va/9vbvZXX+/35t2Jt39C57FnT7qp7t+icP8F
yiuB3qpHZIW4K/P26pCAq6qqUwGnqKCoiEoEYzQekH0tsPOAyaeB3wYZ6PTJN3svz3wIXp7Bqdb+MOI+ZQxrBXEDRUXEzkkS9LeTNx+AEfWhElYRD6rx17aNcFgqqOgJkN8SZHlhur4KxZt2GZWrt3v+6MJngRMC
K+JlYHsOSlm4pqpfxy1fgAX8UlkXU2MSuqqVwt++6brHP+VZ+WBOe499GeW0ql8WGKgKavFKUbntvf7JUm/pzQWObuc5i9n9Mw2gkIaOWuf+PvKbPeOlAVeX9nyQ+Cw148ouMQjadEGd6OZJwTcC5HxDp7bptEGL
IVFMsD/doW6LuFMY1oyNtx8UAM8kbovdcE3/mNAT+Lgx4ecItZ6zdqMWkwsUYxrHjRF/xgDgh6Zwd5oksmwvMUtowV69httjKzOFd0uqEcYDybHpJoZGyoaLbRoUS4kxdMwMoL0C4DXCmMcb9uBGo6+pnGLTjnlb
Qz9v73fTRa6X32Dh+JP8beB3VJkVuKsxVhkua0QO2ciZDRdFfQRIcwIzjNUKGjFQxYFeFeX3Vwr/3eML84Pqp2+VPPfCtC/L3xb4L53yvKKDAJ8iKM72d0/JSqBp95goYpgk0QUtQ+uAe3zZPNJeQD1OapQuynnK
6Xngw5i7ouqfF3G/DDotyED1HvtHAtHVxODQgKOJopRgbYhKdMkPf0T4DT8EdQNgCtGfc7hzwJv60cWOnDq7zsmFs+Llr6ljXqEO8B9c8SoIng/doP5zphZu1SDF8cdHPie3quuuLAcyN7MUnAa9Ywvqis+KMiNK
pcnSU1CveqOu5Y2F8uh22C8MyyUr2isbYn/9wTaApmukptMA9dS7uNZCYLqMzzGJobytPPexgkFoH9gjdjzLLV61mYSAFLtMbspNyOXI5LKDAOAYCL/b4iLYEbMwNnzNWM8zhOb8RxMLMXVTxPOft88cM9fjRWPT
O83QVVtgN2xbccBCjBmnbpydLohR93Ur26i3cF6weQLXuLU2SFw1+7EG3yMk4H3OQH+J9nh5tMhPGGN+dZcBmONn+Ey3x98yA3FNA9kTBK9KodBBkZBwZMCjhnoaIDGwvOCGFlTUi4gTSRibCL6P55t+3f+fszPd
m7z7bufjE309ITIlwi+LyBcUllGDp7A/D5SiWqqIhHh0JJxoYLmoV9SpKBq+4Jwhb9h5LRL+ZscbskxFOyDTvtROcQ+tV6dwU1/G6/M4qRUq1Avmhw/MU0tRy8ZyIIoPHmFVBI8S/MOiiqoLF008qA8ee7MgwjGo
QEdhQVRLRJBB4YBOTf2CuOILID0H6+HzzgvqVdXj6/e16l8RuhSrSzA9N/IeHyqP693F21RyzFf9RdcrZ54VeBoRr+g6Ki7GFPDUwE9xem1oxWxZOg2Fnz5TU/a8LW7TyO0m4bRqhN5tsrw43U1oz2GpkudNt6h3
4vGstujN2A+ibaRrJGNNl3i1CZCm4DlJV8GyEW4aa1DtNwBPmduRXWK/oyQC8WuErMBzxoqPM0zTjyCwaNfhtCneZ40Jv0YoT1nb4bFoshhiosIKwwSFKXPXdHYJfHfj+6O2GRtqjLMkU4NCWr7ffBD3Yx1+aAD8
ohk/1xMLuckYlpJ1+hlbC7tSmnT9CkcPHfNfQeRpFe2Laq2W6INqgcgyyiWUtaDO1CPUqloLYjQPUcUJhiuCiiAhF0sKHCKqBcKqd/yJ1nevOI6UvrNWnDz2dOnEvaIip0H6itYSXMgqqt5A4WNVrhufLlQkKDW1
WLT62gWGWAuoE2+qV50gx1Q4otFp7RyoOhQnIqU6XVU/0Ht9bVaYkq5+HmFaYA1VZ3HeEGBWvQ7uioJHuGdhqKiK4FH1qNbEhDFjzyp6BnhMzHIw17WlbbsB0PfIagHw5BPVyvLbnempp15E5IyKeFUfjQlVkULQ
DxH5jg4kZMdPz40FDbl4wR1e8/D8YV/dWJ3VI/JlUXkMwRsVjy72Uh2LhfLTwdLqJQ7PbmdZRd1Rt7idY7JSHB+6Ve9eLNtZHgEysdRzpcUgiCVCbS5aJcRo17Zxruk41rYk1TRBNI0Zz3H/UBuS3/UboN4GnNJi
nDQNhFSnxeM4UABOT+Swxdhe3WMAjhKn8nxorPgoIUPtaVOwHYbtE+MQhCOmgI8ZiF+y1+IuHVN0vaTJDdO2QGK8uBkbrzZxX5c7BNVJQbv5INUjQKwew8jLhAWvMYwH72X97RohX+CyeUbKxvpMa68rY72nCRn2
LxKy5usdrH8BvHjOFyVfRTiCSp+Y8BTcxwM8f6Ui/4t3g8tSe1cotS+ocdQy8PhaREpEUOcLJ9RQUKiWZYAlKhFfFKpa1OKQNb1WXr1VoQMnrjcQyucR+U1RTiB+NTpzBUuaUv0A1T/A+z+gdGuKK0V96aFUhwtY
r17QWmu8+hh2pVZkTl3x98QVv6nClCBesRxuoVBlUVXeQstlAK8rIuJeADkD95K2QsmTSoGoIu5bNfo/q+hiGZK/fMiw9mhVoYNapVTvg5tbxZcemKYo/x7wDxQWBColurIV8KvAm070ui2Dqtd7/BmBl1UoBR0g
ITkL9Q6kqyLvai3fdTPFRDpLDp/wev12IeB78zNHUD6HcAioRa3eNIS1uwKLCu9MH55dulutFAvlzFbXWS8B4OZzHdfzYJvrNxKEtcaz3FZdkZY7TTNMdKxHPBPVNth+1BW0GP91As51AxRjLk7d0EWSAOltwwpH
e6KpJEaANyybafEExv83M84PDICjcj5sSu32PoFvE/Su2Os9U8RPGSA3m2qs2CI6a0D9EqF94tv2/du7eF3icPtlu/kpGHeSRdaZ4H6NKzkaBbK72Va0rVmHbHJs0bCYZu9L2z6ye/+E7W+5RWmlD9GA0F/8MxaW
uLbD61JOzfE8Is+bgznEbyWwO1RvAf/eLV7/hjt0oh/vmEtUoetspCbxM0LwAxdJTwAHMCPOsy5u4bFaFh7D1+tPiOpnEZnHy5o4ClEtjDl7lB9S6b+QXu/VJu1o2v/S6Eou69fmlcN/U6GLx2sA5lgCJIhcUvge
9epNyjlWVjsLsz33NURPI7JulS56L/VKWVL0h7cu3/3LE08e9vdyvu3spSy47xoVwPVLhR55/IuWelUgYor+XkbZbTzf0qL+QGwDrnbPa8EzqA6AShCngkOcCwell+s1965bmPYsv1cwu0n978KsysJsZcbNOZCn
AujKQBSnTr0qIsI66Dve+Y8cJVNLhXJ4y8bdbOIiTgEgruf+NkN9kSAUI56T0vTqSoNtxnBffNZHGQbbdYf3xmCZp73+ttviQk879cUZ54zxEjTLlOJEOB1BlFYM5w4cgKOV9rQd4JvsT8OKUbJsDPxnZhSctXhc
TMqaTm6EEhKoPmeu6UumxD80hbxb5xEt1RVzzaStL2fsISuYvAVmNcJt0mmxGtN4bLVJrGOcq4oWMG+CchOIY0Z0dx8A+LoZXsqwU1o94pmI7U4ft/u+sAMAjtdhuujyWZRjOCpVYvWOolqgvIOvvsuhE32uftRj
zaNrM8rxqqYswBWgNczNBa/q2gCqSuh0lFvXBFlVf+pFLfw6uC63+Jkc4QXvzr80BFKtT6q4xxF1iAxQ7zQkfZUgd8D/1e3L33/9SHnO6ZljKjiQAvU1fr2QogQuXYHDXbRzW2XmDOo6IhTelwvnxBfPIpSIrqA4
cGZc+BLlijh+WPTmllm8U0xPzz6J42uKPiawHkK3WlscWgV5XbX/wxNPHvZ4JPSdTFSWB3WvCx87kWUVnVNH1UWmDh9FOYsLTRo0xqIRESgVFlG+71zvtsYMaMc54Cyq/cCytQiNRegQSh5fX5leXl5YmnMsKjKh
p1hv3prh0NzngBMIayFdLBQdCdpBuALyp3i5TAHdw73tuIijsS4tHq2S4YCSrT5bsZRGWlhv/Hk7cU+nvQQK7q/9T5+F1W24w+NxjHINp7XOvoE9vRYWn+qlVbbWCES4v7KFxvH1JzEy9gOAZ4z5HiHUVh4k+DZB
6rq93jRle85c04cMnFML5wghRvxpA+GfGiDfYXfrWD3DOubIDqcNBGLnrarhRhlXZ5xabq6xiNKYSlv25KRSj2J9jb+VDXZcJdbwXjd2WUus41in3VYGEY2Rvn1n2tbCjkIwF17Xp588z3lxKngGEmtXh3W2F3xR
v1sAPHaqzyY3Q6YTW+r0uaEV5Lq2WF9QzxvOLT8Nsz3PzQs9f/jMMyLltODXVb1DXG0GgCBcqeGt5avPcOTJ64XIqcGQ7RYUU3Z/nn7cTuo4yg2JQ6Wkdi/gOI9IH1Vv0dha1WpyRS+Jcg0B5g85p/48nvPOUSqy
rqoqof7YSail+pFb7PyUw+awbaoqB8JLyonwVMrFa46zJ732l0+Z18rfU7oSS7d0GuR21dEPOwBvvOs4c/wZelMvITKFyIqEYHttDUamgufLf3dG7vRlbt4z98zkd35u+ikovqrCgoT15EBry6orUN6rVP+sUxRX
t7m2YkvFaoTXK3YBHGxz250Wgz7tfBWnoKUF1022md642LlwmdHDX8aRuDR3pxzxrDWBfTZh6+ljVSYez+tbxKVDdp5rDV0HGxuM6CQXeS9F7GCf3GX37XbFNW5GlCUD4fdNMT9njP0Yw5hsmSyCx+28rhsIx1ri
3Z4tWydgfCexsFLA8iPYbps7pZkQUCYW64KdU5ks9FGgPClYViO+n/4+7de61zJI3GRt7qP0/2rKqyB07TrE1icm3UsCOf4Yn3UFZ0CWBT8IDPHetVzH1Secl5/X/uJNKVwRPMNekYEopUgduj6iKK70aOEpqZBa
ZVX7rCxe4djJDUktrnLS5y3X49PqD515TqR4GdEeykos9FXEo3JL4cde/aUzv3DCc0PdRB6Jm/0S3q517tRpKWY+o6LHUCrL2q5RVUFLVb2Iyg+gXsQVsrayONudnv20iCyo6hqCF2fJVx5R4boKby3fKW+sV99y
R2+dQk+Jyvy50Wvv7Ekrz+qeReQcIamrCoBqaz0kl73u1uq7TBeO7lThZ+a/Juq/AOKDu1lif95anSzh/c/c4uqr7vCZiV2mvn5bXHFeRYqXVHgFCK00Q+K6D8VUVODfLv3gA4rp7eqyuSSURQvAxA5W8y2eKdei
Q+LI01jDm267mYMSPWWpjplODNvUM5ay1+WG/tUJn6MpNtbxVi3PWb9F53Ubv9PEYIm61I9h1+kxxjKohRGGwCgWfmAAvGBxNMfOu07thpwwRXrXYoJN6dvr+8AbtqCO2jmcsIsfExOm7fdHzcCIY+8umdtqtwcN
rO/B9VtvgM4qwzGM220TVzTiJM1YcNkCdPvVoL9KjKTY+GKcYr1t1+M8odZ8uyMLZ4oOX0Y5Ko6VwAqDh/de+wqVV9SV/x3dgiE4O4+W5jwNPY0ts1dRvHipVaSvHb3I3Pxf6Mqdr7uZQx8Mn+7n615JvT6ojpSF
+3lUn0LxVmKk4r0XKFXkY1S/1S0GV8PtOeQnUYx65453T7/kvQ4eA/kMShmur2oANFXQAq8XWa7+Uo5MrQF0e50z4v15EVEVZ2xfRAMTL4F3UV6fO0etP1vo+MO1Ol8qm3RhW/f90x1XfBnRw4LU4YMhGG1r8V0v
/IWuLd5i+pjw+MIs6KcQeZKYDKchJVygwHMZ5bscnt9SgqArzqtfX31CpPMZ4JCgA4ktQ0O1dyHCh+p5Tz5eXeHxafjZm8ILz2/FCE07TdUjgCB67go2VjHoCC9ZCmh1wmRTT9YgCVcNWp799LPNlryxImSrxrY0
2H4zp0VGGPIlGyfkjeruN58cezkCfKsGoFcjtrnKcEDQgQJwQaj3PUYo5ehzsCJ2LMfNLb5gzLKNuaZu4BsGqDFZ62jyWrCbdyxhjc8xbJV5mxAvvsmDLxHgK2P4W3FH6wh3dFs2dLNZgN/HsEQsmZgd8QC1dc6J
GfHboSnDhhYiPfADDWUzoaGkdbxSZCDCFMpZRFJlpfcGACoCThC1pCYXfNfqPOLPUZQvipQv6Vr/n8tU7yfhK6FPFYU/JrifA44g0id2qwgpzAXoB6LyHZgO5STHJotFuqdfqlf0rXLan3sG0WdQqtCzgxBaVnWq
9BHeQ29fwdo2ipfzOH0alT6qFY7Ciqo6Iqyp8q74tUusvt+rTxWiq75yh86h/YvOy4q4uzOCF5W5rlLcgu5Z5YMrrvP4ua/g3C8gUihUQmjibH05Oqi+z/r6j8sjx0IryE7vvKiet+vRFx2291TVHt5fpvbfp9x6
S3cp9EmUzwPrgvZjD29UylCjzA9R/zPfWx9Ur951tx5b0ce2totOA+DSfIsUWGNyUto3ud7Ee1awcbJQW5/kJiFwDPNU0mOok+Pdaqy1uW0YXb/blnU8zehWwKmOKhpgXY4IS9WJ/tIR+uXOVs6x3GWAS90bC4SM
0765dg869jtvxxQXwxzDyUaxFKmtg4pnY0ekaYbNO04aWB2zbR8xgH/WFsPHhFjxz0Yw7gdRBmZ4zNFefF9MCDqjwLcZR1rfA9f9uIdtLXFBrTG+brnHMGlrZgf7Xa4G+lZ3Sn5eFGeu2Xvtr0KPC6kErawCNjSB
sm4T4YNCaDNxz3MY2yCHrlfCcS3k7yIsc+PyBY49sajUIpTaqXSBkmdsOtAgHENo92w1yO9pffeilIe3YK4tC91Zne6fOEIpX8LJFEJ/2DHEto1eRPzP5GivP1Smch6VEyqsh3ix8+GcVRS5Df5D8e5J7Tz9S0Wp
0zKF1/VV4KQ4KR1HcYKTUFR7IuzyiWemHfpFhdOoroeLp068iDopUb0B+mbx8eJHnJkCPxBRfRnhrKCr6HC9amjjVePkEtq5DMCVC8LjT03O3Cp9nA7nBD9QlQpwIeNLOygrwA+pVt9wC4d9efWCPHb8c1v1ApVs
TD5q9mlvlgANxniFxrlc02enSgC9mWQUk7baGGadhNPWtoErvYY7vMn2o3u82QpzuoWtjmLDFVvru5/GfFeNZG3ZY7hXDLhjQFQSYr9rBwwqYmBZEhJx+olLY9aUa6wDjvWpayNco7Hn83U7t58ZWD1GMPFPMGw9
OU/oO33EwHjZgPwGm8/kPEgmvMz93W/KEcBaMFlJwagxhrGUYT9EGw9b3XJOzRrh6Obr7GC//bs3+V6vJy+XPX0F6KqIF1UXumjcG6JwrwHlEMdCmnKcSGgNJ+J8otgduQZREaa0LH9Oj576osCfcPuKrsyX89PF
ifOiOoWypiK1Ki6M6ENQbuH1/ct3Lq09eXILANydDUfnOi8AL0q8piJFAHhKFSqQH1D7b8OR4BJe/fAo3RNPW6PJOnSW9iJeFLRG/WWV6ifAAq78XYRzKlKhWobviAMKjSMZQkNqjTFcERX1gf1aTVMoa/Lyda3r
P148c3NtgRPo+tJJytmXgY4iidGtKipdhet4+Qkd1njjbbf8lMjspKUzN69OsXDkaZBS77FEJcR/RUBvIvqmfvDhh/iykMc6Wy3JiVPX+i0MuM2Q3E6opm2fkVH3Gzo9eoqKxMBtliO6HRja3cbzWjaMkPWWY46x
7DW21u9g1Dz2coKw25avdbkHyk2MHT5BKPt4EJhfHAa/zsZxhc2bHBdJGl8ZxdA8w0YfVwmJWF3bz6yB7hkD/qcJ9aRpu8wLhLj4LQ5mvvJmLDha12nMdFTLzLbpKjXt5QupSyo2cd8vBlxM4FqvWlxRstMdP/6s
/OWNi+oWHnN/vyz0yyI6Z8ONrMOjNSbUe/TR3VMiobcj4lVBaoW+jSBMHz3RcB3PgzvPe+/8mXv6WT9drZwVJ7+gSgelT+wWHRiqB31dC96aubEqnJzMmBWbzEC9UkhRflpxp1R1DVUfXOjixKkDllH9nnS7bwL4
/t05cUd+CeRpJM4UDs9SGF6k63j9oRsM/kqde1aKskJlAZE4ecI83MMW1ZZEruakr9Xjg1NA6tCqUrt4/QiVr7tu9wcLvGAu4vIpRZ6Nz7ze61AlosgAeF3U/UjfeEuZcs4vP6kjRws0F//8zDMgL0uwjoKtgFOL
ca8ivOeVD4rnXvTcuCUcO7LVub8zpmvWG67mcc9pPcaLNa6KoTnJKPZaburPHsP2ks3naWq7AJW4n7VxnqlOWRmhz2kJNZVjnntJGHsx4u/a8vseoVJiyxUxe8GA5wi1tT0DpjsPAKCk/VAHjE4+SGMCU8n31oz1
Vmws5WkCcuz9fMPA9TUD46OEUqzjDJO2jhKagcQY84fsXretnUqsQV7a5EEdBXJtlnSVxGPiQl/ZR/YbQb/Dxkby47Iqq8SC3kkOgwD9Y2flL65f1OLQcaqiI09JEZoziY20J7RUDAszzAV0oR+zd/egVinAH7p3
jKpyrytGmDlQevXun736Br9yrtN7wp15UuEVhGlRtXpb8TZFYQXkO1rXb8w/e0y4dankyJPjS8KW7zi/9nZIhllZOaVTh56hkHnQRZth7G0WYIHIR3j/IUUR+larO0qn+OvA46LaV4aNmkMHLD6k1v/AzPwt/OBZ
RUqBgaKF1Qd7i5wPBzTGeRByrwl2intO4IpW9e+rX/9L6Szcu7cqxTOInEaoo88/eMG1g+OWIt+vqC93zp/y/vYq88e6kxvJbvoVxH3GWn+EjPKw6gtUP1R136ld9XEBcPSw3wYgdbg/QapODMya8TPA6xG6vzm+
sGoxSkcNUCi4v88yyTPfZ+vNNyR5ZtuSx+rEg7becp38GAO7DQtT4G1mRdcjcCN6BGK98ZaSzHYbgB0hHnrUgHf9AXGzLhNaEa6PAF4/4ualCTHNVP1x30+Z5G17XUhuUmTkhxlmU5+whXTX4gl32bsJQeMkHp9s
k5nWE7i24uLeyjiy3TIs0ozJaoSRkLL+2KVsu4akJC44f/ysfOv91/TqwnHp9abQrqCuVLRXiaMQcR7PADTMt6fyiBPV4DL2UD6Jyn8N+jgiK+ZK5l7vYq1vC/76P/qP/rZf0bUZVT4DctRGO7gwP0E9oVXVXa31
B0W3c3HAutB5ZlOmv+ZvMlU8ERb97MLzQvEssG4+8zg9qAyGpXyXQX2VTvTey2FEzglSqmqftHmDKnj9Tu2633Mry09Id+pzOHnMcsW9iKUn26xikmDzPQBQcSoKThTVRdS/psof1IP+n5Tzhz6+9yzf/nCW2ePP
ITKDOLvYNrBB1aF6HfXf9zc+vKkrS+qefUk3cwn4ix+IPPmE5/ZH0yycfBHhmCKLwUmuwaIK/bwuaK3fHpT+ZtdhwzW27LXsMSydaXv2uiP0lDT0WfRy+ZZntx7Blte4v+yp1wDYNMky7ZjlGwbuJM/O9BjwjmVQ
g5Zr1G2cS8qeldGNQmTE9Yr9rfsNoK4a4aotJZrtJgDHyUIn7QAXeXBinMu7vD2/ze/E+PHt5EGZN6/BrP0/1hhfM8W/xoRF3bvorp9mY7JSOYEFyZgYy6hxXcr+labNERqtdBOjqNrk+GPiR7wXOwnPxNfdc5+S
H218vosNes7R3dh5NtUEq2tr9Lr9UJsU5/SiAt6Y4Y/RwRu4Dl0vZ8XpS2Hi/L04ZzAIRNdRPlD0MsBU9RKU92XF3rfm/Efe89yU+vrmPHLoBeC0JTCpqobsaqVE/R0G/s/07voFmZlyevXjeY4ceQmVaYsNYyFv
r6gDqRDeLjusau2eAX0q1MpyFWFKkSlzKSPi4rRf7hk3KjdB71j4fIAvfqJ19a9lcfBqefzQ+hA93il6C2d+Ae9eDowdb9+pzd0/AL3g1vqv9U4/OdALF0YbJVUtevlNVy9/IFQ41m+rzi48BTyHMrC+0qHJJ96p
sIbythtU78x2e9tZ946Ntfva4rlxtlarBuC0AbBrgGI6u7xubD8a5M2QURzY0FZylPZ9H2wRfEnOc9DiWo/n2paR3EuMgmav6mhwLG9R93QYNmcalbi2ZTzdDQCOF7RrCu44w0Sjgy49etAldVnHxTvDsHH4fjPg
2Gu1aSFWE4AsEzLfZoed/Yr/zloYADMOlxrPQNMlXSbW904SCXUzC3v9DnQPDbTyDlcXOFHR8t44YIVaTPd4SjlrBtogKBIbrKOKoJUir+ma/0DmoKB4DpUnLSs4Tl5CRDqKLgv+R1osXYPDoU0FwPVbwvEjwvVr
jrkTXq9cRJ45dw+YZ557VgH1bubJQuWVAO4asp9DHnOc17tEwVvu1ELo+3546gSFflHEzShUiiLOBR+8isPpR6i/JCLi+0vX0fpf4d0UzoPKMSi+KiLPgFShvIowE0nCyF1UXwP/e1LLDZWC9Vo/rDrvXZs9/rzX
lXecLq+LO/GS76we6elU98vi9Dlz+YfsWZEqGA56F62+x+zVm/AM8lR75vNAF2V9+a1i5onjIst3xK851udcZ4qZLyI8BbKI14F1GatROqA3Wdcf1xfrO8VL2/YwdsewtwguMc+lv0U93mNjqWDKhMfNMU/jtG3s
cDtziNPzqcYAc9PlO6oVZmqE+G2QqIFdzznur6cm8Zxtabu7xYBjyvdRWyAfE7KEa7Js1X27yMHFghdsgUWLddSs4knd0MWINRenHy3v47kdS9zPy7RnO6YPbcwBuEMoo9uNWLW2ve8eCgZ2GdOu7oWE75GM4HT9
2Wtdefq586p0EFYIc/MKS4kuvZNlxV+i41a4dq3HocOnKWWB0BUq3I+A6B1EVr26d374+p/d+dL8845zLwbFcfxIYMjHT1K99YYrT8xqG2txvnsGkSdDk0dXW3KXWvJYX4QL2tXh0BVxJ1HOq4TkIQmDDmy0olQo
P/HIB6oqfPjGuzrDu9I9rb5T1rK2fpLOrFPKMwKlKF7lngdaUbqIzqhwWYryNQF6pdBbP1vw/qWC0/MwvxTYUmdqTryexEkHfD8kmaPiQ4Yb+Cuo/hSeGWlk1tffcoN6qZiZm3bycUfoiyueerHqav8oWrwMzKG6
SoxZa6j5otar1IN3i5dm/A70rDTWqSSsb7t9luP33QjginqgLb6ZxqDjZ5sDG7bD9qP7uU2PxLrdZe4f7ONo72ffNiZwq8fTvD7NhkODMS7/PQNgNdZ2zBRWjJkNyPKwSGxXd4iNIxphdMLFJMZVG4BLwv73qzzt
CKE2u2femTXGT4jqMaxpXDSDcrusex7wy3cp7t6iu7qqnULoTM1QlB1ct0SLHup6ouJQ8QFYOh0R1BeV+K7zrkAQd/7FI6r6ks3CXbfG/j4MQKAQ1bcGlbzd681U/mjnc4J8CqVGWLe5A7VNBHKgQuE//YWXfqsb
puvWtWVxxXkBFM8+L4hXrQeK98FtGaY39YTyc6jMIKwGQwBnKVVdxL3rK/02rC5LEZwdIuU5RY4Ca0ooUCZ0FplS+BjkuyLVR2u3bjvu9PtTpz+r9zzw07NXdLD8p0j5sgqfBUKvZhEvoalFDe4c+L9VV8vLRTn7
Pv2P3eBGh1vHj/rZuQ6z/mS9fvetojNz7kXQk6iuIm6AE2vU4RG0Viclzn2JtbXT8ckIZVsusLyiKNzR88WMqPOK6DRO5JTDexydYyryIkod7BzLFhdxoKvi5A1Ebu7gGW3O120mTEUA3k64KiZwNbtJ1QnbXG1h
m9MMy33aPF/9HRyPY+P0pDSJM/7OjzFS2pLRVtl6Qphj2IZ4eQQ4Vy0Gyqb99XcDgGPN74Kd2CLDZttZHg7pmfdiKgHfagxzq8a4VZvxpjY23GfzNpC7KacIpWBpfGxUAkZ0k8/bZy+wvfhv5703+I35ef0iyqAo
RGbn1M0doig7lIWj4wo6IiLOqSjqRFVUVETE4dUhuJKiUMGJqhOhBzKjsBYye0RCYhYOdB2RV/1dvejrfocT3c+i/iWESvTewN0Ish7VGfHy6zj5ZbAka41lPi70Q1YfGn+IKs55htnHHdBeGEkkAxunqMTMbfUX
q4ofrhSza4cB1m6d1HLuWZz0BF0LHmRfI85LSLK66cW/WjC94m68Vd569pCfivS2WhMpp5S+/Fin+A8i8jiqC6CD4RhhalSnReWXxE1dXOnrjZneieXO43AyKmgH3eJcB9ynVTkNunYvhuxVrAipxvvHofj7WjoD
NAs1i4QhEUiBauxPFi6bWiAA7Yhqicpa6DSmZsrQReQqTl/tT9V3ejtjv/0WApQC8nbZtef+ucFNMPEjQHvQ+Hz6zHeT981hMDLCQxSbOdVsrP9N48BuhP7oMszIHhU+W+f+BLVR3a1iWLDLxlycZib5Ohv75+sk
LvftALA0dhJroHoGvlc5+J7PWTa/hzHFv2duZ2f3L81ynNSI0gn+XjOM/W6nI852ZYaQm3DY9nm7xcAgsa6V4Yi39wiNVras1OqKMzNz+pXeDJ9zwqr1Y5LC4cSJOFERh7NuEiIhVijOiaiqCxo9QGfIYBZR9T4k
CVGHZKdYkKMKckmp36y5uKYLT/REOCFwSNE7ofIIL/fMItEwhMF3CclNsuE2qtf7lsu9Mh/xAffUA7W103QaQLCLyB117qL2V+9Mf/Su8MynqTsLn3Pw6Vg0Ze01PepFkWXgfS/9awUzvnPq2eqxzuy96y3llFIj
Mjez6n3/z0XLVxC+GOYkogE6EUEHipxE5CvdcvDeR28Nvn/qudkNCloH612mZs4AhxCWrE+19Yv21ohLQJkJtcfhWsVSXh86g0pyVe4lYkf/NbDOPfe4dZUWnArXVN1b7xa+f7a/Xsr6a/XM/Oe2QlKaAzKa3qVq
zDrdLPGpHAHuTRfzuL+NctlPjzjechPPWUV7EigJ0LUZBD4B7WLEtZhqAHmbDosJamm8ua3GuWyEr7ZEPHfCgNNi7TgxaI2QULT+AAJOnG1Zt7gIXGIFtsUT/BgQG/fAtG0rtbT8iH22bT/NVvRjFo9vWJHS8iBG
4J1imPAVM7SrCV3JjGGwRctCjHGbQQL0++V+fophF7Q1xmc/z9k1WSXEfi9vB/QvvsuvHjrCE8CSCrU4cc6KZEClRhCvIgFbxQUoFvO7hnsfmk7YernXTfjeuhIVb6PtbuP9H8ny6vfmjj+j9bJfV8/HCisBe6n1
XsJwxHOn6ty6cM9XGldNHJOIeZVtcqIMa1esdEZshqCoVIKWKnpdPN/E+79yR9b65dKc0xu35+TIwmcQedbioqCqIlqH5iD6Aeq/o7q0TDGDzM36ltUUaO7rb150zz77R3R7TwOPIfjQvzkM2AUqVF8qKX/p+NN8
SCg9HC7+eVcMRwOH6xjQVb0ZOgHK0RrrtBWLi+16x+Tt5IFyocOzOdrD9xANuWhewmzhK6A/0vXq6kvTC6wXH9PdGvimz3pbqVBMVlrfpoG8WfnZoGXbneR5rscA6Qr3N/SIjLGZrNWstqi5v891HKu60rLfOMFp
fRP91G0xTKSh49LxretjtlUxOht7TwE4jho8msQHKh7M9opTDKcyDVoWXVvRtTJ54wlhfLJS27baironTXqqJ3zIZMTiSpuy9xk2G+lvcZ/jPls0FEQn2ed+lVU5QovQBWO+d7h/lnLTFR+79nxAmGy1Zdfzpbf1
S3OH+IIrmfYwcNbAObgq41gFlVgEGia0x+7PXsIbjRRqo47Q2PtZnQodgRvi+WP169+QI/O3AYpZ5yutf4rKW8B5FbwExhrgTxKPs8GHpRXfY3MJvbNmGV7CQYdWUeaWRRSnAXZuiOqf6Orqv5X5ubdZWXYfnJjT
J7pzZ0XkRdtiLSoe8KrUqAiqb+qafK87f3JTo7378is1i2vf8135kii/iugUcZZ1aGlSg59S8V8tVC7y8Z3f58ShlUUuyDxP6WpVrE+V8irKFxA5irAkKKJqEwLViK/atApCTbGPF8WGW2jsBaoSW2KqIuoEZ3VN
ggSDU7iO5/9E6z+U4p078JLvlif8NvXtZoRoqx21pMFkJ22/mMZ+V5m8NHGzaop6E71TbMLIXQvJatvWdkJfbUZC1KnbDrluB4A1OdnZxH0ZD+RBdLcuMGzCMM34lHom+FubF2DcNtIMutSC3M6Nb3bjak4Xasu8
K0bEe9qaUeyWtD04OoaB7oU8S5hO1XR7t+0/hlLmCBn8P7VwylbX2tnuNL86Pc1ZlMo6IbnIvMQhDnViM42s/SHGZG1krMa2GtbVKd5Ts5tEamBV4KJHvkvp/7K43r2iR/tOemGSUbF051Wm5/93nPs1kJfVyYJ1
k7rHeSXCrYRe1NYqMfzWoaLqQpzVyn1UnH3UWXvICuE66q+h+h1fVX/s5ucuAnRmnvRPAlr3z4E7G9abuCS92+F9n8Hgh4t3yyuH5ie8vtcv3GXmuT9V586IymdDCRI+tLnwgqpXleM4+U1/bP6OvLf69enpE/XN
k8sc7c0uab/6OoWcRPjrKEdQKsXSpLBbYNdG0VBdHe6d3vutIASPviVji+WuO9FwPyvztlxR+Ca1/6N3OpcuP1e8tB3gTWt/0+5XqV6ILtLUIzZJWKhg2EKy2gJ7jp2tulvQn+WIz2zl9ykjH6dzJjEItrrfcoRL
fEfNpnbCgGPpUbo4tjSKaZ/kqLkh2wL5VeM1SjmX3J9gUE6wwNu2JxOy1mYRPIyeNATtGXc6xrqsJnhwdiNJL3oIYvJDf5+8JFPAM+Z+joX3/RFsIpZGxf7fF8z9vNXjXHj3Nf3qsdM8jVAprFtcEDUyq4pTkQLU
iajTMLggdpXw91RniAyHUh3u1QTXIKLCVad8U339vTW5c2H9hx8sHz7edVKcVQgALPNHl/zrl/+9vHDqKuh/ivJFA02xJCIljEDwauxYrF1WnMMUyPE9dzPG+GSYbKUfqPANvP+u1Mvvu6nDtwD8ypK4mTnVxRsL
TM0+RaEhv0DE26r0gnTU6TWce/vQE91Jr7Nw9ny9vlL9qDPXeRrkKUGttah41dhkBIdyHpGv6rnu26Ur3j0aN9Arr7C6/P/WXncVdb8dAEg0ZDpHJ4MLyWrO2puYNyA22rT4vN2Ve4OtQH34tfcfKcU3tM+3tFdd
6Lvq7uzlo8EHtz3C0xmjo8rEozRR4k+LJ2w7zLrJmEcNMWj7e3MyWj2BHtIEfNswptMCwpPg3rhypWqT67K2U09euYPvzTAs1Yj9MLc773GvZNrAN9a23mJYNyaJJbcV1jvq+ukIgK23ec0nPZa2Juv1Nh7y7RxD
OYHlGF1dMUyxH/kBzsD3lL2/wbDzVfPBivW+sXPOJeB1tt5EJqTBTvHO4i36IaNKpSjwIlAIFJ3gfi56qhI4pBMRSodqiToBFyppFUVUcE5iOpBXvHgV8Xh/p/b6etEpL89yjNkvHJM2ReleeqLWuv9TpPwXKvJt
RIvQ0UNcyMOiUvCidejAiA0WcuLCChK0RsWFblFhHKImAOwX0fU311ZXLuuF2+uzz+PoHfZuZk4BKnd3UDD9Xanry+qdl1IK8AXgQiuN4nbV7VzZwpgpv7Z2xS3f6Swfnjv5LZRV9eqc4Kmr0FirCJv3Std5f3td
+ks915gkOT17Rdb8H2iXj4Bp8d7hXDA2RGtFQzaxVyLQWl6V+eCD0eRRhzgV9YpXpcDj8FR+0Q2qnzEzdQk6WtJh9sx2xknfe3ZkDDGo2FiHS0O/bfb8ppnGxQi2OQogq8S7NQkIN4Gt2OK1GEdaNpt2VCbHm9Y2
FxMaADSI0a5UcGxIp98isD3JsPSoa9bA2/Z+K+3G9kp6hP7Kh+z9GqGec22Tm9k2bm8v3ePNfdUTguMoMI7bmJSh75aManDeSa7/foUongdeIUzkWjJX8igFdtgMyY597ttsPfabNo6UhFm0hQWa7kFdexfuPnWd
8v1KpiqVmecWqQcwqAqZ4klYXKMa3NRi0MefLrXoPcvW2bl107r1vqz1T9A99TFQI9WA5VJxXrm9WstRV4ufnpXOtZ52VkqtqymK+rby3JOKK9NgtHh9z9UD9dWliuleTzjzlN9kXTneuSR6uJKVY1MUg2N0vNfV
Qenn5sqtrccKWalwN5fhzPQF6K+jrqsyN6/vvvcGz5z/a9pf/HHRm//MKEUpd2ukXFyRmbtX0WOnkdk74G8qrgf+DIN33qUTxkEoZ3uCHILeLeCsVNpB5QNZ7U8z03da6sBz6KQCvLX8fXlu9gu78XxFL2NKFJpg
53bAxOYYzvYtRuij6LEat/0uuzAxbBMvGomh0TQ2phj2ad4riaA7KmF3XwH4EPCSHdAte78EvMtwlN1BAnBp4Hs0Uf6x/eBmrG4/AXg7Uo8B64L2utu65TPFGAa93eNpuoBjpmTsWLMfdb+Hga8R4r9KSKa6PcJi
nrO1W9o6focQ+90KS5c9NmyyfPIk6s+iASyu4T5Omd12AGEq+a7j/twSGobjqGN1Lc+BbPGZcJucgx/x/3Fexe16BHfikdwxa5nUcpo2UIu1V2kfTD3gxXuc0EhhFPjWm9ywcQBTT3Bj9wq06zGGwiR/T39f72Df
k6yrtBH7fjXdOAy8TIj7KmEW9W3aE1fiVBkh5C78gDBCcqsuch3hNmz+LQNzlq2sqQjCKbttA6idhPz6LdsWxvcvbzvWnT7bozKXdQKDNwVH2QFoyoTP94ECcNrAIc3qVfZ3rNy445sixKc7tniX7DWJe6LeAfjt
F5Mu2Dswq7dpOTYL7GPJUWxFtx9JV9PA5435FsZobzeMrliONW3Md8o+8wYbx1XulhLNoJtlr9eP7nAf2/3dbp/rbnxW9+kYDgyA4zDomJUXmY3fR0U7TroEt3OaMr7I7scGNgPBrbp16wkY+HaY6G4A8VZ6Ppds
HDUYW07utcwa8z1vxtfHhMSr5RHem2NsdDu/vYtrJINulixZ9gSAIbjtptnYaLttLNR+izNWM5e4H+6yN4H5egefHccuH7TpUVt1O6eupHqfwHfewPezxmgXCS7l1ZbjO0RwU3cMfN8w8N3tzP2tZqNmyZIlA/Cm
EifF9Li/7uygXdBzhKxsEub7IDYGqR/RddSc8bsfs6CngBcIJUdTBqpXuT/mXBLyAqJx9jGhx/Pb+3A/MvhmyZJlVwDYMcxubdaOHVS2cJxWcZhh0sIqIba3mXIdlUXclnD1MMhOM5q3s34KhtnOSoi374eRcZQQ
732G4JGJbufbjeObSpjvIqHBxvv22b06zsx6s2TJsmcAHN2LsQ2iMxC8y/7HgTsM3YqVgW8Ege1m+rYlXD1soLzZcY+a87uVtdNLmK/S3iB9L+QEwzrfGWO+d+y+N8H3mB3jIqG+9037fGa9WbJkeagAOGaQwjA9
PoLwFJvXcu22dA18u4nii+7P3QaCzUB5J2C2l7XHW8nenoRBl8nPmOkck/D2o8vVSeBTBr4xlnuDjfHmKYK7Obqc3ydkOd8yIN4vaU5bycCcJUuWHQHwLPdPDorsWPbx2GPS1dEECO7aa7/irPU2/7YdQB4F8ntZ
ktQsLyrYOEQiekFGtcrbbTB7jlDje8zeXzfwTet758woK42Rf0QYKXhlH8G2+fssWbJk2TEAx24pTXa0xtDlN2B8q8fdUnYx6Soq/8V9Bt/9lFHu47061+YowfgzXS/7lWiF3eezhDKjo7bftMlGh2FP57gGFw10
3+H+jOi9EN3i77NkyZIBeMsSm3BEIIw1t45QErJK+6zV3ZQ5hvW+adJV/xG+V/vBgIsWsC2Tv8VuZzsawbVFOWnM91yyvj5ugG/P1sQUIQ78oYHv4iO+JrJkyfIJAuA4ccWzcaxf7Fma1gLvheUfy6AWbH+x2cbA
juEI42O1UfbaXbpboDjJNSx26bjKEf+P5Wbxu/19YnWFge6TBsIx3nudYbLVfMJ6V4Gb9rpEcD8ftHxS2e+kHrAcF8+SAXiLCiWdSZmOoesk7Ljew+M9ZQAcWwtWBsbdEQ94G0BVLT8nvRbFGBCvd6BQdjIFadJt
d2ifG9x2XarGcfh9XJOnCHW7Jwnx3NpY7XLCeucS78sdY8Xv22cOuhf5Jxl4pfHeb8FAkWzEZMkAPF6RD9iYiBOV+6qB4AzB9bfbCrswxnOY4RBqSYA4lUHj4ZXkfKvk+KOyLLdxzTrcP5C6mJAVtJUylZsYLttR
VvWE91kT0FUOrqVoQUiyesGMLMewl/cSwySrKfv8OiHB6qoB71513poUVDOjC2unQ8hUf8k8GB3TD6vJvYw5G3fsdZf9idVnyfLQAnDs/9zh/i5YSwT38CEDwN12AcZEm+UEXCJo+BZmGoGuycjrEWBVtPx+Eibv
NmGyTbCMvbNdY99bifFuZXJHui9h46QVGtdoL70Xm93bw8Z6zxNCCXF+8G07phR4b5vCXia4pO/u8fHpLn/uUZN0RupJ4FeArwBfNWMqhqfW7Z7dtPt2xbwWF4D3zJhaYRjmigZ/Zd+tuH/aVGbIWR5el9EW5wH3
CAkxh+xhWWsBnhl7yG7tsjKPU5ji4Oj4kKagQguDi+/zg/rgGoFPEuK9cwwHjPfZWF40lXhaLtn6W38QnqFPOPimz+Mx4B8Cfw84wzAnpEdImlxIvtdP9MTdhAXH/JK+AfVlQib7q4R54/2W6+/yM57lk8CAI9td
HfEgRiCetvc3GbqDm4pqq+46fUAUbpbdkRljuidMOU/bWonlTZoYXZ4QA/7YlPYquz9AIQPv9r0Dah6M3zAAPkGYr/w9A9bHzMg6QegjELuoTRk7PkEoMyvs94Ux4QjAF4xJv2rGVz8B6tv2uSxZHnkA9vZgFGO+
GxOa5g2M7zaUZW5M8An3uhjTPU2I9x4yw2qRYdggdY/fZTjh6PY+At5mAJvZ1kYAPkNwPT8NfB/4V8B3DSxLM7C6yWvKQPkZhoMy0nKyWWPM54EXgd+0+79ICHetGnv+LvAHBs5ZsjzyAHybYenHEu0ZxNF9eMwe
qGv2wGhmDp9omSJkOJ805VqyMbM5ysDW2TVTsqvsfWKYbAKubfHzzISHchj4onk1Lhsg3kiu123uL118E/gmw57iBcNue48b6z1nxtoRM+oP2bpxtr1P25r6p8CP8yOW5VEGYDWFucLQldRMcEpd0d4eHAguxAE5
ceKTCLpRwR43pjTDsI1l7Cm9zrCH9xLD6Ub7lRQ2DlRljPcmr+XhfZ5n6BpetHvX1tSF5D5HIz56PqJOmQH+0gy12PXuCMMmPEcI07A+B/yurZ+aMGayyrcjy6MKwDXDGN1cY7E3s3YX7e9TpnhXGGavZnn0ZYYQ
23vMlHOH4H4cEFyScYThDUIp0fVkzRxEOdRmeQoZbMdLjM1Hd3Ks0R8lMYGrbOgRMR1z1dh0DHlF497ZWvo5Wy+/CPyOfeefEjKqs2R55AA4yoo9bNMtD0+qpGKSRCxPilmusY53/SGzVmVCBrUTpf+wS8fu9Ywx
lZN23zuN9bbEMK67Yj+XDvg6aGa325Y47vGMGVwn7X1TqmTd1yP+1tRRqVetSnTQD+z9TeDXCHHi7wMXeTR7wmfJAAwE9+FNwki4eWO1/TFWbt9YTs9e0VV1074b2c6D+NCkA+dTRhQHUygbS53S7j9tCtwl29FE
8QwecoXftft61NbFMTaOp4ylRUuJJ+RjA+EHxbjKCVfbl6sGiF8khBqeAH7K5EmX1Zh7MKoW/jrw52bgfda8LS8Df2EGXW6MkuWRBOCakBwzR4jFrI8A4LrxgMX6vh4hhnyCYYx4heFoufqAHpw46cklYBqzNssx
1nybmzKNG8bkkyLZRz9hfPoQK4vphO2esp+H7HxW7F7G9fExofnC7QPwfGx2fR/me3CQogkAv2v3+xDDmt+YF1JtYVub3cf4PNXGtp8xPbLAMLmPfD+zPKoAHMHnlinfeXu/THubRVqAuDLlPcUwNtix78dXrAmN
DHGnMcEUYMuEjQobRy1KiyHRZ/xwe00Yc5lsRxJA7yfnVjG6K9fDsG6mzZA6YYxn1u6hMmwreN28HH02dkI6CE/HpNc4K+3tGTexqUZM0Fyw9bHSMEh3om9ictbzxnaPEhKxvkrIlL5GqBnuZ89FlkcdgDFFO0WI
90TWc4fJxhH27eGMWZKxtGnGvhtjxHH8XQStpnvXjwBaEoBNQTUmcBTJ3+uGcaDJz9gApNoEOHoJ+Ja2j+Y5+MY5PIzrZYbgXj5p4NtLrt2KnfOqrY1b9npYRgJmhb0z70KM5R82kHwceGMCPbMZO56xtXaaUDv8
ReALtp9ZW4NrwJ8C3zJjIBtSWR55AI51wWJK+aj9f3ETdpey5Ah6a41jKhtsSzY55rQeeTABA29jof0JgDY9/gi4vYTtFglo9xPW+zC3ypuzezBt9/iYGVwxg3nJ7t+KnfeqrYGHPa6dZXI9gN3z9wmJWC/Zz7cY
P7d6M/B9CvhrwOftdSwx1L3t89uEkqVvENzgPt+SLJ8EAMYU78f2/xgDjA9j1QJcbf9vMuNmTeYSw0SoqU3ANR2ZqGzMnNQW4K3HHGPRYjD0EoZbNpTQuoFQWkbzsCoDx3D28hN2X6OXYp3gWr5CcDOvM2yav5/l
Q6MyyDP7ORi5Qejb/EWGmdAzYwziSeLCZ4H/2BivJ4Q5bhISvD4wwP0OIfv5KrkGOMsnDIDjg3THQOoQISZcJiA8CatMwU8aD2j6/aURINk8nmICsIfxk4jiz24C/unklxinlgTY1x5i5T/FsNnBlN3LWTM2Yljg
OsPRcrEt4F716B4HpHtREpbBe2dyHXidEH6IHc96I9bHpHkArwN/ZUAcc00uAP83Qtb1IsEL18/3LcujDMCbKaaVBGxjve+s/V4T9lm37HeSh7Ea8/tiQlCdFJDTWG78vzSANyYWxYzth7meNzZDOEyIsy0w7Ndb
AW8bu0hj2JoYIAclOgETbn5OJ9xmlq3LTWPAy7Z+HrOfVbKWtirXgH9uht4/MlDvGrBfJ+QYxHyOPBEpyyMLwJMs7HWCO/o2ITM2xmqmGHbJWW8AYbEFsB31nUlituMAt9cCRvGcfcOIiHW+g8Z2H7YHXwxwY4u/
GYbdi9LsZdjbYfe7BYbK/f2cdULGnGV31pM3Q23Znqvjxlp34hoWQlz5X9s2f4cQF/7HhHjwvzHQz/c3yyMNwJNKZLlX7eGLI8dmTCGmpUVNcKwmBM/NXNBtINv8bJodnXbb0YTlrTeA9mFiuU22VzIs9eowzGae
TtjJsjGNmwTX3oPcMlQnULrpNcjMaH8klpo5QgjjcUJHrO2WnsVBHVeAf2n//7uExKxYa/z7hPaTPt/zLJ90AI4yMEUeR4zNG8jFxg1xrnBaFxwfmkkAdly9cTniZ9x+831k5mliluf+JKqH6YGWBGynTVkdYlgu
5Q1srxDi96sMM7k9B5/MMqm7eNwUo9xcY/9lQHAbL5qB9xTwQ3tfjDCq6+Q51REgXNp2/6U9q/8ZoftVHPLxL4CfbGHtZMnySANwahHfYVjzWxgAdxkOc5CEdaZZy1WDeUZArkcw3GZ8udmj2ifMNo1Lpz8f1gc3
bfoR22fOMkyiqgjhgbSmOnor+jx42dracu9HgWzTO5H+Pyvi/b1fa4Qxg1fN4DvJcHTgKJmhPVGzavxfjE3/f+39PyCMLIwDPpYJWdH5vmfJAJw8mFXyAJUJ6+ww7EAVlWYs85EGuLRtN21zlyrdwhSBs/0MElaX
9m1+FCQCbszW7iSvipCRWtv1eNgytGUMM26GA/LUogdDlo2Jvgv8CsEFHQG4aLDdipCH8FVjsX9CcCX3NvF4RHf0beC/IHTD+h3b9j8lxIyzZMkAPAKMlxJlmvZI7jZAOQXmJquJYLrOxszcFGDTAQlq2zuoPtO7
BUgp40uvUXpNons/7dH9sLGCtnh7ju89+LJKKA96D/ibDPMMGMFunzLwfIXQ7er/TkgC3IxpXwe+bs/4fwR8Cfj7plv+f4SJSLkhR5YMwCOYa/NBjMfTZehSluSVSt0A2HSAw1ZKTh5GJuga10ZbjBIdo7geBONh
ks88iOeQZbL79zGhKQeE3I8TxoibxrQjTC/6in3mdw1Y/zmT1ZZ/DPweIcRVErpv/beEUrr/FfhZviVZMgBPLhWjY0VbzUB+lJR1alT4FjAblYikD+A5jAPkDLCPxjpVgiu6MgB+kpCI1W/onHngaUKewjqh2cY/
NBb9b4zNjqtyiDkM37D19F8SOmb9A/v9/0xo2pElSwbgXVbgn3QF97Bfm60cc85qffju7Qoh5+CEMdP/kLDaaGSfAM7Z/e0bI/4U8F/b///AmHS5yf1fJMwAnrN9fh74TUJ7ygtsnEudJUsG4Cy7Ko8KQI06jwy+
D5/cJvRqfg54kWFHrLTe/gRw3u77h4SEwWcJ5UX/jX3292xbvU3WzRLwfxjYPkXoX346r58sD7K4fAkeKWaczyPLgyJ3CCVDFcPpWWlDnJ6B5CkD5x8D/0/7uWpA/FvALzMsU5pk/VQt6ymvqywZgLNkyfKJ0CmO
kCD1JsG1fJTgho4lg7Wx4q/Z364T5vj+c+D/CvyRbeuLwH8K/AbDNqmjgHeKUPb0W4Qe1FcJjTvakjizZHkgJLugs2TJspsSAe8tQuLV7xKSrX6eEJO9ZIz3FUL2cwf4LvBNY83/zsC2S0io+opt1wN/xrCjVt0A
/JeBv2GgfRv4YzMAJmlZmiVLBuAsWbI89FIbIC4SRgm+S6jR/QLwa4RkLCVkPx8huJvfJpQMxQY9f2Qg+t8aqH6JYS3xv+X+jllfIwxn+JLptL8A/hnD1pTZBZ0lA3CWLFk+ERIzji8Af0iI9Z4juJKPG8h+3pjs
nxlbvcuwi91dQmnRjLHXnwc+A/wqIbHrJ4SM6i7B7fyPgV8wffbHwP8O/JTtD4DIkmVfRFSzcZglS5Y9kycIHar+sYHwOsNe5deB/wH4fzHs2AbDbPgpgqv6PydMQHIGsP+M0G3rFUK29N808P33wP/DPrNMLl/L
khlwlixZPsFymVBKpMBfJ5QdOYJr+j8Q3MX9xnfSwQ7fsfeR7f6qMeNvEuK+v2ig/k1CH+h/x7CmOINvlsyAs2TJ8omV2Kt8ljAZ6Tn73UWCO/kumw9HKQhTj/4zQlLXaULd7zTBnf2HwP9GSObKzDdLBuAsWbJk
mUQHNVhv83fpIJUvAn+HUNJ0hNBt6w1CHPkPjflm8M2SAThLlixZxoDtVoZzxJ8lYXzhIUJp0wqhdOk2wQ0de6VnyZIBOEuWLFmyZMnSLjkJK0uWLA8rkyZh1FmyZADOkiVLlj2WDLhZHgnJvaCzZMmSJUuWA5D/
P99yKSqx/SZqAAAAAElFTkSuQmCC
]]


-- DATA PILL (3 lapis PNG transparan 749x120, base64). Jangan diedit.
PILL.B = [[
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
]]
PILL.T = [[
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
RU5ErkJggg==
]]
PILL.S = [[
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
]]

return SORU
