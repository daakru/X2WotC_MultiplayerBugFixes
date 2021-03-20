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

static private function bool IsTileBump(XComGameStateContext_Ability Context)
{
    local bool bTileBump;
    bTileBump = (Context.PreBuildVisualizationFn
        .Find(class'X2Effect_ScanBeGone_KMP01'.static
        .TileBump_PreBuildVisualization) != INDEX_NONE);

    `Log("bTileBump:" @ bTileBump, , 'KMP01');
    return bTileBump;
}

//---------------------------------------------------------------------------//

static private function TruncatePathForTileBump(
    out XComGameStateContext_Ability AbilityContext)
{
    local TTile tStartLoc;
    local PathPoint StartPath;
    local int idx;

    for (idx=0; idx < AbilityContext.InputContext.MovementPaths.Length; idx++)
    {
        tStartLoc = AbilityContext.InputContext.MovementPaths[idx]
            .MovementTiles[0];
        AbilityContext.InputContext.MovementPaths[idx]
            .MovementTiles.Length = 1;
        AbilityContext.InputContext.MovementPaths[idx]
            .MovementTiles.AddItem(tStartLoc);

        StartPath = AbilityContext.InputContext
            .MovementPaths[idx].MovementData[0];
        StartPath.Traversal = eTraversal_None;
        StartPath.PathTileIndex += 1;
        AbilityContext.InputContext.MovementPaths[idx]
            .MovementData[0].Traversal = eTraversal_None;
        AbilityContext.InputContext.MovementPaths[idx]
            .MovementData.Length = 1;
        AbilityContext.InputContext.MovementPaths[idx]
            .MovementData.AddItem(StartPath);
    }
}

//---------------------------------------------------------------------------//

static function MoveAbility_BuildVisualization_TileBump(
    XComGameState VisualizeGameState)
{
    local XComGameStateHistory History;
    local StateObjectReference MovingUnitRef;    
    local XGUnit MovingUnitVisualizer;
    local VisualizationActionMetadata EmptyMetaData;
    local VisualizationActionMetadata ActionMetaData;
    local XComGameStateContext_Ability AbilityContext;
    local XComGameState_InteractiveObject InteractiveObject;
    local X2Action_PlaySoundAndFlyOver CharSpeechAction;
    local XComGameState_EnvironmentDamage DamageEvent;    
    local X2Action_Delay DelayAction;
    local bool bMoveContainsTeleport;
    local int MovingUnitIndex;
    local X2Action_UpdateUI UpdateUIAction;
    local XComGameStateVisualizationMgr VisualizationMgr;
    local array<X2Action> Nodes;
    local X2Action_MarkerNamed JoinActions;
    // Start Issue %TB%
    local bool bTileBump;
    // End Issue %TB%

    History = `XCOMHISTORY;
    VisualizationMgr = `XCOMVISUALIZATIONMGR;
    AbilityContext = XComGameStateContext_Ability(
        VisualizeGameState.GetContext());
    // Start Issue %TB%
    bTileBump = IsTileBump(AbilityContext);
    // End Issue %TB%
    for (MovingUnitIndex = 0; MovingUnitIndex < AbilityContext
        .InputContext.MovementPaths.Length; ++MovingUnitIndex)
    {
        MovingUnitRef = AbilityContext.InputContext
            .MovementPaths[MovingUnitIndex].MovingUnitRef;

        ActionMetaData = EmptyMetaData;
        ActionMetaData.StateObject_OldState = History.GetGameStateForObjectID(
            MovingUnitRef.ObjectID, eReturnType_Reference,
            VisualizeGameState.HistoryIndex - 1);
        ActionMetaData.StateObject_NewState = VisualizeGameState
            .GetGameStateForObjectID(MovingUnitRef.ObjectID);
        ActionMetaData.VisualizeActor = History
            .GetVisualizer(MovingUnitRef.ObjectID);
        MovingUnitVisualizer = XGUnit(ActionMetaData.VisualizeActor);
        
        // The next two actions are parented to the Build Tree, as they are
        // the beginning of the move sequence for an individual unit.
        // Each move sequence will run in parallel with the others, being
        // joined at the end of this function by the tree insert end node.
        if (true || !bTileBump)
        {
            // Pause a few seconds
            if (MovingUnitVisualizer.GetTeam() == eTeam_XCom)
            {
                DelayAction = X2Action_Delay(class'X2Action_Delay'.static
                    .AddToVisualizationTree(ActionMetaData, AbilityContext,
                    false, VisualizationMgr.BuildVisTree));
                DelayAction.Duration = class'X2Ability_DefaultAbilitySet'
                    .default.TypicalMoveDelay;
            }

            CharSpeechAction = X2Action_PlaySoundAndFlyOver(
                class'X2Action_PlaySoundAndFlyOver'.static
                .AddToVisualizationTree(ActionMetaData, AbilityContext,
                false, DelayAction != none ? DelayAction
                    : VisualizationMgr.BuildVisTree));

            // Civilians on the neutral team are not allowed to
            // have sound + flyover for moving
            if (AbilityContext.InputContext.AbilityTemplateName ==
                'StandardMove' && XComGameState_Unit(ActionMetaData
                .StateObject_NewState).GetTeam() != eTeam_Neutral)
            {
                if (XComGameState_Unit(ActionMetaData.StateObject_NewState)
                    .IsPanicked())
                {
                    //CharSpeechAction.SetSoundAndFlyOverParameters(
                    //    None, "", 'Panic', eColor_Good);
                }
                else
                {
                    if (AbilityContext.InputContext
                        .MovementPaths[MovingUnitIndex]
                        .CostIncreases.Length == 0)
                    {
                        CharSpeechAction.SetSoundAndFlyOverParameters(
                            None, "", 'Moving', eColor_Good);
                    }
                    else
                    {
                        CharSpeechAction.SetSoundAndFlyOverParameters(
                            None, "", 'Dashing', eColor_Good);
                    }
                }
            }
        }
        // Start Issue %TB%
        if (bTileBump)
        {
            TruncatePathForTileBump(AbilityContext);
        }
        // End Issue %TB%
        class'X2VisualizerHelpers'.static
            .ParsePath(AbilityContext, ActionMetaData);

        if (true || !bTileBump)
        {
            // Update unit flag to show the new cover state/moves remaining
            UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'
                .static.AddToVisualizationTree(
                ActionMetaData, AbilityContext));
            UpdateUIAction.SpecificID = MovingUnitRef.ObjectID;
            UpdateUIAction.UpdateType = EUIUT_UnitFlag_Moves;

            UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static
                .AddToVisualizationTree(ActionMetaData, AbilityContext));
            UpdateUIAction.SpecificID = MovingUnitRef.ObjectID;
            UpdateUIAction.UpdateType = EUIUT_UnitFlag_Cover;
        
            // Add "civilian sighted" and/or "advent sighted" VO cues.
            // Removed per Jake
            //MoveAbility_BuildVisForNewUnitVOCallouts(
            //    VisualizeGameState, ActionMetaData);
            bMoveContainsTeleport = VisualizationMgr.GetNodeOfType(
                VisualizationMgr.BuildVisTree, class'X2Action_MoveTeleport',
                ActionMetaData.VisualizeActor) != none;
        }
    }

    foreach VisualizeGameState.IterateByClassType(
        class'XComGameState_InteractiveObject', InteractiveObject)
    {
        if (true || !bTileBump)
        {
            ActionMetaData = EmptyMetaData;
            // Don't necessarily have a previous state,
            // so just use the one we know about
            ActionMetaData.StateObject_OldState = InteractiveObject;
            ActionMetaData.StateObject_NewState = InteractiveObject;
            ActionMetaData.VisualizeActor = History
                .GetVisualizer(InteractiveObject.ObjectID);

            // Allow alien units to move through locked doors at will,
            // but politely shut them behind
            if( InteractiveObject.MustBeHacked()
                && !InteractiveObject.HasBeenHacked()
                && MovingUnitVisualizer.GetTeam() == eTeam_Alien
                && !bMoveContainsTeleport )
            {
                class'X2Action_InteractOpenClose'.static
                    .AddToVisualizationTree(ActionMetaData, AbilityContext);
            }
            else
            {
                class'X2Action_BreakInteractActor'.static
                    .AddToVisualizationTree(ActionMetaData, AbilityContext);
            }
        }
    }

    foreach VisualizeGameState.IterateByClassType(
        class'XComGameState_EnvironmentDamage', DamageEvent)
    {
        if (true || !bTileBump)
        {
            ActionMetaData = EmptyMetaData;
            // Don't necessarily have a previous state,
            // so just use the one we know about
            ActionMetaData.StateObject_OldState = DamageEvent; 
            ActionMetaData.StateObject_NewState = DamageEvent;
            ActionMetaData.VisualizeActor = none;
            // This is my weapon, this is my gun
            class'X2Action_ApplyWeaponDamageToTerrain'.static
                .AddToVisualizationTree(ActionMetaData, AbilityContext);
        }
    }
    if (true || !bTileBump)
    {
        // Add an end node that waits for all leaf nodes, as they may
        // represent separate moving units moving as a group
        VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, Nodes);
        ActionMetaData = EmptyMetaData;
        JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'
            .static.AddToVisualizationTree(ActionMetaData, AbilityContext,
            false, none, Nodes));
        JoinActions.SetName("Join");
    }
}

//---------------------------------------------------------------------------//

static function DevastatingPunchAbility_BuildVisualization_TileBump(
    XComGameState VisualizeGameState)
{
    local XComGameStateHistory History;
    local XComGameState_Unit SourceState;
    local XComGameState_Unit TargetState;
    local XComGameStateContext_Ability Context;
    local VisualizationActionMetadata ActionMetadata;
    local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

    // Start Issue %TB%
    TypicalAbility_BuildVisualization_TileBump(VisualizeGameState);
    // End Issue %TB%
    
    // Check if we should add a fly-over for 'Blind Rage'
    // (iff both source and target are AI).
    History = `XCOMHISTORY;
    Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
    // Start Issue %TB%
    if (IsTileBump(Context))
    {
        return;
    }
    // End Issue %TB%
    SourceState = XComGameState_Unit(History.GetGameStateForObjectID(
        Context.InputContext.SourceObject.ObjectID));
    if( SourceState.ControllingPlayerIsAI() && SourceState
        .IsUnitAffectedByEffectName(class'X2Ability_Berserker'
        .default.RageTriggeredEffectName))
    {
        TargetState = XComGameState_Unit(History.GetGameStateForObjectID(
            Context.InputContext.PrimaryTarget.ObjectID));
        if( TargetState.GetTeam() == SourceState.GetTeam() )
        {
            ActionMetadata.StateObject_OldState = History
                .GetGameStateForObjectID(SourceState.ObjectID,
                eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
            ActionMetadata.StateObject_NewState = VisualizeGameState
                .GetGameStateForObjectID(SourceState.ObjectID);
            ActionMetadata.VisualizeActor = History
                .GetVisualizer(SourceState.ObjectID);

            SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(
                class'X2Action_PlaySoundAndFlyOver'.static
                .AddToVisualizationTree(ActionMetadata, Context,
                false, ActionMetadata.LastActionAdded));
            SoundAndFlyOver.SetSoundAndFlyOverParameters(
                None, class'X2Ability_Berserker'.default.BlindRageFlyover,
                '', eColor_Good);
        }
    }
}

//---------------------------------------------------------------------------//

private static function SpectreMoveInsertTransform(
    XComGameState VisualizeGameState,
    VisualizationActionMetadata ActionMetaData,
    array<X2Action> TransformStartParents,
    array<X2Action> TransformStopParents)
{
	local X2Action_PlayAnimation AnimAction;

	AnimAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static
        .AddToVisualizationTree(ActionMetaData, VisualizeGameState
        .GetContext(), true, , TransformStartParents));
	AnimAction.Params.AnimName = 'HL_Transform_Start';

	AnimAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static
        .AddToVisualizationTree(ActionMetaData, VisualizeGameState
        .GetContext(), true, , TransformStopParents));
	AnimAction.Params.AnimName = 'HL_Transform_Stop';
}

//---------------------------------------------------------------------------//

static function Shadowbind_BuildVisualization_TileBump(
    XComGameState VisualizeGameState)
{
	local XComGameStateVisualizationMgr VisMgr;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local VisualizationActionMetadata ShadowMetaData;
    local VisualizationActionMetadata CosmeticUnitMetaData;
	local XComGameState_Unit ShadowUnit;
    local XComGameState_Unit ShadowbindTargetUnit;
    local XComGameState_Unit TargetUnitState;
    local XComGameState_Unit CosmeticUnit;
	local UnitValue ShadowUnitValue;
	local X2Effect_SpawnShadowbindUnit SpawnShadowEffect;
	local int j;
	local name SpawnShadowEffectResult;
	local X2Action_Fire SourceFire;
	local X2Action_MoveBegin SourceMoveBegin;
	local Actor SourceUnit;
	local array<X2Action> TransformStopParents;
	local VisualizationActionMetadata SourceMetaData;
    local VisualizationActionMetadata TargetMetaData;
	local X2Action_MoveTurn MoveTurnAction;
	local X2Action_PlayAnimation AddAnimAction;
    local X2Action_PlayAnimation AnimAction;
	local X2Action_ShadowbindTarget TargetShadowbind;
	local XComGameState_Item ItemState;
	local X2GremlinTemplate GremlinTemplate;
	local Array<X2Action> FoundNodes;
	local int ScanNodes;
	local X2Action_MarkerNamed JoinAction;

    // Start Issue %TB%
	TypicalAbility_BuildVisualization_TileBump(VisualizeGameState);
    // End Issue %TB%

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
    // Start Issue %TB%
    if (IsTileBump(Context))
    {
        return;
    }
    // End Issue %TB%

	TargetMetaData.StateObject_OldState = History.GetGameStateForObjectID(
        Context.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference,
        VisualizeGameState.HistoryIndex - 1);
	TargetMetaData.StateObject_NewState = VisualizeGameState
        .GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID);
	TargetMetaData.VisualizeActor = History.GetVisualizer(
        Context.InputContext.PrimaryTarget.ObjectID);
	TargetUnitState = XComGameState_Unit(TargetMetaData.StateObject_OldState);

	VisMgr.GetNodesOfType(VisMgr.BuildVisTree,
        class'X2Action_MarkerNamed', FoundNodes);
	for( ScanNodes = 0; ScanNodes < FoundNodes.Length; ++ScanNodes )
	{
		JoinAction = X2Action_MarkerNamed(FoundNodes[ScanNodes]);
		if( JoinAction.MarkerName == 'Join' )
		{
			break;
		}
	}

	// Find the Fire and MoveBegin for the Source
	SourceFire = X2Action_Fire(VisMgr.GetNodeOfType(VisMgr.BuildVisTree,
        class'X2Action_Fire', , Context.InputContext.SourceObject.ObjectID));
	SourceUnit = SourceFire.Metadata.VisualizeActor;

	SourceMoveBegin = X2Action_MoveBegin(VisMgr.GetNodeOfType(
        VisMgr.BuildVisTree, class'X2Action_MoveBegin', SourceUnit));

	// Find the Target's Shadowbind
	TargetShadowbind = X2Action_ShadowbindTarget(VisMgr.GetNodeOfType(
        VisMgr.BuildVisTree, class'X2Action_ShadowbindTarget', ,
        Context.InputContext.PrimaryTarget.ObjectID));

	SourceMetaData.StateObject_OldState = SourceFire
        .Metadata.StateObject_OldState;
	SourceMetaData.StateObject_NewState = SourceFire
        .Metadata.StateObject_NewState;
	SourceMetaData.VisualizeActor = SourceFire.Metadata.VisualizeActor;

	if (Context.InputContext.MovementPaths.Length > 0)
	{
		// If moving, need to set the facing and pre/post transforms
		MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static
            .AddToVisualizationTree(SourceMetaData, Context,
            true, , SourceFire.ParentActions));
		MoveTurnAction.m_vFacePoint = `XWORLD.GetPositionFromTileCoordinates(
            TargetUnitState.TileLocation);
		MoveTurnAction.ForceSetPawnRotation = true;

		VisMgr.ConnectAction(JoinAction, VisMgr.BuildVisTree,
            false, MoveTurnAction);

		TransformStopParents.AddItem(MoveTurnAction);

		SpectreMoveInsertTransform(VisualizeGameState, SourceMetaData,
            SourceMoveBegin.ParentActions, TransformStopParents);
	}

	// Line up the Source's Fire, Target's React, and Shadow's anim
	if( TargetShadowbind != None && TargetShadowbind
        .ParentActions.Length != 0 )
	{
		VisMgr.ConnectAction(JoinAction, VisMgr.BuildVisTree,
            false, , TargetShadowbind.ParentActions);
	}
	
	VisMgr.DisconnectAction(TargetShadowbind);
	VisMgr.ConnectAction(TargetShadowbind, VisMgr.BuildVisTree,
        false, , SourceFire.ParentActions);

	SpawnShadowEffectResult = 'AA_UnknownError';
	for (j = 0; j < Context.ResultContext.TargetEffectResults
        .Effects.Length; ++j)
	{
		SpawnShadowEffect = X2Effect_SpawnShadowbindUnit(Context
            .ResultContext.TargetEffectResults.Effects[j]);

		if (SpawnShadowEffect != none)
		{
			SpawnShadowEffectResult = Context.ResultContext
                .TargetEffectResults.ApplyResults[j];
			break;
		}
	}

	if (SpawnShadowEffectResult == 'AA_Success')
	{
		ShadowbindTargetUnit = XComGameState_Unit(VisualizeGameState
            .GetGameStateForObjectID(Context
            .InputContext.PrimaryTarget.ObjectID));
		`assert(ShadowbindTargetUnit != none);
		ShadowbindTargetUnit.GetUnitValue(class'X2Effect_SpawnUnit'.default
            .SpawnedUnitValueName, ShadowUnitValue);

		ShadowMetaData.StateObject_OldState = History
            .GetGameStateForObjectID(ShadowUnitValue.fValue,
            eReturnType_Reference, VisualizeGameState.HistoryIndex);
		ShadowMetaData.StateObject_NewState = ShadowMetaData
            .StateObject_OldState;
		ShadowUnit = XComGameState_Unit(ShadowMetaData.StateObject_NewState);
		`assert(ShadowUnit != none);
		ShadowMetaData.VisualizeActor = History
            .GetVisualizer(ShadowUnit.ObjectID);
		
		SpawnShadowEffect.AddSpawnVisualizationsToTracks(Context, ShadowUnit,
            ShadowMetaData, ShadowbindTargetUnit);

		AnimAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'
            .static.AddToVisualizationTree(ShadowMetaData, Context,
            true, TargetShadowbind));
		AnimAction.Params.AnimName = 'HL_Shadowbind_TargetShadow';
		AnimAction.Params.BlendTime = 0.0f;

		VisMgr.ConnectAction(JoinAction, VisMgr.BuildVisTree,
            false, AnimAction);

		AddAnimAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'
            .static.AddToVisualizationTree(ShadowMetaData, Context,
            false, TargetShadowbind));
		AddAnimAction.bFinishAnimationWait = false;
		AddAnimAction.Params.AnimName = 'ADD_HL_Shadowbind_FadeIn';
		AddAnimAction.Params.Additive = true;
		AddAnimAction.Params.BlendTime = 0.0f;

		VisMgr.ConnectAction(JoinAction, VisMgr.BuildVisTree,
            false, AddAnimAction);

		// Look for a gremlin that got copied
		ItemState = ShadowUnit.GetSecondaryWeapon();
		
		GremlinTemplate = X2GremlinTemplate(ItemState.GetMyTemplate());
		if( GremlinTemplate != none )
		{
			// This is a newly spawned unit so it should have its own gremlin
			CosmeticUnit = XComGameState_Unit(History.GetGameStateForObjectID(
                ItemState.CosmeticUnitRef.ObjectID));

			History.GetCurrentAndPreviousGameStatesForObjectID(CosmeticUnit
                .ObjectID, CosmeticUnitMetaData.StateObject_OldState,
                CosmeticUnitMetaData.StateObject_NewState, ,
                VisualizeGameState.HistoryIndex);
			CosmeticUnitMetaData.VisualizeActor = CosmeticUnit.GetVisualizer();

			AddAnimAction = X2Action_PlayAnimation(
                class'X2Action_PlayAnimation'.static.AddToVisualizationTree(
                CosmeticUnitMetaData, Context, false, TargetShadowbind));
			AddAnimAction.bFinishAnimationWait = false;
			AddAnimAction.Params.AnimName = 'ADD_HL_Shadowbind_FadeIn';
			AddAnimAction.Params.Additive = true;
			AddAnimAction.Params.BlendTime = 0.0f;

			VisMgr.ConnectAction(JoinAction, VisMgr.BuildVisTree,
                false, AddAnimAction);
		}
	}
}

//---------------------------------------------------------------------------//

static function TypicalAbility_BuildVisualization_TileBump(
    XComGameState VisualizeGameState)
{
    // general
    local XComGameStateHistory History;
    local XComGameStateVisualizationMgr VisualizationMgr;

    // visualizers
    local Actor TargetVisualizer;
    local Actor ShooterVisualizer;

    // actions
    local X2Action AddedAction;
    local X2Action FireAction;
    local X2Action_MoveTurn MoveTurnAction;
    local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
    local X2Action_ExitCover ExitCoverAction;
    local X2Action_MoveTeleport TeleportMoveAction;
    local X2Action_Delay MoveDelay;
    local X2Action_MoveEnd MoveEnd;
    local X2Action_MarkerNamed JoinActions;
    local array<X2Action> LeafNodes;
    local X2Action_WaitForAnotherAction WaitForFireAction;

    // state objects
    local XComGameState_Ability AbilityState;
    local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
    local XComGameState_WorldEffectTileData WorldDataUpdate;
    local XComGameState_InteractiveObject InteractiveObject;
    local XComGameState_BaseObject TargetStateObject;
    local XComGameState_Item SourceWeapon;
    local StateObjectReference ShootingUnitRef;

    // interfaces
    local X2VisualizerInterface TargetVisualizerInterface;
    local X2VisualizerInterface ShooterVisualizerInterface;

    // contexts
    local XComGameStateContext_Ability Context;
    local AbilityInputContext AbilityContext;

    // templates
    local X2AbilityTemplate AbilityTemplate;
    local X2AmmoTemplate AmmoTemplate;
    local X2WeaponTemplate WeaponTemplate;
    local array<X2Effect> MultiTargetEffects;

    // Tree metadata
    local VisualizationActionMetadata InitData;
    local VisualizationActionMetadata BuildData;
    local VisualizationActionMetadata SourceData;
    local VisualizationActionMetadata InterruptTrack;

    local XComGameState_Unit TargetUnitState;
    local name ApplyResult;

    // indices
    local int EffectIndex;
    local int TargetIndex;
    local int TrackIndex;
    local int WindowBreakTouchIndex;

    // flags
    local bool bSourceIsAlsoTarget;
    local bool bMultiSourceIsAlsoTarget;
    local bool bPlayedAttackResultNarrative;
    // Start Issue %TB%
    local bool bTileBump;
    // End Issue %TB%
            
    // good/bad determination
    local bool bGoodAbility;

    History = `XCOMHISTORY;
    VisualizationMgr = `XCOMVISUALIZATIONMGR;
    Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
    // Start Issue %TB%
    bTileBump = IsTileBump(Context);
    // End Issue %TB%
    AbilityContext = Context.InputContext;
    AbilityState = XComGameState_Ability(History
        .GetGameStateForObjectID(AbilityContext.AbilityRef.ObjectID));
    AbilityTemplate = class'XComGameState_Ability'.static
        .GetMyTemplateManager().FindAbilityTemplate(
        AbilityContext.AbilityTemplateName);
    ShootingUnitRef = Context.InputContext.SourceObject;

    //-----------------------------------------------------------------------//

    // Configure the visualization track for the shooter, part I. We split this
    // into two parts since in some situations the shooter can also be a target
    //-----------------------------------------------------------------------//
    ShooterVisualizer = History.GetVisualizer(ShootingUnitRef.ObjectID);
    ShooterVisualizerInterface = X2VisualizerInterface(ShooterVisualizer);

    SourceData = InitData;
    SourceData.StateObject_OldState = History.GetGameStateForObjectID(
        ShootingUnitRef.ObjectID, eReturnType_Reference,
        VisualizeGameState.HistoryIndex - 1);
    SourceData.StateObject_NewState = VisualizeGameState
        .GetGameStateForObjectID(ShootingUnitRef.ObjectID);
    if (SourceData.StateObject_NewState == none)
        SourceData.StateObject_NewState = SourceData.StateObject_OldState;
    SourceData.VisualizeActor = ShooterVisualizer;

    SourceWeapon = XComGameState_Item(History
        .GetGameStateForObjectID(AbilityContext.ItemObject.ObjectID));
    if (SourceWeapon != None)
    {
        WeaponTemplate = X2WeaponTemplate(SourceWeapon.GetMyTemplate());
        AmmoTemplate = X2AmmoTemplate(SourceWeapon
            .GetLoadedAmmoTemplate(AbilityState));
    }

    bGoodAbility = XComGameState_Unit(SourceData.StateObject_NewState)
        .IsFriendlyToLocalPlayer();

    if(Context.IsResultContextMiss()
        && AbilityTemplate.SourceMissSpeech != '')
    {
        SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(
            class'X2Action_PlaySoundAndFlyover'.static
            .AddToVisualizationTree(BuildData, Context));
        SoundAndFlyOver.SetSoundAndFlyOverParameters(
            None, "", AbilityTemplate.SourceMissSpeech,
            bGoodAbility ? eColor_Bad : eColor_Good);
    }
    else if(Context.IsResultContextHit()
        && AbilityTemplate.SourceHitSpeech != '')
    {
        SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(
            class'X2Action_PlaySoundAndFlyover'.static
            .AddToVisualizationTree(BuildData, Context));
        SoundAndFlyOver.SetSoundAndFlyOverParameters(
            None, "", AbilityTemplate.SourceHitSpeech,
            bGoodAbility ? eColor_Good : eColor_Bad);
    }

    if(!AbilityTemplate.bSkipFireAction
        || Context.InputContext.MovementPaths.Length > 0)
    {
        ExitCoverAction = X2Action_ExitCover(class'X2Action_ExitCover'
            .static.AddToVisualizationTree(SourceData, Context));
        ExitCoverAction.bSkipExitCoverVisualization = AbilityTemplate
            .bSkipExitCoverWhenFiring;

        // if this ability has a built in move,
        // do it right before we do the fire action
        if(Context.InputContext.MovementPaths.Length > 0)
        {
            // Start Issue %TB%
            if (bTileBump)
            {
                TruncatePathForTileBump(Context);
            }
            // End Issue %TB%
            // Note that we skip the stop animation since we'll be doing
            // our own stop with the end of move attack
            class'X2VisualizerHelpers'.static.ParsePath(
                Context, SourceData, AbilityTemplate.bSkipMoveStop);

            // Add paths for other units moving with us
            // (e.g., gremlins moving with a move + attack ability)
            if (Context.InputContext.MovementPaths.Length > 1)
            {
                for (TrackIndex = 1; TrackIndex < Context
                    .InputContext.MovementPaths.Length; ++TrackIndex)
                {
                    BuildData = InitData;
                    BuildData.StateObject_OldState = History
                        .GetGameStateForObjectID(Context.InputContext
                        .MovementPaths[TrackIndex].MovingUnitRef.ObjectID);
                    BuildData.StateObject_NewState = VisualizeGameState
                        .GetGameStateForObjectID(Context.InputContext
                        .MovementPaths[TrackIndex].MovingUnitRef.ObjectID);
                    MoveDelay = X2Action_Delay(class'X2Action_Delay'.static
                        .AddToVisualizationTree(BuildData, Context));
                    MoveDelay.Duration = class'X2Ability_DefaultAbilitySet'
                        .default.TypicalMoveDelay;
                    class'X2VisualizerHelpers'.static.ParsePath(
                        Context, BuildData, AbilityTemplate.bSkipMoveStop);
                }
            }

            if(!AbilityTemplate.bSkipFireAction)
            {
                MoveEnd = X2Action_MoveEnd(VisualizationMgr.GetNodeOfType
                    (VisualizationMgr.BuildVisTree, class'X2Action_MoveEnd',
                    SourceData.VisualizeActor));

                if (MoveEnd != none)
                {
                    // Add the fire action as a child of the node
                    // immediately prior to the move end
                    AddedAction = AbilityTemplate.ActionFireClass.static
                        .AddToVisualizationTree(SourceData, Context,
                        false, none, MoveEnd.ParentActions);

                    // Reconnect the move end action as a child of the
                    // fire action, as a special end of move animation
                    // will be performed for this move + attack ability
                    VisualizationMgr.DisconnectAction(MoveEnd);
                    VisualizationMgr.ConnectAction(MoveEnd,
                        VisualizationMgr.BuildVisTree, false, AddedAction);
                }
                else
                {
                    // See if this is a teleport
                    // If so, don't perform exit cover visuals
                    TeleportMoveAction = X2Action_MoveTeleport(
                        VisualizationMgr.GetNodeOfType(VisualizationMgr
                        .BuildVisTree, class'X2Action_MoveTeleport',
                        SourceData.VisualizeActor));
                    if (TeleportMoveAction != none)
                    {
                        // Skip the FOW Reveal (at the start of the path)
                        // Let the fire take care of it (end of the path)
                        ExitCoverAction.bSkipFOWReveal = true;
                    }

                    AddedAction = AbilityTemplate.ActionFireClass.static
                        .AddToVisualizationTree(SourceData, Context,
                        false, SourceData.LastActionAdded);
                }
            }
        }
        else
        {
            // If we were interrupted, insert a marker node for the
            // interrupting visualization code to use. In the move path version
            // above, it is expected for interrupts to be done during the move.
            if (Context.InterruptionStatus != eInterruptionStatus_None)
            {
                // Insert markers for the subsequent interrupt to insert into
                class'X2Action'.static.AddInterruptMarkerPair(
                    SourceData, Context, ExitCoverAction);
            }

            if (!AbilityTemplate.bSkipFireAction)
            {
                // No move, just add the fire action.
                // Parent is exit cover action if we have one
                AddedAction = AbilityTemplate.ActionFireClass.static
                    .AddToVisualizationTree(SourceData, Context,
                    false, SourceData.LastActionAdded);
            }
        }

        if( !AbilityTemplate.bSkipFireAction )
        {
            FireAction = AddedAction;

            class'XComGameState_NarrativeManager'.static
                .BuildVisualizationForDynamicNarrative(VisualizeGameState,
                false, 'AttackBegin', FireAction.ParentActions[0]);

            if( AbilityTemplate.AbilityToHitCalc != None )
            {
                X2Action_Fire(AddedAction).SetFireParameters(
                    Context.IsResultContextHit());
            }
        }
    }

    // If there are effects added to the shooter, add their visualizer actions
    for (EffectIndex = 0; EffectIndex < AbilityTemplate
        .AbilityShooterEffects.Length; ++EffectIndex)
    {
        AbilityTemplate.AbilityShooterEffects[EffectIndex]
            .AddX2ActionsForVisualization(VisualizeGameState,
            SourceData, Context.FindShooterEffectApplyResult(
            AbilityTemplate.AbilityShooterEffects[EffectIndex]));
    }
    //-----------------------------------------------------------------------//

    // Configure the visualization track for the target(s). This functionality
    // uses the context primarily since the game state may not include
    // state objects for misses.
    //-----------------------------------------------------------------------//
    // The shooter is the primary target
    bSourceIsAlsoTarget = AbilityContext.PrimaryTarget
        .ObjectID == AbilityContext.SourceObject.ObjectID;
    // There are effects to apply and there is a primary target
    if (AbilityTemplate.AbilityTargetEffects.Length > 0
        && AbilityContext.PrimaryTarget.ObjectID > 0)
    {
        TargetVisualizer = History.GetVisualizer(
            AbilityContext.PrimaryTarget.ObjectID);
        TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);

        if( bSourceIsAlsoTarget )
        {
            BuildData = SourceData;
        }
        else
        {
            // Interrupt track will either be empty or filled out correctly
            BuildData = InterruptTrack;
        }

        BuildData.VisualizeActor = TargetVisualizer;

        TargetStateObject = VisualizeGameState.GetGameStateForObjectID(
            AbilityContext.PrimaryTarget.ObjectID);
        if( TargetStateObject != none )
        {
            History.GetCurrentAndPreviousGameStatesForObjectID(
                AbilityContext.PrimaryTarget.ObjectID, 
                BuildData.StateObject_OldState,
                BuildData.StateObject_NewState,
                eReturnType_Reference,
                 VisualizeGameState.HistoryIndex);
            `assert(BuildData.StateObject_NewState == TargetStateObject);
        }
        else
        {
            // If TargetStateObject is none, it means that the visualize game
            // state does not contain an entry for the primary target. Use the
            // history version and show no change.
            BuildData.StateObject_OldState = History.GetGameStateForObjectID(
                AbilityContext.PrimaryTarget.ObjectID);
            BuildData.StateObject_NewState = BuildData.StateObject_OldState;
        }

        // if this is a melee attack, make sure the target is facing
        // the location he will be melee'd from
        if(!AbilityTemplate.bSkipFireAction 
            && !bSourceIsAlsoTarget 
            && AbilityContext.MovementPaths.Length > 0
            && AbilityContext.MovementPaths[0].MovementData.Length > 0
            && XGUnit(TargetVisualizer) != none)
        {
            MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static
                .AddToVisualizationTree(BuildData, Context,
                false, ExitCoverAction));
            MoveTurnAction.m_vFacePoint = AbilityContext.MovementPaths[0]
                .MovementData[AbilityContext.MovementPaths[0]
                .MovementData.Length - 1].Position;
            MoveTurnAction.m_vFacePoint.Z = TargetVisualizerInterface.GetTargetingFocusLocation().Z;
            MoveTurnAction.UpdateAimTarget = true;

            // Jwats: Add a wait for ability effect so the
            // idle state machine doesn't process!
            WaitForFireAction = X2Action_WaitForAnotherAction(
                class'X2Action_WaitForAnotherAction'.static
                .AddToVisualizationTree(BuildData, Context,
                false, MoveTurnAction));
            WaitForFireAction.ActionToWaitFor = FireAction;
        }

        // Pass in AddedAction (Fire Action) as the LastActionAdded if we
        // have one. Important! As this is automatically used as the parent
        // in the effect application sub functions below.
        if (AddedAction != none && AddedAction.IsA('X2Action_Fire'))
        {
            BuildData.LastActionAdded = AddedAction;
        }
        
        // Add any X2Actions that are specific to this effect being applied.
        // These actions would typically be instantaneous, showing UI world
        // messages playing any effect specific audio, starting effect
        // specific effects, etc. However, they can also potentially perform
        // animations on the track actor, so the design of effect actions must
        // consider how they will look/play in sequence with other effects.
        for (EffectIndex = 0; EffectIndex < AbilityTemplate
            .AbilityTargetEffects.Length; ++EffectIndex)
        {
            ApplyResult = Context.FindTargetEffectApplyResult(
                AbilityTemplate.AbilityTargetEffects[EffectIndex]);

            // Target effect visualization
            if( !Context.bSkipAdditionalVisualizationSteps )
            {
                AbilityTemplate.AbilityTargetEffects[EffectIndex]
                    .AddX2ActionsForVisualization(
                    VisualizeGameState, BuildData, ApplyResult);
            }

            // Source effect visualization
            AbilityTemplate.AbilityTargetEffects[EffectIndex]
                .AddX2ActionsForVisualizationSource(
                VisualizeGameState, SourceData, ApplyResult);
        }

        // the following is used to handle Rupture flyover text
        TargetUnitState = XComGameState_Unit(BuildData.StateObject_OldState);
        if (TargetUnitState != none &&
            XComGameState_Unit(BuildData.StateObject_OldState)
                .GetRupturedValue() == 0 &&
            XComGameState_Unit(BuildData.StateObject_NewState)
                .GetRupturedValue() > 0)
        {
            // this is the frame that we realized we've been ruptured!
            class 'X2StatusEffects'.static.RuptureVisualization(
                VisualizeGameState, BuildData);
        }

        if (AbilityTemplate.bAllowAmmoEffects && AmmoTemplate != None)
        {
            for (EffectIndex = 0; EffectIndex < AmmoTemplate
                .TargetEffects.Length; ++EffectIndex)
            {
                ApplyResult = Context.FindTargetEffectApplyResult(
                    AmmoTemplate.TargetEffects[EffectIndex]);
                AmmoTemplate.TargetEffects[EffectIndex]
                    .AddX2ActionsForVisualization(
                    VisualizeGameState, BuildData, ApplyResult);
                AmmoTemplate.TargetEffects[EffectIndex]
                    .AddX2ActionsForVisualizationSource(
                    VisualizeGameState, SourceData, ApplyResult);
            }
        }
        if (AbilityTemplate.bAllowBonusWeaponEffects && WeaponTemplate != none)
        {
            for (EffectIndex = 0; EffectIndex < WeaponTemplate
                .BonusWeaponEffects.Length; ++EffectIndex)
            {
                ApplyResult = Context.FindTargetEffectApplyResult(
                    WeaponTemplate.BonusWeaponEffects[EffectIndex]);
                WeaponTemplate.BonusWeaponEffects[EffectIndex]
                    .AddX2ActionsForVisualization(VisualizeGameState,
                    BuildData, ApplyResult);
                WeaponTemplate.BonusWeaponEffects[EffectIndex]
                    .AddX2ActionsForVisualizationSource(VisualizeGameState,
                    SourceData, ApplyResult);
            }
        }

        if (Context.IsResultContextMiss()
            && (AbilityTemplate.LocMissMessage != ""
                || AbilityTemplate.TargetMissSpeech != ''))
        {
            SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(
                class'X2Action_PlaySoundAndFlyover'.static
                .AddToVisualizationTree(BuildData, Context,
                false, BuildData.LastActionAdded));
            SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate
                .LocMissMessage, AbilityTemplate.TargetMissSpeech,
                bGoodAbility ? eColor_Bad : eColor_Good);
        }
        else if(Context.IsResultContextHit()
            && (AbilityTemplate.LocHitMessage != ""
                || AbilityTemplate.TargetHitSpeech != ''))
        {
            SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(
                class'X2Action_PlaySoundAndFlyover'.static
                .AddToVisualizationTree(BuildData, Context,
                false, BuildData.LastActionAdded));
            SoundAndFlyOver.SetSoundAndFlyOverParameters(None,
                AbilityTemplate.LocHitMessage,
                AbilityTemplate.TargetHitSpeech,
                bGoodAbility ? eColor_Good : eColor_Bad);
        }

        if (!bPlayedAttackResultNarrative)
        {
            class'XComGameState_NarrativeManager'.static
                .BuildVisualizationForDynamicNarrative(VisualizeGameState,
                false, 'AttackResult');
            bPlayedAttackResultNarrative = true;
        }

        if( TargetVisualizerInterface != none )
        {
            // Allow the visualizer to do any custom processing based on the
            // new game state. For example, units will create a death action
            // when they reach 0 HP.
            TargetVisualizerInterface.BuildAbilityEffectsVisualization(
                VisualizeGameState, BuildData);
        }

        if( bSourceIsAlsoTarget )
        {
            SourceData = BuildData;
        }
    }

    if (AbilityTemplate.bUseLaunchedGrenadeEffects)
    {
        MultiTargetEffects = X2GrenadeTemplate(SourceWeapon
            .GetLoadedAmmoTemplate(AbilityState)).LaunchedGrenadeEffects;
    }
    else if (AbilityTemplate.bUseThrownGrenadeEffects)
    {
        MultiTargetEffects = X2GrenadeTemplate(SourceWeapon.GetMyTemplate())
            .ThrownGrenadeEffects;
    }
    else
    {
        MultiTargetEffects = AbilityTemplate.AbilityMultiTargetEffects;
    }

    // Apply effects to multi targets - don't show multi effects for burst fire
    // as we just want the first time to visualize
    if( MultiTargetEffects.Length > 0 && AbilityContext.MultiTargets.Length > 0
        && X2AbilityMultiTarget_BurstFire(AbilityTemplate
        .AbilityMultiTargetStyle) == none)
    {
        for( TargetIndex = 0; TargetIndex < AbilityContext.MultiTargets.Length;
            ++TargetIndex )
        {
            bMultiSourceIsAlsoTarget = false;
            if( AbilityContext.MultiTargets[TargetIndex]
                .ObjectID == AbilityContext.SourceObject.ObjectID )
            {
                bMultiSourceIsAlsoTarget = true;
                bSourceIsAlsoTarget = bMultiSourceIsAlsoTarget;
            }

            TargetVisualizer = History.GetVisualizer(AbilityContext
                .MultiTargets[TargetIndex].ObjectID);
            TargetVisualizerInterface = X2VisualizerInterface(
                TargetVisualizer);

            if( bMultiSourceIsAlsoTarget )
            {
                BuildData = SourceData;
            }
            else
            {
                BuildData = InitData;
            }
            BuildData.VisualizeActor = TargetVisualizer;

            // If the ability involved a fire action and we don't have already
            // have a potential parent, all the target visualizations should
            // probably be parented to the fire action and not rely on the
            // auto placement.
            if ((BuildData.LastActionAdded == none) && (FireAction != none))
                BuildData.LastActionAdded = FireAction;

            TargetStateObject = VisualizeGameState.GetGameStateForObjectID(
                AbilityContext.MultiTargets[TargetIndex].ObjectID);
            if (TargetStateObject != none)
            {
                History.GetCurrentAndPreviousGameStatesForObjectID(
                    AbilityContext.MultiTargets[TargetIndex].ObjectID, 
                    BuildData.StateObject_OldState,
                    BuildData.StateObject_NewState,
                    eReturnType_Reference,
                    VisualizeGameState.HistoryIndex);
                `assert(BuildData.StateObject_NewState == TargetStateObject);
            }
            else
            {
                // If TargetStateObject is none, it means that the visualize
                // game state does not contain an entry for the primary target.
                // Use the history version and show no change.
                BuildData.StateObject_OldState = History
                    .GetGameStateForObjectID(AbilityContext
                    .MultiTargets[TargetIndex].ObjectID);
                BuildData.StateObject_NewState = BuildData
                    .StateObject_OldState;
            }

            // Add any X2Actions that are specific to this effect being
            // applied. These actions would typically be instantaneous,
            // showing UI world messages, playing any effect specific audio,
            // starting effect specific effects, etc. However, they can also
            // potentially perform animations on the track actor, so the
            // design of effect actions must consider how they will look/play
            // in sequence with other effects.
            for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length;
                ++EffectIndex)
            {
                ApplyResult = Context.FindMultiTargetEffectApplyResult(
                    MultiTargetEffects[EffectIndex], TargetIndex);

                // Target effect visualization
                MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(
                    VisualizeGameState, BuildData, ApplyResult);

                // Source effect visualization
                MultiTargetEffects[EffectIndex]
                    .AddX2ActionsForVisualizationSource(
                    VisualizeGameState, SourceData, ApplyResult);
            }

            // the following is used to handle Rupture flyover text
            TargetUnitState = XComGameState_Unit(
                BuildData.StateObject_OldState);
            if (TargetUnitState != none && 
                XComGameState_Unit(BuildData.StateObject_OldState)
                    .GetRupturedValue() == 0 &&
                XComGameState_Unit(BuildData.StateObject_NewState)
                    .GetRupturedValue() > 0)
            {
                // this is the frame that we realized we've been ruptured!
                class 'X2StatusEffects'.static
                    .RuptureVisualization(VisualizeGameState, BuildData);
            }
            
            if (!bPlayedAttackResultNarrative)
            {
                class'XComGameState_NarrativeManager'.static
                    .BuildVisualizationForDynamicNarrative(
                    VisualizeGameState, false, 'AttackResult');
                bPlayedAttackResultNarrative = true;
            }

            if( TargetVisualizerInterface != none )
            {
                // Allow the visualizer to do any custom processing based on
                // the new game state. For example, units will create a
                // death action when they reach 0 HP.
                TargetVisualizerInterface.BuildAbilityEffectsVisualization(
                    VisualizeGameState, BuildData);
            }

            if( bMultiSourceIsAlsoTarget )
            {
                SourceData = BuildData;
            }
        }
    }

    //-----------------------------------------------------------------------//

    // Finish adding the shooter's track
    //-----------------------------------------------------------------------//
    if( !bSourceIsAlsoTarget && ShooterVisualizerInterface != none)
    {
        ShooterVisualizerInterface
            .BuildAbilityEffectsVisualization(VisualizeGameState, SourceData);
    }

    // Handle redirect visualization
    TypicalAbility_AddEffectRedirects(VisualizeGameState, SourceData);

    //-----------------------------------------------------------------------//

    // Configure the visualization tracks for the environment
    //-----------------------------------------------------------------------//

    if (ExitCoverAction != none)
    {
        ExitCoverAction
            .ShouldBreakWindowBeforeFiring(Context, WindowBreakTouchIndex);
    }

    foreach VisualizeGameState.IterateByClassType(
        class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
    {
        BuildData = InitData;
        BuildData.VisualizeActor = none;
        BuildData.StateObject_NewState = EnvironmentDamageEvent;
        BuildData.StateObject_OldState = EnvironmentDamageEvent;

        // if this is the damage associated with the exit cover action, we need
        // to force the parenting within the tree otherwise LastActionAdded
        // will be 'none' and actions will auto-parent.
        if ((ExitCoverAction != none) && (WindowBreakTouchIndex > -1))
        {
            if (EnvironmentDamageEvent.HitLocation == AbilityContext
                .ProjectileEvents[WindowBreakTouchIndex].HitLocation)
            {
                BuildData.LastActionAdded = ExitCoverAction;
            }
        }

        for (EffectIndex = 0; EffectIndex < AbilityTemplate
            .AbilityShooterEffects.Length; ++EffectIndex)
        {
            AbilityTemplate.AbilityShooterEffects[EffectIndex]
                .AddX2ActionsForVisualization(VisualizeGameState,
                BuildData, 'AA_Success');
        }

        for (EffectIndex = 0; EffectIndex < AbilityTemplate
            .AbilityTargetEffects.Length; ++EffectIndex)
        {
            AbilityTemplate.AbilityTargetEffects[EffectIndex]
                .AddX2ActionsForVisualization(VisualizeGameState,
                BuildData, 'AA_Success');
        }

        for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length;
            ++EffectIndex)
        {
            MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(
                VisualizeGameState, BuildData, 'AA_Success');
        }
    }

    foreach VisualizeGameState.IterateByClassType(
        class'XComGameState_WorldEffectTileData', WorldDataUpdate)
    {
        BuildData = InitData;
        BuildData.VisualizeActor = none;
        BuildData.StateObject_NewState = WorldDataUpdate;
        BuildData.StateObject_OldState = WorldDataUpdate;

        for (EffectIndex = 0; EffectIndex < AbilityTemplate
            .AbilityShooterEffects.Length; ++EffectIndex)
        {
            AbilityTemplate.AbilityShooterEffects[EffectIndex]
                .AddX2ActionsForVisualization(VisualizeGameState,
                BuildData, 'AA_Success');
        }

        for (EffectIndex = 0; EffectIndex < AbilityTemplate
            .AbilityTargetEffects.Length; ++EffectIndex)
        {
            AbilityTemplate.AbilityTargetEffects[EffectIndex]
                .AddX2ActionsForVisualization(VisualizeGameState,
                BuildData, 'AA_Success');
        }

        for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length;
            ++EffectIndex)
        {
            MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(
                VisualizeGameState, BuildData, 'AA_Success');
        }
    }
    //-----------------------------------------------------------------------//

    // Process any interactions with interactive objects
    foreach VisualizeGameState.IterateByClassType(
        class'XComGameState_InteractiveObject', InteractiveObject)
    {
        // Add any doors that need to listen for notification. 
        // Move logic is taken from MoveAbility_BuildVisualization,
        // which only has special case handling for AI patrol movement
        // (which wouldn't happen here)
        if (Context.InputContext.MovementPaths.Length > 0
            || (InteractiveObject.IsDoor()
                && InteractiveObject.HasDestroyAnim()))  // Closed door?
        {
            BuildData = InitData;
            // Don't necessarily have a previous state,
            // so just use the one we know about
            BuildData.StateObject_OldState = InteractiveObject;
            BuildData.StateObject_NewState = InteractiveObject;
            BuildData.VisualizeActor = History
                .GetVisualizer(InteractiveObject.ObjectID);

            class'X2Action_BreakInteractActor'.static
                .AddToVisualizationTree(BuildData, Context);
        }
    }
    
    // Add a join so that all hit reactions and other actions will complete
    // before the visualization sequence moves on. In the case of
    // fire but no enter cover then we need to make sure to wait
    // for the fire since it isn't a leaf node
    VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, LeafNodes);

    if (!AbilityTemplate.bSkipFireAction)
    {
        if (!AbilityTemplate.bSkipExitCoverWhenFiring)
        {
            LeafNodes.AddItem(class'X2Action_EnterCover'.static
                .AddToVisualizationTree(SourceData, Context,
                false, FireAction));
        }
        else
        {
            LeafNodes.AddItem(FireAction);
        }
    }
    
    if (VisualizationMgr.BuildVisTree.ChildActions.Length > 0)
    {
        JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static
            .AddToVisualizationTree(SourceData, Context,
            false, none, LeafNodes));
        JoinActions.SetName("Join");
    }
}

//---------------------------------------------------------------------------//

defaultproperties
{
    uvForceLadderBlock="KMP01_ShouldBlockLadderWhileConcealed_UnitValue"

    AbilityName="ScanBeGone_Ability_KMP01"
    AbilitySource="eAbilitySource_Perk"
    eHostility=eHostility_Neutral
    eHudIconBehavior=eAbilityIconBehavior_NeverShow
    imgTemplateIcon="img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_mountainmist"

    bPurePassive=true
    bDisplayInUI=true
    bCrossClassEligible=false
}
