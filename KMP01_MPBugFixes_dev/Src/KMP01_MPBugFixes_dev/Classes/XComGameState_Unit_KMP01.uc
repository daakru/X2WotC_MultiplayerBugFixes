/*                                                                             
 * FILE:     XComGameState_Unit_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * MCO of XComGameState_Unit.uc to debug camera pan to enemy concealed units.
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
    //local XComGameStateHistory History;
    //local XComGameState_Player LocalPlayer;

    TacticalRules = `TACTICALRULES;
    //History = `XCOMHISTORY;

    if (!class'X2ModConfig_KMP01'.default.Unstable
        || !TacticalRules.IsA('X2TacticalMPGameRuleset'))
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
            /*
            LocalPlayer = XComGameState_Player(History.GetGameStateForObjectID(
                MPRules.GetLocalClientPlayerObjectID()));

            // Only Visualize if Local Player's Turn is first
            // and they haven't taken any turns yet
            if (!MPRules.IsTurnRemote(0) && LocalPlayer.PlayerTurnCount < 1)
            {
                kLog("Local Player's turn is first,"
                    @ "Visualizing Concealment!", true, default.bDeepLog);
                NewGameState.GetContext().PostBuildVisualizationFn.AddItem(
                    BuildVisualizationForConcealment_Entered_Individual);
            }
            */
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
