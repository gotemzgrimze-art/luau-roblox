local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteDefinitions = require(ReplicatedStorage.Modules.RemoteDefinitions)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ScreenGui")

local root = screenGui:FindFirstChild("HudRoot")
if root then
	root:Destroy()
end

root = Instance.new("Frame")
root.Name = "HudRoot"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = screenGui

local statusCard = Instance.new("Frame")
statusCard.Name = "StatusCard"
statusCard.AnchorPoint = Vector2.new(0, 0)
statusCard.Position = UDim2.fromOffset(24, 24)
statusCard.Size = UDim2.fromOffset(320, 150)
statusCard.BackgroundColor3 = Color3.fromRGB(19, 24, 34)
statusCard.BackgroundTransparency = 0.15
statusCard.BorderSizePixel = 0
	statusCard.Parent = root

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 14)
cardCorner.Parent = statusCard

local headerLabel = Instance.new("TextLabel")
headerLabel.Name = "Header"
headerLabel.BackgroundTransparency = 1
headerLabel.Position = UDim2.fromOffset(18, 16)
headerLabel.Size = UDim2.fromOffset(284, 24)
headerLabel.Font = Enum.Font.GothamBold
headerLabel.Text = "Waiting"
headerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
headerLabel.TextSize = 22
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Parent = statusCard

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "Message"
messageLabel.BackgroundTransparency = 1
messageLabel.Position = UDim2.fromOffset(18, 48)
messageLabel.Size = UDim2.fromOffset(284, 22)
messageLabel.Font = Enum.Font.Gotham
messageLabel.Text = "Waiting for players"
messageLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
messageLabel.TextSize = 16
messageLabel.TextWrapped = true
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.Parent = statusCard

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "Timer"
timerLabel.BackgroundTransparency = 1
timerLabel.Position = UDim2.fromOffset(18, 78)
timerLabel.Size = UDim2.fromOffset(284, 24)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Text = "--"
timerLabel.TextColor3 = Color3.fromRGB(255, 210, 96)
timerLabel.TextSize = 18
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Parent = statusCard

local aliveLabel = Instance.new("TextLabel")
aliveLabel.Name = "Alive"
aliveLabel.BackgroundTransparency = 1
aliveLabel.Position = UDim2.fromOffset(18, 106)
aliveLabel.Size = UDim2.fromOffset(284, 20)
aliveLabel.Font = Enum.Font.Gotham
aliveLabel.Text = "Alive: 0"
aliveLabel.TextColor3 = Color3.fromRGB(180, 255, 192)
aliveLabel.TextSize = 15
aliveLabel.TextXAlignment = Enum.TextXAlignment.Left
aliveLabel.Parent = statusCard

local healthBarBackground = Instance.new("Frame")
healthBarBackground.Name = "HealthBarBackground"
healthBarBackground.Position = UDim2.fromOffset(18, 130)
healthBarBackground.Size = UDim2.fromOffset(284, 10)
healthBarBackground.BackgroundColor3 = Color3.fromRGB(44, 52, 70)
healthBarBackground.BorderSizePixel = 0
healthBarBackground.Parent = statusCard

local healthBarCorner = Instance.new("UICorner")
healthBarCorner.CornerRadius = UDim.new(1, 0)
healthBarCorner.Parent = healthBarBackground

local healthBarFill = Instance.new("Frame")
healthBarFill.Name = "Fill"
healthBarFill.Size = UDim2.fromScale(1, 1)
healthBarFill.BackgroundColor3 = Color3.fromRGB(88, 255, 144)
healthBarFill.BorderSizePixel = 0
healthBarFill.Parent = healthBarBackground

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = healthBarFill

local announcementLabel = Instance.new("TextLabel")
announcementLabel.Name = "Announcement"
announcementLabel.AnchorPoint = Vector2.new(0.5, 0)
announcementLabel.Position = UDim2.fromScale(0.5, 0.08)
announcementLabel.Size = UDim2.fromOffset(640, 60)
announcementLabel.BackgroundTransparency = 1
announcementLabel.Font = Enum.Font.GothamBold
announcementLabel.Text = ""
announcementLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
announcementLabel.TextStrokeTransparency = 0.4
announcementLabel.TextSize = 30
announcementLabel.Parent = root

local announcementToken = 0

local function showAnnouncement(message)
	announcementToken += 1
	local currentToken = announcementToken

	announcementLabel.TextTransparency = 0
	announcementLabel.Text = message

	task.delay(2.5, function()
		if currentToken ~= announcementToken then
			return
		end

		local tween = TweenService:Create(
			announcementLabel,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextTransparency = 1 }
		)
		tween:Play()
	end)
end

local function updateHealth(data)
	local maxHealth = math.max(1, data.MaxHealth or 100)
	local currentHealth = math.clamp(data.Health or maxHealth, 0, maxHealth)
	local fillScale = currentHealth / maxHealth

	healthBarFill.Size = UDim2.fromScale(fillScale, 1)
	healthBarFill.BackgroundColor3 = data.IsAlive and Color3.fromRGB(88, 255, 144) or Color3.fromRGB(255, 80, 80)
end

RemoteDefinitions.RoundState.OnClientEvent:Connect(function(state)
	headerLabel.Text = state.Phase or "Lobby"
	messageLabel.Text = state.Message or ""
	aliveLabel.Text = ("Alive: %d"):format(state.AliveCount or 0)

	if state.TimeLeft ~= nil then
		timerLabel.Text = ("Time: %d"):format(state.TimeLeft)
	else
		timerLabel.Text = "--"
	end
end)

RemoteDefinitions.Announcement.OnClientEvent:Connect(function(message)
	showAnnouncement(message)
end)

RemoteDefinitions.HealthUpdate.OnClientEvent:Connect(function(data)
	updateHealth(data)
end)
