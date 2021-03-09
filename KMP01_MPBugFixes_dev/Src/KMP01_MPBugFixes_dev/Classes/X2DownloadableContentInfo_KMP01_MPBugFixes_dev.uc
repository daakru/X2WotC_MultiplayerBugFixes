/*                                                                             
 * FILE:     XComDownloadableContentInfo_KMP01_MPBugFixes_dev.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01 v0.1
 *
 * Specify Mod behavior on campaign creation or initial saved game load.
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
    PatchSteadyHands();
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
                true, default.bDeepLog);
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
                StatChangeEffect.bDisplayInUI = true;
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
