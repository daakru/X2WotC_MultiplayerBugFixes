/*                                                                             
 * FILE:     XComGameState_SingletonTracker_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01-ST v1.0
 *
 * Singleton GameState for use in the Tactical Layer.
 * Mods using this are safe to remove in the Strategy Layer.
 *
 * Dependencies: None
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class XComGameState_SingletonTracker_KMP01 extends XComGameState_BaseObject;

var bool bEventHasRunBefore;

//---------------------------------------------------------------------------//

static final function InitializeTracker(XComGameState TacticalStartState)
{
	local XComGameState_SingletonTracker_KMP01 STracker;
	
	//STracker = GetSingleTracker();
	
    foreach TacticalStartState.IterateByClassType(
        class'XComGameState_SingletonTracker_KMP01', STracker)
    {
        break;
    }

	if (STracker != none)  // Prevent duplicate Trackers
	{
		`Log("Redscreen: InitializeTracker: Tracker Already Exists!", ,
			'XComGameState_SingletonTracker_KMP01');
		`REDSCREEN("InitializeTracker: Tracker Already Exists!");
		return;
	}
	// Add the tracker class
	STracker = XComGameState_SingletonTracker_KMP01(TacticalStartState
		.CreateNewStateObject(class'XComGameState_SingletonTracker_KMP01'));
}

//---------------------------------------------------------------------------//

/// <summary>
/// Called to set bEventHasRunBefore to true after running the event
/// </summary>
static final function EventHasRun(optional XComGameState NewGameState)
{
	local XComGameState_SingletonTracker_KMP01 Tracker;
	local bool bNoGameState;

	`Log("EventHasRun:", , 'KMP01_MPBugFixes_dev');

	Tracker = GetSingleTracker();
	if (Tracker == none)
	{
		`Log("Redscreen: EventHasRun: Tracker == none", ,
			'XComGameState_SingletonTracker_KMP01');
		`REDSCREEN("EventHasRun: Tracker == none");
		return;
	}

	if (Tracker.bEventHasRunBefore)
	{
		`Log("Redscreen: EventHasRun: Called with bEventHasRunBefore = true", ,
			'XComGameState_SingletonTracker_KMP01');
		`REDSCREEN("EventHasRun: Called with bEventHasRunBefore = true");
		return;
	}

	bNoGameState = (NewGameState == none);

	if (bNoGameState)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static
			.CreateChangeState("KMP01_MPBugFixes_dev: Reset bEventHasRunBefore");
	}

	Tracker = XComGameState_SingletonTracker_KMP01(NewGameState
		.ModifyStateObject(class'XComGameState_SingletonTracker_KMP01',
		Tracker.ObjectID));

	Tracker.bEventHasRunBefore = false;

	if (bNoGameState)
	{
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	}
}

//---------------------------------------------------------------------------//

static final function XComGameState_SingletonTracker_KMP01 GetSingleTracker()
{
	return XComGameState_SingletonTracker_KMP01(
		`XCOMHISTORY.GetSingleGameStateObjectForClass(
		class'XComGameState_SingletonTracker_KMP01', true));
}

//---------------------------------------------------------------------------//

static final function bool ShouldEventRun()
{
	local XComGameState_SingletonTracker_KMP01 STracker;

	STracker = GetSingleTracker();
	if (STracker != none)
	{
		return (STracker.bEventHasRunBefore == false);
	}
	// If the tracker doesn't exist, don't run the event
	return false;
}

//---------------------------------------------------------------------------//

defaultproperties
{
	bTacticalTransient=true
}
