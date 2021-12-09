class HUDMutator extends Mutator;

var PlayerPawn LocalPlayer;
var HUD LocalHUD;

simulated event PostBeginPlay() {
	RegisterHUDMutator2();
}

simulated event Tick(float DeltaTime) {
	super.Tick(DeltaTime);

	if (bHUDMutator == false) {
		RegisterHUDMutator2();
	}
}

simulated event PostRender(Canvas C) {
	if (NextHUDMutator != none)
		NextHUDMutator.PostRender(C);
}

simulated final function RegisterHUDMutator2() {
	local PlayerPawn P;

	foreach AllActors(class'PlayerPawn', P) {
		if (P.myHUD != None) {
			NextHUDMutator = P.myHud.HUDMutator;
			P.myHUD.HUDMutator = Self;
			bHUDMutator = True;

			LocalPlayer = P;
			LocalHUD = P.myHUD;
		}
	}
}

defaultproperties {
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
}
