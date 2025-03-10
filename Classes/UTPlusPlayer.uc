class UTPlusPlayer extends Botpack.TournamentPlayer;

var UTPlus MutUTPlus;

var UTPlusClientSettings Settings;
var Object SettingsHelper;

var PlayerPawn UTPlus_LocalPlayer;

var bool UTPlus_469Client;
var bool UTPlus_469Server;
var bool UTPlus_IsDemoPlayback;

var float UTPlus_AccumulatedHTurn;
var float UTPlus_AccumulatedVTurn;

var EPhysics UTPlus_OldPhysics;
var float UTPlus_OldZ;
var bool UTPlus_ForceZSmoothing;
var int UTPlus_IgnoreZChangeTicks;
var float UTPlus_OldShakeVert;
var float UTPlus_OldBaseEyeHeight;
var float UTPlus_EyeHeightOffset;

var float UTPlus_LastRestartTime;
var float UTPlus_RestartFireLockoutTime;

var UTPlusSavedInputChain UTPlus_SavedInputChain;
var UTPlusDataBuffer UTPlus_InputReplicationBuffer;
var float UTPlus_LastInputSendTime;
var float UTPlus_TimeBetweenNetUpdates;
var bool UTPlus_UpdateClient;
var bool UTPlus_PressedJumpSave;

struct ReplBuffer {
	var int Data[20];
};

var UTPlusInputLogFile UTPlus_InputLogFile;
var bool bTraceInput;

replication {
	unreliable if (Role < ROLE_Authority)
		UTPlus_ServerApplyInput;

	unreliable if (RemoteRole == ROLE_AutonomousProxy)
		UTPlus_CAP,
		UTPlus_CAP_Level,
		UTPlus_CAP_WalkS,
		UTPlus_CAP_WalkS_FallP,
		UTPlus_CAP_WalkS_WalkP,
		UTPlus_CAP_WalkS_WalkP_Level;

	reliable if (Role < ROLE_Authority)
		UTPlus_ServerSetDodgeClickTime;

	unreliable if ( bNetOwner && Role == ROLE_Authority )
		UTPlus_469Server;

	unreliable if ( Role == ROLE_AutonomousProxy || RemoteRole <= ROLE_SimulatedProxy )
		UTPlus_469Client;
}

static final operator(34) int or_eq (out int A, int B) {
	A = A | B;
	return A;
}

static final operator(34) int and_eq (out int A, int B) {
	A = A & B;
	return A;
}

static final function int RotS2U(int R) {
	return R & 0xFFFF;
}

static final function int RotU2S(int R) {
	return ((R << 16) >> 16);
}

final function vector GetBoxExtent() {
	local vector R;
	R.X = CollisionRadius;
	R.Y = CollisionRadius;
	R.Z = CollisionHeight;
	return R;
}

simulated final function PlayerPawn GetLocalPlayer() {
	local PlayerPawn P;

	if (UTPlus_LocalPlayer != none) {
		return UTPlus_LocalPlayer;
	}

	if (Level == none || Level.NetMode == NM_DedicatedServer)
		return none;

	foreach AllActors(class'PlayerPawn', P) {
		if (P.Player != none && P.Player.IsA('Viewport')) {
			UTPlus_LocalPlayer = P;
			return P;
		}
	}

	return none;
}

simulated final function UTPlus_InitSettings() {
	local UTPlusPlayer P;
	local UTPlusSpectator S;

	foreach AllActors(class'UTPlusPlayer', P) {
		if (P.Settings != none) {
			Settings = P.Settings;
			return;
		}
	}

	foreach AllActors(class'UTPlusSpectator', S) {
		if (S.Settings != none) {
			Settings = S.Settings;
			return;
		}
	}

	SettingsHelper = new(none, 'UTPlus') class'Object';
	Settings = new(SettingsHelper, 'Settings') class'UTPlusClientSettings';
	Settings.Initialize();
}

simulated event PostBeginPlay() {
	super.PostBeginPlay();

	UTPlus_InitSettings();

	foreach AllActors(class'UTPlus', MutUTPlus)
		break;

	UTPlus_SavedInputChain = Spawn(class'UTPlusSavedInputChain');
	UTPlus_InputReplicationBuffer = new(XLevel) class'UTPlusDataBuffer';
	UTPlus_InputLogFile = Spawn(class'UTPlusInputLogFile');
	if (Level.NetMode == NM_Client)
		UTPlus_InputLogFile.LogId = "ClientInput";
	else
		UTPlus_InputLogFile.LogId = "ServerInput"$"_"$PlayerReplicationInfo.PlayerId;
	if (bTraceInput)
		UTPlus_InputLogFile.StartLog();
}

event Possess() {
	super.Possess();

	UTPlus_InitSettings();

	if (Level.NetMode == NM_Client) {
		UTPlus_469Client = int(Level.EngineVersion) >= 469;
	} else {
		UTPlus_469Server = int(Level.EngineVersion) >= 469;
		if (RemoteRole != ROLE_AutonomousProxy)
			UTPlus_469Client = UTPlus_469Server;
	}

	if (PlayerReplicationInfo.Class == class'PlayerReplicationInfo')
		PlayerReplicationInfo.NetUpdateFrequency = 20;

	if (Level.NetMode == NM_Client)
		UTPlus_ServerSetDodgeClickTime(DodgeClickTime);
}

simulated event Destroyed() {
	if (bTraceInput && UTPlus_InputLogFile != none)
		UTPlus_InputLogFile.StopLog();
	super.Destroyed();
}

simulated event Touch(Actor Other) {
	if (Other.IsA('Teleporter'))
		UTPlus_IgnoreZChangeTicks = 2;
	super.Touch(Other);
}

event ServerTick(float DeltaTime) {

}

simulated function bool AdjustHitLocation(out vector HitLocation, vector TraceDir) {
	local float adjZ, maxZ;

	TraceDir = Normal(TraceDir);
	HitLocation = HitLocation + 0.5 * CollisionRadius * TraceDir;
	if ( BaseEyeHeight == Default.BaseEyeHeight )
		return true;

	maxZ = Location.Z + EyeHeight + 0.25 * CollisionHeight;
	if (HitLocation.Z > maxZ)	{
		if (TraceDir.Z >= 0)
			return false;
		adjZ = (maxZ - HitLocation.Z)/TraceDir.Z;
		HitLocation.Z = maxZ;
		HitLocation.X = HitLocation.X + TraceDir.X * adjZ;
		HitLocation.Y = HitLocation.Y + TraceDir.Y * adjZ;
		if (VSize(vect(1,1,0) * (HitLocation - Location)) > CollisionRadius)
			return false;
	}
	return true;
}


function actor TraceShot(out vector HitLocation, out vector HitNormal, vector EndTrace, vector StartTrace) {
	local Actor A, Other;
	local UTPlusDummy D;
	
	if (Role != ROLE_Authority || class'UTPlus'.default.bEnablePingCompensation == false)
		return super.TraceShot(HitLocation, HitNormal, EndTrace, StartTrace);

	MutUTPlus.CompensateFor(PlayerReplicationInfo.Ping);

	foreach TraceActors( class'Actor', A, HitLocation, HitNormal, EndTrace, StartTrace) {
		if (A.IsA('UTPlusDummy')) {
			D = UTPlusDummy(A);
			if ((D.Actual != self) && D.AdjustHitLocation(HitLocation, EndTrace - StartTrace)) {
				Other = D.Actual;
				break;
			}
		} else if ((A == Level) || (Mover(A) != None) || A.bProjTarget || (A.bBlockPlayers && A.bBlockActors)) {
			Other = A;
			break;
		}
	}

	MutUTPlus.EndCompensation();
	return Other;
}

// UpdateEyeHeight controls the EyeHeight property of a Pawn.
// This algorithm needs to take into account:
//   - Teleportation (Translocator, Respawning, Teleporters, ...)
//   - Stepping onto unwalkable surfaces
//   - Stairs up & down (see MaxStepHeight)
//   - Ramps
//   - Lifts
//   - Landing 
//
// Currently this algorithm handles teleportation by ignoring Z changes due to
// it. The detection of teleportation is rough, but it mostly works. Glitches
// are rare and usually not noticable during play.
//
// Stepping onto unwalkable surfaces is detected by looking at the Physics of a
// Pawn. Changes from PHYS_Walking to PHYS_Falling cause the change in Z
// position to be smoothed.
// 
// Stairs are distinguished from ramps by looking at the rate of descent. Stairs
// typically have a detected slope of >45°, while ramps have <45°. A slope >45°
// is smoothed, everything else is not smoothed.
// 
// Lift movement is simply removed from Z-change considerations.
// 
// Pawns typically penetrate into the ground slightly before the Landed event is
// executed, which is corrected on the next frame. Landing is handled by always
// smoothing out the Z-change between the two relevant frames (the one on which
// the Pawn landed and the one immediately after).
// 
// Changes are smoothed using an exponential function:
//  NewDelta = OldDelta * e^(-a*DeltaTime)
//   - 'a' was experimentally determined to work best at 9
//   - This has the nice property of being independent of varying DeltaTime
// 
// EyeHeight is then used in PlayerCalcView to determine the CameraLocation, as
// an offset in Z direction from the Pawns Location.
// 
// Additionally, this function also handles FOV changes.
// Well, not anymore, it turns out players dislike smooth FOV changes. 
event UpdateEyeHeight(float DeltaTime) {
	local float DeltaZ;

	// smooth up/down stairs, landing, dont smooth ramps
	if ((Physics == PHYS_Walking && bJustLanded == false) ||
		// Smooth out stepping up onto unwalkable ramps,
		// as well as bobbing on the edge of a water zone.
		(UTPlus_OldPhysics != PHYS_Falling && Physics == PHYS_Falling)
	) {
		DeltaZ = Location.Z - UTPlus_OldZ;

		// remove lifts from the equation.
		if (Base != none)
			DeltaZ -= DeltaTime * Base.Velocity.Z;

		// stair detection heuristic
		if (UTPlus_IgnoreZChangeTicks == 0 && (Abs(DeltaZ) > DeltaTime * GroundSpeed || UTPlus_ForceZSmoothing))
			UTPlus_EyeHeightOffset += FClamp(DeltaZ, -MaxStepHeight, MaxStepHeight);
		UTPlus_ForceZSmoothing = false;
	} else if (bJustLanded) {
		// Always smooth out landing, because you apparently are not considered
		// to have landed until you penetrate the ground by at least 1% of Velocity.Z.
		UTPlus_ForceZSmoothing = true;
	}

	if (UTPlus_IgnoreZChangeTicks > 0) UTPlus_IgnoreZChangeTicks--;
	bJustLanded = false;
	UTPlus_OldPhysics = Physics;
	UTPlus_OldZ = Location.Z;

	UTPlus_EyeHeightOffset += ShakeVert - UTPlus_OldShakeVert;
	UTPlus_OldShakeVert = ShakeVert;

	UTPlus_EyeHeightOffset += BaseEyeHeight - UTPlus_OldBaseEyeHeight;
	UTPlus_OldBaseEyeHeight = BaseEyeHeight;

	UTPlus_EyeHeightOffset = UTPlus_EyeHeightOffset * Exp(-9.0 * DeltaTime);
	EyeHeight = ShakeVert + BaseEyeHeight - UTPlus_EyeHeightOffset;

	// The following events change your FOV:
	//   - Spawning
	//   - Zooming with Sniper Rifle
	//   - Teleporters

	// adjust FOV for weapon zooming
	if (bZooming) {
		ZoomLevel += DeltaTime * 1.0;
		if (ZoomLevel > 0.9)
			ZoomLevel = 0.9;
		DesiredFOV = FClamp(90.0 - (ZoomLevel * 88.0), 1, 170);
	}

	FOVAngle = DesiredFOV;
}

function ClientReStart() {
	super.ClientReStart();

	UTPlus_IgnoreZChangeTicks = 1;
}

// Dummy functions used as markers for UTrace
final function UTPlus_UTraceMarker_LongFrame() {}
final function UTPlus_UTraceMarker_FrameBegin() {}

event PlayerInput(float DeltaTime) {
	if (DeltaTime > 0.02)
		UTPlus_UTraceMarker_LongFrame();
	UTPlus_UTraceMarker_FrameBegin();

	UTPlus_UpdateClientPosition();

	UTPlus_PressedJumpSave = bPressedJump;
	super.PlayerInput(DeltaTime);
}

final function UTPlus_ServerSetDodgeClickTime(float MaxTime) {
	DodgeClickTime = MaxTime;
}

final function UTPlus_UpdateClientPosition() {
	local UTPlusSavedInput In;
	local bool bRealJump;
	local float AdjustDistance;
	local vector PostAdjustLocation;
	local rotator SavedViewRotation;

	if (bUpdatePosition == false)
		return;
	bUpdatePosition = false;

	bRealJump = bPressedJump;
	bUpdating = true;

	UTPlus_SavedInputChain.RemoveOutdatedNodes(CurrentTimeStamp);
	SavedViewRotation = ViewRotation;

	In = UTPlus_SavedInputChain.Oldest;
	if (In != none) {
		while(In.Next != none) {
			UTPlus_PlayBackInput(In, In.Next);
			if (bTraceInput && UTPlus_InputLogFile != none)
				UTPlus_InputLogFile.LogInputReplay(In.Next);
			In = In.Next;
		}
	}

	ViewRotation = SavedViewRotation;

	// Higor: evaluate location adjustment and see if we should either
	// - Discard it
	// - Negate and process over a certain amount of time.
	// - Keep adjustment as is (instant relocation)
	// Deaod: Use exponential decay on offset instead
	AdjustLocationOffset = (Location - PreAdjustLocation);
	AdjustDistance = VSize(AdjustLocationOffset);
	if ((AdjustDistance < 50) &&
		FastTrace(Location, PreAdjustLocation) &&
		IsInState('Dying') == false
	) {
		// Undo adjustment and re-enact smoothly
		PostAdjustLocation = Location;
		MoveSmooth(-AdjustLocationOffset);
		if (AdjustDistance > 2) {
			AdjustLocationOffset = (PostAdjustLocation - Location);
		}
	} else {
		AdjustLocationOffset = vect(0,0,0);
	}

	bUpdating = false;
	bPressedJump = bRealJump;
}

final function UTPlus_SendCAP() {
	local vector ClientLoc;

	if (Mover(Base) != None)
		ClientLoc = Location - Base.Location;
	else
		ClientLoc = Location;

	if (GetStateName() == 'PlayerWalking') {
		if (Physics == PHYS_Walking) {
			if (Base == Level) {
				UTPlus_CAP_WalkS_WalkP_Level(CurrentTimeStamp, ClientLoc.X, ClientLoc.Y, ClientLoc.Z, Velocity.X, Velocity.Y, Velocity.Z);
			} else {
				UTPlus_CAP_WalkS_WalkP(CurrentTimeStamp, ClientLoc.X, ClientLoc.Y, ClientLoc.Z, Velocity.X, Velocity.Y, Velocity.Z, Base);
			}
		} else if (Physics == PHYS_Falling) {
			UTPlus_CAP_WalkS_FallP(CurrentTimeStamp, ClientLoc.X, ClientLoc.Y, ClientLoc.Z, Velocity.X, Velocity.Y, Velocity.Z);
		} else {
			UTPlus_CAP_WalkS(CurrentTimeStamp, Physics, ClientLoc.X, ClientLoc.Y, ClientLoc.Z, Velocity.X, Velocity.Y, Velocity.Z, Base);
		}
	} else if (Base == Level) {
		UTPlus_CAP_Level(CurrentTimeStamp, GetStateName(), Physics, ClientLoc.X, ClientLoc.Y, ClientLoc.Z, Velocity.X, Velocity.Y, Velocity.Z);
	} else {
		UTPlus_CAP(CurrentTimeStamp, GetStateName(), Physics, ClientLoc.X, ClientLoc.Y, ClientLoc.Z, Velocity.X, Velocity.Y, Velocity.Z, Base);
	}
}

final function UTPlus_CAP(
	float TimeStamp,
	name NewState,
	EPhysics Phys,
	float NewLocX, float NewLocY, float NewLocZ,
	float NewVelX, float NewVelY, float NewVelZ,
	Actor NewBase
) {
	local vector Loc,Vel;
	Loc.X = NewLocX; Loc.Y = NewLocY; Loc.Z = NewLocZ;
	Vel.X = NewVelX; Vel.Y = NewVelY; Vel.Z = NewVelZ;
	UTPlus_CAPImpl(TimeStamp, NewState, Phys, Loc, Vel, NewBase);
}

final function UTPlus_CAP_Level(
	float TimeStamp,
	name NewState,
	EPhysics Phys,
	float NewLocX, float NewLocY, float NewLocZ,
	float NewVelX, float NewVelY, float NewVelZ
) {
	local vector Loc,Vel;
	Loc.X = NewLocX; Loc.Y = NewLocY; Loc.Z = NewLocZ;
	Vel.X = NewVelX; Vel.Y = NewVelY; Vel.Z = NewVelZ;
	UTPlus_CAPImpl(TimeStamp, NewState, Phys, Loc, Vel, Level);
}

final function UTPlus_CAP_WalkS(
	float TimeStamp,
	EPhysics Phys,
	float NewLocX, float NewLocY, float NewLocZ,
	float NewVelX, float NewVelY, float NewVelZ,
	Actor NewBase
) {
	local vector Loc,Vel;
	Loc.X = NewLocX; Loc.Y = NewLocY; Loc.Z = NewLocZ;
	Vel.X = NewVelX; Vel.Y = NewVelY; Vel.Z = NewVelZ;
	UTPlus_CAPImpl(TimeStamp, 'PlayerWalking', Phys, Loc, Vel, NewBase);
}

final function UTPlus_CAP_WalkS_FallP(
	float TimeStamp,
	float NewLocX, float NewLocY, float NewLocZ,
	float NewVelX, float NewVelY, float NewVelZ
) {
	local vector Loc,Vel;
	Loc.X = NewLocX; Loc.Y = NewLocY; Loc.Z = NewLocZ;
	Vel.X = NewVelX; Vel.Y = NewVelY; Vel.Z = NewVelZ;
	UTPlus_CAPImpl(TimeStamp, 'PlayerWalking', PHYS_Falling, Loc, Vel, none);
}

final function UTPlus_CAP_WalkS_WalkP(
	float TimeStamp,
	float NewLocX, float NewLocY, float NewLocZ,
	float NewVelX, float NewVelY, float NewVelZ,
	Actor NewBase
) {
	local vector Loc,Vel;
	Loc.X = NewLocX; Loc.Y = NewLocY; Loc.Z = NewLocZ;
	Vel.X = NewVelX; Vel.Y = NewVelY; Vel.Z = NewVelZ;
	UTPlus_CAPImpl(TimeStamp, 'PlayerWalking', PHYS_Walking, Loc, Vel, NewBase);
}

final function UTPlus_CAP_WalkS_WalkP_Level(
	float TimeStamp,
	float NewLocX, float NewLocY, float NewLocZ,
	float NewVelX, float NewVelY, float NewVelZ
) {
	local vector Loc,Vel;
	Loc.X = NewLocX; Loc.Y = NewLocY; Loc.Z = NewLocZ;
	Vel.X = NewVelX; Vel.Y = NewVelY; Vel.Z = NewVelZ;
	UTPlus_CAPImpl(TimeStamp, 'PlayerWalking', PHYS_Walking, Loc, Vel, Level);
}

final function UTPlus_CAPImpl(
	float TimeStamp,
	name NewState,
	EPhysics Phys,
	vector NewLoc,
	vector NewVel,
	Actor NewBase
) {
	local Decoration Carried;
	local vector OldLoc;

	if (bDeleteMe)
		return;

	if (UTPlus_SavedInputChain.Oldest.TimeStamp - 0.5*UTPlus_SavedInputChain.Oldest.Delta > TimeStamp)
		return;

	if (bTraceInput && UTPlus_InputLogFile != none)
		UTPlus_InputLogFile.LogCAP(TimeStamp, NewLoc, NewVel, NewBase);
	CurrentTimeStamp = TimeStamp;

	// Higor: keep track of Position prior to adjustment
	// and stop current smoothed adjustment (if in progress).
	if (bUpdatePosition == false)
		PreAdjustLocation = Location;
	if (VSize(AdjustLocationOffset) > 0) {
		AdjustLocationAlpha = 0;
		AdjustLocationOffset = vect(0,0,0);
	}

	SetPhysics(Phys);
	SetBase(NewBase);
	if (Mover(NewBase) != none)
		NewLoc += NewBase.Location;

	if (GetStateName() != NewState)
		GotoState(NewState);

	Carried = CarriedDecoration;
	OldLoc = Location;

	bCanTeleport = false;
	SetLocation(NewLoc);
	bCanTeleport = true;
	Velocity = NewVel;

	if (Carried != none) {
		CarriedDecoration = Carried;
		CarriedDecoration.SetLocation(NewLoc + CarriedDecoration.Location - OldLoc);
		CarriedDecoration.SetPhysics(PHYS_None);
		CarriedDecoration.SetBase(self);
	}

	bUpdatePosition = true;
}

final function UTPlus_ServerApplyInput(float RefTimeStamp, int NumBits, ReplBuffer B) {
	local int i;
	local UTPlusSavedInput Node;
	local UTPlusSavedInput Old;
	local float DeltaTime;
	local float ServerDeltaTime;
	local float LostTime;

	if (Role < ROLE_Authority) {
		UTPlus_IsDemoPlayback = true;
		return;
	}

	if (bDeleteMe)
		return;

	UTPlus_InputReplicationBuffer.NumBitsConsumed = 0;
	UTPlus_InputReplicationBuffer.NumBits = NumBits;
	for (i = 0; i < arraycount(B.Data); i++)
		UTPlus_InputReplicationBuffer.BitsData[i] = B.Data[i];

	// if (Level.Pauser == "")
	// 	UndoExtrapolation();

	Old = UTPlus_SavedInputChain.Newest;
	if (Old == none) {
		Old = UTPlus_SavedInputChain.AllocateNode();
		Old.DeserializeFrom(UTPlus_InputReplicationBuffer);
		Old.TimeStamp = RefTimeStamp + Old.Delta;
		RefTimeStamp = Old.TimeStamp;
		if (UTPlus_SavedInputChain.AppendNode(Old) == false)
			UTPlus_SavedInputChain.FreeNode(Old);
	}

	while(UTPlus_InputReplicationBuffer.IsDataSufficient(class'UTPlusSavedInput'.default.SerializedBits)) {
		Node = UTPlus_SavedInputChain.AllocateNode();
		Node.DeserializeFrom(UTPlus_InputReplicationBuffer);
		DeltaTime += Node.Delta;
		Node.TimeStamp = RefTimeStamp + DeltaTime;
		if (UTPlus_SavedInputChain.AppendNode(Node) == false)
			UTPlus_SavedInputChain.FreeNode(Node);
	}

	DeltaTime        = UTPlus_SavedInputChain.Newest.TimeStamp - CurrentTimeStamp;
	CurrentTimeStamp = UTPlus_SavedInputChain.Newest.TimeStamp;

	if (ServerTimeStamp != 0.0) {
		ServerDeltaTime = Level.TimeSeconds - ServerTimeStamp;
		ServerTimeStamp = Level.TimeSeconds;

		//ExtrapolationDelta += (ServerDeltaTime - DeltaTime);
	} else {
		ServerTimeStamp = Level.TimeSeconds;
		//ExtrapolationDelta = 0.0;
	}

	// simulate lost time to match extrapolation done by all clients
	LostTime = RefTimeStamp - Old.TimeStamp; // typically <= 0
	LostTime = MutUTPlus.RealPlayTime(ServerTimeStamp, LostTime); // this removed time spent paused
	if (LostTime > 0.001)
		UTPlus_SimMoveAutonomous(LostTime);

	while(Old.Next != none) {
		UTPlus_PlayBackInput(Old, Old.Next);
		if (bTraceInput && UTPlus_InputLogFile != none)
			UTPlus_InputLogFile.LogInput(Old.Next);
		Old = Old.Next;
	}

	// clean up
	UTPlus_SavedInputChain.RemoveOutdatedNodes(Old.TimeStamp);

	UTPlus_UpdateClient = true;
}

function UTPlus_PlayBackInput(UTPlusSavedInput Old, UTPlusSavedInput I) {
	local float OldBaseX, OldBaseY, OldBaseZ;
	local float OldMouseX, OldMouseY;
	local float OldForward, OldStrafe, OldUp, OldLookUp, OldTurn;
	local byte OldRun, OldDuck;

	OldBaseX = aBaseX;
	OldBaseY = aBaseY;
	OldBaseZ = aBaseZ;
	OldMouseX = aMouseX;
	OldMouseY = aMouseY;
	OldForward = aForward;
	OldStrafe = aStrafe;
	OldUp = aUp;
	OldLookUp = aLookUp;
	OldTurn = aTurn;
	OldRun = bRun;
	OldDuck = bDuck;

	aBaseX = 0;
	aBaseY = 0;
	aBaseZ = 0;
	aMouseX = 0;
	aMouseY = 0;
	aForward = 0;
	aStrafe = 0;
	aUp = 0;
	aLookUp = 0;
	aTurn = 0;

	bWasForward    = I.bForw;
	bWasBack       = I.bBack;
	bWasLeft       = I.bLeft;
	bWasRight      = I.bRigh;
	bEdgeForward   = Old.bForw != bWasForward;
	bEdgeBack      = Old.bBack != bWasBack;
	bEdgeLeft      = Old.bLeft != bWasLeft;
	bEdgeRight     = Old.bRigh != bWasRight;

	if (I.bLive) {
		if (I.bForw) aForward += 6000.0;
		if (I.bBack) aForward -= 6000.0;
		if (I.bLeft) aStrafe  += 6000.0;
		if (I.bRigh) aStrafe  -= 6000.0;
		if (I.bDuck) aUp      -= 6000.0;
		if (I.bJump) aUp      += 6000.0;

		if (I.bWalk) bRun = 1; else bRun = 0;
		if (I.bDuck) bDuck = 1; else bDuck = 0;

		bPressedJump = I.bJump && (I.bJump != Old.bJump);
	}

	if (RemoteRole == ROLE_AutonomousProxy) {
		// handle firing and alt-firing on server
		if (I.bFire) {
			if (bFire == 0) {
				if (I.bLive && I.bFFir && Weapon != none)
					Weapon.ForceFire();
				else
					Fire(0);
			}
			bFire = 1;
		} else {
			bFire = 0;
		}

		if (I.bAFir) {
			if (bAltFire == 0) {
				if (I.bLive && I.bFAFr && Weapon != none)
					Weapon.ForceAltFire();
				else
					AltFire(0);
			}
			bAltFire = 1;
		} else {
			bAltFire = 0;
		}
	} else if (RemoteRole == ROLE_Authority) {
		// this assumes that you always replay up until the present, otherwise
		// youd have to save and restore these values
		DodgeDir = Old.SavedDodgeDir;
		DodgeClickTimer = Old.SavedDodgeClickTimer;
	}

	ViewRotation = I.SavedViewRotation;

	// 

	HandleWalking();
	PlayerMove(I.Delta);
	AutonomousPhysics(I.Delta);

	I.SavedLocation = Location;
	I.SavedVelocity = Velocity;

	aBaseX = OldBaseX;
	aBaseY = OldBaseY;
	aBaseZ = OldBaseZ;
	aMouseX = OldMouseX;
	aMouseY = OldMouseY;
	aForward = OldForward;
	aStrafe = OldStrafe;
	aUp = OldUp;
	aLookUp = OldLookUp;
	aTurn = OldTurn;
	bRun = OldRun;
	bDuck = OldDuck;
}

final function ServerTick(float DeltaTime) {
	if (UTPlus_UpdateClient)
		UTPlus_SendCAP();
	UTPlus_UpdateClient = false;
}

function PlayerMove(float Delta) {
	ClientMessage("Help Im Stuck In A Global Function");
	assert false;
}

final function UTPlus_ReplicateInput(float DeltaTime) {
	local float RealDelta;
	local UTPlusSavedInput ReferenceInput;
	local vector NewOffset, TargetLoc;
	local ReplBuffer B;
	local int i;

	// Higor: process smooth adjustment.
	if (VSize(AdjustLocationOffset) > 0) {
		TargetLoc = Location + AdjustLocationOffset;
		NewOffset = AdjustLocationOffset * Exp(-20*DeltaTime);
		MoveSmooth(AdjustLocationOffset - NewOffset);
		AdjustLocationOffset = TargetLoc - Location;
	} else {
		AdjustLocationOffset = vect(0,0,0);
	}

	AutonomousPhysics(DeltaTime);

	UTPlus_SavedInputChain.Add(DeltaTime, self);
	if (bTraceInput && UTPlus_InputLogFile != none)
		UTPlus_InputLogFile.LogInput(UTPlus_SavedInputChain.Newest);

	RealDelta = (Level.TimeSeconds - UTPlus_LastInputSendTime) / Level.TimeDilation;
	if (RealDelta < UTPlus_TimeBetweenNetUpdates - ClientUpdateTime)
		return;

	ClientUpdateTime = FClamp(RealDelta - UTPlus_TimeBetweenNetUpdates + ClientUpdateTime, -UTPlus_TimeBetweenNetUpdates, UTPlus_TimeBetweenNetUpdates);
	UTPlus_LastInputSendTime = Level.TimeSeconds;

	UTPlus_InputReplicationBuffer.Reset();
	ReferenceInput = UTPlus_SavedInputChain.SerializeNodes(10, UTPlus_InputReplicationBuffer);

	if (UTPlus_InputReplicationBuffer.NumBits > 0) {
		for (i = 0; i < arraycount(B.Data); i++)
			B.Data[i] = UTPlus_InputReplicationBuffer.BitsData[i];
		UTPlus_ServerApplyInput(ReferenceInput.TimeStamp, UTPlus_InputReplicationBuffer.NumBits, B);
	}

	if ((Weapon != None) && !Weapon.IsAnimating()) {
		if ((Weapon == ClientPending) || (Weapon != OldClientWeapon)) {
			if (Weapon.Owner != self) //Non-respawnable weapon was picked up and Owner wasn't replicated yet
				Weapon.SetOwner(self); //Simulate owner change locally
			if (Weapon.IsInState('ClientActive'))
				AnimEnd();
			else
				Weapon.GotoState('ClientActive');
			if ((Weapon != ClientPending) && (myHUD != None) && myHUD.IsA('ChallengeHUD'))
				ChallengeHUD(myHUD).WeaponNameFade = 1.3;
			if ((Weapon != OldClientWeapon) && (OldClientWeapon != None))
				OldClientWeapon.GotoState('');

			ClientPending = None;
			bNeedActivate = false;
		} else {
			Weapon.GotoState('');
			Weapon.TweenToStill();
		}
	}
	OldClientWeapon = Weapon;
}

final function int UTPlus_AccumulatedPlayerTurn(float Delta, out float Fraction) {
	local int Result;
	Result = int(Delta + Fraction);
	Fraction += Delta - Result;
	return Result;
}

final function UTPlus_UpdateRotation(float DeltaTime, float maxPitch) {
	local rotator NewRotation;

	DesiredRotation = ViewRotation; //save old rotation

	ViewRotation.Pitch += UTPlus_AccumulatedPlayerTurn(32.0 * DeltaTime * aLookUp, UTPlus_AccumulatedVTurn);
	ViewRotation.Pitch = RotS2U(Clamp(RotU2S(ViewRotation.Pitch), -16384, 16383));

	ViewRotation.Yaw += UTPlus_AccumulatedPlayerTurn(32.0 * DeltaTime * aTurn, UTPlus_AccumulatedHTurn);

	ViewShake(deltaTime);
	ViewFlash(deltaTime);

	NewRotation = Rotation;
	NewRotation.Yaw = ViewRotation.Yaw;
	NewRotation.Pitch = RotS2U(Clamp(
		RotU2S(ViewRotation.Pitch),
		-maxPitch * RotationRate.Pitch,
		maxPitch * RotationRate.Pitch
	));
	SetRotation(NewRotation);
}

final function UTPlus_MoveAutonomous(
	float DeltaTime,
	bool NewbRun,
	bool NewbDuck,
	bool NewbPressedJump,
	eDodgeDir DodgeMove,
	vector newAccel,
	rotator DeltaRot
) {
	//IGPlus_TPFix_LastTouched = none;
	MoveAutonomous(DeltaTime, NewbRun, NewbDuck, NewbPressedJump, DodgeMove, newAccel, DeltaRot);
	//CorrectTeleporterVelocity();
}

/**
 * Splits a large DeltaTime into chunks reasonable enough for MoveAutonomous,
 * so players dont warp through walls
 */
final function UTPlus_SimMoveAutonomous(float DeltaTime) {
	local int SimSteps;
	local float SimTime;

	SimSteps = 1 + int(DeltaTime / 0.01666666666);
	SimTime = DeltaTime / SimSteps;
	while(SimSteps > 0) {
		UTPlus_MoveAutonomous(SimTime, bRun>0, bDuck>0, false, DODGE_None, Acceleration, rot(0,0,0));
		SimSteps--;
	}
}

// COMMANDS

exec function Fire(optional float F) {
	if (Level.TimeSeconds - UTPlus_LastRestartTime > UTPlus_RestartFireLockoutTime)
		super.Fire(F);
}

exec function AltFire(optional float F) {
	if (Level.TimeSeconds - UTPlus_LastRestartTime > UTPlus_RestartFireLockoutTime)
		super.AltFire(F);
}

function string GetReadyMessage() {
	if (Level.Game.IsA('DeathMatchPlus'))
		return DeathMatchPlus(Level.Game).ReadyMessage;

	return class'DeathMatchPlus'.default.ReadyMessage;
}

function string GetNotReadyMessage() {
	if (Level.Game.IsA('DeathMatchPlus'))
		return DeathMatchPlus(Level.Game).NotReadyMessage;

	return class'DeathMatchPlus'.default.NotReadyMessage;
}

exec function Ready() {
	bReadyToPlay = !bReadyToPlay;
	if (bReadyToPlay)
		ClientMessage(GetReadyMessage());
	else
		ClientMessage(GetNotReadyMessage());
}

exec function TraceInput() {
	if (bTraceInput) {
		ClientMessage("Stop tracing input");
		UTPlus_InputLogFile.StopLog();
	} else {
		ClientMessage("Start tracing input");
		UTPlus_InputLogFile.StartLog();
	}
	bTraceInput = !bTraceInput;
}

// STATES

state PlayerWalking {
	ignores SeePlayer, HearNoise, Bump;

	function BeginState() {
		super.BeginState();

		SetCollisionSize(default.CollisionRadius, default.CollisionHeight);
	}

	function PlayerMove(float DeltaTime) {
		local vector X,Y,Z, NewAccel;
		local EDodgeDir OldDodge;
		local eDodgeDir DodgeMove;
		local rotator OldRotation;
		local float Speed2D;
		local rotator MoveRot;

		MoveRot.Yaw = Rotation.Yaw;
		GetAxes(MoveRot,X,Y,Z);

		aForward *= 0.4;
		aStrafe  *= 0.4;
		aLookup  *= 0.24;
		aTurn    *= 0.24;		

		// Update acceleration.
		NewAccel = aForward*X + aStrafe*Y;
		NewAccel.Z = 0;
		
		// Check for Dodge move
		if (DodgeDir == DODGE_Active)
			DodgeMove = DODGE_Active;
		else
			DodgeMove = DODGE_None;
		if (DodgeClickTime > 0.0) {
			if (DodgeDir < DODGE_Active) {
				OldDodge = DodgeDir;
				DodgeDir = DODGE_None;
				if (bEdgeForward && bWasForward)
					DodgeDir = DODGE_Forward;
				if (bEdgeBack && bWasBack)
					DodgeDir = DODGE_Back;
				if (bEdgeLeft && bWasLeft)
					DodgeDir = DODGE_Left;
				if (bEdgeRight && bWasRight)
					DodgeDir = DODGE_Right;
				if (DodgeDir == DODGE_None)
					DodgeDir = OldDodge;
				else if (DodgeDir != OldDodge)
					DodgeClickTimer = DodgeClickTime + 0.5 * DeltaTime;
				else
					DodgeMove = DodgeDir;
			}

			if (DodgeDir == DODGE_Done) {
				DodgeClickTimer -= DeltaTime;
				if (DodgeClickTimer < -0.35) {
					DodgeDir = DODGE_None;
					DodgeClickTimer = DodgeClickTime;
				}
			} else if ((DodgeDir != DODGE_None) && (DodgeDir != DODGE_Active)) {
				DodgeClickTimer -= DeltaTime;
				if (DodgeClickTimer < 0) {
					DodgeDir = DODGE_None;
					DodgeClickTimer = DodgeClickTime;
				}
			}
		}

		if ((Physics == PHYS_Walking)) {
			//if walking, look up/down stairs - unless player is rotating view
			if (!bKeyboardLook && (bLook == 0)) {
				if (bLookUpStairs) {
					ViewRotation.Pitch = FindStairRotation(deltaTime);
				} else if (bCenterView) {
					ViewRotation.Pitch = RotU2S(ViewRotation.Pitch) * (1 - 12 * FMin(0.0833, deltaTime));
					if (Abs(ViewRotation.Pitch) < 1000)
						ViewRotation.Pitch = 0;
				}
			}

			Speed2D = Sqrt(Velocity.X * Velocity.X + Velocity.Y * Velocity.Y);
			//add bobbing when walking
			if (!bShowMenu && bUpdating == false)
				CheckBob(DeltaTime, Speed2D, Y);
		} else if (!bShowMenu) {
			BobTime = 0;
			WalkBob = WalkBob * (1 - FMin(1, 8 * deltatime));
		}

		// Update rotation.
		OldRotation = Rotation;
		UTPlus_UpdateRotation(DeltaTime, 1);

		ProcessMove(DeltaTime, NewAccel, DodgeMove, OldRotation - Rotation);

		if (Role < ROLE_Authority && bUpdating == false)
			UTPlus_ReplicateInput(DeltaTime);

		bPressedJump = false;
	}
}

state PlayerSwimming {
	function PlayerMove(float DeltaTime) {
		local rotator oldRotation;
		local vector X,Y,Z, NewAccel;
		local float Speed2D;

		GetAxes(ViewRotation,X,Y,Z);

		aForward *= 0.2;
		aStrafe  *= 0.1;
		aLookup  *= 0.24;
		aTurn    *= 0.24;
		aUp      *= 0.1;

		NewAccel = aForward*X + aStrafe*Y + aUp*vect(0,0,1);

		//add bobbing when swimming
		if (!bShowMenu) {
			Speed2D = Sqrt(Velocity.X * Velocity.X + Velocity.Y * Velocity.Y);
			WalkBob = Y * Bob *  0.5 * Speed2D * Sin(4.0 * Level.TimeSeconds);
			WalkBob.Z = Bob * 1.5 * Speed2D * Sin(8.0 * Level.TimeSeconds);
		}

		// Update rotation.
		oldRotation = Rotation;
		UTPlus_UpdateRotation(DeltaTime, 2);

		ProcessMove(DeltaTime, NewAccel, DODGE_None, OldRotation - Rotation);
		if (Role < ROLE_Authority && bUpdating == false)
			UTPlus_ReplicateInput(DeltaTime);

		bPressedJump = false;
	}
}

state FeigningDeath {
	function PlayerMove( float DeltaTime) {
		local rotator currentRot;
		local vector NewAccel;

		aLookup  *= 0.24;
		aTurn    *= 0.24;

		// Update acceleration.
		if ( !IsAnimating()  && (aForward != 0) || (aStrafe != 0) )
			NewAccel = vect(0,0,1);
		else
			NewAccel = vect(0,0,0);

		// Update view rotation.
		currentRot = Rotation;
		UTPlus_UpdateRotation(DeltaTime, 1);
		SetRotation(currentRot);

		ProcessMove(DeltaTime, NewAccel, DODGE_None, Rot(0,0,0));
		if (Role < ROLE_Authority && bUpdating == false)
			UTPlus_ReplicateInput(DeltaTime);

		bPressedJump = false;
	}
}

state Dying {
	event EndState() {
		super.EndState();
		UTPlus_LastRestartTime = Level.TimeSeconds;
	}

	function PlayerMove(float DeltaTime) {
		local vector X,Y,Z;

		if ( !bFrozen ) {
			if ( bPressedJump ) {
				Fire(0);
				bPressedJump = false;
			}
			GetAxes(ViewRotation,X,Y,Z);
			// Update view rotation.
			aLookup  *= 0.24;
			aTurn    *= 0.24;
			ViewRotation.Yaw += UTPlus_AccumulatedPlayerTurn(32.0 * DeltaTime * aTurn, UTPlus_AccumulatedHTurn);
			ViewRotation.Pitch += UTPlus_AccumulatedPlayerTurn(32.0 * DeltaTime * aLookUp, UTPlus_AccumulatedVTurn);
			ViewRotation.Pitch = RotS2U(Clamp(RotU2S(ViewRotation.Pitch), -16384, 16383));
			if (Role < ROLE_Authority && bUpdating == false)
				UTPlus_ReplicateInput(DeltaTime);
		}
		ViewShake(DeltaTime);
		ViewFlash(DeltaTime);
	}
}

state PlayerWaiting {
	function PlayerMove(float DeltaTime) {
		local vector X,Y,Z;

		GetAxes(ViewRotation,X,Y,Z);

		aForward *= 0.1;
		aStrafe  *= 0.1;
		aLookup  *= 0.24;
		aTurn    *= 0.24;
		aUp		 *= 0.1;

		Acceleration = aForward*X + aStrafe*Y + aUp*vect(0,0,1);

		UTPlus_UpdateRotation(DeltaTime, 1);

		ProcessMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
		if (Role < ROLE_Authority )
			UTPlus_ReplicateInput(DeltaTime);

		bPressedJump = false;
	}
}

state PlayerFlying {
	function PlayerMove(float DeltaTime) {
		local vector X,Y,Z;

		GetAxes(Rotation,X,Y,Z);

		aForward *= 0.2;
		aStrafe  *= 0.2;
		aLookup  *= 0.24;
		aTurn    *= 0.24;

		Acceleration = aForward*X + aStrafe*Y;
		// Update rotation.
		UTPlus_UpdateRotation(DeltaTime, 2);

		ProcessMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
		if (Role < ROLE_Authority && bUpdating == false)
			UTPlus_ReplicateInput(DeltaTime);

		bPressedJump = false;
	}
}

state CheatFlying {
	function PlayerMove(float DeltaTime) {
		local vector X,Y,Z;

		GetAxes(ViewRotation,X,Y,Z);

		aForward *= 0.1;
		aStrafe  *= 0.1;
		aLookup  *= 0.24;
		aTurn    *= 0.24;
		aUp		 *= 0.1;

		Acceleration = aForward*X + aStrafe*Y + aUp*vect(0,0,1);

		UTPlus_UpdateRotation(DeltaTime, 1);

		ProcessMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
		if (Role < ROLE_Authority && bUpdating == false)
			UTPlus_ReplicateInput(DeltaTime);

		bPressedJump = false;
	}
}

state PlayerSpectating {
	function PlayerMove(float DeltaTime) {
		local vector X,Y,Z;

		GetAxes(ViewRotation,X,Y,Z);

		aForward *= 0.1;
		aStrafe  *= 0.1;
		aLookup  *= 0.24;
		aTurn    *= 0.24;
		aUp		 *= 0.1;

		Acceleration = aForward*X + aStrafe*Y + aUp*vect(0,0,1);

		UTPlus_UpdateRotation(DeltaTime, 1);

		ProcessMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
		if (Role < ROLE_Authority && bUpdating == false)
			UTPlus_ReplicateInput(DeltaTime);

		bPressedJump = false;
	}
}

state PlayerWaking {
	function PlayerMove(Float DeltaTime) {
		ViewFlash(deltaTime * 0.5);
		if ( TimerRate == 0 )
		{
			ViewRotation.Pitch -= DeltaTime * 12000;
			if ( ViewRotation.Pitch < 0 )
			{
				ViewRotation.Pitch = 0;
				GotoState('PlayerWalking');
			}
		}

		ProcessMove(DeltaTime, vect(0,0,0), DODGE_None, rot(0,0,0));
		if (Role < ROLE_Authority && bUpdating == false)
			UTPlus_ReplicateInput(DeltaTime);

		bPressedJump = false;
	}
}

state GameEnded {
	ignores
		SeePlayer,
		HearNoise,
		KilledBy,
		Bump,
		HitWall,
		HeadZoneChange,
		FootZoneChange,
		ZoneChange,
		Falling,
		TakeDamage,
		PainTimer,
		Died;

	function PlayerMove(float DeltaTime) {
		local vector X,Y,Z;

		GetAxes(ViewRotation,X,Y,Z);
		// Update view rotation.

		if (!bFixedCamera) {
			aLookup  *= 0.24;
			aTurn    *= 0.24;
			ViewRotation.Yaw += UTPlus_AccumulatedPlayerTurn( 32.0 * DeltaTime * aTurn, UTPlus_AccumulatedHTurn);
			ViewRotation.Pitch += UTPlus_AccumulatedPlayerTurn( 32.0 * DeltaTime * aLookUp, UTPlus_AccumulatedVTurn);
			ViewRotation.Pitch = RotS2U(Clamp(RotU2S(ViewRotation.Pitch), -16384, 16383));
		} else if ( ViewTarget != None ) {
			ViewRotation = ViewTarget.Rotation;
		}

		ViewShake(DeltaTime);
		ViewFlash(DeltaTime);

		ProcessMove(DeltaTime, vect(0,0,0), DODGE_None, rot(0,0,0));
		if (Role < ROLE_Authority && bUpdating == false)
			UTPlus_ReplicateInput(DeltaTime);

		bPressedJump = false;
	}
}


// ANIMATIONS

function PlayInAir() {
	local vector X,Y,Z, Dir;
	local float f, TweenTime;

	// This change in BaseEyeHeight is removed to avoid players feeling like
	// they've hit their head on a ceiling with every dodge/jump.
	//BaseEyeHeight =  0.7 * Default.BaseEyeHeight;

	if ( (GetAnimGroup(AnimSequence) == 'Landing') && !bLastJumpAlt ) {
		GetAxes(Rotation, X,Y,Z);
		Dir = Normal(Acceleration);
		f = Dir dot Y;
		if ( f > 0.7 )
			TweenAnim('DodgeL', 0.35);
		else if ( f < -0.7 )
			TweenAnim('DodgeR', 0.35);
		else if ( Dir dot X > 0 )
			TweenAnim('DodgeF', 0.35);
		else
			TweenAnim('DodgeB', 0.35);
		bLastJumpAlt = true;
		return;
	}
	bLastJumpAlt = false;
	if ( GetAnimGroup(AnimSequence) == 'Jumping' ) {
		if ( (Weapon == None) || (Weapon.Mass < 20) )
			TweenAnim('DuckWlkS', 2);
		else
			TweenAnim('DuckWlkL', 2);
		return;
	} else if ( GetAnimGroup(AnimSequence) == 'Ducking' ) {
		TweenTime = 2;
	} else {
		TweenTime = 0.7;
	}

	if ( AnimSequence == 'StrafeL' )
		TweenAnim('DodgeR', TweenTime);
	else if ( AnimSequence == 'StrafeR' )
		TweenAnim('DodgeL', TweenTime);
	else if ( AnimSequence == 'BackRun' )
		TweenAnim('DodgeB', TweenTime);
	else if ( (Weapon == None) || (Weapon.Mass < 20) )
		TweenAnim('JumpSMFR', TweenTime);
	else
		TweenAnim('JumpLGFR', TweenTime); 
}

// Copied from TournamentMale

function PlayDying(name DamageType, vector HitLoc) {
	BaseEyeHeight = Default.BaseEyeHeight;
	PlayDyingSound();
			
	if ( DamageType == 'Suicided' ) {
		PlayAnim('Dead8',, 0.1);
		return;
	}

	// check for head hit
	if ( (DamageType == 'Decapitated') && !class'GameInfo'.Default.bVeryLowGore ) {
		PlayDecap();
		return;
	}

	if ( FRand() < 0.15 ) {
		PlayAnim('Dead2',,0.1);
		return;
	}

	// check for big hit
	if ( (Velocity.Z > 250) && (FRand() < 0.75) ) {
		if ( FRand() < 0.5 )
			PlayAnim('Dead1',,0.1);
		else
			PlayAnim('Dead11',, 0.1);
		return;
	}

	// check for repeater death
	if ( (Health > -10) && ((DamageType == 'shot') || (DamageType == 'zapped')) ) {
		PlayAnim('Dead9',, 0.1);
		return;
	}
		
	if ( (HitLoc.Z - Location.Z > 0.7 * CollisionHeight) && !class'GameInfo'.Default.bVeryLowGore ) {
		if ( FRand() < 0.5 )
			PlayDecap();
		else
			PlayAnim('Dead7',, 0.1);
		return;
	}
	
	if ( Region.Zone.bWaterZone || (FRand() < 0.5) ) //then hit in front or back
		PlayAnim('Dead3',, 0.1);
	else
		PlayAnim('Dead8',, 0.1);
}

function PlayDecap() {
	local carcass carc;

	PlayAnim('Dead4',, 0.1);
	if ( Level.NetMode != NM_Client ) {
		carc = Spawn(class 'UT_HeadMale',,, Location + CollisionHeight * vect(0,0,0.8), Rotation + rot(3000,0,16384) );
		if (carc != None) {
			carc.Initfor(self);
			carc.Velocity = Velocity + VSize(Velocity) * VRand();
			carc.Velocity.Z = FMax(carc.Velocity.Z, Velocity.Z);
		}
	}
}

function PlayGutHit(float tweentime) {
	if ( (AnimSequence == 'GutHit') || (AnimSequence == 'Dead2') ) {
		if (FRand() < 0.5)
			TweenAnim('LeftHit', tweentime);
		else
			TweenAnim('RightHit', tweentime);
	}
	else if ( FRand() < 0.6 )
		TweenAnim('GutHit', tweentime);
	else
		TweenAnim('Dead8', tweentime);
}

function PlayHeadHit(float tweentime) {
	if ( (AnimSequence == 'HeadHit') || (AnimSequence == 'Dead7') )
		TweenAnim('GutHit', tweentime);
	else if ( FRand() < 0.6 )
		TweenAnim('HeadHit', tweentime);
	else
		TweenAnim('Dead7', tweentime);
}

function PlayLeftHit(float tweentime) {
	if ( (AnimSequence == 'LeftHit') || (AnimSequence == 'Dead9') )
		TweenAnim('GutHit', tweentime);
	else if ( FRand() < 0.6 )
		TweenAnim('LeftHit', tweentime);
	else 
		TweenAnim('Dead9', tweentime);
}

function PlayRightHit(float tweentime) {
	if ( (AnimSequence == 'RightHit') || (AnimSequence == 'Dead1') )
		TweenAnim('GutHit', tweentime);
	else if ( FRand() < 0.6 )
		TweenAnim('RightHit', tweentime);
	else
		TweenAnim('Dead1', tweentime);
}

// End of Copy

static function SetMultiSkin(Actor SkinActor, string SkinName, string FaceName, byte TeamNum) {
	// forcibly use the default skins
	super.SetMultiSkin(
		SkinActor,
		default.DefaultSkinName,
		"CommandoSkins.Blake",
		TeamNum
	);
}

defaultproperties {
	UTPlus_RestartFireLockoutTime=0.3
	UTPlus_TimeBetweenNetUpdates=0.006666666666666

	bAlwaysRelevant=True

	Drown=Botpack.MaleSounds.drownM02
	BreathAgain=Botpack.MaleSounds.gasp02
	HitSound3=Botpack.MaleSounds.injurM04
	HitSound4=Botpack.MaleSounds.injurH5
	Die=Botpack.MaleSounds.deathc1
	Deaths(0)=Botpack.MaleSounds.deathc1
	Deaths(1)=Botpack.MaleSounds.deathc51
	Deaths(2)=Botpack.MaleSounds.deathc3
	Deaths(3)=Botpack.MaleSounds.deathc4
	Deaths(4)=Botpack.MaleSounds.deathc53
	Deaths(5)=Botpack.MaleSounds.deathc53
	GaspSound=Botpack.MaleSounds.hgasp1
	JumpSound=Botpack.MaleSounds.jump1
	CarcassType=TMale1Carcass
	HitSound1=Botpack.MaleSounds.injurL2
	HitSound2=Botpack.MaleSounds.injurL04
	UWHit1=Botpack.MaleSounds.UWinjur41
	UWHit2=Botpack.MaleSounds.UWinjur42
	LandGrunt=Botpack.MaleSounds.land01
	VoicePackMetaClass="BotPack.VoiceMale"
	Handedness=-1.000000
	Mesh=Mesh'Botpack.Commando'
	SelectionMesh="Botpack.SelectionMale1"
	SpecialMesh="Botpack.TrophyMale1"
	JumpSound=TMJump3
	LandGrunt=MLand3
	CarcassType=TMale1Carcass
	MenuName="Male Commando"
	VoiceType="BotPack.VoiceMaleOne"
	TeamSkin1=2
	TeamSkin2=3
	FixedSkin=0
	FaceSkin=1
	DefaultSkinName="CommandoSkins.cmdo"
	DefaultPackage="CommandoSkins."
}
