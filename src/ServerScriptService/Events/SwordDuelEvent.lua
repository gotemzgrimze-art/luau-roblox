local PvPEventUtils = require(script.Parent.PvPEventUtils)

local SwordDuelEvent = {
	Name = "SwordDuelEvent",
	Weight = 6,
	Duration = 7,
}

function SwordDuelEvent.CanRun(context)
	return context:GetAliveCount() >= 2
end

function SwordDuelEvent.Start(context)
	local eventConfig = context.EventConfig
	local alivePlayers = context:GetAlivePlayers()

	if #alivePlayers < 2 then
		return
	end

	context:EnablePvp()
	context:Announce("Sword duel")

	PvPEventUtils.GrantMeleeTools(context, alivePlayers, {
		ToolName = "Sword",
		HandleColor = Color3.fromRGB(180, 180, 190),
		HandleSize = Vector3.new(0.7, 1, 4.4),
		Damage = eventConfig.Damage,
		KnockbackHorizontal = eventConfig.KnockbackHorizontal,
		KnockbackVertical = eventConfig.KnockbackVertical,
		Cooldown = eventConfig.Cooldown,
		Range = eventConfig.Range,
		HitboxSize = eventConfig.HitboxSize,
		Reason = "Sword duel",
	})
end

function SwordDuelEvent.Cleanup(_context)
end

return SwordDuelEvent
