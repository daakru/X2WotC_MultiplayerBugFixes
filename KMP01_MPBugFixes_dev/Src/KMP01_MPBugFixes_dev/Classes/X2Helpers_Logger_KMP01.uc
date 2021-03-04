/*                                                                             
 * FILE:     X2Helpers_Logger_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01-L v0.3
 *
 * Description.
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class X2Helpers_Logger_KMP01 extends Object config(Game) abstract;

var name modID;
var config bool bLog;
var config bool bLogVerbose;
var config bool bRedscreen;

//---------------------------------------------------------------------------//

struct ScriptFunctionNode
{
    var String SrcClass;
    var String SrcFunction;
};

//---------------------------------------------------------------------------//

static function bool bLogState(bool verbose=false)
{
	return (default.bLog && (!verbose || (verbose && default.bLogVerbose)));
}

//---------------------------------------------------------------------------//

static function kLogger(string Message, bool verbose, bool deeplog)
{
    local array<string> sfslines;
    local array<string> dlcisplit;
    local string sfs;
    local string dlci;

    if (!deeplog)
    {
        `log(Message, bLogState(verbose), default.modID);
    }
    else
    {
        sfs = GetScriptTrace();
        ParseStringIntoArray(sfs, sfslines, "\n", false);
        // The last two lines are for our DeepLogger and dLog calls so skip those
        sfs = Split(sfslines[sfslines.Length - 4], "F");
        dlci = Split(sfs, " ", true);
        dlcisplit = SplitString(dlci, ".");
        `log(dlcisplit[0] @ dlcisplit[1] $ "\n    " $ Message, , 'KMP01_DEEPLOG');
    }
}

//---------------------------------------------------------------------------//

static function DeepLogger(string Message, bool verbose, bool cfgoverride)
{
    local array<string> sfslines;
    local array<string> dlcisplit;
    local string sfs;
    local string dlci;
    local int i;

    if (bLogState(verbose) || cfgoverride)
    {
        sfs = GetScriptTrace();
        ParseStringIntoArray(sfs, sfslines, "\n", false);
        // The last two lines are for our DeepLogger and dLog calls so skip those    
        for (i = sfslines.Length - 1; i > 0; i--)
        {
            sfs = Split(sfslines[i], "F");
            dlci = Split(sfs, " ", true);
            dlcisplit = SplitString(dlci, ".");
            //`log(sfs, , name(dlcisplit[0]));
            `log(dlcisplit[0] @ dlcisplit[1] $ "\n    " $ Message, , 'KMP01_DEEPLOG');
        }
    }
}

//---------------------------------------------------------------------------//

static function kRedscreen(string Message, bool bBypassRed)
{
    local array<string> sfslines;
    local array<string> dlcisplit;
    local string sfs;
    local string dlci;

    if (!bBypassRed && !default.bRedscreen)
    {
        return;
    }
    sfs = GetScriptTrace();
    ParseStringIntoArray(sfs, sfslines, "\n", false);
    // The last two lines are for our DeepLogger and dLog calls so skip those
    sfs = Split(sfslines[sfslines.Length - 4], "F");
    dlci = Split(sfs, " ", true);
    dlcisplit = SplitString(dlci, ".");
    `REDSCREEN("kRedscreen::" $ dlcisplit[0] @ dlcisplit[1] @ "|" @ Message);
}

//---------------------------------------------------------------------------//

/*
// Interface for bLogState, add to each class that needs configurable logs
static function bool bLog(bool verbose=false)
{
    return class'X2Helpers_Logger_KMP01'.static.bLogState(verbose);
}

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
*/

//---------------------------------------------------------------------------//

defaultproperties
{
    modID="KMP01_MPBugFixes_dev"
}
