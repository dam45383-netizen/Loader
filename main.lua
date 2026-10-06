local SORU_URL = "https://pastebin.com/raw/hActzjgY"

local ok, SORU = pcall(function()
    return loadstring(game:HttpGet(SORU_URL))()
end)

if not ok or not SORU then
    warn("[SORU] gagal load dari pastebin, coba ganti executor / cek internet")
    return
end

local Window = SORU:CreateWindow({
    Title = "SORU HUB",
    SupportedGames = {
        129827112113663, -- Prospecting
        10765288803,     -- game 2 lu
        114326934417838 -- BAS
    },
    KickIfNotSupported = false
})

if not Window then
    warn("[SORU] Window nil, cek SupportedGames")
    return
end

-- WAJIB biar BAS.lua bisa baca Window
getgenv().SORU_Window = Window

local placeId = game.PlaceId
local universeId = game.GameId

local function loadRaw(url)
    local s, res = pcall(function()
        return game:HttpGet(url)
    end)
    if s and res then
        pcall(function()
            loadstring(res)()
        end)
    else
        warn("[SORU] gagal load raw: "..url)
    end
end

if placeId == 114326934417838 or universeId == 114326934417838 then
    loadRaw("https://raw.githubusercontent.com/dam45383-netizen/Loader/main/BAS.lua")
elseif placeId == 129827112113663 then
    loadRaw("https://raw.githubusercontent.com/dam45383-netizen/Loader/main/prospecting.lua")
elseif placeId == 10765288803 then
    loadRaw("https://raw.githubusercontent.com/dam45383-netizen/Loader/main/game2.lua")
end
