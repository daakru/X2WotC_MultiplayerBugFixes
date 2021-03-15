/*                                                                             
 * FILE:     X2Helpers_Utility_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01-U
 *
 * Add utility functions commonly used by other classes in the mod.
 *
 * Dependencies: None
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class X2Helpers_Utility_KMP01 extends Object abstract;

//---------------------------------------------------------------------------//

static final function bool IsUnitValid(XComGameState_Unit UnitState,
                                       optional bool bIsDeadValid)
{
    // Skip removed (evac'ed), non-selectable (mimic beacon),
    //   cosmectic (gremlin), dead, and playerless (MOCX!) Units
    return !(UnitState == none
        || UnitState.bRemovedFromPlay
        || UnitState.ControllingPlayer.ObjectID <= 0
        || UnitState.GetMyTemplate().bNeverSelectable
        || UnitState.GetMyTemplate().bIsCosmetic
        || (!bIsDeadValid && !UnitState.IsAlive())
    );
}
