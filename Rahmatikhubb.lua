--[[
    RAHMAT Menu v6.1 — FOV как кольцо, Hue-слайдер, фикс скролла
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Кэширование
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

player.CharacterAdded:Connect(function()
    updateCharacter()
    task.wait(0.5)
    if humanoid then
        humanoid.WalkSpeed = savedWalkSpeed
        humanoid.JumpPower = savedJumpPower
    end
    if noclipEnabled then
        enableNoClip()
    end
end)

updateCharacter()
if humanoid then
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
end

-- Сохраняемые значения
local savedWalkSpeed = 16
local savedJumpPower = 50
local flySpeed = 50
local flying = false
local bodyVelocity, bodyGyro

------------------------------------------------------------
-- GUI
------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RAHMAT_Menu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Главное меню
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 520, 0, 440)
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -220)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainFrame

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -44, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "RAHMAT"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.Parent = titleBar

-- Кнопка сворачивания
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.Position = UDim2.new(1, -38, 0, 6)
closeButton.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Плавающая кнопка открытия
local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 50, 0, 50)
openButton.Position = UDim2.new(1, -70, 0.5, -25)
openButton.BackgroundColor3 = Color3.fromRGB(80, 120, 220)
openButton.Text = "R"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 22
openButton.Visible = false
openButton.Parent = screenGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(1, 0)
openCorner.Parent = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(255, 255, 255)
openStroke.Thickness = 2
openStroke.Transparency = 0.3
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
        if mainFrame.Visible then
            closeMenu()
        else
            openMenu()
        end
    end
end)

------------------------------------------------------------
-- Панель вкладок
------------------------------------------------------------
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 36)
tabBar.Position = UDim2.new(0, 10, 0, 54)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabBar

local function createTabButton(name, text)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 90, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = tabBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    return btn
end

local infoTab = createTabButton("InfoTab", "Инфо")
local settingsTab = createTabButton("SettingsTab", "Настройки")
local animsTab = createTabButton("AnimationsTab", "Анимки")
local playerTab = createTabButton("PlayerTab", "Игрок")
local visualsTab = createTabButton("VisualsTab", "Визуалы")

------------------------------------------------------------
-- Контент
------------------------------------------------------------
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -104)
contentFrame.Position = UDim2.new(0, 10, 0, 98)
contentFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 10)
contentCorner.Parent = contentFrame

local pages = {}

-- Функция создания ScrollingFrame (теперь с фиксом скролла)
local function createScrollPage()
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 4
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    sf.ElasticBehavior = Enum.ElasticBehavior.Never  -- фикс пружины
    sf.Parent = contentFrame
    sf.Visible = false

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = sf

    return sf
end

-- Инфо
local infoPage = createScrollPage()
infoPage.Visible = true
pages.Info = infoPage

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 200)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Добро пожаловать в RAHMAT!\n\nСвернуть: X\nОткрыть: R (Android) или RightShift"
infoLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 15
infoLabel.Parent = infoPage

-- Настройки
local settingsPage = createScrollPage()
settingsPage.Visible = false
pages.Settings = settingsPage

local settingsLabel = Instance.new("TextLabel")
settingsLabel.Size = UDim2.new(1, -20, 0, 30)
settingsLabel.BackgroundTransparency = 1
settingsLabel.Text = "Настройки"
settingsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
settingsLabel.Font = Enum.Font.GothamBold
settingsLabel.TextSize = 18
settingsLabel.Parent = settingsPage

local exampleToggle = Instance.new("TextButton")
exampleToggle.Size = UDim2.new(0, 200, 0, 34)
exampleToggle.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
exampleToggle.Text = "Опция: Выкл"
exampleToggle.TextColor3 = Color3.fromRGB(230, 230, 230)
exampleToggle.Font = Enum.Font.Gotham
exampleToggle.TextSize = 14
exampleToggle.Parent = settingsPage

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = exampleToggle

local toggleState = false
exampleToggle.MouseButton1Click:Connect(function()
    toggleState = not toggleState
    exampleToggle.Text = "Опция: " .. (toggleState and "Вкл" or "Выкл")
end)

-- Анимации
local animsPage = createScrollPage()
animsPage.Visible = false
pages.Animations = animsPage

local animsLabel = Instance.new("TextLabel")
animsLabel.Size = UDim2.new(1, -20, 0, 30)
animsLabel.BackgroundTransparency = 1
animsLabel.Text = "Анимации"
animsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
animsLabel.TextXAlignment = Enum.TextXAlignment.Left
animsLabel.Font = Enum.Font.GothamBold
animsLabel.TextSize = 18
animsLabel.Parent = animsPage

local animContainer = Instance.new("Frame")
animContainer.Size = UDim2.new(1, -20, 0, 180)
animContainer.BackgroundTransparency = 1
animContainer.Parent = animsPage

local animLayout = Instance.new("UIListLayout")
animLayout.FillDirection = Enum.FillDirection.Horizontal
animLayout.Wraps = true
animLayout.Padding = UDim.new(0, 8)
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
    if currentTrack then
        currentTrack:Stop()
        currentTrack = nil
    end
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
    btn.Size = UDim2.new(0, 100, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    btn.Text = animData.name
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        playAnimationById(animData.id)
        for _, child in parent:GetChildren() do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
    end)

    return btn
end

for _, anim in ipairs(animList) do
    createAnimButton(animContainer, anim)
end

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 100, 0, 36)
stopBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
stopBtn.Text = "Стоп"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 14
stopBtn.Parent = animContainer

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 8)
stopCorner.Parent = stopBtn

stopBtn.MouseButton1Click:Connect(function()
    stopAllAnimations()
    for _, child in animContainer:GetChildren() do
        if child:IsA("TextButton") and child ~= stopBtn then
            child.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        end
    end
end)

-- Ввод ID анимации
local idFrame = Instance.new("Frame")
idFrame.Size = UDim2.new(1, -20, 0, 36)
idFrame.BackgroundTransparency = 1
idFrame.Parent = animsPage

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(0, 100, 1, 0)
idLabel.BackgroundTransparency = 1
idLabel.Text = "ID анимации:"
idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
idLabel.TextXAlignment = Enum.TextXAlignment.Left
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 14
idLabel.Parent = idFrame

local idBox = Instance.new("TextBox")
idBox.Size = UDim2.new(0, 150, 1, 0)
idBox.Position = UDim2.new(0, 105, 0, 0)
idBox.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
idBox.Text = ""
idBox.TextColor3 = Color3.fromRGB(255, 255, 255)
idBox.Font = Enum.Font.Gotham
idBox.TextSize = 14
idBox.PlaceholderText = "Введите ID"
idBox.ClearTextOnFocus = false
idBox.Parent = idFrame

local idCorner = Instance.new("UICorner")
idCorner.CornerRadius = UDim.new(0, 6)
idCorner.Parent = idBox

local playIdBtn = Instance.new("TextButton")
playIdBtn.Size = UDim2.new(0, 80, 1, 0)
playIdBtn.Position = UDim2.new(1, -85, 0, 0)
playIdBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
playIdBtn.Text = "Играть"
playIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playIdBtn.Font = Enum.Font.Gotham
playIdBtn.TextSize = 14
playIdBtn.Parent = idFrame

local playIdCorner = Instance.new("UICorner")
playIdCorner.CornerRadius = UDim.new(0, 6)
playIdCorner.Parent = playIdBtn

playIdBtn.MouseButton1Click:Connect(function()
    local id = idBox.Text
    if id ~= "" then
        playAnimationById(id)
        for _, child in animContainer:GetChildren() do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
            end
        end
    end
end)

-- Игрок
local playerPage = createScrollPage()
playerPage.Visible = false
pages.Player = playerPage

local playerLabel = Instance.new("TextLabel")
playerLabel.Size = UDim2.new(1, -20, 0, 30)
playerLabel.BackgroundTransparency = 1
playerLabel.Text = "Игрок"
playerLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
playerLabel.TextXAlignment = Enum.TextXAlignment.Left
playerLabel.Font = Enum.Font.GothamBold
playerLabel.TextSize = 18
playerLabel.Parent = playerPage

local playerInfo = Instance.new("TextLabel")
playerInfo.Size = UDim2.new(1, -20, 0, 60)
playerInfo.BackgroundTransparency = 1
playerInfo.Text = "Имя: " .. player.Name .. "\nDisplayName: " .. player.DisplayName
playerInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
playerInfo.TextWrapped = true
playerInfo.TextXAlignment = Enum.TextXAlignment.Left
playerInfo.TextYAlignment = Enum.TextYAlignment.Top
playerInfo.Font = Enum.Font.Gotham
playerInfo.TextSize = 14
playerInfo.Parent = playerPage

local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(0, 200, 0, 36)
flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
flyBtn.Text = "Fly: Выкл"
flyBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
flyBtn.Font = Enum.Font.GothamBold
flyBtn.TextSize = 15
flyBtn.Parent = playerPage

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 8)
flyCorner.Parent = flyBtn

-- NOCLIP
local noclipEnabled = false
local noclipConnection = nil

local function enableNoClip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        updateCharacter()
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoClip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

local noclipBtn = Instance.new("TextButton")
noclipBtn.Size = UDim2.new(0, 200, 0, 36)
noclipBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
noclipBtn.Text = "Noclip: Выкл"
noclipBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
noclipBtn.Font = Enum.Font.GothamBold
noclipBtn.TextSize = 15
noclipBtn.Parent = playerPage

local noclipCorner = Instance.new("UICorner")
noclipCorner.CornerRadius = UDim.new(0, 8)
noclipCorner.Parent = noclipBtn

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        enableNoClip()
        noclipBtn.Text = "Noclip: Вкл"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
    else
        disableNoClip()
        noclipBtn.Text = "Noclip: Выкл"
        noclipBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    end
end)

-- Слайдеры
local speedPanel = Instance.new("Frame")
speedPanel.Size = UDim2.new(1, -20, 0, 180)
speedPanel.BackgroundTransparency = 1
speedPanel.Parent = playerPage

local speedLayout = Instance.new("UIListLayout")
speedLayout.FillDirection = Enum.FillDirection.Vertical
speedLayout.Padding = UDim.new(0, 8)
speedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
speedLayout.Parent = speedPanel

local function createSlider(parent, labelText, defaultVal, minVal, maxVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 140, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 80, 1, 0)
    box.Position = UDim2.new(0, 145, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    box.Text = tostring(defaultVal)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.PlaceholderText = "0"
    box.ClearTextOnFocus = false
    box.Parent = row

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = box

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0, 70, 1, 0)
    applyBtn.Position = UDim2.new(1, -75, 0, 0)
    applyBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
    applyBtn.Text = "Прим."
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Font = Enum.Font.Gotham
    applyBtn.TextSize = 13
    applyBtn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
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

createSlider(speedPanel, "Скорость ходьбы:", 16, 0, 100, function(v)
    savedWalkSpeed = v
    if humanoid then humanoid.WalkSpeed = v end
end)

createSlider(speedPanel, "Сила прыжка:", 50, 0, 200, function(v)
    savedJumpPower = v
    if humanoid then humanoid.JumpPower = v end
end)

createSlider(speedPanel, "Скорость полёта:", 50, 1, 500, function(v)
    flySpeed = v
end)

------------------------------------------------------------
-- Fly
------------------------------------------------------------
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

flyBtn.MouseButton1Click:Connect(function()
    if flying then
        stopFly()
        flyBtn.Text = "Fly: Выкл"
        flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    else
        startFly()
        flyBtn.Text = "Fly: Вкл"
        flyBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
    end
end)

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
            if moveDir.Magnitude > 0.1 then
                moveDir = moveDir.Unit
            else
                moveDir = Vector3.new(0, 0, 0)
            end
        end
    end

    bodyVelocity.Velocity = moveDir * flySpeed
    if moveDir.Magnitude > 0.1 then
        bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDir)
    end
end)

player.CharacterAdded:Connect(function()
    if flying then
        stopFly()
        flyBtn.Text = "Fly: Выкл"
        flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    end
end)

------------------------------------------------------------
-- Визуалы + Аимбот (выбор цели, FOV, маркер, цвет меню)
------------------------------------------------------------
local visualsPage = createScrollPage()
visualsPage.Visible = false
pages.Visuals = visualsPage

local visualsLabel = Instance.new("TextLabel")
visualsLabel.Size = UDim2.new(1, -20, 0, 30)
visualsLabel.BackgroundTransparency = 1
visualsLabel.Text = "Визуалы"
visualsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
visualsLabel.TextXAlignment = Enum.TextXAlignment.Left
visualsLabel.Font = Enum.Font.GothamBold
visualsLabel.TextSize = 18
visualsLabel.Parent = visualsPage

-- Ники
local namesToggle = Instance.new("TextButton")
namesToggle.Size = UDim2.new(0, 200, 0, 34)
namesToggle.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
namesToggle.Text = "Ники: Выкл"
namesToggle.TextColor3 = Color3.fromRGB(230, 230, 230)
namesToggle.Font = Enum.Font.Gotham
namesToggle.TextSize = 14
namesToggle.Parent = visualsPage

local namesCorner = Instance.new("UICorner")
namesCorner.CornerRadius = UDim.new(0, 8)
namesCorner.Parent = namesToggle

-- Хитбоксы
local boxesToggle = Instance.new("TextButton")
boxesToggle.Size = UDim2.new(0, 200, 0, 34)
boxesToggle.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
boxesToggle.Text = "Хитбоксы: Выкл"
boxesToggle.TextColor3 = Color3.fromRGB(230, 230, 230)
boxesToggle.Font = Enum.Font.Gotham
boxesToggle.TextSize = 14
boxesToggle.Parent = visualsPage

local boxesCorner = Instance.new("UICorner")
boxesCorner.CornerRadius = UDim.new(0, 8)
boxesCorner.Parent = boxesToggle

-- Аимбот вкл/выкл
local aimbotEnabled = false
local aimbotBtn = Instance.new("TextButton")
aimbotBtn.Size = UDim2.new(0, 200, 0, 34)
aimbotBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
aimbotBtn.Text = "Аимбот: Выкл"
aimbotBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
aimbotBtn.Font = Enum.Font.Gotham
aimbotBtn.TextSize = 14
aimbotBtn.Parent = visualsPage

local aimbotCorner = Instance.new("UICorner")
aimbotCorner.CornerRadius = UDim.new(0, 8)
aimbotCorner.Parent = aimbotBtn

-- Выбор цели
local aimTargetLabel = Instance.new("TextLabel")
aimTargetLabel.Size = UDim2.new(1, -20, 0, 20)
aimTargetLabel.BackgroundTransparency = 1
aimTargetLabel.Text = "Цель аимбота:"
aimTargetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
aimTargetLabel.TextXAlignment = Enum.TextXAlignment.Left
aimTargetLabel.Font = Enum.Font.Gotham
aimTargetLabel.TextSize = 14
aimTargetLabel.Parent = visualsPage

local targetDropdownBtn = Instance.new("TextButton")
targetDropdownBtn.Size = UDim2.new(0, 200, 0, 30)
targetDropdownBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
targetDropdownBtn.Text = "Все"
targetDropdownBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
targetDropdownBtn.Font = Enum.Font.Gotham
targetDropdownBtn.TextSize = 14
targetDropdownBtn.Parent = visualsPage

local targetDropdownCorner = Instance.new("UICorner")
targetDropdownCorner.CornerRadius = UDim.new(0, 6)
targetDropdownCorner.Parent = targetDropdownBtn

local targetListFrame = Instance.new("ScrollingFrame")
targetListFrame.Size = UDim2.new(0, 200, 0, 100)
targetListFrame.Position = UDim2.new(0, 10, 0, 260) -- фиксированное положение
targetListFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
targetListFrame.BorderSizePixel = 0
targetListFrame.Visible = false
targetListFrame.ZIndex = 10
targetListFrame.ScrollBarThickness = 4
targetListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
targetListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
targetListFrame.ElasticBehavior = Enum.ElasticBehavior.Never
targetListFrame.Parent = visualsPage

local targetListLayout = Instance.new("UIListLayout")
targetListLayout.Padding = UDim.new(0, 2)
targetListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
targetListLayout.SortOrder = Enum.SortOrder.LayoutOrder
targetListLayout.Parent = targetListFrame

-- Список игроков для выпадашки
local aimTargetPlayer = nil  -- nil = все, иначе Player
local function updateTargetList()
    for _, child in ipairs(targetListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Remove()
        end
    end

    -- Кнопка "Все"
    local allBtn = Instance.new("TextButton")
    allBtn.Size = UDim2.new(1, -10, 0, 24)
    allBtn.BackgroundColor3 = (aimTargetPlayer == nil) and Color3.fromRGB(80, 120, 220) or Color3.fromRGB(55, 55, 60)
    allBtn.Text = "Все"
    allBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    allBtn.Font = Enum.Font.Gotham
    allBtn.TextSize = 13
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
            plrBtn.Size = UDim2.new(1, -10, 0, 24)
            plrBtn.BackgroundColor3 = (aimTargetPlayer == plr) and Color3.fromRGB(80, 120, 220) or Color3.fromRGB(55, 55, 60)
            plrBtn.Text = plr.Name
            plrBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            plrBtn.Font = Enum.Font.Gotham
            plrBtn.TextSize = 13
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
end

targetDropdownBtn.MouseButton1Click:Connect(function()
    targetListFrame.Visible = not targetListFrame.Visible
    if targetListFrame.Visible then
        updateTargetList()
    end
end)

Players.PlayerAdded:Connect(function()
    if targetListFrame.Visible then updateTargetList() end
end)
Players.PlayerRemoving:Connect(function(p)
    if aimTargetPlayer == p then
        aimTargetPlayer = nil
        targetDropdownBtn.Text = "Все"
    end
    if targetListFrame.Visible then updateTargetList() end
end)
updateTargetList()

-- FOV кольцо (исправлено: только контур)
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.Transparency = 0.8
fovCircle.Visible = false
fovCircle.Radius = 100
fovCircle.Filled = false  -- ключевое изменение: делаем кольцо вместо заливки

local fovRadius = 100

local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(1, -20, 0, 20)
fovLabel.BackgroundTransparency = 1
fovLabel.Text = "FOV радиус:"
fovLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
fovLabel.TextXAlignment = Enum.TextXAlignment.Left
fovLabel.Font = Enum.Font.Gotham
fovLabel.TextSize = 14
fovLabel.Parent = visualsPage

local fovSliderRow = Instance.new("Frame")
fovSliderRow.Size = UDim2.new(1, -20, 0, 30)
fovSliderRow.BackgroundTransparency = 1
fovSliderRow.Parent = visualsPage

local fovBox = Instance.new("TextBox")
fovBox.Size = UDim2.new(0, 80, 1, 0)
fovBox.Position = UDim2.new(0, 0, 0, 0)
fovBox.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
fovBox.Text = "100"
fovBox.TextColor3 = Color3.fromRGB(255, 255, 255)
fovBox.Font = Enum.Font.Gotham
fovBox.TextSize = 14
fovBox.Parent = fovSliderRow

local fovApply = Instance.new("TextButton")
fovApply.Size = UDim2.new(0, 70, 1, 0)
fovApply.Position = UDim2.new(0, 85, 0, 0)
fovApply.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
fovApply.Text = "Прим."
fovApply.TextColor3 = Color3.fromRGB(255, 255, 255)
fovApply.Font = Enum.Font.Gotham
fovApply.TextSize = 13
fovApply.Parent = fovSliderRow

fovApply.MouseButton1Click:Connect(function()
    local val = tonumber(fovBox.Text)
    if val then
        val = math.clamp(val, 10, 500)
        fovBox.Text = tostring(val)
        fovRadius = val
        fovCircle.Radius = val
    end
end)

-- Маркер цели
local targetMarker = Drawing.new("Circle")
targetMarker.Color = Color3.fromRGB(255, 0, 0)
targetMarker.Thickness = 2
targetMarker.Transparency = 0.5
targetMarker.Visible = false
targetMarker.Radius = 8

-- HUE-слайдер (ползунок)
local hueLabel = Instance.new("TextLabel")
hueLabel.Size = UDim2.new(1, -20, 0, 20)
hueLabel.BackgroundTransparency = 1
hueLabel.Text = "Оттенок меню (0-360):"
hueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
hueLabel.TextXAlignment = Enum.TextXAlignment.Left
hueLabel.Font = Enum.Font.Gotham
hueLabel.TextSize = 14
hueLabel.Parent = visualsPage

local hueSliderFrame = Instance.new("Frame")
hueSliderFrame.Size = UDim2.new(0, 260, 0, 32)
hueSliderFrame.BackgroundTransparency = 1
hueSliderFrame.Parent = visualsPage

-- Трек слайдера
local hueTrack = Instance.new("Frame")
hueTrack.Size = UDim2.new(0, 200, 0, 8)
hueTrack.Position = UDim2.new(0, 0, 0.5, -4)
hueTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
hueTrack.BorderSizePixel = 0
hueTrack.Parent = hueSliderFrame

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 4)
trackCorner.Parent = hueTrack

-- Ползунок
local hueKnob = Instance.new("TextButton")
hueKnob.Size = UDim2.new(0, 22, 0, 22)
hueKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
hueKnob.Text = ""
hueKnob.AutoButtonColor = false
hueKnob.Parent = hueSliderFrame
local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = hueKnob

-- Метка значения
local hueValueLabel = Instance.new("TextLabel")
hueValueLabel.Size = UDim2.new(0, 50, 1, 0)
hueValueLabel.Position = UDim2.new(0, 210, 0, 0)
hueValueLabel.BackgroundTransparency = 1
hueValueLabel.Text = "0"
hueValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hueValueLabel.Font = Enum.Font.Gotham
hueValueLabel.TextSize = 14
hueValueLabel.TextXAlignment = Enum.TextXAlignment.Left
hueValueLabel.Parent = hueSliderFrame

local function HSVtoRGB(h, s, v)
    h = h % 360
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b = 0, 0, 0
    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    return Color3.fromRGB((r + m) * 255, (g + m) * 255, (b + m) * 255)
end

local function applyHue(hue)
    local mainColor = HSVtoRGB(hue, 0.4, 0.3)
    local titleColor = HSVtoRGB(hue, 0.5, 0.25)
    local contentColor = HSVtoRGB(hue, 0.3, 0.4)
    mainFrame.BackgroundColor3 = mainColor
    titleBar.BackgroundColor3 = titleColor
    contentFrame.BackgroundColor3 = contentColor
end

local currentHue = 0
local function updateHueKnobPosition()
    local trackWidth = 200
    local knobX = math.clamp((currentHue / 360) * trackWidth, 0, trackWidth)
    hueKnob.Position = UDim2.new(0, knobX - hueKnob.Size.X.Offset/2, 0.5, -hueKnob.Size.Y.Offset/2)
    hueValueLabel.Text = tostring(currentHue)
end

-- Логика перетаскивания слайдера
local dragging = false
hueKnob.MouseButton1Down:Connect(function()
    dragging = true
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = UserInputService:GetMouseLocation()
        local trackAbsPos = hueTrack.AbsolutePosition
        local trackSize = hueTrack.AbsoluteSize
        local relX = math.clamp(mousePos.X - trackAbsPos.X, 0, trackSize.X)
        currentHue = math.floor((relX / trackSize.X) * 360)
        updateHueKnobPosition()
        applyHue(currentHue)
    end
end)

updateHueKnobPosition()

-- ESP
local espEnabledNames = false
local espEnabledBoxes = false
local espObjects = {}

local function clearESP(target)
    local data = espObjects[target]
    if data then
        if data.nameTag then data.nameTag:Remove() end
        if data.lines then for _, line in ipairs(data.lines) do line:Remove() end end
        espObjects[target] = nil
    end
end

local function clearAllESP()
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
    
    if espEnabledNames then
        local nameTag = Drawing.new("Text")
        nameTag.Size = 16
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.Color = Color3.fromRGB(255, 255, 255)
        nameTag.Visible = false
        data.nameTag = nameTag
    end

    if espEnabledBoxes then
        for i = 1, 12 do
            local line = Drawing.new("Line")
            line.Color = Color3.fromRGB(255, 0, 0)
            line.Thickness = 2
            line.Visible = false
            table.insert(data.lines, line)
        end
    end

    if data.nameTag or #data.lines > 0 then
        espObjects[target] = data
    end
end

local function updateESP()
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
            else
                data.nameTag.Visible = false
            end
        end

        if #data.lines > 0 then
            if visible then
                local extents = char:GetExtentsSize()
                local half = extents / 2
                local cf = hrp.CFrame
                local corners = {
                    cf * Vector3.new(-half.X, half.Y, -half.Z),
                    cf * Vector3.new(half.X, half.Y, -half.Z),
                    cf * Vector3.new(half.X, half.Y, half.Z),
                    cf * Vector3.new(-half.X, half.Y, half.Z),
                    cf * Vector3.new(-half.X, -half.Y, -half.Z),
                    cf * Vector3.new(half.X, -half.Y, -half.Z),
                    cf * Vector3.new(half.X, -half.Y, half.Z),
                    cf * Vector3.new(-half.X, -half.Y, half.Z)
                }
                local screenCorners = {}
                local allOnScreen = true
                for _, corner in ipairs(corners) do
                    local screenPos, onScreen = camera:WorldToViewportPoint(corner)
                    if not onScreen or screenPos.Z <= 0 then
                        allOnScreen = false
                        break
                    end
                    table.insert(screenCorners, screenPos)
                end

                if allOnScreen and #screenCorners == 8 then
                    local edges = {
                        {1,2}, {2,3}, {3,4}, {4,1},
                        {5,6}, {6,7}, {7,8}, {8,5},
                        {1,5}, {2,6}, {3,7}, {4,8}
                    }
                    for i, edge in ipairs(edges) do
                        if i <= #data.lines then
                            local p1 = screenCorners[edge[1]]
                            local p2 = screenCorners[edge[2]]
                            data.lines[i].From = Vector2.new(p1.X, p1.Y)
                            data.lines[i].To = Vector2.new(p2.X, p2.Y)
                            data.lines[i].Visible = true
                        end
                    end
                else
                    for _, line in ipairs(data.lines) do line.Visible = false end
                end
            else
                for _, line in ipairs(data.lines) do line.Visible = false end
            end
        end
    end
end

-- Аимбот логика
local function getAimTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local screenCenter = camera.ViewportSize / 2

    if aimTargetPlayer then
        local char = aimTargetPlayer.Character
        local head = char and char:FindFirstChild("Head")
        if head and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen and screenPos.Z > 0 then
                local delta = Vector2.new(screenPos.X - screenCenter.X, screenPos.Y - screenCenter.Y)
                if delta.Magnitude < fovRadius then
                    return head
                end
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
                        local delta = Vector2.new(screenPos.X - screenCenter.X, screenPos.Y - screenCenter.Y)
                        local dist = delta.Magnitude
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
    if not aimbotEnabled then
        targetMarker.Visible = false
        fovCircle.Visible = false
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local screenCenter = camera.ViewportSize / 2
    fovCircle.Position = screenCenter
    fovCircle.Visible = true
    fovCircle.Radius = fovRadius

    local targetHead = getAimTarget()
    if targetHead then
        camera.CFrame = CFrame.new(camera.CFrame.Position, targetHead.Position)
        local headPos = targetHead.Position
        local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
        if onScreen and screenPos.Z > 0 then
            targetMarker.Position = Vector2.new(screenPos.X, screenPos.Y)
            targetMarker.Visible = true
        else
            targetMarker.Visible = false
        end
    else
        targetMarker.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    if espEnabledNames or espEnabledBoxes then
        updateESP()
    end
    updateAimbot()
end)

-- Управление переключателями
local function refreshESP()
    clearAllESP()
    if espEnabledNames or espEnabledBoxes then
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= player then
                createESPForPlayer(target)
            end
        end
    end
end

namesToggle.MouseButton1Click:Connect(function()
    espEnabledNames = not espEnabledNames
    namesToggle.Text = "Ники: " .. (espEnabledNames and "Вкл" or "Выкл")
    namesToggle.BackgroundColor3 = espEnabledNames and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(55, 55, 60)
    refreshESP()
end)

boxesToggle.MouseButton1Click:Connect(function()
    espEnabledBoxes = not espEnabledBoxes
    boxesToggle.Text = "Хитбоксы: " .. (espEnabledBoxes and "Вкл" or "Выкл")
    boxesToggle.BackgroundColor3 = espEnabledBoxes and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(55, 55, 60)
    refreshESP()
end)

aimbotBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotBtn.Text = "Аимбот: " .. (aimbotEnabled and "Вкл" or "Выкл")
    aimbotBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(55, 55, 60)
end)

Players.PlayerAdded:Connect(function(target)
    if espEnabledNames or espEnabledBoxes then
        createESPForPlayer(target)
    end
end)

Players.PlayerRemoving:Connect(function(target)
    clearESP(target)
end)

player.CharacterAdded:Connect(function()
    refreshESP()
    if noclipEnabled then
        enableNoClip()
    end
end)

------------------------------------------------------------
-- Переключение вкладок
------------------------------------------------------------
local activeColor = Color3.fromRGB(80, 120, 220)
local inactiveColor = Color3.fromRGB(45, 45, 50)

local function selectTab(tabName)
    for name, page in pairs(pages) do
        page.Visible = (name == tabName)
    end

    local buttons = {
        Info = infoTab,
        Settings = settingsTab,
        Animations = animsTab,
        Player = playerTab,
        Visuals = visualsTab
    }

    for name, btn in pairs(buttons) do
        btn.BackgroundColor3 = (name == tabName) and activeColor or inactiveColor
    end
end

infoTab.MouseButton1Click:Connect(function() selectTab("Info") end)
settingsTab.MouseButton1Click:Connect(function() selectTab("Settings") end)
animsTab.MouseButton1Click:Connect(function() selectTab("Animations") end)
playerTab.MouseButton1Click:Connect(function() selectTab("Player") end)
visualsTab.MouseButton1Click:Connect(function() selectTab("Visuals") end)

selectTab("Info")
