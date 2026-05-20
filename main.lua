-- [[ TH SYSTEM V4.5 - SINTONIA RP ULTRA EDITION ]] --
-- DEVELOPER: TH SYSTEM STORY RJ -- TH SYSTEM PRODUTOR -- TH MODZ PROGRAMADOR

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local PPS = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ CONFIGURAÇÃO FIREBASE ]] --
local DB_URL = "https://th-system-database-default-rtdb.firebaseio.com/"

local TargetGui = (RunService:IsStudio() or not pcall(function() return game:GetService("CoreGui") end)) and LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")

if TargetGui:FindFirstChild("TH_SYSTEM_V45") then TargetGui.TH_SYSTEM_V45:Destroy() end
if TargetGui:FindFirstChild("TH_CarTestMenu") then TargetGui.TH_CarTestMenu:Destroy() end

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
local AutoStatusActive = false
local TrollCarActive = false
local SpeedCarActive = false
local SpeedCarValue = 100
local MagnetActive = false
local IpSpoofActive = false
local SuperSilentActive = false

-- VARIÁVEIS FARM LIXO (HYPE RP)
local AcelerarPrompt = false
local EspLixoAtivo = false

-- NOVAS VARIÁVEIS APELONAS
local TriggerBotActive = false
local WallshotActive = false
local LookAtLineActive = false

-- VARIÁVEIS DE ESP
local EspBox, EspLine, EspName, EspHealth, EspDist, EspWeapon = false, false, false, false, false, false

-- [[ VARIÁVEIS INTEGRADAS DO CAR MANAGER V6.0 ]] --
local ArremessadorAtivo = false
local ForcaArremesso = 3000 
local PotenciaNitro = 40
local SegurandoNitro = false
local EspArmazenado = {}
local CarrosSemAtrito = {}
local EventoPinturaEncontrado = nil
local ArgumentosSalvos = {}

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
                    LocalPlayer:Kick("\n[TH SYSTEM SECURITY]\n\nSeu acesso foi revogado.\nStatus: BANIDO / KEY REMOVIDA")
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

-- [[ LÓGICA DO CAR MANAGER V6.0 ]] --
local function AnalisarModelo(modelo, root, lista)
    if modelo:IsA("Model") then
        local assento = modelo:FindFirstChildWhichIsA("VehicleSeat")
        if assento then
            local partePrincipal = modelo:FindFirstChild("DriveSeat") or assento
            local distancia = (root.Position - partePrincipal.Position).Magnitude
            if distancia < 400 then
                table.insert(lista, {Modelo = modelo, Distancia = distancia, Assento = assento, ParteFisica = partePrincipal})
            end
        end
    end
end

local function ObterTodosCarrosProximos()
    local listaCarros = {}
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return listaCarros end
    
    local pastaVeiculos = workspace:FindFirstChild("Vehicles") or workspace:FindFirstChild("Cars") or workspace:FindFirstChild("Veiculos") or workspace:FindFirstChild("VehiclesFolder")
    
    if pastaVeiculos then
        for _, v in pairs(pastaVeiculos:GetChildren()) do AnalisarModelo(v, root, listaCarros) end
    else
        for _, v in pairs(workspace:GetChildren()) do
            AnalisarModelo(v, root, listaCarros)
            if v:IsA("Folder") and v.Name ~= "Terrain" and v.Name ~= "Map" then
                for _, sub in pairs(v:GetChildren()) do AnalisarModelo(sub, root, listaCarros) end
            end
        end
    end
    table.sort(listaCarros, function(a, b) return a.Distancia < b.Distancia end)
    return listaCarros
end

local function LimparTodosESPCarros()
    for _, esp in pairs(EspArmazenado) do if esp then esp:Destroy() end end
    EspArmazenado = {}
end

local function CriarOuAtualizarESPCarros(carros)
    if not ArremessadorAtivo then LimparTodosESPCarros() return end
    local idsAtivos = {}
    local limite = math.min(#carros, 5)
    
    for i = 1, limite do
        local dados = carros[i]
        local carro = dados.Modelo
        local parte = dados.ParteFisica
        
        if parte and parte:IsDescendantOf(workspace) then
            local idCarro = carro:GetDebugId()
            idsAtivos[idCarro] = true
            local espExistente = EspArmazenado[idCarro]
            
            if not espExistente then
                local Billboard = Instance.new("BillboardGui", ScreenGui)
                Billboard.Size = UDim2.new(0, 120, 0, 35)
                Billboard.AlwaysOnTop = true
                Billboard.ExtentsOffset = Vector3.new(0, 3, 0)
                Billboard.Adornee = parte
                
                local TextLabel = Instance.new("TextLabel", Billboard)
                TextLabel.Size = UDim2.new(1, 0, 1, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextColor3 = Color3.fromRGB(130, 0, 255)
                TextLabel.Font = "GothamBold"
                TextLabel.TextSize = 9
                TextLabel.TextStrokeTransparency = 0.5
                
                EspArmazenado[idCarro] = Billboard
                espExistente = Billboard
            end
            
            local label = espExistente:FindFirstChildWhichIsA("TextLabel")
            if label then
                local statusCarro = CarrosSemAtrito[idCarro] and " [GELO]" or ""
                label.Text = string.format("%s%s\n[%d m]", carro.Name, statusCarro, math.floor(dados.Distancia))
            end
        end
    end
    
    for id, esp in pairs(EspArmazenado) do
        if not idsAtivos[id] then
            if esp then esp:Destroy() end
            EspArmazenado[id] = nil
        end
    end
end

local function EntrarNoP1(modeloCarro)
    if not ArremessadorAtivo then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    local assentoAtual = modeloCarro and modeloCarro:FindFirstChildWhichIsA("VehicleSeat")
    
    if hum and assentoAtual then
        _G.CarStatusText = "SOLICITANDO P1..."
        hum.Sit = false
        task.wait(0.05)
        assentoAtual:Sit(hum)
        _G.CarStatusText = "CONECTADO AO P1.\n[T] Lançar | [L-Shift] Nitro."
    end
end

local function TacarCarroP1()
    if not ArremessadorAtivo then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local assento = hum.SeatPart
        local direcaoVisao = Camera.CFrame.LookVector
        
        local LinearVelocity = Instance.new("LinearVelocity")
        local Attachment = Instance.new("Attachment", assento)
        
        LinearVelocity.MaxForce = math.huge
        LinearVelocity.VectorVelocity = (direcaoVisao * ForcaArremesso) + Vector3.new(0, ForcaArremesso / 4, 0)
        LinearVelocity.Attachment0 = Attachment
        LinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
        LinearVelocity.Parent = assento
        
        hum.Sit = false
        task.wait(0.05)
        
        task.spawn(function()
            task.wait(1.5)
            LinearVelocity:Destroy()
            Attachment:Destroy()
        end)
        _G.CarStatusText = "IMPULSO DISPARADO."
    end
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
local StartBtn = Instance.new("TextButton", InfoKey); StartBtn.Size = UDim2.new(0, 180, 0, 35); StartBtn.Position = UDim2.new(0.5, -90, 0.75, 5); StartBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255); StartBtn.Text = "INICIAR SCRIPT"; StartBtn.TextColor3 = Color3.new(1,1,1); StartBtn.Font = "GothamBold"; Instance.new("UICorner", StartBtn)

-- [[ MENU PRINCIPAL ]] --
local Main = Instance.new("Frame", ScreenGui); Main.Name = "Frame"; Main.Size = UDim2.new(0, 220, 0, 480); Main.Position = UDim2.new(0.5, -110, 0.5, -240); Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12); Main.Visible = false; Instance.new("UICorner", Main); Instance.new("UIStroke", Main).Color = Color3.fromRGB(130, 0, 255)
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 40); Title.Position = UDim2.new(0, 0, 0, 10); Title.Text = "TH SYSTEM V4.5"; Title.TextColor3 = Color3.fromRGB(130, 0, 255); Title.Font = "GothamBold"; Title.TextSize = 16; Title.BackgroundTransparency = 1
local CloseBtn = Instance.new("TextButton", Main); CloseBtn.Size = UDim2.new(1, -20, 0, 35); CloseBtn.Position = UDim2.new(0, 10, 1, -45); CloseBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255); CloseBtn.Text = "FECHAR"; CloseBtn.TextColor3 = Color3.new(1, 1, 1); CloseBtn.Font = "GothamBold"; Instance.new("UICorner", CloseBtn)
local OpenBtn = Instance.new("TextButton", ScreenGui); OpenBtn.Size = UDim2.new(0, 45, 0, 45); OpenBtn.Position = UDim2.new(0, 10, 0.5, -22); OpenBtn.BackgroundColor3 = Color3.fromRGB(12, 12, 12); OpenBtn.Text = "TH"; OpenBtn.TextColor3 = Color3.fromRGB(130, 0, 255); OpenBtn.Font = "GothamBold"; OpenBtn.Visible = false; Instance.new("UICorner", OpenBtn); Instance.new("UIStroke", OpenBtn).Color = Color3.fromRGB(130, 0, 255)
local Container = Instance.new("ScrollingFrame", Main); Container.Size = UDim2.new(1, -20, 1, -110); Container.Position = UDim2.new(0, 10, 0, 50); Container.BackgroundTransparency = 1; Container.ScrollBarThickness = 2; local curY = 0

-- [[ CRIAÇÃO DA JANELA SECUNDÁRIA (CAR MANAGER V6.0) ]] --
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "TH_CarTestMenu_Frame"
MainFrame.Size = UDim2.new(0, 270, 0, 420)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.Visible = false
Instance.new("UICorner", MainFrame)
local MainFrameStroke = Instance.new("UIStroke", MainFrame)
MainFrameStroke.Color = Color3.fromRGB(130, 0, 255)
MainFrameStroke.Thickness = 1.5

local CarTitle = Instance.new("TextLabel", MainFrame)
CarTitle.Size = UDim2.new(1, 0, 0, 35)
CarTitle.Text = "TH CAR MANAGER v6.0"
CarTitle.TextColor3 = Color3.fromRGB(130, 0, 255)
CarTitle.Font = "GothamBold"
CarTitle.TextSize = 13
CarTitle.BackgroundTransparency = 1

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 35)
StatusLabel.Text = "STATUS: AGUARDANDO..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = "Gotham"
StatusLabel.TextSize = 10
StatusLabel.TextWrapped = true
StatusLabel.BackgroundTransparency = 1

_G.CarStatusText = "STATUS: AGUARDANDO..."
task.spawn(function()
    while task.wait(0.1) do
        if StatusLabel and StatusLabel.Parent then
            StatusLabel.Text = _G.CarStatusText
        end
    end
end)

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0, 230, 0, 32)
ToggleBtn.Position = UDim2.new(0.5, -115, 0, 70)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.Text = "MOD: DESATIVADO"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = "GothamBold"
ToggleBtn.TextSize = 11
Instance.new("UICorner", ToggleBtn)

local PaintFrame = Instance.new("Frame", MainFrame)
PaintFrame.Size = UDim2.new(1, -20, 0, 50)
PaintFrame.Position = UDim2.new(0, 10, 0, 110)
PaintFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Instance.new("UICorner", PaintFrame)

local PaintTitle = Instance.new("TextLabel", PaintFrame)
PaintTitle.Size = UDim2.new(1, 0, 0, 20)
PaintTitle.Text = "SISTEMA DE PINTURA VIA SERVIDOR"
PaintTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
PaintTitle.Font = "GothamBold"
PaintTitle.TextSize = 8
PaintTitle.BackgroundTransparency = 1

local PaintBtn = Instance.new("TextButton", PaintFrame)
PaintBtn.Size = UDim2.new(1, -20, 0, 22)
PaintBtn.Position = UDim2.new(0, 10, 0, 20)
PaintBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
PaintBtn.Text = "AGUARDANDO CORES DA OFICINA..."
PaintBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
PaintBtn.Font = "GothamBold"
PaintBtn.TextSize = 9
Instance.new("UICorner", PaintBtn)

local ScrollList = Instance.new("ScrollingFrame", MainFrame)
ScrollList.Size = UDim2.new(1, -20, 0, 200)
ScrollList.Position = UDim2.new(0, 10, 0, 170)
ScrollList.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
ScrollList.BackgroundTransparency = 0.5
ScrollList.BorderSizePixel = 0
ScrollList.ScrollBarThickness = 4
ScrollList.ScrollBarImageColor3 = Color3.fromRGB(130, 0, 255)
Instance.new("UICorner", ScrollList)

local ListLayout = Instance.new("UIListLayout", ScrollList)
ListLayout.Padding = UDim.new(0, 5)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local CloseCarBtn = Instance.new("TextButton", MainFrame)
CloseCarBtn.Size = UDim2.new(1, -20, 0, 25)
CloseCarBtn.Position = UDim2.new(0, 10, 1, -35)
CloseCarBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255)
CloseCarBtn.Text = "OCULTAR MENU VEÍCULO"
CloseCarBtn.TextColor3 = Color3.new(1, 1, 1)
CloseCarBtn.Font = "GothamBold"
CloseCarBtn.TextSize = 10
Instance.new("UICorner", CloseCarBtn)
CloseCarBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- [[ COMPONENTES ]] --
local function AddLabel(txt)
    local b = Instance.new("TextLabel", Container); b.Size = UDim2.new(1, 0, 0, 25); b.Position = UDim2.new(0,0,0,curY); b.BackgroundColor3 = Color3.fromRGB(130, 0, 255); b.Text = txt; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamBold"; b.TextSize = 11; Instance.new("UICorner", b); curY = curY + 30
end
local function AddSubText(txt)
    local b = Instance.new("TextLabel", Container); b.Size = UDim2.new(1, 0, 0, 15); b.Position = UDim2.new(0,0,0,curY); b.BackgroundTransparency = 1; b.Text = txt; b.TextColor3 = Color3.fromRGB(200, 200, 200); b.Font = "Gotham"; b.TextSize = 9; b.TextXAlignment = "Left"; curY = curY + 20
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

AddLabel("FARM LIXO")
AddSubText("SERVIDOR HYPE RP")
AddToggle("ACELERAR PROMPT", function(v) AcelerarPrompt = v end)
AddToggle("ESP LIXOS", function(v) EspLixoAtivo = v end)

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

-- SEÇÃO DO BOTÃO PARA SOLICITAR A ABERTURA DO CAR MANAGER V6.0 --
AddButton("ABRIR MENU VEÍCULO", function()
    if IsAuthenticated then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

AddLabel("VISUAIS (ESP)")
AddToggle("ESP CAIXA", function(v) EspBox = v end)
AddToggle("ESP LINHA", function(v) EspLine = v end)
AddToggle("ESP NOME", function(v) EspName = v end)
AddToggle("ESP VIDA", function(v) EspHealth = v end)
AddToggle("ESP DISTANCIA", function(v) EspDist = v end)
AddToggle("ESP ARMA", function(v) EspWeapon = v end)

-- [[ INTERCEPTADOR DE REMOTES DA MECÂNICA (SPY) ]] --
local function IniciarEspiaoDeOficina()
    local metatable = getrawmetatable(game)
    if setreadonly then setreadonly(metatable, false) end
    local ncall = metatable.__namecall

    metatable.__namecall = newcclosure(function(self, ...)
        local metodo = getnamecallmethod()
        local args = {...}
        
        if metodo == "FireServer" or metodo == "InvokeServer" then
            local nomeLower = string.lower(self.Name)
            if nomeLower:find("paint") or nomeLower:find("color") or nomeLower:find("cor") or nomeLower:find("custom") or nomeLower:find("tune") then
                EventoPinturaEncontrado = self
                ArgumentosSalvos = args
                
                task.spawn(function()
                    PaintBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255)
                    PaintBtn.TextColor3 = Color3.new(1, 1, 1)
                    PaintBtn.Text = "FORÇAR PINTURA GRÁTIS (SERVER)"
                    _G.CarStatusText = "EVENTO DE PINTURA CAPTURADO COM SUCESSO!"
                end)
            end
        end
        return ncall(self, ...)
    end)
end
pcall(IniciarEspiaoDeOficina)

PaintBtn.MouseButton1Click:Connect(function()
    if EventoPinturaEncontrado then
        if EventoPinturaEncontrado:IsA("RemoteEvent") then
            EventoPinturaEncontrado:FireServer(unpack(ArgumentosSalvos))
        elseif EventoPinturaEncontrado:IsA("RemoteFunction") then
            EventoPinturaEncontrado:InvokeServer(unpack(ArgumentosSalvos))
        end
        _G.CarStatusText = "COMANDO DE PINTURA ENVIADO AO SERVIDOR!"
    else
        _G.CarStatusText = "Vá na oficina do jogo e mude a cor uma vez para capturar!"
    end
end)

-- [[ CONTROLE DE ATRITO GELO ]] --
local function AlternarAtritoCarro(modeloCarro)
    if not ArremessadorAtivo or not modeloCarro then return end
    local idCarro = modeloCarro:GetDebugId()
    
    if CarrosSemAtrito[idCarro] then
        CarrosSemAtrito[idCarro] = nil
        for _, part in pairs(modeloCarro:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name:lower():find("wheel") or part.Name:lower():find("roda")) then
                part.CustomPhysicalProperties = nil
            end
        end
        _G.CarStatusText = "ATRITO RESTAURADO."
    else
        CarrosSemAtrito[idCarro] = true
        _G.CarStatusText = "PONTOS DE GELO ATIVADOS!"
    end
    local carros = ObterTodosCarrosProximos()
    UpdateUIList(carros)
end

task.spawn(function()
    while task.wait(0.5) do
        if ArremessadorAtivo then
            local carros = ObterTodosCarrosProximos()
            for i = 1, math.min(#carros, 5) do
                local id = carros[i].Modelo:GetDebugId()
                if CarrosSemAtrito[id] then
                    for _, part in pairs(carros[i].Modelo:GetDescendants()) do
                        if part:IsA("BasePart") and (part.Name:lower():find("wheel") or part.Name:lower():find("roda")) then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0.3, 0.5, 1, 1)
                        end
                    end
                end
            end
        end
    end
end)

-- [[ ATUALIZAÇÃO DA LISTA DE CARROS (UI SECUNDÁRIA) ]] --
function UpdateUIList(carros)
    for _, item in pairs(ScrollList:GetChildren()) do if item:IsA("Frame") then item:Destroy() end end
    ScrollList.CanvasSize = UDim2.new(0, 0, 0, #carros * 30)
    
    for i = 1, math.min(#carros, 8) do
        local dados = carros[i]
        local idCarro = dados.Modelo:GetDebugId()
        local semAtrito = CarrosSemAtrito[idCarro]
        
        local CarFrame = Instance.new("Frame", ScrollList)
        CarFrame.Size = UDim2.new(1, -5, 0, 25)
        CarFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        Instance.new("UICorner", CarFrame)
        
        local CarName = Instance.new("TextLabel", CarFrame)
        CarName.Size = UDim2.new(0.42, 0, 1, 0)
        CarName.Position = UDim2.new(0, 8, 0, 0)
        CarName.Text = dados.Modelo.Name .. " [" .. math.floor(dados.Distancia) .. "m]"
        CarName.TextColor3 = semAtrito and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(230, 230, 230)
        CarName.Font = "Gotham"
        CarName.TextSize = 8
        CarName.TextXAlignment = Enum.TextXAlignment.Left
        CarName.BackgroundTransparency = 1
        
        local P1Btn = Instance.new("TextButton", CarFrame)
        P1Btn.Size = UDim2.new(0, 55, 0, 18)
        P1Btn.Position = UDim2.new(0.46, 0, 0.15, 0)
        P1Btn.BackgroundColor3 = Color3.fromRGB(130, 0, 255)
        P1Btn.Text = "SUBIR P1"
        P1Btn.TextColor3 = Color3.new(1, 1, 1)
        P1Btn.Font = "GothamBold"
        P1Btn.TextSize = 8
        Instance.new("UICorner", P1Btn)
        P1Btn.MouseButton1Click:Connect(function() EntrarNoP1(dados.Modelo) end)

        local FrictionBtn = Instance.new("TextButton", CarFrame)
        FrictionBtn.Size = UDim2.new(0, 60, 0, 18)
        FrictionBtn.Position = UDim2.new(0.72, 0, 0.15, 0)
        FrictionBtn.BackgroundColor3 = semAtrito and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(200, 100, 0)
        FrictionBtn.Text = semAtrito and "NORMAL" or "GELO"
        FrictionBtn.TextColor3 = Color3.new(1, 1, 1)
        FrictionBtn.Font = "GothamBold"
        FrictionBtn.TextSize = 8
        Instance.new("UICorner", FrictionBtn)
        FrictionBtn.MouseButton1Click:Connect(function() AlternarAtritoCarro(dados.Modelo) end)
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    ArremessadorAtivo = not ArremessadorAtivo
    if ArremessadorAtivo then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(130, 0, 255)
        ToggleBtn.Text = "MOD: ATIVADO"
        _G.CarStatusText = "SISTEMA VEICULAR INICIADO."
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        ToggleBtn.Text = "MOD: DESATIVADO"
        _G.CarStatusText = "STATUS: AGUARDANDO..."
        LimparTodosESPCarros()
        CarrosSemAtrito = {}
        UpdateUIList({})
    end
end)

-- [[ ENGINE DE LOOPS SECUNDÁRIOS ]] --
task.spawn(function()
    while task.wait(0.8) do
        if ArremessadorAtivo and MainFrame.Visible then
            local carros = ObterTodosCarrosProximos()
            UpdateUIList(carros)
            CriarOuAtualizarESPCarros(carros)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if SegurandoNitro and ArremessadorAtivo then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
            local assento = hum.SeatPart
            assento.AssemblyLinearVelocity = assento.AssemblyLinearVelocity + (assento.CFrame.LookVector * PotenciaNitro * 0.1)
            _G.CarStatusText = "NITRO INJETADO [SHIFT]"
        end
    end
end)

-- [[ LÓGICAS NATIVAS DE EVENTOS ]] --

PPS.PromptButtonHoldBegan:Connect(function(prompt)
    if AcelerarPrompt then prompt.HoldDuration = 0 end
end)

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

RunService.Stepped:Connect(function()
    if WallshotActive then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(game.Players.LocalPlayer.Character) then
                v.CanQuery = false 
            end
        end
    end
end)

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

local function CreateESP(plr)
    CreateLookLine(plr)
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

task.spawn(function()
    while task.wait(3) do
        if EspLixoAtivo then
            for _, v in pairs(workspace:GetDescendants()) do
                if (v.Name:lower():find("lixo") or v.Name:lower():find("sacola")) and not v:FindFirstChild("Highlight") then
                    local h = Instance.new("Highlight", v)
                    h.FillColor = Color3.new(1, 1, 0)
                    h.OutlineColor = Color3.new(1, 1, 1)
                end
            end
        end
    end
end)

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

-- [[ CAPTURA DE INPUTS (TECLADO) ]] --
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then 
        TacarCarroP1() 
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        SegurandoNitro = true
    end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftShift then SegurandoNitro = false end
end)

-- [[ FUNÇÃO ARRASTAR SISTEMA ]] --
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
            InfoUser.Text = "USER: " .. username
        else LogBtn.Text = "KEY INVÁLIDA!"; task.wait(1); LogBtn.Text = "ENTRAR NO SISTEMA" end
    else LogBtn.Text = "USER NÃO EXISTE!"; task.wait(1); LogBtn.Text = "ENTRAR NO SISTEMA" end
end)

StartBtn.MouseButton1Click:Connect(function() InfoKey:Destroy(); Main.Visible = true; Drag(Main); Drag(OpenBtn); Drag(MainFrame) end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false; OpenBtn.Visible = true end)
OpenBtn.MouseButton1Click:Connect(function() Main.Visible = true; OpenBtn.Visible = false end)
Drag(Login)
Container.CanvasSize = UDim2.new(0,0,0,curY)
