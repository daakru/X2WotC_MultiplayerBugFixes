/*                                                                             
 * FILE:     UIMPShell_SquadCostPanel_RemotePlayer_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * MCO of UIMPShell_SquadCostPanel.uc to hide Squad Loadout Name from opponent.
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class UIMPShell_SquadCostPanel_RemotePlayer_KMP01
    extends UIMPShell_SquadCostPanel_RemotePlayer;

var localized string HIDDEN_LOADOUT_NAME;

//---------------------------------------------------------------------------//

function RefreshDisplay()
{
	local XComGameState_Player RemotePlayerState;
	RemotePlayerState = GetPlayerGameState();

	if(NetworkMgr.Connections.Length > 0 && RemotePlayerState != none)
	{
		`log(`location @ `ShowVar(RemotePlayerState.PlayerName)
            @ `ShowVar(RemotePlayerState.bPlayerReady)
            @ `ShowVar(RemotePlayerState.SquadPointValue)
            @ `ShowVar(RemotePlayerState.SquadName), , 'XCom_Online');
	
		SetPlayerName(RemotePlayerState.PlayerName);
		m_bMicAvailable = RemotePlayerState.MicAvailable;
		
		SetPlayerLoadout(m_kLoadoutGameState);
		m_iSquadCost = RemotePlayerState.SquadPointValue;
		if(RemotePlayerState.SquadName != "")
			m_strLoadoutName = default.HIDDEN_LOADOUT_NAME;
		if(RemotePlayerState.bPlayerReady)
		{
			StatusText.SetText(m_strMPLoadout_RemotePlayerInfo_Ready);
			
			MC.BeginFunctionOp("setReady");
			MC.QueueBoolean(true);
			MC.QueueString(m_strMPLoadout_RemotePlayerInfo_Ready);
			MC.EndOp();
		}
		else
		{
			StatusText.SetText(m_strMPLoadout_RemotePlayerInfo_NotReady);
			
			MC.BeginFunctionOp("setReady");
			MC.QueueBoolean(false);
			MC.QueueString(m_strLoadoutName);
			MC.EndOp();
		}

		Show();
	}
	else
	{
		Hide();
	}

	UpdateSquadCostText();
}
