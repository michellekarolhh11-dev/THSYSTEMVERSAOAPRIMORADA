-- [[ TH SYSTEM V4.5 - SINTONIA RP ULTRA EDITION ]] --
-- DEVELOPER: TH SYSTEM PRODUTOR -- TH MODZ PROGRAMADOR

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ CONFIGURAÇÃO FIREBASE ]] --
local DB_URL = "https://th-system-database-default-rtdb.firebaseio.com/"

local TargetGui = (RunService:IsStudio() or not pcall(function() return game:GetService("CoreGui") end)) and LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")

if TargetGui:FindFirstChild("TH_SYSTEM_V45") then TargetGui.TH_SYSTEM_V45:Destroy() end
local ScreenGui = Instance.new("ScreenGui", TargetGui); ScreenGui.Name = "TH_SYSTEM_V45"; ScreenGui.ResetOnSpawn = false

-- [[ VARIÁVEIS DE SEGURANÇA ]] --
local IsAuthenticated = false
local AntiLeakTriggered = false

-- [[ VARIÁVEIS DE CONTROLE ]] --
local AimActive, AimFOV = false, 150
local SilentAimActive = false
local FlyActive, FlySpeed = false, 50 
local KillAuraActive, KillAuraDist = false, 20
local PuxarItens = false
local GodModeActive = false
local FarmLixeiroActive = false
local AutoStatusActive = false
local TrollCarActive = false
local SpeedCarActive = false
local SpeedCarValue = 100
local MagnetActive = false
local IpSpoofActive = false
local SuperSilentActive = false

-- NOVAS VARIÁVEIS APELONAS
local TriggerBotActive = false
local WallshotActive = false
local LookAtLineActive = false

-- VARIÁVEIS DE ESP
local EspBox, EspLine, EspName, EspHealth, EspDist, EspWeapon = false, false, false, false, false, false

-- [[ FOV CIRCLE ]] --
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.Color = Color3.fromRGB(130, 0, 255); FOVCircle.Transparency = 0.7; FOVCircle.Visible = false

-- [[ FUNÇÃO DE MONITORAMENTO (AUTO-KICK) ]] --
local function StartAutoKick(username)
    task.spawn(function()
        while task.wait(5) do
            if IsAuthenticated then
                local s, res = pcall(function()
                    return game:HttpGet(DB_URL .. "users/" .. username .. ".json")
                end)
                if s and res == "null" then
                    LocalPlayer:Kick("\n[TH SYSTEM SECURITY]\n\nSeu acesso foi revogado pelo Administrador.\nStatus: BANIDO / KEY REMOVIDA")
                    break
                end
            end
        end
    end)
end

-- [[ FUNÇÕES DE SUPORTE ]] --
local function GetClosestPlayer()
    local target, dist = nil, AimFOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
            local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
            if mag < dist then target = p; dist = mag end
        end
    end
    return target
end

local function SafeTeleportItem(targetPos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0)) end
end

-- [[ SISTEMA ANTI-ROUBO ]] --
task.spawn(function()
    while task.wait(2) do
        if not IsAuthenticated and not ScreenGui:FindFirstChild("Login") and not ScreenGui:FindFirstChild("Frame") then
            AntiLeakTriggered = true
            ScreenGui:Destroy()
            LocalPlayer:Kick("TH SYSTEM: Segurança Detectada")
            break
        end
    end
end)

-- [[ TELA DE LOGIN ]] --
local Login = Instance.new("Frame", ScreenGui); Login.Name = "Login"; Login.Size = UDim2.new(0, 260, 0, 310); Login.Position = UDim2.new(0.5, -130, 0.5, -155); Login.BackgroundColor3 = Color3.fromRGB(10, 10, 10); Instance.new("UICorner", Login); Instance.new("UIStroke", Login).Color = Color3.fromRGB(130, 0, 255)
local L_TH = Instance.new("TextLabel", Login); L_TH.Size = UDim2.new(1,0,0,40); L_TH.Position = UDim2.new(0,0,0,20); L_TH.Text = "TH"; L_TH.TextColor3 = Color3.fromRGB(130, 0, 255); L_TH.Font = "GothamBold"; L_TH.TextSize = 35; L_TH.BackgroundTransparency = 1
local L_SYS = Instance.new("TextLabel", L_TH); L_SYS.Size = UDim2.new(1,0,0,20); L_SYS.Position = UDim2.new(0,0,1,-10); L_SYS.Text = "SYSTEM"; L_SYS.TextColor3 = Color3.new(1,1,1); L_SYS.Font = "GothamBold"; L_SYS.TextSize = 14; L_SYS.BackgroundTransparency = 1
local UserIn = Instance.new("TextBox", Login); UserIn.Size = UDim2.new(0, 200, 0, 45); UserIn.Position = UDim2.new(0.5, -100, 0.4, 10); UserIn.PlaceholderText = "NICK"; UserIn.BackgroundColor3 = Color3.fromRGB(20,20,20); UserIn.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", UserIn)
local KeyIn = Instance.new("TextBox", Login); KeyIn.Size = UDim2.new(0, 200, 0, 45); KeyIn.Position = UDim2.new(0.5, -100, 0.6, 15); KeyIn.PlaceholderText = "KEY"; KeyIn.BackgroundColor3 = Color3.fromRGB(20,20,20); KeyIn.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", KeyIn)
local LogBtn = Instance.new("TextButton", Login); LogBtn.Size = UDim2.new(0, 200, 0, 40); LogBtn.Position = UDim2.new(0.5, -100, 0.8, 15); LogBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255); LogBtn.Text = "ENTRAR NO SISTEMA"; LogBtn.TextColor3 = Color3.new(1,1,1); LogBtn.Font = "GothamBold"; Instance.new("UICorner", LogBtn)

-- [[ TELA DE INFO KEY ]] --
local InfoKey = Instance.new("Frame", ScreenGui); InfoKey.Size = UDim2.new(0, 240, 0, 180); InfoKey.Position = UDim2.new(0.5, -120, 0.5, -90); InfoKey.BackgroundColor3 = Color3.fromRGB(10, 10, 10); InfoKey.Visible = false; Instance.new("UICorner", InfoKey); Instance.new("UIStroke", InfoKey).Color = Color3.fromRGB(130, 0, 255)
local InfoTitle = Instance.new("TextLabel", InfoKey); InfoTitle.Size = UDim2.new(1, 0, 0, 30); InfoTitle.Text = "STATUS DA KEY"; InfoTitle.TextColor3 = Color3.fromRGB(130, 0, 255); InfoTitle.Font = "GothamBold"; InfoTitle.BackgroundTransparency = 1
local InfoUser = Instance.new("TextLabel", InfoKey); InfoUser.Size = UDim2.new(1, 0, 0, 20); InfoUser.Position = UDim2.new(0,0,0,40); InfoUser.Text = "USER: --"; InfoUser.TextColor3 = Color3.new(1,1,1); InfoUser.Font = "Gotham"; InfoUser.BackgroundTransparency = 1
local InfoDays = Instance.new("TextLabel", InfoKey); InfoDays.Size = UDim2.new(1, 0, 0, 20); InfoDays.Position = UDim2.new(0,0,0,65); InfoDays.Text = "DIAS: --"; InfoDays.TextColor3 = Color3.new(1,1,1); InfoDays.Font = "Gotham"; InfoDays.BackgroundTransparency = 1
local InfoPlan = Instance.new("TextLabel", InfoKey); InfoPlan.Size = UDim2.new(1, 0, 0, 20); InfoPlan.Position = UDim2.new(0,0,0,90); InfoPlan.Text = "PLANO: PREMIUM"; InfoPlan.TextColor3 = Color3.fromRGB(0, 255, 0); InfoPlan.Font = "GothamBold"; InfoPlan.BackgroundTransparency = 1
local StartBtn = Instance.new("TextButton", InfoKey); StartBtn.Size = UDim2.new(0, 180, 0, 35); StartBtn.Position = UDim2.new(0.5, -90, 0.75, 5); StartBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255); StartBtn.Text = "INICIAR SCRIPT"; StartBtn.TextColor3 = Color3.new(1,1,1); StartBtn.Font = "GothamBold"; Instance.new("UICorner", StartBtn)

-- [[ MENU PRINCIPAL ]] --
local Main = Instance.new("Frame", ScreenGui); Main.Name = "Frame"; Main.Size = UDim2.new(0, 220, 0, 450); Main.Position = UDim2.new(0.5, -110, 0.5, -225); Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12); Main.Visible = false; Instance.new("UICorner", Main); Instance.new("UIStroke", Main).Color = Color3.fromRGB(130, 0, 255)
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 40); Title.Position = UDim2.new(0, 0, 0, 10); Title.Text = "TH SYSTEM V4.5"; Title.TextColor3 = Color3.fromRGB(130, 0, 255); Title.Font = "GothamBold"; Title.TextSize = 16; Title.BackgroundTransparency = 1
local CloseBtn = Instance.new("TextButton", Main); CloseBtn.Size = UDim2.new(1, -20, 0, 35); CloseBtn.Position = UDim2.new(0, 10, 1, -45); CloseBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255); CloseBtn.Text = "FECHAR"; CloseBtn.TextColor3 = Color3.new(1, 1, 1); CloseBtn.Font = "GothamBold"; Instance.new("UICorner", CloseBtn)
local OpenBtn = Instance.new("TextButton", ScreenGui); OpenBtn.Size = UDim2.new(0, 45, 0, 45); OpenBtn.Position = UDim2.new(0, 10, 0.5, -22); OpenBtn.BackgroundColor3 = Color3.fromRGB(12, 12, 12); OpenBtn.Text = "TH"; OpenBtn.TextColor3 = Color3.fromRGB(130, 0, 255); OpenBtn.Font = "GothamBold"; OpenBtn.Visible = false; Instance.new("UICorner", OpenBtn); Instance.new("UIStroke", OpenBtn).Color = Color3.fromRGB(130, 0, 255)
local Container = Instance.new("ScrollingFrame", Main); Container.Size = UDim2.new(1, -20, 1, -110); Container.Position = UDim2.new(0, 10, 0, 50); Container.BackgroundTransparency = 1; Container.ScrollBarThickness = 2; local curY = 0

-- [[ COMPONENTES ]] --
local function AddLabel(txt)
    local b = Instance.new("TextLabel", Container); b.Size = UDim2.new(1, 0, 0, 25); b.Position = UDim2.new(0,0,0,curY); b.BackgroundColor3 = Color3.fromRGB(130, 0, 255); b.Text = txt; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamBold"; b.TextSize = 11; Instance.new("UICorner", b); curY = curY + 30
end
local function AddToggle(name, callback)
    local f = Instance.new("Frame", Container); f.Size = UDim2.new(1, 0, 0, 25); f.Position = UDim2.new(0,0,0,curY); f.BackgroundTransparency = 1
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(0.7, 0, 1, 0); t.Text = name; t.TextColor3 = Color3.new(1,1,1); t.Font = "Gotham"; t.TextSize = 11; t.TextXAlignment = "Left"; t.BackgroundTransparency = 1
    local bg = Instance.new("Frame", f); bg.Size = UDim2.new(0, 32, 0, 16); bg.Position = UDim2.new(1, -32, 0.5, -8); bg.BackgroundColor3 = Color3.fromRGB(45,45,45); Instance.new("UICorner", bg)
    local act = false; local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseButton1Click:Connect(function() act = not act; bg.BackgroundColor3 = act and Color3.fromRGB(130, 0, 255) or Color3.fromRGB(45,45,45); callback(act) end); curY = curY + 28
end
local function AddButton(name, callback)
    local btn = Instance.new("TextButton", Container); btn.Size = UDim2.new(1, 0, 0, 25); btn.Position = UDim2.new(0, 0, 0, curY); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); btn.Text = name; btn.TextColor3 = Color3.new(1, 1, 1); btn.Font = "Gotham"; btn.TextSize = 11; Instance.new("UICorner", btn); btn.MouseButton1Click:Connect(callback); curY = curY + 30
end
local function AddSlider(name, min, max, callback)
    local f = Instance.new("Frame", Container); f.Size = UDim2.new(1, 0, 0, 40); f.Position = UDim2.new(0,0,0,curY); f.BackgroundTransparency = 1
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, 0, 0, 15); t.Text = name; t.TextColor3 = Color3.new(1,1,1); t.Font = "Gotham"; t.TextSize = 10; t.BackgroundTransparency = 1
    local s_bg = Instance.new("Frame", f); s_bg.Size = UDim2.new(1, 0, 0, 4); s_bg.Position = UDim2.new(0, 0, 0.7, 0); s_bg.BackgroundColor3 = Color3.fromRGB(45,45,45); Instance.new("UICorner", s_bg)
    local fill = Instance.new("Frame", s_bg); fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(130, 0, 255); Instance.new("UICorner", fill)
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then local con; con = RunService.RenderStepped:Connect(function() local p = math.clamp((UIS:GetMouseLocation().X - s_bg.AbsolutePosition.X) / s_bg.AbsoluteSize.X, 0, 1); fill.Size = UDim2.new(p,0,1,0); callback(math.floor(min + (max - min) * p)) end); UIS.InputEnded:Connect(function() con:Disconnect() end) end end); curY = curY + 45
end

-- [[ MONTAGEM DAS ABAS ]] --
AddLabel("FUNÇÕES APELONAS")
AddToggle("TRIGGER BOT (AUTO-SHOT)", function(v) TriggerBotActive = v end)
AddToggle("WALLSHOT (BYPASS)", function(v) WallshotActive = v end)
AddToggle("LOOK-AT LINE (DIREÇÃO)", function(v) LookAtLineActive = v end)
AddToggle("SUPER SILENT AIM (BYPASS)", function(v) SuperSilentActive = v end)
AddToggle("MAGNET PLAYER (MIRAR)", function(v) MagnetActive = v end)
AddToggle("GOD MODE APELÃO", function(v) GodModeActive = v end)
AddToggle("IP/HWID SPOOFER", function(v) IpSpoofActive = v end)
AddButton("TP ITENS DROPADOS (SAFE)", function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Tool") and v.Parent == workspace then 
            local h = v:FindFirstChild("Handle") or v:FindFirstChildOfClass("Part")
            if h then SafeTeleportItem(h.Position) end
        end
    end
end)

AddLabel("AIM COMBATE")
AddToggle("ATIVAR AIMBOT", function(v) AimActive = v end)
AddToggle("SILENT AIM", function(v) SilentAimActive = v end)
AddToggle("MOSTRAR FOV", function(v) FOVCircle.Visible = v end)
AddSlider("FOV RAIO", 30, 600, function(v) AimFOV = v end)
AddToggle("KILL AURA", function(v) KillAuraActive = v end)

AddLabel("AUTO & FARM")
AddToggle("AUTO STATUS (MAX)", function(v) AutoStatusActive = v end)

AddLabel("MOVIMENT & UTILS")
AddToggle("FLY ANTI-KICK (V2)", function(v) FlyActive = v end)
AddSlider("VELOCIDADE FLY", 10, 300, function(v) FlySpeed = v end)
AddToggle("MAGNET GERAL (ITEMS)", function(v) PuxarItens = v end)

AddLabel("TP VEÍCULO EM TESTE")
AddButton("TELEPORTAR PARA MARCAÇÃO", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local seat = char.Humanoid.SeatPart
        local car = seat and seat.Parent
        if car and car:IsA("Model") then
            local targetPos = nil
            local wp = LocalPlayer.PlayerGui:FindFirstChild("Waypoint", true)
            if wp and wp:IsA("BasePart") then targetPos = wp.Position end
            if not targetPos then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BillboardGui") and v.Name == "Marcação" then
                        if v.Parent and v.Parent:IsA("BasePart") then targetPos = v.Parent.Position; break end
                    end
                end
            end
            if targetPos then car:MoveTo(targetPos + Vector3.new(0, 10, 0)) end
        end
    end
end)

AddLabel("TROLL")
AddToggle("SPEED CAR (CONTROLÁVEL)", function(v) SpeedCarActive = v end)
AddSlider("VELOCIDADE EXTRA", 50, 500, function(v) SpeedCarValue = v end)
AddToggle("ARREMESSO AO SAIR", function(v) TrollCarActive = v end)

AddLabel("VISUAIS (ESP)")
AddToggle("ESP CAIXA", function(v) EspBox = v end)
AddToggle("ESP LINHA", function(v) EspLine = v end)
AddToggle("ESP NOME", function(v) EspName = v end)
AddToggle("ESP VIDA", function(v) EspHealth = v end)
AddToggle("ESP DISTANCIA", function(v) EspDist = v end)
AddToggle("ESP ARMA", function(v) EspWeapon = v end)

-- [[ LÓGICA DAS NOVAS FUNÇÕES ]] --

-- LOOK-AT LINE (DIREÇÃO DO INIMIGO)
local function CreateLookLine(plr)
    local Line = Drawing.new("Line"); Line.Thickness = 1.5; Line.Color = Color3.fromRGB(255, 0, 0); Line.Visible = false
    RunService.RenderStepped:Connect(function()
        if LookAtLineActive and plr.Character and plr.Character:FindFirstChild("Head") and plr ~= LocalPlayer then
            local Head = plr.Character.Head
            local StartPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
            local EndPos, OnScreen2 = Camera:WorldToViewportPoint(Head.Position + (Head.CFrame.LookVector * 10))
            if OnScreen and OnScreen2 then
                Line.Visible = true; Line.From = Vector2.new(StartPos.X, StartPos.Y); Line.To = Vector2.new(EndPos.X, EndPos.Y)
            else Line.Visible = false end
        else Line.Visible = false end
    end)
end

-- WALLSHOT (SHOOT THROUGH WALLS)
RunService.Stepped:Connect(function()
    if WallshotActive then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(game.Players.LocalPlayer.Character) then
                v.CanQuery = false -- Faz as balas ignorarem a colisão
            end
        end
    end
end)

-- TRIGGER BOT
task.spawn(function()
    while task.wait() do
        if TriggerBotActive then
            local mousePos = UIS:GetMouseLocation()
            local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
            
            local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
            if result and result.Instance and result.Instance.Parent:FindFirstChild("Humanoid") then
                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
        end
    end
end)

-- [[ LÓGICA FLY CORRIGIDA ]] --
RunService.RenderStepped:Connect(function()
    if FlyActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local move = Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
        root.Velocity = Vector3.new(0,0,0) 
        if move.Magnitude > 0 then root.CFrame = root.CFrame + (move * (FlySpeed/20)) end
    end
end)

-- [[ SISTEMA ESP RENDER COMPLETO ]] --
local function CreateESP(plr)
    CreateLookLine(plr) -- Ativa a linha de visão
    local Box = Drawing.new("Square"); Box.Thickness = 1; Box.Filled = false; Box.Color = Color3.fromRGB(130, 0, 255); Box.Visible = false
    local Line = Drawing.new("Line"); Line.Thickness = 1; Line.Color = Color3.new(1, 1, 1); Line.Visible = false
    local Name = Drawing.new("Text"); Name.Size = 14; Name.Center = true; Name.Outline = true; Name.Color = Color3.new(1, 1, 1); Name.Visible = false
    local Health = Drawing.new("Text"); Health.Size = 13; Health.Center = true; Health.Outline = true; Health.Color = Color3.new(0, 1, 0); Health.Visible = false
    local Dist = Drawing.new("Text"); Dist.Size = 13; Dist.Center = true; Dist.Outline = true; Dist.Color = Color3.new(1, 1, 1); Dist.Visible = false
    local Weapon = Drawing.new("Text"); Weapon.Size = 13; Weapon.Center = true; Weapon.Outline = true; Weapon.Color = Color3.new(1, 0.5, 0); Weapon.Visible = false

    local Connection;
    Connection = RunService.RenderStepped:Connect(function()
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr ~= LocalPlayer then
            local Root = plr.Character.HumanoidRootPart
            local Hum = plr.Character.Humanoid
            local Pos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
            if OnScreen then
                local SizeX = 2000 / Pos.Z; local SizeY = 2500 / Pos.Z
                Box.Visible = EspBox; Box.Size = Vector2.new(SizeX, SizeY); Box.Position = Vector2.new(Pos.X - SizeX / 2, Pos.Y - SizeY / 2)
                Line.Visible = EspLine; Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); Line.To = Vector2.new(Pos.X, Pos.Y + SizeY / 2)
                Name.Visible = EspName; Name.Text = plr.Name; Name.Position = Vector2.new(Pos.X, Pos.Y - SizeY / 2 - 15)
                Health.Visible = EspHealth; Health.Text = "Vida: " .. math.floor(Hum.Health); Health.Position = Vector2.new(Pos.X, Pos.Y + SizeY / 2 + 5)
                Dist.Visible = EspDist; local d = math.floor((Root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                Dist.Text = "["..d.."m]"; Dist.Position = Vector2.new(Pos.X, Pos.Y + SizeY / 2 + 20)
                Weapon.Visible = EspWeapon; local tool = plr.Character:FindFirstChildOfClass("Tool")
                Weapon.Text = tool and tool.Name or "Mãos"; Weapon.Position = Vector2.new(Pos.X, Pos.Y - SizeY / 2 - 30)
            else Box.Visible=false; Line.Visible=false; Name.Visible=false; Health.Visible=false; Dist.Visible=false; Weapon.Visible=false end
        else
            Box.Visible=false; Line.Visible=false; Name.Visible=false; Health.Visible=false; Dist.Visible=false; Weapon.Visible=false
            if not plr.Parent then Connection:Disconnect(); Box:Remove(); Line:Remove(); Name:Remove(); Health:Remove(); Dist:Remove(); Weapon:Remove() end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

-- [[ ENGINE LOOPS COMBATE ]] --
RunService.RenderStepped:Connect(function()
    if AntiLeakTriggered then return end
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Radius = AimFOV
    local target = GetClosestPlayer()

    if MagnetActive and target and (UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
        local rootEnemy = target.Character:FindFirstChild("HumanoidRootPart")
        if rootEnemy then rootEnemy.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5) end
    end

    if AimActive and target and (UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
    end

    if GodModeActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then 
        LocalPlayer.Character.Humanoid.Health = 100 
    end
end)

-- [[ LOGIN & DRAG ]] --
local function Drag(o)
    local d, s, sp; o.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = true; s = i.Position; sp = o.Position end end)
    UIS.InputChanged:Connect(function(i) if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local del = i.Position - s; o.Position = UDim2.new(sp.X.Scale, sp.X.Offset + del.X, sp.Y.Scale, sp.Y.Offset + del.Y) end end)
    UIS.InputEnded:Connect(function() d = false end)
end

LogBtn.MouseButton1Click:Connect(function()
    LogBtn.Text = "PROCESSANDO..."
    local username = UserIn.Text
    local success, response = pcall(function() return game:HttpGet(DB_URL .. "users/" .. username .. ".json") end)
    if success and response ~= "null" then
        local data = HttpService:JSONDecode(response)
        if tostring(data.key) == KeyIn.Text then
            IsAuthenticated = true
            StartAutoKick(username)
            Login.Visible = false; InfoKey.Visible = true; Drag(InfoKey)
        else LogBtn.Text = "KEY INVÁLIDA!"; task.wait(1); LogBtn.Text = "ENTRAR NO SISTEMA" end
    else LogBtn.Text = "USER NÃO EXISTE!"; task.wait(1); LogBtn.Text = "ENTRAR NO SISTEMA" end
end)

StartBtn.MouseButton1Click:Connect(function() InfoKey:Destroy(); Main.Visible = true; Drag(Main); Drag(OpenBtn) end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false; OpenBtn.Visible = true end)
OpenBtn.MouseButton1Click:Connect(function() Main.Visible = true; OpenBtn.Visible = false end)
Drag(Login)
Container.CanvasSize = UDim2.new(0,0,0,curY)
