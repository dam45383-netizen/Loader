local SORU = loadstring(game:HttpGet("https://pastebin.com/raw/hActzjgY"))()
if not SORU then 
    warn("SORU gagal ke-load, pastebin ke-block")
    return 
end

-- MASUKIN SEMUA ID LU DISINI, termasuk BAS yang baru
local Window = SORU:CreateWindow({
    Title = "SORU HUB",
    SupportedGames = {129827112113663, 10765288803, 114326934417838},
    KickIfNotSupported = false -- biar gak return nil
})

if not Window then
    warn("Window nil, cek SupportedGames")
    return
end

-- baru disini lu load script BAS yang udah lu obfuscate ringan
if game.PlaceId == 114326934417838 or game.GameId == 114326934417838 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/dam45383-netizen/Loader/refs/heads/main/BAS.lua"))()
end
