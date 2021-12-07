class MutXHairFactory extends Mutator;

var PlayerPawn LocalPlayer;
var HUD LocalHUD;

var Object SettingsHelper;
var XHairSettings Settings;
var XHairLayer Layers;

var int SavedCrosshair;

simulated event PostBeginPlay() {
	InitSettings();
	if (Settings.bEnabled) {
		RegisterHUDMutator2();
	}
}

simulated final function RegisterHUDMutator2() {
	local PlayerPawn P;

	foreach AllActors(class'PlayerPawn', P) {
		if (P.myHUD != None) {
			NextHUDMutator = P.myHud.HUDMutator;
			P.myHUD.HUDMutator = Self;
			bHUDMutator = True;

			LocalPlayer = P;
			LocalHUD = P.myHUD;
		}
	}
}

simulated final function InitSettings() {
	local XHairLayer Latest;
	local XHairLayer L;

	SettingsHelper = new(none, 'XHairFactory') class'Object';
	Settings = new(SettingsHelper, 'Settings') class'XHairSettings';

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

simulated event PostRender(Canvas C) {
	local XHairLayer L;
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
			for (L = Layers; L != none; L = L.Next)
				L.Draw(C);
		}
	}

	if (NextHUDMutator != none)
		NextHUDMutator.PostRender(C);
}

simulated event Destroyed() {
	if (SavedCrosshair >= 0) {
		LocalHUD.Crosshair = SavedCrosshair;
	}
}

defaultproperties {
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy

	SavedCrosshair=-1
}
