class MutHUDClock extends HUDMutator;
// Description="Shows remaining/elapsed time on HUD"

#exec Texture Import File=Textures\HUDClockBackground.pcx Name=HUDClockBackground Mips=Off

var bool bInOvertime;
var int OvertimeOffset;
var int EndOfGameTime;
var bool bPaused;
var float GRISecondCountOffset;

simulated event PostRender(Canvas C) {
	if (LocalHUD.IsA('ChallengeHUD') &&
		ChallengeHUD(LocalHUD).bHideHUD == false &&
		(LocalPlayer.PlayerReplicationInfo == none || LocalPlayer.PlayerReplicationInfo.bIsSpectator == false)
	) {
		class'CanvasUtils'.static.SaveCanvas(C);
		DrawTime(ChallengeHUD(LocalHUD), C);
		class'CanvasUtils'.static.RestoreCanvas(C);
	}

	super.PostRender(C);
}

simulated function int GetClockTime(HUD H) {
	local int Rem;
	local TournamentGameReplicationInfo TGRI;

	TGRI = TournamentGameReplicationInfo(H.PlayerOwner.GameReplicationInfo);

	if (TGRI != none && (bPaused ^^ (H.Level.Pauser != ""))) {
		bPaused = !bPaused;
		if (bPaused) {
			GRISecondCountOffset = H.Level.TimeSeconds - TGRI.SecondCount;
		} else {
			TGRI.SecondCount = H.Level.TimeSeconds - GRISecondCountOffset;
		}
	}

	if (TGRI != none && TGRI.GameEndedComments == "") {
		// game hasnt ended yet
		Rem = TGRI.RemainingTime;
		if (Rem == 0) {
			if (TGRI.TimeLimit <= 0) {
				// playing with score limit
				EndOfGameTime = TGRI.ElapsedTime;
			} else {
				// regular play-time is over
				if (bInOvertime == false)
					OvertimeOffset = TGRI.ElapsedTime;

				bInOvertime = true;
				EndOfGameTime = TGRI.ElapsedTime - OvertimeOffset;
			}
		} else {
			// playing with time limit
			bInOvertime = false;
			EndOfGameTime = Rem;
		}
	}

	return EndOfGameTime;
}

simulated function DrawTime(ChallengeHUD H, Canvas C) {
	local int Min, Sec;
	local float FullSize;
	local float X, Y;
	local float XL;
	local int Seconds;
	local float CharX, CharY;
	local float CharXScaled, CharYScaled;

	CharX = 25.0;
	CharY = 64.0;
	CharXScaled = CharX * H.Scale;
	CharYScaled = CharY * H.Scale;

	Seconds = GetClockTime(H);
	Min = Seconds / 60;
	Sec = Seconds % 60;

	if (Min >= 100)
		XL = 25; // extra full 7-Seg char
	else
		XL = 0;

	C.Style = H.Style;
	C.DrawColor = H.HUDColor;

	if (H.bHideStatus) {
		if (H.bHideAllWeapons) {
			X = 0.5*C.ClipX - 384*H.Scale - XL*H.Scale;
			Y = C.ClipY - 64*H.Scale;
		} else {
			X = C.ClipX - 140*H.Scale - XL*H.Scale;
			Y = 128*H.Scale;
		}
	} else {
		X = C.ClipX - 128*H.StatusScale*H.Scale - 140*H.Scale - XL*H.Scale;
		Y = 128*H.Scale;
	}

	C.SetPos(X,Y);
	C.DrawTile(Texture'HUDClockBackground', 128*H.Scale + XL*H.Scale, 64*H.Scale, 0, 0, 128.0, 64.0);

	C.Style = H.Style;
	C.DrawColor = H.WhiteColor;

	FullSize = CharXScaled * 4 + 12 * H.Scale; //At least 4 digits and : (extra size not counted)

	C.SetPos( X + 64 * H.Scale, Y + 12 * H.Scale);
	C.CurX -= (FullSize / 2);
	if (Min >= 100) {
		C.DrawTile(Texture'BotPack.HudElements1', CharXScaled, CharYScaled, ((Min/100)%10)*CharX, 0, CharX, CharY);
		Min = Min%100;
	}
	C.DrawTile(Texture'BotPack.HudElements1', CharXScaled, CharYScaled, (Min/10)*CharX, 0, CharX, CharY);
	C.DrawTile(Texture'BotPack.HudElements1', CharXScaled, CharYScaled, (Min%10)*CharX, 0, CharX, CharY);
	C.CurX -= 7 * H.Scale;
	C.DrawTile(Texture'BotPack.HudElements1', CharXScaled, CharYScaled, 25, 64, CharX, CharY); //DOUBLE DOT HERE
	C.CurX -= 6 * H.Scale;
	C.DrawTile(Texture'BotPack.HudElements1', CharXScaled, CharYScaled, (Sec/10)*CharX, 0, CharX, CharY);
	C.DrawTile(Texture'BotPack.HudElements1', CharXScaled, CharYScaled, (Sec%10)*CharX, 0, CharX, CharY);
}

