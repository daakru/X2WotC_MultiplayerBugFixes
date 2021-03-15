/*                                                                             
 * FILE:     XComDownloadableContentInfo_KMP01_MPBugFixes_dev.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01 v1.3.3+
 *
 * Specify Mod behavior on campaign creation or initial saved game load.
 *
 * Dependencies: X2ModConfig_KMP01.uc; X2Helpers_Logger_KMP01.uc
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class X2DownloadableContentInfo_KMP01_MPBugFixes_dev
    extends X2DownloadableContentInfo;

var bool bDeepLog;

//---------------------------------------------------------------------------//

/// <summary>
/// Called when the player loads a saved game created prior to mod installation
/// </summary>
static event OnLoadedSavedGame() {}

//---------------------------------------------------------------------------//

/// <summary>
/// Called when the player starts a new campaign
/// </summary>
static event InstallNewCampaign(XComGameState StartState) {}

//---------------------------------------------------------------------------//

/// <summary>
/// Called after Templates have been created
/// </summary>
static event OnPostTemplatesCreated()
{
    kLog("[Loading MP Bug-Spray]"
        $ "\n    Version:" @ (class'X2ModConfig_KMP01'.default.Unstable
        ? "Dev" : "Stable") @ class'X2ModConfig_KMP01'.default.Version 
        $ "\n    Cheats: " @ (class'Engine'.static.IsConsoleAllowed() 
        ? "Enabled" : "Disabled"));

    PatchSteadyHands();
    if (class'X2ModConfig_KMP01'.default.Unstable)
    {
        AddScanBeGoneAbility();
    }
}

//---------------------------------------------------------------------------//

/// <summary>
/// Called just before the player launches into a tactical mission
/// Allows mods to modify the start state before launching into the mission
/// </summary>
static event OnPreMission(XComGameState StartGameState,
	XComGameState_MissionSite MissionState)
{
    kLog("OnPreMission", true, default.bDeepLog);
	class'XComGameState_SingletonTracker_KMP01'
		.static.InitializeTracker(StartGameState);
}

//---------------------------------------------------------------------------//

/// <summary>
/// Patch Steady Hands' Persistent Stat Change Effect to Ignore duplicates
/// </summary>
static function AddScanBeGoneAbility()
{
    local array<X2DataTemplate>             DifficultyVariants;
    local X2DataTemplate                    DifficultyVariant;
    local X2AbilityTemplate                 AbilityTemplate;
    local X2AbilityTemplateManager          AbilityMgr;

    AbilityMgr = class'X2AbilityTemplateManager'
        .static.GetAbilityTemplateManager();

    AbilityMgr.FindDataTemplateAllDifficulties(
        'StandardMove', DifficultyVariants);

    foreach DifficultyVariants(DifficultyVariant)
    {
        AbilityTemplate = X2AbilityTemplate(DifficultyVariant);

        if (AbilityTemplate == none)
        {
            kRed("ERROR: AbilityTemplate Not Found!", false);
            kLog("Warning: Redscreen: ERROR: AbilityTemplate Not Found!",
                false, default.bDeepLog);
            continue;
        }

        if (AbilityTemplate.AdditionalAbilities
            .Find('ScanBeGone_Ability_KMP01') != INDEX_NONE)
        {
            kRed("ERROR: ScanBeGone Already Exists!", false);
            kLog("Warning: Redscreen: ERROR: ScanBeGone Already Exists!",
                false, default.bDeepLog);
            continue;
        }

        AbilityTemplate.AdditionalAbilities
            .AddItem('ScanBeGone_Ability_KMP01');
    }
}

//---------------------------------------------------------------------------//

/// <summary>
/// Patch Steady Hands' Persistent Stat Change Effect to Ignore duplicates
/// </summary>
static function PatchSteadyHands()
{
    local array<X2DataTemplate>             DifficultyVariants;
    local X2DataTemplate                    DifficultyVariant;
    local X2Effect_PersistentStatChange     StatChangeEffect;
    local X2Effect_Persistent               PersistentEffect;
    local X2AbilityTemplate                 AbilityTemplate;
    local X2AbilityTemplateManager          AbilityMgr;
    local X2Effect                          Effect;

    AbilityMgr = class'X2AbilityTemplateManager'
        .static.GetAbilityTemplateManager();

    AbilityMgr.FindDataTemplateAllDifficulties(
        'SteadyHands', DifficultyVariants);

    foreach DifficultyVariants(DifficultyVariant)
    {
        AbilityTemplate = X2AbilityTemplate(DifficultyVariant);

        if (AbilityTemplate == none)
        {
            kRed("ERROR: AbilityTemplate Not Found!", false);
            kLog("Warning: Redscreen: ERROR: AbilityTemplate Not Found!",
                false, default.bDeepLog);
            continue;
        }

        foreach AbilityTemplate.AbilityShooterEffects(Effect)
        {
            PersistentEffect = X2Effect_Persistent(Effect);
            if (PersistentEffect.EffectName != 'SteadyHands')
            {
                continue;
            }

            foreach PersistentEffect.ApplyOnTick(Effect)
            {
                StatChangeEffect = X2Effect_PersistentStatChange(Effect);
                if (StatChangeEffect.EffectName != 'SteadyHandsStatBoost')
                {
                    continue;
                }

                kLog("Original Duplicate Response:"
                    @ StatChangeEffect.DuplicateResponse,
                    true, default.bDeepLog);
                StatChangeEffect.DuplicateResponse = eDupe_Ignore;
                //StatChangeEffect.StatusIcon = StatChangeEffect.IconImage;
                kLog("New Duplicate Response:"
                    @ StatChangeEffect.DuplicateResponse,
                    true, default.bDeepLog);
                break;
            }
            break;
        }
    }
}

//---------------------------------------------------------------------------//

/// Use to Test Tactical Singleton Tracker
exec function CheckTacticalTracker()
{
	local XComGameState_SingletonTracker_KMP01 STracker;

	STracker = class'XComGameState_SingletonTracker_KMP01'
		.static.GetSingleTracker();
	if (STracker == none)
	{
		class'Helpers'.static.OutputMsg("No Tactical Tracker Found.\n");
		return;
	}
	class'Helpers'.static.OutputMsg("Tactical Tracker Found."
		@ "bEventHasRunBefore =" @ STracker.bEventHasRunBefore $ "\n");
}

//---------------------------------------------------------------------------//

/// Use to Test Tactical Singleton Tracker
exec function SetTacticalTrackerBool(bool NewValue)
{
	local XComGameState_SingletonTracker_KMP01 STracker;
	local XComGameState NewGameState;

	STracker = class'XComGameState_SingletonTracker_KMP01'
		.static.GetSingleTracker();
	if (STracker == none)
	{
		class'Helpers'.static.OutputMsg("No Tactical Tracker Found.\n");
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static
		.CreateChangeState();
	STracker = XComGameState_SingletonTracker_KMP01(NewGameState
		.ModifyStateObject(class'XComGameState_SingletonTracker_KMP01',
		STracker.ObjectID));

	STracker.bEventHasRunBefore = NewValue;

	`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	class'Helpers'.static.OutputMsg("Tactical Tracker Found."
		@ "bEventHasRunBefore set to " @ NewValue $ "\n");
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
    // class'X2ModConfig_KMP01'.default.Unstable
}
