class AutoDemoSettings extends Object
	config(AutoDemo) perobjectconfig;

var config bool bEnable;
var config string DemoMask;
var config string DemoPath;
var config string DemoChar;

function Initialize() {
	SaveConfig();
}

defaultproperties {
	bEnable=False
	DemoMask="%l_[%y_%m_%d_%t]_[%c]_%e"
	DemoPath=
	DemoChar=
}
