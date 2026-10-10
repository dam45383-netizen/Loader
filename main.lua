local SORU_URL = "https://raw.githubusercontent.com/dam45383-netizen/Loader/refs/heads/main/UI.lua"

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
        104050046639813,  -- Ride A Fish
        114326934417838, -- BAS
        73956553001240,  -- VBL
        74193805629461, -- +1 mine per click
        85738654635245
    },
    KickIfNotSupported = false
})

if not Window then
    warn("[SORU] Window nil, cek SupportedGames")
    return
end

-- WAJIB biar BAS.lua & VBL.lua bisa baca Window
getgenv().SORU_Window = Window
getgenv().SORU = SORU

local placeId = game.PlaceId
local universeId = game.GameId

local function loadRaw(url)
    local s, res = pcall(function()
        return game:HttpGet(url)
    end)
    if s and res and res ~= "" then
        local ok2, err = pcall(function()
            loadstring(res)()
        end)
        if not ok2 then warn("[SORU] error exec "..url.." : "..tostring(err)) end
    else
        warn("[SORU] gagal load raw: "..url)
    end
end

if placeId == 114326934417838 or universeId == 114326934417838 then
    loadRaw("https://raw.githubusercontent.com/dam45383-netizen/Loader/main/BAS.lua")
elseif placeId == 129827112113663 then
    loadRaw("https://raw.githubusercontent.com/dam45383-netizen/Loader/main/Prospecting.lua")
elseif placeId == 104050046639813 then
    loadRaw("https://raw.githubusercontent.com/dam45383-netizen/Loader/refs/heads/main/Ride%20a%20Fish")
elseif placeId == 73956553001240 or universeId == 73956553001240 then
    loadRaw("https://raw.githubusercontent.com/dam45383-netizen/Loader/refs/heads/main/VBL.lua")
elseif placeId == 74193805629461 then
    loadRaw("https://raw.githubusercontent.com/dam45383-netizen/Loader/refs/heads/main/%2B1%20Mine%20per%20click.lua") 
elseif placeId == 85738654635245 then
    loadRaw("https://raw.githubusercontent.com/dam45383-netizen/Loader/refs/heads/main/Climb%20For%20Animal%20Egg") 
end
