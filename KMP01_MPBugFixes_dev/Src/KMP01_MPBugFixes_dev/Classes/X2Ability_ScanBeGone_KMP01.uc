/*                                                                             
 * FILE:     X2Ability_ScanBeGone_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * Prevent Units that are not visible to the enemy from being tilescanned.
 *
 * Dependencies: X2Effect_ScanBeGone_KMP01.uc
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class X2Ability_ScanBeGone_KMP01 extends X2Ability;

var localized string strScanBeGoneFriendlyName;
var localized string strScanBeGoneDescription;

//---------------------------------------------------------------------------//

var const name uvForceLadderBlock;  // UnitValue name to override ladder block

var const name AbilityName;
var const name AbilitySource;
var const EAbilityHostility eHostility;
var const EAbilityIconBehavior eHudIconBehavior;
var const string imgTemplateIcon;

var const bool bPurePassive;
var const bool bDisplayInUI;
var const bool bCrossClassEligible;

//---------------------------------------------------------------------------//

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(AddScanBeGoneAbility());

	return Templates;
}

//---------------------------------------------------------------------------//

static function X2AbilityTemplate AddScanBeGoneAbility()
{
    local X2Effect_ScanBeGone_KMP01 PersistentEffect;
    local X2AbilityTemplate Template;

    //Template = PersistentPurePassive('ScanBeGone_Ability_KMP01', , ,
    //    'eAbilitySource_Perk', false);

    `CREATE_X2ABILITY_TEMPLATE(Template, default.AbilityName);

    Template.AbilitySourceName = default.AbilitySource;
    Template.Hostility = default.eHostility;
    Template.eAbilityIconBehaviorHUD = default.eHudIconBehavior;
    Template.IconImage = default.imgTemplateIcon;

    Template.bIsPassive = default.bPurePassive;
    Template.bCrossClassEligible = default.bCrossClassEligible;

    Template.LocFriendlyName = default.strScanBeGoneFriendlyName;
    Template.LocLongDescription = default.strScanBeGoneDescription;

    Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
    Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

    // Build the Persistent Effect
    PersistentEffect = new class'X2Effect_ScanBeGone_KMP01';
    PersistentEffect.BuildPersistentEffect(1, true, false);
    PersistentEffect.SetDisplayInfo(ePerkBuff_Passive,
                                    Template.LocFriendlyName,
                                    Template.LocLongDescription,
                                    default.imgTemplateIcon,
                                    default.bDisplayInUI, ,
                                    Template.AbilitySourceName);

    Template.AddTargetEffect(PersistentEffect);

    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

    return Template;
}

//---------------------------------------------------------------------------//
/*
static function X2AbilityTemplate PersistentPurePassive(name TemplateName,
    string TemplateIconImage="img:///UILibrary_PerkIcons.UIPerk_standard",
    bool bCrossClassEligible=false,
    name AbilitySourceName='eAbilitySource_Perk',
    bool bDisplayInUI=false)
{
    local X2AbilityTemplate Template;
    local X2Effect_ScanBeGone_KMP01 Effect;

    `CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

    Template.IconImage = TemplateIconImage;
    Template.AbilitySourceName = AbilitySourceName;
    Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
    Template.Hostility = eHostility_Neutral;
    Template.bIsPassive = true;

    Template.AbilityToHitCalc = default.DeadEye;
    Template.AbilityTargetStyle = default.SelfTarget;
    Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

    // Build the Persistent Effect
    Effect = new class'X2Effect_ScanBeGone_KMP01';
    Effect.BuildPersistentEffect(1, true, false);
    Template.AddTargetEffect(Effect);

    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

    Template.bCrossClassEligible = bCrossClassEligible;

    return Template;
}
*/
//---------------------------------------------------------------------------//

defaultproperties
{
    uvForceLadderBlock="KMP01_ShouldBlockLadderWhileConcealed_UnitValue"

    AbilityName="ScanBeGone_Ability_KMP01"
    AbilitySource="eAbilitySource_Perk"
    eHostility=eHostility_Neutral
    eHudIconBehavior=eAbilityIconBehavior_NeverShow
    imgTemplateIcon="img:///UILibrary_PerkIcons.UIPerk_lowvisibility"

    bPurePassive=true
    bDisplayInUI=true
    bCrossClassEligible=false
}
