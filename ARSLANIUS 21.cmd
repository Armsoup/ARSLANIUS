
@echo off
setlocal enabledelayedexpansion
title ARSLANIUS 21 Release Candidate

set "root_path=%~dp0"
if "%root_path:~-1%"=="\" set "root_path=%root_path:~0,-1%"

set "current_build=51.1"
set "kernel_path=%root_path%\Setting And System Files\kernel.dll"
set "users_root=%root_path%\Users"
set "programs_root=%root_path%\Programs"
set "sys_prof=%root_path%\Setting And System Files\systemprofile"
set "sys_services=%root_path%\Setting And System Files\systemprofile"
set "reg_path=%root_path%\Setting And System Files\REG.cfg"
set "log_path=%root_path%\Setting And System Files\system.log"
set "restore_root=%root_path%\RestorePoints"

:boot
set "safe_mode=0"
echo [%date% %time%] LOADER_COMPLETE >> "%log_path%" 2>nul
color 0f
cls
echo ========================================
echo        %os_name% BOOT MENU
echo ========================================
echo  1. Start ARSLANIUS Normally
echo  2. Safe Mode (No Services / No Autorun)
echo ----------------------------------------
set /p "boot_choice=Select option (1-2): "

if "%boot_choice%"=="2" (
    set "safe_mode=1"
    echo [ INFO ] Safe Mode enabled.
    timeout /t 1 >nul
    del /f /q "%sys_services%\SysPulse.active"
    del /f /q "%sys_services%\SFC_Daemon.active"
)

cls
echo [  WAIT  ] BarOS Kernel 18.0 (%os_name%) starting...
timeout /t 1 >nul

if exist "%kernel_path%" goto kernel_ok
color 4f
echo =====================================================
echo [ FATAL ERROR ] KERNEL_NOT_FOUND
echo.
echo System core file is missing or corrupted.
echo Press [R] to Repair System or any other key to Exit.
echo =====================================================
set /p "choice=> "
if /i "!choice!"=="R" goto bsod 
exit

:repair
cls
color 1f
echo ================================================
echo     ARSLANIUS 21 RECOVERY ENVIRONMENT
echo ================================================
echo.
echo  [1] Startup Repair        - Fix kernel/registry
echo  [2] System Restore        - Go to restore points
echo  [3] System Image Recovery - Restore from backup
echo  [4] Memory Diagnostic     - Check system memory
echo  [5] Return to boot menu
echo.
echo ================================================
set /p "recovery_choice=Select option (1-5): "

if "%recovery_choice%"=="1" goto startup_repair
if "%recovery_choice%"=="2" goto restore_menu
if "%recovery_choice%"=="3" goto image_recovery
if "%recovery_choice%"=="4" goto memory_diag
if "%recovery_choice%"=="5" goto boot
goto recovery_env

:startup_repair
echo.
echo [ WAIT ] Running Startup Repair...
if not exist "%root_path%\Setting And System Files" md "%root_path%\Setting And System Files"
if not exist "%sys_services%" md "%sys_services%" 2>nul

call :hash "Acy98iolop_isArslanius-kop"
echo SYSTEM = !errorlevel! > "%kernel_path%"
call :hash "Jiupolaqmn_isArslanius-lo"
echo SYSTEM ADMINISTRATOR = !errorlevel! >> "%kernel_path%"

echo OS_NAME = ARSLANIUS 21 > "%reg_path%"
echo SYSTEM_COLOR=0e >> "%reg_path%"
echo ADMIN_COLOR=4f >> "%reg_path%"
echo USER_COLOR=1f >> "%reg_path%"

echo [%date% %time%] KERNEL_RESTORED_BY_RECOVERY >> "%log_path%" 2>nul
echo.
echo [ OK ] Startup Repair completed.
pause
goto repair

:restore_menu
if not exist "%root_path%\Setting And System Files" md "%root_path%\Setting And System Files"
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

echo [%date% %time%] RESTORE_APPLIED_FROM_RECOVERY: %rp_sel% >> "%log_path%" 2>nul
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
echo [%date% %time%] IMAGE_RESTORE_EXECUTED >> "%log_path%" 2>nul
echo [ OK ] System image restored.
pause
goto repair

:memory_diag
cls
color 1f
echo ================================================
echo     ARSLANIUS 21 MEMORY DIAGNOSTIC
echo ================================================
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
set "sys_pass="
for /f "tokens=2 delims==" %%a in ('findstr /i /c:"SYSTEM =" "%kernel_path%" 2^>nul') do set "sys_pass=%%a"
if "%sys_pass%"=="" color 4f & echo [ FATAL ] KERNEL_DATA_CORRUPT & pause & goto bsod

if not exist "%reg_path%" goto bsod 
for /f "tokens=2 delims==" %%n in ('findstr /i "OS_NAME" "%reg_path%"') do set "os_name=%%n"
for /f "tokens=2 delims==" %%c in ('findstr /i "SYSTEM_COLOR" "%reg_path%"') do color %%c

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
    
    if not defined code set "code=65"
    
    set /a "hash_val=hash_val * 31 + code + salt"
    set /a "hash_val=hash_val %% 1000000"
    set "code="
)
:hash_done
echo %hash_val%
exit /b %hash_val%

:logon_screen
set "current_user=SYSTEM"
set "user_home=%sys_prof%"
cd /d "%user_home%" 2>nul
echo [%date% %time%] BOOT_V21_INIT_%current_user% >> "%log_path%" 2>nul
cls
color 5b
echo ========================================
echo        %os_name% LOCK SCREEN
echo ========================================
echo Status: Protected / Context: %current_user%
echo ----------------------------------------
echo COMMANDS: Shutdown, Reboot
echo ----------------------------------------
echo.
set "u_in=" & set "p_in="
set /p "u_in=Username: "

if /i "%u_in%"=="Shutdown" echo [%date% %time%] SHUTDOWN_FROM_LOGON >> "%log_path%" & exit
if /i "%u_in%"=="Reboot" echo [%date% %time%] REBOOT_FROM_LOGON >> "%log_path%" & goto boot

if "%u_in%"=="" goto logon_screen
set /p "p_in=Password: "

set "stored_hash="
for /f "tokens=2 delims==" %%a in ('findstr /i /c:"%u_in% =" "%kernel_path%" 2^>nul') do set "stored_hash=%%a"
if not defined stored_hash echo [ ERROR ] User not found. & pause & goto logon_screen
set "stored_hash=%stored_hash: =%"
call :hash "%p_in%"
if NOT "!errorlevel!"=="%stored_hash%" echo [ ERROR ] Password incorrect. & pause & goto logon_screen

set "current_user=%u_in%"
if /i "%current_user%"=="SYSTEM" (set "user_home=%sys_prof%") else (set "user_home=%users_root%\%current_user%")
if not exist "%user_home%" md "%user_home%" 2>nul

if /i "%current_user%"=="SYSTEM" set "reg_key=SYSTEM_COLOR" & goto apply_color
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" set "reg_key=ADMIN_COLOR" & goto apply_color
set "reg_key=USER_COLOR" & goto apply_color

:apply_color
for /f "tokens=2 delims==" %%c in ('findstr /i "%reg_key%" "%reg_path%"') do color %%c
cd /d "%user_home%" 2>nul

:interface
if "%safe_mode%"=="0" (
    if not exist "%sys_services%\SysPulse.active" (
        echo [ KERNEL ] Booting background service: SysPulse...
        echo RUNNING > "%sys_services%\SysPulse.active" 2>nul
        timeout /t 1 >nul
    )
    if not exist "%sys_services%\SFC_Daemon.active" (
        echo [ KERNEL ] Booting background service: SFC_Daemon...
        echo RUNNING > "%sys_services%\SFC_Daemon.active" 2>nul
        timeout /t 1 >nul
    )
)

cls
if exist "alert.sys" (
    color 4f
    echo ========================================
    echo        CRITICAL SYSTEM ALERT
    echo ========================================
    echo.
    type "alert.sys"
    echo.
    echo ----------------------------------------
    echo.
    set /p "ack=Press ENTER to acknowledge and continue..."
    del /f /q "alert.sys"
    echo [%date% %time%] alert_viewed_%current_user% >> "%log_path%" 2>nul

    for /f "tokens=2 delims==" %%c in ('findstr /i "%reg_key%" "%reg_path%"') do color %%c
    goto interface
)

if "%safe_mode%"=="1" color 07
echo %os_name% [Build %current_build%] - Session: %current_user% ^(SAFE MODE: %safe_mode%^)
echo Profile: %cd%
echo ----------------------------------------

if "%safe_mode%"=="1" goto cmd_loop
if exist "mail.txt" echo [ MAIL ] You have unread messages! Type "mail-read".
if exist "autorun.txt" (
    for /f "tokens=*" %%a in (autorun.txt) do (
        echo [ AUTO ] Starting: %%a...
        set "ex_c=%%a"
        goto core_auto
    )
)

:cmd_loop
if "%safe_mode%"=="1" goto skip_all_services

if exist "%sys_services%\SFC_Daemon.active" (
    set "sfc_err=0"
    if NOT exist "%kernel_path%" set "sfc_err=1"
    if NOT exist "%reg_path%" set "sfc_err=1"
    
    if "!sfc_err!"=="1" (
        echo [ SFC_DAEMON ] Integrity violation detected!
        echo [ SFC_DAEMON ] Executing background repair...
        if NOT exist "%kernel_path%" (
            call :hash "Acy98iolop_isArslanius-kop"
echo SYSTEM = !errorlevel! > "%kernel_path%"
            call :hash "Jiupolaqmn_isArslanius-lo"
echo SYSTEM ADMINISTRATOR = !errorlevel! >> "%kernel_path%"
        )
        echo OS_NAME = %os_name% > "%reg_path%"
        echo SYSTEM_COLOR=0e >> "%reg_path%"
        echo ADMIN_COLOR=4f >> "%reg_path%"
        echo USER_COLOR=1f >> "%reg_path%"
        echo [%date% %time%] SFC_DAEMON: AUTO_REPAIR_SUCCESS >> "%log_path%"
        echo [ SFC_DAEMON ] System restored.
    )
)

if exist "%sys_services%\SysPulse.active" (
    if exist "NewFolder" rd /s /q "NewFolder" 2>nul
    
    set /a "pulse_check=!random! %% 10"
    if "!pulse_check!"=="5" echo [%date% %time%] SYSPULSE: System Health OK >> "%log_path%"
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
if /i "%current_user%"=="SYSTEM" set "ex_c=%t_c%" & goto core
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" set "ex_c=%t_c%" & goto core
set /p "a_p=Enter ADMIN password: "
set "admin_hash="
for /f "tokens=2 delims==" %%s in ('findstr /i /c:"SYSTEM ADMINISTRATOR =" "%kernel_path%" 2^>nul') do set "admin_hash=%%s"
set "admin_hash=!admin_hash: =!"
call :hash "!a_p!"
if "!errorlevel!"=="!admin_hash!" ( 
    echo [%date% %time%] SUDO_EXEC: !t_c! BY %current_user% >> "%log_path%" 2>nul
    set "ex_c=%t_c%" & goto core
)
echo [ ERROR ] Access denied. & goto cmd_loop

:check_r
set "is_ok=0"
for %%a in (Help logout passwd reboot_to_recovery lock ArsStore NoteLite Snake ttt Scanner fmx restore restore-point mail-send mail-read clean report cls ver whoami Calc Notepad miner.game reboot shutdown) do (if /i "%ex_c%"=="%%a" set "is_ok=1")

if "%is_ok%"=="0" (
    if /i "%current_user%"=="SYSTEM" goto core
    if /i "%current_user%"=="SYSTEM ADMINISTRATOR" goto core
    echo Error: Access Denied. Use "sudo %cmd%".
    goto cmd_loop
)
goto core

:core
:core_auto
if /i "%current_user%"=="GUEST" (
    set "ok=0"
    for %%a in (Help logout support report cls ver dir whoami Calc Notepad miner.game reboot shutdown) do (if /i "%ex_c%"=="%%a" set "ok=1")
    if "!ok!"=="0" echo [ SECURITY ] Guest cannot use this command. & goto cmd_loop
)
if /i "%safe_mode%"=="1" (
    set "ok=0"
    for %%a in (Help logout support reset reboot_to_recovery report cls ver dir whoami events sfc dash fmx restore-point restore adduser deluser start regedit reboot shutdown) do (if /i "%ex_c%"=="%%a" set "ok=1")
    if "!ok!"=="0" echo [ SECURITY ] Safe mode. & goto cmd_loop
)
if /i NOT "%current_user%"=="SYSTEM" goto exec
set "ok=0"
for %%a in (Help reset logout lock support reboot_to_recovery report cls ver taskmgr fmx Shutdown Reboot dir adduser whoami sfc clean mail-read mail-send edit guest msg-all regedit install deluser alert restore-point restore) do (if /i "%ex_c%"=="%%a" set "ok=1")
if "%ok%"=="0" echo [ SECURITY ] Restricted context. & goto cmd_loop

:exec
:: --- NEW COMMANDS V21 ---
if /i "%ex_c%"=="reboot_to_recovery" goto repair

:: --- STANDART COMMANDS ---
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
if /i "%ex_c%"=="logout" goto boot
if /i "%ex_c%"=="lock" goto logon_screen
if /i "%ex_c%"=="cls" goto interface
if /i "%ex_c%"=="ver" echo %os_name% [Build %current_build%] & goto cmd_loop
if /i "%ex_c%"=="Notepad" start notepad.exe & goto cmd_loop
if /i "%ex_c%"=="Calc" start "" "%programs_root%\Calc.bat" & goto cmd_loop
if /i "%ex_c%"=="MiniDOS" start "" "%root_path%\Setting And System Files\MiniDOS.SYSTEM.Files\RS-DOS.bat" & goto cmd_loop
if /i "%ex_c%"=="CreatedFolder" md "NewFolder" & echo [ OK ] Folder created. & goto cmd_loop
if /i "%ex_c%"=="miner.game" start "" "%programs_root%\miner.cmd" & goto cmd_loop
if /i "%ex_c%"=="reboot" goto boot
if /i "%ex_c%"=="Shutdown" del /f /q "%sys_services%\SysPulse.active" & del /f /q "%sys_services%\SFC_Daemon.active" & exit

echo "%ex_c%" is not recognized.
goto cmd_loop

:msg_all
set /p "m_txt=Global Message: "
for /d %%d in ("%users_root%\*") do (echo [GLOBAL] From %current_user%: %m_txt% >> "%%d\mail.txt")
echo [GLOBAL] From %current_user%: %m_txt% >> "%sys_prof%\mail.txt"
echo [ OK ] Broadcast sent.
goto cmd_loop

:dash
cls
echo ========================================
echo        %os_name% CONTROL CENTER
echo ========================================
set "u_count=0"
for /f %%a in ('find /c "=" ^< "%kernel_path%"') do set "u_count=%%a"

echo [ STATS ] Registered Users: %u_count%
echo [ STATS ] OS Name: %os_name%
echo [ STATS ] Kernel: BarOS 18.0 (V21)

echo.
echo [ SERVICES ]
if exist "%sys_services%\SysPulse.active" (echo  - SysPulse: ONLINE) else (echo  - SysPulse: OFFLINE)
if exist "%sys_services%\SFC_Daemon.active" (echo  - SFC_Daemon: ONLINE) else (echo  - SFC_Daemon: OFFLINE)

echo.
echo [ ENV ]
echo root_path=%root_path%
echo kernel_path=%kernel_path%
echo current_build=Build %current_build%
echo user_home=%user_home%
echo current_user=%current_user%
echo ========================================
pause
goto cmd_loop

:sys_report
echo [ WAIT ] Generating HTML Report...
set "report_f=%user_home%\Report_v21.html"
echo ^<html^>^<body style='background:#111;color:#0f0;font-family:monospace'^> > "%report_f%"
echo ^<h1^>ARSLANIUS 21 - SYSTEM REPORT^</h1^> >> "%report_f%"
echo ^<hr^>^<p^>Build: %current_build%^</p^> >> "%report_f%"
echo ^<p^>Kernel: 18.0^</p^> >> "%report_f%"
echo ^<p^>Active User: %current_user%^</p^> >> "%report_f%"
echo ^<p^>Log Size: %log_path%^</p^> >> "%report_f%"
echo ^<h2^>Registered Users:^</h2^>^<pre^> >> "%report_f%"
type "%kernel_path%" >> "%report_f%"
echo ^</pre^>^</body^>^</html^> >> "%report_f%"
echo [ OK ] Report generated: %report_f%
start "" "%report_f%"
pause & goto cmd_loop

:passwd
if /i "%current_user%"=="SYSTEM" echo Cannot change SYSTEM password. & pause & goto cmd_loop
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" echo Cannot change ADMIN password. & pause & goto cmd_loop

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
echo ========================================
echo        ARSLANIUS EVENT VIEWER
echo ========================================
echo [ INFO ] Filtering critical events...
echo ----------------------------------------
findstr /i "ALERT ERROR SFC CRITICAL DELETED SUDO" "%log_path%" 2>nul
if !errorlevel! NEQ 0 echo [ INFO ] No critical events found.
echo ----------------------------------------
pause
goto cmd_loop

:reset
echo WARNING: This will delete ALL users and reset system to defaults.
set /p "conf=Type YES to continue: "
if /i "!conf!"=="YES" goto startup_repair
echo Canceled.
goto cmd_loop

:regedit
if /i NOT "%current_user%"=="SYSTEM ADMINISTRATOR" if /i NOT "%current_user%"=="SYSTEM" (
    echo [ SECURITY ] Access Denied. Only for Admins. & goto cmd_loop
)
echo.
echo -- SYSTEM CONFIGURATION EDITOR --
echo Current OS Name: %os_name%
set /p "new_name=Enter new OS Name (or Enter to skip): "
if NOT "%new_name%"=="" (
    echo OS_NAME = %new_name% > "%reg_path%"
    echo [ OK ] OS Name updated.
)
echo [ 1 ] System Color (0e)
echo [ 2 ] Admin Color (4f)
echo [ 3 ] User Color (1f)
set /p "c_choice=Select color to change (1-3): "
set /p "c_val=Enter HEX color (ex: 0a): "

if "%c_choice%"=="1" echo SYSTEM_COLOR=%c_val% >> "%reg_path%"
if "%c_choice%"=="2" echo ADMIN_COLOR=%c_val% >> "%reg_path%"
if "%c_choice%"=="3" echo USER_COLOR=%c_val% >> "%reg_path%"

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

if "%nu%"=="" echo [ ERROR ] Name cannot be empty. & goto cmd_loop
if "%np%"=="" echo [ ERROR ] Password cannot be empty. & goto cmd_loop

findstr /i /c:"%nu% =" "%kernel_path%" >nul
if !errorlevel! EQU 0 echo [ ERROR ] User already exists. & goto cmd_loop

(echo.) >> "%kernel_path%"
call :hash "%np%"
echo %nu% = !errorlevel! >> "%kernel_path%"

md "%users_root%\%nu%" 2>nul

echo [%date% %time%] NEW_USER_CREATED: %nu% >> "%log_path%" 2>nul
echo [ OK ] User %nu% created. Profil folder generated.
echo.
goto cmd_loop

:alert_all
echo.
echo -- DEPLOY CRITICAL SYSTEM ALERT --
set /p "al_txt=Alert message: "

for /d %%d in ("%users_root%\*") do (echo %al_txt% > "%%d\alert.sys")
echo %al_txt% > "%sys_prof%\alert.sys"

echo [%date% %time%] GLOBAL_ALERT_SENT: %al_txt% >> "%log_path%" 2>nul
echo [ OK ] Critical alert deployed to all stations.
echo.
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
echo ========================================
echo        FILE MANAGER X (ARSLANIUS)
echo ========================================
echo Current directory: %cd%
echo ----------------------------------------
set "f_num=0"
for %%f in (*.*) do (
    set /a f_num+=1
    echo [ !f_num! ] %%f  (!%%~zf bytes!)
)
echo ----------------------------------------
echo [0] Exit  [Name] Actions
set /p "f_choice=Select file name to manage: "
if "%f_choice%"=="0" goto cmd_loop

:fmx_actions
echo Action for %f_choice%: [1] Read [2] Delete [3] Hide [4] Back
set /p "f_act=Choice: "
if "%f_act%"=="1" cls & type "%f_choice%" & pause & goto fmx
if "%f_act%"=="2" del /f /q "%f_choice%" & echo [ OK ] Deleted. & pause & goto fmx
if /i "%current_user%"=="SYSTEM" (
    if "%f_act%"=="3" attrib +h "%f_choice%" & echo [ OK ] Hidden. & pause & goto fmx
)
goto fmx

:whoami
echo Current User: %current_user%
if /i "%current_user%"=="SYSTEM" echo Permissions: KERNEL
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" echo Permissions: ADMIN
echo Path: %cd%
goto cmd_loop

:sfc_scan
echo.
echo [ SYSTEM ] Beginning system file check...
timeout /t 1 >nul
set "errors=0"

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
if not exist "%root_path%\Setting And System Files" md "%root_path%\Setting And System Files" 2>nul
if NOT exist "%kernel_path%" (
    call :hash "Acy98iolop_isArslanius-kop"
echo SYSTEM = !errorlevel! >> "%kernel_path%"
    call :hash "Jiupolaqmn_isArslanius-lo"
echo SYSTEM ADMINISTRATOR = !errorlevel! >> "%kernel_path%"
)
echo OS_NAME = %os_name% > "%reg_path%"
echo SYSTEM_COLOR=0e >> "%reg_path%"
echo ADMIN_COLOR=4f >> "%reg_path%"
echo USER_COLOR=1f >> "%reg_path%"

echo [%date% %time%] SFC_SILENT_REPAIR_SUCCESS >> "%log_path%"
echo [ DONE ] Repair complete. Returning to terminal.
pause & goto cmd_loop

:as_unpacker
set /p "arc_sel=Enter archive to unpack: "
if NOT exist "%arc_sel%" echo [ ERROR ] Not found. & pause & goto cmd_loop

echo [ WAIT ] Extracting files...
set "current_f="
for /f "usebackq delims=" %%l in ("%arc_sel%") do (
    set "line=%%l"
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
echo Apps: Notepad, Calc, taskmgr, miner.game, edit, install, regedit, ArsStore, as-pack, as-unpack
echo System: Help, Logout, Lock, sudo, cls, Shutdown, ver, fmx, whoami, reboot, clean, service, events, restore-point, restore, passwd
echo Admin: CreatedFolder, MiniDOS, adduser, deluser, alert, Guest, report, reset, reboot_to_recovery
goto cmd_loop

:restore_point
if not exist "%restore_root%" md "%restore_root%" 2>nul

set "rp_name=RP_%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "rp_name=%rp_name: =0%"

md "%restore_root%\%rp_name%" 2>nul

copy /y "%kernel_path%" "%restore_root%\%rp_name%\kernel.dll" >nul
copy /y "%reg_path%" "%restore_root%\%rp_name%\REG.cfg" >nul
copy /y "%log_path%" "%restore_root%\%rp_name%\system.log" >nul

echo [%date% %time%] RESTORE_POINT_CREATED: %rp_name% >> "%log_path%"
echo [ OK ] Restore point created: %rp_name%
pause
goto cmd_loop

:taskmgr
set /a "cpu=%random% %% 15 + 1"
echo [ CORE ] BarOS 18.0 (CPU: !cpu!%%)
goto cmd_loop

:clean
for /d %%i in (NewFolder*) do rd /s /q "%%i"
echo [ OK ] Cleaned.
goto cmd_loop

:store
cls
echo ========================================
echo        ARSLANIUS STORE [v2.0]
echo ========================================
echo Available Apps:
echo [ 1 ] System Scanner (Utility)
echo [ 2 ] NotePad Lite (Office)
echo [ 0 ] Exit Store
echo ----------------------------------------
set /p "s_choice=Enter App ID to Install: "

if "%s_choice%"=="0" goto cmd_loop
if "%s_choice%"=="1" set "app=Scanner" & set "label=app_Scanner"
if "%s_choice%"=="2" set "app=NoteLite" & set "label=app_NoteLite"

if not defined app goto store

echo [ WAIT ] Installing %app%...

:: Создаём пустой .bat файл
if not exist "%programs_root%" md "%programs_root%"
copy nul "%programs_root%\%app%.bat" >nul

:: Копируем код из метки :app_%app% в файл
set "start_line="
set "end_line="
for /f "tokens=1 delims=:" %%a in ('findstr /n /i ":%label%" "%~f0"') do set /a start_line=%%a
for /f "tokens=1 delims=:" %%a in ('findstr /n /i "^goto :EOF" "%~f0"') do if %%a gtr !start_line! if not defined end_line set /a end_line=%%a

if not defined start_line (
    echo [ ERROR ] App code not found.
    pause
    goto store
)

:: Вырезаем строки между start_line и end_line
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

:start
cls
echo ----------------------------------------
echo 1. Explorer (FMX)    4. Regedit (REG)
echo 2. Reboot                 5. Control (DASH)
echo 3. ArsStore              0. Exit Menu
echo ----------------------------------------
echo [ Recent Apps: miner.game, notepad ]
echo ----------------------------------------
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

echo [%date% %time%] RESTORE_APPLIED: %rp_sel% >> "%log_path%"
echo [ DONE ] System restored from %rp_sel%.
echo [ INFO ] Reboot recommended.
pause
goto boot

:bsod
cls & color 17 & echo :(
echo Your PC has encountered a problem and needs to be restarted. We're collecting some error information, and then the restart will occur.
echo.
echo If you call a support person, give them this info:
echo Stop code: KERNEL_NOT_FOUND OR CORRUPTED
pause 
goto repair