
@echo off
setlocal enabledelayedexpansion
title ARSLANIUS 26

:boot
color 0f
set "root_path=%~dp0"
if "%root_path:~-1%"=="\" set "root_path=%root_path:~0,-1%"

set "current_build=56.2"
set "config_root=%root_path%\Settings And System Files"
set "kernel_path=%config_root%\kernel.dll"
set "users_root=%root_path%\Users"
set "reg_version=26"
set "programs_root=%root_path%\Programs"
set "sys_prof=%config_root%\systemprofile"
set "sys_services=%config_root%\systemprofile"
set "reg_path=%config_root%\REG.cfg"
set "log_path=%config_root%\system.log"
set "restore_root=%root_path%\RestorePoints"
if exist "%root_path%\Setting And System Files" (
    if not exist "%root_path%\Settings And System Files" (
        ren "%root_path%\Setting And System Files" "Settings And System Files"
    )
)

set "boot_timeout=30"
set "default_mode=1"
set "boot_choice="
set "safe_mode=0"
set "rec=0"
set "diagnostic=0"
set "last_successful_mode=1"

if exist "%root_path%\Settings And System Files\BCD" (
    for /f "tokens=1,* delims==" %%a in ('type "%root_path%\Settings And System Files\BCD" 2^>nul') do (
        if "%%a"=="BOOT_TIMEOUT" set "boot_timeout=%%b"
        if "%%a"=="DEFAULT_MODE" set "default_mode=%%b"
        if "%%a"=="LAST_SUCCESSFUL_MODE" set "last_successful_mode=%%b"
    )
)

cls
echo ======================================================================================================================
echo                                                 ARSLANIUS BOOT MANAGER 
echo ======================================================================================================================
if %last_successful_mode% NEQ 0 (
    echo  Last Known Good Configuration [Mode %last_successful_mode%]
)
echo  1. Start ARSLANIUS Normally
echo  2. Safe Mode (No Services / No Autorun)
echo  3. Recovery Environment 
echo  4. Diagnostic Mode LOCAL
echo  5. Diagnostic Mode NETWORK
echo ----------------------------------------------------------------------------------------------------------------------
echo  Auto-boot in %boot_timeout% seconds...
echo ======================================================================================================================

choice /C 12345 /N /T %boot_timeout% /D %default_mode% /M "Select option (1-5): "
set "boot_choice=%errorlevel%"

if "%boot_choice%"=="1" (
    cls
    echo ======================================================================================================================
    echo                                                 Loading ARSLANIUS 26
    echo         Build: %current_build%
    echo         Kernel: BarOS 22.0
    echo ======================================================================================================================
    timeout /t 2 >nul
)

if "%boot_choice%"=="2" (
    if NOT "%boot_choice%"=="1" if NOT "%boot_choice%"=="3" if NOT "%boot_choice%"=="4" if NOT "%boot_choice%"=="5" (
        cls
        color 0f
        set "safe_mode=1"
        echo ======================================================================================================================
        echo                                                 ARSLANIUS BOOT MANAGER
        echo ======================================================================================================================
        if NOT exist "%config_root%" 2>nul (
            echo ...
        )
        if exist "%config_root%\BCD" 2>nul (
            echo Loaded: \Settings And System Files\BCD
        )
        if exist "%kernel_path%" 2>nul (
            echo Loaded: \Settings And System Files\kernel.dll
        )
        timeout /t 1 >nul
        if exist "%kernel_path%" 2>nul (
            echo Loaded: \Settings And System Files\REG.cfg
        )
        timeout /t 1 >nul
        if exist "%sys_services%" 2>nul (
            echo Loaded: \Settings And System Files\systemprofile
        )
        timeout /t 1 >nul
        echo.
        echo [ INFO ] Safe Mode enabled.
        timeout /t 1 >nul
        del /f /q "%sys_services%\SysPulse.active" 2>nul
        del /f /q "%sys_services%\SFC_Daemon.active" 2>nul
        del /f /q "%sys_services%\NetMonitor.active" 2>nul
    )
)

if "%boot_choice%"=="3" (
    timeout /t 1 >nul
    cls 
    echo .
    timeout /t 1 >nul
    cls
    echo ..
    timeout /t 1 >nul
    cls
    echo ...
    timeout /t 1 >nul
    cls 
    echo .
    timeout /t 1 >nul
    cls
    echo ..
    timeout /t 1 >nul
    cls
    echo ...
    timeout /t 1 >nul
    del /f /q "%sys_services%\SysPulse.active"
    del /f /q "%sys_services%\SFC_Daemon.active"
    del /f /q "%sys_services%\NetMonitor.active"
    goto repair
)

if "%boot_choice%"=="4" (
    timeout /t 1 >nul
    cls 
    echo .
    timeout /t 1 >nul
    cls
    echo ..
    timeout /t 1 >nul
    cls
    echo ...
    timeout /t 1 >nul
    cls 
    echo .
    timeout /t 1 >nul
    cls
    del /f /q "%sys_services%\SFC_Daemon.active"
    del /f /q "%sys_services%\NetMonitor.active"
    set "diagnostic=1"
    goto interface
)

if "%boot_choice%"=="5" (
    timeout /t 1 >nul
    cls 
    echo .
    timeout /t 1 >nul
    cls
    echo ..
    timeout /t 1 >nul
    cls
    echo ...
    timeout /t 1 >nul
    cls 
    echo .
    timeout /t 1 >nul
    cls
    del /f /q "%sys_services%\SFC_Daemon.active"
    del /f /q "%sys_services%\SysPulse.active"
    set "diagnostic=2"
    goto interface
)

if NOT exist "%config_root%" (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000001a
    echo Info: CONFIG_ROOT_NOT_FOUND
    echo.
    echo File: \Settings And System Files
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=1a" & goto bsod
    exit
)

if not exist "%config_root%\BCD" (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000014
    echo Info: BCD_NOT_FOUND
    echo.
    echo File: \Settings And System Files\BCD
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" goto repair 
    exit
)

set "bcd_error=0"
findstr /i "BOOT_TIMEOUT" "%root_path%\Settings And System Files\BCD" >nul || set "bcd_error=1"
findstr /i "DEFAULT_MODE" "%root_path%\Settings And System Files\BCD" >nul || set "bcd_error=1"

if %bcd_error% EQU 1 (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000013
    echo Info: BCD_CORRUPTED
    echo.
    echo File: \Settings And System Files\BCD
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" goto repair
    exit
)

if exist "%kernel_path%" goto kernel_ok
cls
color 0f
echo ======================================================================================================================
echo                                                 ARSLANIUS BOOT MANAGER
echo ======================================================================================================================
echo.
echo ARSLANIUS failed to start. A recent hardware or software change might be
echo the cause.
echo.
echo Status: 0xc00000001
echo Info: KERNEL_NOT_FOUND
echo.
echo File: \Settings And System Files\kernel.dll
echo.
echo Press [R] to Repair
echo Press [Enter] to Exit
echo.
echo ======================================================================================================================
set /p "choice=> "
if /i "!choice!"=="R" set "bsod=1" & goto bsod
exit

if not exist "%root_path%\Settings And System Files\BCD" (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000014
    echo Info: BCD_NOT_FOUND
    echo.
    echo File: \Settings And System Files\BCD
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" goto repair
    exit
)

set "bcd_error=0"
findstr /i "BOOT_TIMEOUT" "%root_path%\Settings And System Files\BCD" >nul || set "bcd_error=1"
findstr /i "DEFAULT_MODE" "%root_path%\Settings And System Files\BCD" >nul || set "bcd_error=1"

if %bcd_error% EQU 1 (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000013
    echo Info: BCD_CORRUPTED
    echo.
    echo File: \Settings And System Files\BCD
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" goto repair
    exit
)

:repair
set "diagnostic=0"
set "rec=0"
cls
color 1f
echo ======================================================================================================================
echo                                             ARSLANIUS RECOVERY ENVIRONMENT
echo ======================================================================================================================
echo.
echo  [1] Startup Repair        - Fix kernel/registry
echo  [2] System Restore        - Go to restore points
echo  [3] System Image Recovery - Restore from backup
echo  [4] Command Line          - Mini cmd   
echo  [5] Memory Diagnostic     - Check system memory
echo  [6] Return to boot menu
echo.
echo ======================================================================================================================
set /p "recovery_choice=Select option (1-6): "

if "%recovery_choice%"=="1" goto startup_repair
if "%recovery_choice%"=="2" goto restore_menu
if "%recovery_choice%"=="3" goto image_recovery
if "%recovery_choice%"=="4" set "rec=1" & goto interface
if "%recovery_choice%"=="5" goto memory_diag
if "%recovery_choice%"=="6" goto boot
goto repair 

:startup_repair
echo.
echo [ WAIT ] Running Startup Repair...
if not exist "%config_root%" md "%config_root%"
if not exist "%sys_services%" md "%sys_services%" 2>nul

echo SYSTEM = -414170332 > "%kernel_path%"
echo SYSTEM ADMINISTRATOR = 156593571 >> "%kernel_path%"

timeout /t 1 >nul
cls 
echo .
timeout /t 1 >nul
cls
echo ..
timeout /t 1 >nul
cls
echo ...
timeout /t 1 >nul
cls 
echo .
timeout /t 1 >nul
cls
echo ..
timeout /t 1 >nul
cls
echo ...
timeout /t 1 >nul

if exist "%sys_services%\*.cnt" del /f /q "%sys_services%\*.cnt"

echo BOOT_TIMEOUT=30 > "%config_root%\BCD"
echo DEFAULT_MODE=1 >> "%config_root%\BCD"
echo LAST_SUCCESSFUL_MODE=1 >> "%config_root%\BCD"
echo BOOT_COUNT=0 >> "%config_root%\BCD"
echo LAST_BOOT_SUCCESS=%date% >> "%config_root%\BCD"

echo OS_NAME = ARSLANIUS 26 > "%reg_path%"
echo SYSTEM_COLOR=0e >> "%reg_path%"
echo ADMIN_COLOR=4f >> "%reg_path%"
echo USER_COLOR=1f >> "%reg_path%"
echo ENABLE_LUA=1 >> "%reg_path%"
echo REG_VERSION=%reg_version% >> "%reg_path%"

echo [%date% %time% INFO] KERNEL_RESTORED_BY_RECOVERY >> "%log_path%" 2>nul
echo.
echo [ OK ] Startup Repair completed.
pause
goto repair

:restore_menu
if not exist "%config_root%" md "%config_root%"
if not exist "%restore_root%" (
    echo [ ERROR ] No restore points directory.
    pause & goto repair 
)

echo Available restore points:
dir /b "%restore_root%"
echo.
set /p "rp_sel=Enter restore point name (or 0 for exit): "

if "%rp_sel%"=="0" goto repair
if "%rp_sel%"=="" goto restore_menu
if not exist "%restore_root%\%rp_sel%\kernel.dll" (
    echo [ ERROR ] Invalid restore point.
    pause & goto repair
)

copy /y "%restore_root%\%rp_sel%\kernel.dll" "%kernel_path%" >nul
copy /y "%restore_root%\%rp_sel%\REG.cfg" "%reg_path%" >nul
copy /y "%restore_root%\%rp_sel%\system.log" "%log_path%" >nul

timeout /t 1 >nul
cls 
echo .
timeout /t 1 >nul
cls
echo ..
timeout /t 1 >nul
cls
echo ...
timeout /t 1 >nul
cls 
echo .
timeout /t 1 >nul
cls
echo ..
timeout /t 1 >nul
cls
echo ...
timeout /t 1 >nul

echo [%date% %time% INFO] RESTORE_APPLIED_FROM_RECOVERY: %rp_sel% >> "%log_path%" 2>nul
echo.
echo [ OK ] System restored from %rp_sel%.
pause
goto repair

:image_recovery
echo.
echo ===== SYSTEM IMAGE RECOVERY =====
echo.
if exist "%root_path%\Backup\" (
    echo [ FOUND ] Backup directory detected.
    echo Files ready for recovery.
) else (
    echo [ ERROR ] No backup image found.
    echo Please place backup in: %root_path%\Backup\
    pause
    goto repair
)

set /p "img_confirm=Restore from backup? (Y/N): "
if /i not "!img_confirm!"=="Y" goto repair

echo [ WAIT ] Restoring system image...
xcopy /e /y "%root_path%\Backup\*" "%root_path%\" >nul 2>&1
timeout /t 1 >nul
cls 
echo .
timeout /t 1 >nul
cls
echo ..
timeout /t 1 >nul
cls
echo ...
timeout /t 1 >nul
cls 
echo .
timeout /t 1 >nul
cls
echo ..
timeout /t 1 >nul
cls
echo ...
timeout /t 1 >nul
echo [%date% %time%] IMAGE_RESTORE_EXECUTED >> "%log_path%" 2>nul
echo [ OK ] System image restored.
pause
goto repair

:memory_diag
cls
color 1f
echo ======================================================================================================================
echo                                             ARSLANIUS MEMORY DIAGNOSTIC
echo ======================================================================================================================
echo.
echo Checking for memory problems...
echo.
set /a "total=0"
set /a "tested=0"
for /l %%i in (1,1,10) do (
    set /a "tested+=1"
    set /a "total+=64"
    echo Progress: !tested!0%% complete...
    timeout /t 1 >nul
)
echo.
echo [ PASS ] Memory test complete. No errors detected.
echo Total memory simulated: !total! MB
echo Status: Healthy
echo.
pause
goto repair

:kernel_ok
findstr /i /c:"BarOS AUTHORITY" "%kernel_path%" >nul
if !errorlevel! EQU 0 (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000005
    echo Info: RESERVED_USERNAME_DETECTED
    echo Security violation: Reserved username found in kernel.
    echo.
    echo File: \Settings And System Files\kernel.dll
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=5" & goto bsod
    exit
)

set "system_ok=0"
set "admin_ok=0"

for /f "tokens=1 delims==" %%a in ('findstr /i "SYSTEM =" "%kernel_path%"') do (
    set "chk=%%a"
    set "chk=!chk: =!"
    if "!chk!"=="SYSTEM" set "system_ok=1"
)

for /f "tokens=1 delims==" %%a in ('findstr /i "SYSTEM ADMINISTRATOR =" "%kernel_path%"') do (
    set "chk=%%a"
    set "chk=!chk: =!"
    if "!chk!"=="SYSTEMADMINISTRATOR" set "admin_ok=1"
)

if !system_ok! EQU 0 (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000008
    echo Info: KERNEL_INCOMPLETE
    echo.
    echo File: \Settings And System Files\kernel.dll
    echo.
    echo The kernel file is missing required SYSTEM account entries.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=8" & goto bsod
    exit
)

if !admin_ok! EQU 0 (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000008
    echo Info: KERNEL_INCOMPLETE
    echo.
    echo File: \Settings And System Files\kernel.dll
    echo.
    echo The kernel file is missing required ADMINISTRATOR account entries.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=8" & goto bsod
    exit
)

set "net_check_counter=0"

set "expected_system_hash=-414170332"
set "expected_admin_hash=156593571"

set "system_hash="
for /f "tokens=2 delims==" %%a in ('findstr /i /c:"SYSTEM =" "%kernel_path%" 2^>nul') do set "system_hash=%%a"
set "admin_hash="
for /f "tokens=2 delims==" %%a in ('findstr /i /c:"SYSTEM ADMINISTRATOR =" "%kernel_path%" 2^>nul') do set "admin_hash=%%a"

set "system_hash=!system_hash: =!"
set "admin_hash=!admin_hash: =!"

if not "!system_hash!"=="!expected_system_hash!" (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000002
    echo Info: SYSTEM_ACCOUNT_HASH_MISMATCH
    echo Expected: !expected_system_hash!
    echo Found: !system_hash!
    echo.
    echo File: \Settings And System Files\kernel.dll
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=2" & goto bsod
    exit
)

if not "!admin_hash!"=="!expected_admin_hash!" (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000006
    echo Info: ADMIN_ACCOUNT_HASH_MISMATCH
    echo Expected: !expected_admin_hash!
    echo Found: !admin_hash!
    echo.
    echo File: \Settings And System Files\kernel.dll
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=6" & goto bsod
    exit
)

if not exist "%reg_path%" (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000004
    echo Info: REGISTRY_NOT_FOUND
    echo.
    echo File: \Settings And System Files\REG.cfg
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=4" & goto bsod
    exit
)

for /f "tokens=2 delims==" %%n in ('findstr /i "OS_NAME" "%reg_path%"') do set "os_name=%%n"
for /f "tokens=2 delims==" %%c in ('findstr /i "SYSTEM_COLOR" "%reg_path%"') do color %%c

set "reg_error=0"
findstr /i "OS_NAME =" "%reg_path%" >nul || set "reg_error=1"
findstr /i "SYSTEM_COLOR=" "%reg_path%" >nul || set "reg_error=1"
findstr /i "ADMIN_COLOR=" "%reg_path%" >nul || set "reg_error=1"
findstr /i "USER_COLOR=" "%reg_path%" >nul || set "reg_error=1"
findstr /i "ENABLE_LUA=" "%reg_path%" >nul || set "reg_error=1"
findstr /i "REG_VERSION=" "%reg_path%" >nul || set "reg_error=1"

if "%reg_error%"=="1" (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc0000007
    echo Info: BAD_SYSTEM_CONFIG_INFO
    echo.
    echo File: \Settings And System Files\REG.cfg
    echo.
    echo The registry file appears to be missing required entries.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=7" & goto bsod
    exit
)

set "reg_versions="
for /f "tokens=2 delims==" %%v in ('findstr /i "REG_VERSION" "%reg_path%" 2^>nul') do set "reg_versions=%%v"
if not "%reg_versions%"=="%reg_version% " (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000003
    echo Info: REGISTRY_VERSION_MISMATCH
    echo Expected: %reg_version%, Found: %reg_versions%
    echo.
    echo File: \Settings And System Files\REG.cfg
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=3" & goto bsod
    exit
)

set "registrysize=0"
if exist "%reg_path%" for %%i in ("%reg_path%") do set "registrysize=%%~zi"

if %registrysize% GEQ 2048 (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000011
    echo Info: REGISTRY_LOCKED
    echo.
    echo File: \Settings And System Files\REG.cfg
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=11" & goto bsod
    exit
)

set "kernelsize=0"
if exist "%kernel_path%" for %%i in ("%kernel_path%") do set "kernelsize=%%~zi"

if %kernelsize% GEQ 12288 (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000010
    echo Info: KERNEL_LOCKED
    echo.
    echo File: \Settings And System Files\kernel.dll
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=10" & goto bsod
    exit
)

set "logsize=0"
if exist "%log_path%" for %%i in ("%log_path%") do set "logsize=%%~zi"

if %logsize% GEQ 153600 (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000012
    echo Info: LOG_OVERFLOW
    echo.
    echo File: \Settings And System Files\system.log
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=12" & goto bsod
    exit
)

set "enable_lua=1"
for /f "tokens=2 delims==" %%l in ('findstr /i "ENABLE_LUA" "%reg_path%" 2^>nul') do set "enable_lua=%%l"

set "current_user=SYSTEM"
set "user_home=%sys_prof%"
if not exist "%user_home%" md "%user_home%" 2>nul
cd /d "%user_home%" 2>nul
goto logon_screen

:hash
set "input=%~1"
set "hash_val=0"
set "salt=79"

for /l %%i in (0,1,50) do (
    if "!input:~%%i,1!"=="" goto hash_done
    set "char=!input:~%%i,1!"
    
    if "!char!"=="a" set /a "code=1"
    if "!char!"=="b" set /a "code=2"
    if "!char!"=="c" set /a "code=3"
    if "!char!"=="d" set /a "code=4"
    if "!char!"=="e" set /a "code=5"
    if "!char!"=="f" set /a "code=6"
    if "!char!"=="g" set /a "code=7"
    if "!char!"=="h" set /a "code=8"
    if "!char!"=="i" set /a "code=9"
    if "!char!"=="j" set /a "code=10"
    if "!char!"=="k" set /a "code=11"
    if "!char!"=="l" set /a "code=12"
    if "!char!"=="m" set /a "code=13"
    if "!char!"=="n" set /a "code=14"
    if "!char!"=="o" set /a "code=15"
    if "!char!"=="p" set /a "code=16"
    if "!char!"=="q" set /a "code=17"
    if "!char!"=="r" set /a "code=18"
    if "!char!"=="s" set /a "code=19"
    if "!char!"=="t" set /a "code=20"
    if "!char!"=="u" set /a "code=21"
    if "!char!"=="v" set /a "code=22"
    if "!char!"=="w" set /a "code=23"
    if "!char!"=="x" set /a "code=24"
    if "!char!"=="y" set /a "code=25"
    if "!char!"=="z" set /a "code=26"
    if "!char!"=="A" set /a "code=27"
    if "!char!"=="B" set /a "code=28"
    if "!char!"=="C" set /a "code=29"
    if "!char!"=="D" set /a "code=30"
    if "!char!"=="E" set /a "code=31"
    if "!char!"=="F" set /a "code=32"
    if "!char!"=="G" set /a "code=33"
    if "!char!"=="H" set /a "code=34"
    if "!char!"=="I" set /a "code=35"
    if "!char!"=="J" set /a "code=36"
    if "!char!"=="K" set /a "code=37"
    if "!char!"=="L" set /a "code=38"
    if "!char!"=="M" set /a "code=39"
    if "!char!"=="N" set /a "code=40"
    if "!char!"=="O" set /a "code=41"
    if "!char!"=="P" set /a "code=42"
    if "!char!"=="Q" set /a "code=43"
    if "!char!"=="R" set /a "code=44"
    if "!char!"=="S" set /a "code=45"
    if "!char!"=="T" set /a "code=46"
    if "!char!"=="U" set /a "code=47"
    if "!char!"=="V" set /a "code=48"
    if "!char!"=="W" set /a "code=49"
    if "!char!"=="X" set /a "code=50"
    if "!char!"=="Y" set /a "code=51"
    if "!char!"=="Z" set /a "code=52"
    if "!char!"=="0" set /a "code=53"
    if "!char!"=="1" set /a "code=54"
    if "!char!"=="2" set /a "code=55"
    if "!char!"=="3" set /a "code=56"
    if "!char!"=="4" set /a "code=57"
    if "!char!"=="5" set /a "code=58"
    if "!char!"=="6" set /a "code=59"
    if "!char!"=="7" set /a "code=60"
    if "!char!"=="8" set /a "code=61"
    if "!char!"=="9" set /a "code=62"
    if "!char!"=="_" set /a "code=63"
    if "!char!"=="-" set /a "code=64"
    if "!char!"=="?" set /a "code=65"

    if not defined code set "code=66"
    
    set /a "hash_val=hash_val * 31 + code + salt"
    set /a "hash_val=hash_val %% 1000000000"
    set "code="
)
:hash_done
echo %hash_val%
exit /b %hash_val%

:logon_screen
set "u_in=" & set "p_in="
set "current_user=SYSTEM"
set "user_home=%sys_prof%"
cd /d "%user_home%" 2>nul
echo [%date% %time% INFO] BOOT_V26_INIT_%current_user% >> "%log_path%" 2>nul
cls
color 5b
echo ======================================================================================================================
echo                                              %os_name% LOCK SCREEN
echo ======================================================================================================================
echo Status: Protected / Context: %current_user%
echo ----------------------------------------------------------------------------------------------------------------------
echo COMMANDS: Shutdown, Reboot
echo ----------------------------------------------------------------------------------------------------------------------
echo.
set /p "u_in=Username: "

if /i "%u_in%"=="Shutdown" echo [%date% %time% INFO] SHUTDOWN_FROM_LOGON >> "%log_path%" & goto shutdown_screen
if /i "%u_in%"=="Reboot" echo [%date% %time% INFO] REBOOT_FROM_LOGON >> "%log_path%" & goto reboot_screen

if "%u_in%"=="" goto logon_screen

set "login_attempts=0"
if exist "%sys_services%\fail_%u_in%.cnt" (
    set /p login_attempts=<"%sys_services%\fail_%u_in%.cnt"
    set "login_attempts=!login_attempts: =!"
    if "!login_attempts!"=="" set "login_attempts=0"
)
if !login_attempts! GEQ 10 set "bsod=9" & goto bsod

set /p "p_in=Password: "

set "stored_hash="
for /f "tokens=2 delims==" %%a in ('findstr /c:"%u_in% =" "%kernel_path%" 2^>nul') do set "stored_hash=%%a"
if not defined stored_hash echo [ ERROR ] User not found. & pause & goto logon_screen
set "stored_hash=%stored_hash: =%"
call :hash "%p_in%"
if "!errorlevel!"=="%stored_hash%" goto logon_ok
if NOT "!errorlevel!"=="%stored_hash%" (
    set /a login_attempts+=1
    echo !login_attempts!> "%sys_services%\fail_%u_in%.cnt"
    echo [ ERROR ] Password incorrect. (Attempt !login_attempts!/10)
    if !login_attempts! GEQ 10 set "bsod=9" & goto bsod
    pause & goto logon_screen
)

:logon_ok
if exist "%sys_services%\fail_%u_in%.cnt" del /f /q "%sys_services%\fail_%u_in%.cnt"

set "current_user=%u_in%"
if /i "%current_user%"=="SYSTEM" (set "user_home=%sys_prof%") else (set "user_home=%users_root%\%current_user%")

if /i "%current_user%"=="SYSTEM" set "current_user=BarOS AUTHORITY\SYSTEM"
if not exist "%user_home%" md "%user_home%" 2>nul
if /i "%current_user%"=="BarOS AUTHORITY\SYSTEM" set "reg_key=SYSTEM_COLOR" & goto apply_color
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" set "reg_key=ADMIN_COLOR" & goto apply_color
set "reg_key=USER_COLOR" & goto apply_color
					
:apply_color
if exist "%sys_services%\fail_%u_in%.cnt" del /f /q "%sys_services%\fail_%u_in%.cnt" >nul
for /f "tokens=2 delims==" %%c in ('findstr /i "%reg_key%" "%reg_path%"') do color %%c
cd /d "%user_home%" 2>nul

:interface
set "current_mode=%boot_choice%"
if "%rec%"=="1" set "current_mode=3"
if "%diagnostic%"=="1" set "current_mode=4"
if "%diagnostic%"=="2" set "current_mode=5"

echo BOOT_TIMEOUT=%boot_timeout% > "%config_root%\BCD"
echo DEFAULT_MODE=%default_mode% >> "%config_root%\BCD"
echo LAST_SUCCESSFUL_MODE=%current_mode% >> "%config_root%\BCD"
echo BOOT_COUNT=%boot_count% >> "%config_root%\BCD"
echo LAST_BOOT_SUCCESS=%date% >> "%config_root%\BCD"

if "%rec%"=="1" set "current_user=BarOS AUTHORITY\SYSTEM"
if "%safe_mode%"=="0" if "%rec%"=="0" if "%diagnostic%"=="0" (
    if not exist "%sys_services%\SysPulse.active" (
        echo [ KERNEL ] Booting background service: BarOS AUTHORITY\SysPulse...
        echo RUNNING > "%sys_services%\SysPulse.active" 2>nul
        timeout /t 1 >nul
    )
    if not exist "%sys_services%\NetMonitor.active" (
        echo [ KERNEL ] Booting background service: BarOS AUTHORITY\NetMonitor...
        echo RUNNING > "%sys_services%\NetMonitor.active" 2>nul
        timeout /t 1 >nul
    )
    if not exist "%sys_services%\SFC_Daemon.active" (
        echo [ KERNEL ] Booting background service: BarOS AUTHORITY\SFC_Daemon...
        echo RUNNING > "%sys_services%\SFC_Daemon.active" 2>nul
        timeout /t 1 >nul
    )
)
if "%rec%"=="1" (
    if not exist "%sys_services%\SFC_Daemon.active" (
        echo [ KERNEL ] Booting background service: BarOS AUTHORITY\SFC_Daemon...
        echo RUNNING > "%sys_services%\SFC_Daemon.active" 2>nul
        timeout /t 1 >nul
    )
    set "current_user=BarOS AUTHORITY\SFC_Daemon"
    del /f /q "%sys_services%\SysPulse.active"
    del /f /q "%sys_services%\NetMonitor.active"
    if not exist "%sys_services%\SFC_Daemon" md "%sys_services%\SFC_Daemon"
    set "user_home=%sys_services%\SFC_Daemon"
    cd /d "%sys_services%\SFC_Daemon"
)
if "%diagnostic%"=="1" (
    if not exist "%sys_services%\SysPulse.active" (
        echo [ KERNEL ] Booting background service: BarOS AUTHORITY\SysPulse...
        echo RUNNING > "%sys_services%\SysPulse.active" 2>nul
        timeout /t 1 >nul
    )
    set "current_user=BarOS AUTHORITY\SysPulse"
    del /f /q "%sys_services%\SFC_Daemon.active"
    del /f /q "%sys_services%\NetMonitor.active"
    if not exist "%sys_services%\SysPulse" md "%sys_services%\SysPulse"
    set "user_home=%sys_services%\SysPulse"
    cd /d "%sys_services%\SysPulse"
)
if "%diagnostic%"=="2" (
    if not exist "%sys_services%\NetMonitor.active" (
        echo [ KERNEL ] Booting background service: BarOS AUTHORITY\NetMonitor...
        echo RUNNING > "%sys_services%\NetMonitor.active" 2>nul
        timeout /t 1 >nul
    )
    set "current_user=BarOS AUTHORITY\NetMonitor"
    del /f /q "%sys_services%\SFC_Daemon.active"
    del /f /q "%sys_services%\SysPulse.active"
    if not exist "%sys_services%\NetMonitor" md "%sys_services%\NetMonitor"
    set "user_home=%sys_services%\NetMonitor"
    cd /d "%sys_services%\NetMonitor"
)

cls
if exist "alert.sys" (
    color 4f
    echo ======================================================================================================================
    echo                                                 CRITICAL SYSTEM ALERT
    echo ======================================================================================================================
    echo.
    type "alert.sys"
    echo.
    echo ----------------------------------------------------------------------------------------------------------------------
    echo.
    set /p "ack=Press ENTER to acknowledge and continue..."
    del /f /q "alert.sys"
    echo [%date% %time% WARNING] ALERT_VIEWED_%current_user% >> "%log_path%" 2>nul

    for /f "tokens=2 delims==" %%c in ('findstr /i "%reg_key%" "%reg_path%"') do color %%c
    goto interface
)

if "%diagnostic%"=="2" color 0e
if "%diagnostic%"=="1" color 0e
if "%rec%"=="1" color 0e
if "%safe_mode%"=="1" color 07
echo %os_name% [Build %current_build%] - Session: %current_user% ^(SAFE MODE: %safe_mode%^)
echo Profile: %cd%
echo Have ideas or found a bug? Visit: https://github.com/Armsoup/ARSLANIUS/discussions
echo Or: https://t.me/+8FQ20tOaKI5lNGMy
echo ----------------------------------------------------------------------------------------------------------------------

if "%safe_mode%"=="1" goto cmd_loop
if "%rec%"=="1" goto cmd_loop
if "%diagnostic%"=="1" goto cmd_loop
if "%diagnostic%"=="2" goto cmd_loop
if exist "mail.txt" echo [ MAIL ] You have unread messages! Type "mail-read".
if exist "autorun.txt" (
    for /f "tokens=*" %%a in (autorun.txt) do (
        echo [ AUTO ] Starting: %%a...
        set "ex_c=%%a"
        goto core_auto
    )
)

:cmd_loop
if "%rec%"=="1" goto skip_all_services
if "%safe_mode%"=="1" goto skip_all_services
if "%diagnostic%"=="1" goto skip_all_services
if "%diagnostic%"=="2" goto skip_all_services

if exist "%sys_services%\SFC_Daemon.active" (
    set "sfc_err=0"
    if NOT exist "%kernel_path%" set "sfc_err=1"
    if NOT exist "%reg_path%" set "sfc_err=1"
    
    if "!sfc_err!"=="1" (
        echo [ BarOS AUTHORITY\SFC_DAEMON ] Integrity violation detected!
        echo [ BarOS AUTHORITY\SFC_DAEMON ] Executing background repair...
        if NOT exist "%kernel_path%" (
            echo SYSTEM = -414170332 > "%kernel_path%"
            echo SYSTEM ADMINISTRATOR = 156593571 >> "%kernel_path%"
        )
        echo OS_NAME = %os_name% > "%reg_path%"
        echo SYSTEM_COLOR=0e >> "%reg_path%"
        echo ADMIN_COLOR=4f >> "%reg_path%"
        echo USER_COLOR=1f >> "%reg_path%"
        echo ENABLE_LUA=1 >> "%reg_path%"
        echo REG_VERSION=%reg_version% >> "%reg_path%"
        echo [%date% %time% WARNING] BarOS AUTHORITY\SFC_DAEMON: AUTO_REPAIR_SUCCESS >> "%log_path%"
        echo [ SFC_DAEMON ] System restored.
    )
)

if exist "%sys_services%\SysPulse.active" (
    if exist "NewFolder" rd /s /q "NewFolder" 2>nul
    
    for %%i in ("%root_path%\Settings And System Files\system.log") do (
        if %%~zi GEQ 10240 (
            echo [%date% %time% INFO] BarOS AUTHORITY\SYSPULSE: LOG_CLEARED > "%root_path%\Settings And System Files\system.log"
        )
    )
    
    set /a "pulse_check=%random% %% 10"
    if "%pulse_check%"=="5" echo [%date% %time% INFO] BarOS AUTHORITY\SYSPULSE: System Health OK >> "%log_path%"
)

if exist "%sys_services%\NetMonitor.active" (
    set /a "net_check=%random% %% 10"
    if "%net_check%"=="5" (
        ping -n 1 github.com >nul 2>&1
        if errorlevel 1 (
            echo BarOS AUTHORITY\NETMONITOR: OFFLINE 
            echo [%date% %time% INFO] BarOS AUTHORITY\NETMONITOR: OFFLINE >> "%log_path%"
        ) else (
            echo BarOS AUTHORITY\NETMONITOR: ONLINE 
            echo [%date% %time% INFO] BarOS AUTHORITY\NETMONITOR: ONLINE >> "%log_path%"
        )
    )
)

:skip_all_services
cd /d "%user_home%" 2>nul
set "cmd="
set /p cmd="%current_user%@ARSLANIUS> "
set "ex_c=%cmd%"
if "%cmd%"=="" goto cmd_loop

set "f_w=" & set "t_c="
for /f "tokens=1,2" %%a in ("%cmd%") do (set "f_w=%%a" & set "t_c=%%b")

if /i NOT "%f_w%"=="sudo" goto check_r
if "%t_c%"=="" echo Usage: sudo [command] & goto cmd_loop
if /i "%current_user%"=="BarOS AUTHORITY\SYSTEM" set "ex_c=%t_c%" & goto core
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" set "ex_c=%t_c%" & goto core
if /i "%current_user%"=="BarOS AUTHORITY\SFC_Daemon" set "ex_c=%t_c%" & goto core
if /i "%current_user%"=="BarOS AUTHORITY\SysPulse" set "ex_c=%t_c%" & goto core
if /i "%current_user%"=="BarOS AUTHORITY\NetMonitor" set "ex_c=%t_c%" & goto core
set /p "a_p=Enter ADMIN password: "
set "admin_hash="
for /f "tokens=2 delims==" %%s in ('findstr /i /c:"SYSTEM ADMINISTRATOR =" "%kernel_path%" 2^>nul') do set "admin_hash=%%s"
set "admin_hash=!admin_hash: =!"
call :hash "!a_p!"
if "!errorlevel!"=="!admin_hash!" ( 
    echo [%date% %time% WARNING] SUDO_EXEC: !t_c! BY %current_user% >> "%log_path%" 2>nul
    set "ex_c=%t_c%" & goto core
)
echo [ ERROR ] Access denied. & goto cmd_loop

:check_r
if "%enable_lua%"=="0 " goto core

set "is_ok=0"
for %%a in (Help mkdir ping cp mv touch backup ls cd cat ren backup-restore passwd reboot_to_recovery lock ArsStore NoteLite Snake sysinfo Scanner fmx restore restore-point mail-send mail-read clean report cls ver whoami Calc Notepad miner.game reboot shutdown) do (if /i "%ex_c%"=="%%a" set "is_ok=1")

if "%is_ok%"=="0" (
    if /i "%current_user%"=="BarOS AUTHORITY\SYSTEM" goto core
    if /i "%current_user%"=="SYSTEM ADMINISTRATOR" goto core
    if /i "%current_user%"=="BarOS AUTHORITY\SFC_Daemon" goto core
    if /i "%current_user%"=="BarOS AUTHORITY\SysPulse" goto core
    if /i "%current_user%"=="BarOS AUTHORITY\NetMonitor" goto core
    echo Error: Access Denied. Use "sudo %cmd%".
    goto cmd_loop
)
goto core

:core
:core_auto
if /i "%current_user%"=="GUEST" (
    set "ok=0"
    for %%a in (Help lock ls cd support report cls ver dir whoami Calc Notepad miner.game reboot shutdown) do (if /i "%ex_c%"=="%%a" set "ok=1")
    if "!ok!"=="0" echo [ SECURITY ] Guest cannot use this command. & goto cmd_loop
)

if /i "%current_user%"=="BarOS AUTHORITY\SFC_Daemon" (
    set "ok=0"
    for %%a in (Help mv bcdboot cp rm touch edit bcdedit mkdir ls cd cat ren support reset reboot_to_recovery cls ver dir whoami events sfc adduser deluser regedit) do (if /i "%ex_c%"=="%%a" set "ok=1")
    if "!ok!"=="0" echo [ SECURITY ] Restricred. & goto cmd_loop
)

if /i "%current_user%"=="BarOS AUTHORITY\SysPulse" (
    set "ok=0"
    for %%a in (Help ls sysinfo events report dash taskmgr cd cat support reboot shutdown reboot_to_recovery cls ver dir whoami) do (if /i "%ex_c%"=="%%a" set "ok=1")
    if "!ok!"=="0" echo [ SECURITY ] Restricred. & goto cmd_loop
)

if /i "%current_user%"=="BarOS AUTHORITY\NetMonitor" (
    set "ok=0"
    for %%a in (Help reboot ping netstat ipconfig tracert nslookup arp route shutdown cls whoami) do (if /i "%ex_c%"=="%%a" set "ok=1")
    if "!ok!"=="0" echo [ SECURITY ] Restricred. & goto cmd_loop
)

if /i "%safe_mode%"=="1" (
    set "ok=0"
    for %%a in (Help lock mv cp bcdboot bcdedit rm touch chattr mkdir ls cd cat ren backup backup-restore sysinfo support reset reboot_to_recovery report cls ver dir whoami events sfc dash fmx restore-point restore adduser deluser start regedit reboot shutdown) do (if /i "%ex_c%"=="%%a" set "ok=1")
    if "!ok!"=="0" echo [ SECURITY ] Safe mode. & goto cmd_loop
)

if "%enable_lua%"=="0 " goto exec
if /i NOT "%current_user%"=="SYSTEM ADMINISTRATOR" goto exec
set "ok=0"
for %%a in (Help calc ping bcdedit bcdboot loader_error netstat ipconfig tracert nslookup arp route notepad sysinfo cp mv rm reset bsod touch mkdir ls cd cat ren backup backup-restore lock support events reboot_to_recovery report cls ver taskmgr fmx Shutdown Reboot dir adduser whoami sfc clean mail-read mail-send edit guest msg-all regedit install deluser alert restore-point restore) do (if /i "%ex_c%"=="%%a" set "ok=1")
if "%ok%"=="0" echo [ SECURITY ] Restricted context. & goto cmd_loop

:exec
:: --- NEW COMMANDS V26 ---

if /i "%ex_c%"=="bcdedit" goto bcdedit 
if /i "%ex_c%"=="bcdboot" goto bcdboot 
if /i "%ex_c%"=="loader_error" (
    cls
    color 0f
    echo ======================================================================================================================
    echo                                                 ARSLANIUS BOOT MANAGER
    echo ======================================================================================================================
    echo.
    echo ARSLANIUS failed to start. A recent hardware or software change might be
    echo the cause.
    echo.
    echo Status: 0xc00000666
    echo Status: 0xTeam_by_%current_user%
    echo Status: 0xcDEADBEEF
    echo Info: MANUAL_CRASH
    echo.
    echo File: \ARSLANIUS 26.cmd
    echo.
    echo Press [R] to Repair
    echo Press [Enter] to Exit
    echo.
    echo ======================================================================================================================
    set /p "choice=> "
    if /i "!choice!"=="R" set "bsod=666" & goto bsod
    exit
)
if /i "%ex_c%"=="ping" goto ping
if /i "%ex_c%"=="netstat" goto netstat
if /i "%ex_c%"=="ipconfig" goto ipconfig
if /i "%ex_c%"=="tracert" goto tracert
if /i "%ex_c%"=="nslookup" goto nslookup
if /i "%ex_c%"=="arp" goto arp
if /i "%ex_c%"=="route" goto route

:: --- STANDART COMMANDS ---
if /i "%ex_c%"=="ls" goto ls
if /i "%ex_c%"=="cd" goto cd
if /i "%ex_c%"=="cat" goto cat
if /i "%ex_c%"=="ren" goto ren
if /i "%ex_c%"=="mkdir" goto mkdir
if /i "%ex_c%"=="chattr" goto chattr
if /i "%ex_c%"=="touch" goto touch
if /i "%ex_c%"=="bsod" set "bsod=666" & goto bsod 
if /i "%ex_c%"=="cp" goto cp
if /i "%ex_c%"=="rm" goto rm
if /i "%ex_c%"=="mv" goto mv
if /i "%ex_c%"=="backup" goto system_backup
if /i "%ex_c%"=="backup-restore" goto backup_restore
if /i "%ex_c%"=="sysinfo" goto sysinfo
if /i "%ex_c%"=="reboot_to_recovery" (
    color 0f
    timeout /t 2 >nul
    cls 
    echo .
    timeout /t 1 >nul
    cls
    echo ..
    timeout /t 1 >nul
    cls
    echo ...
    timeout /t 1 >nul
    cls 
    echo .
    timeout /t 1 >nul
    cls
    echo ..
    timeout /t 1 >nul
    cls
    echo ...
    timeout /t 1 >nul
    goto repair 
)
if /i "%ex_c%"=="passwd" goto passwd
if /i "%ex_c%"=="reset" goto reset

for /f "tokens=1,2" %%a in ("%ex_c%") do (
    set "f_w=%%a"
    set "t_c=%%b"
)

if /i "%f_w%"=="call" (
    if "%t_c%"=="" echo Usage: call [label] & goto cmd_loop
    echo [%date% %time%] CALL_EXEC: %t_c% BY %current_user% >> "%log_path%" 2>nul
    
    findstr /i /c:":%t_c%" "%~f0" >nul 2>&1
    if errorlevel 1 echo [ ERROR ] Block :%t_c% not found. & goto cmd_loop
    
    goto :%t_c%
)
if /i "%ex_c%"=="ArsStore" goto store
if /i "%ex_c%"=="restore-point" goto restore_point
if /i "%ex_c%"=="restore" goto restore
if /i "%ex_c%"=="as-pack" goto as_packer
if /i "%ex_c%"=="as-unpack" goto as_unpacker
if /i "%ex_c%"=="report" goto sys_report
if /i "%ex_c%"=="msg-all" goto msg_all
if /i "%ex_c%"=="fmx" goto fmx
if /i "%ex_c%"=="regedit" goto regedit
if /i "%ex_c%"=="help" goto help
if /i "%ex_c%"=="install" goto install
if /i "%ex_c%"=="alert" goto alert_all 
if /i "%ex_c%"=="events" goto eventvwr 
if /i "%ex_c%"=="service" goto service
if /i "%ex_c%"=="sfc" goto sfc_scan
if /i "%ex_c%"=="dash" goto dash
if /i "%ex_c%"=="Guest" goto guest_toggle
if /i "%ex_c%"=="start" goto start
if /i "%ex_c%"=="taskmgr" goto taskmgr
if /i "%ex_c%"=="adduser" goto adduser
if /i "%ex_c%"=="deluser" goto deluser
if /i "%ex_c%"=="whoami" goto whoami
if /i "%ex_c%"=="mail-send" goto mail_send
if /i "%ex_c%"=="mail-read" goto mail_read
if /i "%ex_c%"=="clean" goto clean
if /i "%ex_c%"=="edit" goto edit
if /i "%ex_c%"=="lock" goto logon_screen
if /i "%ex_c%"=="cls" goto interface
if /i "%ex_c%"=="ver" echo %os_name% [Build %current_build%] & goto cmd_loop
if /i "%ex_c%"=="Notepad" start notepad.exe & goto cmd_loop
if /i "%ex_c%"=="Calc" start "" "%programs_root%\Calc.bat" & goto cmd_loop
if /i "%ex_c%"=="reboot" goto reboot_screen
if /i "%ex_c%"=="Shutdown" goto shutdown_screen

start "" "%ex_c%" 2>nul || echo "%ex_c%" is not recognized.
goto cmd_loop

:backup_restore
echo.
echo ===== SYSTEM IMAGE RESTORE =====
echo.
if exist "%root_path%\Backup\" (
    echo [ FOUND ] Backup directory detected.
    echo Files ready for recovery.
) else (
    echo [ ERROR ] No backup image found.
    echo Please create backup
    pause
    goto cmd_loop
)

set /p "img_confirm=Restore from backup? (Y/N): "
if /i not "!img_confirm!"=="Y" goto cmd_loop

echo [ WAIT ] Restoring system image...
xcopy /e /y "%root_path%\Backup\*" "%root_path%\" >nul 2>&1
echo [%date% %time%] IMAGE_RESTORE_EXECUTED >> "%log_path%" 2>nul
echo [ OK ] System image restored. Rebooting…
pause
goto boot

:msg_all
set /p "m_txt=Global Message: "
for /d %%d in ("%users_root%\*") do (echo [GLOBAL] From %current_user%: %m_txt% >> "%%d\mail.txt")
echo [GLOBAL] From %current_user%: %m_txt% >> "%sys_prof%\mail.txt"
echo [ OK ] Broadcast sent.
goto cmd_loop

:system_backup
if exist "%root_path%\Backup" rd /s /q  "%root_path%\Backup" >nul 2>&1
robocopy "%root_path%" "%root_path%\Backup" /E /COPY:DAT /R:0 /W:0 /XD Backup >nul 2>&1
echo [%date% %time% INFO] SYSTEM_BACKUP_EXECUTED >> "%log_path%" 2>nul
echo [ OK ] System backup created in Backup folder.
pause
goto cmd_loop

:ping
set /p "ping_host=Enter host to ping: "
ping -n 4 %ping_host%
pause
goto cmd_loop

:netstat
netstat -an
pause
goto cmd_loop

:ipconfig
ipconfig /all
pause
goto cmd_loop

:tracert
set /p "trace_host=Enter host to trace: "
tracert %trace_host%
pause
goto cmd_loop

:bcdboot
echo [ WAIT ] Creating default BCD configuration...
echo BOOT_TIMEOUT=30 > "%config_root%\BCD"
echo DEFAULT_MODE=1 >> "%config_root%\BCD"
echo LAST_SUCCESSFUL_MODE=1 >> "%config_root%\BCD"
echo BOOT_COUNT=0 >> "%config_root%\BCD"
echo LAST_BOOT_SUCCESS=Never >> "%config_root%\BCD"
echo [ OK ] BCD created. Reboot to apply changes.
pause
goto cmd_loop

:nslookup
set /p "ns_host=Enter host to lookup: "
nslookup %ns_host%
pause
goto cmd_loop

:arp
arp -a
pause
goto cmd_loop

:route
route print
pause
goto cmd_loop

:shutdown_screen
cls
color 9f
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo                                               SHUTTING DOWN
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo                                               %os_name%
timeout /t 3 >nul
del /f /q "%sys_services%\SysPulse.active"
del /f /q "%sys_services%\SFC_Daemon.active"
del /f /q "%sys_services%\NetMonitor.active"
exit

:reboot_screen
cls
color 9f
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo                                               SHUTTING DOWN
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo                                               %os_name%
timeout /t 3 >nul
del /f /q "%sys_services%\SysPulse.active"
del /f /q "%sys_services%\SFC_Daemon.active"
del /f /q "%sys_services%\NetMonitor.active"
goto boot

:dash
cls
echo ======================================================================================================================
echo                                                 %os_name% CONTROL CENTER
echo ======================================================================================================================
set "u_count=0"
for /f %%a in ('find /c "=" ^< "%kernel_path%"') do set "u_count=%%a"

echo [ STATS ] Registered Users: %u_count%
echo [ STATS ] OS Name: %os_name%
echo [ STATS ] Kernel: BarOS 22.0 (V26)
echo.
echo [ SERVICES ]
if exist "%sys_services%\SysPulse.active" (echo  - BarOS AUTHORITY\SysPulse: ONLINE) else (echo  - BarOS AUTHORITY\SysPulse: OFFLINE)
if exist "%sys_services%\SFC_Daemon.active" (echo  - BarOS AUTHORITY\SFC_Daemon: ONLINE) else (echo  - BarOS AUTHORITY\SFC_Daemon: OFFLINE)
if exist "%sys_services%\NetMonitor.active" (echo  - BarOS AUTHORITY\NetMonitor: ONLINE) else (echo  - BarOS AUTHORITY\NetMonitor: OFFLINE)

echo.
echo [ ENV ]
echo root_path=%root_path%
echo kernel_path=%kernel_path%
echo current_build=Build %current_build%
echo user_home=%user_home%
echo current_user=%current_user%
echo ======================================================================================================================
pause
goto cmd_loop

:cp
set /p "source_file=Source file: "
if "%source_file%"=="" goto cmd_loop
if not exist "%source_file%" (
    echo [ ERROR ] Source file not found.
    pause
    goto cmd_loop
)
set /p "dest_file=Destination file: "
if "%dest_file%"=="" goto cmd_loop
copy "%source_file%" "%dest_file%" >nul 2>&1
if errorlevel 1 (
    echo [ ERROR ] Copy failed.
) else (
    echo [ OK ] Copied to %dest_file%.
)
pause
goto cmd_loop

:rm
set /p "target_file=File to delete: "
if "%target_file%"=="" goto cmd_loop
if not exist "%target_file%" (
    echo [ ERROR ] File not found.
    pause
    goto cmd_loop
)
del /f /q "%target_file%" 2>nul
if errorlevel 1 (
    echo [ ERROR ] Delete failed.
) else (
    echo [ OK ] Deleted.
)
pause
goto cmd_loop

:mv 
set /p "source_file=Source file: "
if "%source_file%"=="" goto cmd_loop
if not exist "%source_file%" (
    echo [ ERROR ] Source file not found.
    pause
    goto cmd_loop
)
set /p "dest_file=Destination file: "
if "%dest_file%"=="" goto cmd_loop
move "%source_file%" "%dest_file%" >nul 2>&1
if errorlevel 1 (
    echo [ ERROR ] Move failed.
) else (
    echo [ OK ] Moved to %dest_file%.
)
pause
goto cmd_loop

:sys_report
set "lsize=0"
if exist "%log_path%" for %%i in ("%log_path%") do set "lsize=%%~zi"
echo [ WAIT ] Generating HTML Report...
echo. > "%root_path%\Report_v26.html"
set "report_f=%root_path%\Report_v26.html"
echo ^<html^>^<body style='background:#111;color:#0f0;font-family:monospace'^> > "%report_f%"
echo ^<h1^>ARSLANIUS 26 - SYSTEM REPORT^</h1^> >> "%report_f%"
echo ^<hr^>^<p^>Build: %current_build%^</p^> >> "%report_f%"
echo ^<p^>Kernel: 22.0^</p^> >> "%report_f%"
echo ^<p^>Active User: %current_user%^</p^> >> "%report_f%"
echo ^<p^>Log Size: %lsize% bytes^</p^> >> "%report_f%"
echo ^<h2^>Registered Users:^</h2^>^<pre^> >> "%report_f%"
type "%kernel_path%" >> "%report_f%"
echo ^</pre^>^</body^>^</html^> >> "%report_f%"
echo [ OK ] Report generated: %report_f%
start "" "%report_f%"
pause & goto cmd_loop

:passwd
if /i "%current_user%"=="BarOS AUTHORITY\SYSTEM" echo Cannot change SYSTEM password. & pause & goto cmd_loop
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" echo Cannot change ADMIN password. & pause & goto cmd_loop
if /i "%current_user%"=="BarOS AUTHORITY\SFC_Daemon" echo Cannot change TEMPORARY password. & pause & goto cmd_loop
if /i "%current_user%"=="BarOS AUTHORITY\SysPulse" echo Cannot change TEMPORARY password. & pause & goto cmd_loop
if /i "%current_user%"=="BarOS AUTHORITY\NetMonitor" echo Cannot change TEMPORARY password. & pause & goto cmd_loop

set "old_hash="
for /f "tokens=2 delims==" %%a in ('findstr /i /b "%current_user% =" "%kernel_path%"') do set "old_hash=%%a"
set "old_hash=!old_hash: =!"

set /p "old=Current password: "
call :hash "!old!" >nul
if not "!errorlevel!"=="!old_hash!" echo Wrong password & pause & goto cmd_loop

set /p "new1=New password: "
set /p "new2=Confirm: "
if not "!new1!"=="!new2!" echo Passwords do not match & pause & goto cmd_loop

call :hash "!new1!" >nul
set "new_hash=!errorlevel!"

set "temp_file=%kernel_path%.tmp"
type "%kernel_path%" | findstr /v /i /b "%current_user% =" > "%temp_file%"
echo %current_user% = !new_hash! >> "%temp_file%"
move /y "%temp_file%" "%kernel_path%" >nul

echo Password changed.
pause
goto cmd_loop

:chattr
if /i NOT "%current_user%"=="BarOS AUTHORITY\SYSTEM" (
    echo [ ERROR ] Only SYSTEM can change attributes.
    goto cmd_loop
)
set /p "ch_file=Enter filename: "
if not exist "%ch_file%" (
    echo [ ERROR ] File not found.
) else (
    attrib +h "%ch_file%"
    echo [ OK ] File hidden.
)
goto cmd_loop

:touch
set /p "touch_file=Enter filename: "
if exist "%touch_file%" (
    echo [ OK ] File exists. (timestamp not updated - batch limitation)
) else (
    type nul > "%touch_file%"
    echo [ OK ] File created.
)
goto cmd_loop

:sysinfo
cls
echo ======================================================================================================================
echo              ARSLANIUS SYSTEM INFORMATION
echo ======================================================================================================================
echo.

echo [USER]
echo   Current User  : %current_user%
echo   Home          : %user_home%
echo.

echo [SYSTEM]
echo   OS Name       : %os_name%
echo   Build         : %current_build%
echo   Kernel        : BarOS 22.0
echo   Safe Mode     : %safe_mode%
echo.

set "ucount=0"
for /f %%a in ('find /c "=" ^< "%kernel_path%"') do set "ucount=%%a"
echo [ACCOUNTS]
echo   Registered    : %ucount%
echo.

set "netm=OFFLINE"
set "sp=OFFLINE"
set "sfc=OFFLINE"
if exist "%sys_services%\SysPulse.active" set "sp=ONLINE"
if exist "%sys_services%\SFC_Daemon.active" set "sfc=ONLINE"
if exist "%sys_services%\NetMonitor.active" set "netm=ONLINE"
echo [SERVICES]
echo   BarOS AUTHORITY\SysPulse      : %sp%
echo   BarOS AUTHORITY\SFC_Daemon    : %sfc%
echo   BarOS AUTHORITY\NetMonitor    : %netm%
echo.

set "ksize=0"
if exist "%kernel_path%" for %%i in ("%kernel_path%") do set "ksize=%%~zi"
set "rsize=0"
if exist "%reg_path%" for %%i in ("%reg_path%") do set "rsize=%%~zi"
set "lsize=0"
if exist "%log_path%" for %%i in ("%log_path%") do set "lsize=%%~zi"

echo [STORAGE]
echo   kernel.dll    : %ksize% bytes
echo   REG.cfg       : %rsize% bytes
echo   system.log    : %lsize% bytes
echo.

set "rpcount=0"
if exist "%restore_root%" for /f %%a in ('dir /b "%restore_root%" 2^>nul ^| find /c /v ""') do set "rpcount=%%a"
echo [RECOVERY]
echo   Restore Points: %rpcount%
echo.

echo ======================================================================================================================
pause
goto cmd_loop

:service
echo.
echo -- ARSLANIUS SERVICE MANAGER --
echo 1. list  - Show active services
echo 2. start - Run a service
echo 3. stop  - Stop a service
echo.
set "s_act="
set /p "s_act=Action (1/2/3): "

if "%s_act%"=="1" goto s_list
if "%s_act%"=="2" goto s_start
if "%s_act%"=="3" goto s_stop
echo [ ERROR ] Invalid action. & pause & goto cmd_loop

:s_list
echo Active services:
dir /b "%sys_services%\*.active" 2>nul
pause & goto cmd_loop

:s_start
set "s_name="
set /p "s_name=Service name: "
if "%s_name%"=="" echo Error: Name empty. & pause & goto cmd_loop
echo RUNNING > "%sys_services%\%s_name%.active"
echo [ OK ] Service %s_name% is now ONLINE.
pause & goto cmd_loop

:s_stop
set "s_name="
set /p "s_name=Service name to stop: "
if exist "%sys_services%\%s_name%.active" (
    del /f /q "%sys_services%\%s_name%.active"
    echo [ OK ] Service %s_name% OFFLINE.
) else (
    echo [ ERROR ] Service not found.
)
pause & goto cmd_loop

:eventvwr
cls
echo ======================================================================================================================
echo                                                  ARSLANIUS EVENT VIEWER
echo ======================================================================================================================
echo [ INFO ] Filtering critical events...
echo ----------------------------------------------------------------------------------------------------------------------
findstr /i "ERROR WARNING" "%log_path%" 2>nul
if !errorlevel! NEQ 0 echo [ INFO ] No critical events found.
echo ----------------------------------------------------------------------------------------------------------------------
pause
goto cmd_loop

:reset
echo WARNING: This will delete ALL users and reset system to defaults.
set /p "conf=Type YES to continue: "
if /i "!conf!"=="YES" goto startup_repair
echo Canceled.
goto cmd_loop

:bcdedit
if /i NOT "%current_user%"=="SYSTEM ADMINISTRATOR" if /i NOT "%current_user%"=="BarOS AUTHORITY\SYSTEM" if /i NOT "%current_user%"=="BarOS AUTHORITY\SFC_Daemon" (
    echo [ SECURITY ] Access Denied. Only for Admins.
    goto cmd_loop
)
echo.
echo -- BOOT CONFIGURATION EDITOR --
set /p "boot_timeout_new=Enter new timeout (or Enter to skip): "
if NOT "%boot_timeout_new%"=="" (
    echo BOOT_TIMEOUT=%boot_timeout_new% > "%config_root%\BCD"
    echo [ OK ] timeout updated.
)
if "%boot_timeout_new%"=="" (
    echo BOOT_TIMEOUT=30 > "%config_root%\BCD"
)

set /p "Default_choice_new=Enter Default Mode (ex: 1): "
if NOT "%Default_choice_new%"=="" echo DEFAULT_MODE=%Default_choice_new% >> "%config_root%\BCD"
if "%Default_choice_new%"=="" (
    echo DEFAULT_MODE=1 >> "%config_root%\BCD"
)

echo LAST_SUCCESSFUL_MODE=%current_mode% >> "%config_root%\BCD"
echo BOOT_COUNT=%boot_count% >> "%config_root%\BCD"
echo LAST_BOOT_SUCCESS=%date% >> "%config_root%\BCD"

echo [ DONE ] Configuration saved. Reboot to apply changes.
pause
goto cmd_loop

:regedit
if /i NOT "%current_user%"=="SYSTEM ADMINISTRATOR" if /i NOT "%current_user%"=="BarOS AUTHORITY\SYSTEM" if /i NOT "%current_user%"=="BarOS AUTHORITY\SFC_Daemon" (
    echo [ SECURITY ] Access Denied. Only for Admins.
    goto cmd_loop
)
echo.
echo -- SYSTEM CONFIGURATION EDITOR --
set /p "new_name=Enter new OS Name (or Enter to skip): "
if NOT "%new_name%"=="" (
    echo OS_NAME = %new_name% > "%reg_path%"
    echo [ OK ] OS Name updated.
)
if "%new_name%"=="" (
    echo OS_NAME =%os_name% > "%reg_path%"
)

set /p "sys_col=Enter System Color (ex: 0e): "
if NOT "%sys_col%"=="" echo SYSTEM_COLOR=%sys_col% >> "%reg_path%"
if "%sys_col%"=="" (
    echo SYSTEM_COLOR=0e >> "%reg_path%"
)
set /p "adm_col=Enter Admin Color (ex: 4f): "
if NOT "%adm_col%"=="" echo ADMIN_COLOR=%adm_col% >> "%reg_path%"
if "%adm_col%"=="" (
    echo ADMIN_COLOR=4f >> "%reg_path%"
)
set /p "usr_col=Enter User Color (ex: 1f): "
if NOT "%usr_col%"=="" echo USER_COLOR=%usr_col% >> "%reg_path%"
if "%usr_col%"=="" (
    echo USER_COLOR=1f >> "%reg_path%"
)
set /p "lua_val=Enter Enable LUA (1=enabled, 0=disabled): "
if NOT "%lua_val%"=="" echo ENABLE_LUA=%lua_val% >> "%reg_path%"
if "%lua_val%"=="" (
    echo ENABLE_LUA=1 >> "%reg_path%"
)
echo REG_VERSION=%reg_version% >> "%reg_path%"
echo [ DONE ] Configuration saved. Reboot to apply changes.
pause
goto cmd_loop

:install
echo -- APP INSTALLER --
set /p "a_n=App Name: "
echo @echo off > "%a_n%.bat"
echo echo App %a_n% running... >> "%a_n%.bat"
echo pause >> "%a_n%.bat"
echo [ OK ] App %a_n% installed.
goto cmd_loop

:adduser
echo.
echo -- NEW USER --
set /p "nu=Username: "
set /p "np=Password: "

if /i "%nu%"=="BarOS AUTHORITY\SYSTEM" (
    echo [ ERROR ] Reserved username. Cannot create.
    goto cmd_loop
)
if /i "%nu%"=="SYSTEM" (
    echo [ ERROR ] Reserved username. Cannot create.
    goto cmd_loop
)
if /i "%nu%"=="SYSTEM ADMINISTRATOR" (
    echo [ ERROR ] Reserved username. Cannot create.
    goto cmd_loop
)

if "%nu%"=="" echo [ ERROR ] Name cannot be empty. & goto cmd_loop
if "%np%"=="" echo [ ERROR ] Password cannot be empty. & goto cmd_loop

findstr /i /c:"%nu% =" "%kernel_path%" >nul
if !errorlevel! EQU 0 echo [ ERROR ] User already exists. & goto cmd_loop

(echo.) >> "%kernel_path%"
call :hash "%np%"
echo %nu% = !errorlevel! >> "%kernel_path%"

md "%users_root%\%nu%" 2>nul

echo [%date% %time% INFO] NEW_USER_CREATED: %nu% >> "%log_path%" 2>nul
echo [ OK ] User %nu% created. Profil folder generated.
echo.
goto cmd_loop

:alert_all
echo.
echo -- DEPLOY CRITICAL SYSTEM ALERT --
set /p "al_txt=Alert message: "

for /d %%d in ("%users_root%\*") do (echo %al_txt% > "%%d\alert.sys")
echo %al_txt% > "%sys_prof%\alert.sys"

echo [%date% %time% INFO] GLOBAL_ALERT_SENT: %al_txt% >> "%log_path%" 2>nul
echo [ OK ] Critical alert deployed to all stations.
echo.
goto cmd_loop

:ls
dir /w
goto cmd_loop

:mkdir
set /p "folder_name=Enter folder name: "
if "%folder_name%"=="" goto cmd_loop
md "%folder_name%" 2>nul
if exist "%folder_name%" (
    echo [ OK ] Folder created.
) else (
    echo [ ERROR ] Failed to create folder. Check path or permissions.
)
pause
goto cmd_loop

:cd
set "new_path="
set "stop="
set /p "new_path=Enter path: "
if NOT "%new_path%"==".." cd /d %new_path% & set "user_home=%new_path%"
if "%new_path%"==".." (
   set "user_home=%new_path%"
   cd /d "%user_home%" 2>nul
)
if "%new_path%"=="" goto cmd_loop
if errorlevel 1 (
    echo [ ERROR ] Invalid path.
    if "%user_home%"==".." (
       set "stop=."
       set "user_home=%stop%"
       cd /d "%user_home%" 2>nul
    )
) else (
    echo [ OK ] Directory changed to %user_home%
    if "%user_home%"==".." (
       set "stop=."
       set "user_home=%stop%"
       cd /d "%user_home%" 2>nul
    )
)
pause
goto cmd_loop

:cat
set /p "target_file=Enter filename: "
if "%target_file%"=="" goto cmd_loop
if not exist "%target_file%" (
    echo [ ERROR ] File not found.
) else (
    type "%target_file%"
)
pause
goto cmd_loop

:ren
set /p "old_name=Old name: "
if "%old_name%"=="" goto cmd_loop
set /p "new_name=New name: "
if "%new_name%"=="" goto cmd_loop
ren "%old_name%" "%new_name%" 2>nul
if errorlevel 1 (
    echo [ ERROR ] Rename failed.
) else (
    echo [ OK ] Renamed to %new_name%.
)
pause
goto cmd_loop

:deluser
echo -- DELETE USER --
set /p "du=Enter username: "
if /i "%du%"=="SYSTEM" echo [ ERROR ] Restricted. & goto cmd_loop
if /i "%du%"=="SYSTEM ADMINISTRATOR" echo [ ERROR ] Restricted. & goto cmd_loop
if /i "%du%"=="%current_user%" echo [ ERROR ] Active session. & goto cmd_loop
type "%kernel_path%" | findstr /v /i /c:"%du% =" > "%kernel_path%.tmp"
move /y "%kernel_path%.tmp" "%kernel_path%" >nul
rd /s /q "%users_root%\%du%" 2>nul
echo [ OK ] User %du% removed.
goto cmd_loop

:as_packer
echo.
echo [ ARSLANIUS PACKER v1.0 ]
set /p "arc_name=Enter archive name (ex: backup): "
echo [ WAIT ] Packing files in %cd%...
echo :: ARSLANIUS_ARCHIVE_V1 > "%arc_name%.arc"

for %%f in (*.*) do (
    if /i NOT "%%f"=="%arc_name%.arc" (
        echo [ PACK ] Adding: %%f
        echo :FILE_START:%%f >> "%arc_name%.arc"
        type "%%f" >> "%arc_name%.arc"
        echo. >> "%arc_name%.arc"
        echo :FILE_END:%%f >> "%arc_name%.arc"
    )
)
echo [ OK ] Archive %arc_name%.arc created.
pause & goto cmd_loop

:mail_send
set /p "m_to=To user: "
set /p "m_txt=Message: "
set "dp="
if /i "%m_to%"=="SYSTEM" set "dp=%sys_prof%"
if /i "%m_to%"=="SYSTEM ADMINISTRATOR" set "dp=%users_root%\SYSTEM ADMINISTRATOR"
if not defined dp ( if exist "%users_root%\%m_to%\" set "dp=%users_root%\%m_to%" )
if not defined dp echo [ ERROR ] User folder missing. & goto cmd_loop
pushd "%dp%"
(echo From %current_user% [%date% %time%]: %m_txt%) >> mail.txt
popd & echo [ OK ] Sent.
goto cmd_loop

:mail_read
if exist "mail.txt" (
    echo. & type "mail.txt" & echo.
    set /p "m_del=Clear mailbox? (Y/N): "
    if /i "!m_del!"=="Y" del /f /q "mail.txt"
) else ( echo No mail. )
goto cmd_loop

:fmx
cls
echo ======================================================================================================================
echo                                                FILE MANAGER X (ARSLANIUS)
echo ======================================================================================================================
echo Current directory: %cd%
echo ----------------------------------------------------------------------------------------------------------------------
set "f_num=0"
for %%f in (*.*) do (
    set /a f_num+=1
    echo [ !f_num! ] %%f  (!%%~zf bytes!)
)
echo ----------------------------------------------------------------------------------------------------------------------
echo [0] Exit  [Name] Actions
set /p "f_choice=Select file name to manage: "
if "%f_choice%"=="0" goto cmd_loop

:fmx_actions
echo Action for %f_choice%: [1] Read [2] Delete [3] Hide [4] Back
set /p "f_act=Choice: "
if "%f_act%"=="1" cls & type "%f_choice%" & pause & goto fmx
if "%f_act%"=="2" del /f /q "%f_choice%" & echo [ OK ] Deleted. & pause & goto fmx
if /i "%current_user%"=="BarOS AUTHORITY\SYSTEM" (
    if "%f_act%"=="3" attrib +h "%f_choice%" & echo [ OK ] Hidden. & pause & goto fmx
)
goto fmx

:whoami
echo Current User: %current_user%
if /i "%current_user%"=="BarOS AUTHORITY\SYSTEM" echo Permissions: KERNEL
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" echo Permissions: Administrator
if /i "%current_user%"=="BarOS AUTHORITY\SFC_Daemon" echo Permissions: LOCAL SERVICE
if /i "%current_user%"=="BarOS AUTHORITY\SysPulse" echo Permissions: LOCAL SERVICE
if /i "%current_user%"=="BarOS AUTHORITY\NetMonitor" echo Permissions: NETWORK SERVICE
echo Path: %cd%
goto cmd_loop

:sfc_scan
echo.
echo [ SYSTEM ] Beginning system file check...
timeout /t 1 >nul
set "errors=0"

echo [ WAIT ] Checking: BCD...
if NOT exist "%config_root%\BCD" (set "errors=1" & echo [ FAIL ] BCD MISSING) else (echo [  OK  ] BCD)

echo [ WAIT ] Checking: kernel.dll...
if NOT exist "%kernel_path%" (set "errors=1" & echo [ FAIL ] kernel.dll MISSING) else (
    for %%i in ("%kernel_path%") do if %%~zi LSS 10 (set "errors=1" & echo [ FAIL ] kernel.dll CORRUPTED) else (echo [  OK  ] kernel.dll)
)

echo [ WAIT ] Checking: REG.cfg...
if NOT exist "%reg_path%" (set "errors=1" & echo [ FAIL ] REG.cfg MISSING) else (echo [  OK  ] REG.cfg)

echo [ WAIT ] Checking: system.log...
if NOT exist "%log_path%" (set "errors=1" & echo [ FAIL ] system.log MISSING) else (echo [  OK  ] system.log)

if "%errors%"=="0" (
    echo.
    echo [ DONE ] All system files are healthy. No action required.
    goto cmd_loop
)

echo.
echo [ WARN ] Integrity violations found.
set /p "sfc_r=Repair files now? (Y/N): "
if /i "%sfc_r%"=="Y" goto sfc_repair
goto cmd_loop

:sfc_repair
echo [ WAIT ] Repairing system files...
if not exist "%config_root%" md "%config_root%" 2>nul
if NOT exist "%kernel_path%" (
    echo SYSTEM = -414170332 > "%kernel_path%"
    echo SYSTEM ADMINISTRATOR = 156593571 >> "%kernel_path%"
)
echo OS_NAME =%os_name% > "%reg_path%"
echo SYSTEM_COLOR=0e >> "%reg_path%"
echo ADMIN_COLOR=4f >> "%reg_path%"
echo USER_COLOR=1f >> "%reg_path%"
echo ENABLE_LUA=1 >> "%reg_path%"
echo REG_VERSION=%reg_version% >> "%reg_path%"

echo BOOT_TIMEOUT=30 > "%config_root%\BCD"
echo DEFAULT_MODE=1 >> "%config_root%\BCD"
echo LAST_SUCCESSFUL_MODE=1 >> "%config_root%\BCD"
echo BOOT_COUNT=0 >> "%config_root%\BCD"
echo LAST_BOOT_SUCCESS=Never >> "%config_root%\BCD"

echo [%date% %time% WARNING] SFC_SILENT_REPAIR_SUCCESS >> "%log_path%"
echo [ DONE ] Repair complete. Returning to terminal.
pause & goto cmd_loop

:as_unpacker
setlocal disabledelayedexpansion
set /p "arc_sel=Enter archive to unpack: "
if NOT exist "%arc_sel%" echo [ ERROR ] Not found. & pause & goto cmd_loop

echo [ WAIT ] Extracting files...
set "current_f="
for /f "usebackq delims=" %%l in ("%arc_sel%") do (
    set "line=%%l"
    setlocal enabledelayedexpansion
    echo !line! | findstr /c:":FILE_START:" >nul
    if !errorlevel! EQU 0 (
        for /f "tokens=2 delims=:" %%f in ("!line!") do set "current_f=%%f"
        echo [ EXTRACT ] Writing: !current_f!
        type nul > "!current_f!"
    ) else (
        echo !line! | findstr /c:":FILE_END:" >nul
        if !errorlevel! EQU 0 (
            set "current_f="
        ) else (
            if defined current_f (
                if NOT "!line:~0,2!"=="::" echo !line! >> "!current_f!"
                if "!line:~0,2!"=="::" echo !line! >> "!current_f!"
            )
        )
    )
)
goto cmd_loop

:help
echo Apps: Notepad, Calc (Must be installed from ArsStore), taskmgr, edit, install, regedit, ArsStore, as-pack, as-unpack, sysinfo
echo System: Help, Lock, ping, sudo, cls, Shutdown, ver, fmx, whoami, reboot, clean, service, events, restore-point, restore, passwd, backup, backup-restore, ls, cd, cat, ren, mkdir, touch, cp, mv
echo Admin: adduser, deluser, alert, Guest, report, reset, reboot_to_recovery, chattr, bsod, rm, netstat, ipconfig, tracert, nslookup, arp, route, loader_error, bcdboot, bcdedit
goto cmd_loop

:restore_point
if NOT exist "%config_root%" md "%config_root%" 2>nul
if NOT exist "%restore_root%" md "%restore_root%" 2>nul

set "rp_name=RP_%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "rp_name=%rp_name: =0%"

md "%restore_root%\%rp_name%" 2>nul

copy /y "%kernel_path%" "%restore_root%\%rp_name%\kernel.dll" >nul
copy /y "%reg_path%" "%restore_root%\%rp_name%\REG.cfg" >nul
copy /y "%log_path%" "%restore_root%\%rp_name%\system.log" >nul

echo [%date% %time% INFO] RESTORE_POINT_CREATED: %rp_name% >> "%log_path%"
echo [ OK ] Restore point created: %rp_name%
pause
goto cmd_loop

:taskmgr
set /a "cpu=%random% %% 15 + 1"
echo [ CORE ] BarOS 22.0 (CPU: !cpu!%%)
goto cmd_loop

:clean
for /d %%i in (NewFolder*) do rd /s /q "%%i"
echo [ OK ] Cleaned.
goto cmd_loop

:store
cls
echo ======================================================================================================================
echo                                                     ARSLANIUS STORE [v2.0]
echo ======================================================================================================================
echo Available Apps:
echo [ 1 ] System Scanner (Utility)
echo [ 2 ] NotePad Lite (Office)
echo [ 3 ] Calc (Utility)
echo [ 0 ] Exit Store
echo ----------------------------------------------------------------------------------------------------------------------
set /p "s_choice=Enter App ID to Install: "

if "%s_choice%"=="0" goto cmd_loop
if "%s_choice%"=="1" set "app=Scanner" & set "label=app_Scanner"
if "%s_choice%"=="2" set "app=NoteLite" & set "label=app_NoteLite"
if "%s_choice%"=="3" set "app=Calc" & set "label=app_Calculator"

if not defined app goto store

echo [ WAIT ] Installing %app%...

if not exist "%programs_root%" md "%programs_root%"
copy nul "%programs_root%\%app%.bat" >nul

set "start_line="
set "end_line="
for /f "tokens=1 delims=:" %%a in ('findstr /n /i ":%label%" "%~f0"') do set /a start_line=%%a
for /f "tokens=1 delims=:" %%a in ('findstr /n /i "^goto :EOF" "%~f0"') do if %%a gtr !start_line! if not defined end_line set /a end_line=%%a

if not defined start_line (
    echo [ ERROR ] App code not found.
    pause
    goto store
)

(for /f "tokens=1* delims=:" %%a in ('findstr /n "^" "%~f0"') do (
    if %%a gtr !start_line! if %%a lss !end_line! echo %%b
)) > "%programs_root%\%app%.bat"

echo [ OK ] %app% installed to Programs.
pause
goto store

:edit
set /p "ef=File: " & set /p "et=Text: "
echo %et% >> "%ef%" & goto cmd_loop

:guest_toggle
set /p "g_act=Enable Guest Mode? (Y/N): "
if /i "%g_act%"=="Y" (
    call :hash "GUEST"
    echo GUEST = !errorlevel! >> "%kernel_path%"
    md "%users_root%\GUEST" 2>nul
    echo [ OK ] Guest mode ACTIVE. Login: GUEST / Pass: GUEST
) else (
    type "%kernel_path%" | findstr /v /i /c:"GUEST =" > "%kernel_path%.tmp"
    move /y "%kernel_path%.tmp" "%kernel_path%" >nul
    rd /s /q "%users_root%\GUEST" 2>nul
    echo [ OK ] Guest mode DISABLED. Profile wiped.
)
pause & goto cmd_loop

:: ========== STORE APPS ==========
:app_Scanner
@echo off
echo Scanning %userprofile%...
dir /s /b "%cd%" > "%cd%\scan_%date%.txt"
echo Scan complete. Saved to scan_%date%.txt
pause
exit /b

:app_NoteLite
@echo off
set /p "txt=Enter text: "
echo %txt% >> "%cd%\notes.txt"
echo Note saved.
pause
exit /b

:app_Calculator
@echo off
title Calculator
color 2f
::::: :start
set /p sum=Please enter the question:
set /a ans=%sum%
echo The Answer=%ans%
pause
cls
echo Previos Answer=%ans%
cls
:: goto start
:EOF

:start
cls 
echo ----------------------------------------------------------------------------------------------------------------------
echo                                         1. Explorer (FMX)    4. Regedit (REG)
echo                                         2. Reboot            5. Control (DASH)
echo                                         3. ArsStore          0. Exit Menu
echo ----------------------------------------------------------------------------------------------------------------------
echo                                         [ Recent Apps: ArsStore, notepad ]
echo ----------------------------------------------------------------------------------------------------------------------
set /p "win_c=Search or Select: "

if "%win_c%"=="1" goto fmx
if "%win_c%"=="2" goto boot
if "%win_c%"=="3" goto store
if "%win_c%"=="4" goto regedit
if "%win_c%"=="5" goto dash
if "%win_c%"=="0" goto cmd_loop
goto start 

:restore
if not exist "%restore_root%" (
    echo [ ERROR ] No restore points directory.
    pause & goto cmd_loop
)

echo Available restore points:
dir /b "%restore_root%"
echo.
set /p "rp_sel=Enter restore point name: "

if "%rp_sel%"=="" goto cmd_loop
if not exist "%restore_root%\%rp_sel%\kernel.dll" (
    echo [ ERROR ] Invalid restore point.
    pause & goto cmd_loop
)

copy /y "%restore_root%\%rp_sel%\kernel.dll" "%kernel_path%" >nul
copy /y "%restore_root%\%rp_sel%\REG.cfg" "%reg_path%" >nul
copy /y "%restore_root%\%rp_sel%\system.log" "%log_path%" >nul

echo [%date% %time% INFO] RESTORE_APPLIED: %rp_sel% >> "%log_path%"
echo [ DONE ] System restored from %rp_sel%.
echo [ INFO ] Reboot recommended.
pause
goto boot

:bsod
if /i "%bsod%"=="1a" (
   cls
   color 17
   echo *** STOP: 0x00000001a [0xc00000001a, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files
   echo.
   echo CONFIG_ROOT_NOT_FOUND - The config root is missing.
   echo Please reinstall or run Startup Repair.
   echo.
   echo If this is the first time you've seen this error, restart the system.
   echo If it appears again, run Startup Repair from the recovery environment.
   echo.
   echo Technical information:
   echo *** Address 0x00000001a base at Settings And System Files - CONFIG_ROOT_NOT_FOUND
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)

if /i "%bsod%"=="1" (
   cls
   color 17
   echo *** STOP: 0x00000001 [0xc00000001, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files\kernel.dll
   echo.
   echo KERNEL_NOT_FOUND - The system kernel file is missing or corrupted.
   echo Please reinstall or run Startup Repair to restore the kernel.
   echo.
   echo If this is the first time you've seen this error, restart the system.
   echo If it appears again, run Startup Repair from the recovery environment.
   echo.
   echo Technical information:
   echo *** Address 0x00000001 base at kernel.dll - KERNEL_NOT_FOUND
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)
cls

if /i "%bsod%"=="2" (
   cls
   color 17
   echo *** STOP: 0x00000002 [0xc00000002, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files\kernel.dll
   echo.
   echo SYSTEM_ACCOUNT_HASH_MISMATCH - Someone's been playing with kernel.dll in Notepad, huh?
   echo The SYSTEM account hash doesn't match. Nice try, hacker.
   echo.
   echo Technical information:
   echo *** Expected hash: !expected_system_hash!
   echo *** Found hash: !system_hash!
   echo *** Hash mismatch detected in kernel space.
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)
cls

if /i "%bsod%"=="3" (
   cls
   color 17
   echo *** STOP: 0x00000003 [0xc00000003, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files\REG.cfg
   echo.
   echo REGISTRY_VERSION_MISMATCH - Time traveler detected!
   echo This registry belongs to another version of ARSLANIUS.
   echo Your system expects version %reg_version%, but found %reg_versions%.
   echo.
   echo Technical information:
   echo *** Expected version: %reg_version%
   echo *** Found version: %reg_versions%
   echo *** Registry version mismatch - possible time paradox.
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)
cls

if /i "%bsod%"=="4" (
   cls
   color 17
   echo *** STOP: 0x00000004 [0xc00000004, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files\REG.cfg
   echo.
   echo REGISTRY_NOT_FOUND - REG.cfg? Never heard of her.
   echo The registry is missing. No settings, no colors, no nothing.
   echo.
   echo Technical information:
   echo *** Registry file not found at specified path.
   echo *** System cannot function without registry configuration.
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)
cls

if /i "%bsod%"=="5" (
   cls
   color 4f
   echo *** STOP: 0x00000005 [0xc00000005, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files\kernel.dll
   echo.
   echo RESERVED_USERNAME_DETECTED - Security violation!
   echo Someone tried to create 'BarOS AUTHORITY' in kernel.dll.
   echo That's like printing your own "100%% REAL OFFICIAL" dollar bill.
   echo.
   echo Technical information:
   echo *** Reserved username found in kernel space.
   echo *** System halted to prevent unauthorized access.
   echo.
   echo If you call a support specialist, tell him this information so that he can laugh.
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)
cls

if /i "%bsod%"=="6" (
   cls
   color 17
   echo *** STOP: 0x00000006 [0xc00000006, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files\kernel.dll
   echo.
   echo ADMIN_ACCOUNT_HASH_MISMATCH - Someone tried to give themselves admin privileges the hard way.
   echo The ADMINISTRATOR hash doesn't match. Spoiler: it didn't work.
   echo.
   echo Technical information:
   echo *** Expected admin hash: !expected_admin_hash!
   echo *** Found admin hash: !admin_hash!
   echo *** Access denied. Run Startup Repair to restore sanity.
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)
cls

if /i "%bsod%"=="7" (
   cls
   color 17
   echo *** STOP: 0x00000007 [0xc0000007, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files\REG.cfg
   echo.
   echo BAD_SYSTEM_CONFIG_INFO - The registry is missing required entries.
   echo OS_NAME, SYSTEM_COLOR, ADMIN_COLOR, USER_COLOR, ENABLE_LUA, or REG_VERSION
   echo is missing. Run Startup Repair to restore the registry.
   echo.
   echo Technical information:
   echo *** Registry file found but incomplete.
   echo *** Expected entries: OS_NAME, SYSTEM_COLOR, ADMIN_COLOR, USER_COLOR,
   echo *** ENABLE_LUA, REG_VERSION
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)

if /i "%bsod%"=="8" (
   cls
   color 17
   echo *** STOP: 0x00000008 [0xc00000008, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files\kernel.dll
   echo.
   echo KERNEL_INCOMPLETE - The kernel is missing required SYSTEM or ADMINISTRATOR entries.
   echo Someone deleted important lines from kernel.dll. Probably with Notepad.
   echo Run Startup Repair to restore the missing entries.
   echo.
   echo Technical information:
   echo *** Missing: SYSTEM or SYSTEM ADMINISTRATOR account
   echo *** Kernel file found but incomplete.
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)

if /i "%bsod%"=="9" (
   cls
   color 4f
   echo *** STOP: 0x00000009 [0x00000009, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \ARSLANIUS 26.cmd
   echo.
   echo LOGON_ATTACK_DETECTED - Too many failed login attempts.
   echo A brute force attack may be in progress.
   echo.
   echo Technical information:
   echo *** Failed attempts: 10
   echo *** System halted to prevent unauthorized access.
   echo *** Run Recovery Environment to investigate.
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)

if /i "%bsod%"=="10" (
   cls
   color 17
   echo *** STOP: 0x00000010 [0xc00000010, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files\kernel.dll
   echo.
   echo The kernel is full, run startup repair to reset it.
   echo Looks like someone needed TOO many accounts.
   echo Run Startup Repair to restore kernel.
   echo.
   echo Technical information:
   echo *** Size: %kernelsize% bytes
   echo *** Kernel file found but locked.
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)

if /i "%bsod%"=="11" (
   cls
   color 17
   echo *** STOP: 0x00000011 [0xc00000011, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo *** File: \Settings And System Files\REG.cfg
   echo.
   echo The registry is full, run startup repair to reset it.
   echo Looks like someone filled the registry with all sorts of junk, huh?
   echo Run Startup Repair to restore registry.
   echo.
   echo Technical information:
   echo *** Size: %registrysize% bytes
   echo *** REG file found but locked.
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto repair
)

if /i "%bsod%"=="12" (
    cls
    color 17
    echo *** STOP: 0x00000012 [0xc00000012, 0x00000000, 0x00000000, 0x00000000]
    echo.
    echo *** File: \Settings And System Files\system.log
    echo.
    echo LOG_OVERFLOW - The system log is full of shit.
    echo Someone's been writing a novel in system.log.
    echo 150 KB is the limit. Run Startup Repair to clear the log.
    echo.
    echo Technical information:
    echo *** Size: %logsize% bytes
    echo *** Log file found but locked due to size limit.
    echo.
    echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
    pause
    goto repair
)

if /i "%bsod%"=="666" (
   cls
   color 17
   echo *** STOP: 0xDEADBEEF [0x00000666, 0x00000000, 0x00000000, 0x00000000]
   echo.
   echo MANUAL_CRASH - You typed 'bsod' or 'loader_error' and now you're here. Surprised? You shouldn't be.
   echo This error was intentionally triggered by the 'bsod' command.
   echo No real damage was done. Just reboot and continue.
   echo.
   echo Technical information:
   echo *** Crash initiated by user: %current_user%
   echo *** Stop code: 0xTeam_by_%current_user%
   echo *** Next time try 'help' instead. Or don't. I'm not your mom.
   echo.
   echo For support, visit: https://github.com/Armsoup/ARSLANIUS/issues
   pause
   goto boot
)