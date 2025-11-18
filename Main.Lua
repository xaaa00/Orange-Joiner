-- ========================================
-- AUTO-JOINER PARA STEAL A BRAINROT
-- Busca servidores con Brainrots de 10M-999M
-- ========================================

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Configuración
local MIN_VALUE = 10000000 -- 10M
local MAX_VALUE = 999000000 -- 999M
local GAME_ID = game.PlaceId
local SCAN_DELAY = 2 -- segundos entre escaneos

-- Variables
local isScanning = false
local foundServer = false

-- ========================================
-- CREAR GUI
-- ========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotAutoJoiner"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame principal (pequeño)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0.5, -100, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Hacer draggable
local dragging = false
local dragInput, mousePos, framePos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        mainFrame.Position = UDim2.new(
            framePos.X.Scale, framePos.X.Offset + delta.X,
            framePos.Y.Scale, framePos.Y.Offset + delta.Y
        )
    end
end)

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "🧠 Brainrot Hunter"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 35)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Listo para buscar"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Botón de escaneo
local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0, 160, 0, 30)
scanButton.Position = UDim2.new(0.5, -80, 1, -40)
scanButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
scanButton.Text = "▶ Iniciar Búsqueda"
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.TextSize = 12
scanButton.Font = Enum.Font.GothamBold
scanButton.BorderSizePixel = 0
scanButton.Parent = mainFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = scanButton

-- ========================================
-- FUNCIONES DE ESCANEO
-- ========================================

local function formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(num)
end

local function checkCurrentServer()
    -- Busca Brainrots en el servidor actual
    local highestValue = 0
    
    for _, base in pairs(workspace:GetChildren()) do
        if base.Name:find("'s Base") then
            for _, obj in pairs(base:GetDescendants()) do
                -- Busca modelos de Brainrot con valores
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    if obj.Name:lower():find("value") or obj.Name:lower():find("money") then
                        if obj.Value > highestValue then
                            highestValue = obj.Value
                        end
                    end
                end
            end
        end
    end
    
    return highestValue
end

local function scanServers()
    isScanning = true
    scanButton.Text = "⏸ Detener"
    scanButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    
    statusLabel.Text = "Escaneando servidores..."
    
    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..GAME_ID.."/servers/Public?sortOrder=Asc&limit=100"
        ))
    end)
    
    if not success then
        statusLabel.Text = "❌ Error al obtener servidores"
        isScanning = false
        scanButton.Text = "▶ Iniciar Búsqueda"
        scanButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        return
    end
    
    -- Primero verifica servidor actual
    local currentValue = checkCurrentServer()
    if currentValue >= MIN_VALUE and currentValue <= MAX_VALUE then
        statusLabel.Text = "✅ ¡Servidor actual tiene "..formatNumber(currentValue).."!"
        foundServer = true
        return
    end
    
    statusLabel.Text = "Buscando en "..#servers.data.." servidores..."
    
    -- Intenta unirse a servidores aleatorios
    for i, server in pairs(servers.data) do
        if not isScanning then break end
        
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            statusLabel.Text = "Probando servidor "..(i).."/"..#servers.data
            
            local success, result = pcall(function()
                TeleportService:TeleportToPlaceInstance(GAME_ID, server.id, player)
            end)
            
            if success then
                statusLabel.Text = "🔄 Uniéndose a servidor..."
                wait(3)
                return
            end
            
            wait(SCAN_DELAY)
        end
    end
    
    if not foundServer then
        statusLabel.Text = "❌ No se encontraron servidores"
        isScanning = false
        scanButton.Text = "▶ Reintentar"
        scanButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    end
end

-- ========================================
-- EVENTOS
-- ========================================

scanButton.MouseButton1Click:Connect(function()
    if isScanning then
        isScanning = false
        scanButton.Text = "▶ Iniciar Búsqueda"
        scanButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        statusLabel.Text = "Detenido"
    else
        foundServer = false
        scanServers()
    end
end)

-- Hover effect
scanButton.MouseEnter:Connect(function()
    scanButton.BackgroundColor3 = isScanning and 
        Color3.fromRGB(220, 50, 40) or 
        Color3.fromRGB(90, 190, 95)
end)

scanButton.MouseLeave:Connect(function()
    scanButton.BackgroundColor3 = isScanning and 
        Color3.fromRGB(244, 67, 54) or 
        Color3.fromRGB(76, 175, 80)
end)

-- ========================================
-- NOTIFICACIÓN INICIAL
-- ========================================
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "🧠 Brainrot Hunter";
    Text = "Auto-joiner cargado. Rango: 10M-999M";
    Duration = 5;
})

print("✅ Brainrot Auto-Joiner cargado correctamente")
print("📊 Buscando Brainrots entre "..formatNumber(MIN_VALUE).." y "..formatNumber(MAX_VALUE))
