@echo off
setlocal enabledelayedexpansion
title ARSLANIUS 18 SP1

:: ========================================
:: ПОЛНЫЕ ПУТИ (БЕЗ СОКРАЩЕНИЙ)
:: ========================================
set "root_path=%~dp0"
:: Убираем лишний слэш в конце, если он есть
if "%root_path:~-1%"=="\" set "root_path=%root_path:~0,-1%"

set "kernel_path=%root_path%\Setting And System Files\kernel.dll"
set "users_root=%root_path%\Users"
set "programs_root=%root_path%\Programs"
set "sys_prof=%root_path%\Setting And System Files\systemprofile"
set "sys_services=%root_path%\Setting And System Files\systemprofile"
set "reg_path=%root_path%\Setting And System Files\REG.cfg"
set "log_path=%root_path%\Setting And System Files\system.log"
set "restore_root=%root_path%\RestorePoints"
set "current_build=48.2"

:boot
set "safe_mode=0"
echo [%date% %time%] LOADER_COMPLETE >> "%log_path%" 2>nul
color 0f
cls
echo ========================================
echo        ARSLANIUS 18 BOOT MENU
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
echo [  WAIT  ] BarOS Kernel 15.4 (ARSLANIUS 18) starting...
timeout /t 1 >nul

:: --- КРИТИЧЕСКАЯ ЗАЩИТА ЯДРА ---
if exist "%kernel_path%" goto kernel_ok
color 4f
echo =====================================================
echo [ FATAL ERROR ] KERNEL_NOT_FOUND
echo.
echo System core file is missing or corrupted.
echo Press [R] to Repair System or any other key to Exit.
echo =====================================================
set /p "choice=> "
if /i "!choice!"=="R" goto repair
exit

:repair
if not exist "%root_path%\Setting And System Files" md "%root_path%\Setting And System Files"
if not exist "%sys_services%" md "%sys_services%" 2>nul
echo SYSTEM = Acy98iolop_isArslanius-kop > "%kernel_path%"
echo SYSTEM ADMINISTRATOR = Jiupolaqmn_isArslanius-lo >> "%kernel_path%"
echo OS_NAME = ARSLANIUS 18 > "%reg_path%"
echo SYSTEM_COLOR=0e >> "%reg_path%"
echo ADMIN_COLOR=4f >> "%reg_path%"
echo USER_COLOR=1f >> "%reg_path%"
echo [%date% %time%] KERNEL_RESTORED >> "%log_path%" 2>nul
goto boot

:kernel_ok
set "sys_pass="
for /f "tokens=2 delims==" %%a in ('findstr /i /c:"SYSTEM =" "%kernel_path%" 2^>nul') do set "sys_pass=%%a"
if "%sys_pass%"=="" color 4f & echo [ FATAL ] KERNEL_DATA_CORRUPT & pause & goto repair

:: ЗАГРУЗКА РЕЕСТРА (OS NAME И ЦВЕТА)
if not exist "%reg_path%" goto repair
for /f "tokens=2 delims==" %%n in ('findstr /i "OS_NAME" "%reg_path%"') do set "os_name=%%n"
for /f "tokens=2 delims==" %%c in ('findstr /i "SYSTEM_COLOR" "%reg_path%"') do color %%c

set "current_user=SYSTEM"
set "user_home=%sys_prof%"
if not exist "%user_home%" md "%user_home%" 2>nul
cd /d "%user_home%" 2>nul

:logon_screen
set "current_user=SYSTEM"
set "user_home=%sys_prof%"
cd /d "%user_home%" 2>nul
echo [%date% %time%] BOOT_V18_INIT_%current_user% >> "%log_path%" 2>nul
cls
color 5b
echo ========================================
echo        %os_name% LOCK SCREEN
echo ========================================
echo Status: Protected / Context: %current_user%
echo ----------------------------------------
echo.
set "u_in=" & set "p_in="
set /p "u_in=Username: "
set /p "p_in=Password: "

if "%u_in%"=="" goto logon_screen
set "c_p="
for /f "tokens=2 delims==" %%a in ('findstr /i /c:"%u_in% =" "%kernel_path%" 2^>nul') do set "c_p=%%a"
if not defined c_p echo [ ERROR ] User not found. & pause & goto logon_screen
set "c_p=%c_p: =%"
if NOT "%p_in%"=="%c_p%" echo [ ERROR ] Password incorrect. & pause & goto logon_screen

set "current_user=%u_in%"
if /i "%current_user%"=="SYSTEM" (set "user_home=%sys_prof%") else (set "user_home=%users_root%\%current_user%")
if not exist "%user_home%" md "%user_home%" 2>nul

if /i "%current_user%"=="SYSTEM" set "reg_key=SYSTEM_COLOR" & goto apply_color
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" set "reg_key=ADMIN_COLOR" & goto apply_color
set "reg_key=USER_COLOR"

:apply_color
for /f "tokens=2 delims==" %%c in ('findstr /i "%reg_key%" "%reg_path%"') do color %%c
cd /d "%user_home%" 2>nul

:interface
:: --- АВТОЗАПУСК СЛУЖБ (ОТКЛЮЧЕНО В SAFE MODE) ---
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
:: --- ПРОВЕРКА КРИТИЧЕСКИХ АЛЕРТОВ ---
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

:: ШАПКА ИНТЕРФЕЙСА
if "%safe_mode%"=="1" color 07
echo %os_name% [Build %current_build%] - Session: %current_user% ^(MODE: %safe_mode%^)
echo Profile: %cd%
echo ----------------------------------------

:: ПРОВЕРКА ПОЧТЫ И AUTORUN (ОТКЛЮЧЕНО В SAFE MODE)
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
:: ЕСЛИ SAFE MODE - ПРОПУСКАЕМ СЛУЖБЫ
if "%safe_mode%"=="1" goto skip_all_services

:: --- РАБОТА СЛУЖБЫ SFC (АВТО-ПРОВЕРКА) ---
if exist "%sys_services%\SFC_Daemon.active" (
    set "sfc_err=0"
    if NOT exist "%kernel_path%" set "sfc_err=1"
    if NOT exist "%reg_path%" set "sfc_err=1"
    
    if "!sfc_err!"=="1" (
        echo [ SFC_DAEMON ] Integrity violation detected!
        echo [ SFC_DAEMON ] Executing background repair...
        if NOT exist "%kernel_path%" (
            echo SYSTEM = Acy98iolop_isArslanius-kop > "%kernel_path%"
            echo SYSTEM ADMINISTRATOR = Jiupolaqmn_isArslanius-lo >> "%kernel_path%"
        )
        echo OS_NAME = %os_name% > "%reg_path%"
        echo SYSTEM_COLOR=0e >> "%reg_path%"
        echo ADMIN_COLOR=4f >> "%reg_path%"
        echo USER_COLOR=1f >> "%reg_path%"
        echo [%date% %time%] SFC_DAEMON: AUTO_REPAIR_SUCCESS >> "%log_path%"
        echo [ SFC_DAEMON ] System restored.
    )
)

:: --- РАБОТА СЛУЖБЫ SYSPULSE ---
if exist "%sys_services%\SysPulse.active" (
    if exist "NewFolder" rd /s /q "NewFolder" 2>nul
    
    set /a "pulse_check=!random! %% 10"
    if "!pulse_check!"=="5" echo [%date% %time%] SYSPULSE: System Health OK >> "%log_path%"
)

:skip_all_services
cd /d "%user_home%" 2>nul
set "cmd="
set /p cmd="%current_user%@ARSLANIUS> "
if "%cmd%"=="" goto cmd_loop

set "f_w=" & set "t_c="
for /f "tokens=1,2" %%a in ("%cmd%") do (set "f_w=%%a" & set "t_c=%%b")

:: --- SUDO (ПОЛНАЯ ЛОГИКА) ---
if /i NOT "%f_w%"=="sudo" goto check_r
if "%t_c%"=="" echo Usage: sudo [command] & goto cmd_loop
if /i "%current_user%"=="SYSTEM" set "ex_c=%t_c%" & goto core
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" set "ex_c=%t_c%" & goto core
set /p "a_p=Enter ADMIN password: "
set "c_a="
for /f "tokens=2 delims==" %%s in ('findstr /i /c:"SYSTEM ADMINISTRATOR =" "%kernel_path%" 2^>nul') do set "c_a=%%s"
set "c_a=!c_a: =!"
if "!a_p!"=="!c_a!" (
    echo [%date% %time%] SUDO_EXEC: !t_c! BY %current_user% >> "%log_path%" 2>nul
    set "ex_c=%t_c%" & goto core
)
echo [ ERROR ] Access denied. & goto cmd_loop

:check_r
set "ex_c=%cmd%"
set "isA=0"
for %%a in (MiniDOS Bsod run events CreatedFolder adduser deluser clean msg-all regedit guest fmx sfc dash alert install) do (if /i "%ex_c%"=="%%a" set "isA=1")
if "%isA%"=="0" goto core
if /i "%current_user%"=="SYSTEM" goto core
if /i "%current_user%"=="SYSTEM ADMINISTRATOR" goto core
echo Error: Access Denied. Use "sudo %ex_c%". & goto cmd_loop

:core
:core_auto
if /i "%current_user%"=="GUEST" (
    set "ok=0"
    for %%a in (Help logout report cls ver dir whoami Calc Notepad miner.game) do (if /i "%ex_c%"=="%%a" set "ok=1")
    if "!ok!"=="0" echo [ SECURITY ] Guest cannot use this command. & goto cmd_loop
)
if /i NOT "%current_user%"=="SYSTEM" goto exec
set "ok=0"
for %%a in (Help logout lock report run cls ver taskmgr fmx Shutdown Reboot dir adduser whoami sfc clean mail-read mail-send edit guest msg-all regedit install deluser alert restore-point restore) do (if /i "%ex_c%"=="%%a" set "ok=1")
if "%ok%"=="0" echo [ SECURITY ] Restricted context. & goto cmd_loop

:exec
:: --- НОВЫЕ КОМАНДЫ V18 ---
if /i "%ex_c%"=="ArsStore" goto store
if /i "%ex_c%"=="run" goto script_launcher
if /i "%ex_c%"=="as-2-bat" goto as_compiler 
if /i "%ex_c%"=="restore-point" goto restore_point
if /i "%ex_c%"=="restore" goto restore
if /i "%ex_c%"=="as-pack" goto as_packer
if /i "%ex_c%"=="as-unpack" goto as_unpacker
if /i "%ex_c%"=="report" goto sys_report

:: --- СТАНДАРТНЫЕ КОМАНДЫ ---
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
if /i "%ex_c%"=="Bsod" goto bsod
if /i "%ex_c%"=="reboot" goto boot
if /i "%ex_c%"=="Shutdown" del /f /q "%sys_services%\SysPulse.active" & del /f /q "%sys_services%\SFC_Daemon.active" & exit

echo "%ex_c%" is not recognized.
goto cmd_loop

:: --- БЛОКИ ЛОГИКИ (ПОЛНЫЕ ВЕРСИИ) ---

:msg_all
set /p "m_txt=Global Message: "
for /d %%d in ("%users_root%\*") do (echo [GLOBAL] From %current_user%: %m_txt% >> "%%d\mail.txt")
echo [GLOBAL] From %current_user%: %m_txt% >> "%sys_prof%\mail.txt"
echo [ OK ] Broadcast sent.
goto cmd_loop

:dash
cls
echo ========================================
echo        ARSLANIUS 18 CONTROL CENTER
echo ========================================
:: Считаем юзеров в ядре
set "u_count=0"
for /f %%a in ('find /c "=" ^< "%kernel_path%"') do set "u_count=%%a"

echo [ STATS ] Registered Users: %u_count%
echo [ STATS ] OS Name: %os_name%
echo [ STATS ] Kernel: BarOS 15.4 (V18)

echo.
echo [ SERVICES ]
if exist "%sys_services%\SysPulse.active" (echo  - SysPulse: ONLINE) else (echo  - SysPulse: OFFLINE)
if exist "%sys_services%\SFC_Daemon.active" (echo  - SFC_Daemon: ONLINE) else (echo  - SFC_Daemon: OFFLINE)

echo.
echo [ STORAGE ]
for %%i in ("%log_path%") do echo  - Log File Size: %%~zi bytes
echo ========================================
pause
goto cmd_loop

:sys_report
echo [ WAIT ] Generating HTML Report...
set "report_f=%user_home%\Report_v18.html"
echo ^<html^>^<body style='background:#111;color:#0f0;font-family:monospace'^> > "%report_f%"
echo ^<h1^>ARSLANIUS 18 SP1 - SYSTEM REPORT^</h1^> >> "%report_f%"
echo ^<hr^>^<p^>Build: %current_build%^</p^> >> "%report_f%"
echo ^<p^>Kernel: 15.4^</p^> >> "%report_f%"
echo ^<p^>Active User: %current_user%^</p^> >> "%report_f%"
echo ^<p^>Log Size: %log_path%^</p^> >> "%report_f%"
echo ^<h2^>Registered Users:^</h2^>^<pre^> >> "%report_f%"
type "%kernel_path%" >> "%report_f%"
echo ^</pre^>^</body^>^</html^> >> "%report_f%"
echo [ OK ] Report generated: %report_f%
start "" "%report_f%"
pause & goto cmd_loop

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
:: Ищем только ошибки и важные действия в логе
findstr /i "ALERT ERROR CRITICAL DELETED SUDO" "%log_path%" 2>nul
if !errorlevel! NEQ 0 echo [ INFO ] No critical events found.
echo ----------------------------------------
pause
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

:: Сначала проверяем, не пустые ли поля
if "%nu%"=="" echo [ ERROR ] Name cannot be empty. & goto cmd_loop
if "%np%"=="" echo [ ERROR ] Password cannot be empty. & goto cmd_loop

:: ПРОВЕРКА: Не существует ли уже такой юзер?
findstr /i /c:"%nu% =" "%kernel_path%" >nul
if !errorlevel! EQU 0 echo [ ERROR ] User already exists. & goto cmd_loop

:: ЗАПИСЬ: Сначала перенос строки, потом данные
(echo.) >> "%kernel_path%"
echo %nu% = %np% >> "%kernel_path%"

:: Создаем папку профиля
md "%users_root%\%nu%" 2>nul

echo [%date% %time%] NEW_USER_CREATED: %nu% >> "%log_path%" 2>nul
echo [ OK ] User %nu% created. Profil folder generated.
echo.
goto cmd_loop

:alert_all
echo.
echo -- DEPLOY CRITICAL SYSTEM ALERT --
set /p "al_txt=Alert message: "

:: Рассылаем файл alert.sys всем пользователям
for /d %%d in ("%users_root%\*") do (echo %al_txt% > "%%d\alert.sys")
:: Отправляем самому себе (в систему)
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

:: ЦИКЛ СКЛЕЙКИ
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
:: Выводим файлы с нумерацией
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

:: Проверка Ядра
echo [ WAIT ] Checking: kernel.dll...
if NOT exist "%kernel_path%" (set "errors=1" & echo [ FAIL ] kernel.dll MISSING) else (
    for %%i in ("%kernel_path%") do if %%~zi LSS 10 (set "errors=1" & echo [ FAIL ] kernel.dll CORRUPTED) else (echo [  OK  ] kernel.dll)
)

:: Проверка Реестра
echo [ WAIT ] Checking: REG.cfg...
if NOT exist "%reg_path%" (set "errors=1" & echo [ FAIL ] REG.cfg MISSING) else (echo [  OK  ] REG.cfg)

:: Проверка Лога
echo [ WAIT ] Checking: system.log...
if NOT exist "%log_path%" (set "errors=1" & echo [ FAIL ] system.log MISSING) else (echo [  OK  ] system.log)

:: ИТОГ СКАНЕРА
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
:: Копируем логику из :repair, но БЕЗ "goto boot" в конце
if not exist "%root_path%\Setting And System Files" md "%root_path%\Setting And System Files" 2>nul
if NOT exist "%kernel_path%" (
    echo SYSTEM = Acy98iolop_isArslanius-kop > "%kernel_path%"
    echo SYSTEM ADMINISTRATOR = Jiupolaqmn_isArslanius-lo >> "%kernel_path%"
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
    :: Проверяем маркеры через поиск в строке
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
echo System: Help, Logout, Lock, sudo, cls, as-2-bat, Shutdown, ver, fmx, whoami, reboot, clean, service, events, restore-point, restore
echo Admin: CreatedFolder, MiniDOS, BSoD, adduser, deluser, alert, Guest, report 
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
echo [ CORE ] BarOS 15.4 (CPU: !cpu!%%)
goto cmd_loop

:clean
for /d %%i in (NewFolder*) do rd /s /q "%%i"
echo [ OK ] Cleaned.
goto cmd_loop

:store
cls
echo ========================================
echo        ARSLANIUS STORE [v1.0]
echo ========================================
echo Available Apps:
echo [ 1 ] System_Scanner (Utility)
echo [ 2 ] Snake_Game (Game)
echo [ 3 ] Note_Pad_Lite (Office)
echo [ 0 ] Exit Store
echo ----------------------------------------
set /p "s_choice=Enter App ID to Install: "

if "%s_choice%"=="0" goto cmd_loop
if "%s_choice%"=="1" (set "a_n=Scanner" & set "a_code=echo Scanning... & pause")
if "%s_choice%"=="2" (set "a_n=Snake" & set "a_code=echo Snake Game Start! & pause")
if "%s_choice%"=="3" (set "a_n=NoteLite" & set "a_code=echo Write your notes here... & pause")

:: Процесс "установки"
echo [ WAIT ] Downloading %a_n%...
timeout /t 2 >nul
echo @echo off > "%programs_root%\%a_n%.bat"
echo %a_code% >> "%programs_root%\%a_n%.bat"
echo [ OK ] %a_n% installed to your profile.
pause
goto store

:edit
set /p "ef=File: " & set /p "et=Text: "
echo %et% >> "%ef%" & goto cmd_loop

:guest_toggle
set /p "g_act=Enable Guest Mode? (Y/N): "
if /i "%g_act%"=="Y" (
    echo GUEST = GUEST >> "%kernel_path%"
    md "%users_root%\GUEST" 2>nul
    echo [ OK ] Guest mode ACTIVE. Login: GUEST / Pass: GUEST
) else (
    type "%kernel_path%" | findstr /v /i /c:"GUEST =" > "%kernel_path%.tmp"
    move /y "%kernel_path%.tmp" "%kernel_path%" >nul
    rd /s /q "%users_root%\GUEST" 2>nul
    echo [ OK ] Guest mode DISABLED. Profile wiped.
)
pause & goto cmd_loop

:start
cls
echo ----------------------------------------
echo 1. Explorer (FMX)    4. Settings (REG)
echo 2. PowerShell (AS)   5. Control (DASH)
echo 3. ArsStore         0. Exit Menu
echo ----------------------------------------
echo [ Recent Apps: miner.game, notepad ]
echo ----------------------------------------
set /p "win_c=Search or Select: "

if "%win_c%"=="1" goto fmx
if "%win_c%"=="2" goto script_launcher
if "%win_c%"=="3" goto store
if "%win_c%"=="4" goto conf_edit
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

:script_launcher
set /p "s_file=Run Script (.as): "
if NOT exist "%s_file%" echo [ ERROR ] No script file found. & pause & goto cmd_loop

echo [ BOOTING ARSLAN-SCRIPT INTERPRETER ]
echo ----------------------------------------

for /f "usebackq tokens=1,2*" %%a in ("%s_file%") do (
    set "cmd_as=%%a" & set "p1=%%b" & set "p2=%%c"

    if /i "!cmd_as!"=="PRINT" echo !p1! !p2!
    if /i "!cmd_as!"=="WAIT"  timeout /t !p1! >nul
    if /i "!cmd_as!"=="COLOR" color !p1!
    if /i "!cmd_as!"=="BEEP"  echo ^G
    if /i "!cmd_as!"=="LOG"   echo [%date% %time%] AS_LOG: !p1! !p2! >> "%log_path%"
    if /i "!cmd_as!"=="EXIT"  goto script_end
    if /i "!cmd_as!"=="OPEN"  start !p1!
)

:script_end
echo ----------------------------------------
echo [ AS ] Execution finished.
pause & goto cmd_loop

:as_compiler
echo.
echo [ ARSLAN-SCRIPT COMPILER v1.5 ]
set /p "as_src=Source file (.as): "
if NOT exist "%as_src%" echo [ ERROR ] Source not found. & pause & goto cmd_loop
set /p "as_dest=Output name (ex: MyApp): "

echo [ WAIT ] Compiling %as_src%...
echo @echo off > "%as_dest%.bat"
echo :: Compiled by ARSLANIUS 18 Compiler >> "%as_dest%.bat"

:: ЧИТАЕМ ФАЙЛ ПОСТРОЧНО
for /f "usebackq tokens=1,2*" %%a in ("%as_src%") do (
    set "c_cmd=%%a"
    set "c_p1=%%b"
    set "c_p2=%%c"
    
    :: ГЛАВНЫЙ ТРАНСЛЯТОР
    if /i "!c_cmd!"=="PRINT" echo echo !c_p1! !c_p2! >> "%as_dest%.bat"
    if /i "!c_cmd!"=="OPEN" echo start !c_p1! >> "%as_dest%.bat"
    if /i "!c_cmd!"=="WAIT"  echo timeout /t !c_p1! ^>nul >> "%as_dest%.bat"
    if /i "!c_cmd!"=="COLOR" echo color !c_p1! >> "%as_dest%.bat"
    if /i "!c_cmd!"=="BEEP"  echo echo ^G >> "%as_dest%.bat"
    if /i "!c_cmd!"=="EXIT"  echo exit /b >> "%as_dest%.bat"
    if /i "!c_cmd!"=="LOG"   echo echo [!date! !time!] !c_p1! !c_p2! ^>^> system.log >> "%as_dest%.bat"
)

echo [ OK ] Compilation successful!
echo [ INFO ] Check %as_dest%.bat now.
pause
goto cmd_loop

:bsod
cls & color 17 & echo :( SYSTEM_HALTED & pause & color 5b & goto boot