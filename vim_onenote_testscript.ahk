﻿; This script requires vim installed on the computer. It effectively diffs the results of sending the keys below to a new onenote page vs to a new vim document.
; This may also be true of e, w and b, due to the way onenote handles words (treating punctuation as a word)

; Results are outputed as the current time and date in %A_ScriptDir%\testlogs

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force
#warn
sendlevel, 1 ; So these commands get triggered by autohotkey.
SetTitleMatchMode 2 ; window title functions will match by containing the match text. 
SetKeyDelay, 50 ; Only affects sendevent, used for sending the test
; (gives vim script time to react).

; Contains clipboard related functions, among others.
#include %A_ScriptDir%\vim_onenote_library.ahk

; 1 optional commandline argument, -quiet, stops ouput at the end of the tests.
; Used for CI testing.
arg1 = %1%
if (arg1 == "-quiet"){
    QuietMode := True
}else{
    QuietMode := False
}

TestsFailed := False
LogFileName = testLogs\%A_Now%.txt ;%A_Scriptdir%\testlogs\%A_Now%.txt

; Initialise the programs
SetWorkingDir %A_ScriptDir%\TestingLogs  ; Temp vim files are put out of the way.
run, cmd.exe /r gvim,,,VimPID
winwait,  - GVIM ; Wait for vim to start
SetWorkingDir %A_ScriptDir%  
send :imap jj <esc>{return} ; Prepare vim    
;TODO: Check if onenote already open. Or just ignore? multiple windows may cause problems.
;       May be fixed by making the switch specific to the test page.
Run, OneNote,,,OneNotePID
winwait, - OneNote ; Wait for onenote to start
sleep, 200
WinActivate,OneNote
WinWaitActive,OneNote
send ^nVim Onenote Test{return} ; Create a new page in onenote, name it, move to text section
WinMaximize,OneNote

run, %A_ScriptDir%/vim_onenote.ahk,,, AHKVimPID ; Run our vim emulator script.

; Set all our scripts and two testing programs to Above normal priority, for test reliability.
Process, Priority, ,A ; This script
Process, Priority, OneNotePID,A
Process, Priority, VimPID,A
Process, Priority, AHKVimPID,A
; They all get killed on script end anyway.

; This is the text that all of the tests are run on, fresh.
; Feel free to add extra lines to the end, if your test needs them.
; The test will be send from normal mode, with the cursor at the start of the sample text.
SampleText =
(
This is the first line of the test, and contains a comma and a period.
Second line here
3rd line. The second line is shorter than both 1st and 3rd line.
The fourth line contains     some additional whitespace.
What should I put on the 5th line?A missing space, perhaps
This line 6 should be longer than the line before it and after it to test kj
No line, including 7, can be longer than 80 characters.
This is because onenote wraps automatically, (line 8)
And treats a wrapped line as separate lines (line 9)
)

; Additional test cases should be added to testcases.txt
ArrayOfTests := [""] ; Base case, ensures the sample is entered the same between the two.
ReadFileWithComments(ArrayOfTests)

ReadFileWithComments(OutputArray){
    Loop, read, testcases.txt
    {
        Line := A_LoopReadLine
        output := StrSplit(Line, ";")
        if(Output.Length() > 0 AND strlen(Output[1]) > 0)
        {
            testString := output[1]
            ; escape special chars
            StringReplace, testString, testString, ^, {^}, A
            StringReplace, testString, testString, +, {+}, A
            StringReplace, testString, testString, #, {#}, A
            StringReplace, testString, testString, !, {!}, A
            OutputArray.push(testString)
        }
    }
}

RunTests() ; Lets get this show on the road


RunTests(){
    Global ArrayOfTests
    for index, test in ArrayOfTests
    {
        ; msgbox Current test: "%test%"
        TestAndCompareOutput(test)
    }
    EndTesting()
}

SwitchToVim(){
    WinActivate,  - GVIM
    WinWaitActive,  - GVIM
}

SwitchToOnenote(){
    WinActivate,OneNote
    WinWaitActive,OneNote
}

SendTestToOnenoteAndReturnResult(test){
    Global SampleText
    SwitchToOnenote()
    ; Make sure at start of body of onenote, and it's empty.
    send ^a^a{delete}
    ; Ensure insert mode for the sample text.
    sendevent i{backspace}
    sleep, 20
    ; Paste sample text. Faster, more reliable.
    SaveClipboard()
    Clipboard :=""
    Clipboard := SampleText
    Clipwait
    sendevent ^v ; Paste, for some reason normal send won't work.
    RestoreClipboard()
    sleep,50 
    ; Make sure we are in normal mode to start with, at start of text.
    send {esc}
    sleep, 50
    send ^{home} 
    sendevent %test%
    sleep, 50
    send ^a^a^a ; Ensure we select all of the inserted text.
    output := GetSelectedText()
    ; Delete text ready for next test
    send {backspace}
    return output
}

SendTestToVimAndReturnResult(test){
    Global SampleText
    SwitchToVim()
    ; Ensure insert mode for the sample text.
    send i{backspace}
    send %SampleText%
    sleep, 50
    ; Make sure we are in normal mode to start with, at start of text.
    send {esc}^{home}
    send %test%
    sleep, 50
    SaveClipboard()
    clipboard= ; Empty the clipboard for clipwait to work
    send {esc}:`%d{numpadAdd} ; select all text, cut to system clipboard
    send {return}
    ClipWait
    output := Clipboard
    RestoreClipboard()
    return output
}

TestAndCompareOutput(test){
    global Log
    OnenoteOutput := SendTestToOnenoteAndReturnResult(test)
    VimOutput := SendTestToVimAndReturnResult(test)
    CompareStrings(OnenoteOutput, VimOutput, test)
}

CompareStrings(OnenoteOutput, VIMOutput, CurrentTest){
    Global LogFileName
    Global TestsFailed
    ; Store files in separate dir.
    SetWorkingDir %A_ScriptDir%\TestingLogs  
    file1 := FileOpen("OnenoteOutput", "w")
    file2 := FileOpen("VIMOutput", "w")
    file1.write(OnenoteOutput)
    file2.write(VIMOutput)
    file1.close()
    file2.close()

    ; This line runs the DOS fc (file compare) program and enters the reults in a file.
    ; Could also consider using comp.exe /AL instead, to compare individual characters. Possibly more useful.
    ; Comp sucks. Wow. Using fc, but only shows two lines: the different one and the one after. Hard to see, but it'll do for now.
    DiffResult := ComObjCreate("WScript.Shell").Exec("cmd.exe /q /c fc.exe /LB2 /N OnenoteOutput VIMOutput").StdOut.ReadAll() 
    IfNotInString,DiffResult, FC: no differences encountered
    {
        TestsFailed := True
        LogFile := FileOpen(LogFileName, "a")
        LogEntry := "Test = """
        LogEntry = Test = "%CurrentTest%"`n%DiffResult%`n`n
        LogFile.Write(LogEntry) ; "Test = ""%CurrentTest%""`n%DiffResult%`n`n")
        LogFile.Close()
    }
    FileDelete, OnenoteOutput
    FileDelete, VIMOutput
    FileDelete, _.sw*
}

; Tidy up, close programs.
EndTesting(){
    Global TestsFailed
    Global LogFileName
    Global QuietMode
    ; Delete the new page in onenote
    SwitchToOnenote()
    send ^+A
    send {delete}
    SwitchToVim()
    send :q{!}
    send {return} ; Exit vim.
   
    if (TestsFailed == True)
    {
        if not QuietMode {
            msgbox,4,,At least one test has failed!`nResults are in %LogFileName%`nOpen log? 
            IfMsgBox Yes
            {
                run %LogFileName%
            }
        }
        EndScript(1)
    }else{
        if not QuietMode {
            msgbox, All tests pass!
        }
        EndScript(0)
    }
}




EndScript(exitCode){
    Global OneNotePID
    Global AHKVimPID
    Global VimPID
    process, Close, %OneNotePID%
    process, Close, %AHKVimPID%
    process, Close, %VimPID%
    if exitCode = 1
        ExitApp, 1 ; Failed exit
    else
        ExitApp, 0 ; Success.
}

EndScript(1)

+ & esc::EndScript(1) ; Abort
