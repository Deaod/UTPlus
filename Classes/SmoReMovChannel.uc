class SmoReMovChannel extends Info;

var vector ReplLoc;
var vector ClientLoc;
var vector Offset;

var SmoReMovChannel Next;

replication {
	reliable if (Role == ROLE_Authority)
		ReplLoc;
}

simulated event Tick(float DeltaTime) {
	super.Tick(DeltaTime);
	
	if (Level.NetMode == NM_Client) {
		if (Owner == none || Owner.Role == ROLE_SimulatedProxy) {
			GoToState('ClientMode');
		} else {
			Disable('Tick');
		}
	} else {
		if (Owner != none) {
			// this is done to avoid sending unnecessary location updates
			ReplLoc.X = int(Owner.Location.X + 0.5);
			ReplLoc.Y = int(Owner.Location.Y + 0.5);
			ReplLoc.Z = int(Owner.Location.Z + 0.5);
		}
	}
}

state ClientMode {
	simulated event Tick(float DeltaTime) {
		local vector OwnerLoc;

		super.Tick(DeltaTime);

		OwnerLoc = Owner.Location;
		if (VSize(ReplLoc - ClientLoc) != 0) {
			Offset = OwnerLoc - ReplLoc;
		}
		
		if (VSize(Offset) <= 100) {
			OwnerLoc -= Offset;
			Offset   *= Exp(-28 * DeltaTime);
			OwnerLoc += Offset;
			Owner.MoveSmooth(OwnerLoc - Owner.Location);
		}

		ClientLoc = ReplLoc;
	}
}

defaultproperties {
	NetUpdateFrequency=1000
}
