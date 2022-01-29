class MutSmoReMove extends Mutator;

var SmoReMovChannel List;

function SmoReMovChannel FindChannel(Pawn P) {
	local SmoReMovChannel C;

	for (C = List; C != none; C = C.Next)
		if (C.Owner == P)
			return C;

	return none;
}

event ModifyPlayer(Pawn P) {
	local SmoReMovChannel C;

	C = FindChannel(P);
	if (C == none) {
		C = Spawn(class'SmoReMovChannel', P);
		C.Next = List;
		List = C;
	}

	super.ModifyPlayer(P);
}
