local PvPEventUtils = require(script.Parent.PvPEventUtils)

local SlapFightEvent = {
	Name = "SlapFightEvent",
	Weight = 8,
	Duration = 8,
}

function SlapFightEvent.CanRun(context)
	return context:GetAliveCount() >= 2
end

function SlapFightEvent.Start(context)
	local eventConfig = context.EventConfig
	local alivePlayers = context:GetAlivePlayers()

	if #alivePlayers < 2 then
		return
	end

	context:EnablePvp()
	context:Announce("Slap fight")

	PvPEventUtils.GrantMeleeTools(context, alivePlayers, {
		ToolName = "Slapper",
		HandleColor = Color3.fromRGB(255, 198, 154),
		HandleSize = Vector3.new(1, 1.6, 4),
		Damage = eventConfig.Damage,
		KnockbackHorizontal = eventConfig.KnockbackHorizontal,
		KnockbackVertical = eventConfig.KnockbackVertical,
		Cooldown = eventConfig.Cooldown,
		Range = eventConfig.Range,
		HitboxSize = eventConfig.HitboxSize,
		Reason = "Slap fight",
	})
end

function SlapFightEvent.Cleanup(_context)
end

return SlapFightEvent
