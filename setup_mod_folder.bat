@echo off
SETLOCAL

IF [%2%]==[] (
	echo usage:
	echo setup_mod_folder.bat [mod_name] [target_path]
	EXIT /B 1
)

SET mod_name=%1
SET target_path=%2

echo mod_name=%mod_name%, target_path=%target_path%

IF NOT EXIST %mod_name% (
	echo mod folder not found!
	EXIT /B 2
)

IF EXIST %target_path% (
	echo Target folder already exists!
	EXIT /B 3
)

IF NOT EXIST %mod_name%\res\scripts\lib (
	mklink /D %mod_name%\res\scripts\lib ..\..\..\_common_res\scripts\lib
)

mklink /D %target_path% %CD%\%mod_name%

echo Success!

EXIT /B 0