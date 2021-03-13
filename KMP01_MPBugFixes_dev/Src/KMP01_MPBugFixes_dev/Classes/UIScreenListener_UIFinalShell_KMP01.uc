/*                                                                             
 * FILE:     UIScreenListener_UIFinalShell_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * UISL for the Main Menu screen.
 * Display a warning when Developmental Functionality is enabled.
 *
 * Dependencies: X2ModConfig_KMP01.uc
 *
 * Based primarily on UIMainMenu_ScreenListener_PBNCE.uc by shiremct.
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class UIScreenListener_UIFinalShell_KMP01 extends UIScreenListener;

var localized string strMod_Version;

var localized string strMessage_Title;
var localized string strMessage_Header;
var localized string strMessage_Body;
var localized string strDismiss_Button;

//---------------------------------------------------------------------------//

var const bool bLog;
var const string imgWarning;
var privatewrite string strVersionText;

var const name uiVersionPanel;
var const name uiVersionFill;
var const bool bgTop;
var const bool bgBot;

var const name uiWarningPanel;
var const name uiWarningImage;
var const name uiWarningTitle;
var const name uiWarningHeader;
var const name uiWarningBody;
var const name uiWarningButton;

//---------------------------------------------------------------------------//

event OnInit(UIScreen Screen)
{
    `Log("OnInit", bLog, 'KMP01_UIFinalShell');
    CreatePanel_Version(Screen);

    if(ShouldShowWarningMsg())
    {
        `Log("Call CreatePanel", bLog, 'KMP01_UIFinalShell');
	    CreatePanel_ConfigWarning(Screen);
    }
}

//---------------------------------------------------------------------------//

private function CreatePanel_Version(UIScreen Screen)
{
    local UITextContainer VersionPanel;
    local UIBGBox VersionFill;
    local string strLoadedVersion;

    VersionPanel = Screen.Spawn(class'UITextContainer', Screen);
    if (strVersionText == "")
    {
        strLoadedVersion = (class'X2ModConfig_KMP01'.default.Unstable
            ? "Dev" : "Stable") @ class'X2ModConfig_KMP01'.default.Version;
        strVersionText = Repl(strMod_Version, "%ver", strLoadedVersion, true);
    }

    VersionFill = Screen.Spawn(class'UIBGBox', Screen);
    VersionFill.InitBG(uiVersionFill, 72, 248, 512, 42, eUIState_Normal);
    VersionFill.LibID = class'UIUtilities_Controls'.const.MC_X2BackgroundSimple;
    VersionFill.SetOutline(bgBot, class'UIUtilities_Colors'
        .const.FADED_HTML_COLOR);
    VersionFill.bHighlightOnMouseEvent = false;
    VersionFill.SetAlpha(80);

    VersionPanel.InitTextContainer(uiVersionPanel, , 72, 248, 512, 42,
        true, class'UIUtilities_Controls'.const.MC_X2BackgroundSimple);

    VersionPanel.text.OnTextSizeRealized = OnVersionTextSizeRealized;
    VersionFill.Show();

    VersionPanel.SetText(class'UIUtilities_Text'.static
        .GetColoredText(strVersionText, eUIState_Normal, 20));
    
    // class'UIUtilities_Text'.static.GetColoredText(strVersionText, eUIState_TheLost, 20)
    // class'UIUtilities_Text'.static.StyleText(strVersionText, eUITextStyle_Tooltip_H2, eUIState_Normal)

    `Log("TextSizeRealized =" @ VersionPanel.text.TextSizeRealized, bLog, 'KMP01_UIFinalShell');
    

    VersionPanel.bg.SetOutline(bgTop, class'UIUtilities_Colors'
        .const.BLACK_HTML_COLOR);
    VersionPanel.bg.ProcessMouseEvents(OnVersionBGMouseEvent);
    VersionPanel.bg.SetAlpha(54);

    VersionPanel.text.SetPosition(14, 6);
}

//---------------------------------------------------------------------------//

function OnVersionTextSizeRealized()
{
    local UITextContainer Panel;
    local UIScreen Screen;
    local UIBGBox Fill;

    local int NewWidth;
    local int NewHeight;

    `Log("OnVersionTextSizeRealized", bLog, 'KMP01_UIFinalShell');

    Screen = `PRESBASE.ScreenStack.GetScreen(class'UIFinalShell');
    if (Screen == none)
    {
        `Log("Screen == none", bLog, 'KMP01_UIFinalShell');
        return;
    }

    Panel = UITextContainer(Screen.GetChildByName(uiVersionPanel));
    if (Panel == none || Panel.text.bIsVisible)
    {
        return;
    }

    Fill = UIBGBox(Screen.GetChildByName(uiVersionFill));
    if (Fill == none)
    {
        `Log("Fill == none", bLog, 'KMP01_UIFinalShell');
        return;
    }
    `Log("Text Width:" @ Panel.text.Width
        @ "Height:" @ Panel.text.Height
        @ "Size Realized:" @ Panel.text.TextSizeRealized,
        bLog, 'KMP01_UIFinalShell');

    NewWidth = Panel.text.Width + (bool(Panel.text.Width % 2) ? 34 : 33);
    NewHeight = Panel.bg.Height + 4;
    Fill.SetSize(NewWidth, NewHeight);
    Fill.AnchorTopRight();
    Fill.OriginTopRight();
    Fill.SetPosition(-20, 38);
    Panel.bg.SetSize(NewWidth - 4, NewHeight - 4);
    Panel.SetSize(Panel.bg.Width, Panel.bg.Height);
    Panel.AnchorTopRight();
    Panel.SetPosition(Fill.X - Fill.Width + 2, Fill.Y + 2);
    Panel.text.Show();
}

//---------------------------------------------------------------------------//

final function OnVersionBGMouseEvent(UIPanel Panel, int cmd)
{
    local UIBGBox bg;

    bg = UIBGBox(Panel);
    if (bg == none)
    {
        return;
    }
    
    switch (cmd)
    {
        case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
            OnVersionPanelClicked(bg);
            break;
        case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
        case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
            bg.OnReceiveFocus();
            UpdateBGStyle(bg);
            break;
        case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
        case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
        case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
            bg.OnLoseFocus();
            UpdateBGStyle(bg);
            break;
    }
}

//---------------------------------------------------------------------------//

final function UpdateBGStyle(UIBGBox bg)
{
    local UITextContainer Panel;
    local UIBGBox Fill;

    Panel = UITextContainer(bg.GetParent(class'UITextContainer'));
    Fill = UIBGBox(Panel.GetParent(class'UIFinalShell').GetChildByName(uiVersionFill));

    if (bg.bIsFocused)
    {
        Fill.SetOutline(bgBot, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
        bg.SetOutline(bgTop, class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR);
        bg.SetAlpha(66);
        Fill.SetAlpha(100);
        Panel.SetText(class'UIUtilities_Text'.static.GetColoredText(
            strVersionText, , 20));
    }
    else
    {
        Fill.SetOutline(bgBot, class'UIUtilities_Colors'.const.FADED_HTML_COLOR);
        bg.SetOutline(bgTop, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
        bg.SetAlpha(54);
        Fill.SetAlpha(80);
        Panel.SetText(class'UIUtilities_Text'.static.GetColoredText(
            strVersionText, eUIState_Normal, 20));
    }
}

//---------------------------------------------------------------------------//

final function OnVersionPanelClicked(UIBGBox bg)
{
    local TDialogueBoxData DialogData;
    
    bg.OnLoseFocus();

    DialogData = GetOnlinePlayPermissionDialogBoxData();
    DialogData.strImagePath = imgWarning;
    DialogData.fnCallback = WarningDialogCallbackFn;
    `PRESBASE.UIRaiseDialog(DialogData);
}

//---------------------------------------------------------------------------//

final function WarningDialogCallbackFn(name eAction)
{
    local UIScreen Screen;
    local UIImage Img;

    if (eAction == 'eUIAction_Accept')
    {
        Screen = `PRESBASE.ScreenStack.GetScreen(class'UIFinalShell');
        Img = UIImage(Screen.GetChildByName('KMP01_WarningDialogImg'));
        if (Img != none)
        {
            Img.Remove();
        }
    }
}

//---------------------------------------------------------------------------//

final function TDialogueBoxData GetOnlinePlayPermissionDialogBoxData()
{
	local TDialogueBoxData kDialogBoxData;
    local WorldInfo CurrentWorldInfo;

    CurrentWorldInfo = `XWORLDINFO;

	if( CurrentWorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_XBOX_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_XBOX_Text;
	}
	else if( CurrentWorldInfo.IsConsoleBuild(CONSOLE_PS3) )
	{
		kDialogBoxData.strTitle = "";
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_PS3_Text;
	}
	else
	{	
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_Default_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_Default_Text;
	}
	kDialogBoxData.strAccept = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_ButtonText;
	kDialogBoxData.strCancel = "";
	kDialogBoxData.eType = eDialog_Warning;

	return kDialogBoxData;
}

//---------------------------------------------------------------------------//

private function CreatePanel_ConfigWarning(UIScreen Screen)
{
    local UIBGBox         WarningPanelBG;
    local UIImage         WarningImage;
    local UIX2PanelHeader WarningTitle;
    local UITextContainer WarningHeader;
    local UITextContainer WarningBody;
    local UIButton        DismissButton;
    
    local int Width;
    local int Height;

    local int Left;
    local int Right;
    local int xCenter;

    local int Top;
    local int Bot;
    local int yCenter;

    `Log("CreatePanel_ConfigWarning", bLog, 'KMP01_UIFinalShell');
    
    Width = 768;
    Height = 320;

    Left = 960 - Width/2;
    Right = Left + Width;
    xCenter = Left + Width/2;

    Top = 540 - Height/2;
    Bot = Top + Height;
    yCenter = Top + Height/2;

    `Log("Dimensions:" @ "W:" $ Width @ "H:" $ Height
        @ "L:" $ Left @ "R:" $ Right @ "C:" $ xCenter
        @ "T:" $ Top @ "B:" $ Bot @ "M:" $ yCenter,
        bLog, 'KMP01_UIFinalShell');

    // Warning Panel
    WarningPanelBG = Screen.Spawn(class'UIBGBox', Screen);
    WarningPanelBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
    WarningPanelBG.InitBG(uiWarningPanel, Left, Top, Width, Height);
    
    // Warning Image
    WarningImage = Screen.Spawn(class'UIImage', Screen);
    WarningImage.InitImage(uiWarningImage, default.imgWarning);
    WarningImage.OriginTopRight();
    WarningImage.SetPosition(Right + 20, Top + 20);
    
    // Warning Title
    WarningTitle = Screen.Spawn(class'UIX2PanelHeader', Screen);
    WarningTitle.InitPanelHeader(uiWarningTitle, class'UIUtilities_Text'
        .static.GetColoredText(strMessage_Title, eUIState_Bad, 32), "");
    WarningTitle.SetPosition(Left + 10, Top + 10);
    WarningTitle.SetHeaderWidth(Width - 20);

    // Warning Header
    WarningHeader = Screen.Spawn(class'UITextContainer', Screen);
    WarningHeader.InitTextContainer(uiWarningHeader, ,
        Left + 20, Top + 60, Width - 40, 30, , , true);
    WarningHeader.Text.SetHTMLText(class'UIUtilities_Text'.static.StyleText(
        strMessage_Header, eUITextStyle_Tooltip_H1, eUIState_Warning2));
	
    // Warning Body
    WarningBody = Screen.Spawn(class'UITextContainer', Screen);
    WarningBody.InitTextContainer(uiWarningBody, ,
        Left + 20, Top + 90, Width - 40, Height - 100, , , true);
    WarningBody.Text.SetHTMLText(class'UIUtilities_Text'.static.StyleText(
        strMessage_Body, eUITextStyle_Tooltip_Body, eUIState_Normal));                  
    
    // Dismiss Button
    DismissButton = Screen.Spawn(class'UIButton', Screen);
    DismissButton.InitButton(uiWarningButton, strDismiss_Button,
        DismissButtonHandler, , 'XComButton');
    DismissButton.SetResizeToText(false);
    DismissButton.SetSize(96, 30);
    DismissButton.SetPosition(xCenter - 48, Bot - 54);
}

//---------------------------------------------------------------------------//

private function DismissButtonHandler(UIButton Button)
{
    local UIScreen Screen;

    Screen = UIScreen(Button.GetParent(class'UIFinalShell'));

    Screen.GetChildByName(uiWarningPanel).Remove();
    Screen.GetChildByName(uiWarningImage).Remove();
    Screen.GetChildByName(uiWarningTitle).Remove();
    Screen.GetChildByName(uiWarningHeader).Remove();
    Screen.GetChildByName(uiWarningBody).Remove();

    Button.Remove();
}

//---------------------------------------------------------------------------//

private function bool ShouldShowWarningMsg()
{
    `Log("ShouldShowWarningMessage", bLog, 'KMP01_UIFinalShell');
    if (class'X2ModConfig_KMP01'.default.Unstable)
    {
        `Log("Return True", bLog, 'KMP01_UIFinalShell');
        return true; 
    }
    `Log("Return False", bLog, 'KMP01_UIFinalShell');
    return false;
}

//---------------------------------------------------------------------------//

defaultproperties
{
    bLog=true
    ScreenClass=UIFinalShell

    uiVersionPanel="KMP01_VersionPanel"
    uiVersionFill="KMP01_VersionFillBG"
    bgBot=true
    bgTop=false

    uiWarningPanel="KMP01_WarningPanelBG"
    uiWarningImage="KMP01_WarningImage"
    uiWarningTitle="KMP01_WarningTitle"
    uiWarningHeader="KMP01_WarningHeader"
    uiWarningBody="KMP01_WarningBody"
    uiWarningButton="KMP01_WarningButton"

    imgWarning="UILibrary_StrategyImages.ScienceIcons.IC_AutopsyCyberdisc"
}
