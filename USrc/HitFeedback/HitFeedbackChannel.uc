class HitFeedbackChannel extends Info;

var PlayerPawn PlayerOwner;
var HitFeedbackChannel Next;

var string HitSound;
var Sound PlayedHitSound;
var string TeamHitSound;
var Sound PlayedTeamHitSound;

var Object SettingsHelper;
var HitFeedbackSettings Settings;

replication {
	reliable if (Role == ROLE_Authority && Owner.RemoteRole == ROLE_AutonomousProxy)
		PlayHitFeedback;
}

simulated final function InitSettings() {
	SettingsHelper = new(none, 'HitFeedback') class'Object';
	Settings = new(SettingsHelper, 'Settings') class'HitFeedbackSettings';
	Settings.Initialize();
}

simulated final function PlayHitFeedback(PlayerReplicationInfo VictimPRI, int Damage) {
	local int OwnTeam;
	local int EnemyTeam;

	if (Level.NetMode == NM_DedicatedServer)
		return;

	if (VictimPRI == none)
		return;

	if (PlayerOwner == none)
		PlayerOwner = PlayerPawn(Owner);

	if (Settings == none)
		InitSettings();

	OwnTeam = PlayerOwner.PlayerReplicationInfo.Team;
	EnemyTeam = VictimPRI.Team;

	PlayHitSound(Damage, OwnTeam, EnemyTeam);
}

simulated final function Sound GetHitSound() {
	local string HS;

	HS = Settings.HitSounds[Settings.SelectedHitSound];
	if (HitSound != HS) {
		HitSound = HS;
		PlayedHitSound = Sound(DynamicLoadObject(HitSound, class'Sound'));
	}
	return PlayedHitSound;
}

simulated final function Sound GetTeamHitSound() {
	local string HS;

	HS = Settings.HitSounds[Settings.SelectedTeamHitSound];
	if (TeamHitSound != HS) {
		TeamHitSound = HS;
		PlayedTeamHitSound = Sound(DynamicLoadObject(TeamHitSound, class'Sound'));
	}
	return PlayedTeamHitSound;
}

simulated final function PlaySoundWithPitch469(Sound S, float Volume, optional byte Priority, optional float Pitch) {
	local string TSP;

	TSP = PlayerOwner.GetPropertyText("TransientSoundPriority");
	PlayerOwner.SetPropertyText("TransientSoundPriority", string(Priority));

	while (Volume > 0.0) {
		PlayerOwner.PlaySound(S, SLOT_None, FMin(1.0, Volume), false, , Pitch);
		Volume -= FMin(1.0, Volume);
	}

	PlayerOwner.SetPropertyText("TransientSoundPriority", TSP);
}

simulated final function PlaySoundWithPitch436(Sound S, float Volume, optional byte Priority, optional float Pitch) {
	while (Volume > 0.0) {
		PlayerOwner.PlaySound(S, SLOT_None, float(Priority), false, , Pitch);
		Volume -= 1.0;
	}
}

simulated final function PlaySoundWithPitch(Sound S, float Volume, optional byte Priority, optional float Pitch) {
	Volume = FClamp(Volume, 0.0, 6.0);

	if (int(Level.EngineVersion) >= 469) {
		// >=469
		PlaySoundWithPitch469(S, Volume, Priority, Pitch);
	} else {
		// <469
		PlaySoundWithPitch436(S, Volume, Priority, Pitch);
	}
}

simulated final function PlayHitSound(float Damage, int OwnTeam, int EnemyTeam) {
	local bool bEnable;
	local bool bPitchShift;
	local Sound HitSound;
	local float Volume;
	local float Pitch;

	if (PlayerOwner.GameReplicationInfo.bTeamGame && OwnTeam == EnemyTeam) {
		bEnable = Settings.bEnableTeamHitSounds;
		bPitchShift = Settings.bHitSoundTeamPitchShift;
		HitSound = GetTeamHitSound();
		Volume = Settings.HitSoundTeamVolume;
	} else {
		bEnable = Settings.bEnableHitSounds;
		bPitchShift = Settings.bHitSoundPitchShift;
		HitSound = GetHitSound();
		Volume = Settings.HitSoundVolume;
	}

	if (bEnable) {
		if (bPitchShift)
			Pitch = Lerp(FClamp(Damage/300.0, 0, 1), 3.2, 0.22);
		else
			Pitch = 1.0;

		PlaySoundWithPitch(HitSound, Volume, 255, Pitch);
	}
}

defaultproperties {

}
