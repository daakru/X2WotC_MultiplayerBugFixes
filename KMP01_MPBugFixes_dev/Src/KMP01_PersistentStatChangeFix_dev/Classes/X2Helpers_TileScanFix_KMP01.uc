
class X2Helpers_TileScanFix_KMP01 extends Object abstract;

static function ToggleHiddenUnitTileBlocked(XComGameState_Unit Unit, bool bShouldBlock)
{
    if (bShouldBlock)
    {
        `XWORLD.SetTileBlockedByUnitFlag(Unit);
        return;
    }
    `XWORLD.ClearTileBlockedByUnitFlag(Unit);
}

static function ToggleAllHiddenUnitTileBlocked(XComGameState NewGameState, bool bShouldBlock)
{
    local XComGameState_Unit UnitState;
    local XComGameStateHistory History;
    local X2TacticalGameRuleset Rules;
    local XComGameState_Player LocalPlayer;
    local XGUnit Unit;

    History = `XCOMHISTORY;
    Rules = `TACTICALRULES;

    LocalPlayer = XComGameState_Player(History.GetGameStateForObjectID(`TACTICALRULES.GetLocalClientPlayerObjectID()));

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
        
        Unit = XGUnit(UnitState.GetVisualizer());

        // Skip if we own this unit or already have visibility on it
        if (UnitState.ControllingPlayer.ObjectID == LocalPlayer.ObjectID)
        //    || Unit.IsVisibleToTeam(LocalPlayer.TeamFlag))
        {
            continue;
        }
        
        UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

        ToggleHiddenUnitTileBlocked(UnitState, bShouldBlock);
    }
}

static function MakeGameStateAndCallFunction(GameRuleStateChange eRuleState)
{
    local XComGameState NewGameState;
    local bool bShouldBlock;

    NewGameState = class'XComGameStateContext_ChangeContainer'.static
        .CreateChangeState("MakeGameStateAndCallFunction");
    
    switch (eRuleState)
    {
        case eGameRule_PlayerTurnBegin:
            bShouldBlock = false;
            break;
        case eGameRule_PlayerTurnEnd:
            bShouldBlock = true;
            break;
        case eGameRule_UnitGroupTurnBegin:
            //break;
        case eGameRule_UnitGroupTurnEnd:
            //break;
        default:
            //REDSCREEN
            //kLog("Cleaning up Pending Game State",
            //    true, default.bDeepLog);
            `XCOMHISTORY.CleanupPendingGameState(NewGameState);
            return;
    }

    ToggleAllHiddenUnitTileBlocked(NewGameState, bShouldBlock);

    if (NewGameState.GetNumGameStateObjects() > 0)
    {
        //kLog("Adding NewGameState with" @ NewGameState.GetNumGameStateObjects()
        //    @ "modified State Objects to TacRules",
        //    true, default.bDeepLog);
        `TACTICALRULES.SubmitGameState(NewGameState);
    }
    else
    {
        //kLog("Cleaning up Pending Game State",
        //    true, default.bDeepLog);
        `XCOMHISTORY.CleanupPendingGameState(NewGameState);
    }
}