class UTPlusSavedInputChain extends Actor;

var UTPlusSavedInput Newest;
var UTPlusSavedInput Oldest;

var UTPlusSavedInput SpareNodes;

final function UTPlusSavedInput AllocateNode() {
	local UTPlusSavedInput Node;
	if (SpareNodes != none) {
		Node = SpareNodes;
		SpareNodes = Node.Next;
	} else {
		Node = Spawn(class'UTPlusSavedInput');
	}

	Node.Initialize();
	return Node;
}

final function FreeNode(UTPlusSavedInput Node) {
	if (Node.Prev != none)
		Node.Prev.Next = Node.Next;
	if (Node.Next != none)
		Node.Next.Prev = Node.Prev;

	if (Node == Oldest)
		Oldest = Node.Next;
	if (Node == Newest)
		Newest = Node.Prev;

	Node.Next = SpareNodes;
	Node.Prev = none;

	SpareNodes = Node;
}

final function Add(float Delta, UTPlusPlayer P) {
	local UTPlusSavedInput Node;

	Node = AllocateNode();
	Node.CopyFrom(Delta, P);
	if (AppendNode(Node) == false)
		FreeNode(Node);
}

final function bool AppendNode(UTPlusSavedInput Node) {
	if (Newest == none) {
		Oldest = Node;
		Newest = Node;
	} else {
		if (Newest.TimeStamp > Node.TimeStamp - 0.5*Node.Delta)
			return false;

		Node.Prev = Newest;
		Newest.Next = Node;
		Newest = Node;
	}
	return true;
}

final function RemoveAllNodes() {
	while(Oldest != none)
		FreeNode(Oldest);
}

final function RemoveOutdatedNodes(float CurrentTimeStamp) {
	if (Oldest == none)
		return;
	while(Oldest.Next != none && Abs(Oldest.TimeStamp-CurrentTimeStamp) > Abs(Oldest.Next.TimeStamp-CurrentTimeStamp))
		FreeNode(Oldest);
}


final function UTPlusSavedInput SerializeNodes(int MaxNumNodes, UTPlusDataBuffer B) {
	local UTPlusSavedInput I, Ref;
	local int Space;
	local float DeltaError;
	
	DeltaError = 0.0;
	I = Newest;
	Space = B.GetSpace();

	if (I == none)
		return none;

	while(I != Oldest && MaxNumNodes > 0 && Space >= I.SerializedBits) {
		MaxNumNodes -= 1;
		Space -= I.SerializedBits;
		I = I.Prev;
	}

	Ref = I;

	for (I = I.Next; I != none; I = I.Next)
		I.SerializeTo(B, DeltaError);

	return Ref;
}

defaultproperties {
	bHidden=True
	DrawType=DT_None
	RemoteRole=ROLE_None
}
