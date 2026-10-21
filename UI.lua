--[[
    SORU HUB UI v5.3  (API 100% kompatibel dengan v2.x / v3.x / v4.x)

    BARU DI v5.3  (sidebar window baru)
      Sidebar   : bisa dilipat jadi mode ikon (tombol di kepala sidebar, tersimpan di config) dengan tooltip nama tab,
                  grup tab dengan judul + garis pemisah, ikon tab bisa huruf / simbol / asset gambar, footer profil ikut mengecil
      Header    : chip menampilkan FPS + ping, breadcrumb tab aktif
      Dashboard : kartu statistik berbahasa visual sama dengan kartu komponen;  Toast: stripe aksen

    BARU DI v5.2  (panel samping baru)
      Panel     : fisika spring (buka/tutup mengalir, lepas geseran = meluncur sesuai kecepatan), tanpa pegangan resize
                  sehingga stabil saat diisi banyak kartu. Di kanan layar (OpenDrag = "Left") atau kiri layar (OpenDrag = "Right").
                  Style disatukan dengan window: header berbanner + halo, footer profil, grip bertulisan vertikal, cahaya latar.

    BARU DI v5.1  (perombakan visual)
      Kartu     : wash warna + stripe aksen yang menyala saat hover / aktif, ikon tile di setiap komponen, kedalaman gradien baru
      Toggle    : saklar besar bertuliskan ON/OFF, seluruh kartu menyala saat ON
      Button    : kartu aksi berwarna dengan badge gradien yang bercahaya + gelombang saat diklik
      Slider    : track tabung berkilau + tick step + label min/max, knob berhalo, shimmer saat digeser
      Dropdown  : pill nilai + tombol chevron bulat, daftar opsi di panel cekung dengan bar penanda
      Keybind   : keycap 3D;  ColorPicker: swatch bercahaya + panel cekung;  Section: kapsul
      Accordion : timeline (garis + titik) di dalam panel cekung, badge jumlah item
      Tab       : sidebar berikon, pill aktif bercahaya, breadcrumb di header, header berbanner
      Panel     : header berbanner, pegangan tab bertulisan vertikal, cahaya latar lebih terasa

    BARU DI v5.0  (polish + perbaikan bug)
      Background : tipe file dibaca dari ekstensi (.mp4 / .webm = video, .png / .jpg = gambar) dan dimuat di belakang layar,
                   jadi UI langsung muncul. File rusak / 404 tidak lagi disimpan, getcustomasset dibungkus pcall.
      Smooth     : slider berinterpolasi halus, window mengikuti kursor dengan easing, animasi ambient berhenti saat window ditutup,
                   satu loop render untuk FPS / parallax / drag, save config di-debounce (tidak ada hitch saat toggle)
      Perbaikan  : warna hover ikut tema, Toggle / Slider :Set sinkron ke config, step slider dihitung dari Min,
                   Keybind tidak nyangkut saat listening, toast dibatasi, error di callback tidak merusak UI,
                   nama game dimuat async, Panel ikut dibersihkan saat window dihancurkan, kebocoran tabel transparansi
      Komponen   : ColorPicker punya input hex, Textbox numeric aman, Dropdown tetap terfilter saat Refresh
      Panel      : Window:Panel (+ alias Tab:Panel), drag tab lebih mulus, animasi ambient berhenti saat panel tertutup

    API
      local Window = SORU:CreateWindow({
          Title = "SORU HUB", SupportedGames = {123}, KickIfNotSupported = true,
          ReferenceSize = Vector2.new(1280, 720), Scale = 1,
          ToggleKey = Enum.KeyCode.RightShift,
          Demo = false, -- true = tambah tab "Showcase" berisi semua komponen
          Background = "https://.../bg.webm",  -- .webm / .mp4 (video loop) | .png / .jpg | rbxassetid | path lokal | false = tanpa background
          BackgroundAspect = 16/9,             -- rasio video (lebar/tinggi)
          BackgroundFrames = {"https://.../f01.png"}, BackgroundFPS = 12,  -- alternatif: frame sequence (1 - 30 fps)
      })
      local Tab = Window:Tab({Title = "Main", Icon = "M", Group = "Combat"})   -- Icon: huruf / simbol / rbxassetid; Group (opsional): judul grup di sidebar
      Tab:Button({Title, Desc, Callback = function() end})
      Tab:Toggle({Title, Flag, Default, Desc, Callback = function(v) end})        -- :Set(v, fire) :Get()
      Tab:Slider({Title, Flag, Min, Max, Step, Default, Suffix, Callback = function(v) end})
      Tab:Textbox({Title, Flag, Default, Placeholder, Numeric, Min, Max, Live, ClearOnFocus, Callback = function(text|number) end})
      Tab:Dropdown({Title, Flag, Options = {}, Default, Multi, Callback = function(value|array) end})  -- :Set(v) :Get() :Refresh(opts)
      Tab:Keybind({Title, Flag, Default = Enum.KeyCode.X, Callback = function(key) end, OnChange = function(key) end})
      Tab:ColorPicker({Title, Flag, Default = Color3, Callback = function(color) end})
      Tab:Accordion({Title, Desc, Open}) -> berisi komponen di atas (:Expand :Collapse :SetOpen :IsOpen)
      Tab:Paragraph({Title, Desc})
      Tab:Section("Judul") / Tab:Divider() / Tab:Label("Teks")

    PANEL  (panel samping dengan fisika spring, digeser dari tepi layar)
      local P = Window:Panel({
          Title = "Quick Panel", Subtitle = "Pengaturan cepat",
          Width = 300,                          -- 220 - 520
          Open = false,                         -- true = mulai terbuka
          GripY = 0.3,                          -- posisi vertikal grip 0.1 - 0.9
          OpenDrag = "Left",                    -- "Left": panel di kanan layar, geser grip ke kiri untuk buka | "Right": panel di kiri layar
          Footer = true,                        -- false = tanpa footer profil
          Callback = function(isOpen) end,
      })
      P:Section / P:Toggle / P:Slider / P:Button ... (semua komponen Tab bisa dipakai; Tab:Panel({...}) sama dengan Window:Panel({...}))
      P:Show() P:Hide() P:Switch() P:IsOpen() P:SetTitle() P:SetSubtitle() P:SetVisible() P:SetWidth(w) P:Destroy()
      Tap grip = buka/tutup, tarik grip = geser, lepas dengan kecepatan = lanjut meluncur.
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
local ContentProvider = game:GetService("ContentProvider")

local CFG = "SORU_HUB" local CFGS = CFG.."/configs"
pcall(function() if makefolder then if not isfolder(CFG) then makefolder(CFG) end if not isfolder(CFGS) then makefolder(CFGS) end end end)
local SIZE_FILE = "soru.size"
local SIZE_FILE2 = CFG.."/soru.size"

----------------------------------------------------------------------
-- ASET (icon, background) - semua akses file dibungkus pcall
----------------------------------------------------------------------
local URLS = {
    ICON = "https://raw.githubusercontent.com/dam45383-netizen/UI/main/SORU_S_ICON_1024.png",
    BG = "https://raw.githubusercontent.com/dam45383-netizen/UI/main/SORU_THEME_1024.mp4",     -- background bawaan (video)
    BG_IMG = "https://raw.githubusercontent.com/dam45383-netizen/UI/main/SORU_THEME_1024.png", -- cadangan kalau video gagal (boleh tidak ada)
}

local function assetOf(p)
    if not getcustomasset then return nil end
    local ok, a = pcall(getcustomasset, p)
    if ok and type(a) == "string" and a ~= "" then return a end
    return nil
end
-- unduh sekali, simpan di folder SORU_HUB, balikan content id (atau nil kalau gagal)
local function getAsset(name, url)
    if not (isfile and getcustomasset) then return nil end
    local p = CFG.."/"..name
    local ok, has = pcall(isfile, p)
    if ok and has then
        local a = assetOf(p)
        if a then return a end
    end
    if url and writefile then
        local ok2, data = pcall(function() return game:HttpGet(url) end)
        if ok2 and type(data) == "string" and #data > 64 and not data:find("^404") then
            pcall(writefile, p, data)
            task.wait(0.05)
            return assetOf(p)
        end
    end
    return nil
end
local function urlExt(src)
    local s = tostring(src or ""):lower():gsub("%?.*$", "")
    return s:match("%.(%w+)$")
end
local function bgKind(src)
    local e = urlExt(src)
    if e == "webm" or e == "mp4" then return "video" end
    if e == "gif" then return "gif" end
    return "image"
end
-- url / rbxassetid / path lokal -> content id (nil kalau gagal)
local function srcAsset(src)
    src = tostring(src or "")
    if src == "" then return nil end
    if src:match("^rbxasset") then return src end
    if src:match("^%d+$") then return "rbxassetid://"..src end
    if src:match("^https?://") then
        local h = 5381
        for i = 1, #src do h = (h * 33 + src:byte(i)) % 4294967296 end
        return getAsset("SORU_BG_"..h.."."..(urlExt(src) or "bin"), src)
    end
    if isfile and getcustomasset then
        local ok, has = pcall(isfile, src)
        if ok and has then return assetOf(src) end
    end
    return nil
end
local ICON = getAsset("SORU_S_ICON_1024.png", URLS.ICON) or ""

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
-- balikan: content id (atau nil), apakah barusan dibuat (supaya pemanggil bisa yield sebentar)
local function sfxAsset(name, def)
    if not (writefile and isfile and getcustomasset) then return nil, false end
    local file = CFG.."/sfx_k1_"..name..".wav"
    local okf, has = pcall(isfile, file)
    local gen = false
    if not (okf and has) then
        gen = true
        local made = pcall(function()
            local RATE, TAU = 22050, math.pi * 2
            local function le(x, n)
                local t = {}
                for i = 1, n do t[i] = string.char(x % 256) x = math.floor(x / 256) end
                return table.concat(t)
            end
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
        end)
        if not made then return nil, false end
    end
    return assetOf(file), gen
end

----------------------------------------------------------------------
-- THEME
----------------------------------------------------------------------
local T = {
    ink       = Color3.fromRGB(7, 6, 13),
    panel     = Color3.fromRGB(15, 13, 27),
    card      = Color3.fromRGB(28, 24, 48),
    cardHover = Color3.fromRGB(44, 38, 78),
    cardDown  = Color3.fromRGB(62, 50, 114),
    stroke    = Color3.fromRGB(78, 70, 124),
    text      = Color3.fromRGB(246, 244, 255),
    dim       = Color3.fromRGB(150, 142, 186),
    accent    = Color3.fromRGB(145, 96, 255),
    accent2   = Color3.fromRGB(94, 106, 255),
    cyan      = Color3.fromRGB(56, 200, 255),
    pink      = Color3.fromRGB(245, 80, 165),
    ok        = Color3.fromRGB(74, 222, 128),
    warn      = Color3.fromRGB(250, 204, 21),
    bad       = Color3.fromRGB(248, 113, 113),
    off       = Color3.fromRGB(52, 50, 74),
    input     = Color3.fromRGB(13, 11, 23),
}
local ACCENT, ACCENT2, DIM = T.accent, T.accent2, T.dim
local WHITE = Color3.new(1, 1, 1)
local VERSION = "5.3"
local SHADOW_ID = "6014261993" -- kosongkan ("") kalau shadow/neon tidak muncul
local FULL = UDim.new(1, 0)
local RING = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.35, T.cyan), ColorSequenceKeypoint.new(0.7, T.pink), ColorSequenceKeypoint.new(1, T.accent)}
local RING2 = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.5, T.cyan), ColorSequenceKeypoint.new(1, T.accent)}

-- preset warna: {accent, accent2, cyan, pink}  (126 tema, ditulis dengan hex)
local THEMES, THEME_ORDER = {}, {}
do
    local function hx(s)
        s = s:gsub("#", "")
        return Color3.fromRGB(tonumber(s:sub(1, 2), 16), tonumber(s:sub(3, 4), 16), tonumber(s:sub(5, 6), 16))
    end
    local function add(name, a, b, c, d)
        THEMES[name] = {hx(a), hx(b), hx(c), hx(d)}
        THEME_ORDER[#THEME_ORDER + 1] = name
    end

    -- bawaan + sebelumnya
    add("Violet", "9160FF", "5E6AFF", "38C8FF", "F550A5")
    add("Ocean", "28A0FF", "3870FF", "2DE6CD", "7882FF")
    add("Crimson", "FF4664", "DC2650", "FFA046", "FF5AAA")
    add("Emerald", "2DD496", "10AA78", "3CBEFF", "BEEB50")
    add("Sunset", "FF963C", "F0465A", "FFCD46", "FF5AAA")
    add("Rose", "FF6996", "E63C78", "FFBE78", "C86EFF")
    add("Sakura", "FF96BE", "DC6ED2", "96D2FF", "FFC878")
    add("Mint", "50E6BE", "28BEAA", "82C8FF", "D2F06E")
    add("Aqua", "1ED2E6", "2896EB", "78FFD2", "AA8CFF")
    add("Ice", "82C8FF", "648CFF", "C8EBFF", "BEA0FF")
    add("Sky", "46AAFF", "3278E6", "82E6FF", "FFAAC8")
    add("Midnight", "5A6EFF", "3C46C8", "50C8FF", "AA64FF")
    add("Gold", "FABE28", "EB8C1E", "FFE678", "FF785A")
    add("Lava", "FF5F32", "E12D2D", "FFB43C", "FF508C")
    add("Toxic", "A0F028", "5AC83C", "E6FF50", "3CDCAA")
    add("Cyber", "FF28C8", "8C3CFF", "28F0FF", "FFDC32")
    add("Orchid", "D26EFF", "A050E6", "78AAFF", "FF78C8")
    add("Berry", "BE3CAA", "8232C8", "FF6EAA", "5AAAFF")
    add("Forest", "50BE64", "288C5A", "BEDC5A", "50C8C8")
    add("Coffee", "D29664", "AA6E46", "F0C88C", "E6786E")
    add("Peach", "FFA078", "F56E64", "FFD796", "F082B4")
    add("Steel", "7896BE", "506EA0", "96DCF0", "C8AAFF")
    add("Mono", "BEC2D6", "787EA0", "EBEEFA", "96AAFF")

    -- merah & oranye
    add("Ruby", "E0314B", "B3203F", "FF8A5C", "FF5FA2")
    add("Cherry", "F2385A", "C2184B", "FFA07A", "FF6FB5")
    add("Blood", "D61F2C", "9E1220", "FF6B4A", "E8457A")
    add("Coral", "FF6F61", "F2496B", "FFC27A", "E96AD0")
    add("Tangerine", "FF8A1F", "F25C05", "FFC93C", "FF4F7B")
    add("Amber", "FFB000", "E08700", "FFE066", "FF6B3D")
    add("Mango", "FFA62B", "FF6F3C", "FFD470", "F05C9C")
    add("Ember", "FF7A18", "E0401C", "FFD04A", "FF3D7F")
    add("Flame", "FF5E2B", "FF2E4F", "FFB347", "FF7EB6")
    add("Rust", "C8623A", "9A4326", "F0B26B", "D9567A")
    add("Copper", "D98550", "B0643A", "F5C98E", "E0607E")

    -- kuning & krem
    add("Lemon", "F5E34A", "D9B91E", "FFF59A", "8DE07A")
    add("Honey", "F2B84B", "D98E2B", "FFE19A", "F08A6B")
    add("Sand", "E3C48A", "BF9A5E", "F5E6C0", "D9887A")

    -- hijau
    add("Lime", "B6F03C", "7CCB2B", "E4FF7A", "3DE0A0")
    add("Venom", "7DFF4D", "3DC21E", "C8FF3D", "18E0A8")
    add("Jade", "2FBF8F", "1F8F6B", "7FE3C2", "6AA8FF")
    add("Pine", "2E8B63", "1F6B4A", "8FD0A0", "4FB7C9")
    add("Moss", "8DB255", "5F8A3A", "C9DE8A", "6FBF9B")
    add("Sage", "9CC5A1", "6F9F7E", "D4E8C2", "7FB7C4")
    add("Clover", "4CC764", "2E9E4B", "A6E86B", "3AC9C0")
    add("Matcha", "A7D676", "78B04A", "DDF0A8", "7ECFA6")
    add("Spring", "7EE36B", "3FC46B", "D2F57A", "4FD8E0")
    add("Kiwi", "9BD44A", "5FA82E", "D6F27A", "4FD0B0")
    add("Seafoam", "5FE0B7", "2FB39A", "A8F0DC", "6EC1F0")
    add("Matrix", "00FF66", "00B347", "7CFFB2", "00E5FF")

    -- teal & cyan
    add("Teal", "14B8A6", "0E8F83", "5EEAD4", "60A5FA")
    add("Lagoon", "21C5C5", "1790B8", "7CF0E6", "8E9BFF")
    add("Glacier", "7FDBE8", "4FA3D9", "D3F6FB", "A9A2F5")
    add("Cyan", "00D8FF", "0094E0", "7DF9FF", "FF4FD8")
    add("Tidal", "2AA7C9", "1D6FA3", "6FE0D2", "F28AB2")
    add("Deepsea", "1B8FB5", "12608F", "4FD1C5", "7A8CFF")
    add("Peacock", "1AA6A0", "126F8F", "66E0A8", "A66CFF")
    add("Reef", "FF7F6B", "1FB8C9", "FFD36B", "8F7CF0")
    add("Tropical", "1FD6A2", "FF6B8B", "FFC93C", "2EB8F5")

    -- biru
    add("Cobalt", "3D6BFF", "2447D6", "6FA8FF", "B06BFF")
    add("Royal", "4B5CF0", "3037C4", "7AA2FF", "C76BF0")
    add("Sapphire", "2F6FED", "1B49B8", "5FC3FF", "8F7CFF")
    add("Azure", "3AA0FF", "2272E0", "7FE0FF", "FF7FB0")
    add("Denim", "5B84C4", "3F5F99", "9EC5F0", "C08FD6")
    add("Navy", "3E5BC4", "28388F", "6FA8E8", "9A7BE0")
    add("Indigo", "6366F1", "4338CA", "38BDF8", "E879F9")
    add("Cornflower", "7C9CFF", "5577E6", "B7D0FF", "E6A0F5")
    add("Electric", "2D7DFF", "1E3FFF", "00E0FF", "FF2DA8")
    add("Blueberry", "5A6BE6", "3A3FA8", "8FA8FF", "C46BE0")

    -- ungu
    add("Grape", "9B4DE0", "6A2FB8", "D28CFF", "FF6FB5")
    add("Amethyst", "9966CC", "6F3FA3", "C9A0F0", "F081C8")
    add("Lavender", "B49CFF", "8E78E6", "E1D6FF", "FFA6D9")
    add("Wisteria", "A78BFA", "7C6AD8", "D9CCFF", "F5A8D0")
    add("Plum", "A64D9E", "7A2F75", "E08CC6", "7C8CFF")
    add("Mulberry", "8E3A8C", "5E2460", "D07FC9", "6F96E6")
    add("Ultraviolet", "8B3DFF", "5A1FE0", "C77DFF", "3DE0FF")
    add("Twilight", "7C6CF2", "4F3FBF", "5ECBF0", "F28FC0")
    add("Dusk", "8F7AD6", "5E4FA3", "7FBDE0", "F0A0B8")
    add("Galaxy", "6D4BFF", "2F1FA8", "00C2FF", "B05CFF")
    add("Nebula", "7B5CFF", "4A2FBF", "46D9FF", "FF5CC2")
    add("Cosmos", "5B4FE0", "2A2490", "4FC8F0", "E05CC8")
    add("Vapor", "C084FC", "818CF8", "7DD3FC", "F0ABFC")

    -- pink
    add("Bubblegum", "FF7EC8", "E255A8", "7FD8FF", "FFB8E0")
    add("Flamingo", "FF6FA8", "E5427F", "FFA77A", "FFB0C8")
    add("Candy", "FF5FA8", "C23BD6", "5FE0FF", "FFD84A")
    add("Blush", "F7A8B8", "E07A96", "C9A7F0", "FFD9E0")
    add("HotPink", "FF2E93", "D6106F", "8C5CFF", "FF8CC6")
    add("Raspberry", "D81B6A", "A30F52", "B06BE0", "FF6FA3")
    add("Strawberry", "F2406A", "C01F4A", "8EDB7A", "FF8FA3")
    add("Lychee", "FF9EB5", "E8738F", "B79CF0", "FFD6C2")
    add("Cotton", "FFB3DE", "B8A3FF", "A3E6FF", "FFE0A3")
    add("Magenta", "E52BC8", "A81F9E", "5AC8FF", "FF7AE5")

    -- netral & gelap
    add("Graphite", "8A93A8", "5C6478", "7EA6E8", "C5CCDC")
    add("Slate", "7B8BA6", "55637E", "9C8CE0", "B4C2DA")
    add("Silver", "C0C6D4", "8F97AB", "9FB4FF", "F0F2F8")
    add("Obsidian", "6B5BD2", "3E3490", "3CB4E6", "D6478F")
    add("Noir", "B8B8D0", "7A7A9A", "FF4D6D", "E8E8F5")
    add("Carbon", "5FA8D3", "3C6E91", "E87D7D", "A8D8F0")

    -- cokelat
    add("Cocoa", "B5805A", "8A5A3C", "E0B88F", "D9707A")
    add("Chocolate", "A0684A", "70402C", "D9A07A", "C45E6E")

    -- alam & musim
    add("Autumn", "E07B39", "B5502A", "F2C14E", "C7506A")
    add("Winter", "8FB8E8", "5D8BC4", "DDEBFA", "B5A3E0")
    add("Summer", "FFB830", "FF7A3D", "3DD6E0", "FF5C8A")
    add("Aurora", "4DE8B0", "5C7CFA", "3DD6F5", "C26BFF")
    add("Eclipse", "F2A33A", "5A3FC0", "FFD27A", "8A5CF0")
    add("Sunrise", "FF9A5C", "FF5E7E", "FFD36B", "B879FF")
    add("Horizon", "F28C5C", "C2527A", "FFC38A", "6C7CE0")
    add("Watermelon", "FF4F6D", "2ECF7A", "FF9AAE", "9AF0B8")

    -- retro & neon
    add("Synthwave", "FF2E97", "7B2FF7", "2DE2E6", "F9C80E")
    add("Retrowave", "FF4FD8", "5B3FFF", "00E5FF", "FFB000")
    add("Vaporwave", "FF71CE", "B967FF", "01CDFE", "05FFA1")
    add("Outrun", "FF3F7F", "6A1FD6", "29D3FF", "FFD23F")
    add("Tokyo", "F72585", "7209B7", "4CC9F0", "4361EE")
    add("Miami", "FF5E9C", "22D3C5", "FFD166", "7B6CFF")
    add("Cyberpunk", "FCEE21", "00E5FF", "FF2A6D", "9B5CFF")

    -- palet populer
    add("Dracula", "BD93F9", "6272A4", "8BE9FD", "FF79C6")
    add("Nord", "88C0D0", "5E81AC", "8FBCBB", "B48EAD")
    add("Gruvbox", "FABD2F", "D65D0E", "8EC07C", "FB4934")
    add("Monokai", "A6E22E", "F92672", "66D9EF", "FD971F")
    add("Solarized", "268BD2", "6C71C4", "2AA198", "D33682")
    add("TokyoNight", "7AA2F7", "3D59A1", "7DCFFF", "BB9AF7")
    add("Mocha", "CBA6F7", "89B4FA", "94E2D5", "F5C2E7")
    add("RosePine", "C4A7E7", "31748F", "9CCFD8", "EBBCBA")
    add("Everforest", "A7C080", "5C8A6E", "7FBBB3", "E67E80")
    add("Ayu", "FFB454", "59C2FF", "95E6CB", "F07178")
    add("OneDark", "61AFEF", "528BFF", "56B6C2", "C678DD")
    add("Palenight", "82AAFF", "6A7BD8", "89DDFF", "C792EA")
end
    local function applyPalette(name)
    local p = THEMES[name]
    if not p then return nil end
    local old = {T.accent, T.accent2, T.cyan, T.pink}
    T.accent, T.accent2, T.cyan, T.pink = p[1], p[2], p[3], p[4]
    ACCENT, ACCENT2 = p[1], p[2]
    RING = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.35, T.cyan), ColorSequenceKeypoint.new(0.7, T.pink), ColorSequenceKeypoint.new(1, T.accent)}
    RING2 = ColorSequence.new{ColorSequenceKeypoint.new(0, T.accent), ColorSequenceKeypoint.new(0.5, T.cyan), ColorSequenceKeypoint.new(1, T.accent)}
    return old
end
-- warna palet disimpan sebagai indeks supaya "warna istirahat" ikut berganti saat tema diganti
local function palIdx(c)
    if c == T.accent then return 1 elseif c == T.accent2 then return 2 elseif c == T.cyan then return 3 elseif c == T.pink then return 4 end
    return nil
end
local function palCol(i)
    if i == 1 then return T.accent elseif i == 2 then return T.accent2 elseif i == 3 then return T.cyan end
    return T.pink
end
-- FONT
local FAMILY = "Nunito" -- alternatif: "TitilliumWeb" (gaming/tech), "Ubuntu", "Jura", "Roboto"
local function mkFont(w) return Font.new("rbxasset://fonts/families/"..FAMILY..".json", w) end
local FONT_FACES = {
    [Enum.Font.Gotham]       = mkFont(Enum.FontWeight.Regular),
    [Enum.Font.GothamMedium] = mkFont(Enum.FontWeight.Medium),
    [Enum.Font.GothamBold]   = mkFont(Enum.FontWeight.Bold),
    [Enum.Font.Code]         = Font.new("rbxasset://fonts/families/RobotoMono.json"),
}
----------------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------------
local function new(class, props, parent)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k == "Font" and FONT_FACES[v] then o.FontFace = FONT_FACES[v]
            else o[k] = v end
        end
    end
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

-- ikon kecil dari frame (tanpa asset): tile gradien + glyph.  kind: toggle slider list key play color text group info
local function makeIcon(parent, kind, size)
    size = size or 28
    local k = size / 28
    local tile = new("Frame", {Name = "Icon", Size = UDim2.fromOffset(size, size), BackgroundColor3 = WHITE, BackgroundTransparency = 0.62, BorderSizePixel = 0, ZIndex = 2}, parent)
    corner(tile, math.floor(size * 0.34))
    grad(tile, T.accent, T.accent2, 45)
    stroke(tile, T.accent, 1, 0.55)
    local c = size / 2
    local function part(w, h, x, y, col, tr, r, rot)
        local b = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(c + x * k, c + y * k), Size = UDim2.fromOffset(math.max(1, w * k), math.max(1, h * k)), BackgroundColor3 = col or WHITE, BackgroundTransparency = tr or 0, BorderSizePixel = 0, Rotation = rot or 0, ZIndex = 3}, tile)
        corner(b, r or FULL)
        return b
    end
    if kind == "toggle" then
        part(16, 9, 0, 0, WHITE, 0.5)
        part(5, 5, 3.5, 0, T.cyan, 0)
    elseif kind == "slider" then
        part(16, 2, 0, 0, WHITE, 0.5)
        part(9, 2, -3.5, 0, T.cyan, 0)
        part(6, 6, 1, 0, WHITE, 0)
    elseif kind == "list" then
        part(14, 2, 0, -5, WHITE, 0.1)
        part(14, 2, 0, 0, WHITE, 0.45)
        part(9, 2, -2.5, 5, WHITE, 0.45)
    elseif kind == "key" then
        local b = part(14, 12, 0, 0, WHITE, 1, 4)
        stroke(b, WHITE, 1.5, 0.1)
        part(6, 2, 0, 0, T.cyan, 0)
    elseif kind == "play" then
        part(8, 2.2, 0, -2.8, WHITE, 0, FULL, 45)
        part(8, 2.2, 0, 2.8, WHITE, 0, FULL, -45)
    elseif kind == "color" then
        local b = part(14, 14, 0, 0, WHITE, 0)
        new("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 120)), ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 210, 80)), ColorSequenceKeypoint.new(0.65, Color3.fromRGB(70, 220, 200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 100, 255))}, Rotation = 45}, b)
    elseif kind == "text" then
        label(tile, {Text = "Aa", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = math.max(8, math.floor(11 * k)), ZIndex = 3, TextTruncate = Enum.TextTruncate.None})
    elseif kind == "group" then
        part(14, 5, 0, -4, WHITE, 0.1, 2)
        part(14, 5, 0, 4, WHITE, 0.5, 2)
    elseif kind == "info" then
        label(tile, {Text = "i", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = math.max(9, math.floor(13 * k)), ZIndex = 3, TextTruncate = Enum.TextTruncate.None})
    end
    return tile
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
local function loop(o, secs, props, style)
    local t = TweenService:Create(o, TweenInfo.new(secs, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), props)
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

-- panggil callback milik user tanpa merusak UI kalau callback-nya error
local function safe(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[SORU HUB] "..tostring(err)) end
end

local TWC, TWN = {}, 0
local BOLD_FACE = FONT_FACES[Enum.Font.GothamBold]
local function textW(txt, size)
    txt = tostring(txt)
    local key = txt..":"..size
    local c = TWC[key]
    if c then return c end
    local w = #txt * (size * 0.6)
    pcall(function()
        local p = Instance.new("GetTextBoundsParams")
        p.Text, p.Font, p.Size, p.Width = txt, BOLD_FACE, size, 800
        w = TextService:GetTextBoundsAsync(p).X
    end)
    TWN = TWN + 1
    if TWN > 400 then TWC, TWN = {}, 0 end
    TWC[key] = w
    return w
end

local function hover(b, s, hoverC, downC)
    local bg0 = b.BackgroundColor3
    hoverC = hoverC or T.cardHover
    downC = downC or T.cardDown
    local c0, t0, ci = nil, nil, nil
    if s then c0, t0 = s.Color, s.Transparency ci = palIdx(c0) end
    local inside = false
    b.MouseEnter:Connect(function()
        inside = true
        sfx("hover")
        play(b, {BackgroundColor3 = hoverC}, 0.18)
        if s then play(s, {Color = ACCENT, Transparency = 0.25}, 0.18) end
    end)
    b.MouseLeave:Connect(function()
        inside = false
        play(b, {BackgroundColor3 = bg0}, 0.22)
        if s then play(s, {Color = ci and palCol(ci) or c0, Transparency = t0}, 0.22) end
    end)
    b.MouseButton1Down:Connect(function() play(b, {BackgroundColor3 = downC}, 0.08) end)
    b.MouseButton1Up:Connect(function() play(b, {BackgroundColor3 = inside and hoverC or bg0}, 0.2) end)
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
            local st = input.UserInputState
            if (st == Enum.UserInputState.End or st == Enum.UserInputState.Cancel) and not ended then
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

    local conns, cleanups = {}, {}
    local function bind(sig, fn) local c = sig:Connect(fn) conns[#conns + 1] = c return c end
    gui.Destroying:Connect(function()
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        for _, f in ipairs(cleanups) do pcall(f) end
    end)

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
    ""Http:JSONDecode(readfile(path("default"))) if d and type(d)=="table" then Data=d if not Data.Features then Data.Features={} end pcall(function() writefile(path(curName),Http:JSONEncode(Data)) end) end
    end
    end
    end)

    -- simpan config ditunda 0.45 detik (digabung) supaya tidak ada hitch I/O di tengah animasi
    local saveQ = false
    local function persist()
        if saveQ then return end
        saveQ = true
        task.delay(0.45, function() saveQ = false saveN(curName) end)
    end
    cleanups[#cleanups + 1] = function() if saveQ then saveQ = false saveN(curName) end end

    -- tema tersimpan dipakai sebelum UI dibuat
    local curTheme = "Violet"
    do
        local th = Data.Features["UITheme"]
        if type(th) == "string" and THEMES[th] then curTheme = th applyPalette(th) end
    end

    local toggleKey = C.ToggleKey or Enum.KeyCode.RightShift
    do local mk = Data.Features["MenuKey"] if type(mk) == "string" then toggleKey = toKey(mk) or toggleKey end end
    local binding = false
    local booting = false

    -- SOUND (dibuat di belakang layar; kalau belum pernah dibuat, sound muncul bertahap tanpa membekukan UI)
    local sndOn = (Data.Features["UISound"] ~= false)
    local sndVol = (type(Data.Features["UIVol"]) == "number") and math.clamp(Data.Features["UIVol"], 0, 100) / 100 or 0.6
    local sndBase, sndLast = {}, {}
    task.spawn(function()
        for name, def in pairs(SFX_DEFS) do
            local asset, gen = sfxAsset(name, def)
            if asset and gui.Parent then
                local s = Instance.new("Sound")
                s.Name = name s.SoundId = asset s.Volume = 1 s.Parent = gui
                sndBase[name] = {snd = s, dur = def[1]}
            end
            if gen then task.wait() end
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

    -- nama game dimuat async (GetProductInfo bisa lambat); label yang butuh nama didaftarkan lewat bindName
    local gameName = "Unknown"
    local nameBinds = {}
    local function bindName(fn) nameBinds[#nameBinds + 1] = fn fn(gameName) end
    task.spawn(function()
        local ok, info = pcall(function() return Market:GetProductInfo(placeId) end)
        if ok and info and info.Name then
            gameName = info.Name
            for _, fn in ipairs(nameBinds) do pcall(fn, gameName) end
        end
    end)

    ------------------------------------------------------------------
    -- ROOT + SISTEM SKALA (anti-DPI)
    ------------------------------------------------------------------
    local REF = C.ReferenceSize or Vector2.new(1280, 720)
    local root = new("Frame", {Name = "Root", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, gui)
    local rootScale = new("UIScale", {Scale = 1}, root)

    local userScale = math.clamp(C.Scale or 1, 0.6, 1.5)
    local virt = Vector2.new(REF.X, REF.Y)

    local DEFAULT_SIZE = Vector2.new(640, 420)
    local minSize = Vector2.new(480, 320)
    local maxSize = Vector2.new(960, 640)
    local winSize = DEFAULT_SIZE
    local winPos = nil
    local curPos = Vector2.new(0, 0)
    local dragging = false

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
            local okf, has = pcall(isfile, p)
            if okf and has then
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
    -- TOAST (maksimal 5 tampil sekaligus, klik untuk menutup)
    ------------------------------------------------------------------
    local toastHolder = new("Frame", {Name = "Toasts", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.new(0, 310, 1, -28), BackgroundTransparency = 1, ZIndex = 200}, root)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right}, toastHolder)
    local toastN = 0
    local toasts = {}
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
        local tstripe = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0.62, 0), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 203}, f)
        corner(tstripe, FULL)
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
        -- shine + ring pulse saat muncul
        local shine = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 56, 2.4, 0), Position = UDim2.new(-0.2, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 202}, f)
        new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.84), NumberSequenceKeypoint.new(1, 1)}}, shine)
        local pr = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 203}, ic)
        corner(pr, FULL)
        local prs = stroke(pr, color, 1.5, 0.2)
        local gone = false
        local entry = {}
        local function leave()
            if gone then return end
            gone = true
            for i, e in ipairs(toasts) do
                if e == entry then table.remove(toasts, i) break end
            end
            if not f.Parent then return end
            play(f, {Position = UDim2.fromOffset(350, 0)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            task.wait(0.28)
            if not wrap.Parent then return end
            play(wrap, {Size = UDim2.new(1, 0, 0, 0)}, 0.22)
            task.wait(0.24)
            wrap:Destroy()
        end
        entry.leave = leave
        toasts[#toasts + 1] = entry
        if #toasts > 5 then task.spawn(toasts[1].leave) end
        local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 210}, f)
        hit.MouseButton1Click:Connect(leave)
        play(f, {Position = UDim2.fromOffset(0, 0)}, 0.55, Enum.EasingStyle.Back)
        task.delay(0.2, function() if ic.Parent then play(icS, {Scale = 1}, 0.45, Enum.EasingStyle.Back) end end)
        task.delay(0.3, function()
            if shine.Parent then play(shine, {Position = UDim2.new(1.2, 0, 0.5, 0)}, 0.7, Enum.EasingStyle.Quad) end
            if pr.Parent then play(pr, {Size = UDim2.fromScale(2.3, 2.3)}, 0.8) play(prs, {Transparency = 1}, 0.8) end
        end)
        play(prog, {Size = UDim2.new(0, 0, 0, 2)}, dur, Enum.EasingStyle.Linear)
        task.delay(dur, leave)
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
    -- STATE + ENTRANCE + LOOP AMBIENT (berhenti otomatis saat window ditutup)
    ------------------------------------------------------------------
    local isOpen = false
    local openTok = 0
    local transTargets = {}
    local curTrans = (type(Data.Features["UITrans"]) == "number") and Data.Features["UITrans"] or 0.15
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
            if body.Parent then body.Position = UDim2.fromOffset(-30, 0) end
        end
        for i, body in ipairs(list) do
            task.delay(math.min(i - 1, 14) * 0.04, function()
                if body.Parent then play(body, {Position = UDim2.fromOffset(0, 0)}, 0.55, Enum.EasingStyle.Back) end
            end)
        end
    end

    local winLoops = {}
    local function wspin(g, s) local t = spin(g, s) winLoops[#winLoops + 1] = t return t end
    local function wloop(o, secs, props, style) local t = loop(o, secs, props, style) winLoops[#winLoops + 1] = t return t end
    local function setLoops(on)
        for _, t in ipairs(winLoops) do
            if on then t:Play() else t:Pause() end
        end
    end

    ------------------------------------------------------------------
    -- WINDOW SHELL
    ------------------------------------------------------------------
    local shell = new("Frame", {Name = "Shell", BackgroundTransparency = 1, Size = UDim2.fromOffset(winSize.X, winSize.Y), Visible = false, ZIndex = 10}, root)
    local shadow, neon = nil, nil
    if SHADOW_ID ~= "" then
        shadow = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.new(1, 64, 1, 64), BackgroundTransparency = 1, Image = "rbxassetid://"..SHADOW_ID, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 1}, shell)
        -- neon: bayangan berwarna aksen yang "bernapas"
        neon = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 30, 1, 30), BackgroundTransparency = 1, Image = "rbxassetid://"..SHADOW_ID, ImageColor3 = T.accent, ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 1}, shell)
        wloop(neon, 2.4, {Size = UDim2.new(1, 58, 1, 58)})
    end

    local win = new("CanvasGroup", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.ink, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 2}, shell)
    corner(win, 20)
    wspin(new("UIGradient", {Color = RING}, stroke(win, WHITE, 2, 0.18)), 8)
    local winScale = new("UIScale", {Scale = 0.12}, win)

    do
        local tint = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, win)
        new("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(20, 17, 36), Color3.fromRGB(8, 7, 14)), Rotation = 125}, tint)
    end
    local bgImg = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "", ImageTransparency = 0.82, ScaleType = Enum.ScaleType.Crop, ZIndex = 2}, win)
    local bgS = new("UIScale", {Scale = 1.05}, bgImg)

    -- BACKGROUND: bawaan = URLS.BG (video). Bisa diganti lewat C.Background / C.BackgroundFrames, C.Background = false -> polos.
    local vidRatio = tonumber(C.BackgroundAspect) or (16 / 9)
    local bgVidOn = false
    local bgBox = new("Frame", {Name = "BGVideo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, win)
    new("UIScale", {Scale = 1.08}, bgBox)
    local bgVid = new("VideoFrame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Looped = true, Volume = 0, ZIndex = 1}, bgBox)
    local vidDim = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(14, 12, 24), BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 2, Visible = false}, bgBox)

    local lastWr = 0
    -- video di-"crop" supaya menutup seluruh window (tanpa gepeng)
    local function fitVideo()
        local a = win.AbsoluteSize
        if a.X <= 0 or a.Y <= 0 then return end
        local wr = a.X / a.Y
        if math.abs(wr - lastWr) < 0.001 then return end
        lastWr = wr
        if wr > vidRatio then bgVid.Size = UDim2.fromScale(1, wr / vidRatio)
        else bgVid.Size = UDim2.fromScale(vidRatio / wr, 1) end
    end
    bind(win:GetPropertyChangedSignal("AbsoluteSize"), fitVideo)
    local function setVid(p) if bgVidOn then pcall(function() bgVid.Playing = p end) end end

    local function bgTargets(t)
        local it = math.clamp(0.9 - t * 0.8, 0.3, 1)
        return it, math.clamp(1 - (it - 0.12), 0, 1)
    end
    local function showImage(asset)
        local it = bgTargets(curTrans)
        bgImg.Image = asset
        bgImg.ImageTransparency = 1
        play(bgImg, {ImageTransparency = it}, 0.9, Enum.EasingStyle.Quad)
    end
    local function startVideo(asset)
        if not pcall(function() bgVid.Video = asset bgVid.Playing = true end) then return false end
        local t0 = os.clock()
        while not bgVid.IsLoaded and os.clock() - t0 < 12 do task.wait(0.1) end
        if not bgVid.IsLoaded then
            pcall(function() bgVid.Playing = false bgVid.Video = "" end)
            return false
        end
        bgVidOn = true
        lastWr = 0
        fitVideo()
        local _, dimT = bgTargets(curTrans)
        vidDim.BackgroundTransparency = 1
        vidDim.Visible = true
        bgImg.Visible = false
        play(vidDim, {BackgroundTransparency = dimT}, 0.9, Enum.EasingStyle.Quad)
        setVid(isOpen)
        return true
    end

    local function applyBackground()
        local frames, src = C.BackgroundFrames, C.Background
        local userSet = (src ~= nil) or (type(frames) == "table" and #frames > 0)
        if src == nil then src = URLS.BG end
        if type(frames) == "table" and #frames > 0 then
            -- mode frame sequence
            local list = {}
            for _, u in ipairs(frames) do
                local a = srcAsset(u)
                if a then list[#list + 1] = a end
            end
            if #list == 0 then return end
            pcall(function() ContentProvider:PreloadAsync(list) end)
            showImage(list[1])
            local dt = 1 / math.clamp(tonumber(C.BackgroundFPS) or 12, 1, 30)
            local i = 1
            while gui.Parent do
                if isOpen then
                    i = i % #list + 1
                    bgImg.Image = list[i]
                    task.wait(dt)
                else
                    task.wait(0.3)
                end
            end
        elseif type(src) == "string" and src ~= "" then
            local kind = bgKind(src)
            if kind == "gif" then
                task.wait(2.5)
                notify("Background", "GIF tidak didukung Roblox. Ubah ke .webm atau pakai BackgroundFrames.", T.warn, 6)
                return
            end
            local asset = srcAsset(src)
            if kind == "video" then
                if asset and startVideo(asset) then return end
                local fb = srcAsset(URLS.BG_IMG)
                if fb then showImage(fb) end
                if userSet then
                    task.wait(1)
                    notify("Background", fb and "Video gagal dimuat, pakai gambar biasa" or "Video gagal dimuat", T.warn, 4)
                end
            elseif asset then
                showImage(asset)
            elseif userSet then
                task.wait(2.5)
                notify("Background", "Gagal memuat background", T.bad, 4)
            end
        end
    end
    task.spawn(applyBackground)

    do
        local glow = new("Frame", {Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, win)
        new("UIGradient", {Color = ColorSequence.new(T.accent, T.accent2), Transparency = NumberSequence.new(0.78, 1), Rotation = 90}, glow)
    end

    -- aurora orb + partikel
    local ambientOn = (Data.Features["UIAnim"] ~= false)
    local ambient = new("Frame", {Name = "Ambient", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4, Visible = ambientOn}, win)
    do
        local function orb(col, size, px, py, dx, dy, secs)
            local o = new("Frame", {Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(px, py), BackgroundTransparency = 1, ZIndex = 4}, ambient)
            local layers = 7
            for i = 1, layers do
                local s = 1 - (i - 1) / layers * 0.9
                local c = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s), BackgroundColor3 = col, BackgroundTransparency = 0.94, BorderSizePixel = 0, ZIndex = 4}, o)
                corner(c, FULL)
            end
            wloop(o, secs, {Position = UDim2.fromScale(px + dx, py + dy)})
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
    end

    do
        local accentLine = new("Frame", {Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 15}, win)
        local ag = new("UIGradient", {Color = RING2}, accentLine)
        ag.Offset = Vector2.new(-1, 0)
        wloop(ag, 3.5, {Offset = Vector2.new(1, 0)})
    end

    do
        local zf = Data.Features["BGZoom"]
        if type(zf) == "number" then bgS.Scale = zf else wloop(bgS, 14, {Scale = 1.13}) end
    end

    local function applyTrans(t)
        t = math.clamp(t, 0, 0.7)
        curTrans = t
        for i = #transTargets, 1, -1 do
            local e = transTargets[i]
            if e.inst.Parent and e.inst:IsDescendantOf(gui) then
                e.inst.BackgroundTransparency = math.clamp(t + e.off, 0, 1)
            else
                table.remove(transTargets, i)
            end
        end
        local it, dimT = bgTargets(t)
        bgImg.ImageTransparency = it
        vidDim.BackgroundTransparency = dimT
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
                local c = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(z, z), BackgroundColor3 = (i % 2 == 0) and T.cyan or T.accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0}, box)
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
            for _, c in ipairs(layers) do play(c, {BackgroundTransparency = 0.955}, 0.3) end
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
    -- LAYOUT WINDOW (posisi mengikuti kursor dengan easing saat di-drag)
    ------------------------------------------------------------------
    local drawPos, easing = nil, false
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
        if dragging then
            shell.Size = UDim2.fromOffset(sz.X, sz.Y)
            if not drawPos then drawPos = curPos end
            easing = true
        elseif animate then
            drawPos, easing = curPos, false
            play(shell, {Size = UDim2.fromOffset(sz.X, sz.Y), Position = UDim2.fromOffset(x, y)}, 0.4)
        else
            drawPos, easing = curPos, false
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
    local pulse, lScale
    do
        corner(launcher, 16)
        spin(new("UIGradient", {Color = RING2}, stroke(launcher, WHITE, 1.8, 0)), 4)
        pulse = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(LAUNCH, LAUNCH), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 98, Visible = true}, launcher)
        corner(pulse, 18)
        local pulseS = stroke(pulse, ACCENT, 2, 0.2)
        local pInfo = TweenInfo.new(2.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, -1, false, 0.3)
        TweenService:Create(pulse, pInfo, {Size = UDim2.fromOffset(LAUNCH + 34, LAUNCH + 34)}):Play()
        TweenService:Create(pulseS, pInfo, {Transparency = 1}):Play()
        local lIcon = new("ImageLabel", {Size = UDim2.fromOffset(32, 32), Position = UDim2.new(0.5, -16, 0.5, -16), BackgroundTransparency = 1, Image = ICON, ScaleType = Enum.ScaleType.Fit, ZIndex = 100}, launcher)
        loop(new("UIScale", {Scale = 1}, lIcon), 1.6, {Scale = 1.1})
        -- dua titik kecil mengorbit launcher
        for k = 1, 2 do
            local oh = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(LAUNCH + 12, LAUNCH + 12), BackgroundTransparency = 1, BorderSizePixel = 0, Rotation = (k - 1) * 180, ZIndex = 101}, launcher)
            local od = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(5, 5), BackgroundColor3 = (k == 1) and T.cyan or T.pink, BorderSizePixel = 0, ZIndex = 101}, oh)
            corner(od, FULL)
            spin(oh, 5)
        end
        lScale = new("UIScale", {Scale = 1}, launcher)
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
    cleanups[#cleanups + 1] = function() if blur then pcall(function() blur:Destroy() end) end end

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
        play(win, {Position = UDim2.fromScale(0.5, 0.5)}, 0.55, Enum.EasingStyle.Quint)
        play(winScale, {Scale = 1}, 0.65, Enum.EasingStyle.Back)
        play(win, {GroupTransparency = 0}, 0.3)
        if shadow then play(shadow, {ImageTransparency = 0.55}, 0.45) end
        if neon then play(neon, {ImageTransparency = 0.72}, 0.6) end
        setLoops(true)
        if openFx then openFx() end
        setVid(true)
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
        if neon then play(neon, {ImageTransparency = 1}, 0.25) end
        updateBlur()
        task.delay(0.45, function()
            if not isOpen and tok == openTok then
                shell.Visible = false
                setVid(false)
                setLoops(false)
            end
        end)
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
    -- HEADER (banner, logo berhalo, judul, breadcrumb tab aktif, chip FPS, tombol window)
    ------------------------------------------------------------------
    local HDR = 64
    local TOPY = HDR + 2
    local tb = new("Frame", {Size = UDim2.new(1, 0, 0, HDR), BackgroundTransparency = 1, Active = true, ZIndex = 10}, win)
    local chipL, cdot, minB, xB, setCrumb
    do
        local banner = new("Frame", {Size = UDim2.new(1, 0, 0, HDR), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6}, win)
        new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.55, 0.93), NumberSequenceKeypoint.new(1, 1)}}, banner)
        local halo = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(36, HDR / 2), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = T.accent, BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 9}, tb)
        corner(halo, FULL)
        wloop(halo, 1.6, {BackgroundTransparency = 0.93, Size = UDim2.fromOffset(64, 64)})
        local logo = new("Frame", {Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0, 16, 0.5, -20), BackgroundColor3 = Color3.fromRGB(26, 24, 42), BorderSizePixel = 0, ZIndex = 10}, tb)
        corner(logo, 14)
        wspin(new("UIGradient", {Color = RING2}, stroke(logo, WHITE, 1.8, 0.1)), 5)
        new("ImageLabel", {Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1, Image = ICON, ZIndex = 11}, logo)
        local titleText = C.Title or "SORU HUB"
        local titleL = label(tb, {Text = titleText, Position = UDim2.fromOffset(68, 13), Size = UDim2.new(1, -340, 0, 20), Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = WHITE, ZIndex = 11})
        local tg = new("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, T.text), ColorSequenceKeypoint.new(0.35, T.text), ColorSequenceKeypoint.new(0.5, T.cyan), ColorSequenceKeypoint.new(0.65, T.text), ColorSequenceKeypoint.new(1, T.text)}, Offset = Vector2.new(-1, 0)}, titleL)
        winLoops[#winLoops + 1] = TweenService:Create(tg, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 2.4), {Offset = Vector2.new(1, 0)})
        winLoops[#winLoops]:Play()
        local subL = label(tb, {Text = "v"..VERSION, Position = UDim2.fromOffset(68, 36), Size = UDim2.new(1, -340, 0, 14), TextSize = 10, TextColor3 = DIM, ZIndex = 11})
        bindName(function(n) subL.Text = (n == "Unknown") and ("v"..VERSION) or ("v"..VERSION.."  "..n) end)
        local sepL = new("Frame", {Position = UDim2.fromOffset(10, HDR), Size = UDim2.new(1, -20, 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 10}, win)
        new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1)}}, sepL)

        -- breadcrumb: nama tab yang sedang aktif
        local cx = 68 + math.floor(textW(titleText, 17)) + 14
        local crumb = new("Frame", {Position = UDim2.fromOffset(cx, 14), Size = UDim2.fromOffset(86, 22), BackgroundColor3 = T.accent, BackgroundTransparency = 0.84, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 11}, tb)
        corner(crumb, FULL)
        stroke(crumb, T.accent, 1, 0.45)
        local cdt = new("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(9, 8), BackgroundColor3 = T.cyan, BorderSizePixel = 0, ZIndex = 12}, crumb)
        corner(cdt, FULL)
        wloop(cdt, 1.1, {BackgroundTransparency = 0.6})
        local crL = label(crumb, {Text = "Dashboard", Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -26, 1, 0), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.text, TextTruncate = Enum.TextTruncate.None, ZIndex = 12})
        setCrumb = function(name)
            crL.Text = name
            crL.Position = UDim2.fromOffset(22, 9)
            crL.TextTransparency = 1
            play(crL, {Position = UDim2.fromOffset(22, 0), TextTransparency = 0}, 0.4, Enum.EasingStyle.Back)
            play(crumb, {Size = UDim2.fromOffset(math.max(64, textW(name, 10) + 36), 22)}, 0.35, Enum.EasingStyle.Back)
        end

        -- chip FPS
        local chip = new("Frame", {Size = UDim2.fromOffset(134, 24), Position = UDim2.new(1, -232, 0.5, -12), BackgroundColor3 = Color3.fromRGB(28, 25, 44), BorderSizePixel = 0, ZIndex = 11}, tb)
        corner(chip, FULL) stroke(chip, T.accent, 1, 0.55)
        cdot = new("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(11, 9), BackgroundColor3 = T.ok, BorderSizePixel = 0, ZIndex = 12}, chip)
        corner(cdot, FULL)
        wloop(cdot, 1.2, {BackgroundTransparency = 0.7})
        chipL = label(chip, {Text = "-- fps", Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -28, 1, 0), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = DIM, ZIndex = 12})

        local function hbtn(xOff, txt, col, hoverC)
            local b = new("TextButton", {Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, xOff, 0.5, -16), Text = txt, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = col or DIM, BackgroundColor3 = Color3.fromRGB(28, 25, 44), AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 11}, tb)
            corner(b, FULL)
            stroke(b, T.stroke, 1, 0.55)
            hover(b, nil, hoverC or Color3.fromRGB(42, 38, 66), T.cardDown)
            return b
        end
        minB = hbtn(-82, "–")
        xB = hbtn(-44, "✕", T.bad, Color3.fromRGB(82, 36, 50))
    end
    ------------------------------------------------------------------
    -- TAB BAR HORIZONTAL (icon saja, geser kiri-kanan) + CONTENT
    ------------------------------------------------------------------
    local BAR_H = 50
    local CONT_Y = TOPY + BAR_H + 6
    local TAB_W, TAB_H2, TAB_GAP, PADX, TAB_Y = 44, 40, 4, 8, 5

    local bar = new("Frame", {Name = "TabBar", Position = UDim2.fromOffset(10, TOPY), Size = UDim2.new(1, -20, 0, BAR_H), BackgroundColor3 = T.panel, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 5}, win)
    corner(bar, 16) stroke(bar, T.stroke, 1, 0.55) regTrans(bar, 0.05)
    grad(bar, WHITE, Color3.fromRGB(190, 186, 214), 90)

    local tabList = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.None, ScrollingDirection = Enum.ScrollingDirection.X, ZIndex = 6}, bar)

       -- pill aktif: kapsul kaca yang melebar menutupi ikon + nama tab terpilih
    local pillSheenG
    local pill = new("Frame", {Name = "Pill", Position = UDim2.fromOffset(PADX, TAB_Y), Size = UDim2.fromOffset(TAB_W, TAB_H2), BackgroundColor3 = WHITE, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 5}, tabList)
    corner(pill, 14)
    grad(pill, T.accent, T.accent2, 0)
    wspin(new("UIGradient", {Color = RING2}, stroke(pill, WHITE, 1.4, 0.1)), 5)
    do
        local rim = new("Frame", {Position = UDim2.fromOffset(-4, -3), Size = UDim2.new(1, 8, 1, 8), BackgroundColor3 = T.accent, BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 4}, pill)
        corner(rim, 18)
        wloop(rim, 1.5, {BackgroundTransparency = 0.95})
        -- kilau yang menyapu saat pindah tab (UIGradient ikut terpotong sudut bulat)
        local sheen = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6}, pill)
        corner(sheen, 14)
        pillSheenG = new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.72), NumberSequenceKeypoint.new(1, 1)}, Offset = Vector2.new(-1, 0)}, sheen)
        -- garis cahaya di dasar kapsul
        local ind = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(0.34, 0, 0, 3), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 7}, pill)
        corner(ind, FULL)
        grad(ind, T.cyan, T.accent, 0)
    end
    
    -- panah + pudar di ujung kiri/kanan (muncul otomatis kalau tab lebih lebar dari bar, bisa diklik)
    local function mkFade(left)
        local btn = new("TextButton", {Name = left and "FadeL" or "FadeR", AnchorPoint = Vector2.new(left and 0 or 1, 0), Position = UDim2.new(left and 0 or 1, 0, 0, 0), Size = UDim2.new(0, 34, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Visible = false, ZIndex = 9}, bar)
        local bg = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.panel, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 9}, btn)
        corner(bg, 16)
        new("UIGradient", {Transparency = NumberSequence.new(0.05, 1), Rotation = left and 0 or 180}, bg)
        local ar = label(btn, {Text = left and "‹" or "›", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(left and 2 or -2, -1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = T.text, TextTransparency = 1, TextTruncate = Enum.TextTruncate.None, ZIndex = 10})
        return {btn = btn, bg = bg, ar = ar}
    end
    local fadeL, fadeR = mkFade(true), mkFade(false)
    local showL, showR = false, false

    local function viewW()
        return tabList.AbsoluteWindowSize.X / math.max(rootScale.Scale * winScale.Scale, 0.01)
    end
    local function setFade(f, on)
        if on then f.btn.Visible = true end
        play(f.bg, {BackgroundTransparency = on and 0 or 1}, 0.25)
        play(f.ar, {TextTransparency = on and 0.1 or 1}, 0.25)
        if not on then
            task.delay(0.28, function()
                if f.btn.Parent and f.bg.BackgroundTransparency >= 0.99 then f.btn.Visible = false end
            end)
        end
    end
    local function updFade()
        local view = viewW()
        if view < 1 then return end
        local cw, cx = tabList.CanvasSize.X.Offset, tabList.CanvasPosition.X
        local l, r = cx > 3, cx < cw - view - 3
        if l ~= showL then showL = l setFade(fadeL, l) end
        if r ~= showR then showR = r setFade(fadeR, r) end
    end
    tabList:GetPropertyChangedSignal("CanvasPosition"):Connect(updFade)
    tabList:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updFade)
    tabList:GetPropertyChangedSignal("CanvasSize"):Connect(updFade)

    local function scrollBy(dir)
        local view = viewW()
        local cw = tabList.CanvasSize.X.Offset
        local nx = math.clamp(tabList.CanvasPosition.X + dir * view * 0.6, 0, math.max(0, cw - view))
        play(tabList, {CanvasPosition = Vector2.new(nx, 0)}, 0.4, Enum.EasingStyle.Quint)
    end
    fadeL.btn.MouseButton1Click:Connect(function() sfx("tick") scrollBy(-1) end)
    fadeR.btn.MouseButton1Click:Connect(function() sfx("tick") scrollBy(1) end)

    -- tab aktif otomatis digeser ke tengah kalau belum kelihatan penuh
        local function revealTab(t)
        local view = viewW()
        if view < 1 then return end
        local cw, cx = tabList.CanvasSize.X.Offset, tabList.CanvasPosition.X
        if t.x - 8 >= cx and t.x + t.w + 8 <= cx + view then return end
        local nx = math.clamp(t.x + t.w / 2 - view / 2, 0, math.max(0, cw - view))
        play(tabList, {CanvasPosition = Vector2.new(nx, 0)}, 0.45, Enum.EasingStyle.Quint)
    end
    
    local content = new("Frame", {Position = UDim2.fromOffset(10, CONT_Y), Size = UDim2.new(1, -20, 1, -(CONT_Y + 10)), BackgroundColor3 = T.panel, BackgroundTransparency = 0.25, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 5}, win)
    corner(content, 18) stroke(content, T.stroke, 1, 0.65) regTrans(content, 0.1)

    local rh = new("Frame", {Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -28, 1, -28), BackgroundTransparency = 1, Active = true, ZIndex = 30}, win)
    do
        local rhL = label(rh, {Text = "⋰", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(-4, -2), TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Bottom, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(100, 94, 130)})
        rh.MouseEnter:Connect(function() play(rhL, {TextColor3 = ACCENT}, 0.15) end)
        rh.MouseLeave:Connect(function() play(rhL, {TextColor3 = Color3.fromRGB(100, 94, 130)}, 0.2) end)
    end

    -- tooltip nama tab (muncul di bawah icon)
    local showTip, hideTip
    do
        local tipF = new("Frame", {Name = "TabTip", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(80, 26), BackgroundColor3 = Color3.fromRGB(26, 23, 44), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 95}, root)
        corner(tipF, 10)
        local tipS = stroke(tipF, T.accent, 1, 1)
        local tipL = label(tipF, {Text = "", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 12, TextTransparency = 1, TextTruncate = Enum.TextTruncate.None, ZIndex = 96})
        local tipTok = 0
        showTip = function(b, text)
            tipTok = tipTok + 1
            local tok = tipTok
            local rs = math.max(rootScale.Scale, 0.01)
            local ap, asz = b.AbsolutePosition, b.AbsoluteSize
            local w = textW(text, 12) + 26
            local x = math.clamp((ap.X + asz.X / 2) / rs, w / 2 + 6, virt.X - w / 2 - 6)
            local y = (ap.Y + asz.Y) / rs + 8
            tipL.Text = text
            tipF.Size = UDim2.fromOffset(w, 26)
            if not tipF.Visible then tipF.Position = UDim2.fromOffset(x, y + 8) end
            tipF.Visible = true
            play(tipF, {Position = UDim2.fromOffset(x, y), BackgroundTransparency = 0.05}, 0.25, Enum.EasingStyle.Back)
            play(tipS, {Transparency = 0.35}, 0.15)
            play(tipL, {TextTransparency = 0}, 0.15)
            task.delay(2.2, function() if tok == tipTok then hideTip() end end)
        end
        hideTip = function()
            tipTok = tipTok + 1
            local tok = tipTok
            play(tipF, {BackgroundTransparency = 1}, 0.12)
            play(tipS, {Transparency = 1}, 0.12)
            play(tipL, {TextTransparency = 1}, 0.12)
            task.delay(0.14, function() if tok == tipTok then tipF.Visible = false end end)
        end
    end

    -- animasi masuk: header turun, tab bar + konten menyusul, icon tab muncul berurutan, glint menyapu window
    openFx = function()
        bar.Position = UDim2.fromOffset(10, TOPY - 14)
        content.Position = UDim2.fromOffset(10, CONT_Y + 34)
        tb.Position = UDim2.fromOffset(0, -16)
        play(tb, {Position = UDim2.fromOffset(0, 0)}, 0.6, Enum.EasingStyle.Back)
        play(bar, {Position = UDim2.fromOffset(10, TOPY)}, 0.75, Enum.EasingStyle.Back)
        task.delay(0.07, function() play(content, {Position = UDim2.fromOffset(10, CONT_Y)}, 0.75, Enum.EasingStyle.Back) end)
        for _, t in pairs(tabs) do
            t.bsc.Scale = 0
            task.delay(0.2 + math.min(t.index - 1, 12) * 0.05, function()
                if t.badge.Parent then play(t.bsc, {Scale = 1}, 0.5, Enum.EasingStyle.Back) end
            end)
        end
        local gl = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 110, 2.4, 0), Position = UDim2.new(-0.3, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 40}, win)
        new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.88), NumberSequenceKeypoint.new(1, 1)}}, gl)
        task.delay(0.25, function() play(gl, {Position = UDim2.new(1.3, 0, 0.5, 0)}, 0.9, Enum.EasingStyle.Quad) end)
        task.delay(1.3, function() gl:Destroy() end)
    end

    -- drag window: easing halus, miring mengikuti arah gerak, lalu memantul balik
    track(tb,
        function()
            winPos = curPos
            dragging = true
            drawPos = curPos
            if isOpen then play(winScale, {Scale = 1.015}, 0.18) end
            return curPos
        end,
        function(dx, dy, st, moved)
            if moved and st then
                local s = rootScale.Scale
                winPos = Vector2.new(st.X + dx / s, st.Y + dy / s)
                layoutWin(false)
            end
        end,
        function()
            dragging = false
            easing = true
            if isOpen then
                play(winScale, {Scale = 1}, 0.4, Enum.EasingStyle.Back)
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

            ------------------------------------------------------------------
    -- TAB SYSTEM v2: tab terpilih melebar (ikon + nama), tab lain tetap ikon
    ------------------------------------------------------------------
    local tabSeq = {}   -- urutan tampil: {tab = entry} atau {sep = frame}
    local lastGroup = nil

    local function tabWidth(t)
        return (t.name == cur) and t.fullW or TAB_W
    end

    -- susun ulang posisi semua tab (tab aktif lebar, sisanya ikon)
    local function relayout(animate)
        local x = PADX
        for _, it in ipairs(tabSeq) do
            if it.sep then
                x = x + 5
                local sp = UDim2.fromOffset(x, 14)
                if animate then play(it.sep, {Position = sp}, 0.5) else it.sep.Position = sp end
                x = x + 10
            else
                local t = it.tab
                local w = tabWidth(t)
                t.x, t.w = x, w
                local pos, size = UDim2.fromOffset(x, TAB_Y), UDim2.fromOffset(w, TAB_H2)
                if animate then
                    play(t.btn, {Position = pos, Size = size}, 0.5)
                else
                    t.btn.Position, t.btn.Size = pos, size
                end
                x = x + w + TAB_GAP
            end
        end
        tabList.CanvasSize = UDim2.fromOffset(x + PADX - TAB_GAP, 0)
        task.defer(updFade)
    end

    -- pill meregang menutupi tab lama + baru, lalu mengendap di tab baru
    local function movePill(t, animate)
        pillTok = pillTok + 1
        local tok = pillTok
        local x, w = t.x, t.w
        if not animate then
            pill.Position = UDim2.fromOffset(x, TAB_Y)
            pill.Size = UDim2.fromOffset(w, TAB_H2)
            return
        end
        local x0, w0 = pill.Position.X.Offset, pill.Size.X.Offset
        local l, r = math.min(x0, x), math.max(x0 + w0, x + w)
        play(pill, {Position = UDim2.fromOffset(l, TAB_Y), Size = UDim2.fromOffset(r - l, TAB_H2)}, 0.16, Enum.EasingStyle.Quad)
        pillSheenG.Offset = Vector2.new(-1, 0)
        play(pillSheenG, {Offset = Vector2.new(1, 0)}, 0.7, Enum.EasingStyle.Quad)
        task.delay(0.15, function()
            if tok ~= pillTok then return end
            play(pill, {Position = UDim2.fromOffset(x, TAB_Y), Size = UDim2.fromOffset(w, TAB_H2)}, 0.42, Enum.EasingStyle.Back)
        end)
    end

    -- tampilan satu tab: aktif = nama muncul + ikon terang, tidak aktif = ikon saja
    local function paintTab(t, on)
        play(t.badge, {BackgroundTransparency = on and 0.05 or 0.72}, 0.25)
        play(t.bst, {Transparency = on and 0.1 or 0.6}, 0.25)
        play(t.box, {Position = UDim2.fromOffset(on and 42 or 30, 0)}, on and 0.55 or 0.2, on and Enum.EasingStyle.Back or Enum.EasingStyle.Quint)
        play(t.nameL, {TextTransparency = on and 0 or 1}, on and 0.35 or 0.15)
        if t.capL then play(t.capL, {TextTransparency = on and 0 or 1}, on and 0.35 or 0.15) end
        if t.glyph:IsA("TextLabel") then
            play(t.glyph, {TextColor3 = on and T.text or DIM}, 0.25)
        else
            play(t.glyph, {ImageTransparency = on and 0 or 0.3}, 0.25)
        end
    end

    local function switchTab(n)
        if cur == n or not tabs[n] then return end
        local oldName = cur
        local old = tabs[oldName]
        local ne = tabs[n]
        local dir = (ne.index > (old and old.index or 0)) and 1 or -1
        cur = n
        sfx("tab")
        hideTip()
        if old then
            paintTab(old, false)
            play(old.frame, {GroupTransparency = 1, Position = UDim2.new(0.5, -24 * dir, 0.5, 0)}, 0.2)
            play(old.zoom, {Scale = 0.96}, 0.2)
            task.delay(0.21, function() if cur ~= oldName then old.frame.Visible = false end end)
        end
        -- halaman baru masuk dari samping (searah urutan tab)
        ne.frame.Visible = true
        ne.frame.GroupTransparency = 1
        ne.frame.Position = UDim2.new(0.5, 30 * dir, 0.5, 0)
        ne.zoom.Scale = 1.035
        play(ne.frame, {GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5)}, 0.5, Enum.EasingStyle.Quint)
        play(ne.zoom, {Scale = 1}, 0.55, Enum.EasingStyle.Quint)
        entrance(ne.scroll)
        paintTab(ne, true)
        setCrumb(n)
        play(ne.btn, {BackgroundTransparency = 1}, 0.1)
        -- ikon memantul + cincin
        ne.bsc.Scale = 0.65
        play(ne.bsc, {Scale = 1}, 0.6, Enum.EasingStyle.Back)
        ne.badge.Rotation = -28
        play(ne.badge, {Rotation = 0}, 0.7, Enum.EasingStyle.Elastic)
        local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TAB_W / 2, TAB_H2 / 2), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8}, ne.btn)
        corner(ring, 12)
        local rst = stroke(ring, T.cyan, 1.5, 0.2)
        play(ring, {Size = UDim2.fromOffset(46, 46)}, 0.5)
        play(rst, {Transparency = 1}, 0.5)
        task.delay(0.55, function() ring:Destroy() end)
        relayout(true)
        movePill(ne, true)
        revealTab(ne)
    end

    local function createTab(name, active, icon, group)
        tabOrder = tabOrder + 1
        local idx = tabOrder
        -- ganti grup = garis pemisah vertikal tipis
        if group and group ~= lastGroup then
            lastGroup = group
            if #tabSeq > 0 then
                local ln = new("Frame", {Size = UDim2.fromOffset(1, 22), Position = UDim2.fromOffset(0, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6}, tabList)
                new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1)}, Rotation = 90}, ln)
                tabSeq[#tabSeq + 1] = {sep = ln}
            end
        end
        local g = group or lastGroup
        local tipText = g and (tostring(g).."  ›  "..tostring(name)) or tostring(name)

        local b = new("TextButton", {Name = name, Size = UDim2.fromOffset(TAB_W, TAB_H2), Position = UDim2.fromOffset(PADX, TAB_Y), BackgroundColor3 = ACCENT, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 6}, tabList)
        corner(b, 14)
        local badge = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(TAB_W / 2, TAB_H2 / 2), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = WHITE, BackgroundTransparency = active and 0.05 or 0.72, BorderSizePixel = 0, ZIndex = 7}, b)
        corner(badge, 10)
        grad(badge, T.accent, T.accent2, 45)
        local bst = stroke(badge, T.accent, 1, active and 0.1 or 0.6)
        local bsc = new("UIScale", {Scale = 1}, badge)

        -- ikon: huruf / simbol, atau asset gambar (rbxassetid / angka id / url)
        local ic = icon and tostring(icon) or nil
        local asset = nil
        if ic then
            if ic:match("^rbxasset") then
                asset = ic
            elseif ic:match("^%d%d%d+$") then
                asset = "rbxassetid://"..ic
            elseif ic:match("^https?://") then
                asset = srcAsset(ic)
            end
        end
        local glyph
        if asset then
            glyph = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Image = asset, ImageTransparency = active and 0 or 0.3, ZIndex = 8}, badge)
        else
            glyph = label(badge, {Text = ic or string.upper(string.sub(name, 1, 1)), Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = active and T.text or DIM, ZIndex = 8, TextTruncate = Enum.TextTruncate.None})
        end

        -- nama tab (dan nama grup kecil di bawahnya): tersingkap saat tab melebar
        local nameW, capW = textW(name, 12), g and textW(tostring(g), 9) or 0
        local labW = math.ceil(math.max(nameW, capW)) + 6
        local fullW = 42 + labW + 14
        local clip = new("Frame", {Name = "Clip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 7}, b)
        local box = new("Frame", {Position = UDim2.fromOffset(active and 42 or 30, 0), Size = UDim2.fromOffset(labW, TAB_H2), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8}, clip)
        local nameL = label(box, {Text = tostring(name), Position = UDim2.fromOffset(0, g and 6 or 0), Size = UDim2.new(1, 0, 0, g and 16 or TAB_H2), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = WHITE, TextTransparency = active and 0 or 1, TextTruncate = Enum.TextTruncate.None, ZIndex = 9})
        local capL = nil
        if g then
            capL = label(box, {Text = tostring(g), Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 11), Font = Enum.Font.GothamMedium, TextSize = 9, TextColor3 = T.cyan, TextTransparency = active and 0 or 1, TextTruncate = Enum.TextTruncate.None, ZIndex = 9})
        end

        local page = new("CanvasGroup", {Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = active, GroupTransparency = active and 0 or 1, ZIndex = 6}, content)
        local zoom = new("UIScale", {Scale = 1}, page)
        local scroll = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT, ScrollBarImageTransparency = 0.3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 7}, page)
        new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
        new("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14)}, scroll)

        local t = {name = name, btn = b, frame = page, scroll = scroll, glyph = glyph, badge = badge, bst = bst, bsc = bsc, index = idx, x = PADX, w = TAB_W, fullW = fullW, zoom = zoom, box = box, nameL = nameL, capL = capL}
        tabs[name] = t
        tabSeq[#tabSeq + 1] = {tab = t}
        relayout(false)
        if active then movePill(t, false) end

        b.MouseEnter:Connect(function()
            if cur == name then return end
            showTip(b, tipText)
            play(b, {BackgroundTransparency = 0.9}, 0.15)
            play(bsc, {Scale = 1.14}, 0.25, Enum.EasingStyle.Back)
            badge.Rotation = -16
            play(badge, {Rotation = 0}, 0.6, Enum.EasingStyle.Elastic)
            if glyph:IsA("TextLabel") then play(glyph, {TextColor3 = T.text}, 0.15) end
        end)
        b.MouseLeave:Connect(function()
            hideTip()
            play(b, {BackgroundTransparency = 1}, 0.2)
            play(bsc, {Scale = 1}, 0.25)
            if cur ~= name and glyph:IsA("TextLabel") then play(glyph, {TextColor3 = DIM}, 0.2) end
        end)
        b.MouseButton1Down:Connect(function() play(bsc, {Scale = 0.88}, 0.08) end)
        b.MouseButton1Up:Connect(function() play(bsc, {Scale = 1}, 0.3, Enum.EasingStyle.Back) end)
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
        local TXL = nested and 46 or 52   -- awal teks (setelah ikon)
        local ICN = nested and 24 or 28   -- ukuran ikon

        -- holder: pembungkus tiap komponen. Di dalam accordion tiap item diberi titik timeline di sisi kiri.
        local function holder(h, auto, deco)
            local hf = new("Frame", {Name = "Holder", Size = UDim2.new(1, 0, 0, h or 0), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder()}, container)
            if auto then hf.AutomaticSize = Enum.AutomaticSize.Y end
            if nested and not deco then
                local ny = (h and h > 0) and math.min(h / 2, 24) or 22
                local node = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(-12, ny), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = T.cyan, BorderSizePixel = 0, ZIndex = 3}, hf)
                corner(node, FULL)
                stroke(node, T.accent, 2, 0.45)
            end
            return hf
        end
        local function enter(body) list[#list + 1] = body end
        K._holder, K._enter = holder, enter

        -- kartu dasar: gradien kedalaman, wash warna di kiri, stripe aksen, ikon tile (opsional).
        -- balikan: f, stroke, holder, fx (hover/active/press), tile
        local function card(h, clickable, kind, tileTop)
            local hf = holder(h)
            local R = nested and 12 or 16
            local f = new(clickable and "TextButton" or "Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.card, BackgroundTransparency = 0.12, BorderSizePixel = 0})
            if clickable then f.Text = "" f.AutoButtonColor = false end
            f.Parent = hf
            corner(f, R)
            local s = stroke(f, T.stroke, 1, 0.45)
            new("UIGradient", {Transparency = NumberSequence.new(0, 0.7), Rotation = 60}, s)
            grad(f, WHITE, Color3.fromRGB(176, 170, 206), 90)
            if nested then f.BackgroundTransparency = 0.38 end
            gloss(f)
            regTrans(f, nested and 0.25 or 0)
            enter(f)

            local wash = new("Frame", {Name = "Wash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.accent, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 0}, f)
            corner(wash, R)
            new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.66), NumberSequenceKeypoint.new(0.55, 0.92), NumberSequenceKeypoint.new(1, 1)}}, wash)
            local stripe = new("Frame", {Name = "Stripe", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0.4, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 2}, f)
            corner(stripe, FULL)
            grad(stripe, T.cyan, T.accent, 90)

            local tile = nil
            if kind then
                tile = makeIcon(f, kind, ICN)
                if tileTop then
                    tile.Position = UDim2.fromOffset(12, tileTop)
                else
                    tile.AnchorPoint = Vector2.new(0, 0.5)
                    tile.Position = UDim2.new(0, 12, 0.5, 0)
                end
            end

            local fx = {idleWash = 0.55}
            local hovering, activeOn, pressed = false, false, false
            local function paint()
                local on = hovering or activeOn
                local wt = fx.idleWash
                if activeOn and hovering then wt = 0 elseif activeOn then wt = 0.1 elseif hovering then wt = 0.3 end
                play(wash, {BackgroundTransparency = wt}, 0.3)
                play(stripe, {Size = UDim2.new(0, 3, on and 0.72 or 0.4, 0), BackgroundTransparency = on and 0 or 0.35}, 0.3, Enum.EasingStyle.Back)
                play(s, {Color = on and ACCENT or T.stroke, Transparency = on and 0.2 or 0.45}, 0.25)
                play(f, {BackgroundColor3 = pressed and T.cardDown or (hovering and T.cardHover or T.card)}, 0.18)
                if tile then play(tile, {BackgroundTransparency = on and 0.35 or 0.62}, 0.25) end
            end
            function fx.hover(v) hovering = v paint() end
            function fx.active(v) activeOn = v paint() end
            function fx.press(v) pressed = v paint() end
            function fx.paint() paint() end
            function fx.bindHover(btn)
                btn.MouseEnter:Connect(function()
                    sfx("hover")
                    fx.hover(true)
                    if tile then
                        tile.Rotation = -12
                        play(tile, {Rotation = 0}, 0.6, Enum.EasingStyle.Elastic)
                    end
                end)
                btn.MouseLeave:Connect(function() fx.hover(false) end)
            end

            if clickable then
                ripple(f)
                if not nested then spotlight(f) end
                local sc = new("UIScale", {Scale = 1}, f)
                local hov = false
                local HOVS = nested and 1 or 1.012
                local shine = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 46, 2, 0), Position = UDim2.new(-0.2, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 0}, f)
                new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(1, 1)}}, shine)
                fx.bindHover(f)
                f.MouseEnter:Connect(function()
                    hov = true
                    play(sc, {Scale = HOVS}, 0.3, Enum.EasingStyle.Back)
                    shine.Position = UDim2.new(-0.15, 0, 0.5, 0)
                    play(shine, {Position = UDim2.new(1.15, 0, 0.5, 0)}, 0.6, Enum.EasingStyle.Quad)
                end)
                f.MouseLeave:Connect(function()
                    hov = false
                    fx.press(false)
                    play(sc, {Scale = 1}, 0.25)
                end)
                f.MouseButton1Down:Connect(function() fx.press(true) play(sc, {Scale = 0.98}, 0.08) end)
                f.MouseButton1Up:Connect(function() fx.press(false) play(sc, {Scale = hov and HOVS or 1}, 0.35, Enum.EasingStyle.Back) end)
            end
            return f, s, hf, fx, tile
        end
        K._card = card

        -- input kecil: kotak gelap dengan underline fokus
        local function inputBox(parent, props)
            local wrap = new("Frame", {BackgroundColor3 = T.input, BorderSizePixel = 0, ClipsDescendants = true}, parent)
            for k, v in pairs(props.wrap or {}) do wrap[k] = v end
            corner(wrap, 10)
            local ws = stroke(wrap, T.stroke, 1, 0.35)
            local box = new("TextBox", {Size = UDim2.new(1, -18, 1, 0), Position = UDim2.fromOffset(9, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = props.text or "", PlaceholderText = props.placeholder or "", PlaceholderColor3 = Color3.fromRGB(100, 94, 130), TextColor3 = T.text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = props.clear or false, ClipsDescendants = true}, wrap)
            local ul = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0}, wrap)
            grad(ul, T.accent, T.cyan, 0)
            box.Focused:Connect(function()
                sfx("tick", 1.4)
                play(ws, {Color = ACCENT, Transparency = 0.1, Thickness = 1.5}, 0.2)
                play(ul, {Size = UDim2.new(1, 0, 0, 2)}, 0.35)
                play(wrap, {BackgroundColor3 = Color3.fromRGB(24, 20, 42)}, 0.2)
            end)
            box.FocusLost:Connect(function()
                play(ws, {Color = T.stroke, Transparency = 0.35, Thickness = 1}, 0.25)
                play(ul, {Size = UDim2.new(0, 0, 0, 2)}, 0.25)
                play(wrap, {BackgroundColor3 = T.input}, 0.25)
            end)
            return wrap, box
        end

        -- judul + deskripsi (opsional) di sisi kiri kartu (x = awal teks, setelah ikon)
        local function rowLabels(f, o, title, wScale, wOff, h, z)
            local hasDesc = o.Desc ~= nil
            local w = wOff - (TXL - 14)
            local t = label(f, {Text = tostring(title), Position = UDim2.fromOffset(TXL, hasDesc and 10 or 0), Size = UDim2.new(wScale, w, 0, hasDesc and 18 or h), Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = z or 1})
            local d = nil
            if hasDesc then
                d = label(f, {Text = tostring(o.Desc), Position = UDim2.fromOffset(TXL, 29), Size = UDim2.new(wScale, w, 0, 16), TextSize = 11, TextColor3 = DIM, ZIndex = z or 1})
            end
            return t, d
        end

        ----------------------------------------------------------------
        -- SECTION: kapsul judul + garis
        ----------------------------------------------------------------
        function K:Section(text)
            if type(text) == "table" then text = text.Title or text.Text end
            text = string.upper(tostring(text or ""))
            local hf = holder(28, false, true)
            hf:SetAttribute("Deco", true)
            local f = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
            enter(f)
            local w = textW(text, 11)
            local cap = new("Frame", {Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(w + 38, 22), BackgroundColor3 = T.accent, BackgroundTransparency = 0.84, BorderSizePixel = 0}, f)
            corner(cap, FULL)
            stroke(cap, T.accent, 1, 0.4)
            local dot = new("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(11, 8), BackgroundColor3 = WHITE, BorderSizePixel = 0, Rotation = 45}, cap)
            grad(dot, T.accent, T.cyan, 45)
            wloop(dot, 1.3, {BackgroundTransparency = 0.55})
            local sl = label(cap, {Text = text, Position = UDim2.fromOffset(25, 0), Size = UDim2.new(1, -29, 1, 0), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.None})
            new("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(240, 234, 255), T.cyan)}, sl)
            local lx = w + 38 + 14
            local line = new("Frame", {Position = UDim2.new(0, lx, 0, 14), Size = UDim2.new(1, -(lx + 6), 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new(0.3, 1)}, line)
            return f
        end

        function K:Divider()
            local hf = holder(12, false, true)
            hf:SetAttribute("Deco", true)
            local f = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
            enter(f)
            local line = new("Frame", {Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.new(1, -12, 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1)}}, line)
            local d = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = T.cyan, BorderSizePixel = 0, Rotation = 45}, f)
        end

        function K:Label(text)
            if type(text) == "table" then text = text.Text or text.Title end
            local hf = holder(0, true)
            local f = new("Frame", {Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.card, BackgroundTransparency = 0.35, BorderSizePixel = 0}, hf)
            corner(f, nested and 10 or 14) regTrans(f, 0.2) enter(f)
            new("UIPadding", {PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 12)}, f)
            local bar = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -18, 0.5, 0), Size = UDim2.new(0, 3, 0.6, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.4, BorderSizePixel = 0}, f)
            corner(bar, FULL)
            grad(bar, T.cyan, T.accent, 90)
            local t = label(f, {Text = tostring(text or ""), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 12, TextColor3 = DIM, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None})
            return {Set = function(_, s) t.Text = tostring(s) end}
        end

        function K:Paragraph(o)
            o = o or {}
            local hf = holder(0, true)
            local R = nested and 12 or 16
            local f = new("Frame", {Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.card, BackgroundTransparency = 0.12, BorderSizePixel = 0}, hf)
            corner(f, R) stroke(f, T.stroke, 1, 0.45) regTrans(f, 0) enter(f)
            grad(f, WHITE, Color3.fromRGB(176, 170, 206), 90)
            local PL = ICN + 24
            new("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, PL), PaddingRight = UDim.new(0, 14)}, f)
            local tile = makeIcon(f, "info", ICN)
            tile.Position = UDim2.fromOffset(12 - PL, 0)
            local bar = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -PL, 0.5, 0), Size = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.3, BorderSizePixel = 0}, f)
            corner(bar, FULL)
            grad(bar, T.cyan, T.accent, 90)
            local col = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0}, f)
            new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, col)
            local t = label(col, {Text = tostring(o.Title or ""), Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 13, LayoutOrder = 1})
            local d = label(col, {Text = tostring(o.Desc or ""), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 11, TextColor3 = DIM, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2})
            return {Set = function(_, title, desc) if title then t.Text = tostring(title) end if desc then d.Text = tostring(desc) end end}
        end

        ----------------------------------------------------------------
        -- BUTTON: kartu aksi berwarna + badge gradien bercahaya
        ----------------------------------------------------------------
        function K:Button(o)
            o = o or {}
            local hasDesc = o.Desc ~= nil
            local h = hasDesc and 60 or 48
            local bt, st, _, fx = card(h, true, "play")
            fx.idleWash = 0.3
            fx.paint()
            rowLabels(bt, o, o.Title or "Button", 1, -66, h)
            local glow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -27, 0.5, 0), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = T.accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1}, bt)
            corner(glow, FULL)
            local badge = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -27, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = WHITE, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 2}, bt)
            corner(badge, FULL)
            grad(badge, T.accent, T.accent2, 45)
            stroke(badge, T.cyan, 1.2, 0.6)
            local arrow = label(badge, {Text = "›", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(1, -1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = WHITE, ZIndex = 3, TextTruncate = Enum.TextTruncate.None})
            bt.MouseEnter:Connect(function()
                play(badge, {Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 0}, 0.3, Enum.EasingStyle.Back)
                play(glow, {BackgroundTransparency = 0.8, Size = UDim2.fromOffset(48, 48)}, 0.35)
                play(arrow, {Position = UDim2.fromOffset(3, -1)}, 0.25)
            end)
            bt.MouseLeave:Connect(function()
                play(badge, {Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 0.2}, 0.25)
                play(glow, {BackgroundTransparency = 1, Size = UDim2.fromOffset(36, 36)}, 0.25)
                play(arrow, {Position = UDim2.fromOffset(1, -1)}, 0.2)
            end)
            bt.MouseButton1Click:Connect(function()
                sfx("click")
                local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -27, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, bt)
                corner(ring, FULL)
                local rst = stroke(ring, T.cyan, 2, 0.1)
                play(ring, {Size = UDim2.fromOffset(84, 84)}, 0.5)
                play(rst, {Transparency = 1}, 0.5)
                task.delay(0.55, function() ring:Destroy() end)
                safe(o.Callback)
            end)
            return bt
        end

        ----------------------------------------------------------------
        -- TOGGLE: saklar besar ON/OFF, seluruh kartu menyala saat ON
        ----------------------------------------------------------------
        function K:Toggle(o)
            o = o or {}
            local flag = o.Flag or o.Title or ("Toggle"..nextOrder())
            local curV = Data.Features[flag]
            if type(curV) ~= "boolean" then curV = (o.Default == true) end
            local hasDesc = o.Desc ~= nil
            local h = hasDesc and 60 or 48
            local fr, st, _, fx = card(h, true, "toggle")
            rowLabels(fr, o, o.Title or flag, 1, -92, h)
            -- glow lembut di belakang track saat ON
            local tglow = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(78, 44), BackgroundColor3 = T.accent, BackgroundTransparency = curV and 0.84 or 1, BorderSizePixel = 0, ZIndex = 0}, fr)
            corner(tglow, FULL)
            local tgb = new("Frame", {Size = UDim2.fromOffset(54, 28), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0), BackgroundColor3 = T.off, BorderSizePixel = 0}, fr)
            corner(tgb, FULL)
            local tst = stroke(tgb, ACCENT, 2, curV and 0.4 or 1)
            local onF = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = curV and 0 or 1, BorderSizePixel = 0}, tgb)
            corner(onF, FULL)
            grad(onF, T.accent, T.cyan, 0)
            local onT = label(tgb, {Text = "ON", Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0, 20, 1, 0), Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = WHITE, TextTransparency = curV and 0 or 1, TextTruncate = Enum.TextTruncate.None, ZIndex = 2})
            local offT = label(tgb, {Text = "OFF", Position = UDim2.new(1, -30, 0, 0), Size = UDim2.new(0, 22, 1, 0), Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = DIM, TextTransparency = curV and 1 or 0, TextTruncate = Enum.TextTruncate.None, ZIndex = 2})
            local dot = new("Frame", {Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(0, 0.5), Position = curV and UDim2.new(1, -25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, tgb)
            corner(dot, FULL)
            local dst = stroke(dot, ACCENT, 3, curV and 0.55 or 1)
            local tck = label(dot, {Text = "✓", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.accent2, TextTransparency = curV and 0 or 1, TextTruncate = Enum.TextTruncate.None, ZIndex = 4})
            if curV then fx.active(true) end
            -- silent = hanya visual (tanpa suara, tanpa simpan, tanpa callback)
            local function upd(v, silent)
                if not silent then
                    sfx(v and "on" or "off")
                    local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = v and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3}, tgb)
                    corner(ring, FULL)
                    local rst = stroke(ring, v and T.cyan or T.dim, 2, 0.2)
                    play(ring, {Size = UDim2.fromOffset(58, 58)}, 0.5)
                    play(rst, {Transparency = 1}, 0.5)
                    task.delay(0.55, function() ring:Destroy() end)
                end
                fx.active(v)
                play(onF, {BackgroundTransparency = v and 0 or 1}, 0.25)
                play(tglow, {BackgroundTransparency = v and 0.84 or 1}, 0.35)
                play(onT, {TextTransparency = v and 0 or 1}, 0.25)
                play(offT, {TextTransparency = v and 1 or 0}, 0.25)
                play(tck, {TextTransparency = v and 0 or 1}, 0.25)
                play(tst, {Transparency = v and 0.4 or 1}, 0.25)
                play(dst, {Transparency = v and 0.55 or 1}, 0.25)
                play(dot, {Position = v and UDim2.new(1, -25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, 0.4, Enum.EasingStyle.Back)
                play(dot, {Size = UDim2.fromOffset(26, 22)}, 0.1)
                task.delay(0.1, function() play(dot, {Size = UDim2.fromOffset(22, 22)}, 0.3, Enum.EasingStyle.Back) end)
                Data.Features[flag] = v
                if not silent then
                    persist()
                    safe(o.Callback, v)
                end
            end
            Reg[flag] = {Set = function(v, ns) curV = v and true or false upd(curV, ns) end, Get = function() return curV end}
            fr.MouseButton1Click:Connect(function() curV = not curV upd(curV) end)
            Data.Features[flag] = curV
            if o.Callback then task.spawn(safe, o.Callback, curV) end
            return {
                Set = function(_, v, fire) curV = v and true or false upd(curV, not fire) end,
                Get = function() return curV end,
            }
        end

        ----------------------------------------------------------------
        -- SLIDER: track tabung berkilau, tick step, label min/max, knob berhalo
        ----------------------------------------------------------------
        function K:Slider(o)
            o = o or {}
            local flag = o.Flag
            local mn, mx, step = o.Min or 0, o.Max or 100, o.Step or 1
            if mx < mn then mn, mx = mx, mn end
            if step <= 0 then step = 1 end
            local val = o.Default or mn
            if flag and type(Data.Features[flag]) == "number" then val = Data.Features[flag] end
            local f, st, _, fx = card(70, false, "slider", 10)
            label(f, {Text = tostring(o.Title or flag or "Slider"), Position = UDim2.fromOffset(TXL, 10), Size = UDim2.new(1, -(TXL + 76), 0, 28), Font = Enum.Font.GothamBold, TextSize = 13})
            local function fmt(v)
                local s = (v == math.floor(v)) and tostring(math.floor(v)) or tostring(v)
                return s..(o.Suffix or "")
            end
            local chipV = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(54, 24), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.82, BorderSizePixel = 0}, f)
            corner(chipV, FULL)
            local chipS = stroke(chipV, ACCENT, 1, 0.5)
            local vl = label(chipV, {Text = "", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.None})
            local hit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 40), Size = UDim2.new(1, -20, 0, 22)}, f)
            fx.bindHover(hit)
            local bar = new("Frame", {Position = UDim2.new(0, 6, 0.5, -4), Size = UDim2.new(1, -12, 0, 8), BackgroundColor3 = Color3.fromRGB(34, 31, 56), BorderSizePixel = 0}, hit)
            corner(bar, FULL)
            stroke(bar, T.stroke, 1, 0.55)
            local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1, ClipsDescendants = true}, bar)
            corner(fill, FULL)
            grad(fill, T.accent2, T.cyan, 0)
            do -- kilau tabung di atas fill
                local gl = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, fill)
                corner(gl, FULL)
                new("UIGradient", {Transparency = NumberSequence.new(0.45, 1), Rotation = 90}, gl)
            end
            local shim = new("Frame", {Size = UDim2.new(0, 34, 1, 0), Position = UDim2.new(-0.6, 0, 0, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, fill)
            new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1)}}, shim)
            local nSteps = math.floor((mx - mn) / step + 0.5)
            if nSteps >= 1 and nSteps <= 20 then
                for i = 0, nSteps do
                    local tk = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(i / nSteps, 0, 0.5, 0), Size = UDim2.fromOffset(2, 2), BackgroundColor3 = WHITE, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 3}, bar)
                    corner(tk, FULL)
                end
            end
            label(f, {Text = fmt(mn), Position = UDim2.fromOffset(18, 57), Size = UDim2.fromOffset(70, 12), TextSize = 9, TextColor3 = Color3.fromRGB(112, 106, 152)})
            label(f, {Text = fmt(mx), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 57), Size = UDim2.fromOffset(70, 12), TextSize = 9, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(112, 106, 152)})
            local halo = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T.accent, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 4}, bar)
            corner(halo, FULL)
            local knob = new("Frame", {Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5}, bar)
            corner(knob, FULL)
            local kst = stroke(knob, ACCENT, 3, 0.45)
            local tip = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -12), Size = UDim2.fromOffset(44, 20), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7}, knob)
            corner(tip, 7) grad(tip, T.accent, T.cyan, 0)
            local tipL = label(tip, {Text = "", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextTransparency = 1, TextTruncate = Enum.TextTruncate.None, ZIndex = 8})

            -- posisi visual mengejar target dengan easing eksponensial (Heartbeat hanya aktif saat masih bergerak)
            local shown, goal, sconn = 0, 0, nil
            local function paintFrac(a)
                fill.Size = UDim2.fromScale(a, 1)
                knob.Position = UDim2.fromScale(a, 0.5)
                halo.Position = UDim2.fromScale(a, 0.5)
            end
            local function setGoal(a, instant)
                goal = a
                if instant then
                    shown = a
                    paintFrac(a)
                    return
                end
                if sconn then return end
                sconn = RunService.Heartbeat:Connect(function(dt)
                    shown = shown + (goal - shown) * (1 - math.exp(-dt * 24))
                    if math.abs(goal - shown) < 0.0005 then
                        shown = goal
                        paintFrac(shown)
                        sconn:Disconnect()
                        sconn = nil
                        return
                    end
                    paintFrac(shown)
                end)
            end
            local function quant(v)
                v = mn + math.floor((v - mn) / step + 0.5) * step
                v = math.clamp(v, mn, mx)
                return math.floor(v * 1000 + 0.5) / 1000
            end
            local function render(v, instant)
                setGoal((mx == mn) and 0 or (v - mn) / (mx - mn), instant)
                local txt = fmt(v)
                vl.Text = txt
                tipL.Text = txt
                tip.Size = UDim2.fromOffset(math.max(40, textW(txt, 11) + 16), 20)
                chipV.Size = UDim2.fromOffset(math.max(54, textW(txt, 12) + 24), 24)
            end
            val = quant(val)
            local function set(v, silent, instant)
                v = quant(v)
                local changed = (v ~= val)
                if changed and not silent then sfx("tick", 0.75 + ((mx == mn) and 0 or (v - mn) / (mx - mn)) * 0.9) end
                val = v
                if changed or instant then render(v, instant) end
                if changed and not silent then safe(o.Callback, v) end
            end
            local function fromX(px)
                local aw = bar.AbsoluteSize.X
                if aw <= 0 then return end
                set(mn + (mx - mn) * math.clamp((px - bar.AbsolutePosition.X) / aw, 0, 1), false, false)
            end
            local function grab(on)
                play(knob, {Size = on and UDim2.fromOffset(20, 20) or UDim2.fromOffset(16, 16)}, 0.15, Enum.EasingStyle.Back)
                play(halo, {Size = on and UDim2.fromOffset(42, 42) or UDim2.fromOffset(26, 26), BackgroundTransparency = on and 0.72 or 0.9}, 0.25)
                play(kst, {Thickness = on and 5 or 3, Transparency = on and 0.25 or 0.45}, 0.2)
                play(tip, {BackgroundTransparency = on and 0 or 1}, 0.15)
                play(tipL, {TextTransparency = on and 0 or 1}, 0.15)
                play(chipV, {BackgroundTransparency = on and 0.1 or 0.82}, 0.2)
                play(chipS, {Transparency = on and 0 or 0.5}, 0.2)
                fx.active(on)
                if on then
                    shim.Position = UDim2.new(-0.6, 0, 0, 0)
                    play(shim, {Position = UDim2.new(1.2, 0, 0, 0)}, 0.9, Enum.EasingStyle.Quad)
                end
            end
            track(hit,
                function(pos)
                    scroll.ScrollingEnabled = false
                    grab(true)
                    fromX(pos.X)
                    return true
                end,
                function(dx, dy, stt, moved, pos) fromX(pos.X) end,
                function()
                    scroll.ScrollingEnabled = true
                    grab(false)
                    sfx("pop")
                    if flag then Data.Features[flag] = val persist() end
                    safe(o.OnRelease, val)
                end)

            set(val, true, true)
            if flag then Data.Features[flag] = val end
            if o.Callback then task.spawn(safe, o.Callback, val) end
            return {
                Set = function(_, v, fire)
                    set(v, not fire, false)
                    if flag then Data.Features[flag] = val end
                end,
                Get = function() return val end,
            }
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
            local h = hasDesc and 60 or 48
            local f, st, _, fx = card(h, false, "text")
            f.ClipsDescendants = true
            spotlight(f)
            rowLabels(f, o, o.Title or flag or "Textbox", 0.5, -20, h)
            local _, box = inputBox(f, {text = val, placeholder = o.Placeholder or "Type here...", clear = o.ClearOnFocus,
                wrap = {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0.42, 0, 0, 32)}})
            box.Focused:Connect(function() fx.active(true) end)
            box.FocusLost:Connect(function() fx.active(false) end)
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
            local lastLive = nil
            if o.Live and o.Callback then
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    local v = out(box.Text)
                    if v == nil or box.Text == lastLive then return end
                    lastLive = box.Text
                    safe(o.Callback, v)
                end)
            end
            local before = val
            box.Focused:Connect(function() before = box.Text end)
            box.FocusLost:Connect(function(enterPressed)
                local nv = norm(box.Text)
                box.Text = nv
                val = nv
                if enterPressed then sfx("pop") end
                if flag then Data.Features[flag] = nv persist() end
                if o.Callback and (enterPressed or nv ~= before) and not o.Live then
                    local v = out(nv)
                    if v ~= nil then safe(o.Callback, v) end
                end
            end)
            if flag then Data.Features[flag] = val end
            if o.Callback and val ~= "" then
                local v = out(val)
                if v ~= nil then task.spawn(safe, o.Callback, v) end
            end
            return {
                Set = function(_, v) val = tostring(v) box.Text = val if flag then Data.Features[flag] = val end end,
                Get = function() return out(box.Text) end,
            }
        end
        K.TextBox = K.Textbox
        K.Input = K.Textbox

        ----------------------------------------------------------------
        -- DROPDOWN: pill nilai + chevron bulat, opsi di panel cekung (search otomatis kalau opsi > 6)
        ----------------------------------------------------------------
        function K:Dropdown(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local multi = o.Multi and true or false
            local opts = o.Options or {}
            local hasDesc = o.Desc ~= nil
            local H0 = hasDesc and 60 or 48
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

            local f, st, hf, fx = card(H0, false, "list")
            f.ClipsDescendants = true
            local head = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, H0)}, f)
            ripple(head)
            spotlight(f, head)
            fx.bindHover(head)
            local tLbl, dLbl = rowLabels(head, o, o.Title or flag or "Dropdown", 1, -190, H0, 2)
            local pillV = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -46, 0.5, 0), Size = UDim2.fromOffset(70, 24), BackgroundColor3 = T.input, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 2}, head)
            corner(pillV, FULL)
            stroke(pillV, T.cyan, 1, 0.6)
            local valL = label(pillV, {Text = "", Size = UDim2.new(1, -14, 1, 0), Position = UDim2.fromOffset(7, 0), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.cyan, ZIndex = 3})
            local chevC = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 2}, head)
            corner(chevC, FULL)
            local arrow = label(chevC, {Text = "›", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, -1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = WHITE, Rotation = 90, ZIndex = 3, TextTruncate = Enum.TextTruncate.None})

            -- panel cekung berisi pencarian + daftar opsi
            local pop = new("Frame", {Position = UDim2.fromOffset(8, H0 + 2), Size = UDim2.new(1, -16, 0, 40), BackgroundColor3 = T.input, BackgroundTransparency = 0.3, BorderSizePixel = 0, ClipsDescendants = true}, f)
            corner(pop, 12) stroke(pop, T.stroke, 1, 0.6)
            local sbW, sb = inputBox(pop, {placeholder = "Search...", wrap = {Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 26), Visible = false}})
            local listF = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = ACCENT, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, pop)
            new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, listF)

            local function paint(anim)
                for _, r in ipairs(rows) do
                    local on = isSel(r.name)
                    local bt = on and 0.8 or 1
                    if anim then
                        play(r.btn, {BackgroundTransparency = bt}, 0.2)
                        play(r.txt, {TextColor3 = on and T.text or DIM}, 0.2)
                        play(r.ck, {TextTransparency = on and 0 or 1}, 0.2)
                        play(r.bar, {BackgroundTransparency = on and 0 or 1}, 0.2)
                    else
                        r.btn.BackgroundTransparency = bt
                        r.txt.TextColor3 = on and T.text or DIM
                        r.ck.TextTransparency = on and 0 or 1
                        r.bar.BackgroundTransparency = on and 0 or 1
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
                local pw = math.clamp(textW(txt, 11) + 24, 56, 132)
                pillV.Size = UDim2.fromOffset(pw, 24)
                local lw = -(TXL + 46 + pw + 10)
                tLbl.Size = UDim2.new(1, lw, 0, hasDesc and 18 or H0)
                if dLbl then dLbl.Size = UDim2.new(1, lw, 0, 16) end
            end
            local function commit()
                local v = getVal()
                if flag then Data.Features[flag] = v persist() end
                safe(o.Callback, v)
            end
            local function layout()
                local show = #opts > 6
                sbW.Visible = show
                local sbH = show and 32 or 0
                local lh = math.max(0, math.min(#opts, 5) * 30 - 2)
                local popH = 12 + sbH + lh
                pop.Size = UDim2.new(1, -16, 0, popH)
                listF.Position = UDim2.fromOffset(6, 6 + sbH)
                listF.Size = UDim2.new(1, -12, 0, lh)
                expanded = H0 + 2 + popH + 8
                if open then play(hf, {Size = UDim2.new(1, 0, 0, expanded)}, 0.3) end
            end
            local function applyFilter()
                local q = sb.Text:lower()
                for _, r in ipairs(rows) do r.btn.Visible = (q == "") or (r.name:lower():find(q, 1, true) ~= nil) end
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
                    corner(b, 9)
                    local bar = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(3, 14), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0}, b)
                    corner(bar, FULL)
                    grad(bar, T.cyan, T.accent, 90)
                    local t = label(b, {Text = name, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -40, 1, 0), TextSize = 12, TextColor3 = DIM})
                    local ck = label(b, {Text = "✓", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(16, 16), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.cyan, TextTransparency = 1})
                    rows[i] = {btn = b, txt = t, ck = ck, bar = bar, name = name}
                    b.MouseEnter:Connect(function() if not isSel(name) then play(b, {BackgroundTransparency = 0.9}, 0.12) end end)
                    b.MouseLeave:Connect(function() if not isSel(name) then play(b, {BackgroundTransparency = 1}, 0.15) end end)
                    b.MouseButton1Click:Connect(function() pick(name) end)
                end
                layout()
                paint(false)
                applyFilter()
            end
            sb:GetPropertyChangedSignal("Text"):Connect(applyFilter)
            setOpen = function(v)
                open = v
                sfx(v and "expand" or "collapse")
                fx.active(v)
                play(arrow, {Rotation = v and -90 or 90}, 0.3, Enum.EasingStyle.Back)
                play(chevC, {BackgroundTransparency = v and 0.25 or 0.85}, 0.25)
                play(hf, {Size = UDim2.new(1, 0, 0, v and expanded or H0)}, 0.38, Enum.EasingStyle.Quint)
                if v then
                    for i, r in ipairs(rows) do
                        if i <= 8 then
                            r.txt.TextTransparency = 1
                            task.delay(0.05 + i * 0.03, function() if open and r.txt.Parent then play(r.txt, {TextTransparency = 0}, 0.25) end end)
                        end
                    end
                end
            end
            head.MouseButton1Click:Connect(function() setOpen(not open) end)

            build()
            if flag then Data.Features[flag] = getVal() end
            if o.Callback and (multi or single ~= nil) then task.spawn(safe, o.Callback, getVal()) end
            local api = {}
            function api:Set(v, fire)
                setFrom(v) paint(true)
                if flag then Data.Features[flag] = getVal() end
                if fire then safe(o.Callback, getVal()) end
            end
            function api:Get() return getVal() end
            function api:Refresh(newOpts) opts = newOpts or {} build() end
            return api
        end

        ----------------------------------------------------------------
        -- KEYBIND: keycap 3D
        ----------------------------------------------------------------
        function K:Keybind(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local key = o.Default
            if type(key) == "string" then key = toKey(key) end
            local sv = flag and Data.Features[flag]
            if type(sv) == "string" then key = (sv ~= "None") and toKey(sv) or nil end
            local hasDesc = o.Desc ~= nil
            local h = hasDesc and 60 or 48
            local fr, st, _, fx = card(h, true, "key")
            rowLabels(fr, o, o.Title or flag or "Keybind", 1, -124, h)
            local capSh = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 2), Size = UDim2.fromOffset(64, 26), BackgroundColor3 = Color3.fromRGB(10, 8, 20), BackgroundTransparency = 0.15, BorderSizePixel = 0}, fr)
            corner(capSh, 9)
            local cap = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, -1), Size = UDim2.fromOffset(64, 26), BackgroundColor3 = Color3.fromRGB(60, 54, 96), BorderSizePixel = 0, ZIndex = 2}, fr)
            corner(cap, 9)
            grad(cap, WHITE, Color3.fromRGB(150, 144, 190), 90)
            local ps = stroke(cap, ACCENT, 1, 0.55)
            local kl = label(cap, {Text = "", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 11, TextTruncate = Enum.TextTruncate.None, ZIndex = 3})
            local listening = false
            local lastCancel = 0
            local function show()
                local txt = listening and "..." or (key and key.Name or "None")
                kl.Text = txt
                local sz = UDim2.fromOffset(math.max(56, textW(txt, 11) + 24), 26)
                play(cap, {Size = sz}, 0.3, Enum.EasingStyle.Back)
                play(capSh, {Size = sz}, 0.3, Enum.EasingStyle.Back)
                play(ps, {Color = listening and T.cyan or ACCENT, Transparency = listening and 0.05 or 0.55}, 0.2)
                play(kl, {TextColor3 = listening and T.cyan or T.text}, 0.2)
                fx.active(listening)
            end
            show()
            fr.MouseButton1Click:Connect(function()
                if listening or os.clock() - lastCancel < 0.35 then return end
                listening = true
                binding = true
                sfx("click")
                show()
                -- berdenyut selama menunggu tombol
                task.spawn(function()
                    local hi = false
                    while listening and cap.Parent do
                        hi = not hi
                        play(ps, {Transparency = hi and 0.55 or 0.05}, 0.5, Enum.EasingStyle.Sine)
                        play(cap, {BackgroundColor3 = hi and Color3.fromRGB(60, 54, 96) or Color3.fromRGB(44, 74, 112)}, 0.5, Enum.EasingStyle.Sine)
                        task.wait(0.5)
                    end
                    play(cap, {BackgroundColor3 = Color3.fromRGB(60, 54, 96)}, 0.2)
                end)
            end)
            bind(UIS.InputBegan, function(i, gp)
                if listening then
                    local ut = i.UserInputType
                    if ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.Touch then
                        -- klik di mana saja = batal (tombol tetap seperti semula)
                        listening = false
                        lastCancel = os.clock()
                        show()
                        task.delay(0.1, function() binding = false end)
                        return
                    end
                    if ut ~= Enum.UserInputType.Keyboard then return end
                    listening = false
                    local changed = true
                    if i.KeyCode == Enum.KeyCode.Escape then changed = false
                    elseif i.KeyCode == Enum.KeyCode.Backspace then key = nil
                    else key = i.KeyCode end
                    show()
                    if changed then
                        if flag then Data.Features[flag] = key and key.Name or "None" persist() end
                        sfx("pop")
                        safe(o.OnChange, key)
                    end
                    task.delay(0.1, function() binding = false end)
                    return
                end
                if not gp and key and i.KeyCode == key and o.Callback then safe(o.Callback, key) end
            end)
            if flag then Data.Features[flag] = key and key.Name or "None" end
            return {
                Set = function(_, k)
                    if type(k) == "string" then k = toKey(k) end
                    key = k
                    show()
                    if flag then Data.Features[flag] = key and key.Name or "None" end
                end,
                Get = function() return key end,
            }
        end
        K.Bind = K.Keybind

        ----------------------------------------------------------------
        -- COLOR PICKER: swatch bercahaya, panel cekung (SV box + hue + input hex)
        ----------------------------------------------------------------
        function K:ColorPicker(o)
            o = o or {}
            local flag = o.Flag or o.Title
            local col = (typeof(o.Default) == "Color3") and o.Default or T.accent
            local sv = flag and Data.Features[flag]
            if type(sv) == "table" and #sv == 3 then col = Color3.fromRGB(sv[1], sv[2], sv[3]) end
            local hh, ss, vv = col:ToHSV()
            local H0, PH = 48, 108
            local POPH = 8 + PH + 8 + 28 + 8
            local EXP = H0 + 2 + POPH + 8
            local open = false
            local f, st, hf, fx = card(H0, false, "color")
            f.ClipsDescendants = true
            local head = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, H0)}, f)
            ripple(head)
            spotlight(f, head)
            fx.bindHover(head)
            label(head, {Text = tostring(o.Title or flag or "Color"), Position = UDim2.fromOffset(TXL, 0), Size = UDim2.new(1, -(TXL + 140), 0, H0), Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 2})
            local hexL = label(head, {Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -66, 0, 0), Size = UDim2.fromOffset(70, H0), TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.Code, TextSize = 11, TextColor3 = DIM, ZIndex = 2})
            local sg = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(54, 34), BackgroundColor3 = col, BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 1}, head)
            corner(sg, 12)
            local sw = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.fromOffset(36, 22), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 2}, head)
            corner(sw, 8) stroke(sw, WHITE, 1.5, 0.35)

            local pop = new("Frame", {Position = UDim2.fromOffset(8, H0 + 2), Size = UDim2.new(1, -16, 0, POPH), BackgroundColor3 = T.input, BackgroundTransparency = 0.3, BorderSizePixel = 0}, f)
            corner(pop, 12) stroke(pop, T.stroke, 1, 0.6)
            local svBox = new("Frame", {Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -52, 0, PH), BackgroundColor3 = Color3.fromHSV(hh, 1, 1), BorderSizePixel = 0}, pop)
            corner(svBox, 9)
            local wf = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, svBox)
            corner(wf, 9) new("UIGradient", {Transparency = NumberSequence.new(0, 1)}, wf)
            local bf = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, svBox)
            corner(bf, 9) new("UIGradient", {Transparency = NumberSequence.new(1, 0), Rotation = 90}, bf)
            local pt = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3}, svBox)
            corner(pt, FULL) stroke(pt, WHITE, 2.5, 0)
            local svHit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4}, svBox)

            local hue = new("Frame", {Position = UDim2.new(1, -34, 0, 8), Size = UDim2.fromOffset(22, PH), BackgroundColor3 = WHITE, BorderSizePixel = 0}, pop)
            corner(hue, 9)
            local ks = {}
            for i = 0, 6 do ks[#ks + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)) end
            new("UIGradient", {Color = ColorSequence.new(ks), Rotation = 90}, hue)
            local hp = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, hh, 0), Size = UDim2.new(1, 6, 0, 7), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, hue)
            corner(hp, 4) stroke(hp, Color3.new(0, 0, 0), 1, 0.5)
            local hHit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4}, hue)

            local function hex(c) return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
            local _, hexBox = inputBox(pop, {text = "", placeholder = "#RRGGBB", wrap = {Position = UDim2.fromOffset(10, 8 + PH + 8), Size = UDim2.new(1, -20, 0, 28)}})
            local function apply(anim, silent, exact)
                col = exact or Color3.fromHSV(hh, ss, vv)
                sw.BackgroundColor3 = col
                sg.BackgroundColor3 = col
                svBox.BackgroundColor3 = Color3.fromHSV(hh, 1, 1)
                local hx = hex(col)
                hexL.Text = hx
                if not hexBox:IsFocused() then hexBox.Text = hx end
                local p1, p2 = UDim2.fromScale(ss, 1 - vv), UDim2.new(0.5, 0, hh, 0)
                if anim then play(pt, {Position = p1}, 0.15) play(hp, {Position = p2}, 0.15)
                else pt.Position = p1 hp.Position = p2 end
                if not silent then safe(o.Callback, col) end
            end
            local function rgbOf() return {math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)} end
            local function persistCol()
                if flag then Data.Features[flag] = rgbOf() persist() end
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
                function(pos) scroll.ScrollingEnabled = false play(pt, {Size = UDim2.fromOffset(18, 18)}, 0.12) svFrom(pos) return true end,
                function(_, _, _, _, pos) svFrom(pos) end,
                function() scroll.ScrollingEnabled = true play(pt, {Size = UDim2.fromOffset(14, 14)}, 0.25, Enum.EasingStyle.Back) persistCol() end)
            track(hHit,
                function(pos) scroll.ScrollingEnabled = false play(hp, {Size = UDim2.new(1, 10, 0, 9)}, 0.12) hueFrom(pos) return true end,
                function(_, _, _, _, pos) hueFrom(pos) end,
                function() scroll.ScrollingEnabled = true play(hp, {Size = UDim2.new(1, 6, 0, 7)}, 0.25, Enum.EasingStyle.Back) persistCol() end)

            -- input hex: #RGB / #RRGGBB, dengan atau tanpa tanda #
            local function parseHex(s)
                s = tostring(s):gsub("[%s#]", "")
                if #s == 3 then s = s:gsub(".", "%0%0") end
                if #s ~= 6 or s:find("%X") then return nil end
                local r, g, b = tonumber(s:sub(1, 2), 16), tonumber(s:sub(3, 4), 16), tonumber(s:sub(5, 6), 16)
                if not (r and g and b) then return nil end
                return Color3.fromRGB(r, g, b)
            end
            hexBox.FocusLost:Connect(function()
                local c = parseHex(hexBox.Text)
                if c then
                    hh, ss, vv = c:ToHSV()
                    apply(true, false, c)
                    persistCol()
                    sfx("pop")
                else
                    hexBox.Text = hex(col)
                end
            end)

            local function setOpen(v)
                open = v
                sfx(v and "expand" or "collapse")
                fx.active(v)
                play(hf, {Size = UDim2.new(1, 0, 0, v and EXP or H0)}, 0.4, Enum.EasingStyle.Quint)
            end
            head.MouseButton1Click:Connect(function() setOpen(not open) end)

            apply(false, true)
            if flag then Data.Features[flag] = rgbOf() end
            if o.Callback then task.spawn(safe, o.Callback, col) end
            return {
                Set = function(_, c)
                    if typeof(c) == "Color3" then
                        hh, ss, vv = c:ToHSV()
                        apply(true, true, c)
                        if flag then Data.Features[flag] = rgbOf() end
                    end
                end,
                Get = function() return col end,
            }
        end

        ----------------------------------------------------------------
        -- ACCORDION: grup buka/tutup dengan timeline, isinya komponen apa saja
        --   local A = Tab:Accordion({Title = "Farm", Desc = "opsional", Open = false})
        --   A:Toggle({...}) A:Slider({...}) A:Button({...}) A:Dropdown({...}) dst
        --   A:Expand() A:Collapse() A:SetOpen(bool) A:IsOpen()
        ----------------------------------------------------------------
                ----------------------------------------------------------------
        -- ACCORDION v2: sekali dibuka tetap terbuka (klik hanya bisa membuka)
        --   local A = Tab:Accordion({Title = "Farm", Desc = "opsional", Open = false})
        --   A:Toggle({...}) A:Slider({...}) A:Button({...}) A:Dropdown({...}) dst
        --   A:Expand() A:Collapse() A:SetOpen(bool) A:IsOpen()
        --   (Collapse / SetOpen(false) hanya bisa lewat script, klik user tidak bisa menutup)
        ----------------------------------------------------------------
        function K:Accordion(o)
            o = o or {}
            local hasDesc = o.Desc ~= nil
            local HEAD = hasDesc and 62 or 52
            local PADT, PADB = 14, 16
            local PILL_W = 84
            local R = nested and 12 or 16
            local open, animating, tok = false, false, 0
            local f, st, hf, fx, tile = card(HEAD, false, "group", math.floor((HEAD - ICN) / 2))
            f.ClipsDescendants = true

            local function setP(inst, props, t)
                if t and t > 0 then
                    play(inst, props, t)
                else
                    for k, v in pairs(props) do inst[k] = v end
                end
            end

            -- wash aksen di header, menyala saat terbuka
            local hglow = new("Frame", {Name = "HeadGlow", Size = UDim2.new(1, 0, 0, HEAD), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0}, f)
            corner(hglow, R)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new(0, 1)}, hglow)

            -- header
            local head = new("Frame", {Name = "Head", Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, BorderSizePixel = 0}, f)
            local hit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, head)
            local tLbl, dLbl = rowLabels(head, o, o.Title or "Accordion", 1, -140, HEAD, 2)
            if dLbl then
                tLbl.Position = UDim2.fromOffset(TXL, 13)
                dLbl.Position = UDim2.fromOffset(TXL, 32)
            end

            -- badge jumlah item
            local cnt = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(12 + PILL_W + 8), 0.5, 0), Size = UDim2.fromOffset(26, 22), BackgroundColor3 = ACCENT, BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 2}, head)
            corner(cnt, FULL)
            stroke(cnt, ACCENT, 1, 0.5)
            local cntL = label(cnt, {Text = "0", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 10, TextTruncate = Enum.TextTruncate.None, ZIndex = 3})

            -- cahaya berdenyut di belakang tombol (hanya saat tertutup)
            local glow = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -(12 + PILL_W / 2), 0.5, 0), Size = UDim2.fromOffset(PILL_W + 6, 32), BackgroundColor3 = T.accent, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 1}, head)
            corner(glow, FULL)
            wloop(glow, 1.1, {Size = UDim2.fromOffset(PILL_W + 26, 42), BackgroundTransparency = 0.94})

            -- tombol OPEN -> OPENED
            local pill = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(PILL_W, 26), BackgroundColor3 = WHITE, BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 3}, head)
            corner(pill, FULL)
            local pg = grad(pill, T.accent, T.cyan, 0)
            local pst = stroke(pill, T.cyan, 1, 0.55)
            local pSc = new("UIScale", {Scale = 1}, pill)
            local pDot = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = WHITE, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 4}, pill)
            corner(pDot, FULL)
            local pArr = label(pDot, {Text = "›", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, -1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = WHITE, Rotation = 90, TextTruncate = Enum.TextTruncate.None, ZIndex = 5})
            local pTxt = label(pill, {Text = "OPEN", Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -30, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.None, ZIndex = 4})

            -- garis pemisah header (menggambar dari tengah saat terbuka)
            local sep = new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, HEAD), Size = UDim2.new(0, 0, 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, f)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1)}}, sep)

            -- isi: wrap (ukuran offset eksplisit, clip) berisi panel cekung + timeline + content.
            -- Saat tertutup wrap disembunyikan total, jadi isi tidak mungkin bocor / bergeser.
            local wrap = new("Frame", {Position = UDim2.fromOffset(0, HEAD), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Visible = false}, f)
            local inset = new("Frame", {Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 1, -14), BackgroundColor3 = T.input, BackgroundTransparency = 0.4, BorderSizePixel = 0}, wrap)
            corner(inset, 12)
            local ist = stroke(inset, WHITE, 1, 0.55)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Rotation = 90}, ist)
            do -- bayangan di sisi atas supaya terasa cekung
                local ish = new("Frame", {Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0, BorderSizePixel = 0}, inset)
                corner(ish, 12)
                new("UIGradient", {Transparency = NumberSequence.new(0.45, 1), Rotation = 90}, ish)
            end
            local content = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0}, wrap)
            new("UIPadding", {PaddingTop = UDim.new(0, PADT), PaddingBottom = UDim.new(0, PADB), PaddingLeft = UDim.new(0, 30), PaddingRight = UDim.new(0, 14)}, content)
            local lay = new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, content)

            -- timeline + kilau yang meluncur turun
            local tree = new("Frame", {Position = UDim2.fromOffset(17, 12), Size = UDim2.new(0, 2, 1, -26), BackgroundColor3 = WHITE, BorderSizePixel = 0, ClipsDescendants = true}, wrap)
            corner(tree, FULL)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new(0.25, 0.85), Rotation = 90}, tree)
            local glint = new("Frame", {Size = UDim2.new(1, 0, 0, 46), Position = UDim2.fromOffset(0, -46), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, tree)
            new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.05), NumberSequenceKeypoint.new(1, 1)}, Rotation = 90}, glint)
            local glintOn = false
            local function startGlint()
                if glintOn then return end
                glintOn = true
                local t = TweenService:Create(glint, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.6), {Position = UDim2.new(0, 0, 1, 0)})
                t:Play()
                winLoops[#winLoops + 1] = t
            end

            local sub = buildComponents(scroll, content, true)

            local function contentH()
                if lay.AbsoluteContentSize.Y <= 0 then return 0 end
                local fac = head.AbsoluteSize.Y / HEAD
                if fac < 0.01 then fac = math.max(rootScale.Scale * winScale.Scale, 0.01) end
                return math.floor(lay.AbsoluteContentSize.Y / fac + 0.5) + PADT + PADB
            end
            local function setH(h)
                wrap.Size = UDim2.new(1, 0, 0, h)
                hf.Size = UDim2.new(1, 0, 0, HEAD + h)
            end
            local function resetKids()
                for _, b in ipairs(sub._kids) do
                    if b.Parent then b.Position = UDim2.fromOffset(0, 0) end
                end
            end
            local function recount()
                local n = 0
                for _, c in ipairs(content:GetChildren()) do
                    if c.Name == "Holder" and not c:GetAttribute("Deco") then n = n + 1 end
                end
                cntL.Text = tostring(n)
                cnt.Size = UDim2.fromOffset(math.max(26, textW(tostring(n), 10) + 16), 22)
            end
            content.ChildAdded:Connect(function() task.defer(recount) end)
            content.ChildRemoved:Connect(function() task.defer(recount) end)

            -- tampilan header untuk dua keadaan (tertutup = ajakan "OPEN", terbuka = "OPENED" hijau)
            local function paintHead(v, instant)
                local function d(x) return instant and 0 or x end
                setP(pill, {BackgroundTransparency = v and 0.8 or 0}, d(0.3))
                setP(pst, {Color = v and T.ok or T.cyan, Transparency = v and 0.35 or 0.55}, d(0.3))
                pg.Color = v and ColorSequence.new(T.ok, T.ok) or ColorSequence.new(T.accent, T.cyan)
                setP(pDot, {BackgroundColor3 = v and T.ok or WHITE, BackgroundTransparency = v and 0.75 or 0.8}, d(0.3))
                setP(pArr, {TextColor3 = v and T.ok or WHITE, Rotation = v and 0 or 90}, d(0.3))
                setP(pTxt, {TextColor3 = v and T.ok or WHITE}, d(0.3))
                pTxt.Text = v and "OPENED" or "OPEN"
                pArr.Text = v and "✓" or "›"
                glow.Visible = not v
                setP(hglow, {BackgroundTransparency = v and 0.82 or 1}, d(0.4))
                setP(cnt, {BackgroundTransparency = v and 0.55 or 0.82}, d(0.3))
                setP(sep, {Size = v and UDim2.new(1, -24, 0, 1) or UDim2.new(0, 0, 0, 1)}, d(0.5))
                if v then fx.hover(false) end
                fx.active(v)
            end

            -- efek "terbuka": cincin dari tombol, kilau menyapu header, ikon memantul
            local function burst()
                local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -(12 + PILL_W / 2), 0.5, 0), Size = UDim2.fromOffset(PILL_W, 26), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5}, head)
                corner(ring, FULL)
                local rs = stroke(ring, T.cyan, 2, 0.1)
                play(ring, {Size = UDim2.fromOffset(PILL_W + 50, 56)}, 0.55)
                play(rs, {Transparency = 1}, 0.55)
                task.delay(0.6, function() ring:Destroy() end)
                local sh = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 60, 2, 0), Position = UDim2.new(-0.15, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5}, head)
                new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.82), NumberSequenceKeypoint.new(1, 1)}}, sh)
                play(sh, {Position = UDim2.new(1.15, 0, 0.5, 0)}, 0.7, Enum.EasingStyle.Quad)
                task.delay(0.75, function() sh:Destroy() end)
                pSc.Scale = 0.8
                play(pSc, {Scale = 1}, 0.5, Enum.EasingStyle.Back)
                if tile then
                    tile.Rotation = -25
                    play(tile, {Rotation = 0}, 0.8, Enum.EasingStyle.Elastic)
                end
            end

            local function setOpen(v, instant)
                if v == open then return end
                open = v
                tok = tok + 1
                local my = tok
                if not instant then sfx(v and "expand" or "collapse") end
                paintHead(v, instant)
                if v then
                    startGlint()
                    if not instant then burst() end
                else
                    resetKids()
                end
                if instant then
                    wrap.Visible = v
                    setH(v and contentH() or 0)
                    return
                end
                animating = true
                task.spawn(function()
                    if v then
                        wrap.Visible = true
                        RunService.Heartbeat:Wait()
                        if tok ~= my then return end
                    end
                    local h = v and contentH() or 0
                    local dur = v and 0.5 or 0.4
                    local sty = v and Enum.EasingStyle.Quint or Enum.EasingStyle.Quart
                    play(hf, {Size = UDim2.new(1, 0, 0, HEAD + h)}, dur, sty)
                    play(wrap, {Size = UDim2.new(1, 0, 0, h)}, dur, sty)
                    if v then
                        for i, b in ipairs(sub._kids) do
                            if b.Parent then
                                b.Position = UDim2.fromOffset(0, -10)
                                task.delay(0.05 + math.min(i - 1, 8) * 0.045, function()
                                    if open and tok == my and b.Parent then play(b, {Position = UDim2.fromOffset(0, 0)}, 0.45, Enum.EasingStyle.Back) end
                                end)
                            end
                        end
                    end
                    task.wait(dur + 0.05)
                    if tok ~= my then return end
                    animating = false
                    if open then
                        resetKids()
                        setH(contentH())
                    else
                        wrap.Visible = false
                    end
                end)
            end
            -- isi berubah saat terbuka (dropdown mengembang, komponen ditambah): ukuran ikut langsung
            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if open and not animating then
                    local h = contentH()
                    if math.abs(wrap.Size.Y.Offset - h) > 1 then setH(h) end
                end
            end)

            -- interaksi header: hanya aktif selama masih tertutup
            hit.MouseEnter:Connect(function()
                if open then return end
                sfx("hover")
                fx.hover(true)
                play(pSc, {Scale = 1.07}, 0.25, Enum.EasingStyle.Back)
                if tile then
                    tile.Rotation = -12
                    play(tile, {Rotation = 0}, 0.6, Enum.EasingStyle.Elastic)
                end
            end)
            hit.MouseLeave:Connect(function()
                fx.hover(false)
                play(pSc, {Scale = 1}, 0.25)
            end)
            hit.MouseButton1Down:Connect(function()
                if not open then play(pSc, {Scale = 0.92}, 0.08) end
            end)
            hit.MouseButton1Up:Connect(function()
                if not open then play(pSc, {Scale = 1.07}, 0.3, Enum.EasingStyle.Back) end
            end)
            hit.MouseButton1Click:Connect(function()
                if open then return end
                setOpen(true)
            end)

            function sub:Expand() setOpen(true) end
            function sub:Collapse() setOpen(false) end
            function sub:SetOpen(v) setOpen(v and true or false) end
            function sub:IsOpen() return open end
            if o.Open then setOpen(true, true) end
            return sub
        end
        K.Group = K.Accordion
        -- panel samping bisa dibuat dari tab maupun dari window: Tab:Panel({...}) == Window:Panel({...})
        function K:Panel(o) return Window:Panel(o) end

        K.Color = K.ColorPicker

        return K
    end

    ------------------------------------------------------------------
    -- DASHBOARD
    ------------------------------------------------------------------
    local dashScroll = createTab("Dashboard", true)
    local D = buildComponents(dashScroll)
    local xyv, fpsV, pingV, fpsPush

        -- ===== DASHBOARD GAYA BARU =====
    -- dummy supaya loop FPS & koordinat bawaan tidak error
    fpsV, xyv = {Text = "", TextColor3 = WHITE}, {Text = ""}
    local DISCORD = Color3.fromRGB(88, 101, 242)
    local joinT = os.time()

    -- kartu gelap + glow warna di sudut
    local function pcard(parent, pos, size, col, clickable)
        local f = new(clickable and "TextButton" or "Frame", {Position = pos, Size = size, BackgroundColor3 = T.ink, BorderSizePixel = 0, ClipsDescendants = true}, parent)
        if clickable then f.Text = "" f.AutoButtonColor = false end
        corner(f, 16)
        local s = stroke(f, T.stroke, 1, 0.55)
        regTrans(f, 0.05)
        gloss(f)
        local wash = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 0}, f)
        corner(wash, 16)
        new("UIGradient", {Rotation = -35, Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.55, 0.9), NumberSequenceKeypoint.new(1, 1)}}, wash)
        return f, s
    end

    -- sel kecil: judul tebal + nilai redup
    local function cell(parent, ord, title, value, clickable, h)
        h = h or 30
        local y0 = math.floor((h - 25) / 2)
        local c = new(clickable and "TextButton" or "Frame", {BackgroundColor3 = T.input, BackgroundTransparency = 0.25, BorderSizePixel = 0, LayoutOrder = ord}, parent)
        if clickable then c.Text = "" c.AutoButtonColor = false end
        corner(c, 9) stroke(c, T.stroke, 1, 0.6)
        label(c, {Text = title, Position = UDim2.fromOffset(9, y0), Size = UDim2.new(1, -14, 0, 13), Font = Enum.Font.GothamBold, TextSize = 11})
        return c, label(c, {Text = value, Position = UDim2.fromOffset(9, y0 + 13), Size = UDim2.new(1, -14, 0, 11), TextSize = 9, TextColor3 = DIM})
    end

    -- sensor blur (palsu: teks digandakan & digeser). Ketuk untuk buka / tutup sensor
    local function blurLabel(parent, text, pos, size, font, tsize, col)
        local box = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Position = pos, Size = size, ZIndex = 3}, parent)
        local real = label(box, {Text = text, Size = UDim2.fromScale(1, 1), Font = font, TextSize = tsize, TextColor3 = col or T.text, TextTransparency = 1, ZIndex = 4})
        local ghosts = {}
        for _, o in ipairs({{0, 0}, {-4, 0}, {4, 0}, {0, -3}, {0, 3}, {-3, -2}, {3, 2}, {-3, 2}, {3, -2}}) do
            ghosts[#ghosts + 1] = label(box, {Text = text, Position = UDim2.fromOffset(o[1], o[2]), Size = UDim2.fromScale(1, 1), Font = font, TextSize = tsize, TextColor3 = col or T.text, TextTransparency = 0.82, ZIndex = 3})
        end
        local hidden = true
        box.MouseButton1Click:Connect(function()
            hidden = not hidden
            sfx("tick")
            play(real, {TextTransparency = hidden and 1 or 0}, 0.2)
            for _, g in ipairs(ghosts) do play(g, {TextTransparency = hidden and 0.82 or 1}, 0.2) end
        end)
        return box
    end

    do -- baris 1: avatar + "Hello, ..."
        local hf = D._holder(84)
        local row = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
        D._enter(row)

        local av = pcard(row, UDim2.fromOffset(0, 0), UDim2.fromOffset(84, 84), T.accent)
        local img = new("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop, ZIndex = 2}, av)
        corner(img, 16)
        task.spawn(function()
            local ok, url = pcall(function() return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size150x150) end)
            if ok and img.Parent then img.Image = url end
        end)

        local hi = pcard(row, UDim2.fromOffset(96, 16), UDim2.new(1, -96, 0, 52), T.cyan)
        local gw = math.ceil(textW("Hello,", 16)) + 5
        label(hi, {Text = "Hello,", Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(gw, 20), Font = Enum.Font.GothamBold, TextSize = 16, TextTruncate = Enum.TextTruncate.None})
        blurLabel(hi, pl.DisplayName, UDim2.fromOffset(14 + gw, 8), UDim2.new(1, -(28 + gw), 0, 20), Enum.Font.GothamBold, 16)
        local nw = math.ceil(textW(pl.Name, 11)) + 4
        blurLabel(hi, pl.Name, UDim2.fromOffset(14, 30), UDim2.fromOffset(nw, 14), Enum.Font.GothamMedium, 11, DIM)
        local gl = label(hi, {Text = "-", Position = UDim2.fromOffset(14 + nw, 30), Size = UDim2.new(1, -(28 + nw), 0, 14), TextSize = 11, TextColor3 = DIM})
        bindName(function(n) gl.Text = "-  "..n end)
    end

    do -- baris 2: kolom kiri (Server + Discord), kolom kanan (Executor + Friends)
        local hf = D._holder(212)
        local row = new("Frame", {Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, hf)
        D._enter(row)
        local left = new("Frame", {Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1}, row)
        local right = new("Frame", {Position = UDim2.new(0.5, 4, 0, 0), Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1}, row)

        -- SERVER
        local sv = pcard(left, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 152), T.cyan)
        label(sv, {Text = "Server", Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 18), Font = Enum.Font.GothamBold, TextSize = 14})
        label(sv, {Text = "Information on the session you're currently in", Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -28, 0, 12), TextSize = 9, TextColor3 = DIM})
        local grid = new("Frame", {Position = UDim2.fromOffset(10, 46), Size = UDim2.new(1, -20, 0, 100), BackgroundTransparency = 1}, sv)
        new("UIGridLayout", {CellSize = UDim2.new(0.5, -3, 0, 30), CellPadding = UDim2.fromOffset(6, 5), SortOrder = Enum.SortOrder.LayoutOrder}, grid)
        local _, plV = cell(grid, 1, "Players", "-")
        local _, mxV = cell(grid, 2, "Maximum Players", "-")
        local _, lat = cell(grid, 3, "Latency", "-")
        local _, rgV = cell(grid, 4, "Region", "-")
        local _, upV = cell(grid, 5, "In server for", "00:00:00")
        local jb = cell(grid, 6, "Join Script", "Tap to copy join script", true)
        pingV = lat   -- loop ping bawaan mengisi label ini
        pcall(function() mxV.Text = Players.MaxPlayers.." players max" end)
        hover(jb) ripple(jb)
        jb.MouseButton1Click:Connect(function()
            sfx("click")
            copy(("game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game.Players.LocalPlayer)"):format(tostring(placeId), game.JobId))
            notify("Copied", "Join script copied", ACCENT, 1.8)
        end)
        task.spawn(function()
            pcall(function() rgV.Text = game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(pl) end)
        end)
        task.spawn(function()
            while gui.Parent do
                if isOpen and cur == "Dashboard" then
                    plV.Text = #Players:GetPlayers().." playing"
                    local s = os.time() - joinT
                    upV.Text = string.format("%02d:%02d:%02d", s // 3600, s % 3600 // 60, s % 60)
                end
                task.wait(1)
            end
        end)

        -- DISCORD
        local dc, dcs = pcard(left, UDim2.fromOffset(0, 160), UDim2.new(1, 0, 0, 52), DISCORD, true)
        label(dc, {Text = "Discord", Position = UDim2.fromOffset(14, 5), Size = UDim2.new(1, -28, 0, 26), Font = Enum.Font.GothamBold, TextSize = 21})
        label(dc, {Text = "Tap to join the Discord Server", Position = UDim2.fromOffset(14, 31), Size = UDim2.new(1, -28, 0, 14), TextSize = 11, TextColor3 = Color3.fromRGB(210, 216, 255)})
        hover(dc, dcs, Color3.fromRGB(20, 18, 36), T.cardDown) ripple(dc)
        dc.MouseButton1Click:Connect(function()
            copy("https://discord.gg/cHsx3RFYb")
            notify("Discord", "Invite copied to clipboard", DISCORD, 2)
        end)

        -- EXECUTOR
        local exeName = "Executor"
        pcall(function() if identifyexecutor then exeName = tostring((identifyexecutor())) end end)
        local env = (getgenv and getgenv()) or getfenv()
        local missing = {}
        for _, n in ipairs({"writefile", "readfile", "isfile", "getcustomasset"}) do
            if type(env[n]) ~= "function" then missing[#missing + 1] = n end
        end
        local good = (#missing == 0)
        local wv = pcard(right, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 68), good and T.ok or T.bad)
        label(wv, {Text = exeName, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 26), Font = Enum.Font.GothamBold, TextSize = 20})
        label(wv, {Text = good and "Your executor seems to support this script." or ("Missing: "..table.concat(missing, ", ")), Position = UDim2.fromOffset(14, 36), Size = UDim2.new(1, -28, 0, 26), TextSize = 11, TextColor3 = good and T.ok or T.bad, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None})

        -- FRIENDS
        local fr = pcard(right, UDim2.fromOffset(0, 76), UDim2.new(1, 0, 0, 136), T.warn)
        label(fr, {Text = "Friends", Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 18), Font = Enum.Font.GothamBold, TextSize = 14})
        label(fr, {Text = "Find out what your friends are currently doing", Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -28, 0, 12), TextSize = 9, TextColor3 = DIM})
        local fg = new("Frame", {Position = UDim2.fromOffset(10, 46), Size = UDim2.new(1, -20, 0, 82), BackgroundTransparency = 1}, fr)
        new("UIGridLayout", {CellSize = UDim2.new(0.5, -3, 0, 38), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder}, fg)
        local _, fIn = cell(fg, 1, "In Server", "-", false, 38)
        local _, fOff = cell(fg, 2, "Offline", "-", false, 38)
        local _, fOn = cell(fg, 3, "Online", "-", false, 38)
        local _, fAll = cell(fg, 4, "All", "-", false, 38)
        local function plural(n) return (n == 0) and "no friends" or ((n == 1) and "1 friend" or (n.." friends")) end
        task.spawn(function()
            while gui.Parent do
                local total, online, inSrv = 0, 0, 0
                pcall(function()
                    local pages = Players:GetFriendsAsync(pl.UserId)
                    while true do
                        total = total + #pages:GetCurrentPage()
                        if pages.IsFinished then break end
                        pages:AdvanceToNextPageAsync()
                    end
                end)
                pcall(function() online = #pl:GetFriendsOnline(200) end)
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= pl then
                        local okf, isF = pcall(function() return pl:IsFriendsWith(p.UserId) end)
                        if okf and isF then inSrv = inSrv + 1 end
                    end
                end
                fAll.Text = plural(total)
                fOn.Text = plural(online)
                fOff.Text = plural(math.max(0, total - online))
                fIn.Text = plural(inSrv)
                task.wait(60)
            end
        end)
    end
    -- ganti warna aksen semua elemen yang sudah ada (cocokkan warna lama -> baru)
    local function retheme(oldPal)
        local nw = {T.accent, T.accent2, T.cyan, T.pink}
        local function sw(c)
            for i = 1, 4 do if c == oldPal[i] then return nw[i] end end
            return c
        end
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("GuiObject") then
                local c = d.BackgroundColor3
                local n = sw(c)
                if n ~= c then d.BackgroundColor3 = n end
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    c = d.TextColor3
                    n = sw(c)
                    if n ~= c then d.TextColor3 = n end
                elseif d:IsA("ImageLabel") then
                    c = d.ImageColor3
                    n = sw(c)
                    if n ~= c then d.ImageColor3 = n end
                elseif d:IsA("ScrollingFrame") then
                    c = d.ScrollBarImageColor3
                    n = sw(c)
                    if n ~= c then d.ScrollBarImageColor3 = n end
                end
            elseif d:IsA("UIStroke") then
                local c = d.Color
                local n = sw(c)
                if n ~= c then d.Color = n end
            elseif d:IsA("UIGradient") then
                local nk, changed = {}, false
                for i, k in ipairs(d.Color.Keypoints) do
                    local n = sw(k.Value)
                    if n ~= k.Value then changed = true end
                    nk[i] = ColorSequenceKeypoint.new(k.Time, n)
                end
                if changed then d.Color = ColorSequence.new(nk) end
            end
        end
    end

    D:Section("Interface")
    D:Dropdown({
        Title = "Theme", Desc = "Accent color preset", Flag = "UITheme", Options = THEME_ORDER, Default = "Violet",
        Callback = function(v)
            if type(v) ~= "string" or v == curTheme or not THEMES[v] then return end
            curTheme = v
            local oldPal = applyPalette(v)
            if not oldPal then return end
            task.spawn(function()
                play(win, {GroupTransparency = 0.45}, 0.12)
                task.wait(0.12)
                retheme(oldPal)
                play(win, {GroupTransparency = 0}, 0.4)
                sfx("pop")
                notify("Theme", v, ACCENT, 1.6)
            end)
        end,
    })
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
        OnRelease = function(v) Data.Features["UITrans"] = v / 100 persist() end,
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
    -- LOOP LIVE: satu RenderStepped untuk FPS, easing drag window, parallax
    ------------------------------------------------------------------
    local fc, lfT = 0, os.clock()
    local pxx, pyy, lastPx, lastPy = 0.5, 0.5, nil, nil
    bind(RunService.RenderStepped, function(dt)
        -- FPS + ping (1x per detik)
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
                play(cdot, {BackgroundColor3 = fcol}, 0.3)
                local pingMs = nil
                pcall(function() pingMs = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
                if pingMs then pingV.Text = pingMs.." ms" end
                chipL.Text = fps.." fps"..(pingMs and ("  •  "..pingMs.." ms") or "")
            end
        end
        -- posisi window mengejar kursor (easing eksponensial) + miring halus mengikuti arah gerak
        if easing and drawPos then
            local k = 1 - math.exp(-dt * 26)
            local nx = drawPos.X + (curPos.X - drawPos.X) * k
            local ny = drawPos.Y + (curPos.Y - drawPos.Y) * k
            if dragging then
                local tgt = math.clamp((nx - drawPos.X) * 0.25, -2.4, 2.4)
                win.Rotation = win.Rotation + (tgt - win.Rotation) * math.min(1, dt * 12)
            elseif math.abs(curPos.X - nx) < 0.2 and math.abs(curPos.Y - ny) < 0.2 then
                nx, ny = curPos.X, curPos.Y
                easing = false
            end
            drawPos = Vector2.new(nx, ny)
            shell.Position = UDim2.fromOffset(nx, ny)
        end
        -- parallax halus: gambar / video background bergeser tipis mengikuti mouse
        if isOpen then
            local sz, ap = win.AbsoluteSize, win.AbsolutePosition
            if sz.X > 0 and sz.Y > 0 then
                local m = UIS:GetMouseLocation()
                local pk = 1 - math.exp(-dt * 5)
                pxx = pxx + (math.clamp((m.X - ap.X) / sz.X, 0, 1) - pxx) * pk
                pyy = pyy + (math.clamp((m.Y - ap.Y) / sz.Y, 0, 1) - pyy) * pk
                if not lastPx or math.abs(pxx - lastPx) > 0.0004 or math.abs(pyy - lastPy) > 0.0004 then
                    lastPx, lastPy = pxx, pyy
                    local ppos = UDim2.new(0.5, (0.5 - pxx) * 22, 0.5, (0.5 - pyy) * 14)
                    bgImg.Position = ppos
                    bgBox.Position = ppos
                end
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
        spin(new("UIGradient", {Color = RING}, stroke(sp, WHITE, 1.5, 0.3)), 3)
        local sc = new("UIScale", {Scale = 0.8}, sp)
        -- gelombang kejut saat "Ready"
        local function shock(col)
            local r = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(70, 70), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 151}, root)
            corner(r, FULL)
            local rs2 = stroke(r, col, 2.5, 0.1)
            play(r, {Size = UDim2.fromOffset(440, 440)}, 0.9, Enum.EasingStyle.Quint)
            play(rs2, {Transparency = 1, Thickness = 0.5}, 0.9)
            task.delay(0.95, function() r:Destroy() end)
        end
        local ringF = new("Frame", {Size = UDim2.fromOffset(60, 60), Position = UDim2.new(0.5, -30, 0, 20), BackgroundColor3 = T.panel, BorderSizePixel = 0}, sp)
        corner(ringF, FULL)
        spin(new("UIGradient", {Color = RING2}, stroke(ringF, WHITE, 2.4, 0)), 1.4)
        local ico = new("ImageLabel", {Size = UDim2.new(1, -18, 1, -18), Position = UDim2.fromOffset(9, 9), BackgroundTransparency = 1, Image = ICON}, ringF)
        loop(new("UIScale", {Scale = 1}, ico), 0.7, {Scale = 1.12})
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
                if s[2] >= 1 then shock(T.cyan) task.delay(0.12, function() shock(T.accent) end) sfx("pop") end
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
    bindName(function(n) Window.GameName = n end)
    Window.IsSupported = isSupported
    Window.Notify = notify
    Window.ShowBadge = showNotSupportedBadge
    function Window:IsGame(id) return placeId == id or gameId == id end
    function Window:Toggle() toggleWin() end
    function Window:Open() if not booting then openA() end end
    function Window:Close() closeA() end
    function Window:SetScale(pct) userScale = math.clamp((tonumber(pct) or 100) / 100, 0.6, 1.5) applyScale() saveUI() end
    function Window:SetBlur(b) blurOn = b and true or false updateBlur() end
    function Window:SetSound(b) sndOn = b and true or false end
    function Window:Destroy() delA() end

    ------------------------------------------------------------------
    -- SORU PANEL v4 : Window:Panel(o)  (panel samping dengan fisika spring)
    --   Tap grip = buka/tutup, tarik grip = geser, lepas dengan kecepatan = lanjut meluncur.
    --   OpenDrag = "Left" (bawaan): panel di KANAN layar, geser grip ke kiri untuk membuka.
    --   OpenDrag = "Right"        : panel di KIRI layar, geser grip ke kanan untuk membuka.
    ------------------------------------------------------------------
    function Window:Panel(o)
        o = o or {}
        -- game tidak didukung: kembalikan objek kosong supaya pemanggilan P:Toggle(...) dst tidak error
        if not isSupported then
            return setmetatable({}, {__index = function() return function() end end})
        end

        -- ===== ukuran & konfigurasi =====
        local W = math.clamp(tonumber(o.Width) or 300, 220, 520)
        local GRIP, M, TOP, RAD = 28, 10, 12, 20   -- area grip, jarak ke tepi layar, jarak atas/bawah, radius sudut
        local HEAD = 62                            -- tinggi header
        local FOOTH = (o.Footer == false) and 0 or 60   -- ruang footer profil (0 = tanpa footer)
        local SPAN = W + M                         -- jarak tempuh panel (px) dari tertutup ke terbuka
        local dockL = (tostring(o.OpenDrag or "Left"):lower() == "right")   -- true = panel di kiri layar
        local AX = dockL and 0 or 1                -- sisi layar tempat panel menempel

        -- spring: frekuensi (rad/s) & damping ratio
        local OPEN_F,  OPEN_Z  = 12,   0.82        -- buka: ada sedikit "settle" di ujung
        local CLOSE_F, CLOSE_Z = 13.5, 1           -- tutup: mulus tanpa memantul

        local isP, hov, dragging, destroyed = false, false, false, false
        local prog, vel, target = 0, 0, 0          -- prog: 0 = tertutup, 1 = terbuka
        local conn

        -- animasi ambient di dalam panel: berhenti sendiri saat panel tertutup
        local ploops, loopsOn = {}, true
        local function setPLoops(on)
            if loopsOn == on then return end
            loopsOn = on
            for i = 1, #ploops do
                if on then ploops[i]:Play() else ploops[i]:Pause() end
            end
        end

        -- ikon "<" dari 2 batang tipis; kotaknya diputar 180 untuk membalik arah
        local function chevron(parent, sz, thick, col, z)
            local box = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = z}, parent)
            local L = sz * 0.62
            local c = sz / 2
            local d = L / 2 * 0.7071
            local tipx = c - L * 0.7071 / 2
            local arms = {}
            for i = 1, 2 do
                local s = (i == 1) and -1 or 1
                arms[i] = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(tipx + d, c + s * d), Size = UDim2.fromOffset(L, thick), Rotation = s * 45, BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = z}, box)
                corner(arms[i], FULL)
            end
            return box, arms
        end

        -- ===== holder: grip di sisi dalam, panel di sisi layar =====
        -- AnchorPoint ikut sisi layar -> Position.X.Offset = jarak dari tepi layar tersebut
        local holder = new("Frame", {Name = "SORU_Panel", AnchorPoint = Vector2.new(AX, 0), Position = UDim2.new(AX, 0, 0, TOP), Size = UDim2.new(0, W + GRIP, 1, -TOP * 2), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 60}, root)

        -- bayangan: memudar sesuai progres supaya tidak bocor di tepi layar saat panel tertutup
        local shadowImg, shadowBox
        if SHADOW_ID ~= "" then
            shadowBox = new("Frame", {AnchorPoint = Vector2.new(AX, 0), Position = UDim2.new(AX, 0, 0, 0), Size = UDim2.new(0, W, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0}, holder)
            shadowImg = new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 8), Size = UDim2.new(1, 56, 1, 56), BackgroundTransparency = 1, Image = "rbxassetid://" .. SHADOW_ID, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 0}, shadowBox)
        end

        -- ===== body (gaya sama dengan sidebar window: gradien kedalaman + cincin berputar) =====
        local body = new("Frame", {Name = "Body", AnchorPoint = Vector2.new(AX, 0), Position = UDim2.new(AX, 0, 0, 0), Size = UDim2.new(0, W, 1, 0), BackgroundColor3 = T.panel, BorderSizePixel = 0, Active = true, ClipsDescendants = true, ZIndex = 1}, holder)
        corner(body, RAD)
        grad(body, WHITE, Color3.fromRGB(190, 186, 214), 90)
        local bs = stroke(body, WHITE, 1.8, 0.25)
        ploops[#ploops + 1] = spin(new("UIGradient", {Color = RING2}, bs), 8)
        regTrans(body, 0.05)

        -- cahaya latar: dua bola cahaya lembut yang melayang pelan
        do
            local function aura(color, size, x0, y0, x1, y1, secs)
                local g = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x0, y0), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1}, body)
                for i = 0, 4 do
                    local f = 1 - i * 0.2
                    local c = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(f, f), BackgroundColor3 = color, BackgroundTransparency = 0.92, BorderSizePixel = 0, ZIndex = 1}, g)
                    corner(c, FULL)
                end
                ploops[#ploops + 1] = loop(g, secs, {Position = UDim2.fromScale(x1, y1)})
            end
            aura(T.accent, 260, 0.15, 0.12, 0.7, 0.3, 8)
            aura(T.cyan, 220, 0.9, 0.92, 0.4, 0.7, 10)
        end

        -- banner header: sudut atas membulat mengikuti body, sisi bawah rata dengan garis pemisah
        do
            local bclip = new("Frame", {Name = "BannerClip", Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 1}, body)
            local banner = new("Frame", {Size = UDim2.new(1, 0, 0, HEAD + RAD), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, bclip)
            corner(banner, RAD)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.74), NumberSequenceKeypoint.new(0.6, 0.92), NumberSequenceKeypoint.new(1, 1)}}, banner)
        end

        -- ===== header =====
        local hd = new("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, body)

        local halo = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(34, HEAD / 2), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = T.accent, BackgroundTransparency = 0.84, BorderSizePixel = 0, ZIndex = 2}, hd)
        corner(halo, FULL)
        ploops[#ploops + 1] = loop(halo, 1.6, {BackgroundTransparency = 0.94, Size = UDim2.fromOffset(58, 58)})
        local badge = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(34, HEAD / 2), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, hd)
        corner(badge, 12)
        grad(badge, T.accent, T.cyan, 45)
        do
            local bin = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -4, 1, -4), BackgroundColor3 = T.panel, BorderSizePixel = 0, ZIndex = 4}, badge)
            corner(bin, 10)
            local gem = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(11, 11), BackgroundColor3 = WHITE, BorderSizePixel = 0, Rotation = 45, ZIndex = 5}, bin)
            corner(gem, 3)
            grad(gem, T.accent, T.cyan, 45)
        end

        local hasSub = o.Subtitle ~= nil and tostring(o.Subtitle) ~= ""
        local tl = label(hd, {Text = tostring(o.Title or "Panel"), Position = UDim2.fromOffset(64, 0), Size = UDim2.new(1, -118, 0, HEAD), Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3})
        local sl = label(hd, {Text = tostring(o.Subtitle or ""), Position = UDim2.fromOffset(64, 34), Size = UDim2.new(1, -118, 0, 14), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3})
        -- dengan subtitle: judul naik sedikit; tanpa subtitle: judul di tengah header
        local function layoutHead(sub)
            sl.Visible = sub
            tl.Position = UDim2.fromOffset(64, sub and 11 or 0)
            tl.Size = UDim2.new(1, -118, 0, sub and 22 or HEAD)
        end
        layoutHead(hasSub)

        local closeB = new("TextButton", {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -46, 0.5, -15), Text = "", BackgroundColor3 = Color3.fromRGB(28, 25, 44), AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3}, hd)
        corner(closeB, FULL)
        stroke(closeB, T.stroke, 1, 0.55)
        hover(closeB, nil, Color3.fromRGB(42, 38, 66), T.cardDown)
        local cbox, carms = chevron(closeB, 14, 2, DIM, 4)
        cbox.Rotation = dockL and 0 or 180
        closeB.MouseEnter:Connect(function() for i = 1, #carms do play(carms[i], {BackgroundColor3 = WHITE}, 0.15) end end)
        closeB.MouseLeave:Connect(function() for i = 1, #carms do play(carms[i], {BackgroundColor3 = DIM}, 0.2) end end)

        do
            local sep = new("Frame", {Position = UDim2.fromOffset(14, HEAD), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, body)
            new("UIGradient", {Color = ColorSequence.new(T.accent, T.cyan), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1)})}, sep)
        end

        -- ===== area komponen =====
        local scroll = new("ScrollingFrame", {Position = UDim2.fromOffset(0, HEAD + 2), Size = UDim2.new(1, 0, 1, -(HEAD + 2 + FOOTH)), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT, ScrollBarImageTransparency = 0.35, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 2}, body)
        new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
        new("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14)}, scroll)

        local K = buildComponents(scroll)

        -- ===== footer profil (sama dengan sidebar window) =====
        if FOOTH > 0 then
            local foot = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.new(1, -20, 0, 46), BackgroundColor3 = T.card, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 3}, body)
            corner(foot, 14) stroke(foot, T.stroke, 1, 0.6) regTrans(foot, 0.1)
            local ringA = new("Frame", {Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = T.panel, BorderSizePixel = 0, ZIndex = 4}, foot)
            corner(ringA, FULL)
            ploops[#ploops + 1] = spin(new("UIGradient", {Color = RING2}, stroke(ringA, WHITE, 1.6, 0)), 4)
            local fav = new("ImageLabel", {Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = T.off, BorderSizePixel = 0, ZIndex = 5}, ringA)
            corner(fav, FULL)
            task.spawn(function()
                local ok, img = pcall(function() return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
                if ok and fav.Parent then fav.Image = img end
            end)
            local od = new("Frame", {Size = UDim2.fromOffset(9, 9), Position = UDim2.fromOffset(31, 31), BackgroundColor3 = T.ok, BorderSizePixel = 0, ZIndex = 6}, foot)
            corner(od, FULL)
            stroke(od, T.panel, 2, 0)
            label(foot, {Text = pl.DisplayName, Position = UDim2.fromOffset(48, 8), Size = UDim2.new(1, -54, 0, 15), Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 4})
            label(foot, {Text = "Online  •  v"..VERSION, Position = UDim2.fromOffset(48, 24), Size = UDim2.new(1, -54, 0, 12), TextSize = 9, TextColor3 = Color3.fromRGB(116, 110, 156), ZIndex = 4})
        end

        -- ===== grip: tab di sisi dalam panel; chevron berputar saat panel membuka, judul tertulis vertikal =====
        local GH = 150
        local grip = new("Frame", {Name = "Grip", AnchorPoint = Vector2.new(1 - AX, 0.5), Position = UDim2.new(1 - AX, 0, math.clamp(tonumber(o.GripY) or 0.3, 0.1, 0.9), 0), Size = UDim2.fromOffset(GRIP, GH), BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, ZIndex = 3}, holder)
        local ghalo = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(24, 112), BackgroundColor3 = T.accent, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 3}, grip)
        corner(ghalo, FULL)
        -- halo "bernapas" pelan sebagai petunjuk bahwa grip bisa ditarik
        loop(ghalo, 1.8, {BackgroundTransparency = 0.76})
        local tab = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 100), BackgroundColor3 = T.panel, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 4}, grip)
        corner(tab, FULL)
        local ts = stroke(tab, WHITE, 1.4, 0.3)
        new("UIGradient", {Color = ColorSequence.new(T.cyan, T.accent), Rotation = 90}, ts)
        local chev, chevArms = chevron(tab, 18, 2.4, DIM, 5)
        chev.Position = UDim2.new(0.5, 0, 0, 20)
        local vtxt = label(tab, {Text = string.upper(tostring(o.Title or "Panel")), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 14), Size = UDim2.fromOffset(60, 16), Rotation = dockL and -90 or 90, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = DIM, ZIndex = 5})

        local function gripFx(on)
            play(tab, {Size = on and UDim2.fromOffset(24, 116) or UDim2.fromOffset(20, 100)}, 0.4)
            play(ghalo, {Size = on and UDim2.fromOffset(32, 132) or UDim2.fromOffset(24, 112)}, 0.5)
            play(ts, {Transparency = on and 0 or 0.3}, 0.3)
            play(vtxt, {TextColor3 = on and WHITE or DIM}, 0.3)
            for i = 1, #chevArms do play(chevArms[i], {BackgroundColor3 = on and WHITE or DIM}, 0.3) end
        end
        grip.MouseEnter:Connect(function() hov = true sfx("hover") gripFx(true) end)
        grip.MouseLeave:Connect(function() hov = false if not dragging then gripFx(false) end end)

        -- ===== gerak: spring physics =====
        -- Satu angka `prog` (0..1) menggerakkan semuanya. Spring menjaga kecepatan saat arah berubah di tengah
        -- animasi atau saat panel dilepas dari geseran (fling), jadi gerakannya selalu menyambung dan mulus.
        local function apply(snap)
            local p = math.clamp(prog, 0, 1.04)
            local x = W - p * SPAN
            local q = math.clamp(p, 0, 1)
            local px = (1 - q) * 20                 -- parallax: isi header sedikit tertinggal di belakang panel
            if snap then
                x = math.floor(x + 0.5)
                px = math.floor(px + 0.5)
            end
            holder.Position = UDim2.new(AX, dockL and -x or x, 0, TOP)
            hd.Position = UDim2.fromOffset(dockL and -px or px, 0)
            chev.Rotation = dockL and (180 * (1 - q)) or (180 * q)   -- mengarah ke dalam saat tertutup, ke tepi saat terbuka
            if shadowImg then shadowImg.ImageTransparency = 1 - 0.4 * q end
        end

        local function stopLoop()
            if conn then
                conn:Disconnect()
                conn = nil
            end
        end

        local function startLoop()
            if conn then return end
            conn = RunService.RenderStepped:Connect(function(dt)
                if dragging then return end
                dt = math.min(dt, 1 / 15)
                local f, z
                if target > 0.5 then f, z = OPEN_F, OPEN_Z else f, z = CLOSE_F, CLOSE_Z end
                local k, c = f * f, 2 * z * f
                local n = math.max(1, math.ceil(dt * 240))   -- sub-step supaya stabil di FPS berapa pun
                local h = dt / n
                for _ = 1, n do
                    vel = vel + ((target - prog) * k - vel * c) * h
                    prog = prog + vel * h
                end
                if prog < 0 then
                    prog = 0
                    if vel < 0 then vel = 0 end
                end
                if math.abs(target - prog) < 0.0005 and math.abs(vel) < 0.005 then
                    prog, vel = target, 0
                    stopLoop()
                    apply(true)
                    if target == 0 then setPLoops(false) end
                else
                    apply(false)
                end
            end)
        end

        -- buka / tutup
        local function goTo(open, quiet)
            local was = isP
            isP = open and true or false
            target = isP and 1 or 0
            if isP then setPLoops(true) end
            if was ~= isP then
                if not quiet then sfx(isP and "expand" or "collapse") end
                if isP then
                    task.delay(0.14, function() if isP and scroll.Parent then entrance(scroll) end end)
                end
                if o.Callback then task.spawn(safe, o.Callback, isP) end
            end
            startLoop()
        end
        closeB.MouseButton1Click:Connect(function() sfx("click") goTo(false) end)

        -- geser grip: panel mengikuti jari/mouse; lepas = lanjut dengan kecepatan geseran, tap = toggle
        local dragV, lastT, lastP = 0, 0, 0
        track(grip,
            function()
                stopLoop()
                vel = 0
                dragging = true
                gripFx(true)
                dragV, lastT, lastP = 0, os.clock(), prog
                return {p0 = prog}
            end,
            function(dx, dy, st, moved)
                if not (moved and st) then return end
                local d = dx / math.max(rootScale.Scale, 0.01)
                if dockL then d = -d end
                prog = math.clamp(st.p0 - d / SPAN, 0, 1)    -- geser ke arah dalam layar = membuka
                if prog > 0.04 then setPLoops(true) end
                local now = os.clock()
                local dt = now - lastT
                if dt > 0.004 then
                    dragV = dragV + ((prog - lastP) / dt - dragV) * 0.35   -- kecepatan, dihaluskan
                    lastT, lastP = now, prog
                end
                apply(false)
            end,
            function(moved)
                dragging = false
                gripFx(hov)
                if not moved then goTo(not isP) return end
                local v = (os.clock() - lastT < 0.1) and dragV or 0        -- berhenti dulu sebelum lepas = tanpa fling
                local open
                if math.abs(v) > 0.9 then open = v > 0 else open = (prog + v * 0.15) > 0.5 end
                vel = v
                goTo(open)
            end)

        -- lebar bisa diubah lewat API (SetWidth); ketinggian selalu setinggi layar
        local function setWidth(w)
            W = math.clamp(tonumber(w) or W, 220, 520)
            SPAN = W + M
            holder.Size = UDim2.new(0, W + GRIP, 1, -TOP * 2)
            body.Size = UDim2.new(0, W, 1, 0)
            if shadowBox then shadowBox.Size = UDim2.new(0, W, 1, 0) end
            apply(true)
        end

        -- API tambahan (nama sengaja bukan Open/Toggle supaya tidak bentrok dgn komponen)
        function K:Show() goTo(true) end
        function K:Hide() goTo(false) end
        function K:Switch() goTo(not isP) end
        function K:IsOpen() return isP end
        function K:SetTitle(t)
            tl.Text = tostring(t)
            vtxt.Text = string.upper(tostring(t))
        end
        function K:SetSubtitle(t)
            local s = (t == nil) and "" or tostring(t)
            sl.Text = s
            layoutHead(s ~= "")
        end
        function K:SetVisible(v) holder.Visible = v and true or false end
        function K:SetWidth(w) setWidth(w) end
        -- kompatibilitas dengan panel lama (resize di layar sudah tidak ada)
        function K:SetSize(w) if w then setWidth(w) end end
        function K:SetHeight() end
        function K:GetSize() return W, holder.AbsoluteSize.Y / math.max(rootScale.Scale, 0.01) end
        function K:ResetSize() setWidth(tonumber(o.Width) or 300) end
        function K:SetResizable() end
        function K:Destroy()
            if destroyed then return end
            destroyed = true
            stopLoop()
            for i = 1, #ploops do pcall(function() ploops[i]:Cancel() end) end
            holder:Destroy()
        end
        holder.Destroying:Connect(stopLoop)
        cleanups[#cleanups + 1] = function() K:Destroy() end

        if o.Open then
            isP, prog, target = true, 1, 1
            task.delay(0.3, function() if isP and scroll.Parent then entrance(scroll) end end)
        else
            setPLoops(false)
        end
        apply(true)

        return K
    end

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
        local scroll = createTab(c.Title or "Tab", false, c.Icon, c.Group)
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
