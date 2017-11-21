﻿; Onenote requires signin before starting useability.
; This subverts that.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance Force
SetTitleMatchMode 2
msgbox

; Env variables encrypted by appveyor.
; Store login info to use for onenote registration.
; Env variables encrypted by appveyor.
; Store login info to use for onenote registration.
EnvGet,ONUser,OnenoteUser
EnvGet,ONPass,OnenotePass

Run, OneNote,,,OneNotePID

sleep, 500
WinActivate,OneNote
WinWaitActive,OneNote
sleep, 500
send {return}
WinWaitActive,Accounts
sleep, 500
send %ONUser%
send {return}
sleep, 1000
send %ONPass%{return}
winwait,Office
send {return}
winwait,OneNote ; Wait for onenote to start
sleep, 200
WinActivate,OneNote
WinWaitActive,OneNote
; wait for notebook load
sleep, 2000


/* Not using this method because it is too unreliable for testing

; Demo .one file to skip new notebook creation
UrlDownloadToFile, https://www.onenotegem.com/uploads/8/5/1/8/8518752/things_to_do_list.one, %A_Scriptdir%\test.one

; This registry entry bypasses the signin.
RegContents =
(
Windows Registry Editor Version 5.00`r
`r
[HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\OneNote]`r
"FirstBootStatus"=dword:01000101`r
"OneNoteName"="OneNote"`r
)
RegFileName=%A_ScriptDir%\avoidONSignin.reg
RegFile := FileOpen(RegFileName, "w")
RegFile.Write(RegContents)
RegFile.Close()
run %RegFileName%
sleep, 50
send {return}
sleep, 50
send {return}
sleep, 50
send {return}

Run, OneNote,,,OneNotePID
; winwait, - Microsoft OneNote ; Wait for onenote to start
sleep, 500
send {return}
WinActivate,OneNote
WinWaitActive,OneNote
; Skip signin dialogues, add new notebook.
send {return}
sleep, 100
send {return}
sleep, 500

run C:\projects\vim-keybindings-for-onenote\test.one
sleep, 200
winwait,OneNote ; Wait for onenote to start
sleep, 501
WinActivate,OneNote
WinWaitActive,OneNote
send ^n{return}
sleep, 700
send {return}
*/