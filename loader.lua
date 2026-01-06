local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local success, Library = pcall(function()
    return loadstring(game:HttpGet(repo .. "Library.lua"))()
end)

if not success then
    error("Không thể tải thư viện!")
end

local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

_G.AutoFarmRunning = false
_G.AutoFarmTask = nil
_G.Flying = false
_G.FlySpeed = 50
_G.NoClipEnabled = false
_G.FlyBodyVelocity = nil
_G.NoClipConnection = nil
_G.InfJumpEnabled = false
_G.FarmFlySpeed = 50
_G.AimSmoothness = 0.3
_G.ESPRunning = false
_G.ESPConnection = nil
_G.ESPObjects = {}
_G.EnemyESPRunning = false
_G.EnemyESPConnection = nil
_G.EnemyESPObjects = {}
_G.PlayerESPRunning = false
_G.PlayerESPConnection = nil
_G.PlayerESPObjects = {}
_G.HitboxMultiplier = 5
_G.HitboxEnabled = false
_G.HitboxConnection = nil
_G.OriginalHitboxSizes = {}
_G.ShowHeadHitboxEnabled = false
_G.HeadHitboxConnection = nil
_G.HeadHitboxParts = {}
_G.Invisible = false
_G.InvisibilityConnection = nil

_G.SpeedLoop = nil

_G.Waypoints = {}
_G.SelectedWaypoint = nil

_G.KnownEnemies = {
    "Zombie",
    "ArcticZombie",
    "Headless Zombie", 
    "Infected Zombie",
    "Mutant Zombie",
    "Radioactive Zombie",
    "Others Enemy"
}

_G.SelectedEnemies = {}
for _, enemyName in pairs(_G.KnownEnemies) do
    _G.SelectedEnemies[enemyName] = true
end

_G.AvailableObjects = {
    "BlueberryBush",
    "Coal", 
    "CommonLoot",
    "CopperOre",
    "IronOre",
    "MedicalLoot",
    "Palm1",
    "Palm2", 
    "Palm3",
    "PotatoPlant",
    "PresentLoot",
    "RareLoot",
    "Sandstone",
    "Stone",
    "StrawberryBush",
    "Tree1",
    "Tree2",
    "Tree3",
    "Tree4",
    "Tree5",
    "UncommonLoot"
}

_G.SelectedObjects = {}
for _, objName in pairs(_G.AvailableObjects) do
    _G.SelectedObjects[objName] = true
end

local BRIGHT_PURPLE_COLOR = Color3.fromRGB(200, 0, 255)

_G.ESPColors = {
    ["BlueberryBush"] = Color3.fromRGB(0, 100, 255),
    ["Coal"] = Color3.fromRGB(30, 30, 30),
    ["CommonLoot"] = Color3.fromRGB(255, 255, 255),
    ["CopperOre"] = Color3.fromRGB(184, 115, 51),
    ["IronOre"] = Color3.fromRGB(150, 150, 150),
    ["MedicalLoot"] = Color3.fromRGB(255, 0, 0),
    ["Palm1"] = Color3.fromRGB(34, 139, 34),
    ["Palm2"] = Color3.fromRGB(0, 100, 0),
    ["Palm3"] = Color3.fromRGB(0, 80, 0),
    ["PotatoPlant"] = Color3.fromRGB(139, 69, 19),
    ["PresentLoot"] = Color3.fromRGB(255, 215, 0),
    ["RareLoot"] = Color3.fromRGB(0, 255, 255),
    ["Sandstone"] = Color3.fromRGB(210, 180, 140),
    ["Stone"] = Color3.fromRGB(128, 128, 128),
    ["StrawberryBush"] = Color3.fromRGB(255, 0, 0),
    ["Tree1"] = Color3.fromRGB(85, 107, 47),
    ["Tree2"] = Color3.fromRGB(107, 142, 35),
    ["Tree3"] = Color3.fromRGB(124, 252, 0),
    ["Tree4"] = Color3.fromRGB(173, 255, 47),
    ["Tree5"] = Color3.fromRGB(154, 205, 50),
    ["UncommonLoot"] = Color3.fromRGB(0, 255, 0),
    
    ["Zombie"] = Color3.fromRGB(255, 100, 100),
    ["ArcticZombie"] = Color3.fromRGB(100, 200, 255),
    ["Headless Zombie"] = Color3.fromRGB(255, 150, 50),
    ["Infected Zombie"] = Color3.fromRGB(100, 255, 100),
    ["Mutant Zombie"] = Color3.fromRGB(255, 50, 200),
    ["Radioactive Zombie"] = Color3.fromRGB(50, 255, 50),
    ["Others Enemy"] = Color3.fromRGB(255, 50, 50),
    ["Boss"] = Color3.fromRGB(255, 0, 0),
    ["Player"] = Color3.fromRGB(0, 200, 255),
}

local function startSpeedLoop()
    if _G.SpeedLoop then return end
    
    _G.SpeedLoop = RunService.Heartbeat:Connect(function()
        if not Toggles.SpeedToggle or not Toggles.SpeedToggle.Value then
            _G.SpeedLoop:Disconnect()
            _G.SpeedLoop = nil
            return
        end
        
        local character = player.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local speed = Options.SpeedValue and Options.SpeedValue.Value or 50
        humanoid.WalkSpeed = speed
    end)
end

local function disableCameraShake()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    for _, child in pairs(camera:GetChildren()) do
        if child:IsA("Camera") or child:IsA("Script") then
            local success, result = pcall(function()
                if child.Name:lower():find("shake") or child.Name:lower():find("camera") then
                    child:Destroy()
                end
            end)
        end
    end
    
    camera.CameraType = Enum.CameraType.Custom
end

local function getEnemyType(enemyName)
    for _, knownEnemy in pairs(_G.KnownEnemies) do
        if string.find(enemyName, knownEnemy) or enemyName == knownEnemy then
            if knownEnemy == "Others Enemy" then
                return "Others Enemy", enemyName
            end
            return knownEnemy, nil
        end
    end
    
    if string.find(enemyName, "Arctic") then
        return "ArcticZombie", nil
    elseif string.find(enemyName, "Mutant") then
        return "Mutant Zombie", nil
    elseif string.find(enemyName, "Headless") then
        return "Headless Zombie", nil
    elseif string.find(enemyName, "Infected") then
        return "Infected Zombie", nil
    elseif string.find(enemyName, "Radioactive") then
        return "Radioactive Zombie", nil
    elseif string.find(enemyName, "Zombie") then
        return "Zombie", nil
    elseif string.find(enemyName, "Boss") then
        return "Boss", nil
    else
        return "Others Enemy", enemyName
    end
end

local function createHeadHitbox(enemy)
    if not enemy or not enemy:IsA("Model") then return nil end
    
    local head = enemy:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return nil end
    
    local hitboxPart = Instance.new("Part")
    hitboxPart.Name = "BeautifulHeadHitbox"
    hitboxPart.Size = head.Size * 1.1
    hitboxPart.CFrame = head.CFrame
    hitboxPart.Transparency = 0.85
    hitboxPart.CanCollide = false
    hitboxPart.Anchored = true
    hitboxPart.CastShadow = false
    hitboxPart.Locked = true
    hitboxPart.Color = BRIGHT_PURPLE_COLOR
    
    local glow = Instance.new("PointLight")
    glow.Name = "HitboxGlow"
    glow.Color = BRIGHT_PURPLE_COLOR
    glow.Brightness = 2
    glow.Range = 10
    glow.Shadows = false
    glow.Parent = hitboxPart
    
    local highlight = Instance.new("SelectionBox")
    highlight.Name = "HitboxOutline"
    highlight.Adornee = hitboxPart
    highlight.LineThickness = 0.05
    highlight.Color3 = BRIGHT_PURPLE_COLOR
    highlight.Transparency = 0.3
    highlight.Parent = hitboxPart
    
    _G.HeadHitboxParts[enemy] = {
        part = hitboxPart,
        head = head,
        enemy = enemy
    }
    
    hitboxPart.Parent = workspace
    
    return hitboxPart
end

local function updateHeadHitbox(hitboxData)
    if not hitboxData or not hitboxData.part or not hitboxData.head then return end
    
    hitboxData.part.CFrame = hitboxData.head.CFrame
    hitboxData.part.Size = hitboxData.head.Size * 1.1
end

local function removeHeadHitbox(hitboxData)
    if hitboxData and hitboxData.part then
        hitboxData.part:Destroy()
    end
end

local function toggleShowHeadHitbox()
    if _G.ShowHeadHitboxEnabled then
        _G.ShowHeadHitboxEnabled = false
        
        for enemy, hitboxData in pairs(_G.HeadHitboxParts) do
            removeHeadHitbox(hitboxData)
        end
        _G.HeadHitboxParts = {}
        
        if _G.HeadHitboxConnection then
            _G.HeadHitboxConnection:Disconnect()
            _G.HeadHitboxConnection = nil
        end
        
        Library:Notify("Đã tắt hitbox đẹp", 3)
        return
    end
    
    _G.ShowHeadHitboxEnabled = true
    
    local function createHitboxesForExistingEnemies()
        local enemiesFolder = workspace:FindFirstChild("Enemies")
        if not enemiesFolder then return end
        
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if enemy:IsA("Model") then
                createHeadHitbox(enemy)
            end
        end
    end
    
    local function onEnemyAdded(child)
        if not _G.ShowHeadHitboxEnabled then return end
        
        task.wait(0.1)
        
        if child:IsA("Model") then
            createHeadHitbox(child)
        end
    end
    
    local function onEnemyRemoved(child)
        if _G.HeadHitboxParts[child] then
            removeHeadHitbox(_G.HeadHitboxParts[child])
            _G.HeadHitboxParts[child] = nil
        end
    end
    
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        createHitboxesForExistingEnemies()
        
        _G.HeadHitboxConnection = enemiesFolder.ChildAdded:Connect(onEnemyAdded)
        enemiesFolder.ChildRemoved:Connect(onEnemyRemoved)
    end
    
    local updateConnection
    updateConnection = RunService.RenderStepped:Connect(function()
        if not _G.ShowHeadHitboxEnabled then
            updateConnection:Disconnect()
            return
        end
        
        for enemy, hitboxData in pairs(_G.HeadHitboxParts) do
            if enemy and enemy.Parent and enemy.Parent == workspace.Enemies then
                updateHeadHitbox(hitboxData)
            else
                removeHeadHitbox(hitboxData)
                _G.HeadHitboxParts[enemy] = nil
            end
        end
    end)
    
    Library:Notify("Đã bật hitbox tím đẹp", 3)
end

local function applyHitboxToEnemy(enemy, multiplier)
    if enemy and enemy:IsA("Model") then
        local head = enemy:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            if not _G.OriginalHitboxSizes[enemy] then
                _G.OriginalHitboxSizes[enemy] = head.Size
            end
            
            local originalSize = _G.OriginalHitboxSizes[enemy]
            
            local baseSize = math.min(originalSize.X, originalSize.Y, originalSize.Z)
            local uniformSize = baseSize * multiplier
            
            head.Size = Vector3.new(uniformSize, uniformSize, uniformSize)
        end
    end
end

local function updateAllHitboxes(multiplier)
    _G.HitboxMultiplier = multiplier
    
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return end
    
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        applyHitboxToEnemy(enemy, multiplier)
    end
end

local function resetEnemyHitboxes()
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return end
    
    for enemy, originalSize in pairs(_G.OriginalHitboxSizes) do
        if enemy and enemy.Parent and enemy.Parent == enemiesFolder then
            local head = enemy:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                head.Size = originalSize
            end
        end
    end
    
    _G.OriginalHitboxSizes = {}
end

local function toggleHitbox()
    if _G.HitboxEnabled then
        _G.HitboxEnabled = false
        
        if _G.HitboxConnection then
            _G.HitboxConnection:Disconnect()
            _G.HitboxConnection = nil
        end
        
        resetEnemyHitboxes()
        
        Library:Notify("Đã tắt auto hitbox", 3)
        return
    end
    
    _G.HitboxEnabled = true
    
    local multiplier = Options.HitboxMultiplier and Options.HitboxMultiplier.Value or 5
    updateAllHitboxes(multiplier)
    
    local function onEnemyAdded(child)
        if not _G.HitboxEnabled then return end
        
        task.wait(0.1)
        
        if child:IsA("Model") then
            local multiplier = Options.HitboxMultiplier and Options.HitboxMultiplier.Value or 5
            applyHitboxToEnemy(child, multiplier)
        end
    end
    
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        _G.HitboxConnection = enemiesFolder.ChildAdded:Connect(onEnemyAdded)
    end
    
    Library:Notify("Đã bật auto hitbox", 3)
end

local function toggleInvisible()
    if _G.Invisible then
        _G.Invisible = false
        
        if _G.InvisibilityConnection then
            _G.InvisibilityConnection:Disconnect()
            _G.InvisibilityConnection = nil
        end
        
        local character = player.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                    if part:FindFirstChild("OriginalTransparency") then
                        part.Transparency = part.OriginalTransparency.Value
                        part.OriginalTransparency:Destroy()
                    end
                end
            end
        end
        
        Library:Notify("Đã bật tàng hình", 3)
        return
    end
    
    _G.Invisible = true
    
    local function updateInvisibility()
        local character = player.Character
        if not character then return end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if not part:FindFirstChild("OriginalTransparency") then
                    local originalValue = Instance.new("NumberValue")
                    originalValue.Name = "OriginalTransparency"
                    originalValue.Value = part.Transparency
                    originalValue.Parent = part
                end
                part.Transparency = 1
            end
        end
    end
    
    updateInvisibility()
    
    _G.InvisibilityConnection = RunService.Heartbeat:Connect(function()
        if not _G.Invisible then
            _G.InvisibilityConnection:Disconnect()
            _G.InvisibilityConnection = nil
            return
        end
        
        updateInvisibility()
    end)
    
    player.CharacterAdded:Connect(function()
        if _G.Invisible then
            task.wait(1)
            updateInvisibility()
        end
    end)
    
    Library:Notify("Đã bật tàng hình", 3)
end

local function createESP(obj, isEnemy, isPlayer, enemyType, customName, playerName)
    if not obj or not obj:IsDescendantOf(workspace) then return nil end
    
    local esp = {}
    
    if isEnemy and not enemyType then
        enemyType, customName = getEnemyType(obj.Name)
    end
    
    if isEnemy and enemyType and not _G.SelectedEnemies[enemyType] then
        return nil
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPBillboard"
    billboard.Adornee = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1000
    billboard.ResetOnSpawn = false
    
    local displayText = ""
    if isPlayer then
        displayText = playerName or "Player"
    elseif isEnemy then
        if enemyType == "Others Enemy" and customName then
            displayText = customName
        else
            displayText = enemyType or obj.Name
        end
    else
        displayText = obj.Name
    end
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ESPLabel"
    textLabel.Size = UDim2.new(1, 0, 0.5, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 18
    textLabel.Text = displayText
    textLabel.Parent = billboard
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "ESPDistance"
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distanceLabel.Font = Enum.Font.SourceSansBold
    distanceLabel.TextSize = 16
    distanceLabel.Text = "0 studs"
    distanceLabel.Parent = billboard
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = obj
    
    local color
    if isPlayer then
        color = _G.ESPColors["Player"]
    elseif isEnemy then
        color = _G.ESPColors[enemyType] or _G.ESPColors["Others Enemy"]
    else
        color = _G.ESPColors[obj.Name] or Color3.new(1, 1, 1)
    end
    
    highlight.FillColor = color
    highlight.OutlineColor = color
    textLabel.TextColor3 = color
    distanceLabel.TextColor3 = color
    
    esp.billboard = billboard
    esp.highlight = highlight
    esp.object = obj
    esp.isEnemy = isEnemy
    esp.isPlayer = isPlayer
    esp.enemyType = enemyType
    
    if obj:IsA("Model") then
        if obj.PrimaryPart then
            billboard.Adornee = obj.PrimaryPart
            highlight.Adornee = obj
        else
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then
                billboard.Adornee = part
                highlight.Adornee = obj
            else
                billboard:Destroy()
                highlight:Destroy()
                return nil
            end
        end
    end
    
    billboard.Parent = game:GetService("CoreGui")
    highlight.Parent = game:GetService("CoreGui")
    
    return esp
end

local function updateESP(espTable)
    if not espTable or not espTable.billboard or not espTable.billboard.Parent then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local targetPart = espTable.billboard.Adornee
    if not targetPart or not targetPart.Parent then return end
    
    local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude
    espTable.billboard.ESPDistance.Text = math.floor(distance) .. " studs"
    
    local maxDistance = espTable.isEnemy and 500 or 300
    if espTable.isPlayer then
        maxDistance = 1000
    end
    espTable.billboard.Enabled = distance <= maxDistance
    espTable.highlight.Enabled = distance <= maxDistance
end

local function removeESP(espTable)
    if espTable then
        if espTable.billboard then
            espTable.billboard:Destroy()
        end
        if espTable.highlight then
            espTable.highlight:Destroy()
        end
    end
end

local function refreshEnemyESP()
    if not _G.EnemyESPRunning then return end
    
    for enemy, esp in pairs(_G.EnemyESPObjects) do
        removeESP(esp)
    end
    _G.EnemyESPObjects = {}
    
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if enemy:IsA("BasePart") or enemy:IsA("Model") then
                local enemyType, customName = getEnemyType(enemy.Name)
                if _G.SelectedEnemies[enemyType] then
                    local esp = createESP(enemy, true, false, enemyType, customName)
                    if esp then
                        _G.EnemyESPObjects[enemy] = esp
                    end
                end
            end
        end
    end
end

local function refreshResourceESP()
    if not _G.ESPRunning then return end
    
    for obj, esp in pairs(_G.ESPObjects) do
        removeESP(esp)
    end
    _G.ESPObjects = {}
    
    local spawnedFolder = workspace:FindFirstChild("Spawned")
    if spawnedFolder then
        for _, obj in ipairs(spawnedFolder:GetChildren()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                if _G.SelectedObjects[obj.Name] then
                    local esp = createESP(obj, false, false)
                    if esp then
                        _G.ESPObjects[obj] = esp
                    end
                end
            end
        end
    end
end

local function refreshPlayerESP()
    if not _G.PlayerESPRunning then return end
    
    for plyr, esp in pairs(_G.PlayerESPObjects) do
        removeESP(esp)
    end
    _G.PlayerESPObjects = {}
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local character = otherPlayer.Character
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local esp = createESP(character, false, true, nil, nil, otherPlayer.Name)
                if esp then
                    _G.PlayerESPObjects[otherPlayer] = esp
                end
            end
        end
    end
end

local function toggleAllResources(value)
    for _, objName in pairs(_G.AvailableObjects) do
        _G.SelectedObjects[objName] = value
        if Toggles["ResourceESP_" .. objName] then
            Toggles["ResourceESP_" .. objName]:SetValue(value)
        end
    end
    
    if _G.ESPRunning then
        refreshResourceESP()
    end
end

local function toggleAllEnemies(value)
    for _, enemyName in pairs(_G.KnownEnemies) do
        _G.SelectedEnemies[enemyName] = value
        if Toggles["EnemyESP_" .. enemyName] then
            Toggles["EnemyESP_" .. enemyName]:SetValue(value)
        end
    end
    
    if _G.EnemyESPRunning then
        refreshEnemyESP()
    end
end

local function simulateClick()
    local mouse = player:GetMouse()
    local screenCenter = Vector2.new(mouse.ViewSizeX / 2, mouse.ViewSizeY / 2)
    
    if VirtualInputManager then
        VirtualInputManager:SendMouseButtonEvent(
            screenCenter.X, 
            screenCenter.Y, 
            0,
            true,
            game, 
            1
        )
        
        task.wait(0.05)
        
        VirtualInputManager:SendMouseButtonEvent(
            screenCenter.X, 
            screenCenter.Y, 
            0,
            false,
            game, 
            1
        )
    end
end

local function setupClickTP()
    local mouse = player:GetMouse()
    
    mouse.Button1Down:Connect(function()
        if Toggles.ClickTPToggle and Toggles.ClickTPToggle.Value then
            local character = player.Character
            if not character then return end
            
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end
            
            local target = mouse.Hit.Position
            humanoidRootPart.CFrame = CFrame.new(target + Vector3.new(0, 5, 0))
        end
    end)
end

local function smoothAimAtObject(objPosition)
    if not objPosition then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local currentLookVector = camera.CFrame.LookVector
    local directionToTarget = (objPosition - camera.CFrame.Position).Unit
    
    local smoothFactor = math.clamp(_G.AimSmoothness, 0.01, 0.99)
    local newLookVector = currentLookVector:Lerp(directionToTarget, 1 - smoothFactor)
    
    local newCFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + newLookVector)
    
    camera.CFrame = newCFrame
    
    local lookPos = Vector3.new(objPosition.X, objPosition.Y, objPosition.Z)
    local currentRotation = humanoidRootPart.CFrame
    local targetRotation = CFrame.lookAt(humanoidRootPart.Position, lookPos)
    humanoidRootPart.CFrame = currentRotation:Lerp(targetRotation, 0.5)
end

local function getObjectPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart.Position
        end
        
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.Position
        end
        
        if obj.GetPivot then
            return obj:GetPivot().Position
        end
    end
    
    return nil
end

local function isObjectSelected(objName)
    return _G.SelectedObjects[objName] == true
end

local function saveWaypoint(name)
    local character = player.Character
    if not character then 
        Library:Notify("Lỗi: Không tìm thấy nhân vật!", 3)
        return 
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        Library:Notify("Lỗi: Không tìm thấy HumanoidRootPart!", 3)
        return 
    end
    
    local position = humanoidRootPart.Position
    local waypointId = HttpService:GenerateGUID(false)
    
    _G.Waypoints[waypointId] = {
        id = waypointId,
        name = name,
        position = position,
        timestamp = os.time()
    }
    
    Library:Notify("Waypoint '" .. name .. "' сохранен!", 3)
    return waypointId
end

local function teleportToWaypoint(waypointId)
    local waypoint = _G.Waypoints[waypointId]
    if not waypoint then 
        Library:Notify("Không tìm thấy waypoint!", 3)
        return 
    end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    humanoidRootPart.CFrame = CFrame.new(waypoint.position + Vector3.new(0, 5, 0))
    Library:Notify("Dịch chuyểnирован к '" .. waypoint.name .. "'", 3)
end

local function deleteWaypoint(waypointId)
    if _G.Waypoints[waypointId] then
        local name = _G.Waypoints[waypointId].name
        _G.Waypoints[waypointId] = nil
        Library:Notify("Waypoint '" .. name .. "' удален!", 3)
    end
end

local function findNearestSelectedObject()
    local spawnedFolder = workspace:FindFirstChild("Spawned")
    if not spawnedFolder then return nil end
    
    local character = player.Character
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearestObj = nil
    local nearestDistance = math.huge
    
    for _, item in ipairs(spawnedFolder:GetChildren()) do
        local itemName = item.Name
        if isObjectSelected(itemName) then
            if item:IsA("BasePart") or item:IsA("Model") then
                local position = getObjectPosition(item)
                if position then
                    local distance = (humanoidRootPart.Position - position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestObj = item
                    end
                end
            end
        end
    end
    
    return nearestObj, nearestDistance
end

local function findNearestPlayer()
    local character = player.Character
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearestPlayer = nil
    local nearestDistance = math.huge
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherCharacter = otherPlayer.Character
            local otherHumanoidRootPart = otherCharacter:FindFirstChild("HumanoidRootPart")
            if otherHumanoidRootPart then
                local distance = (humanoidRootPart.Position - otherHumanoidRootPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = otherPlayer
                end
            end
        end
    end
    
    return nearestPlayer, nearestDistance
end

local function teleportToNearestPlayer()
    local nearestPlayer, distance = findNearestPlayer()
    if not nearestPlayer then
        Library:Notify("Không tìm thấy người chơi!", 3)
        return
    end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local targetCharacter = nearestPlayer.Character
    if not targetCharacter then return end
    
    local targetHumanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetHumanoidRootPart then return end
    
    humanoidRootPart.CFrame = CFrame.new(targetHumanoidRootPart.Position + Vector3.new(0, 5, 0))
    Library:Notify("Dịch chuyểnирован к " .. nearestPlayer.Name .. " (" .. math.floor(distance) .. " studs)", 3)
end

local function moveToObject(objPosition, speed)
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local startPos = humanoidRootPart.Position
    local direction = (objPosition - startPos).Unit
    local distance = (objPosition - startPos).Magnitude
    local travelTime = distance / speed
    
    if travelTime <= 0 then return true end
    
    local startTime = tick()
    
    while _G.AutoFarmRunning and tick() - startTime < travelTime do
        local elapsed = tick() - startTime
        local progress = elapsed / travelTime
        local currentPos = startPos + (objPosition - startPos) * progress
        
        humanoidRootPart.CFrame = CFrame.new(currentPos)
        
        smoothAimAtObject(objPosition)
        
        task.wait()
    end
    
    return true
end

local function toggleFly()
    if _G.Flying then
        _G.Flying = false
        
        if _G.FlyBodyVelocity then
            _G.FlyBodyVelocity:Destroy()
            _G.FlyBodyVelocity = nil
        end
        
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
        
        return
    end
    
    _G.Flying = true
    local flySpeed = Options.FlySpeed and Options.FlySpeed.Value or 50
    
    local function updateFly()
        local character = player.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        if not _G.FlyBodyVelocity or not _G.FlyBodyVelocity.Parent then
            if _G.FlyBodyVelocity then
                _G.FlyBodyVelocity:Destroy()
            end
            
            _G.FlyBodyVelocity = Instance.new("BodyVelocity")
            _G.FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            _G.FlyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
            _G.FlyBodyVelocity.P = 1250
            _G.FlyBodyVelocity.Parent = humanoidRootPart
        end
        
        local camera = workspace.CurrentCamera
        local direction = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
        end
        
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
        end
        
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            direction = direction - Vector3.new(0, 1, 0)
        end
        
        if direction.Magnitude > 0 then
            direction = direction.Unit * flySpeed
        end
        
        _G.FlyBodyVelocity.Velocity = direction
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end
    end
    
    local flyConnection
    flyConnection = RunService.Heartbeat:Connect(function()
        if not _G.Flying then
            flyConnection:Disconnect()
            return
        end
        
        local success, err = pcall(updateFly)
        if not success then
            _G.Flying = false
            flyConnection:Disconnect()
        end
    end)
end

local function toggleNoClip()
    if _G.NoClipEnabled then
        _G.NoClipEnabled = false
        if _G.NoClipConnection then
            _G.NoClipConnection:Disconnect()
            _G.NoClipConnection = nil
        end
        return
    end
    
    _G.NoClipEnabled = true
    
    _G.NoClipConnection = RunService.Stepped:Connect(function()
        if not _G.NoClipEnabled then
            if _G.NoClipConnection then
                _G.NoClipConnection:Disconnect()
            end
            return
        end
        
        local character = player.Character
        if not character then return end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function ensureNoClipForAutoFarm()
    if _G.AutoFarmRunning and not _G.NoClipEnabled then
        toggleNoClip()
        if Toggles.NoClipToggle then
            Toggles.NoClipToggle:SetValue(true)
        end
    end
end

local function toggleInfJump()
    if _G.InfJumpEnabled then
        _G.InfJumpEnabled = false
        if _G.InfJumpConnection then
            _G.InfJumpConnection:Disconnect()
            _G.InfJumpConnection = nil
        end
        return
    end
    
    _G.InfJumpEnabled = true
    
    _G.InfJumpConnection = UserInputService.JumpRequest:Connect(function()
        if _G.InfJumpEnabled then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
end

local function toggleAllObjects(value)
    for _, objName in pairs(_G.AvailableObjects) do
        _G.SelectedObjects[objName] = value
        if Toggles["FarmObject_" .. objName] then
            Toggles["FarmObject_" .. objName]:SetValue(value)
        end
    end
end

local function startAutoFarm()
    if _G.AutoFarmRunning then 
        return 
    end
    
    local hasSelectedObjects = false
    for _, objName in pairs(_G.AvailableObjects) do
        if _G.SelectedObjects[objName] then
            hasSelectedObjects = true
            break
        end
    end
    
    if not hasSelectedObjects then
        Library:Notify("Lỗi: Chưa chọn tài nguyên để farm!", 5)
        return
    end
    
    _G.AutoFarmRunning = true
    
    ensureNoClipForAutoFarm()
    
    _G.AutoFarmTask = task.spawn(function()
        while _G.AutoFarmRunning do
            task.wait(0.5)
            
            if not player.Character then
                player:LoadCharacter()
                task.wait(2)
                continue
            end
            
            local spawnedFolder = workspace:FindFirstChild("Spawned")
            if not spawnedFolder then
                task.wait(2)
                continue
            end
            
            local nearestObj, distance = findNearestSelectedObject()
            if not nearestObj then
                task.wait(2)
                continue
            end
            
            local objPosition = getObjectPosition(nearestObj)
            if not objPosition then
                task.wait(1)
                continue
            end
            
            local targetPosition = objPosition + Vector3.new(0, 3, 0)
            
            local successMove = moveToObject(targetPosition, _G.FarmFlySpeed)
            
            if successMove then
                task.wait(0.2)
                
                local startTime = os.time()
                local clicked = false
                
                while nearestObj and nearestObj.Parent and nearestObj.Parent == spawnedFolder and _G.AutoFarmRunning do
                    if os.time() - startTime > 45 then
                        break
                    end
                    
                    local currentObjPosition = getObjectPosition(nearestObj)
                    if currentObjPosition then
                        smoothAimAtObject(currentObjPosition)
                    end
                    
                    simulateClick()
                    clicked = true
                    
                    if not nearestObj or not nearestObj.Parent or nearestObj.Parent ~= spawnedFolder then
                        break
                    end
                    
                    task.wait(0.5)
                end
                
                task.wait(0.2)
            end
        end
    end)
end

local function stopAutoFarm()
    if not _G.AutoFarmRunning then return end
    
    _G.AutoFarmRunning = false
    
    if _G.AutoFarmTask then
        task.cancel(_G.AutoFarmTask)
        _G.AutoFarmTask = nil
    end
end

local function toggleESP()
    if _G.ESPRunning then
        _G.ESPRunning = false
        
        for _, esp in pairs(_G.ESPObjects) do
            removeESP(esp)
        end
        _G.ESPObjects = {}
        
        if _G.ESPConnection then
            _G.ESPConnection:Disconnect()
            _G.ESPConnection = nil
        end
        
        return
    end
    
    _G.ESPRunning = true
    
    local function onChildAdded(child)
        if not _G.ESPRunning then return end
        
        task.wait(0.1)
        
        if child:IsA("BasePart") or child:IsA("Model") then
            if _G.SelectedObjects[child.Name] then
                local esp = createESP(child, false, false)
                if esp then
                    _G.ESPObjects[child] = esp
                end
            end
        end
    end
    
    local function onChildRemoved(child)
        if _G.ESPObjects[child] then
            removeESP(_G.ESPObjects[child])
            _G.ESPObjects[child] = nil
        end
    end
    
    local spawnedFolder = workspace:FindFirstChild("Spawned")
    if spawnedFolder then
        refreshResourceESP()
        
        _G.ESPConnection = spawnedFolder.ChildAdded:Connect(onChildAdded)
        spawnedFolder.ChildRemoved:Connect(onChildRemoved)
    end
    
    local updateConnection
    updateConnection = RunService.RenderStepped:Connect(function()
        if not _G.ESPRunning then
            updateConnection:Disconnect()
            return
        end
        
        for obj, esp in pairs(_G.ESPObjects) do
            if obj and obj.Parent and obj.Parent == workspace.Spawned then
                updateESP(esp)
            else
                removeESP(esp)
                _G.ESPObjects[obj] = nil
            end
        end
    end)
end

local function toggleEnemyESP()
    if _G.EnemyESPRunning then
        _G.EnemyESPRunning = false
        
        for _, esp in pairs(_G.EnemyESPObjects) do
            removeESP(esp)
        end
        _G.EnemyESPObjects = {}
        
        if _G.EnemyESPConnection then
            _G.EnemyESPConnection:Disconnect()
            _G.EnemyESPConnection = nil
        end
        
        return
    end
    
    _G.EnemyESPRunning = true
    
    local function onEnemyAdded(child)
        if not _G.EnemyESPRunning then return end
        
        task.wait(0.1)
        
        if child:IsA("BasePart") or child:IsA("Model") then
            local enemyType, customName = getEnemyType(child.Name)
            if _G.SelectedEnemies[enemyType] then
                local esp = createESP(child, true, false, enemyType, customName)
                if esp then
                    _G.EnemyESPObjects[child] = esp
                end
            end
        end
    end
    
    local function onEnemyRemoved(child)
        if _G.EnemyESPObjects[child] then
            removeESP(_G.EnemyESPObjects[child])
            _G.EnemyESPObjects[child] = nil
        end
    end
    
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        refreshEnemyESP()
        
        _G.EnemyESPConnection = enemiesFolder.ChildAdded:Connect(onEnemyAdded)
        enemiesFolder.ChildRemoved:Connect(onEnemyRemoved)
    end
    
    local updateConnection
    updateConnection = RunService.RenderStepped:Connect(function()
        if not _G.EnemyESPRunning then
            updateConnection:Disconnect()
            return
        end
        
        for enemy, esp in pairs(_G.EnemyESPObjects) do
            if enemy and enemy.Parent and enemy.Parent == workspace.Enemies then
                updateESP(esp)
            else
                removeESP(esp)
                _G.EnemyESPObjects[enemy] = nil
            end
        end
    end)
end

local function togglePlayerESP()
    if _G.PlayerESPRunning then
        _G.PlayerESPRunning = false
        
        for _, esp in pairs(_G.PlayerESPObjects) do
            removeESP(esp)
        end
        _G.PlayerESPObjects = {}
        
        if _G.PlayerESPConnection then
            _G.PlayerESPConnection:Disconnect()
            _G.PlayerESPConnection = nil
        end
        
        return
    end
    
    _G.PlayerESPRunning = true
    
    local function onPlayerAdded(otherPlayer)
        if not _G.PlayerESPRunning then return end
        
        otherPlayer.CharacterAdded:Connect(function(character)
            task.wait(0.5)
            if _G.PlayerESPRunning and character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local esp = createESP(character, false, true, nil, nil, otherPlayer.Name)
                    if esp then
                        _G.PlayerESPObjects[otherPlayer] = esp
                    end
                end
            end
        end)
        
        if otherPlayer.Character then
            task.wait(0.5)
            local character = otherPlayer.Character
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local esp = createESP(character, false, true, nil, nil, otherPlayer.Name)
                if esp then
                    _G.PlayerESPObjects[otherPlayer] = esp
                end
            end
        end
    end
    
    local function onPlayerRemoved(otherPlayer)
        if _G.PlayerESPObjects[otherPlayer] then
            removeESP(_G.PlayerESPObjects[otherPlayer])
            _G.PlayerESPObjects[otherPlayer] = nil
        end
    end
    
    refreshPlayerESP()
    
    _G.PlayerESPConnection = Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoved)
    
    local updateConnection
    updateConnection = RunService.RenderStepped:Connect(function()
        if not _G.PlayerESPRunning then
            updateConnection:Disconnect()
            return
        end
        
        for otherPlayer, esp in pairs(_G.PlayerESPObjects) do
            if otherPlayer and otherPlayer.Character and otherPlayer.Character.Parent then
                updateESP(esp)
            else
                removeESP(esp)
                _G.PlayerESPObjects[otherPlayer] = nil
            end
        end
    end)
end

local function toggleSpeed()
    if Toggles.SpeedToggle then
        Toggles.SpeedToggle:SetValue(not Toggles.SpeedToggle.Value)
    end
end

local Window = Library:CreateWindow({
    Title = "melbel🐧",
    Footer = "AutoFarm + ESP + Hitbox đẹp + Teleport + Waypoints + Tàng hình",
    Icon = 15740602925,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Chính", "home"),
    Player = Window:AddTab("Nhân vật", "user"),
    Teleport = Window:AddTab("Dịch chuyển", "move"),
    ESP = Window:AddTab("ESP", "eye"),
    Hitbox = Window:AddTab("Hitbox", "target"),
}

local AutoFarmGroup = Tabs.Main:AddLeftGroupbox("AutoFarm Tài nguyên")

AutoFarmGroup:AddToggle("AutoFarmToggle", {
    Text = "Bật AutoFarm tài nguyên",
    Default = false,
    Tooltip = "Di chuyển mượt đến tài nguyên đã chọn kèm tự ngắm",
    
    Callback = function(Value)
        if Value then
            startAutoFarm()
        else
            stopAutoFarm()
        end
    end,
})

AutoFarmGroup:AddSlider("FarmFlySpeed", {
    Text = "Tốc độ AutoFarm",
    Default = 50,
    Min = 20,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        _G.FarmFlySpeed = Value
    end
})

AutoFarmGroup:AddSlider("AimSmoothness", {
    Text = "Độ mượt khi ngắm",
    Default = 0.3,
    Min = 0.01,
    Max = 0.9,
    Rounding = 2,
    Tooltip = "Giá trị càng thấp thì camera xoay càng nhanh",
    Callback = function(Value)
        _G.AimSmoothness = Value
    end
})

AutoFarmGroup:AddDivider()

AutoFarmGroup:AddButton("Chọn tất cả tài nguyên để farm", function()
    toggleAllObjects(true)
    Library:Notify("Tất cả tài nguyên đều được lựa chọn để phục vụ nông nghiệp!", 3)
end)

AutoFarmGroup:AddButton("Bỏ chọn toàn bộ tài nguyên farm", function()
    toggleAllObjects(false)
    Library:Notify("Tất cả tài nguyên dành cho nông nghiệp đều bị hủy bỏ!", 3)
end)

AutoFarmGroup:AddDivider()
AutoFarmGroup:AddLabel("Chọn nguồn tài nguyên:")

for _, objName in pairs(_G.AvailableObjects) do
    AutoFarmGroup:AddToggle("FarmObject_" .. objName, {
        Text = objName,
        Default = true,
        
        Callback = function(Value)
            _G.SelectedObjects[objName] = Value
        end,
    })
end

local MovementGroup = Tabs.Main:AddRightGroupbox("Di chuyển")

MovementGroup:AddToggle("FlyToggle", {
    Text = "Bật Fly",
    Default = false,
    Tooltip = "WASD để di chuyển, Q/E lên xuống",
    
    Callback = function(Value)
        toggleFly()
    end,
})

MovementGroup:AddToggle("NoClipToggle", {
    Text = "Bật NoClip",
    Default = false,
    Tooltip = "Đi xuyên tường",
    
    Callback = function(Value)
        toggleNoClip()
    end,
})

MovementGroup:AddToggle("InfJumpToggle", {
    Text = "Bật InfJump",
    Default = false,
    Tooltip = "Nhảy InfJump (Space)",
    
    Callback = function(Value)
        toggleInfJump()
    end,
})

local FlySettingsGroup = Tabs.Main:AddLeftGroupbox("Cài đặt bay")

FlySettingsGroup:AddSlider("FlySpeed", {
    Text = "Bay",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
})

local CameraGroup = Tabs.Main:AddRightGroupbox("Tắt chế độ rung máy ảnh")

CameraGroup:AddButton("Tắt chế độ rung máy ảnh", function()
    disableCameraShake()
    Library:Notify("Chức năng chống rung camera đã bị tắt!", 3)
end)

local PlayerGroup = Tabs.Player:AddLeftGroupbox("Thuộc tính nhân vật")

PlayerGroup:AddToggle("SpeedToggle", {
    Text = "Thay đổi tốc độ",
    Default = false,
    
    Callback = function(Value)
        if Value then
            startSpeedLoop()
        else
            if _G.SpeedLoop then
                _G.SpeedLoop:Disconnect()
                _G.SpeedLoop = nil
            end
            
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = 16
                end
            end
        end
    end,
})

PlayerGroup:AddSlider("SpeedValue", {
    Text = "Tốc độ chạy",
    Default = 50,
    Min = 16,
    Max = 200,
    Rounding = 0,
})

PlayerGroup:AddToggle("InvisibleToggle", {
    Text = "Bật tàng hình",
    Default = false,
    Tooltip = "Làm nhân vật của bạn trở nên vô hình",
    
    Callback = function(Value)
        toggleInvisible()
    end,
})

local TeleportGroup = Tabs.Teleport:AddLeftGroupbox("Dịch chuyển")

TeleportGroup:AddToggle("ClickTPToggle", {
    Text = "Kích hoạt ClickTP",
    Default = false,
    
    Callback = function(Value)
        if Value then
            setupClickTP()
            Library:Notify("ClickTP đã được kích hoạt! Nhấp chuột trái để Dịch chuyển", 3)
        end
    end,
})

TeleportGroup:AddButton("Dịch chuyển đến người chơi gần nhất", function()
    teleportToNearestPlayer()
end)

local WaypointsGroup = Tabs.Teleport:AddRightGroupbox("Waypoints")

local waypointNameInput = WaypointsGroup:AddInput("WaypointNameInput", {
    Text = "Tên Waypoint",
    Default = "Waypoint",
    Tooltip = "Nhập tên vị trí",
    Placeholder = "Nhập tên",
})

WaypointsGroup:AddButton("Lưu Waypoint", function()
    local name = Options.WaypointNameInput.Value or "Waypoint"
    saveWaypoint(name)
end)

WaypointsGroup:AddDivider()

local waypointsList = WaypointsGroup:AddDropdown("WaypointsList", {
    Text = "Waypoint đã lưu",
    Default = 1,
    Values = {},
    Tooltip = "Chọn một điểm tham chiếu cho Dịch chuyển",
    
    Callback = function(Value)
        _G.SelectedWaypoint = Value
    end,
})

local function updateWaypointsList()
    local waypointValues = {}
    for id, waypoint in pairs(_G.Waypoints) do
        table.insert(waypointValues, id)
    end
    waypointsList:SetValues(waypointValues)
    
    if #waypointValues > 0 then
        local displayValues = {}
        for id, waypoint in pairs(_G.Waypoints) do
            table.insert(displayValues, waypoint.name .. " (" .. math.floor(waypoint.position.X) .. ", " .. math.floor(waypoint.position.Y) .. ", " .. math.floor(waypoint.position.Z) .. ")")
        end
        waypointsList:SetValues(displayValues)
    end
end

WaypointsGroup:AddButton("Dịch chuyển đến điểm tham chiếu đã chọn", function()
    if _G.SelectedWaypoint then
        for id, waypoint in pairs(_G.Waypoints) do
            local displayName = waypoint.name .. " (" .. math.floor(waypoint.position.X) .. ", " .. math.floor(waypoint.position.Y) .. ", " .. math.floor(waypoint.position.Z) .. ")"
            if displayName == _G.SelectedWaypoint then
                teleportToWaypoint(id)
                return
            end
        end
    end
    Library:Notify("Hãy chọn một điểm đến từ danh sách!", 3)
end)

WaypointsGroup:AddButton("Xóa Waypoint đã chọn", function()
    if _G.SelectedWaypoint then
        for id, waypoint in pairs(_G.Waypoints) do
            local displayName = waypoint.name .. " (" .. math.floor(waypoint.position.X) .. ", " .. math.floor(waypoint.position.Y) .. ", " .. math.floor(waypoint.position.Z) .. ")"
            if displayName == _G.SelectedWaypoint then
                deleteWaypoint(id)
                updateWaypointsList()
                return
            end
        end
    end
    Library:Notify("Выберите waypoint из списка!", 3)
end)

WaypointsGroup:AddButton("Cập nhật danh sách Waypoint", function()
    updateWaypointsList()
    Library:Notify("Danh sách điểm định vị đã được cập nhật!", 3)
end)

local HitboxGroup = Tabs.Hitbox:AddLeftGroupbox("Hitbox Multiplier")

HitboxGroup:AddToggle("AutoHitboxToggle", {
    Text = "Bật chế độ tự động chọn vùng va chạm",
    Default = false,
    Tooltip = "Tự động áp dụng vùng va chạm (hitbox) cho tất cả kẻ thù.",
    
    Callback = function(Value)
        toggleHitbox()
    end
})

HitboxGroup:AddSlider("HitboxMultiplier", {
    Text = "Множитель хитбокса",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Tooltip = "Thay đổi kích thước vùng va chạm của kẻ địch (Head.Size)",
    
    Callback = function(Value)
        if _G.HitboxEnabled then
            updateAllHitboxes(Value)
        end
    end
})

HitboxGroup:AddDivider()

local HeadHitboxGroup = Tabs.Hitbox:AddRightGroupbox("Vùng va chạm đầu đẹp")

HeadHitboxGroup:AddLabel("Vùng va chạm màu tím phong cách")
HeadHitboxGroup:AddLabel("Sáng và trong suốt")

HeadHitboxGroup:AddToggle("ShowHeadHitboxToggle", {
    Text = "Kích hoạt vùng va chạm đẹp mắt",
    Default = false,
    Tooltip = "Hiển thị các vùng va chạm màu tím bắt mắt trên đầu kẻ thù.",
    
    Callback = function(Value)
        toggleShowHeadHitbox()
    end
})

local ESPResourcesGroup = Tabs.ESP:AddLeftGroupbox("ESP Tài nguyên")

ESPResourcesGroup:AddToggle("ESPToggle", {
    Text = "Bật ESP tài nguyên",
    Default = false,
    Tooltip = "Hiển thị tài nguyên đã chọn trong Spawned",
    
    Callback = function(Value)
        toggleESP()
    end,
})

ESPResourcesGroup:AddDivider()

for _, objName in pairs(_G.AvailableObjects) do
    ESPResourcesGroup:AddToggle("ResourceESP_" .. objName, {
        Text = objName,
        Default = true,
        
        Callback = function(Value)
            _G.SelectedObjects[objName] = Value
            if _G.ESPRunning then
                refreshResourceESP()
            end
        end,
    })
end

ESPResourcesGroup:AddDivider()

ESPResourcesGroup:AddButton("Chọn tất cả các nguồn lực", function()
    toggleAllResources(true)
    Library:Notify("Tất cả tài liệu được chọn cho ESP!", 3)
end)

ESPResourcesGroup:AddButton("Hủy bỏ tất cả tài nguyên", function()
    toggleAllResources(false)
    Library:Notify("Tất cả tài nguyên đều bị hủy bỏ cho ESP!", 3)
end)

local ESPEnemiesGroup = Tabs.ESP:AddRightGroupbox("ESP Kẻ địch")

ESPEnemiesGroup:AddToggle("EnemyESPToggle", {
    Text = "Bật ESP kẻ địch",
    Default = false,
    Tooltip = "Hiển thị các kẻ thù đã chọn từ thư mục Kẻ thù.",
    
    Callback = function(Value)
        toggleEnemyESP()
    end,
})

ESPEnemiesGroup:AddDivider()

for _, enemyName in pairs(_G.KnownEnemies) do
    ESPEnemiesGroup:AddToggle("EnemyESP_" .. enemyName, {
        Text = enemyName,
        Default = true,
        
        Callback = function(Value)
            _G.SelectedEnemies[enemyName] = Value
            if _G.EnemyESPRunning then
                refreshEnemyESP()
            end
        end,
    })
end

ESPEnemiesGroup:AddDivider()

ESPEnemiesGroup:AddButton("Выбрать всех врагов", function()
    toggleAllEnemies(true)
    Library:Notify("Все враги выбраны для ESP!", 3)
end)

ESPEnemiesGroup:AddButton("Hủy bỏ tất cả kẻ thù", function()
    toggleAllEnemies(false)
    Library:Notify("Tất cả kẻ thù đều bị tiêu diệt nhờ ESP!", 3)
end)

local ESPPlayersGroup = Tabs.ESP:AddLeftGroupbox("ESP Người chơi")

ESPPlayersGroup:AddToggle("PlayerESPToggle", {
    Text = "Bật ESP người chơi",
    Default = false,
    Tooltip = "Hiển thị tất cả người chơi trên máy chủ",
    
    Callback = function(Value)
        togglePlayerESP()
    end,
})

local SettingsTab = Window:AddTab("Настройки UI", "settings")

local UIGroup = SettingsTab:AddLeftGroupbox("Управление")

UIGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Hiển thị menu chính",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

UIGroup:AddLabel("Клавиша меню"):AddKeyPicker("MenuKeybind", { 
    Default = "RightShift", 
    NoUI = true, 
    Text = "Phím menu" 
})

Library.ToggleKeybind = Options.MenuKeybind

UIGroup:AddDivider()
UIGroup:AddButton("Tải lên kịch bản", function()
    stopAutoFarm()
    _G.Flying = false
    if _G.FlyBodyVelocity then
        _G.FlyBodyVelocity:Destroy()
    end
    _G.NoClipEnabled = false
    if _G.NoClipConnection then
        _G.NoClipConnection:Disconnect()
    end
    _G.InfJumpEnabled = false
    if _G.InfJumpConnection then
        _G.InfJumpConnection:Disconnect()
    end
    
    if _G.SpeedLoop then
        _G.SpeedLoop:Disconnect()
        _G.SpeedLoop = nil
    end
    
    _G.HitboxEnabled = false
    if _G.HitboxConnection then
        _G.HitboxConnection:Disconnect()
    end
    resetEnemyHitboxes()
    
    _G.ShowHeadHitboxEnabled = false
    if _G.HeadHitboxConnection then
        _G.HeadHitboxConnection:Disconnect()
    end
    for enemy, hitboxData in pairs(_G.HeadHitboxParts) do
        removeHeadHitbox(hitboxData)
    end
    _G.HeadHitboxParts = {}
    
    _G.ESPRunning = false
    for _, esp in pairs(_G.ESPObjects) do
        removeESP(esp)
    end
    _G.ESPObjects = {}
    
    _G.EnemyESPRunning = false
    for _, esp in pairs(_G.EnemyESPObjects) do
        removeESP(esp)
    end
    _G.EnemyESPObjects = {}
    
    _G.PlayerESPRunning = false
    for _, esp in pairs(_G.PlayerESPObjects) do
        removeESP(esp)
    end
    _G.PlayerESPObjects = {}
    
    _G.Invisible = false
    if _G.InvisibilityConnection then
        _G.InvisibilityConnection:Disconnect()
        _G.InvisibilityConnection = nil
    end
    
    Library:Unload()
end)

player.CharacterAdded:Connect(function(character)
    task.wait(1)
    
    if Toggles.SpeedToggle and Toggles.SpeedToggle.Value then
        startSpeedLoop()
    end
end)

if ThemeManager and SaveManager then
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    
    ThemeManager:SetFolder("RobloxMAN")
    SaveManager:SetFolder("RobloxMAN/configs")
    
    SaveManager:BuildConfigSection(SettingsTab)
    ThemeManager:ApplyToTab(SettingsTab)
    
    SaveManager:LoadAutoloadConfig()
end

updateWaypointsList()

Library:OnUnload(function()
    stopAutoFarm()
    _G.Flying = false
    if _G.FlyBodyVelocity then
        _G.FlyBodyVelocity:Destroy()
    end
    _G.NoClipEnabled = false
    if _G.NoClipConnection then
        _G.NoClipConnection:Disconnect()
    end
    _G.InfJumpEnabled = false
    if _G.InfJumpConnection then
        _G.InfJumpConnection:Disconnect()
    end
    
    if _G.SpeedLoop then
        _G.SpeedLoop:Disconnect()
        _G.SpeedLoop = nil
    end
    
    _G.HitboxEnabled = false
    if _G.HitboxConnection then
        _G.HitboxConnection:Disconnect()
    end
    resetEnemyHitboxes()
    
    _G.ShowHeadHitboxEnabled = false
    if _G.HeadHitboxConnection then
        _G.HeadHitboxConnection:Disconnect()
    end
    for enemy, hitboxData in pairs(_G.HeadHitboxParts) do
        removeHeadHitbox(hitboxData)
    end
    _G.HeadHitboxParts = {}
    
    _G.ESPRunning = false
    for _, esp in pairs(_G.ESPObjects) do
        removeESP(esp)
    end
    _G.ESPObjects = {}
    
    _G.EnemyESPRunning = false
    for _, esp in pairs(_G.EnemyESPObjects) do
        removeESP(esp)
    end
    _G.EnemyESPObjects = {}
    
    _G.PlayerESPRunning = false
    for _, esp in pairs(_G.PlayerESPObjects) do
        removeESP(esp)
    end
    _G.PlayerESPObjects = {}
    
    _G.Invisible = false
    if _G.InvisibilityConnection then
        _G.InvisibilityConnection:Disconnect()
        _G.InvisibilityConnection = nil
    end
end)

task.wait(1)
disableCameraShake()
