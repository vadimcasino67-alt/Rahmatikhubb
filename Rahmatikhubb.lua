--[[
    RAHMAT Menu — заготовка UI
    Тип: LocalScript
    Расположение: StarterPlayer > StarterPlayerScripts
    Вкладки: Инфо, Настройки
]]

local Players = game:GetService("Players")
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
-- Главный контейнер
------------------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 480, 0, 320)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
mainFrame.BorderSizePixel = 0
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

closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

------------------------------------------------------------
-- Панель вкладок (Инфо / Настройки)
------------------------------------------------------------
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -20, 0, 36)
tabBar.Position = UDim2.new(0, 10, 0, 54)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabBar

local function createTabButton(name, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 140, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(220, 220, 220)
	button.Font = Enum.Font.Gotham
	button.TextSize = 15
	button.Parent = tabBar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local infoTabButton = createTabButton("InfoTabButton", "Инфо")
local settingsTabButton = createTabButton("SettingsTabButton", "Настройки")

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

-- Страница "Инфо"
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
infoLabel.Text = "Добро пожаловать в RAHMAT!\n\nЗдесь будет информация о плейсе."
infoLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 16
infoLabel.Parent = infoPage

-- Страница "Настройки"
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

-- пример переключателя в настройках
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
-- Логика переключения вкладок
------------------------------------------------------------
local activeColor = Color3.fromRGB(80, 120, 220)
local inactiveColor = Color3.fromRGB(45, 45, 50)

local function selectTab(tabName)
	infoPage.Visible = (tabName == "Info")
	settingsPage.Visible = (tabName == "Settings")

	infoTabButton.BackgroundColor3 = (tabName == "Info") and activeColor or inactiveColor
	settingsTabButton.BackgroundColor3 = (tabName == "Settings") and activeColor or inactiveColor
end

infoTabButton.MouseButton1Click:Connect(function()
	selectTab("Info")
end)

settingsTabButton.MouseButton1Click:Connect(function()
	selectTab("Settings")
end)

selectTab("Info") -- вкладка по умолчанию
