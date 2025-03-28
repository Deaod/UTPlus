class IGEnhancedRifle extends Botpack.SuperShockRifle;

var MutIGEnhanced Mutator;
var IGEnhancedChannel Channel;

simulated event PostBeginPlay() {
	super.PostBeginPlay();

	if (Role != ROLE_Authority)
		return;

	foreach AllActors(class'MutIGEnhanced', Mutator)
		break;
}

simulated final function PlayBeamClientSide() {
	local Pawn P;
	local Actor HitActor;
	local vector HitLocation;
	local vector HitNormal;
	local vector X, Y, Z;
	local vector TraceStart;
	local vector TraceEnd;

	local float YMod;
	local vector SourceOffset;
	local vector SourceLocation;

	P = Pawn(Owner);
	if (P == none)
		return;

	GetAxes(P.ViewRotation, X, Y, Z);

	TraceStart = Owner.Location + vect(0,0,1)*P.EyeHeight;
	TraceEnd = TraceStart + X*10000;

	HitActor = P.TraceShot(HitLocation, HitNormal, TraceEnd, TraceStart);

	if (HitActor == none) {
		HitLocation = TraceEnd;
		HitNormal = -X;
	}

	YMod = -1;
	if (Owner != none && Owner.IsA('PlayerPawn')) {
		if (Abs(PlayerPawn(Owner).Handedness) > 1)
			YMod = 0;
		else
			YMod = PlayerPawn(Owner).Handedness;
	}
	SourceOffset = CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * YMod * Y  + FireOffset.Z * Z;
	SourceLocation = Owner.Location + SourceOffset;

	Channel.ClientPlayEffect(
		P.PlayerReplicationInfo,
		SourceLocation,
		SourceOffset,
		HitActor,
		HitLocation,
		(HitLocation - HitActor.Location),
		HitNormal);

}

simulated final function ClientFireHook() {
	if (Level.NetMode == NM_Client) {
		if (Channel == none) {
			foreach AllActors(class'IGEnhancedChannel', Channel)
				if (Channel.Owner == Owner)
					break;
			if (Channel.Owner != Owner)
				Channel = none;
		}
		if (Channel != none) {
			if (Channel.Settings == none)
				Channel.InitSettings();

			if (Channel.Settings.bBeamClientSide) {
				PlayBeamClientSide();
			}
		}
	}
}

simulated function bool ClientFire(float V) {
	ClientFireHook();
	return super.ClientFire(V);
}

simulated function bool ClientAltFire(float V) {
	ClientFireHook();
	return super.ClientAltFire(V);
}

// StartTrace here does not take FireOffset into consideration.
// The visible effect still will, but the hitscan trace will not.
function TraceFire( float Accuracy ) {
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;
	local Pawn PawnOwner;

	PawnOwner = Pawn(Owner);
	Owner.MakeNoise(PawnOwner.SoundDampening);
	GetAxes(PawnOwner.ViewRotation,X,Y,Z);
	StartTrace = Owner.Location + vect(0,0,1) * PawnOwner.EyeHeight;
	EndTrace = StartTrace + Accuracy * (FRand() - 0.5 )* Y * 1000
		+ Accuracy * (FRand() - 0.5 ) * Z * 1000 ;

	if (bBotSpecialMove && (Tracked != none) &&
		(((Owner.Acceleration == vect(0,0,0)) && (VSize(Owner.Velocity) < 40)) ||
			(Normal(Owner.Velocity) dot Normal(Tracked.Velocity) > 0.95))
	) {
		EndTrace += 10000 * Normal(Tracked.Location - StartTrace);
	} else {
		AdjustedAim = PawnOwner.AdjustAim(1000000, StartTrace, 2.75*AimError, false, false);	
		EndTrace += (10000 * vector(AdjustedAim)); 
	}

	Tracked = none;
	bBotSpecialMove = false;

	Other = PawnOwner.TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
	ProcessTraceHit(Other, HitLocation, HitNormal, vector(AdjustedAim),Y,Z);
}

function ProcessTraceHit(
	Actor Other,
	vector HitLocation,
	vector HitNormal,
	vector X,
	vector Y,
	vector Z
) {
	local SuperShockBeam Smoke;
	local float YMod;
	local vector SourceOffset;
	local vector SourceLocation;
	local vector TargetOffset;

	if (Other == none) {
		HitNormal = -X;
		HitLocation = Owner.Location + X*10000.0;
	}

	YMod = -1;
	if (Owner != none && Owner.IsA('PlayerPawn')) {
		if (Abs(PlayerPawn(Owner).Handedness) > 1)
			YMod = 0;
		else
			YMod = PlayerPawn(Owner).Handedness;
	}
	SourceOffset = CalcDrawOffset() + (FireOffset.X + 20) * X - FireOffset.Y * YMod * Y + FireOffset.Z * Z;
	SourceLocation = Owner.Location + SourceOffset;

	if (Other != none)
		TargetOffset = HitLocation - Other.Location;

	Mutator.PlayEffect(
		Pawn(Owner).PlayerReplicationInfo,
		SourceLocation,
		SourceOffset,
		Other,
		HitLocation,
		TargetOffset,
		HitNormal
	);

	Smoke = Spawn(class'SuperShockBeam');
	Smoke.RemoteRole = ROLE_None;

	if ((Other != self) && (Other != Owner) && (Other != none)) 
		Other.TakeDamage(HitDamage, Pawn(Owner), HitLocation, 60000.0*X, MyDamageType);
}

// Use PlayAnim instead of LoopAnim to avoid inconsistent reload times,
// depending on whether the animation is looping or not
simulated function PlayFiring() {
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
	PlayAnim('Fire1', 0.20 + 0.20 * FireAdjust,0.05);
}

simulated function PlayAltFiring() {
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
	PlayAnim('Fire1', 0.20 + 0.20 * FireAdjust,0.05);
}

state ClientFiring {
	simulated function bool ClientFire(float Value) {
		return false;
	}

	simulated function bool ClientAltFire(float Value) {
		return false;
	}
}
