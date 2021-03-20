/*                                                                             
 * FILE:     XComDownloadableContentInfo_KMP01_MPBugFixes_dev.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01 v1.3.4.1
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

struct MPTemplateChanges
{
    var name TemplateName;
    var int PointCost;
    var array<name> AddPerks;
    var array<name> RemovePerks;
};

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
    AddScanBeGoneAbility_Dev();
    PatchMeleeForScanBeGone();
    if (class'X2ModConfig_KMP01'.default.Unstable)
    {
        // Do Dev stuff here :)
        ModifyMPCharacterTemplates();
    }
    else
    {
        // Add Stable versions of Dev features here :)
        //AddScanBeGoneAbility();
    }
}

//---------------------------------------------------------------------------//

static private function GetModifyMPTemplateData(
    out array<MPTemplateChanges> Data)
{
    local MPTemplateChanges Changes;
    local MPTemplateChanges EmptyChanges;

    // Templar Changes
    Changes.TemplateName = 'Templar';
    Changes.PointCost = 4500;

    Changes.AddPerks.AddItem('MeditationPreparation');
    Changes.AddPerks.AddItem('TemplarBladestorm');
    Changes.AddPerks.AddItem('Fortress');

    Data.AddItem(Changes);
    Changes = EmptyChanges;
}

//---------------------------------------------------------------------------//

static private function ModifyMPCharacterTemplates()
{
    local array<X2DataTemplate> DifficultyVariants;
    local X2DataTemplate DifficultyVariant;
    local X2MPCharacterTemplateManager MPTemplateMgr;
    local X2MPCharacterTemplate MPTemplate;

    local array<MPTemplateChanges> MPTemplateChangeData;
    local MPTemplateChanges ChangeData;
    local name PerkName;

    GetModifyMPTemplateData(MPTemplateChangeData);

    foreach MPTemplateChangeData(ChangeData)
    {
        MPTemplateMgr.FindDataTemplateAllDifficulties(
            ChangeData.TemplateName, DifficultyVariants);

        foreach DifficultyVariants(DifficultyVariant)
        {
            MPTemplate = X2MPCharacterTemplate(DifficultyVariant);

            if (MPTemplate == none)
            {
                kRed("ERROR: MPTemplate Not Found!", false);
                kLog("Warning: Redscreen: ERROR: MPTemplate Not Found!",
                    false, default.bDeepLog);
                continue;
            }

            foreach ChangeData.RemovePerks(PerkName)
            {
                MPTemplate.Abilities.RemoveItem(PerkName);
            }

            foreach ChangeData.AddPerks(PerkName)
            {
                MPTemplate.Abilities.AddItem(PerkName);
            }

            if (ChangeData.PointCost != 0
                && ChangeData.PointCost != MPTemplate.Cost)
            {
                MPTemplate.Cost = ChangeData.PointCost;
            }
        }
    }
}

//---------------------------------------------------------------------------//

/// <summary>
/// Fix Tile Scanning
/// </summary>
static function AddScanBeGoneAbility_Dev()
{
    local array<X2DataTemplate> DifficultyVariants;
    local X2DataTemplate DifficultyVariant;
    local X2AbilityTemplate AbilityTemplate;
    local X2AbilityTemplateManager AbilityMgr;

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
        AbilityTemplate.BuildVisualizationFn =
            class'X2Ability_ScanBeGone_KMP01'
            .static.MoveAbility_BuildVisualization_TileBump;
        AbilityTemplate.AdditionalAbilities
            .AddItem('ScanBeGone_Ability_KMP01');
    }
}

//---------------------------------------------------------------------------//

static private function GetTypicalAbilityMeleeTemplates(out array<name> Names)
{
    Names.AddItem('Rend');  // Templar
    Names.AddItem('Strike');  // Spark
    Names.AddItem('StunLance');  // Stun Lancer
    Names.AddItem('SwordSlice');  // Ranger
    Names.AddItem('BigDamnPunchMP');  // Andromedon Shell
    Names.AddItem('SkirmisherMelee');  // Skirmisher
    Names.AddItem('ChryssalidSlash');  // Chryssalid
    Names.AddItem('ChryssalidSlashMP');  // Chryssalid
    Names.AddItem('StandardMovingMelee');  // Psi Zombie
}

//---------------------------------------------------------------------------//

static private function GetBerserkerMoveTemplates(out array<name> Names)
{
    Names.AddItem('DevastatingPunchMP');
}

//---------------------------------------------------------------------------//

static private function GetSpectreMoveTemplates(out array<name> Names)
{
    Names.AddItem('Shadowbind');
    Names.AddItem('ShadowbindM2');
    Names.AddItem('ShadowbindMP');
}

//---------------------------------------------------------------------------//

static function PatchMeleeForScanBeGone()
{
    local array<name> TypicalAbilityMeleeTemplateNames;
    local array<name> BerserkerMoveTemplateNames;
    local array<name> SpectreMoveTemplateNames;
    local X2Condition_UnitValue IsNotImmobilized;
    local array<X2DataTemplate> DifficultyVariants;
    local X2DataTemplate DifficultyVariant;
    local X2AbilityTemplateManager AbilityMgr;
    local X2AbilityTemplate AbilityTemplate;
    local name TemplateName;

    AbilityMgr = class'X2AbilityTemplateManager'
        .static.GetAbilityTemplateManager();

    GetTypicalAbilityMeleeTemplates(TypicalAbilityMeleeTemplateNames);
    GetBerserkerMoveTemplates(BerserkerMoveTemplateNames);
    GetSpectreMoveTemplates(SpectreMoveTemplateNames);

    foreach TypicalAbilityMeleeTemplateNames(TemplateName)
    {
        AbilityMgr.FindDataTemplateAllDifficulties(
            TemplateName, DifficultyVariants);

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
            AbilityTemplate.BuildVisualizationFn =
                class'X2Ability_ScanBeGone_KMP01'.static
                .TypicalAbility_BuildVisualization_TileBump;

            IsNotImmobilized = new class'X2Condition_UnitValue';
            IsNotImmobilized.AddCheckValue(class'X2Ability_DefaultAbilitySet'
                .default.ImmobilizedValueName, 0);
            AbilityTemplate.AbilityShooterConditions.AddItem(IsNotImmobilized);
        }
    }

    foreach BerserkerMoveTemplateNames(TemplateName)
    {
        AbilityMgr.FindDataTemplateAllDifficulties(
            TemplateName, DifficultyVariants);

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
            AbilityTemplate.BuildVisualizationFn =
                class'X2Ability_ScanBeGone_KMP01'.static
                .DevastatingPunchAbility_BuildVisualization_TileBump;

            IsNotImmobilized = new class'X2Condition_UnitValue';
            IsNotImmobilized.AddCheckValue(class'X2Ability_DefaultAbilitySet'
                .default.ImmobilizedValueName, 0);
            AbilityTemplate.AbilityShooterConditions.AddItem(IsNotImmobilized);
        }
    }

    foreach SpectreMoveTemplateNames(TemplateName)
    {
        AbilityMgr.FindDataTemplateAllDifficulties(
            TemplateName, DifficultyVariants);

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
            AbilityTemplate.BuildVisualizationFn =
                class'X2Ability_ScanBeGone_KMP01'.static
                .Shadowbind_BuildVisualization_TileBump;

            IsNotImmobilized = new class'X2Condition_UnitValue';
            IsNotImmobilized.AddCheckValue(class'X2Ability_DefaultAbilitySet'
                .default.ImmobilizedValueName, 0);
            AbilityTemplate.AbilityShooterConditions.AddItem(IsNotImmobilized);
        }
    }
}

//---------------------------------------------------------------------------//

/// <summary>
/// Fix Tile Scanning
/// </summary>
static function AddScanBeGoneAbility()
{
    local array<X2DataTemplate> DifficultyVariants;
    local X2DataTemplate DifficultyVariant;
    local X2AbilityTemplate AbilityTemplate;
    local X2AbilityTemplateManager AbilityMgr;

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
    local array<X2DataTemplate> DifficultyVariants;
    local X2DataTemplate DifficultyVariant;
    local X2Effect_PersistentStatChange StatChangeEffect;
    local X2Effect_Persistent PersistentEffect;
    local X2AbilityTemplate AbilityTemplate;
    local X2AbilityTemplateManager AbilityMgr;
    local X2Effect Effect;

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

exec function PrintCursor()
{
    class'Helpers'.static.OutputMsg(
        class'X2Helpers_Utility_KMP01'.static.GetCursorLoc());
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
