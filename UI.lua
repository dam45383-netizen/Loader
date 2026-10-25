--[[ SORU HUB v7.0 - Cartoon Classic
     Kertas krem, outline tinta tebal, bayangan keras, tombol "ditekan" ke bawah, animasi memantul.
     Tanpa gradient & tanpa gambar bayangan = ringan. API sama dengan v6.1. ]]
local SORU = {Version = "7.0"}
local Players, TweenService, UIS, RunService = game:GetService("Players"), game:GetService("TweenService"), game:GetService("UserInputService"), game:GetService("RunService")
local Market, Http, Stats, TextService = game:GetService("MarketplaceService"), game:GetService("HttpService"), game:GetService("Stats"), game:GetService("TextService")
local GuiService, TeleportService, LocalizationService = game:GetService("GuiService"), game:GetService("TeleportService"), game:GetService("LocalizationService")

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

SORU.Icons = {
    home = "home", player = "rbxassetid://12120698352", user = "rbxassetid://108483430622128", settings = "rbxassetid://70386228443175",
    sword = "rbxassetid://82472368671405", gamepad = "rbxassetid://84173963561612", crosshair = "rbxassetid://12614416478",
    stat = "rbxassetid://12094445329", eyes = "rbxassetid://14321059114", shop = "rbxassetid://4985385964", star = "rbxassetid://107005941750079",
    fish = "rbxassetid://97167558235554", discord = "rbxassetid://94434236999817", gps = "rbxassetid://17824309485",
    boss = "rbxassetid://13132186360", loop = "rbxassetid://122032243989747",
}

----------------------------------------------------------------------
-- THEME: kertas krem + tinta cokelat tua. Aksen bisa diganti (44 preset)
----------------------------------------------------------------------
local T = {
    bg = Color3.fromRGB(255, 244, 214), side = Color3.fromRGB(253, 230, 172), card = Color3.fromRGB(255, 252, 242),
    hover = Color3.fromRGB(255, 237, 190), ink = Color3.fromRGB(58, 38, 42), text = Color3.fromRGB(58, 38, 42),
    dim = Color3.fromRGB(128, 100, 88), off = Color3.fromRGB(228, 210, 175), input = Color3.fromRGB(255, 255, 250),
    ok = Color3.fromRGB(46, 170, 90), warn = Color3.fromRGB(226, 146, 12), bad = Color3.fromRGB(222, 66, 66),
    accent = Color3.fromRGB(145, 96, 255), accent2 = Color3.fromRGB(94, 106, 255),
}
local WHITE, BACK, R = Color3.new(1, 1, 1), Enum.EasingStyle.Back, 10
local XL, XC, XR = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right
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
    "Violet 9160FF 5E6AFF", "Ocean 28A0FF 3870FF", "Crimson FF4664 DC2650", "Emerald 2DD496 10AA78", "Sunset FF963C F0465A",
    "Rose FF6996 E63C78", "Sakura FF96BE DC6ED2", "Mint 50E6BE 28BEAA", "Aqua 1ED2E6 2896EB", "Ice 82C8FF 648CFF",
    "Midnight 5A6EFF 3C46C8", "Gold FABE28 EB8C1E", "Lava FF5F32 E12D2D", "Toxic A0F028 5AC83C", "Cyber FF28C8 8C3CFF",
    "Orchid D26EFF A050E6", "Forest 50BE64 288C5A", "Coffee D29664 AA6E46", "Peach FFA078 F56E64", "Steel 7896BE 506EA0",
    "Mono BEC2D6 787EA0", "Ruby E0314B B3203F", "Coral FF6F61 F2496B", "Amber FFB000 E08700", "Lime B6F03C 7CCB2B",
    "Jade 2FBF8F 1F8F6B", "Teal 14B8A6 0E8F83", "Cobalt 3D6BFF 2447D6", "Indigo 6366F1 4338CA", "Grape 9B4DE0 6A2FB8",
    "Lavender B49CFF 8E78E6", "Bubblegum FF7EC8 E255A8", "HotPink FF2E93 D6106F", "Synthwave FF2E97 7B2FF7", "Vaporwave FF71CE B967FF",
    "Tokyo F72585 7209B7", "Dracula BD93F9 6272A4", "Nord 88C0D0 5E81AC", "Mocha CBA6F7 89B4FA", "Matrix 00FF66 00B347",
    "Aurora 4DE8B0 5C7CFA", "Nebula 7B5CFF 4A2FBF", "Cyan 00D8FF 0094E0", "Ember FF7A18 E0401C",
}) do SORU.AddTheme(s:match("(%S+)%s+(%x+)%s+(%x+)")) end

-- elemen berwarna aksen didaftarkan di sini; ganti tema = tulis ulang semuanya
local skins, themeFns, transList = {}, {}, {}
local curTrans, NOANIM = 0, false
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
local function regT(o, off)
    transList[#transList + 1] = {o, off or 0}
    o.BackgroundTransparency = math.clamp(curTrans + (off or 0), 0, 1)
end
local function applyTrans(t)
    curTrans = math.clamp(t, 0, 0.7)
    for i = #transList, 1, -1 do
        local e = transList[i]
        if e[1].Parent then e[1].BackgroundTransparency = math.clamp(curTrans + e[2], 0, 1) else table.remove(transList, i) end
    end
end

----------------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------------
local NUN = "rbxasset://fonts/families/Nunito.json"
-- W: 1 = isi (Nunito medium), 2 = label (Nunito bold), 3 = judul kartun (Fredoka One)
local FONT = {Font.new(NUN, Enum.FontWeight.Medium), Font.new(NUN, Enum.FontWeight.Bold), Font.fromEnum(Enum.Font.FredokaOne)}
local MONO = Font.new("rbxasset://fonts/families/RobotoMono.json")

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return new("UICorner", {CornerRadius = (r == "full") and UDim.new(1, 0) or UDim.new(0, r or 8)}, o) end
local function stroke(o, col, th, tr)
    return new("UIStroke", {Color = col or T.ink, Thickness = th or 2, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
end
-- instance + corner + outline tinta sekaligus
local function mk(class, props, parent, r, st)
    local o = new(class, props, parent)
    if r then corner(o, r) end
    if st then stroke(o, T.ink, st) end
    return o
end
-- bayangan keras: kotak tinta bergeser, dibuat SEBELUM elemen yang dibayangi
local function hardShadow(parent, r, off, size)
    return mk("Frame", {Name = "Shadow", Position = UDim2.fromOffset(off, off), Size = size or UDim2.new(1, -6, 1, -6), BackgroundColor3 = T.ink, BorderSizePixel = 0}, parent, r)
end
-- body kartun + bayangan di dalam holder (body = holder - 6px)
local function sticker(parent, r, st, bg, class)
    hardShadow(parent, r, 4)
    return mk(class or "Frame", {Name = "Body", Size = UDim2.new(1, -6, 1, -6), BackgroundColor3 = bg or T.card, BorderSizePixel = 0}, parent, r, st or 2)
end
local function text(parent, p)
    local d = {BackgroundTransparency = 1, BorderSizePixel = 0, FontFace = FONT[2], TextSize = 13, TextColor3 = T.text, TextXAlignment = XL, TextTruncate = Enum.TextTruncate.AtEnd}
    for k, v in pairs(p) do
        if k == "W" then d.FontFace = FONT[v] elseif k == "Mono" then d.FontFace = MONO else d[k] = v end
    end
    return new("TextLabel", d, parent)
end
local function play(o, p, t, style, dir)
    if NOANIM then for k, v in pairs(p) do o[k] = v end return end
    TweenService:Create(o, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), p):Play()
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
    local ok, v = pcall(function() return TextService:GetTextSize(tostring(s), size, Enum.Font.FredokaOne, Vector2.new(1000, 100)).X end)
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

-- judul + deskripsi di sisi kiri kartu (h = tinggi holder, tinggi isi = h - 6)
local function rowText(f, title, desc, rpad, h, ws)
    local w = ws or 1
    local t = text(f, {Text = tostring(title), Position = UDim2.fromOffset(14, desc and 7 or 0), Size = UDim2.new(w, -(14 + rpad), 0, desc and 20 or (h - 6)), W = 3})
    local d = desc and text(f, {Text = tostring(desc), Position = UDim2.fromOffset(14, 27), Size = UDim2.new(w, -(14 + rpad), 0, 16), TextSize = 11, TextColor3 = T.dim, W = 1})
    return t, d
end

-- kotak input: outline tinta, terisi aksen tipis saat fokus
local function inputBox(parent, p)
    local wrap = mk("Frame", {BackgroundColor3 = T.input, BorderSizePixel = 0, ClipsDescendants = true}, parent, 8, 2)
    for k, v in pairs(p.wrap or {}) do wrap[k] = v end
    local box = new("TextBox", {Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Text = p.text or "", PlaceholderText = p.placeholder or "", PlaceholderColor3 = T.dim, TextColor3 = T.text, FontFace = FONT[2], TextSize = 12, TextXAlignment = XL, ClearTextOnFocus = p.clear or false}, wrap)
    box.Focused:Connect(function() play(wrap, {BackgroundColor3 = T.input:Lerp(T.accent, 0.25)}, 0.15) end)
    box.FocusLost:Connect(function() play(wrap, {BackgroundColor3 = T.input}, 0.2) end)
    return wrap, box
end

-- ikon tab: "home" (digambar) | gambar (rbxassetid / id angka) | huruf / simbol
local function tabIcon(b, icon, name)
    local box = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1}, b)
    local ic = icon and (SORU.Icons[icon] or tostring(icon)) or nil
    if ic == "home" then
        local parts = {}
        for _, d in ipairs({{11, 11, -3, 45}, {13, 8, 4, 0}}) do
            parts[#parts + 1] = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, d[3]), Size = UDim2.fromOffset(d[1], d[2]), Rotation = d[4], BackgroundColor3 = T.dim, BorderSizePixel = 0}, box, 2)
        end
        return function(c) for _, f in ipairs(parts) do f.BackgroundColor3 = c end end
    elseif ic and (ic:match("^rbxasset") or ic:match("^%d%d%d+$")) then
        local img = new("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = ic:match("^%d+$") and ("rbxassetid://" .. ic) or ic, ImageColor3 = T.dim}, box)
        return function(c) img.ImageColor3 = c end
    end
    local gl = text(box, {Text = ic or string.upper(string.sub(name, 1, 1)), Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 16, TextColor3 = T.dim, TextTruncate = NOTRUNC})
    return function(c) gl.TextColor3 = c end
end

----------------------------------------------------------------------
-- DRAWER: dropdown = panel geser di sisi kanan window (satu per host, dibuat saat pertama dipakai)
----------------------------------------------------------------------
local function makeDrawer(host, rad)
    local D, spec, rows = {}, nil, {}
    local ov = mk("TextButton", {Name = "Drawer", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ClipsDescendants = true, ZIndex = 500, BorderSizePixel = 0}, host, rad)
    local dr = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 280, 0.5, 0), Size = UDim2.new(0.62, 0, 1, -24), BackgroundTransparency = 1, Active = true}, ov)
    new("UISizeConstraint", {MinSize = Vector2.new(196, 0), MaxSize = Vector2.new(240, 4000)}, dr)
    local bd = sticker(dr, 12, 3, T.side)
    local title = text(bd, {Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -110, 0, 22), W = 3, TextSize = 16})
    local count = text(bd, {Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -110, 0, 14), TextSize = 11, TextColor3 = T.dim, W = 1})
    local function sbtn(x, txt, w)
        local b = mk("TextButton", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 10), Size = UDim2.fromOffset(w, 26), BackgroundColor3 = T.card, Text = txt, FontFace = FONT[3], TextSize = 12, TextColor3 = T.ink, AutoButtonColor = false, BorderSizePixel = 0}, bd, 8, 2)
        b.MouseEnter:Connect(function() play(b, {BackgroundColor3 = T.hover}, 0.12) end)
        b.MouseLeave:Connect(function() play(b, {BackgroundColor3 = T.card}, 0.15) end)
        return b
    end
    local closeB, clearB = sbtn(-12, "X", 26), sbtn(-46, "Clear", 52)
    local sw, box = inputBox(bd, {placeholder = "Search...", wrap = {Position = UDim2.fromOffset(12, 52), Size = UDim2.new(1, -24, 0, 30)}})
    local list = new("ScrollingFrame", {Position = UDim2.fromOffset(8, 92), Size = UDim2.new(1, -16, 1, -100), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = T.ink, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, bd)
    new("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, list)
    new("UIPadding", {PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6)}, list)

    local function repaint()
        for _, r in ipairs(rows) do r.paint() end
        if spec and spec.count then count.Text = spec.count() .. " selected" end
    end
    function D.close()
        if not ov.Visible then return end
        local sp = spec
        spec = nil
        play(ov, {BackgroundTransparency = 1}, 0.2)
        play(dr, {Position = UDim2.new(1, 280, 0.5, 0)}, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(NOANIM and 0 or 0.26, function() if not spec then ov.Visible = false end end)
        if sp and sp.onClose then safe(sp.onClose) end
    end
    function D.open(sp)
        if spec and spec.onClose then safe(spec.onClose) end
        spec = sp
        title.Text = tostring(sp.title)
        count.Text = sp.count and (sp.count() .. " selected") or (#sp.options .. " options")
        clearB.Visible, sw.Visible, box.Text = sp.clear ~= nil, sp.search, ""
        list.Position = UDim2.fromOffset(8, sp.search and 92 or 56)
        list.Size = UDim2.new(1, -16, 1, sp.search and -100 or -64)
        list.CanvasPosition = Vector2.new(0, 0)
        for _, r in ipairs(rows) do r.btn:Destroy() end
        rows = {}
        for i, n in ipairs(sp.options) do
            local name = tostring(n)
            local b = mk("TextButton", {Size = UDim2.new(1, -10, 0, 32), BackgroundColor3 = T.hover, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i}, list, 8)
            local rs = stroke(b, T.ink, 2, 1)
            local tx, sc = 12, sp.swatch and sp.swatch(name)
            if sc then
                mk("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = sc, BorderSizePixel = 0}, b, "full", 2)
                tx = 32
            end
            text(b, {Text = name, Position = UDim2.fromOffset(tx, 0), Size = UDim2.new(1, -(tx + 26), 1, 0), TextSize = 12, W = 3})
            local ck = mk("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = T.ink, BackgroundTransparency = 1, BorderSizePixel = 0}, b, "full")
            local r = {btn = b, name = name}
            function r.paint()
                local on = sp.isSel(name)
                b.BackgroundColor3 = on and T.accent or T.hover
                b.BackgroundTransparency = on and 0 or 1
                rs.Transparency, ck.BackgroundTransparency = on and 0 or 1, on and 0 or 1
            end
            b.MouseEnter:Connect(function() if not sp.isSel(name) then b.BackgroundTransparency = 0.3 end end)
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
        play(ov, {BackgroundTransparency = 0.45}, 0.2)
        dr.Position = UDim2.new(1, 280, 0.5, 0)
        play(dr, {Position = UDim2.new(1, -8, 0.5, 0)}, 0.34, BACK)
    end
    box:GetPropertyChangedSignal("Text"):Connect(function()
        local q = box.Text:lower()
        for _, r in ipairs(rows) do r.btn.Visible = (q == "") or (r.name:lower():find(q, 1, true) ~= nil) end
    end)
    clearB.MouseButton1Click:Connect(function() if spec and spec.clear then spec.clear() repaint() end end)
    closeB.MouseButton1Click:Connect(D.close)
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
    skins, themeFns, transList = {}, {}, {}
    local pl = Players.LocalPlayer
    local pg = pl:WaitForChild("PlayerGui")
    local host = pg
    pcall(function() if gethui then host = gethui() end end)
    for _, h in ipairs({host, pg}) do
        local old = h:FindFirstChild("SORU_HUB")
        if old then old:Destroy() end
    end
    local gui = new("ScreenGui", {Name = "SORU_HUB", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 100})
    gui.Parent = host

    local conns = {}
    local function bind(sig, fn) local c = sig:Connect(fn) conns[#conns + 1] = c return c end
    gui.Destroying:Connect(function() for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end end)

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
    local curTheme = (type(F.UITheme) == "string" and THEMES[F.UITheme]) and F.UITheme or "Violet"
    applyTheme(curTheme)
    curTrans = (type(F.UITrans) == "number") and F.UITrans or 0
    local toggleKey = C.ToggleKey or Enum.KeyCode.RightShift
    if type(F.MenuKey) == "string" then toggleKey = toKey(F.MenuKey) or toggleKey end
    local binding, activeStop = false, nil

    local gameName, nameBinds = "Unknown", {}
    local function bindName(fn) nameBinds[#nameBinds + 1] = fn fn(gameName) end
    task.spawn(function()
        local ok, info = pcall(function() return Market:GetProductInfo(placeId) end)
        if ok and info and info.Name then
            gameName = info.Name
            for _, fn in ipairs(nameBinds) do pcall(fn, gameName) end
        end
    end)

    ------------------------------------------------------------------
    -- ROOT + SKALA (anti-DPI)
    ------------------------------------------------------------------
    local REF = C.ReferenceSize or Vector2.new(1280, 720)
    local root = new("Frame", {Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)
    local rootScale = new("UIScale", {}, root)
    local DEFAULT, MINS, MAXS = Vector2.new(700, 440), Vector2.new(520, 340), Vector2.new(980, 640)
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

    ------------------------------------------------------------------
    -- TOAST (kanan bawah, maksimal 5, klik untuk menutup)
    ------------------------------------------------------------------
    local toastHolder = new("Frame", {Name = "Toasts", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.new(0, 300, 1, -28), BackgroundTransparency = 1, ZIndex = 200}, root)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom}, toastHolder)
    local toasts, toastN = {}, 0
    local function notify(title, msg, color, dur)
        color, dur = color or T.accent, dur or 3
        toastN = toastN + 1
        local glyph = (color == T.ok and "✓") or (color == T.bad and "✕") or (color == T.warn and "!") or "i"
        local wrap = new("Frame", {Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, LayoutOrder = toastN}, toastHolder)
        local m = new("Frame", {Position = UDim2.fromOffset(340, 0), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, wrap)
        local f = sticker(m, 12, 2)
        local ic = mk("Frame", {Position = UDim2.fromOffset(10, 11), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = color, BorderSizePixel = 0}, f, "full", 2)
        text(ic, {Text = glyph, Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 2, TextSize = 16, TextTruncate = NOTRUNC})
        text(f, {Text = tostring(title or ""), Position = UDim2.fromOffset(52, 6), Size = UDim2.new(1, -62, 0, 18), W = 3, TextSize = 13})
        text(f, {Text = tostring(msg or ""), Position = UDim2.fromOffset(52, 24), Size = UDim2.new(1, -62, 0, 22), TextSize = 11, W = 1, TextColor3 = T.dim, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top})
        local pb = mk("Frame", {Position = UDim2.new(0, 12, 1, -12), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = T.off, BorderSizePixel = 0}, f, "full", 1.5)
        local pr = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0}, pb, "full")
        local gone, entry = false, {}
        local function leave()
            if gone then return end
            gone = true
            for i, e in ipairs(toasts) do if e == entry then table.remove(toasts, i) break end end
            play(m, {Position = UDim2.fromOffset(340, 0)}, 0.25, BACK, Enum.EasingDirection.In)
            task.delay(NOANIM and 0 or 0.28, function() wrap:Destroy() end)
        end
        entry.leave = leave
        toasts[#toasts + 1] = entry
        if #toasts > 5 then task.spawn(toasts[1].leave) end
        new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5}, f).MouseButton1Click:Connect(leave)
        play(m, {Position = UDim2.fromOffset(0, 0)}, 0.45, BACK)
        play(pr, {Size = UDim2.new(0, 0, 1, 0)}, dur, Enum.EasingStyle.Linear)
        task.delay(dur, leave)
    end

    ------------------------------------------------------------------
    -- SHELL + WINDOW + HEADER
    ------------------------------------------------------------------
    local shell = new("Frame", {Name = "Shell", BackgroundTransparency = 1, Visible = false}, root)
    local wsh = hardShadow(shell, 14, 7, UDim2.fromScale(1, 1))
    local win = mk("Frame", {Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg, BorderSizePixel = 0, ClipsDescendants = true, Active = true}, shell, 14, 3)
    regT(win, 0)
    local winScale = new("UIScale", {Scale = 1}, win)
    local ctxWin = newCtx(win, 14)

    layoutWin = function(animate)
        local sz = Vector2.new(math.min(winSize.X, virt.X - 20), math.min(winSize.Y, virt.Y - 20))
        local x, y
        if winPos then x, y = winPos.X, winPos.Y else x, y = (virt.X - sz.X) / 2, (virt.Y - sz.Y) / 2 end
        x = math.clamp(x, 10, math.max(10, virt.X - sz.X - 10))
        y = math.clamp(y, 10, math.max(10, virt.Y - sz.Y - 10))
        if winPos then winPos = Vector2.new(x, y) end
        curPos = Vector2.new(x, y)
        shell.Size = UDim2.fromOffset(sz.X, sz.Y)
        if animate then play(shell, {Position = UDim2.fromOffset(x, y)}, 0.3) else shell.Position = UDim2.fromOffset(x, y) end
    end

    local HDR = 42
    local TOP = HDR + 3
    local hd = mk("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, HDR), BorderSizePixel = 0, Active = true}, win, 14)
    skin(hd, "BackgroundColor3", "accent")
    skin(new("Frame", {Position = UDim2.fromOffset(0, HDR - 14), Size = UDim2.new(1, 0, 0, 14), BorderSizePixel = 0}, hd), "BackgroundColor3", "accent")
    new("Frame", {Position = UDim2.fromOffset(0, HDR), Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = T.ink, BorderSizePixel = 0, ZIndex = 2}, win)

    local logo = mk("Frame", {Position = UDim2.fromOffset(10, 7), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = T.card, BorderSizePixel = 0}, hd, "full", 2)
    if ICON ~= "" then
        new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78), BackgroundTransparency = 1, Image = ICON, ScaleType = Enum.ScaleType.Fit}, logo)
    else
        text(logo, {Text = "S", Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 17})
    end
    local titleText = tostring(C.Title or "SORU HUB")
    text(hd, {Text = titleText, Position = UDim2.fromOffset(46, 3), Size = UDim2.fromOffset(math.ceil(textW(titleText, 17)) + 8, 20), W = 3, TextSize = 17, TextColor3 = WHITE, TextStrokeColor3 = T.ink, TextStrokeTransparency = 0, TextTruncate = NOTRUNC})
    local subL = text(hd, {Text = C.Subtitle and tostring(C.Subtitle) or ("v" .. VERSION), Position = UDim2.fromOffset(46, 24), Size = UDim2.new(1, -330, 0, 13), TextSize = 10})
    if not C.Subtitle then
        bindName(function(n) subL.Text = (n == "Unknown") and ("v" .. VERSION) or ("v" .. VERSION .. "  •  " .. n) end)
    end

    local function hbtn(x, glyph)
        local b = mk("TextButton", {Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, x, 0.5, -13), BackgroundColor3 = T.card, Text = glyph or "", FontFace = FONT[3], TextSize = 13, TextColor3 = T.ink, AutoButtonColor = false, BorderSizePixel = 0}, hd, "full", 2)
        b.MouseEnter:Connect(function() play(b, {BackgroundColor3 = T.hover}, 0.12) end)
        b.MouseLeave:Connect(function() play(b, {BackgroundColor3 = T.card, TextColor3 = T.ink}, 0.15) end)
        return b
    end
    local xB, maxB, minB = hbtn(-38, "X"), hbtn(-68), hbtn(-98, "–")
    xB.MouseEnter:Connect(function() play(xB, {BackgroundColor3 = T.bad, TextColor3 = WHITE}, 0.12) end)
    stroke(new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(9, 9), BackgroundTransparency = 1}, maxB), T.ink, 2, 0)

    local chip = mk("Frame", {Size = UDim2.fromOffset(130, 26), Position = UDim2.new(1, -236, 0.5, -13), BackgroundColor3 = T.card, BorderSizePixel = 0}, hd, "full", 2)
    local cdot = mk("Frame", {Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = T.ok, BorderSizePixel = 0}, chip, "full", 1.5)
    local chipL = text(chip, {Text = "-- fps", Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -30, 1, 0), W = 3, TextSize = 11})

    ------------------------------------------------------------------
    -- SIDEBAR + CONTENT
    ------------------------------------------------------------------
    local SIDE_W, FOOT_H, TAB_H = 164, 58, 36
    local bar = new("Frame", {Name = "Sidebar", Position = UDim2.fromOffset(0, TOP), Size = UDim2.new(0, SIDE_W, 1, -TOP), BackgroundColor3 = T.side, BorderSizePixel = 0}, win)
    new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = T.ink, BorderSizePixel = 0}, bar)
    local tabList = new("ScrollingFrame", {Size = UDim2.new(1, -3, 1, -FOOT_H), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y}, bar)
    local pill = mk("Frame", {Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -22, 0, TAB_H), BorderSizePixel = 0, Visible = false}, tabList, 10, 2)
    skin(pill, "BackgroundColor3", "accent")

    do -- footer sidebar: avatar + nama
        new("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, -1, 1, -FOOT_H), Size = UDim2.new(1, -22, 0, 2), BackgroundColor3 = T.ink, BackgroundTransparency = 0.6, BorderSizePixel = 0}, bar)
        local av = mk("ImageLabel", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -10), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = T.off, BorderSizePixel = 0}, bar, "full", 2)
        mk("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 36, 1, -8), Size = UDim2.fromOffset(11, 11), BackgroundColor3 = T.ok, BorderSizePixel = 0}, bar, "full", 2)
        text(bar, {Text = pl.DisplayName, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 54, 1, -26), Size = UDim2.new(1, -62, 0, 16), W = 3, TextSize = 12})
        text(bar, {Text = "Online  •  v" .. VERSION, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 54, 1, -11), Size = UDim2.new(1, -62, 0, 14), TextSize = 10, TextColor3 = T.dim, W = 1})
        task.spawn(function()
            local ok, img = pcall(function() return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
            if ok and av.Parent then av.Image = img end
        end)
    end

    local CONT_X = SIDE_W + 10
    local content = new("Frame", {Position = UDim2.fromOffset(CONT_X, TOP + 8), Size = UDim2.new(1, -(CONT_X + 6), 1, -(TOP + 14)), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true}, win)

    local rh = new("Frame", {Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -28, 1, -28), BackgroundTransparency = 1, Active = true, ZIndex = 30}, win)
    local rhL = text(rh, {Text = "⋰", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(-4, -2), TextXAlignment = XR, TextYAlignment = Enum.TextYAlignment.Bottom, W = 2, TextSize = 18, TextColor3 = T.dim})
    rh.MouseEnter:Connect(function() play(rhL, {TextColor3 = T.ink}, 0.15) end)
    rh.MouseLeave:Connect(function() play(rhL, {TextColor3 = T.dim}, 0.2) end)

    ------------------------------------------------------------------
    -- OPEN / CLOSE + LAUNCHER + DRAG / RESIZE
    ------------------------------------------------------------------
    local isOpen = false
    local function openA()
        if isOpen then return end
        isOpen = true
        layoutWin()
        shell.Visible = true
        winScale.Scale, wsh.BackgroundTransparency = 0.88, 1
        play(winScale, {Scale = 1}, 0.45, BACK)
        play(wsh, {BackgroundTransparency = 0}, 0.3)
    end
    local function closeA()
        if not isOpen then return end
        isOpen = false
        if ctxWin.d then ctxWin.d.close() end
        if NOANIM then shell.Visible = false return end
        play(winScale, {Scale = 0.88}, 0.2, BACK, Enum.EasingDirection.In)
        play(wsh, {BackgroundTransparency = 1}, 0.15)
        task.delay(0.2, function() if not isOpen then shell.Visible = false end end)
    end
    local function toggleWin() if isOpen then closeA() else openA() end end

    local LAUNCH, launchPos = 48, nil
    local launcher = new("Frame", {Name = "Launcher", Size = UDim2.fromOffset(LAUNCH + 5, LAUNCH + 5), BackgroundTransparency = 1, Active = true, ZIndex = 90}, root)
    hardShadow(launcher, 16, 4, UDim2.fromOffset(LAUNCH, LAUNCH))
    local lbody = mk("Frame", {Size = UDim2.fromOffset(LAUNCH, LAUNCH), BorderSizePixel = 0}, launcher, 16, 3)
    skin(lbody, "BackgroundColor3", "accent")
    if ICON ~= "" then
        new("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, Image = ICON}, lbody)
    else
        text(lbody, {Text = "S", Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 22, TextColor3 = WHITE, TextStrokeColor3 = T.ink, TextStrokeTransparency = 0})
    end
    layoutLauncher = function()
        if not launchPos then launchPos = Vector2.new(14, math.floor(virt.Y / 2 - LAUNCH / 2)) end
        launchPos = Vector2.new(math.clamp(launchPos.X, 4, math.max(4, virt.X - LAUNCH - 8)), math.clamp(launchPos.Y, 4, math.max(4, virt.Y - LAUNCH - 8)))
        launcher.Position = UDim2.fromOffset(launchPos.X, launchPos.Y)
    end
    launcher.MouseEnter:Connect(function() play(lbody, {Position = UDim2.fromOffset(-1, -2)}, 0.15, BACK) end)
    launcher.MouseLeave:Connect(function() play(lbody, {Position = UDim2.fromOffset(0, 0)}, 0.2) end)
    track(launcher,
        function() play(lbody, {Position = UDim2.fromOffset(3, 3)}, 0.06) return launchPos end,
        function(dx, dy, st, moved)
            if moved and st then
                launchPos = Vector2.new(st.X + dx / rootScale.Scale, st.Y + dy / rootScale.Scale)
                layoutLauncher()
            end
        end,
        function(moved)
            play(lbody, {Position = UDim2.fromOffset(0, 0)}, 0.3, BACK)
            if not moved then toggleWin() end
        end)
    track(hd,
        function() winPos = curPos return curPos end,
        function(dx, dy, st, moved)
            if moved and st then
                winPos = Vector2.new(st.X + dx / rootScale.Scale, st.Y + dy / rootScale.Scale)
                layoutWin()
            end
        end)
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
            if moved then F.UIW, F.UIH = math.floor(winSize.X), math.floor(winSize.Y) persist() end
        end)

    ------------------------------------------------------------------
    -- TAB SYSTEM
    ------------------------------------------------------------------
    local Window = {Tabs = {}, Flags = Reg, Gui = gui, PlaceId = placeId, GameId = gameId}
    local tabs = Window.Tabs
    local cur, tabN = nil, 0

    local function paintTab(t)
        t.label.TextColor3 = t.on and T.ink or T.dim
        t.setIc(t.on and T.ink or T.dim)
    end
    local function switchTab(n)
        local ne = tabs[n]
        if not ne or cur == n then return end
        local old = tabs[cur]
        if old then
            old.on = false
            old.page.Visible = false
            paintTab(old)
        end
        cur, ne.on, ne.page.Visible = n, true, true
        paintTab(ne)
        ne.page.Position = UDim2.fromOffset(0, 16)
        play(ne.page, {Position = UDim2.fromOffset(0, 0)}, 0.35, BACK)
        pill.Visible = true
        play(pill, {Position = UDim2.fromOffset(10, ne.y)}, 0.35, BACK)
    end

    local function createTab(name, icon)
        tabN = tabN + 1
        local y = 8 + (tabN - 1) * (TAB_H + 6)
        local b = mk("TextButton", {Name = name, Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, -22, 0, TAB_H), BackgroundColor3 = T.hover, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0}, tabList, 10)
        local setIc = tabIcon(b, icon, name)
        local lb = text(b, {Text = name, Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -44, 1, 0), W = 3, TextColor3 = T.dim})
        tabList.CanvasSize = UDim2.fromOffset(0, y + TAB_H + 12)

        local page = new("ScrollingFrame", {Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = T.ink, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false}, content)
        new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, page)
        new("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12)}, page)
        local th = new("Frame", {Name = "Title", Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, LayoutOrder = -1}, page)
        text(th, {Text = name, Size = UDim2.new(1, 0, 0, 34), W = 3, TextSize = 28})
        skin(mk("Frame", {Position = UDim2.fromOffset(2, 37), Size = UDim2.fromOffset(44, 7), BorderSizePixel = 0}, th, "full", 2), "BackgroundColor3", "accent")

        local t = {name = name, btn = b, page = page, y = y, on = false, label = lb, setIc = setIc}
        tabs[name] = t
        b.MouseEnter:Connect(function() if not t.on then play(b, {BackgroundTransparency = 0.3}, 0.12) lb.TextColor3 = T.ink end end)
        b.MouseLeave:Connect(function() play(b, {BackgroundTransparency = 1}, 0.15) if not t.on then lb.TextColor3 = T.dim end end)
        b.MouseButton1Click:Connect(function() switchTab(name) end)
        paintTab(t)
        if tabN == 1 then
            pill.Position = UDim2.fromOffset(10, y)
            switchTab(name)
        end
        return page
    end

    ------------------------------------------------------------------
    -- KOMPONEN
    ------------------------------------------------------------------
    local function buildComponents(scroll, container, nested, ctx)
        container = container or scroll
        local K = {}
        local order, count = 0, 0
        local CH, CD = nested and 42 or 44, nested and 54 or 56 -- tinggi holder: satu baris / dengan deskripsi

        local function holder(h, deco)
            order = order + 1
            local hf = new("Frame", {Name = "Holder", Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = order}, K._cur or container)
            if not deco then
                count = count + 1
                if K._badge then K._badge.Text = tostring(count) end
            end
            return hf
        end

        -- kartu dasar: outline tinta + bayangan keras. Kartu yang bisa diklik "turun" saat ditekan
        local function card(h, clickable)
            local hf = holder(h)
            local f = sticker(hf, R, 2, T.card, clickable and "TextButton" or "Frame")
            if clickable then f.Text, f.AutoButtonColor = "", false end
            local fx, hov, act = {}, false, false
            local function paint()
                play(f, {BackgroundColor3 = act and T.card:Lerp(T.accent, 0.28) or (hov and T.hover or T.card)}, 0.15)
            end
            function fx.hover(v) hov = v paint() end
            function fx.active(v) act = v paint() end
            themeFns[#themeFns + 1] = paint
            if clickable then
                f.MouseEnter:Connect(function() fx.hover(true) end)
                f.MouseLeave:Connect(function() fx.hover(false) play(f, {Position = UDim2.fromOffset(0, 0)}, 0.1) end)
                f.MouseButton1Down:Connect(function() play(f, {Position = UDim2.fromOffset(3, 3)}, 0.06) end)
                f.MouseButton1Up:Connect(function() play(f, {Position = UDim2.fromOffset(0, 0)}, 0.25, BACK) end)
            end
            return f, hf, fx
        end
        K._card = card

        ----------------------------------------------------------------
        -- SECTION / DIVIDER / LABEL / PARAGRAPH / INFO
        ----------------------------------------------------------------
        function K:Section(t)
            if type(t) == "table" then t = t.Title or t.Name or t.Text end
            t = string.upper(tostring(t or ""))
            local hf = holder(28, true)
            stroke(skin(new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(10, 10), Rotation = 45, BorderSizePixel = 0}, hf), "BackgroundColor3", "accent"), T.ink, 2)
            local w = math.ceil(textW(t, 12))
            text(hf, {Text = t, Position = UDim2.fromOffset(26, 0), Size = UDim2.fromOffset(w + 8, 28), W = 3, TextSize = 12, TextTruncate = NOTRUNC})
            new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 26 + w + 16, 0.5, 0), Size = UDim2.new(1, -(26 + w + 24), 0, 2), BackgroundColor3 = T.ink, BackgroundTransparency = 0.7, BorderSizePixel = 0}, hf)
        end

        function K:Divider()
            new("Frame", {Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.new(1, -12, 0, 2), BackgroundColor3 = T.ink, BackgroundTransparency = 0.75, BorderSizePixel = 0}, holder(12, true))
        end

        function K:Label(t)
            if type(t) == "table" then t = t.Text or t.Title or t.Name end
            local hf = holder(0, true)
            hf.AutomaticSize = Enum.AutomaticSize.Y
            local l = text(hf, {Text = tostring(t or ""), Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 12, TextColor3 = T.dim, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = NOTRUNC})
            return {Set = function(_, s) l.Text = tostring(s) end}
        end

        function K:Paragraph(o)
            o = o or {}
            local hf = holder(0)
            hf.AutomaticSize = Enum.AutomaticSize.Y
            new("UIPadding", {PaddingBottom = UDim.new(0, 6)}, hf)
            hardShadow(hf, R, 4, UDim2.new(1, -6, 1, 0))
            local f = mk("Frame", {Name = "Body", Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.card, BorderSizePixel = 0}, hf, R, 2)
            new("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 12)}, f)
            new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, f)
            skin(mk("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -12, 0.5, 0), Size = UDim2.new(0, 5, 0.6, 0), BorderSizePixel = 0}, f, "full", 1.5), "BackgroundColor3", "accent")
            local t = text(f, {Text = tostring(o.Title or o.Name or ""), Size = UDim2.new(1, 0, 0, 20), W = 3, LayoutOrder = 1})
            local d = text(f, {Text = tostring(o.Desc or o.Content or ""), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 11, W = 1, TextColor3 = T.dim, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = NOTRUNC, RichText = true, LayoutOrder = 2})
            return {Set = function(_, title, desc) if title then t.Text = tostring(title) end if desc then d.Text = tostring(desc) end end, SetTitle = function(_, s) t.Text = tostring(s) end, SetDesc = function(_, s) d.Text = tostring(s) end}
        end

        -- baris informasi: judul kiri, nilai kanan. Copy = true -> klik untuk menyalin nilai
        function K:Info(o)
            if type(o) ~= "table" then o = {Title = tostring(o)} end
            local clickable = (o.Copy or o.Callback) and true or false
            local f = card(CH, clickable)
            text(f, {Text = tostring(o.Title or o.Name or "Info"), Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.42, -14, 1, 0), W = 3})
            local v = text(f, {Text = tostring(o.Value or "-"), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0.58, -14, 1, 0), TextXAlignment = XR, TextSize = 12, TextColor3 = T.dim})
            if clickable then
                f.MouseButton1Click:Connect(function()
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
            local desc = o.Desc or o.SubText
            local h = desc and CD or CH
            local f = card(h, true)
            local tl, dl = rowText(f, o.Title or o.Name or "Button", desc, 54, h)
            local ar = mk("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(26, 26), BorderSizePixel = 0}, f, "full", 2)
            skin(ar, "BackgroundColor3", "accent")
            text(ar, {Text = o.Icon and tostring(o.Icon) or "›", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(1, -1), TextXAlignment = XC, W = 2, TextSize = 18, TextTruncate = NOTRUNC})
            f.MouseButton1Click:Connect(function()
                play(ar, {Size = UDim2.fromOffset(32, 32)}, 0.08)
                task.delay(0.1, function() play(ar, {Size = UDim2.fromOffset(26, 26)}, 0.3, BACK) end)
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
            local h = desc and CD or CH
            local f, _, fx = card(h, true)
            rowText(f, title, desc, 72, h)
            local sw = mk("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(46, 24), BackgroundColor3 = T.off, BorderSizePixel = 0}, f, "full", 2)
            local on = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = v and 0 or 1, BorderSizePixel = 0}, sw)
            skin(on, "BackgroundColor3", "accent")
            corner(on, "full")
            local function kpos(x) return x and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) end
            local knob = mk("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = kpos(v), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = WHITE, BorderSizePixel = 0}, sw, "full", 2)
            local obj = {Value = v}
            local function upd(nv, silent)
                v, obj.Value = nv, nv
                play(on, {BackgroundTransparency = v and 0 or 1}, 0.2)
                play(knob, {Position = kpos(v)}, 0.3, BACK)
                fx.active(v)
                F[flag] = v
                if not silent then persist() safe(o.Callback, v) end
            end
            f.MouseButton1Click:Connect(function() upd(not v) end)
            function obj:Set(nv, fire) upd(nv and true or false, not fire) end
            function obj:Get() return v end
            fx.active(v)
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
            local f, _, fx = card(nested and 58 or 62, false)
            text(f, {Text = o.Title or o.Name or flag or "Slider", Position = UDim2.fromOffset(14, 7), Size = UDim2.new(1, -96, 0, 20), W = 3})
            local chipV = mk("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(52, 20), BorderSizePixel = 0}, f, "full", 2)
            skin(chipV, "BackgroundColor3", "accent")
            local vl = text(chipV, {Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 11, TextTruncate = NOTRUNC})
            local hit = new("TextButton", {Position = UDim2.new(0, 10, 1, -30), Size = UDim2.new(1, -20, 0, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, f)
            local bar = mk("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(1, -8, 0, 10), BackgroundColor3 = T.off, BorderSizePixel = 0}, hit, "full", 2)
            local fill = mk("Frame", {Size = UDim2.fromScale(0, 1), BorderSizePixel = 0}, bar, "full")
            skin(fill, "BackgroundColor3", "accent")
            local knob = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, bar, "full", 2.5)
            local function quant(x)
                x = math.clamp(mn + math.floor((x - mn) / step + 0.5) * step, mn, mx)
                return math.floor(x * 1000 + 0.5) / 1000
            end
            local function render(x)
                local a = (mx == mn) and 0 or (x - mn) / (mx - mn)
                fill.Size = UDim2.fromScale(a, 1)
                knob.Position = UDim2.fromScale(a, 0.5)
                vl.Text = tostring(x) .. (o.Suffix or "")
                chipV.Size = UDim2.fromOffset(math.max(46, textW(vl.Text, 11) + 20), 20)
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
                local aw = bar.AbsoluteSize.X
                if aw > 0 then set(mn + (mx - mn) * math.clamp((px - bar.AbsolutePosition.X) / aw, 0, 1)) end
            end
            local function grab(g)
                play(knob, {Size = g and UDim2.fromOffset(24, 24) or UDim2.fromOffset(18, 18)}, 0.15, BACK)
                fx.active(g)
            end
            hit.MouseEnter:Connect(function() fx.hover(true) end)
            hit.MouseLeave:Connect(function() fx.hover(false) end)
            track(hit,
                function(pos) scroll.ScrollingEnabled = false grab(true) fromX(pos.X) return true end,
                function(dx, dy, st, moved, pos) fromX(pos.X) end,
                function()
                    scroll.ScrollingEnabled = true
                    grab(false)
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
            local h = desc and CD or CH
            local f, _, fx = card(h, false)
            rowText(f, title, desc, 8, h, 0.5)
            local _, box = inputBox(f, {text = val, placeholder = o.Placeholder or "Type here...", clear = o.ClearOnFocus,
                wrap = {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0.42, 0, 0, 28)}})
            box.Focused:Connect(function() fx.active(true) end)
            box.FocusLost:Connect(function() fx.active(false) end)
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
        -- DROPDOWN: klik membuka drawer di sisi kanan (search otomatis kalau opsi > 6)
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

            local h = desc and CD or CH
            local f, _, fx = card(h, true)
            local tl, dl = rowText(f, title, desc, 124, h)
            local chipD = mk("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -34, 0.5, 0), Size = UDim2.fromOffset(70, 24), BorderSizePixel = 0}, f, "full", 2)
            skin(chipD, "BackgroundColor3", "accent")
            local vl = text(chipD, {Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -12, 1, 0), TextXAlignment = XC, W = 3, TextSize = 11})
            text(f, {Text = "›", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(18, 22), TextXAlignment = XC, W = 2, TextSize = 22, TextTruncate = NOTRUNC})
            local function refresh()
                local t
                if multi then
                    local v = getVal()
                    t = (#v == 0) and "None" or ((#v <= 2) and table.concat(v, ", ") or (#v .. " selected"))
                else
                    t = single or "Select..."
                end
                vl.Text = t
                local w = math.clamp(textW(t, 11) + 24, 56, 140)
                chipD.Size = UDim2.fromOffset(w, 24)
                tl.Size = UDim2.new(1, -(14 + w + 46), 0, tl.Size.Y.Offset)
                if dl then dl.Size = UDim2.new(1, -(14 + w + 46), 0, 16) end
            end
            local function commit()
                local v = getVal()
                F[flag] = v
                persist()
                safe(o.Callback, v)
            end
            f.MouseButton1Click:Connect(function()
                fx.active(true)
                ctx.drawer().open({
                    title = title, options = opts, multi = multi, search = #opts > 6, swatch = o.Swatch, isSel = isSel,
                    pick = function(n)
                        if multi then chosen[n] = (not chosen[n]) and true or nil else single = n end
                        refresh()
                        commit()
                    end,
                    count = multi and function() return #getVal() end or nil,
                    clear = multi and function() chosen = {} refresh() commit() end or nil,
                    onClose = function() fx.active(false) end,
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
            function api:Refresh(n) opts = n or {} end
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
            local h = desc and CD or CH
            local f, _, fx = card(h, true)
            rowText(f, title, desc, 94, h)
            local cap = mk("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(60, 26), BackgroundColor3 = T.input, BorderSizePixel = 0}, f, 8, 2)
            local kl = text(cap, {Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 11, TextTruncate = NOTRUNC})
            local listening, lastCancel = false, 0
            local function show()
                local t = listening and "..." or (key and key.Name or "None")
                kl.Text = t
                cap.Size = UDim2.fromOffset(math.max(54, textW(t, 11) + 24), 26)
                play(cap, {BackgroundColor3 = listening and T.accent or T.input}, 0.15)
                fx.active(listening)
            end
            local function stop()
                listening = false
                lastCancel = os.clock()
                if activeStop == stop then activeStop = nil end
                show()
                task.delay(0.1, function() binding = false end)
            end
            show()
            f.MouseButton1Click:Connect(function()
                if listening or os.clock() - lastCancel < 0.35 then return end
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
        -- COLOR PICKER (kartu mengembang: kotak SV + hue + input hex)
        ----------------------------------------------------------------
        function K:ColorPicker(o)
            o = o or {}
            local title = o.Title or o.Name or o.Flag or "Color"
            local flag = o.Flag or title
            local col = (typeof(o.Default) == "Color3") and o.Default or T.accent
            local sv = F[flag]
            if type(sv) == "table" and #sv == 3 then col = Color3.fromRGB(sv[1], sv[2], sv[3]) end
            local hh, ss, vv = col:ToHSV()
            local H0, PH = CH, 100
            local VH, EXP, open = H0 - 6, H0 + PH + 50, false
            local f, hf, fx = card(H0, false)
            f.ClipsDescendants = true
            local head = new("TextButton", {Size = UDim2.new(1, 0, 0, VH), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, f)
            head.MouseEnter:Connect(function() fx.hover(true) end)
            head.MouseLeave:Connect(function() fx.hover(false) end)
            text(head, {Text = title, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -140, 1, 0), W = 3})
            local hexL = text(head, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -58, 0, 0), Size = UDim2.fromOffset(70, VH), TextXAlignment = XR, Mono = true, TextSize = 11, TextColor3 = T.dim})
            local sw = mk("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(34, 22), BackgroundColor3 = col, BorderSizePixel = 0}, head, 7, 2)

            local pop = new("Frame", {Position = UDim2.fromOffset(12, VH + 4), Size = UDim2.new(1, -24, 0, PH + 8 + 28), BackgroundTransparency = 1}, f)
            local svBox = mk("Frame", {Size = UDim2.new(1, -32, 0, PH), BackgroundColor3 = Color3.fromHSV(hh, 1, 1), BorderSizePixel = 0}, pop, 8, 2)
            local wf = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0}, svBox, 8)
            new("UIGradient", {Transparency = NumberSequence.new(0, 1)}, wf)
            local bf = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, svBox, 8)
            new("UIGradient", {Transparency = NumberSequence.new(1, 0), Rotation = 90}, bf)
            local pt = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0}, svBox, "full", 2)
            local svHit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, svBox)
            local hue = mk("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(22, PH), BackgroundColor3 = WHITE, BorderSizePixel = 0}, pop, 8, 2)
            local ks = {}
            for i = 0, 6 do ks[#ks + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)) end
            new("UIGradient", {Color = ColorSequence.new(ks), Rotation = 90}, hue)
            local hp = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 6, 0, 8), BackgroundColor3 = WHITE, BorderSizePixel = 0}, hue, 4, 2)
            local hHit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, hue)
            local _, hexBox = inputBox(pop, {placeholder = "#RRGGBB", wrap = {Position = UDim2.fromOffset(0, PH + 8), Size = UDim2.new(1, 0, 0, 28)}})

            local function hex(c) return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
            local function rgbOf() return {math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)} end
            local function apply(silent, exact)
                col = exact or Color3.fromHSV(hh, ss, vv)
                sw.BackgroundColor3 = col
                svBox.BackgroundColor3 = Color3.fromHSV(hh, 1, 1)
                hexL.Text = hex(col)
                if not hexBox:IsFocused() then hexBox.Text = hex(col) end
                pt.Position = UDim2.fromScale(ss, 1 - vv)
                hp.Position = UDim2.new(0.5, 0, hh, 0)
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
                    if asz.Y <= 0 then return end
                    hh = math.clamp((yOf(pos) - ap.Y) / asz.Y, 0, 1)
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
                fx.active(open)
                play(hf, {Size = UDim2.new(1, 0, 0, open and EXP or H0)}, 0.35, BACK)
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
        -- ACCORDION: klik header = buka / tutup, tinggi mengikuti isi
        ----------------------------------------------------------------
        function K:Accordion(o)
            o = o or {}
            local desc = o.Desc or o.SubText
            local HEAD = desc and CD or CH
            local VH = HEAD - 6
            local open, animating, tok = false, false, 0
            local f, hf, fx = card(HEAD, false)
            f.ClipsDescendants = true
            local tint = mk("Frame", {Size = UDim2.new(1, 0, 0, VH), BackgroundTransparency = 1, BorderSizePixel = 0}, f, R)
            skin(tint, "BackgroundColor3", "accent")
            local fill = new("Frame", {Position = UDim2.fromOffset(0, VH - 12), Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, BorderSizePixel = 0}, f)
            skin(fill, "BackgroundColor3", "accent")
            local sep = new("Frame", {Position = UDim2.fromOffset(0, VH), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = T.ink, BorderSizePixel = 0, Visible = false}, f)
            local head = new("TextButton", {Name = "Head", Size = UDim2.new(1, 0, 0, VH), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, f)
            rowText(head, o.Title or o.Name or "Accordion", desc, 84, HEAD)
            local cnt = mk("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -36, 0.5, 0), Size = UDim2.fromOffset(26, 20), BackgroundColor3 = T.input, BorderSizePixel = 0}, head, "full", 1.5)
            local cntL = text(cnt, {Text = "0", Size = UDim2.fromScale(1, 1), TextXAlignment = XC, W = 3, TextSize = 10, TextTruncate = NOTRUNC})
            local chev = text(head, {Text = "›", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -18, 0.5, 0), Size = UDim2.fromOffset(20, 20), TextXAlignment = XC, W = 2, TextSize = 24, TextTruncate = NOTRUNC})

            local wrap = new("Frame", {Position = UDim2.fromOffset(0, VH), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Visible = false}, f)
            local cont = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0}, wrap)
            new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 10)}, cont)
            local lay = new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, cont)
            mk("Frame", {Position = UDim2.fromOffset(9, 10), Size = UDim2.new(0, 3, 1, -20), BackgroundColor3 = T.ink, BackgroundTransparency = 0.6, BorderSizePixel = 0}, wrap, "full")

            local sub = buildComponents(scroll, cont, true, ctx)
            sub._badge, sub._content = cntL, cont

            local function contentH()
                local ah = lay.AbsoluteContentSize.Y
                if ah <= 0 then return 0 end
                local fac = head.AbsoluteSize.Y / VH
                if fac < 0.01 then fac = math.max(rootScale.Scale, 0.01) end
                return math.floor(ah / fac + 0.5) + 18
            end
            local function setH(h)
                wrap.Size = UDim2.new(1, 0, 0, h)
                hf.Size = UDim2.new(1, 0, 0, HEAD + h)
            end
            local function setOpen(v, instant)
                if v == open then return end
                open = v
                tok = tok + 1
                local my = tok
                fx.active(v)
                sep.Visible = v
                play(chev, {Rotation = v and 90 or 0}, 0.3, BACK)
                play(tint, {BackgroundTransparency = v and 0 or 1}, 0.25)
                play(fill, {BackgroundTransparency = v and 0 or 1}, 0.25)
                play(cnt, {BackgroundColor3 = v and T.card or T.input}, 0.2)
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
                    play(hf, {Size = UDim2.new(1, 0, 0, HEAD + h)}, 0.35, BACK)
                    play(wrap, {Size = UDim2.new(1, 0, 0, h)}, 0.35, BACK)
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
            head.MouseEnter:Connect(function() fx.hover(true) end)
            head.MouseLeave:Connect(function() fx.hover(false) end)
            head.MouseButton1Click:Connect(function() setOpen(not open) end)

            function sub:Expand() setOpen(true) end
            function sub:Collapse() setOpen(false) end
            function sub:SetOpen(v) setOpen(v and true or false) end
            function sub:IsOpen() return open end
            if o.Open then setOpen(true, true) end
            return sub
        end
        K.Group = K.Accordion

        function K:Panel(o) return Window:Panel(o) end

        -- alias gaya Vora. CreateSection = accordion; komponen sesudahnya masuk ke dalamnya
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
    function Window.Notify(a, b, c, d)
        if a == Window then a, b, c, d = b, c, d, nil end
        if type(a) == "table" then return notify(a.Title or a.Name, a.Content or a.Desc or a.Message, a.Color, a.Duration) end
        return notify(a, b, c, d)
    end
    function Window:IsGame(id) return placeId == id or gameId == id end
    function Window:Toggle() toggleWin() end
    function Window:Open() openA() end
    function Window:Close() closeA() end
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
        return buildComponents(createTab(c.Title or c.Name or "Tab", c.Icon), nil, false, ctxWin)
    end
    function Window:CreateTab(c) c = c or {} return Window:Tab({Title = c.Name or c.Title, Icon = c.Icon}) end

    -- support game
    local supported, kickOnFail = C.SupportedGames, C.KickIfNotSupported
    if kickOnFail == nil then kickOnFail = true end
    local isSupported = true
    if supported and #supported > 0 then
        isSupported = false
        for _, id in ipairs(supported) do if id == placeId or id == gameId then isSupported = true break end end
    end
    Window.IsSupported = isSupported

    -- modal konfirmasi tutup
    local over = new("TextButton", {Name = "Modal", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 300, BorderSizePixel = 0}, root)
    do
        local dh = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(320, 170), BackgroundTransparency = 1, Active = true}, over)
        local dia = sticker(dh, 14, 3, T.bg)
        text(dia, {Text = "Close SORU Hub?", Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 26), TextXAlignment = XC, W = 3, TextSize = 20})
        text(dia, {Text = "The interface will be closed. Re-execute the script to open it again.", Position = UDim2.fromOffset(24, 50), Size = UDim2.new(1, -48, 0, 40), TextXAlignment = XC, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, TextSize = 12, W = 1, TextColor3 = T.dim, TextTruncate = NOTRUNC})
        local function mbtn(x, txt, col, tcol)
            local p0 = UDim2.new(x, x == 0 and 16 or 8, 1, -56)
            local b = mk("TextButton", {Size = UDim2.new(0.5, -24, 0, 36), Position = p0, Text = txt, FontFace = FONT[3], TextSize = 14, BackgroundColor3 = col, TextColor3 = tcol, AutoButtonColor = false, BorderSizePixel = 0}, dia, 10, 2)
            b.MouseButton1Down:Connect(function() play(b, {Position = p0 + UDim2.fromOffset(0, 2)}, 0.05) end)
            b.MouseButton1Up:Connect(function() play(b, {Position = p0}, 0.2, BACK) end)
            return b
        end
        local no, yes = mbtn(0, "Cancel", T.card, T.ink), mbtn(0.5, "Close", T.bad, WHITE)
        yes.TextStrokeColor3, yes.TextStrokeTransparency = T.ink, 0
        no.MouseButton1Click:Connect(function() over.Visible = false end)
        yes.MouseButton1Click:Connect(function() over.Visible = false closeA() task.delay(0.3, function() gui:Destroy() end) end)
    end
    xB.MouseButton1Click:Connect(function() over.Visible = true end)
    minB.MouseButton1Click:Connect(closeA)
    local maxed, prevSize = false, nil
    maxB.MouseButton1Click:Connect(function()
        maxed = not maxed
        if maxed then
            prevSize = winSize
            winSize = Vector2.new(math.min(MAXS.X, virt.X - 20), math.min(MAXS.Y, virt.Y - 20))
            winPos = nil
        else
            winSize = prevSize or DEFAULT
        end
        layoutWin(true)
    end)

    bind(UIS.InputBegan, function(i, gp)
        if binding or gp then return end
        if i.KeyCode == toggleKey then toggleWin() end
    end)
    bind(gui:GetPropertyChangedSignal("AbsoluteSize"), applyScale)
    applyScale()
    applyTrans(curTrans)

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
        local GRIP, M, HEADP = 28, 12, 58
        local dockL = tostring(o.OpenDrag or "Left"):lower() == "right"
        local AX = dockL and 0 or 1
        local isP, destroyed, prog = false, false, 0
        local holder = new("Frame", {Name = "SORU_Panel", AnchorPoint = Vector2.new(AX, 0), Size = UDim2.new(0, W + GRIP, 1, -28), BackgroundTransparency = 1, ZIndex = 60}, root)
        local function pos(p)
            local x = (1 - p) * W - p * M
            return UDim2.new(AX, dockL and -x or x, 0, 14)
        end
        holder.Position = pos(0)
        local psh = mk("Frame", {AnchorPoint = Vector2.new(AX, 0), Position = UDim2.new(AX, dockL and -5 or 5, 0, 5), Size = UDim2.new(0, W, 1, 0), BackgroundColor3 = T.ink, BorderSizePixel = 0}, holder, 14)
        local body = mk("Frame", {Name = "Body", AnchorPoint = Vector2.new(AX, 0), Position = UDim2.new(AX, 0, 0, 0), Size = UDim2.new(0, W, 1, 0), BackgroundColor3 = T.side, BorderSizePixel = 0, Active = true, ClipsDescendants = true}, holder, 14, 3)
        regT(body, 0)
        local hasSub = o.Subtitle ~= nil and tostring(o.Subtitle) ~= ""
        local tl = text(body, {Text = tostring(o.Title or "Panel"), Position = UDim2.fromOffset(16, hasSub and 9 or 0), Size = UDim2.new(1, -64, 0, hasSub and 24 or HEADP), W = 3, TextSize = 17})
        local sl = text(body, {Text = tostring(o.Subtitle or ""), Position = UDim2.fromOffset(16, 33), Size = UDim2.new(1, -64, 0, 14), TextSize = 11, W = 1, TextColor3 = T.dim, Visible = hasSub})
        local cb = mk("TextButton", {Position = UDim2.new(1, -44, 0, 15), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = T.card, Text = dockL and "‹" or "›", FontFace = FONT[2], TextSize = 20, TextColor3 = T.ink, AutoButtonColor = false, BorderSizePixel = 0}, body, "full", 2)
        new("Frame", {Position = UDim2.fromOffset(0, HEADP), Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = T.ink, BorderSizePixel = 0}, body)
        local pscroll = new("ScrollingFrame", {Position = UDim2.fromOffset(0, HEADP + 3), Size = UDim2.new(1, 0, 1, -(HEADP + 3)), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = T.ink, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, body)
        new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, pscroll)
        new("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}, pscroll)
        local pctx = newCtx(body, 14)
        local K = buildComponents(pscroll, nil, false, pctx)

        local grip = new("Frame", {Name = "Grip", AnchorPoint = Vector2.new(1 - AX, 0.5), Position = UDim2.new(1 - AX, 0, math.clamp(tonumber(o.GripY) or 0.3, 0.1, 0.9), 0), Size = UDim2.fromOffset(GRIP, 124), BorderSizePixel = 0, Active = true}, holder)
        skin(grip, "BackgroundColor3", "accent")
        corner(grip, 10)
        stroke(grip, T.ink, 3)
        local gt = text(grip, {Text = string.upper(tostring(o.Title or "Panel")), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(104, 16), Rotation = dockL and -90 or 90, TextXAlignment = XC, W = 3, TextSize = 11})

        local function goTo(open)
            local was = isP
            isP = open and true or false
            prog = isP and 1 or 0
            if not isP and pctx.d then pctx.d.close() end
            play(holder, {Position = pos(prog)}, 0.4, BACK)
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
            tl.Position = UDim2.fromOffset(16, s ~= "" and 9 or 0)
            tl.Size = UDim2.new(1, -64, 0, s ~= "" and 24 or HEADP)
        end
        function K:SetVisible(v) holder.Visible = v and true or false end
        function K:SetWidth(w)
            W = math.clamp(tonumber(w) or W, 220, 520)
            holder.Size = UDim2.new(0, W + GRIP, 1, -28)
            body.Size, psh.Size = UDim2.new(0, W, 1, 0), UDim2.new(0, W, 1, 0)
            holder.Position = pos(prog)
        end
        function K:Destroy() if not destroyed then destroyed = true holder:Destroy() end end
        if o.Open then
            isP, prog = true, 1
            holder.Position = pos(1)
        end
        return K
    end

    ------------------------------------------------------------------
    -- DASHBOARD (tab pertama): profil, server, statistik, executor, discord, interface
    ------------------------------------------------------------------
    local ticks = {}
    local function buildDashboard(D)
        -- kartu Hello: klik untuk menampilkan / menyensor nama
        local hero = D._card(70, true)
        local av = mk("ImageLabel", {Position = UDim2.fromOffset(12, 9), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = T.off, BorderSizePixel = 0}, hero, "full", 2)
        task.spawn(function()
            local ok, img = pcall(function() return Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
            if ok and av.Parent then av.Image = img end
        end)
        local hello = text(hero, {Position = UDim2.fromOffset(72, 9), Size = UDim2.new(1, -84, 0, 26), W = 3, TextSize = 19})
        local subH = text(hero, {Position = UDim2.fromOffset(72, 36), Size = UDim2.new(1, -84, 0, 16), TextSize = 11, W = 1, TextColor3 = T.dim})
        local shown = false
        local function paintHello()
            hello.Text = "Hello, " .. (shown and pl.DisplayName or string.rep("•", math.min(#pl.DisplayName, 10)))
            subH.Text = gameName .. (shown and "" or "  •  tap to show name")
        end
        bindName(paintHello)
        hero.MouseButton1Click:Connect(function() shown = not shown paintHello() end)

        local t0 = os.clock()
        local function confirmBtn(parent, title, desc, fn)
            local armed, b = false, nil
            b = parent:Button({Title = title, Desc = desc, Callback = function()
                if not armed then
                    armed = true
                    b:SetDesc("Tap again to confirm")
                    task.delay(2.5, function() if armed then armed = false b:SetDesc(desc) end end)
                    return
                end
                armed = false
                b:SetDesc(desc)
                fn()
            end})
        end
        local function lvl(v, a, b) return (v <= a and T.ok) or (v <= b and T.warn) or T.bad end -- ping: kecil = bagus

        -- SERVER
        local S = D:Accordion({Title = "Server", Desc = "Information on your current session", Open = true})
        local iPl, iLat, iReg, iTime = S:Info({Title = "Players"}), S:Info({Title = "Latency"}), S:Info({Title = "Region"}), S:Info({Title = "In server for", Value = "00:00:00"})
        task.spawn(function()
            local ok, r = pcall(function() return LocalizationService:GetCountryRegionForPlayerAsync(pl) end)
            iReg:Set(ok and tostring(r) or "-")
        end)
        S:Button({Title = "Copy join script", Desc = "Teleport straight into this server", Callback = function()
            copy(string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%s, "%s", game:GetService("Players").LocalPlayer)', tostring(placeId), tostring(game.JobId)))
            notify("Join script", "Copied to clipboard", T.accent, 1.8)
        end})
        confirmBtn(S, "Rejoin server", "Teleport back into this server", function() TeleportService:TeleportToPlaceInstance(placeId, game.JobId, pl) end)
        confirmBtn(S, "Server hop", "Join another server of this game", function() TeleportService:Teleport(placeId, pl) end)

        -- STATISTICS
        local ST = D:Accordion({Title = "Statistics", Desc = "FPS, ping, memory, coordinates"})
        local iFps, iPing, iMem = ST:Info({Title = "FPS"}), ST:Info({Title = "Ping"}), ST:Info({Title = "Memory"})
        local iPos = ST:Info({Title = "Coordinates", Value = "X:0  Y:0  Z:0", Copy = true})
        ST:Info({Title = "Place ID", Value = tostring(placeId), Copy = true})
        ST:Info({Title = "Game ID", Value = tostring(gameId), Copy = true})
        local frames, lastF = 0, os.clock()
        bind(RunService.RenderStepped, function() frames = frames + 1 end)
        ticks[#ticks + 1] = function()
            local now = os.clock()
            local fps = math.floor(frames / math.max(now - lastF, 0.1) + 0.5)
            frames, lastF = 0, now
            local ping, mem = 0, 0
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
            pcall(function() mem = math.floor(Stats:GetTotalMemoryUsageMb() + 0.5) end)
            local s = math.floor(now - t0)
            iPl:Set(#Players:GetPlayers() .. " / " .. Players.MaxPlayers)
            iLat:Set(ping .. " ms", lvl(ping, 80, 150))
            iPing:Set(ping .. " ms", lvl(ping, 80, 150))
            iTime:Set(string.format("%02d:%02d:%02d", math.floor(s / 3600), math.floor((s % 3600) / 60), s % 60))
            iFps:Set(fps .. " fps", (fps >= 50 and T.ok) or (fps >= 30 and T.warn) or T.bad)
            iMem:Set(mem .. " MB")
            local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
            if hrp then iPos:Set(string.format("X:%.1f  Y:%.1f  Z:%.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)) end
        end

        -- EXECUTOR
        local EX = D:Accordion({Title = "Executor", Desc = "What this script needs from your executor"})
        local exeName = "Unknown"
        pcall(function() if identifyexecutor then exeName = tostring((identifyexecutor())) end end)
        EX:Info({Title = "Name", Value = exeName})
        local missing = {}
        for _, n in ipairs({"writefile", "readfile", "isfile", "getcustomasset", "setclipboard"}) do
            local ok, v = pcall(function() return getfenv()[n] or (n == "setclipboard" and toclipboard) end)
            if not (ok and v) then missing[#missing + 1] = n end
        end
        EX:Info({Title = "Support"}):Set(#missing == 0 and "Full support" or ("Missing: " .. table.concat(missing, ", ")), #missing == 0 and T.ok or T.bad)

        D:Button({Title = "Join our Discord", Desc = "Copies the invite and tries to open Discord", Callback = function()
            copy("https://discord.gg/cHsx3RFYb")
            pcall(function()
                local req = request or http_request or (syn and syn.request)
                if req then
                    req({Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST", Headers = {["Content-Type"] = "application/json", Origin = "https://discord.com"}, Body = Http:JSONEncode({cmd = "INVITE_BROWSER", args = {code = "cHsx3RFYb"}, nonce = Http:GenerateGUID(false)})})
                end
            end)
            notify("Discord", "Invite copied to clipboard", T.accent2, 2)
        end})

        -- INTERFACE
        local UI = D:Accordion({Title = "Interface", Desc = "Theme, scale, transparency, keys"})
        UI:Dropdown({Title = "Theme", Desc = "Accent color preset", Flag = "UITheme", Options = ORDER, Default = curTheme,
            Swatch = function(n) return THEMES[n] and THEMES[n][1] or nil end,
            Callback = function(v)
                if type(v) == "string" and v ~= curTheme and THEMES[v] then
                    curTheme = v
                    applyTheme(v)
                end
            end})
        local scaleS = UI:Slider({Title = "UI scale", Flag = "UIScale", Min = 60, Max = 150, Step = 5, Suffix = "%", Default = math.floor(userScale * 100 + 0.5),
            OnRelease = function(v) userScale = v / 100 applyScale() end})
        UI:Slider({Title = "Transparency", Flag = "UITransPct", Min = 0, Max = 60, Step = 5, Suffix = "%", Default = math.floor(curTrans * 100 + 0.5),
            Callback = function(v) applyTrans(v / 100) F.UITrans = v / 100 end})
        UI:Keybind({Title = "Menu key", Desc = "Show or hide the interface", Flag = "MenuKey", Default = toggleKey,
            OnChange = function(k) if k then toggleKey = k end end})
        UI:Toggle({Title = "Reduce animation", Desc = "Instant changes, lightest on weak devices", Flag = "UINoAnim", Default = NOANIM,
            Callback = function(v) NOANIM = v and true or false end})
        UI:Button({Title = "Reset UI size", Desc = "Back to the default size and scale", Callback = function()
            winSize, winPos = DEFAULT, nil
            userScale = autoScale()
            scaleS:Set(math.floor(userScale * 100 + 0.5))
            F.UIW, F.UIH = nil, nil
            applyScale()
            layoutWin(true)
            persist()
            notify("UI reset", "Size and scale restored", T.accent, 2)
        end})
        D:Accordion({Title = "Changelog", Desc = "v" .. VERSION}):Paragraph({Title = "v7.0 - Cartoon Classic", Desc = "Cream paper look, thick ink outlines, hard shadows, press-down buttons, bouncy animations. Flat and light: no gradients, no shadow images."})
    end
    buildDashboard(Window:Tab({Title = "Dashboard", Icon = "home"}))

    -- loop 1 detik: chip fps/ping di header + info dashboard
    local fc, lfT = 0, os.clock()
    bind(RunService.RenderStepped, function() fc = fc + 1 end)
    task.spawn(function()
        while gui.Parent do
            task.wait(1)
            local now = os.clock()
            local fps = math.floor(fc / math.max(now - lfT, 0.1) + 0.5)
            fc, lfT = 0, now
            if isOpen then
                local ping
                pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
                cdot.BackgroundColor3 = (fps >= 50 and T.ok) or (fps >= 30 and T.warn) or T.bad
                chipL.Text = fps .. " fps" .. (ping and ("  •  " .. ping .. " ms") or "")
                if cur == "Dashboard" then for _, fn in ipairs(ticks) do pcall(fn) end end
            end
        end
    end)

    if C.Demo then
        local S = Window:Tab({Title = "Showcase", Icon = "★"})
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
