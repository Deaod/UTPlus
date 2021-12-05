class UTPlusSpectator extends Botpack.CHSpectator;

var UTPlus_ClientSettings Settings;
var Object SettingsHelper;

simulated final function UTPlus_InitSettings() {
	local UTPlusPlayer P;
	local UTPlusSpectator S;

	foreach AllActors(class'UTPlusPlayer', P) {
		if (P.Settings != none) {
			Settings = P.Settings;
			return;
		}
	}

	foreach AllActors(class'UTPlusSpectator', S) {
		if (S.Settings != none) {
			Settings = S.Settings;
			return;
		}
	}

	SettingsHelper = new(none, 'UTPlus') class'Object';
	Settings = new(SettingsHelper, 'ClientSettings') class'UTPlus_ClientSettings';
}

simulated event PostBeginPlay() {
	super.PostBeginPlay();

	UTPlus_InitSettings();
}

simulated event Possess() {
	super.Possess();

	UTPlus_InitSettings();
}
