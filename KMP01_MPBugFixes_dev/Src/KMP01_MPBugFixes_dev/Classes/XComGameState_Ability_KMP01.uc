/*                                                                             
 * FILE:     XComGameState_Ability_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01 v0.1
 *
 * MCO of XComGameState_Ability.uc to debug Deep Cover.
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class XComGameState_Ability_KMP01 extends XComGameState_Ability;

var bool bDeepLog;

//---------------------------------------------------------------------------//

// Override the Event Listener to add a buttload of logs to try and figure out
// if this is part of the problem
function EventListenerReturn DeepCoverTurnEndListener(Object EventData,
                                                      Object EventSource,
                                                      XComGameState GameState,
                                                      Name EventID,
                                                      Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local UnitValue AttacksThisTurn;
	local bool GotValue;
	local StateObjectReference HunkerDownRef;
	local XComGameState_Ability HunkerDownState;
	local XComGameStateHistory History;
	local XComGameState NewGameState;

    local XComGameState_Player DebugPlayer;

    kLog("Enter DeepCover Event Listener Function", true, bDeepLog);

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(GameState
        .GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if (UnitState == none)
    {
        kLog("UnitState not found", true, bDeepLog);
		UnitState = XComGameState_Unit(History
            .GetGameStateForObjectID(OwnerStateObject.ObjectID));
    }
    else
    {
        DebugPlayer = XComGameState_Player(History.GetGameStateForObjectID(
            UnitState.ControllingPlayer.ObjectID));
        kLog("UnitState located from GameState: Unit Template Name:"
            @ UnitState.GetMyTemplateName()
            @ "  Unit's Controlling Player Team:"
            @ DebugPlayer.TeamFlag,
            true, bDeepLog);
    }
	if (UnitState == none)
    {
        kLog("Exiting: UnitState still not found", true, bDeepLog);
        return ELR_NoInterrupt;
    }
    else
    {
        DebugPlayer = XComGameState_Player(History.GetGameStateForObjectID(
            UnitState.ControllingPlayer.ObjectID));
        kLog("UnitState located from History: Unit Template Name:"
            @ UnitState.GetMyTemplateName()
            @ "  Unit's Controlling Player Team:"
            @ DebugPlayer.TeamFlag,
            true, bDeepLog);
    }
    if (!UnitState.IsHunkeredDown())
	{
        kLog("Unit is not Hunkered",
            true, bDeepLog);
		GotValue = UnitState.GetUnitValue('AttacksThisTurn', AttacksThisTurn);
        if (GotValue && AttacksThisTurn.fValue != 0)
        {
            kLog("AttacksThisTurn:" @ AttacksThisTurn.fValue,
                true, bDeepLog);
            return ELR_NoInterrupt;
        }
		if (!GotValue || AttacksThisTurn.fValue == 0)
		{
            kLog("AttacksThisTurn:"
                @ ((GotValue == false) ? "N/A" 
                : string(AttacksThisTurn.fValue)),
                true, bDeepLog);
			HunkerDownRef = UnitState.FindAbility('HunkerDown');
            kLog("HunkerDownRef Object ID:" @ HunkerDownRef.ObjectID,
                true, bDeepLog);
			HunkerDownState = XComGameState_Ability(History
                .GetGameStateForObjectID(HunkerDownRef.ObjectID));
            //kLog("HunkerDownState", true, bDeepLog);
			if (HunkerDownState != none)
            {
                kLog("HunkerDownState CanActivateAbility:" @ HunkerDownState
                    .CanActivateAbility(UnitState,,true),
                    true, bDeepLog);
                if (HunkerDownState.CanActivateAbility(UnitState,,true)
                    == 'AA_Success')
			    {
                    kLog("Unit Action Points:"
                            @ UnitState.NumActionPoints()
                        $ "\n    Unit All Action Points:"
                            @ UnitState.NumAllActionPoints()
                        $ "\n    Unit Has DeepCoverActionPoint:"
                            @ UnitState.ActionPoints.Find('deepcover')
                            != INDEX_NONE,
                        true, bDeepLog);
				    if (UnitState.NumActionPoints() == 0)
				    {
                        kLog("Prepare NewGameState to add"
                            @ "DeepCoverActionPoint",
                            true, bDeepLog);
					    NewGameState = 
                            class'XComGameStateContext_ChangeContainer'
                            .static.CreateChangeState(
                            string(GetFuncName()));
					    UnitState = XComGameState_Unit(NewGameState
                            .ModifyStateObject(UnitState.Class,
                            UnitState.ObjectID));
                        kLog("UnitState added to NewGameState",
                            true, bDeepLog);
					    //  give the unit an action point
                        //  so they can activate hunker down										
					    UnitState.ActionPoints.AddItem(
                            class'X2CharacterTemplateManager'.default
                            .DeepCoverActionPoint);	
                        kLog("Unit given one DeepCoverActionPoint."
                            $ "\n    Unit Action Points:"
                                @ UnitState.NumActionPoints()
                            $ "\n    Unit All Action Points:"
                                @ UnitState.NumAllActionPoints()
                            $ "\n    Unit Has DeepCoverActionPoint:"
                                @ UnitState.ActionPoints.Find('deepcover')
                                != INDEX_NONE,
                            true, bDeepLog);				
					    `TACTICALRULES.SubmitGameState(NewGameState);
                        kLog("Submit the NewGameState to TacRules",
                            true, bDeepLog);
				    }
                    kLog("Return HunkerDownState"
                        $ ".AbilityTriggerEventListener_Self",
                        true, bDeepLog);
				    return HunkerDownState.AbilityTriggerEventListener_Self(
                        EventData, EventSource, GameState,
                        EventID, CallbackData);
			    }
            }
            else
            {
                kLog("HunkerDownState not found",
                    true, bDeepLog);
            }
		}
	}
    else
    {
        kLog("Unit is already Hunkered",
            true, bDeepLog);
    }
    kLog("Return ELR_NoIntercept",
        true, bDeepLog);

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
    bDeepLog=true
}
