class IGEnhancedChannel extends Info;

var PlayerPawn PlayerOwner;
var IGEnhancedChannel Next;

var Object SettingsHelper;
var IGEnhancedSettings Settings;

replication {
	reliable if (Role == ROLE_Authority && Owner.RemoteRole == ROLE_AutonomousProxy)
		PlayEffect;
}

simulated final function InitSettings() {
	SettingsHelper = new(none, 'IGEnhanced') class'Object';
	Settings = new(SettingsHelper, 'Settings') class'IGEnhancedSettings';
	Settings.Initialize();
}

simulated final function PlayEffect(
	PlayerReplicationInfo SourcePRI,
	vector SourceLocation,
	vector SourceOffset,
	Actor Target,
	vector TargetLocation,
	vector TargetOffset,
	vector HitNormal
) {
	if (Level.NetMode == NM_DedicatedServer)
		return;

	if (PlayerOwner == none)
		PlayerOwner = PlayerPawn(Owner);

	if (Settings == none)
		InitSettings();

	if (Settings.bBeamClientSide && SourcePRI.Owner == Owner)
		return;

	ClientPlayEffect(
		SourcePRI,
		SourceLocation,
		SourceOffset,
		Target,
		TargetLocation,
		TargetOffset,
		HitNormal
	);
}

simulated final function ClientPlayEffect(
	PlayerReplicationInfo SourcePRI,
	vector SourceLocation,
	vector SourceOffset,
	Actor Target,
	vector TargetLocation,
	vector TargetOffset,
	vector HitNormal
) {
	local vector SmokeLocation;
	local vector HitLocation;

	if (PlayerOwner == none)
		PlayerOwner = PlayerPawn(Owner);

	if (SourcePRI.Owner != none && Settings.BeamOriginMode == BAM_Attached) {
		SmokeLocation = SourcePRI.Owner.Location + SourceOffset;
	} else {
		SmokeLocation = SourceLocation;
	}

	if (Target != none && Settings.BeamDestinationMode == BAM_Attached) {
		HitLocation = Target.Location + TargetOffset;
	} else {
		HitLocation = TargetLocation;
	}

	PlayBeam(SourcePRI, SmokeLocation, HitLocation, HitNormal);
	PlayRing(SourcePRI, HitLocation, HitNormal);
}

simulated final function PlayBeam(
	PlayerReplicationInfo SourcePRI,
	vector SmokeLocation,
	vector HitLocation,
	vector HitNormal
) {
	local IGEnhancedBeam Smoke;
	local Vector DVector;
	local int NumPoints;
	local rotator SmokeRotation;
	local vector MoveAmount;

	DVector = HitLocation - SmokeLocation;
	NumPoints = VSize(DVector) / 135.0;
	if ( NumPoints < 1 )
		return;
	SmokeRotation = rotator(DVector);
	SmokeRotation.roll = Rand(65535);

	if (Settings.BeamType == BT_None) return;
	if (Settings.bBeamHideOwn &&
		(SourcePRI.Owner == PlayerOwner || SourcePRI.Owner == PlayerOwner.ViewTarget) &&
		PlayerOwner.bBehindView == false)
		return;

	Smoke = class'IGEnhancedBeam'.static.AllocBeam(PlayerOwner);
	if (Smoke == none) return;
	Smoke.SetLocation(SmokeLocation);
	Smoke.SetRotation(SmokeRotation);
	MoveAmount = DVector / NumPoints;

	if (Settings.BeamType == BT_Default) {
		Smoke.SetProperties(
			-1,
			1,
			1,
			0.27,
			MoveAmount,
			NumPoints - 1);

	} else if (Settings.BeamType == BT_TeamColored) {
		Smoke.SetProperties(
			SourcePRI.Team,
			Settings.BeamScale,
			Settings.BeamFadeCurve,
			Settings.BeamDuration,
			MoveAmount,
			NumPoints - 1);

	} else if (Settings.BeamType == BT_Instant) {
		Smoke.SetProperties(
			SourcePRI.Team,
			Settings.BeamScale,
			Settings.BeamFadeCurve,
			Settings.BeamDuration,
			MoveAmount,
			0);

		for (NumPoints = NumPoints - 1; NumPoints > 0; NumPoints--) {
			SmokeLocation += MoveAmount;
			Smoke = class'IGEnhancedBeam'.static.AllocBeam(PlayerOwner);
			if (Smoke == None) break;
			Smoke.SetLocation(SmokeLocation);
			Smoke.SetRotation(SmokeRotation);
			Smoke.SetProperties(
				SourcePRI.Team,
				Settings.BeamScale,
				Settings.BeamFadeCurve,
				Settings.BeamDuration,
				MoveAmount,
				0);
		}
	}
}

simulated final function PlayRing(
	PlayerReplicationInfo SourcePRI,
	vector HitLocation,
	vector HitNormal
) {
	local Actor A;

	switch(Settings.ExplosionType) {
		case ET_None:
			A = Spawn(class'EnergyImpact',,, HitLocation,rotator(HitNormal));
			if (A != none) {
				A.RemoteRole = ROLE_None;
				A.PlayOwnedSound(Sound'UnrealShare.General.Explo1',,12.0,,2200);
			}
			break;
		case ET_Default:
			A = Spawn(class'UT_Superring2',,, HitLocation+HitNormal*8,rotator(HitNormal));
			A.RemoteRole = ROLE_None;
			break;
		case ET_TeamColored:
			if (SourcePRI.Team == 1) {
				A = Spawn(class'IGEnhancedExplosion',,, HitLocation+HitNormal*8,rotator(HitNormal));
				A.RemoteRole = ROLE_None;
				A = Spawn(class'EnergyImpact',,, HitLocation,rotator(HitNormal));
				if (A != none) A.RemoteRole = ROLE_None;
			} else {
				A = Spawn(class'UT_Superring2',,, HitLocation+HitNormal*8,rotator(HitNormal));
				A.RemoteRole = ROLE_None;
			}
			breaK;
	}
}

defaultproperties {

}
