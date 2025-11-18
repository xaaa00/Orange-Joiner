-- ========================================
-- ORANGE JOINER 
-- ========================================

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Configuration
local MIN_VALUE = 10000000 -- 10M per second
local MAX_VALUE = 999000000 -- 999M per second
local GAME_ID = game.PlaceId
local QUICK_CHECK_TIME = 3 -- 3 seconds to check each server
local HOP_DELAY = 1 -- 1 second between hops

-- Variables
local isScanning = false
local serversChecked = 0
local serverQueue = {}

-- ========================================
-- CREATE GUI
-- ========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OrangeJoinerV3"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 160)
mainFrame.Position = UDim2.new(0.5, -130, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 100, 0)
stroke.Thickness = 3
stroke.Parent = mainFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Make draggable
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

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "ORANGE JOINER"
title.TextColor3 = Color3.fromRGB(255, 100, 0)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 22)
statusLabel.Position = UDim2.new(0, 10, 0, 45)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

local progressLabel = Instance.new("TextLabel")
progressLabel.Size = UDim2.new(1, -20, 0, 20)
progressLabel.Position = UDim2.new(0, 10, 0, 70)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "Servers: 0 | Queue: 0"
progressLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
progressLabel.TextSize = 10
progressLabel.Font = Enum.Font.Gotham
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.Parent = mainFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 18)
speedLabel.Position = UDim2.new(0, 10, 0, 92)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Mode: Fast Search (3sec per server)"
speedLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
speedLabel.TextSize = 9
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = mainFrame

local rangeLabel = Instance.new("TextLabel")
rangeLabel.Size = UDim2.new(1, -20, 0, 16)
rangeLabel.Position = UDim2.new(0, 10, 0, 110)
rangeLabel.BackgroundTransparency = 1
rangeLabel.Text = "Range: 10M - 999M per second"
rangeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
rangeLabel.TextSize = 9
rangeLabel.Font = Enum.Font.Gotham
rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
rangeLabel.Parent = mainFrame

local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0, 220, 0, 35)
scanButton.Position = UDim2.new(0.5, -110, 1, -45)
scanButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
scanButton.Text = "START GLOBAL SEARCH"
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.TextSize = 12
scanButton.Font = Enum.Font.GothamBold
scanButton.BorderSizePixel = 0
scanButton.Parent = mainFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = scanButton

-- ========================================
-- DETECTION FUNCTIONS
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

local function quickCheckServer()
    local highestValue = 0
    
    -- Quick search in workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            local name = obj.Name:lower()
            if name:find("mps") or name:find("value") or name:find("income") or name:find("rate") then
                if obj.Value > highestValue then
                    highestValue = obj.Value
                end
            end
        end
        
        -- Search in attributes
        if obj:IsA("Model") or obj:IsA("Part") then
            for attrName, attrValue in pairs(obj:GetAttributes()) do
                if type(attrValue) == "number" then
                    if attrName:lower():find("mps") or attrName:lower():find("value") then
                        if attrValue > highestValue then
                            highestValue = attrValue
                        end
                    end
                end
            end
        end
    end
    
    return highestValue
end

local function getServerList()
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..GAME_ID.."/servers/Public?sortOrder=Desc&limit=100"
        ))
    end)
    
    if not success or not result or not result.data then
        return {}
    end
    
    local servers = {}
    for _, server in pairs(result.data) do
        if server.id ~= game.JobId and server.playing > 0 and server.playing < server.maxPlayers then
            table.insert(servers, server)
        end
    end
    
    return servers
end

local function hopToNextServer()
    if #serverQueue == 0 then
        statusLabel.Text = "No more servers in queue"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        isScanning = false
        scanButton.Text = "RETRY SEARCH"
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        return
    end
    
    local server = table.remove(serverQueue, 1)
    serversChecked = serversChecked + 1
    
    statusLabel.Text = "Hopping to server "..serversChecked
    progressLabel.Text = "Checked: "..serversChecked.." | Queue: "..#serverQueue
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(GAME_ID, server.id, player)
    end)
    
    if not success then
        warn("Hop error: "..tostring(err))
        task.wait(HOP_DELAY)
        hopToNextServer()
    end
end

-- ========================================
-- MAIN SCAN FUNCTION
-- ========================================

local function startGlobalScan()
    isScanning = true
    serversChecked = 0
    scanButton.Text = "STOP"
    scanButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    
    statusLabel.Text = "Getting server list..."
    statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    
    serverQueue = getServerList()
    
    if #serverQueue == 0 then
        statusLabel.Text = "No servers found"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        isScanning = false
        scanButton.Text = "RETRY"
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        return
    end
    
    statusLabel.Text = "Found "..#serverQueue.." servers"
    progressLabel.Text = "Queue: "..#serverQueue.." servers"
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Global Search Started";
        Text = #serverQueue.." servers in queue";
        Duration = 5;
    })
    
    task.wait(2)
    hopToNextServer()
end

-- ========================================
-- AUTO-CHECK ON SERVER LOAD
-- ========================================

task.spawn(function()
    task.wait(QUICK_CHECK_TIME)
    
    if not isScanning then return end
    
    local value = quickCheckServer()
    
    if value >= MIN_VALUE and value <= MAX_VALUE then
        -- FOUND!
        isScanning = false
        statusLabel.Text = "PERFECT SERVER FOUND!"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        progressLabel.Text = "Value: "..formatNumber(value).." per second"
        speedLabel.Text = "Stay here!"
        
        scanButton.Text = "FOUND!"
        scanButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SERVER FOUND!";
            Text = "Brainrot: "..formatNumber(value).."/sec";
            Duration = 15;
        })
        
        -- Visual effect
        for i = 1, 3 do
            stroke.Color = Color3.fromRGB(100, 255, 100)
            task.wait(0.3)
            stroke.Color = Color3.fromRGB(255, 100, 0)
            task.wait(0.3)
        end
        stroke.Color = Color3.fromRGB(100, 255, 100)
        
    elseif isScanning then
        -- NOT found, keep searching
        if value > 0 then
            statusLabel.Text = "Only "..formatNumber(value).."/sec here"
            speedLabel.Text = "Need 10M-999M | Next server..."
        else
            statusLabel.Text = "No Brainrots here"
            speedLabel.Text = "Hopping to next..."
        end
        
        task.wait(HOP_DELAY)
        hopToNextServer()
    end
end)

-- ========================================
-- EVENTS
-- ========================================

scanButton.MouseButton1Click:Connect(function()
    if isScanning then
        isScanning = false
        serverQueue = {}
        scanButton.Text = "START GLOBAL SEARCH"
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        statusLabel.Text = "Search stopped"
        statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        speedLabel.Text = "Mode: Fast Search (3sec per server)"
    else
        startGlobalScan()
    end
end)

scanButton.MouseEnter:Connect(function()
    if isScanning then
        scanButton.BackgroundColor3 = Color3.fromRGB(220, 50, 40)
    else
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 130, 30)
    end
end)

scanButton.MouseLeave:Connect(function()
    if isScanning then
        scanButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    else
        scanButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    end
end)

-- ========================================
-- INITIALIZATION
-- ========================================

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Orange Joiner V3";
    Text = "Fast global search | 10M-999M/sec";
    Duration = 5;
})

print("Orange Joiner V3 Loaded")
print("Mode: Fast Global Search")
print("Range: 10M - 999M per second")
print("Speed: 3 seconds per server")
