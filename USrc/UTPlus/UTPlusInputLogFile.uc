class UTPlusInputLogFile extends StatLogFile;

var string LogId;
var bool bStarted;

event BeginPlay() {
    // empty to override StatLog
}

function string PadTo2Digits(int A) {
    if (A < 10)
        return "0"$A;
    return string(A);
}

function StartLog() {
    local string FileName;

    bWorld = false;
    FileName = "../Logs/"$LogId$"_"$Level.Year$PadTo2Digits(Level.Month)$PadTo2Digits(Level.Day)$"_"$PadTo2Digits(Level.Hour)$PadTo2Digits(Level.Minute);
    StatLogFile = FileName$".tmp.csv";
    StatLogFinal = FileName$".csv";

    OpenLog();

    // header
    FileLog("Type|TimeStamp|Delta|Forw|Back|Left|Right|Walk|Duck|Jump|Dodge|Fire|AltFire|ForceFire|ForceAltFire|ViewRot|Location|Velocity|DodgeDir");

    bStarted = true;
}

function StopLog() {
	if (bStarted == false)
		return;
	FlushLog();
	CloseLog();
	bStarted = false;
}

function LogInputGeneric(string Type, UTPlusSavedInput I) {
	if (bStarted == false)
		StartLog();

	FileLog(Type$"|"$I.TimeStamp$"|"$(I.Delta*1000.0)$"|"$I.bForw$"|"$I.bBack$"|"$I.bLeft$"|"$I.bRigh$"|"$I.bWalk$"|"$I.bDuck$"|"$I.bJump$"|"$I.bDodg$"|"$I.bFire$"|"$I.bAFir$"|"$I.bFFir$"|"$I.bFAFr$"|"$(I.SavedViewRotation.Pitch&0xFFFF)$","$(I.SavedViewRotation.Yaw&0xFFFF)$"|"$I.SavedLocation$"|"$I.SavedVelocity$"|"$I.SavedDodgeDir);
}

function LogInput(UTPlusSavedInput I) {
	LogInputGeneric("Input", I);
}

function LogCAP(float TimeStamp, vector Loc, vector Vel, Actor NewBase) {
	if (bStarted == false)
		StartLog();
	
	if (Mover(NewBase) != none)
		Loc += NewBase.Location;

	FileLog("CAP|"$TimeStamp$"|||||||||||||||"$Loc$"|"$Vel$"|");
}

function LogInputReplay(UTPlusSavedInput I) {
	LogInputGeneric("Replay", I);
}
