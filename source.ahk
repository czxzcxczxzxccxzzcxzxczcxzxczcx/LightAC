#Requires AutoHotkey v2.0
#Warn

; ===== GLOBAL SETTINGS =========
global L := {enabled:false, cps:12, hold:140, randOn:true, rand:12, clicking:false, pressTime:0}
global R := {enabled:false, cps:12, hold:140, randOn:true, rand:12, clicking:false, pressTime:0}

global WindowWhitelist := Map()
global WhitelistEnabled := true

; GUI control globals
global L_enable, R_enable
global L_dropdown, R_dropdown
global L_cpsSlider, L_cpsValue, L_holdSlider, L_holdValue, L_randSlider, L_randValue
global R_cpsSlider, R_cpsValue, R_holdSlider, R_holdValue, R_randSlider, R_randValue
global WhitelistToggle, WhitelistList, AddAppBtn, RemoveAppBtn

; Timer globals
global L_AutoClickTimer, R_AutoClickTimer, L_CheckHoldTimer, R_CheckHoldTimer


; ===== GUI FUNCTIONS ===========
UpdateLCPS(*) {
    global L, L_cpsSlider, L_cpsValue
    L.cps := L_cpsSlider.Value
    L_cpsValue.Text := L.cps
}
UpdateLHold(*) {
    global L, L_holdSlider, L_holdValue
    L.hold := L_holdSlider.Value
    L_holdValue.Text := L.hold
}
UpdateLRand(*) {
    global L, L_randSlider, L_randValue
    L.rand := L_randSlider.Value
    L_randValue.Text := "±" . L.rand . "%"
}
UpdateRCPS(*) {
    global R, R_cpsSlider, R_cpsValue
    R.cps := R_cpsSlider.Value
    R_cpsValue.Text := R.cps
}
UpdateRHold(*) {
    global R, R_holdSlider, R_holdValue
    R.hold := R_holdSlider.Value
    R_holdValue.Text := R.hold
}
UpdateRRand(*) {
    global R, R_randSlider, R_randValue
    R.rand := R_randSlider.Value
    R_randValue.Text := "±" . R.rand . "%"
}

UpdateSection(side) {
    global L_dropdown, R_dropdown
    sel := (side="L") ? L_dropdown.Text : R_dropdown.Text

    if (side="L")
        ToggleControls(L_cpsText, L_cpsSlider, L_cpsValue,
                       L_holdText, L_holdSlider, L_holdValue,
                       L_randCheck, L_randSlider, L_randValue, sel)
    else
        ToggleControls(R_cpsText, R_cpsSlider, R_cpsValue,
                       R_holdText, R_holdSlider, R_holdValue,
                       R_randCheck, R_randSlider, R_randValue, sel)
}

ToggleControls(cpsT,cpsS,cpsV, holdT,holdS,holdV, randC,randS,randV, sel) {
    cpsT.Visible := sel="Click Speed"
    cpsS.Visible := sel="Click Speed"
    cpsV.Visible := sel="Click Speed"

    holdT.Visible := sel="Hold Settings"
    holdS.Visible := sel="Hold Settings"
    holdV.Visible := sel="Hold Settings"

    randC.Visible := sel="Randomization"
    randS.Visible := sel="Randomization"
    randV.Visible := sel="Randomization"
}

; ===== WHITELIST FUNCTIONS =====
ToggleWhitelist(*) {
    global WhitelistEnabled, WhitelistToggle
    WhitelistEnabled := WhitelistToggle.Value
}

ToggleWhitelistTray(*) {
    global WhitelistEnabled, WhitelistToggle
    WhitelistEnabled := !WhitelistEnabled
    WhitelistToggle.Value := WhitelistEnabled
}

AddActiveApp(*) {
    global WindowWhitelist, WhitelistList

    windows := []
    idList := WinGetList()
    for hwnd in idList {
        title := WinGetTitle(hwnd)
        if (title != "") {
            proc := WinGetProcessName("ahk_id " hwnd)
            windows.Push({title: title, proc: proc})
        }
    }
    if (windows.Length = 0) {
        MsgBox("No active windows found.")
        return
    }

    selGui := Gui("+AlwaysOnTop", "Select a window to whitelist")
    selGui.AddText("x10 y10 w300", "Select window:")
    selList := selGui.AddListBox("x10 y30 w300 h200")
    for w in windows
        selList.Add([w.title])
    okBtn := selGui.AddButton("x50 y240 w100 h30", "Add")
    cancelBtn := selGui.AddButton("x170 y240 w100 h30", "Cancel")
    okBtn.OnEvent("Click", (*) => AddSelectedWindow(selGui, selList, windows))
    cancelBtn.OnEvent("Click", (*) => selGui.Destroy())
    selGui.Show("w330 h280")
}

AddSelectedWindow(selGui, selList, windows, *) {
    global WindowWhitelist, WhitelistList
    selIndex := selList.Value
    if !selIndex
        return
    selectedProc := windows[selIndex].proc
    if !WindowWhitelist.Has(selectedProc) {
        WindowWhitelist[selectedProc] := true
        WhitelistList.Add([selectedProc])
    }
    selGui.Destroy()
}

RemoveSelectedApps(*) {
    global WindowWhitelist, WhitelistList
    selected := WhitelistList.Value
    if !selected
        return
    if !IsObject(selected)
        selected := [selected]
    allItems := ControlGetItems(WhitelistList)
    i := selected.Length
    while i >= 1 {
        idx := selected[i]
        itemText := allItems[idx]
        if WindowWhitelist.Has(itemText)
            WindowWhitelist.Delete(itemText)
        WhitelistList.Delete(idx)
        i -= 1
    }
}

IsWhitelistedActive() {
    global WindowWhitelist, WhitelistEnabled

    if !WhitelistEnabled
        return true

    try hwnd := WinGetID("A")
    catch
        return false   ; No active window yet (alt-tab transition etc.)

    if !hwnd
        return false

    try proc := WinGetProcessName("ahk_id " hwnd)
    catch
        return false

    return WindowWhitelist.Has(proc)
}

; ===== GUI CREATION =============
gui1 := Gui("+AlwaysOnTop", "Light AC v2.02")
gui1.SetFont("s10", "Segoe UI")

; --- LEFT CLICK ---
gui1.AddGroupBox("x15 y10 w340 h125", "Left Click")
L_enable := gui1.AddCheckBox("x30 y32", "Enable Left Clicker")
L_dropdown := gui1.AddDropDownList("x180 y29 w150 Choose1", ["Click Speed", "Hold Settings", "Randomization"])
L_cpsText := gui1.AddText("x30 y58", "CPS")
L_cpsSlider := gui1.AddSlider("x30 y75 w250 Range1-20 ToolTip", L.cps)
L_cpsValue := gui1.AddText("x290 y58 w50 Right", L.cps)
L_holdText := gui1.AddText("x30 y58 Hidden", "Hold Delay (ms)")
L_holdSlider := gui1.AddSlider("x30 y75 w250 Range0-1000 ToolTip Hidden", L.hold)
L_holdValue := gui1.AddText("x290 y58 w50 Right Hidden", L.hold)
L_randCheck := gui1.AddCheckBox("x30 y58 Hidden", "Enable Randomization")
L_randSlider := gui1.AddSlider("x30 y85 w250 Range0-40 ToolTip Hidden", L.rand)
L_randValue := gui1.AddText("x290 y68 w50 Right Hidden", "±" . L.rand . "%")

; --- RIGHT CLICK ---
gui1.AddGroupBox("x15 y150 w340 h125", "Right Click")
R_enable := gui1.AddCheckBox("x30 y172", "Enable Right Clicker")
R_dropdown := gui1.AddDropDownList("x180 y169 w150 Choose1", ["Click Speed", "Hold Settings", "Randomization"])
R_cpsText := gui1.AddText("x30 y198", "CPS")
R_cpsSlider := gui1.AddSlider("x30 y215 w250 Range1-20 ToolTip", R.cps)
R_cpsValue := gui1.AddText("x290 y198 w50 Right", R.cps)
R_holdText := gui1.AddText("x30 y198 Hidden", "Hold Delay (ms)")
R_holdSlider := gui1.AddSlider("x30 y215 w250 Range0-1000 ToolTip Hidden", R.hold)
R_holdValue := gui1.AddText("x290 y198 w50 Right Hidden", R.hold)
R_randCheck := gui1.AddCheckBox("x30 y198 Hidden", "Enable Randomization")
R_randSlider := gui1.AddSlider("x30 y225 w250 Range0-40 ToolTip Hidden", R.rand)
R_randValue := gui1.AddText("x290 y208 w50 Right Hidden", "±" . R.rand . "%")

; --- WHITELIST ---
gui1.AddGroupBox("x15 y285 w340 h140", "Application Whitelist")
WhitelistToggle := gui1.AddCheckBox("x30 y305 Checked", "Enable Whitelist Mode")
WhitelistList := gui1.AddListBox("x30 y330 w260 h72 Multi")
AddAppBtn := gui1.AddButton("x300 y330 w40 h31", "+")
RemoveAppBtn := gui1.AddButton("x300 y370 w40 h31", "-")

gui1.Show("w370 h440")
gui1.OnEvent("Close", (*) => gui1.Hide())

; ===== SETTINGS WINDOW =========
global settingsGui, AlwaysOnTopToggle
settingsGui := Gui("+AlwaysOnTop", "Settings")
settingsGui.SetFont("s10", "Segoe UI")

AlwaysOnTopToggle := settingsGui.AddCheckBox("x20 y20", "Keep Main Window On Top")
AlwaysOnTopToggle.Value := true  ; default enabled
AlwaysOnTopToggle.OnEvent("Click", ToggleAlwaysOnTop)
settingsGui.AddButton("x20 y60 w80 h25", "Close").OnEvent("Click", (*) => settingsGui.Hide())

ToggleAlwaysOnTop(*) {
    global AlwaysOnTopToggle, gui1
    if AlwaysOnTopToggle.Value
        gui1.SetAlwaysOnTop(true)
    else
        gui1.SetAlwaysOnTop(false)
}

A_TrayMenu.Add("Settings", (*) => settingsGui.Show())

; ===== ATTACH EVENTS ===========
L_cpsSlider.OnEvent("Change", UpdateLCPS)
L_holdSlider.OnEvent("Change", UpdateLHold)
L_randSlider.OnEvent("Change", UpdateLRand)
R_cpsSlider.OnEvent("Change", UpdateRCPS)
R_holdSlider.OnEvent("Change", UpdateRHold)
R_randSlider.OnEvent("Change", UpdateRRand)

; Dropdowns
L_dropdown.OnEvent("Change", (*) => UpdateSection("L"))
R_dropdown.OnEvent("Change", (*) => UpdateSection("R"))

; Checkboxes
L_enable.OnEvent("Click", (*) => L.enabled := L_enable.Value)
R_enable.OnEvent("Click", (*) => R.enabled := R_enable.Value)
WhitelistToggle.OnEvent("Click", ToggleWhitelist)
AddAppBtn.OnEvent("Click", AddActiveApp)
RemoveAppBtn.OnEvent("Click", RemoveSelectedApps)

; ===== TRAY MENU ===============
A_TrayMenu.Delete()
A_TrayMenu.Add("Open Auto Clicker", (*) => gui1.Show())
A_TrayMenu.Add("Toggle Whitelist", ToggleWhitelistTray)
;A_TrayMenu.Add("Settings", (*) => settingsGui.Show())
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())

; ===== HOTKEY CONTROLS =========
^o::
{
    L.enabled := !L.enabled
    L_enable.Value := L.enabled
    ShowTip("Left Clicker: " . (L.enabled ? "Enabled" : "Disabled"))
}
^p::
{
    R.enabled := !R.enabled
    R_enable.Value := R.enabled
    ShowTip("Right Clicker: " . (R.enabled ? "Enabled" : "Disabled"))
}

; ===== LEFT CLICK ADJUSTMENTS ===== 
;^, & -:: AdjustLeft("cps", -1) 
;^, & +:: AdjustLeft("cps", 1) 
;^. & -:: AdjustLeft("rand", -1)
; ^. & +:: AdjustLeft("rand", 1) 
;^/ & -:: AdjustLeft("hold", -10)
; ^/ & +:: AdjustLeft("hold", 10) 
; ===== RIGHT CLICK ADJUSTMENTS ===== 
;^, & [:: AdjustRight("cps", -1) 
;^, & ]:: AdjustRight("cps", 1) 
;^. & [:: AdjustRight("rand", -1) 
;^. & ]:: AdjustRight("rand", 1) 
;^/ & [:: AdjustRight("hold", -10) 
;^/ & ]:: AdjustRight("hold", 10)

AdjustLeft(type, amount)
{
    global L
    global L_cpsSlider, L_cpsValue
    global L_randSlider, L_randValue
    global L_holdSlider, L_holdValue

    switch type
    {
        case "cps":
            L.cps := Max(1, Min(20, L.cps + amount))
            L_cpsSlider.Value := L.cps
            L_cpsValue.Text := L.cps
            ShowTip("Left CPS: " . L.cps)

        case "rand":
            L.rand := Max(0, Min(40, L.rand + amount))
            L_randSlider.Value := L.rand
            L_randValue.Text := "±" . L.rand . "%"
            ShowTip("Left Random: ±" . L.rand . "%")

        case "hold":
            L.hold := Max(0, Min(1000, L.hold + amount))
            L_holdSlider.Value := L.hold
            L_holdValue.Text := L.hold
            ShowTip("Left Delay: " . L.hold . " ms")
    }
}

AdjustRight(type, amount)
{
    global R
    global R_cpsSlider, R_cpsValue
    global R_randSlider, R_randValue
    global R_holdSlider, R_holdValue

    switch type
    {
        case "cps":
            R.cps := Max(1, Min(20, R.cps + amount))
            R_cpsSlider.Value := R.cps
            R_cpsValue.Text := R.cps
            ShowTip("Right CPS: " . R.cps)

        case "rand":
            R.rand := Max(0, Min(40, R.rand + amount))
            R_randSlider.Value := R.rand
            R_randValue.Text := "±" . R.rand . "%"
            ShowTip("Right Random: ±" . R.rand . "%")

        case "hold":
            R.hold := Max(0, Min(1000, R.hold + amount))
            R_holdSlider.Value := R.hold
            R_holdValue.Text := R.hold
            ShowTip("Right Delay: " . R.hold . " ms")
    }
}

; TOOLTIP
ShowTip(text)
{
    ToolTip(text)
    SetTimer(ClearTip, -1000)
}

ClearTip(*)
{
    ToolTip()
}

; ===== TIMER & CLICK LOGIC =====
L_AutoClickTimer := AutoClick.Bind("L")
R_AutoClickTimer := AutoClick.Bind("R")
L_CheckHoldTimer := CheckHold.Bind("L")
R_CheckHoldTimer := CheckHold.Bind("R")

~*LButton::{
    if (!L.enabled)
        return
    L.pressTime := A_TickCount
    SetTimer(L_CheckHoldTimer, 10)
}

~*LButton Up:: StopClicking("L")

~*RButton::{
    if (!R.enabled)
        return
    R.pressTime := A_TickCount
    SetTimer(R_CheckHoldTimer, 10)
}

~*RButton Up:: StopClicking("R")

StopClicking(side) {
    local obj := (side="L") ? L : R
    obj.clicking := false
    SetTimer((side="L") ? L_AutoClickTimer : R_AutoClickTimer, 0)
    SetTimer((side="L") ? L_CheckHoldTimer : R_CheckHoldTimer, 0)
}

CheckHold(side) {
    local obj := (side="L") ? L : R
    key := (side="L") ? "LButton" : "RButton"
    if (!GetKeyState(key, "P")) {
        StopClicking(side)
        return
    }
    if (!obj.clicking && (A_TickCount - obj.pressTime >= obj.hold)) {
        obj.clicking := true
        SetTimer((side="L") ? L_AutoClickTimer : R_AutoClickTimer, 1)
    }
}

AutoClick(side) {
    local obj := (side="L") ? L : R
    key := (side="L") ? "LButton" : "RButton"
    btn := (side="L") ? "Left" : "Right"
    if (!obj.clicking
        || !GetKeyState(key, "P")
        || !IsWhitelistedActive()
        || ((side="L") && !L.enabled)
        || ((side="R") && !R.enabled)) {
        StopClicking(side)
        return
    }
    base := 1000 / obj.cps
    if (obj.randOn && obj.rand > 0) {
        var := base * (obj.rand / 100)
        delay := base + Random(-var, var)
    } else
        delay := base
    Click btn
    SetTimer((side="L") ? L_AutoClickTimer : R_AutoClickTimer, -delay)
}
