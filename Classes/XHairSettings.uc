class XHairSettings extends Object
	config(XHairFactory) perobjectconfig;

var bool bEnabled;

function Initialize() {
	SaveConfig();
}

defaultproperties {
	bEnabled=False
}
