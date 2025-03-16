class MutHitFeedback extends Mutator;
// Description="Provides feedback when players deal damage"

var HitFeedbackChannel ChannelList;

event PostBeginPlay() {
	if (Level == none || Level.Game == none) {
		Destroy(); // spawned client-side? wtf?
		return;
	}

	if (Level.Game.BaseMutator == none)
		Level.Game.BaseMutator = self;
	else
		Level.Game.BaseMutator.AddMutator(self);

	Level.Game.RegisterDamageMutator(self);

	SetTimer(0.5, true);
}

function AddMutator(Mutator M) {
	if (M.Class != Class)
		super.AddMutator(M);
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
}

function Timer() {
	local Pawn P;

	// Complexity: O(n) = n*n (!)
	// Maybe find something better?
	for (P = Level.PawnList; P != none; P = P.NextPawn)
		if (P.IsA('PlayerPawn') && FindChannel(P) == none)
			CreateChannel(P);
}

function MutatorTakeDamage(
	out int ActualDamage,
	Pawn Victim,
	Pawn InstigatedBy,
	out vector HitLocation,
	out vector Momentum,
	name DamageType
) {
	local int TotalDamage;
	local HitFeedbackTracker Tracker;
	local HitFeedbackChannel Channel;
	local Actor VT;

	if (InstigatedBy != none && Victim != none) {
		Tracker = FindTracker(Victim);
		if (Tracker != none)
			TotalDamage = Tracker.LastDamage;

		for (Channel = ChannelList; Channel != none; Channel = Channel.Next) {
			if (Channel.PlayerOwner == none)
				continue;

			VT = Channel.PlayerOwner.ViewTarget;
			if (VT == none)
				VT = Channel.PlayerOwner;
			if (VT == InstigatedBy)
				Channel.PlayHitFeedback(Victim.PlayerReplicationInfo, TotalDamage);
		}
	}

	super.MutatorTakeDamage(ActualDamage, Victim, InstigatedBy, HitLocation, Momentum, DamageType);
}

