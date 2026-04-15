local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local RemoteDefinitions = {
	Announcement = remotesFolder:WaitForChild("Announcement"),
	RoundState = remotesFolder:WaitForChild("RoundState"),
	HealthUpdate = remotesFolder:WaitForChild("HealthUpdate"),
}

return table.freeze(RemoteDefinitions)
