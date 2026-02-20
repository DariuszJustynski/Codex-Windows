@echo off
title Codex Launcher
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\run.ps1" -Reuse
pause
