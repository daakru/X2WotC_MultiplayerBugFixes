﻿[WotC] MP Bug-Spray: Multiplayer Overhaul (WIP)
Mod Author: Kinetos#6935
Version: 1.4.0

Developmental gameplay fixes for XCOM 2 WotC Multiplayer.
Code is available on GitHub here: https://github.com/daakru/X2WotC_MultiplayerBugFixes.

Current Mod Class Overrides (MCOs):
    UIMPShell_SquadCostPanel_RemotePlayer
    >>> X2Effect_Persistent
    >>> XComGameState_Ability
    >>> XComGameState_Effect
    XComGameState_Unit
    UITacticalHUD_MouseControls
">>>" signifies an MCO is disabled through config.

=-= Gameplay Changes =-=

Any direct gameplay changes will be documented here on addition or removal:
    Hides Squad Loadout Names from your opponent in the lobby UI.
    Steady Hands now functions as it does in Single Player.
    Hunkered Down from Deep Cover now functions as it does in Single Player.
    Camera should no longer pan to enemy concealed units at match start.
    Non-visible units no longer prevent targeting a tile for movement unless they are at the top of a ladder.

Developmental Features (Set Unstable=true in XComGame.ini):
    Test changing character costs and abilities.

=-= Credits and Thanks =-=

Thanks to those who help test new features before release:
    Action Man
    Ted
    D'Haren Legion

Thanks to the regulars of the XCOM 2 Modding discord for all their help.
Thanks to Iridar and robojumper for all their advice in fixing tilescanning.

XCOM 2 WOTC API Copyright (c) 2016 Firaxis Games, Inc.
