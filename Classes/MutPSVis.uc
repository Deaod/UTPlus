class MutPSVis extends Mutator;

#exec TEXTURE IMPORT FILE="Textures/GreySkin.bmp" MIPS=OFF

var Mutator WarmupMutator;
var bool bWarmupMutatorSearchDone;

var Texture TeamSkinMap[4];
var PSVisDummy DummyList[64];

function Mutator FindWarmupMutator() {
    if (bWarmupMutatorSearchDone)
        return WarmupMutator;

    if (WarmupMutator == none)
        foreach AllActors(class'Mutator', WarmupMutator)
            if (WarmupMutator.IsA('MutWarmup'))
                break;

    if (WarmupMutator != none && WarmupMutator.IsA('MutWarmup') == false)
        WarmupMutator = none;

    bWarmupMutatorSearchDone = true;
    return WarmupMutator;
}

function bool IsInWarmup() {
    local Mutator M;
    local bool bInWarmup;
    local bool bCountDown;

    M = FindWarmupMutator();
    if (M != none)
        bInWarmup = (M.GetPropertyText("bInWarmup") ~= "true");

    if (Level.Game.IsA('DeathMatchPlus'))
        bCountDown = (DeathMatchPlus(Level.Game).CountDown > 0);

    return bInWarmup || bCountDown;
}

function Texture GetDummyTexture(PlayerStart PS) {
    if (Level.Game.bTeamGame && PS.TeamNumber >= 0 && PS.TeamNumber < arraycount(TeamSkinMap)) {
        return TeamSkinMap[PS.TeamNumber];
    }
    return Texture'GreySkin';
}

event PostBeginPlay() {
    local PlayerStart PS;
    local PSVisDummy D;
    local int i;

    super.PostBeginPlay();

    if (Level.Game.IsA('DeathMatchPlus') == false) {
        Log("Error, GameMode is not based on DeathMatchPlus. Aborting.", 'MutPSVis');
        return;
    }

    i = 0;
    foreach AllActors(class'PlayerStart', PS) {
        if (i >= arraycount(DummyList)) {
            Log("Error, too many PlayerStart objects.", 'MutPSVis');
            break;
        }

        D = Spawn(class'PSVisDummy', none, '', PS.Location, PS.Rotation);
        D.SetCollision(false, false, false);
        D.SetCollisionSize(0,0);
        D.DrawType = DT_Mesh;
        D.Mesh = LodMesh'Botpack.Commando';
        D.Skin = GetDummyTexture(PS);
        D.LoopAnim('Breath1');
        D.bAlwaysRelevant = true;

        DummyList[i] = D;
        i++;
    }

    SetTimer(1.0, true);
}

event Timer() {
    local int i;
    local DeathMatchPlus G;

    G = DeathMatchPlus(Level.Game);

    if ((G != none) && G.bNetReady == false && (G.bRequireReady == false || IsInWarmup() == false)) {
        for (i = 0; i < arraycount(DummyList); i++) {
            if (DummyList[i] == none)
                break;

            DummyList[i].DrawType = DT_None;
            DummyList[i].Destroy();
            DummyList[i] = none;
        }

        SetTimer(0.0, false);
    }
}

defaultproperties
{
    TeamSkinMap(0)=Texture'UnrealShare.ShieldBelt.newred'
    TeamSkinMap(1)=Texture'UnrealShare.ShieldBelt.newblue'
    TeamSkinMap(2)=Texture'UnrealShare.ShieldBelt.newgreen'
    TeamSkinMap(3)=Texture'UnrealShare.ShieldBelt.newgold'
}
