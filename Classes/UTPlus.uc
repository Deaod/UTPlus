class UTPlus extends Engine.Mutator
    config(UTPlus);

var UTPlusDummy CompDummies;

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

function CheckDummyLife(UTPlusDummy D, out UTPlusDummy Ref) {
	if (D == none) return;

	if (D.Actual.bDeleteMe) {
		Ref = D.Next;
		CheckDummyLife(Ref, Ref);
	} else {
		CheckDummyLife(D.Next, D.Next);
	}
}

function TickPawns(float DeltaTime) {
	local Pawn P;
	local UTPlusPlayer PP;
	local UTPlusDummy D;

	if (Role != ROLE_Authority)
		return;

	CheckDummyLife(CompDummies, CompDummies);

	for (P = Level.PawnList; P != none; P = P.NextPawn) {
		if (P.IsA('Spectator') == false) {
			for (D = CompDummies; D != none; D = D.Next)
				if (D.Actual == P)
					break;

			if (D == none) {
				D = Spawn(class'UTPlusDummy');
				D.Actual = P;
				D.Next = CompDummies;
				CompDummies = D;
			}
		}

		if (P.RemoteRole == ROLE_AutonomousProxy) {
			PP = UTPlusPlayer(P);
			if (PP != none) {
				PP.ServerTick(DeltaTime);
			}
		}
	}
}

event Tick(float DeltaTime) {
	TickPawns(DeltaTime);
}

function CompensateFor(int Ping) {
	local UTPlusDummy D;

	for (D = CompDummies; D != none; D = D.Next) {
		if (D.Actual.Health > 0 &&
			D.Actual.PlayerReplicationInfo.bIsSpectator == false &&
			D.Actual.bHidden == false &&
			D.Actual.bCollideActors == true
		) {
			D.CompStart(Ping);
		}
	}
}

function EndCompensation() {
	local UTPlusDummy D;

	for (D = CompDummies; D != none; D = D.Next) {
		D.CompEnd();
	}
}

defaultproperties {
	bAlwaysTick=True
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
}
