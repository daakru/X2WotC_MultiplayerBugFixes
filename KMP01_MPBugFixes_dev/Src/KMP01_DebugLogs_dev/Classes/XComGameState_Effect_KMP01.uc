/*                                                                             
 * FILE:     XComGameState_Effect_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * MCO of XComGameState_Effect.uc to debug effect removal conditions.
 *
 * Dependencies: X2Helpers_Logger_KMP01
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class XComGameState_Effect_KMP01 extends XComGameState_Effect;

var bool bDeepLog;

//---------------------------------------------------------------------------//

function EventListenerReturn OnPlayerTurnTicked(Object EventData,
                                                Object EventSource,
                                                XComGameState GameState,
                                                Name Event,
                                                Object CallbackData)
{
    kLog("OnPlayerTurnTicked:"
        $ "\n    Team:    " @ XComGameState_Player(EventData).TeamFlag
        $ "\n    Effect:  " @ GetX2Effect().EffectName
        $ "\n    bRemoved:" @ bRemoved
        $ "\n    bIgnoreP:" @ GetX2Effect().bIgnorePlayerCheckOnTick,
        true, bDeepLog);

	// only applicable at the end of the instigating player's turn,
    // unless bIgnorePlayerCheckOnTick is true
	if( GetX2Effect().FullTurnComplete(self, XComGameState_Player(EventData)) )
	{
        kLog("OnPlayerTurnTicked: Full Turn Complete:"
            $ "\n    Team:  " @ XComGameState_Player(EventData).TeamFlag
            $ "\n    Effect:" @ GetX2Effect().EffectName,
            true, bDeepLog);
		InternalTickEffect(GameState, XComGameState_Player(EventData));
	}
    else  // KMP01: Add else here to log the alternative
    {
        kLog("OnPlayerTurnTicked: Turn Not Complete:"
            $ "\n    Team:  " @ XComGameState_Player(EventData).TeamFlag
            $ "\n    Effect:" @ GetX2Effect().EffectName,
            true, bDeepLog);
    }

	return ELR_NoInterrupt;
}

//---------------------------------------------------------------------------//

function EventListenerReturn OnGroupTurnTicked(Object EventData,
                                               Object EventSource,
                                               XComGameState GameState,
                                               Name Event,
                                               Object CallbackData)
{
	local XComGameState_Player ActivePlayer;

	ActivePlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(
        `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID));

    kLog("OnGroupTurnTicked:"
        $ "\n    Team:    " @ ActivePlayer.TeamFlag
        $ "\n    Effect:  " @ GetX2Effect().EffectName
        $ "\n    bRemoved:" @ bRemoved
        $ "\n    bIgnoreP:" @ GetX2Effect().bIgnorePlayerCheckOnTick,
        true, bDeepLog);

	// only applicable at the end of the instigating player's turn,
    // unless bIgnorePlayerCheckOnTick is true
	if( GetX2Effect().FullTurnComplete(self, ActivePlayer) )
	{
        kLog("OnGroupTurnTicked: Full Turn Complete:"
            $ "\n    Team:  " @ ActivePlayer.TeamFlag
            $ "\n    Effect:" @ GetX2Effect().EffectName,
            true, bDeepLog);
		InternalTickEffect(GameState, ActivePlayer);
	}
    else  // KMP01: Add else here to log the alternative
    {
        kLog("OnGroupTurnTicked: Turn Not Complete:"
            $ "\n    Team:  " @ ActivePlayer.TeamFlag
            $ "\n    Effect:" @ GetX2Effect().EffectName,
            true, bDeepLog);
    }

	return ELR_NoInterrupt;
}

//---------------------------------------------------------------------------//

protected function InternalTickEffect(XComGameState CallbackGameState,
                                      XComGameState_Player Player)
{
	local XComGameStateContext_TickEffect TickContext;
	local XComGameState NewGameState;
	local X2TacticalGameRuleset TacticalRules;

    kLog("InternalTickEffect:"
        $ "\n    Team:    " @ Player.TeamFlag
        $ "\n    Effect:  " @ GetX2Effect().EffectName
        $ "\n    bRemoved:" @ bRemoved,
        true, bDeepLog);

	TacticalRules = `TACTICALRULES;

	// only act if this Effect is not already removed, and if the tactical game
	// has not ended (so poison/etc can't kill units after game end).
	if( !bRemoved && !TacticalRules.HasTacticalGameEnded() )
	{
		TickContext = class'XComGameStateContext_TickEffect'.static
            .CreateTickContext(self);
		TickContext.SetVisualizationFence(true);
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, TickContext);
		if( !TickEffect(NewGameState, false, Player) )
		{
            kLog("InternalTickEffect:"
                $ "\n    Removing Effect:" @ GetX2Effect().EffectName,
                true, bDeepLog);
			RemoveEffect(NewGameState, CallbackGameState);
		}
        else  // KMP01: Add else here to log the alternative
        {
            kLog("InternalTickEffect:"
                $ "\n    Not Removing Effect:" @ GetX2Effect().EffectName,
                true, bDeepLog);
        }

		if( NewGameState.GetNumGameStateObjects() > 0 )
		{
            kLog("InternalTickEffect:"
                $ "\n    Submit Game State",
                true, bDeepLog);
			TacticalRules.SubmitGameState(NewGameState);
		}
		else
		{
            kLog("InternalTickEffect:"
                $ "\n    Cleanup Game State",
                true, bDeepLog);
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}
	}
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
