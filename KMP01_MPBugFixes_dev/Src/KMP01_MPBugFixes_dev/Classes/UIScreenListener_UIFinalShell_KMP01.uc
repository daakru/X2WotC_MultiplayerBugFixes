/*                                                                             
 * FILE:     UIScreenListener_UIFinalShell_KMP01.uc
 * AUTHOR:   Kinetos#6935, https://steamcommunity.com/id/kinetos/
 * VERSION:  KMP01
 *
 * UISL for the Main Menu screen.
 * Display a warning when Developmental Functionality is enabled.
 *
 * Based primarily on UIMainMenu_ScreenListener_PBNCE.uc by shiremct.
 * Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 */

class UIScreenListener_UIFinalShell_KMP01 extends UIScreenListener
    config(Game);

var localized string strMessage_Title;
var localized string strMessage_Header;
var localized string strMessage_Body;
var localized string strDismiss_Button;

//---------------------------------------------------------------------------//

var UIBGBox         WarningPanelBG;
var UIPanel         WarningPanel;
var UIImage         WarningImage;
var UIX2PanelHeader WarningTitle;
var UITextContainer WarningHeader;
var UITextContainer WarningBody;
var UIButton        DismissButton;

var string          imgWarning;

//---------------------------------------------------------------------------//

event OnInit(UIScreen Screen)
{
    if(ShouldShowWarningMsg())
    {
	    CreatePanel_ConfigWarning(Screen);
    }
}

//---------------------------------------------------------------------------//

private function CreatePanel_ConfigWarning(UIScreen Screen)
{
    // Warning Panel
    WarningPanelBG = Screen.Spawn(class'UIBGBox', Screen);
    WarningPanelBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
    WarningPanelBG.InitBG('ConfigPopup_BG', 500, 300, 800, 420);  // X, Y, H, W

    WarningPanel = Screen.Spawn(class'UIPanel', Screen);
    WarningPanel.InitPanel('ConfigPopup');
    WarningPanel.SetSize(WarningPanelBG.Width, WarningPanelBG.Height);
    WarningPanel.SetPosition(WarningPanelBG.X, WarningPanelBG.Y);

    // Warning Image
    WarningImage = Screen.Spawn(class'UIImage', Screen);
    WarningImage.InitImage('KMP01_WarningImage', default.imgWarning);
    //WarningImage.SetScale(1.0);
    WarningImage.SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
    WarningImage.SetPosition(WarningPanelBG.X + WarningPanelBG.Width,
                             WarningPanelBG.Y + 20);

    // Warning Title
    WarningTitle = Screen.Spawn(class'UIX2PanelHeader', WarningPanel);
    WarningTitle.InitPanelHeader('', class'UIUtilities_Text'.static
        .GetColoredText(strMessage_Title, eUIState_Bad, 32), "");
    WarningTitle.SetPosition(WarningTitle.X + 10, WarningTitle.Y + 10);
    WarningTitle.SetHeaderWidth(WarningPanel.Width - 20);

    // Warning Header
    WarningHeader = Screen.Spawn(class'UITextContainer', WarningPanel);
    WarningHeader.InitTextContainer();
    WarningHeader.bAutoScroll = true;
    WarningHeader.SetSize(WarningPanelBG.Width - 40, 30);
    WarningHeader.SetPosition(WarningHeader.X + 20, WarningHeader.Y +60);

    WarningHeader.Text.SetHTMLText( class'UIUtilities_Text'.static.StyleText(
        strMessage_Header, eUITextStyle_Tooltip_H1, eUIState_Warning2));
	
    // Warning Body
    WarningBody = Screen.Spawn(class'UITextContainer', WarningPanel);
    WarningBody.InitTextContainer();
    WarningBody.bAutoScroll = true;
    WarningBody.SetSize(WarningPanelBG.Width - 40,
                        WarningPanelBG.Height - 100);
    WarningBody.SetPosition(WarningBody.X +20, WarningBody.Y + 90);

    WarningBody.Text.SetHTMLText( class'UIUtilities_Text'.static.StyleText(
        strMessage_Body, eUITextStyle_Tooltip_Body, eUIState_Normal));
    WarningBody.Text.SetHeight(WarningBody.Text.Height * 3.0f);                   

    // Dismiss Button
    DismissButton = Screen.Spawn(class'UIButton', WarningPanel);
    DismissButton.InitButton('DismissButton', strDismiss_Button,
        DismissButtonHandler, );
    DismissButton.SetSize(760, 30); 
    DismissButton.SetResizeToText(true);
    DismissButton.AnchorTopCenter();
    DismissButton.OriginTopCenter();
    DismissButton.SetPosition(DismissButton.X - 60, WarningPanelBG.Y + 350);
}

//---------------------------------------------------------------------------//

private function DismissButtonHandler(UIButton Button)
{
    DismissButton.Remove();
    WarningBody.Remove();
    WarningHeader.Remove();
    WarningTitle.Remove();
    WarningImage.Remove();
    WarningPanel.Remove();
    WarningPanelBG.Remove();
}

//---------------------------------------------------------------------------//

private function bool ShouldShowWarningMsg()
{
    if (class'X2ModConfig_KMP01'.default.Unstable)
    {	
        return true; 
    }
    return false;
}

//---------------------------------------------------------------------------//

defaultproperties
{
    ScreenClass=UIFinalShell
    imgWarning="UILibrary_StrategyImages.ScienceIcons.IC_AutopsyCyberdisc"
}
