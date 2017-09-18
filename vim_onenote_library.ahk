IsLastHotkey(key)
{
    return (A_PriorHotkey == key and A_TimeSincePriorHotkey < 800)
}

IsLastkey(key)
{
    return (A_Priorkey == key and A_TimeSincePriorkey < 800)
}

SaveClipboard(){
    ; push clipboard to variable
    global ClipSaved := ClipboardAll
    ; Clear clipboard to avoid errors
    Clipboard :=
}

Copy(){
    SaveClipboard()
    send ^c
    ClipWait, 0.1
}

Paste(){
    Send %Clipboard%
    RestoreClipboard()
}

RestoreClipboard(){
    ;restore original clipboard
    global ClipSaved
    Clipboard := ClipSaved
    ;ClipWait
    ClipSaved := ; free memory
}

GetSelectedText(){
    Copy()
    Output := Clipboard
    RestoreClipboard()
    return Output
}