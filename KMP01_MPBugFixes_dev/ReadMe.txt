[WotC] MP Bug-Spray (WIP)
Mod Author: Kinetos#6935
Version: 1.3.2

Developmental gameplay fixes for XCOM 2 WotC Multiplayer.
Code is available on GitHub here: https://github.com/daakru/X2WotC_MultiplayerBugFixes.

Current Mod Class Overrides (MCOs):
    XComGameState_Ability
    UITacticalHUD_MouseControls
    UIMPShell_SquadCostPanel_RemotePlayer
    XComGameState_Effect
    X2Effect_Persistent

Any direct gameplay changes will be documented here on addition or removal:
    Hides Squad Loadout Names from your opponent in the lobby UI.
    Prevents Steady Hands from stacking indefinitely.
    Removes Hunkered Down from Deep Cover at the start of the opponent's turn if you attack.

Developmental Features (Set Unstable=false in XComGame.ini):
    Attempt to forcibly remove Steady Hands on Unit Group's turn ending.
    Attempt to forcibly remove Hunker Down on Unit Group's turn start.
