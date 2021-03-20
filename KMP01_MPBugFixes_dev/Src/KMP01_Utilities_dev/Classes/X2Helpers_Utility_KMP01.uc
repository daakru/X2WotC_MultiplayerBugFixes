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

//---------------------------------------------------------------------------//

static final function string TTileToString(out TTile Tile)
{
    return "x:" @ Tile.X @ "y:" @ Tile.Y @ "z:" @ Tile.Z;
}

//---------------------------------------------------------------------------//

static final function string VectorToString(out Vector vLoc)
{
    return "x:" @ vLoc.X @ "y:" @ vLoc.Y @ "z:" @ vLoc.Z;
}

//---------------------------------------------------------------------------//

static final function string GetCursorLoc(optional out Vector vLoc,
                                          optional out TTile Tile)
{
    local XComWorldData WorldData;

    WorldData = `XWORLD;
    vLoc = `CURSOR.Location;
    if(!WorldData.GetFloorTileForPosition(vLoc, Tile))
    {
        Tile = WorldData.GetTileCoordinatesFromPosition(vLoc);
    }
    return "Cursor:" @ VectorToString(vLoc) 
        @ "\n  Tile:" @ TTileToString(Tile);
}
