/*                                                                             
 * FILE:     X2Effect_Persistent_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * MCO of X2Effect_Persistent.uc to debug effect removal conditions.
 *
 * Dependencies: X2Helpers_Logger_KMP01
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class X2Effect_Persistent_KMP01 extends X2Effect_Persistent;

var bool bDeepLog;
var bool bPathing;

//---------------------------------------------------------------------------//

// Occurs once per turn during the Unit Effects phase
// Returns true if the associated XComGameSate_Effect should NOT be removed
simulated function bool OnEffectTicked(
    const out EffectAppliedData ApplyEffectParameters,
    XComGameState_Effect kNewEffectState,
    XComGameState NewGameState,
    bool FirstApplication,
    XComGameState_Player Player)
{
	local X2Effect TickEffect;
	local XComGameState_BaseObject OldTargetState, NewTargetState;
	local XComGameStateContext_TickEffect TickContext;
	local EffectAppliedData TickData;
	local bool TickCompletesEffect;
	local XComGameState_Unit EffectTargetUnit;
	local X2EventManager EventManager;
	local XComGameStateHistory History;
	local bool bIsFullTurnComplete;

    local int idxLog;
    local string LogMsg;
    local string LogPathing;

    LogPathing = string(GetFuncName()) $ "()";

	bIsFullTurnComplete = FullTurnComplete(kNewEffectState, Player);
	OldTargetState = `XCOMHISTORY.GetGameStateForObjectID(
        ApplyEffectParameters.TargetStateObjectRef.ObjectID);

    LogMsg = ("OnEffectTicked: Initial Conditions:"
        $ "\n    Team:                  " @ Player.TeamFlag
        $ "\n    Effect:                " @ kNewEffectState.GetX2Effect().EffectName
        $ "\n    bIsFullTurnComplete:   " @ bIsFullTurnComplete
        $ "\n    FirstApplication:      " @ FirstApplication
        $ "\n    bTickWhenApplied:      " @ bTickWhenApplied
        $ "\n    IsTickEveryAction:     " @ IsTickEveryAction(OldTargetState)
        $ "\n    ApplyOnTick.Length:    " @ ApplyOnTick.Length
        $ "\n    bInfiniteDuration:     " @ bInfiniteDuration
        $ "\n    iTurnsRemaining:       " @ kNewEffectState.iTurnsRemaining
        $ "\n    iShedChance:           " @ kNewEffectState.iShedChance
        $ "\n    iPerTurnShedChance:    " @ iPerTurnShedChance
        $ "\n    ChanceEventTriggerName:" @ ChanceEventTriggerName
        $ "\n    EffectTickedFn:        " @ string(EffectTickedFn)
        $ "\n    FullTurnsTicked:       " @ kNewEffectState.FullTurnsTicked
        $ "\n                Runtime Updates:"
    );

	if(bIsFullTurnComplete  /// IB_1.1
		|| (FirstApplication && bTickWhenApplied) 
		|| (IsTickEveryAction(OldTargetState)))
	{
        LogPathing $= " ->" $ "IB_1.1t";  /// IB_1.1t
        
		TickContext = XComGameStateContext_TickEffect(
            NewGameState.GetContext());

		if (ApplyOnTick.Length > 0)  /// IB_1t.2
		{
            LogPathing $= " ->" $ "IB_1t.2t";  /// IB_1t.2t
            
			NewTargetState = NewGameState.ModifyStateObject(
                OldTargetState.Class, OldTargetState.ObjectID);
			
            LogMsg $= "\n        " $ "Pre-Clear arrTickSuccess:"
                $ kIterString('name', , TickContext.arrTickSuccess);

			TickContext.arrTickSuccess.Length = 0;
			TickData = ApplyEffectParameters;
			TickData.EffectRef.ApplyOnTickIndex = 0;

			foreach ApplyOnTick(TickEffect, idxLog)  /// IB_1t.2t.FE_1
			{
                LogPathing $= " ->" $ "IB_1t.2t.FE_1[" $ idxLog $ "]";

				TickContext.arrTickSuccess.AddItem(TickEffect
                    .ApplyEffect(TickData, NewTargetState, NewGameState));
				TickData.EffectRef.ApplyOnTickIndex++;
                
                LogMsg $= "\n        ApplyOnTick[" $ idxLog $ "]: TickSuccess:"
                    @ TickContext.arrTickSuccess[idxLog];
			}
            LogPathing $= " ->" $ "IB_1t.2t.FE_1b";  /// IB_1t.2t.FE_1b
		}
        LogPathing $= " ->" $ "IB_1t.2b";  /// IB_1t.2b

        
		if (!bInfiniteDuration)  /// IB_1t.3
		{
            LogPathing $= " ->" $ "IB_1t.3t";  /// IB_1t.3t
            
			kNewEffectState.iTurnsRemaining -= 1;
            //If this goes negative, something has gone wrong with the handling
			`assert(kNewEffectState.iTurnsRemaining > -1);
		}
        LogPathing $= " ->" $ "IB_1t.3b";  /// IB_1t.3b

		kNewEffectState.iShedChance += iPerTurnShedChance;

        LogMsg $= "\n        Update iShedChance" @ kNewEffectState.iShedChance;

		if (kNewEffectState.iShedChance > 0)  /// IB_1t.4
		{
            LogPathing $= " ->" $ "IB_1t.4t";  /// IB_1t.4t
            
			if (`SYNC_RAND(100) <= kNewEffectState.iShedChance)  /// IB_1t.4t.5
			{
                LogPathing $= " ->" $ "IB_1t.4t.5t";  /// IB_1t.4t.5t
                
				kNewEffectState.iTurnsRemaining = 0;

				// If there is an event that should be triggered
                // due to this chance, fire it
				if( ChanceEventTriggerName != '' )  /// IB_1t.4t.5t.6
				{
                    LogPathing $= " ->" $ "IB_1t.4t.5t.6t";  /// IB_1t.4t.5t.6t
                    
					History = `XCOMHISTORY;
					EventManager = `XEVENTMGR;

					EffectTargetUnit = XComGameState_Unit(History
                        .GetGameStateForObjectID(ApplyEffectParameters
                        .TargetStateObjectRef.ObjectID));

                    LogMsg $= "\n        Update EffectTargetUnit:"
                        @ EffectTargetUnit.GetMyTemplateName();

					EventManager.TriggerEvent(ChanceEventTriggerName,
                        EffectTargetUnit, EffectTargetUnit);
				}
                LogPathing $= " ->" $ "IB_1t.4t.5t.6b";  /// IB_1t.4t.5t.6b
			}
            LogPathing $= " ->" $ "IB_1t.4t.5b";  /// IB_1t.4t.5b
		}
        LogPathing $= " ->" $ "IB_1t.4b";  /// IB_1t.4b

		if (EffectTickedFn != none)  /// IB_1t.7
		{
            LogPathing $= " ->" $ "IB_1t.7t";  /// IB_1t.7t
            
			TickCompletesEffect = EffectTickedFn(self, ApplyEffectParameters,
                kNewEffectState, NewGameState, FirstApplication);

            LogMsg $= "\n        Update TickCompletesEffect:"
                @ TickCompletesEffect;
		}
        LogPathing $= " ->" $ "IB_1t.7b";  /// IB_1t.7b

		if( bIsFullTurnComplete )  /// IB_1t.8
		{
            LogPathing $= " ->" $ "IB_1t.8t";  /// IB_1t.8t
            
			++kNewEffectState.FullTurnsTicked;

            LogMsg $= "\n        Update FullTurnsTicked:"
                @ kNewEffectState.FullTurnsTicked;
		}
        LogPathing $= " ->" $ "IB_1t.8b";  /// IB_1t.8b
	}
    LogPathing $= " ->" $ "IB_1b";  /// IB_1b

    LogPathing $= " ->" $ "RETURN:" @ ((bInfiniteDuration
        || kNewEffectState.iTurnsRemaining > 0) && !TickCompletesEffect);

    kLog(LogMsg $ (bPathing ? ("\n\n    PATHING:" @ LogPathing) : ""),
        true, bDeepLog);

	return (bInfiniteDuration || kNewEffectState.iTurnsRemaining > 0)
        && !TickCompletesEffect;
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

// NIFSO
private static function string kIterString(name aType, string delim=", ",
                                           optional array<name> nArr,
                                           optional array<int> iArr,
                                           optional array<float> fArr,
                                           optional array<string> sArr,
                                           optional array<Object> oArr)
{
    local string outstr;
    local int idx;
    local name n;
    local int i;
    local float f;
    local string s;
    local Object o;

    outstr = "";

    switch (Caps(aType))
    {
        case "NAME":
            foreach nArr(n, idx)
            {
                outstr $= ( (idx != 0) ? delim : "" ) $ n;
            }
            break;
        case "INT":
            foreach iArr(i, idx)
            {
                outstr $= ( (idx != 0) ? delim : "" ) $ i;
            }
            break;
        case "FLOAT":
            foreach fArr(f, idx)
            {
                outstr $= ( (idx != 0) ? delim : "" ) $ f;
            }
            break;
        case "STRING":
            foreach sArr(s, idx)
            {
                outstr $= ( (idx != 0) ? delim : "" ) $ s;
            }
            break;
        case "OBJECT":
            foreach oArr(o, idx)
            {
                outstr $= ( (idx != 0) ? delim : "" ) $ o.Name;
            }
            break;
        default:
            `REDSCREEN("ERROR: kIterString Unsupported Type:" @ aType);
            `Log("Warning: Redscreen: ERROR: kIterString Unsupported Type:" @ aType, , 'KMP01');
    }

    return outstr;
}

defaultproperties
{
    bDeepLog=true
    bPathing=true
}
