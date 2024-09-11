#property link          "https://www.earnforex.com/metatrader-indicators/price-line-alert/"
#property version       "1.04"
#property strict
#property copyright     "EarnForex.com - 2019-2024"
#property description   "Place price lines with alerts."
#property description   " "
#property description   "WARNING: Use this software at your own risk."
#property description   "The creator of this indicator cannot be held responsible for any damage or loss."
#property description   " "
#property description   "Find more on www.EarnForex.com"
#property icon          "\\Files\\EF-Icon-64x64px.ico"

#property indicator_chart_window

#include <MQLTA Utils.mqh>

input string Comment_1 = "===================="; // Price Line Alert
input string IndicatorName = "PLA";              // Objects Prefix (used to draw objects)

input string Comment_2 = "===================="; // Notification Options
input bool SendAlert = false;                    // Send Alert Notification
input bool SendApp = false;                      // Send Notification to Mobile
input bool SendEmail = false;                    // Send Notification via Email

input string Comment_3 = "===================="; // Notifications and Close Options
input color LineColorOFF = clrGray;              // Inactive Line Color
input color LineColorAbove = clrGreen;           // Alert Above Line Color
input color LineColorBelow = clrRed;             // Alert Below Line Color
input ENUM_LINE_STYLE LineStyle = STYLE_DOT;     // Lines Style
input bool DrawLabels = true;                    // Draw Line Labels
input int Xoff = 20;                             // Horizontal spacing for the control panel
input int Yoff = 20;                             // Vertical spacing for the control panel
input string Font = "Consolas";                  // Panel Font
input int FontSize = 8;                          // Font Size

double DPIScale; // Scaling parameter for the panel based on the screen DPI.
int PanelMovX, PanelMovY, PanelLabX, PanelLabY, PanelRecX;
int DetGLabelX, DetGLabelY, DetCmntLabelX, DetButtonX, DetButtonY;
int SetGLabelX, SetGLabelY, SetButtonX, SetButtonY;
int _XOffset, _YOffset;
bool _SendAlert, _SendApp, _SendEmail, _DrawLabels;
int CurrentPage = 0;

int OnInit()
{
    IndicatorSetString(INDICATOR_SHORTNAME, IndicatorName);

    CleanChart();
    ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 1);

    _XOffset = Xoff;
    _YOffset = Yoff;
    
    _SendAlert = SendAlert;
    _SendApp = SendApp;
    _SendEmail = SendEmail;
    _DrawLabels = DrawLabels;

    DPIScale = (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI) / 96.0;

    PanelMovX = (int)MathRound(26 * DPIScale);
    PanelMovY = (int)MathRound(26 * DPIScale);
    PanelLabX = (int)MathRound(160 * DPIScale);
    PanelLabY = PanelMovY;
    PanelRecX = PanelMovX * 2 + PanelLabX + 6;

    DetGLabelX = (int)MathRound(80 * DPIScale);
    DetGLabelY = (int)MathRound(20 * DPIScale);
    DetCmntLabelX = (int)MathRound(200 * DPIScale);
    DetButtonX = (int)MathRound(50 * DPIScale);
    DetButtonY = DetGLabelY;

    SetGLabelX = (int)MathRound(140 * DPIScale);
    SetGLabelY = (int)MathRound(20 * DPIScale);
    SetButtonX = (int)MathRound(50 * DPIScale);
    SetButtonY = SetGLabelY;

    CreateMiniPanel();
    ScanLines();
    ShowSettings();

    return INIT_SUCCEEDED;
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    ScanLines();
    return rates_total;
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        ChartSetInteger(ChartID(), CHART_MOUSE_SCROLL, true); // Enable chart sideways scroll.
        if (sparam == PanelExp)
        {
            CloseEdit();
            ShowDetails();
            CloseSettings();
        }
        else if (sparam == PanelOptions)
        {
            CloseEdit();
            CloseDetails();
            ShowSettings();
        }
        else if (sparam == DetailsClose)
        {
            CloseDetails();
        }
        else if (sparam == DetailsEdit)
        {
            CloseEdit();
            CloseDetails();
            CloseSettings();
            if (TotalLines > 0) ShowEdit();
        }
        else if (sparam == DetailsNext)
        {
            if (CurrentPage < TotPages)
            {
                CloseDetails();
                ShowDetails(CurrentPage + 1);
            }
        }
        else if (sparam == DetailsPrev)
        {
            if (CurrentPage > 1)
            {
                CloseDetails();
                ShowDetails(CurrentPage - 1);
            }
        }
        else if (sparam == EditClose)
        {
            CloseEdit();
        }
        else if (sparam == EditNext)
        {
            if (EditIndexNext > -1) ShowEdit(EditIndexNext);
        }
        else if (sparam == EditPrev)
        {
            if (EditIndexPrev > -1) ShowEdit(EditIndexPrev);
        }
        else if (sparam == EditDelete)
        {
            int Line = (int)StringToInteger(ObjectGetString(0, EditTLNumberI, OBJPROP_TEXT));
            DeleteLine(Line);
            CloseEdit();
            ScanLines();
            ShowDetails();
        }
        else if (sparam == DetailsNew)
        {
            CreateLine();
        }
        else if (sparam == EditTLTypeI)
        {
            ClickEditTLTypeI();
        }
        else if (sparam == EditTLNotifyI)
        {
            ClickEditTLNotifyI();
        }
        else if (sparam == EditSave)
        {
            SaveEditChanges();
        }
        else if (sparam == SettingsClose)
        {
            CloseSettings();
        }
        else if (sparam == SettingsAlertE)
        {
            ClickSettingsAlertE();
        }
        else if (sparam == SettingsAppE)
        {
            ClickSettingsAppE();
        }
        else if (sparam == SettingsEmailE)
        {
            ClickSettingsEmailE();
        }
        else if (sparam == SettingsDrawLabelE)
        {
            ClickSettingsDrawLabelE();
        }
        else if (sparam == SettingsSave)
        {
            SaveSettingsChanges();
        }
    }
    else if (id == CHARTEVENT_MOUSE_MOVE)
    {
        if (StringToInteger(sparam) == 1)
        {
            if ((lparam > _XOffset + 2) && (lparam < _XOffset + 2 + PanelLabX) &&
                (dparam > _YOffset + 2) && (dparam < _YOffset + 2 + PanelLabY))
            {
                ChartSetInteger(ChartID(), CHART_MOUSE_SCROLL, false);  // Disable chart sideways scroll.
                _XOffset = int(lparam - 2 - PanelLabX / 2);
                _YOffset = int(dparam - 2 - PanelLabY / 2);
                CloseDetails();
                CloseSettings();
                CloseEdit();
                UpdatePanel();
            }
        }
    }
    // Detect manual drag of a horizontal line.
    else if (id == CHARTEVENT_OBJECT_DRAG)
    {
        if (StringFind(sparam, "-HLINE-") != -1)
        {
            ScanLines();
            CloseDetails();
            CloseSettings();
            CloseEdit();
        }
    }
}

void OnDeinit(const int reason)
{
    CleanChart();
}

void CleanChart()
{
    ObjectsDeleteAll(0, IndicatorName);
}

void DeleteAllLines()
{
    ObjectsDeleteAll(0, IndicatorName + "-HLINE-");
}

int TotalLines = 0;
int DetectedLines = 0;
int Lines[];
void ScanLines()
{
    TotalLines = 0;
    for (int i = 0; i < ObjectsTotal(0, 0, OBJ_HLINE); i++)
    {
        if (StringFind(ObjectName(0, i, 0, OBJ_HLINE), IndicatorName + "-HLINE-", 0) >= 0)
        {
            TotalLines++;
            ArrayResize(Lines, TotalLines, 10);
            Lines[TotalLines - 1] = LineNumberFromName(ObjectName(0, i, 0, OBJ_HLINE));
        }
    }
    DetectedLines = TotalLines;
    if (TotalLines > 0) ArraySort(Lines, WHOLE_ARRAY, 0, MODE_ASCEND);
    for (int j = 0; j < DetectedLines; j++)
    {
        int LineNumber = Lines[j];
        string LineName = LineNameFromNumber(LineNumber);
        double LPrice = GetLinePrice(LineName);
        bool LNotify = false;
        string LType = GetLineType(LineName);
        if (StringFind(GetLineNotification(LineName), "NT") >= 0) LNotify = true;
        color LineColor = LineColorOFF;
        if ((LType == "ABOVE") && (LNotify)) LineColor = LineColorAbove;
        if ((LType == "BELOW") && (LNotify)) LineColor = LineColorBelow;
        ObjectSetInteger(0, LineName, OBJPROP_COLOR, LineColor);
        if (((iClose(Symbol(), Period(), 0) > LPrice) && (LType == "ABOVE") && (LNotify)) ||
            ((iClose(Symbol(), Period(), 0) < LPrice) && (LType == "BELOW") && (LNotify)))
        {
            NotifyHit(LineNumber);
        }
    }
    UpdateLineLabels();
}

int LineNumberFromName(string LName)
{
    StringReplace(LName, IndicatorName + "-HLINE-", "");
    return (int)StringToInteger(LName);
}

string LineNameFromNumber(int Number)
{
    return (IndicatorName + "-HLINE-" + IntegerToString(Number));
}

/*
Description[]
0 - Line Type - ABOVE/BELOW
1 - Notification Enabled true/false - T/F
2 - Comment - String(25)
*/
string GetLineType(string LName)
{
    string LDescr[];
    string DescrTmp = ObjectGetString(0, LName, OBJPROP_TEXT);
    int R = StringReplace(DescrTmp, "-", "@");
    int RR = StringReplace(DescrTmp, "@", "-");
    if (RR != 2) return "N/A";
    int res = StringSplit(DescrTmp, StringGetCharacter("-", 0), LDescr);
    string Tmp = LDescr[0];
    return Tmp;
}

string GetLineNotification(string LName)
{
    string LDescr[];
    string DescrTmp = ObjectGetString(0, LName, OBJPROP_TEXT);
    int R = StringReplace(DescrTmp, "-", "@");
    int RR = StringReplace(DescrTmp, "@", "-");
    if (RR != 2) return "N/A";
    int res = StringSplit(DescrTmp, StringGetCharacter("-", 0), LDescr);
    string Tmp = LDescr[1];
    return Tmp;
}

string GetLineComment(string LName)
{
    string LDescr[];
    string DescrTmp = ObjectGetString(0, LName, OBJPROP_TEXT);
    int R = StringReplace(DescrTmp, "-", "@");
    int RR = StringReplace(DescrTmp, "@", "-");
    if (RR != 2) return "N/A";
    int res = StringSplit(DescrTmp, StringGetCharacter("-", 0), LDescr);
    string Tmp = LDescr[2];
    return Tmp;
}

double GetLinePrice(string LName)
{
    return NormalizeDouble(ObjectGetDouble(0, LName, OBJPROP_PRICE), _Digits);
}

void SetLineDescr(string LName,
                  string LType,
                  bool LNotification,
                  string LComment
                 )
{
    string LNotTmp = "";
    string LAutoCTmp = "";
    string LActTmp = "";
    if (LNotification) LNotTmp = "NT";
    else LNotTmp = "NF";
    string LDescrTmp = StringConcatenate(LType, "-", LNotTmp, "-", LComment);
    ObjectSetString(0, LName, OBJPROP_TEXT, LDescrTmp);
}

void DeleteLine(int Line)
{
    ObjectDelete(0, LineNameFromNumber(Line));
    ScanLines();
    ShowDetails();
}

bool LineExists(int Line)
{
    for (int i = 0; i < TotalLines; i++)
    {
        if (Lines[i] == Line)
        {
            return true;
        }
    }
    return false;
}

void CreateLine()
{
    int i = 1;
    if (TotalLines > 0)
    {
        while (LineExists(i)) i++;
    }
    ObjectCreate(0, LineNameFromNumber(i), OBJ_HLINE, 0, 0, iClose(Symbol(), Period(), 0));
    ObjectSetString(0, LineNameFromNumber(i), OBJPROP_TEXT, "ABOVE-NF-");
    ObjectSetInteger(0, LineNameFromNumber(i), OBJPROP_COLOR, LineColorOFF);
    ObjectSetInteger(0, LineNameFromNumber(i), OBJPROP_STYLE, LineStyle);
    ObjectSetInteger(0, LineNameFromNumber(i), OBJPROP_BACK, false);
    ObjectSetInteger(0, LineNameFromNumber(i), OBJPROP_SELECTABLE, true);
    CloseDetails();
    ShowEdit(i);
}

void ClickEditTLTypeI()
{
    string Tmp = ObjectGetString(0, EditTLTypeI, OBJPROP_TEXT);
    if (Tmp == "ABOVE")
    {
        ObjectSetString(0, EditTLTypeI, OBJPROP_TEXT, "BELOW");
    }
    else if (Tmp == "BELOW")
    {
        ObjectSetString(0, EditTLTypeI, OBJPROP_TEXT, "ABOVE");
    }
}

void ClickEditTLNotifyI()
{
    string Tmp = ObjectGetString(0, EditTLNotifyI, OBJPROP_TEXT);
    if (Tmp == "ON")
    {
        ObjectSetString(0, EditTLNotifyI, OBJPROP_TEXT, "OFF");
    }
    else if (Tmp == "OFF")
    {
        ObjectSetString(0, EditTLNotifyI, OBJPROP_TEXT, "ON");
    }
}

void SaveEditChanges()
{
    int LineNumber = (int)StringToInteger(ObjectGetString(0, EditTLNumberI, OBJPROP_TEXT));
    string LineName = "";
    string LineDescr = "";
    string LineType = "ABOVE";
    bool LineNotify = false;
    string LineComment = "";
    double LinePrice = NormalizeDouble(StringToDouble(ObjectGetString(0, EditTLPriceI, OBJPROP_TEXT)), _Digits);
    string LineTypeTmp = ObjectGetString(0, EditTLTypeI, OBJPROP_TEXT);
    string LineNotifyTmp = ObjectGetString(0, EditTLNotifyI, OBJPROP_TEXT);
    string LineCommentTmp = ObjectGetString(0, EditTLCommentI, OBJPROP_TEXT);
    if (LineTypeTmp == "ABOVE") LineType = "ABOVE";
    if (LineTypeTmp == "BELOW") LineType = "BELOW";
    if (LineNotifyTmp == "ON") LineNotify = true;
    if (LineNotifyTmp == "OFF") LineNotify = false;
    color LineColor = LineColorOFF;
    if ((LineType == "ABOVE") && (LineNotify)) LineColor = LineColorAbove;
    if ((LineType == "BELOW") && (LineNotify)) LineColor = LineColorBelow;
    LineComment = LineCommentTmp;
    LineName = LineNameFromNumber(LineNumber);
    SetLineDescr(LineName, LineType, LineNotify, LineComment);
    ObjectSetInteger(0, LineName, OBJPROP_COLOR, LineColor);
    ObjectSetDouble(0, LineName, OBJPROP_PRICE, LinePrice);
    ShowEdit(LineNumber);
}

void DeleteLineLabels()
{
    ObjectsDeleteAll(0, IndicatorName + "-HLINELABEL-");
}

void ClickSettingsAlertE()
{
    string Tmp = ObjectGetString(0, SettingsAlertE, OBJPROP_TEXT);
    if (Tmp == "ON")
    {
        ObjectSetString(0, SettingsAlertE, OBJPROP_TEXT, "OFF");
    }
    else if (Tmp == "OFF")
    {
        ObjectSetString(0, SettingsAlertE, OBJPROP_TEXT, "ON");
    }
}

void ClickSettingsEmailE()
{
    string Tmp = ObjectGetString(0, SettingsEmailE, OBJPROP_TEXT);
    if (Tmp == "ON")
    {
        ObjectSetString(0, SettingsEmailE, OBJPROP_TEXT, "OFF");
    }
    else if (Tmp == "OFF")
    {
        ObjectSetString(0, SettingsEmailE, OBJPROP_TEXT, "ON");
    }
}

void ClickSettingsAppE()
{
    string Tmp = ObjectGetString(0, SettingsAppE, OBJPROP_TEXT);
    if (Tmp == "ON")
    {
        ObjectSetString(0, SettingsAppE, OBJPROP_TEXT, "OFF");
    }
    else if (Tmp == "OFF")
    {
        ObjectSetString(0, SettingsAppE, OBJPROP_TEXT, "ON");
    }
}

void ClickSettingsDrawLabelE()
{
    string Tmp = ObjectGetString(0, SettingsDrawLabelE, OBJPROP_TEXT);
    if (Tmp == "ON")
    {
        ObjectSetString(0, SettingsDrawLabelE, OBJPROP_TEXT, "OFF");
    }
    else if (Tmp == "OFF")
    {
        ObjectSetString(0, SettingsDrawLabelE, OBJPROP_TEXT, "ON");
    }
}

void SaveSettingsChanges()
{
    string SettingsAlertTmp = ObjectGetString(0, SettingsAlertE, OBJPROP_TEXT);
    string SettingsAppTmp = ObjectGetString(0, SettingsAppE, OBJPROP_TEXT);
    string SettingsDrawLabelTmp = ObjectGetString(0, SettingsDrawLabelE, OBJPROP_TEXT);
    string SettingsEmailTmp = ObjectGetString(0, SettingsEmailE, OBJPROP_TEXT);
    if (SettingsAlertTmp == "ON") _SendAlert = true;
    else _SendAlert = false;
    if (SettingsAppTmp == "ON") _SendApp = true;
    else _SendApp = false;
    if (SettingsDrawLabelTmp == "ON") _DrawLabels = true;
    else _DrawLabels = false;
    if (SettingsEmailTmp == "ON") _SendEmail = true;
    else _SendEmail = false;
    ScanLines();
    ShowSettings();
}

void NotifyHit(int Line)
{
    if ((!_SendAlert) && (!_SendApp) && (!_SendEmail)) return;
    string EmailSubject = IndicatorName + " " + Symbol() + " Notification";
    string EmailBody = AccountCompany() + " - " + AccountName() + " - " + IntegerToString(AccountNumber()) + "\r\n" + IndicatorName + " Notification for " + Symbol() + "\r\n";
    EmailBody += "Line " + IntegerToString(Line) + " with comment " + GetLineComment(LineNameFromNumber(Line)) + " has been hit.\r\n";
    string AlertText = IndicatorName + " - " + Symbol() + ": Line " + IntegerToString(Line) + " has been hit.";
    string AppText = IndicatorName + " - " + Symbol() + ": Line " + IntegerToString(Line) + " hit. " + GetLineComment(LineNameFromNumber(Line));
    if (_SendAlert)
    {
        Alert(AlertText);
    }
    if (_SendEmail)
    {
        if (!SendMail(EmailSubject, EmailBody)) Print("Error sending email: " + IntegerToString(GetLastError()));
    }
    if (_SendApp)
    {
        if (!SendNotification(AppText)) Print("Error sending notification: " + IntegerToString(GetLastError()));
    }
    UpdateNotify(Line, "NT", "NF");
}

void UpdateNotify(int Line, string OldNotify, string NewNotify)
{
    string Tmp = ObjectGetString(0, LineNameFromNumber(Line), OBJPROP_TEXT);
    StringReplace(Tmp, OldNotify, NewNotify);
    ObjectSetString(0, LineNameFromNumber(Line), OBJPROP_TEXT, Tmp);
}

void UpdateLineLabels()
{
    DeleteLineLabels();
    if (!DrawLabels) return;
    string LabelBase = IndicatorName + "-HLINELABEL-";
    for (int i = 0; i < TotalLines; i++)
    {
        int LineNumber = Lines[i];
        string LineName = LineNameFromNumber(LineNumber);
        string LabelName = LabelBase + IntegerToString(LineNumber);
        string LineType = GetLineType(LineName);
        bool LNotify = false;
        if (GetLineNotification(LineName) == "NT") LNotify = true;
        color LineColor = LineColorOFF;
        if ((LineType == "ABOVE") && (LNotify)) LineColor = LineColorAbove;
        if ((LineType == "BELOW") && (LNotify)) LineColor = LineColorBelow;
        ObjectCreate(0, LabelName, OBJ_TEXT, 0, 0, 0);
        ObjectSetInteger(0, LabelName, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
        ObjectSetInteger(0, LabelName, OBJPROP_COLOR, LineColor);
        double PriceY = GetLinePrice(LineName);
        int SubW = 0;
        datetime TimeTmp = iTime(Symbol(), Period(), 0);
        string LabelDescr = "LINE " + IntegerToString(LineNumber) + " - Notify if price goes " + LineType;
        if (StringLen(GetLineComment(LineName)) > 0) LabelDescr += " - " + GetLineComment(LineName);
        ObjectSetInteger(0, LabelName, OBJPROP_TIME, TimeTmp);
        ObjectSetDouble(0, LabelName, OBJPROP_PRICE, PriceY);
        ObjectSetInteger(0, LabelName, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, LabelName, OBJPROP_BACK, false);
        ObjectSetString(0, LabelName, OBJPROP_TEXT, LabelDescr);
        ObjectSetInteger(0, LabelName, OBJPROP_FONTSIZE, FontSize);
        ObjectSetString(0, LabelName, OBJPROP_FONT, Font);
        ObjectSetInteger(0, LabelName, OBJPROP_COLOR, LineColor);
    }
}

string PanelBase = IndicatorName + "-BAS";
string PanelOptions = IndicatorName + "-OPT";
string PanelLabel = IndicatorName + "-LAB";
string PanelExp = IndicatorName + "-EXP";
void CreateMiniPanel()
{
    ObjectCreate(0, PanelBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, PanelBase, OBJPROP_XDISTANCE, _XOffset);
    ObjectSetInteger(0, PanelBase, OBJPROP_YDISTANCE, _YOffset);
    ObjectSetInteger(0, PanelBase, OBJPROP_XSIZE, PanelRecX);
    ObjectSetInteger(0, PanelBase, OBJPROP_YSIZE, PanelMovY + 2 * 2);
    ObjectSetInteger(0, PanelBase, OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, PanelBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, PanelBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, PanelBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, PanelBase, OBJPROP_COLOR, clrBlack);

    DrawEdit(PanelExp,
             _XOffset + PanelLabX + 3,
             _YOffset + 2,
             PanelMovX,
             PanelMovX,
             true,
             int(FontSize * 1.5),
             "Open Details",
             ALIGN_CENTER,
             "Wingdings",
             "?",
             false,
             clrNavy,
             clrKhaki,
             clrBlack);

    DrawEdit(PanelOptions,
             _XOffset + PanelMovX + PanelLabX + 4,
             _YOffset + 2,
             PanelMovX,
             PanelMovX,
             true,
             int(FontSize * 1.5),
             "Options",
             ALIGN_CENTER,
             "Wingdings",
             ":",
             false,
             clrNavy,
             clrKhaki,
             clrBlack);

    DrawEdit(PanelLabel,
             _XOffset + 2,
             _YOffset + 2,
             PanelLabX,
             PanelLabY,
             true,
             int(FontSize * 1.5),
             "",
             ALIGN_CENTER,
             Font,
             "PRICE LINE ALERT",
             false,
             clrNavy,
             clrKhaki,
             clrBlack);
}

void UpdatePanel()
{
    ObjectSetInteger(0, PanelBase, OBJPROP_XDISTANCE, _XOffset);
    ObjectSetInteger(0, PanelBase, OBJPROP_YDISTANCE, _YOffset);
    ObjectSetInteger(0, PanelExp, OBJPROP_XDISTANCE, _XOffset + PanelLabX + 3);
    ObjectSetInteger(0, PanelExp, OBJPROP_YDISTANCE, _YOffset + 2);
    ObjectSetInteger(0, PanelOptions, OBJPROP_XDISTANCE, _XOffset + PanelMovX + PanelLabX + 4);
    ObjectSetInteger(0, PanelOptions, OBJPROP_YDISTANCE, _YOffset + 2);
    ObjectSetInteger(0, PanelLabel, OBJPROP_XDISTANCE, _XOffset + 2);
    ObjectSetInteger(0, PanelLabel, OBJPROP_YDISTANCE, _YOffset + 2);
}

string DetailsBase = IndicatorName + "-D-Base";
string DetailsNew = IndicatorName + "-D-New";
string DetailsEdit = IndicatorName + "-D-Edit";
string DetailsClose = IndicatorName + "-D-Close";
string DetailsPage = IndicatorName + "-D-Page";
string DetailsPrev = IndicatorName + "-D-Prev";
string DetailsNext = IndicatorName + "-D-Next";
string DetailsTLPrice = IndicatorName + "-D-TLPrice";
string DetailsTLNumber = IndicatorName + "-D-TLNumber";
string DetailsTLType = IndicatorName + "-D-TLType";
string DetailsTLNotify = IndicatorName + "-D-TLNotify";
string DetailsTLComment = IndicatorName + "-D-TLCmnt";
int TotPages = 0;
int MaxLinesPerPage = 5;
void ShowDetails(int CurrPage = 1)
{
    ScanLines();
    int DetXoff = _XOffset;
    int DetYoff = _YOffset + PanelMovY + 2 * 4;
    int DetX = 0;
    int DetY = 0;
    int LinesThisPage = 0;
    CurrentPage = CurrPage;
    TotPages = (int)MathCeil((double)TotalLines / MaxLinesPerPage);
    if ((TotalLines > 0) && ((TotalLines % MaxLinesPerPage == 0) || (CurrPage < TotPages)))
    {
        LinesThisPage = MaxLinesPerPage;
    }
    if ((TotalLines > 0) && (TotalLines % MaxLinesPerPage > 0) && (CurrPage == TotPages))
    {
        LinesThisPage = TotalLines % MaxLinesPerPage;
    }
    int IndexFirstLine = (CurrPage - 1) * MaxLinesPerPage;
    if (TotalLines == 0)
    {
        DetX = (DetButtonX + 2) * 3 + 2;
        DetY = DetButtonY + 2 * 2;
    }
    else
    {
        DetX = (DetGLabelX + 2) * 4 + DetCmntLabelX + 4;
        DetY = DetButtonY + (DetGLabelY + 5) * (LinesThisPage + 1) + 10 + 7;
    }
    ObjectCreate(0, DetailsBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, DetailsBase, OBJPROP_XDISTANCE, DetXoff);
    ObjectSetInteger(0, DetailsBase, OBJPROP_YDISTANCE, DetYoff);
    ObjectSetInteger(0, DetailsBase, OBJPROP_XSIZE, DetX);
    ObjectSetInteger(0, DetailsBase, OBJPROP_YSIZE, DetY);
    ObjectSetInteger(0, DetailsBase, OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, DetailsBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, DetailsBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, DetailsBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, DetailsBase, OBJPROP_COLOR, clrBlack);

    DrawEdit(DetailsNew,
             DetXoff + 2,
             DetYoff + 2,
             DetButtonX,
             DetButtonY,
             "Create New Line",
             "New");

    DrawEdit(DetailsEdit,
             DetXoff + DetButtonX + 4,
             DetYoff + 2,
             DetButtonX,
             DetButtonY,
             "Edit Existing Lines",
             "Edit");

    DrawEdit(DetailsClose,
             DetXoff + (DetButtonX + 2) * 2 + 2,
             DetYoff + 2,
             DetButtonX,
             DetButtonY,
             "Close Details Panel",
             "Close");

    if (TotPages > 1)
    {
        string TextPage = IntegerToString((int)CurrPage) + " / " + IntegerToString((int)TotPages);

        DrawEdit(DetailsPage,
                 DetXoff + (DetButtonX + 2) * 5 + 2,
                 DetYoff + 2,
                 DetButtonX,
                 DetButtonY,
                 "Page",
                 TextPage);

        DrawEdit(DetailsPrev,
                 DetXoff + (DetButtonX + 2) * 4 + 2,
                 DetYoff + 2,
                 DetButtonX,
                 DetButtonY,
                 "Go to previous page",
                 "Prev");

        DrawEdit(DetailsNext,
                 DetXoff + (DetButtonX + 2) * 6 + 2,
                 DetYoff + 2,
                 DetButtonX,
                 DetButtonY,
                 "Go to next page",
                 "Next");
    }

    if (TotalLines == 0) return;

    DrawEdit(DetailsTLNumber,
             DetXoff + 2,
             DetYoff + 2 + DetButtonY + 2 + 10,
             DetGLabelX,
             DetGLabelY,
             "Line Number",
             "#");

    DrawEdit(DetailsTLPrice,
             DetXoff + (DetGLabelX + 2) + 2,
             DetYoff + 2 + DetButtonY + 2 + 10,
             DetGLabelX,
             DetGLabelY,
             "Line Price",
             "Price");

    DrawEdit(DetailsTLType,
             DetXoff + (DetGLabelX + 2) * 2 + 2,
             DetYoff + 2 + DetButtonY + 2 + 10,
             DetGLabelX,
             DetGLabelY,
             "Notify if the price is ABOVE or BELOW the line",
             "Notify");

    DrawEdit(DetailsTLNotify,
             DetXoff + (DetGLabelX + 2) * 3 + 2,
             DetYoff + 2 + DetButtonY + 2 + 10,
             DetGLabelX,
             DetGLabelY,
             "Line Notifications",
             "Notification");

    DrawEdit(DetailsTLComment,
             DetXoff + (DetGLabelX + 2) * 4 + 2,
             DetYoff + 2 + DetButtonY + 2 + 10,
             DetCmntLabelX,
             DetGLabelY,
             "Line Comment",
             "Comment");

    int j = 1;
    for (int i = IndexFirstLine; i < (IndexFirstLine + LinesThisPage); i++)
    {
        string DetailsTLNumberI = IndicatorName + "-D-TLNumber-" + IntegerToString(i);
        string DetailsTLPriceI = IndicatorName + "-D-TLPrice-" + IntegerToString(i);
        string DetailsTLTypeI = IndicatorName + "-D-TLType-" + IntegerToString(i);
        string DetailsTLNotifyI = IndicatorName + "-D-TLNotify-" + IntegerToString(i);
        string DetailsTLCommentI = IndicatorName + "-D-TLCmnt-" + IntegerToString(i);
        int LineNumber = Lines[i];
        string LineName = LineNameFromNumber(LineNumber);
        string TextPrice = DoubleToString(GetLinePrice(LineName), _Digits);
        string TextType = GetLineType(LineName);
        string TextNotify = GetLineNotification(LineName);
        string TextCmnt = GetLineComment(LineName);
        if (StringFind(TextNotify, "N/A", 0) == -1)
        {
            if (StringFind(TextNotify, "NT", 0) == 0) TextNotify = "ON";
            else if (StringFind(TextNotify, "NF", 0) == 0) TextNotify = "OFF";
        }
        
        DrawEdit(DetailsTLNumberI,
                 DetXoff + 2,
                 DetYoff + DetButtonY + (DetGLabelY + 5) * j + 20,
                 DetGLabelX,
                 DetGLabelY,
                 "Line Number",
                 IntegerToString(LineNumber));

        DrawEdit(DetailsTLPriceI,
                 DetXoff + (DetGLabelX + 2) + 2,
                 DetYoff + DetButtonY + (DetGLabelY + 5) * j + 20,
                 DetGLabelX,
                 DetGLabelY,
                 "Line Price",
                 TextPrice);

        DrawEdit(DetailsTLTypeI,
                 DetXoff + (DetGLabelX + 2) * 2 + 2,
                 DetYoff + DetButtonY + (DetGLabelY + 5) * j + 20,
                 DetGLabelX,
                 DetGLabelY,
                 "Notify if the Price is ABOVE or BELOW the line",
                 TextType);

        DrawEdit(DetailsTLNotifyI,
                 DetXoff + (DetGLabelX + 2) * 3 + 2,
                 DetYoff + DetButtonY + (DetGLabelY + 5) * j + 20,
                 DetGLabelX,
                 DetGLabelY,
                 "Line Notifications",
                 TextNotify);

        DrawEdit(DetailsTLCommentI,
                 DetXoff + (DetGLabelX + 2) * 4 + 2,
                 DetYoff + DetButtonY + (DetGLabelY + 5) * j + 20,
                 DetCmntLabelX,
                 DetGLabelY,
                 "Line Comment",
                 TextCmnt);
        j++;
    }
}

void CloseDetails()
{
    ObjectsDeleteAll(0, IndicatorName + "-D-");
}

string EditBase = IndicatorName + "-E-Base";
string EditDelete = IndicatorName + "-E-Del";
string EditSave = IndicatorName + "-E-Save";
string EditClose = IndicatorName + "-E-Close";
string EditPage = IndicatorName + "-E-Page";
string EditPrev = IndicatorName + "-E-Prev";
string EditNext = IndicatorName + "-E-Next";
string EditTLNumber = IndicatorName + "-E-TLNumber";
string EditTLPrice = IndicatorName + "-E-TLPrice";
string EditTLType = IndicatorName + "-E-TLType";
string EditTLNotify = IndicatorName + "-E-TLNotify";
string EditTLComment = IndicatorName + "-E-TLCmnt";
string EditTLNumberI = IndicatorName + "-E-TLNumberI";
string EditTLPriceI = IndicatorName + "-E-TLPriceI";
string EditTLTypeI = IndicatorName + "-E-TLTypeI";
string EditTLNotifyI = IndicatorName + "-E-TLNotifyI";
string EditTLCommentI = IndicatorName + "-E-TLCmntI";
int EditIndexPrev = -1;
int EditIndexNext = -1;
void ShowEdit(int Line = -1)
{
    ScanLines();
    if (Line == -1) Line = Lines[0];
    EditIndexPrev = -1;
    EditIndexNext = -1;
    int CurrIndex = -1;
    int EditXoff = _XOffset;
    int EditYoff = _YOffset + PanelMovY + 2 * 4;
    int EditX = 0;
    int EditY = 0;
    int LinesThisPage = 1;
    if (TotalLines == 0)
    {
        EditX = (DetButtonX + 1) * 3;
        EditY = (DetButtonY + 2) * 2;
    }
    else
    {
        EditX = (DetGLabelX + 2) * 4 + DetCmntLabelX + 4;
        EditY = DetButtonY + (DetGLabelY + 5) * (LinesThisPage + 1) + 10 + 7;
    }
    for (int i = 0; i < TotalLines; i++)
    {
        if (Lines[i] == Line)
        {
            CurrIndex = i + 1;
            if (i > 0) EditIndexPrev = Lines[i - 1];
            if (i < TotalLines - 1) EditIndexNext = Lines[i + 1];
        }
    }
    if (CurrIndex == -1) return;
    
    ObjectCreate(0, EditBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, EditBase, OBJPROP_XDISTANCE, EditXoff);
    ObjectSetInteger(0, EditBase, OBJPROP_YDISTANCE, EditYoff);
    ObjectSetInteger(0, EditBase, OBJPROP_XSIZE, EditX);
    ObjectSetInteger(0, EditBase, OBJPROP_YSIZE, EditY);
    ObjectSetInteger(0, EditBase, OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, EditBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, EditBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, EditBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, EditBase, OBJPROP_COLOR, clrBlack);

    DrawEdit(EditDelete,
             EditXoff + DetButtonX + 4,
             EditYoff + 2,
             DetButtonX,
             DetButtonY,
             "Delete Line",
             "Delete");

    DrawEdit(EditSave,
             EditXoff + 2,
             EditYoff + 2,
             DetButtonX,
             DetButtonY,
             "Save Changes",
             "Save");

    DrawEdit(EditClose,
             EditXoff + (DetButtonX + 2) * 2 + 2,
             EditYoff + 2,
             DetButtonX,
             DetButtonY,
             "Close Edit Panel",
             "Close");

    if (TotalLines > 1)
    {
        string TextPage = IntegerToString(CurrIndex) + " / " + IntegerToString(TotalLines);

        DrawEdit(EditPage,
                 EditXoff + (DetButtonX + 2) * 5 + 2,
                 EditYoff + 2,
                 DetButtonX,
                 DetButtonY,
                 "Page",
                 TextPage);

        DrawEdit(EditPrev,
                 EditXoff + (DetButtonX + 2) * 4 + 2,
                 EditYoff + 2,
                 DetButtonX,
                 DetButtonY,
                 "Go to previous page",
                 "Prev");

        DrawEdit(EditNext,
                 EditXoff + (DetButtonX + 2) * 6 + 2,
                 EditYoff + 2,
                 DetButtonX,
                 DetButtonY,
                 "Go to next page",
                 "Next");
    }

    DrawEdit(EditTLNumber,
             EditXoff + 2,
             EditYoff + 2 + DetButtonY + 2 + 10,
             DetGLabelX,
             DetGLabelY,
             "Line Number",
             "#");

    DrawEdit(EditTLPrice,
             EditXoff + (DetGLabelX + 2) + 2,
             EditYoff + 2 + DetButtonY + 2 + 10,
             DetGLabelX,
             DetGLabelY,
             "Line Price",
             "Price");

    DrawEdit(EditTLType,
             EditXoff + (DetGLabelX + 2) * 2 + 2,
             EditYoff + 2 + DetButtonY + 2 + 10,
             DetGLabelX,
             DetGLabelY,
             "Notify if the price is ABOVE or BELOW the line",
             "Notify");

    DrawEdit(EditTLNotify,
             EditXoff + (DetGLabelX + 2) * 3 + 2,
             EditYoff + 2 + DetButtonY + 2 + 10,
             DetGLabelX,
             DetGLabelY,
             "Line Notifications",
             "Notification");

    DrawEdit(EditTLComment,
             EditXoff + (DetGLabelX + 2) * 4 + 2,
             EditYoff + 2 + DetButtonY + 2 + 10,
             DetCmntLabelX,
             DetGLabelY,
             "Line Comment",
             "Comment");

    int LineNumber = Line;
    string LineName = LineNameFromNumber(LineNumber);
    string TextPrice = DoubleToString(GetLinePrice(LineName), _Digits);
    string TextType = GetLineType(LineName);
    string TextNotify = GetLineNotification(LineName);
    string TextCmnt = GetLineComment(LineName);
    if (StringFind(TextNotify, "N/A", 0) == -1)
    {
        if (StringFind(TextNotify, "NT", 0) == 0) TextNotify = "ON";
        else if (StringFind(TextNotify, "NF", 0) == 0) TextNotify = "OFF";
    }

    DrawEdit(EditTLNumberI,
             EditXoff + 2,
             EditYoff + DetButtonY + DetGLabelY + 25,
             DetGLabelX,
             DetGLabelY,
             "Line Number",
             IntegerToString(LineNumber));

    DrawEdit(EditTLPriceI,
             EditXoff + DetGLabelX + 4,
             EditYoff + DetButtonY + DetGLabelY + 25,
             DetGLabelX,
             DetGLabelY,
             "Price Level for the Line - Click to Change",
             TextPrice,
             ALIGN_CENTER,
             false);


    DrawEdit(EditTLTypeI,
             EditXoff + (DetGLabelX + 2) * 2 + 2,
             EditYoff + DetButtonY + DetGLabelY + 25,
             DetGLabelX,
             DetGLabelY,
             "Notify if the price is ABOVE or BELOW the line - Click to Change",
             TextType);

    DrawEdit(EditTLNotifyI,
             EditXoff + (DetGLabelX + 2) * 3 + 2,
             EditYoff + DetButtonY + DetGLabelY + 25,
             DetGLabelX,
             DetGLabelY,
             "Line Notifications - Click to Change",
             TextNotify);

    DrawEdit(EditTLCommentI,
             EditXoff + (DetGLabelX + 2) * 4 + 2,
             EditYoff + DetButtonY + DetGLabelY + 25,
             DetCmntLabelX,
             DetGLabelY,
             "Line Comment - Click to Change",
             TextCmnt,
             ALIGN_CENTER,
             false);
}

void CloseEdit()
{
    ObjectsDeleteAll(0, IndicatorName + "-E-");
}

string SettingsBase = IndicatorName + "-S-Base";
string SettingsSave = IndicatorName + "-S-Save";
string SettingsClose = IndicatorName + "-S-Close";
string SettingsAlert = IndicatorName + "-S-Alert";
string SettingsAlertE = IndicatorName + "-S-AlertE";
string SettingsEmail = IndicatorName + "-S-Email";
string SettingsEmailE = IndicatorName + "-S-EmailE";
string SettingsApp = IndicatorName + "-S-App";
string SettingsAppE = IndicatorName + "-S-AppE";
string SettingsDrawLabel = IndicatorName + "-S-DrawLabel";
string SettingsDrawLabelE = IndicatorName + "-S-DrawLabelE";
void ShowSettings()
{
    int SetXoff = _XOffset;
    int SetYoff = _YOffset + PanelMovY + 2 * 4;
    int SetX = SetGLabelX + SetButtonX + 6;
    int SetY = (SetButtonY + 2) * 5 + 2;

    string TextEmail, TextAlert, TextApp, TextDrawLabel;
    if (_SendEmail) TextEmail = "ON";
    else TextEmail = "OFF";
    if (_SendAlert) TextAlert = "ON";
    else TextAlert = "OFF";
    if (_SendApp) TextApp = "ON";
    else TextApp = "OFF";
    if (_DrawLabels) TextDrawLabel = "ON";
    else TextDrawLabel = "OFF";

    ObjectCreate(0, SettingsBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, SettingsBase, OBJPROP_XDISTANCE, SetXoff);
    ObjectSetInteger(0, SettingsBase, OBJPROP_YDISTANCE, SetYoff);
    ObjectSetInteger(0, SettingsBase, OBJPROP_XSIZE, SetX);
    ObjectSetInteger(0, SettingsBase, OBJPROP_YSIZE, SetY);
    ObjectSetInteger(0, SettingsBase, OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, SettingsBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, SettingsBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, SettingsBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, SettingsBase, OBJPROP_COLOR, clrBlack);

    DrawEdit(SettingsSave,
             SetXoff + 2,
             SetYoff + 2,
             DetButtonX,
             DetButtonY,
             "Save Changes",
             "Save");

    DrawEdit(SettingsClose,
             SetXoff + (DetButtonX + 2) * 1 + 2,
             SetYoff + 2,
             DetButtonX,
             DetButtonY,
             "Close Settings Panel",
             "Close");

    DrawEdit(SettingsAlert,
             SetXoff + 2,
             SetYoff + 2 + (DetButtonY + 2) * 1,
             SetGLabelX,
             SetGLabelY,
             "Send Alert Notifications Enable/Disable",
             "Alert Notifications",
             ALIGN_LEFT);

    DrawEdit(SettingsEmail,
             SetXoff + 2,
             SetYoff + 2 + (DetButtonY + 2) * 2,
             SetGLabelX,
             SetGLabelY,
             "Send Emails Notifications Enable/Disable",
             "Emails Notifications",
             ALIGN_LEFT);

    DrawEdit(SettingsApp,
             SetXoff + 2,
             SetYoff + 2 + (DetButtonY + 2) * 3,
             SetGLabelX,
             SetGLabelY,
             "Send Apps Notifications Enable/Disable",
             "App Notifications",
             ALIGN_LEFT);

    DrawEdit(SettingsDrawLabel,
             SetXoff + 2,
             SetYoff + 2 + (DetButtonY + 2) * 4,
             SetGLabelX,
             SetGLabelY,
             "Draw Line Labels Enable/Disable",
             "Draw Labels",
             ALIGN_LEFT);

    DrawEdit(SettingsAlertE,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2 + (DetButtonY + 2) * 1,
             SetButtonX,
             SetButtonY,
             "Click to Enable/Disable",
             TextAlert);

    DrawEdit(SettingsEmailE,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2 + (DetButtonY + 2) * 2,
             SetButtonX,
             SetButtonY,
             "Click to Enable/Disable",
             TextEmail);

    DrawEdit(SettingsAppE,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2 + (DetButtonY + 2) * 3,
             SetButtonX,
             SetButtonY,
             "Click to Enable/Disable",
             TextApp);

    DrawEdit(SettingsDrawLabelE,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2 + (DetButtonY + 2) * 4,
             SetButtonX,
             SetButtonY,
             "Click to Enable/Disable",
             TextDrawLabel);
}

void CloseSettings()
{
    ObjectsDeleteAll(0, IndicatorName + "-S-");
}

// The same the standard DrawEdit but with more defaults.
void DrawEdit(string Name,
              int XStart,
              int YStart,
              int Width,
              int Height,
              string Tooltip,
              string Text,
              ENUM_ALIGN_MODE AlignMode = ALIGN_CENTER,
              bool ReadOnly = true
             )
{
    DrawEdit(Name,
             XStart,
             YStart,
             Width,
             Height,
             ReadOnly,
             FontSize,
             Tooltip,
             AlignMode,
             Font,
             Text,
             false);
}
//+------------------------------------------------------------------+