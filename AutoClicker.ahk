; Left Click Auto Clicer v3 (adjustable randomization)

#Requires AutoHotkey v2.0
#Warn

global toggle := false
global clicking := false
global cps := 12
global maxCPS := 20
global minCPS := 1
global delay := 1000 / cps
global holdDelay := 140   
global pressTime := 0

; ===== Randomization Settings =====
global randomizationEnabled := true
global randomPercent := 12      ; default ±12%
global maxRandomPercent := 40
global minRandomPercent := 0

UpdateDelay() {
    global cps, delay, clicking
    delay := 1000 / cps

    if (clicking) {
        SetTimer(AutoClick, 0)
        SetTimer(AutoClick, -delay)
    }
}

; =========================
; TOGGLE AUTOCLICKER
; =========================
^`::
{
    global toggle, clicking
    toggle := !toggle

    if (!toggle) {
        clicking := false
        SetTimer(AutoClick, 0)
        ToolTip("Autoclicker OFF")
    } else {
        ToolTip("Autoclicker ON")
    }

    SetTimer(() => ToolTip(), -1000)
}

; =========================
; CPS CONTROLS
; =========================

^=::   ; Ctrl + =
{
    global cps, maxCPS
    if (cps < maxCPS) {
        cps++
        UpdateDelay()
        ToolTip("CPS: " cps)
        SetTimer(() => ToolTip(), -800)
    }
}

^-::   ; Ctrl + -
{
    global cps, minCPS
    if (cps > minCPS) {
        cps--
        UpdateDelay()
        ToolTip("CPS: " cps)
        SetTimer(() => ToolTip(), -800)
    }
}

; =========================
; RANDOMIZATION CONTROLS
; =========================

+=::   ; Shift + =
{
    global randomPercent, maxRandomPercent
    if (randomPercent < maxRandomPercent) {
        randomPercent += 2
        ToolTip("Randomization: ±" randomPercent "%")
        SetTimer(() => ToolTip(), -800)
    }
}

+-::   ; Shift + -
{
    global randomPercent, minRandomPercent
    if (randomPercent > minRandomPercent) {
        randomPercent -= 2
        ToolTip("Randomization: ±" randomPercent "%")
        SetTimer(() => ToolTip(), -800)
    }
}

+`::  ; Shift + C → Toggle randomization
{
    global randomizationEnabled
    randomizationEnabled := !randomizationEnabled

    if (randomizationEnabled)
        ToolTip("Randomization ON")
    else
        ToolTip("Randomization OFF")

    SetTimer(() => ToolTip(), -1000)
}

; =========================
; SAFER LEFT CLICK DETECTION
; =========================

~*LButton::
{
    global toggle, pressTime

    if (!toggle)
        return

    pressTime := A_TickCount
    SetTimer(CheckHold, 10)
}

CheckHold()
{
    global pressTime, holdDelay, clicking, delay, toggle

    if (!GetKeyState("LButton", "P")) {
        SetTimer(CheckHold, 0)
        return
    }

    if (!clicking && (A_TickCount - pressTime >= holdDelay)) {
        clicking := true
        SetTimer(CheckHold, 0)
        SetTimer(AutoClick, 1)
    }
}

~*LButton Up::
{
    global clicking
    clicking := false
    SetTimer(AutoClick, 0)
    SetTimer(CheckHold, 0)
}

; =========================
; RANDOMIZED AUTOCLICK
; =========================

AutoClick()
{
    global clicking, cps, randomizationEnabled, randomPercent

    static nextClickTime := 0

    if (!clicking)
        return

    currentTime := A_TickCount

    if (nextClickTime = 0)
        nextClickTime := currentTime

    baseDelay := 1000 / cps

    if (randomizationEnabled && randomPercent > 0) {
        variation := baseDelay * (randomPercent / 100)
        targetDelay := baseDelay + Random(-variation, variation)
    } else {
        targetDelay := baseDelay
    }

    if (currentTime >= nextClickTime) {
        Click
        nextClickTime := currentTime + targetDelay
    }

    SetTimer(AutoClick, 1)
}
