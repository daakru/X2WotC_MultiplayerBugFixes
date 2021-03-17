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

var const name UV_ForceLadderBlock;

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
    local X2AbilityTemplate Template;

    Template = PersistentPurePassive('ScanBeGone_Ability_KMP01', , , 'eAbilitySource_Perk', false);

    return Template;
}

//---------------------------------------------------------------------------//

static function X2AbilityTemplate PersistentPurePassive(name TemplateName,
    optional string TemplateIconImage="img:///UILibrary_PerkIcons.UIPerk_standard",
    optional bool bCrossClassEligible=false,
    optional Name AbilitySourceName='eAbilitySource_Perk',
    optional bool bDisplayInUI=true)
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

//---------------------------------------------------------------------------//

defaultproperties
{
    UV_ForceLadderBlock="KMP01_ShouldBlockLadderWhileConcealed_UnitValue"
}