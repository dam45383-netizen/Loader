local Window = getgenv().SORU_Window
if not Window then return end
local Players=game:GetService("Players") local TweenService=game:GetService("TweenService") local ProximityPromptService=game:GetService("ProximityPromptService")
local UserInputService=game:GetService("UserInputService") local VIM=game:GetService("VirtualInputManager") local RS=game:GetService("ReplicatedStorage") local RunService=game:GetService("RunService")
local plr=Players.LocalPlayer

local SAFE_BASE_POS=Vector3.new(-75,3.5,-7.4) local HELPER_DROP_POS=Vector3.new(-105.2,3.7,-6.2) local OFFSET_DIST=3 local RANGE=15
local sliderSpeed=16
local ACCENT=Color3.fromRGB(139,92,246) local DIM=Color3.fromRGB(148,140,180)

local RARITY_SCORE={["Common"]=1,["Uncommon"]=2,["Rare"]=3,["Epic"]=4,["Legendary"]=5,["Mythic"]=6,["Secret"]=7,["Godly"]=8,["Cosmic"]=9,["Divine"]=10,["Celestial"]=11}
local RARITY_COLOR={["Common"]=Color3.fromRGB(180,180,180),["Uncommon"]=Color3.fromRGB(92,255,92),["Rare"]=Color3.fromRGB(85,170,255),["Epic"]=Color3.fromRGB(170,85,255),["Legendary"]=Color3.fromRGB(255,180,0),["Mythic"]=Color3.fromRGB(255,60,60),["Secret"]=Color3.fromRGB(0,0,0),["Godly"]=Color3.fromRGB(255,223,0),["Cosmic"]=Color3.fromRGB(0,255,255),["Divine"]=Color3.fromRGB(255,255,255),["Celestial"]=Color3.fromRGB(255,120,255)}
local function getRarityColor(r) return RARITY_COLOR[r] or ACCENT end
local rarityNames={} local rf=RS:FindFirstChild("Rarities") if rf then for _,c in ipairs(rf:GetChildren()) do table.insert(rarityNames,c.Name) end else rarityNames={"Common","Rare","Epic","Legendary","Mythic","Secret"} end
local function getRarityScore(n) if RARITY_SCORE[n] then return RARITY_SCORE[n] end for i,v in ipairs(rarityNames) do if v==n then return i end end return 0 end
local function getBasePos(m) local b if m.PrimaryPart then b=m.PrimaryPart.Position else local ok,cf=pcall(function() return m:GetPivot() end) if ok then b=Vector3.new(cf.X,cf.Y,cf.Z) else for _,v in ipairs(m:GetDescendants()) do if v:IsA("BasePart") then b=v.Position break end end end end return b end
local function getOffsetPos(m) local base=getBasePos(m) if not base then return nil,nil end local hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") local dir=hrp and Vector3.new(hrp.Position.X-base.X,0,hrp.Position.Z-base.Z) or Vector3.new(0,0,1) if dir.Magnitude<1 then dir=Vector3.new(0,0,1) end return Vector3.new(base.X,3.5,base.Z)+dir.Unit*OFFSET_DIST,Vector3.new(base.X,3.5,base.Z) end
local function getZoneBuildsFolder() local b=workspace:FindFirstChild("Build") if b then local zb=b:FindFirstChild("ZoneBuilds") if zb then return zb end end return workspace:FindFirstChild("ZoneBuilds") or workspace:FindFirstChild("Build") end
local function getAnimalZone(model) local pos=getBasePos(model) if not pos then return "Unknown" end local zb=getZoneBuildsFolder() if not zb then return "Unknown" end local closest="Unknown" local minD=math.huge for _,z in ipairs(zb:GetChildren()) do if z:IsA("Model") then local zp=getBasePos(z) if zp then local d=(Vector3.new(pos.X,0,pos.Z)-Vector3.new(zp.X,0,zp.Z)).Magnitude if d<minD then minD=d closest=z.Name end end end end return closest end

-- FIXED: biar highest $ kebaca
local function getCashPerSecond(model)
    for _,v in ipairs(model:GetDescendants()) do
        if v:IsA("TextLabel") then
            local n=v.Name:lower()
            if (n:find("cash") or n:find("cps") or n:find("persec")) and (v.Text:find("%$") or v.Text:find("/")) then return v.Text end
        end
    end
    for _,v in ipairs(model:GetDescendants()) do if v.Name=="CashPerSecond" and v:IsA("TextLabel") then return v.Text end end
    local attr=model:GetAttribute("CashPerSecond") or model:GetAttribute("CPS") or model:GetAttribute("Cash")
    if attr then return tostring(attr) end
    return "0"
end
local function parseCash(text)
    if not text then return 0 end
    local s=tostring(text):upper()
    s=s:gsub("%$",""):gsub("/SEC",""):gsub("/S",""):gsub(" ",""):gsub(",","")
    local num=tonumber(s:match("[%d%.]+")) if not num then return 0 end
    if s:find("T") then num*=1e12 elseif s:find("B") then num*=1e9 elseif s:find("M") then num*=1e6 elseif s:find("K") then num*=1e3 end
    return num
end
local function parseFilterInput(text) if not text or text=="" then return 0 end return parseCash(text) end

-- NEW: helper buat (zone)-(model)
local function getZoneTargetPos(zoneName)
    local zb=getZoneBuildsFolder() if not zb then return nil end
    local zoneModel=zb:FindFirstChild(zoneName) if not zoneModel then return nil end
    -- cari model drop di dalam zone (kalau ada) -> Drop / Base / Plot / Main
    for _,name in ipairs({"Drop","Base","Plot","Main","Center","DropPoint"}) do
        local m=zoneModel:FindFirstChild(name)
        if m then local p=getBasePos(m) if p then return Vector3.new(p.X,3.5,p.Z), m end end
    end
    local p=getBasePos(zoneModel)
    if p then return Vector3.new(p.X,3.5,p.Z), zoneModel end
    return nil
end

local defendMode="None" local attackEnabled=false local minCashFilter=0 local bigEggPriority=true
local selectedFollowPlayer=nil local followEnabled=false
local espEnabled=false local selectedEspRarity={} local espCache={}
local function getWalkSpeed() return sliderSpeed end
do local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") if hum then sliderSpeed=hum.WalkSpeed end end

local function findDropButton() for _,v in ipairs(plr.PlayerGui:GetDescendants()) do if v:IsA("TextButton") and (v.Name:lower():find("drop") or v.Text:lower():find("drop")) then return v end end return nil end
local function isDropVisible() local btn=findDropButton() if not btn then return false end if not btn.Visible then return false end local cur=btn.Parent while cur and cur~=plr.PlayerGui do if cur:IsA("GuiObject") and not cur.Visible then return false end cur=cur.Parent end return true end
local function fireDropNow() local dropBtn=findDropButton() if dropBtn then pcall(function() dropBtn:Activate() end) end local remote=RS:FindFirstChild("DropCarriedRemote") or RS:FindFirstChild("DropCarriedRemote",true) or RS:FindFirstChild("DropCarried",true) if remote then pcall(function() remote:FireServer() end) end end
local function getClosestAnimalToHRP(maxDist) local hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") if not hrp then return nil end local closest=nil local minD=maxDist or 8 local folder=workspace:FindFirstChild("AnimalPickups") if folder then for _,m in ipairs(folder:GetChildren()) do if m:IsA("Model") then local pos=getBasePos(m) if pos then local d=(Vector3.new(hrp.Position.X,0,hrp.Position.Z)-Vector3.new(pos.X,0,pos.Z)).Magnitude if d<minD then minD=d closest=m end end end end end return closest end
local function isCarryingTarget(targetModel) if not isDropVisible() then return false end local closest=getClosestAnimalToHRP(8) if not closest then return true end if closest==targetModel then return true end if closest.Name==targetModel.Name and closest:GetAttribute("Rarity")==targetModel:GetAttribute("Rarity") then return true end return false end

local function walkDirect(targetPos,lookAt,keepRot) local char=plr.Character local hrp=char and char:FindFirstChild("HumanoidRootPart") if not hrp or not targetPos then return end if lookAt then lookAt=Vector3.new(lookAt.X,targetPos.Y,lookAt.Z) end pcall(function() hrp.AssemblyLinearVelocity=Vector3.zero hrp.AssemblyAngularVelocity=Vector3.zero end) local function distLeft() return (Vector3.new(hrp.Position.X,0,hrp.Position.Z)-Vector3.new(targetPos.X,0,targetPos.Z)).Magnitude end if distLeft()<1.2 then return end while distLeft()>1.2 do if not char or not hrp.Parent then break end local ws=getWalkSpeed() local cur=Vector3.new(hrp.Position.X,targetPos.Y,hrp.Position.Z) local dir=Vector3.new(targetPos.X-cur.X,0,targetPos.Z-cur.Z) if dir.Magnitude<0.1 then break end dir=dir.Unit local dt=RunService.Heartbeat:Wait() local step=dir*ws*dt if step.Magnitude>distLeft() then step=dir*distLeft() end local newPos=cur+step local cf=keepRot and CFrame.new(newPos)*(hrp.CFrame-hrp.CFrame.Position) or (lookAt and CFrame.lookAt(newPos,lookAt) or CFrame.lookAt(newPos,newPos+dir)) hrp.CFrame=cf hrp.AssemblyLinearVelocity=Vector3.zero end end
local function walkDirectFallback(targetPos,keepRot,originalAnimal) local char=plr.Character local hrp=char and char:FindFirstChild("HumanoidRootPart") if not hrp or not targetPos then return false end pcall(function() hrp.AssemblyLinearVelocity=Vector3.zero hrp.AssemblyAngularVelocity=Vector3.zero end) local function distLeft() return (Vector3.new(hrp.Position.X,0,hrp.Position.Z)-Vector3.new(targetPos.X,0,targetPos.Z)).Magnitude end if distLeft()<1.2 then return true end while distLeft()>1.2 do if not char or not hrp.Parent then return false end if not isDropVisible() then if originalAnimal and originalAnimal.Parent then local p,b=getOffsetPos(originalAnimal) if p then walkDirect(p,b,false) end end return false end local ws=getWalkSpeed() local cur=Vector3.new(hrp.Position.X,targetPos.Y,hrp.Position.Z) local dir=Vector3.new(targetPos.X-cur.X,0,targetPos.Z-cur.Z) if dir.Magnitude<0.1 then break end dir=dir.Unit local dt=RunService.Heartbeat:Wait() local step=dir*ws*dt if step.Magnitude>distLeft() then step=dir*distLeft() end local newPos=cur+step local cf=keepRot and CFrame.new(newPos)*(hrp.CFrame-hrp.CFrame.Position) or CFrame.lookAt(newPos,newPos+dir) hrp.CFrame=cf hrp.AssemblyLinearVelocity=Vector3.zero end return true end
local function walkDefendFallback(targetPos,mode,originalAnimal) if mode=="None" or not mode then return walkDirectFallback(targetPos,true,originalAnimal) end local hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") if not hrp then return false end local start=Vector3.new(hrp.Position.X,targetPos.Y,hrp.Position.Z) local dir=(targetPos-start) local dist=Vector3.new(dir.X,0,dir.Z).Magnitude if dist<5 then return walkDirectFallback(targetPos,true,originalAnimal) end dir=Vector3.new(dir.X,0,dir.Z).Unit local perp=Vector3.new(-dir.Z,0,dir.X) local points={} if mode=="ZigZag" then for i=1,4 do local t=i/5 local baseP=start:Lerp(targetPos,t) local offset=(i%2==0 and 1 or -1)*10 table.insert(points,baseP+perp*offset) end elseif mode=="Random" then for i=1,4 do local t=i/5 local baseP=start:Lerp(targetPos,t) table.insert(points,baseP+perp*math.random(-12,12)) end elseif mode=="Circle" then for i=1,6 do local t=i/7 local baseP=start:Lerp(targetPos,t) local ang=i*60 table.insert(points,baseP+Vector3.new(math.cos(math.rad(ang))*8,0,math.sin(math.rad(ang))*8)) end elseif mode=="Juke" then for i=1,5 do local t=i/6 local baseP=start:Lerp(targetPos,t) local offset=(i%2==0 and 14 or -14)+math.random(-4,4) table.insert(points,baseP+perp*offset) end end for _,p in ipairs(points) do local ok=walkDirectFallback(p,true,originalAnimal) if not ok then return false end task.wait(0.05) end return walkDirectFallback(targetPos,true,originalAnimal) end
local function walkToSafeBaseFallback(originalAnimal) local ok=walkDefendFallback(Vector3.new(-75,3.5,-7.4),defendMode,originalAnimal) if not ok then return false end ok=walkDefendFallback(SAFE_BASE_POS,defendMode,originalAnimal) return ok end
local function walkToSafeBase() walkDirect(Vector3.new(-75,3.5,-7.4),nil,true) walkDirect(SAFE_BASE_POS,nil,true) end

local function makeBigPrompt(p) if not p:IsA("ProximityPrompt") then return end pcall(function() p.HoldDuration=0 p.MaxActivationDistance=RANGE p.RequiresLineOfSight=false p.KeyboardKeyCode=Enum.KeyCode.E p.Exclusivity=Enum.ProximityPromptExclusivity.OnePerButton end) end
local function firePrompt(p) if not p:IsA("ProximityPrompt") then return end makeBigPrompt(p) if fireproximityprompt then pcall(fireproximityprompt,p,0) end pcall(function() p:InputHoldBegin() task.wait(0.05) p:InputHoldEnd() end) end
local function fireSteal(m) if not m or not m.Parent then return end for _,v in ipairs(m:GetDescendants()) do if v:IsA("ProximityPrompt") then firePrompt(v) end end end
local function touchSteal(m) if not m or not m.Parent then return end local hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") local part=m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart") if hrp and part then pcall(function() firetouchinterest(hrp,part,0) task.wait(0.02) firetouchinterest(hrp,part,1) end) end end
local function pressE() pcall(function() VIM:SendKeyEvent(true,Enum.KeyCode.E,false,game) task.wait(0.05) VIM:SendKeyEvent(false,Enum.KeyCode.E,false,game) end) end
local function getClosestPlayerToModel(model,maxDist) local pos=getBasePos(model) if not pos then return nil end local closest=nil local minD=maxDist or 20 for _,p in ipairs(Players:GetPlayers()) do if p~=plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local hrp=p.Character.HumanoidRootPart local d=(Vector3.new(hrp.Position.X,0,hrp.Position.Z)-Vector3.new(pos.X,0,pos.Z)).Magnitude if d<minD then minD=d closest=p end end end return closest end
local function equipBat() local char=plr.Character if not char then return nil end local bat=char:FindFirstChildWhichIsA("Tool") if bat and bat.Name:lower():find("bat") then return bat end for _,t in ipairs(plr.Backpack:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("bat") then t.Parent=char return t end end for _,t in ipairs(plr.Backpack:GetChildren()) do if t:IsA("Tool") then t.Parent=char return t end end return char:FindFirstChildOfClass("Tool") end
local function attackCarrier(carrier) if not attackEnabled then return end if not carrier or not carrier.Character then return end local char=carrier.Character local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end for i=1,20 do if not char.Parent or not attackEnabled then break end local myHrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") if not myHrp then break end local pred=hrp.Position+hrp.CFrame.LookVector*5 pred=Vector3.new(pred.X,3.5,pred.Z) walkDirect(pred,hrp.Position,false) local bat=equipBat() if bat then pcall(function() bat:Activate() end) pcall(function() VIM:SendMouseButtonEvent(0,0,0,true,game,0) task.wait(0.05) VIM:SendMouseButtonEvent(0,0,0,false,game,0) end) end task.wait(0.15) local dist=(Vector3.new(myHrp.Position.X,0,myHrp.Position.Z)-Vector3.new(hrp.Position.X,0,hrp.Position.Z)).Magnitude if dist>30 then break end end end

local function showStealNotif(model) if not model or not model.Parent then return end local rarity=model:GetAttribute("Rarity") or "Unknown" local weight=model:GetAttribute("WeightKg") or model:GetAttribute("Weight") or 0 Window.Notify("STEAL "..model.Name:upper(), tostring(weight).." KG "..string.upper(rarity).." "..getCashPerSecond(model), ACCENT, 3) end

-- === STEAL METHOD FINAL ( Dipake Auto Steal + Break Egg ) ===
local function stealMethod(targetModel)
    if not targetModel or not targetModel.Parent then return end
    showStealNotif(targetModel)
    local lastPos=getBasePos(targetModel)
    local tries=0
    while tries<8 and targetModel.Parent do
        if isDropVisible() then
            if not isCarryingTarget(targetModel) then fireDropNow() task.wait(0.35) tries+=1 continue else break end
        end
        local curPos=getBasePos(targetModel)
        if curPos and lastPos and (curPos-lastPos).Magnitude>2 then local carrier=getClosestPlayerToModel(targetModel,20) if carrier and attackEnabled then attackCarrier(carrier) end end
        lastPos=curPos
        local p,b=getOffsetPos(targetModel) if p then walkDirect(p,b,false) end
        touchSteal(targetModel) fireSteal(targetModel) pressE() task.wait(0.25) tries+=1
        if isDropVisible() and not isCarryingTarget(targetModel) then fireDropNow() task.wait(0.3) end
    end
    if not isDropVisible() then walkToSafeBase() return end
    if not isCarryingTarget(targetModel) then fireDropNow() task.wait(0.3) return end

    -- 1. KE (ZONE)-(MODEL) DULU - BUKAN LANGSUNG BASE
    local zoneName=getAnimalZone(targetModel)
    local zonePos, zoneModelObj = getZoneTargetPos(zoneName)
    local hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if zonePos and hrp then
        Window.Notify("ZONE COMBO", "Ke "..zoneName.." -> "..(zoneModelObj and zoneModelObj.Name or "Model"), DIM, 2)
        walkDirect(zonePos, nil, true)
        task.wait(0.2)
    else
        walkDirect(HELPER_DROP_POS, nil, true)
        task.wait(0.15)
    end

    -- 2. TELEPORT BALIK KE TARGET + INTERACT LAGI
    if targetModel.Parent then
        hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        local tPos=getBasePos(targetModel)
        if tPos and hrp then
            hrp.CFrame=CFrame.new(Vector3.new(tPos.X,3.5,tPos.Z+2))
            task.wait(0.08)
            for i=1,5 do fireSteal(targetModel) touchSteal(targetModel) pressE() task.wait(0.04) end
            task.wait(0.1)
        end
    end

    -- 3. INSTANT TELEPORT KE BASE KAYA BLATANT
    hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame=CFrame.new(SAFE_BASE_POS) end
end

local function removeAnimalEsp(model) local data=espCache[model] if data then pcall(function() if data.hl then data.hl:Destroy() end end) pcall(function() if data.bb then data.bb:Destroy() end end) espCache[model]=nil end end
local function clearAllEsp() for m,_ in pairs(espCache) do removeAnimalEsp(m) end table.clear(espCache) end
local function createAnimalEsp(model) if not model or not model.Parent then return end if espCache[model] then return end if not model:IsA("Model") then return end local rarity=model:GetAttribute("Rarity") or "Unknown" if next(selectedEspRarity)~=nil and not selectedEspRarity[rarity] then return end local adornee=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") if not adornee then return end local color=getRarityColor(rarity) local hl=Instance.new("Highlight") hl.Name="SoruEspHL" hl.Adornee=model hl.FillColor=color hl.OutlineColor=color hl.FillTransparency=0.65 hl.OutlineTransparency=0 hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.Parent=model local bb=Instance.new("BillboardGui") bb.Name="SoruEspBB" bb.Adornee=adornee bb.Size=UDim2.fromOffset(165,56) bb.StudsOffset=Vector3.new(0,4.2,0) bb.AlwaysOnTop=true bb.Parent=adornee local f=Instance.new("Frame",bb) f.Size=UDim2.new(1,0,1,0) f.BackgroundColor3=Color3.fromRGB(20,18,32) f.BackgroundTransparency=0.12 Instance.new("UICorner",f).CornerRadius=UDim.new(0,8) local st=Instance.new("UIStroke",f) st.Color=color st.Transparency=0.2 st.Thickness=1 local n=Instance.new("TextLabel",f) n.Size=UDim2.new(1,-8,0,14) n.Position=UDim2.new(0,5,0,4) n.BackgroundTransparency=1 n.Text=model.Name:upper() n.Font=Enum.Font.GothamBold n.TextSize=10 n.TextColor3=Color3.new(1,1,1) n.TextXAlignment=Enum.TextXAlignment.Left n.TextTruncate=Enum.TextTruncate.AtEnd local rLbl=Instance.new("TextLabel",f) rLbl.Size=UDim2.new(1,-8,0,11) rLbl.Position=UDim2.new(0,5,0,18) rLbl.BackgroundTransparency=1 rLbl.Text=string.upper(rarity).." "..getCashPerSecond(model) rLbl.Font=Enum.Font.GothamMedium rLbl.TextSize=9 rLbl.TextColor3=color rLbl.TextXAlignment=Enum.TextXAlignment.Left local w=model:GetAttribute("WeightKg") or model:GetAttribute("Weight") or 0 local zone=getAnimalZone(model) local wLbl=Instance.new("TextLabel",f) wLbl.Size=UDim2.new(1,-8,0,10) wLbl.Position=UDim2.new(0,5,0,30) wLbl.BackgroundTransparency=1 wLbl.Text=tostring(w).." KG "..zone wLbl.Font=Enum.Font.GothamMedium wLbl.TextSize=8 wLbl.TextColor3=DIM wLbl.TextXAlignment=Enum.TextXAlignment.Left espCache[model]={hl=hl,bb=bb} end
local function refreshAllEsp() if not espEnabled then clearAllEsp() return end local folder=workspace:FindFirstChild("AnimalPickups") if not folder then return end for _,m in ipairs(folder:GetChildren()) do if m:IsA("Model") then local rarity=m:GetAttribute("Rarity") or "Unknown" local allowed=next(selectedEspRarity)==nil or selectedEspRarity[rarity] if allowed then createAnimalEsp(m) else removeAnimalEsp(m) end end end for m,_ in pairs(espCache) do if not m.Parent then removeAnimalEsp(m) end end end

workspace.DescendantAdded:Connect(function(v) if v:IsA("ProximityPrompt") then task.wait(0.1) makeBigPrompt(v) end end)
for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then makeBigPrompt(v) end end

local zoneNames={} local zbFolder=getZoneBuildsFolder() if zbFolder then for _,m in ipairs(zbFolder:GetChildren()) do if m:IsA("Model") then table.insert(zoneNames,m.Name) end end end if #zoneNames==0 then zoneNames={"Zone1"} end
local defendModes={"None","ZigZag","Random","Circle","Juke"} local selected={} local selectedZones={} local selectedEggZone=nil

local MainTab=Window:Tab({Title="Main"}) local MiscTab=Window:Tab({Title="Misc"}) local EspTab=Window:Tab({Title="Esp"}) local PlotTab=Window:Tab({Title="Plot"}) local BlatantTab=Window:Tab({Title="Blatant"})

MainTab:Section("BASE SYSTEM")
local baseOn=false local baseConn=nil
MainTab:Toggle({Title="Auto Base", Flag="AutoBase", Default=false, Callback=function(v) baseOn=v if baseOn then baseConn=ProximityPromptService.PromptTriggered:Connect(function(prompt,p) if p==plr and prompt.Name:lower():find("steal") then task.wait(0.2) walkToSafeBase() end end) Window.Notify("BASE", "Auto Base ON", ACCENT, 2) else if baseConn then baseConn:Disconnect() end end end})

MainTab:Section("MOVEMENT")
MainTab:Slider({Title="Walk Speed", Flag="WalkSpeed", Min=16, Max=500, Step=1, Default=16, Suffix=" SPD", Callback=function(v) sliderSpeed=v local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed=v hum:SetAttribute("BaseSpeed",v) end end})

MainTab:Section("STEAL CONFIG")
MainTab:Dropdown({Title="Rarity Filter", Flag="RarityFilter", Options=rarityNames, Multi=true, Callback=function(val) selected={} if type(val)=="table" then for _,n in ipairs(val) do selected[n]=true end elseif val then selected[val]=true end end})
MainTab:Dropdown({Title="Zone Filter", Flag="ZoneFilter", Options=zoneNames, Multi=true, Callback=function(val) selectedZones={} if type(val)=="table" then for _,n in ipairs(val) do selectedZones[n]=true end elseif val then selectedZones[val]=true end end})
MainTab:Dropdown({Title="Defend Mode", Flag="DefendMode", Options=defendModes, Default="None", Callback=function(val) defendMode=type(val)=="table" and val[1] or val defendMode=defendMode or "None" end})
MainTab:Textbox({Title="Min $ /Sec", Flag="MinCash", Placeholder="$ 0 = off", Callback=function(text) local v=parseFilterInput(text) minCashFilter=v if v>0 then Window.Notify("FILTER $", "Min $"..tostring(v), ACCENT, 2) else Window.Notify("FILTER $", "OFF", DIM, 2) end end})

local function getStealTargets() local folder=workspace:FindFirstChild("AnimalPickups") if not folder or next(selected)==nil then return {} end local out={} for _,m in ipairs(folder:GetChildren()) do if m:IsA("Model") and selected[m:GetAttribute("Rarity")] then if next(selectedZones)~=nil then local z=getAnimalZone(m) if not selectedZones[z] then continue end end if minCashFilter>0 then local cash=parseCash(getCashPerSecond(m)) if cash<minCashFilter then continue end end table.insert(out,m) end end table.sort(out,function(a,b) return parseCash(getCashPerSecond(a)) > parseCash(getCashPerSecond(b)) end) return out end

MainTab:Toggle({Title="Auto Steal", Flag="AutoSteal", Default=false, Callback=function(v)
    getgenv().SORU_AutoSteal=v
    if v then
        if next(selected)==nil then Window.Notify("ERROR", "Pilih Rarity dulu!", Color3.fromRGB(248,113,113), 3) getgenv().SORU_AutoSteal=false return end
        walkToSafeBase()
        task.spawn(function()
            while getgenv().SORU_AutoSteal do
                local list=getStealTargets()
                local found=#list>0
                for _,m in ipairs(list) do if not getgenv().SORU_AutoSteal then break end pcall(function() stealMethod(m) end) task.wait(0.5) end
                if not found then task.wait(0.8) end
            end
        end)
    end
end})

MainTab:Toggle({Title="Attack Carrier", Flag="AttackCarrier", Default=false, Callback=function(v) attackEnabled=v Window.Notify("ATTACK", v and "ON" or "OFF", v and Color3.fromRGB(255,80,80) or DIM, 2) end})

MainTab:Section("BREAK EGG")
MainTab:Dropdown({Title="Egg Zone", Flag="EggZone", Options=zoneNames, Callback=function(val) selectedEggZone=type(val)=="table" and val[1] or val end})
MainTab:Toggle({Title="Big Egg Priority", Flag="BigEggPrio", Default=true, Callback=function(v) bigEggPriority=v Window.Notify("BIG EGG", v and "Biggest First" or "OFF", v and ACCENT or DIM, 2) end})

local function getEggSize(model) for _,a in ipairs({"Size","EggSize","Scale","WeightKg","Weight","SizeMultiplier"}) do local v=model:GetAttribute(a) if typeof(v)=="number" then return v end end for _,d in ipairs(model:GetDescendants()) do if d:IsA("NumberValue") and d.Name:lower():find("size") then return d.Value end end local ok,_,sz=pcall(function() return model:GetBoundingBox() end) if ok and sz then return sz.Magnitude end return 0 end
local function getEggsInZone(zoneName) local zb=getZoneBuildsFolder() if not zb then return {} end local zoneModel=zb:FindFirstChild(zoneName) if not zoneModel then return {} end local eggsRoot=zoneModel:FindFirstChild("Eggs") or zoneModel local out={} for _,v in ipairs(eggsRoot:GetChildren()) do if v:IsA("Model") and v.Name:lower():find("egg") then table.insert(out,v) end end if #out==0 then for _,v in ipairs(eggsRoot:GetDescendants()) do if v:IsA("Model") and v.Name:lower():find("egg") then table.insert(out,v) end end end if bigEggPriority then table.sort(out,function(a,b) return getEggSize(a)>getEggSize(b) end) end return out end
local function getEggHealth(eggModel) if eggModel:GetAttribute("Health") then return eggModel:GetAttribute("Health") end for _,d in ipairs(eggModel:GetDescendants()) do local h=d:GetAttribute("Health") if h~=nil then return h end end return nil end
local function equipPickaxe() local char=plr.Character if not char then return nil end local tool=char:FindFirstChildOfClass("Tool") if tool and tool.Name:lower():find("pickaxe") then return tool end for _,t in ipairs(plr.Backpack:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("pickaxe") then t.Parent=char return t end end for _,t in ipairs(plr.Backpack:GetChildren()) do if t:IsA("Tool") then t.Parent=char return t end end return char:FindFirstChildOfClass("Tool") end

MainTab:Toggle({Title="Break Egg", Flag="BreakEgg", Default=false, Callback=function(v)
    getgenv().SORU_BreakEgg=v
    if v then
        if not selectedEggZone then Window.Notify("ERROR", "Pilih Zone dulu!", Color3.fromRGB(248,113,113), 2) getgenv().SORU_BreakEgg=false return end
        task.spawn(function()
            while getgenv().SORU_BreakEgg do
                local targets=getStealTargets()
                if #targets>0 then for _,m in ipairs(targets) do if not getgenv().SORU_BreakEgg then break end pcall(function() stealMethod(m) end) task.wait(0.3) end continue end
                local eggs=getEggsInZone(selectedEggZone) if #eggs==0 then task.wait(1) continue end
                for _,egg in ipairs(eggs) do
                    if not getgenv().SORU_BreakEgg then break end
                    if #getStealTargets()>0 then break end
                    local pos,base=getOffsetPos(egg) if not pos then local b=getBasePos(egg) if b then pos=Vector3.new(b.X,3.5,b.Z+3) base=Vector3.new(b.X,3.5,b.Z) end end
                    if not pos then continue end
                    pcall(function() walkDirect(pos,base,false) equipPickaxe() while getgenv().SORU_BreakEgg and egg.Parent do if #getStealTargets()>0 then break end local h=getEggHealth(egg) if h==nil or h<=0 then break end task.wait(0.15) end end)
                    task.wait(0.2)
                end
                task.wait(0.5)
            end
        end)
    end
end})

MainTab:Section("FOLLOW PLAYER")
local function getPlayerList() local l={} for _,p in ipairs(Players:GetPlayers()) do if p~=plr then table.insert(l,p.Name) end end if #l==0 then l={"No Player"} end return l end
local playerDD=MainTab:Dropdown({Title="Player List", Flag="PlayerList", Options=getPlayerList(), Callback=function(val) local name=type(val)=="table" and val[1] or val if name and name~="No Player" then selectedFollowPlayer=name Window.Notify("FOLLOW", "Target "..name, ACCENT, 2) end end})
MainTab:Toggle({Title="Follow Player", Flag="FollowPlayer", Default=false, Callback=function(v)
    followEnabled=v
    if v then
        if not selectedFollowPlayer or selectedFollowPlayer=="No Player" then Window.Notify("ERROR", "Pilih player dulu!", Color3.fromRGB(248,113,113), 2) followEnabled=false return end
        Window.Notify("FOLLOW", "Follow ON "..selectedFollowPlayer, ACCENT, 2)
        task.spawn(function() while followEnabled do if selectedFollowPlayer then local target=Players:FindFirstChild(selectedFollowPlayer) if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then local hrp=target.Character.HumanoidRootPart walkDirect(Vector3.new(hrp.Position.X,3.5,hrp.Position.Z),hrp.Position,false) end end task.wait(0.15) end end)
    else
        Window.Notify("FOLLOW", "OFF", DIM, 2)
    end
end})
task.spawn(function() while task.wait(2) do pcall(function() playerDD:Refresh(getPlayerList()) end) end end)

MiscTab:Section("MISC UTILITY")
local noRagdollOn=false local ragdollConns={}
local function enableNoRagdoll() for _,c in ipairs(ragdollConns) do pcall(function() c:Disconnect() end) end ragdollConns={} local char=plr.Character local hum=char and char:FindFirstChildOfClass("Humanoid") if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false) hum.BreakJointsOnDeath=false hum.PlatformStand=false end) table.insert(ragdollConns,hum.StateChanged:Connect(function(_,new) if new==Enum.HumanoidStateType.Ragdoll or new==Enum.HumanoidStateType.FallingDown then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end end)) end table.insert(ragdollConns,RunService.Heartbeat:Connect(function() local c=plr.Character local h=c and c:FindFirstChildOfClass("Humanoid") if h then if h:GetState()==Enum.HumanoidStateType.Ragdoll or h:GetState()==Enum.HumanoidStateType.FallingDown then h:ChangeState(Enum.HumanoidStateType.GettingUp) h.PlatformStand=false end h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) h:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false) end end)) end
local function disableNoRagdoll() for _,c in ipairs(ragdollConns) do pcall(function() c:Disconnect() end) end ragdollConns={} local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true) hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true) hum.BreakJointsOnDeath=true end) end end
MiscTab:Toggle({Title="No Ragdoll", Flag="NoRagdoll", Default=false, Callback=function(v) noRagdollOn=v if v then enableNoRagdoll() else disableNoRagdoll() end end})

local antiMentalOn=false local antiMentalConns={}
local function enableAntiMental() for _,c in ipairs(antiMentalConns) do pcall(function() c:Disconnect() end) end antiMentalConns={} table.insert(antiMentalConns,RunService.Heartbeat:Connect(function() local char=plr.Character local hrp=char and char:FindFirstChild("HumanoidRootPart") if not hrp then return end local vel=hrp.AssemblyLinearVelocity local flat=Vector3.new(vel.X,0,vel.Z).Magnitude if flat>35 then hrp.AssemblyLinearVelocity=Vector3.new(0,vel.Y,0) hrp.AssemblyAngularVelocity=Vector3.zero pcall(function() hrp.Velocity=Vector3.new(0,hrp.Velocity.Y,0) end) end if hrp.AssemblyAngularVelocity.Magnitude>20 then hrp.AssemblyAngularVelocity=Vector3.zero end end)) end
local function disableAntiMental() for _,c in ipairs(antiMentalConns) do pcall(function() c:Disconnect() end) end antiMentalConns={} end
MiscTab:Toggle({Title="Anti Mental", Flag="AntiMental", Default=false, Callback=function(v) antiMentalOn=v if v then enableAntiMental() else disableAntiMental() end end})

MiscTab:Section("GAMEPASS")
local fastBreakOn=false local fastBreakConn=nil
local function setFastBreakAttribute(state) pcall(function() plr:SetAttribute("FastSwingOwned",state) end) pcall(function() if plr.Character then plr.Character:SetAttribute("FastSwingOwned",state) end end) end
MiscTab:Toggle({Title="Fast Break", Flag="FastBreak", Default=false, Callback=function(v) fastBreakOn=v if fastBreakOn then setFastBreakAttribute(true) if fastBreakConn then fastBreakConn:Disconnect() end fastBreakConn=RunService.Heartbeat:Connect(function() if plr:GetAttribute("FastSwingOwned")~=true then setFastBreakAttribute(true) end end) else if fastBreakConn then fastBreakConn:Disconnect() fastBreakConn=nil end setFastBreakAttribute(false) end end})

EspTab:Section("ESP SYSTEM")
EspTab:Dropdown({Title="Rarity Filter ESP", Flag="EspRarity", Options=rarityNames, Multi=true, Callback=function(val) selectedEspRarity={} if type(val)=="table" then for _,n in ipairs(val) do selectedEspRarity[n]=true end elseif val then selectedEspRarity[val]=true end if espEnabled then refreshAllEsp() end end})
EspTab:Toggle({Title="Animal ESP", Flag="AnimalESP", Default=false, Callback=function(v) espEnabled=v if espEnabled then refreshAllEsp() Window.Notify("ESP", "ON", ACCENT, 2) task.spawn(function() while espEnabled do refreshAllEsp() task.wait(1.5) end end) local folder=workspace:FindFirstChild("AnimalPickups") if folder then folder.ChildAdded:Connect(function(m) if espEnabled and m:IsA("Model") then task.wait(0.2) createAnimalEsp(m) end end) folder.ChildRemoved:Connect(function(m) removeAnimalEsp(m) end) end else clearAllEsp() Window.Notify("ESP", "OFF", DIM, 2) end end})
local clearOnRespawn=true
EspTab:Toggle({Title="Clear ESP On Death", Flag="ClearEsp", Default=true, Callback=function(v) clearOnRespawn=v end})

PlotTab:Section("PLOT")
PlotTab:Toggle({Title="Equip Best", Flag="EquipBest", Default=false, Callback=function(v)
    getgenv().SORU_EquipBest=v
    if v then task.spawn(function() while getgenv().SORU_EquipBest do pcall(function() RS.PetsInventoryRemote:FireServer("EquipBest", nil) end) task.wait(1.5) end end) end
end})

PlotTab:Section("INDEX")
PlotTab:Toggle({Title="Auto Claim Index", Flag="ClaimIndex", Default=false, Callback=function(v)
    getgenv().SORU_ClaimIndex=v
    if v then task.spawn(function() while getgenv().SORU_ClaimIndex do pcall(function() RS.IndexRemote:FireServer("ClaimAll", nil) end) task.wait(2) end end) end
end})

BlatantTab:Section("INSTANT STEAL - HIGHEST $")
BlatantTab:Button({Title="Instant Steal Highest $", Callback=function()
    local folder=workspace:FindFirstChild("AnimalPickups") if not folder then Window.Notify("BLATANT", "No Animals", DIM, 2) return end
    local candidates={}
    for _,m in ipairs(folder:GetChildren()) do if m:IsA("Model") then table.insert(candidates,{model=m,cash=parseCash(getCashPerSecond(m)),str=getCashPerSecond(m)}) end end
    if #candidates==0 then Window.Notify("BLATANT", "No Target", DIM, 2) return end
    table.sort(candidates,function(a,b) return a.cash > b.cash end)
    local best=candidates[1].model
    Window.Notify("BLATANT", best.Name.." $"..candidates[1].cash, ACCENT, 2)
    local hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end
    local pos=getOffsetPos(best) if not pos then pos=getBasePos(best) end
    if pos then hrp.CFrame=CFrame.new(pos) task.wait(0.08) for i=1,5 do fireSteal(best) touchSteal(best) pressE() task.wait(0.05) end task.wait(0.15) hrp.CFrame=CFrame.new(SAFE_BASE_POS) end
end})

plr.CharacterAdded:Connect(function(char) task.wait(0.5) local hum=char:WaitForChild("Humanoid",15) if hum then sliderSpeed=hum.WalkSpeed hum:SetAttribute("BaseSpeed",sliderSpeed) end task.wait(0.5) if noRagdollOn then enableNoRagdoll() end if antiMentalOn then enableAntiMental() end if fastBreakOn then setFastBreakAttribute(true) end if clearOnRespawn then clearAllEsp() end if espEnabled then task.wait(0.5) refreshAllEsp() end end)
RunService.Heartbeat:Connect(function() local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") if hum then if math.abs(hum.WalkSpeed-sliderSpeed)>0.1 then hum.WalkSpeed=sliderSpeed end end end)
Window.Notify("Soru Hub", "Loaded Zone-(Model) Combo + Highest $", ACCENT, 3)
