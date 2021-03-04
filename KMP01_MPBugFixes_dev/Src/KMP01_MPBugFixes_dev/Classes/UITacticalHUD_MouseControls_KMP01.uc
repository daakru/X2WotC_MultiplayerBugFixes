/*                                                                             
 * FILE:     UITacticalHUD_MouseControls_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01 v0.1
 *
 * MCO of UITacticalHUD_MouseControls.uc to add custom commander abilities.
 *
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class UITacticalHUD_MouseControls_KMP01
    extends UITacticalHUD_MouseControls
    config(Game);

var localized string BUTTON_TOOLTIP_TEXT;
var localized string BUTTON_TOOLTIP_CHOSEN;

//---------------------------------------------------------------------------//

var bool bDeepLog;

///var LWCommandRange_Actor CRActor, CRTemplate;
var UIIcon OfficerIcon;
var UIIcon ChosenIcon;
var UIButton TestButton;
//var bool CRToggleOn;
var protected int IconCount;

var private const config int XOffset;
var private const config int YOffset;
var private const config float ResFactor;
var private const config int DebugOffset;

var protected string ChosenCmdrPerkIcon;
var protected string LWOfficerCmdrPerkIcon;

//---------------------------------------------------------------------------//

simulated function UpdateControls()
{
	local string key, label;
	local PlayerInput kInput;
	local XComKeybindingData kKeyData;
	local int i;
	local TacticalBindableCommands command;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_Unit ChosenUnit;
    local int bChosenActive;
    local int NumActiveControls;
	
	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History
        .GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	kInput = PC.PlayerInput;
	kKeyData = Movie.Pres.m_kKeybindingData;

	AS_SetHoverHelp("");

	if(UITacticalHUD(screen).m_isMenuRaised)
	{
		SetNumActiveControls(1);

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(
            kInput, eGBC_Cancel, eKC_General);
		SetButtonItem(m_optCancelShot,
            m_strCancelShot,
            key != "" ? key : m_strNoKeyBoundString,
            ButtonItems[0].UIState);

		if (OfficerIcon != none)
        {
			OfficerIcon.Hide();
        }
        if (ChosenIcon != none)
        {
            ChosenIcon.Hide();
        }
	}
	else
	{
		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(
            kInput, eTBC_EndTurn);
		SetButtonItem(m_optEndTurn,
            m_strEndTurn,
            key != "" ? key : m_strNoKeyBoundString,
            ButtonItems[m_optEndTurn].UIState);

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(
            kInput, eTBC_PrevUnit);
		SetButtonItem(m_optPrevSoldier,
            m_strPrevSoldier,
            key != "" ? key : m_strNoKeyBoundString,
            ButtonItems[m_optPrevSoldier].UIState);

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(
            kInput, eTBC_NextUnit);
		SetButtonItem(m_optNextSoldier,
            m_strNextSoldier,
            key != "" ? key : m_strNoKeyBoundString,
            ButtonItems[m_optNextSoldier].UIState);

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(
            kInput, eTBC_CamRotateLeft);
		label = kKeyData.GetTacticalBindableActionLabel(eTBC_CamRotateLeft);
		SetButtonItem(m_optRotateCameraLeft,
            label,
            key != "" ? key : m_strNoKeyBoundString,
            ButtonItems[m_optRotateCameraLeft].UIState);

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(
            kInput, eTBC_CamRotateRight);
		label = kKeyData.GetTacticalBindableActionLabel(
            eTBC_CamRotateRight);
		SetButtonItem(m_optRotateCameraRight,
            label,
            key != "" ? key : m_strNoKeyBoundString,
            ButtonItems[m_optRotateCameraRight].UIState);

		for(i = 0; i < CommandAbilities.Length; i++)
		{
			command = TacticalBindableCommands(eTBC_CommandAbility1 + i);
			AbilityState = XComGameState_Ability(`XCOMHISTORY
                .GetGameStateForObjectID(CommandAbilities[i]
                .AbilityObjectRef.ObjectID));
			key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(
                kInput, command);
			label = Caps(AbilityState.GetMyFriendlyName());
			SetButtonItem( m_optCallSkyranger + i,
                label,
                key != "" ? key : m_strNoKeyBoundString,
                ButtonItems[m_optCallSkyranger + i].UIState,
                BattleData.IsAbilityObjectiveHighlighted(
                    AbilityState.GetMyTemplate()));
		}
        
        ChosenUnit = class'XComGameState_Unit'.static.GetActivatedChosen();
        if (ChosenUnit != none)
        {
            bChosenActive = 1;
        }
        NumActiveControls = 5 + CommandAbilities.Length;// + bChosenActive;
        /*
        kLog("i:" @ i @ "| NumActiveControls:" @ NumActiveControls,
            true, bDeepLog);

        for (i = i + 5; i < NumActiveControls; i++)
        {
            kLog("i:" @ i @ "| NumActiveControls:" @ NumActiveControls,
                true, bDeepLog);
            command = TacticalBindableCommands(eTBC_CommandAbility1 + i);
            AbilityState = new class'XComGameState_Ability';
            key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(
                kInput, command);
            label = Caps("Custom Ability Test");
            SetButtonItem( m_optCallSkyranger + i,    label,
                key != "" ? key : m_strNoKeyBoundString,
                ButtonItems[m_optCallSkyranger + i].UIState,
                BattleData.IsAbilityObjectiveHighlighted(
                AbilityState.GetMyTemplate()));
        }
        */
		if (True) //class'LWOfficerUtilities'.static.HasOfficerInSquad())
		{
			if (OfficerIcon != none)
            {
				OfficerIcon.Show();
			}
            else
            {
                //kLog("Icon X Position:" @ ( int(Movie.UI_RES_X * ResFactor)
                //    * (bChosenActive - (NumActiveControls + 1)) ) + XOffset,
                //    true, bDeepLog);
                //kLog("X Resolution:" @ Movie.UI_RES_X,
                //    true, bDeepLog);
                
				AddCustomCommanderIcon(OfficerIcon,
                    ( int(Movie.UI_RES_X * ResFactor)
                    * (-(NumActiveControls + 1 + DebugOffset)) ) + XOffset,
                    YOffset,
                    Caps(BUTTON_TOOLTIP_TEXT), LWOfficerCmdrPerkIcon,
                    OnChildMouseEvent_CustomCmdr);
                //AddCustomCommanderIcon(OfficerIcon, XOffset - 400,
                //    YOffset, OnChildMouseEvent_CustomCmdr);

                //(Movie.UI_RES_X * 0.0078) + (Movie.UI_RES_X * 0.0222
                //    * (bChosenActive - (NumActiveControls + 1))), 4);
				//(29 * (bChosenActive - (NumActiveControls + 1)))
            }
		}
        // add "phantom" control to leave space for Command Range icon
		SetNumActiveControls(NumActiveControls);
        // Show the "Chosen Info" button if the chosen is active on a map
		if (bool(bChosenActive))
		{
            if (ChosenIcon != none)
            {
                ChosenIcon.Show();
            }
            else
            {
                key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(
                    kInput, eTBC_OpenChosenHUD);
                AddCustomCommanderIcon(ChosenIcon,
                    ( int(Movie.UI_RES_X * ResFactor)
                    * (-(NumActiveControls + 2 + DebugOffset)) ) + XOffset,
                    YOffset,
                    Caps(Repl(BUTTON_TOOLTIP_CHOSEN, "%key", key, true)),
                    ChosenCmdrPerkIcon, OnChildMouseEvent_CustomCmdr);
                //AddCustomCommanderIcon(ChosenIcon, XOffset - 500,
                //    YOffset, OnChildMouseEvent_CustomCmdr);
            }
            //m_optChosenInfo = NumActiveControls;
			//key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(
            //    kInput, eTBC_OpenChosenHUD);
			//label = kKeyData.GetTacticalBindableActionLabel(
            //    eTBC_OpenChosenHUD);
			//SetButtonItem(m_optChosenInfo, label, key != "" ? key
            //    : m_strNoKeyBoundString,
            //    ButtonItems[m_optChosenInfo].UIState);
		}
        /*
        if (TestButton != none)
        {
            TestButton.Show();
        }
        else
        {
            AddCustomCommanderButton(TestButton,
                ( int(Movie.UI_RES_X * ResFactor)
                * (-(NumActiveControls + 4 + DebugOffset)) ) + XOffset,
                YOffset, LWOfficerCmdrPerkIcon, OnClickedTestButton);
        }
        */
	}
}

//---------------------------------------------------------------------------//

function AddCustomCommanderIcon(
    out UIIcon CmdrIcon,
    float newX,
    float newY,
    string TooltipText,
    string Icon,
    delegate<OnMouseEventDelegate> MouseEventDelegate)
{
    local UIToolTip ToolTip;

    IconCount += 1;
	CmdrIcon = Spawn(class'UIIcon', self).InitIcon(
        name("abilityIcon" $ IconCount $ "MC"), Icon, false, true, 36);
	CmdrIcon.ProcessMouseEvents(MouseEventDelegate);
	CmdrIcon.bDisableSelectionBrackets = true;
    if (CmdrIcon == ChosenIcon)
    {
        CmdrIcon.EnableMouseAutomaticColor(
        class'UIUtilities_Colors'.const.BAD_HTML_COLOR,
        class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
    }
    else
    {
	    CmdrIcon.EnableMouseAutomaticColor(
            class'UIUtilities_Colors'.const.GOOD_HTML_COLOR,
            class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
    }

	CmdrIcon.SetToolTipText(
        class'UIUtilities_Text'.static.GetSizedText(TooltipText, 20),
        "",
        1937, 50,
        false,
        class'UIUtilities'.const.ANCHOR_TOP_RIGHT,
        false,
        0.0);
	
    ToolTip = (Movie.Pres.m_kTooltipMgr
        .GetTooltipByID(CmdrIcon.CachedTooltipId));
    ToolTip.SetAlpha(50);
    ToolTip.SetHeight(200); //31
    //ToolTip.AnimateX(1924);

    CmdrIcon.SetTooltip(ToolTip);

	CmdrIcon.OriginTopRight();
	CmdrIcon.AnchorTopRight();
	CmdrIcon.SetPosition(newX, newY);
	CmdrIcon.Show();
}

//---------------------------------------------------------------------------//

function AddCustomCommanderButton(
    out UIButton CmdrButton,
    float newX,
    float newY,
    string Icon,
    delegate<UIButton.OnClickedDelegate> ClickedDelegate)
{
    IconCount += 1;
	CmdrButton = Spawn(class'UIButton', self).InitButton(
        name("abilityButton" $ IconCount $ "MC"),
        class'UIUtilities_Text'.static.InjectImage(Icon),
        ClickedDelegate,
        eUIButtonStyle_HOTLINK_BUTTON);

	CmdrButton.OriginTopRight();
	CmdrButton.AnchorTopRight();
	CmdrButton.SetPosition(newX, newY);
	CmdrButton.Show();
}

//---------------------------------------------------------------------------//

function OnClickedTestButton(UIButton Button)
{
    kLog("OnClickedTestButton", true, bDeepLog);
}

//---------------------------------------------------------------------------//

function OnChildMouseEvent_CustomCmdr(UIPanel ChildControl, int cmd)
{
    switch (ChildControl)
    {
        case OfficerIcon:
            //kLog("Child Control is OfficerIcon", true, bDeepLog);
            if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		    {
			    OnClicked_OfficerIcon();
			    //Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
			    //if (CRToggleOn)
				    //PlaySound( SoundCue'SoundUI.GhostArmorOffCue',
                    //    true , true );
			    //else
				    //PlaySound( SoundCue'SoundUI.GhostArmorOnCue',
                    //    true , true );
		    }
		    else if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN)
		    {
			    OfficerIcon.OnReceiveFocus();
		    }
		    else if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT
                || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT)
		    {
			    OfficerIcon.OnLoseFocus();
		    }
            break;
        case ChosenIcon:
            //kLog("Child Control is ChosenIcon", true, bDeepLog);
            if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		    {
			    OnClicked_ChosenIcon();
			    //Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
			    //if (CRToggleOn)
				    //PlaySound( SoundCue'SoundUI.GhostArmorOffCue',
                    //    true , true );
			    //else
				    //PlaySound( SoundCue'SoundUI.GhostArmorOnCue',
                    //    true , true );
		    }
		    else if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN)
		    {
			    ChosenIcon.OnReceiveFocus();
		    }
		    else if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT
                || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT)
		    {
			    ChosenIcon.OnLoseFocus();
		    }
            break;
        default:
            kRed("Child Control does not match any known"
                @ "Custom Commander UIIcon", false);
            kLog("Warning: Redscreen: Child Control does not match any known"
                @ "Custom Commander UIIcon",
                true, bDeepLog);
            break;
    }
}

//---------------------------------------------------------------------------//

function OnClicked_OfficerIcon()
{
    //local X2Camera Camera;
    local XComCamera GameCamera;
    local X2CameraStack CameraStack;
    local Vector NewLocation;
    local TPOV NewPOV;
    local float DeltaTime;

    kLog("OnClicked_OfficerIcon",
        true, bDeepLog);
    //class'WorldInfo'.static.GetWorldInfo().ConsoleCommand("exit");
    // reset the camera (based on the cursor) on the active unit
    /*
	`Cursor.MoveToUnit(XComTacticalController(PC).GetActiveUnitPawn());
	`Cursor.m_bCustomAllowCursorMovement = false;
	`Cursor.m_bAllowCursorAscensionAndDescension = false;
    */
    CameraStack = `CAMERASTACK;
    //Camera = CameraStack.FindCameraWithTag(
    //    X2Camera(PC.PlayerCamera).CameraTag);
    NewLocation = XGUnit(XComTacticalController(PC).GetActiveUnitPawn()
        .GetGameUnit()).Location;
    GameCamera = XComPresentationLayer(Movie.Pres).GetCamera();
    NewPOV.Rotation = GameCamera.GetCameraRotation();
    NewPOV.FOV = GameCamera.GetFOVAngle();
    NewPOV.Location = NewLocation;
    DeltaTime = PC.PlayerInput.CurrentDeltaTime;
    kLog("NewLocation(x, y, z):      (" $ NewLocation.X
                                        $ "," @ NewLocation.Y
                                        $ "," @ NewLocation.Z $ ")\n    "
        $ "NewPOV.Location(x, y, z): (" $ NewPOV.Location.X
                                        $ "," @ NewPOV.Location.Y
                                        $ "," @ NewPOV.Location.Z $ ")\n    "
        $ "DeltaTime:" @ DeltaTime,
        true, bDeepLog);
    kLog("Running EXEC.LogCamPOV",
        true, bDeepLog);
    class'WorldInfo'.static.GetWorldInfo().ConsoleCommand("LogCamPOV");
    kLog("Running CameraStack.DEBUGPrintCameraStack()",
        true, bDeepLog);
    CameraStack.DEBUGPrintCameraStack();
    kLog("Running EXEC.PrintCameraStack()",
        true, bDeepLog);
    class'WorldInfo'.static.GetWorldInfo().ConsoleCommand("PrintCameraStack");
    //GameCamera.ApplyCameraModifiers(DeltaTime, NewPOV);
}

//---------------------------------------------------------------------------//

function OnClicked_ChosenIcon()
{
    kLog("OnClicked_ChosenIcon",
        true, bDeepLog);

    `PRES.UIChosenRevealScreen();
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

    IconCount=0
    ChosenCmdrPerkIcon="img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_chosendazed"
    LWOfficerCmdrPerkIcon="img:///UILibrary_LW_OfficerPack.LWOfficers_Generic"
}
