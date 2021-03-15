class X2Ability_ScanBeGone_KMP01 extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(AddScanBeGoneAbility());

	return Templates;
}


static function X2AbilityTemplate AddScanBeGoneAbility()
{
    local X2AbilityTemplate Template;

    Template = PersistentPurePassive('ScanBeGone_Ability_KMP01', , , 'eAbilitySource_Perk', false);

    return Template;
}


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