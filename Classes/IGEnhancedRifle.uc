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

	SourceOffset = CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * Y + FireOffset.Z * Z;
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

simulated function bool ClientFire(float V) {
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

	return super.ClientFire(V);
}

// StartTrace here does not take FireOffset into consideration.
// The visible effect still will, but the hitscan trace will not.
function TraceFire( float Accuracy ) {
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;

	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
	StartTrace = Owner.Location + vect(0,0,1) * Pawn(Owner).EyeHeight;
	EndTrace = StartTrace + Accuracy * (FRand() - 0.5 )* Y * 1000
		+ Accuracy * (FRand() - 0.5 ) * Z * 1000 ;

	if (bBotSpecialMove && (Tracked != None) &&
		(((Owner.Acceleration == vect(0,0,0)) && (VSize(Owner.Velocity) < 40)) ||
			(Normal(Owner.Velocity) Dot Normal(Tracked.Velocity) > 0.95))
	) {
		EndTrace += 10000 * Normal(Tracked.Location - StartTrace);
	} else {
		AdjustedAim = pawn(owner).AdjustAim(1000000, StartTrace, 2.75*AimError, False, False);	
		EndTrace += (10000 * vector(AdjustedAim)); 
	}

	Tracked = None;
	bBotSpecialMove = false;

	Other = Pawn(Owner).TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
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
	local vector SourceOffset;
	local vector SourceLocation;
	local vector TargetOffset;

	if (Other == None) {
		HitNormal = -X;
		HitLocation = Owner.Location + X*10000.0;
	}

	SourceOffset = CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * Y + FireOffset.Z * Z;
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

	if ((Other != self) && (Other != Owner) && (Other != None)) 
		Other.TakeDamage(HitDamage, Pawn(Owner), HitLocation, 60000.0*X, MyDamageType);
}

function SpawnEffect(vector HitLocation, vector SmokeLocation)
{
	local SuperShockBeam Smoke;
	Smoke = Spawn(class'SuperShockBeam');
	Smoke.RemoteRole = ROLE_None;
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
