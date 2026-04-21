local PvPEventUtils = require(script.Parent.PvPEventUtils)

local RocketLauncherMadnessEvent = {
	Name = "RocketLauncherMadnessEvent",
	Weight = 5,
	Duration = 8,
}

function RocketLauncherMadnessEvent.CanRun(context)
	return context:GetAliveCount() >= 2
end

function RocketLauncherMadnessEvent.Start(context)
	local eventConfig = context.EventConfig
	local alivePlayers = context:GetAlivePlayers()

	if #alivePlayers < 2 then
		return
	end

	context:EnablePvp()
	context:Announce("Rocket launcher madness")

	PvPEventUtils.GrantRocketTools(context, alivePlayers, {
		ToolName = "Rocket Launcher",
		HandleColor = Color3.fromRGB(96, 96, 96),
		HandleSize = Vector3.new(1.2, 1.2, 4.5),
		Damage = eventConfig.Damage,
		KnockbackHorizontal = eventConfig.KnockbackHorizontal,
		KnockbackVertical = eventConfig.KnockbackVertical,
		Cooldown = eventConfig.Cooldown,
		Ammo = eventConfig.Ammo,
		ExplosionRadius = eventConfig.ExplosionRadius,
		ProjectileSpeed = eventConfig.ProjectileSpeed,
		ProjectileLifetime = eventConfig.ProjectileLifetime,
		Reason = "Rocket launcher",
	})
end

function RocketLauncherMadnessEvent.Cleanup(_context)
end

return RocketLauncherMadnessEvent
