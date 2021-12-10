class XHairSettings extends Object
	config(XHairFactory) perobjectconfig;

var config bool bEnabled;

function Initialize() {
	SaveConfig();
}

defaultproperties {
	bEnabled=False
}
