class XHairSettings extends Object
	config perobjectconfig;

var bool bEnabled;

event Spawned() {
	SaveConfig();
}

defaultproperties {
	bEnabled=False
}
