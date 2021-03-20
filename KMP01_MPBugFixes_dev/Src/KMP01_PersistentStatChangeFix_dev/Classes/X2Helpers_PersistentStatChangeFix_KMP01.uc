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

enum EEffectClass_Type
{
    eEffectClass_None,
    eEffectClass_Effect,
    eEffectClass_Persistent,
    eEffectClass_StatChange,
    eEffectClass_Other
};

//---------------------------------------------------------------------------//

private static function array<name> Generate_WatchEffects()
{
    local array<name> EffectList;

    EffectList.AddItem('SteadyHandsStatBoost');
    EffectList.AddItem('FrenzyEffect');
    EffectList.AddItem('HunkerDown');
    //EffectList.AddItem('');

    return EffectList;
}

//---------------------------------------------------------------------------//

private static function array<name> Generate_PTB_ForceRemoveEffects()
{
    local array<name> EffectList;

    //EffectList.AddItem('');

    return EffectList;
}

//---------------------------------------------------------------------------//

private static function array<name> Generate_PTE_ForceRemoveEffects()
{
    local array<name> EffectList;

    //EffectList.AddItem('');

    return EffectList;
}

//---------------------------------------------------------------------------//

private static function array<name> Generate_UGB_ForceRemoveEffects()
{
    local array<name> EffectList;

    EffectList.AddItem('HunkerDown');
    //EffectList.AddItem('');

    return EffectList;
}

//---------------------------------------------------------------------------//

private static function array<name> Generate_UGE_ForceRemoveEffects()
{
    local array<name> EffectList;

    EffectList.AddItem('SteadyHandsStatBoost');
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

static private function EEffectClass_Type LogEffectInfo(
    name EffectName, const out XComGameState_Effect EffectState)
{
    local X2Effect_PersistentStatChange StatChangeEffect;
    local X2Effect_Persistent Effect;
    local EEffectClass_Type eType;

    if (EffectState == none)
    {
        return eEffectClass_None;
    }

    Effect = EffectState.GetX2Effect();
    if (Effect == none)
    {
        return eEffectClass_Effect;
    }

    eType = eEffectClass_Persistent;
    
    if (Effect.IsA('X2Effect_PersistentStatChange'))
    {
        StatChangeEffect = X2Effect_PersistentStatChange(Effect);
        eType = eEffectClass_StatChange;
    }

    // Log EffectState Info
    kLog("Logging EffectState of '" $ EffectName $ "':"
        $ "\n    iTurnsRemaining:                   " @ EffectState.iTurnsRemaining
        $ "\n    FullTurnsTicked:                   " @ EffectState.FullTurnsTicked
        $ "\n    StatChanges.Length:                " @ EffectState.StatChanges.Length
        $ "\n    ObjectID:                          " @ EffectState.ObjectID,
        true, default.bSubLog);

    // Log Persistent Effect Template Info
    kLog("Logging Template of '" $ EffectName $ "':"
        $ "\n    iNumTurns:                         " @ Effect.iNumTurns
        $ "\n    bInfiniteDuration:                 " @ Effect.bInfiniteDuration
        $ "\n    bIgnorePlayerCheckOnTick:          " @ Effect.bIgnorePlayerCheckOnTick
        $ "\n    DuplicateResponse:                 " @ Effect.DuplicateResponse
        $ "\n    ApplyOnTick.Length:                " @ Effect.ApplyOnTick.Length
        $ "\n    WatchRule:                         " @ Effect.WatchRule
        $ "\n    FriendlyName:                      " @ Effect.FriendlyName
        $ "\n    FriendlyDescription:               " @ Effect.FriendlyDescription,
        true, default.bSubLog);

    if (eType == eEffectClass_StatChange)
    {
        // Log properties specific to PersistentStatChange Templates
    }

    return eType;
}

//---------------------------------------------------------------------------//

static final function bool ModifyUnitState(XComGameState NewGameState,
                                           XComGameState_Unit UnitState,
                                           optional name TriggeredEventID)
{
    local array<name> WatchEffects;
    //local array<name> PTB_ForceRemoveEffects;
    //local array<name> PTE_ForceRemoveEffects;
    //local array<name> UGB_ForceRemoveEffects;
    //local array<name> UGE_ForceRemoveEffects;
    local XComGameState_Effect EffectState;
    local EEffectClass_Type eType;
    local name EffectName;
    local bool bModified;

    local X2Effect_PersistentStatChange PStatEffect;
    local X2Effect_Persistent PEffect;

    kLog("ModifyUnitState:", true, default.bPathLog);

    WatchEffects = Generate_WatchEffects();

    //PTB_ForceRemoveEffects = Generate_PTB_ForceRemoveEffects();
    //PTE_ForceRemoveEffects = Generate_PTE_ForceRemoveEffects();
    //UGB_ForceRemoveEffects = Generate_UGB_ForceRemoveEffects();
    //UGE_ForceRemoveEffects = Generate_UGE_ForceRemoveEffects();

    foreach UnitState.AffectedByEffectNames(EffectName)
    {
        if (WatchEffects.Find(EffectName) == INDEX_NONE)
        {
            //kLog("Not interested in effect with name: '" $ EffectName $ "'",
            //    true, default.bSubLog);
            continue;
        }

        EffectState = UnitState.GetUnitAffectedByEffectState(EffectName);

        eType = LogEffectInfo(EffectName, EffectState);

        if (eType != eEffectClass_Persistent && eType != eEffectClass_StatChange)
        {
            continue;
        }

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
