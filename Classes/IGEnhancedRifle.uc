class IGEnhancedRifle extends Botpack.SuperShockRifle;

// StartTrace here does not take FireOffset into consideration.
// The visible effect still will, but the hitscan trace will not.
function TraceFire( float Accuracy ) {
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;

	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
	StartTrace = Owner.Location + CalcDrawOffset();
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
