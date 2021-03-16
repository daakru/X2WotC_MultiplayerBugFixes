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

var localized string strMovementBlockedByTileBump;

var bool bDeepLog;

var private const float fValueInterrupt;
var private const string imgTileBump;
var private const float TypicalMoveDelay;

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
    /*
    `XEVENTMGR.RegisterForEvent(
        EffectObject,
        'AbilityActivated',
        TileBumpListener_Cleanup_KMP01,
        ELD_OnVisualizationBlockStarted, ,
        EffectUnit, ,
    );
    */
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
    //local XComGameState_Ability AbilityState;
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
        // bad
    }

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
    //UnitState.SetUnitFloatValue(default.EffectName, 1, eCleanup_BeginTurn);

    kLog("bVisOrderIdp:" @ AbilityContext.bVisualizationOrderIndependent
        $ "\n    DesVisBlock: " @ AbilityContext.DesiredVisualizationBlockIndex
        //$ "\n    bVisFence:   " @ AbilityContext.bVisualizationFence
        //$ "\n    VisFenceTime:" @ AbilityContext.VisualizationFenceTimeout
        $ "\n    PreBuildVis: " @ AbilityContext.PreBuildVisualizationFn.Length
        $ "\n    PostVisBuild:" @ AbilityContext.PostBuildVisualizationFn.Length,
        true, default.bDeepLog);

    //AbilityContext.bVisualizationOrderIndependent = false;
    //AbilityContext.DesiredVisualizationBlockIndex = `XCOMHISTORY.GetCurrentHistoryIndex() + 10;
    //AbilityContext.bVisualizationFence = true;
    //AbilityContext.PreBuildVisualizationFn.Length = 0;
    AbilityContext.PreBuildVisualizationFn.AddItem(TileBump_PreBuildVisualization);
    //AbilityContext.PostBuildVisualizationFn.Length = 0;
    //AbilityContext.PostBuildVisualizationFn.AddItem(TileBump_PostBuildVisualization);

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

/// <summary>
/// Open the tome of Black Magic and prepare to release the seal
/// </summary>
static function EventListenerReturn TileBumpListener_Cleanup_KMP01(
    Object EventData, 
    Object EventSource,
    XComGameState EventGameState,
    name EventID,
    Object CallbackData)
{
    local delegate<X2AbilityTemplate.BuildVisualizationDelegate> PreBuildVis;
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_Unit UnitState;
    local XComGameState NewGameState;
    local UnitValue UVal;

    kLog("AbilityActivated Event for Visualization:", true, default.bDeepLog);
    
    AbilityContext = XComGameStateContext_Ability(EventGameState.GetContext());
    UnitState = XComGameState_Unit(EventSource);

    kLog("PreBuildVisFn.Length:" @ AbilityContext.PreBuildVisualizationFn.Length, true, default.bDeepLog);
    
    if (AbilityContext.PreBuildVisualizationFn.Find(TileBump_PreBuildVisualization) == INDEX_NONE)
    {
        kLog("Exit: No PreBuildVisFn Found for Unit"
            @ UnitState.GetName(eNameType_FullNick),
            true, default.bDeepLog);
        return ELR_NoInterrupt;
    }
    kLog("PreBuildVisFn Found!", true, default.bDeepLog);

    TileBump_PostBuildVisualization(EventGameState);

    return ELR_NoInterrupt;
}

//---------------------------------------------------------------------------//

/// <summary>
/// Activate Black Magic to remove the Immobilized UnitValue added on Interrupt
/// </summary>
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

    return ELR_NoInterrupt;
}

simulated function TileBump_PreBuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory              History;
    local VisualizationActionMetadata       ActionMetadata;
    local X2Action_PlaySoundAndFlyOver      SoundAction;
	local XComGameStateContext_Ability      AbilityContext;
	//local X2Action_CameraLookAt             LookAtAction;
	local int                               ObjectID;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
    ObjectID = AbilityContext.InputContext.SourceObject.ObjectID;

	History = `XCOMHISTORY;
	
	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	ActionMetadata.VisualizeActor = History.GetVisualizer(ObjectID);
	// Just merge it directly into the build tree root -- the whole context will be inserted correctly
	ActionMetadata.LastActionAdded = `XCOMVISUALIZATIONMGR.BuildVisTree;

	SoundAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
	SoundAction.SetSoundAndFlyOverParameters(SoundCue'SoundGlobalUI.MenuClickNegative_Cue'/*AkEvent'SoundX2StrategyUI.ToDoWidget_Red'*/, default.strMovementBlockedByTileBump, /*CharacterSpeech*/'', eColor_Bad, imgTileBump, /*LookAtDuration*/, /*BlockUntilFinished*/, /*VisibleTeam*/, /*MessageBehavior*/);  // SoundCue(`CONTENT.RequestGameArchetype("KAndromedonGU.Sound.OhYeah"))
    // SoundUI.NegativeSelection2Cue
    TileBumpCleanup(XComGameState_Unit(History.GetGameStateForObjectID(ObjectID)));
}

static function TileBump_PostBuildVisualization(XComGameState VisualizeGameState)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_Unit UnitState;
    local XComGameState NewGameState;
    local TTile StartLocation;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

    StartLocation = AbilityContext.InputContext.MovementPaths[0].MovementTiles[0];

    kLog("Begin Casting Black Magic:", true, default.bDeepLog);

    //NewGameState = class'XComGameStateContext_ChangeContainer'.static
    //    .CreateChangeState("TileBumpCleanup");

    //UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(
    //    class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));
    UnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(
        AbilityContext.InputContext.SourceObject.ObjectID));

    // Correct Unit Location
    `CHEATMGR.TeleportUnit(XGUnit(UnitState.GetVisualizer()), `XWORLD.GetPositionFromTileCoordinates(StartLocation));

    kLog("Moving Back to Start Location: x:" @ StartLocation.X
        @ "y:" @ StartLocation.Y @ "z:" @ StartLocation.Z,
        true, default.bDeepLog); 
    /*
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
    */
    kLog("Seal the Black Magic back within the void", true, default.bDeepLog);
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

    imgTileBump="img:///KMP01_UILibrary_PerkIcons.UIPerk_cmdr_choseninfo"
    TypicalMoveDelay=0.5f
}
