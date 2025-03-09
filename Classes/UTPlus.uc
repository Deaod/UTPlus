class UTPlus extends Mutator
    config(UTPlus);
// Description="Main UT+ mutator, improved gameplay"

var config bool bEnablePingCompensation;

var UTPlusDummy CompDummies;

var UTPlusGameEventChain GameEventChain;

function UTPlusDummy FindDummy(Pawn P) {
	local UTPlusDummy D;

	for (D = CompDummies; D != none; D = D.Next)
		if (D.Actual == P)
			return D;

	return none;
}

function PostBeginPlay() {
	super.PostBeginPlay();

	GameEventChain = new(XLevel) class'UTPlusGameEventChain';
	GameEventChain.Play(Level.TimeSeconds);
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

function CheckGameEvents() {
	if (Level.Pauser != "")	{	// This code is to avoid players being kicked when paused.
		if (GameEventChain.IsPlaying())
			GameEventChain.Pause(Level.TimeSeconds);
	} else {
		if (GameEventChain.IsPaused())
			GameEventChain.Play(Level.TimeSeconds);
	}
}

function float RealPlayTime(float TimeStamp, float DeltaTime) {
	return GameEventChain.RealPlayTime(TimeStamp, DeltaTime);
}

event Tick(float DeltaTime) {
	CheckGameEvents();
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

function bool HandleAdminMutateComamnd(string C, PlayerPawn Sender) {
	if (Sender.PlayerReplicationInfo == none || Sender.PlayerReplicationInfo.bAdmin == false)
		return false;

	if (C ~= "EnablePingCompensation") {
		default.bEnablePingCompensation = true;
		Sender.ClientMessage("Ping Compensation Enabled!");
		return true;
	} else if (C ~= "DisablePingCompensation") {
		default.bEnablePingCompensation = false;
		Sender.ClientMessage("Ping Compensation Disabled!");
		return true;
	}

	return false;
}

function bool HandleMutateComand(string C, PlayerPawn Sender) {
	if (C ~= "version") {
		Sender.ClientMessage(class'StringUtils'.static.GetPackage());
		return true;
	}
	return false;
}

function Mutate(string MutateString, PlayerPawn Sender) {
	if (Left(MutateString, 6) ~= "UTPlus") {
		MutateString = class'StringUtils'.static.Trim(Mid(MutateString, 6, Len(MutateString)));
		if (HandleMutateComand(MutateString, Sender) == false)
			if (HandleAdminMutateComamnd(MutateString, Sender) == false)
				Sender.ClientMessage("Unknown UTPlus Command:"@MutateString);
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
