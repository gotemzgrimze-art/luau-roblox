local Config = {
	MaxPlayers = 9,
	MinPlayersToStart = 2,

	World = {
		PlatformGridSize = 3,
		PlatformSpacing = 42,
		PlatformSize = Vector3.new(24, 2, 24),
		PlatformHeight = 40,
		PlatformSpawnOffset = Vector3.new(0, 5, 0),
		LobbyPosition = Vector3.new(-120, 50, 0),
		LobbySize = Vector3.new(56, 2, 56),
		FallDeathY = 0,
	},

	Health = {
		Max = 100,
		RegenDelay = 6,
		RegenPerSecond = 4,
		RegenTick = 0.5,
	},

	Round = {
		LobbyPollInterval = 1,
		RoundStartCountdown = 3,
		GracePeriod = 6,
		EndRoundDelay = 6,
		EventDelayBase = 4,
		EventDelayMin = 2,
		EventDelayStep = 0.35,
		EventDurationBase = 8,
		EventDurationMin = 4,
		EventDurationStep = 0.35,
	},

	Events = {
		MeteorEvent = {
			WarningDuration = 2,
			MeteorHeight = 75,
			FallDuration = 1.4,
			ImpactRadius = 18,
			Damage = 45,
		},
		FireEvent = {
			TickRate = 0.5,
			DamagePerTick = 8,
		},
		AlienEvent = {
			WarningDuration = 2.5,
			MinimumCollapseDuration = 2,
		},
	},
}

return table.freeze(Config)
