@echo off
title Cellular Watchdog - auto-recover when service drops
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Switch-CellularTech.ps1" watch
pause
