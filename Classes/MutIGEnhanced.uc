class MutIGEnhanced extends Botpack.InstaGibDM
	config;

var IGEnhancedChannel ChannelList;

function IGEnhancedChannel FindChannel(Pawn P) {
	local IGEnhancedChannel C;
	
	if (P.IsA('PlayerPawn') == false)
		return none;

	for (C = ChannelList; C != none; C = C.Next)
		if (P == C.Owner)
			return C;

	return none;
}

function CreateChannel(Pawn P) {
	local IGEnhancedChannel C;
	
	if (P.IsA('PlayerPawn') == false)
		return;

	C = Spawn(class'IGEnhancedChannel', P);
	C.PlayerOwner = PlayerPawn(P);
	C.Next = ChannelList;
	ChannelList = C;
}

function PlayEffect(
	PlayerReplicationInfo SourcePRI,
	vector SourceLocation,
	vector SourceOffset,
	Actor Target,
	vector TargetLocation,
	vector TargetOffset,
	vector HitNormal
) {
	local IGEnhancedChannel C;
	for (C = ChannelList; C != none; C = C.Next)
		C.PlayEffect(
			SourcePRI,
			SourceLocation,
			SourceOffset,
			Target,
			TargetLocation,
			TargetOffset,
			HitNormal
		);
}

function ModifyPlayer(Pawn P) {
	super.ModifyPlayer(P);

	if (FindChannel(P) == none)
		CreateChannel(P);
}

defaultproperties
{
	WeaponName=IGEnhancedRifle
	DefaultWeapon=class'IGEnhancedRifle'
	AmmoName=SuperShockCore
}
