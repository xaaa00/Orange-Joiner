-- ========================================
-- GRAPPLE HOOK SPEED BOOSTER V2
-- Método mejorado sin rollback
-- ========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Esperar character
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Actualizar character al respawnear
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
end)

-- Settings
local settings = {
    enabled = false,
    speedMultiplier = 1.5  -- Multiplicador de velocidad (1.5 = 50% más rápido)
}

-- ========================================
-- GUI
-- ========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GrappleSpeedGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 200)
mainFrame.Position = UDim2.new(0.5, -125, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 100, 0)
stroke.Thickness = 3
stroke.Parent = mainFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Dragging
local dragging = false
local dragInput, mousePos, framePos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - mousePos
        mainFrame.Position = UDim2.new(
            framePos.X.Scale, framePos.X.Offset + delta.X,
            framePos.Y.Scale, framePos.Y.Offset + delta.Y
        )
    end
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "GRAPPLE SPEED BOOST"
title.TextColor3 = Color3.fromRGB(255, 100, 0)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 40)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: OFF"
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Multiplier Label
local multiplierLabel = Instance.new("TextLabel")
multiplierLabel.Size = UDim2.new(1, -20, 0, 20)
multiplierLabel.Position = UDim2.new(0, 10, 0, 70)
multiplierLabel.BackgroundTransparency = 1
multiplierLabel.Text = "Speed Multiplier: 1.5x"
multiplierLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
multiplierLabel.TextSize = 11
multiplierLabel.Font = Enum.Font.Gotham
multiplierLabel.TextXAlignment = Enum.TextXAlignment.Left
multiplierLabel.Parent = mainFrame

-- Slider Background
local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(0, 210, 0, 6)
sliderBg.Position = UDim2.new(0.5, -105, 0, 95)
sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = mainFrame

local sliderBgCorner = Instance.new("UICorner")
sliderBgCorner.CornerRadius = UDim.new(1, 0)
sliderBgCorner.Parent = sliderBg

-- Slider Fill
local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(1, 0)
sliderFillCorner.Parent = sliderFill

-- Slider Button
local sliderButton = Instance.new("TextButton")
sliderButton.Size = UDim2.new(0, 20, 0, 20)
sliderButton.Position = UDim2.new(0.5, -10, 0.5, -10)
sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderButton.Text = ""
sliderButton.BorderSizePixel = 0
sliderButton.Parent = sliderBg

local sliderButtonCorner = Instance.new("UICorner")
sliderButtonCorner.CornerRadius = UDim.new(1, 0)
sliderButtonCorner.Parent = sliderButton

-- Slider Functionality
local sliderDragging = false

sliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local sliderPos = sliderBg.AbsolutePosition.X
        local sliderSize = sliderBg.AbsoluteSize.X
        
        local relativePos = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
        
        sliderButton.Position = UDim2.new(relativePos, -10, 0.5, -10)
        sliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
        
        -- Update multiplier (1.0 to 3.0)
        settings.speedMultiplier = 1 + (relativePos * 2)
        multiplierLabel.Text = string.format("Speed Multiplier: %.1fx", settings.speedMultiplier)
    end
end)

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 210, 0, 35)
toggleButton.Position = UDim2.new(0.5, -105, 0, 120)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
toggleButton.Text = "ACTIVATE BOOST"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 12
toggleButton.Font = Enum.Font.GothamBold
toggleButton.BorderSizePixel = 0
toggleButton.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 210, 0, 30)
closeButton.Position = UDim2.new(0.5, -105, 0, 162)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeButton.Text = "Close GUI"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 11
closeButton.Font = Enum.Font.Gotham
closeButton.BorderSizePixel = 0
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- ========================================
-- GRAPPLE SPEED BOOST SYSTEM
-- ========================================

local originalVelocities = {}

-- Función principal de boost
local connection
local function enableBoost()
    if connection then connection:Disconnect() end
    
    connection = RunService.Heartbeat:Connect(function()
        if not settings.enabled then return end
        
        -- Detectar BodyVelocity del grapple
        for _, obj in pairs(rootPart:GetChildren()) do
            if obj:IsA("BodyVelocity") and obj.Velocity.Magnitude > 50 then
                -- Guardar velocidad original
                if not originalVelocities[obj] then
                    originalVelocities[obj] = obj.Velocity
                end
                
                -- Aplicar multiplicador
                local boostedVelocity = obj.Velocity * settings.speedMultiplier
                obj.Velocity = boostedVelocity
                obj.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            end
        end
    end)
end

enableBoost()

-- ========================================
-- BUTTON FUNCTIONS
-- ========================================

toggleButton.MouseButton1Click:Connect(function()
    settings.enabled = not settings.enabled
    
    if settings.enabled then
        toggleButton.Text = "DEACTIVATE BOOST"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        statusLabel.Text = "Status: ON - Use your grapple!"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Grapple Boost Active";
            Text = "Multiplier: "..string.format("%.1fx", settings.speedMultiplier);
            Duration = 3;
        })
    else
        toggleButton.Text = "ACTIVATE BOOST"
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        statusLabel.Text = "Status: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        -- Limpiar velocidades guardadas
        originalVelocities = {}
    end
end)

closeButton.MouseButton1Click:Connect(function()
    if connection then connection:Disconnect() end
    screenGui:Destroy()
end)

-- ========================================
-- INICIALIZACIÓN
-- ========================================

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Grapple Speed Boost Loaded";
    Text = "Adjust speed with slider";
    Duration = 5;
})

print("========================================")
print("GRAPPLE SPEED BOOST V2 - Loaded")
print("- Use slider to adjust speed (1x - 3x)")
print("- Activate and use your grapple hook")
print("========================================")
