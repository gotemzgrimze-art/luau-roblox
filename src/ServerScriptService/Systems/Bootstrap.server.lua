local Players = game:GetService("Players")

Players.CharacterAutoLoads = false

local RoundManager = require(script.Parent.RoundManager)

RoundManager.Start()
