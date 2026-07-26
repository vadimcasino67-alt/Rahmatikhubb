--[[
    RAHMAT Menu v7.3 + MM2 Tab (Мудрый Живчик) — Полный комплект:
    ESP (убийца/шериф), аимбот, кнопка выстрела (шериф), кнопка броска ножа (убийца),
    авто-подбор пистолета, заморозка плавающих кнопок.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

player.CharacterAdded:Connect(function()
    updateCharacter()
    task.wait(0.5)
    if humanoid then
        humanoid.WalkSpeed = savedWalkSpeed
        humanoid.JumpPower = savedJumpPower
    end
    if noclipEnabled then enableNoClip() end
    if invisEnabled then applyInvisibility(true) end
    if flingEnabled then setupFling(character) end
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
-- GUI (RAHMAT Menu)
------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RAHMAT_Menu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 460, 0, 380)
mainFrame.Position = UDim2.new(0.5, -230, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 14)
uiCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(0, 0, 0)
mainStroke.Transparency = 0.5
mainStroke.Thickness = 1.5
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Parent = mainFrame

-- Заголовок с радужным эффектом
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

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

-- Радужная анимация заголовка
local rainbowHue = 0
RunService.RenderStepped:Connect(function(dt)
    rainbowHue = (rainbowHue + dt * 120) % 360
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
local dragStartPos, frameStartPos = nil, nil

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

local draggingOpen = false
local openStartPos, openBtnStartPos = nil, nil

openButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not mainFrame.Visible then
            draggingOpen = true
            openStartPos = UserInputService:GetMouseLocation()
            openBtnStartPos = openButton.AbsolutePosition
        end
    end
end)
openButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingOpen = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = UserInputService:GetMouseLocation() - dragStartPos
        mainFrame.Position = UDim2.new(
            frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
        )
    elseif draggingOpen and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = UserInputService:GetMouseLocation() - openStartPos
        local newPos = openBtnStartPos + delta
        local screenSize = workspace.CurrentCamera.ViewportSize
        local btnSize = openButton.AbsoluteSize
        newPos = Vector2.new(
            math.clamp(newPos.X, 0, screenSize.X - btnSize.X),
            math.clamp(newPos.Y, 0, screenSize.Y - btnSize.Y)
        )
        openButton.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
    end
end)

-- Изменение размера
local resizeHandle = Instance.new("TextButton")
resizeHandle.Size = UDim2.new(0, 18, 0, 18)
resizeHandle.Position = UDim2.new(1, -18, 1, -18)
resizeHandle.BackgroundColor3 = Color3.fromRGB(123, 97, 255)
resizeHandle.Text = "◣"
resizeHandle.TextColor3 = Color3.fromRGB(28, 28, 33)
resizeHandle.Font = Enum.Font.GothamBold
resizeHandle.TextSize = 12
resizeHandle.AutoButtonColor = false
resizeHandle.Parent = mainFrame
local resizeCorner = Instance.new("UICorner")
resizeCorner.CornerRadius = UDim.new(0, 6)
resizeCorner.Parent = resizeHandle

local resizing = false
local resizeStartPos, resizeStartSize = nil, nil

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStartPos = UserInputService:GetMouseLocation()
        resizeStartSize = mainFrame.Size
    end
end)
resizeHandle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = UserInputService:GetMouseLocation() - resizeStartPos
        local newWidth = math.max(320, resizeStartSize.X.Offset + delta.X)
        local newHeight = math.max(280, resizeStartSize.Y.Offset + delta.Y)
        mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

-- Панель вкладок
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 32)
tabBar.Position = UDim2.new(0, 8, 0, 46)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

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
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -16, 1, -86)
contentFrame.Position = UDim2.new(0, 8, 0, 82)
contentFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
contentFrame.BackgroundTransparency = 0.3
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

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

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0, 180, 0, 30)
resetButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
resetButton.Text = "Очистить настройки"
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.Font = Enum.Font.GothamBold
resetButton.TextSize = 13
resetButton.Parent = settingsPage
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
    fovRadius = 100; fovCircle.Radius = 100; fovBox.Text = "100"
    refreshESP()
    -- Сброс MM2
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
    -- очистка ESP мм2
    for _, data in pairs(mm2EspStorage) do data.Gui:Destroy() end
    mm2EspStorage = {}
end
resetButton.MouseButton1Click:Connect(resetAllSettings)
task.spawn(function() fixScrolling(settingsPage) end)

-- ================== ВКЛАДКА АНИМКИ (без изменений) ==================
local animsPage = createScrollPage()
pages.Animations = animsPage
-- ... (оставлено как было, полный код не дублирую для краткости)

-- ================== ВКЛАДКА ИГРОК (без изменений) ==================
local playerPage = createScrollPage()
pages.Player = playerPage
-- ... (полный код был выше)

-- ================== ВКЛАДКА ВИЗУАЛЫ (без изменений) ==================
local visualsPage = createScrollPage()
pages.Visuals = visualsPage
-- ...

-- ================== ВКЛАДКА MM2 (ДОПОЛНЕНА) ==================
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

-- Объект состояния MM2
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

-- Кнопка ESP (уже была)
local mm2ESPBtn = Instance.new("TextButton")
mm2ESPBtn.Size = UDim2.new(0, 160, 0, 30)
mm2ESPBtn.BackgroundColor3 = Color3.fromRGB(123, 97, 255)
mm2ESPBtn.Text = "ESP: Вкл"
mm2ESPBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
mm2ESPBtn.Font = Enum.Font.GothamBold
mm2ESPBtn.TextSize = 13
mm2ESPBtn.Parent = mm2Page
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
local mm2AimbotCorner = Instance.new("UICorner")
mm2AimbotCorner.CornerRadius = UDim.new(0, 6)
mm2AimbotCorner.Parent = mm2AimbotBtn

mm2AimbotBtn.MouseButton1Click:Connect(function()
    MM2.AimbotEnabled = not MM2.AimbotEnabled
    mm2AimbotBtn.Text = "Аимбот: " .. (MM2.AimbotEnabled and "Вкл" or "Выкл")
    mm2AimbotBtn.BackgroundColor3 = MM2.AimbotEnabled and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
end)

-- НОВОЕ: Кнопка Выстрел (Шериф)
local shootToggleBtn = Instance.new("TextButton")
shootToggleBtn.Size = UDim2.new(0, 160, 0, 30)
shootToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
shootToggleBtn.Text = "Выстрел (Шериф): Выкл"
shootToggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
shootToggleBtn.Font = Enum.Font.GothamBold
shootToggleBtn.TextSize = 13
shootToggleBtn.Parent = mm2Page
local shootToggleCorner = Instance.new("UICorner")
shootToggleCorner.CornerRadius = UDim.new(0, 6)
shootToggleCorner.Parent = shootToggleBtn

shootToggleBtn.MouseButton1Click:Connect(function()
    MM2.ShootButtonEnabled = not MM2.ShootButtonEnabled
    shootToggleBtn.Text = "Выстрел (Шериф): " .. (MM2.ShootButtonEnabled and "Вкл" or "Выкл")
    shootToggleBtn.BackgroundColor3 = MM2.ShootButtonEnabled and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
    if MM2.ShootButtonEnabled then
        shootBtn.Visible = true
    else
        shootBtn.Visible = false
    end
end)

-- НОВОЕ: Кнопка Бросок ножа (Убийца)
local knifeToggleBtn = Instance.new("TextButton")
knifeToggleBtn.Size = UDim2.new(0, 160, 0, 30)
knifeToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
knifeToggleBtn.Text = "Бросок ножа: Выкл"
knifeToggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
knifeToggleBtn.Font = Enum.Font.GothamBold
knifeToggleBtn.TextSize = 13
knifeToggleBtn.Parent = mm2Page
local knifeToggleCorner = Instance.new("UICorner")
knifeToggleCorner.CornerRadius = UDim.new(0, 6)
knifeToggleCorner.Parent = knifeToggleBtn

knifeToggleBtn.MouseButton1Click:Connect(function()
    MM2.KnifeThrowEnabled = not MM2.KnifeThrowEnabled
    knifeToggleBtn.Text = "Бросок ножа: " .. (MM2.KnifeThrowEnabled and "Вкл" or "Выкл")
    knifeToggleBtn.BackgroundColor3 = MM2.KnifeThrowEnabled and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
    if MM2.KnifeThrowEnabled then
        knifeBtn.Visible = true
    else
        knifeBtn.Visible = false
    end
end)

-- НОВОЕ: Авто-подбор пистолета
local autoPickupBtn = Instance.new("TextButton")
autoPickupBtn.Size = UDim2.new(0, 160, 0, 30)
autoPickupBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
autoPickupBtn.Text = "Авто-подбор пистолета: Выкл"
autoPickupBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
autoPickupBtn.Font = Enum.Font.GothamBold
autoPickupBtn.TextSize = 13
autoPickupBtn.Parent = mm2Page
local autoPickupCorner = Instance.new("UICorner")
autoPickupCorner.CornerRadius = UDim.new(0, 6)
autoPickupCorner.Parent = autoPickupBtn

autoPickupBtn.MouseButton1Click:Connect(function()
    MM2.AutoPickupGun = not MM2.AutoPickupGun
    autoPickupBtn.Text = "Авто-подбор пистолета: " .. (MM2.AutoPickupGun and "Вкл" or "Выкл")
    autoPickupBtn.BackgroundColor3 = MM2.AutoPickupGun and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
end)

-- НОВОЕ: Заморозка плавающих кнопок
local freezeButtonsToggle = Instance.new("TextButton")
freezeButtonsToggle.Size = UDim2.new(0, 160, 0, 30)
freezeButtonsToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 56)
freezeButtonsToggle.Text = "Заморозить кнопки: Выкл"
freezeButtonsToggle.TextColor3 = Color3.fromRGB(220, 220, 220)
freezeButtonsToggle.Font = Enum.Font.GothamBold
freezeButtonsToggle.TextSize = 13
freezeButtonsToggle.Parent = mm2Page
local freezeButtonsCorner = Instance.new("UICorner")
freezeButtonsCorner.CornerRadius = UDim.new(0, 6)
freezeButtonsCorner.Parent = freezeButtonsToggle

freezeButtonsToggle.MouseButton1Click:Connect(function()
    MM2.FreezeButtons = not MM2.FreezeButtons
    freezeButtonsToggle.Text = "Заморозить кнопки: " .. (MM2.FreezeButtons and "Вкл" or "Выкл")
    freezeButtonsToggle.BackgroundColor3 = MM2.FreezeButtons and Color3.fromRGB(123, 97, 255) or Color3.fromRGB(50, 50, 56)
end)

task.spawn(function() fixScrolling(mm2Page) end)

-- ================== ПЛАВАЮЩИЕ КНОПКИ MM2 (Shoot & Knife) ==================
local floatGui = Instance.new("ScreenGui")
floatGui.Name = "MM2_FloatButtons"
floatGui.ResetOnSpawn = false
floatGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
floatGui.Parent = playerGui

-- Кнопка Выстрел (Шериф)
local shootBtn = Instance.new("TextButton")
shootBtn.Size = UDim2.new(0, 60, 0, 60)
shootBtn.Position = UDim2.new(0.8, 0, 0.7, 0)
shootBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
shootBtn.Text = "SHOOT"
shootBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shootBtn.Font = Enum.Font.GothamBold
shootBtn.TextSize = 14
shootBtn.Visible = false
shootBtn.Parent = floatGui
local shootCorner = Instance.new("UICorner")
shootCorner.CornerRadius = UDim.new(1, 0)
shootCorner.Parent = shootBtn

-- Кнопка Бросок ножа (Убийца)
local knifeBtn = Instance.new("TextButton")
knifeBtn.Size = UDim2.new(0, 60, 0, 60)
knifeBtn.Position = UDim2.new(0.2, 0, 0.7, 0)
knifeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
knifeBtn.Text = "KNIFE"
knifeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
knifeBtn.Font = Enum.Font.GothamBold
knifeBtn.TextSize = 14
knifeBtn.Visible = false
knifeBtn.Parent = floatGui
local knifeCorner = Instance.new("UICorner")
knifeCorner.CornerRadius = UDim.new(1, 0)
knifeCorner.Parent = knifeBtn

-- Перетаскивание для кнопок (если не заморожены)
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

-- ================== ФУНКЦИИ ДЛЯ ДЕЙСТВИЙ ==================
-- Выстрел с автоаимом (для шерифа)
local function shootWithAim()
    if not player.Character then return end
    local gun = player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun")
    if not gun then return end
    -- экипируем пистолет, если не экипирован
    if player.Character:FindFirstChild("Gun") == nil and player.Backpack:FindFirstChild("Gun") then
        player.Character.Humanoid:EquipTool(player.Backpack["Gun"])
        task.wait(0.1)
    end
    -- автоаим на ближайшего врага (убийцу)
    local enemy = getClosestEnemyMM2() -- используем существующую функцию поиска
    if enemy then
        smoothAimMM2(enemy)
        task.wait(0.05)
    end
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

shootBtn.MouseButton1Click:Connect(shootWithAim)

-- Бросок ножа с автоаимом (для убийцы)
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

-- Авто-подбор пистолета
local function autoPickupGunLoop()
    while task.wait(0.5) do
        if not MM2.AutoPickupGun then continue end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then continue end
        local root = player.Character.HumanoidRootPart
        -- ищем пистолет в workspace (обычно Tool по имени "Gun")
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj.Name == "Gun" and obj.Parent ~= player.Character and obj.Parent ~= player.Backpack then
                local distance = (root.Position - obj.Position).Magnitude
                if distance < 15 then
                    -- телепортируемся прямо к пистолету для подбора
                    local oldCFrame = root.CFrame
                    root.CFrame = CFrame.new(obj.Position)
                    task.wait(0.1)
                    root.CFrame = oldCFrame
                    break -- подобрали один, дальше не ищем в этом цикле
                end
            end
        end
    end
end

task.spawn(autoPickupGunLoop)

-- ================== ОСНОВНОЙ СКРИПТ MM2 (ESP, AIMBOT) ==================
local mm2EspStorage = {}

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

player.CharacterAdded:Connect(function()
    for _, data in pairs(mm2EspStorage) do data.Gui:Destroy() end
    mm2EspStorage = {}
end)
Players.PlayerRemoving:Connect(function(plr)
    if mm2EspStorage[plr] then
        mm2EspStorage[plr].Gui:Destroy()
        mm2EspStorage[plr] = nil
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

infoTab.MouseButton1Click:Connect(function() selectTab("Info") end)
settingsTab.MouseButton1Click:Connect(function() selectTab("Settings") end)
animsTab.MouseButton1Click:Connect(function() selectTab("Animations") end)
playerTab.MouseButton1Click:Connect(function() selectTab("Player") end)
visualsTab.MouseButton1Click:Connect(function() selectTab("Visuals") end)
mm2Tab.MouseButton1Click:Connect(function() selectTab("MM2") end)
selectTab("Info")

print("RAHMAT Menu v7.3 + MM2 полный набор загружен. Мудрый Живчик доволен.")
