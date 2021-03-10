/*                                                                             
 * FILE:     UIScreenListener_TacticalHUD_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * UISL for the UITacticalHUD to add buttons to commander abilities bar.
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class UIScreenListener_TacticalHUD_KMP01 extends UIScreenListener;

//---------------------------------------------------------------------------//

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{
	local UITacticalHUD HUDScreen;

	`log("Starting TacticalHUD Listener OnInit");

	if(Screen == none)
	{
		`RedScreen("UITacticalHUD ScreenListener: Screen == none");
		return;
	}
	HUDScreen = UITacticalHUD(Screen);
	if(HUDScreen == none)
	{
		`RedScreen("UITacticalHUD ScreenListener: HUDScreen == none");
		return;
	}
	UpdateMouseControls(HUDScreen);
}

//---------------------------------------------------------------------------//

// This event is triggered after a screen receives focus
//event OnReceiveFocus(UIScreen Screen);

// This event is triggered after a screen loses focus
//event OnLoseFocus(UIScreen Screen);

// This event is triggered when a screen is removed
//event OnRemoved(UIScreen Screen);

//---------------------------------------------------------------------------//

simulated function UpdateMouseControls(UITacticalHUD HUDScreen)
{
	if ((HUDScreen.m_kMouseControls != none)
        && (HUDScreen.Movie.IsMouseActive()))
	{
		HUDScreen.m_kMouseControls.Remove();
		HUDScreen.m_kMouseControls = HUDScreen.Spawn(
            class'UITacticalHUD_MouseControls_KMP01', HUDScreen);
		HUDScreen.m_kMouseControls.InitMouseControls();
	}
}

//---------------------------------------------------------------------------//

defaultproperties
{
	ScreenClass=UITacticalHUD
}
