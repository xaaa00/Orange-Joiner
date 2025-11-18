-- ========================================
-- AUTO-JOINER MEJORADO PARA STEAL A BRAINROT
-- Detecta Brainrots que generen 10M-999M/segundo
-- ========================================

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Configuración
local MIN_VALUE = 10000000 -- 10M por segundo
local MAX_VALUE = 999000000 -- 999M por segundo
local GAME_ID = game.PlaceId
local SCAN_DELAY = 3 -- segundos entre intentos de servidor
local CHECK_DELAY = 5 -- segundos para revisar servidor actual

-- Variables
local isScanning = false
local foundServer = false
local serversChecked = 0

-- ========================================
-- CREAR GUI MEJORADA
-- ========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotAutoJoiner"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 140)
mainFrame.Position = UDim2.new(0.5, -120, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Borde brillante
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 140, 0)
stroke.Thickness = 2
stroke.Parent = mainFrame

-- Esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
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
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "🧠 BRAINROT HUNTER V2"
title.TextColor3 = Color3.fromRGB(255, 140, 0)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Status label principal
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 40)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Listo para buscar"
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Info label (servidores checados)
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 18)
infoLabel.Position = UDim2.new(0, 10, 0, 62)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Servidores: 0 | Mejor: N/A"
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = mainFrame

-- Detección label
local detectLabel = Instance.new("TextLabel")
detectLabel.Size = UDim2.new(1, -20, 0, 18)
detectLabel.Position = UDim2.new(0, 10, 0, 82)
detectLabel.BackgroundTransparency = 1
detectLabel.Text = "Rango: 10M - 999M/seg"
detectLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
detectLabel.TextSize = 9
detectLabel.Font = Enum.Font.Gotham
detectLabel.TextXAlignment = Enum.TextXAlignment.Left
detectLabel.Parent = mainFrame

-- Botón de escaneo
local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0, 200, 0, 32)
scanButton.Position = UDim2.new(0.5, -100, 1, -42)
scanButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
scanButton.Text = "▶ INICIAR BÚSQUEDA"
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.TextSize = 12
scanButton.Font = Enum.Font.GothamBold
scanButton.BorderSizePixel = 0
scanButton.Parent = mainFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = scanButton

-- ========================================
-- FUNCIONES DE DETECCIÓN MEJORADAS
-- ========================================

local function formatNumber(num)
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(math.floor(num))
end

local bestValueFound = 0

local function checkCurrentServer()
    local highestValue = 0
    local brainrotsFound = 0
    
    -- Buscar en todas las bases de jugadores
    for _, base in pairs(workspace:GetChildren()) do
        if base:IsA("Model") and (base.Name:find("'s Base") or base.Name:find("Base")) then
            -- Buscar Brainrots en la base
            for _, obj in pairs(base:GetDescendants()) do
                -- Buscar diferentes tipos de valores
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    local objName = obj.Name:lower()
                    
                    -- Palabras clave que indican valor de generación
                    if objName:find("mps") or objName:find("persecond") or 
                       objName:find("rate") or objName:find("income") or
                       objName:find("value") or objName:find("money") then
                        
                        if obj.Value > highestValue then
                            highestValue = obj.Value
                            brainrotsFound = brainrotsFound + 1
                        end
                    end
                end
                
                -- También buscar en Attributes (nuevo método de Roblox)
                if obj:IsA("Model") or obj:IsA("Part") then
                    for attrName, attrValue in pairs(obj:GetAttributes()) do
                        if type(attrValue) == "number" then
                            local name = attrName:lower()
                            if name:find("mps") or name:find("value") or name:find("income") then
                                if attrValue > highestValue then
                                    highestValue = attrValue
                                    brainrotsFound = brainrotsFound + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- También buscar directamente en workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("Brainrot") then
            for _, child in pairs(obj:GetDescendants()) do
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    if child.Value > highestValue then
                        highestValue = child.Value
                    end
                end
            end
        end
    end
    
    if highestValue > bestValueFound then
        bestValueFound = highestValue
    end
    
    return highestValue, brainrotsFound
end

local function scanServers()
    isScanning = true
    scanButton.Text = "⏸ DETENER"
    scanButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    serversChecked = 0
    
    statusLabel.Text = "🔍 Verificando servidor actual..."
    
    -- Esperar un poco para que cargue el servidor
    wait(CHECK_DELAY)
    
    -- Verificar servidor actual primero
    local currentValue, brainrotsFound = checkCurrentServer()
    
    if currentValue >= MIN_VALUE and currentValue <= MAX_VALUE then
        statusLabel.Text = "✅ ¡ENCONTRADO! "..formatNumber(currentValue).."/seg"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        infoLabel.Text = "Brainrots detectados: "..brainrotsFound
        foundServer = true
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "🎯 ¡SERVIDOR ENCONTRADO!";
            Text = "Valor: "..formatNumber(currentValue).."/segundo";
            Duration = 10;
        })
        
        isScanning = false
        scanButton.Text = "✅ ENCONTRADO"
        scanButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        return
    else
        if currentValue > 0 then
            statusLabel.Text = "❌ Servidor actual: "..formatNumber(currentValue).."/seg"
            infoLabel.Text = "Fuera de rango (10M-999M)"
        else
            statusLabel.Text = "⚠️ No se detectaron Brainrots aquí"
        end
    end
    
    statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    
    wait(2)
    statusLabel.Text = "🌐 Buscando otros servidores..."
    
    -- Obtener lista de servidores
    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..GAME_ID.."/servers/Public?sortOrder=Desc&limit=100"
        ))
    end)
    
    if not success then
        statusLabel.Text = "❌ Error de conexión"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        isScanning = false
        scanButton.Text = "🔄 REINTENTAR"
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        return
    end
    
    if not servers or not servers.data or #servers.data == 0 then
        statusLabel.Text = "❌ No hay servidores disponibles"
        isScanning = false
        scanButton.Text = "🔄 REINTENTAR"
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        return
    end
    
    statusLabel.Text = "📊 Encontrados "..#servers.data.." servidores"
    infoLabel.Text = "Mejor hasta ahora: "..formatNumber(bestValueFound)
    
    -- Mezclar servidores para probar aleatoriamente
    local serverList = {}
    for i, server in pairs(servers.data) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers and server.playing > 0 then
            table.insert(serverList, server)
        end
    end
    
    -- Intentar unirse a servidores
    for i, server in pairs(serverList) do
        if not isScanning then 
            statusLabel.Text = "⏸ Búsqueda detenida"
            break 
        end
        
        serversChecked = serversChecked + 1
        statusLabel.Text = "🔄 Probando servidor "..serversChecked.."/"..#serverList
        infoLabel.Text = "Jugadores: "..server.playing.."/"..server.maxPlayers
        
        local success, result = pcall(function()
            TeleportService:TeleportToPlaceInstance(GAME_ID, server.id, player)
        end)
        
        if success then
            statusLabel.Text = "🚀 Uniéndose a servidor..."
            wait(5)
            return
        else
            wait(SCAN_DELAY)
        end
        
        -- Cada 5 servidores, mostrar progreso
        if serversChecked % 5 == 0 then
            detectLabel.Text = "Progreso: "..serversChecked.." checados"
        end
    end
    
    if not foundServer then
        statusLabel.Text = "😔 No se encontraron servidores"
        statusLabel.TextColor3 = Color3.fromRGB(255, 180, 100)
        infoLabel.Text = "Total checados: "..serversChecked
        isScanning = false
        scanButton.Text = "🔄 REINTENTAR"
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    end
end

-- ========================================
-- EVENTOS
-- ========================================

scanButton.MouseButton1Click:Connect(function()
    if isScanning then
        isScanning = false
        scanButton.Text = "▶ INICIAR BÚSQUEDA"
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        statusLabel.Text = "⏸ Detenido por usuario"
        statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    else
        foundServer = false
        bestValueFound = 0
        scanServers()
    end
end)

-- Efectos hover
scanButton.MouseEnter:Connect(function()
    if isScanning then
        scanButton.BackgroundColor3 = Color3.fromRGB(220, 50, 40)
    else
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 160, 30)
    end
end)

scanButton.MouseLeave:Connect(function()
    if isScanning then
        scanButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    else
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    end
end)

-- ========================================
-- INICIALIZACIÓN
-- ========================================

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "🧠 Brainrot Hunter V2";
    Text = "Rango: 10M-999M/seg | Mejorado";
    Duration = 5;
})

print("✅ Brainrot Auto-Joiner V2 cargado")
print("📊 Rango: "..formatNumber(MIN_VALUE).." - "..formatNumber(MAX_VALUE).." por segundo")
print("🔧 Detección mejorada + Modo debug activado")
