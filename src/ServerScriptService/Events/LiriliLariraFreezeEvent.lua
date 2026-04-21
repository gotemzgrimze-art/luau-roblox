local LiriliLariraFreezeEvent = {
	Name = "LiriliLariraFreezeEvent",
	Weight = 8,
	Duration = 5,
}

function LiriliLariraFreezeEvent.CanRun(context)
	return context:GetAliveCount() > 0
end

function LiriliLariraFreezeEvent.Start(context)
	local eventConfig = context.EventConfig
	local targets = {}

	if eventConfig.AffectAllAlive then
		targets = context:GetAlivePlayers()
	else
		local targetPlayer = context:GetRandomAlivePlayer()
		if targetPlayer then
			table.insert(targets, targetPlayer)
		end
	end

	if #targets == 0 then
		return
	end

	if eventConfig.AffectAllAlive then
		context:Announce("Lirili Larira freeze on everyone")
	else
		context:Announce(("Lirili Larira freeze targeting %s"):format(targets[1].Name))
	end

	context:Schedule(eventConfig.WarningDuration, function()
		for _, player in ipairs(targets) do
			local rootPart = context:GetRootPart(player)
			if rootPart then
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero
			end
		end

		local restoreHumanoids = context:ApplyHumanoidOverridesPerPlayer(targets, function(_player, humanoid)
			local overrides = {
				WalkSpeed = 0,
				AutoRotate = false,
			}

			if humanoid.UseJumpPower then
				overrides.JumpPower = 0
			else
				overrides.JumpHeight = 0
			end

			return overrides
		end)

		context:Schedule(eventConfig.FreezeDuration, function()
			restoreHumanoids()
		end)
	end)
end

function LiriliLariraFreezeEvent.Cleanup(_context)
end

return LiriliLariraFreezeEvent
