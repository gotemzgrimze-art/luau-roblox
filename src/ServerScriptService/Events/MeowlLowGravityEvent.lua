local Workspace = game:GetService("Workspace")

local MeowlLowGravityEvent = {
	Name = "MeowlLowGravityEvent",
	Weight = 7,
	Duration = 7,
}

function MeowlLowGravityEvent.CanRun(context)
	return context:GetAliveCount() > 0
end

function MeowlLowGravityEvent.Start(context)
	local eventConfig = context.EventConfig
	local gravityScale = math.clamp(eventConfig.GravityScale, 0.05, 1)
	local upwardForceMultiplier = Workspace.Gravity * (1 - gravityScale)
	local alivePlayers = context:GetAlivePlayers()

	if #alivePlayers == 0 then
		return
	end

	context:Announce("Meowl low gravity online")

	for _, player in ipairs(alivePlayers) do
		local rootPart = context:GetRootPart(player)
		if rootPart then
			local attachment = context:TrackInstance(Instance.new("Attachment"))
			attachment.Name = "LowGravityAttachment"
			attachment.Parent = rootPart

			local vectorForce = context:TrackInstance(Instance.new("VectorForce"))
			vectorForce.Name = "LowGravityForce"
			vectorForce.Attachment0 = attachment
			vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
			vectorForce.ApplyAtCenterOfMass = true
			vectorForce.Force = Vector3.new(0, rootPart.AssemblyMass * upwardForceMultiplier, 0)
			vectorForce.Parent = rootPart
		end
	end
end

function MeowlLowGravityEvent.Cleanup(_context)
end

return MeowlLowGravityEvent
