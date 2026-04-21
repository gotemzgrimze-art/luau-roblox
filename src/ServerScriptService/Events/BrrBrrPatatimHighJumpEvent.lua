local BrrBrrPatatimHighJumpEvent = {
	Name = "BrrBrrPatatimHighJumpEvent",
	Weight = 8,
	Duration = 6,
}

function BrrBrrPatatimHighJumpEvent.CanRun(context)
	return context:GetAliveCount() > 0
end

function BrrBrrPatatimHighJumpEvent.Start(context)
	local eventConfig = context.EventConfig
	local alivePlayers = context:GetAlivePlayers()

	if #alivePlayers == 0 then
		return
	end

	context:Announce("Brr Brr Patatim high jump enabled")

	context:ApplyHumanoidOverridesPerPlayer(alivePlayers, function(_player, humanoid)
		if humanoid.UseJumpPower then
			return {
				JumpPower = eventConfig.JumpPower,
			}
		end

		return {
			JumpHeight = eventConfig.JumpHeight,
		}
	end)
end

function BrrBrrPatatimHighJumpEvent.Cleanup(_context)
end

return BrrBrrPatatimHighJumpEvent
