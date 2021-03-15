/*                                                                             
 * FILE:     X2Effect_ScanBeGone_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * Prevent Units that are not visible to the enemy from being tilescanned.
 *
 * Dependencies: X2ModConfig_KMP01.uc; X2Helpers_Logger_KMP01.uc
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class X2Effect_ScanBeGone_KMP01 extends X2Effect_Persistent;

var bool bDeepLog;

var private const float fValueInterrupt;

//var const private int COLLISION_MIN_TILE_DISTANCE;
//var const private int COLLISION_MAX_TILE_DISTANCE;


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
        ELD_OnVisualizationBlockStarted, ,
        EffectUnit, ,
        EffectUnit
    );
    /*
    `XEVENTMGR.RegisterForEvent(
        EffectObject,
        'Visualizer_Interrupt',
        TileBumpListener_Cleanup_KMP01,
        ELD_OnStateSubmitted, ,
        , ,
        EffectUnit);
    
    `XEVENTMGR.RegisterForEvent(
        EffectObject,
        'ObjectMoved',
        TileBumpListener_Immediate_KMP01,
        ELD_Immediate,
        4, , ,
        EffectUnit);
    */

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
    local XComGameState_Player PlayerState;
    local XComGameState_Player BlockPlayer;
    local XComGameState_Unit UnitState;
    local XComGameState_Unit Blocker;
    local array<Actor> TileActors;

    local array<PathingInputData> MovePaths;
    local array<TTile> MoveTiles;
    local TTile TargetLoc;
    local UnitValue UVal;

    local XComGameState NewGameState;

    UnitState = XComGameState_Unit(EventSource);

    AbilityContext = XComGameStateContext_Ability(EventGameState.GetContext());

    if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
    {
        kLog("Exit: Not in the Interrupt Phase", true, default.bDeepLog);
        return ELR_NoInterrupt;
    }
    if (AbilityContext.InputContext.MovementPaths.Length < 1)
    {
        kLog("Exit: Not a movement skill (No Movement Paths)", true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

    PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));

    MovePaths = AbilityContext.InputContext.MovementPaths;
    MoveTiles = MovePaths[MovePaths.Length - 1].MovementTiles;
    TargetLoc = MoveTiles[MoveTiles.Length - 1];

    TileActors = `XWORLD.GetActorsOnTile(TargetLoc);

    if (TileActors.Length == 0)
    {
        kLog("Exit: No Units on Target Tile", true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

    Blocker = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XGUnit(TileActors[0]).ObjectID));
    if (Blocker != none)
    {
        BlockPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(Blocker.ControllingPlayer.ObjectID));

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
    }
    else
    {
        kLog("Unit:    " @ UnitState.GetName(eNameType_FullNick)
            $ "\n    Player:  " @ PlayerState.ObjectID
                                @ PlayerState.PlayerName
                                @ PlayerState.TeamFlag
            $ "\n    Location:" @ "x:" @ UnitState.TileLocation.X 
                                @ "y:" @ UnitState.TileLocation.Y
                                @ "z:" @ UnitState.TileLocation.Z
            $ "\n    Target:  " @ "x:" @ TargetLoc.X
                                @ "y:" @ TargetLoc.Y
                                @ "z:" @ TargetLoc.Z,
            true, default.bDeepLog);
    }
    /*
    if (EventGameState.HistoryIndex > -1)
    {
        kLog("Exit: Game State exists in History", true, default.bDeepLog);
        return ELR_NoInterrupt;
    }
    */
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
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
    }
    return ELR_NoInterrupt;
}

static function EventListenerReturn TileBumpListener_Cleanup_KMP01(
    Object EventData, 
    Object EventSource,
    XComGameState EventGameState,
    name EventID,
    Object CallbackData)
{

    if (EventID == 'AbilityActivated')
    {
        kLog("AbilityActivated Event for Visualization:" @ XComGameStateContext_Ability(EventGameState.GetContext()).InterruptionStatus, true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

    if (XComGameStateContext_Ability(EventData).InterruptionStatus != eInterruptionStatus_Interrupt)
    {
        kLog("Cleanup Phase:", true, default.bDeepLog);
        return TileBumpCleanup(XComGameState_Unit(CallbackData));
    }
    else
    {
        kLog("Interrupt Phase:", true, default.bDeepLog);
        return TileBumpCleanup(XComGameState_Unit(CallbackData));
    }
    return ELR_NoInterrupt;
}

static private function EventListenerReturn TileBumpCleanup(XComGameState_Unit UnitState)
{
    local XComGameState NewGameState;
    local UnitValue UVal;
    
    if (!UnitState.GetUnitValue(class'X2Ability_DefaultAbilitySet'
            .default.ImmobilizedValueName, UVal))
    {
        kLog("Exit: No Immobilize UnitValue Found for Unit"
            @ UnitState.GetName(eNameType_FullNick),
            true, default.bDeepLog);
        return ELR_NoInterrupt;
    }
    else if (UVal.fValue != default.fValueInterrupt)
    {
        kLog("Exit: Immobilize was set by other effect"
            @ UnitState.GetName(eNameType_FullNick),
            true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

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
            @ "modified State Objects to TacRules",
            true, default.bDeepLog);
        `TACTICALRULES.SubmitGameState(NewGameState);
    }
    else
    {
        kLog("Cleaning up Pending Game State",
            true, default.bDeepLog);
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
    }
    return ELR_NoInterrupt;
}

//---------------------------------------------------------------------------//
/*
static function EventListenerReturn PostTileBumpListener_KMP01(
    Object EventData, 
    Object EventSource,
    XComGameState EventGameState,
    name EventID,
    Object CallbackData)
{
    local XComGameState_Player PlayerState;
    local XComGameState_Unit UnitState;
    local XComGameState NewGameState;
    local UnitValue UVal;

    UnitState = XComGameState_Unit(EventSource);
    PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
    
    if (!UnitState.GetUnitValue(class'X2Ability_DefaultAbilitySet'
            .default.ImmobilizedValueName, UVal))
    {
        kLog("Exit: No Immobilize UnitValue Found for Unit "
            @ UnitState.GetName(eNameType_FullNick),
            true, default.bDeepLog);
        return ELR_NoInterrupt;
    }
    else if (UVal.fValue != default.fValueInterrupt)
    {
        kLog("Exit: Immobilize was set by other effect"
            @ UnitState.GetName(eNameType_FullNick),
            true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

    NewGameState = class'XComGameStateContext_ChangeContainer'.static
        .CreateChangeState("TileBumpListener_Interrupt_KMP01");
    UnitState = XComGameState_Unit(NewGameState
        .ModifyStateObject(UnitState.Class, UnitState.ObjectID));

    kLog("Remove Immobilize UnitValue",
            true, default.bDeepLog);
    UnitState.ClearUnitValue(class'X2Ability_DefaultAbilitySet'
        .default.ImmobilizedValueName);

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
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
    }
    return ELR_NoInterrupt;
}
*/
//---------------------------------------------------------------------------//
/*
static function EventListenerReturn TileBumpListener_KMP01(
    Object EventData, 
    Object EventSource,
    XComGameState EventGameState,
    name EventID,
    Object CallbackData)
{
    local XComGameState_Unit ELUnit;
    local XComGameState_Unit MovingUnit;
    local XComGameState NewGameState;
    local array<Actor> TileActors;

    local XComGameState_Player MovingPlayer;
    local XComGameState_Player ListenerPlayer;

    MovingUnit = XComGameState_Unit(EventSource);  // Moving Unit
    ELUnit = XComGameState_Unit(CallbackData);  // Listener Unit

    ListenerPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(ELUnit.ControllingPlayer.ObjectID));
    MovingPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(MovingUnit.ControllingPlayer.ObjectID));

    kLog("Listener Unit:" @ ELUnit.GetName(eNameType_FullNick)
        $ "\n    Listener Player:" @ ListenerPlayer.ObjectID
            @ ListenerPlayer.PlayerName @ ListenerPlayer.TeamFlag
        $ "\n    Moving Unit:" @ MovingUnit.GetName(eNameType_FullNick)
        $ "\n    Moving Player:" @ MovingPlayer.ObjectID
            @ MovingPlayer.PlayerName @ MovingPlayer.TeamFlag,
        true, default.bDeepLog);

    if (ELUnit == MovingUnit)
    {
        kLog("Exit: Units are the same" , true, default.bDeepLog);
        return ELR_NoInterrupt;
    }
    
    TileActors = `XWORLD.GetActorsOnTile(ELUnit.TileLocation);

    if (TileActors.Length <= 1)
    {
        kLog("Exit: Less than two units on tile" , true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

    NewGameState = class'XComGameStateContext_ChangeContainer'.static
        .CreateChangeState("TileBumpListener_KMP01");

    HandleTileBump(ELUnit, NewGameState);

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
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
    }
    return ELR_NoInterrupt;
}
*/
//---------------------------------------------------------------------------//
/*
private static function HandleTileBump(XComGameState_Unit Unit,
                                       XComGameState NewGameState)
{
	local XComWorldData World;
	local vector NewLoc;
	local XGUnit UnitVisualizer;
	local TTile NewTileLocation;
    local array<Actor> TileActors;

	World = `XWORLD;

	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(
        class'XComGameState_Unit', Unit.ObjectID));

    
    kLog("Handling Tile Bump:" , true, default.bDeepLog);

    TileActors = World.GetActorsOnTile(Unit.TileLocation);
    if (TileActors.Length <= 1)
    {
        kLog("Exit: Less than two units on tile" , true, default.bDeepLog);
        return;
    }

	// Move the tile location of the unit
	UnitVisualizer = XGUnit(Unit.GetVisualizer());
	if( !UnitVisualizer.m_kBehavior.PickRandomCoverLocation(
        NewLoc, default.COLLISION_MIN_TILE_DISTANCE,
        default.COLLISION_MAX_TILE_DISTANCE) )
	{
        kLog("UnitVisualizer.m_kBehavior.PickRandomCoverLocation: False" , true, default.bDeepLog);
		NewLoc = World.FindClosestValidLocation(
            UnitVisualizer.Location, false, false, true);
	}

	NewTileLocation = World.GetTileCoordinatesFromPosition(NewLoc); 
	Unit.SetVisibilityLocation(NewTileLocation);
}
*/
//---------------------------------------------------------------------------//
/*
static function EventListenerReturn TileBumpListener_Immediate_KMP01(
    Object EventData, 
    Object EventSource,
    XComGameState EventGameState,
    name EventID,
    Object CallbackData)
{
    local XComGameState_Unit ELUnit;
    local XComGameState_Unit MovingUnit;
    local array<Actor> TileActors;
    local TTile MV_Location;
    local TTile EL_Location;

    local XComGameState_Player MovingPlayer;
    local XComGameState_Player ListenerPlayer;

    local XComGameStateContext_Ability AbilityContext;
    local array<PathingInputData> MovePaths;
    local PathingInputData PathData;
    local array<TTile> MoveTiles;
    local TTile MTile;
    local string Msg;
    local int idx;

    MovingUnit = XComGameState_Unit(EventSource);  // Moving Unit
    ELUnit = XComGameState_Unit(CallbackData);  // Listener Unit

    ListenerPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(ELUnit.ControllingPlayer.ObjectID));
    MovingPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(MovingUnit.ControllingPlayer.ObjectID));

    if (ELUnit == MovingUnit)
    {
        kLog("Exit: Units are the same" , true, default.bDeepLog);
        return ELR_NoInterrupt;
    }
    if (ELUnit.ControllingPlayer == MovingUnit.ControllingPlayer)
    {
        kLog("Exit: Units are controlled by the same Player" , true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

    //// This doesn't work here because the event hasn't been processed yet
    //TileActors = `XWORLD.GetActorsOnTile(ELUnit.TileLocation);
    //
    //if (TileActors.Length <= 1)
    //{
    //    kLog("Exit: Less than two units on tile" , true, default.bDeepLog);
    //    return ELR_NoInterrupt;
    //}

    //MovingUnit.GetKeystoneVisibilityLocation(MV_Location);
    //ELUnit.GetKeystoneVisibilityLocation(EL_Location);
    //if (MV_Location != EL_Location)
    //{
    //    kLog("Exit: Units will not collide"
    //        $ "\n    MV_Location: x:" @ MV_Location.X @ "y:" @ MV_Location.Y @ "z:" @ MV_Location.Z
    //        $ "\n    EL_Location: x:" @ EL_Location.X @ "y:" @ EL_Location.Y @ "z:" @ EL_Location.Z,
    //        true, default.bDeepLog);
    //    return ELR_NoInterrupt;
    //}

    AbilityContext = XComGameStateContext_Ability(EventGameState.GetContext());

    if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
    {
        return ELR_NoInterrupt;
    }
    kLog("INTERRUPT PHASE!!!" , true, default.bDeepLog);

    MovePaths = AbilityContext.InputContext.MovementPaths;
    Msg = "";
    foreach MovePaths(PathData, idx)
    {
        Msg $= "\n    MovePath[" $ idx $ "]:";
        MoveTiles = PathData.MovementTiles;
        foreach MoveTiles(MTile, idx)
        {
            Msg $= "\n        MTile[" $ idx $ "]: x:" @ MTile.X @ "y:" @ MTile.Y @ "z:" @ MTile.Z;
        }
    }
    kLog(Msg, true, default.bDeepLog);

    if (MTile != ELUnit.TileLocation)
    {
        kLog("Exit: Units will not collide"
            $ "\n    MVUnit.TileLocation: x:" @ MTile.X @ "y:" @ MTile.Y @ "z:" @ MTile.Z
            //$ "\n    MVUnit.TileLocation: x:" @ MovingUnit.TileLocation.X @ "y:" @ MovingUnit.TileLocation.Y @ "z:" @ MovingUnit.TileLocation.Z
            $ "\n    ELUnit.TileLocation: x:" @ ELUnit.TileLocation.X @ "y:" @ ELUnit.TileLocation.Y @ "z:" @ ELUnit.TileLocation.Z,
            true, default.bDeepLog);
        return ELR_NoInterrupt;
    }

    kLog("Listener Unit:" @ ELUnit.GetName(eNameType_FullNick)
        @ "; Location: x:" @ ELUnit.TileLocation.X @ "y:" @ ELUnit.TileLocation.Y @ "z:" @ ELUnit.TileLocation.Z
        $ "\n    Listener Player:" @ ListenerPlayer.ObjectID
            @ ListenerPlayer.PlayerName @ ListenerPlayer.TeamFlag
        $ "\n    Moving Unit:" @ MovingUnit.GetName(eNameType_FullNick)
        @ "; Location: x:" @ MovingUnit.TileLocation.X @ "y:" @ MovingUnit.TileLocation.Y @ "z:" @ MovingUnit.TileLocation.Z
        $ "\n    Moving Player:" @ MovingPlayer.ObjectID
            @ MovingPlayer.PlayerName @ MovingPlayer.TeamFlag,
        true, default.bDeepLog);

    // PURGEEEEEEEE
    ThisIsProbablyUnstableAsFrick(EventGameState);

    //return ELR_InterruptEventAndListeners;
    //return ELR_InterruptEvent;
    //return ELR_InterruptListeners;
    return ELR_NoInterrupt;
}
*/
//---------------------------------------------------------------------------//

// Cancel the movement action pepega
private static function ThisIsProbablyUnstableAsFrick(out XComGameState NewGameState)
{
    local XComGameState_BaseObject TargetObject;
    local int NumObjects;
    //local int idx;
    
    NumObjects = NewGameState.GetNumGameStateObjects();

    kLog("NumObjects:" @ NumObjects, true, default.bDeepLog);

    if (NewGameState.HistoryIndex > -1)
    {
        kLog("MONKAS: Game State exists in History", true, default.bDeepLog);
    }

    // PURGE THE MOVEMENT BWAHAHAHA
    
    while (NumObjects > 0)
    {
        TargetObject = NewGameState.DebugGetGameStateForObjectIndex(NumObjects - 1);
        NewGameState.PurgeGameStateForObjectID(TargetObject.ObjectID);
        NumObjects = NewGameState.GetNumGameStateObjects();
        kLog("NumObjects:" @ NumObjects, true, default.bDeepLog);
    }
    
    /*for (idx = NumObjects - 1; idx >= 0 ; idx--)
    {
        TargetObject = NewGameState.DebugGetGameStateForObjectIndex(idx);
        NewGameState.RemoveStateObject(TargetObject.ObjectID);
        kLog("NumObjects:" @ NewGameState.GetNumGameStateObjects(), true, default.bDeepLog);
    }
    if (NumObjects == 1)
    {
        TargetObject = NewGameState.DebugGetGameStateForObjectIndex(0);
        NewGameState.RemoveStateObject(TargetObject.ObjectID);
        kLog("NumObjects:" @ NewGameState.GetNumGameStateObjects(), true, default.bDeepLog);
    }*/
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
	if(!UnitState.IsEnemyUnit(TargetUnit)
        || Unit.IsVisibleToTeam(LocalPlayer.TeamFlag)
        || TargetUnit.IsCivilian())
	{
		return eGameplayBlocking_Blocks;
	}
	else
	{
		return eGameplayBlocking_DoesNotBlock;
	}
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
    // class'X2ModConfig_KMP01'.default.Unstable

    EffectRank=1 // This rank is set for blocking
    EffectName="ScanBeGone_Effect_KMP01"
    fValueInterrupt=2391060667
}
