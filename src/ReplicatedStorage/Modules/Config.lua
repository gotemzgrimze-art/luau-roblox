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
		PlacedMap = {
			Enabled = true,
			PlatformsFolderName = "MapPlatforms",
			LobbySpawnPartName = "LobbySpawn",
			RequireFullGrid = true,
		},
		MapBuilder = {
			Enabled = true,
			RespectExistingCustomMap = true,
			LobbyIslandSize = Vector3.new(92, 2, 92),
			ObservationDeckSize = Vector3.new(42, 2, 36),
			ObservationOffset = Vector3.new(62, 16, 0),
			BridgeWidth = 14,
			VoidBackdropY = -120,
			VoidBackdropSize = Vector3.new(420, 6, 420),
			HouseSignHeight = 16,
		},
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
	},

	Events = {
		Selection = {
			AvoidImmediateRepeat = true,
		},

		TralaleloTralalaTsunamiEvent = {
			Weight = 10,
			Duration = 6,
			WarningDuration = 2.25,
			WaveSpeed = 74,
			WaveHeight = 18,
			WaveThickness = 12,
			Damage = 26,
			KnockbackHorizontal = 78,
			KnockbackVertical = 38,
		},

		BombordiroCrocodileBombEvent = {
			Weight = 10,
			Duration = 5,
			WarningDuration = 2,
			BombHeight = 70,
			DropDuration = 1.35,
			ExplosionRadius = 16,
			Damage = 34,
			KnockbackHorizontal = 82,
			KnockbackVertical = 42,
		},

		LiriliLariraFreezeEvent = {
			Weight = 8,
			Duration = 5,
			WarningDuration = 1.2,
			FreezeDuration = 3,
			AffectAllAlive = false,
		},

		BrrBrrPatatimHighJumpEvent = {
			Weight = 8,
			Duration = 6,
			JumpPower = 120,
			JumpHeight = 28,
		},

		MeowlLowGravityEvent = {
			Weight = 7,
			Duration = 7,
			GravityScale = 0.42,
		},

		SlapFightEvent = {
			Weight = 8,
			Duration = 8,
			Damage = 10,
			KnockbackHorizontal = 86,
			KnockbackVertical = 34,
			Cooldown = 0.45,
			Range = 10,
			HitboxSize = Vector3.new(10, 7, 10),
		},

		RocketLauncherMadnessEvent = {
			Weight = 5,
			Duration = 8,
			Damage = 34,
			KnockbackHorizontal = 96,
			KnockbackVertical = 46,
			Cooldown = 1.2,
			Ammo = 2,
			ExplosionRadius = 16,
			ProjectileSpeed = 95,
			ProjectileLifetime = 4.5,
		},

		SwordDuelEvent = {
			Weight = 6,
			Duration = 7,
			Damage = 20,
			KnockbackHorizontal = 58,
			KnockbackVertical = 24,
			Cooldown = 0.55,
			Range = 12,
			HitboxSize = Vector3.new(9, 8, 13),
		},
	},
}

return table.freeze(Config)
