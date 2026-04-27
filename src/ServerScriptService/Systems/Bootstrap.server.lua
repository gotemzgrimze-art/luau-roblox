local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local Config = require(ReplicatedStorage.Modules.Config)
local MapBuilder = require(script.Parent.MapBuilder)
local RoundManager = require(script.Parent.RoundManager)

local success, buildError = pcall(MapBuilder.Build, Config)
if not success then
	warn(("MapBuilder failed: %s"):format(buildError))
end

RoundManager.Start()
