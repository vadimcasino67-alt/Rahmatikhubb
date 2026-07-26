--[[
    RAHMAT Menu
    Вкладки: Инфо, Настройки, Анимации, Игрок
    Сворачивание: кнопка X
    Открытие: плавающая кнопка R (для Android) + RightShift
    + Улучшенный Fly (управление через стандартный джойстик + клавиши Space/Shift)
    + Вкладка "Анимации" с воспроизведением стандартных анимаций и загрузкой по ID
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- ScreenGui
------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RAHMAT_Menu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

------------------------------------------------------------
-- Главный контейнер (меню)
------------------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 520, 0, 440) -- немного увеличим высоту
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -220)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainFrame

------------------------------------------------------------
-- Заголовок
------------------------------------------------------------
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -44, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "RAHMAT"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.Parent = titleBar

-- Кнопка сворачивания (X)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
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

------------------------------------------------------------
-- Плавающая кнопка открытия (для Android)
------------------------------------------------------------
local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
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

------------------------------------------------------------
-- Функции открытия / сворачивания
------------------------------------------------------------
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
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -20, 0, 36)
tabBar.Position = UDim2.new(0, 10, 0, 54)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabBar

local function createTabButton(name, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 115, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(220, 220, 220)
	button.Font = Enum.Font.Gotham
	button.TextSize = 14
	button.Parent = tabBar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local infoTabButton = createTabButton("InfoTabButton", "Инфо")
local settingsTabButton = createTabButton("SettingsTabButton", "Настройки")
local animationsTabButton = createTabButton("AnimationsTabButton", "Анимации")
local playerTabButton = createTabButton("PlayerTabButton", "Игрок")

------------------------------------------------------------
-- Контейнер содержимого
------------------------------------------------------------
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -104)
contentFrame.Position = UDim2.new(0, 10, 0, 98)
contentFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 10)
contentCorner.Parent = contentFrame

------------------------------------------------------------
-- Страница "Инфо"
------------------------------------------------------------
local infoPage = Instance.new("Frame")
infoPage.Name = "InfoPage"
infoPage.Size = UDim2.new(1, 0, 1, 0)
infoPage.BackgroundTransparency = 1
infoPage.Visible = true
infoPage.Parent = contentFrame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 1, -20)
infoLabel.Position = UDim2.new(0, 10, 0, 10)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Добро пожаловать в RAHMAT!\n\nЗдесь будет информация о плейсе.\n\nСвернуть: кнопка X\nОткрыть: круглая кнопка R (удобно на Android)\nТакже: RightShift"
infoLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 15
infoLabel.Parent = infoPage

------------------------------------------------------------
-- Страница "Настройки"
------------------------------------------------------------
local settingsPage = Instance.new("Frame")
settingsPage.Name = "SettingsPage"
settingsPage.Size = UDim2.new(1, 0, 1, 0)
settingsPage.BackgroundTransparency = 1
settingsPage.Visible = false
settingsPage.Parent = contentFrame

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

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ExampleToggle"
toggleButton.Size = UDim2.new(0, 200, 0, 34)
toggleButton.Position = UDim2.new(0, 10, 0, 50)
toggleButton.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
toggleButton.Text = "Опция: Выкл"
toggleButton.TextColor3 = Color3.fromRGB(230, 230, 230)
toggleButton.Font = Enum.Font.Gotham
toggleButton.TextSize = 14
toggleButton.Parent = settingsPage

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local toggleState = false
toggleButton.MouseButton1Click:Connect(function()
	toggleState = not toggleState
	toggleButton.Text = "Опция: " .. (toggleState and "Вкл" or "Выкл")
end)

------------------------------------------------------------
-- Страница "Анимации" (обновлено)
------------------------------------------------------------
local animationsPage = Instance.new("Frame")
animationsPage.Name = "AnimationsPage"
animationsPage.Size = UDim2.new(1, 0, 1, 0)
animationsPage.BackgroundTransparency = 1
animationsPage.Visible = false
animationsPage.Parent = contentFrame

local animationsLabel = Instance.new("TextLabel")
animationsLabel.Size = UDim2.new(1, -20, 0, 30)
animationsLabel.Position = UDim2.new(0, 10, 0, 10)
animationsLabel.BackgroundTransparency = 1
animationsLabel.Text = "Анимации"
animationsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
animationsLabel.TextXAlignment = Enum.TextXAlignment.Left
animationsLabel.Font = Enum.Font.GothamBold
animationsLabel.TextSize = 18
animationsLabel.Parent = animationsPage

-- Контейнер для кнопок анимаций
local animButtonContainer = Instance.new("Frame")
animButtonContainer.Name = "AnimButtonContainer"
animButtonContainer.Size = UDim2.new(1, -20, 0, 150)
animButtonContainer.Position = UDim2.new(0, 10, 0, 45)
animButtonContainer.BackgroundTransparency = 1
animButtonContainer.Parent = animationsPage

local animLayout = Instance.new("UIListLayout")
animLayout.FillDirection = Enum.FillDirection.Horizontal
animLayout.Wrap = true
animLayout.Padding = UDim.new(0, 8)
animLayout.Spacing = UDim.new(0, 8)
animLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
animLayout.Parent = animButtonContainer

-- Словарь стандартных анимаций (ID и название)
local animations = {
	{id = "180393100", name = "Idle"},
	{id = "180393200", name = "Walk"},
	{id = "180393300", name = "Run"},
	{id = "180393400", name = "Jump"},
	{id = "180393500", name = "Sit"},
	{id = "180393600", name = "Dance"}
}

local currentAnimationTrack = nil
local animator = nil

-- Функция получения Animator
local function getAnimator()
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return nil end
	-- Ищем Animator в Humanoid или в самом персонаже
	local anim = hum:FindFirstChild("Animator")
	if not anim then
		anim = Instance.new("Animator")
		anim.Parent = hum
	end
	return anim
end

-- Функция остановки текущей анимации
local function stopAnimation()
	if currentAnimationTrack then
		currentAnimationTrack:Stop()
		currentAnimationTrack = nil
	end
end

-- Создание кнопки для анимации
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
		stopAnimation()
		animator = getAnimator()
		if not animator then return end
		local track = animator:LoadAnimation(Instance.new("Animation"))
		track.AnimationId = "rbxassetid://" .. animData.id
		track:Play()
		currentAnimationTrack = track
		-- Меняем цвет кнопки, чтобы показать активную
		for _, child in parent:GetChildren() do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
			end
		end
		btn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
	end)

	return btn
end

for _, anim in ipairs(animations) do
	createAnimButton(animButtonContainer, anim)
end

-- Кнопка "Стоп"
local stopAnimBtn = Instance.new("TextButton")
stopAnimBtn.Size = UDim2.new(0, 100, 0, 36)
stopAnimBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
stopAnimBtn.Text = "Стоп"
stopAnimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopAnimBtn.Font = Enum.Font.GothamBold
stopAnimBtn.TextSize = 14
stopAnimBtn.Parent = animButtonContainer

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 8)
stopCorner.Parent = stopAnimBtn

stopAnimBtn.MouseButton1Click:Connect(function()
	stopAnimation()
	-- Сброс цвета кнопок
	for _, child in animButtonContainer:GetChildren() do
		if child:IsA("TextButton") and child ~= stopAnimBtn then
			child.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
		end
	end
end)

-- Поле для ввода своего ID анимации
local animIdFrame = Instance.new("Frame")
animIdFrame.Size = UDim2.new(1, -20, 0, 36)
animIdFrame.Position = UDim2.new(0, 10, 0, 205)
animIdFrame.BackgroundTransparency = 1
animIdFrame.Parent = animationsPage

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(0, 100, 1, 0)
idLabel.BackgroundTransparency = 1
idLabel.Text = "ID анимации:"
idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
idLabel.TextXAlignment = Enum.TextXAlignment.Left
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 14
idLabel.Parent = animIdFrame

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
idBox.Parent = animIdFrame

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
playIdBtn.Parent = animIdFrame

local playIdCorner = Instance.new("UICorner")
playIdCorner.CornerRadius = UDim.new(0, 6)
playIdCorner.Parent = playIdBtn

playIdBtn.MouseButton1Click:Connect(function()
	local id = idBox.Text
	if id == "" then return end
	stopAnimation()
	animator = getAnimator()
	if not animator then return end
	local track = animator:LoadAnimation(Instance.new("Animation"))
	track.AnimationId = "rbxassetid://" .. id
	track:Play()
	currentAnimationTrack = track
	-- Сброс цвета кнопок
	for _, child in animButtonContainer:GetChildren() do
		if child:IsA("TextButton") then
			child.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
		end
	end
end)

------------------------------------------------------------
-- Страница "Игрок" + Fly (без дополнительных кнопок)
------------------------------------------------------------
local playerPage = Instance.new("Frame")
playerPage.Name = "PlayerPage"
playerPage.Size = UDim2.new(1, 0, 1, 0)
playerPage.BackgroundTransparency = 1
playerPage.Visible = false
playerPage.Parent = contentFrame

-- Информация об игроке
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
playerInfo.Text = "Имя: " .. player.Name .. "\nDisplayName: " .. player.DisplayName .. "\nUserId: " .. player.UserId
playerInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
playerInfo.TextWrapped = true
playerInfo.TextXAlignment = Enum.TextXAlignment.Left
playerInfo.TextYAlignment = Enum.TextYAlignment.Top
playerInfo.Font = Enum.Font.Gotham
playerInfo.TextSize = 14
playerInfo.Parent = playerPage

-- Кнопка Fly On/Off
local flyButton = Instance.new("TextButton")
flyButton.Name = "FlyToggle"
flyButton.Size = UDim2.new(0, 200, 0, 36)
flyButton.Position = UDim2.new(0, 10, 0, 120)
flyButton.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
flyButton.Text = "Fly: Выкл"
flyButton.TextColor3 = Color3.fromRGB(230, 230, 230)
flyButton.Font = Enum.Font.GothamBold
flyButton.TextSize = 15
flyButton.Parent = playerPage

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 8)
flyCorner.Parent = flyButton

-- Панель настроек скорости (ходьба, прыжок, скорость полёта)
local settingsPanel = Instance.new("Frame")
settingsPanel.Name = "SettingsPanel"
settingsPanel.Size = UDim2.new(1, -20, 0, 180)
settingsPanel.Position = UDim2.new(0, 10, 0, 170)
settingsPanel.BackgroundTransparency = 1
settingsPanel.Parent = playerPage

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.FillDirection = Enum.FillDirection.Vertical
settingsLayout.Padding = UDim.new(0, 8)
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
settingsLayout.Parent = settingsPanel

-- Функция создания строки настройки
local function createSettingRow(parent, labelText, defaultVal, minVal, maxVal, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 140, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.Parent = row

	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(0, 80, 1, 0)
	textBox.Position = UDim2.new(0, 145, 0, 0)
	textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	textBox.Text = tostring(defaultVal)
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = 14
	textBox.PlaceholderText = "0"
	textBox.ClearTextOnFocus = false
	textBox.Parent = row

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = textBox

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
		local val = tonumber(textBox.Text)
		if val then
			val = math.clamp(val, minVal, maxVal)
			textBox.Text = tostring(val)
			callback(val)
		else
			textBox.Text = tostring(defaultVal)
		end
	end)

	return row, textBox, applyBtn
end

-- Сохраняемые значения
local savedWalkSpeed = 16
local savedJumpPower = 50
local flySpeed = 50

-- Применение настроек к персонажу
local function applyWalkSpeed(speed)
	savedWalkSpeed = speed
	local char = player.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		if hum then
			hum.WalkSpeed = speed
		end
	end
end

local function applyJumpPower(power)
	savedJumpPower = power
	local char = player.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		if hum then
			hum.JumpPower = power
		end
	end
end

-- Строка скорости ходьбы
local walkRow, walkBox, walkBtn = createSettingRow(settingsPanel, "Скорость ходьбы:", savedWalkSpeed, 0, 100, applyWalkSpeed)

-- Строка скорости прыжка
local jumpRow, jumpBox, jumpBtn = createSettingRow(settingsPanel, "Сила прыжка:", savedJumpPower, 0, 200, applyJumpPower)

-- Строка скорости полёта
local flySpeedRow, flySpeedBox, flySpeedBtn = createSettingRow(settingsPanel, "Скорость полёта:", flySpeed, 1, 500, function(val)
	flySpeed = val
end)

-- Применяем настройки при респавне
player.CharacterAdded:Connect(function(char)
	wait(0.5)
	local hum = char:FindFirstChild("Humanoid")
	if hum then
		hum.WalkSpeed = savedWalkSpeed
		hum.JumpPower = savedJumpPower
	end
end)

-- Применяем сразу, если персонаж уже есть
local char = player.Character
if char then
	local hum = char:FindFirstChild("Humanoid")
	if hum then
		hum.WalkSpeed = savedWalkSpeed
		hum.JumpPower = savedJumpPower
	end
end

------------------------------------------------------------
-- Логика Fly (управление через стандартные клавиши)
------------------------------------------------------------
local flying = false
local bodyVelocity, bodyGyro

local function startFly()
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	flying = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 10000
	bodyGyro.Parent = hrp
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
end

flyButton.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		flyButton.Text = "Fly: Выкл"
		flyButton.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
	else
		startFly()
		flyButton.Text = "Fly: Вкл"
		flyButton.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
	end
end)

-- Обновление полёта (клавиши + джойстик Android)
RunService.RenderStepped:Connect(function()
	if not flying then return end
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp or not bodyVelocity or not bodyGyro then return end

	local camera = workspace.CurrentCamera
	local moveDir = Vector3.new(0, 0, 0)

	-- Клавиатурный ввод (на Android эмулируется джойстиком и кнопками)
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0, 1, 0) end

	if moveDir.Magnitude > 0 then
		moveDir = moveDir.Unit
		bodyVelocity.Velocity = moveDir * flySpeed
		bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + camera.CFrame.LookVector)
	else
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	end
end)

-- Если персонаж умер/респавнился — выключаем fly
player.CharacterAdded:Connect(function()
	if flying then
		stopFly()
		flyButton.Text = "Fly: Выкл"
		flyButton.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
	end
end)

------------------------------------------------------------
-- Логика переключения вкладок
------------------------------------------------------------
local activeColor = Color3.fromRGB(80, 120, 220)
local inactiveColor = Color3.fromRGB(45, 45, 50)

local function selectTab(tabName)
	infoPage.Visible = (tabName == "Info")
	settingsPage.Visible = (tabName == "Settings")
	animationsPage.Visible = (tabName == "Animations")
	playerPage.Visible = (tabName == "Player")

	infoTabButton.BackgroundColor3 = (tabName == "Info") and activeColor or inactiveColor
	settingsTabButton.BackgroundColor3 = (tabName == "Settings") and activeColor or inactiveColor
	animationsTabButton.BackgroundColor3 = (tabName == "Animations") and activeColor or inactiveColor
	playerTabButton.BackgroundColor3 = (tabName == "Player") and activeColor or inactiveColor
end

infoTabButton.MouseButton1Click:Connect(function()
	selectTab("Info")
end)

settingsTabButton.MouseButton1Click:Connect(function()
	selectTab("Settings")
end)

animationsTabButton.MouseButton1Click:Connect(function()
	selectTab("Animations")
end)

playerTabButton.MouseButton1Click:Connect(function()
	selectTab("Player")
end)

selectTab("Info")
