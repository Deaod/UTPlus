class MutXHairFactory extends HUDMutator
	config(User);
// Description="Allows rendering custom crosshairs made up of multiple layers"

var Object SettingsHelper;
var XHairSettings Settings;
var XHairLayer Layers;

var config int SavedCrosshair;

simulated event PostBeginPlay() {
	super.PostBeginPlay();
	InitSettings();
}

simulated final function InitSettings() {
	local XHairLayer Latest;
	local XHairLayer L;

	SettingsHelper = new(none, 'XHairFactory') class'Object';
	Settings = new(SettingsHelper, 'Settings') class'XHairSettings';
	Settings.Initialize();

	L = new(SettingsHelper) class'XHairLayer';
	if (L.bUse == false)
		return;
	Layers = L;
	Latest = L;
	L = new(SettingsHelper) class'XHairLayer';
	while(L.bUse) {
		Latest.Next = L;
		Latest = L;
		L = new(SettingsHelper) class'XHairLayer';
	}

	for (L = Layers; L != none; L = L.Next)
		L.Initialize();
}

static final function string ObjectGetPropertyTextOrDefault(Object O, string Property, string Def) {
	local string Result;
	Result = O.GetPropertyText(Property);
	if (Result == "")
		return Def;
	return Result;
}

simulated final function DrawCrosshair(Canvas C, float Scale) {
	local XHairLayer L;
	
	class'CanvasUtils'.static.SaveCanvas(C);

	C.SetOrigin(0, 0);
	C.SetClip(C.SizeX, C.SizeY);

	for (L = Layers; L != none; L = L.Next)
		L.Draw(C, Scale);

	class'CanvasUtils'.static.RestoreCanvas(C);
}

simulated event PostRender(Canvas C) {
	local bool bAutoScale;
	local float Scale;

	if (Settings == none)
		InitSettings();

	if (Settings.bEnabled) {
		// This leads to crosshair overlap for a single frame
		if (LocalHUD.Crosshair < MaxInt) {
			if (SavedCrosshair < 0) {
				SavedCrosshair = LocalHUD.Crosshair;
				SaveConfig();
			}
			LocalHUD.Crosshair = MaxInt;
		}

		if (LocalPlayer.bBehindView == false &&
			Level.LevelAction == LEVACT_None &&
			LocalPlayer.Weapon != none &&
			LocalPlayer.Weapon.bOwnsCrossHair == false
		) {
			bAutoScale = ObjectGetPropertyTextOrDefault(LocalHUD, "bAutoCrosshairScale", "False") ~= "true";
			if (bAutoScale) {
				if (C.SizeX < 512)
				    Scale = 0.5;
				else
					Scale = Clamp(int(0.1 + C.SizeX/640.0), 1, 2);
			} else {
				Scale = float(ObjectGetPropertyTextOrDefault(LocalHUD, "CrosshairScale", "1.0"));
			}

			DrawCrosshair(C, Scale);
		}
	}

	super.PostRender(C);
}

simulated event Destroyed() {
	if (SavedCrosshair >= 0) {
		LocalHUD.Crosshair = SavedCrosshair;
		SavedCrosshair = -1;
		SaveConfig();
	}
}

defaultproperties {
	SavedCrosshair=-1
}
