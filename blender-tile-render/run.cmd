@echo off

REM Adjust path as needed
SET BLENDER_PATH="C:\Program Files\Blender Foundation\Blender 4.0\blender.exe"
SET PORT=8080
SET DEFAULT_CYCLES_DEVICE=CPU

%BLENDER_PATH% -noaudio --background --log-level 0 --python tile-web.py --port %PORT% --cycles-device %DEFAULT_CYCLES_DEVICE%
pause
