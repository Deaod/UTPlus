class MutAutoPause extends Mutator;

var Mutator WarmupMutator;
var bool bWarmupMutatorSearchDone;

var int PlayerCount;
var int TeamPlayerCount[4];
enum EAutoPauseReason {
	APR_None,
	APR_PlayerLeft,
	APR_TeamChange,
	APR_AdminPaused
};
var EAutoPauseReason AutoPauseReason;

var config int CountdownSeconds;
var int CountdownCurrent;

function Mutator FindWarmupMutator() {
	if (bWarmupMutatorSearchDone)
		return WarmupMutator;

	if (WarmupMutator == none)
		foreach AllActors(class'Mutator', WarmupMutator)
			if (WarmupMutator.IsA('MutWarmup'))
				break;

	if (WarmupMutator != none && WarmupMutator.IsA('MutWarmup') == false)
		WarmupMutator = none;

	bWarmupMutatorSearchDone = true;
	return WarmupMutator;
}

function bool IsInWarmup() {
	local Mutator M;
	local bool bInWarmup;
	local bool bCountDown;

	M = FindWarmupMutator();
	if (M != none)
		bInWarmup = (M.GetPropertyText("bInWarmup") ~= "true");

	if (Level.Game.IsA('DeathMatchPlus'))
		bCountDown = (DeathMatchPlus(Level.Game).CountDown > 0);

	return bInWarmup || bCountDown;
}

function CheckAutoPause() {
	if (Level.Pauser == "" && Level.Game.NumPlayers < PlayerCount) {
		AutoPauseReason = APR_PlayerLeft;
		GoToState('AutoPaused');
	}

	if (Level.Pauser != "" && AutoPauseReason == APR_None) {
		AutoPauseReason = APR_AdminPaused;
		GoToState('AdminPaused');
	}
}

auto state Warmup {
	event Tick(float DeltaTime) {
		if (IsInWarmup() == false)
			GoToState('Play');

		super.Tick(DeltaTime);
	}
}

state Play {
	function CalibratePlayerCount() {
		local Pawn P;

		PlayerCount = Level.Game.NumPlayers;

		if (Level.Game.bTeamGame)
			for (P = Level.PawnList; P != none; P = P.NextPawn)
				if (P.IsA('Spectator') == false && P.PlayerReplicationInfo != none)
					TeamPlayerCount[P.PlayerReplicationInfo.Team] += 1;
	}

	event BeginState() {
		CalibratePlayerCount();
	}

	event Tick(float DeltaTime) {
		super.Tick(DeltaTime);

		if (Level.Game.NumPlayers > PlayerCount) {
			CalibratePlayerCount();
		}

		CheckAutoPause();
	}
}

state AdminPaused {
	event Tick(float DeltaTime) {
		super.Tick(DeltaTime);

		if (Level.Pauser == "") {
			Pause();
			GoToState('UnpauseCountdown');
		}
	}
}

state AutoPaused {
	event BeginState() {
		Pause();
	}

	event Tick(float DeltaTime) {
		super.Tick(DeltaTime);

		if (Level.Pauser == "") {
			// Admin unpaused the game
			Pause();
			GoToState('UnpauseCountdown');
			return;
		}

		if (Level.Game.NumPlayers >= PlayerCount || Level.Game.NumPlayers == 0) {
			GoToState('UnpauseCountdown');
			return;
		}
	}
}

state UnpauseCountdown {
	event BeginState() {
		CountdownCurrent = CountdownSeconds + 1;
		Timer();
	}

	event Timer() {
		if (IsInState('UnpauseCountdown') == false)
			return;

		CountdownCurrent -= 1;

		if (CountdownCurrent == 0) {
			Unpause();
			GoToState('Play');
			return;
		}

		if (CountdownCurrent <= 10) {
			BroadcastLocalizedMessage(class'TimeMessage', 16 - CountdownCurrent);
		}

		SetTimer(Level.TimeDilation, false);
	}

	event Tick(float DeltaTime) {
		super.Tick(DeltaTime);

		if (Level.Pauser == "")
			Pause();

		CheckAutoPause();
	}

	event EndState() {
		SetTimer(0, false);
	}
}

function Pause() {
	Level.Pauser = "MutAutoPause";
}

function Unpause() {
	Level.Pauser = "";
	AutoPauseReason = APR_None;
}

defaultproperties {
	CountdownSeconds=5

	bAlwaysTick=True
}
