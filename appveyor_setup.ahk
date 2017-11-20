﻿; Onenote requires signin before starting useability.
; This subverts that.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance Force

; Demo .one file to skip new notebook creation
UrlDownloadToFile, https://www.onenotegem.com/uploads/8/5/1/8/8518752/things_to_do_list.one, %A_Scriptdir%\test.one

; This registry entry bypasses the signin.
RegContents =
(
[HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\OneNote]
"FirstBootStatus"=dword:02000104
"OneNoteName"="OneNote"
)
RegFileName=%A_ScriptDir%\avoidONSignin.reg
RegFile := FileOpen(RegFileName, "w")
RegFile.Write(RegContents)
RegFile.Close()
run %RegFileName%
send {return}

Run, OneNote,,,OneNotePID
winwait, - Microsoft OneNote ; Wait for onenote to start
sleep, 300
WinActivate,OneNote
WinWaitActive,OneNote
; Skip signin dialogues, add new notebook.
send {return}
sleep, 100
send {return}
sleep, 100

run C:\projects\vim-keybindings-for-onenote\test.one
winwait, - Microsoft OneNote ; Wait for onenote to start
sleep, 300
WinActivate,OneNote
WinWaitActive,OneNote
send !f4