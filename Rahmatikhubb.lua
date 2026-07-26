--[[
    RAHMAT Menu v3 (Fly через джойстик + вертикальные кнопки)
    Исправленная версия — вкладки работают
]]

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
    btn.Size = UDim2.new(0, 115, 1, 0)
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
local animsTab = createTabButton("AnimationsTab", "Анимации")
local playerTab = createTabButton("PlayerTab", "Игрок")

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

-- Инфо
local infoPage = Instance.new("Frame")
infoPage.Size = UDim2.new(1, 0, 1, 0)
infoPage.BackgroundTransparency = 1
infoPage.Visible = true
infoPage.Parent = contentFrame
pages.Info = infoPage

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 1, -20)
infoLabel.Position = UDim2.new(0, 10, 0, 10)
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
local settingsPage = Instance.new("Frame")
settingsPage.Size = UDim2.new(1, 0, 1, 0)
settingsPage.BackgroundTransparency = 1
settingsPage.Visible = false
settingsPage.Parent = contentFrame
pages.Settings = settingsPage

local settingsLabel = Instance.new("TextLabel")
settingsLabel.Size = UDim2.new(1, -20, 0, 30)
settingsLabel.Position = UDim2.new(0, 10, 0, 10)
settingsLabel.BackgroundTransparency = 1
settingsLabel.Text = "Настройки"
settingsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
settingsLabel.Font = Enum.Font.GothamBold
settingsLabel.TextSize = 18
settingsLabel.Parent = settingsPage

local exampleToggle = Instance.new("TextButton")
exampleToggle.Size = UDim2.new(0, 200, 0, 34)
exampleToggle.Position = UDim2.new(0, 10, 0, 50)
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
local animsPage = Instance.new("Frame")
animsPage.Size = UDim2.new(1, 0, 1, 0)
animsPage.BackgroundTransparency = 1
animsPage.Visible = false
animsPage.Parent = contentFrame
pages.Animations = animsPage

local animsLabel = Instance.new("TextLabel")
animsLabel.Size = UDim2.new(1, -20, 0, 30)
animsLabel.Position = UDim2.new(0, 10, 0, 10)
animsLabel.BackgroundTransparency = 1
animsLabel.Text = "Анимации"
animsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
animsLabel.TextXAlignment = Enum.TextXAlignment.Left
animsLabel.Font = Enum.Font.GothamBold
animsLabel.TextSize = 18
animsLabel.Parent = animsPage

local animContainer = Instance.new("Frame")
animContainer.Size = UDim2.new(1, -20, 0, 150)
animContainer.Position = UDim2.new(0, 10, 0, 45)
animContainer.BackgroundTransparency = 1
animContainer.Parent = animsPage

local animLayout = Instance.new("UIListLayout")
animLayout.FillDirection = Enum.FillDirection.Horizontal
animLayout.Wraps = true
animLayout.Padding = UDim.new(0, 8)
animLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
animLayout.Parent = animContainer

local animList = {
    {id = "180393100", name = "Idle"},
    {id = "180393200", name = "Walk"},
    {id = "180393300", name = "Run"},
    {id = "180393400", name = "Jump"},
    {id = "180393500", name = "Sit"},
    {id = "180393600", name = "Dance"}
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

local idFrame = Instance.new("Frame")
idFrame.Size = UDim2.new(1, -20, 0, 36)
idFrame.Position = UDim2.new(0, 10, 0, 205)
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
local playerPage = Instance.new("Frame")
playerPage.Size = UDim2.new(1, 0, 1, 0)
playerPage.BackgroundTransparency = 1
playerPage.Visible = false
playerPage.Parent = contentFrame
pages.Player = playerPage

local playerLabel = Instance.new("TextLabel")
playerLabel.Size = UDim2.new(1, -20, 0, 30)
playerLabel.Position = UDim2.new(0, 10, 0, 10)
playerLabel.BackgroundTransparency = 1
playerLabel.Text = "Игрок"
playerLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
playerLabel.TextXAlignment = Enum.TextXAlignment.Left
playerLabel.Font = Enum.Font.GothamBold
playerLabel.TextSize = 18
playerLabel.Parent = playerPage

local playerInfo = Instance.new("TextLabel")
playerInfo.Size = UDim2.new(1, -20, 0, 60)
playerInfo.Position = UDim2.new(0, 10, 0, 45)
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
flyBtn.Position = UDim2.new(0, 10, 0, 120)
flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
flyBtn.Text = "Fly: Выкл"
flyBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
flyBtn.Font = Enum.Font.GothamBold
flyBtn.TextSize = 15
flyBtn.Parent = playerPage

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 8)
flyCorner.Parent = flyBtn

-- Настройки скорости
local speedPanel = Instance.new("Frame")
speedPanel.Size = UDim2.new(1, -20, 0, 180)
speedPanel.Position = UDim2.new(0, 10, 0, 170)
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
-- Fly через джойстик
------------------------------------------------------------
local verticalFrame = Instance.new("Frame")
verticalFrame.Name = "FlyVertical"
verticalFrame.Size = UDim2.new(0, 120, 0, 100)
verticalFrame.Position = UDim2.new(0.5, 60, 1, -120)
verticalFrame.BackgroundTransparency = 1
verticalFrame.Visible = false
verticalFrame.Parent = screenGui

local btnUp = Instance.new("TextButton")
btnUp.Size = UDim2.new(0, 50, 0, 50)
btnUp.Position = UDim2.new(0, 35, 0, 0)
btnUp.BackgroundColor3 = Color3.fromRGB(80, 120, 220)
btnUp.Text = "▲"
btnUp.TextColor3 = Color3.fromRGB(255, 255, 255)
btnUp.Font = Enum.Font.GothamBold
btnUp.TextSize = 28
btnUp.Parent = verticalFrame

local upCorner = Instance.new("UICorner")
upCorner.CornerRadius = UDim.new(1, 0)
upCorner.Parent = btnUp

local btnDown = Instance.new("TextButton")
btnDown.Size = UDim2.new(0, 50, 0, 50)
btnDown.Position = UDim2.new(0, 35, 0, 50)
btnDown.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
btnDown.Text = "▼"
btnDown.TextColor3 = Color3.fromRGB(255, 255, 255)
btnDown.Font = Enum.Font.GothamBold
btnDown.TextSize = 28
btnDown.Parent = verticalFrame

local downCorner = Instance.new("UICorner")
downCorner.CornerRadius = UDim.new(1, 0)
downCorner.Parent = btnDown

local flyUp = false
local flyDown = false

btnUp.MouseButton1Down:Connect(function() flyUp = true end)
btnUp.MouseButton1Up:Connect(function() flyUp = false end)
btnUp.MouseLeave:Connect(function() flyUp = false end)

btnDown.MouseButton1Down:Connect(function() flyDown = true end)
btnDown.MouseButton1Up:Connect(function() flyDown = false end)
btnDown.MouseLeave:Connect(function() flyDown = false end)

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

    verticalFrame.Visible = true
end

local function stopFly()
    flying = false
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    verticalFrame.Visible = false
    flyUp = false
    flyDown = false
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

-- Обработка полёта (джойстик + вертикаль)
RunService.RenderStepped:Connect(function()
    if not flying then return end
    updateCharacter()
    if not rootPart or not bodyVelocity or not bodyGyro then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    -- Горизонталь от джойстика
    local moveDir = Vector3.new(0, 0, 0)
    if humanoid then
        local joy = humanoid.MoveDirection
        if joy.Magnitude > 0.1 then
            local joyUnit = joy.Unit
            local forward = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            local fwd = joyUnit:Dot(forward)
            local rgt = joyUnit:Dot(right)
            moveDir = (forward * fwd + right * rgt)
            if moveDir.Magnitude > 0.1 then
                moveDir = moveDir.Unit
            else
                moveDir = Vector3.new(0, 0, 0)
            end
        end
    end

    -- Вертикаль (кнопки + клавиши Space/Shift)
    local vert = 0
    if flyUp or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        vert = 1
    end
    if flyDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        vert = -1
    end

    local finalDir = moveDir * flySpeed + Vector3.new(0, vert * flySpeed, 0)
    if finalDir.Magnitude > 0 then
        bodyVelocity.Velocity = finalDir
        if moveDir.Magnitude > 0.1 then
            bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDir)
        else
            bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + camera.CFrame.LookVector)
        end
    else
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
end)

-- Отключаем Fly при смерти / респавне
player.CharacterAdded:Connect(function()
    if flying then
        stopFly()
        flyBtn.Text = "Fly: Выкл"
        flyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
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
        Player = playerTab
    }

    for name, btn in pairs(buttons) do
        btn.BackgroundColor3 = (name == tabName) and activeColor or inactiveColor
    end
end

infoTab.MouseButton1Click:Connect(function()
    selectTab("Info")
end)

settingsTab.MouseButton1Click:Connect(function()
    selectTab("Settings")
end)

animsTab.MouseButton1Click:Connect(function()
    selectTab("Animations")
end)

playerTab.MouseButton1Click:Connect(function()
    selectTab("Player")
end)

-- Стартовая вкладка
selectTab("Info")
