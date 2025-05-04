@echo off

:: BatchGotAdmin
:CheckAdmin
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges to update your firewall...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    goto %EOF%

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------
@echo off
TITLE GameSpamFilter by HL2DM.ORG - Henky updated by Exomatic!!
cd %~dp0
setlocal enabledelayedexpansion

if "%1"=="list" (
  SET /A RULECOUNT=0
  for /f %%i in ('netsh advfirewall firewall show rule name^=all ^| findstr GameSpamFilter') do (
    SET /A RULECOUNT+=1
    netsh advfirewall firewall show rule GameSpamFilter!RULECOUNT! | findstr RemoteIP
  )
  SET "RULECOUNT="
  echo -----------------------------------------------
  echo You have now been updated with the current IP's and should have less spam once you refresh the server list.
  echo Did i miss one? Please paste the IP on my steam profile, http://steamcommunity.com/id/Exomatic
  color 0a
  pause
  exit/b
)

REM Download new IP's
echo Downloading the current IP list
powershell -Command "curl -o spamip.txt https://raw.githubusercontent.com/Exomatic/steamserverspamfilter/refs/heads/main/spamip.txt"
IF NOT EXIST %~DP0\spamip.txt GOTO :DLFAILED

echo Updating Firewall
REM Deleting existing block on ips
SET /A RULECOUNT=0
for /f %%i in ('netsh advfirewall firewall show rule name^=all ^| findstr GameSpamFilter') do (
  SET /A RULECOUNT+=1
  netsh advfirewall firewall delete rule name="GameSpamFilter!RULECOUNT!"
)
SET "RULECOUNT="

REM Block new ips (while reading them from GameSpamFilter.txt)
SET /A IPCOUNT=0
SET /A BLOCKCOUNT=1
for /f %%i in (spamip.txt) do (
  SET /A IPCOUNT+=1
  if !IPCOUNT! == 201 (
    netsh advfirewall firewall add rule name="GameSpamFilter!BLOCKCOUNT!" protocol=any dir=in action=block remoteip=!IPADDR!
    netsh advfirewall firewall add rule name="GameSpamFilter!BLOCKCOUNT!" protocol=any dir=out action=block remoteip=!IPADDR!
    SET /A BLOCKCOUNT+=1
    SET /A IPCOUNT=1
    set IPADDR=%%i
  ) else (
    if not "!IPADDR!" == "" (  
      set IPADDR=!IPADDR!,%%i
    ) else (
      set IPADDR=%%i
    )
  )
)

REM add the final block of IPs of length less than 201
netsh advfirewall firewall add rule name="GameSpamFilter!BLOCKCOUNT!" protocol=any dir=in action=block remoteip=!IPADDR!
netsh advfirewall firewall add rule name="GameSpamFilter!BLOCKCOUNT!" protocol=any dir=out action=block remoteip=!IPADDR!

SET "IPCOUNT="
SET "BLOCKCOUNT="
SET "IPADDR="

REM call this batch again with list to show the blocked IPs
call %0 list
exit

:DLFAILED
color 0c
echo.
echo We were unable to download spamip.txt, you can try to manually download it from https://raw.githubusercontent.com/Exomatic/steamserverspamfilter/refs/heads/main/spamip.txt
pause
exit