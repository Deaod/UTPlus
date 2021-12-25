class UTPlus extends Mutator
    config(UTPlus);

var config bool bEnablePingCompensation;

var UTPlusDummy CompDummies;

function UTPlusDummy FindDummy(Pawn P) {
	local UTPlusDummy D;

	for (D = CompDummies; D != none; D = D.Next)
		if (D.Actual == P)
			return D;

	return none;
}

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

function ModifyPlayer(Pawn P) {
	local UTPlusDummy D;

	super.ModifyPlayer(P);

	D = FindDummy(P);
	if (D == none) {
		D = Spawn(class'UTPlusDummy');
		D.Actual = P;
		D.Next = CompDummies;
		CompDummies = D;
	}
}

function TickPawns(float DeltaTime) {
	local Pawn P;
	local UTPlusPlayer PP;
	local UTPlusDummy D;

	if (Role != ROLE_Authority)
		return;

	for (P = Level.PawnList; P != none; P = P.NextPawn) {
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
		if (D.Actual != none &&
			D.Actual.Health > 0 &&
			D.Actual.PlayerReplicationInfo != none &&
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

function HandleMutateComand(string C, PlayerPawn Sender) {
	if (C ~= "version") {
		Sender.ClientMessage(class'StringUtils'.static.GetPackage());
	} else if (C ~= "EnablePingCompensation") {
		if (Sender.PlayerReplicationInfo.bAdmin) {
			default.bEnablePingCompensation = true;
			Sender.ClientMessage("Ping Compensation Enabled!");
		} else {
			Sender.ClientMessage("Please Log In As Admin!");
		}
	} else if (C ~= "DisablePingCompensation") {
		if (Sender.PlayerReplicationInfo.bAdmin) {
			default.bEnablePingCompensation = false;
			Sender.ClientMessage("Ping Compensation Disabled!");
		} else {
			Sender.ClientMessage("Please Log In As Admin!");
		}
	} else {
		Sender.ClientMessage("Unknown UTPlus Command:"@C);
	}
}

function Mutate(string MutateString, PlayerPawn Sender) {
	if (Left(MutateString, 6) ~= "UTPlus") {
		MutateString = class'StringUtils'.static.Trim(Mid(MutateString, 6, Len(MutateString)));
		HandleMutateComand(MutateString, Sender);
	} else {
		super.Mutate(MutateString, Sender);
	}
}

defaultproperties {
	bEnablePingCompensation=True

	bAlwaysTick=True
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
}
