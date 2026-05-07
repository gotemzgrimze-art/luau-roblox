local Players = game:GetService("Players")

local LeaderboardManager = {}
LeaderboardManager.__index = LeaderboardManager

function LeaderboardManager.new()
	local self = setmetatable({}, LeaderboardManager)

	self.PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
		self:_ensurePlayerLeaderboard(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_ensurePlayerLeaderboard(player)
	end

	return self
end

function LeaderboardManager:_ensurePlayerLeaderboard(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local wins = leaderstats:FindFirstChild("Wins")
	if not wins then
		wins = Instance.new("IntValue")
		wins.Name = "Wins"
		wins.Value = 0
		wins.Parent = leaderstats
	end

	return wins
end

function LeaderboardManager:AwardWin(player)
	if not player or player.Parent ~= Players then
		return false
	end

	local wins = self:_ensurePlayerLeaderboard(player)
	wins.Value += 1

	return true
end

return LeaderboardManager
