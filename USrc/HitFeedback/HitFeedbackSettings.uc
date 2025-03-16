class HitFeedbackSettings extends Object
	config(HitFeedback) perobjectconfig;

#exec Audio Import FILE=Sounds\HitSound.wav Name=HitSound
#exec Audio Import FILE=Sounds\HitSound1.wav Name=HitSound1
#exec Audio Import FILE=Sounds\HitSoundFriendly.wav Name=HitSoundFriendly

var config string HitSounds[16];

var config bool bEnableHitSounds;
var config int SelectedHitSound;
var config bool bHitSoundPitchShift;
var config float HitSoundVolume;

var config bool bEnableTeamHitSounds;
var config int SelectedTeamHitSound;
var config bool bHitSoundTeamPitchShift;
var config float HitSoundTeamVolume;

function Initialize() {
	local int i;
	local string PackageName;

	PackageName = class'StringUtils'.static.GetPackage();

	for (i = 0; i < arraycount(HitSounds); i++) {
		if (Left(HitSounds[i], 6) ~= "UTPlus") {
			HitSounds[i] = PackageName$Mid(HitSounds[i], InStr(HitSounds[i], "."));
		}
		if (HitSounds[i] == "" && HitSounds[i] != default.HitSounds[i]) {
			HitSounds[i] = default.HitSounds[i];
		}
	}

	SaveConfig();
}

defaultproperties {
	HitSounds(0)="UTPlus.HitSoundFriendly"
	HitSounds(1)="UTPlus.HitSound"
	HitSounds(2)="UTPlus.HitSound1"

	bEnableHitSounds=True
	SelectedHitSound=1
	bHitSoundPitchShift=True
	HitSoundVolume=4

	bEnableTeamHitSounds=True
	SelectedTeamHitSound=0
	bHitSoundTeamPitchShift=False
	HitSoundTeamVolume=4
}
