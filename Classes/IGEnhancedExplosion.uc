class IGEnhancedExplosion extends UT_RingExplosion;

simulated function SpawnEffects() {
	local Actor A;
	A = Spawn(class'ShockExplo');
	A.RemoteRole = ROLE_None;
}
