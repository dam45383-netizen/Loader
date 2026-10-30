local SORU = {Version = "1.1"}
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
local LOGO = (ICON ~= "") and ICON or "rbxassetid://119521146805131" --  kalau ICON gagal diunduh

----------------------------------------------------------------------
-- THEME: palet . Aksen bisa diganti lewat Settings (45 preset)
----------------------------------------------------------------------
local T = {
    -- permukaan, dari yang paling dalam: well (sumur input) < bg (dasar window) < side (sidebar / drawer / panel) < el (komponen) < hover
    well = Color3.fromRGB(7, 8, 11), bg = Color3.fromRGB(10, 11, 15), side = Color3.fromRGB(15, 16, 22),
    el = Color3.fromRGB(22, 24, 32), hover = Color3.fromRGB(32, 35, 47),
    -- garis: outline = hairline biasa, rim = tepi atas yang "terkena cahaya"
    outline = Color3.fromRGB(44, 48, 62), rim = Color3.fromRGB(86, 94, 118),
    -- teks: text (utama) > dim (deskripsi) > mute (placeholder / disabled); off = trek toggle mati
    text = Color3.fromRGB(236, 239, 247), dim = Color3.fromRGB(142, 150, 170), mute = Color3.fromRGB(88, 95, 114), off = Color3.fromRGB(38, 41, 54),
    -- status
    ok = Color3.fromRGB(61, 220, 151), warn = Color3.fromRGB(245, 185, 74), bad = Color3.fromRGB(255, 92, 108),
    -- sinyal: diganti oleh applyTheme
    accent = Color3.fromRGB(0, 140, 210), accent2 = Color3.fromRGB(0, 100, 180),
}
-- token turunan aksen: dihitung ulang di applyTheme, jadi bisa dipasang lewat skin(obj, prop, "hi" | "tint" | "wash" | "trace")
local function derive()
    T.hi = T.accent:Lerp(Color3.new(1, 1, 1), 0.4)  -- puncak kilau / glow
    T.tint = T.el:Lerp(T.accent, 0.16)               -- permukaan aktif (tab, baris terpilih)
    T.wash = T.bg:Lerp(T.accent, 0.08)               -- wash tipis untuk header / sidebar
    T.trace = T.outline:Lerp(T.accent, 0.5)          -- outline bernuansa aksen
end
derive()
-- skala desain (dipakai semua fase berikutnya)
local STROKE = {hair = 0.78, line = 0.55, edge = 0.3, focus = 0}      -- hierarki transparansi UIStroke
local R = {xs = 4, sm = 6, md = 8, lg = 12, xl = 16}                  -- skala UICorner
local SP = {xs = 4, sm = 8, md = 12, lg = 16, xl = 24}                -- grid spasi 4/8
local DUR = {fast = 0.15, base = 0.22, slow = 0.35, page = 0.45}      -- durasi motion (semua lewat play())
local WHITE = Color3.new(1, 1, 1)
local QUINT, BACK = Enum.EasingStyle.Quint, Enum.EasingStyle.Back
local XL, XC, XR = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right
local NOTRUNC = Enum.TextTruncate.None
local H1, H2 = 40, 56 -- tinggi elemen: satu baris / dengan deskripsi (kelipatan 8)

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
    "Purple 008CD2 0064B4", "Violet 9160FF 5E6AFF", "Ocean 28A0FF 3870FF", "Crimson FF4664 DC2650", "Emerald 2DD496 10AA78",
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
-- TIPOGRAFI "SIGNAL": Michroma (judul / identitas), Source Sans Pro (label & isi), Roboto Mono (nilai live, input, caption).
-- W lama tetap jalan: 1 = desc, 2 = label, 3 = strong. W juga boleh nama peran: "title" | "strong" | "label" | "desc" | "cap".
-- FACES[peran] = {Enum.Font lama untuk TextService:GetTextSize (sinkron), skala optik}. Source Sans tampak lebih kecil dari Gotham di ukuran sama,
-- jadi setiap TextSize "nominal" dikalikan skala peran lewat tsz(). Kalau terasa kecil / besar, ubah angka skala di sini saja.
local function enumFont(name, fallback)
    local ok, v = pcall(function() return Enum.Font[name] end)
    return ok and v or fallback
end
local FACES = {
    title = {enumFont("Michroma", Enum.Font.GothamBold), 0.84},
    strong = {enumFont("SourceSansBold", Enum.Font.GothamBold), 1.1},
    label = {enumFont("SourceSansSemibold", Enum.Font.GothamMedium), 1.1},
    desc = {enumFont("SourceSans", Enum.Font.Gotham), 1.1},
    cap = {enumFont("RobotoMono", Enum.Font.Code), 1},
}
local TS = {title = 15, strong = 14, label = 14, desc = 12, cap = 11} -- ukuran nominal default tiap peran
local ROLE = {[1] = "desc", [2] = "label", [3] = "strong"}
local FONT = {}
for k, f in pairs(FACES) do FONT[k] = Font.fromEnum(f[1]) end
FONT[1], FONT[2], FONT[3] = FONT.desc, FONT.label, FONT.strong
local function tsz(size, role)
    local f = FACES[ROLE[role] or role]
    return math.floor(size * (f and f[2] or 1) + 0.5)
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

-- UICorner: angka disnap ke skala 2 / 4 / 6 / 8 / 12 / 16, atau pakai nama R ("xs" "sm" "md" "lg" "xl"), atau "full" (kapsul / lingkaran)
local function corner(o, r)
    if r == "full" then return new("UICorner", {CornerRadius = UDim.new(1, 0)}, o) end
    if type(r) ~= "number" then r = R[r] or R.sm end
    local px = (r <= 3 and 2) or (r <= 5 and 4) or (r <= 7 and 6) or (r <= 9 and 8) or (r <= 13 and 12) or 16
    return new("UICorner", {CornerRadius = UDim.new(0, px)}, o)
end
-- UIStroke: tr boleh angka atau tingkat STROKE ("hair" | "line" | "edge" | "focus").
-- Tingkat "line" dan "edge" otomatis top-lit (tepi atas lebih terang, cahaya selalu dari atas); lit = true / false untuk memaksa.
local function stroke(o, col, th, tr, lit)
    if lit == nil then lit = (tr == "line" or tr == "edge") end
    if type(tr) == "string" then tr = STROKE[tr] end
    local s = new("UIStroke", {Color = col or T.outline, Thickness = th or 1, Transparency = tr or STROKE.line, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
    if lit then
        new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.5)})}, s)
    end
    return s
end

-- BAYANGAN: ImageLabel 9-slice (dibuat SEBELUM elemen yang dibayangi, sibling di belakangnya). Kalau aset gagal dimuat, diganti tiga bingkai bulat bertumpuk.
local ContentProvider = game:GetService("ContentProvider")
local SHADOW_IMG = "rbxassetid://6015897843"
local shadowState = {ok = nil, pending = {}} -- ok: nil (belum dites) | "testing" | true | false
local function shadowFallback(img)
    if img:GetAttribute("Fallback") then return end
    img:SetAttribute("Fallback", true)
    img.Image = ""
    local sp, layers = img.Size.X.Offset, {}
    for i, d in ipairs({{10, 0.2}, {22, 0.13}, {34, 0.08}}) do
        local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, d[1] - sp, 1, d[1] - sp),
            BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, img)
        new("UICorner", {CornerRadius = UDim.new(0, 12 + d[1] / 2)}, f)
        layers[i] = {f = f, a = d[2]}
    end
    local function sync() -- ikuti ImageTransparency supaya tween lama tetap bekerja
        local k = math.clamp((1 - img.ImageTransparency) * 2, 0, 1.4)
        for _, l in ipairs(layers) do l.f.BackgroundTransparency = 1 - math.min(l.a * k, 1) end
    end
    img:GetPropertyChangedSignal("ImageTransparency"):Connect(sync)
    sync()
end
local function shadow(parent, z, spread, dy, sc)
    spread = spread or 40
    local img = new("ImageLabel", {Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, dy or 5), Size = UDim2.new(1, spread, 1, spread),
        BackgroundTransparency = 1, Image = SHADOW_IMG, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), SliceScale = sc or 1, ZIndex = z or 0}, parent)
    local st = shadowState.ok
    if st == false then
        shadowFallback(img)
    elseif st ~= true then
        shadowState.pending[#shadowState.pending + 1] = img
        if st == nil then
            shadowState.ok = "testing"
            task.spawn(function()
                local failed = false
                pcall(function()
                    ContentProvider:PreloadAsync({img}, function(_, status)
                        if status ~= Enum.AssetFetchStatus.Success then failed = true end
                    end)
                end)
                shadowState.ok = not failed
                if failed then
                    for _, i in ipairs(shadowState.pending) do if i.Parent then shadowFallback(i) end end
                end
                shadowState.pending = {}
            end)
        end
    end
    return img
end
-- AURA: cahaya aksen (aset yang sama, diwarnai aksen dan ikut tema). Awalnya mati; tween ImageTransparency untuk menyalakan.
local function aura(parent, spread, key)
    local g = new("ImageLabel", {Name = "Aura", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, spread or 24, 1, spread or 24),
        BackgroundTransparency = 1, Image = (shadowState.ok == false) and "" or SHADOW_IMG, ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450), SliceScale = 0.3, ZIndex = 0}, parent)
    skin(g, "ImageColor3", key or "accent")
    return g
end
-- SHEEN: gradien fill vertikal, atas terang -> bawah gelap (mengalikan BackgroundColor3). amt 0..1
local function sheen(o, amt)
    local d = 1 - (amt or 0.12)
    return new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(d, d, math.min(1, d + 0.02)))}, o)
end
-- TRACE: motif tanda tangan, garis aksen tipis yang memudar. fade: "r" (memudar ke kanan, default) | "l" | "d" (ke bawah) | "mid" (terang di tengah)
local function trace(parent, props, fade)
    local d = {BorderSizePixel = 0, BackgroundColor3 = T.accent}
    for k, v in pairs(props or {}) do d[k] = v end
    local f = new("Frame", d, parent)
    skin(f, "BackgroundColor3", "accent")
    local seq = (fade == "mid") and NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})
        or NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.55, 0.6), NumberSequenceKeypoint.new(1, 1)})
    new("UIGradient", {Transparency = seq, Rotation = (fade == "d") and 90 or ((fade == "l") and 180 or 0)}, f)
    return f
end
-- TEKS: W = 1 / 2 / 3 (lama) atau nama peran. TextSize nominal (default per peran dari TS) dikalikan skala optik peran.
local function text(parent, p)
    local role, d = "label", {BackgroundTransparency = 1, BorderSizePixel = 0, TextColor3 = T.text, TextXAlignment = XL, TextTruncate = Enum.TextTruncate.AtEnd}
    for k, v in pairs(p) do
        if k == "W" then role = ROLE[v] or v else d[k] = v end
    end
    if not FACES[role] then role = "label" end
    d.FontFace = d.FontFace or FONT[role]
    d.TextSize = tsz(d.TextSize or TS[role], role)
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

-- CHEVRON: panah "v" digambar dari dua Frame (tanpa aset). Return box (putar lewat Rotation: 0 = bawah, -90 = kanan) dan paint(warna, instan)
local function chevron(parent, props)
    local d = {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1}
    for k, v in pairs(props or {}) do d[k] = v end
    local box = new("Frame", d, parent)
    local arms = {}
    for i, a in ipairs({{-3, 45}, {3, -45}}) do
        arms[i] = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, a[1], 0.5, 1), Size = UDim2.fromOffset(9, 2), Rotation = a[2],
            BackgroundColor3 = T.dim, BorderSizePixel = 0, ZIndex = d.ZIndex}, box)
        corner(arms[i], "full")
    end
    return box, function(c, instant)
        for _, a in ipairs(arms) do play(a, {BackgroundColor3 = c}, instant and 0 or DUR.fast) end
    end
end

-- INTERACT: satu binder state untuk semua elemen yang bisa disentuh. apply("idle" | "hover" | "press" | "focus" | "disabled").
-- Hover dilewati di layar sentuh murni (supaya tidak "menempel"); focus = pilihan gamepad / keyboard (kotak seleksi bawaan Roblox disembunyikan).
-- Return refresh(): panggil ulang untuk menggambar ulang state saat ini (ganti tema, disabled berubah).
local TOUCH_ONLY = UIS.TouchEnabled and not UIS.MouseEnabled
local NOSEL = Instance.new("Frame")
NOSEL.Name, NOSEL.BackgroundTransparency, NOSEL.BorderSizePixel = "NoSelection", 1, 0
local function interact(hit, apply, isDisabled)
    local hov, down, foc = false, false, false
    local function refresh()
        if isDisabled and isDisabled() then apply("disabled") return end
        apply(down and "press" or (foc and "focus") or (hov and "hover") or "idle")
    end
    pcall(function() hit.SelectionImageObject = NOSEL end)
    if not TOUCH_ONLY then
        hit.MouseEnter:Connect(function() hov = true refresh() end)
        hit.MouseLeave:Connect(function() hov, down = false, false refresh() end)
    end
    hit.SelectionGained:Connect(function() foc = true refresh() end)
    hit.SelectionLost:Connect(function() foc = false refresh() end)
    hit.InputBegan:Connect(function(i)
        local ut = i.UserInputType
        if ut ~= Enum.UserInputType.MouseButton1 and ut ~= Enum.UserInputType.Touch then return end
        down = true
        refresh()
        local c
        c = i.Changed:Connect(function()
            local st = i.UserInputState
            if st == Enum.UserInputState.End or st == Enum.UserInputState.Cancel then
                c:Disconnect()
                down = false
                refresh()
            end
        end)
    end)
    return refresh
end
-- tunda aksi untuk stagger; NOANIM -> langsung (tidak ada jeda)
local function after(d, fn)
    if NOANIM or d <= 0 then fn() else task.delay(d, fn) end
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
-- lebar teks (sinkron). role default "strong" (paling lebar) supaya aman untuk ukuran kotak
local function textW(s, size, role)
    local r = ROLE[role] or role or "strong"
    local f = FACES[r] or FACES.strong
    local px = tsz(size, r)
    local ok, v = pcall(function() return TextService:GetTextSize(tostring(s), px, f[1], Vector2.new(1000, 100)).X end)
    return ok and v or (#tostring(s) * px * 0.6)
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

-- judul + deskripsi di sisi kiri elemen (rpad = ruang kosong di kanan, wfrac = lebar relatif).
-- Posisi relatif ke garis tengah baris, jadi tinggi baris bebas: judul di atas garis tengah, deskripsi tepat di bawahnya.
local function rowText(f, title, desc, rpad, wfrac)
    local w, rp = wfrac or 1, rpad or 12
    if not desc then
        return text(f, {Text = tostring(title), Position = UDim2.fromOffset(12, 0), Size = UDim2.new(w, -(12 + rp), 1, 0), W = "label"})
    end
    local t = text(f, {Text = tostring(title), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 0.5, 1),
        Size = UDim2.new(w, -(12 + rp), 0, tsz(14, "label") + 4), W = "label"})
    local d = text(f, {Text = tostring(desc), Position = UDim2.new(0, 12, 0.5, 2), Size = UDim2.new(w, -(12 + rp), 0, tsz(12, "desc") + 4),
        TextColor3 = T.dim, W = "desc"})
    return t, d
end

-- kotak input "sumur": well gelap, hairline top-lit, cincin + aura aksen saat fokus. Nilai yang diketik memakai mono.
-- return: wrap, box, ctl  ->  ctl:SetError(bool), ctl:SetDisabled(bool), ctl:Refresh()
local function inputBox(parent, p)
    local wrap = new("Frame", {BackgroundColor3 = T.well, BorderSizePixel = 0}, parent)
    corner(wrap, "sm")
    local st = stroke(wrap, T.outline, 1, "line")
    local gl = aura(wrap, 16)
    for k, v in pairs(p.wrap or {}) do wrap[k] = v end
    local box = new("TextBox", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Text = p.text or "", PlaceholderText = p.placeholder or "",
        PlaceholderColor3 = T.mute, TextColor3 = T.text, FontFace = FONT.cap, TextSize = tsz(13, "cap"), TextXAlignment = XL, ClearTextOnFocus = p.clear or false,
        ClipsDescendants = true}, wrap)
    new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, box)
    local s = {focus = false, hover = false, err = false, dis = false}
    local function paint()
        local col, tr, gtr = T.outline, STROKE.line, 1
        if s.dis then tr = STROKE.hair
        elseif s.err then col, tr = T.bad, STROKE.focus
        elseif s.focus then col, tr, gtr = T.accent, STROKE.focus, 0.86
        elseif s.hover then col, tr = T.rim, STROKE.edge end
        play(st, {Color = col, Transparency = tr}, DUR.fast)
        play(gl, {ImageTransparency = gtr}, DUR.base)
        play(box, {TextColor3 = s.dis and T.mute or T.text}, DUR.fast)
    end
    if not TOUCH_ONLY then
        box.MouseEnter:Connect(function() s.hover = true paint() end)
        box.MouseLeave:Connect(function() s.hover = false paint() end)
    end
    box.Focused:Connect(function() s.focus = true paint() end)
    box.FocusLost:Connect(function() s.focus = false paint() end)
    local ctl = {}
    function ctl:SetError(on) s.err = on and true or false paint() end
    function ctl:SetDisabled(on) s.dis = on and true or false box.TextEditable = not s.dis paint() end
    function ctl:Refresh() paint() end
    return wrap, box, ctl
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
    corner(body, 10)
    skin(stroke(body, T.accent, 1, 0.5), "Color", "accent")
    local dtitle = text(body, {Text = "", Position = UDim2.fromOffset(12, 9), Size = UDim2.new(1, -24, 0, 18), W = 3, TextSize = 13})
    local _, box = inputBox(body, {placeholder = "Search...", wrap = {Position = UDim2.fromOffset(8, 32), Size = UDim2.new(1, -16, 0, 28), BackgroundColor3 = T.bg, BackgroundTransparency = 0.5}})
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
            local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.el, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i}, list)
            corner(b, 7)
            local tx, cbox, mark, tick = 8, nil, nil, nil
            if sp.multi then
                cbox = new("Frame", {Position = UDim2.new(0, 8, 0.5, -7), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.bg, BorderSizePixel = 0}, b)
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
            local lb = text(b, {Text = name, Position = UDim2.fromOffset(tx, 0), Size = UDim2.new(1, -(tx + (tick and 26 or 6)), 1, 0), W = 3, TextSize = 13, TextColor3 = T.dim})
            local r = {btn = b, name = name}
            function r.paint()
                local on = sp.isSel(name)
                b.BackgroundColor3 = on and T.accent or T.el
                b.BackgroundTransparency = on and 0.84 or 1
                if sp.multi then
                    cbox.BackgroundColor3 = on and T.accent or T.bg
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
                    b.BackgroundColor3, b.BackgroundTransparency = T.el, 0.4
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
    local REF = C.ReferenceSize or Vector2.new(1280, 720)
    local root = new("Frame", {Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)
    local rootScale = new("UIScale", {}, root)
    local DEFAULT, MINS, MAXS = Vector2.new(700, 450), Vector2.new(400, 300), Vector2.new(980, 640)
    local winSize = Vector2.new(math.clamp(tonumber(F.UIW) or DEFAULT.X, MINS.X, MAXS.X), math.clamp(tonumber(F.UIH) or DEFAULT.Y, MINS.Y, MAXS.Y))
    local winPos, curPos, virt = nil, Vector2.new(), Vector2.new(REF.X, REF.Y)
    local layoutWin, layoutLauncher, layoutHeader, hdrFx, introTabs

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

    -- ripple klik (posisi diambil dari kursor / sentuhan terakhir)
    local function ripple(f, size)
        if NOANIM then return end
        local loc = UIS:GetMouseLocation()
        local s = math.max(rootScale.Scale, 0.01)
        local ap, asz = f.AbsolutePosition, f.AbsoluteSize
        local x = math.clamp((loc.X - ap.X) / s, 0, asz.X / s)
        local y = math.clamp((loc.Y - ap.Y) / s, 0, asz.Y / s)
        local r = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.86, BorderSizePixel = 0}, f)
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
        corner(m, 10)
        stroke(m, color, 1, 0.55)
        local ic = new("Frame", {Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = color, BackgroundTransparency = 0.82, BorderSizePixel = 0}, m)
        corner(ic, 9)
        stroke(ic, color, 1, 0.6)
        new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
            Image = img or LOGO, ImageColor3 = (img == nil and ICON ~= "") and WHITE or color, ScaleType = Enum.ScaleType.Fit}, ic)
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
    -- SHELL + WINDOW + HEADER
    ------------------------------------------------------------------
    local Window = {Tabs = {}, Flags = Reg, Gui = gui, PlaceId = placeId, GameId = gameId}
    local shell = new("Frame", {Name = "Shell", BackgroundTransparency = 1, Visible = false}, root)
    local wsh = shadow(shell, 0, 56, 12)
    local WSH_T = 0.4 -- transparansi bayangan window saat terbuka
    local win = new("Frame", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.03, BorderSizePixel = 0, ClipsDescendants = true, Active = true}, shell)
    corner(win, "lg")
    local wstG = new("UIGradient", {Rotation = 120}, stroke(win, WHITE, 1, 0))
    local winScale = new("UIScale", {Scale = 1}, win)
    local ctxWin = newCtx(win, 12)

    layoutWin = function(anim)
        local sz = Vector2.new(math.min(winSize.X, virt.X - 20), math.min(winSize.Y, virt.Y - 20))
        local x, y
        if winPos then x, y = winPos.X, winPos.Y else x, y = (virt.X - sz.X) / 2, (virt.Y - sz.Y) / 2 end
        x = math.clamp(x, 10, math.max(10, virt.X - sz.X - 10))
        y = math.clamp(y, 10, math.max(10, virt.Y - sz.Y - 10))
        if winPos then winPos = Vector2.new(x, y) end
        curPos = Vector2.new(x, y)
        shell.Size = UDim2.fromOffset(sz.X, sz.Y)
        if layoutHeader then layoutHeader(sz.X) end
        if anim then play(shell, {Position = UDim2.fromOffset(x, y)}, anim == true and DUR.page or anim) else shell.Position = UDim2.fromOffset(x, y) end
    end

    ------------------------------------------------------------------
    -- HEADER: badge logo + judul/versi + chip live (FPS / Ping / Jam) + kontrol window
    -- Chip otomatis disembunyikan satu per satu saat window dikecilkan.
    ------------------------------------------------------------------
    local HDR = 48
    local hd, minB, maxB, xB
    do
        local Stats, Market = game:GetService("Stats"), game:GetService("MarketplaceService")
        local PAD, BTN, CHIP_H, GAP = 12, UIS.TouchEnabled and 36 or 28, 24, 8
        local CTRL_W = PAD + BTN * 3 + GAP * 2
        local RESERVE = CTRL_W + 16 -- kontrol + pemisah
        local grads = {}

        -- latar header: wash aksen di kiri yang memudar ke warna sidebar
        local function hdrSeq()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, T.side:Lerp(T.accent, 0.2)),
                ColorSequenceKeypoint.new(0.55, T.side:Lerp(T.accent2, 0.05)),
                ColorSequenceKeypoint.new(1, T.side),
            })
        end
        hd = new("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, HDR), BackgroundColor3 = WHITE, BorderSizePixel = 0, Active = true, ClipsDescendants = true}, win)
        corner(hd, "lg")
        grads[1] = new("UIGradient", {Color = hdrSeq()}, hd)
        local fill = new("Frame", {Name = "BottomFiller", Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, hd)
        grads[2] = new("UIGradient", {Color = hdrSeq()}, fill)
        new("Frame", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.92, BorderSizePixel = 0, ZIndex = 3}, hd)

        -- garis bawah: hairline + trace aksen 2px yang memudar ke kanan
        new("Frame", {Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 2}, hd)
        trace(hd, {Name = "AccentLine", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), ZIndex = 3}, "r")

        -- badge logo: aura aksen + kotak sumur dengan outline gradien
        local bw = new("Frame", {Name = "LogoHolder", Position = UDim2.fromOffset(PAD, math.floor((HDR - 32) / 2)), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, ZIndex = 2}, hd)
        local bwScale = new("UIScale", {}, bw)
        local ba = aura(bw, 20)
        ba.ImageTransparency, ba.ZIndex = 0.78, 1
        local badge = new("Frame", {Name = "Badge", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.well, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 2}, bw)
        corner(badge, "md")
        local bsg = new("UIGradient", {Rotation = 45}, stroke(badge, WHITE, 1.5, 0))
        logoImg(badge, {Name = "Logo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20), ScaleType = Enum.ScaleType.Fit, ZIndex = 3})

        -- judul (Michroma) + pill versi (mono) + subjudul (nama game, atau C.Subtitle)
        local titleText = tostring(C.Title or C.Name or "SORU HUB")
        local tw = math.ceil(textW(titleText, 15, "title")) + 6
        local TX = PAD + 32 + 12
        local tl = text(hd, {Name = "Title", Text = titleText, Position = UDim2.fromOffset(TX, 7), Size = UDim2.fromOffset(tw, 18), W = "title", TextSize = 15, ZIndex = 2})
        local verText = "v" .. VERSION
        local pw = math.ceil(textW(verText, 10, "cap")) + 12
        local pill = new("Frame", {Name = "Version", Position = UDim2.fromOffset(TX + tw + 6, 9), Size = UDim2.fromOffset(pw, 14), BackgroundTransparency = 0.84, BorderSizePixel = 0, ZIndex = 2}, hd)
        skin(pill, "BackgroundColor3", "accent")
        corner(pill, "full")
        skin(stroke(pill, T.accent, 1, 0.6), "Color", "accent")
        skin(text(pill, {Text = verText, Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = "cap", TextSize = 10, TextTruncate = NOTRUNC, ZIndex = 3}), "TextColor3", "accent")
        local sub = text(hd, {Name = "Subtitle", Text = tostring(C.Subtitle or "Loading game..."), Position = UDim2.fromOffset(TX, 26), Size = UDim2.fromOffset(160, 16), TextSize = 11, W = "desc", TextColor3 = T.dim, ZIndex = 2})
        if C.Subtitle == nil then
            task.spawn(function()
                local ok, info = pcall(function() return Market:GetProductInfo(placeId) end)
                local nm = (ok and type(info) == "table" and info.Name) or ("Place " .. tostring(placeId))
                if sub.Parent then sub.Text = tostring(nm) end
            end)
        end

        -- chip live: FPS, Ping, Jam. Titik status + cincin lembut (glow) mengikuti warna status
        local chips = new("Frame", {Name = "Chips", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -RESERVE, 0.5, 0), Size = UDim2.fromOffset(0, CHIP_H), BackgroundTransparency = 1, ZIndex = 2}, hd)
        new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, GAP)}, chips)
        local chipList = {}
        local function chip(w, order, accentDot)
            local c = new("Frame", {Size = UDim2.fromOffset(w, CHIP_H), BackgroundColor3 = T.well, BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = order, ZIndex = 2}, chips)
            corner(c, "full")
            stroke(c, T.outline, 1, "line")
            local d = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = T.ok, BorderSizePixel = 0, ZIndex = 3}, c)
            corner(d, "full")
            local ring = stroke(d, T.ok, 2, 0.7)
            if accentDot then skin(d, "BackgroundColor3", "accent") skin(ring, "Color", "accent") end
            local l = text(c, {Position = UDim2.fromOffset(25, 0), Size = UDim2.new(1, -31, 1, 0), TextSize = 11, W = "cap", TextColor3 = T.dim, TextTruncate = NOTRUNC, ZIndex = 3, Text = "--"})
            chipList[#chipList + 1] = {f = c, w = w}
            return d, l, ring
        end
        local fpsD, fpsL, fpsR = chip(76, 1)
        local pingD, pingL, pingR = chip(80, 2)
        local _, timeL = chip(68, 3, true)
        fpsL.Text, pingL.Text, timeL.Text = "-- FPS", "-- ms", os.date("%H:%M")

        local frames, acc, lastClock = 0, 0, ""
        bind(RunService.Heartbeat, function(dt)
            frames = frames + 1
            acc = acc + dt
            if acc < 0.5 then return end
            local fps = math.floor(frames / acc + 0.5)
            frames, acc = 0, 0
            if not isOpen then return end
            fpsL.Text = fps .. " FPS"
            local fc = (fps >= 50 and T.ok) or (fps >= 30 and T.warn) or T.bad
            fpsD.BackgroundColor3, fpsR.Color = fc, fc
            local ping = 0
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
            pingL.Text = ping .. " ms"
            local pc = (ping < 100 and T.ok) or (ping < 200 and T.warn) or T.bad
            pingD.BackgroundColor3, pingR.Color = pc, pc
            local ck = os.date("%H:%M")
            if ck ~= lastClock then lastClock = ck timeL.Text = ck end
        end)

        -- pemisah + tombol kontrol window (ikon digambar dari Frame, tanpa aset)
        new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(CTRL_W + 8), 0.5, 0), Size = UDim2.fromOffset(1, 20), BackgroundColor3 = T.outline, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 2}, hd)
        local controls = new("Frame", {Name = "Controls", Position = UDim2.new(1, -CTRL_W, 0, 0), Size = UDim2.new(0, CTRL_W, 1, 0), BackgroundTransparency = 1, ZIndex = 2}, hd)
        new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, GAP)}, controls)
        new("UIPadding", {PaddingRight = UDim.new(0, PAD)}, controls)
        local function glyph(kind, parent)
            local box = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, ZIndex = 4}, parent)
            local fills, strokes = {}, {}
            local function bar(w, h, rot, y)
                local f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, y or 0), Size = UDim2.fromOffset(w, h), Rotation = rot or 0,
                    BackgroundColor3 = T.dim, BorderSizePixel = 0, ZIndex = 4}, box)
                corner(f, "full")
                fills[#fills + 1] = f
            end
            if kind == "min" then
                bar(10, 2, 0, 3)
            elseif kind == "max" then
                local sq = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 4}, box)
                corner(sq, 2)
                strokes[1] = stroke(sq, T.dim, 1.5, 0, false)
            else
                bar(14, 2, 45)
                bar(14, 2, -45)
            end
            return function(c)
                for _, f in ipairs(fills) do play(f, {BackgroundColor3 = c}, DUR.fast) end
                for _, s in ipairs(strokes) do play(s, {Color = c}, DUR.fast) end
            end
        end
        local function ctrlBtn(name, kind, order, hotKey)
            local b = new("TextButton", {Name = name, LayoutOrder = order, Size = UDim2.fromOffset(BTN, BTN), BackgroundColor3 = T.el, BackgroundTransparency = 0.5, Text = "",
                AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3}, controls)
            corner(b, "md")
            local st = stroke(b, T.outline, 1, "line")
            local sc = new("UIScale", {}, b)
            local paint = glyph(kind, b)
            interact(b, function(s)
                local hot = s ~= "idle"
                local col = hot and T[hotKey] or T.outline
                play(b, {BackgroundColor3 = (s == "press") and col or (hot and T.hover or T.el), BackgroundTransparency = (s == "press") and 0.6 or (hot and 0.15 or 0.5)}, DUR.fast)
                play(st, {Color = col, Transparency = hot and 0.2 or STROKE.line}, DUR.fast)
                play(sc, {Scale = (s == "press") and 0.92 or 1}, DUR.fast)
                paint(hot and ((hotKey == "bad") and T.bad or T.text) or T.dim)
            end)
            return b
        end
        minB = ctrlBtn("Minimize", "min", 1, "accent")
        maxB = ctrlBtn("Maximize", "max", 2, "accent")
        xB = ctrlBtn("Close", "close", 3, "bad")

        -- responsif: chip hilang berurutan (Jam, Ping, FPS), pill versi hilang kalau sempit
        layoutHeader = function(W)
            local base = W - TX - RESERVE
            local want = math.max(tw + 6 + pw, 120)
            local used, fit = 0, true
            for _, c in ipairs(chipList) do
                local need = c.w + ((used > 0) and GAP or 0)
                if fit and base - (used + need + 10) >= want then
                    c.f.Visible = true
                    used = used + need
                else
                    fit = false
                    c.f.Visible = false
                end
            end
            chips.Size = UDim2.fromOffset(used, CHIP_H)
            local avail = math.max(base - ((used > 0) and (used + 10) or 0), 40)
            tl.Size = UDim2.fromOffset(math.min(avail, tw), 18)
            pill.Visible = avail >= tw + 6 + pw
            sub.Size = UDim2.fromOffset(avail, 16)
        end
        layoutHeader(winSize.X)

        -- intro saat window dibuka: badge "pop", lalu chip menyusul dari kanan
        hdrFx = function()
            bwScale.Scale = 0.6
            play(bwScale, {Scale = 1}, DUR.slow, BACK)
            chips.Position = UDim2.new(1, -RESERVE + 16, 0.5, 0)
            after(0.08, function() play(chips, {Position = UDim2.new(1, -RESERVE, 0.5, 0)}, DUR.slow) end)
        end

        local function paintHdr()
            for _, g in ipairs(grads) do g.Color = hdrSeq() end
            bsg.Color = ColorSequence.new(T.hi, T.accent2)
        end
        paintHdr()
        themeFns[#themeFns + 1] = paintHdr
    end

    ------------------------------------------------------------------
    -- SIDEBAR + CONTENT
    ------------------------------------------------------------------
    local TOUCH = UIS.TouchEnabled
    local SIDE_W, FOOT_H, TAB_H, TAB_GAP, NAV_Y = 168, 72, 40, 4, 12
    local INDY = math.floor((TAB_H - 20) / 2)
    local SBTN = TOUCH and 36 or 32
    local bar = new("Frame", {Name = "Sidebar", Position = UDim2.fromOffset(0, HDR), Size = UDim2.new(0, SIDE_W, 1, -HDR), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true}, win)

    -- latar sidebar: gradien tipis aksen -> gelap. Hanya sudut kiri-bawah yang membulat (sudut lain keluar bar & kepotong)
    local sbg = new("Frame", {Name = "Background", Position = UDim2.fromOffset(0, -16), Size = UDim2.new(1, 16, 1, 16), BackgroundColor3 = WHITE, BorderSizePixel = 0}, bar)
    corner(sbg, "lg")
    local sbgGrad = new("UIGradient", {Rotation = 90}, sbg)
    local function paintSide()
        sbgGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, T.side:Lerp(T.accent, 0.12)),
            ColorSequenceKeypoint.new(0.5, T.side),
            ColorSequenceKeypoint.new(1, T.side:Lerp(T.bg, 0.6)),
        })
    end
    paintSide()
    themeFns[#themeFns + 1] = paintSide

    -- pemisah vertikal: hairline + trace aksen yang memudar ke bawah
    new("Frame", {Name = "Separator", Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.outline, BackgroundTransparency = 0.35, BorderSizePixel = 0}, bar)
    trace(bar, {Name = "SeparatorTrace", Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundTransparency = 0.45}, "d")

    local tabList = new("ScrollingFrame", {Name = "TabContainer", Active = true, Position = UDim2.fromOffset(0, NAV_Y), Size = UDim2.new(1, -1, 1, -(NAV_Y + FOOT_H)), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y}, bar)
    skin(tabList, "ScrollBarImageColor3", "accent")
    local btnHolder = new("Frame", {Name = "ButtonsHolder", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.Y}, tabList)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, TAB_GAP)}, btnHolder)
    new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, btnHolder)
    -- rel aksen: "trace" yang menyala di tepi kiri tab aktif (meluncur antar tab)
    local indicator = new("Frame", {Name = "SlidingIndicator", Position = UDim2.fromOffset(0, INDY), Size = UDim2.fromOffset(3, 20), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, tabList)
    skin(indicator, "BackgroundColor3", "accent")
    corner(indicator, "full")
    local indAura = aura(indicator, 30)

    -- footer: kartu profil (avatar + nama + status) dengan tombol Settings di kanan
    local foot = new("Frame", {Name = "Footer", Position = UDim2.new(0, 0, 1, -FOOT_H), Size = UDim2.new(1, -1, 0, FOOT_H), BackgroundTransparency = 1}, bar)
    local card = new("Frame", {Name = "ProfileCard", Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), BackgroundColor3 = T.well, BackgroundTransparency = 0.3, BorderSizePixel = 0}, foot)
    corner(card, "md")
    stroke(card, T.outline, 1, "line")
    local av = new("ImageLabel", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = T.el, BorderSizePixel = 0}, card)
    corner(av, "full")
    skin(stroke(av, T.accent, 1.5, 0.3), "Color", "accent")
    local avInitial = text(av, {Text = string.upper(string.sub(pl.DisplayName, 1, 1)), Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = "strong", TextSize = 14, TextColor3 = T.dim, TextTruncate = NOTRUNC})
    local dot = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 38, 0.5, 12), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = T.ok, BorderSizePixel = 0, ZIndex = 2}, card)
    corner(dot, "full")
    stroke(dot, T.side, 2, 0)
    text(card, {Text = pl.DisplayName, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 52, 0.5, 1), Size = UDim2.new(1, -(52 + SBTN + 14), 0, 18), W = "label", TextSize = 13})
    text(card, {Text = "online", Position = UDim2.new(0, 52, 0.5, 2), Size = UDim2.new(1, -(52 + SBTN + 14), 0, 14), TextSize = 10, W = "cap", TextColor3 = T.ok})
    task.spawn(function()
        local ok, img = pcall(function() return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
        if ok and av.Parent then av.Image = img avInitial.Visible = false end
    end)
    local setBtn = new("TextButton", {Name = "SettingsButton", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(SBTN, SBTN),
        BackgroundColor3 = T.el, BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ClipsDescendants = true}, card)
    corner(setBtn, "md")
    local setStroke = stroke(setBtn, T.outline, 1, "line")
    -- ikon "tune" (tiga slider) digambar dari Frame, tanpa aset
    local setBox = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1}, setBtn)
    local setParts = {}
    for _, d in ipairs({{3, 4}, {8, 11}, {13, 6}}) do
        local ln = new("Frame", {Position = UDim2.fromOffset(0, d[1] - 1), Size = UDim2.fromOffset(16, 2), BackgroundColor3 = T.dim, BorderSizePixel = 0}, setBox)
        corner(ln, "full")
        local kn = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(d[2], d[1]), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = T.dim, BorderSizePixel = 0, ZIndex = 2}, setBox)
        corner(kn, "full")
        setParts[#setParts + 1] = ln
        setParts[#setParts + 1] = kn
    end
    local function setPaint(c) for _, f in ipairs(setParts) do play(f, {BackgroundColor3 = c}, DUR.fast) end end

    local CONT_X, CONT_Y = SIDE_W, HDR + 8
    local content = new("Frame", {Name = "ContentContainer", Position = UDim2.fromOffset(CONT_X, CONT_Y), Size = UDim2.new(1, -CONT_X, 1, -CONT_Y), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true}, win)

    -- wash aksen tipis di area konten + outline window bergradien aksen (ikut ganti tema)
    do
        local wash = new("Frame", {Name = "Wash", Position = UDim2.fromOffset(CONT_X, 0), Size = UDim2.new(1, -CONT_X, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 0}, win)
        corner(wash, "lg")
        local washG = new("UIGradient", {Rotation = 135, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(0.45, 1), NumberSequenceKeypoint.new(1, 1)})}, wash)
        local function paintFrame()
            washG.Color = ColorSequence.new(T.accent, T.accent2)
            wstG.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, T.outline:Lerp(T.accent, 0.55)),
                ColorSequenceKeypoint.new(0.5, T.outline),
                ColorSequenceKeypoint.new(1, T.outline:Lerp(T.accent2, 0.3)),
            })
        end
        paintFrame()
        themeFns[#themeFns + 1] = paintFrame
    end

    -- resize handle: tiga garis diagonal (area sentuh lebih besar di layar sentuh)
    local RH = TOUCH and 36 or 20
    local rh = new("TextButton", {Name = "ResizeHandle", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), Size = UDim2.fromOffset(RH, RH), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 100}, win)
    local rLines = {}
    for _, cfg in ipairs({{6, -4, -4}, {10, -4, -8}, {14, -4, -12}}) do
        local ln = new("Frame", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, cfg[2], 1, cfg[3]), Size = UDim2.fromOffset(cfg[1], 2), Rotation = -45, BackgroundColor3 = T.dim, BorderSizePixel = 0, ZIndex = 101}, rh)
        corner(ln, "full")
        rLines[#rLines + 1] = ln
    end
    interact(rh, function(s)
        local hot = s ~= "idle"
        for _, l in ipairs(rLines) do play(l, {BackgroundColor3 = hot and T.accent or T.dim}, DUR.fast) end
    end)
    ------------------------------------------------------------------
    -- OPEN / CLOSE + LAUNCHER + DRAG / RESIZE
    ------------------------------------------------------------------
    local LAUNCH, launchPos = TOUCH and 52 or 48, nil
    local launcher = new("Frame", {Name = "Launcher", Size = UDim2.fromOffset(LAUNCH, LAUNCH), BackgroundTransparency = 1, Active = true, ZIndex = 90}, root)
    shadow(launcher, 0, 24, 4, 0.3)
    local lau = aura(launcher, 24)
    local lsc = new("UIScale", {}, launcher)
    local face = new("Frame", {Name = "Face", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg, BorderSizePixel = 0, ZIndex = 2}, launcher)
    corner(face, "xl")
    sheen(face, 0.15)
    do
        local lstG = new("UIGradient", {Rotation = 45}, stroke(face, WHITE, 1.5, 0))
        local function paintLauncher() lstG.Color = ColorSequence.new(T.hi, T.accent) end
        paintLauncher()
        themeFns[#themeFns + 1] = paintLauncher
    end
    logoImg(face, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62), ScaleType = Enum.ScaleType.Fit, ZIndex = 3})
    -- state launcher: aura menyala redup saat window terbuka, terang saat hover, paling terang saat ditekan / diseret
    local lstate = "idle"
    local function launchGlow()
        local a = (lstate == "press") and 0.45 or ((lstate == "hover" or lstate == "focus") and 0.6 or (isOpen and 0.72 or 0.9))
        play(lau, {ImageTransparency = a}, DUR.fast)
    end
    interact(launcher, function(s)
        lstate = s
        play(lsc, {Scale = (s == "press") and 0.92 or ((s == "hover" or s == "focus") and 1.06 or 1)}, DUR.fast)
        launchGlow()
    end)
    layoutLauncher = function()
        if not launchPos then launchPos = Vector2.new(math.floor(virt.X * 0.1), math.floor(virt.Y * 0.1)) end
        launchPos = Vector2.new(math.clamp(launchPos.X, 4, math.max(4, virt.X - LAUNCH - 8)), math.clamp(launchPos.Y, 4, math.max(4, virt.Y - LAUNCH - 8)))
        launcher.Position = UDim2.fromOffset(launchPos.X, launchPos.Y)
    end

    -- buka: window naik + membesar, lalu header (badge, chip) dan tab menyusul berurutan. tutup: tab keluar dulu, lalu window mengecil
    local function openA()
        if isOpen then return end
        isOpen = true
        layoutWin()
        shell.Visible = true
        winScale.Scale, wsh.ImageTransparency = 0.94, 1
        win.Position = UDim2.new(0.5, 0, 0.5, 14)
        play(winScale, {Scale = 1}, DUR.slow, BACK)
        play(win, {Position = UDim2.fromScale(0.5, 0.5)}, DUR.slow)
        play(wsh, {ImageTransparency = WSH_T}, DUR.slow)
        blurUpdate()
        launchGlow()
        if hdrFx then hdrFx() end
        if introTabs then introTabs(true) end
    end
    local function closeA()
        if not isOpen then return end
        isOpen = false
        if ctxWin.d then ctxWin.d.close() end
        blurUpdate()
        launchGlow()
        if NOANIM then shell.Visible = false return end
        if introTabs then introTabs(false) end
        after(0.05, function()
            if isOpen then return end
            play(winScale, {Scale = 0.94}, DUR.base, QUINT, Enum.EasingDirection.In)
            play(win, {Position = UDim2.new(0.5, 0, 0.5, 10)}, DUR.base, QUINT, Enum.EasingDirection.In)
            play(wsh, {ImageTransparency = 1}, DUR.base)
        end)
        task.delay(0.05 + DUR.base + 0.03, function() if not isOpen then shell.Visible = false end end)
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
        new("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 12)}, page)
        text(page, {Name = "TabTitle", Text = name, Size = UDim2.new(1, 0, 0, 32), W = "title", TextSize = 22, LayoutOrder = -2})
        trace(page, {Name = "TabRule", Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.35, LayoutOrder = -1}, "r")
        -- state kosong: hilang begitu komponen pertama ditambahkan
        local empty = text(page, {Name = "Empty", Text = "Nothing here yet", Size = UDim2.new(1, 0, 0, 48), TextXAlignment = XC, W = "desc", TextSize = 13, TextColor3 = T.mute, LayoutOrder = 0})
        local added = page.ChildAdded:Connect(function(c)
            if c:IsA("GuiObject") and c ~= empty and c.Name ~= "TabTitle" and c.Name ~= "TabRule" then empty.Visible = false end
        end)
        empty.Destroying:Connect(function() added:Disconnect() end)
        return page
    end

    local setState = "idle"
    local function paintSettingsBtn(on, state)
        local s = state or setState
        local hot = (s == "hover" or s == "press" or s == "focus")
        play(setBtn, {BackgroundColor3 = on and T.tint or (hot and T.hover or T.el), BackgroundTransparency = on and 0.25 or (hot and 0.1 or 0.45)}, DUR.fast)
        play(setStroke, {Color = (on or hot) and T.accent or T.outline, Transparency = on and 0.35 or (hot and 0.45 or STROKE.line)}, DUR.fast)
        setPaint(on and T.accent or (hot and T.text or T.dim))
    end
    local function showPage(p)
        p.Visible = true
        p.Position = UDim2.fromOffset(16, 0)
        play(p, {Position = UDim2.fromOffset(0, 0)}, DUR.slow)
        local tt = p:FindFirstChild("TabTitle")
        if tt then
            tt.TextTransparency = 1
            play(tt, {TextTransparency = 0}, DUR.slow)
        end
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
            old.repaint()
        end
        local snap = (cur == nil) or (cur == SETTINGS)
        cur = n
        if n == SETTINGS then
            showPage(setPage)
            paintSettingsBtn(true)
            play(indicator, {BackgroundTransparency = 1}, DUR.fast)
            play(indAura, {ImageTransparency = 1}, DUR.fast)
        else
            local ne = tabs[n]
            ne.on = true
            ne.repaint()
            showPage(ne.page)
            lastTab = n
            if snap then indicator.Position = UDim2.fromOffset(0, ne.y + INDY) end
            play(indicator, {Position = UDim2.fromOffset(0, ne.y + INDY), BackgroundTransparency = 0}, DUR.slow)
            play(indAura, {ImageTransparency = 0.72}, DUR.slow)
        end
    end
    local function switchTab(n) if tabs[n] then go(n) end end
    interact(setBtn, function(s)
        setState = s
        paintSettingsBtn(cur == SETTINGS, s)
    end)
    setBtn.MouseButton1Click:Connect(function()
        ripple(setBtn, 70)
        if cur == SETTINGS then
            if lastTab then go(lastTab) end
        else
            go(SETTINGS)
        end
    end)

    -- ikon tab: tile kecil di kiri label, menyala (tint aksen) saat tab aktif
    local function tabIcon(b, icon)
        local ic = icon and tostring(icon) or nil
        if ic == nil or ic == "" then return nil end
        local tile = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = T.well, BackgroundTransparency = 0.45, BorderSizePixel = 0}, b)
        corner(tile, "md")
        stroke(tile, T.outline, 1, "hair")
        local box = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1}, tile)
        local function tint(on)
            play(tile, {BackgroundColor3 = on and T.accent or T.well, BackgroundTransparency = on and 0.78 or 0.45}, DUR.base)
        end
        if ic == "home" then
            local parts = {}
            for _, d in ipairs({{11, 11, -3, 45}, {13, 8, 4, 0}}) do
                local p = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, d[3]), Size = UDim2.fromOffset(d[1], d[2]), Rotation = d[4], BackgroundColor3 = T.dim, BorderSizePixel = 0}, box)
                corner(p, 2)
                parts[#parts + 1] = p
            end
            return function(c, on) tint(on) for _, f in ipairs(parts) do f.BackgroundColor3 = c end end
        elseif ic:match("^rbxasset") or ic:match("^%d%d%d+$") then
            local img = new("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = ic:match("^%d+$") and ("rbxassetid://" .. ic) or ic, ImageColor3 = T.dim}, box)
            return function(c, on) tint(on) play(img, {ImageColor3 = c}, 0.2) end
        end
        local gl = text(box, {Text = ic, Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 15, TextColor3 = T.dim, TextTruncate = NOTRUNC})
        return function(c, on) tint(on) gl.TextColor3 = c end
    end

    local tabSeq, introTok = {}, 0
    local function createTab(name, icon)
        tabN = tabN + 1
        local y = (tabN - 1) * (TAB_H + TAB_GAP)
        local b = new("TextButton", {Name = name .. "Button", LayoutOrder = tabN, Size = UDim2.new(1, 0, 0, TAB_H), BackgroundColor3 = T.el, BackgroundTransparency = 1,
            BorderSizePixel = 0, AutoButtonColor = false, ClipsDescendants = true, Text = ""}, btnHolder)
        corner(b, "md")
        local bst = stroke(b, T.trace, 1, 1)
        local inner = new("Frame", {Name = "Inner", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, b)
        local rawIc = tabIcon(inner, icon)
        local lx = rawIc and 44 or 16
        local lb = text(inner, {Text = name, Position = UDim2.fromOffset(lx, 0), Size = UDim2.new(1, -(lx + 8), 1, 0), TextColor3 = T.dim})
        local page = newPage(name)
        local t = {name = name, btn = b, page = page, y = y, on = false, label = lb, inner = inner, state = "idle"}
        -- satu fungsi menggambar semua state tab: idle / hover / press / focus + aktif
        function t.repaint(instant)
            local d = instant and 0 or DUR.base
            local s, on = t.state, t.on
            local hot = (s == "hover" or s == "focus")
            local bgc, bgt, stt, lc, shift = T.el, 1, 1, T.dim, 0
            if on then bgc, bgt, stt, lc = T.tint, 0.3, 0.45, T.text
            elseif s == "press" then bgc, bgt, stt, lc, shift = T.hover, 0.35, STROKE.hair, T.text, 2
            elseif hot then bgc, bgt, stt, lc, shift = T.el, 0.55, STROKE.hair, T.text, 2 end
            play(b, {BackgroundColor3 = bgc, BackgroundTransparency = bgt}, d)
            play(bst, {Color = T.trace, Transparency = stt}, d)
            play(lb, {TextColor3 = lc, Position = UDim2.fromOffset(lx + shift, 0)}, d)
            if rawIc then rawIc(on and T.accent or ((hot or s == "press") and T.text or T.dim), on) end
        end
        tabs[name] = t
        tabSeq[#tabSeq + 1] = t
        interact(b, function(s) t.state = s t.repaint() end)
        b.MouseButton1Click:Connect(function()
            ripple(b, 150)
            go(name)
        end)
        if tabN == 1 then go(name) end
        return page
    end
    -- intro / outro tab berurutan (geser masuk dari kiri; keluar lebih cepat dengan urutan terbalik)
    introTabs = function(show)
        introTok = introTok + 1
        local my = introTok
        for i, t in ipairs(tabSeq) do
            local k = math.min(i, 8)
            if show then
                t.inner.Position = UDim2.fromOffset(-16, 0)
                after(0.06 + k * 0.03, function()
                    if introTok == my then play(t.inner, {Position = UDim2.fromOffset(0, 0)}, DUR.slow) end
                end)
            else
                after((8 - k) * 0.012, function()
                    if introTok == my then play(t.inner, {Position = UDim2.fromOffset(-16, 0)}, DUR.fast, QUINT, Enum.EasingDirection.In) end
                end)
            end
        end
    end
    themeFns[#themeFns + 1] = function()
        for _, t in ipairs(tabSeq) do t.repaint(true) end
        paintSettingsBtn(cur == SETTINGS)
    end

    ------------------------------------------------------------------
    -- KOMPONEN
    ------------------------------------------------------------------
    local function buildComponents(scroll, container, ctx)
        container = container or scroll
        local K = {}
        local order = 0
        local function nextOrder() order = order + 1 return order end

        -- elemen dasar: permukaan el berlapis (sheen), outline top-lit, sudut md
        local function elem(h)
            local f = new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.el, BackgroundTransparency = 0.35, BorderSizePixel = 0, LayoutOrder = nextOrder()}, K._cur or container)
            corner(f, "md")
            sheen(f, 0.12)
            local st = stroke(f, T.outline, 1, "line")
            return f, st
        end
        local function overlay(f)
            return new("TextButton", {Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2}, f)
        end
        -- state baris yang bisa diklik: idle / hover / press / focus / disabled. extra(state) = tambahan khusus komponen. Return refresh()
        local function rowFx(f, st, hit, isDis, extra)
            return interact(hit, function(s)
                local bg, bt, sc, stt = T.el, 0.35, T.outline, STROKE.line
                if s == "hover" then bg, bt, sc, stt = T.hover, 0.2, T.trace, STROKE.edge
                elseif s == "press" then bg, bt, sc, stt = T.hover, 0.1, T.accent, 0.3
                elseif s == "focus" then bg, bt, sc, stt = T.hover, 0.2, T.accent, STROKE.focus
                elseif s == "disabled" then bt, stt = 0.6, STROKE.hair end
                play(f, {BackgroundColor3 = bg, BackgroundTransparency = bt}, DUR.fast)
                play(st, {Color = sc, Transparency = stt}, DUR.fast)
                if extra then extra(s) end
            end, isDis)
        end
        -- nonaktif: tirai gelap tipis (Active = true menahan input), dibuat sekali saat pertama dipakai. Return setVeil(on)
        local function veilFor(f)
            local veil
            return function(on)
                if on then
                    if not veil then
                        veil = new("Frame", {Name = "DisabledVeil", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 30, Active = true}, f)
                        corner(veil, "md")
                    end
                    veil.Visible = true
                elseif veil then
                    veil.Visible = false
                end
            end
        end
        local function sideIcon(f, icon)
            local ic = tostring(icon)
            if ic:match("^rbxasset") or ic:match("^%d%d%d+$") then
                return new("ImageLabel", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
                    Image = ic:match("^%d+$") and ("rbxassetid://" .. ic) or ic, ImageColor3 = T.dim}, f)
            end
            return text(f, {Text = ic, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(20, 20), TextXAlignment = XC, W = "strong", TextColor3 = T.dim, TextTruncate = NOTRUNC})
        end

        ----------------------------------------------------------------
        -- SECTION / DIVIDER / LABEL / PARAGRAPH / INFO
        ----------------------------------------------------------------
        function K:Section(t)
            if type(t) == "table" then t = t.Title or t.Name or t.Text end
            t = tostring(t or "")
            local hf = new("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, K._cur or container)
            local w = math.ceil(textW(t, 13, "label"))
            local rail = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 2), Size = UDim2.fromOffset(2, 12), BorderSizePixel = 0}, hf)
            skin(rail, "BackgroundColor3", "accent")
            corner(rail, "full")
            text(hf, {Text = t, Position = UDim2.fromOffset(14, 2), Size = UDim2.fromOffset(w + 8, 26), W = "label", TextSize = 13, TextColor3 = T.dim, TextTruncate = NOTRUNC})
            local ln = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14 + w + 14, 0.5, 2), Size = UDim2.new(1, -(14 + w + 20), 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 0.3, BorderSizePixel = 0}, hf)
            new("UIGradient", {Transparency = NumberSequence.new(0, 1)}, ln)
        end

        function K:Divider()
            local hf = new("Frame", {Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, K._cur or container)
            local ln = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(1, -8, 0, 1), BackgroundColor3 = T.outline, BackgroundTransparency = 0.3, BorderSizePixel = 0}, hf)
            new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1)})}, ln)
        end

        function K:Label(t)
            if type(t) == "table" then t = t.Text or t.Title or t.Name end
            local hf = new("Frame", {Size = UDim2.new(1, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder()}, K._cur or container)
            local l = text(hf, {Text = tostring(t or ""), Position = UDim2.fromOffset(5, 0), Size = UDim2.new(1, -10, 0, 26), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextTruncate = NOTRUNC, W = "desc", TextSize = 14})
            return {Set = function(_, s) l.Text = tostring(s) end, SetText = function(_, s) l.Text = tostring(s) end, Get = function() return l.Text end}
        end

        function K:Paragraph(o)
            o = o or {}
            local f = new("Frame", {Name = "ParagraphFrame", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.el, BackgroundTransparency = 0.55, BorderSizePixel = 0, LayoutOrder = nextOrder()}, K._cur or container)
            corner(f, "md")
            stroke(f, T.outline, 1, "hair")
            local pbar = new("Frame", {Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(2, 14), BorderSizePixel = 0}, f)
            skin(pbar, "BackgroundColor3", "accent")
            corner(pbar, "full")
            local tl = text(f, {Text = tostring(o.Title or o.Name or "Paragraph"), Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 22), W = "label"})
            local dl = text(f, {Text = tostring(o.Desc or o.Content or ""), Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true, TextSize = 13, W = "desc", TextColor3 = T.dim, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = NOTRUNC, RichText = true, LineHeight = 1.12})
            new("UIPadding", {PaddingBottom = UDim.new(0, 14)}, f)
            local obj = {Title = tl.Text, Desc = dl.Text}
            function obj:Set(title, desc) if title then tl.Text = tostring(title) obj.Title = tl.Text end if desc then dl.Text = tostring(desc) obj.Desc = dl.Text end end
            function obj:SetTitle(s) tl.Text = tostring(s) obj.Title = tl.Text end
            function obj:SetDesc(s) dl.Text = tostring(s) obj.Desc = dl.Text end
            function obj:GetTitle() return obj.Title end
            function obj:GetDesc() return obj.Desc end
            return obj
        end

        -- baris informasi: judul kiri, nilai kanan (mono). Copy = true -> klik untuk menyalin nilai
        function K:Info(o)
            if type(o) ~= "table" then o = {Title = tostring(o)} end
            local clickable = (o.Copy or o.Callback) and true or false
            local f, st = elem(H1)
            text(f, {Text = tostring(o.Title or o.Name or "Info"), Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.42, -12, 1, 0), W = "label"})
            local base = T.dim
            local v = text(f, {Text = tostring(o.Value or "-"), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.58, -12, 1, 0), TextXAlignment = XR, W = "cap", TextSize = 12, TextColor3 = base})
            local dis, setVeil = false, veilFor(f)
            local refresh
            if clickable then
                local hit = overlay(f)
                refresh = rowFx(f, st, hit, function() return dis end)
                hit.MouseButton1Click:Connect(function()
                    if dis then return end
                    if o.Copy then
                        copy(v.Text)
                        notify("Copied", v.Text, T.accent, 1.4)
                        play(v, {TextColor3 = T.accent}, DUR.fast)
                        after(0.6, function() play(v, {TextColor3 = base}, DUR.base) end)
                    end
                    safe(o.Callback, v.Text)
                end)
            end
            return {
                Set = function(_, t, col) base = col or T.dim v.Text, v.TextColor3 = tostring(t), base end,
                Get = function() return v.Text end,
                SetDisabled = function(_, x) dis = x and true or false setVeil(dis) if refresh then refresh() end end,
                IsDisabled = function() return dis end,
            }
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
                tl = text(f, {Text = tostring(title), Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = "label"})
            end
            if o.Icon then sideIcon(f, o.Icon) end
            local hit = overlay(f)
            local dis, setVeil = false, veilFor(f)
            -- tombol = jejak aksen: permukaan ber-tint aksen + outline aksen; hover menyala, tekan terisi
            local function rest(s)
                local bg, bt, stt = T.tint, 0.3, 0.6
                if s == "hover" then bt, stt = 0.12, 0.3
                elseif s == "press" then bg, bt, stt = T.accent, 0.7, 0.1
                elseif s == "focus" then bt, stt = 0.12, STROKE.focus
                elseif s == "disabled" then bg, bt, stt = T.el, 0.6, STROKE.hair end
                play(f, {BackgroundColor3 = bg, BackgroundTransparency = bt}, DUR.fast)
                play(st, {Color = (s == "disabled") and T.outline or T.accent, Transparency = stt}, DUR.fast)
            end
            f.BackgroundColor3, f.BackgroundTransparency = T.tint, 0.3
            st.Color, st.Transparency = T.accent, 0.6
            local refresh = interact(hit, rest, function() return dis end)
            themeFns[#themeFns + 1] = function() refresh() end
            hit.MouseButton1Click:Connect(function()
                if dis then return end
                ripple(f, 200)
                play(f, {BackgroundColor3 = T.accent, BackgroundTransparency = 0.35}, DUR.fast)
                after(0.12, refresh)
                safe(o.Callback)
            end)
            return {
                SetTitle = function(_, s) tl.Text = tostring(s) end,
                SetDesc = function(_, s) if dl then dl.Text = tostring(s) end end,
                Fire = function() safe(o.Callback) end,
                SetDisabled = function(_, x) dis = x and true or false setVeil(dis) refresh() end,
                IsDisabled = function() return dis end,
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
            local f, st = elem(desc and H2 or H1)
            rowText(f, title, desc, 68)
            -- trek: mati = abu gelap, hidup = aksen + aura. Knob meregang saat ditekan lalu meluncur dengan pantulan kecil
            local TW, KN = 44, 18
            local sw = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(TW, 24), BackgroundColor3 = v and T.accent or T.off, BorderSizePixel = 0}, f)
            corner(sw, "full")
            sheen(sw, 0.14)
            local swSt = stroke(sw, v and T.hi or T.outline, 1, v and 0.35 or STROKE.line)
            local gl -- aura dibuat lazy: baris yang tak pernah menyala tidak membayar instance
            if v then gl = aura(sw, 16) gl.ImageTransparency = 0.72 end
            local function glow(a)
                if not gl then
                    if a >= 1 then return end
                    gl = aura(sw, 16)
                end
                play(gl, {ImageTransparency = a}, DUR.base)
            end
            local pressed = false
            local function kgeo(on, p)
                local kw = p and (KN + 4) or KN
                return UDim2.new(0, on and (TW - 3 - kw) or 3, 0.5, 0), UDim2.fromOffset(kw, KN)
            end
            local kp, ks = kgeo(v, false)
            local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = kp, Size = ks, BackgroundColor3 = v and WHITE or T.dim, BorderSizePixel = 0, ZIndex = 2}, sw)
            corner(knob, "full")
            local hit = overlay(f)
            local dis, setVeil = false, veilFor(f)
            local obj = {Value = v}
            local function paintKnob(style)
                local p, s = kgeo(v, pressed)
                play(knob, {Position = p, Size = s, BackgroundColor3 = v and WHITE or T.dim}, DUR.base, style)
            end
            local refresh = rowFx(f, st, hit, function() return dis end, function(s)
                local np = (s == "press")
                if np ~= pressed then pressed = np paintKnob() end
            end)
            local function upd(nv, silent)
                v, obj.Value = nv, nv
                play(sw, {BackgroundColor3 = v and T.accent or T.off}, DUR.base)
                play(swSt, {Color = v and T.hi or T.outline, Transparency = v and 0.35 or STROKE.line}, DUR.base)
                glow(v and 0.72 or 1)
                paintKnob(BACK)
                F[flag] = v
                if not silent then persist() safe(o.Callback, v) end
            end
            hit.MouseButton1Click:Connect(function() if not dis then upd(not v) end end)
            themeFns[#themeFns + 1] = function()
                sw.BackgroundColor3 = v and T.accent or T.off
                swSt.Color = v and T.hi or T.outline
                refresh()
            end
            function obj:Set(nv, fire) upd(nv and true or false, not fire) end
            function obj:Get() return v end
            function obj:SetDisabled(x) dis = x and true or false setVeil(dis) refresh() end
            function obj:IsDisabled() return dis end
            F[flag], Reg[flag] = v, obj
            if o.Disabled then obj:SetDisabled(true) end
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
            local f, st = elem(64)
            text(f, {Text = tostring(o.Title or o.Name or flag or "Slider"), Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -100, 0, 22), W = "label"})
            local vl = skin(text(f, {Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 22), TextXAlignment = XR, W = "cap", TextSize = 13, TextColor3 = T.dim, TextTruncate = NOTRUNC}), "TextColor3", "accent")
            local sbar = new("Frame", {Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = T.well, BorderSizePixel = 0}, f)
            corner(sbar, "full")
            stroke(sbar, T.outline, 1, "hair")
            local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, sbar)
            corner(fill, "full")
            local fillG = new("UIGradient", {}, fill)
            local function paintFill() fillG.Color = ColorSequence.new(T.accent2, T.hi) end
            paintFill()
            themeFns[#themeFns + 1] = paintFill
            local knob = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, sbar)
            corner(knob, "full")
            skin(stroke(knob, T.accent, 2, 0), "Color", "accent")
            local kau = aura(knob, 20)
            kau.ImageTransparency = 0.85
            local hit = new("TextButton", {Position = UDim2.fromOffset(4, 28), Size = UDim2.new(1, -8, 0, 36), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3}, f)
            local dis, setVeil = false, veilFor(f)
            -- knob membesar saat hover (18) dan saat diseret (20); aura mengikuti
            local refresh = rowFx(f, st, hit, function() return dis end, function(s)
                local big = (s == "press") and 20 or ((s == "hover" or s == "focus") and 18 or 16)
                play(knob, {Size = UDim2.fromOffset(big, big)}, DUR.fast)
                play(kau, {ImageTransparency = (s == "press") and 0.45 or ((s == "hover" or s == "focus") and 0.7 or 0.85)}, DUR.fast)
            end)
            local function quant(x)
                x = math.clamp(mn + math.floor((x - mn) / step + 0.5) * step, mn, mx)
                return math.floor(x * 1000 + 0.5) / 1000
            end
            local function render(x, instant)
                local a = (mx == mn) and 0 or (x - mn) / (mx - mn)
                local d = instant and 0 or DUR.fast
                play(fill, {Size = UDim2.fromScale(a, 1)}, d)
                play(knob, {Position = UDim2.fromScale(a, 0.5)}, d)
                vl.Text = tostring(x) .. (o.Suffix or "")
            end
            val = quant(val)
            render(val, true)
            local obj = {Value = val}
            local function set(x, silent, instant)
                x = quant(x)
                if x == val then return end
                val, obj.Value = x, x
                render(x, instant)
                if flag then F[flag] = x end
                if not silent then safe(o.Callback, x) end
            end
            local function fromX(px)
                local aw = sbar.AbsoluteSize.X
                if aw > 0 and not dis then set(mn + (mx - mn) * math.clamp((px - sbar.AbsolutePosition.X) / aw, 0, 1), false, true) end
            end
            track(hit,
                function(pos)
                    if dis then return nil end
                    scroll.ScrollingEnabled = false
                    fromX(pos.X)
                    return true
                end,
                function(dx, dy, p0, moved, pos) fromX(pos.X) end,
                function(moved, began)
                    if not began then return end
                    scroll.ScrollingEnabled = true
                    if flag then F[flag] = val persist() end
                    safe(o.OnRelease, val)
                end)
            function obj:Set(x, fire) set(x, not fire) if flag then F[flag] = val end end
            function obj:Get() return val end
            function obj:SetDisabled(x) dis = x and true or false setVeil(dis) refresh() end
            function obj:IsDisabled() return dis end
            if flag then F[flag], Reg[flag] = val, obj end
            if o.Disabled then obj:SetDisabled(true) end
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
            local BH = UIS.TouchEnabled and 36 or 32
            local f, st = elem(desc and H2 or (BH + 16))
            rowText(f, title, desc, 8, 0.5)
            local wrap, box, ctl = inputBox(f, {text = val, placeholder = o.Placeholder or "Type here...", clear = o.ClearOnFocus,
                wrap = {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0.42, 0, 0, BH)}})
            new("UISizeConstraint", {MinSize = Vector2.new(96, 0), MaxSize = Vector2.new(200, 1000)}, wrap)
            local dis, setVeil = false, veilFor(f)
            local function flash() ctl:SetError(true) after(0.9, function() ctl:SetError(false) end) end
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
            box.Focused:Connect(function()
                before = box.Text
                play(st, {Color = T.accent, Transparency = 0.4}, DUR.fast)
            end)
            if o.Live and o.Callback then
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    local v = out(box.Text)
                    if v ~= nil and box.Text ~= lastLive then lastLive = box.Text safe(o.Callback, v) end
                end)
            end
            box.FocusLost:Connect(function(enter)
                play(st, {Color = T.outline, Transparency = STROKE.line}, DUR.fast)
                local raw = box.Text
                local nv = norm(raw)
                -- error state: angka tidak valid / di luar Min-Max (nilai dikoreksi + kotak berkedip merah)
                if o.Numeric and raw ~= "" and tonumber(nv) ~= tonumber(raw) then flash() end
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
            function obj:SetError(on) ctl:SetError(on) end
            function obj:SetDisabled(x) dis = x and true or false setVeil(dis) ctl:SetDisabled(dis) end
            function obj:IsDisabled() return dis end
            Reg[flag] = obj
            if o.Disabled then obj:SetDisabled(true) end
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

            local f, st = elem(desc and H2 or H1)
            rowText(f, title, desc, 0, 0.5)
            local vl = text(f, {Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -36, 1, 0), TextXAlignment = XR, TextSize = 12, W = "cap", TextColor3 = T.dim})
            local _, chevPaint = chevron(f, {Position = UDim2.new(1, -24, 0.5, 0), Rotation = -90})
            local hit = overlay(f)
            local dis, setVeil = false, veilFor(f)
            local rf = rowFx(f, st, hit, function() return dis end, function(s) chevPaint((s == "idle" or s == "disabled") and T.dim or T.accent) end)
            -- nilai terpilih = teks terang; kosong / belum dipilih = redup; tanpa opsi sama sekali = "No options"
            local function refresh()
                local txt, empty
                if multi then
                    local v = getVal()
                    txt = (#v == 0) and "None" or ((#v == 1) and v[1] or (#v .. " Selected"))
                    empty = (#v == 0)
                else
                    txt = single or "Select..."
                    empty = (single == nil)
                end
                if empty and #opts == 0 then txt = "No options" end
                vl.Text = txt
                vl.TextColor3 = empty and T.mute or T.text
            end
            local function commit()
                local v = getVal()
                F[flag] = v
                persist()
                safe(o.Callback, v)
            end
            hit.MouseButton1Click:Connect(function()
                if dis then return end
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
            function api:SetDisabled(x) dis = x and true or false setVeil(dis) rf() end
            function api:IsDisabled() return dis end
            Reg[flag] = api
            if o.Disabled then api:SetDisabled(true) end
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
            local f, st = elem(desc and H2 or H1)
            rowText(f, title, desc, 112)
            local KH = UIS.TouchEnabled and 36 or 32
            local cap = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(80, KH), BackgroundColor3 = T.well, BackgroundTransparency = 0.2,
                BorderSizePixel = 0, FontFace = FONT.cap, TextSize = tsz(12, "cap"), TextColor3 = T.dim, Text = "", ClipsDescendants = true, AutoButtonColor = false}, f)
            corner(cap, "sm")
            local capSt = stroke(cap, T.outline, 1, "line")
            local cgl
            local listening, lastCancel, cstate = false, 0, "idle"
            local dis, setVeil = false, veilFor(f)
            -- keycap: mono; kosong ("None") redup; saat mendengarkan -> aksen + aura + baris ikut menyala
            local function show()
                local t = listening and "press a key" or (key and key.Name or "None")
                cap.Text = t
                cap.Size = UDim2.fromOffset(math.max(80, textW(t, 12, "cap") + 24), KH)
                local hot = (cstate == "hover" or cstate == "press" or cstate == "focus")
                play(cap, {TextColor3 = listening and T.accent or (key and T.text or T.mute), BackgroundColor3 = listening and T.tint or T.well, BackgroundTransparency = listening and 0.1 or 0.2}, DUR.fast)
                play(capSt, {Color = (listening or hot) and T.accent or T.outline, Transparency = listening and STROKE.focus or (hot and 0.35 or STROKE.line)}, DUR.fast)
                if listening and not cgl then cgl = aura(cap, 14) end
                if cgl then play(cgl, {ImageTransparency = listening and 0.75 or 1}, DUR.base) end
                play(st, {Color = listening and T.accent or T.outline, Transparency = listening and 0.4 or STROKE.line}, DUR.fast)
            end
            interact(cap, function(s) cstate = s show() end, function() return dis end)
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
                if dis or listening or os.clock() - lastCancel < 0.35 then return end
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
            function obj:SetDisabled(x)
                dis = x and true or false
                setVeil(dis)
                if dis and listening then stop() else show() end
            end
            function obj:IsDisabled() return dis end
            Reg[flag] = obj
            if o.Disabled then obj:SetDisabled(true) end
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
            local OPEN_H, open = 252, false
            local f, st = elem(H1)
            f.ClipsDescendants = true
            text(f, {Text = tostring(title), Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -92, 0, H1), W = "label"})
            local sw = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -44, 0, H1 / 2), Size = UDim2.fromOffset(32, 22), BackgroundColor3 = col, BorderSizePixel = 0}, f)
            corner(sw, "sm")
            stroke(sw, T.rim, 1, 0.3)
            local chev, chevPaint = chevron(f, {Position = UDim2.new(1, -24, 0, H1 / 2), Rotation = -90, ZIndex = 3})
            local head = new("TextButton", {Size = UDim2.new(1, 0, 0, H1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2}, f)
            local dis, setVeil = false, veilFor(f)
            -- state kepala: hover / press / fokus + "terbuka" tetap berpendar aksen
            local refresh = rowFx(f, st, head, function() return dis end, function(s)
                chevPaint(((s == "idle" or s == "disabled") and not open) and T.dim or T.accent)
                if open then play(st, {Color = T.accent, Transparency = 0.45}, DUR.fast) end
            end)

            local pop = new("Frame", {Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 194), BackgroundTransparency = 1}, f)
            local svBox = new("Frame", {Size = UDim2.new(1, 0, 0, 128), BackgroundColor3 = Color3.fromHSV(hh, 1, 1), BorderSizePixel = 0}, pop)
            corner(svBox, 4)
            stroke(svBox, WHITE, 1, 0.85)
            local wf = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, svBox)
            corner(wf, 4)
            new("UIGradient", {Transparency = NumberSequence.new(0, 1)}, wf)
            local bf = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, svBox)
            corner(bf, 4)
            new("UIGradient", {Transparency = NumberSequence.new(1, 0), Rotation = 90}, bf)
            local pt = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, svBox)
            corner(pt, "full")
            stroke(pt, Color3.new(0, 0, 0), 1, 0)
            local svHit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4}, svBox)

            local hue = new("Frame", {Position = UDim2.fromOffset(0, 136), Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = WHITE, BorderSizePixel = 0}, pop)
            corner(hue, 4)
            stroke(hue, WHITE, 1, 0.85)
            local ks = {}
            for i = 0, 6 do ks[#ks + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)) end
            new("UIGradient", {Color = ColorSequence.new(ks)}, hue)
            local hp = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 6, 1, 6), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, hue)
            corner(hp, 2)
            stroke(hp, Color3.new(0, 0, 0), 1, 0)
            local hHit = new("TextButton", {Position = UDim2.fromOffset(0, -9), Size = UDim2.new(1, 0, 1, 18), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4}, hue)
            local _, hexBox, hexCtl = inputBox(pop, {placeholder = "#RRGGBB", wrap = {Position = UDim2.fromOffset(0, 162), Size = UDim2.new(1, 0, 0, 32)}})
            -- penunjuk membesar saat diseret
            interact(svHit, function(s) local big = (s == "press") and 16 or 12 play(pt, {Size = UDim2.fromOffset(big, big)}, DUR.fast) end)
            interact(hHit, function(s) play(hp, {Size = UDim2.new(0, (s == "press") and 8 or 6, 1, 6)}, DUR.fast) end)

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
                    hexCtl:SetError(true)
                    after(0.9, function() hexCtl:SetError(false) end)
                end
            end)
            head.MouseButton1Click:Connect(function()
                if dis then return end
                open = not open
                play(f, {Size = UDim2.new(1, 0, 0, open and OPEN_H or H1)}, DUR.slow)
                play(chev, {Rotation = open and 0 or -90}, DUR.slow)
                refresh()
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
            function obj:SetDisabled(x)
                dis = x and true or false
                if dis and open then
                    open = false
                    play(f, {Size = UDim2.new(1, 0, 0, H1)}, DUR.slow)
                    play(chev, {Rotation = -90}, DUR.slow)
                end
                setVeil(dis)
                refresh()
            end
            function obj:IsDisabled() return dis end
            Reg[flag] = obj
            if o.Disabled then obj:SetDisabled(true) end
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
            local HEAD = desc and H2 or H1
            local open, animating, tok = false, false, 0
            local box = new("Frame", {Name = "SectionContainer", Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder()}, K._cur or container)
            local hd2 = new("TextButton", {Name = "SectionHeader", Size = UDim2.new(1, 0, 0, HEAD), BackgroundColor3 = T.el, BackgroundTransparency = 0.5, AutoButtonColor = false, Text = "", BorderSizePixel = 0}, box)
            corner(hd2, "md")
            sheen(hd2, 0.1)
            local hst = stroke(hd2, T.outline, 1, "line")
            text(hd2, {Text = tostring(o.Title or o.Name or "Section"), Position = UDim2.fromOffset(12, desc and 8 or 0), Size = UDim2.new(1, -48, 0, desc and 22 or HEAD), W = "label", TextSize = 14})
            if desc then text(hd2, {Text = tostring(desc), Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -48, 0, 18), TextSize = 12, W = "desc", TextColor3 = T.dim}) end
            local chev, chevPaint = chevron(hd2, {Position = UDim2.new(1, -24, 0.5, 0), Rotation = -90})

            local wrap = new("Frame", {Position = UDim2.fromOffset(0, HEAD + 4), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Visible = false}, box)
            local guide = new("Frame", {Position = UDim2.fromOffset(3, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundTransparency = 0.6, BorderSizePixel = 0}, wrap)
            skin(guide, "BackgroundColor3", "accent")
            corner(guide, "full")
            new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.12, 0), NumberSequenceKeypoint.new(0.88, 0), NumberSequenceKeypoint.new(1, 1)})}, guide)
            local cont = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0}, wrap)
            new("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 5)}, cont)
            local lay = new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, cont)

            -- state kosong: petunjuk redup sampai komponen pertama ditambahkan
            local emptyHint = text(cont, {Name = "Empty", Text = "Empty", Size = UDim2.new(1, 0, 0, 28), W = "desc", TextSize = 12, TextColor3 = T.mute, LayoutOrder = 0})
            cont.ChildAdded:Connect(function(c) if c ~= emptyHint and c:IsA("GuiObject") then emptyHint.Visible = false end end)
            local sub = buildComponents(scroll, cont, ctx)
            sub._content = cont

            local hstate = "idle"
            local function paintHead(instant)
                local d = instant and 0 or DUR.fast
                local hot = (hstate ~= "idle")
                local bg, bt, sc, stt = T.el, 0.5, T.outline, STROKE.line
                if open then bg, bt, sc, stt = T.tint, 0.3, T.accent, 0.45
                elseif hstate == "press" then bg, bt, sc, stt = T.hover, 0.2, T.accent, 0.3
                elseif hot then bg, bt, sc, stt = T.hover, 0.3, T.trace, STROKE.edge end
                play(hd2, {BackgroundColor3 = bg, BackgroundTransparency = bt}, d)
                play(hst, {Color = sc, Transparency = stt}, d)
                chevPaint(open and T.accent or (hot and T.text or T.dim), instant)
            end
            themeFns[#themeFns + 1] = function() paintHead(true) end
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
            interact(hd2, function(s) hstate = s paintHead() end)
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
        local COMPACT = 0.82 -- Width (default 300) diperkecil jadi ~246px. Naikkan kalau mau lebih lebar
        local function calcW(w) return math.clamp(math.floor((tonumber(w) or 300) * COMPACT + 0.5), 200, 400) end
        local W = calcW(o.Width)
        local GRIP, TUCK, M, HEADP = UIS.TouchEnabled and 32 or 24, 10, 10, 48
        local dockL = tostring(o.OpenDrag or "Left"):lower() == "right"
        local AX = dockL and 0 or 1
        local isP, destroyed, prog = false, false, 0
        local title0 = tostring(o.Title or "Panel")
        local GH = math.clamp(math.ceil(textW(string.upper(title0), 13, "title")) + 52, 88, 160)
        local minH = math.max(110, GH + 14)

        -- holder: nempel di tengah layar (vertikal), tinggi diatur fit() mengikuti isi
        local holder = new("Frame", {Name = "SORU_Panel", AnchorPoint = Vector2.new(AX, 0.5), Size = UDim2.fromOffset(W + GRIP, 200), BackgroundTransparency = 1, ZIndex = 60}, root)
        local function pos(p)
            local x = (1 - p) * W - p * M
            return UDim2.new(AX, dockL and -x or x, 0.5, 0)
        end
        holder.Position = pos(0)

        -- GRIP (dibuat duluan supaya ada di belakang body; 10px nyelip di bawah body jadi kelihatan seperti tab)
        local gy = math.clamp(tonumber(o.GripY) or 0.3, 0.12, 0.88)
        local cx = dockL and (TUCK + GRIP / 2) or (GRIP / 2)
        local function arrowRot(open)
            if dockL then return open and 90 or -90 end
            return open and -90 or 90
        end
        local grip = new("TextButton", {Name = "Grip", AnchorPoint = Vector2.new(1 - AX, gy), Position = UDim2.new(1 - AX, 0, gy, 0), Size = UDim2.fromOffset(GRIP + TUCK, GH),
            BackgroundColor3 = WHITE, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Active = true}, holder)
        corner(grip, 9)
        local gst = stroke(grip, WHITE, 1, 0.8)
        local function gseq() return ColorSequence.new(T.accent, T.accent2) end
        local gg = new("UIGradient", {Color = gseq(), Rotation = 90}, grip)
        local arrow, arrowPaint = chevron(grip, {Position = UDim2.fromOffset(cx, 16), Rotation = arrowRot(false)})
        arrowPaint(WHITE, true)
        local gt = text(grip, {Text = string.upper(title0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, GH / 2 + 9), Size = UDim2.fromOffset(GH - 38, 16),
            Rotation = dockL and -90 or 90, TextXAlignment = XC, W = "title", TextSize = 13})
        interact(grip, function(s) play(gst, {Transparency = (s == "idle") and 0.8 or 0.3}, DUR.fast) end)

        -- BODY
        local bh = new("Frame", {Name = "BodyHolder", AnchorPoint = Vector2.new(AX, 0), Position = UDim2.new(AX, 0, 0, 0), Size = UDim2.new(0, W, 1, 0), BackgroundTransparency = 1}, holder)
        local psh = shadow(bh, 0, 40, 6)
        psh.ImageTransparency = 1
        local body = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.side, BackgroundTransparency = 0.03, BorderSizePixel = 0, Active = true, ClipsDescendants = true}, bh)
        corner(body, 12)
        local bstG = new("UIGradient", {Rotation = 90}, stroke(body, WHITE, 1, 0.1))
        local function bseq() return ColorSequence.new(T.accent:Lerp(T.outline, 0.3), T.outline) end
        bstG.Color = bseq()

        -- header: gradien aksen -> sidebar, ikon logo, judul + subjudul, tombol tutup, garis aksen di bawah
        local function pseq()
            return ColorSequence.new({ColorSequenceKeypoint.new(0, T.side:Lerp(T.accent, 0.22)), ColorSequenceKeypoint.new(1, T.side)})
        end
        local hdr = new("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, HEADP), BackgroundColor3 = WHITE, BorderSizePixel = 0}, body)
        corner(hdr, 12)
        local hg1 = new("UIGradient", {Color = pseq()}, hdr)
        local hfill = new("Frame", {Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0}, hdr)
        local hg2 = new("UIGradient", {Color = pseq()}, hfill)
        trace(hdr, {Name = "AccentLine", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), ZIndex = 2}, "r")
        new("Frame", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 2}, hdr)

        local ibox = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T.bg, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 2}, hdr)
        corner(ibox, 8)
        skin(stroke(ibox, T.accent, 1, 0.45), "Color", "accent")
        logoImg(ibox, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16), ScaleType = Enum.ScaleType.Fit, ZIndex = 3})

        local hasSub = o.Subtitle ~= nil and tostring(o.Subtitle) ~= ""
        local TXW = 48
        local tl = text(hdr, {Text = title0, Position = UDim2.fromOffset(TXW, hasSub and 7 or 0), Size = UDim2.new(1, -(TXW + 56), 0, hasSub and 19 or HEADP), W = "label", TextSize = 15, ZIndex = 2})
        local sl = text(hdr, {Text = tostring(o.Subtitle or ""), Position = UDim2.fromOffset(TXW, 25), Size = UDim2.new(1, -(TXW + 56), 0, 14), TextSize = 11, W = 1, TextColor3 = T.dim, Visible = hasSub, ZIndex = 2})

        local CBS = UIS.TouchEnabled and 36 or 28
        local cb = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(CBS, CBS), BackgroundColor3 = T.el, BackgroundTransparency = 0.45, Text = "",
            AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3}, hdr)
        corner(cb, "md")
        local cst = stroke(cb, T.outline, 1, "line")
        local cic, cicPaint = chevron(cb, {Position = UDim2.fromScale(0.5, 0.5), Rotation = dockL and 90 or -90, ZIndex = 4})
        interact(cb, function(s)
            local hot = s ~= "idle"
            play(cb, {BackgroundColor3 = hot and T.hover or T.el, BackgroundTransparency = hot and 0.15 or 0.45}, DUR.fast)
            play(cst, {Color = hot and T.accent or T.outline, Transparency = hot and 0.2 or STROKE.line}, DUR.fast)
            cicPaint(hot and T.text or T.dim)
        end)

        -- isi
        local pscroll = new("ScrollingFrame", {Active = true, Position = UDim2.fromOffset(0, HEADP), Size = UDim2.new(1, 0, 1, -HEADP), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, body)
        skin(pscroll, "ScrollBarImageColor3", "accent")
        local plist = new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, pscroll)
        new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, pscroll)
        -- pudar tipis di tepi bawah: penanda masih ada isi yang bisa di-scroll (hanya menutup padding bawah kalau isi muat)
        local pfade = new("Frame", {Name = "Fade", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = T.side, BorderSizePixel = 0, ZIndex = 5}, body)
        new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)}, pfade)

        -- tinggi panel = header + isi (maks 70% tinggi layar). Ikut berubah saat accordion buka/tutup & saat layar di-resize
        local function fit(anim)
            if destroyed then return end
            local s = math.max(rootScale.Scale, 0.01)
            local maxH = math.max(minH, gui.AbsoluteSize.Y / s * 0.7)
            local want = HEADP + 22 + plist.AbsoluteContentSize.Y / s
            local sz = UDim2.fromOffset(W + GRIP, math.floor(math.clamp(want, minH, maxH)))
            if anim then play(holder, {Size = sz}, 0.2) else holder.Size = sz end
        end
        bind(plist:GetPropertyChangedSignal("AbsoluteContentSize"), function() fit() end)
        bind(rootScale:GetPropertyChangedSignal("Scale"), function() fit() end)
        fit()

        -- drawer dropdown butuh ruang: begitu dipakai pertama kali, tinggi minimum panel dinaikkan
        local pctx = newCtx(body, 12)
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

        local function goTo(open)
            local was = isP
            isP = open and true or false
            prog = isP and 1 or 0
            if not isP and pctx.d then pctx.d.close() end
            play(holder, {Position = pos(prog)}, 0.45, QUINT)
            play(psh, {ImageTransparency = isP and 0.5 or 1}, 0.4)
            play(arrow, {Rotation = arrowRot(isP)}, 0.3)
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

        themeFns[#themeFns + 1] = function()
            gg.Color = gseq()
            hg1.Color, hg2.Color = pseq(), pseq()
            bstG.Color = bseq()
            cicPaint(T.dim, true)
        end

        function K:Show() goTo(true) end
        function K:Hide() goTo(false) end
        function K:Switch() goTo(not isP) end
        function K:IsOpen() return isP end
        function K:SetTitle(t) tl.Text, gt.Text = tostring(t), string.upper(tostring(t)) end
        function K:SetSubtitle(t)
            local s = (t == nil) and "" or tostring(t)
            sl.Text, sl.Visible = s, s ~= ""
            tl.Position = UDim2.fromOffset(TXW, s ~= "" and 7 or 0)
            tl.Size = UDim2.new(1, -(TXW + 56), 0, s ~= "" and 19 or HEADP)
        end
        function K:SetVisible(v) holder.Visible = v and true or false end
        function K:SetWidth(w)
            W = calcW(w)
            bh.Size = UDim2.new(0, W, 1, 0)
            fit()
            holder.Position = pos(prog)
        end
        function K:Destroy() if not destroyed then destroyed = true holder:Destroy() end end
        if o.Open then
            isP, prog = true, 1
            holder.Position = pos(1)
            psh.ImageTransparency = 0.5
            arrow.Rotation = arrowRot(true)
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
            Callback = function(v)
                NOANIM = v and true or false
            end})
    end

    if C.Demo then
        local S = Window:Tab({Title = "Showcase", Icon = "rbxassetid://107005941750079"})
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
