class MutXHairFactory extends HUDMutator;

var Object SettingsHelper;
var XHairSettings Settings;
var XHairLayer Layers;

var int SavedCrosshair;

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
}

static final function string ObjectGetPropertyTextOrDefault(Object O, string Property, string Def) {
	local string Result;
	Result = O.GetPropertyText(Property);
	if (Result == "")
		return Def;
	return Result;
}

simulated event PostRender(Canvas C) {
	local XHairLayer L;
	local bool bAutoScale;
	local float Scale;

	if (Settings.bEnabled) {
		// This leads to crosshair overlap for a single frame
		if (LocalHUD.Crosshair < MaxInt) {
			SavedCrosshair = LocalHUD.Crosshair;
			LocalHUD.Crosshair = MaxInt;
		}

		if (LocalPlayer.bBehindView == false &&
			Level.LevelAction == LEVACT_None &&
			LocalPlayer.Weapon != none &&
			LocalPlayer.Weapon.bOwnsCrossHair == false
		) {
			bAutoScale = ObjectGetPropertyTextOrDefault(LocalHUD, "bAutoCrosshairScale", "False") ~= "true";
			if (bAutoScale) {
				if (C.ClipX < 512)
				    Scale = 0.5;
				else
					Scale = Clamp(int(0.1 + C.ClipX/640.0), 1, 2);
			} else {
				Scale = float(ObjectGetPropertyTextOrDefault(LocalHUD, "CrosshairScale", "1.0"));
			}

			for (L = Layers; L != none; L = L.Next)
				L.Draw(C, Scale);
		}
	}

	super.PostRender(C);
}

simulated event Destroyed() {
	if (SavedCrosshair >= 0) {
		LocalHUD.Crosshair = SavedCrosshair;
	}
}

defaultproperties {
	SavedCrosshair=-1
}
