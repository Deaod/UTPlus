class MutHitFeedback extends Mutator;

var HitFeedbackChannel ChannelList;

event PostBeginPlay() {
	Level.Game.RegisterDamageMutator(self);
}

function HitFeedbackChannel FindChannel(Pawn P) {
	local HitFeedbackChannel C;
	
	if (P.IsA('PlayerPawn') == false)
		return none;

	for (C = ChannelList; C != none; C = C.Next)
		if (P == C.Owner)
			return C;

	return none;
}

function CreateChannel(Pawn P) {
	local HitFeedbackChannel C;
	
	if (P.IsA('PlayerPawn') == false)
		return;

	C = Spawn(class'HitFeedbackChannel', P);
	C.PlayerOwner = PlayerPawn(P);
	C.Next = ChannelList;
	ChannelList = C;
}

function HitFeedbackTracker FindTracker(Pawn P) {
	local Inventory I;

	for (I = P.Inventory; I != none; I = I.Inventory)
		if (I.IsA('HitFeedbackTracker'))
			return HitFeedbackTracker(I);

	return none;
}

function CreateTracker(Pawn P) {
	local HitFeedbackTracker T;
	T = Spawn(class'HitFeedbackTracker');
	T.GiveTo(P);
}

function ModifyPlayer(Pawn P) {
	super.ModifyPlayer(P);

	if (FindTracker(P) == none)
		CreateTracker(P);

	if (FindChannel(P) == none)
		CreateChannel(P);
}

function MutatorTakeDamage(
	out int ActualDamage,
	Pawn Victim,
	Pawn InstigatedBy,
	out Vector HitLocation,
	out Vector Momentum,
	name DamageType
) {
	local int TotalDamage;
	local HitFeedbackTracker Tracker;
	local HitFeedbackChannel Channel;

	if (Victim != none)
		Tracker = FindTracker(Victim);
	if (Tracker != none)
		TotalDamage = Tracker.LastDamage;

	if (InstigatedBy != none)
		Channel = FindChannel(InstigatedBy);
	if (Channel != none)
		Channel.PlayHitFeedback(Victim.PlayerReplicationInfo, TotalDamage);

	super.MutatorTakeDamage(ActualDamage, Victim, InstigatedBy, HitLocation, Momentum, DamageType);
}

