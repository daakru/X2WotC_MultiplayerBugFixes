/*                                                                             
 * FILE:     XComGameState_Unit_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * MCO of XComGameState_Unit.uc to debug camera pan to enemy concealed units.
 *
 * Dependencies: X2Helpers_Logger_KMP01
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class XComGameState_Unit_KMP01 extends XComGameState_Unit;

var bool bDeepLog;

//---------------------------------------------------------------------------//

function EnterConcealmentNewGameState(XComGameState NewGameState)
{
    local XComGameState_Unit NewUnitState;
    local X2TacticalGameRuleset TacticalRules;
    local X2TacticalMPGameRuleset MPRules;

    TacticalRules = `TACTICALRULES;

    if (!TacticalRules.IsA('X2TacticalMPGameRuleset'))
    {
        kLog("Not an MPGame, calling super", true, default.bDeepLog);
        super.EnterConcealmentNewGameState(NewGameState);
        return;
    }

    MPRules = X2TacticalMPGameRuleset(TacticalRules);
    
    if (ControllingPlayer.ObjectID == MPRules.GetLocalClientPlayerObjectID())
    {
        kLog("Unit \"" $ GetMPName(eNameType_FullNick)
            $ "\" is owned by the Local Player", true, default.bDeepLog);
        // we only need to visualize this once
        if(NewGameState.GetContext().PostBuildVisualizationFn.Find(
            BuildVisualizationForConcealment_Entered_Individual) == INDEX_NONE)
        {
            NewGameState.GetContext().PostBuildVisualizationFn
                .AddItem(BuildVisualizationForConcealment_Entered_Individual);
        }
    }
    else
    {
        kLog("Unit \"" $ GetMPName(eNameType_FullNick)
            $ "\" is not owned by the Local Player",
            true, default.bDeepLog);
    }

    NewUnitState = XComGameState_Unit(NewGameState
        .ModifyStateObject(class'XComGameState_Unit', ObjectID));
    NewUnitState.SetIndividualConcealment(true, NewGameState);
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
