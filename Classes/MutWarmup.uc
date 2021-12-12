class MutWarmup extends HUDMutator
	config(Warmup);

var config int WarmupTimeLimit;

var bool bPerpetualWarmup;
var int GameTimeLimit;
var int GameFragLimit;
var int GameScoreLimit;
var StatLog GameLocalLog;
var StatLog GameWorldLog;

const MaxWeapons = 32;
var int WeaponCount;
var string WeaponsToGive[MaxWeapons];

var localized string ReadyText;
var localized color ReadyColor;
var localized string NotReadyText;
var localized color NotReadyColor;
var localized string WarmupText;
var localized string ReadyHintText;
var localized color ReadyHintColor;

var bool bInWarmup;

replication {
	reliable if (Role == ROLE_Authority)
		bInWarmup;
}

simulated function PostRender(Canvas C) {
	local string Message;
	local color MessageColor;
	local float X, Y;
	local float HintY;
	local ChallengeHUD CH;

	super.PostRender(C);

	if (LocalPlayer == none || bInWarmup == false)
		return;

	// Write WARMUP - READY or WARMUP - NOT READY on screen
	if (TournamentPlayer(LocalPlayer).bReadyToPlay) {
		Message = WarmupText@"-"@ReadyText;
		MessageColor = ReadyColor;
	} else {
		Message = WarmupText@"-"@NotReadyText;
		MessageColor = NotReadyColor;
	}

	CH = ChallengeHUD(LocalHUD);

	class'CanvasUtils'.static.SaveCanvas(C);

	C.Style = ERenderStyle.STY_Normal;

	C.Font = CH.MyFonts.GetSmallFont(C.SizeX);
	C.DrawColor = ReadyHintColor;
	C.TextSize(ReadyHintText, X, Y);
	HintY = C.SizeY - (64*CH.Scale) - Y - 3;
	C.SetPos((C.SizeX - X)*0.5, HintY);
	C.DrawText(ReadyHintText);

	C.Font = CH.MyFonts.GetBigFont(C.SizeX);
	C.DrawColor = MessageColor;
	C.TextSize(Message, X, Y);
	C.SetPos(C.SizeX*0.5 - X*0.5, HintY - Y - 5);
	C.DrawText(Message);

	class'CanvasUtils'.static.RestoreCanvas(C);
}

state auto Initial {
Begin:
	Sleep(0);
	GoToState('Warmup');
}

state Warmup {
	function BeginState() {
		local DeathMatchPlus DMP;
		local TeamGamePlus TGP;
		DMP = DeathMatchPlus(Level.Game);

		DMP.bRequireReady = true;
		DMP.bNetReady = false;
		DMP.CountDown = 0;
		GameTimeLimit = DMP.TimeLimit;
		bPerpetualWarmup = (WarmupTimeLimit <= 0);
		DMP.TimeLimit = WarmupTimeLimit;
		DMP.RemainingTime = DMP.TimeLimit*60;
		GameFragLimit = DMP.FragLimit;
		DMP.FragLimit = 0;
		if (DMP.IsA('TeamGamePlus')) {
			TGP = TeamGamePlus(DMP);
			GameScoreLimit = TGP.GoalTeamScore;
			TGP.GoalTeamScore = 0;
		}

		GameLocalLog = DMP.LocalLog;
		GameWorldLog = DMP.WorldLog;
		DMP.LocalLog = none;
		DMP.WorldLog = none;

		DetermineWeapons();
		SetTimer(Level.TimeDilation, true);

		bInWarmup = true;
	}

	function ModifyPlayer(Pawn P) {
		local DeathMatchPlus DMP;
		local int x;
		DMP = DeathMatchPlus(Level.Game);

		for (x = 0; x < WeaponCount; ++x) {
			DMP.GiveWeapon(P, WeaponsToGive[x]);
		}

		super.ModifyPlayer(P);
	}

	function Timer() {
		local DeathMatchPlus DMP;
		local Pawn P;
		DMP = DeathMatchPlus(Level.Game);

		// deal with changing gamespeed
		if (TimerRate != Level.TimeDilation)
			SetTimer(Level.TimeDilation, true);

		ResetPlayers();
		ResetTeams();

		if (bPerpetualWarmup == false && DMP.RemainingTime <= 10)
			for (P = Level.PawnList; P != none; P = P.NextPawn)
				if (P.IsA('PlayerPawn'))
					PlayerPawn(P).bReadyToPlay = true;
			
		if (AreAllPlayersReady())
			GoToState('WarmupCountdown');
	}
}

state WarmupCountdown {
	function BeginState() {
		local Pawn P;
		local DeathMatchPlus DMP;
		DMP = DeathMatchPlus(Level.Game);

		foreach AllActors(class'Pawn', P) {
			if (P.IsA('Bot') || (P.IsA('PlayerPawn') && P.IsA('Spectator') == false)) {
				P.Health = 0;
				P.Died(P, 'Suicided', P.Location);
				P.PlayerReStartState = 'PlayerWaiting';
			}
		}

		ResetGame(DeathMatchPlus(Level.Game));
		ResetPlayers();
		ResetTeams();

		bInWarmup = false;
	}

	function Timer() {
		local DeathMatchPlus DMP;
		DMP = DeathMatchPlus(Level.Game);

		if (DMP.CountDown <= 1)
			GoToState('WarmupEnded');
	}
}

state WarmupEnded {
Begin:
	SetTimer(0.0, false);
	Reset();
	GoToState('');
}

function bool AreAllPlayersReady() {
	local PlayerPawn P;

	if (Level.Game.NumPlayers == Level.Game.MaxPlayers) {
		foreach AllActors(class'PlayerPawn', P) {
			if (P.IsA('Spectator') == false && P.bReadyToPlay == false) {
				return false;
			}
		}
		return true;
	}

	return false;
}

function Reset() {
	ResetPlayers();
	ResetPickups();
	ResetCarcasses();
	ResetProjectiles();
	ResetObjectives();
}

function ResetGame(DeathMatchPlus G) {
	local TeamGamePlus TGP;
	local PlayerPawn PP;
	local TournamentGameReplicationInfo TGRI;

	TGRI = TournamentGameReplicationInfo(G.GameReplicationInfo);

	G.bOvertime = false;
	G.bRequireReady = true;
	G.CountDown = 10;
	G.TimeLimit = GameTimeLimit;
	G.RemainingTime = GameTimeLimit*60;
	TGRI.RemainingMinute = G.RemainingTime;
	TGRI.bStopCountDown = true;
	G.FragLimit = GameFragLimit;
	if (G.IsA('TeamGamePlus')) {
		TGP = TeamGamePlus(G);
		TGP.GoalTeamScore = GameScoreLimit;
	}
	G.LocalLog = GameLocalLog;
	G.WorldLog = GameWorldLog;

	foreach AllActors(class'PlayerPawn', PP) {
		if (G.LocalLog != none)
			G.LocalLog.LogPlayerConnect(PP);
		if (G.WorldLog != none)
			G.WorldLog.LogPlayerConnect(PP);
	}
	if (G.LocalLog != none)
		G.LocalLog.FlushLog();
	if (G.WorldLog != none)
		G.WorldLog.FlushLog();
}

function ResetPlayers() {
	local PlayerReplicationInfo PRI;

	foreach AllActors(class'PlayerReplicationInfo', PRI) {
		PRI.Score = 0;
		PRI.Deaths = 0;
	}
}

function ResetTeams() {
	local TeamInfo T;
	foreach AllActors(class'TeamInfo', T) {
		T.Score = 0;
	}
}

function ResetObjectives() {
	local CTFFlag F;
	local ControlPoint CP;
	local FortStandard FS;

	foreach AllActors(class'CTFFlag', F) {
		F.SendHome();
	}

	foreach AllActors(Class'ControlPoint', CP) {
		CP.Enable('Touch');
	}

	foreach AllActors(Class'FortStandard', FS) {
		FS.Enable('Touch');
		FS.Enable('Trigger');
		FS.SetCollision(true, false, false);
	}
}

function ResetPickups() {
	local Inventory I;

	foreach AllActors(class'Inventory', I) {
		if (I.bTossedOut || I.bHeldItem)
			I.Destroy();
		else if (I.IsInState('Sleeping'))
			I.GotoState('Pickup');
	}
}

function ResetCarcasses() {
	local Carcass C;

	foreach AllActors(class'Carcass', C) {
		if (!C.bStatic && !C.bNoDelete) {
			C.Destroy();
		}
	}
}

function ResetProjectiles() {
	local Projectile P;

	foreach AllActors(class'Projectile', P) {
		if (!P.bStatic && !P.bNoDelete) {
			P.Destroy();
		}
	}
}

function AddWeaponToGive(string WeaponClassName) {
	local int x;
	for (x = 0; x < WeaponCount; ++x)
		if (WeaponsToGive[x] ~= WeaponClassName)
			return;

	if (WeaponCount >= MaxWeapons) {
		Log("Too many Weapons on map! Discarding"@WeaponClassName, 'IGPlus');
		return;
	}

	WeaponsToGive[WeaponCount++] = WeaponClassName;
}

function DetermineWeapons() {
	local Weapon W;

	if (Level.Game.BaseMutator != None)
		AddWeaponToGive(string(Level.Game.BaseMutator.MutatedDefaultWeapon()));

	// Find the rest of the weapons around the map.
	foreach AllActors(Class'Weapon', W)
		AddWeaponToGive(string(W.Class));
}

defaultproperties {
	WarmupTimeLimit=0

	ReadyText="READY"
	ReadyColor=(R=255,G=255,B=255,A=255)
	NotReadyText="NOT READY"
	NotReadyColor=(R=255,G=255,B=255,A=255)
	WarmupText="Warmup"
	ReadyHintText="Use console command 'Ready' to ready up!"
	ReadyHintColor=(R=255,G=255,B=255,A=255)
	bInWarmup=True
}
