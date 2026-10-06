local SORU = loadstring(game:HttpGet("https://pastebin.com/raw/hActzjgY"))()
Window = SORU:CreateWindow({
    Title = "SORU HUB",
    SupportedGames = {129827112113663, 10765288803},
    KickIfNotSupported = false
})

if game.PlaceId == 129827112113663 or game.GameId == 129827112113663 then
    local MainAPI = Window:Tab({Title = "Main"})
    MainAPI:Button({Title = "Prospecting OK", Callback = function() print("ok") end})
else
    
