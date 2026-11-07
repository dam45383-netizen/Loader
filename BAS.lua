local Window = getgenv().SORU_Window
if not Window then return end

-- ================= TABS =================
local TabMain = Window:CreateTab({ Name = "Main", Icon = "home" })
local TabMisc = Window:CreateTab({ Name = "Misc", Icon = "◈" })
local TabEsp = Window:CreateTab({ Name = "Esp", Icon = "◎" })
local TabPlot = Window:CreateTab({ Name = "Plot", Icon = "⬡" })
local TabBlatant = Window:CreateTab({ Name = "Blatant", Icon = "⚡" })
local TabUpgrade = Window:CreateTab({ Name = "Upgrade", Icon = "▲" })
local TabDiamond = Window:CreateTab({ Name = "Diamond", Icon = "💎" })

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VIM = game:GetService("VirtualInputManager")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local plr = Players.LocalPlayer

local SAFE_BASE_POS = Vector3.new(-13.8073769, 4.5, -53.5250626)
local SAFE_BASE_CF = CFrame.new(-13.8073769, 4.5, -53.5250626, 0, 0, 1, 0, 1, -0, -1, 0, 0)
local SAFE_BASE_MID = Vector3.new(-75, 3.5, -7.4)
local HELPER_DROP_POS = Vector3.new(-105.2, 3.7, -6.2)
local OFFSET_DIST = 3
local RANGE = 15
local SLIDER_MIN, SLIDER_MAX = 16, 500
local sliderSpeed = 16

local function getRealHumanoidSpeed()
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then return hum.WalkSpeed end
    return sliderSpeed
end

local ACCENT = Color3.fromRGB(139, 92, 246)
local DIM = Color3.fromRGB(148, 140, 180)
local RARITY_SCORE = {["Common"]=1,["Uncommon"]=2,["Rare"]=3,["Epic"]=4,["Legendary"]=5,["Mythic"]=6,["Secret"]=7,["Godly"]=8,["Cosmic"]=9,["Divine"]=10,["Celestial"]=11}
local RARITY_COLOR = {["Common"]=Color3.fromRGB(180,180,180),["Uncommon"]=Color3.fromRGB(92,255,92),["Rare"]=Color3.fromRGB(85,170,255),["Epic"]=Color3.fromRGB(170,85,255),["Legendary"]=Color3.fromRGB(255,180,0),["Mythic"]=Color3.fromRGB(255,60,60),["Secret"]=Color3.fromRGB(0,0,0),["Godly"]=Color3.fromRGB(255,223,0),["Cosmic"]=Color3.fromRGB(0,255,255),["Divine"]=Color3.fromRGB(255,255,255),["Celestial"]=Color3.fromRGB(255,120,255)}
local function getRarityColor(r) return RARITY_COLOR[r] or ACCENT end

local rarityNames = {}
local rf = RS:FindFirstChild("Rarities")
if rf then for _, c in ipairs(rf:GetChildren()) do table.insert(rarityNames, c.Name) end
else rarityNames = {"Common","Rare","Epic","Legendary","Mythic","Secret"} end

local function getRarityScore(n)
    if RARITY_SCORE[n] then return RARITY_SCORE[n] end
    for i, v in ipairs(rarityNames) do if v == n then return i end end
    return 0
end

local function getBasePos(m)
    local b
    if m.PrimaryPart then b = m.PrimaryPart.Position
    else
        local ok, cf = pcall(function() return m:GetPivot() end)
        if ok then b = Vector3.new(cf.X, cf.Y, cf.Z)
        else for _, v in ipairs(m:GetDescendants()) do if v:IsA("BasePart") then b = v.Position break end end end
    end
    return b
end

local function getOffsetPos(m)
    local base = getBasePos(m)
    if not base then return nil, nil end
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    local dir = hrp and Vector3.new(hrp.Position.X - base.X, 0, hrp.Position.Z - base.Z) or Vector3.new(0, 0, 1)
    if dir.Magnitude < 1 then dir = Vector3.new(0, 0, 1) end
    return Vector3.new(base.X, 3.5, base.Z) + dir.Unit * OFFSET_DIST, Vector3.new(base.X, 3.5, base.Z)
end

local function getZoneBuildsFolder()
    local b = workspace:FindFirstChild("Build")
    if b then local zb = b:FindFirstChild("ZoneBuilds") if zb then return zb end end
    return workspace:FindFirstChild("ZoneBuilds") or workspace:FindFirstChild("Build")
end

local function getAnimalZone(model)
    local pos = getBasePos(model)
    if not pos then return "Unknown" end
    local zb = getZoneBuildsFolder()
    if not zb then return "Unknown" end
    local closest = "Unknown" local minD = math.huge
    for _, z in ipairs(zb:GetChildren()) do
        if z:IsA("Model") then
            local zp = getBasePos(z)
            if zp then
                local d = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(zp.X, 0, zp.Z)).Magnitude
                if d < minD then minD = d closest = z.Name end
            end
        end
    end
    return closest
end

local function getCashPerSecond(model)
    for _, v in ipairs(model:GetDescendants()) do
        if v.Name == "CashPerSecond" and v:IsA("TextLabel") then return v.Text end
    end
    return "?"
end

local function parseCash(text)
    if not text then return 0 end
    local s = tostring(text):gsub("%$",""):gsub("/s",""):gsub("/sec",""):gsub(" ",""):gsub(",",""):upper()
    local num = tonumber(s:match("[%d%.]+"))
    if not num then return 0 end
    if s:find("K") then num *= 1000 elseif s:find("M") then num *= 1000000 elseif s:find("B") then num *= 1000000000 elseif s:find("T") then num *= 1000000000000 end
    return num
end

local function parseFilterInput(text)
    if not text or text == "" then return 0 end
    return parseCash(text)
end

-- Helper lib baru: Dropdown single return string, lama return table
local function unwrap(v)
    if type(v) == "table" then return v[1] end
    return v
end

local defendMode = "None" local attackEnabled = false local minCashFilter = 0 local bigEggPriority = true
local selectedFollowPlayer = nil local followEnabled = false local espEnabled = false
local selectedEspRarity = {} local espCache = {} local selectedTeleportZone = nil local pendingTeleportZone = nil
local eggEspEnabled = false local selectedEggZones = {} local selectedEggSizes = {} local eggEspCache = {}

local function getWalkSpeed() return sliderSpeed end
do local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") if hum then sliderSpeed = hum.WalkSpeed end end

local function findDropButton()
    for _, v in ipairs(plr.PlayerGui:GetDescendants()) do
        if v:IsA("TextButton") and (v.Name:lower():find("drop") or v.Text:lower():find("drop")) then return v end
    end
    return nil
end

local function isDropVisible()
    local btn = findDropButton()
    if not btn then return false end
    if not btn.Visible then return false end
    local cur = btn.Parent
    while cur and cur ~= plr.PlayerGui do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        cur = cur.Parent
    end
    return true
end

local function fireDropNow()
    local dropBtn = findDropButton()
    if dropBtn then pcall(function() dropBtn:Activate() end) end
    local remote = RS:FindFirstChild("DropCarriedRemote") or RS:FindFirstChild("DropCarriedRemote", true) or RS:FindFirstChild("DropCarried", true)
    if remote then pcall(function() remote:FireServer() end) end
end

local function getClosestAnimalToHRP(maxDist)
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest = nil local minD = maxDist or 8
    local folder = workspace:FindFirstChild("AnimalPickups")
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            if m:IsA("Model") then
                local pos = getBasePos(m)
                if pos then
                    local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
                    if d < minD then minD = d closest = m end
                end
            end
        end
    end
    return closest
end

local function isCarryingTarget(targetModel)
    if not isDropVisible() then return false end
    local closest = getClosestAnimalToHRP(8)
    if not closest then return true end
    if closest == targetModel then return true end
    if closest.Name == targetModel.Name and closest:GetAttribute("Rarity") == targetModel:GetAttribute("Rarity") then return true end
    return false
end

local function walkDirect(targetPos, lookAt, keepRot)
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetPos then return end
    if lookAt then lookAt = Vector3.new(lookAt.X, targetPos.Y, lookAt.Z) end
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero end)
    local function distLeft() return (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude end
    if distLeft() < 1.2 then return end
    while distLeft() > 1.2 do
        if not char or not hrp.Parent then break end
        local ws = getWalkSpeed()
        local cur = Vector3.new(hrp.Position.X, targetPos.Y, hrp.Position.Z)
        local dir = Vector3.new(targetPos.X - cur.X, 0, targetPos.Z - cur.Z)
        if dir.Magnitude < 0.1 then break end
        dir = dir.Unit
        local dt = RunService.Heartbeat:Wait()
        local step = dir * ws * dt
        if step.Magnitude > distLeft() then step = dir * distLeft() end
        local newPos = cur + step
        local cf = keepRot and CFrame.new(newPos) * (hrp.CFrame - hrp.CFrame.Position) or (lookAt and CFrame.lookAt(newPos, lookAt) or CFrame.lookAt(newPos, newPos + dir))
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
end

local function walkDirectFallback(targetPos, keepRot, originalAnimal)
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetPos then return false end
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero end)
    local function distLeft() return (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude end
    if distLeft() < 1.2 then return true end
    while distLeft() > 1.2 do
        if not char or not hrp.Parent then return false end
        if not isDropVisible() then return false end
        local ws = getWalkSpeed()
        local cur = Vector3.new(hrp.Position.X, targetPos.Y, hrp.Position.Z)
        local dir = Vector3.new(targetPos.X - cur.X, 0, targetPos.Z - cur.Z)
        if dir.Magnitude < 0.1 then break end
        dir = dir.Unit
        local dt = RunService.Heartbeat:Wait()
        local step = dir * ws * dt
        if step.Magnitude > distLeft() then step = dir * distLeft() end
        local newPos = cur + step
        local cf = keepRot and CFrame.new(newPos) * (hrp.CFrame - hrp.CFrame.Position) or CFrame.lookAt(newPos, newPos + dir)
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
    return true
end

local function walkDefendFallback(targetPos, mode, originalAnimal)
    if mode == "None" or not mode then return walkDirectFallback(targetPos, true, originalAnimal) end
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local start = Vector3.new(hrp.Position.X, targetPos.Y, hrp.Position.Z)
    local dir = (targetPos - start)
    local dist = Vector3.new(dir.X, 0, dir.Z).Magnitude
    if dist < 5 then return walkDirectFallback(targetPos, true, originalAnimal) end
    dir = Vector3.new(dir.X, 0, dir.Z).Unit
    local perp = Vector3.new(-dir.Z, 0, dir.X)
    local points = {}
    if mode == "ZigZag" then for i = 1, 4 do local t = i / 5 local baseP = start:Lerp(targetPos, t) local offset = (i % 2 == 0 and 1 or -1) * 10 table.insert(points, baseP + perp * offset) end
    elseif mode == "Random" then for i = 1, 4 do local t = i / 5 local baseP = start:Lerp(targetPos, t) table.insert(points, baseP + perp * math.random(-12, 12)) end
    elseif mode == "Circle" then for i = 1, 6 do local t = i / 7 local baseP = start:Lerp(targetPos, t) local ang = i * 60 table.insert(points, baseP + Vector3.new(math.cos(math.rad(ang)) * 8, 0, math.sin(math.rad(ang)) * 8)) end
    elseif mode == "Juke" then for i = 1, 5 do local t = i / 6 local baseP = start:Lerp(targetPos, t) local offset = (i % 2 == 0 and 14 or -14) + math.random(-4, 4) table.insert(points, baseP + perp * offset) end end
    for _, p in ipairs(points) do local ok = walkDirectFallback(p, true, originalAnimal) if not ok then return false end task.wait(0.05) end
    return walkDirectFallback(targetPos, true, originalAnimal)
end

local function walkToSafeBaseFallback(originalAnimal)
    local ok = walkDefendFallback(SAFE_BASE_MID, defendMode, originalAnimal)
    if not ok then
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = SAFE_BASE_CF end
        return true
    end
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = SAFE_BASE_CF task.wait(0.08) hrp.CFrame = SAFE_BASE_CF end
    return true
end

local function walkToSafeBase()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if defendMode == "None" then hrp.CFrame = SAFE_BASE_CF else walkDirect(SAFE_BASE_MID, nil, true) hrp.CFrame = SAFE_BASE_CF end
end

local function makeBigPrompt(p)
    if not p:IsA("ProximityPrompt") then return end
    pcall(function() p.HoldDuration = 0 p.MaxActivationDistance = RANGE p.RequiresLineOfSight = false p.KeyboardKeyCode = Enum.KeyCode.E p.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton end)
end

local function firePrompt(p)
    if not p:IsA("ProximityPrompt") then return end
    makeBigPrompt(p)
    if fireproximityprompt then pcall(fireproximityprompt, p, 0) end
    pcall(function() p:InputHoldBegin() task.wait(0.05) p:InputHoldEnd() end)
end

local function fireSteal(m)
    if not m or not m.Parent then return end
    for _, v in ipairs(m:GetDescendants()) do if v:IsA("ProximityPrompt") then firePrompt(v) end end
end

local function touchSteal(m)
    if not m or not m.Parent then return end
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
    if hrp and part then pcall(function() firetouchinterest(hrp, part, 0) task.wait(0.02) firetouchinterest(hrp, part, 1) end) end
end

local function pressE() pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.05) VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end) end

local function getClosestPlayerToModel(model, maxDist)
    local pos = getBasePos(model)
    if not pos then return nil end
    local closest = nil local minD = maxDist or 20
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
            if d < minD then minD = d closest = p end
        end
    end
    return closest
end

local function equipBat()
    local char = plr.Character if not char then return nil end
    local bat = char:FindFirstChildWhichIsA("Tool")
    if bat and bat.Name:lower():find("bat") then return bat end
    for _, t in ipairs(plr.Backpack:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("bat") then t.Parent = char return t end end
    for _, t in ipairs(plr.Backpack:GetChildren()) do if t:IsA("Tool") then t.Parent = char return t end end
    return char:FindFirstChildOfClass("Tool")
end

local function attackCarrier(carrier)
    if not attackEnabled then return end
    if not carrier or not carrier.Character then return end
    local char = carrier.Character
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for i = 1, 20 do
        if not char.Parent or not attackEnabled then break end
        local myHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then break end
        local pred = hrp.Position + hrp.CFrame.LookVector * 5
        pred = Vector3.new(pred.X, 3.5, pred.Z)
        walkDirect(pred, hrp.Position, false)
        local bat = equipBat()
        if bat then pcall(function() bat:Activate() end) pcall(function() VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0) task.wait(0.05) VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0) end) end
        task.wait(0.15)
        local dist = (Vector3.new(myHrp.Position.X, 0, myHrp.Position.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
        if dist > 30 then break end
    end
end

local function VoraNotify(t, c) Window:Notify({ Title = t, Content = c, Duration = 2 }) end
local stealMode = "Normal"

local function stealMethod(targetModel)
    if not targetModel or not targetModel.Parent then return end
    showStealNotif(targetModel)
    local lastPos = getBasePos(targetModel) local tries = 0
    while tries < 8 and targetModel.Parent do
        if isDropVisible() then if not isCarryingTarget(targetModel) then fireDropNow() task.wait(0.35) tries += 1 continue else break end end
        local curPos = getBasePos(targetModel)
        if curPos and lastPos and (curPos - lastPos).Magnitude > 2 then local carrier = getClosestPlayerToModel(targetModel, 20) if carrier and attackEnabled then attackCarrier(carrier) end end
        lastPos = curPos local p, b = getOffsetPos(targetModel) if p then walkDirect(p, b, false) end touchSteal(targetModel) fireSteal(targetModel) pressE() task.wait(0.25) tries += 1
        if isDropVisible() and not isCarryingTarget(targetModel) then fireDropNow() task.wait(0.3) end
    end
    if not isDropVisible() then walkToSafeBase() return end if not isCarryingTarget(targetModel) then fireDropNow() task.wait(0.3) return end
    if stealMode == "Helper" then local ok = walkDefendFallback(HELPER_DROP_POS, defendMode, targetModel) if not ok then return end if not isCarryingTarget(targetModel) then fireDropNow() return end task.wait(0.15) fireDropNow() task.wait(0.2) walkToSafeBaseFallback(targetModel)
    else local ok = walkToSafeBaseFallback(targetModel) if not ok then return end end
end

-- ESP Animal
local function removeAnimalEsp(model)
    local data = espCache[model]
    if data then pcall(function() if data.hl then data.hl:Destroy() end end) pcall(function() if data.bb then data.bb:Destroy() end end) espCache[model] = nil end
end
local function clearAllEsp() for m, _ in pairs(espCache) do removeAnimalEsp(m) end table.clear(espCache) end
local function createAnimalEsp(model)
    if not model or not model.Parent then return end
    if espCache[model] then return end
    if not model:IsA("Model") then return end
    local rarity = model:GetAttribute("Rarity") or "Unknown"
    if next(selectedEspRarity) ~= nil and not selectedEspRarity[rarity] then return end
    local adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not adornee then return end
    local color = getRarityColor(rarity)
    local hl = Instance.new("Highlight") hl.Name = "SoruEspHL" hl.Adornee = model hl.FillColor = color hl.OutlineColor = color hl.FillTransparency = 0.65 hl.OutlineTransparency = 0 hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop hl.Parent = model
    local bb = Instance.new("BillboardGui") bb.Name = "SoruEspBB" bb.Adornee = adornee bb.Size = UDim2.fromOffset(165, 56) bb.StudsOffset = Vector3.new(0, 4.2, 0) bb.AlwaysOnTop = true bb.Parent = adornee
    local f = Instance.new("Frame", bb) f.Size = UDim2.new(1, 0, 1, 0) f.BackgroundColor3 = Color3.fromRGB(20, 18, 32) f.BackgroundTransparency = 0.12 Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke", f) st.Color = color st.Transparency = 0.2 st.Thickness = 1
    local n = Instance.new("TextLabel", f) n.Size = UDim2.new(1, -8, 0, 14) n.Position = UDim2.new(0, 5, 0, 4) n.BackgroundTransparency = 1 n.Text = model.Name:upper() n.Font = Enum.Font.GothamBold n.TextSize = 10 n.TextColor3 = Color3.new(1, 1, 1) n.TextXAlignment = Enum.TextXAlignment.Left n.TextTruncate = Enum.TextTruncate.AtEnd
    local rLbl = Instance.new("TextLabel", f) rLbl.Size = UDim2.new(1, -8, 0, 11) rLbl.Position = UDim2.new(0, 5, 0, 18) rLbl.BackgroundTransparency = 1 rLbl.Text = string.upper(rarity) .. " • " .. getCashPerSecond(model) rLbl.Font = Enum.Font.GothamMedium rLbl.TextSize = 9 rLbl.TextColor3 = color rLbl.TextXAlignment = Enum.TextXAlignment.Left
    local w = model:GetAttribute("WeightKg") or model:GetAttribute("Weight") or 0
    local zone = getAnimalZone(model)
    local wLbl = Instance.new("TextLabel", f) wLbl.Size = UDim2.new(1, -8, 0, 10) wLbl.Position = UDim2.new(0, 5, 0, 30) wLbl.BackgroundTransparency = 1 wLbl.Text = tostring(w) .. " KG • " .. zone wLbl.Font = Enum.Font.GothamMedium wLbl.TextSize = 8 wLbl.TextColor3 = DIM wLbl.TextXAlignment = Enum.TextXAlignment.Left
    espCache[model] = { hl = hl, bb = bb }
end
local function refreshAllEsp()
    if not espEnabled then clearAllEsp() return end
    local folder = workspace:FindFirstChild("AnimalPickups")
    if not folder then return end
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            local rarity = m:GetAttribute("Rarity") or "Unknown"
            local allowed = next(selectedEspRarity) == nil or selectedEspRarity[rarity]
            if allowed then createAnimalEsp(m) else removeAnimalEsp(m) end
        end
    end
    for m, _ in pairs(espCache) do if not m.Parent then removeAnimalEsp(m) end end
end

-- Egg helpers (dipake ESP + Break Egg + Diamond)
local function getEggSize(model)
    for _, a in ipairs({"Size","EggSize","Scale","WeightKg","Weight","SizeMultiplier"}) do local v = model:GetAttribute(a) if typeof(v) == "number" then return v end end
    for _, d in ipairs(model:GetDescendants()) do if d:IsA("NumberValue") and d.Name:lower():find("size") then return d.Value end end
    local ok, _, sz = pcall(function() return model:GetBoundingBox() end)
    if ok and sz then return sz.Magnitude end
    return 0
end
local function getEggSizeCategory(model)
    local sz = getEggSize(model)
    if sz < 8 then return "Small" elseif sz < 16 then return "Standar" elseif sz < 28 then return "Big" else return "Titan" end
end
local function getEggsInZone(zoneName)
    local zb = getZoneBuildsFolder()
    if not zb then return {} end
    local zoneModel = zb:FindFirstChild(zoneName)
    if not zoneModel then return {} end
    local eggsRoot = zoneModel:FindFirstChild("Eggs") or zoneModel
    local out = {}
    for _, v in ipairs(eggsRoot:GetChildren()) do if v:IsA("Model") and v.Name:lower():find("egg") then table.insert(out, v) end end
    if #out == 0 then for _, v in ipairs(eggsRoot:GetDescendants()) do if v:IsA("Model") and v.Name:lower():find("egg") then table.insert(out, v) end end end
    if bigEggPriority then table.sort(out, function(a, b) return getEggSize(a) > getEggSize(b) end) end
    return out
end
local function getAllEggs()
    local zb = getZoneBuildsFolder()
    if not zb then return {} end
    local out = {}
    for _, zone in ipairs(zb:GetChildren()) do if zone:IsA("Model") then local eggs = getEggsInZone(zone.Name) for _, e in ipairs(eggs) do table.insert(out, e) end end end
    return out
end
local function getZoneTeleportPos(zoneName)
    local eggs = getEggsInZone(zoneName)
    if #eggs > 0 then local p = getBasePos(eggs[1]) if p then return Vector3.new(p.X, 5, p.Z) end end
    local zb = getZoneBuildsFolder()
    if zb then local zm = zb:FindFirstChild(zoneName) if zm then local p = getBasePos(zm) if p then return Vector3.new(p.X, 5, p.Z) end end end
    return nil
end

local function removeEggEsp(model)
    local data = eggEspCache[model]
    if data then pcall(function() if data.hl then data.hl:Destroy() end end) pcall(function() if data.bb then data.bb:Destroy() end end) eggEspCache[model] = nil end
end
local function clearAllEggEsp() for m, _ in pairs(eggEspCache) do removeEggEsp(m) end table.clear(eggEspCache) end
local function createEggEsp(model)
    if not model or not model.Parent then return end
    if eggEspCache[model] then return end
    if not model:IsA("Model") then return end
    if next(selectedEggZones) ~= nil then local zone = getAnimalZone(model) if not selectedEggZones[zone] then return end end
    if next(selectedEggSizes) ~= nil then local cat = getEggSizeCategory(model) if not selectedEggSizes[cat] then return end end
    local adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not adornee then for _, v in ipairs(model:GetDescendants()) do if v:IsA("BasePart") then adornee = v break end end end
    if not adornee then return end
    local cat = getEggSizeCategory(model)
    local col = cat == "Titan" and Color3.fromRGB(255, 60, 60) or cat == "Big" and Color3.fromRGB(255, 180, 0) or cat == "Standar" and Color3.fromRGB(85, 170, 255) or Color3.fromRGB(180, 180, 180)
    local hl = Instance.new("Highlight") hl.Name = "EggEspHL" hl.Adornee = model hl.FillColor = col hl.OutlineColor = col hl.FillTransparency = 0.6 hl.OutlineTransparency = 0 hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop hl.Parent = model
    local bb = Instance.new("BillboardGui") bb.Name = "EggEspBB" bb.Adornee = adornee bb.Size = UDim2.fromOffset(140, 32) bb.StudsOffset = Vector3.new(0, 4, 0) bb.AlwaysOnTop = true bb.Parent = adornee
    local f = Instance.new("Frame", bb) f.Size = UDim2.new(1, 0, 1, 0) f.BackgroundColor3 = Color3.fromRGB(20, 18, 32) f.BackgroundTransparency = 0.1 Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local st = Instance.new("UIStroke", f) st.Color = col st.Transparency = 0.2 st.Thickness = 1
    local n = Instance.new("TextLabel", f) n.Size = UDim2.new(1, -6, 0, 14) n.Position = UDim2.new(0, 4, 0, 2) n.BackgroundTransparency = 1 n.Text = model.Name:upper() n.Font = Enum.Font.GothamBold n.TextSize = 9 n.TextColor3 = Color3.new(1, 1, 1) n.TextXAlignment = Enum.TextXAlignment.Left n.TextTruncate = Enum.TextTruncate.AtEnd
    local c = Instance.new("TextLabel", f) c.Size = UDim2.new(1, -6, 0, 10) c.Position = UDim2.new(0, 4, 0, 16) c.BackgroundTransparency = 1 c.Text = cat .. " • " .. getAnimalZone(model) c.Font = Enum.Font.GothamMedium c.TextSize = 8 c.TextColor3 = col c.TextXAlignment = Enum.TextXAlignment.Left
    eggEspCache[model] = { hl = hl, bb = bb }
end
local function refreshEggEsp()
    if not eggEspEnabled then clearAllEggEsp() return end
    local all = getAllEggs()
    for _, m in ipairs(all) do createEggEsp(m) end
    for m, _ in pairs(eggEspCache) do if not m.Parent then removeEggEsp(m) end end
end

workspace.DescendantAdded:Connect(function(v) if v:IsA("ProximityPrompt") then task.wait(0.1) makeBigPrompt(v) end end)
for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then makeBigPrompt(v) end end

local zoneNames = {}
local zbFolder = getZoneBuildsFolder()
if zbFolder then for _, m in ipairs(zbFolder:GetChildren()) do if m:IsA("Model") then table.insert(zoneNames, m.Name) end end end
if #zoneNames == 0 then zoneNames = {"Zone1"} end

local defendModes = {"None","ZigZag","Random","Circle","Juke"}
local selected = {} local selectedZones = {} local selectedEggZone = nil

-- ================= MAIN =================
TabMain:CreateSection({ Name = "Base" })
local baseOn = false local baseConn = nil
TabMain:CreateToggle({ Name = "Auto Base", Default = false, Callback = function(v)
    baseOn = v
    if baseOn then
        baseConn = ProximityPromptService.PromptTriggered:Connect(function(prompt, p)
            if p == plr and prompt.Name:lower():find("steal") then task.wait(0.2) walkToSafeBase() end
        end)
    else if baseConn then baseConn:Disconnect() end end
end })

TabMain:CreateSection({ Name = "Movement" })
local walkSliderRef = nil
walkSliderRef = TabMain:CreateSlider({ Name = "Speed", Min = SLIDER_MIN, Max = SLIDER_MAX, Default = getRealHumanoidSpeed(), Callback = function(v)
    sliderSpeed = v
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v hum:SetAttribute("BaseSpeed", v) end
end })

TabMain:CreateSection({ Name = "Steal" })
TabMain:CreateMultiDropdown({ Name = "Rarity", Items = rarityNames, Default = {}, Callback = function(val)
    selected = {}
    if type(val) == "table" then for _, n in ipairs(val) do selected[n] = true end end
end })
TabMain:CreateMultiDropdown({ Name = "Zone", Items = zoneNames, Default = {}, Callback = function(val)
    selectedZones = {}
    if type(val) == "table" then for _, n in ipairs(val) do selectedZones[n] = true end end
end })
TabMain:CreateDropdown({ Name = "Defend", Items = defendModes, Default = "None", Callback = function(val)
    defendMode = unwrap(val) or "None"
end })
TabMain:CreateInput({ Name = "Min $", Placeholder = "$ 0", Default = "", Callback = function(text)
    minCashFilter = parseFilterInput(text)
end })

local function getStealTargets()
    local folder = workspace:FindFirstChild("AnimalPickups")
    if not folder or next(selected) == nil then return {} end
    local out = {}
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") and selected[m:GetAttribute("Rarity")] then
            if next(selectedZones) ~= nil then local z = getAnimalZone(m) if not selectedZones[z] then continue end end
            if minCashFilter > 0 then local cash = parseCash(getCashPerSecond(m)) if cash < minCashFilter then continue end end
            table.insert(out, m)
        end
    end
    table.sort(out, function(a, b) return getRarityScore(a:GetAttribute("Rarity") or "") > getRarityScore(b:GetAttribute("Rarity") or "") end)
    return out
end

local function showStealNotif(model)
    if not model or not model.Parent then return end
    local rarity = model:GetAttribute("Rarity") or "Unknown"
    VoraNotify(model.Name, rarity .. " - " .. getCashPerSecond(model))
end

local stealOn = false
TabMain:CreateToggle({ Name = "Auto Steal", Default = false, Callback = function(v)
    stealOn = v
    if stealOn then
        if next(selected) == nil then VoraNotify("Error", "Rarity empty") return end
        walkToSafeBase()
        task.spawn(function()
            while stealOn do
                local list = getStealTargets()
                local found = #list > 0
                for _, m in ipairs(list) do if not stealOn then break end pcall(function() stealMethod(m) end) task.wait(0.5) end
                if not found then task.wait(0.8) end
            end
        end)
    end
end })
TabMain:CreateToggle({ Name = "Attack Carrier", Default = false, Callback = function(v) attackEnabled = v end })

TabMain:CreateSection({ Name = "Egg" })
TabMain:CreateDropdown({ Name = "Egg Zone", Items = zoneNames, Default = nil, Callback = function(val) selectedEggZone = unwrap(val) end })
TabMain:CreateToggle({ Name = "Big Egg", Default = true, Callback = function(v) bigEggPriority = v end })

local function getEggHealth(eggModel)
    if eggModel:GetAttribute("Health") then return eggModel:GetAttribute("Health") end
    for _, d in ipairs(eggModel:GetDescendants()) do local h = d:GetAttribute("Health") if h ~= nil then return h end end
    return nil
end
local function equipPickaxe()
    local char = plr.Character if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool.Name:lower():find("pickaxe") then return tool end
    for _, t in ipairs(plr.Backpack:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("pickaxe") then t.Parent = char return t end end
    for _, t in ipairs(plr.Backpack:GetChildren()) do if t:IsA("Tool") then t.Parent = char return t end end
    return char:FindFirstChildOfClass("Tool")
end

local breakOn = false
TabMain:CreateToggle({ Name = "Break Egg", Default = false, Callback = function(v)
    breakOn = v
    if breakOn then
        if not selectedEggZone then VoraNotify("Error", "Zone empty") breakOn = false return end
        task.spawn(function()
            while breakOn do
                local targets = getStealTargets()
                if #targets > 0 then
                    for _, m in ipairs(targets) do if not breakOn then break end pcall(function() stealMethod(m) end) task.wait(0.3) end
                    continue
                end
                local eggs = getEggsInZone(selectedEggZone)
                if #eggs == 0 then task.wait(1) continue end
                for _, egg in ipairs(eggs) do
                    if not breakOn then break end
                    if #getStealTargets() > 0 then break end
                    local pos, base = getOffsetPos(egg)
                    if not pos then local b = getBasePos(egg) if b then pos = Vector3.new(b.X, 3.5, b.Z + 3) base = Vector3.new(b.X, 3.5, b.Z) end end
                    if not pos then continue end
                    pcall(function()
                        walkDirect(pos, base, false)
                        equipPickaxe()
                        while breakOn and egg.Parent do
                            if #getStealTargets() > 0 then break end
                            local h = getEggHealth(egg)
                            if h == nil or h <= 0 then break end
                            task.wait(0.15)
                        end
                    end)
                    task.wait(0.2)
                end
                task.wait(0.5)
            end
        end)
    end
end })

TabMain:CreateSection({ Name = "Follow" })
local function getPlayerList()
    local l = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= plr then table.insert(l, p.Name) end end
    if #l == 0 then l = {"No Player"} end
    return l
end
local playerDropdown = TabMain:CreateDropdown({ Name = "Player List", Items = getPlayerList(), Default = "No Player", Callback = function(val)
    local name = unwrap(val)
    if name and name ~= "No Player" then selectedFollowPlayer = name end
end })
TabMain:CreateToggle({ Name = "Follow Player", Default = false, Callback = function(v)
    followEnabled = v
    if followEnabled then
        if not selectedFollowPlayer or selectedFollowPlayer == "No Player" then VoraNotify("Error", "Player empty") followEnabled = false return end
        task.spawn(function()
            while followEnabled do
                if selectedFollowPlayer then
                    local target = Players:FindFirstChild(selectedFollowPlayer)
                    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = target.Character.HumanoidRootPart
                        walkDirect(Vector3.new(hrp.Position.X, 3.5, hrp.Position.Z), hrp.Position, false)
                    end
                end
                task.wait(0.15)
            end
        end)
    end
end })
task.spawn(function() while task.wait(2) do pcall(function() if playerDropdown then playerDropdown:Refresh(getPlayerList()) end end) end end)

-- ================= MISC =================
TabMisc:CreateSection({ Name = "Guard" })
local noRagdollOn = false local ragdollConns = {} local lastYPos = 0 local lastSafeCF = nil
local function disableNoRagdoll()
    for _, c in ipairs(ragdollConns) do pcall(function() c:Disconnect() end) end
    ragdollConns = {} lastSafeCF = nil
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true) hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true) hum.BreakJointsOnDeath = true hum.PlatformStand = false end) end
end
local function enableNoRagdoll()
    for _, c in ipairs(ragdollConns) do pcall(function() c:Disconnect() end) end
    ragdollConns = {}
    local char = plr.Character local hum = char and char:FindFirstChildOfClass("Humanoid") local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then lastYPos = hrp.Position.Y lastSafeCF = hrp.CFrame end
    if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false) hum.BreakJointsOnDeath = false hum.PlatformStand = false end) end
    table.insert(ragdollConns, RunService.Heartbeat:Connect(function()
        local c = plr.Character local h = c and c:FindFirstChildOfClass("Humanoid") local r = c and c:FindFirstChild("HumanoidRootPart")
        if not h or not r then return end
        local curY = r.Position.Y local velY = r.AssemblyLinearVelocity.Y local deltaY = curY - lastYPos
        if h.FloorMaterial ~= Enum.Material.Air and velY < 5 and math.abs(deltaY) < 0.2 then lastSafeCF = r.CFrame end
        if deltaY > 0.25 or velY > 12 or r.AssemblyLinearVelocity.Magnitude > 40 then
            if lastSafeCF then r.CFrame = CFrame.new(lastSafeCF.Position + Vector3.new(0, 0.5, 0)) * (lastSafeCF - lastSafeCF.Position) else r.CFrame = CFrame.new(r.Position.X, lastYPos, r.Position.Z) end
            r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero r.Velocity = Vector3.zero
            h.PlatformStand = false h:ChangeState(Enum.HumanoidStateType.RunningNoPhysics) task.wait() h:ChangeState(Enum.HumanoidStateType.Running)
            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        end
        if h:GetState() == Enum.HumanoidStateType.Ragdoll or h:GetState() == Enum.HumanoidStateType.FallingDown or h.PlatformStand then h.PlatformStand = false h:ChangeState(Enum.HumanoidStateType.Running) end
        lastYPos = curY
    end))
    table.insert(ragdollConns, RunService.Stepped:Connect(function()
        local c = plr.Character local r = c and c:FindFirstChild("HumanoidRootPart")
        if not r then return end
        if r.AssemblyLinearVelocity.Y > 15 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X * 0.2, 0, r.AssemblyLinearVelocity.Z * 0.2) end
    end))
    task.spawn(function()
        while noRagdollOn do
            local c = plr.Character local h = c and c:FindFirstChildOfClass("Humanoid") local r = c and c:FindFirstChild("HumanoidRootPart")
            if h and r then
                if h:GetState() == Enum.HumanoidStateType.Ragdoll or h:GetState() == Enum.HumanoidStateType.FallingDown or h.PlatformStand then
                    h.PlatformStand = false h:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                    r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero task.wait() h:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
            task.wait(0.01)
        end
    end)
end
TabMisc:CreateToggle({ Name = "Anti Ragdoll", Default = false, Callback = function(v) noRagdollOn = v if v then enableNoRagdoll() else disableNoRagdoll() end end })

TabMisc:CreateSection({ Name = "Gamepass" })
local fastBreakOn = false local fastBreakConn = nil
local function setFastBreakAttribute(state)
    pcall(function() plr:SetAttribute("FastSwingOwned", state) end)
    pcall(function() if plr.Character then plr.Character:SetAttribute("FastSwingOwned", state) end end)
end
TabMisc:CreateToggle({ Name = "Fast Break", Default = false, Callback = function(v)
    fastBreakOn = v
    if fastBreakOn then
        setFastBreakAttribute(true)
        if fastBreakConn then fastBreakConn:Disconnect() end
        fastBreakConn = RunService.Heartbeat:Connect(function() if plr:GetAttribute("FastSwingOwned") ~= true then setFastBreakAttribute(true) end end)
    else if fastBreakConn then fastBreakConn:Disconnect() fastBreakConn = nil end setFastBreakAttribute(false) end
end })

-- ================= ESP =================
TabEsp:CreateSection({ Name = "Esp" })
TabEsp:CreateMultiDropdown({ Name = "Rarity", Items = rarityNames, Default = {}, Callback = function(val)
    selectedEspRarity = {}
    if type(val) == "table" then for _, n in ipairs(val) do selectedEspRarity[n] = true end elseif val then selectedEspRarity[val] = true end
    if espEnabled then refreshAllEsp() end
end })
local clearOnRespawn = true
TabEsp:CreateToggle({ Name = "Esp", Default = false, Callback = function(v)
    espEnabled = v
    if espEnabled then
        refreshAllEsp()
        task.spawn(function() while espEnabled do refreshAllEsp() task.wait(1.5) end end)
        local folder = workspace:FindFirstChild("AnimalPickups")
        if folder then
            folder.ChildAdded:Connect(function(m) if espEnabled and m:IsA("Model") then task.wait(0.2) createAnimalEsp(m) end end)
            folder.ChildRemoved:Connect(function(m) removeAnimalEsp(m) end)
        end
    else clearAllEsp() end
end })
TabEsp:CreateToggle({ Name = "Clear On Death", Default = true, Callback = function(v) clearOnRespawn = v end })
TabEsp:CreateSection({ Name = "Esp Egg" })
TabEsp:CreateMultiDropdown({ Name = "Zone", Items = zoneNames, Default = {}, Callback = function(val)
    selectedEggZones = {}
    if type(val) == "table" then for _, n in ipairs(val) do selectedEggZones[n] = true end end
    if eggEspEnabled then refreshEggEsp() end
end })
TabEsp:CreateMultiDropdown({ Name = "Filter", Items = {"Small","Standar","Big","Titan"}, Default = {}, Callback = function(val)
    selectedEggSizes = {}
    if type(val) == "table" then for _, n in ipairs(val) do selectedEggSizes[n] = true end end
    if eggEspEnabled then refreshEggEsp() end
end })
TabEsp:CreateToggle({ Name = "Egg Esp", Default = false, Callback = function(v)
    eggEspEnabled = v
    if eggEspEnabled then refreshEggEsp() task.spawn(function() while eggEspEnabled do refreshEggEsp() task.wait(1.5) end end) else clearAllEggEsp() end
end })

-- ================= PLOT =================
TabPlot:CreateSection({ Name = "Plot" })
TabPlot:CreateToggle({ Name = "Equip Best", Default = false, Callback = function(v)
    if v then task.spawn(function() while v do pcall(function() game.ReplicatedStorage.PetsInventoryRemote:FireServer("EquipBest", nil) end) task.wait(1.5) end end) end
end })
TabPlot:CreateSection({ Name = "Index" })
TabPlot:CreateToggle({ Name = "Claim Index", Default = false, Callback = function(v)
    if v then task.spawn(function() while v do pcall(function() game.ReplicatedStorage.IndexRemote:FireServer("ClaimAll", nil) end) task.wait(2) end end) end
end })

-- ================= BLATANT =================
TabBlatant:CreateSection({ Name = "Steal" })
TabBlatant:CreateButton({ Name = "Instant Steal", Callback = function()
    local folder = workspace:FindFirstChild("AnimalPickups")
    if not folder then return end
    local function getPromptAnchorPos(prompt)
        local p = prompt.Parent
        if p:IsA("BasePart") then return p.Position end
        if p:IsA("Model") then if p.PrimaryPart then return p.PrimaryPart.Position end local ok, cf = pcall(function() return p:GetPivot() end) if ok then return Vector3.new(cf.X, cf.Y, cf.Z) end for _, b in ipairs(p:GetDescendants()) do if b:IsA("BasePart") then return b.Position end end end
        local bp = p:FindFirstChildWhichIsA("BasePart", true)
        if bp then return bp.Position end
        return nil
    end
    local function findPromptNearModel(model, maxDist)
        local basePos = getBasePos(model)
        if not basePos then return nil end
        for _, v in ipairs(model:GetDescendants()) do if v:IsA("ProximityPrompt") then return v end end
        local closest = nil local minD = maxDist or 12
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Name:lower():find("steal") then
                local anchorPos = getPromptAnchorPos(v)
                if anchorPos then local d = (Vector3.new(anchorPos.X, 0, anchorPos.Z) - Vector3.new(basePos.X, 0, basePos.Z)).Magnitude if d < minD then minD = d closest = v end end
            end
        end
        return closest
    end
    local function firePromptZero(p)
        if not p then return end
        pcall(function() p.HoldDuration = 0 p.MaxActivationDistance = 15 p.RequiresLineOfSight = false end)
        if fireproximityprompt then pcall(function() fireproximityprompt(p, 0) end) else pcall(function() p:InputHoldBegin() p:InputHoldEnd() end) end
    end
    local candidates = {}
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            local cash = parseCash(getCashPerSecond(m))
            if cash == 0 then local attr = m:GetAttribute("CashPerSecond") or m:GetAttribute("CPS") if typeof(attr) == "number" then cash = attr elseif typeof(attr) == "string" then cash = parseCash(attr) end end
            if cash > 0 then table.insert(candidates, { model = m, cash = cash }) end
        end
    end
    if #candidates == 0 then return end
    table.sort(candidates, function(a, b) return a.cash > b.cash end)
    local bestModel = candidates[1].model
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local targetStart = tick()
    while tick() - targetStart < 0.2 do
        if not bestModel.Parent then break end
        local prompt = findPromptNearModel(bestModel, 12)
        if prompt then
            local anchorPos = getPromptAnchorPos(prompt)
            local basePos = getBasePos(bestModel)
            if anchorPos and basePos then
                local dist = (Vector3.new(anchorPos.X, 0, anchorPos.Z) - Vector3.new(basePos.X, 0, basePos.Z)).Magnitude
                if dist <= 12 then hrp.CFrame = CFrame.new(anchorPos + Vector3.new(0, 0.5, 0)) firePromptZero(prompt) touchSteal(bestModel) end
            end
        end
        if isDropVisible() then break end
        task.wait(0.01)
    end
    hrp.CFrame = SAFE_BASE_CF task.wait(0.05) hrp.CFrame = SAFE_BASE_CF
end })

TabBlatant:CreateSection({ Name = "Teleport" })
TabBlatant:CreateDropdown({ Name = "Zone", Items = zoneNames, Default = nil, Callback = function(val) selectedTeleportZone = unwrap(val) end })
TabBlatant:CreateButton({ Name = "Teleport", Callback = function()
    if not selectedTeleportZone then VoraNotify("Error", "Zone empty") return end
    pendingTeleportZone = selectedTeleportZone
    VoraNotify("Teleport", "Reset to " .. selectedTeleportZone)
    local char = plr.Character
    if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.Health = 0 else char:BreakJoints() end end
end })

-- ================= UPGRADE =================
TabUpgrade:CreateSection({ Name = "Auto Treadmill" })
local treadmillOn = false
TabUpgrade:CreateToggle({ Name = "Auto Upgrade", Default = false, Callback = function(v)
    treadmillOn = v
    if treadmillOn then task.spawn(function() while treadmillOn do pcall(function() game.ReplicatedStorage.UpgradeTreadmillRequest:FireServer() end) task.wait(1) end end) end
end })
TabUpgrade:CreateSection({ Name = "Auto Plot" })
local plotUpgradeOn = false
TabUpgrade:CreateToggle({ Name = "Auto Upgrade", Default = false, Callback = function(v)
    plotUpgradeOn = v
    if plotUpgradeOn then task.spawn(function() while plotUpgradeOn do pcall(function() game.ReplicatedStorage.UpgradePlotRequest:FireServer() end) task.wait(1) end end) end
end })

-- ================= DIAMOND / FARM EGG =================
-- Logic: break egg di zone -> tunggu waktu habis -> tween ke EggGemDrops sampai habis -> loop
local diamondZone = nil
local diamondFarmSpeed = 60
local diamondOn = false
local diamondTween = nil

local function getEggTimeLeft(egg)
    -- Coba semua nama attribute / value yang biasa dipake game buat timer egg
    for _, name in ipairs({"TimeLeft","Time","Remaining","RemainingTime","Timer","HatchTime","HatchIn","Duration","Countdown","TimeRemaining"}) do
        local v = egg:GetAttribute(name)
        if typeof(v) == "number" then return v end
    end
    for _, d in ipairs(egg:GetDescendants()) do
        if (d:IsA("NumberValue") or d:IsA("IntValue")) and (d.Name:lower():find("time") or d.Name:lower():find("timer") or d.Name:lower():find("left") or d.Name:lower():find("remain")) then
            return d.Value
        end
        if d:IsA("TextLabel") and (d.Name:lower():find("time") or d.Name:lower():find("timer")) then
            local n = tonumber(tostring(d.Text):match("[%d%.]+"))
            if n then return n end
        end
    end
    return nil -- nil = game ga expose timer, fallback: anggap habis kalau egg udah ke-break / hilang
end

local function tweenTo(pos, speed)
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not pos then return end
    if diamondTween then pcall(function() diamondTween:Cancel() end) end
    local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
    local dur = math.max(dist / math.max(speed, 1), 0.15)
    diamondTween = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = CFrame.new(Vector3.new(pos.X, pos.Y, pos.Z)) })
    diamondTween:Play()
    diamondTween.Completed:Wait()
end

local function collectEggGemDrops()
    local drops = workspace:FindFirstChild("EggGemDrops")
    if not drops then return end
    -- Sampai gada child dari parent EggGemDrops
    while diamondOn and drops.Parent and #drops:GetChildren() > 0 do
        local gotOne = false
        for _, drop in ipairs(drops:GetChildren()) do
            if not diamondOn then break end
            if not drop.Parent then continue end
            local pos = getBasePos(drop)
            if not pos then continue end
            gotOne = true
            -- Tween sesuai kecepatan slider ke drop
            pcall(function() tweenTo(Vector3.new(pos.X, pos.Y + 1, pos.Z), diamondFarmSpeed) end)
            task.wait(0.15)
            -- Kalau drop udah keambil, lanjut ke child berikutnya
            if not drop.Parent then continue end
            -- Coba sentuh juga biar ke-pickup
            local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            local part = drop:IsA("BasePart") and drop or drop:FindFirstChildWhichIsA("BasePart")
            if hrp and part then pcall(function() firetouchinterest(hrp, part, 0) task.wait(0.05) firetouchinterest(hrp, part, 1) end) end
        end
        if not gotOne then task.wait(0.3) end
        task.wait(0.1)
    end
end

local function diamondFarmLoop()
    while diamondOn do
        if not diamondZone then task.wait(0.5) continue end
        local eggs = getEggsInZone(diamondZone)
        if #eggs == 0 then
            -- Ga ada egg, cek dulu siapa tau masih ada drops sisa
            collectEggGemDrops()
            task.wait(1)
            continue
        end
        for _, egg in ipairs(eggs) do
            if not diamondOn then break end
            -- 1. Break egg sesuai zone, pake logic break egg yang sama
            local pos, base = getOffsetPos(egg)
            if not pos then local b = getBasePos(egg) if b then pos = Vector3.new(b.X, 3.5, b.Z + 3) base = Vector3.new(b.X, 3.5, b.Z) end end
            if not pos then continue end
            pcall(function()
                walkDirect(pos, base, false)
                equipPickaxe()
                while diamondOn and egg.Parent do
                    local h = getEggHealth(egg)
                    if h ~= nil and h <= 0 then break end
                    -- 2. Kalau waktu sudah habis -> stop break, langsung ke collect
                    local t = getEggTimeLeft(egg)
                    if t ~= nil and t <= 0 then break end
                    task.wait(0.15)
                end
            end)
            if not diamondOn then break end
            -- 3. Waktu habis / egg ke-break -> tween ke EggGemDrops sampai habis
            collectEggGemDrops()
            task.wait(0.2)
        end
        task.wait(0.5)
    end
end

TabDiamond:CreateSection({ Name = "Farm Egg" })
TabDiamond:CreateDropdown({ Name = "Zone", Items = zoneNames, Default = nil, Callback = function(val) diamondZone = unwrap(val) end })
TabDiamond:CreateSlider({ Name = "Farm Egg Speed", Min = 16, Max = 500, Default = 60, Callback = function(v) diamondFarmSpeed = v end })
TabDiamond:CreateToggle({ Name = "Farm Diamond", Default = false, Callback = function(v)
    diamondOn = v
    if diamondOn then
        if not diamondZone then VoraNotify("Error", "Zone empty") diamondOn = false return end
        task.spawn(diamondFarmLoop)
    else
        if diamondTween then pcall(function() diamondTween:Cancel() end) diamondTween = nil end
    end
end })
TabDiamond:CreateSection({ Name = "Info" })
TabDiamond:CreateLabel({ Name = "Break egg di zone -> waktu habis -> tween ke EggGemDrops sampai habis -> loop." })

-- ================= PANEL BAWAAN LIB BARU =================
-- Gantiin tracker custom lama. Window:Panel(o) return K yang sama kayak Tab.
local trackerMode = "Blatant"
local trackerPanel = Window:Panel({ Title = "Animal Tracker", Subtitle = "Steal tercepat", Open = false })

local function getPromptAnchorPosT(pr)
    local p = pr.Parent
    if p:IsA("BasePart") then return p.Position end
    if p:IsA("Model") then if p.PrimaryPart then return p.PrimaryPart.Position end local ok, cf = pcall(function() return p:GetPivot() end) if ok then return Vector3.new(cf.X, cf.Y, cf.Z) end for _, b in ipairs(p:GetDescendants()) do if b:IsA("BasePart") then return b.Position end end end
    local bp = p:FindFirstChildWhichIsA("BasePart", true)
    if bp then return bp.Position end
    return nil
end
local function findPromptNearT(m, md)
    local bp = getBasePos(m)
    if not bp then return nil end
    for _, v in ipairs(m:GetDescendants()) do if v:IsA("ProximityPrompt") then return v end end
    local cl = nil local mn = md or 12
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Name:lower():find("steal") then
            local ap = getPromptAnchorPosT(v)
            if ap then local d = (Vector3.new(ap.X, 0, ap.Z) - Vector3.new(bp.X, 0, bp.Z)).Magnitude if d < mn then mn = d cl = v end end
        end
    end
    return cl
end
local function fireZeroT(p)
    if not p then return end
    pcall(function() p.HoldDuration = 0 p.MaxActivationDistance = 15 p.RequiresLineOfSight = false end)
    if fireproximityprompt then pcall(function() fireproximityprompt(p, 0) end) else pcall(function() p:InputHoldBegin() p:InputHoldEnd() end) end
end
local function instantSteal(m)
    if not m or not m.Parent then return end
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local st = tick()
    while tick() - st < 0.4 do
        if not m.Parent then break end
        local pr = findPromptNearT(m, 12)
        if pr then
            local an = getPromptAnchorPosT(pr)
            local bs = getBasePos(m)
            if an and bs then if (Vector3.new(an.X, 0, an.Z) - Vector3.new(bs.X, 0, bs.Z)).Magnitude <= 12 then hrp.CFrame = CFrame.new(an + Vector3.new(0, 0.5, 0)) fireZeroT(pr) touchSteal(m) end end
        end
        if isDropVisible() then break end
        task.wait(0.01)
    end
    hrp.CFrame = SAFE_BASE_CF task.wait(0.05) hrp.CFrame = SAFE_BASE_CF
end
local function legitStealTracker(m)
    if not m or not m.Parent then return end
    local tries = 0
    while tries < 8 and m.Parent do
        if isDropVisible() then if isCarryingTarget(m) then break end fireDropNow() task.wait(0.35) tries += 1 continue end
        local p, b = getOffsetPos(m)
        if not p then local bp = getBasePos(m) if bp then p = Vector3.new(bp.X, 3.5, bp.Z + 3) b = Vector3.new(bp.X, 3.5, bp.Z) end end
        if p then walkDirect(p, b, false) end
        touchSteal(m) fireSteal(m) pressE() task.wait(0.25) tries += 1
    end
    if isCarryingTarget(m) then walkToSafeBaseFallback(m) end
end

local function getBestAnimal()
    local folder = workspace:FindFirstChild("AnimalPickups")
    if not folder then return nil end
    local best, bestCash = nil, -1
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            local cv = parseCash(getCashPerSecond(m))
            if cv == 0 then local at = m:GetAttribute("CashPerSecond") or m:GetAttribute("CPS") if typeof(at) == "number" then cv = at elseif typeof(at) == "string" then cv = parseCash(at) end end
            if cv > bestCash then bestCash = cv best = m end
        end
    end
    return best, bestCash
end

trackerPanel:CreateSection({ Name = "Tracker" })
trackerPanel:CreateDropdown({ Name = "Mode", Items = {"Blatant","Legit"}, Default = "Blatant", Callback = function(val) trackerMode = unwrap(val) or "Blatant" end })
local trackerLabel = trackerPanel:CreateLabel({ Name = "0 animals" })
trackerPanel:CreateButton({ Name = "Steal Best", Callback = function()
    local best = getBestAnimal()
    if not best then VoraNotify("Tracker", "No animal") return end
    task.spawn(function() pcall(function() if trackerMode == "Blatant" then instantSteal(best) else legitStealTracker(best) end end) end)
end })
trackerPanel:CreateButton({ Name = "Open / Close", Callback = function() trackerPanel:Switch() end })

task.spawn(function()
    while task.wait(0.6) do
        pcall(function()
            local folder = workspace:FindFirstChild("AnimalPickups")
            local n = folder and #folder:GetChildren() or 0
            if trackerLabel then trackerLabel:Set(n .. " animals • " .. trackerMode) end
        end)
    end
end)

-- ================= CHARACTER / LOOP =================
plr.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid", 15)
    if hum then
        local realSpeed = hum.WalkSpeed
        sliderSpeed = realSpeed
        hum:SetAttribute("BaseSpeed", realSpeed)
        if walkSliderRef then walkSliderRef:Set(realSpeed) end
    end
    task.wait(0.5)
    if noRagdollOn then enableNoRagdoll() end
    if fastBreakOn then setFastBreakAttribute(true) end
    if clearOnRespawn then clearAllEsp() clearAllEggEsp() end
    if espEnabled then task.wait(0.5) refreshAllEsp() end
    if eggEspEnabled then task.wait(0.5) refreshEggEsp() end
end)
plr.CharacterAdded:Connect(function(char)
    if pendingTeleportZone then
        local zoneName = pendingTeleportZone
        local hrp = char:WaitForChild("HumanoidRootPart", 15)
        if hrp then task.wait(0.2) local pos = getZoneTeleportPos(zoneName) if pos then hrp.CFrame = CFrame.new(pos) task.wait(0.15) hrp.CFrame = CFrame.new(pos) end end
        pendingTeleportZone = nil
    end
end)
RunService.Heartbeat:Connect(function()
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then if math.abs(hum.WalkSpeed - sliderSpeed) > 0.1 then hum.WalkSpeed = sliderSpeed end end
end)
