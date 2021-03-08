/*                                                                             
 * FILE:     X2EventListener_RemovePersistentEffects_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01 v0.0
 *
 * Register Event Listeners to Remove Persistent Effects that aren't ticking.
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class X2EventListener_RemovePersistentEffects_KMP01 extends X2EventListener;

var bool bDeepLog;

//---------------------------------------------------------------------------//

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;

    Templates.AddItem(CreatePlayerTurnEndedTemplate());

    return Templates;
}

//---------------------------------------------------------------------------//

static function X2EventListenerTemplate CreatePlayerTurnEndedTemplate()
{
    local X2EventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template,
        'PlayerTurnEndedListenerTemplate_KMP01');

    // Should the Event Listener listen for the event during tactical missions?
    Template.RegisterInTactical = true;
    // Should listen to the event while on Avenger?
    Template.RegisterInStrategy = false;
    Template.AddEvent('PlayerTurnEnded', OnPlayerTurnEnded_KMP01);

    return Template;
}

//---------------------------------------------------------------------------//

private static function array<name> Generate_PTE_ForceRemoveEffects()
{
    local array<name> EffectList;

    EffectList.AddItem('SteadyHandsStatBoost');
    EffectList.AddItem('HunkerDown');
    //EffectList.AddItem('');

    return EffectList;
}

/**
 *  Triggered on Line 4574 in X2TacticalGameRuleset.uc
 *
 *  PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(PreviousPlayerRef.ObjectID));
 *  Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_PlayerTurnEnd);
 *  Context.PlayerRef = PreviousPlayerRef;
 *  NewGameState = Context.ContextBuildGameState();
 *
 *  EventManager.TriggerEvent('PlayerTurnEnded', PlayerState, PlayerState, NewGameState);
 */

/**
 *  Triggers the specified event, queueing up all listeners for this event to be processed 
 *  during their specified Event Window.  Also, immediately triggers the ELD_Immediate event window.
 *
 *  @param EventID is the handle for the type of event that has been triggered.
 *  @param EventData is the optional object containing the data relevant to this event's triggered state.
 *  @param EventSource is the optional object to be considered the source of this event (used for pre-filtering).
 *
 *  @return TRUE iff any event listener with ELD_Immediate specified for this event executes and causes an event interrupt
 *
 *  native function bool TriggerEvent( Name EventID, optional Object EventData, optional Object EventSource, optional XComGameState EventGameState );
 */

//---------------------------------------------------------------------------//

/// <summary>
/// Called when 'PlayerTurnEndedListenerTemplate_KMP01' is triggered by a 'PlayerTurnEnded' Event
/// </summary>
/// <param name="EventData">    XComGameState_Player of the Player whose turn is ending </param>
/// <param name="EventSource">  XComGameState_Player of the Player whose turn is ending </param>
/// <param name="NewGameState"> New XComGameState built from the GameRule Context </param>
static protected function EventListenerReturn OnPlayerTurnEnded_KMP01(
    Object EventData,
    Object EventSource,
    XComGameState EventGameState,
    Name EventID,  // 'PlayerTurnEnded'
    Object CallbackData)  // None
{
    local XComGameState_Player PlayerState;
    local XComGameState_Unit UnitState;
    local XComGameStateHistory History;
    local XComGameState NewGameState;
    local bool bUnitStateModified;
    
    History = `XCOMHISTORY;
    PlayerState = XComGameState_Player(EventData);

    kLog("Turn" @ PlayerState.PlayerTurnCount @ "Ending for Player:" @ PlayerState.ObjectID @ PlayerState.PlayerName @ PlayerState.TeamFlag, true, default.bDeepLog);

    NewGameState = class'XComGameStateContext_ChangeContainer'.static
        .CreateChangeState("OnPlayerTurnEnded_KMP01: Remove Effects");

    foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
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

        kLog("Now Checking Unit:" @ UnitState.GetMPName(eNameType_FullNick)
            $ "\n    Ending Player:     " @ PlayerState.ObjectID
                @ PlayerState.PlayerName @ PlayerState.TeamFlag
            $ "\n    Controlling Player:"
                @ UnitState.ControllingPlayer.ObjectID,
            true, default.bDeepLog);

        // Check if this Unit belongs to the Player whose turn is ending
        if (UnitState.ControllingPlayer.ObjectID == PlayerState.ObjectID)
        {
            bUnitStateModified = ModifyUnitState(NewGameState, UnitState);
            kLog("Unit with Template Name '" $ UnitState.GetMyTemplateName()
                $ "', ID '" $ UnitState.ObjectID
                $ "', and Name:" @ UnitState.GetMPName(eNameType_FullNick)
                $ ": bUnitStateModified =" @ bUnitStateModified,
                true, default.bDeepLog);
        }
        else
        {
            // TODO: Handle Units controlled by another Player
        }
    }

    if (NewGameState.GetNumGameStateObjects() > 0)
    {
        kLog("Adding NewGameState with" @ NewGameState.GetNumGameStateObjects()
            @ "modified State Objects to History.",
            true, default.bDeepLog);
        History.AddGameStateToHistory(NewGameState);
    }
    else
    {
        kLog("Cleaning up Pending Game State.",
            true, default.bDeepLog);
        History.CleanupPendingGameState(NewGameState);
    }
    return ELR_NoInterrupt;
}

//---------------------------------------------------------------------------//

static final function bool ModifyUnitState(XComGameState NewGameState,
                                           XComGameState_Unit UnitState)
{
    local array<name> PTE_ForceRemoveEffects;
    local XComGameState_Effect EffectState;
    local name EffectName;
    local bool bModified;

    local X2Effect_PersistentStatChange PStatEffect;
    local X2Effect_Persistent PEffect;

    PTE_ForceRemoveEffects = Generate_PTE_ForceRemoveEffects();

    foreach UnitState.AffectedByEffectNames(EffectName)
    {
        if (PTE_ForceRemoveEffects.Find(EffectName) == INDEX_NONE)  //(EffectName != 'SteadyHandsStatBoost')
        {
            kLog("Not interested in effect with name: '" $ EffectName $ "'",
                true, default.bDeepLog);
            continue;
        }
        EffectState = UnitState.GetUnitAffectedByEffectState(EffectName);
        PEffect = EffectState.GetX2Effect();
        if (!PEffect.IsA('X2Effect_PersistentStatChange'))
        {
            kRed("ERROR: Something Went Wrong!", false);
            kLog("Warning: Redscreen: ERROR: Something Went Wrong!",
                true, default.bDeepLog);
            continue;
        }

        kLog("Logging EffectState of '" $ EffectName $ "':"
            $ "\n    iTurnsRemaining:                   " @ EffectState.iTurnsRemaining
            //$ "\n    iShedChance:                       " @ EffectState.iShedChance
            //$ "\n    iStacks:                           " @ EffectState.iStacks
            //$ "\n    AttacksReceived:                   " @ EffectState.AttacksReceived
            //$ "\n    CreatedObjectReference.ObjectID:   " @ EffectState.CreatedObjectReference.ObjectID
            $ "\n    FullTurnsTicked:                   " @ EffectState.FullTurnsTicked
            $ "\n    StatChanges.Length:                " @ EffectState.StatChanges.Length
            $ "\n    ObjectID:                          " @ EffectState.ObjectID,
            true, default.bDeepLog);

        PStatEffect = X2Effect_PersistentStatChange(PEffect);

        kLog("Logging Template of '" $ EffectName $ "':"
            //$ "\n    TickTriggers.Length:               " @ PStatEffect.TickTriggers.Length
            $ "\n    iNumTurns:                         " @ PStatEffect.iNumTurns
            //$ "\n    iInitialShedChance:                " @ PStatEffect.iInitialShedChance
            //$ "\n    iPerTurnShedChance:                " @ PStatEffect.iPerTurnShedChance
            $ "\n    bInfiniteDuration:                 " @ PStatEffect.bInfiniteDuration
            //$ "\n    bTickWhenApplied:                  " @ PStatEffect.bTickWhenApplied
            //$ "\n    bCanTickEveryAction:               " @ PStatEffect.bCanTickEveryAction
            //$ "\n    bConvertTurnsToActions:            " @ PStatEffect.bConvertTurnsToActions
            //$ "\n    bRemoveWhenSourceDies:             " @ PStatEffect.bRemoveWhenSourceDies
            //$ "\n    bRemoveWhenTargetDies:             " @ PStatEffect.bRemoveWhenTargetDies
            //$ "\n    bRemoveWhenSourceDamaged:          " @ PStatEffect.bRemoveWhenSourceDamaged
            //$ "\n    bRemoveWhenTargetConcealmentBroken:" @ PStatEffect.bRemoveWhenTargetConcealmentBroken
            //$ "\n    bPersistThroughTacticalGameEnd:    " @ PStatEffect.bPersistThroughTacticalGameEnd
            $ "\n    bIgnorePlayerCheckOnTick:          " @ PStatEffect.bIgnorePlayerCheckOnTick
            //$ "\n    bUniqueTarget:                     " @ PStatEffect.bUniqueTarget
            //$ "\n    bStackOnRefresh:                   " @ PStatEffect.bStackOnRefresh
            //$ "\n    bDupeForSameSourceOnly:            " @ PStatEffect.bDupeForSameSourceOnly
            //$ "\n    bEffectForcesBleedout:             " @ PStatEffect.bEffectForcesBleedout
            $ "\n    DuplicateResponse:                 " @ PStatEffect.DuplicateResponse
            $ "\n    ApplyOnTick.Length:                " @ PStatEffect.ApplyOnTick.Length
            $ "\n    WatchRule:                         " @ PStatEffect.WatchRule
            //$ "\n    CustomIdleOverrideAnim:            " @ PStatEffect.CustomIdleOverrideAnim
            //$ "\n    EffectRank:                        " @ PStatEffect.EffectRank
            //$ "\n    EffectName:                        " @ PStatEffect.EffectName
            //$ "\n    BuffCategory:                      " @ PStatEffect.BuffCategory
            //$ "\n    AbilitySourceName:                 " @ PStatEffect.AbilitySourceName
            //$ "\n    bDisplayInUI:                      " @ PStatEffect.bDisplayInUI
            //$ "\n    bDisplayInSpecialDamageMessageUI:  " @ PStatEffect.bDisplayInSpecialDamageMessageUI
            $ "\n    FriendlyName:                      " @ PStatEffect.FriendlyName
            $ "\n    FriendlyDescription:               " @ PStatEffect.FriendlyDescription
            /* $ "\n    IconImage:                         " @ PStatEffect.IconImage
            $ "\n    SourceBuffCategory:                " @ PStatEffect.SourceBuffCategory
            $ "\n    bSourceDisplayInUI:                " @ PStatEffect.bSourceDisplayInUI
            $ "\n    SourceFriendlyName:                " @ PStatEffect.SourceFriendlyName
            $ "\n    SourceFriendlyDescription:         " @ PStatEffect.SourceFriendlyDescription
            $ "\n    SourceIconLabel:                   " @ PStatEffect.SourceIconLabel
            $ "\n    StatusIcon:                        " @ PStatEffect.StatusIcon
            $ "\n    EffectHierarchyValue:              " @ PStatEffect.EffectHierarchyValue
            $ "\n    EffectAppliedEventName:            " @ PStatEffect.EffectAppliedEventName
            $ "\n    ChanceEventTriggerName:            " @ PStatEffect.ChanceEventTriggerName
            $ "\n    EffectTickedFn:                    " @ PStatEffect.EffectTickedFn */,
            true, default.bDeepLog);
        if (class'X2ModConfig_KMP01'.default.Unstable)
        {
            kLog("Removing Effect:" @ EffectName, true, default.bDeepLog);
            EffectState = XComGameState_Effect(NewGameState
                .ModifyStateObject(EffectState.Class, EffectState.ObjectID));
            
            EffectState.RemoveEffect(NewGameState, NewGameState);
            bModified = true;
        }
    }
    return bModified;
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
}