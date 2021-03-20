/*                                                                             
 * FILE:     X2EventListener_RemovePersistentEffects_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * Register Event Listeners to Remove Persistent Effects that aren't ticking.
 * NOTE: Seems to only activate on the active player's machine
 *
 * Dependencies: X2ModConfig_KMP01; X2Helpers_Logger_KMP01
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class X2EventListener_RemovePersistentEffects_KMP01 extends X2EventListener;

var bool bDeepLog;
var bool bPathLog;
var bool bSubLog;

//---------------------------------------------------------------------------//

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;

    Templates.AddItem(CreateUnitGroupTurnBegunTemplate());
    Templates.AddItem(CreateUnitGroupTurnEndedTemplate());
    Templates.AddItem(CreatePlayerTurnBegunTemplate());
    Templates.AddItem(CreatePlayerTurnEndedTemplate());

    return Templates;
}

//---------------------------------------------------------------------------//

static function X2EventListenerTemplate CreateUnitGroupTurnBegunTemplate()
{
    local X2EventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template,
        'UnitGroupTurnBegunListenerTemplate_KMP01');

    // Should the Event Listener listen for the event during tactical missions?
    Template.RegisterInTactical = true;
    // Should listen to the event while on Avenger?
    Template.RegisterInStrategy = false;
    Template.AddEvent('UnitGroupTurnBegun', OnUnitGroupTurnEvent_KMP01);

    return Template;
}

static function X2EventListenerTemplate CreateUnitGroupTurnEndedTemplate()
{
    local X2EventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template,
        'UnitGroupTurnEndedListenerTemplate_KMP01');

    // Should the Event Listener listen for the event during tactical missions?
    Template.RegisterInTactical = true;
    // Should listen to the event while on Avenger?
    Template.RegisterInStrategy = false;
    Template.AddEvent('UnitGroupTurnEnded', OnUnitGroupTurnEvent_KMP01);

    return Template;
}

static function X2EventListenerTemplate CreatePlayerTurnBegunTemplate()
{
    local X2EventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template,
        'PlayerTurnBegunListenerTemplate_KMP01');

    // Should the Event Listener listen for the event during tactical missions?
    Template.RegisterInTactical = true;
    // Should listen to the event while on Avenger?
    Template.RegisterInStrategy = false;
    Template.AddEvent('PlayerTurnBegun', OnPlayerTurnEvent_KMP01);

    return Template;
}

static function X2EventListenerTemplate CreatePlayerTurnEndedTemplate()
{
    local X2EventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template,
        'PlayerTurnEndedListenerTemplate_KMP01');

    // Should the Event Listener listen for the event during tactical missions?
    Template.RegisterInTactical = true;
    // Should listen to the event while on Avenger?
    Template.RegisterInStrategy = false;
    Template.AddEvent('PlayerTurnEnded', OnPlayerTurnEvent_KMP01);

    return Template;
}

//---------------------------------------------------------------------------//

/// <summary>
/// Called on triggering a 'UnitGroupTurnBegun' or 'UnitGroupTurnEnded' Event
/// </summary>
/// <param name="EventData">    XComGameState_AIGroup that triggered the event </param>
/// <param name="EventSource">  XComGameState_AIGroup that triggered the event </param>
/// <param name="NewGameState"> New XComGameState built from the GameRule Context </param>
static protected function EventListenerReturn OnUnitGroupTurnEvent_KMP01(
    Object EventData,
    Object EventSource,
    XComGameState EventGameState,
    Name EventID,  // 'UnitGroupTurnBegun' or 'UnitGroupTurnEnded'
    Object CallbackData)  // None
{
    local XComGameState_AIGroup GroupState;
    local XComGameState_Unit UnitState;
    local XComGameStateHistory History;
    local XComGameState NewGameState;
    local bool bUnitStateModified;
    local array<int> LivingMemberIDs;
    local array<XComGameState_Unit> LivingMembers;
    local int idx;
    local XComGameState_Player CtrlPlayer;

    History = `XCOMHISTORY;
    GroupState = XComGameState_AIGroup(EventData);

    kLog("Turn" @ (EventID == 'UnitGroupTurnBegun' ? "Begun" : "Ended")
        @ "for Group on team:" @ GroupState.TeamName
        @ "with Initiative Priority:" @ GroupState.InitiativePriority,
        true, default.bPathLog);

    NewGameState = class'XComGameStateContext_ChangeContainer'.static
        .CreateChangeState("OnUnitGroupTurnEvent_KMP01");

    if (!GroupState.GetLivingMembers(LivingMemberIDs, LivingMembers))
    {
        // No Units in this Unit Group
        kLog("No Units found in Group: Exiting ELR_NoInterrupt",
            true, default.bSubLog);
        return ELR_NoInterrupt;
    }

    foreach LivingMembers(UnitState, idx)
    {
        // Skip removed (evac'ed), non-selectable (mimic beacon),
        //   cosmectic (gremlin), dead, and playerless (MOCX!) Units
        if (UnitState == none || UnitState.bRemovedFromPlay
            || UnitState.ControllingPlayer.ObjectID <= 0
            || UnitState.GetMyTemplate().bNeverSelectable
            || UnitState.GetMyTemplate().bIsCosmetic
            || !UnitState.IsAlive())
        {
            continue;
        }

        CtrlPlayer = XComGameState_Player(History.GetGameStateForObjectID(
            UnitState.ControllingPlayer.ObjectID));

        kLog("Now Checking Unit:" @ UnitState.GetMPName(eNameType_FullNick)
            $ "\n    Controlling Player:" @ CtrlPlayer.ObjectID
                @ CtrlPlayer.PlayerName @ CtrlPlayer.TeamFlag,
            true, default.bSubLog);

        if (CtrlPlayer.ObjectID > 0)
        {
            bUnitStateModified = class'X2Helpers_PersistentStatChangeFix_KMP01'
                .static.ModifyUnitState(NewGameState, UnitState, EventID);
            kLog("Unit with Template Name '" $ UnitState.GetMyTemplateName()
                $ "', ID '" $ UnitState.ObjectID
                $ "', and Name:" @ UnitState.GetMPName(eNameType_FullNick)
                $ ": bUnitStateModified =" @ bUnitStateModified,
                true, default.bSubLog);
        }
    }

    if (NewGameState.GetNumGameStateObjects() > 0)
    {
        kLog("Adding NewGameState with" @ NewGameState.GetNumGameStateObjects()
            @ "modified State Objects to TacRules",
            true, default.bSubLog);
        `TACTICALRULES.SubmitGameState(NewGameState);
    }
    else
    {
        kLog("Cleaning up Pending Game State",
            true, default.bSubLog);
        History.CleanupPendingGameState(NewGameState);
    }
    return ELR_NoInterrupt;
}

//---------------------------------------------------------------------------//

/// <summary>
/// Called on triggering a 'PlayerTurnBegun' or 'PlayerTurnEnded' Event
/// </summary>
/// <param name="EventData">    XComGameState_Player that triggered the event </param>
/// <param name="EventSource">  XComGameState_Player that triggered the event </param>
/// <param name="NewGameState"> New XComGameState built from the GameRule Context </param>
static protected function EventListenerReturn OnPlayerTurnEvent_KMP01(
    Object EventData,
    Object EventSource,
    XComGameState EventGameState,
    Name EventID,  // 'PlayerTurnEnded' or 'PlayerTurnEnded'
    Object CallbackData)  // None
{
    local XComGameState_Player PlayerState;
    local XComGameStateHistory History;
    local XComGameState NewGameState;
    //local bool bStateModified;
    
    History = `XCOMHISTORY;
    PlayerState = XComGameState_Player(EventData);

    kLog("Turn" @ PlayerState.PlayerTurnCount @ (EventID == 'PlayerTurnBegun'
        ? "Begun" : "Ended") @ "for Player:" @ PlayerState.ObjectID
        @ PlayerState.PlayerName @ PlayerState.TeamFlag,
        true, default.bPathLog);

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //

    // Return because we aren't using this function for anything but logging
    return ELR_NoInterrupt;
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //

    NewGameState = class'XComGameStateContext_ChangeContainer'.static
        .CreateChangeState("OnPlayerTurnEvent_KMP01");

    // HANDLE MODIFICATIONS TO GAME STATE

    // NOTE: Moved Fix for Deep Cover and Steady Hands to UnitGroup Events
    //bStateModified = class'X2Helpers_PersistentStatChangeFix_KMP01'
    //    .static.HandlePlayerTurnEvent(NewGameState, PlayerState, EventID);

    // END HANDLE MODIFICATIONS TO GAME STATE

    if (NewGameState.GetNumGameStateObjects() > 0)
    {
        kLog("Adding NewGameState with" @ NewGameState.GetNumGameStateObjects()
            @ "modified State Objects to TacRules",
            true, default.bSubLog);
        `TACTICALRULES.SubmitGameState(NewGameState);
    }
    else
    {
        kLog("Cleaning up Pending Game State.",
            true, default.bSubLog);
        History.CleanupPendingGameState(NewGameState);
    }
    return ELR_NoInterrupt;
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
    bDeepLog=false
    bPathLog=true
    bSubLog=false
}
