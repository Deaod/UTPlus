class SmoReMovChannel extends Info;

var vector ReplLoc;
var vector ClientLoc;
var vector Offset;

var SmoReMovChannel Next;

replication {
	reliable if (Role == ROLE_Authority)
		ReplLoc;
}

simulated function int Round(float F) {
	if (F >= 0)
		return int(F + 0.5);
	return int(F - 0.5);
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
			ReplLoc.X = Round(Owner.Location.X);
			ReplLoc.Y = Round(Owner.Location.Y);
			ReplLoc.Z = Round(Owner.Location.Z);
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
