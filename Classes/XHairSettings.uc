class XHairSettings extends Object
	config(XHairFactory) perobjectconfig;

var bool bEnabled;

event Spawned() {
	SaveConfig();
}

defaultproperties {
	bEnabled=False
}
