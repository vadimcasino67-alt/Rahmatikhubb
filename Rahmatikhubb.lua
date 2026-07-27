--[[
    RAHMAT Menu v7.3 + MM2 Tab (Мудрый Живчик) — СУПЕРСТАБИЛЬНЫЙ ФИКС
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Проверка Drawing API
local DrawingAvailable = pcall(function() return Drawing end) and Drawing ~= nil
local fovCircle, targetMarker
if DrawingAvailable then
    fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Thickness = 1
    fovCircle.Transparency = 0.7
    fovCircle.Visible = false
    fovCircle.Radius = 100
    fovCircle.Filled = false

    targetMarker = Drawing.new("Circle")
    targetMarker.Color = Color3.fromRGB(255, 0, 0)
    targetMarker.Thickness = 2
    targetMarker.Transparency = 0.5
    targetMarker.Visible = false
    targetMarker.Radius = 6
end

-- Кэширование персонажа
local character, humanoid, rootPart
local function updateCharacter()
    character = player.Character
    if character then
        humanoid = character:FindFirstChild("Humanoid")
        rootPart = character:FindFirstChild("HumanoidRootPart")
    else
        humanoid = nil
        rootPart = nil
    end
end

-- ПЕРЕМЕННЫЕ ПО УМОЛЧАНИЮ
local savedWalkSpeed = 16
local savedJumpPower = 50
local flySpeed = 50
local flying = false
local bodyVelocity, bodyGyro
local noclipEnabled = false
local noclipConnection = nil
local invisEnabled = false
local invisSavedCFrame = nil
local flingEnabled = false
local flingConnections = {}
local espEnabledNames = false
local espEnabledBoxes = false
local espObjects = {}
local aimbotEnabled = false
local aimTargetPlayer = nil
local fovRadius = 100
local currentHue = 0
local teleportTarget = nil

-- MM2 переменные
local MM2 = {
    AimbotEnabled = true,
    ESPEnabled = true,
    FOV = 120,
    Smoothness = 0.4,
    Range = 50,
    ShootButtonEnabled = false,
    KnifeThrowEnabled = false,
    AutoPickupGun = false,
    FreezeButtons = false
}
local mm2EspStorage = {}

-- ФУНКЦИИ ОБЩИЕ
local function HSVtoRGB(h, s, v)
    h = h % 360
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b = 0, 0, 0
    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = x, 0, c
    elseif h < 300 then r, g, b = 0, x, c
    else r, g, b = c, 0, x end
    return Color3.fromRGB((r + m) * 255, (g + m) * 255, (b + m) * 255)
end

local mainFrame, titleBar, contentFrame  -- будут созданы

local function applyHue(hue)
    if not mainFrame then return end
    local mainColor = HSVtoRGB(hue, 0.2, 0.25)
    local titleColor = HSVtoRGB(hue, 0.3, 0.2)
    local contentColor = HSVtoRGB(hue, 0.15, 0.3)
    mainFrame.BackgroundColor3 = mainColor
    titleBar.BackgroundColor3 = titleColor
    contentFrame.BackgroundColor3 = contentColor
end

-- Fly
local function startFly()
    updateCharacter()
    if not rootPart then return end
    flying = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 10000
    bodyGyro.Parent = rootPart
end

local function stopFly()
    flying = false
    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
end

-- Noclip
local function enableNoClip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        updateCharacter()
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end

local function disableNoClip()
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
end

-- Invisibility
local function applyInvisibility(state)
    updateCharacter()
    if not character or not rootPart then return end
    if state then
        invisSavedCFrame = rootPart.CFrame
        rootPart.CFrame = CFrame.new(0, -500, 0)
        rootPart.Anchored = true
        if humanoid then humanoid.WalkSpeed = 0 end
    else
        if invisSavedCFrame then
            rootPart.CFrame = invisSavedCFrame
            invisSavedCFrame = nil
        end
        rootPart.Anchored = false
        if humanoid then humanoid.WalkSpeed = savedWalkSpeed end
    end
end

-- Fling
local function setupFling(char)
    if not flingEnabled then return end
    for _, conn in ipairs(flingConnections) do conn:Disconnect() end
    table.clear(flingConnections)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local conn = part.Touched:Connect(function(hitPart)
                if not flingEnabled then return end
                local hitChar = hitPart.Parent
                if hitChar:IsA("Model") and Players:GetPlayerFromCharacter(hitChar) and hitChar ~= char then
                    local hitRoot = hitChar:FindFirstChild("HumanoidRootPart")
                    if hitRoot then
                        local flingDir = (hitRoot.Position - part.Position).Unit + Vector3.new(0, 1, 0)
                        local bv = Instance.new("BodyVelocity")
                        bv.Velocity = flingDir * 200 + Vector3.new(0, 100, 0)
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Parent = hitRoot
                        Debris:AddItem(bv, 0.5)
                    end
                end
            end)
            table.insert(flingConnections, conn)
        end
    end
end

local function disableFling()
    for _, conn in ipairs(flingConnections) do conn:Disconnect() end
    table.clear(flingConnections)
end

-- ESP/AIMBOT
local function clearESP(target)
    local data = espObjects[target]
    if data then
        if data.nameTag then data.nameTag:Remove() end
        if data.lines then for _, line in ipairs(data.lines) do line:Remove() end end
        espObjects[target] = nil
    end
end

function clearAllESP()
    for _, data in pairs(espObjects) do
        if data.nameTag then data.nameTag:Remove() end
        if data.lines then for _, line in ipairs(data.lines) do line:Remove() end end
    end
    table.clear(espObjects)
end

local function createESPForPlayer(target)
    if target == player then return end
    if espObjects[target] then clearESP(target) end
    local data = {nameTag = nil, lines = {}}
    if espEnabledNames and DrawingAvailable then
        local nameTag = Drawing.new("Text")
        nameTag.Size = 14
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.Color = Color3.fromRGB(255, 255, 255)
        nameTag.Visible = false
        data.nameTag = nameTag
    end
    if espEnabledBoxes and DrawingAvailable then
        for i = 1, 12 do
            local line = Drawing.new("Line")
            line.Color = Color3.fromRGB(255, 0, 0)
            line.Thickness = 2
            line.Visible = false
            table.insert(data.lines, line)
        end
    end
    if data.nameTag or #data.lines > 0 then espObjects[target] = data end
end

local function updateESP()
    if not DrawingAvailable then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    for target, data in pairs(espObjects) do
        local char = target.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local human = char and char:FindFirstChild("Humanoid")
        local visible = hrp and head and human and human.Health > 0
        if data.nameTag then
            if visible then
                local headPos = head.Position + Vector3.new(0, 0.5, 0)
                local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
                data.nameTag.Visible = onScreen and screenPos.Z > 0
                if data.nameTag.Visible then
                    data.nameTag.Position = Vector2.new(screenPos.X, screenPos.Y)
                    data.nameTag.Text = target.Name
                end
            else data.nameTag.Visible = false end
        end
        if #data.lines > 0 then
            if visible then
                local extents = char:GetExtentsSize()
                local half = extents / 2
                local cf = hrp.CFrame
                local corners = {
                    cf * Vector3.new(-half.X, half.Y, -half.Z), cf * Vector3.new(half.X, half.Y, -half.Z),
                    cf * Vector3.new(half.X, half.Y, half.Z), cf * Vector3.new(-half.X, half.Y, half.Z),
                    cf * Vector3.new(-half.X, -half.Y, -half.Z), cf * Vector3.new(half.X, -half.Y, -half.Z),
                    cf * Vector3.new(half.X, -half.Y, half.Z), cf * Vector3.new(-half.X, -half.Y, half.Z)
                }
                local screenCorners = {}
                local allOnScreen = true
                for _, corner in ipairs(corners) do
                    local screenPos, onScreen = camera:WorldToViewportPoint(corner)
                    if not onScreen or screenPos.Z <= 0 then allOnScreen = false break end
                    table.insert(screenCorners, screenPos)
                end
                if allOnScreen and #screenCorners == 8 then
                    local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
                    for i, edge in ipairs(edges) do
                        if i <= #data.lines then
                            local p1, p2 = screenCorners[edge[1]], screenCorners[edge[2]]
                            data.lines[i].From = Vector2.new(p1.X, p1.Y)
                            data.lines[i].To = Vector2.new(p2.X, p2.Y)
                            data.lines[i].Visible = true
                        end
                    end
                else for _, line in ipairs(data.lines) do line.Visible = false end end
            else for _, line in ipairs(data.lines) do line.Visible = false end end
        end
    end
end

local function getAimTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local screenCenter = camera.ViewportSize / 2
    if aimTargetPlayer then
        local char = aimTargetPlayer.Character
        local head = char and char:FindFirstChild("Head")
        if head and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen and screenPos.Z > 0 and (Vector2.new(screenPos.X - screenCenter.X, screenPos.Y - screenCenter.Y)).Magnitude < fovRadius then
                return head
            end
        end
        return nil
    else
        local closestHead = nil
        local shortestDist = fovRadius
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= player then
                local char = target.Character
                local head = char and char:FindFirstChild("Head")
                if head and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    if onScreen and screenPos.Z > 0 then
                        local dist = (Vector2.new(screenPos.X - screenCenter.X, screenPos.Y - screenCenter.Y)).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            closestHead = head
                        end
                    end
                end
            end
        end
        return closestHead
    end
end

local function updateAimbot()
    if not DrawingAvailable then return end
    if not aimbotEnabled then 
        if fovCircle then fovCircle.Visible = false end
        if targetMarker then targetMarker.Visible = false end
        return 
    end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local screenCenter = camera.ViewportSize / 2
    if fovCircle then
        fovCircle.Position = screenCenter
        fovCircle.Visible = true
        fovCircle.Radius = fovRadius
    end
    local targetHead = getAimTarget()
    if targetHead then
        camera.CFrame = CFrame.new(camera.CFrame.Position, targetHead.Position)
        if targetMarker then
            local screenPos, onScreen = camera:WorldToViewportPoint(targetHead.Position)
            if onScreen and screenPos.Z > 0 then
                targetMarker.Position = Vector2.new(screenPos.X, screenPos.Y)
                targetMarker.Visible = true
            else targetMarker.Visible = false end
        end
    else
        if targetMarker then targetMarker.Visible = false end
    end
end

function refreshESP()
    clearAllESP()
    if (espEnabledNames or espEnabledBoxes) and DrawingAvailable then
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= player then createESPForPlayer(target) end
        end
    end
end

-- MM2 функции
local function getPlayerRoleMM2(plr)
    local role = "Innocent"
    local char = plr.Character
    if not char then return role end
    local function hasItem(name)
        if plr.Backpack:FindFirstChild(name) then return true end
        if char:FindFirstChild(name) then return true end
        return false
    end
    if hasItem("Knife") and not hasItem("Gun") then
        role = "Murderer"
    elseif hasItem("Gun") then
        role = "Sheriff"
    end
    return role
end

local function createESPMM2(plr)
    if mm2EspStorage[plr] then return end
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MM2_ESP"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextColor3 = Color3.new(1,1,1)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 18
    textLabel.Parent = billboard
    mm2EspStorage[plr] = {Gui = billboard, Label = textLabel}
end

local function updateESPMM2()
    if not MM2.ESPEnabled then return end
    for plr, data in pairs(mm2EspStorage) do
        local char = plr.Character
        local human = char and char:FindFirstChild("Humanoid")
        if not char or not human or human.Health <= 0 then
            data.Gui:Destroy()
            mm2EspStorage[plr] = nil
        else
            local role = getPlayerRoleMM2(plr)
            local color = Color3.new(1,1,1)
            if role == "Murderer" then
                color = Color3.fromRGB(255, 50, 50)
                data.Label.Text = "Убийца"
            elseif role == "Sheriff" then
                color = Color3.fromRGB(50, 150, 255)
                data.Label.Text = "Шериф"
            else
                data.Gui:Destroy()
                mm2EspStorage[plr] = nil
                continue
            end
            data.Label.TextColor3 = color
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and not mm2EspStorage[plr] then
            local role = getPlayerRoleMM2(plr)
            if role == "Murderer" or role == "Sheriff" then
                createESPMM2(plr)
            end
        end
    end
end

function getClosestEnemyMM2()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local myPos = root.Position
    local screenCenter = workspace.CurrentCamera.ViewportSize / 2
    local closest = nil
    local closestDist = MM2.FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local enemyRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local enemyHuman = plr.Character:FindFirstChild("Humanoid")
            if enemyRoot and enemyHuman and enemyHuman.Health > 0 then
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(enemyRoot.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = {
                            Player = plr,
                            Character = plr.Character,
                            RootPart = enemyRoot,
                            ScreenPos = screenPos,
                            Distance = (myPos - enemyRoot.Position).Magnitude
                        }
                    end
                end
            end
        end
    end
    return closest
end

function smoothAimMM2(target)
    if not target then return end
    local cam = workspace.CurrentCamera
    local lookAt = CFrame.new(cam.CFrame.Position, target.RootPart.Position)
    if MM2.Smoothness >= 1 then
        cam.CFrame = lookAt
    else
        cam.CFrame = cam.CFrame:Lerp(lookAt, MM2.Smoothness)
    end
end

local lastAttackMM2 = 0
local function autoAttackMM2(target)
    if not target then return end
    if target.Distance > MM2.Range then return end
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

-- ================== СОЗДАНИЕ GUI ==================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RAHMAT_Menu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 460, 0, 380)
mainFrame.Position = UDim2.new(0.5, -230, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Active = false
mainFrame.Parent = screenGui
mainFrame.ZIndex = 1

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 14)
uiCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(0, 0, 0)
mainStroke.Transparency = 0.5
mainStroke.Thickness = 1.5
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Parent = mainFrame

-- Заголовок
titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
titleBar.ZIndex = 2

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -44, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "RAHMAT"
titleLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.Parent = titleBar

local rainbowHue = 0
RunService.RenderStepped:Connect(function(dt)
    rainbowHue = (rainbowHue + dt * 120) % 360
    titleLabel.TextColor3 = HSVtoRGB(rainbowHue, 1, 1)
end)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -34, 0, 4)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = titleBar
closeButton.ZIndex = 20
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 48, 0, 48)
openButton.Position = UDim2.new(1, -66, 0.5, -24)
openButton.BackgroundColor3 = Color3.fromRGB(123, 97, 255)
openButton.Text = "R"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 22
openButton.Visible = false
openButton.Parent = screenGui
openButton.ZIndex = 20

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(1, 0)
openCorner.Parent = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(255, 255, 255)
openStroke.Thickness = 2
openStroke.Transparency = 0.4
openStroke.Parent = openButton

local function openMenu()
    mainFrame.Visible = true
    openButton.Visible = false
end
local function closeMenu()
    mainFrame.Visible = false
    openButton.Visible = true
end

closeButton.MouseButton1Click:Connect(closeMenu)
openButton.MouseButton1Click:Connect(openMenu)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if mainFrame.Visible then closeMenu() else openMenu() end
    end
end)

-- Перемещение меню
local dragging = false
local dragStartPos, frameStartPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStartPos = UserInputService:GetMouseLocation()
        frameStartPos = mainFrame.Position
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = UserInputService:GetMouseLocation() - dragStartPos
        mainFrame.Position = UDim2.new(
            frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
        )
    end
end)

-- Панель вкладок
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 32)
tabBar.Position = UDim2.new(0, 8, 0, 46)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame
tabBar.ZIndex = 15

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar

local function createTabButton(name, text)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 80, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.ZIndex = 30
    btn.Parent = tabBar
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    return btn
end

local infoTab = createTabButton("InfoTab", "Инфо")
local settingsTab = createTabButton("SettingsTab", "Настр.")
local animsTab = createTabButton("AnimationsTab", "Анимки")
local playerTab = createTabButton("PlayerTab", "Игрок")
local visualsTab = createTabButton("VisualsTab", "Визуалы")
local mm2Tab = createTabButton("MM2Tab", "MM2")

local tabButtons = {infoTab, settingsTab, animsTab, playerTab, visualsTab, mm2Tab}
local tabPadding = 4

local function resizeTabs()
    local totalWidth = mainFrame.AbsoluteSize.X - 16
    if totalWidth <= 0 then return end
    local numTabs = #tabButtons
    local totalPadding = (numTabs - 1) * tabPadding
    local availableWidth = totalWidth - totalPadding
    local tabWidth = math.max(60, availableWidth / numTabs)
    for _, btn in ipairs(tabButtons) do
        btn.Size = UDim2.new(0, tabWidth, 1, 0)
    end
end
mainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeTabs)
resizeTabs()

-- Контент
contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -16, 1, -86)
contentFrame.Position = UDim2.new(0, 8, 0, 82)
contentFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame
contentFrame.Active = false
contentFrame.ZIndex = 1

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 12)
contentCorner.Parent = contentFrame

local pages = {}

local function createScrollPage()
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 3
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
    sf.ElasticBehavior = Enum.ElasticBehavior.Never
    sf.ScrollingDirection = Enum.ScrollingDirection.Y
    sf.ClipsDescendants = true
    sf.Parent = contentFrame
    sf.Visible = false
    sf.ZIndex = 1
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = sf
    return sf
end

local function fixScrolling(sf)
    task.wait()
    local layout = sf:FindFirstChildOfClass("UIListLayout")
    local padding = layout and layout.Padding.Offset or 0
    local totalHeight = 0
    for _, child in ipairs(sf:GetChildren()) do
        if child:IsA("GuiObject") and child ~= layout then
            totalHeight = totalHeight + child.AbsoluteSize.Y + padding
        end
    end
    if totalHeight > 0 then
        sf.AutomaticCanvasSize = Enum.AutomaticSize.None
        sf.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    end
end

-- ================== ВКЛАДКА ИНФО ==================
local infoPage = createScrollPage()
infoPage.Visible = true
pages.Info = infoPage

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -16, 0, 160)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Добро пожаловать в RAHMAT!\n\nСвернуть: ✕\nОткрыть: R (Android) или RightShift"
infoLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 13
infoLabel.Parent = infoPage
infoLabel.ZIndex = 1
task.spawn(function() fixScrolling(infoPage) end)

-- ================== ВКЛАДКА НАСТРОЙКИ ==================
local settingsPage = createScrollPage()
settingsPage.Visible = false
pages.Settings = settingsPage

local settingsLabel = Instance.new("TextLabel")
settingsLabel.Size = UDim2.new(1, -16, 0, 24)
settingsLabel.BackgroundTransparency = 1
settingsLabel.Text = "Настройки"
settingsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
settingsLabel.Font = Enum.Font.GothamBold
settingsLabel.TextSize = 15
settingsLabel.Parent = settingsPage
settingsLabel.ZIndex = 1

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0, 180, 0, 30)
resetButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
resetButton.Text = "Очистить настройки"
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.Font = Enum.Font.GothamBold
resetButton.TextSize = 13
resetButton.Parent = settingsPage
resetButton.ZIndex = 10
local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 6)
resetCorner.Parent = resetButton

local function resetAllSettings()
    if flying then stopFly(); flyBtn.Text = "Fly: Выкл"; flyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56) end
    if noclipEnabled then noclipEnabled = false; disableNoClip(); noclipBtn.Text = "Noclip: Выкл"; noclipBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56) end
    if invisEnabled then invisEnabled = false; applyInvisibility(false); invisBtn.Text = "Невидимка: Выкл"; invisBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56) end
    if flingEnabled then flingEnabled = false; disableFling(); flingBtn.Text = "Fling: Выкл"; flingBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56) end
    if espEnabledNames then espEnabledNames = false; namesToggle.Text = "Ники: Выкл"; namesToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 56) end
    if espEnabledBoxes then espEnabledBoxes = false; boxesToggle.Text = "Хитбоксы: Выкл"; boxesToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 56) end
    clearAllESP()
    if aimbotEnabled then aimbotEnabled = false; aimbotBtn.Text = "Аимбот: Выкл"; aimbotBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56) end
    savedWalkSpeed = 16; savedJumpPower = 50; flySpeed = 50
    if humanoid then humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 end
    teleportTarget = nil; teleportDropdownBtn.Text = "Выбрать"
    currentHue = 0; applyHue(0); updateHueKnobPosition()
    fovRadius = 100; if fovCircle then fovCircle.Radius = 100 end; fovBox.Text = "100"
    refreshESP()
    MM2.AimbotEnabled = false; mm2AimbotBtn.Text = "Аимбот: Выкл"; mm2AimbotBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
    MM2.ESPEnabled = false; mm2ESPBtn.Text = "ESP: Выкл"; mm2ESPBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
    if MM2.ShootButtonEnabled then
        MM2.ShootButtonEnabled = false
        shootToggleBtn.Text = "Выстрел (Шериф): Выкл"
        shootToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
        shootBtn.Visible = false
    end
    if MM2.KnifeThrowEnabled then
        MM2.KnifeThrowEnabled = false
        knifeToggleBtn.Text = "Бросок ножа: Выкл"
        knifeToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
        knifeBtn.Visible = false
    end
    if MM2.AutoPickupGun then
        MM2.AutoPickupGun = false
        autoPickupBtn.Text = "Авто-подбор пистолета: Выкл"
        autoPickupBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
    end
    for _, data in pairs(mm2EspStorage) do data.Gui:Destroy() end
    mm2EspStorage = {}
end
resetButton.MouseButton1Click:Connect(resetAllSettings)
task.spawn(function() fixScrolling(settingsPage) end)

-- ================== ВКЛАДКА АНИМКИ ==================
local animsPage = createScrollPage()
pages.Animations = animsPage

local animsLabel = Instance.new("TextLabel")
animsLabel.Size = UDim2.new(1, -16, 0, 24)
animsLabel.BackgroundTransparency = 1
animsLabel.Text = "Анимации"
animsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
animsLabel.TextXAlignment = Enum.TextXAlignment.Left
animsLabel.Font = Enum.Font.GothamBold
animsLabel.TextSize = 15
animsLabel.Parent = animsPage
animsLabel.ZIndex = 1

local animContainer = Instance.new("Frame")
animContainer.Size = UDim2.new(1, -16, 0, 160)
animContainer.BackgroundTransparency = 1
animContainer.Parent = animsPage
animContainer.ZIndex = 1

local animLayout = Instance.new("UIListLayout")
animLayout.FillDirection = Enum.FillDirection.Horizontal
animLayout.Wraps = true
animLayout.Padding = UDim.new(0, 6)
animLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
animLayout.Parent = animContainer

local animList = {
    {id = "1083461615", name = "Zombie Idle"},
    {id = "1083462077", name = "Zombie Walk"},
    {id = "3360689775", name = "Cartwheel"},
    {id = "3360963031", name = "Levitation"},
    {id = "656118852", name = "Ninja Run"},
    {id = "180393400", name = "Jump"}
}

local currentTrack = nil
local function getAnimator()
    updateCharacter()
    if not character or not humanoid then return nil end
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    return animator
end

local function stopAllAnimations()
    if currentTrack then currentTrack:Stop(); currentTrack = nil end
end

local function playAnimationById(id)
    stopAllAnimations()
    local animator = getAnimator()
    if not animator then return end
    local animObj = Instance.new("Animation")
    animObj.AnimationId = "rbxassetid://" .. id
    local track = animator:LoadAnimation(animObj)
    track:Play()
    currentTrack = track
end

local function createAnimButton(parent, animData)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 90, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
    btn.Text = animData.name
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.ZIndex = 10
    btn.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    btn.MouseButton1Click:Connect(function()
        playAnimationById(animData.id)
        for _, child in parent:GetChildren() do
            if child:IsA("TextButton") then child.BackgroundColor3 = Color3.fromRGB(50, 50, 56) end
        end
        btn.BackgroundColor3 = Color3.fromRGB(123, 97, 255)
    end)
    return btn
end

for _, anim in ipairs(animList) do
    createAnimButton(animContainer, anim)
end

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 90, 0, 28)
stopBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
stopBtn.Text = "Стоп"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 12
stopBtn.ZIndex = 10
stopBtn.Parent = animContainer
local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 6)
stopCorner.Parent = stopBtn
stopBtn.MouseButton1Click:Connect(function()
    stopAllAnimations()
    for _, child in animContainer:GetChildren() do
        if child:IsA("TextButton") and child ~= stopBtn then child.BackgroundColor3 = Color3.fromRGB(50, 50, 56) end
    end
end)

local idFrame = Instance.new("Frame")
idFrame.Size = UDim2.new(1, -16, 0, 30)
idFrame.BackgroundTransparency = 1
idFrame.Parent = animsPage
idFrame.ZIndex = 1

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(0, 80, 1, 0)
idLabel.BackgroundTransparency = 1
idLabel.Text = "ID аним.:"
idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
idLabel.TextXAlignment = Enum.TextXAlignment.Left
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 12
idLabel.Parent = idFrame
idLabel.ZIndex = 1

local idBox = Instance.new("TextBox")
idBox.Size = UDim2.new(0, 120, 1, 0)
idBox.Position = UDim2.new(0, 84, 0, 0)
idBox.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
idBox.Text = ""
idBox.TextColor3 = Color3.fromRGB(255, 255, 255)
idBox.Font = Enum.Font.Gotham
idBox.TextSize = 12
idBox.PlaceholderText = "ID"
idBox.ClearTextOnFocus = false
idBox.Parent = idFrame
idBox.ZIndex = 1
local idCorner = Instance.new("UICorner")
idCorner.CornerRadius = UDim.new(0, 4)
idCorner.Parent = idBox

local playIdBtn = Instance.new("TextButton")
playIdBtn.Size = UDim2.new(0, 60, 1, 0)
playIdBtn.Position = UDim2.new(1, -64, 0, 0)
playIdBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
playIdBtn.Text = "Играть"
playIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playIdBtn.Font = Enum.Font.Gotham
playIdBtn.TextSize = 12
playIdBtn.Parent = idFrame
playIdBtn.ZIndex = 10
local playIdCorner = Instance.new("UICorner")
playIdCorner.CornerRadius = UDim.new(0, 4)
playIdCorner.Parent = playIdBtn

playIdBtn.MouseButton1Click:Connect(function()
    local id = idBox.Text
    if id ~= "" then
        playAnimationById(id)
        for _, child in animContainer:GetChildren() do
            if child:IsA("TextButton") then child.BackgroundColor3 = Color3.fromRGB(50, 50, 56) end
        end
    end
end)

task.spawn(function() fixScrolling(animsPage) end)

-- ================== ВКЛАДКА ИГРОК ==================
local playerPage = createScrollPage()
pages.Player = playerPage

local playerLabel = Instance.new("TextLabel")
playerLabel.Size = UDim2.new(1, -16, 0, 24)
playerLabel.BackgroundTransparency = 1
playerLabel.Text = "Игрок"
playerLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
playerLabel.TextXAlignment = Enum.TextXAlignment.Left
playerLabel.Font = Enum.Font.GothamBold
playerLabel.TextSize = 15
playerLabel.Parent = playerPage
playerLabel.ZIndex = 1

local playerInfo = Instance.new("TextLabel")
playerInfo.Size = UDim2.new(1, -16, 0, 40)
playerInfo.BackgroundTransparency = 1
playerInfo.Text = "Имя: " .. player.Name .. "\nDisplayName: " .. player.DisplayName
playerInfo.TextColor3 = Color3.fromRGB(190, 190, 190)
playerInfo.TextWrapped = true
playerInfo.TextXAlignment = Enum.TextXAlignment.Left
playerInfo.TextYAlignment = Enum.TextYAlignment.Top
playerInfo.Font = Enum.Font.Gotham
playerInfo.TextSize = 12
playerInfo.Parent = playerPage
playerInfo.ZIndex = 1

-- Fly
local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(0, 160, 0, 30)
flyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
flyBtn.Text = "Fly: Выкл"
flyBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
flyBtn.Font = Enum.Font.GothamBold
flyBtn.TextSize = 13
flyBtn.Parent = playerPage
flyBtn.ZIndex = 10
local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 6)
flyCorner.Parent = flyBtn

flyBtn.MouseButton1Click:Connect(function()
    if flying then
        stopFly()
        flyBtn.Text = "Fly: Выкл"
        flyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
    else
        startFly()
        flyBtn.Text = "Fly: Вкл"
        flyBtn.BackgroundColor3 = Color3.fromRGB(123, 97, 255)
    end
end)

-- Noclip
local noclipBtn = Instance.new("TextButton")
noclipBtn.Size = UDim2.new(0, 160, 0, 30)
noclipBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
noclipBtn.Text = "Noclip: Выкл"
noclipBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
noclipBtn.Font = Enum.Font.GothamBold
noclipBtn.TextSize = 13
noclipBtn.Parent = playerPage
noclipBtn.ZIndex = 10
local noclipCorner = Instance.new("UICorner")
noclipCorner.CornerRadius = UDim.new(0, 6)
noclipCorner.Parent = noclipBtn

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        enableNoClip()
        noclipBtn.Text = "Noclip: Вкл"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(123, 97, 255)
    else
        disableNoClip()
        noclipBtn.Text = "Noclip: Выкл"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
    end
end)

-- Невидимка
local invisBtn = Instance.new("TextButton")
invisBtn.Size = UDim2.new(0, 160, 0, 30)
invisBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
invisBtn.Text = "Невидимка: Выкл"
invisBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
invisBtn.Font = Enum.Font.GothamBold
invisBtn.TextSize = 13
invisBtn.Parent = playerPage
invisBtn.ZIndex = 10
local invisCorner = Instance.new("UICorner")
invisCorner.CornerRadius = UDim.new(0, 6)
invisCorner.Parent = invisBtn

invisBtn.MouseButton1Click:Connect(function()
    invisEnabled = not invisEnabled
    if invisEnabled then
        applyInvisibility(true)
        invisBtn.Text = "Невидимка: Вкл"
        invisBtn.BackgroundColor3 = Color3.fromRGB(123, 97, 255)
    else
        applyInvisibility(false)
        invisBtn.Text = "Невидимка: Выкл"
        invisBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
    end
end)

-- Телепорт
local teleportLabel = Instance.new("TextLabel")
teleportLabel.Size = UDim2.new(1, -16, 0, 18)
teleportLabel.BackgroundTransparency = 1
teleportLabel.Text = "Телепорт к игроку:"
teleportLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
teleportLabel.TextXAlignment = Enum.TextXAlignment.Left
teleportLabel.Font = Enum.Font.Gotham
teleportLabel.TextSize = 12
teleportLabel.Parent = playerPage
teleportLabel.ZIndex = 1

local teleportDropdownBtn = Instance.new("TextButton")
teleportDropdownBtn.Size = UDim2.new(0, 160, 0, 28)
teleportDropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
teleportDropdownBtn.Text = "Выбрать"
teleportDropdownBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
teleportDropdownBtn.Font = Enum.Font.Gotham
teleportDropdownBtn.TextSize = 12
teleportDropdownBtn.Parent = playerPage
teleportDropdownBtn.ZIndex = 10
local teleportDropdownCorner = Instance.new("UICorner")
teleportDropdownCorner.CornerRadius = UDim.new(0, 4)
teleportDropdownCorner.Parent = teleportDropdownBtn

local teleportListFrame = Instance.new("ScrollingFrame")
teleportListFrame.Size = UDim2.new(0, 160, 0, 80)
teleportListFrame.Position = UDim2.new(0, 8, 0, 250)
teleportListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
teleportListFrame.BorderSizePixel = 0
teleportListFrame.Visible = false
teleportListFrame.ZIndex = 20
teleportListFrame.ScrollBarThickness = 3
teleportListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
teleportListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
teleportListFrame.ElasticBehavior = Enum.ElasticBehavior.Never
teleportListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
teleportListFrame.ClipsDescendants = true
teleportListFrame.Parent = playerPage
local teleportListLayout = Instance.new("UIListLayout")
teleportListLayout.Padding = UDim.new(0, 2)
teleportListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
teleportListLayout.SortOrder = Enum.SortOrder.LayoutOrder
teleportListLayout.Parent = teleportListFrame

local function updateTeleportList()
    for _, child in ipairs(teleportListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Remove() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local plrBtn = Instance.new("TextButton")
            plrBtn.Size = UDim2.new(1, -8, 0, 22)
            plrBtn.BackgroundColor3 = (teleportTarget == plr) and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
            plrBtn.Text = plr.Name
            plrBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            plrBtn.Font = Enum.Font.Gotham
            plrBtn.TextSize = 12
            plrBtn.ZIndex = 20
            plrBtn.Parent = teleportListFrame
            local plrCorner = Instance.new("UICorner")
            plrCorner.CornerRadius = UDim.new(0, 4)
            plrCorner.Parent = plrBtn
            plrBtn.MouseButton1Click:Connect(function()
                teleportTarget = plr
                teleportDropdownBtn.Text = plr.Name
                teleportListFrame.Visible = false
                updateTeleportList()
            end)
        end
    end
    task.spawn(function() task.wait(); fixScrolling(teleportListFrame) end)
end

teleportDropdownBtn.MouseButton1Click:Connect(function()
    teleportListFrame.Visible = not teleportListFrame.Visible
    if teleportListFrame.Visible then updateTeleportList() end
end)

local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(0, 160, 0, 28)
teleportBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
teleportBtn.Text = "Телепортироваться"
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportBtn.Font = Enum.Font.Gotham
teleportBtn.TextSize = 12
teleportBtn.Parent = playerPage
teleportBtn.ZIndex = 10
local teleportBtnCorner = Instance.new("UICorner")
teleportBtnCorner.CornerRadius = UDim.new(0, 4)
teleportBtnCorner.Parent = teleportBtn

teleportBtn.MouseButton1Click:Connect(function()
    if not teleportTarget then return end
    local targetChar = teleportTarget.Character
    if targetChar then
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            updateCharacter()
            if rootPart then rootPart.CFrame = CFrame.new(targetRoot.Position) end
        end
    end
end)

-- Fling
local flingBtn = Instance.new("TextButton")
flingBtn.Size = UDim2.new(0, 160, 0, 30)
flingBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
flingBtn.Text = "Fling: Выкл"
flingBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
flingBtn.Font = Enum.Font.GothamBold
flingBtn.TextSize = 13
flingBtn.Parent = playerPage
flingBtn.ZIndex = 10
local flingCorner = Instance.new("UICorner")
flingCorner.CornerRadius = UDim.new(0, 6)
flingCorner.Parent = flingBtn

flingBtn.MouseButton1Click:Connect(function()
    flingEnabled = not flingEnabled
    if flingEnabled then
        if character then setupFling(character) end
        flingBtn.Text = "Fling: Вкл"
        flingBtn.BackgroundColor3 = Color3.fromRGB(123, 97, 255)
    else
        disableFling()
        flingBtn.Text = "Fling: Выкл"
        flingBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
    end
end)

-- Слайдеры
local speedPanel = Instance.new("Frame")
speedPanel.Size = UDim2.new(1, -16, 0, 150)
speedPanel.BackgroundTransparency = 1
speedPanel.Parent = playerPage
speedPanel.ZIndex = 1
local speedLayout = Instance.new("UIListLayout")
speedLayout.FillDirection = Enum.FillDirection.Vertical
speedLayout.Padding = UDim.new(0, 6)
speedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
speedLayout.Parent = speedPanel

local function createSlider(parent, labelText, defaultVal, minVal, maxVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.Parent = parent
    row.ZIndex = 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 120, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.Parent = row
    lbl.ZIndex = 1
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 70, 1, 0)
    box.Position = UDim2.new(0, 124, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
    box.Text = tostring(defaultVal)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.PlaceholderText = "0"
    box.ClearTextOnFocus = false
    box.Parent = row
    box.ZIndex = 1
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box
    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0, 55, 1, 0)
    applyBtn.Position = UDim2.new(1, -60, 0, 0)
    applyBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
    applyBtn.Text = "Прим."
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Font = Enum.Font.Gotham
    applyBtn.TextSize = 11
    applyBtn.Parent = row
    applyBtn.ZIndex = 10
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = applyBtn
    applyBtn.MouseButton1Click:Connect(function()
        local val = tonumber(box.Text)
        if val then
            val = math.clamp(val, minVal, maxVal)
            box.Text = tostring(val)
            callback(val)
        else
            box.Text = tostring(defaultVal)
        end
    end)
    return row
end

createSlider(speedPanel, "Скорость ходьбы:", 16, 0, 99999, function(v) savedWalkSpeed = v; if humanoid then humanoid.WalkSpeed = v end end)
createSlider(speedPanel, "Сила прыжка:", 50, 0, 99999, function(v) savedJumpPower = v; if humanoid then humanoid.JumpPower = v end end)
createSlider(speedPanel, "Скорость полёта:", 50, 0, 99999, function(v) flySpeed = v end)

task.spawn(function() fixScrolling(playerPage) end)

-- Fly управление
RunService.RenderStepped:Connect(function()
    if not flying then return end
    updateCharacter()
    if not rootPart or not bodyVelocity or not bodyGyro then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local moveDir = Vector3.new(0, 0, 0)
    if humanoid then
        local joy = humanoid.MoveDirection
        if joy.Magnitude > 0.1 then
            local forward = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            local fwd = joy:Dot(forward)
            local rgt = joy:Dot(right)
            moveDir = (forward * fwd + right * rgt)
            if moveDir.Magnitude > 0.1 then moveDir = moveDir.Unit else moveDir = Vector3.new(0, 0, 0) end
        end
    end
    bodyVelocity.Velocity = moveDir * flySpeed
    if moveDir.Magnitude > 0.1 then
        bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDir)
    end
end)

-- ================== ВКЛАДКА ВИЗУАЛЫ ==================
local visualsPage = createScrollPage()
pages.Visuals = visualsPage

local visualsLabel = Instance.new("TextLabel")
visualsLabel.Size = UDim2.new(1, -16, 0, 24)
visualsLabel.BackgroundTransparency = 1
visualsLabel.Text = "Визуалы"
visualsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
visualsLabel.TextXAlignment = Enum.TextXAlignment.Left
visualsLabel.Font = Enum.Font.GothamBold
visualsLabel.TextSize = 15
visualsLabel.Parent = visualsPage
visualsLabel.ZIndex = 1

-- Ники
local namesToggle = Instance.new("TextButton")
namesToggle.Size = UDim2.new(0, 160, 0, 30)
namesToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
namesToggle.Text = "Ники: Выкл"
namesToggle.TextColor3 = Color3.fromRGB(220, 220, 220)
namesToggle.Font = Enum.Font.Gotham
namesToggle.TextSize = 13
namesToggle.Parent = visualsPage
namesToggle.ZIndex = 10
local namesCorner = Instance.new("UICorner")
namesCorner.CornerRadius = UDim.new(0, 6)
namesCorner.Parent = namesToggle

namesToggle.MouseButton1Click:Connect(function()
    espEnabledNames = not espEnabledNames
    namesToggle.Text = "Ники: " .. (espEnabledNames and "Вкл" or "Выкл")
    namesToggle.BackgroundColor3 = espEnabledNames and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
    refreshESP()
end)

-- Хитбоксы
local boxesToggle = Instance.new("TextButton")
boxesToggle.Size = UDim2.new(0, 160, 0, 30)
boxesToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
boxesToggle.Text = "Хитбоксы: Выкл"
boxesToggle.TextColor3 = Color3.fromRGB(220, 220, 220)
boxesToggle.Font = Enum.Font.Gotham
boxesToggle.TextSize = 13
boxesToggle.Parent = visualsPage
boxesToggle.ZIndex = 10
local boxesCorner = Instance.new("UICorner")
boxesCorner.CornerRadius = UDim.new(0, 6)
boxesCorner.Parent = boxesToggle

boxesToggle.MouseButton1Click:Connect(function()
    espEnabledBoxes = not espEnabledBoxes
    boxesToggle.Text = "Хитбоксы: " .. (espEnabledBoxes and "Вкл" or "Выкл")
    boxesToggle.BackgroundColor3 = espEnabledBoxes and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
    refreshESP()
end)

-- Аимбот
local aimbotBtn = Instance.new("TextButton")
aimbotBtn.Size = UDim2.new(0, 160, 0, 30)
aimbotBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
aimbotBtn.Text = "Аимбот: Выкл"
aimbotBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
aimbotBtn.Font = Enum.Font.Gotham
aimbotBtn.TextSize = 13
aimbotBtn.Parent = visualsPage
aimbotBtn.ZIndex = 10
local aimbotCorner = Instance.new("UICorner")
aimbotCorner.CornerRadius = UDim.new(0, 6)
aimbotCorner.Parent = aimbotBtn

aimbotBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotBtn.Text = "Аимбот: " .. (aimbotEnabled and "Вкл" or "Выкл")
    aimbotBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
end)

-- Выбор цели
local aimTargetLabel = Instance.new("TextLabel")
aimTargetLabel.Size = UDim2.new(1, -16, 0, 18)
aimTargetLabel.BackgroundTransparency = 1
aimTargetLabel.Text = "Цель аимбота:"
aimTargetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
aimTargetLabel.TextXAlignment = Enum.TextXAlignment.Left
aimTargetLabel.Font = Enum.Font.Gotham
aimTargetLabel.TextSize = 12
aimTargetLabel.Parent = visualsPage
aimTargetLabel.ZIndex = 1

local targetDropdownBtn = Instance.new("TextButton")
targetDropdownBtn.Size = UDim2.new(0, 160, 0, 28)
targetDropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
targetDropdownBtn.Text = "Все"
targetDropdownBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
targetDropdownBtn.Font = Enum.Font.Gotham
targetDropdownBtn.TextSize = 12
targetDropdownBtn.Parent = visualsPage
targetDropdownBtn.ZIndex = 10
local targetDropdownCorner = Instance.new("UICorner")
targetDropdownCorner.CornerRadius = UDim.new(0, 4)
targetDropdownCorner.Parent = targetDropdownBtn

local targetListFrame = Instance.new("ScrollingFrame")
targetListFrame.Size = UDim2.new(0, 160, 0, 80)
targetListFrame.Position = UDim2.new(0, 8, 0, 180)
targetListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
targetListFrame.BorderSizePixel = 0
targetListFrame.Visible = false
targetListFrame.ZIndex = 20
targetListFrame.ScrollBarThickness = 3
targetListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
targetListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
targetListFrame.ElasticBehavior = Enum.ElasticBehavior.Never
targetListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
targetListFrame.ClipsDescendants = true
targetListFrame.Parent = visualsPage
local targetListLayout = Instance.new("UIListLayout")
targetListLayout.Padding = UDim.new(0, 2)
targetListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
targetListLayout.SortOrder = Enum.SortOrder.LayoutOrder
targetListLayout.Parent = targetListFrame

local function updateTargetList()
    for _, child in ipairs(targetListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Remove() end
    end
    local allBtn = Instance.new("TextButton")
    allBtn.Size = UDim2.new(1, -8, 0, 22)
    allBtn.BackgroundColor3 = (aimTargetPlayer == nil) and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
    allBtn.Text = "Все"
    allBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    allBtn.Font = Enum.Font.Gotham
    allBtn.TextSize = 12
    allBtn.ZIndex = 20
    allBtn.Parent = targetListFrame
    local allCorner = Instance.new("UICorner")
    allCorner.CornerRadius = UDim.new(0, 4)
    allCorner.Parent = allBtn
    allBtn.MouseButton1Click:Connect(function()
        aimTargetPlayer = nil
        targetDropdownBtn.Text = "Все"
        targetListFrame.Visible = false
        updateTargetList()
    end)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local plrBtn = Instance.new("TextButton")
            plrBtn.Size = UDim2.new(1, -8, 0, 22)
            plrBtn.BackgroundColor3 = (aimTargetPlayer == plr) and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
            plrBtn.Text = plr.Name
            plrBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            plrBtn.Font = Enum.Font.Gotham
            plrBtn.TextSize = 12
            plrBtn.ZIndex = 20
            plrBtn.Parent = targetListFrame
            local plrCorner = Instance.new("UICorner")
            plrCorner.CornerRadius = UDim.new(0, 4)
            plrCorner.Parent = plrBtn
            plrBtn.MouseButton1Click:Connect(function()
                aimTargetPlayer = plr
                targetDropdownBtn.Text = plr.Name
                targetListFrame.Visible = false
                updateTargetList()
            end)
        end
    end
    task.spawn(function() task.wait(); fixScrolling(targetListFrame) end)
end

targetDropdownBtn.MouseButton1Click:Connect(function()
    targetListFrame.Visible = not targetListFrame.Visible
    if targetListFrame.Visible then updateTargetList() end
end)

task.spawn(function() while true do task.wait(1); if targetListFrame.Visible then updateTargetList() end end end)
Players.PlayerAdded:Connect(function() if targetListFrame.Visible then updateTargetList() end end)
Players.PlayerRemoving:Connect(function(p)
    if aimTargetPlayer == p then aimTargetPlayer = nil; targetDropdownBtn.Text = "Все" end
    if targetListFrame.Visible then updateTargetList() end
end)
updateTargetList()

-- FOV
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(1, -16, 0, 18)
fovLabel.BackgroundTransparency = 1
fovLabel.Text = "FOV радиус:"
fovLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
fovLabel.TextXAlignment = Enum.TextXAlignment.Left
fovLabel.Font = Enum.Font.Gotham
fovLabel.TextSize = 12
fovLabel.Parent = visualsPage
fovLabel.ZIndex = 1

local fovSliderRow = Instance.new("Frame")
fovSliderRow.Size = UDim2.new(1, -16, 0, 28)
fovSliderRow.BackgroundTransparency = 1
fovSliderRow.Parent = visualsPage
fovSliderRow.ZIndex = 1

local fovBox = Instance.new("TextBox")
fovBox.Size = UDim2.new(0, 70, 1, 0)
fovBox.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
fovBox.Text = "100"
fovBox.TextColor3 = Color3.fromRGB(255, 255, 255)
fovBox.Font = Enum.Font.Gotham
fovBox.TextSize = 12
fovBox.Parent = fovSliderRow
fovBox.ZIndex = 1
local fovApply = Instance.new("TextButton")
fovApply.Size = UDim2.new(0, 50, 1, 0)
fovApply.Position = UDim2.new(0, 74, 0, 0)
fovApply.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
fovApply.Text = "OK"
fovApply.TextColor3 = Color3.fromRGB(255, 255, 255)
fovApply.Font = Enum.Font.Gotham
fovApply.TextSize = 12
fovApply.Parent = fovSliderRow
fovApply.ZIndex = 10
fovApply.MouseButton1Click:Connect(function()
    local val = tonumber(fovBox.Text)
    if val then val = math.clamp(val, 0, 99999); fovBox.Text = tostring(val); fovRadius = val; if fovCircle then fovCircle.Radius = val end end
end)

-- HUE
local hueLabel = Instance.new("TextLabel")
hueLabel.Size = UDim2.new(1, -16, 0, 18)
hueLabel.BackgroundTransparency = 1
hueLabel.Text = "Оттенок меню (0-360):"
hueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
hueLabel.TextXAlignment = Enum.TextXAlignment.Left
hueLabel.Font = Enum.Font.Gotham
hueLabel.TextSize = 12
hueLabel.Parent = visualsPage
hueLabel.ZIndex = 1

local hueSliderFrame = Instance.new("Frame")
hueSliderFrame.Size = UDim2.new(0, 220, 0, 28)
hueSliderFrame.BackgroundTransparency = 1
hueSliderFrame.Active = true
hueSliderFrame.Parent = visualsPage
hueSliderFrame.ZIndex = 1

local hueTrack = Instance.new("Frame")
hueTrack.Size = UDim2.new(0, 160, 0, 6)
hueTrack.Position = UDim2.new(0, 0, 0.5, -3)
hueTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
hueTrack.BorderSizePixel = 0
hueTrack.Active = true
hueTrack.Parent = hueSliderFrame
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 3)
trackCorner.Parent = hueTrack

local hueKnob = Instance.new("TextButton")
hueKnob.Size = UDim2.new(0, 18, 0, 18)
hueKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
hueKnob.Text = ""
hueKnob.AutoButtonColor = false
hueKnob.Active = true
hueKnob.Parent = hueSliderFrame
hueKnob.ZIndex = 10
local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = hueKnob

local hueValueLabel = Instance.new("TextLabel")
hueValueLabel.Size = UDim2.new(0, 40, 1, 0)
hueValueLabel.Position = UDim2.new(0, 170, 0, 0)
hueValueLabel.BackgroundTransparency = 1
hueValueLabel.Text = "0"
hueValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hueValueLabel.Font = Enum.Font.Gotham
hueValueLabel.TextSize = 12
hueValueLabel.TextXAlignment = Enum.TextXAlignment.Left
hueValueLabel.Parent = hueSliderFrame
hueValueLabel.ZIndex = 1

local function updateHueKnobPosition()
    local trackWidth = 160
    local knobX = math.clamp((currentHue / 360) * trackWidth, 0, trackWidth)
    hueKnob.Position = UDim2.new(0, knobX - hueKnob.Size.X.Offset/2, 0.5, -hueKnob.Size.Y.Offset/2)
    hueValueLabel.Text = tostring(currentHue)
end

local hueDragging = false
hueKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        hueDragging = true
        local pos = UserInputService:GetMouseLocation()
        local trackAbsPos = hueTrack.AbsolutePosition
        local trackSize = hueTrack.AbsoluteSize
        local relX = math.clamp(pos.X - trackAbsPos.X, 0, trackSize.X)
        currentHue = math.floor((relX / trackSize.X) * 360)
        updateHueKnobPosition()
        applyHue(currentHue)
    end
end)
hueKnob.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        hueDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not hueDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = UserInputService:GetMouseLocation()
        if pos then
            local trackAbsPos = hueTrack.AbsolutePosition
            local trackSize = hueTrack.AbsoluteSize
            local relX = math.clamp(pos.X - trackAbsPos.X, 0, trackSize.X)
            currentHue = math.floor((relX / trackSize.X) * 360)
            updateHueKnobPosition()
            applyHue(currentHue)
        end
    elseif input.UserInputType == Enum.UserInputType.Touch then
        local pos = input.Position
        local trackAbsPos = hueTrack.AbsolutePosition
        local trackSize = hueTrack.AbsoluteSize
        local relX = math.clamp(pos.X - trackAbsPos.X, 0, trackSize.X)
        currentHue = math.floor((relX / trackSize.X) * 360)
        updateHueKnobPosition()
        applyHue(currentHue)
    end
end)
updateHueKnobPosition()

-- ESP/AIM обновление
RunService.RenderStepped:Connect(function()
    if espEnabledNames or espEnabledBoxes then updateESP() end
    updateAimbot()
end)

task.spawn(function() fixScrolling(visualsPage) end)

-- ================== ВКЛАДКА MM2 ==================
local mm2Page = createScrollPage()
pages.MM2 = mm2Page

local mm2Label = Instance.new("TextLabel")
mm2Label.Size = UDim2.new(1, -16, 0, 24)
mm2Label.BackgroundTransparency = 1
mm2Label.Text = "Murder Mystery 2"
mm2Label.TextColor3 = Color3.fromRGB(230, 230, 230)
mm2Label.TextXAlignment = Enum.TextXAlignment.Left
mm2Label.Font = Enum.Font.GothamBold
mm2Label.TextSize = 15
mm2Label.Parent = mm2Page
mm2Label.ZIndex = 1

-- Кнопка ESP
local mm2ESPBtn = Instance.new("TextButton")
mm2ESPBtn.Size = UDim2.new(0, 160, 0, 30)
mm2ESPBtn.BackgroundColor3 = Color3.fromRGB(123, 97, 255)
mm2ESPBtn.Text = "ESP: Вкл"
mm2ESPBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
mm2ESPBtn.Font = Enum.Font.GothamBold
mm2ESPBtn.TextSize = 13
mm2ESPBtn.Parent = mm2Page
mm2ESPBtn.ZIndex = 10
local mm2ESPCorner = Instance.new("UICorner")
mm2ESPCorner.CornerRadius = UDim.new(0, 6)
mm2ESPCorner.Parent = mm2ESPBtn

mm2ESPBtn.MouseButton1Click:Connect(function()
    MM2.ESPEnabled = not MM2.ESPEnabled
    mm2ESPBtn.Text = "ESP: " .. (MM2.ESPEnabled and "Вкл" or "Выкл")
    mm2ESPBtn.BackgroundColor3 = MM2.ESPEnabled and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
    if not MM2.ESPEnabled then
        for _, data in pairs(mm2EspStorage) do data.Gui:Destroy() end
        mm2EspStorage = {}
    end
end)

-- Кнопка аимбота
local mm2AimbotBtn = Instance.new("TextButton")
mm2AimbotBtn.Size = UDim2.new(0, 160, 0, 30)
mm2AimbotBtn.BackgroundColor3 = Color3.fromRGB(123, 97, 255)
mm2AimbotBtn.Text = "Аимбот: Вкл"
mm2AimbotBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
mm2AimbotBtn.Font = Enum.Font.GothamBold
mm2AimbotBtn.TextSize = 13
mm2AimbotBtn.Parent = mm2Page
mm2AimbotBtn.ZIndex = 10
local mm2AimbotCorner = Instance.new("UICorner")
mm2AimbotCorner.CornerRadius = UDim.new(0, 6)
mm2AimbotCorner.Parent = mm2AimbotBtn

mm2AimbotBtn.MouseButton1Click:Connect(function()
    MM2.AimbotEnabled = not MM2.AimbotEnabled
    mm2AimbotBtn.Text = "Аимбот: " .. (MM2.AimbotEnabled and "Вкл" or "Выкл")
    mm2AimbotBtn.BackgroundColor3 = MM2.AimbotEnabled and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
end)

-- Плавающие кнопки MM2
local floatGui = Instance.new("ScreenGui")
floatGui.Name = "MM2_FloatButtons"
floatGui.ResetOnSpawn = false
floatGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
floatGui.ZIndex = 10
floatGui.Parent = playerGui

local shootBtn = Instance.new("TextButton")
shootBtn.Size = UDim2.new(0, 70, 0, 70)
shootBtn.Position = UDim2.new(0.8, 0, 0.7, 0)
shootBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
shootBtn.Text = "SHOOT"
shootBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shootBtn.Font = Enum.Font.GothamBold
shootBtn.TextSize = 16
shootBtn.Visible = false
shootBtn.ZIndex = 20
shootBtn.Parent = floatGui
Instance.new("UICorner", shootBtn).CornerRadius = UDim.new(1, 0)

local knifeBtn = Instance.new("TextButton")
knifeBtn.Size = UDim2.new(0, 70, 0, 70)
knifeBtn.Position = UDim2.new(0.2, 0, 0.7, 0)
knifeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
knifeBtn.Text = "KNIFE"
knifeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
knifeBtn.Font = Enum.Font.GothamBold
knifeBtn.TextSize = 16
knifeBtn.Visible = false
knifeBtn.ZIndex = 20
knifeBtn.Parent = floatGui
Instance.new("UICorner", knifeBtn).CornerRadius = UDim.new(1, 0)

local function makeDraggable(btn)
    local draggingBtn = false
    local dragStartPosBtn, btnStartPos
    btn.InputBegan:Connect(function(input)
        if MM2.FreezeButtons then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingBtn = true
            dragStartPosBtn = UserInputService:GetMouseLocation()
            btnStartPos = btn.AbsolutePosition
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingBtn = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not draggingBtn then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = UserInputService:GetMouseLocation() - dragStartPosBtn
            local newPos = btnStartPos + delta
            local screenSize = workspace.CurrentCamera.ViewportSize
            local btnSize = btn.AbsoluteSize
            newPos = Vector2.new(
                math.clamp(newPos.X, 0, screenSize.X - btnSize.X),
                math.clamp(newPos.Y, 0, screenSize.Y - btnSize.Y)
            )
            btn.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
        end
    end)
end

makeDraggable(shootBtn)
makeDraggable(knifeBtn)

-- Функции выстрела/броска
local function shootWithAim()
    if not player.Character then return end
    local gun = player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun")
    if not gun then return end
    if player.Character:FindFirstChild("Gun") == nil and player.Backpack:FindFirstChild("Gun") then
        player.Character.Humanoid:EquipTool(player.Backpack["Gun"])
        task.wait(0.1)
    end
    local enemy = getClosestEnemyMM2()
    if enemy then
        smoothAimMM2(enemy)
        task.wait(0.05)
    end
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

shootBtn.MouseButton1Click:Connect(shootWithAim)

local function throwKnife()
    if not player.Character then return end
    local knife = player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife")
    if not knife then return end
    if player.Character:FindFirstChild("Knife") == nil and player.Backpack:FindFirstChild("Knife") then
        player.Character.Humanoid:EquipTool(player.Backpack["Knife"])
        task.wait(0.1)
    end
    local enemy = getClosestEnemyMM2()
    if enemy then
        smoothAimMM2(enemy)
        task.wait(0.05)
    end
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

knifeBtn.MouseButton1Click:Connect(throwKnife)

-- Тогглы кнопок
local shootToggleBtn = Instance.new("TextButton")
shootToggleBtn.Size = UDim2.new(0, 160, 0, 30)
shootToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
shootToggleBtn.Text = "Выстрел (Шериф): Выкл"
shootToggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
shootToggleBtn.Font = Enum.Font.GothamBold
shootToggleBtn.TextSize = 13
shootToggleBtn.Parent = mm2Page
shootToggleBtn.ZIndex = 10
local shootToggleCorner = Instance.new("UICorner")
shootToggleCorner.CornerRadius = UDim.new(0, 6)
shootToggleCorner.Parent = shootToggleBtn

shootToggleBtn.MouseButton1Click:Connect(function()
    MM2.ShootButtonEnabled = not MM2.ShootButtonEnabled
    shootToggleBtn.Text = "Выстрел (Шериф): " .. (MM2.ShootButtonEnabled and "Вкл" or "Выкл")
    shootToggleBtn.BackgroundColor3 = MM2.ShootButtonEnabled and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
    shootBtn.Visible = MM2.ShootButtonEnabled
end)

local knifeToggleBtn = Instance.new("TextButton")
knifeToggleBtn.Size = UDim2.new(0, 160, 0, 30)
knifeToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
knifeToggleBtn.Text = "Бросок ножа: Выкл"
knifeToggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
knifeToggleBtn.Font = Enum.Font.GothamBold
knifeToggleBtn.TextSize = 13
knifeToggleBtn.Parent = mm2Page
knifeToggleBtn.ZIndex = 10
local knifeToggleCorner = Instance.new("UICorner")
knifeToggleCorner.CornerRadius = UDim.new(0, 6)
knifeToggleCorner.Parent = knifeToggleBtn

knifeToggleBtn.MouseButton1Click:Connect(function()
    MM2.KnifeThrowEnabled = not MM2.KnifeThrowEnabled
    knifeToggleBtn.Text = "Бросок ножа: " .. (MM2.KnifeThrowEnabled and "Вкл" or "Выкл")
    knifeToggleBtn.BackgroundColor3 = MM2.KnifeThrowEnabled and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
    knifeBtn.Visible = MM2.KnifeThrowEnabled
end)

-- Авто-подбор
local autoPickupBtn = Instance.new("TextButton")
autoPickupBtn.Size = UDim2.new(0, 160, 0, 30)
autoPickupBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
autoPickupBtn.Text = "Авто-подбор пистолета: Выкл"
autoPickupBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
autoPickupBtn.Font = Enum.Font.GothamBold
autoPickupBtn.TextSize = 13
autoPickupBtn.Parent = mm2Page
autoPickupBtn.ZIndex = 10
local autoPickupCorner = Instance.new("UICorner")
autoPickupCorner.CornerRadius = UDim.new(0, 6)
autoPickupCorner.Parent = autoPickupBtn

autoPickupBtn.MouseButton1Click:Connect(function()
    MM2.AutoPickupGun = not MM2.AutoPickupGun
    autoPickupBtn.Text = "Авто-подбор пистолета: " .. (MM2.AutoPickupGun and "Вкл" or "Выкл")
    autoPickupBtn.BackgroundColor3 = MM2.AutoPickupGun and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
end)

-- Заморозка
local freezeButtonsToggle = Instance.new("TextButton")
freezeButtonsToggle.Size = UDim2.new(0, 160, 0, 30)
freezeButtonsToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
freezeButtonsToggle.Text = "Заморозить кнопки: Выкл"
freezeButtonsToggle.TextColor3 = Color3.fromRGB(220, 220, 220)
freezeButtonsToggle.Font = Enum.Font.GothamBold
freezeButtonsToggle.TextSize = 13
freezeButtonsToggle.Parent = mm2Page
freezeButtonsToggle.ZIndex = 10
local freezeButtonsCorner = Instance.new("UICorner")
freezeButtonsCorner.CornerRadius = UDim.new(0, 6)
freezeButtonsCorner.Parent = freezeButtonsToggle

freezeButtonsToggle.MouseButton1Click:Connect(function()
    MM2.FreezeButtons = not MM2.FreezeButtons
    freezeButtonsToggle.Text = "Заморозить кнопки: " .. (MM2.FreezeButtons and "Вкл" or "Выкл")
    freezeButtonsToggle.BackgroundColor3 = MM2.FreezeButtons and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
end)

task.spawn(function() fixScrolling(mm2Page) end)

-- Цикл авто-подбора
local function autoPickupGunLoop()
    while task.wait(0.3) do
        if not MM2.AutoPickupGun then continue end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then continue end
        local root = player.Character.HumanoidRootPart
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj.Name == "Gun" and obj.Parent ~= player.Character and obj.Parent ~= player.Backpack then
                if (root.Position - obj.Position).Magnitude < 15 then
                    obj.Parent = player.Backpack
                    break
                end
            end
        end
    end
end
task.spawn(autoPickupGunLoop)

-- MM2 ESP/AIM рендер степ
RunService.RenderStepped:Connect(function()
    if MM2.ESPEnabled then
        updateESPMM2()
    else
        if next(mm2EspStorage) then
            for _, data in pairs(mm2EspStorage) do data.Gui:Destroy() end
            mm2EspStorage = {}
        end
    end
    
    if not MM2.AimbotEnabled then return end
    if not player.Character then return end
    local enemy = getClosestEnemyMM2()
    if enemy then
        smoothAimMM2(enemy)
        local now = tick()
        if now - lastAttackMM2 >= 0.6 then
            autoAttackMM2(enemy)
            lastAttackMM2 = now
        end
    end
end)

-- ================== ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК ==================
local activeColor = Color3.fromRGB(123, 97, 255)
local inactiveColor = Color3.fromRGB(40, 40, 46)

local function selectTab(tabName)
    for name, page in pairs(pages) do page.Visible = (name == tabName) end
    local buttons = {
        Info = infoTab, Settings = settingsTab, Animations = animsTab,
        Player = playerTab, Visuals = visualsTab, MM2 = mm2Tab
    }
    for name, btn in pairs(buttons) do
        btn.BackgroundColor3 = (name == tabName) and activeColor or inactiveColor
    end
end

-- Фикс вкладок
local function fixTabs()
    infoTab.ZIndex = 30
    settingsTab.ZIndex = 30
    animsTab.ZIndex = 30
    playerTab.ZIndex = 30
    visualsTab.ZIndex = 30
    mm2Tab.ZIndex = 30
    tabBar.ZIndex = 15
    contentFrame.ZIndex = 1
    
    infoTab.MouseButton1Click:Connect(function() selectTab("Info") end)
    settingsTab.MouseButton1Click:Connect(function() selectTab("Settings") end)
    animsTab.MouseButton1Click:Connect(function() selectTab("Animations") end)
    playerTab.MouseButton1Click:Connect(function() selectTab("Player") end)
    visualsTab.MouseButton1Click:Connect(function() selectTab("Visuals") end)
    mm2Tab.MouseButton1Click:Connect(function() selectTab("MM2") end)
    
    selectTab("Info")
end
task.spawn(fixTabs)

-- ================== ЕДИНОЕ СОБЫТИЕ ПЕРСОНАЖА ==================
local function onCharacterAdded(newChar)
    updateCharacter()
    task.wait(0.5)
    if humanoid then
        humanoid.WalkSpeed = savedWalkSpeed
        humanoid.JumpPower = savedJumpPower
    end
    if noclipEnabled then enableNoClip() end
    if invisEnabled then applyInvisibility(true) end
    if flingEnabled then setupFling(character) end
    if flying then 
        stopFly() 
        flyBtn.Text = "Fly: Выкл"
        flyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
    end
    if shootBtn then shootBtn.Visible = MM2.ShootButtonEnabled end
    if knifeBtn then knifeBtn.Visible = MM2.KnifeThrowEnabled end
    if MM2.ESPEnabled then
        for _, data in pairs(mm2EspStorage) do data.Gui:Destroy() end
        mm2EspStorage = {}
    end
    refreshESP()
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Игроки
Players.PlayerAdded:Connect(function(target)
    if (espEnabledNames or espEnabledBoxes) and DrawingAvailable then createESPForPlayer(target) end
end)
Players.PlayerRemoving:Connect(function(target) 
    clearESP(target) 
    if mm2EspStorage[target] then
        mm2EspStorage[target].Gui:Destroy()
        mm2EspStorage[target] = nil
    end
end)

-- Инициализация при старте
updateCharacter()
if humanoid then
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
end
if (espEnabledNames or espEnabledBoxes) and DrawingAvailable then refreshESP() end

print("RAHMAT Menu v7.3 + MM2 — МЕНЮ ЖИВОЕ И РАБОТАЕТ!")
