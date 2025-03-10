class UTPlusPlayerReplicationInfo extends PlayerReplicationInfo;

function PostBeginPlay() {
	super.PostBeginPlay();

	SetTimer(0.5 * Level.TimeDilation, true);
}

function Timer() {
	local float MinDist, Dist;
	local LocationID L;

	MinDist = 1000000;
	PlayerLocation = none;
	if (PlayerZone != none) {
		for (L = PlayerZone.LocationID; L != none; L = L.NextLocation) {
			Dist = VSize(Owner.Location - L.Location);
			if ((Dist < L.Radius) && (Dist < MinDist)) {
				PlayerLocation = L;
				MinDist = Dist;
			}
		}
	}

	if (UTPlusPlayer(Owner) != none)
		Ping = int(UTPlusPlayer(Owner).UTPlus_PingAverage * 1000.0 + 0.5);
	if (PlayerPawn(Owner) != none)
		PacketLoss = int(PlayerPawn(Owner).ConsoleCommand("GETLOSS"));
}
