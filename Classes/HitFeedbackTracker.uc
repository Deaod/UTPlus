class HitFeedbackTracker extends TournamentPickup;

var int LastDamage;

function bool HandlePickupQuery(Inventory Item) {
	return Inventory.HandlePickupQuery(Item);
}

function int ArmorPriority(name DamageType) {
	return MaxInt;
}

function int ArmorAbsorbDamage(int Damage, name DamageType, vector HitLocation) {
	LastDamage = Damage;
	return Damage;
}

defaultproperties {
	bIsAnArmor=True
	ArmorAbsorption=0
	Charge=0
}
