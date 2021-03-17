/*                                                                             
 * FILE:     X2Effect_ScanBeGone_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * Prevent Units that are not visible to the enemy from being tilescanned.
 *
 * Dependencies: X2Helpers_Logger_KMP01.uc; X2Ability_ScanBeGone_KMP01.uc
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class X2Effect_ScanBeGone_KMP01 extends X2Effect_Persistent;

var localized string strMovementBlockedByTileBump;

var bool bDeepLog;

var private const float fValueInterrupt;
var private const string imgTileBump;

//---------------------------------------------------------------------------//

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
    local XComGameState_Unit EffectUnit;
    local Object EffectObject;

    EffectObject = EffectGameState;
    
    //  Unit State of the unit this effect was applied to.
    EffectUnit = XComGameState_Unit(`XCOMHISTORY
        .GetGameStateForObjectID(EffectGameState
        .ApplyEffectParameters.TargetStateObjectRef.ObjectID));
    
    `XEVENTMGR.RegisterForEvent(
        EffectObject,
        'AbilityActivated',
        TileBumpListener_Interrupt_KMP01,
        ELD_OnStateSubmitted, ,
        EffectUnit, ,
        EffectUnit
    );
    `XEVENTMGR.RegisterForEvent(
        EffectObject,
        'AbilityActivated',
        TileBumpListener_Cleanup_KMP01,
        ELD_OnVisualizationBlockCompleted, ,
        EffectUnit, ,
        EffectUnit
    );
    super.RegisterForEvents(EffectGameState);
}

//---------------------------------------------------------------------------//

static function EventListenerReturn TileBumpListener_Interrupt_KMP01(
    Object EventData, 
    Object EventSource,
    XComGameState EventGameState,
    name EventID,
    Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameStateHistory History;
    local XComGameState NewGameState;

    local XComGameState_Player PlayerState;
    local XComGameState_Player BlockPlayer;
    local XComGameState_Unit UnitState;
    local XComGameState_Unit Blocker;

    local array<PathingInputData> MovePaths;
    local array<Actor> TileActors;
    local array<TTile> MoveTiles;
    local TTile TargetLoc;
    local UnitValue UVal;

    History = `XCOMHISTORY;
    UnitState = XComGameState_Unit(EventSource);

    AbilityContext = XComGameStateContext_Ability(EventGameState.GetContext());

    if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
    {
        kLog("Exit: Not in the Interrupt Phase", true, default.bDeepLog);
        return ELR_NoInterrupt;
    }
    if (AbilityContext.InputContext.MovementPaths.Length < 1)
    {
        kLog("Exit: Not a movement skill (No Movement Paths)",
            true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

    PlayerState = XComGameState_Player(History.GetGameStateForObjectID(
        UnitState.ControllingPlayer.ObjectID));

    MovePaths = AbilityContext.InputContext.MovementPaths;
    MoveTiles = MovePaths[MovePaths.Length - 1].MovementTiles;
    TargetLoc = MoveTiles[MoveTiles.Length - 1];

    TileActors = `XWORLD.GetActorsOnTile(TargetLoc);

    if (TileActors.Length == 0)
    {
        kLog("Exit: No Units on Target Tile", true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

    Blocker = XComGameState_Unit(History
        .GetGameStateForObjectID(XGUnit(TileActors[0]).ObjectID));
    if (Blocker != none)
    {
        kRed("ERROR: No Blocking Unit Found in History!", false);
        kLog("Warning: Redscreen:"
            @ "ERROR: No Blocking Unit Found in History!",
        false, default.bDeepLog);
    }

    BlockPlayer = XComGameState_Player(History
        .GetGameStateForObjectID(Blocker.ControllingPlayer.ObjectID));

    kLog("Unit:    " @ UnitState.GetName(eNameType_FullNick)
        $ "\n    Player:  " @ PlayerState.ObjectID
                            @ PlayerState.PlayerName
                            @ PlayerState.TeamFlag
        $ "\n    Location:" @ "x:" @ UnitState.TileLocation.X 
                            @ "y:" @ UnitState.TileLocation.Y
                            @ "z:" @ UnitState.TileLocation.Z
        $ "\n    Target:  " @ "x:" @ TargetLoc.X
                            @ "y:" @ TargetLoc.Y
                            @ "z:" @ TargetLoc.Z
        $ "\n    Blocker: " @ Blocker.GetName(eNameType_FullNick)
        $ "\n    Player:  " @ BlockPlayer.ObjectID
                            @ BlockPlayer.PlayerName
                            @ BlockPlayer.TeamFlag,
        true, default.bDeepLog);

    NewGameState = class'XComGameStateContext_ChangeContainer'.static
        .CreateChangeState("TileBumpListener_Interrupt_KMP01");
    UnitState = XComGameState_Unit(NewGameState
        .ModifyStateObject(UnitState.Class, UnitState.ObjectID));

    if (UnitState.GetUnitValue(class'X2Ability_DefaultAbilitySet'
        .default.ImmobilizedValueName, UVal))
    {
        kLog("Immobilize Already Added: Reapply with fValue=1",
            true, default.bDeepLog);
        UnitState.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'
            .default.ImmobilizedValueName, 1, UVal.eCleanup);
    }
    else
    {
        kLog("Set UnitValue to Immobilize with custom fValue"
            @ UnitState.GetName(eNameType_FullNick),
            true, default.bDeepLog);
        UnitState.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'
            .default.ImmobilizedValueName, default.fValueInterrupt);
    }

    kLog("bVisOrderIdp:" @ AbilityContext.bVisualizationOrderIndependent
        $ "\n    DesVisBlock: " @ AbilityContext
            .DesiredVisualizationBlockIndex
        $ "\n    PreBuildVis: " @ AbilityContext
            .PreBuildVisualizationFn.Length
        $ "\n    PostVisBuild:" @ AbilityContext
            .PostBuildVisualizationFn.Length,
        true, default.bDeepLog);

    //AbilityContext.PreBuildVisualizationFn.Length = 0;
    //AbilityContext.PostBuildVisualizationFn.Length = 0;
    AbilityContext.PreBuildVisualizationFn
        .AddItem(TileBump_PreBuildVisualization);

    if (NewGameState.GetNumGameStateObjects() > 0)
    {
        kLog("Adding NewGameState with" @ NewGameState.GetNumGameStateObjects()
            @ "modified State Objects to TacRules",
            true, default.bDeepLog);
        `TACTICALRULES.SubmitGameState(NewGameState);
    }
    else
    {
        kLog("Cleaning up Pending Game State",
            true, default.bDeepLog);
        History.CleanupPendingGameState(NewGameState);
    }
    return ELR_NoInterrupt;
}

//---------------------------------------------------------------------------//

static function EventListenerReturn TileBumpListener_Cleanup_KMP01(
    Object EventData, 
    Object EventSource,
    XComGameState EventGameState,
    name EventID,
    Object CallbackData)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_Unit UnitState;
    local TTile StartLocation;

    kLog("AbilityActivated Event for Visualization:", true, default.bDeepLog);
    
    AbilityContext = XComGameStateContext_Ability(EventGameState.GetContext());
    UnitState = XComGameState_Unit(EventSource);
    
    if (AbilityContext.PreBuildVisualizationFn
        .Find(TileBump_PreBuildVisualization) == INDEX_NONE)
    {
        kLog("Exit: No PreBuildVisFn Found for Unit"
            @ UnitState.GetName(eNameType_FullNick),
            true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

    StartLocation = AbilityContext.InputContext
        .MovementPaths[0].MovementTiles[0];

    UnitState = XComGameState_Unit(EventGameState.GetGameStateForObjectID(
        AbilityContext.InputContext.SourceObject.ObjectID));

    kLog("Move Unit Back to Start Location: x:" @ StartLocation.X
        @ "y:" @ StartLocation.Y @ "z:" @ StartLocation.Z,
        true, default.bDeepLog);

    // Correct Unit Location
    `CHEATMGR.TeleportUnit(XGUnit(UnitState.GetVisualizer()),
        `XWORLD.GetPositionFromTileCoordinates(StartLocation));

    return ELR_NoInterrupt;
}

//---------------------------------------------------------------------------//

/// <summary>
/// Open the tome of Black Magic and prepare to release the seal
/// </summary>
simulated function TileBump_PreBuildVisualization(
    XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability AbilityContext;
    local VisualizationActionMetadata ActionMetadata;
    local X2Action_PlaySoundAndFlyOver SoundAction;
	local XComGameStateHistory History;
	local int UnitID;

	AbilityContext = XComGameStateContext_Ability(
        VisualizeGameState.GetContext());
    UnitID = AbilityContext.InputContext.SourceObject.ObjectID;

	History = `XCOMHISTORY;
	
	History.GetCurrentAndPreviousGameStatesForObjectID(UnitID,
        ActionMetadata.StateObject_OldState,
        ActionMetadata.StateObject_NewState,
        eReturnType_Reference, VisualizeGameState.HistoryIndex);
	ActionMetadata.VisualizeActor = History.GetVisualizer(UnitID);

	ActionMetadata.LastActionAdded = `XCOMVISUALIZATIONMGR.BuildVisTree;

	SoundAction = X2Action_PlaySoundAndFlyOver(
        class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(
        ActionMetadata, VisualizeGameState.GetContext()));
	SoundAction.SetSoundAndFlyOverParameters( // SoundUI.NegativeSelection2Cue
        SoundCue'SoundGlobalUI.MenuClickNegative_Cue',
        default.strMovementBlockedByTileBump, '', eColor_Bad,
        default.imgTileBump, /*Look*/, /*Block*/, /*VisTeam*/, /*Behavior*/);
    

    TileBumpCleanup(XComGameState_Unit(
        History.GetGameStateForObjectID(UnitID)));
}

//---------------------------------------------------------------------------//

/// <summary>
/// Activate Black Magic to remove the Immobilized UnitValue added on Interrupt
/// </summary>
static private function TileBumpCleanup(XComGameState_Unit UnitState)
{
    local XComGameState NewGameState;
    local UnitValue UVal;
    
    if (!UnitState.GetUnitValue(class'X2Ability_DefaultAbilitySet'
        .default.ImmobilizedValueName, UVal))
    {
        kLog("Exit: No Immobilize UnitValue Found for Unit"
            @ UnitState.GetName(eNameType_FullNick),
            true, default.bDeepLog);
        return;
    }
    else if (UVal.fValue != default.fValueInterrupt)
    {
        kLog("Exit: Immobilize was set by other effect"
            @ UnitState.GetName(eNameType_FullNick),
            true, default.bDeepLog);
        return;
    }

    kLog("Begin Casting Black Magic:", true, default.bDeepLog);
    NewGameState = class'XComGameStateContext_ChangeContainer'.static
        .CreateChangeState("TileBumpCleanup");
    UnitState = XComGameState_Unit(NewGameState
        .ModifyStateObject(UnitState.Class, UnitState.ObjectID));

    kLog("Remove Immobilize UnitValue",
        true, default.bDeepLog);
    UnitState.ClearUnitValue(class'X2Ability_DefaultAbilitySet'
        .default.ImmobilizedValueName);
    
    if (NewGameState.GetNumGameStateObjects() > 0)
    {
        kLog("Adding NewGameState with" @ NewGameState.GetNumGameStateObjects()
            @ "modified State Objects to TacRules through use of Black Magic",
            true, default.bDeepLog);
        `TACTICALRULES.SubmitGameState(NewGameState);
    }
    else
    {
        kLog("Cleaning up Pending Game State",
            true, default.bDeepLog);
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
    }
    kLog("Seal the Black Magic back within the void", true, default.bDeepLog);
}

//---------------------------------------------------------------------------//

function EGameplayBlocking ModifyGameplayPathBlockingForTarget(
    const XComGameState_Unit UnitState, const XComGameState_Unit TargetUnit)
{
    local XComGameState_Player LocalPlayer;
    local XGUnit Unit;

    LocalPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(
        `TACTICALRULES.GetLocalClientPlayerObjectID()));
    Unit = XGUnit(UnitState.GetVisualizer());

	// This unit blocks the target unit if they are on the same team
    // (not an enemy), are visible to the enemy, or target unit is a civilian
    // or they are at the top of a ladder and not concealed.
	if(!UnitState.IsEnemyUnit(TargetUnit)
        || Unit.IsVisibleToTeam(LocalPlayer.TeamFlag)
        || TargetUnit.IsCivilian()
        || ( IsAtopLadder(Unit) && ShouldBlockLadder(UnitState) ))
	{
		return eGameplayBlocking_Blocks;
	}
	else
	{
		return eGameplayBlocking_DoesNotBlock;
	}
}

//---------------------------------------------------------------------------//

private function bool IsAtopLadder(XGUnit Unit)
{
    local WorldInfo WorldInfo;
    local XComWorldData World;
    local XComLadder Ladder;
    local Vector lTop;
    //local Vector lBot;
    local TTile LadderTopTile;
    //local TTile LadderBotTile;
    local TTile UnitTile;

    WorldInfo = `XWORLDINFO; //class'WorldInfo'.static.GetWorldInfo();
    World = `XWORLD;

    foreach WorldInfo.OverlappingActors(class'XComLadder', Ladder, 144.0f, Unit.Location, false)
    {
        lTop = Ladder.GetTop();
        //lBot = Ladder.GetBottom();
        LadderTopTile = World.GetTileCoordinatesFromPosition(lTop);
        //LadderBotTile = World.GetTileCoordinatesFromPosition(lBot);
        UnitTile = World.GetTileCoordinatesFromPosition(Unit.Location);
        kLog("Unit Location:  " @ Unit.Location.X @ Unit.Location.Y @ Unit.Location.Z
            $ "\n    Unit Tile:      " @ UnitTile.X @ UnitTile.Y @ UnitTile.Z
            //$ "\n    Ladder Top:     " @ lTop.X @ lTop.Y @ lTop.Z
            $ "\n    Ladder Top Tile:" @ LadderTopTile.X @ LadderTopTile.Y @ LadderTopTile.Z,
            //$ "\n    Ladder Bottom:  " @ lBot.X @ lBot.Y @ lBot.Z
            //$ "\n    Ladder Bot Tile:" @ LadderBotTile.X @ LadderBotTile.Y @ LadderBotTile.Z
            //$ "\n    Unit On Top:    " @ LadderTopTile == UnitTile,
            true, default.bDeepLog);
        if (UnitTile.X == LadderTopTile.X
            && UnitTile.Y == LadderTopTile.Y
            && UnitTile.Z > (LadderTopTile.Z - 2))
        {
            return UnitTile.Z < (LadderTopTile.Z + 3);
        }
    }
    return false;
}

//---------------------------------------------------------------------------//

private function bool ShouldBlockLadder(XComGameState_Unit UnitState)
{
    local bool bForceBlock;
    local bool bConcealed;
    local UnitValue UVal;

    if (true)
    {
        return true;
    }
    
    bConcealed = UnitState.IsConcealed() || UnitState.IsSuperConcealed();

    if (bConcealed && UnitState.GetUnitValue(
        class'X2Ability_ScanBeGone_KMP01'.default.UV_ForceLadderBlock, UVal))
    {
        kLog("Found LadderBlock Unit Value for Concealed Unit",
            true, default.bDeepLog);
        bForceBlock = bool(UVal.fValue);
    }
    
    return bForceBlock || !bConcealed;
}

//---------------------------------------------------------------------------//

function EGameplayBlocking ModifyGameplayDestinationBlockingForTarget(
    const XComGameState_Unit UnitState, const XComGameState_Unit TargetUnit) 
{
	return ModifyGameplayPathBlockingForTarget(UnitState, TargetUnit);
}

//---------------------------------------------------------------------------//

// Interface for kLogger, add to each class that needs configurable logs
private static function kLog(string Msg, bool verbose=false, bool deep=false)
{
    class'X2Helpers_Logger_KMP01'.static.kLogger(Msg, verbose, deep);
}

// Interface for kRedscreen, add to each class that needs configurable logs
private static function kRed(string Msg, bool bBypassRed=true)
{
    class'X2Helpers_Logger_KMP01'.static.kRedscreen(Msg, bBypassRed);
}

//---------------------------------------------------------------------------//

defaultproperties
{
    bDeepLog=true

    EffectRank=1 // This rank is set for blocking
    EffectName="ScanBeGone_Effect_KMP01"
    fValueInterrupt=2391060667

    imgTileBump="img:///UILibrary_PerkIcons.UIPerk_panic"
}
