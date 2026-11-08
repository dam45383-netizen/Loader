
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
local LOGO, LOGOCHAR, LOGONAME = "", "S", "SoruHub"
-- CHAT: isi URL Firebase Realtime Database di sini (atau lewat CreateWindow({ChatUrl = "..."})). Contoh: "https://nama-project-default-rtdb.firebaseio.com"
local CHAT_URL = "https://chatting-soru-hub-default-rtdb.asia-southeast1.firebasedatabase.app/"

-- BANNER: logo SORU HUB utuh (huruf S + teks + kursor) di pojok kiri atas sidebar, WARNANYA IKUT TEMA.
-- Dibuat dari 2 lapis PNG (base64 di PALING BAWAH file): BANNER_B64 = lapisan bayangan yang di-tint warna aksen tema, BANNER_B64S = highlight putih + tulisan "SORU" (tetap).
-- Dipakai otomatis kalau C.Logo / C.LogoUrl kosong. Opsi: CreateWindow({Banner = false}) matikan, CreateWindow({Banner = "rbxassetid://ID"}) pakai gambar sendiri (warna tidak ikut tema).
local BANNER, BANNER2, BANNER_B64, BANNER_B64S = "", "", "", ""
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
-- ART: aset gambar base64 = PNG putih + alpha yang di-tint warna tema (jadi ikut ganti tema). Datanya ada di PALING BAWAH file (ART64).
--   ART64.glow   = halo luar window / pil aktif (9-slice)      ART64.ring = garis tepi kaca + cahaya tipis di dalam (9-slice, dipakai window & semua kartu)
--   ART64.radial = cahaya bulat (avatar)                       ART64.icons = atlas ikon 64px (8 kolom), dipakai mkIcon otomatis
-- Kalau executor tidak punya writefile / getcustomasset (atau CreateWindow({Art = false})) -> otomatis pakai tampilan polos lama tanpa gambar.
----------------------------------------------------------------------
local ART64 = {}
local ART = {ok = false}
local ART_CELLS = {
    grid = {0, 0}, sliders = {64, 0}, chevron = {128, 0}, star = {192, 0}, starfill = {256, 0}, bell = {320, 0}, search = {384, 0}, settings = {448, 0},
    play = {0, 64}, clock = {64, 64}, bars = {128, 64}, crown = {192, 64}, verified = {256, 64}, level = {320, 64}, arrowup = {384, 64}, user = {448, 64},
    target = {0, 128}, terminal = {64, 128}, dot = {128, 128}, check = {192, 128}, close = {256, 128}, home = {320, 128}, list = {384, 128},
}
local ART_ALIAS = {gauge = "clock", activity = "bars", [">_"] = "terminal"} -- nama lama -> ikon atlas
local function loadArt(on)
    ART.ok, ART.glowL = false, nil
    if on == false or not (isfile and getcustomasset and writefile) then return end
    local g = loadB64(ART64.glow or "", "artglow")
    local r = loadB64(ART64.ring or "", "artring")
    local d = loadB64(ART64.radial or "", "artradial")
    local i = loadB64(ART64.icons or "", "articons")
    if g == "" or r == "" or d == "" or i == "" then return end
    ART.glow, ART.ring, ART.radial, ART.icons, ART.ok = g, r, d, i, true
end

----------------------------------------------------------------------
-- THEME: palet gelap ala Nemesis (hampir hitam + ungu). Aksen bisa diganti lewat UI Settings (45 preset)
----------------------------------------------------------------------
local WHITE = Color3.new(1, 1, 1)
local T = {
    bg = Color3.fromRGB(12, 9, 20), side = Color3.fromRGB(9, 7, 15), el = Color3.fromRGB(20, 15, 32), field = Color3.fromRGB(28, 23, 42),
    hover = Color3.fromRGB(40, 33, 60), chip = Color3.fromRGB(32, 28, 47), glass = Color3.fromRGB(23, 18, 37), outline = Color3.fromRGB(46, 37, 72), text = Color3.fromRGB(255, 255, 255),
    mid = Color3.fromRGB(160, 151, 201), dim = Color3.fromRGB(143, 134, 183), faint = Color3.fromRGB(125, 117, 163), off = Color3.fromRGB(52, 46, 70),
    ok = Color3.fromRGB(84, 224, 40), warn = Color3.fromRGB(241, 196, 15), bad = Color3.fromRGB(240, 60, 70),
    accent = Color3.fromRGB(134, 46, 248), accent2 = Color3.fromRGB(84, 22, 196),
}
local function derive()
    T.accentL = T.accent:Lerp(WHITE, 0.42) -- judul halaman, angka slider
    T.accentLL = T.accent:Lerp(WHITE, 0.62) -- garis grafik
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
    "Soru 862EF8 5416C4", "Nemesis 813DC3 5E2F9E", "Violet 9160FF 5E6AFF", "Ocean 28A0FF 3870FF", "Crimson FF4664 DC2650", "Emerald 2DD496 10AA78",
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
local DEF_ICONS = {settings = SORU.Icons.settings, chevron = SORU.Icons.chevron} -- bawaan library; kalau tidak kamu ganti, ikon atlas base64 yang dipakai
local GLYPH = {
    grid = "▦", home = "⌂", sprout = "✿", sliders = "☰", pickaxe = "⚒", hammer = "⚒", zap = "ϟ", wrench = "✎", save = "▣", eraser = "▱",
    box = "◧", layers = "≋", wheat = "✾", gauge = "◔", activity = "∿", target = "◎", star = "☆", starfill = "★", sort = "⇅", crosshair = "⌖",
    user = "☺", send = "➤", smile = "☺", info = "ⓘ", palette = "◐", dot = "•", close = "✕", check = "✓", settings = "⚙", folder = "▤", list = "≡", play = "▶", eye = "◉",
    level = "▯", bars = "▂▄▆", crown = "♛", verified = "✔", clock = "◔", terminal = ">_", arrowup = "↑", chevron = "›",
}
local function mkIcon(parent, name, size, color, props)
    local ic = {}
    name = tostring(name or "dot")
    local src = SORU.Icons[name] or name
    local o
    local cell = ART.ok and (SORU.Icons[name] == nil or SORU.Icons[name] == DEF_ICONS[name]) and ART_CELLS[ART_ALIAS[name] or name]
    if cell then -- ikon atlas base64 (putih, di-tint lewat ImageColor3)
        o = new("ImageLabel", {BackgroundTransparency = 1, Image = ART.icons, ImageRectOffset = Vector2.new(cell[1], cell[2]), ImageRectSize = Vector2.new(64, 64),
            ImageColor3 = color, ScaleType = Enum.ScaleType.Stretch, Size = UDim2.fromOffset(size, size)}, parent)
        function ic.tint(c, t) play(o, {ImageColor3 = c}, t or 0.2) end
    elseif src:match("^rbxasset") or src:match("^%d%d%d+$") then
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

-- lapisan gambar (hanya kalau ART.ok): garis tepi kaca (rim) + halo luar (glow). Warna ikut tema (skin), sebaran terang lewat UIGradient diagonal
local RIM = { -- titik transparansi gradien (0 = kiri atas, 1 = kanan bawah); makin kecil = makin terang
    base = {{0, 0.72}, {0.5, 0.86}, {1, 0.7}},
    tl = {{0, 0.1}, {0.38, 0.62}, {1, 0.74}},
    br = {{0, 0.84}, {0.5, 0.74}, {1, 0.02}},
    both = {{0, 0.1}, {0.42, 0.76}, {0.7, 0.64}, {1, 0.06}},
    win = {{0, 0.12}, {0.3, 0.76}, {0.7, 0.76}, {1, 0.06}},
    pill = {{0, 0.2}, {0.5, 0.5}, {1, 0.12}},
}
local function seqOf(pts)
    local k = {}
    for i, v in ipairs(pts) do k[i] = NumberSequenceKeypoint.new(v[1], v[2]) end
    return NumberSequence.new(k)
end
local function artRim(parent, mode, z, key)
    if not ART.ok then return nil end
    local r = new("ImageLabel", {Name = "Rim", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = ART.ring, ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(34, 34, 50, 50), SliceScale = 0.5, ZIndex = z or 1}, parent)
    skin(r, "ImageColor3", key or "accentL")
    new("UIGradient", {Rotation = 45, Transparency = seqOf(RIM[mode or "base"])}, r)
    return r
end
local function artGlow(parent, pad, tr, z)
    if not ART.ok then return nil end
    local g = new("ImageLabel", {Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, pad * 2, 1, pad * 2),
        BackgroundTransparency = 1, Image = ART.glow, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(52, 52, 68, 68), SliceScale = 0.5,
        ImageTransparency = tr or 0.5, ZIndex = z or 0}, parent)
    skin(g, "ImageColor3", "accent")
    return g
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
    loadArt(C.Art) -- aset base64 (ikon, garis tepi, halo); gagal = tampilan polos
    BANNER, BANNER2 = "", ""
    if LOGO == "" and C.Banner ~= false then
        if C.Banner then
            BANNER = tostring(C.Banner)
            if BANNER:match("^%d+$") then BANNER = "rbxassetid://" .. BANNER end
        else
            BANNER, BANNER2 = loadBanner()
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
    ART.glowL = artGlow(shell, 12, 0.5, 0) -- halo neon di luar window (ikut tema)
    local win = new("Frame", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = WHITE, BorderSizePixel = 0, ClipsDescendants = true, Active = true}, shell)
    corner(win, 14)
    stroke(win, T.outline, 1, ART.ok and 1 or 0.1)
    local winG = new("UIGradient", {Rotation = 135}, win)
    local function paintWin()
        winG.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, T.bg:Lerp(T.accent, 0.1)), ColorSequenceKeypoint.new(0.6, T.bg), ColorSequenceKeypoint.new(1, T.bg)})
    end
    paintWin()
    themeFns[#themeFns + 1] = paintWin
    artRim(win, "win", 90) -- garis tepi neon window (di atas isi, di bawah handle resize)
    local winScale = new("UIScale", {Scale = 1}, win)
    local ctxWin = newCtx(win, 14)

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
    local SIDE_W, LOGO_H, FOOT_H = 164, 64, 46
    local sbg = new("Frame", {Name = "Sidebar", Size = UDim2.new(0, SIDE_W, 1, 0), BackgroundColor3 = T.side, BorderSizePixel = 0, ClipsDescendants = true}, win)
    corner(sbg, 14)
    new("Frame", {Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0, 14, 1, 0), BackgroundColor3 = T.side, BorderSizePixel = 0}, sbg) -- luruskan sisi kanan
    new("Frame", {Name = "Separator", Position = UDim2.fromOffset(SIDE_W - 1, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.outline, BackgroundTransparency = 0.55, BorderSizePixel = 0}, win)

local dragLogo = new("Frame", {Name = "LogoArea", Size = UDim2.new(0, SIDE_W - 1, 0, LOGO_H), BackgroundTransparency = 1, Active = true}, win)
    local BS = 32                                    -- ukuran badge (px)
    local BX, BY = 14, math.floor((LOGO_H - BS) / 2) -- posisi badge: kiri, tengah vertikal

    -- glow aksen berlapis di belakang badge (berdenyut pelan, diam kalau "Reduce animation" aktif)
    for i, pad in ipairs(BANNER ~= "" and {} or {5, 10, 15, 20}) do
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
    if BANNER ~= "" then
        -- banner SORU HUB: ukuran & posisi disamakan dengan referensi (kiri 14, atas 9, 137x43). Lapisan bawah = bayangan (di-tint warna tema), lapisan atas = highlight putih + tulisan SORU
        local bp = {Position = UDim2.fromOffset(14, 9), Size = UDim2.fromOffset(137, 43), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit}
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
    nm.Visible = BANNER == "" -- teks nama sudah ada di dalam gambar banner

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
    
    local NAV_Y = LOGO_H - 2
    local nav = new("ScrollingFrame", {Name = "Nav", Active = true, Position = UDim2.fromOffset(0, NAV_Y), Size = UDim2.new(1, -1, 1, -(NAV_Y + FOOT_H)), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y}, sbg)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 9)}, nav)
    new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 12)}, nav)

    -- tombol UI Settings (kiri bawah)
    local setBtn = new("TextButton", {Name = "UISettings", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.new(1, -25, 0, 29), BackgroundColor3 = T.glass,
        Text = "", AutoButtonColor = false, BorderSizePixel = 0}, sbg)
    corner(setBtn, 10)
    if ART.ok then artRim(setBtn, "base", 1) else stroke(setBtn, T.outline, 1, 0.5) end
    local setIc = mkIcon(setBtn, "settings", 13, T.accentL, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0)})
    local setLb = text(setBtn, {Text = "UI Settings", Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -42, 1, 0), W = 2, TextSize = 11, TextColor3 = T.text, TextTruncate = NOTRUNC})

    ------------------------------------------------------------------
    -- MAIN: judul halaman + subjudul, tombol bintang / lonceng / pencarian, chip sub-tab, konten
    ------------------------------------------------------------------
    local main = new("Frame", {Name = "Main", Position = UDim2.fromOffset(SIDE_W, 0), Size = UDim2.new(1, -SIDE_W, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true}, win)
    local dragMain = new("Frame", {Name = "DragZone", Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, Active = true}, main)
    local titleL = text(main, {Name = "Title", Text = "", Position = UDim2.fromOffset(17, 10), Size = UDim2.new(1, -270, 0, 20), W = 4, TextSize = 15})
    local subL = text(main, {Name = "Subtitle", Text = "", Position = UDim2.fromOffset(17, 32), Size = UDim2.new(1, -270, 0, 12), TextSize = 10, W = 1, TextColor3 = T.mid})
    local hl = new("Frame", {Name = "HeaderLine", Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 0.5, BorderSizePixel = 0}, main)
    do -- kilau lembut di kanan header (warna tema)
        local sh = skin(new("Frame", {Name = "HeaderSheen", Size = UDim2.new(1, 0, 0, 54), BorderSizePixel = 0, ZIndex = 0}, main), "BackgroundColor3", "accent")
        new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 0.97), NumberSequenceKeypoint.new(1, 0.86)})}, sh)
    end

    local SEARCH_W = 152
    local function hdrBtn(name, xOff)
        local b = new("TextButton", {Name = name, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, xOff, 0, 15), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T.chip, Text = "", AutoButtonColor = false, BorderSizePixel = 0}, main)
        corner(b, 9)
        stroke(b, T.outline, 1, 0.3)
        b.MouseEnter:Connect(function() play(b, {BackgroundColor3 = T.hover}, 0.15) end)
        b.MouseLeave:Connect(function() play(b, {BackgroundColor3 = T.chip}, 0.15) end)
        return b
    end
    local starB = hdrBtn("Favorite", -(14 + SEARCH_W + 15 + 26 + 10))
    local starIc = mkIcon(starB, "star", 14, T.text, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
    local bellB = hdrBtn("Notifications", -(14 + SEARCH_W + 15))
    local bellIc = mkIcon(bellB, "bell", 14, T.text, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
    local badge = new("Frame", {Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 1, 0, 3), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.bad, BorderSizePixel = 0, ZIndex = 5, Visible = false}, bellB)
    corner(badge, "full")
    local badgeL = text(badge, {Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 4, TextSize = 9, TextTruncate = NOTRUNC, ZIndex = 6, Text = "0"})

    local sBox = new("Frame", {Name = "Search", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(SEARCH_W, 28), BackgroundColor3 = T.chip, BorderSizePixel = 0}, main)
    corner(sBox, 10)
    local sStroke = stroke(sBox, T.outline, 1, 0.45)
    mkIcon(sBox, "search", 13, T.mid:Lerp(WHITE, 0.3), {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0)})
    local sInput = new("TextBox", {Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(35, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", PlaceholderText = "Search tabs/groups...",
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
        if C.Pill ~= false then pB, pT, pS = loadPill() end
        if pB ~= "" then
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
        if ART.glowL then ART.glowL.ImageTransparency = 1 play(ART.glowL, {ImageTransparency = 0.5}, 0.4) end
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
        if ART.glowL then play(ART.glowL, {ImageTransparency = 1}, 0.25) end
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
    local GH, IH, IGAP, HGAP, FH, FLAT = 30, 24, 4, 8, 30, {} -- tinggi header grup, tinggi item, jarak antar item, jarak header -> item, tinggi item grup "flat" (Dashboard), daftar grup flat
    local TOP0, TOP1 = 54, 88 -- awal konten tanpa / dengan baris chip
    local groups, glist, pages = {}, {}, {}
    local cur, lastPage, searching = nil, nil, false
    local SETTINGS = "\0settings"
    local favs = type(F.UIFavs) == "table" and F.UIFavs or {}
    F.UIFavs = favs

    local function itemsH(g)
        local n, h = 0, 0
        for _, p in ipairs(g.pages) do if p.item.Visible then n, h = n + 1, h + p.ih end end
        return (n > 0) and (h + (n - 1) * IGAP) or 0
    end
    local function relayoutGroup(g, anim)
        local ih = itemsH(g)
        local open = g.open or searching or g.flat
        g.items.Size = UDim2.new(1, 0, 0, ih)
        local h = (g.vis == false) and 0 or (g.flat and ih or (GH + ((open and ih > 0) and (ih + HGAP + 2) or 0)))
        g.holder.Visible = g.vis ~= false
        if anim then play(g.holder, {Size = UDim2.new(1, 0, 0, h)}, 0.25) else g.holder.Size = UDim2.new(1, 0, 0, h) end
    end

    local function createGroup(name, icon)
        if groups[name] then return groups[name] end
        local g = {name = name, pages = {}, open = true, flat = FLAT[name] == true}
        groups[name] = g
        glist[#glist + 1] = g
        g.holder = new("Frame", {Name = name .. "Group", Size = UDim2.new(1, 0, 0, GH), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = not g.flat, LayoutOrder = #glist}, nav)
        g.head = new("TextButton", {Name = "Header", Size = UDim2.new(1, 0, 0, GH), BackgroundColor3 = T.glass, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Visible = not g.flat}, g.holder)
        corner(g.head, 10)
        if ART.ok then artRim(g.head, "base", 1) else stroke(g.head, T.outline, 1, 0.5) end
        g.icon = mkIcon(g.head, icon or "sliders", 13, T.text, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0)})
        text(g.head, {Text = name, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -62, 1, 0), W = 3, TextSize = 11})
        local sortIc = mkIcon(g.head, "chevron", 13, T.mid, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -17, 0.5, 0)})
        g.items = new("Frame", {Name = "Items", Position = UDim2.fromOffset(0, g.flat and 0 or (GH + HGAP)), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0}, g.holder)
        new("UIListLayout", {Padding = UDim.new(0, IGAP), SortOrder = Enum.SortOrder.LayoutOrder}, g.items)
        g.head.MouseEnter:Connect(function() play(g.head, {BackgroundColor3 = T.hover}, 0.15) end)
        g.head.MouseLeave:Connect(function() play(g.head, {BackgroundColor3 = T.glass}, 0.15) end)
        g.head.MouseButton1Click:Connect(function()
            g.open = not g.open
            play(sortIc.inst, {Rotation = g.open and 0 or 90}, 0.2) -- terbuka = panah ke kanan (seperti referensi), tertutup = menghadap bawah
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
    local function pillCols() -- kiri: ungu pekat kebiruan, kanan: aksen tema
        local h, s, v = T.accent:ToHSV()
        return Color3.fromHSV((h - 0.015) % 1, math.min(s * 1.2, 1), v * 0.84), Color3.fromHSV((h + 0.004) % 1, s, v * 0.95)
    end
    local function paintItem(p, on, instant)
        p.on = on
        local function set(o, props, t)
            if instant then for k, v in pairs(props) do o[k] = v end else play(o, props, t or 0.22) end
        end
        set(p.pill, {BackgroundTransparency = on and 0 or 1})
        set(p.pillSt, {Transparency = on and 0.35 or 1})
        set(p.gloss, {BackgroundTransparency = on and 0 or 1})
        if p.pillRim then set(p.pillRim, {ImageTransparency = on and 0 or 1}) end
        if p.pillGlow then set(p.pillGlow, {ImageTransparency = on and 0.55 or 1}) end
        set(p.item, {BackgroundTransparency = 1})
        set(p.label, {TextColor3 = on and T.text or T.dim})
        p.icon.tint(on and WHITE or T.mid, instant and 0 or 0.22)
        set(p.bar, {Size = UDim2.fromOffset(3, on and (p.ih >= 28 and 14 or 11) or 0)})
        set(p.barGlow, {Size = UDim2.fromOffset(7, on and (p.ih >= 28 and 20 or 15) or 0), BackgroundTransparency = on and 0.8 or 1})
        if p.iconGlow then set(p.iconGlow, {Transparency = on and 0.55 or 1}) end
        if on and not instant and not NOANIM then -- kilau gradien saat tab dipilih
            p.pillG.Offset = Vector2.new(-0.3, 0)
            play(p.pillG, {Offset = Vector2.new(0, 0)}, 0.4)
        end
    end
    local function paintSettingsBtn(on)
        play(setBtn, {BackgroundColor3 = on and T.accent or T.glass}, 0.2)
        play(setLb, {TextColor3 = T.text}, 0.2)
        setIc.tint(on and T.text or T.accentL)
    end
    local function updateStar()
        local p = pages[cur]
        local on = p ~= nil and not p.hidden and favs[p.key] == true
        if starIc.inst:IsA("TextLabel") then starIc.inst.Text = on and "★" or "☆"
        elseif starIc.inst:IsA("ImageLabel") and ART.ok then
            local c = ART_CELLS[on and "starfill" or "star"]
            starIc.inst.ImageRectOffset = Vector2.new(c[1], c[2]) -- bintang kosong / terisi (atlas)
        end
        starIc.tint(on and T.accentL or T.text)
    end

    local function createPage(gname, name, icon, subtitle, columns, hidden)
        local key = hidden and SETTINGS or (gname .. "/" .. name)
        local p = {key = key, name = name, subtitle = subtitle, subs = {}, hidden = hidden, top = TOP0, on = false}
        pages[key] = p
        if not hidden then
            local g = createGroup(gname, nil)
            p.group = g
            p.ih = g.flat and FH or IH
            p.item = new("TextButton", {Name = name .. "Button", LayoutOrder = #g.pages + 1, Size = UDim2.new(1, 0, 0, p.ih), BackgroundColor3 = T.el, BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = ""}, g.items)
            corner(p.item, 10)
            -- pil aktif (gradien horizontal + kilap atas + garis tepi + halo), hanya tampil saat tab dipilih
            p.pill = new("Frame", {Name = "Pill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0}, p.item)
            corner(p.pill, 10)
            p.pillG = new("UIGradient", {Rotation = 0}, p.pill)
            p.pillSt = skin(stroke(p.pill, T.accentL, 1, 1), "Color", "accentL")
            p.gloss = new("Frame", {Name = "Gloss", Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 0.5, -2), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0}, p.pill)
            corner(p.gloss, 9)
            new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1)})}, p.gloss)
            p.pillRim = artRim(p.pill, "pill", 2)
            if p.pillRim then p.pillRim.ImageTransparency = 1 end
            p.pillGlow = artGlow(p.item, 12, 1, 0)
            local ik = icon or name:sub(1, 1):upper() -- tanpa ikon -> huruf pertama nama (seperti referensi: M / G / E / P)
            p.icon = mkIcon(p.item, ik, (ART.ok and ART_CELLS[ART_ALIAS[ik] or ik]) and 13 or 12, T.mid, {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0)})
            if p.icon.inst:IsA("TextLabel") then -- ikon teks: outline lembut supaya terlihat bercahaya saat aktif
                p.iconGlow = skin(new("UIStroke", {Thickness = 1.5, Transparency = 1}, p.icon.inst), "Color", "accentL")
            end
            p.label = text(p.item, {Text = name, Position = UDim2.fromOffset(g.flat and 36 or 39, 0), Size = UDim2.new(1, -(g.flat and 50 or 68), 1, 0), W = 2, TextSize = 11, TextColor3 = T.dim})
            -- penanda putih di tepi kanan pil
            p.barGlow = new("Frame", {Name = "IndicatorGlow", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 1, 0.5, 0), Size = UDim2.fromOffset(7, 0), BackgroundTransparency = 1, BorderSizePixel = 0}, p.item)
            corner(p.barGlow, "full")
            p.bar = new("Frame", {Name = "Indicator", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -3, 0.5, 0), Size = UDim2.fromOffset(3, 0), BorderSizePixel = 0}, p.item)
            corner(p.bar, "full")
            if ART.ok then -- bintang favorit (atlas)
                p.star = mkIcon(p.item, "starfill", 13, T.accentH, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -11, 0.5, 0), Visible = favs[key] == true}).inst
                skin(p.star, "ImageColor3", "accentH")
            else
                p.star = text(p.item, {Text = "★", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -7, 0.5, 0), Size = UDim2.fromOffset(12, 12), TextXAlignment = XC, TextSize = 9, TextTruncate = NOTRUNC, Visible = favs[key] == true})
                skin(p.star, "TextColor3", "accentL")
            end
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
                    play(p.label, {TextColor3 = T.text}, 0.15)
                    p.icon.tint(T.text, 0.15)
                end
            end)
            p.item.MouseLeave:Connect(function()
                if not p.on then
                    play(p.item, {BackgroundTransparency = 1}, 0.15)
                    play(p.label, {TextColor3 = T.dim}, 0.15)
                    p.icon.tint(T.mid, 0.15)
                end
            end)
            p.item.MouseButton1Click:Connect(function()
                if ctxWin.d then ctxWin.d.close() end
                if cur ~= key then ripple(p.item, 120) end
                go(key)
            end)
        end
        p.frame = new("Frame", {Name = name, Position = UDim2.fromOffset(0, TOP0), Size = UDim2.new(1, 0, 1, -TOP0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Visible = false}, main)
        p.chips = new("ScrollingFrame", {Name = name .. "Chips", Active = true, Position = UDim2.fromOffset(14, 60), Size = UDim2.new(1, -28, 0, 24), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
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
                p.label.TextColor3 = p.on and T.text or T.dim
                p.icon.tint(p.on and T.accentL or T.mid, 0)
            end
            for i, s in ipairs(p.subs) do
                s.chip.BackgroundColor3 = (p.curSub == i) and T.chipOn or T.chip
            end
        end
        paintSettingsBtn(cur == SETTINGS)
        updateStar()
    end

    setBtn.MouseEnter:Connect(function() if cur ~= SETTINGS then play(setBtn, {BackgroundColor3 = T.hover}, 0.15) end end)
    setBtn.MouseLeave:Connect(function() if cur ~= SETTINGS then play(setBtn, {BackgroundColor3 = T.glass}, 0.15) end end)
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
    local bellPop = new("Frame", {Name = "NotifPanel", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 50), Size = UDim2.fromOffset(236, 176), BackgroundColor3 = T.el, BorderSizePixel = 0, Visible = false, ZIndex = 60}, win)
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
            corner(box, nested and 8 or 14)
            stroke(box, T.outline, 1, (ART.ok and not nested) and 1 or (nested and 0.6 or 0.4))
            if not nested then artRim(box, "base", 1) end
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
        local stats = {exec = 0, secs = 0, day = "", today = 0}
        pcall(function()
            if isfile and isfile(SF) then
                local d = Http:JSONDecode(readfile(SF))
                if type(d) == "table" then
                    stats.exec, stats.secs = tonumber(d.exec) or 0, tonumber(d.secs) or 0
                    stats.day, stats.today = tostring(d.day or ""), tonumber(d.today) or 0
                end
            end
        end)
        stats.exec = stats.exec + 1
        local dayKey = os.date("%Y-%m-%d")
        if stats.day ~= dayKey then stats.day, stats.today = dayKey, 0 end
        stats.today = stats.today + 1
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
            local function card(parent, size, pos, rim) -- rim: "base" / "tl" / "br" / "both" = sebaran cahaya di garis tepi kaca
                local f = new("Frame", {Size = size, Position = pos or UDim2.new(), BackgroundColor3 = T.el, BorderSizePixel = 0}, parent)
                corner(f, 14)
                stroke(f, T.outline, 1, ART.ok and 1 or 0.4)
                artRim(f, rim or "base", 1)
                return f
            end
            local function lb(parent, txt, x, y, w, h, o) -- label kecil; w boleh UDim2
                o = o or {}
                o.Text, o.Position = txt, UDim2.fromOffset(x, y)
                o.Size = (typeof(w) == "UDim2") and w or UDim2.fromOffset(w, h)
                return text(parent, o)
            end
            local function chip(parent, glyph, x, y, sz) -- kotak ikon ungu tipis
                sz = sz or 22
                local b = new("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 0.8, BorderSizePixel = 0}, parent)
                skin(b, "BackgroundColor3", "accent")
                corner(b, math.floor(sz * 0.32))
                skin(stroke(b, T.accent, 1, 0.72), "Color", "accent")
                local ic = mkIcon(b, glyph, sz > 22 and 13 or 11, T.accentL, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
                themeFns[#themeFns + 1] = function() ic.tint(T.accentL, 0) end
                return b
            end
            local function pill(parent, txt, kind, x, y) -- badge: "owner" (isi aksen tema) / "ver" (kaca gelap) / "plan" (aksen pudar). Mengembalikan x berikutnya
                local w = textW(txt, 10) + 22
                local f = new("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 22), BorderSizePixel = 0}, parent)
                corner(f, "full")
                local l = text(f, {Text = txt, Size = UDim2.fromScale(1, 1), TextXAlignment = XC, TextColor3 = T.text, W = 4, TextSize = 10, TextTruncate = NOTRUNC})
                if kind == "owner" then
                    skin(f, "BackgroundColor3", "accent")
                    new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.7, 0.62, 0.92))}, f)
                    skin(stroke(f, T.accentL, 1, 0.35), "Color", "accentL")
                elseif kind == "plan" then
                    skin(f, "BackgroundColor3", "accent")
                    f.BackgroundTransparency = 0.72
                    skin(l, "TextColor3", "accentL")
                else
                    f.BackgroundColor3 = T.chip
                    stroke(f, T.outline, 1, 0.3)
                end
                return x + w + 9
            end

            ---------------- BARIS 1: profil + level ----------------
            local r1 = rowF(96)
            local pc = card(r1, UDim2.new(0.61, -5, 1, 0), nil, "base")
            if ART.ok then -- cahaya di belakang avatar
                skin(new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(38, 36), Size = UDim2.fromOffset(96, 96), BackgroundTransparency = 1,
                    Image = ART.radial, ImageTransparency = 0.55}, pc), "ImageColor3", "accent")
            end
            local av = new("ImageLabel", {Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(60, 60), BackgroundColor3 = T.field, BorderSizePixel = 0,
                Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(LP.UserId)}, pc)
            corner(av, "full")
            skin(stroke(av, T.accent, 3, 0.05), "Color", "accent")
            lb(pc, "WELCOME BACK", 83, 10, 130, 11, {W = 2, TextSize = 8, TextColor3 = T.dim})
            lb(pc, LP.DisplayName, 83, 21, 130, 20, {W = 4, TextSize = 15, TextTruncate = NOTRUNC})
            local nx = 83 + math.min(textW(LP.DisplayName, 15), 128) + 8
            if ART.ok then -- mahkota + centang terverifikasi
                mkIcon(pc, "crown", 14, Color3.fromRGB(253, 214, 8), {Position = UDim2.fromOffset(nx, 24)})
                local vb = mkIcon(pc, "verified", 14, T.accentL, {Position = UDim2.fromOffset(nx + 19, 24)})
                themeFns[#themeFns + 1] = function() vb.tint(T.accentL, 0) end
            else
                lb(pc, "👑 🔮", nx, 21, 40, 20, {TextSize = 11, TextTruncate = NOTRUNC})
            end
            lb(pc, "@" .. LP.Name, 83, 43, 150, 12, {W = 1, TextSize = 9, TextColor3 = T.faint})
            local bx = pill(pc, tostring(C.Role or "OWNER"):upper(), "owner", 10, 70)
            bx = pill(pc, tostring(C.Version or "v1.0"), "ver", bx, 70)
            pill(pc, tostring(C.Plan or "Lifetime"), "plan", bx, 70)

            local lc = card(r1, UDim2.new(0.39, -5, 1, 0), UDim2.new(0.61, 5, 0, 0), "both")
            local lic = mkIcon(lc, "level", 25, T.accent, {Position = UDim2.fromOffset(18, 18)})
            themeFns[#themeFns + 1] = function() lic.tint(T.accent, 0) end
            local lvTop = lb(lc, "", 58, 11, 100, 11, {W = 2, TextSize = 8, TextColor3 = T.dim})
            local lvName = lb(lc, "", 58, 21, UDim2.new(1, -66, 0, 20), nil, {W = 4, TextSize = 15})
            local lvNext = lb(lc, "", 58, 42, UDim2.new(1, -66, 0, 12), nil, {W = 1, TextSize = 9, TextColor3 = T.faint})
            local track = new("Frame", {Position = UDim2.fromOffset(14, 64), Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = T.field, BorderSizePixel = 0}, lc)
            corner(track, "full")
            local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, track)
            corner(fill, "full")
            local fillG = new("UIGradient", {}, fill)
            local lvL = lb(lc, "", 14, 76, 80, 12, {W = 2, TextSize = 9, TextColor3 = T.dim})
            local lvR = lb(lc, "", 0, 76, UDim2.new(1, -14, 0, 12), nil, {W = 2, TextSize = 9, TextColor3 = T.dim, TextXAlignment = XR})
            local function kfmt(n) -- 1000 -> "1K"
                if n >= 1000 then return ((n % 1000 == 0) and tostring(math.floor(n / 1000)) or ("%.1f"):format(n / 1000)) .. "K" end
                return tostring(n)
            end
            local function updLevel()
                local xp, lv = lvInfo()
                local lo, hi = lvStart(lv), lvStart(lv + 1)
                local frac = (xp - lo) / (hi - lo)
                lvTop.Text = "LEVEL"
                lvName.Text = LV[math.min(lv, #LV)]
                lvNext.Text = "Next: " .. LV[math.min(lv + 1, #LV)]
                lvL.Text = xp .. "/" .. kfmt(hi)
                lvR.Text = ("%.2f%%"):format(math.clamp(frac, 0, 1) * 100)
                fill.Size = UDim2.fromScale(math.clamp(frac, 0.03, 1), 1)
            end

            ---------------- BARIS 2: executions + time spent ----------------
            local r2 = rowF(65)
            local ec = card(r2, UDim2.new(0.33, -5, 1, 0), nil, "br")
            chip(ec, "play", 11, 8, 26)
            lb(ec, "Executions", 47, 8, UDim2.new(1, -52, 0, 26), nil, {W = 2, TextSize = 11})
            local exN = lb(ec, "0", 14, 32, 90, 28, {W = 4, TextSize = 21, TextTruncate = NOTRUNC})
            local exD = lb(ec, "", 60, 41, UDim2.new(1, -66, 0, 14), nil, {W = 3, TextSize = 10, TextTruncate = NOTRUNC})
            skin(exD, "TextColor3", "accent")
            local tc = card(r2, UDim2.new(0.67, -5, 1, 0), UDim2.new(0.33, 5, 0, 0), "base")
            chip(tc, "gauge", 11, 8, 26)
            lb(tc, "Time spent", 47, 8, 110, 26, {W = 2, TextSize = 11})
            lb(tc, "Total usage", 14, 38, 100, 13, {W = 1, TextSize = 9, TextColor3 = T.dim})
            local cnt = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.new(0.56, 0, 0, 52), BackgroundColor3 = T.side, BorderSizePixel = 0}, tc)
            corner(cnt, 10)
            stroke(cnt, T.outline, 1, 0.5)
            new("UISizeConstraint", {MinSize = Vector2.new(120, 52), MaxSize = Vector2.new(162, 52)}, cnt)
            local cells = {}
            for i, nmv in ipairs({"DAY", "HOUR", "MIN", "SEC"}) do
                local cf = new("Frame", {Position = UDim2.fromScale((i - 1) / 4, 0), Size = UDim2.fromScale(0.25, 1), BackgroundTransparency = 1, BorderSizePixel = 0}, cnt)
                local num = text(cf, {Text = "00", Position = UDim2.fromOffset(0, 7), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = XC, W = 4, TextSize = 14, TextTruncate = NOTRUNC})
                local tag = text(cf, {Text = nmv, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 11), TextXAlignment = XC, W = 2, TextSize = 8, TextColor3 = T.dim, TextTruncate = NOTRUNC})
                if i > 1 then new("Frame", {Position = UDim2.fromOffset(0, 8), Size = UDim2.new(0, 1, 1, -16), BackgroundColor3 = T.outline, BackgroundTransparency = 0.4, BorderSizePixel = 0}, cf) end
                if i == 4 then
                    skin(num, "TextColor3", "accentL")
                    skin(tag, "TextColor3", "accentH")
                    local ub = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 42), Size = UDim2.fromOffset(16, 3), BorderSizePixel = 0}, cf)
                    corner(ub, "full")
                    skin(ub, "BackgroundColor3", "accentL")
                end
                cells[i] = num
            end
            local function updTime()
                local s = stats.secs
                local v = {math.floor(s / 86400), math.floor(s % 86400 / 3600), math.floor(s % 3600 / 60), math.floor(s % 60)}
                for i = 1, 4 do cells[i].Text = ("%02d"):format(v[i]) end
            end

            ---------------- BARIS 3: performance ----------------
            local r3 = rowF(136)
            local pf = card(r3, UDim2.new(1, 0, 1, 0), nil, "base")
            chip(pf, "activity", 11, 8, 26)
            lb(pf, "Performance", 47, 8, 120, 26, {W = 2, TextSize = 11})
            lb(pf, "Current FPS", 14, 38, 100, 12, {W = 1, TextSize = 9, TextColor3 = T.dim})
            local fpsL = lb(pf, "-- fps", 14, 50, UDim2.new(0.38, -14, 0, 28), nil, {W = 4, TextSize = 21, TextTruncate = NOTRUNC})
            local function stat(y, tag) -- kapsul kaca: ikon + nilai | tag (LIVE = pil berdenyut warna kualitas, MEM = pil aksen)
                local f = new("Frame", {Position = UDim2.fromOffset(12, y), Size = UDim2.new(0.36, -12, 0, 22), BackgroundColor3 = T.glass, BorderSizePixel = 0}, pf)
                corner(f, "full")
                stroke(f, T.outline, 1, 0.6)
                local v = text(f, {Text = "--", Position = UDim2.fromOffset(30, 0), Size = UDim2.new(0.58, -30, 1, 0), W = 3, TextSize = 9, TextTruncate = NOTRUNC})
                new("Frame", {Position = UDim2.new(0.58, 0, 0, 5), Size = UDim2.new(0, 1, 1, -10), BackgroundColor3 = T.outline, BorderSizePixel = 0}, f)
                local tp = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.new(0.42, -8, 1, -8), BackgroundColor3 = T.ok, BackgroundTransparency = 0.8, BorderSizePixel = 0}, f)
                corner(tp, "full")
                local dt = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(5, 5), BackgroundColor3 = T.ok, BorderSizePixel = 0}, tp)
                corner(dt, "full")
                local t = text(tp, {Text = tag, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 1, 0), TextXAlignment = XC, W = 4, TextSize = 8, TextTruncate = NOTRUNC})
                return f, v, t, tp, dt
            end
            local pingF, pingV, pingT, pingP, pingD = stat(80, "LIVE")
            local memF, memV, memT, memP, memD = stat(106, "MEM")
            skin(memP, "BackgroundColor3", "accent")
            memD.Visible = false
            memT.Position, memT.Size = UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1)
            skin(memT, "TextColor3", "accentL")
            local bars = {}
            for i = 1, 3 do -- ikon sinyal (3 batang)
                bars[i] = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(9 + (i - 1) * 5, 17), Size = UDim2.fromOffset(3, 3 + i * 3), BackgroundColor3 = T.ok, BorderSizePixel = 0}, pingF)
                corner(bars[i], 1)
            end
            local mic = mkIcon(memF, "save", 12, T.accentL, {Position = UDim2.fromOffset(9, 5)})
            themeFns[#themeFns + 1] = function() mic.tint(T.accentL, 0) end

            local plot = new("Frame", {Position = UDim2.new(0.42, 0, 0, 14), Size = UDim2.new(0.58, -3, 0, 102), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true}, pf)
            for i = 1, 4 do skin(new("Frame", {Position = UDim2.new(0, 0, i / 5, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.93, BorderSizePixel = 0}, plot), "BackgroundColor3", "accentL") end
            for i = 1, 9 do skin(new("Frame", {Position = UDim2.new(i / 10, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundTransparency = 0.94, BorderSizePixel = 0}, plot), "BackgroundColor3", "accentL") end
            local ax = new("Frame", {Position = UDim2.new(0.42, 0, 0, 120), Size = UDim2.new(0.58, -14, 0, 11), BackgroundTransparency = 1, BorderSizePixel = 0}, pf)
            for i, s in ipairs({"20s", "15s", "10s", "5s", "Now"}) do
                local l = text(ax, {Text = s, AnchorPoint = Vector2.new((i == 1) and 0 or ((i == 5) and 1 or 0.5), 0), Position = UDim2.fromScale((i - 1) / 4, 0), Size = UDim2.fromOffset(30, 11),
                    TextXAlignment = (i == 1) and XL or ((i == 5) and XR or XC), W = (i == 5) and 3 or 1, TextSize = 8, TextColor3 = T.faint, TextTruncate = NOTRUNC})
                if i == 5 then skin(l, "TextColor3", "accentL") end
            end
            local fpsS, pingS, fills, segs, psegs = {}, {}, {}, {}, {}
            for i = 1, N do fpsS[i], pingS[i] = 60, 40 end
            local fadeSeq = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.34), NumberSequenceKeypoint.new(1, 1)})
            for i = 1, N do -- isi area di bawah garis FPS (gradien memudar ke bawah)
                local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), BorderSizePixel = 0}, plot)
                skin(f, "BackgroundColor3", "accent")
                new("UIGradient", {Rotation = 90, Transparency = fadeSeq}, f)
                fills[i] = f
            end
            for i = 1, N do psegs[i] = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.mid, BackgroundTransparency = 0.25, BorderSizePixel = 0, Visible = false}, plot) end
            for i = 1, N do segs[i] = skin(new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false}, plot), "BackgroundColor3", "accentLL") end
            local dots = {} -- titik terang di sebagian titik data garis FPS
            for i = 1, N, 3 do
                local d = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(5, 5), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2, Visible = false}, plot)
                corner(d, "full")
                skin(stroke(d, T.accentL, 2, 0.5), "Color", "accentL")
                dots[i] = d
            end
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
                    if dots[i] then dots[i].Position, dots[i].Visible = UDim2.fromOffset(x, y), true end
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
                pingT.TextColor3, pingP.BackgroundColor3, pingD.BackgroundColor3 = q, q, q
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
            corner(cm, 14)
            stroke(cm, T.outline, 1, ART.ok and 1 or 0.4)
            artRim(cm, "base", 1)
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
            local function paintFill() fillG.Color = ColorSequence.new(T.accent2:Lerp(T.accent, 0.45), T.accentH) end
            paintFill()
            themeFns[#themeFns + 1] = function() paintFill() refreshLB() refreshLog() end
            showView("lb")
            exN.Text = tostring(stats.exec)
            exD.Text = "↑ +" .. stats.today
            exD.Position = UDim2.fromOffset(14 + textW(tostring(stats.exec), 21) + 10, 41)
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
        if not groups[gname] then createGroup(gname, c.GroupIcon or ((gname == "Menu") and "sliders" or nil)) end
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
        if C.FlatDashboard ~= false then FLAT[dashGroup] = true end -- pil Dashboard tanpa header grup (FlatDashboard = false untuk header lama)
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

-- DATA BANNER (2 lapis PNG transparan 480x152, base64, tanpa kursor). Jangan diedit.
BANNER_B64 = [[
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
]]
BANNER_B64S = [[
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
]]


-- DATA PILL (3 lapis PNG transparan 749x120, base64). Jangan diedit.
PILL.B = [[
iVBORw0KGgoAAAANSUhEUgAAAu0AAAB4CAYAAABGisy+AAAc1ElEQVR42u3deZBsV2Hf8e+93fPe0/q0IbQgGQmEkYwIUGyJkR3KMmYLIaZA2C4nqcQVyolx4hhSjssOqfxBnMSQOLEreMEbIGJHiSsWGLtsvIKxEIoLJGOwIkACYUDbE9ITb5m+N3+cc5jzjs7tnqWn
p2fm+6mamplebt/13N85fe65Td/3SJIkaVATf2bpN/ncIhwGDhTz0VTmr6k838a/y2VIj7fZ36Pi/V183wg4Dnx+A/OcT2uy33fCscehJEmac8Dda/o5he6mCLznAZfEQJqe6+Lfq/Hx9Lmr2XO1ikCf/bQx8E5iUH8ycH78O5+Ppnhv/v8oC+Oj+JOCe5qPlZglDwCH
4u/TsvcBnMgy5zHg/8XHvlqEfuI0PgTcF5f3WKWSMK0S1AxUlPZEC3VjS/tCC65mCwVbv4nPm0ftvlmiVoL1HpzavcdLedLYC/vpsq5nKidtba6M7udcNjUzPmurx0htWhs9//TbcL5ZZodjuF6trL8uC71d8X/6OQYczELzMeC6OE1i+CWG7DZO4zhwMgvuJ+Ljo0og
Tcf1JHvNSnzPYeAlMSR3cfp9EcBTeG4qZcU4C/H5e9JjB+NrDgGnx2Ucx5+TWWVjnH3WPcDXsgrBOE47BfvHgLuAD2bL+bE55Zldu4/u1dDeFCemfkGfaWiQJO0HefBrs59xDHF5C2o6J46z0JpPJ+9aMc7+XsnO500W8NI02yJcdpX5IgvOZegsM0OX/T8qssRh4ALW
Wpi7LEx3MZwez0Lqavw7vf5e1lrOG+AR4JXA82NAXcnmvYth+7EYbE8U0x8x3FI+ia9ZyULyyfg5Ly4Cel6paIr1SZzffJ7yz+yyx1JwPy3+PlRst+PF+r6P0EUm7+2xks3HGPhifN2h+P4e+HQM9Gk9vj8uW5r3q4Bvj+sW4LPAXwIPxp9ut+e1vdQ9pqnshIuUf15e
Cx7HmufBrBY6igXXKDt4apWNSbE83ZQWnYZT+5Plte7VyrSarNBri7+pzFNXzMOkWM99ZVs0U7ZPrisKnabSktEWhWhbzG+X/ZQtDxTrrtaS0FfWde11zcBB3w+0YPVT9tWh9ZW31qxM2a9rf5f9DpsZ89VXCrJ+SqscxQm2tq80U5Zz2vRntbR3cV9uis9vi+mtxpPc
ZGD+hrZ7bT2W+9DQ/M/a1s3AZwy1gI4qLV99Ma1J1vKWh5O22P5t5acrni/LmL7yebWQ0FXKlNqxWwaLbmCfru2vbRESa+u/qxzjbeWzm4Ft2wyUw+06tu20cpnKcrczWvyayrHUTXl9VwQipmz/vrItGFhPKUQezFpa24F9Kl8XqXvEKGttnWTnw0PZfJchfZy1uLZZ
+ZfW8UoRbvMuHCeLc17qzpGfr0Y8vr91+px82UeV42KSbb9R8VhqST+RlT2rxXI/ADyclVGTGCSfFMNmU0x3NYbV4/H/SVYhGE3Zx9LylsF8FbgSOGMH8tmZxf+nA+dm+1VZATsGPAqcHZc5Lfel8blH4jJemwX6bwDOAs6J77soBvYbY8Xnr4AvA0fjtlhP+b18QXcX
t7RP+/rxYuBZwLOBPwL+dE41qqZyYkwFyRmEr7muJfQbOzv+vgi4HLgsFmQHssJpKNyWIYEplZFa+GsrBfpQoT908qrNUzcQdIZaYYZCWfnebkYlqJyntjj51kJXPxBs+ynrm0pgKYPurK+t11O5GwqztQJ4NGPas8JCM2M++inP1cLBiaw1ramEumYd8zBUMSv3w1pF
qBsIWE2xn56MhfNkoJKxMrDuusrrqexTTaVVr5tRMWmLfb2dsZ7GU45RspP4rP0uDyVtEZjKMDyrnGkG1ketsjW0T3QDx2kzYz9upszXUAWgmVFp7mdUMKdVetfzVXszsJ6agX1laJ3Nurixq1TYmFKZprIfMBBchxoB+oGyvVnHumZKw0IzsE+dLBoNKB5L6+BEcdx3
RYW/PI+sZOfl8ic/xldnNEx0U/aJ9LoTxWMn43F+pl/cPM7JbL1OsorMozG4p/D+UPz7cPZNzvnAN8btcEcM6bcBnwFuj5WnI8D9WaWIgf3TlvZtaNkmbqirge8gfOV0Tfx65RHgz9j8Vce1FuLTY431zBjWL44/1wDfQvgKLV2QsRvXa7Ogz0mfNakEm36gdbZs7ZlW
+DNlOltd5n4dwXiz+/QyX8TVFa04s07A/YzWjI0uc7vObXZs4FuEdsbJt+HUC646hr8ZorIflpWYacs/9I1EWseHslbJmkmsmNQqBZNKy9aBDezzsyqD+1XPxr5ab1hcmbrXHaw8dmiHP3+jDkwpV2eFxXmEyNESZ7jyuFkZeO6MrMycxBDfxe2TV7KOx/V9bXzf8wkt
7x8A7iR8y3Ec+EoM8A/EaU1rONpxu6mlvdYS8QTCVyxXAt8LXB8DM4SvQ24E/iPhSuXNBK2y5eZ04ArguYRW/GsJX8ccjs81cce5gLWrnk9fkpNfP2O9bjWwb+VC2WlBeFZXilk141qo7KdMa6P74zxr5LvhIpmdDh/rLVDLPqsbuXhvoxWPZgvl2LRg2M84ydYqJeup
8GxmO3udzuzyo5mxLaVlLVd3Y4V5I8/l6/jLhOsL7iK0wt/NqS3298Ygf2wZw/tuCe15oXh2DMzPiCehy4CXE1q50wZaBT4CvAX4wy1+9qXAUwjdXK4Cvin+XBED+0Z3IEmSJG1PuJ/W8JB3Z/oSofX9jhji749h/QHChbKfXbbgvuzdY8rxQl8IvIrQBeYq4FZCt5Sn
cmqr2igG6itZu1grvxgjDdm0Qujikm42cDK+9iDh4pBrs4B+btyYF8T3tKzvIkNJkiQtLjdOezx1s70k/jwvBvTbgU8SulY/kXBR62dYu4B4x8P7sra0l8MvPQe4AXgNodU7zfRjzL4S+nNxhaeLU/IL/M4jXLCQxgU9Qvia5EAM6QdZu3L+9EqtzXAuSZK0+5Q57iSh
hf024OPAFwjXDX2UMK78zofjJQzt+cVUFwF/H3gDodWcGL7TEFGzNkaqAByvbJw0HBXZdI+zNpxSuqK8NuSXYV2SJGlvhPc823WEayH/IIb3I4SuNLcQGot3rMV9mUJ73ro+Bl4P/HNC//V0O98yrK+ntXs9FyjMCuK2qkuSJO2f8P4wYcjwWwit7vcBv08YZWZHgvuy
hPa87/rVhAtIb8ge69nYyAdb3WgGdEmSpP0b4FMW/DRhUJNPEfq4f5DQbWbhwX0ZQnu+0K8H3kq48HPRYV2SJEmCU1vejwLvJ7S030MYofDIooP7Tof21H/9LELr+g8S+pJPWK6bAEiSJGl/hvd0B9sPAO8jDA95N/B/WeA9VnZyyMcU2K8Efhp4WVxgA7skSZKWQWpN
XwH+DmHkwd8gDP89Jowuk79uz4X2UQzn3wS8i3Cxabo1uoFdkiRJyxTc0+8XEe7Z87+BQ/HnTuCvOXUExPnPxA50j0mB/dnArxNujGTruiRJkpZZ3s/9CzHH3hlz7EcJQ0RuW3BfdGhPgf0q4DeBp7M2lKMkSZK07LoYzr8AvJdwn58GeDdhlJltCe6LDO1pAa6OC/Uc
bGGXJEnS7pMuUL2bcCfVO4CvADcBt29HcF9UC3ce2N8L/A0DuyRJknapdOHpNwCXxUz9YeA6wnCQn2fOF6cuYgz0FNifBPycgV2SJEl7JLinrjKXxt8rhIFWWuZ8s852QQtzEfBOwhW3qwZ2SZIk7QEtoTX9MuAVwBOBi4FnxQzczPODtjOwQ/i64KeAlxBa2L3oVJIk
SXtJDzwFuAY4CFxBGMu9n1fe3s7QnmoePwS8jrVx2CVJkqS9ook/I+ClwDcTxnJ/OXA2c2px367RY9LQjq8m3DzpjGyhJEmSpL0mjSjzKGHglU8C9wM3A1/NXrMp29Hy3cbA/kLgZ1j7asDALkmSpL0qjRZzJvB64GmEO6Zex9r1nJvOw/MO7WmkmMuBXwAuIVx4arcY
SZIk7ZfgfhbwtwkXpp4Xs/GWurfMM0ynwH4Y+HnCcDdeeCpJkqT9FtzT/Ym+EzgXeD5wIVvofdLOceZ6wtiUb2NtpBhb2CVJkrQfg3tPuD/RSwgXpD6NLdxwaV6t4Kkf+48D/xhvniRJkqT9HdqJefh64KGYjxvCnVNTcF93gJ9HaB8T+q1/D/AjrN0ZSpIkSdrPeuAA
8CrgsSwjf4gNtrhvNbSPYmD/NuC/ELrHOFKMJEmSdOqFqa8DTsafVeCW+Ny6wvtWQnvqEvMs4JcIg8jbyi5JkiSdGtzTYC03EMZsPxaD+62ss5/7ZkN7GinmacCvAJcZ2CVJkqTB7NwD5xNGlLkP+BqhBf6R9U5gs7WF84CfBZ6JY7FLkiRJszJ0T2j0fg3wBOBvAqfF
55p5hvY0sRXgzYRB4x2LXZIkSVqfHnghYSjIc4FLWUff9vEmP+jVwPdjlxhJkiRpvZrs98uAzxD6t0+Au6eF9/EmPuRlwFuAM4rHJUmSJM3WA2cCrwW+HP//CnCUgQtT19tKnt78VOCNwDXxMVvZJUmSpI1J2fpK4BWEC1KvZm349MdZT0t7GinmCcAPAt8a//eOp5Ik
SdLm9cA3A58mdJN5kNBl5nGt7bNaytMbDgHfRWjCPx1b2CVJkqStSF3MDxHumPqk+HOAys1K1xvaX0gYDP5MQiu7/dglSZKkrQf3Pob1lxF6tlxae+F4xkQ6Ql+bfwI8N4Z8W9klSZKk+emBFwF/Trjp0lHChalf7ybTzkj9FwLfR+ggfwDHY5ckSZLmKfVgOSNm7nOB
ywjXj369X/u0VvMR8FLge4GzmTHguyRJkqRN6wkjyLwIeCJwXv5kO+VN1wE/AFxCpTO8JEmSpLlIOXsMfAtwMaGLepOeawfecC7wGuB52IddkiRJWpQrCfdEugC4iNh4PhTaX8zaeOyOFiNJkiRtr3yo9RcQGtFXGGhpT54LnAPcB5xwHUqSJEkLcw3wZOCKmNf7MrSn
i03/AvgAcBPwpfhY5/qTJEmStk1qbT8XeAbhpqaXw3BL+xeB98XfZ2cTkSRJkrT9nkkYReZQGdrbmOwvIQwxcxXwhvi3o8dIkiRJi3M5Ybz2Hhil0J7ufjoGng4cJozPfrmBXZIkSVqY1EXmdEK/9guAc/I7nI4II8Y8HXgV8KwY5B3yUZIkSVqsHjgzhfhx9uBVhCb4
64Dr42MGdkmSJGmxUi+XCwkjOrYptJ9NGObx7wEvYa1/uyRJkqTFSV3TbwJ+CngQeDS1pF8KvBJ4BXAA+7FLkiRJO+lvAd9IGBTmUArtzyAM4v4R4M9ZuzBVkiRJ0uKkhvNLgHcCb06h/RzghhjSj8bwDvZnlyRJknbKMULvlyPAY2PCcDJPB64mNMEfch1JkiRJO+q0
GNpvA462wJeBDxNa1g3skiRJ0s5K3dTvBH4XmLTABPht1prgJUmSJO289wOfgrV+638M/AlegCpJkiTtpHSvpOPAB2M+b9v44APArwJfcz1JkiRJOyY1oH+KMKpjD6eOEPPbwCfjY7a2S5IkSTvnt4C/JvaESQG9Ae4H3oU3VpIkSZJ2Quoa8yXg5jyX5y3tDXAjYVgZ
+7ZLkiRJiw/tDaEHzK3ZY18P7ekF9wH/LQvxjiYjSZIkLS6wP0zo/bIas/rj+rSnF94M3GJolyRJkhYe2n8H+NMyi9dC+0PAf2etr7vBXZIkSdr+wH4U+BXC/ZMGQ3v+ht/EcdslSZKkRUiN5X8A/B6VhvOh0P4Q8GPAvcAIW9slSZKk7dDHvH0f8B+AE+sJ7XnS/xDw
o4QbLtlNRpIkSdqe0N4BPxHzd/WeSe2UN7fAu4H/mj0mSZIkaT4mMXP/H+AdTGkob/p+MIunN50D/E/g+pj6W9evJEmStCUpV38CeBVw97TQPi2Ap9b2I8C/Bj5LNlakJEmSpE1J15E+CPxwDOxTc/asVvPUv/1jwA8BD2D/dkmSJGkrgT2F9p8gjBYzs2G8XeeEU1+b
txLuzmRolyRJkjYudYv5ZeBtrF14uuXQTlYbeAfwTuwmI0mSJG3UhDC84x8Db2ID90OadiHq414bg/q5wM8Cr8ULUyVJkqT1SLn5c8CrgY8zMLzjVkM72YSfQhhR5tkGd0mSJGmqFLgfBb4beB+hxX2ykRC+mRrCXcA/BT6/kRqCJEmStA+lrPzWGNg3nJ/bTX5oC/wZ
YSjIR7CPuyRJklRKdzsdEbqXvz3LzRvu7rLZGWiB9xCGqll1m0iSJEmnSI3dNwFvBk5sJrDDxvu0n/Le+PsA8NPA92H/dkmSJCkP7B8h3PH0frbQrXwroZ3sgy8F/hfwAoO7JEmS9rk0tOPdwCuBO9jidaBbDdcpoN9LuAXrnXhhqiRJkvav1If9IUJPlDvi/1vKx/No
EU83Xvow8M8II8t4YaokSZL2m5R/VwkN2r/HnBq05xXa+1iD+F3C3Z2+xNrNmCRJkqT9IPVC+bfAL8V8vKkLT0tb7dNeqwR0wD8EfhI4n7WWeEmSJGmvSv3Yfwb4gSz/ziVsz/uC0TQU5C/HGT7u9pMkSdI+Cey/AfzIvAP7doX21LL+duBG7CYjSZKkvR/YbwXeCDy6
Hfl33t1jvj7dOKOXE1rdX4xDQUqSJGlvBva7CWOxf4JtGklxu0J0ujD1HuBfALfjiDKSJEnaO9LQjg8C/yAG9i0P7bjo0J5qHm1cgB8DPu+2lSRJ0h6QuoMfBb4f+KMY2Cfb9YHb3V0ldYm5Gfhx4IFsQSVJkqTdGNh7wljsbwJ+fbsD+yJCex7Q3wu8KwZ5Q7skSZJ2
o9Qo/XbgHWxTH/adCu0NcAL4T8CvZQtneJckSdJukS48fQ/hBkpzH9pxyHaNHlP9rLhAlwJvA16XPS5JkiTthsD+W8B3Aw+zwKHNFxna8+D+pBjcXxP/H7sfSJIkackD+yeA7wTuYkHdYpJFj5ue7pj6BeBfAu8mXHVrNxlJkiQtc2D/FPCPdiKw70Roh7XO+/cCbwF+
h9ACbx93SZIkLWNgv4MwFvttOxHYdyq058H9buBfATeydsFq5/4hSZKkHbYaA/tthD7sH92pwL6Tob0M7m8E/jNwfCdXhiRJkva9ntDCPib0CHktcPtOZ9RFX4g6VHHogAMxvL8JuCg+1uDoMpIkSVqM1B0G4BeAHwa+ygJunrQbQjtFzeU7YnC/Plt5reFdkiRJ2yRv
XX8U+HeEmydNWJJeIMsS2uHUwemvAP4NYUjIs+LjqTuNJEmSNC95A/HHgR8ljMUOS9Rte5lCO8XKOR14KfAG4DrgNNZGmLHlXZIkSVvRxZ8x8Bjwq8C/B+6JWbNniUY2XMbQXtZqzgb+LvA9wAuAc7IVbZ93SZIkTdNzao+OPsubAL9P6Arz/koOXRrLGtrJAnlaaU8A
Xg3cADyftW4zKcDbdUaSJElDwR1Obez9BPDzwC8SWtqb4rWG9i2G90uAFwMvB55H6P8+Bk6wNgqNLfCSJEn7I4hTyX2pRX0CfBq4htDAewz4C+Am4F2Em33CEnaH2Y2hPd8Y+cyeCTwH+C7g22JwP5dTu89ggJckSdpzyl4WeUhvWRu28VbCzZFeAdwJ/BrwPuCLuyWs
78bQThHCUyg/DbgKeDKh+8y3AxdnGysP8NNqZwb7xW9HdsNBsg0VzmX4zPz5eW2L2mfup+28Xn22rppdvhzLeJw1e7zsaHbxdmvWOW/NHJalWedr99L+Uu7/s46HfoHlxEbmZT3bJA/rjwFHgAsJDbjJSeBm4H8ADxF6ZNzFLmpZ3wuhfVoYOA14BuGC1RcBzwUuB1bM
CbuigJHbWdLGwmrPqQ1ToyyINJXzZrNE812WD+1AmKy9dtaydFOWe+iiRCqPNZXKU1f5rKZS8WimbIe+CKDNQHjtK+ulGQi5m2kg2q1l8yrhDqXvievnW4GnxeduAf4K+Bjwh8DX1pEfDe0LDu9NpeB6KvDM+PtK4DLgMHAoBvmW0Af+QPx/Jb4v36BtceA0A60CffaT
hhDKC842O7Dz16TprGSvLafXDxTCbVHYpem22WvTZ46y15cH+GhK4dJnB0iTTTt9ZpstW1dsh74obNP8TSqf3VZqvU22HinWWVMpcJps+lTWZ0voVrWeCmBTTCM99zCn3hGtXH/5iSet89N4/Fd4XVaQTIp5LddNM1BI98W8NMW2b4r9sK/st2nbjbJ5bCpBoK+sT4r9
oDxu8u2Z7yP5duyyz+orx02+3UfFus2Xr60cD032utXKvK0WryvXZ1ccq+l9+Wd3cTq1k3xb2SfbYrnK9d5m+8RqsVx95fhL64LKsVbbp2eFuKFWp77ymvJzatuyq5SbzcDvfL8YVfbBtjjm2kqZNSqOx3xeRpV9u2zZbYv9Y5Jt40lRhrdFq95QAOqK5cmnMymWcSU+
fiKWD5PKPtQVx3qat1G2DOkGMXkXASpld1pnK9mytMV26wbKmabS8tlPOY81lfePKmUsRTnRV45pKqG7HdgGk6IsyJdjUpwr07ROTpluWxzzXWV52+LYLsv+WqZIrz1ZKSvGA8dvX1QYmmKZu8r5imz+m8p2bSuvnxTbZ5QdF02xLlaAg5X567LpTOJyHs+mnx+/4+JY
Xs1ecxL4S+BDwJ8An4sZ7wLCDZHuAb4ysG827LKW9b0Y2msnoNpGaYEz4s60khVo4+z/VHgdynaWcXbwlaG3Gwh9kyLENsXJoC3CWJMd5H1RcOYHIEUlYFwUtmVwKAPxqPK5o8rz7UBlpKwIkK2f8rWjKcGaYv5XikpDkx2wfSWQ5CfBUfH6Lh7Uk6IgIIbn/MQ2KgJR
WSHqioA4iSfSR7N5mVRaONLrDxDuN3BGERLyAutEFtBWswK1yyqRaR3l23hcqQA22etG2Ql9tSgwh8LKUHjrB1r08grnwTiNr8b1Uztxp21zLP5uByoX+edPiudqIbsvTkJdZZuWJ67xQKV7km2PtM6OF0FplM3TpDjey9CStufx+FNWCvIT5MEssHWVoDNU5tWO/65S
DrZF6KdSKeyntETWAnr+eZOBz26K42xawO2Lk+y0CvrQ46OB80BeZo2L+apNI98X+kpgpgiQo0qZXmuc6It9g+K9FJXMPit/miKEN0XliCzglNs731fb4nhui8pfVzmnkQWq2vnqQHF+W8nmqSvWSX7OGU1p8Bo69mut2EOt2asD27irBPNJpbKQXjsuPndSnI/LY7Js
4JhUGuvaSgWvVslos3VPpeFjUmy3bkrD36TYF/rKvtZXKiFdsbxlI0deboyy+VqNZf6xInxPigY2KvtHXgntsgrTA/H3OOa1E/GHSqNmxx7qnrnXQjtTWnO6JZ3P0UABPhr4uo3KtwBNJXxQCaTlibMpDozayb0ZCGDTWpearGBvKpWUtlJROEAYk788MeQFe97CWT63
EqcxqrSCpxPKwUrLTVv5dqAtWnDLlr+jWYF0ImuVScu2klVKzsqWpQw9qdA6AtydtVycrHxD0mbB7vyiMDtRvH4lFmpHixNQ2apXa/ka+tqw/Laj1sJJ/MyjA+GvqwSMphIcy2/NJgPHcL5MtZPtpJhvKoF6qFDvB9aZtKxWspCaHIjlwyKuqzlQOacMdXepVb6Gvukc
eq4ZqMCVFZ1uoOGoFsxrFd3aZ/XrqIC21L9VXG/XjGZGw8pQvpk1mkr+7dPqOrfteOCbOaY0zOXLfHKbMl4/0GgLe/Q6qr0c2mcdANN2uu1cKdO+el7UPCyrwwMtJ02lcK89V/uqsS0KvCdWWllTuDsS5yFvhWqySsVjwP1FIKy1rpYnrQtji3sqJFvCRTGPxnk5Ajy4
gf34wqKFoq9UmB7YQIGs2eXGrMe2Mr1p5cCy63fB9lqWee4XNP2NXIi4mX263yX7guZTtvVb2M7NnMpNBhpV9p3/D+8tKhIzcMSqAAAAAElFTkSuQmCC
]]
PILL.T = [[
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
RU5ErkJggg==
]]
PILL.S = [[
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
]]

-- DATA ART (4 PNG putih + alpha, base64): glow / ring = 9-slice, radial = cahaya bulat, icons = atlas ikon 64px. Jangan diedit.
ART64.glow = [[
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
TkSuQmCC
]]
ART64.ring = [[
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
]]
ART64.radial = [[
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
URpNewAAAABJRU5ErkJggg==
]]
ART64.icons = [[
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
]]

return SORU
