/*                                                                             
 * FILE:     X2Helpers_PersistentStatChangeFix_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * Add functions used by X2EventListener_RemovePersistentEffects_KMP01.uc.
 *
 * Dependencies: X2ModConfig_KMP01; X2Helpers_Logger_KMP01
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class X2Helpers_PersistentStatChangeFix_KMP01 extends Object abstract;

var bool bDeepLog;
var bool bPathLog;
var bool bSubLog;

//---------------------------------------------------------------------------//

private static function array<name> Generate_PTE_ForceRemoveEffects()
{
    local array<name> EffectList;

    EffectList.AddItem('SteadyHandsStatBoost');
    EffectList.AddItem('HunkerDown');
    //EffectList.AddItem('');

    return EffectList;
}

//---------------------------------------------------------------------------//

/// <summary>
/// Called on triggering a 'PlayerTurnBegun' or 'PlayerTurnEnded' Event
/// </summary>
/// <param name="EventData">    XComGameState_Player that triggered the event </param>
/// <param name="EventSource">  XComGameState_Player that triggered the event </param>
/// <param name="NewGameState"> New XComGameState built from the GameRule Context </param>
static final function bool HandlePlayerTurnEvent(XComGameState NewGameState,
    XComGameState_Player PlayerState, Name EventID)
{
    local XComGameStateHistory History;
    local XComGameState_Unit UnitState;
    local bool bUnitStateModified;
    
    History = `XCOMHISTORY;

    kLog("HandlePlayerTurnEvent:", true, default.bPathLog);

    foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
    {
        kLog("Now Checking Unit:" @ UnitState.GetMPName(eNameType_FullNick)
            $ "\n    Ending Player:     " @ PlayerState.ObjectID
                @ PlayerState.PlayerName @ PlayerState.TeamFlag
            $ "\n    Controlling Player:"
                @ UnitState.ControllingPlayer.ObjectID,
            true, default.bSubLog);

        // Skip if Unit is not valid or does not belong to the Turn Player
        if (!class'X2Helpers_Utility_KMP01'.static.IsUnitValid(UnitState)
            || UnitState.ControllingPlayer.ObjectID != PlayerState.ObjectID)
        {
            continue;
        }

        bUnitStateModified = ModifyUnitState(NewGameState, UnitState, EventID);
        kLog("Unit with Template Name '" $ UnitState.GetMyTemplateName()
            $ "', ID '" $ UnitState.ObjectID
            $ "', and Name:" @ UnitState.GetMPName(eNameType_FullNick)
            $ ": bUnitStateModified =" @ bUnitStateModified,
            true, default.bSubLog);
    }

    return bUnitStateModified;
}

//---------------------------------------------------------------------------//

static final function bool ModifyUnitState(XComGameState NewGameState,
                                           XComGameState_Unit UnitState,
                                           optional name TriggeredEventID)
{
    local array<name> PTE_ForceRemoveEffects;
    local XComGameState_Effect EffectState;
    local name EffectName;
    local bool bModified;

    local X2Effect_PersistentStatChange PStatEffect;
    local X2Effect_Persistent PEffect;

    kLog("ModifyUnitState:", true, default.bPathLog);

    PTE_ForceRemoveEffects = Generate_PTE_ForceRemoveEffects();

    foreach UnitState.AffectedByEffectNames(EffectName)
    {
        if (PTE_ForceRemoveEffects.Find(EffectName) == INDEX_NONE)  //(EffectName != 'SteadyHandsStatBoost')
        {
            kLog("Not interested in effect with name: '" $ EffectName $ "'",
                true, default.bSubLog);
            continue;
        }
        EffectState = UnitState.GetUnitAffectedByEffectState(EffectName);
        PEffect = EffectState.GetX2Effect();
        if (!PEffect.IsA('X2Effect_PersistentStatChange'))
        {
            kRed("ERROR: Something Went Wrong!", false);
            kLog("Warning: Redscreen: ERROR: Something Went Wrong!",
                true, default.bSubLog);
            continue;
        }

        kLog("Logging EffectState of '" $ EffectName $ "':"
            $ "\n    iTurnsRemaining:                   " @ EffectState.iTurnsRemaining
            $ "\n    FullTurnsTicked:                   " @ EffectState.FullTurnsTicked
            $ "\n    StatChanges.Length:                " @ EffectState.StatChanges.Length
            $ "\n    ObjectID:                          " @ EffectState.ObjectID,
            true, default.bSubLog);

        PStatEffect = X2Effect_PersistentStatChange(PEffect);

        kLog("Logging Template of '" $ EffectName $ "':"
            $ "\n    iNumTurns:                         " @ PStatEffect.iNumTurns
            $ "\n    bInfiniteDuration:                 " @ PStatEffect.bInfiniteDuration
            $ "\n    bIgnorePlayerCheckOnTick:          " @ PStatEffect.bIgnorePlayerCheckOnTick
            $ "\n    DuplicateResponse:                 " @ PStatEffect.DuplicateResponse
            $ "\n    ApplyOnTick.Length:                " @ PStatEffect.ApplyOnTick.Length
            $ "\n    WatchRule:                         " @ PStatEffect.WatchRule
            $ "\n    FriendlyName:                      " @ PStatEffect.FriendlyName
            $ "\n    FriendlyDescription:               " @ PStatEffect.FriendlyDescription,
            true, default.bSubLog);

        // Universal Features
        switch (TriggeredEventID)
        {
            case 'PlayerTurnBegun':
                break;
            case 'UnitGroupTurnBegun':
                if (EffectName == 'HunkerDown')
                {
                    kLog("UnitGroupTurnBegun: Removing Effect:" @ EffectName, true, default.bSubLog);
                    EffectState = XComGameState_Effect(NewGameState
                        .ModifyStateObject(EffectState.Class, EffectState.ObjectID));
            
                    EffectState.RemoveEffect(NewGameState, NewGameState);
                    bModified = true;
                }
                break;
            case 'PlayerTurnEnded':
                break;
            case 'UnitGroupTurnEnded':
                if (EffectName == 'SteadyHandsStatBoost')
                {
                    kLog("UnitGroupTurnEnded: Removing Effect:" @ EffectName, true, default.bSubLog);
                    EffectState = XComGameState_Effect(NewGameState
                        .ModifyStateObject(EffectState.Class, EffectState.ObjectID));
            
                    EffectState.RemoveEffect(NewGameState, NewGameState);
                    bModified = true;
                }
                break;
            default:
                break;
        }

        // Enable Stable Only Features
        if (!class'X2ModConfig_KMP01'.default.Unstable)
        {
            switch (TriggeredEventID)
            {
                case 'PlayerTurnBegun':
                    break;
                case 'UnitGroupTurnBegun':
                    break;
                case 'PlayerTurnEnded':
                    break;
                case 'UnitGroupTurnEnded':
                    break;
                default:
                    break;
            }
        }
        // Enable Developmental Only Features
        else
        {
            switch (TriggeredEventID)
            {
                case 'PlayerTurnBegun':
                    break;
                case 'UnitGroupTurnBegun':
                    break;
                case 'PlayerTurnEnded':
                    break;
                case 'UnitGroupTurnEnded':
                    break;
                default:
                    break;
            }
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
    bDeepLog=false
    bPathLog=true
    bSubLog=false
}
