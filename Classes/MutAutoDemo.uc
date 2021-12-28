class MutAutoDemo extends Mutator
	config(AutoDemo);

var Object SettingsHelper;
var AutoDemoSettings Settings;

var config bool bForceRecord;
var bool bGameStarted;
var bool bStartForceRecord;

var PlayerPawn LocalPlayer;
var AutoDemoLevelBase LevelBase;

replication {
	reliable if (Role == ROLE_Authority)
		bGameStarted,
		bStartForceRecord;
}

simulated final function InitSettings() {
	SettingsHelper = new(none, 'AutoDemo') class'Object';
	Settings = new(SettingsHelper, 'Settings') class'AutoDemoSettings';
	Settings.Initialize();
}

final function bool IsInWarmup() {
	local Mutator M;
	foreach AllActors(class'Mutator', M) {
		if (M.IsA('MutWarmup')) {
			return M.GetPropertyText("bInWarmup") ~= "true";
		}
	}
	return false;
}

simulated final function PlayerPawn GetLocalPlayer() {
	if (LocalPlayer != none)
		return LocalPlayer;

	foreach AllActors(class'PlayerPawn', LocalPlayer) {
		if (LocalPlayer.Player != none && LocalPlayer.Player.IsA('Viewport')) {
			return LocalPlayer;
		}
	}

	LocalPlayer = none;
	return none;
}

simulated final function string FindClanTags() {
	local PlayerReplicationInfo PRI;
	local GameReplicationInfo GRI;
	local string PrefixTags[4];
	local string SuffixTags[4];
	local string Tags[4];
	local int TeamSize[4];
	local int MaxTeams;
	local int Team;
	local int MixCount;
	local string Result;

	foreach AllActors(class'GameReplicationInfo', GRI)
		break;

	if (GRI.bTeamGame == false)
		return "FFA";

	foreach AllActors(class'PlayerReplicationInfo', PRI) {
		if (PRI.bIsSpectator == true || PRI.bIsABot == true)
			continue;

		if (TeamSize[PRI.Team] == 0) {
			PrefixTags[PRI.Team] = PRI.PlayerName;
			SuffixTags[PRI.Team] = PRI.PlayerName;
		} else {
			PrefixTags[PRI.Team] = class'StringUtils'.static.CommonPrefix(PrefixTags[PRI.Team], PRI.PlayerName);
			SuffixTags[PRI.Team] = class'StringUtils'.static.CommonSuffix(SuffixTags[PRI.Team], PRI.PlayerName);
		}

		++TeamSize[PRI.Team];
	}

	for (MaxTeams = 0; MaxTeams < 4; ++MaxTeams)
		if (TeamSize[MaxTeams] == 0)
			break;

	for (Team = 0; Team < MaxTeams; ++Team) {
		Tags[Team] = class'StringUtils'.static.MergeAffixes(PrefixTags[Team], SuffixTags[Team]);
		if (Len(Tags[Team]) == 0) {
			Tags[Team] = "Mix";
			++MixCount;
		}
	}

	if (MaxTeams <= 1 || MixCount > 1)
		return "Unknown";

	Result = Tags[0];
	for (Team = 1; Team < MaxTeams; ++Team)
		Result = Result$"_"$Tags[Team];

	return Result;
}

simulated final function string FindLocalPlayerName() {
	local string Result;
	local PlayerPawn P;

	Result = "ServerSide";

	P = GetLocalPlayer();
	if (P != none)
		Result = P.PlayerReplicationInfo.PlayerName;

	return Result;
}

simulated final function string FixFileName(string S, string ReplaceChar) {
	local int i;
	local string S2,Result;

	Result = "";
	for (i = 0; i < Len(S); i++) {
		S2 = Mid(S,i,1);
		if (Asc(S2) < 32 || Asc(S2) > 128)
			S2 = ReplaceChar;
		else {
			switch(S2) {
				case "|":
				case ".":
				case ":":
				case "%":
				case "\\":
				case "/":
				case "*":
				case "?":
				case ">":
				case "<":
				case "(":	//
				case ")":	//
				case "`":	//
				case "'":	//
				case "�":	//
				case "&":	// Weak Linux, Weak
				case " ":
					S2 = ReplaceChar;
					break;
			}
		}
		Result = Result$S2;
	}
	return Result;
}

simulated final function string PadNumberToTwoDigits(int Val) {
	if (Val < 10)
		return "0"$string(Val);
	else
		return string(Val);
}

simulated final function string CreateDemoName(string DemoName) {
	local int i;
	local string S;
	local string Result;

	if (DemoName == "")
		DemoName = "%l_[%y_%m_%d_%t]_[%c]_%e";	// Incase admin messes up :/

	while(true) {
		i = InStr(DemoName, "%");
		if (i < 0) break;

		S = Mid(DemoName,i+1,1);
		switch(Caps(S)) {
			case "E":
				S = string(Level);
				S = Left(S,InStr(S,"."));
				break;
			case "F":
				S = Level.Title;
				break;
			case "D":
				S = PadNumberToTwoDigits(Level.Day);
				break;
			case "M":
				S = PadNumberToTwoDigits(Level.Month);
				break;
			case "Y":
				S = string(Level.Year);
				break;
			case "H":
				S = PadNumberToTwoDigits(Level.Hour);
				break;
			case "N":
				S = PadNumberToTwoDigits(Level.Minute);
				break;
			case "T":
				S = PadNumberToTwoDigits(Level.Hour) $ PadNumberToTwoDigits(Level.Minute);
				break;
			case "C":	// Try to find 2 unique tags within the 2 teams. If only 2 players exists, add their names.
				S = FindClanTags();
				break;
			case "L":
				S = FindLocalPlayerName();
				break;
			case "%":
				break;
			default:
				S = "%"$S;
				break;
		}
		Result = Result $ Left(DemoName, i) $ S;
		DemoName = Mid(DemoName, i + 2);
	}
	
	return Settings.DemoPath $ FixFileName(Result $ DemoName, Settings.DemoChar);
}

simulated final function StartDemoRec() {
	local string Result;
	local PlayerPawn P;
	P = GetLocalPlayer();
	if (P == none) {
		Level.ConsoleCommand("DemoRec"@CreateDemoName(Settings.DemoMask));
	} else {
		Result = P.ConsoleCommand("DemoRec"@CreateDemoName(Settings.DemoMask));
		P.ClientMessage(Result);
	}
}

state auto WaitingForStart {
	final function TickGameStartDetection() {
		local DeathMatchPlus DMP;
		
		DMP = DeathMatchPlus(Level.Game);
		if (DMP.CountDown <= 1) {
			if (IsInWarmup()) {
				GoToState('WaitingForWarmupEnd');
			} else {
				bGameStarted = true;
			}
		}
	}

	simulated event Tick(float DeltaTime) {
		TickGameStartDetection();

		if (Settings == none)
			InitSettings();

		if (bGameStarted) {
			if (Level.NetMode != NM_Client)
				bStartForceRecord = bForceRecord;

			if (LevelBase == none)
				SetPropertyText("LevelBase", GetPropertyText("XLevel"));

			if ((LevelBase == none || LevelBase.DemoRecDriver == none) &&
				bGameStarted && (Settings.bEnable || (Level.NetMode != NM_DedicatedServer && bStartForceRecord))
			) {
				StartDemoRec();
			}
			
			GoToState('Done');
		}

		super.Tick(DeltaTime);
	}
}

state WaitingForWarmupEnd {
	event Tick(float DeltaTime) {
		local DeathMatchPlus DMP;
		
		DMP = DeathMatchPlus(Level.Game);
		if (DMP.CountDown > 1) {
			GoToState('WaitingForStart');
		}

		super.Tick(DeltaTime);
	}
}

state Done {
	simulated function BeginState() {
		Disable('Tick');
	}
}

defaultproperties {
	bForceRecord=False

	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
}
