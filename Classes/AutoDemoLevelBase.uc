class AutoDemoLevelBase extends Object;

struct FURL
{
	var string Protocol;
	var string Host;
	var int Port;
	var string Map;
	var array<string> Op;
	var string Portal;
	var bool bValid;
};

var private native const int NetNotify;		// Internal

var const Array<Object> Actors;

var const Object Level;

var const Object NetDriver;
var const Object Engine;
var const FURL URL;
var const Object DemoRecDriver;
