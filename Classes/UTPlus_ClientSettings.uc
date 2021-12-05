class UTPlus_ClientSettings extends Object;

var bool bSmoothFOVChanges;

event Spawned() {
}

function string GetSettingValue(string Key) {
	return Key$":"@GetPropertyText(Key)$"\n";
}

function string ToString() {
	return "Client Settings:\n"$
		GetSettingValue("bSmoothFOVChanges");
}

defaultproperties {
	bSmoothFOVChanges=False
}
