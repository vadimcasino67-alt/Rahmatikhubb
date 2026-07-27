--[[
    RAHMAT Menu v7.3 + MM2 Tab — РАБОЧИЙ ФИНАЛ
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Проверка Drawing (если нет – просто без ESP/aimbot кругов)
local DrawingAvailable = pcall(function() 
    local d = Drawing.new("Line")
    d:Remove()
    return true
end)

local fovCircle, targetMarker
if DrawingAvailable then
    fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(255,255,255)
    fovCircle.Thickness = 1
    fovCircle.Transparency = 0.7
    fovCircle.Visible = false
    fovCircle.Radius = 100
    fovCircle.Filled = false
    targetMarker = Drawing.new("Circle")
    targetMarker.Color = Color3.fromRGB(255,0,0)
    targetMarker.Thickness = 2
    targetMarker.Transparency = 0.5
    targetMarker.Visible = false
    targetMarker.Radius = 6
end

-- Переменные
local character, humanoid, rootPart
local savedWalkSpeed = 16
local savedJumpPower = 50
local flySpeed = 50
local flying = false
local bodyVelocity, bodyGyro
local noclipEnabled = false
local noclipConn
local invisEnabled = false
local invisSaved
local flingEnabled = false
local flingConns = {}
local espNames = false
local espBoxes = false
local espData = {}
local aimbotOn = false
local aimTarget = nil
local fovRadius = 100
local currentHue = 0
local teleportTarget = nil

local MM2 = {
    Aimbot = true,
    ESP = true,
    FOV = 120,
    Smooth = 0.4,
    Range = 50,
    ShootBtn = false,
    KnifeBtn = false,
    AutoPick = false,
    Freeze = false
}
local mm2ESP = {}

local function updateChar()
    character = player.Character
    if character then
        humanoid = character:FindFirstChild("Humanoid")
        rootPart = character:FindFirstChild("HumanoidRootPart")
    else
        humanoid = nil
        rootPart = nil
    end
end

-- Функции Fly, Noclip, Invis, Fling
local function startFly()
    updateChar()
    if not rootPart then return end
    flying = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = rootPart
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
    bodyGyro.P = 10000
    bodyGyro.Parent = rootPart
end
local function stopFly()
    flying = false
    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
end
local function enableNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if not noclipEnabled then return end
        updateChar()
        if character then
            for _,p in ipairs(character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end
local function disableNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
end
local function applyInvis(state)
    updateChar()
    if not character or not rootPart then return end
    if state then
        invisSaved = rootPart.CFrame
        rootPart.CFrame = CFrame.new(0,-500,0)
        rootPart.Anchored = true
        if humanoid then humanoid.WalkSpeed = 0 end
    else
        if invisSaved then rootPart.CFrame = invisSaved; invisSaved = nil end
        rootPart.Anchored = false
        if humanoid then humanoid.WalkSpeed = savedWalkSpeed end
    end
end
local function setupFling(char)
    if not flingEnabled then return end
    for _,c in ipairs(flingConns) do c:Disconnect() end
    table.clear(flingConns)
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            local conn = p.Touched:Connect(function(hit)
                if not flingEnabled then return end
                local model = hit.Parent
                if model:IsA("Model") and Players:GetPlayerFromCharacter(model) and model ~= char then
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dir = (hrp.Position - p.Position).Unit + Vector3.new(0,1,0)
                        local bv = Instance.new("BodyVelocity")
                        bv.Velocity = dir*200 + Vector3.new(0,100,0)
                        bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
                        bv.Parent = hrp
                        Debris:AddItem(bv,0.5)
                    end
                end
            end)
            table.insert(flingConns,conn)
        end
    end
end
local function disableFling()
    for _,c in ipairs(flingConns) do c:Disconnect() end
    table.clear(flingConns)
end

-- ESP / Aimbot
local function clearESP(plr)
    local d = espData[plr]
    if d then
        if d.name then d.name:Remove() end
        if d.lines then for _,l in ipairs(d.lines) do l:Remove() end end
        espData[plr] = nil
    end
end
function clearAllESP()
    for _,d in pairs(espData) do
        if d.name then d.name:Remove() end
        if d.lines then for _,l in ipairs(d.lines) do l:Remove() end end
    end
    table.clear(espData)
end
local function createESP(plr)
    if plr == player then return end
    if espData[plr] then clearESP(plr) end
    local data = {name=nil, lines={}}
    if espNames and DrawingAvailable then
        local t = Drawing.new("Text")
        t.Size = 14; t.Center = true; t.Outline = true
        t.Color = Color3.new(1,1,1); t.Visible = false
        data.name = t
    end
    if espBoxes and DrawingAvailable then
        for i=1,12 do
            local l = Drawing.new("Line")
            l.Color = Color3.new(1,0,0); l.Thickness = 2; l.Visible = false
            table.insert(data.lines,l)
        end
    end
    if data.name or #data.lines>0 then espData[plr] = data end
end
local function updateESP()
    if not DrawingAvailable then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    for plr,data in pairs(espData) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChild("Humanoid")
        local vis = hrp and head and hum and hum.Health>0
        if data.name then
            if vis then
                local hp = head.Position + Vector3.new(0,0.5,0)
                local sp, on = cam:WorldToViewportPoint(hp)
                data.name.Visible = on and sp.Z>0
                if data.name.Visible then
                    data.name.Position = Vector2.new(sp.X,sp.Y)
                    data.name.Text = plr.Name
                end
            else data.name.Visible = false end
        end
        if #data.lines>0 then
            if vis then
                local ext = char:GetExtentsSize()
                local half = ext/2
                local cf = hrp.CFrame
                local corners = {
                    cf*Vector3.new(-half.X, half.Y, -half.Z), cf*Vector3.new(half.X, half.Y, -half.Z),
                    cf*Vector3.new(half.X, half.Y, half.Z), cf*Vector3.new(-half.X, half.Y, half.Z),
                    cf*Vector3.new(-half.X,-half.Y,-half.Z), cf*Vector3.new(half.X,-half.Y,-half.Z),
                    cf*Vector3.new(half.X,-half.Y, half.Z), cf*Vector3.new(-half.X,-half.Y, half.Z)
                }
                local sc = {}
                local allOn = true
                for _,cr in ipairs(corners) do
                    local sp, on = cam:WorldToViewportPoint(cr)
                    if not on or sp.Z<=0 then allOn=false break end
                    table.insert(sc,sp)
                end
                if allOn and #sc==8 then
                    local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
                    for i,e in ipairs(edges) do
                        if i<=#data.lines then
                            data.lines[i].From = Vector2.new(sc[e[1]].X, sc[e[1]].Y)
                            data.lines[i].To = Vector2.new(sc[e[2]].X, sc[e[2]].Y)
                            data.lines[i].Visible = true
                        end
                    end
                else for _,l in ipairs(data.lines) do l.Visible = false end end
            else for _,l in ipairs(data.lines) do l.Visible = false end end
        end
    end
end
local function getAimTarget()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local center = cam.ViewportSize/2
    if aimTarget then
        local c = aimTarget.Character
        local h = c and c:FindFirstChild("Head")
        if h and c:FindFirstChild("Humanoid") and c.Humanoid.Health>0 then
            local sp, on = cam:WorldToViewportPoint(h.Position)
            if on and sp.Z>0 and (Vector2.new(sp.X-center.X,sp.Y-center.Y)).Magnitude < fovRadius then
                return h
            end
        end
        return nil
    else
        local best = nil; local bestDist = fovRadius
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player then
                local c = p.Character; local h = c and c:FindFirstChild("Head")
                if h and c:FindFirstChild("Humanoid") and c.Humanoid.Health>0 then
                    local sp, on = cam:WorldToViewportPoint(h.Position)
                    if on and sp.Z>0 then
                        local d = (Vector2.new(sp.X-center.X,sp.Y-center.Y)).Magnitude
                        if d<bestDist then bestDist=d; best=h end
                    end
                end
            end
        end
        return best
    end
end
local function updateAimbot()
    if not DrawingAvailable then return end
    if not aimbotOn then
        if fovCircle then fovCircle.Visible = false end
        if targetMarker then targetMarker.Visible = false end
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local center = cam.ViewportSize/2
    if fovCircle then fovCircle.Position = center; fovCircle.Visible = true; fovCircle.Radius = fovRadius end
    local head = getAimTarget()
    if head then
        cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
        if targetMarker then
            local sp, on = cam:WorldToViewportPoint(head.Position)
            if on and sp.Z>0 then targetMarker.Position = Vector2.new(sp.X,sp.Y); targetMarker.Visible = true
            else targetMarker.Visible = false end
        end
    else if targetMarker then targetMarker.Visible = false end end
end
function refreshESP()
    clearAllESP()
    if (espNames or espBoxes) and DrawingAvailable then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player then createESP(p) end
        end
    end
end

-- MM2 функции
local function getRole(plr)
    local c = plr.Character; if not c then return "Innocent" end
    local function has(n) return plr.Backpack:FindFirstChild(n) or c:FindFirstChild(n) end
    if has("Knife") and not has("Gun") then return "Murderer"
    elseif has("Gun") then return "Sheriff" end
    return "Innocent"
end
local function createMM2ESP(plr)
    if mm2ESP[plr] then return end
    local c = plr.Character; if not c then return end
    local h = c:FindFirstChild("Head"); if not h then return end
    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0,200,0,50); bg.StudsOffset = Vector3.new(0,2.5,0)
    bg.AlwaysOnTop = true; bg.Parent = h
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1
    tl.TextStrokeTransparency = 0.5; tl.TextColor3 = Color3.new(1,1,1)
    tl.Font = Enum.Font.SourceSansBold; tl.TextSize = 18; tl.Parent = bg
    mm2ESP[plr] = {Gui=bg, Label=tl}
end
local function updateMM2ESP()
    if not MM2.ESP then return end
    for plr,data in pairs(mm2ESP) do
        local c = plr.Character; local h = c and c:FindFirstChild("Humanoid")
        if not c or not h or h.Health<=0 then data.Gui:Destroy(); mm2ESP[plr]=nil
        else
            local role = getRole(plr)
            if role=="Murderer" then data.Label.TextColor3=Color3.fromRGB(255,50,50); data.Label.Text="Убийца"
            elseif role=="Sheriff" then data.Label.TextColor3=Color3.fromRGB(50,150,255); data.Label.Text="Шериф"
            else data.Gui:Destroy(); mm2ESP[plr]=nil end
        end
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and not mm2ESP[p] then
            local r = getRole(p)
            if r=="Murderer" or r=="Sheriff" then createMM2ESP(p) end
        end
    end
end
function getClosestMM2()
    local c = player.Character; if not c then return nil end
    local root = c:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local myPos = root.Position; local center = workspace.CurrentCamera.ViewportSize/2
    local best = nil; local bestDist = MM2.FOV
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and p.Character then
            local er = p.Character:FindFirstChild("HumanoidRootPart")
            local eh = p.Character:FindFirstChild("Humanoid")
            if er and eh and eh.Health>0 then
                local sp,on = workspace.CurrentCamera:WorldToViewportPoint(er.Position)
                if on then
                    local d = (Vector2.new(sp.X,sp.Y)-center).Magnitude
                    if d<bestDist then bestDist=d; best={Player=p, Char=p.Character, Root=er, Dist=(myPos-er.Position).Magnitude} end
                end
            end
        end
    end
    return best
end
function smoothAimMM2(t)
    if not t then return end
    local cam = workspace.CurrentCamera
    local look = CFrame.new(cam.CFrame.Position, t.Root.Position)
    if MM2.Smooth>=1 then cam.CFrame = look else cam.CFrame = cam.CFrame:Lerp(look,MM2.Smooth) end
end
local lastAttack = 0
local function autoAttack(t)
    if not t or t.Dist>MM2.Range then return end
    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0)
end

-- ========== GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RAHMAT"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0,460,0,380)
mainFrame.Position = UDim2.new(0.5,-230,0.5,-190)
mainFrame.BackgroundColor3 = Color3.fromRGB(28,28,33)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui
mainFrame.ZIndex = 1
Instance.new("UICorner",mainFrame).CornerRadius = UDim.new(0,14)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,36)
titleBar.BackgroundColor3 = Color3.fromRGB(22,22,28)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
titleBar.ZIndex = 2
Instance.new("UICorner",titleBar).CornerRadius = UDim.new(0,14)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1,-84,1,0)
titleLabel.Position = UDim2.new(0,14,0,0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "RAHMAT"
titleLabel.TextColor3 = Color3.fromRGB(255,0,0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.Parent = titleBar

-- кнопки заголовка
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,28,0,28)
closeBtn.Position = UDim2.new(1,-34,0,4)
closeBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(220,220,220)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = titleBar; closeBtn.ZIndex = 20
Instance.new("UICorner",closeBtn).CornerRadius = UDim.new(0,8)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0,28,0,28)
minBtn.Position = UDim2.new(1,-66,0,4)
minBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
minBtn.Text = "🗕"
minBtn.TextColor3 = Color3.fromRGB(220,220,220)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.Parent = titleBar; minBtn.ZIndex = 20
Instance.new("UICorner",minBtn).CornerRadius = UDim.new(0,8)

local restBtn = Instance.new("TextButton")
restBtn.Size = UDim2.new(0,28,0,28)
restBtn.Position = UDim2.new(1,-34,0,4)
restBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
restBtn.Text = "▼"
restBtn.TextColor3 = Color3.fromRGB(220,220,220)
restBtn.Font = Enum.Font.GothamBold
restBtn.TextSize = 14
restBtn.Visible = false
restBtn.Parent = titleBar; restBtn.ZIndex = 20
Instance.new("UICorner",restBtn).CornerRadius = UDim.new(0,8)

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0,48,0,48)
openBtn.Position = UDim2.new(1,-66,0.5,-24)
openBtn.BackgroundColor3 = Color3.fromRGB(123,97,255)
openBtn.Text = "R"
openBtn.TextColor3 = Color3.new(1,1,1)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 22
openBtn.Visible = false
openBtn.Parent = screenGui; openBtn.ZIndex = 20
Instance.new("UICorner",openBtn).CornerRadius = UDim.new(1,0)

-- сворачивание
local minimized = false
local fullH = 380; local minH = 36
local tabBar, contentFrame
local function minimize()
    minimized = true
    tabBar.Visible = false
    contentFrame.Visible = false
    mainFrame.Size = UDim2.new(0,460,0,minH)
    minBtn.Visible = false
    restBtn.Visible = true
end
local function restore()
    minimized = false
    tabBar.Visible = true
    contentFrame.Visible = true
    mainFrame.Size = UDim2.new(0,460,0,fullH)
    minBtn.Visible = true
    restBtn.Visible = false
end
minBtn.MouseButton1Click:Connect(minimize)
restBtn.MouseButton1Click:Connect(restore)

local function openMenu()
    mainFrame.Visible = true
    openBtn.Visible = false
    if minimized then restore() end
end
local function closeMenu()
    mainFrame.Visible = false
    openBtn.Visible = true
end
closeBtn.MouseButton1Click:Connect(closeMenu)
openBtn.MouseButton1Click:Connect(openMenu)
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if mainFrame.Visible then closeMenu() else openMenu() end
    end
end)

-- перемещение
local drag, dragStart, frameStart
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = true
        dragStart = UserInputService:GetMouseLocation()
        frameStart = mainFrame.Position
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then drag = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = UserInputService:GetMouseLocation() - dragStart
        mainFrame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset+delta.X, frameStart.Y.Scale, frameStart.Y.Offset+delta.Y)
    end
end)

-- вкладки
tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1,-16,0,32)
tabBar.Position = UDim2.new(0,8,0,46)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame
tabBar.ZIndex = 15
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0,4)
tabLayout.Parent = tabBar

contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1,-16,1,-86)
contentFrame.Position = UDim2.new(0,8,0,82)
contentFrame.BackgroundColor3 = Color3.fromRGB(24,24,29)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame
contentFrame.ZIndex = 1
Instance.new("UICorner",contentFrame).CornerRadius = UDim.new(0,12)

local pages = {}
local function createPage()
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1,0,1,0)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness = 3
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ScrollBarImageColor3 = Color3.fromRGB(100,100,110)
    sf.ElasticBehavior = Enum.ElasticBehavior.Never
    sf.ScrollingDirection = Enum.ScrollingDirection.Y
    sf.ClipsDescendants = true
    sf.Parent = contentFrame
    sf.Visible = false
    sf.ZIndex = 1
    local uiList = Instance.new("UIListLayout")
    uiList.Padding = UDim.new(0,5)
    uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = sf
    return sf
end

-- === СТРАНИЦЫ ===
local infoPage = createPage(); pages.Info = infoPage
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1,-16,0,160)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "RAHMAT Menu\n\nСвернуть: 🗕 | Закрыть: ✕ | Открыть: R / RightShift"
infoLabel.TextColor3 = Color3.fromRGB(210,210,210)
infoLabel.TextWrapped = true; infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Font = Enum.Font.Gotham; infoLabel.TextSize = 13
infoLabel.Parent = infoPage; infoLabel.ZIndex = 1

local settingsPage = createPage(); pages.Settings = settingsPage
local setLabel = Instance.new("TextLabel")
setLabel.Size = UDim2.new(1,-16,0,24); setLabel.BackgroundTransparency = 1
setLabel.Text = "Настройки"; setLabel.TextColor3 = Color3.fromRGB(230,230,230)
setLabel.Font = Enum.Font.GothamBold; setLabel.TextSize = 15
setLabel.Parent = settingsPage; setLabel.ZIndex = 1

-- сброс
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0,180,0,30)
resetBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
resetBtn.Text = "Сбросить всё"
resetBtn.TextColor3 = Color3.new(1,1,1)
resetBtn.Font = Enum.Font.GothamBold; resetBtn.TextSize = 13
resetBtn.Parent = settingsPage; resetBtn.ZIndex = 10
Instance.new("UICorner",resetBtn).CornerRadius = UDim.new(0,6)

-- Далее создадим все кнопки, но resetBtn.onClick определим позже, когда кнопки будут готовы
-- Чтобы не усложнять, создадим функцию сброса в конце после создания всех кнопок

local animsPage = createPage(); pages.Animations = animsPage
local animLabel = Instance.new("TextLabel")
animLabel.Size = UDim2.new(1,-16,0,24); animLabel.BackgroundTransparency = 1
animLabel.Text = "Анимации"; animLabel.TextColor3 = Color3.fromRGB(230,230,230)
animLabel.Font = Enum.Font.GothamBold; animLabel.TextSize = 15
animLabel.Parent = animsPage; animLabel.ZIndex = 1
local animContainer = Instance.new("Frame")
animContainer.Size = UDim2.new(1,-16,0,160); animContainer.BackgroundTransparency = 1
animContainer.Parent = animsPage; animContainer.ZIndex = 1
local animLayout = Instance.new("UIListLayout")
animLayout.FillDirection = Enum.FillDirection.Horizontal; animLayout.Wraps = true
animLayout.Padding = UDim.new(0,6); animLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
animLayout.Parent = animContainer
local animList = {
    {id="1083461615",name="Zombie Idle"},{id="1083462077",name="Zombie Walk"},
    {id="3360689775",name="Cartwheel"},{id="3360963031",name="Levitation"},
    {id="656118852",name="Ninja Run"},{id="180393400",name="Jump"}
}
local currentTrack
local function getAnimator()
    updateChar()
    if not character or not humanoid then return nil end
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then animator = Instance.new("Animator"); animator.Parent = humanoid end
    return animator
end
local function stopAnims()
    if currentTrack then currentTrack:Stop(); currentTrack = nil end
end
local function playAnim(id)
    stopAnims()
    local animator = getAnimator()
    if not animator then return end
    local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://"..id
    local track = animator:LoadAnimation(anim); track:Play(); currentTrack = track
end
for _,a in ipairs(animList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,90,0,28); btn.BackgroundColor3 = Color3.fromRGB(50,50,56)
    btn.Text = a.name; btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Font = Enum.Font.Gotham; btn.TextSize = 12; btn.ZIndex = 10
    btn.Parent = animContainer
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(function()
        playAnim(a.id)
        for _,c in ipairs(animContainer:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(50,50,56) end end
        btn.BackgroundColor3 = Color3.fromRGB(123,97,255)
    end)
end
local stopAnimBtn = Instance.new("TextButton")
stopAnimBtn.Size = UDim2.new(0,90,0,28); stopAnimBtn.BackgroundColor3 = Color3.fromRGB(60,30,30)
stopAnimBtn.Text = "Стоп"; stopAnimBtn.TextColor3 = Color3.new(1,1,1)
stopAnimBtn.Font = Enum.Font.GothamBold; stopAnimBtn.TextSize = 12; stopAnimBtn.ZIndex = 10
stopAnimBtn.Parent = animContainer
Instance.new("UICorner",stopAnimBtn).CornerRadius = UDim.new(0,6)
stopAnimBtn.MouseButton1Click:Connect(function()
    stopAnims()
    for _,c in ipairs(animContainer:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(50,50,56) end end
end)

local idFrame = Instance.new("Frame")
idFrame.Size = UDim2.new(1,-16,0,30); idFrame.BackgroundTransparency = 1
idFrame.Parent = animsPage; idFrame.ZIndex = 1
local idLab = Instance.new("TextLabel")
idLab.Size = UDim2.new(0,80,1,0); idLab.BackgroundTransparency = 1
idLab.Text = "ID аним.:"; idLab.TextColor3 = Color3.fromRGB(200,200,200)
idLab.Font = Enum.Font.Gotham; idLab.TextSize = 12; idLab.Parent = idFrame
local idBox = Instance.new("TextBox")
idBox.Size = UDim2.new(0,120,1,0); idBox.Position = UDim2.new(0,84,0,0)
idBox.BackgroundColor3 = Color3.fromRGB(50,50,56); idBox.Text = ""
idBox.TextColor3 = Color3.new(1,1,1); idBox.Font = Enum.Font.Gotham; idBox.TextSize = 12
idBox.PlaceholderText = "ID"; idBox.ClearTextOnFocus = false; idBox.Parent = idFrame
Instance.new("UICorner",idBox).CornerRadius = UDim.new(0,4)
local playId = Instance.new("TextButton")
playId.Size = UDim2.new(0,60,1,0); playId.Position = UDim2.new(1,-64,0,0)
playId.BackgroundColor3 = Color3.fromRGB(70,70,75); playId.Text = "Играть"
playId.TextColor3 = Color3.new(1,1,1); playId.Font = Enum.Font.Gotham; playId.TextSize = 12
playId.Parent = idFrame; playId.ZIndex = 10
Instance.new("UICorner",playId).CornerRadius = UDim.new(0,4)
playId.MouseButton1Click:Connect(function()
    local id = idBox.Text; if id~="" then playAnim(id) end
end)

-- страница Игрок
local playerPage = createPage(); pages.Player = playerPage
local plrLabel = Instance.new("TextLabel")
plrLabel.Size = UDim2.new(1,-16,0,24); plrLabel.BackgroundTransparency = 1
plrLabel.Text = "Игрок"; plrLabel.TextColor3 = Color3.fromRGB(230,230,230)
plrLabel.Font = Enum.Font.GothamBold; plrLabel.TextSize = 15
plrLabel.Parent = playerPage; plrLabel.ZIndex = 1
local plrInfo = Instance.new("TextLabel")
plrInfo.Size = UDim2.new(1,-16,0,40); plrInfo.BackgroundTransparency = 1
plrInfo.Text = "Имя: "..player.Name.."\nDisplay: "..player.DisplayName
plrInfo.TextColor3 = Color3.fromRGB(190,190,190); plrInfo.TextWrapped = true
plrInfo.Font = Enum.Font.Gotham; plrInfo.TextSize = 12; plrInfo.Parent = playerPage

local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(0,160,0,30); flyBtn.BackgroundColor3 = Color3.fromRGB(50,50,56)
flyBtn.Text = "Fly: Выкл"; flyBtn.TextColor3 = Color3.fromRGB(220,220,220)
flyBtn.Font = Enum.Font.GothamBold; flyBtn.TextSize = 13; flyBtn.Parent = playerPage; flyBtn.ZIndex = 10
Instance.new("UICorner",flyBtn).CornerRadius = UDim.new(0,6)
flyBtn.MouseButton1Click:Connect(function()
    if flying then stopFly(); flyBtn.Text="Fly: Выкл"; flyBtn.BackgroundColor3=Color3.fromRGB(50,50,56)
    else startFly(); flyBtn.Text="Fly: Вкл"; flyBtn.BackgroundColor3=Color3.fromRGB(123,97,255) end
end)

local noclipBtn = Instance.new("TextButton")
noclipBtn.Size = UDim2.new(0,160,0,30); noclipBtn.BackgroundColor3 = Color3.fromRGB(50,50,56)
noclipBtn.Text = "Noclip: Выкл"; noclipBtn.TextColor3 = Color3.fromRGB(220,220,220)
noclipBtn.Font = Enum.Font.GothamBold; noclipBtn.TextSize = 13; noclipBtn.Parent = playerPage; noclipBtn.ZIndex = 10
Instance.new("UICorner",noclipBtn).CornerRadius = UDim.new(0,6)
noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then enableNoclip(); noclipBtn.Text="Noclip: Вкл"; noclipBtn.BackgroundColor3=Color3.fromRGB(123,97,255)
    else disableNoclip(); noclipBtn.Text="Noclip: Выкл"; noclipBtn.BackgroundColor3=Color3.fromRGB(50,50,56) end
end)

local invisBtn = Instance.new("TextButton")
invisBtn.Size = UDim2.new(0,160,0,30); invisBtn.BackgroundColor3 = Color3.fromRGB(50,50,56)
invisBtn.Text = "Невидимка: Выкл"; invisBtn.TextColor3 = Color3.fromRGB(220,220,220)
invisBtn.Font = Enum.Font.GothamBold; invisBtn.TextSize = 13; invisBtn.Parent = playerPage; invisBtn.ZIndex = 10
Instance.new("UICorner",invisBtn).CornerRadius = UDim.new(0,6)
invisBtn.MouseButton1Click:Connect(function()
    invisEnabled = not invisEnabled
    if invisEnabled then applyInvis(true); invisBtn.Text="Невидимка: Вкл"; invisBtn.BackgroundColor3=Color3.fromRGB(123,97,255)
    else applyInvis(false); invisBtn.Text="Невидимка: Выкл"; invisBtn.BackgroundColor3=Color3.fromRGB(50,50,56) end
end)

local teleportLabel = Instance.new("TextLabel")
teleportLabel.Size = UDim2.new(1,-16,0,18); teleportLabel.BackgroundTransparency = 1
teleportLabel.Text = "Телепорт:"; teleportLabel.TextColor3 = Color3.fromRGB(200,200,200)
teleportLabel.Font = Enum.Font.Gotham; teleportLabel.TextSize = 12; teleportLabel.Parent = playerPage
local tpDrop = Instance.new("TextButton")
tpDrop.Size = UDim2.new(0,160,0,28); tpDrop.BackgroundColor3 = Color3.fromRGB(50,50,56)
tpDrop.Text = "Выбрать"; tpDrop.TextColor3 = Color3.fromRGB(220,220,220)
tpDrop.Font = Enum.Font.Gotham; tpDrop.TextSize = 12; tpDrop.Parent = playerPage; tpDrop.ZIndex = 10
Instance.new("UICorner",tpDrop).CornerRadius = UDim.new(0,4)
local tpList = Instance.new("ScrollingFrame")
tpList.Size = UDim2.new(0,160,0,80); tpList.Position = UDim2.new(0,8,0,250)
tpList.BackgroundColor3 = Color3.fromRGB(40,40,46); tpList.BorderSizePixel = 0
tpList.Visible = false; tpList.ZIndex = 20; tpList.ScrollBarThickness = 3
tpList.CanvasSize = UDim2.new(0,0,0,0); tpList.AutomaticCanvasSize = Enum.AutomaticSize.Y
tpList.ElasticBehavior = Enum.ElasticBehavior.Never; tpList.ScrollingDirection = Enum.ScrollingDirection.Y
tpList.ClipsDescendants = true; tpList.Parent = playerPage
local tpLayout = Instance.new("UIListLayout")
tpLayout.Padding = UDim.new(0,2); tpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tpLayout.SortOrder = Enum.SortOrder.LayoutOrder; tpLayout.Parent = tpList
local function updateTpList()
    for _,c in ipairs(tpList:GetChildren()) do if c:IsA("TextButton") then c:Remove() end end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1,-8,0,22); b.BackgroundColor3 = (teleportTarget==p) and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
            b.Text = p.Name; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.Gotham; b.TextSize = 12
            b.ZIndex = 20; b.Parent = tpList
            Instance.new("UICorner",b).CornerRadius = UDim.new(0,4)
            b.MouseButton1Click:Connect(function()
                teleportTarget = p; tpDrop.Text = p.Name; tpList.Visible = false; updateTpList()
            end)
        end
    end
end
tpDrop.MouseButton1Click:Connect(function()
    tpList.Visible = not tpList.Visible
    if tpList.Visible then updateTpList() end
end)
local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(0,160,0,28); tpBtn.BackgroundColor3 = Color3.fromRGB(70,70,75)
tpBtn.Text = "Телепорт"; tpBtn.TextColor3 = Color3.new(1,1,1)
tpBtn.Font = Enum.Font.Gotham; tpBtn.TextSize = 12; tpBtn.Parent = playerPage; tpBtn.ZIndex = 10
Instance.new("UICorner",tpBtn).CornerRadius = UDim.new(0,4)
tpBtn.MouseButton1Click:Connect(function()
    if not teleportTarget then return end
    local c = teleportTarget.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        updateChar()
        if rootPart then rootPart.CFrame = c.HumanoidRootPart.CFrame end
    end
end)

local flingBtn = Instance.new("TextButton")
flingBtn.Size = UDim2.new(0,160,0,30); flingBtn.BackgroundColor3 = Color3.fromRGB(50,50,56)
flingBtn.Text = "Fling: Выкл"; flingBtn.TextColor3 = Color3.fromRGB(220,220,220)
flingBtn.Font = Enum.Font.GothamBold; flingBtn.TextSize = 13; flingBtn.Parent = playerPage; flingBtn.ZIndex = 10
Instance.new("UICorner",flingBtn).CornerRadius = UDim.new(0,6)
flingBtn.MouseButton1Click:Connect(function()
    flingEnabled = not flingEnabled
    if flingEnabled then if character then setupFling(character) end; flingBtn.Text="Fling: Вкл"; flingBtn.BackgroundColor3=Color3.fromRGB(123,97,255)
    else disableFling(); flingBtn.Text="Fling: Выкл"; flingBtn.BackgroundColor3=Color3.fromRGB(50,50,56) end
end)

local speedPanel = Instance.new("Frame")
speedPanel.Size = UDim2.new(1,-16,0,150); speedPanel.BackgroundTransparency = 1
speedPanel.Parent = playerPage
local spLayout = Instance.new("UIListLayout")
spLayout.FillDirection = Enum.FillDirection.Vertical; spLayout.Padding = UDim.new(0,6)
spLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; spLayout.Parent = speedPanel
local function createSlider(parent, label, def, min, max, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,28); row.BackgroundTransparency = 1; row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0,120,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = Color3.fromRGB(200,200,200)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.Parent = row
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0,70,1,0); box.Position = UDim2.new(0,124,0,0)
    box.BackgroundColor3 = Color3.fromRGB(50,50,56); box.Text = tostring(def)
    box.TextColor3 = Color3.new(1,1,1); box.Font = Enum.Font.Gotham; box.TextSize = 12
    box.ClearTextOnFocus = false; box.Parent = row
    Instance.new("UICorner",box).CornerRadius = UDim.new(0,4)
    local apply = Instance.new("TextButton")
    apply.Size = UDim2.new(0,55,1,0); apply.Position = UDim2.new(1,-60,0,0)
    apply.BackgroundColor3 = Color3.fromRGB(70,70,75); apply.Text = "OK"
    apply.TextColor3 = Color3.new(1,1,1); apply.Font = Enum.Font.Gotham; apply.TextSize = 11
    apply.Parent = row; apply.ZIndex = 10
    Instance.new("UICorner",apply).CornerRadius = UDim.new(0,4)
    apply.MouseButton1Click:Connect(function()
        local val = tonumber(box.Text)
        if val then val = math.clamp(val,min,max); box.Text = tostring(val); callback(val)
        else box.Text = tostring(def) end
    end)
end
createSlider(speedPanel,"Скорость:",16,0,99999,function(v) savedWalkSpeed=v; if humanoid then humanoid.WalkSpeed=v end end)
createSlider(speedPanel,"Прыжок:",50,0,99999,function(v) savedJumpPower=v; if humanoid then humanoid.JumpPower=v end end)
createSlider(speedPanel,"Fly скорость:",50,0,99999,function(v) flySpeed=v end)

-- страница Визуалы
local visualsPage = createPage(); pages.Visuals = visualsPage
local visLabel = Instance.new("TextLabel")
visLabel.Size = UDim2.new(1,-16,0,24); visLabel.BackgroundTransparency = 1
visLabel.Text = "Визуалы"; visLabel.TextColor3 = Color3.fromRGB(230,230,230)
visLabel.Font = Enum.Font.GothamBold; visLabel.TextSize = 15; visLabel.Parent = visualsPage

local namesToggle = Instance.new("TextButton")
namesToggle.Size = UDim2.new(0,160,0,30); namesToggle.BackgroundColor3 = Color3.fromRGB(50,50,56)
namesToggle.Text = "Ники: Выкл"; namesToggle.TextColor3 = Color3.fromRGB(220,220,220)
namesToggle.Font = Enum.Font.Gotham; namesToggle.TextSize = 13; namesToggle.Parent = visualsPage; namesToggle.ZIndex = 10
Instance.new("UICorner",namesToggle).CornerRadius = UDim.new(0,6)
namesToggle.MouseButton1Click:Connect(function()
    espNames = not espNames
    namesToggle.Text = "Ники: "..(espNames and "Вкл" or "Выкл")
    namesToggle.BackgroundColor3 = espNames and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
    refreshESP()
end)

local boxesToggle = Instance.new("TextButton")
boxesToggle.Size = UDim2.new(0,160,0,30); boxesToggle.BackgroundColor3 = Color3.fromRGB(50,50,56)
boxesToggle.Text = "Хитбоксы: Выкл"; boxesToggle.TextColor3 = Color3.fromRGB(220,220,220)
boxesToggle.Font = Enum.Font.Gotham; boxesToggle.TextSize = 13; boxesToggle.Parent = visualsPage; boxesToggle.ZIndex = 10
Instance.new("UICorner",boxesToggle).CornerRadius = UDim.new(0,6)
boxesToggle.MouseButton1Click:Connect(function()
    espBoxes = not espBoxes
    boxesToggle.Text = "Хитбоксы: "..(espBoxes and "Вкл" or "Выкл")
    boxesToggle.BackgroundColor3 = espBoxes and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
    refreshESP()
end)

local aimbotBtn = Instance.new("TextButton")
aimbotBtn.Size = UDim2.new(0,160,0,30); aimbotBtn.BackgroundColor3 = Color3.fromRGB(50,50,56)
aimbotBtn.Text = "Аимбот: Выкл"; aimbotBtn.TextColor3 = Color3.fromRGB(220,220,220)
aimbotBtn.Font = Enum.Font.Gotham; aimbotBtn.TextSize = 13; aimbotBtn.Parent = visualsPage; aimbotBtn.ZIndex = 10
Instance.new("UICorner",aimbotBtn).CornerRadius = UDim.new(0,6)
aimbotBtn.MouseButton1Click:Connect(function()
    aimbotOn = not aimbotOn
    aimbotBtn.Text = "Аимбот: "..(aimbotOn and "Вкл" or "Выкл")
    aimbotBtn.BackgroundColor3 = aimbotOn and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
end)

-- выбор цели аимбота
local aimTarLabel = Instance.new("TextLabel")
aimTarLabel.Size = UDim2.new(1,-16,0,18); aimTarLabel.BackgroundTransparency = 1
aimTarLabel.Text = "Цель:"; aimTarLabel.TextColor3 = Color3.fromRGB(200,200,200)
aimTarLabel.Font = Enum.Font.Gotham; aimTarLabel.TextSize = 12; aimTarLabel.Parent = visualsPage
local tarDrop = Instance.new("TextButton")
tarDrop.Size = UDim2.new(0,160,0,28); tarDrop.BackgroundColor3 = Color3.fromRGB(50,50,56)
tarDrop.Text = "Все"; tarDrop.TextColor3 = Color3.fromRGB(220,220,220)
tarDrop.Font = Enum.Font.Gotham; tarDrop.TextSize = 12; tarDrop.Parent = visualsPage; tarDrop.ZIndex = 10
Instance.new("UICorner",tarDrop).CornerRadius = UDim.new(0,4)
local tarList = Instance.new("ScrollingFrame")
tarList.Size = UDim2.new(0,160,0,80); tarList.Position = UDim2.new(0,8,0,180)
tarList.BackgroundColor3 = Color3.fromRGB(40,40,46); tarList.BorderSizePixel = 0
tarList.Visible = false; tarList.ZIndex = 20; tarList.ScrollBarThickness = 3
tarList.CanvasSize = UDim2.new(0,0,0,0); tarList.AutomaticCanvasSize = Enum.AutomaticSize.Y
tarList.ElasticBehavior = Enum.ElasticBehavior.Never; tarList.ScrollingDirection = Enum.ScrollingDirection.Y
tarList.ClipsDescendants = true; tarList.Parent = visualsPage
local tarLay = Instance.new("UIListLayout")
tarLay.Padding = UDim.new(0,2); tarLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
tarLay.SortOrder = Enum.SortOrder.LayoutOrder; tarLay.Parent = tarList
local function updateTarList()
    for _,c in ipairs(tarList:GetChildren()) do if c:IsA("TextButton") then c:Remove() end end
    local allBtn = Instance.new("TextButton")
    allBtn.Size = UDim2.new(1,-8,0,22); allBtn.BackgroundColor3 = (aimTarget==nil) and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
    allBtn.Text = "Все"; allBtn.TextColor3 = Color3.new(1,1,1); allBtn.Font = Enum.Font.Gotham; allBtn.TextSize = 12
    allBtn.ZIndex = 20; allBtn.Parent = tarList
    Instance.new("UICorner",allBtn).CornerRadius = UDim.new(0,4)
    allBtn.MouseButton1Click:Connect(function()
        aimTarget = nil; tarDrop.Text = "Все"; tarList.Visible = false; updateTarList()
    end)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1,-8,0,22); b.BackgroundColor3 = (aimTarget==p) and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
            b.Text = p.Name; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.Gotham; b.TextSize = 12
            b.ZIndex = 20; b.Parent = tarList
            Instance.new("UICorner",b).CornerRadius = UDim.new(0,4)
            b.MouseButton1Click:Connect(function()
                aimTarget = p; tarDrop.Text = p.Name; tarList.Visible = false; updateTarList()
            end)
        end
    end
end
tarDrop.MouseButton1Click:Connect(function()
    tarList.Visible = not tarList.Visible
    if tarList.Visible then updateTarList() end
end)
Players.PlayerAdded:Connect(function() if tarList.Visible then updateTarList() end end)
Players.PlayerRemoving:Connect(function(p) if aimTarget==p then aimTarget=nil; tarDrop.Text="Все" end; if tarList.Visible then updateTarList() end end)
updateTarList()

-- FOV
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(1,-16,0,18); fovLabel.BackgroundTransparency = 1
fovLabel.Text = "FOV:"; fovLabel.TextColor3 = Color3.fromRGB(200,200,200)
fovLabel.Font = Enum.Font.Gotham; fovLabel.TextSize = 12; fovLabel.Parent = visualsPage
local fovRow = Instance.new("Frame")
fovRow.Size = UDim2.new(1,-16,0,28); fovRow.BackgroundTransparency = 1; fovRow.Parent = visualsPage
local fovBox = Instance.new("TextBox")
fovBox.Size = UDim2.new(0,70,1,0); fovBox.BackgroundColor3 = Color3.fromRGB(50,50,56)
fovBox.Text = "100"; fovBox.TextColor3 = Color3.new(1,1,1)
fovBox.Font = Enum.Font.Gotham; fovBox.TextSize = 12; fovBox.Parent = fovRow
local fovApply = Instance.new("TextButton")
fovApply.Size = UDim2.new(0,50,1,0); fovApply.Position = UDim2.new(0,74,0,0)
fovApply.BackgroundColor3 = Color3.fromRGB(70,70,75); fovApply.Text = "OK"
fovApply.TextColor3 = Color3.new(1,1,1); fovApply.Font = Enum.Font.Gotham; fovApply.TextSize = 12
fovApply.Parent = fovRow
fovApply.MouseButton1Click:Connect(function()
    local v = tonumber(fovBox.Text)
    if v then v = math.clamp(v,0,99999); fovBox.Text = tostring(v); fovRadius = v; if fovCircle then fovCircle.Radius = v end end
end)

-- HUE
local hueLabel = Instance.new("TextLabel")
hueLabel.Size = UDim2.new(1,-16,0,18); hueLabel.BackgroundTransparency = 1
hueLabel.Text = "Оттенок:"; hueLabel.TextColor3 = Color3.fromRGB(200,200,200)
hueLabel.Font = Enum.Font.Gotham; hueLabel.TextSize = 12; hueLabel.Parent = visualsPage
local hueFrame = Instance.new("Frame")
hueFrame.Size = UDim2.new(0,220,0,28); hueFrame.BackgroundTransparency = 1
hueFrame.Parent = visualsPage
local hueTrack = Instance.new("Frame")
hueTrack.Size = UDim2.new(0,160,0,6); hueTrack.Position = UDim2.new(0,0,0.5,-3)
hueTrack.BackgroundColor3 = Color3.fromRGB(60,60,66); hueTrack.BorderSizePixel = 0
hueTrack.Parent = hueFrame
Instance.new("UICorner",hueTrack).CornerRadius = UDim.new(0,3)
local hueKnob = Instance.new("TextButton")
hueKnob.Size = UDim2.new(0,18,0,18); hueKnob.BackgroundColor3 = Color3.new(1,1,1)
hueKnob.Text = ""; hueKnob.AutoButtonColor = false; hueKnob.Parent = hueFrame; hueKnob.ZIndex = 10
Instance.new("UICorner",hueKnob).CornerRadius = UDim.new(1,0)
local hueValLabel = Instance.new("TextLabel")
hueValLabel.Size = UDim2.new(0,40,1,0); hueValLabel.Position = UDim2.new(0,170,0,0)
hueValLabel.BackgroundTransparency = 1; hueValLabel.Text = "0"
hueValLabel.TextColor3 = Color3.new(1,1,1); hueValLabel.Font = Enum.Font.Gotham; hueValLabel.TextSize = 12
hueValLabel.Parent = hueFrame
local function updateHueKnob()
    local tw = 160
    local x = math.clamp((currentHue/360)*tw, 0, tw)
    hueKnob.Position = UDim2.new(0, x - hueKnob.Size.X.Offset/2, 0.5, -hueKnob.Size.Y.Offset/2)
    hueValLabel.Text = tostring(currentHue)
end
local hueDragging = false
hueKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        hueDragging = true
        local pos = UserInputService:GetMouseLocation()
        local relX = math.clamp(pos.X - hueTrack.AbsolutePosition.X, 0, hueTrack.AbsoluteSize.X)
        currentHue = math.floor((relX/hueTrack.AbsoluteSize.X)*360)
        updateHueKnob()
        mainFrame.BackgroundColor3 = Color3.fromHSV(currentHue/360,0.2,0.25)
        titleBar.BackgroundColor3 = Color3.fromHSV(currentHue/360,0.3,0.2)
        contentFrame.BackgroundColor3 = Color3.fromHSV(currentHue/360,0.15,0.3)
    end
end)
hueKnob.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if not hueDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local pos = input.UserInputType == Enum.UserInputType.Touch and input.Position or UserInputService:GetMouseLocation()
        local relX = math.clamp(pos.X - hueTrack.AbsolutePosition.X, 0, hueTrack.AbsoluteSize.X)
        currentHue = math.floor((relX/hueTrack.AbsoluteSize.X)*360)
        updateHueKnob()
        mainFrame.BackgroundColor3 = Color3.fromHSV(currentHue/360,0.2,0.25)
        titleBar.BackgroundColor3 = Color3.fromHSV(currentHue/360,0.3,0.2)
        contentFrame.BackgroundColor3 = Color3.fromHSV(currentHue/360,0.15,0.3)
    end
end)
updateHueKnob()

-- страница MM2
local mm2Page = createPage(); pages.MM2 = mm2Page
local mm2Label = Instance.new("TextLabel")
mm2Label.Size = UDim2.new(1,-16,0,24); mm2Label.BackgroundTransparency = 1
mm2Label.Text = "Murder Mystery 2"; mm2Label.TextColor3 = Color3.fromRGB(230,230,230)
mm2Label.Font = Enum.Font.GothamBold; mm2Label.TextSize = 15; mm2Label.Parent = mm2Page

local mm2ESPBtn = Instance.new("TextButton")
mm2ESPBtn.Size = UDim2.new(0,160,0,30); mm2ESPBtn.BackgroundColor3 = Color3.fromRGB(123,97,255)
mm2ESPBtn.Text = "ESP: Вкл"; mm2ESPBtn.TextColor3 = Color3.fromRGB(220,220,220)
mm2ESPBtn.Font = Enum.Font.GothamBold; mm2ESPBtn.TextSize = 13; mm2ESPBtn.Parent = mm2Page; mm2ESPBtn.ZIndex = 10
Instance.new("UICorner",mm2ESPBtn).CornerRadius = UDim.new(0,6)
mm2ESPBtn.MouseButton1Click:Connect(function()
    MM2.ESP = not MM2.ESP
    mm2ESPBtn.Text = "ESP: "..(MM2.ESP and "Вкл" or "Выкл")
    mm2ESPBtn.BackgroundColor3 = MM2.ESP and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
end)

local mm2AimbotBtn = Instance.new("TextButton")
mm2AimbotBtn.Size = UDim2.new(0,160,0,30); mm2AimbotBtn.BackgroundColor3 = Color3.fromRGB(123,97,255)
mm2AimbotBtn.Text = "Аимбот: Вкл"; mm2AimbotBtn.TextColor3 = Color3.fromRGB(220,220,220)
mm2AimbotBtn.Font = Enum.Font.GothamBold; mm2AimbotBtn.TextSize = 13; mm2AimbotBtn.Parent = mm2Page; mm2AimbotBtn.ZIndex = 10
Instance.new("UICorner",mm2AimbotBtn).CornerRadius = UDim.new(0,6)
mm2AimbotBtn.MouseButton1Click:Connect(function()
    MM2.Aimbot = not MM2.Aimbot
    mm2AimbotBtn.Text = "Аимбот: "..(MM2.Aimbot and "Вкл" or "Выкл")
    mm2AimbotBtn.BackgroundColor3 = MM2.Aimbot and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
end)

-- плавающие кнопки
local floatGui = Instance.new("ScreenGui")
floatGui.Name = "MM2Float"; floatGui.ResetOnSpawn = false; floatGui.Parent = playerGui
local shootBtn = Instance.new("TextButton")
shootBtn.Size = UDim2.new(0,70,0,70); shootBtn.Position = UDim2.new(0.8,0,0.7,0)
shootBtn.BackgroundColor3 = Color3.fromRGB(255,80,80); shootBtn.Text = "SHOOT"
shootBtn.TextColor3 = Color3.new(1,1,1); shootBtn.Font = Enum.Font.GothamBold; shootBtn.TextSize = 16
shootBtn.Visible = false; shootBtn.Parent = floatGui; shootBtn.ZIndex = 20
Instance.new("UICorner",shootBtn).CornerRadius = UDim.new(1,0)
local knifeBtn = Instance.new("TextButton")
knifeBtn.Size = UDim2.new(0,70,0,70); knifeBtn.Position = UDim2.new(0.2,0,0.7,0)
knifeBtn.BackgroundColor3 = Color3.fromRGB(80,80,255); knifeBtn.Text = "KNIFE"
knifeBtn.TextColor3 = Color3.new(1,1,1); knifeBtn.Font = Enum.Font.GothamBold; knifeBtn.TextSize = 16
knifeBtn.Visible = false; knifeBtn.Parent = floatGui; knifeBtn.ZIndex = 20
Instance.new("UICorner",knifeBtn).CornerRadius = UDim.new(1,0)

local function makeDraggable(btn)
    local drag, start, btnStart
    btn.InputBegan:Connect(function(input)
        if MM2.Freeze then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = true; start = UserInputService:GetMouseLocation(); btnStart = btn.AbsolutePosition
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not drag then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = UserInputService:GetMouseLocation() - start
            local newPos = btnStart + delta
            local screen = workspace.CurrentCamera.ViewportSize
            local bs = btn.AbsoluteSize
            newPos = Vector2.new(math.clamp(newPos.X,0,screen.X-bs.X), math.clamp(newPos.Y,0,screen.Y-bs.Y))
            btn.Position = UDim2.new(0,newPos.X,0,newPos.Y)
        end
    end)
end
makeDraggable(shootBtn); makeDraggable(knifeBtn)

local function shootFunc()
    if not player.Character then return end
    local gun = player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun")
    if not gun then return end
    if not player.Character:FindFirstChild("Gun") then player.Character.Humanoid:EquipTool(player.Backpack["Gun"]); task.wait(0.1) end
    local enemy = getClosestMM2()
    if enemy then smoothAimMM2(enemy); task.wait(0.05) end
    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0); task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0)
end
shootBtn.MouseButton1Click:Connect(shootFunc)

local function knifeFunc()
    if not player.Character then return end
    local knife = player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife")
    if not knife then return end
    if not player.Character:FindFirstChild("Knife") then player.Character.Humanoid:EquipTool(player.Backpack["Knife"]); task.wait(0.1) end
    local enemy = getClosestMM2()
    if enemy then smoothAimMM2(enemy); task.wait(0.05) end
    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0); task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0)
end
knifeBtn.MouseButton1Click:Connect(knifeFunc)

local shootToggle = Instance.new("TextButton")
shootToggle.Size = UDim2.new(0,160,0,30); shootToggle.BackgroundColor3 = Color3.fromRGB(50,50,56)
shootToggle.Text = "Выстрел: Выкл"; shootToggle.TextColor3 = Color3.fromRGB(220,220,220)
shootToggle.Font = Enum.Font.GothamBold; shootToggle.TextSize = 13; shootToggle.Parent = mm2Page; shootToggle.ZIndex = 10
Instance.new("UICorner",shootToggle).CornerRadius = UDim.new(0,6)
shootToggle.MouseButton1Click:Connect(function()
    MM2.ShootBtn = not MM2.ShootBtn
    shootToggle.Text = "Выстрел: "..(MM2.ShootBtn and "Вкл" or "Выкл")
    shootToggle.BackgroundColor3 = MM2.ShootBtn and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
    shootBtn.Visible = MM2.ShootBtn
end)

local knifeToggle = Instance.new("TextButton")
knifeToggle.Size = UDim2.new(0,160,0,30); knifeToggle.BackgroundColor3 = Color3.fromRGB(50,50,56)
knifeToggle.Text = "Бросок ножа: Выкл"; knifeToggle.TextColor3 = Color3.fromRGB(220,220,220)
knifeToggle.Font = Enum.Font.GothamBold; knifeToggle.TextSize = 13; knifeToggle.Parent = mm2Page; knifeToggle.ZIndex = 10
Instance.new("UICorner",knifeToggle).CornerRadius = UDim.new(0,6)
knifeToggle.MouseButton1Click:Connect(function()
    MM2.KnifeBtn = not MM2.KnifeBtn
    knifeToggle.Text = "Бросок ножа: "..(MM2.KnifeBtn and "Вкл" or "Выкл")
    knifeToggle.BackgroundColor3 = MM2.KnifeBtn and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
    knifeBtn.Visible = MM2.KnifeBtn
end)

local autoPickBtn = Instance.new("TextButton")
autoPickBtn.Size = UDim2.new(0,160,0,30); autoPickBtn.BackgroundColor3 = Color3.fromRGB(50,50,56)
autoPickBtn.Text = "Автоподбор: Выкл"; autoPickBtn.TextColor3 = Color3.fromRGB(220,220,220)
autoPickBtn.Font = Enum.Font.GothamBold; autoPickBtn.TextSize = 13; autoPickBtn.Parent = mm2Page; autoPickBtn.ZIndex = 10
Instance.new("UICorner",autoPickBtn).CornerRadius = UDim.new(0,6)
autoPickBtn.MouseButton1Click:Connect(function()
    MM2.AutoPick = not MM2.AutoPick
    autoPickBtn.Text = "Автоподбор: "..(MM2.AutoPick and "Вкл" or "Выкл")
    autoPickBtn.BackgroundColor3 = MM2.AutoPick and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
end)

local freezeBtn = Instance.new("TextButton")
freezeBtn.Size = UDim2.new(0,160,0,30); freezeBtn.BackgroundColor3 = Color3.fromRGB(50,50,56)
freezeBtn.Text = "Заморозка: Выкл"; freezeBtn.TextColor3 = Color3.fromRGB(220,220,220)
freezeBtn.Font = Enum.Font.GothamBold; freezeBtn.TextSize = 13; freezeBtn.Parent = mm2Page; freezeBtn.ZIndex = 10
Instance.new("UICorner",freezeBtn).CornerRadius = UDim.new(0,6)
freezeBtn.MouseButton1Click:Connect(function()
    MM2.Freeze = not MM2.Freeze
    freezeBtn.Text = "Заморозка: "..(MM2.Freeze and "Вкл" or "Выкл")
    freezeBtn.BackgroundColor3 = MM2.Freeze and Color3.fromRGB(123,97,255) or Color3.fromRGB(50,50,56)
end)

-- === СОЗДАНИЕ ВКЛАДОК ===
local infoTab = Instance.new("TextButton")
infoTab.Name = "InfoTab"; infoTab.Size = UDim2.new(0,80,1,0)
infoTab.BackgroundColor3 = Color3.fromRGB(123,97,255); infoTab.Text = "Инфо"
infoTab.TextColor3 = Color3.fromRGB(200,200,200); infoTab.Font = Enum.Font.GothamMedium; infoTab.TextSize = 13
infoTab.Parent = tabBar; infoTab.ZIndex = 30
Instance.new("UICorner",infoTab).CornerRadius = UDim.new(0,8)
local settingsTab = Instance.new("TextButton")
settingsTab.Name = "SettingsTab"; settingsTab.Size = UDim2.new(0,80,1,0)
settingsTab.BackgroundColor3 = Color3.fromRGB(40,40,46); settingsTab.Text = "Настр."
settingsTab.TextColor3 = Color3.fromRGB(200,200,200); settingsTab.Font = Enum.Font.GothamMedium; settingsTab.TextSize = 13
settingsTab.Parent = tabBar; settingsTab.ZIndex = 30
Instance.new("UICorner",settingsTab).CornerRadius = UDim.new(0,8)
local animsTab = Instance.new("TextButton")
animsTab.Name = "AnimationsTab"; animsTab.Size = UDim2.new(0,80,1,0)
animsTab.BackgroundColor3 = Color3.fromRGB(40,40,46); animsTab.Text = "Анимки"
animsTab.TextColor3 = Color3.fromRGB(200,200,200); animsTab.Font = Enum.Font.GothamMedium; animsTab.TextSize = 13
animsTab.Parent = tabBar; animsTab.ZIndex = 30
Instance.new("UICorner",animsTab).CornerRadius = UDim.new(0,8)
local playerTab = Instance.new("TextButton")
playerTab.Name = "PlayerTab"; playerTab.Size = UDim2.new(0,80,1,0)
playerTab.BackgroundColor3 = Color3.fromRGB(40,40,46); playerTab.Text = "Игрок"
playerTab.TextColor3 = Color3.fromRGB(200,200,200); playerTab.Font = Enum.Font.GothamMedium; playerTab.TextSize = 13
playerTab.Parent = tabBar; playerTab.ZIndex = 30
Instance.new("UICorner",playerTab).CornerRadius = UDim.new(0,8)
local visualsTab = Instance.new("TextButton")
visualsTab.Name = "VisualsTab"; visualsTab.Size = UDim2.new(0,80,1,0)
visualsTab.BackgroundColor3 = Color3.fromRGB(40,40,46); visualsTab.Text = "Визуалы"
visualsTab.TextColor3 = Color3.fromRGB(200,200,200); visualsTab.Font = Enum.Font.GothamMedium; visualsTab.TextSize = 13
visualsTab.Parent = tabBar; visualsTab.ZIndex = 30
Instance.new("UICorner",visualsTab).CornerRadius = UDim.new(0,8)
local mm2Tab = Instance.new("TextButton")
mm2Tab.Name = "MM2Tab"; mm2Tab.Size = UDim2.new(0,80,1,0)
mm2Tab.BackgroundColor3 = Color3.fromRGB(40,40,46); mm2Tab.Text = "MM2"
mm2Tab.TextColor3 = Color3.fromRGB(200,200,200); mm2Tab.Font = Enum.Font.GothamMedium; mm2Tab.TextSize = 13
mm2Tab.Parent = tabBar; mm2Tab.ZIndex = 30
Instance.new("UICorner",mm2Tab).CornerRadius = UDim.new(0,8)

local tabBtns = {infoTab, settingsTab, animsTab, playerTab, visualsTab, mm2Tab}
local function resizeTabs()
    local w = mainFrame.AbsoluteSize.X - 16
    if w<=0 then return end
    local tabW = math.max(60, (w - (#tabBtns-1)*4)/#tabBtns)
    for _,b in ipairs(tabBtns) do b.Size = UDim2.new(0,tabW,1,0) end
end
mainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeTabs)
resizeTabs()

local function selectTab(name)
    pages.Info.Visible = (name=="Info")
    pages.Settings.Visible = (name=="Settings")
    pages.Animations.Visible = (name=="Animations")
    pages.Player.Visible = (name=="Player")
    pages.Visuals.Visible = (name=="Visuals")
    pages.MM2.Visible = (name=="MM2")
    for _,b in ipairs(tabBtns) do
        b.BackgroundColor3 = (b.Name==name.."Tab") and Color3.fromRGB(123,97,255) or Color3.fromRGB(40,40,46)
    end
end
infoTab.MouseButton1Click:Connect(function() selectTab("Info") end)
settingsTab.MouseButton1Click:Connect(function() selectTab("Settings") end)
animsTab.MouseButton1Click:Connect(function() selectTab("Animations") end)
playerTab.MouseButton1Click:Connect(function() selectTab("Player") end)
visualsTab.MouseButton1Click:Connect(function() selectTab("Visuals") end)
mm2Tab.MouseButton1Click:Connect(function() selectTab("MM2") end)
selectTab("Info")

-- === ФУНКЦИЯ СБРОСА (теперь все кнопки определены) ===
local function resetAll()
    if flying then stopFly(); flyBtn.Text="Fly: Выкл"; flyBtn.BackgroundColor3=Color3.fromRGB(50,50,56) end
    if noclipEnabled then noclipEnabled=false; disableNoclip(); noclipBtn.Text="Noclip: Выкл"; noclipBtn.BackgroundColor3=Color3.fromRGB(50,50,56) end
    if invisEnabled then invisEnabled=false; applyInvis(false); invisBtn.Text="Невидимка: Выкл"; invisBtn.BackgroundColor3=Color3.fromRGB(50,50,56) end
    if flingEnabled then flingEnabled=false; disableFling(); flingBtn.Text="Fling: Выкл"; flingBtn.BackgroundColor3=Color3.fromRGB(50,50,56) end
    if espNames then espNames=false; namesToggle.Text="Ники: Выкл"; namesToggle.BackgroundColor3=Color3.fromRGB(50,50,56) end
    if espBoxes then espBoxes=false; boxesToggle.Text="Хитбоксы: Выкл"; boxesToggle.BackgroundColor3=Color3.fromRGB(50,50,56) end
    clearAllESP()
    if aimbotOn then aimbotOn=false; aimbotBtn.Text="Аимбот: Выкл"; aimbotBtn.BackgroundColor3=Color3.fromRGB(50,50,56) end
    savedWalkSpeed=16; savedJumpPower=50; flySpeed=50
    if humanoid then humanoid.WalkSpeed=16; humanoid.JumpPower=50 end
    teleportTarget=nil; tpDrop.Text="Выбрать"
    currentHue=0; updateHueKnob()
    mainFrame.BackgroundColor3 = Color3.fromHSV(0,0.2,0.25)
    titleBar.BackgroundColor3 = Color3.fromHSV(0,0.3,0.2)
    contentFrame.BackgroundColor3 = Color3.fromHSV(0,0.15,0.3)
    fovRadius=100; if fovCircle then fovCircle.Radius=100 end; fovBox.Text="100"
    refreshESP()
    MM2.Aimbot=false; mm2AimbotBtn.Text="Аимбот: Выкл"; mm2AimbotBtn.BackgroundColor3=Color3.fromRGB(50,50,56)
    MM2.ESP=false; mm2ESPBtn.Text="ESP: Выкл"; mm2ESPBtn.BackgroundColor3=Color3.fromRGB(50,50,56)
    if MM2.ShootBtn then MM2.ShootBtn=false; shootToggle.Text="Выстрел: Выкл"; shootToggle.BackgroundColor3=Color3.fromRGB(50,50,56); shootBtn.Visible=false end
    if MM2.KnifeBtn then MM2.KnifeBtn=false; knifeToggle.Text="Бросок ножа: Выкл"; knifeToggle.BackgroundColor3=Color3.fromRGB(50,50,56); knifeBtn.Visible=false end
    if MM2.AutoPick then MM2.AutoPick=false; autoPickBtn.Text="Автоподбор: Выкл"; autoPickBtn.BackgroundColor3=Color3.fromRGB(50,50,56) end
    for _,d in pairs(mm2ESP) do d.Gui:Destroy() end; mm2ESP = {}
end
resetBtn.MouseButton1Click:Connect(resetAll)

-- === СОБЫТИЯ ===
player.CharacterAdded:Connect(function()
    updateChar()
    task.wait(0.5)
    if humanoid then humanoid.WalkSpeed = savedWalkSpeed; humanoid.JumpPower = savedJumpPower end
    if noclipEnabled then enableNoclip() end
    if invisEnabled then applyInvis(true) end
    if flingEnabled then setupFling(character) end
    if flying then stopFly(); flyBtn.Text="Fly: Выкл"; flyBtn.BackgroundColor3=Color3.fromRGB(50,50,56) end
    shootBtn.Visible = MM2.ShootBtn
    knifeBtn.Visible = MM2.KnifeBtn
    refreshESP()
end)
Players.PlayerAdded:Connect(function(p) if (espNames or espBoxes) and DrawingAvailable then createESP(p) end end)
Players.PlayerRemoving:Connect(function(p) clearESP(p); if mm2ESP[p] then mm2ESP[p].Gui:Destroy(); mm2ESP[p]=nil end end)

updateChar()
if humanoid then humanoid.WalkSpeed=16; humanoid.JumpPower=50 end

-- === ЦИКЛЫ ===
RunService.RenderStepped:Connect(function()
    if flying then
        updateChar()
        if rootPart and bodyVelocity and bodyGyro then
            local cam = workspace.CurrentCamera
            if cam then
                local dir = Vector3.zero
                if humanoid and humanoid.MoveDirection.Magnitude>0.1 then
                    local fwd = cam.CFrame.LookVector; local right = cam.CFrame.RightVector
                    local joy = humanoid.MoveDirection
                    dir = (fwd*joy:Dot(fwd) + right*joy:Dot(right))
                    if dir.Magnitude>0.1 then dir = dir.Unit else dir = Vector3.zero end
                end
                bodyVelocity.Velocity = dir*flySpeed
                if dir.Magnitude>0.1 then bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position+dir) end
            end
        end
    end
    if espNames or espBoxes then updateESP() end
    updateAimbot()
    if MM2.ESP then updateMM2ESP()
    else if next(mm2ESP) then for _,d in pairs(mm2ESP) do d.Gui:Destroy() end; mm2ESP = {} end end
    if MM2.Aimbot and player.Character then
        local enemy = getClosestMM2()
        if enemy then
            smoothAimMM2(enemy)
            local now = tick()
            if now - lastAttack >= 0.6 then autoAttack(enemy); lastAttack = now end
        end
    end
end)

-- авто-подбор пистолета
task.spawn(function()
    while task.wait(0.3) do
        if not MM2.AutoPick then continue end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then continue end
        local root = player.Character.HumanoidRootPart
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj.Name=="Gun" and obj.Parent~=player.Character and obj.Parent~=player.Backpack then
                if (root.Position-obj.Position).Magnitude<15 then obj.Parent=player.Backpack break end
            end
        end
    end
end)

-- радуга заголовка
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt*120)%360
    titleLabel.TextColor3 = Color3.fromHSV(hue/360,1,1)
end)

print("RAHMAT Menu v7.3 — Полностью рабочий! Вкладки, сворачивание, все функции.")
