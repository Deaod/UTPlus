class UTPlusClientSettings extends Object
	config(UTPlus) perobjectconfig;

event Initialize() {
	SaveConfig();
}

function string GetSettingValue(string Key) {
	return Key$":"@GetPropertyText(Key)$"\n";
}

function string ToString() {
	return "Client Settings:\n"$
		"";
}

defaultproperties {
}
