local SORU = loadstring(game:HttpGet("https://pastebin.com/raw/hActzjgY"))()
Window = SORU:CreateWindow({
    Title = "SORU HUB",
    SupportedGames = {129827112113663, 10765288803},
    KickIfNotSupported = false
})

if Window:IsGame(129827112113663) or game.PlaceId == 129827112113663 then
    local MainAPI = Window:Tab({Title = "Main"})
    MainAPI:Button({Title = "Test Prospecting Work", Callback = function() print("Prospecting OK") end})

elseif Window:IsGame(10765288803) or game.PlaceId == 10765288803 then
    local MainAPI = Window:Tab({Title = "Main"})
    MainAPI:Button({Title = "Test BAS Work", Callback = function() print("BAS OK") end})
end
