class IGEnhancedSettings extends Object
	config(IGEnhanced) perobjectconfig;

enum EBeamAttachMode {
	BAM_Precise,
	BAM_Attached
};
var config EBeamAttachMode BeamOriginMode;
var config EBeamAttachMode BeamDestinationMode;

enum EBeamType {
	BT_None,
	BT_Default,
	BT_TeamColored,
	BT_Instant
};
var config EBeamType BeamType;
var config bool bBeamHideOwn;
var config bool bBeamClientSide;
var config float BeamScale;
var config float BeamDuration;
var config float BeamFadeCurve;

enum EExplosionType {
	ET_None,
	ET_Default,
	ET_TeamColored
};
var config EExplosionType ExplosionType;

function Initialize() {
	SaveConfig();
}

defaultproperties {
	BeamOriginMode=BAM_Precise
	BeamDestinationMode=BAM_Precise

	BeamType=BT_Default
	bBeamHideOwn=False
	bBeamClientSide=False
	BeamScale=0.45
	BeamDuration=0.75
	BeamFadeCurve=4

	ExplosionType=ET_Default
}
