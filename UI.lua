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

-- BANNER: banner NEXRIFT (logo N + wordmark + tagline + strip diagonal) di pojok kiri atas sidebar, WARNANYA IKUT TEMA.
-- Dibuat dari 2 lapis PNG (base64 di PALING BAWAH file): BANNER_B64 = lapisan tint (bingkai, strip, logo N, huruf X) yang diwarnai aksen tema, BANNER_B64S = tulisan putih + tagline (tetap).
-- Dipakai otomatis kalau C.Logo / C.LogoUrl kosong. Opsi: CreateWindow({Banner = false}) matikan, CreateWindow({Banner = "rbxassetid://ID"}) pakai gambar sendiri (warna tidak ikut tema),
-- CreateWindow({CodeBanner = true}) paksa banner buatan kode. Kalau executor tidak punya writefile/getcustomasset, otomatis jatuh ke banner buatan kode.
local BANNER, BANNER2, BANNER_B64, BANNER_B64S = "", "", "", ""
local NEXBANNER = false -- true = banner NEXRIFT buatan kode (cadangan kalau gambar base64 tidak bisa dimuat)
local BN_HSHIFT, BN_SBOOST = 0, 1 -- gambar NEXRIFT sudah putih+alpha -> warna tint = aksen tema apa adanya (hanya dibuat terang penuh)
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

-- PILL (launcher di atas layar): gambar 3 lapis seperti banner. PILL.B = body gelap (warna ikut tema), PILL.T = lapisan tint aksen (halo merah menyala, bingkai, logo N, huruf X, garis; ikut tema),
-- PILL.S = tulisan NEXRIFT putih (tetap). Base64 ada di PALING BAWAH file. Bar sinyal + angka FPS digambar LIVE di atas gambar.
-- Opsi: CreateWindow({Pill = false}) = pill polos lama (tanpa gambar), CreateWindow({CodePill = true}) = pill buatan kode. Kalau executor tidak punya writefile/getcustomasset, otomatis jatuh ke pill buatan kode.
local PILL = {B = "", T = "", S = ""}
local PILL_H, PILL_ASPECT, PILL_OFF = 36, 1129.5 / 171, Color3.fromRGB(62, 60, 70) -- tinggi pill (px), rasio bingkai pill, warna bar yang mati
local PILL_IMG_FX, PILL_IMG_FY = 1213 / 1129.5, 254 / 171 -- ukuran gambar relatif pill (lebih besar: ada ruang untuk halo merah di sekeliling)
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
    elseif name == "crown" or name == "gem" or name == "rank" then -- ikon rank dari Frame (tidak bergantung font/emoji, jadi tidak jadi "[]")
        o = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size)}, parent)
        local parts = {}
        local function part(cx, cy, w, h, rot, r, col, tr) -- pusat (cx, cy) & ukuran (w, h) dalam fraksi `size`
            local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(size * cx, size * cy), Size = UDim2.fromOffset(math.max(1, size * w), math.max(1, size * h)),
                Rotation = rot or 0, BackgroundColor3 = col or color, BackgroundTransparency = tr or 0, BorderSizePixel = 0}, o)
            if r then corner(f, r) end
            if not col then parts[#parts + 1] = f end
        end
        if name == "crown" then
            part(0.5, 0.58, 0.84, 0.30, 0)           -- badan
            part(0.5, 0.82, 0.84, 0.12, 0, 1)        -- alas
            part(0.17, 0.40, 0.26, 0.26, 45)         -- 3 ujung runcing
            part(0.5, 0.33, 0.32, 0.32, 45)
            part(0.83, 0.40, 0.26, 0.26, 45)
        elseif name == "gem" then
            part(0.5, 0.5, 0.60, 0.60, 45, 1)        -- berlian
            part(0.5, 0.5, 0.26, 0.26, 45, 1, WHITE, 0.55) -- kilau di tengah
        else -- "rank": 3 chevron bertumpuk (lencana pangkat)
            for _, y0 in ipairs({0.12, 0.37, 0.62}) do
                part(0.5 - 0.22, y0 + 0.17, 0.56, 0.14, -38, 1)
                part(0.5 + 0.22, y0 + 0.17, 0.56, 0.14, 38, 1)
            end
        end
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
            if not C.CodeBanner then BANNER, BANNER2 = loadBanner() end -- banner gambar base64 (default)
            if BANNER == "" then NEXBANNER = true end                    -- gagal dimuat / executor tanpa file API -> banner buatan kode
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
        local NEXPILL = false
        if C.Pill ~= false and not C.OldPill then
            if not C.CodePill then pB, pT, pS = loadPill() end -- pill gambar base64 (default)
            NEXPILL = (pB == "")                                -- gagal dimuat / executor tanpa file API -> pill buatan kode
        end
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
            -- PILL NEXRIFT (gambar base64, 3 lapis): body gelap (ikut tema) + tint aksen (halo merah menyala, bingkai, logo N, huruf X, garis) + huruf putih.
            -- Gambar sedikit lebih besar dari pill supaya halo-nya keluar dari bingkai. Bar sinyal & angka FPS digambar LIVE di atasnya (posisi = fraksi ukuran pill, diukur dari gambar referensi).
            local PH = PILL_H
            local PW = math.floor(PH * PILL_ASPECT + 0.5)
            launcher = new("Frame", {Name = "Launcher", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(PW, PH),
                BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 90}, root)
            local function lay(name, img, z)
                return new("ImageLabel", {Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(PILL_IMG_FX, PILL_IMG_FY),
                    BackgroundTransparency = 1, BorderSizePixel = 0, Image = img, ScaleType = Enum.ScaleType.Stretch, ZIndex = z}, launcher)
            end
            local lBody, lTint = lay("PillBody", pB, 90), lay("PillTint", pT, 91)
            lay("PillShine", pS, 92)

            -- bar sinyal: 3 bar + 1 bar abu di kanan (menyala kalau FPS sangat tinggi). {x, y, lebar, tinggi} dalam fraksi pill
            local sig = {}
            for i, g in ipairs({{0.6711, 0.4912, 0.0151, 0.2632}, {0.6968, 0.3684, 0.0151, 0.3860}, {0.7224, 0.2632, 0.0151, 0.4912}, {0.7481, 0.4094, 0.0133, 0.2573}}) do
                sig[i] = new("Frame", {Name = "Sig" .. i, Position = UDim2.fromScale(g[1], g[2]), Size = UDim2.fromScale(g[3], g[4]),
                    BackgroundColor3 = PILL_OFF, BorderSizePixel = 0, ZIndex = 93}, launcher)
                corner(sig[i], "full")
            end
            local fpsL = text(launcher, {Name = "FPS", Text = "--", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.8796, 0.512),
                Size = UDim2.fromScale(0.14, 0.7), W = 4, TextSize = math.floor(PH * 0.37 + 0.5), TextXAlignment = XC, TextYAlignment = YC, TextTruncate = NOTRUNC, ZIndex = 93})

            local curFps, hov = 0, false
            local function tcol() return bannerTint(T.accent) end -- warna lapisan tint = aksen tema
            local function paintSig()
                local lit = curFps >= 90 and 4 or (curFps >= 50 and 3 or (curFps >= 35 and 2 or 1))
                local col = curFps >= 35 and tcol() or (curFps >= 20 and T.warn or T.bad)
                for i, b in ipairs(sig) do b.BackgroundColor3 = (i <= lit) and col or PILL_OFF end
                fpsL.TextColor3 = curFps >= 20 and Color3.fromRGB(236, 239, 247) or T.bad
            end
            local function paintPill()
                lBody.ImageColor3 = T.side:Lerp(T.accent2, 0.09)
                lTint.ImageColor3 = hov and tcol():Lerp(WHITE, 0.22) or tcol()
                paintSig()
            end
            paintPill()
            themeFns[#themeFns + 1] = paintPill
            launcher.MouseEnter:Connect(function() hov = true play(lTint, {ImageColor3 = tcol():Lerp(WHITE, 0.22)}, 0.2) end)
            launcher.MouseLeave:Connect(function() hov = false play(lTint, {ImageColor3 = tcol()}, 0.2) end)

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
            do -- badge rank di samping nama: mahkota + permata (digambar dari Frame; emoji 👑🔮 tidak tampil di font ini -> "[]")
                local bxr = 66 + math.min(textW(LP.DisplayName, 14), 108) + 8
                mkIcon(pc, "crown", 14, T.warn, {Position = UDim2.fromOffset(bxr, 21)})
                local gem = mkIcon(pc, "gem", 14, T.accentL, {Position = UDim2.fromOffset(bxr + 18, 21)})
                themeFns[#themeFns + 1] = function() gem.tint(T.accentL, 0) end
            end
            lb(pc, "@" .. LP.Name, 66, 38, 150, 12, {W = 1, TextSize = 9, TextColor3 = T.faint})
            local bx = pill(pc, tostring(C.Role or "OWNER"):upper(), T.warn, 12, 64)
            bx = pill(pc, tostring(C.Version or "V1.0"), T.accent, bx, 64, true)
            pill(pc, tostring(C.Plan or "Lifetime"), Color3.fromRGB(110, 118, 255), bx, 64)

            local lc = card(r1, UDim2.new(0.4, -5, 1, 0), UDim2.new(0.6, 5, 0, 0))
            mkIcon(lc, "rank", 26, T.warn, {Position = UDim2.fromOffset(12, 13)}) -- logo rank (glyph ≋ tidak ada di font -> "[]")
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
                    if e.Crown then mkIcon(r, "crown", 11, T.warn, {Position = UDim2.fromOffset(49, 0), ZIndex = 5}) end -- mahkota di pojok avatar (bukan emoji)
                    text(r, {Text = e.Name, Position = UDim2.fromOffset(66, 3), Size = UDim2.new(0.42, -66, 0, 16), W = 3, TextSize = 11})
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

-- DATA GAMBAR NEXRIFT (PNG transparan, base64). Jangan diedit.
-- BANNER_B64 = lapisan tint banner 548x188 (bingkai, strip diagonal, logo N, huruf X) -> diwarnai aksen tema | BANNER_B64S = lapisan statis (tulisan NEXRIFT putih, tagline, garis)
-- PILL.B / PILL.T / PILL.S = pill 774x162: body gelap (ikut tema) / tint aksen (halo merah menyala, bingkai, logo N, X, garis) / huruf putih
BANNER_B64 = [[
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
]]
BANNER_B64S = [[
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
YII=
]]
PILL.B = [[
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
zQAAAABJRU5ErkJggg==
]]
PILL.T = [[
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
AAAASUVORK5CYII=
]]
PILL.S = [[
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
AABJkv8H11wkpMrCPTsAAAAASUVORK5CYII=
]]

return SORU
