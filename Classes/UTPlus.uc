class UTPlus extends Engine.Mutator
    config(UTPlus);

function ModifyLogin(
	out class<PlayerPawn> SpawnClass,
	out string Portal,
	out string Options
) {
	if (SpawnClass == none)
		return;

	if (ClassIsChildOf(SpawnClass, class'Spectator')) {
		SpawnClass = class'UTPlusSpectator';
	} else if (ClassIsChildOf(SpawnClass, class'TournamentPlayer')) {
		SpawnClass = class'UTPlusPlayer';
	}
}

function TickPawns(float DeltaTime) {
	local Pawn P;
	local UTPlusPlayer PP;

	if (Role != ROLE_Authority)
		return;

	for (P = Level.PawnList; P != none; P = P.NextPawn) {
		if (P.RemoteRole != ROLE_AutonomousProxy) continue;
		PP = UTPlusPlayer(P);
		if (PP != none) {
			PP.ServerTick(DeltaTime);
		}
	}
}

event Tick(float DeltaTime) {
	TickPawns(DeltaTime);
}

defaultproperties {
	bAlwaysTick=True
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
}
