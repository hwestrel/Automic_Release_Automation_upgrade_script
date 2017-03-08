@echo off
::-------------------------------------------------------------
:: Automic Release Automation Upgrade Script
:: Henrik Westrell 2017
:: Visit https://github.com/hwestrel/Automic_Release_Automation_upgrade_script 
:: for more information and updates
::-------------------------------------------------------------

::-------------------------------------------------------------
:: Env. specific Variables 
::-------------------------------------------------------------
Set DestFolder=C:\Automic
Set BakFolder=C:\Automic_bak
Set APMBinFolder=%DestFolder%\Tools\Package.Manager\bin

:: Relative tool paths
Set ApacheFolder=\External.Resources\apache-tomcat-7.0.70
Set ARAFolder=\Tools\ARA

:: AE Variables
Set AEClient=100
Set AEUserDep=ARA/ARA
Set AEUser=ARA
Set AEDep=ARA
Set AEPwd=ara


:: MSSQL variables
Set DBUpgradeVersion=12.1
Set MSSQLBakFolder=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup
Set SQLUser=automic
Set SQLPwd=Password1
Set AEdb=AE
Set ARAdb=ARA

:: other Varibles 
::-------------------------------------------------------------
:: Figure out script folder path and Source path
for %%F in ("%~f0") do set ScriptFolder=%%~dpF
Set SourceFolder=%1
set JDBC_DRIVER_JAR=%ScriptFolder%sqljdbc42.jar
set LICENSE_FILE=%ScriptFolder%license.txt
Set Response_template=%ScriptFolder%template.varfile
Set Response_file=%ScriptFolder%install.varfile

::-------------------------------------------------------------
:: Checks
::-------------------------------------------------------------
If "%SourceFolder%" == "" (
	echo SourceFolder not defined. Usage %~f0  [Automic Source unzipped folder]
	exit /B 1	
)  
If NOT EXIST %SourceFolder% (
	echo SourceFolder %SourceFolder% does not exist. Usage %~f0 [Automic Source unzipped folder]
	exit /B 1
)

If NOT EXIST %DestFolder% (
	echo A previous installation at %DestFolder% does not exist. Check script variables
	exit /B 1
)

call net session >nul 2>&1
if %errorLevel% == 0 (
	echo Success: Administrative permissions confirmed.
) else (
	echo Failure: Current permissions inadequate. Run shell as Administrator
	exit /B 1
)

echo.
echo -------------------------------------------------------------
echo - Starting upgrade procedure
echo - SourceFolder = %SourceFolder%
echo - ScriptFolder = %ScriptFolder%
echo -------------------------------------------------------------

echo -------------------------------------------------------------
echo -  Stop services
echo -------------------------------------------------------------
sc stop UC4.ServiceManager.Automic
sc stop W3SVC
pause

echo -------------------------------------------------------------
echo -   Backup Automic folder and databases
echo -------------------------------------------------------------
pause
cd %ScriptFolder%
move /Y %DestFolder% %BakFolder%
If ERRORLEVEL 1 (
	echo Error renaming %DestFolder% to %BakFolder%
	echo Make sure all Automic related processes are killed and try again
	exit /B 1
)
REM if EXIST "%MSSQLBakFolder%\AE.bak" (
	REM echo Rename "%MSSQLBakFolder%\AE.bak"
	REM rename "%MSSQLBakFolder%\AE.bak" AE.bak_old
REM )

REM if EXIST "%MSSQLBakFolder%\ARA.bak" (
	REM echo Rename "%MSSQLBakFolder%\ARA.bak"
	REM rename "%MSSQLBakFolder%\ARA.bak" ARA.bak_old
REM )

set TIMEF=%TIME::=_%
set TIMEF=%TIMEF:,=_%
set TIMEF=%TIMEF: =_%
set timestamp=%DATE%%TIMEF%

echo Create ARA db backup: %ARAdb%_%timestamp% 
call sqlcmd -S localhost -U %SQLUser% -P %SQLPwd% -v dbName=%ARAdb% -v timestamp=%timestamp% -i %ScriptFolder%Backup_db.sql
echo Create AE db backup: %AEdb%_%timestamp% 
call sqlcmd -S localhost -U %SQLUser% -P %SQLPwd% -v dbName=%AEdb%  -v timestamp=%timestamp% -i %ScriptFolder%Backup_db.sql

echo -------------------------------------------------------------
echo -   Rename %ARAdb% and %AEdb% databases
echo -------------------------------------------------------------
pause

call sqlcmd -S localhost -U %SQLUser% -P %SQLPwd% -v dbName=%ARAdb% -i %ScriptFolder%Rename_db.sql
If ERRORLEVEL 1 (
	echo Error renaming database %ARAdb%
	exit /B 1
)
call sqlcmd -S localhost -U %SQLUser% -P %SQLPwd% -v dbName=%AEdb%  -i %ScriptFolder%Rename_db.sql
If ERRORLEVEL 1 (
	echo Error renaming database %AEdb%
	exit /B 1
)

echo -------------------------------------------------------------
echo -  Copy JDBC driver and license file to %DestFolder%
echo -------------------------------------------------------------
pause

mkdir %DestFolder%
copy %JDBC_DRIVER_JAR% %DestFolder%\
copy %LICENSE_FILE% %DestFolder%\

echo -------------------------------------------------------------
echo -  Updating Response file
echo -  Inspect the response file. Close Notepad when done
echo -------------------------------------------------------------
powershell.exe -Command "(GC $Env:Response_template) -replace '-JDBC_DRIVER_JAR-', $Env:JDBC_DRIVER_JAR| Set-Content -path $Env:Response_file"
powershell.exe -Command "(GC $Env:Response_file) -replace '-LICENSE_FILE-', $Env:LICENSE_FILE| Set-Content -path $Env:Response_file"
powershell.exe -Command "(GC $Env:Response_file) -replace '-AEdb-', $Env:AEdb| Set-Content -path $Env:Response_file"
powershell.exe -Command "(GC $Env:Response_file) -replace '-ARAdb-', $Env:ARAdb| Set-Content -path $Env:Response_file"
powershell.exe -Command "(GC $Env:Response_file) -replace '-SQLUser-', $Env:SQLUser| Set-Content -path $Env:Response_file"
powershell.exe -Command "(GC $Env:Response_file) -replace '-SQLPwd-', $Env:SQLPwd| Set-Content -path $Env:Response_file"
powershell.exe -Command "(GC $Env:Response_file) -replace '-AEClient-', $Env:AEClient| Set-Content -path $Env:Response_file"
powershell.exe -Command "(GC $Env:Response_file) -replace '-AEUser-', $Env:AEUser| Set-Content -path $Env:Response_file"
powershell.exe -Command "(GC $Env:Response_file) -replace '-AEPwd-', $Env:AEPwd| Set-Content -path $Env:Response_file"
powershell.exe -Command "(GC $Env:Response_file) -replace '-AEDep-', $Env:AEDep| Set-Content -path $Env:Response_file"

powershell.exe -Command "(GC $Env:Response_file) -replace '\\', '\\'| Set-Content -path $Env:Response_file"
powershell.exe -Command "(GC $Env:Response_file) -replace ':', '\:'| Set-Content -path $Env:Response_file"

call notepad %Response_file%
pause

echo.
echo -------------------------------------------------------------
echo -  Create temp AE and ARA databases
echo -------------------------------------------------------------
pause

call sqlcmd -S localhost -U %SQLUser% -P %SQLPwd%  -v dbName=%AEdb% -i %ScriptFolder%create_db.sql
call sqlcmd -S localhost -U %SQLUser% -P %SQLPwd%  -v dbName=%ARAdb% -i %ScriptFolder%create_db.sql

echo -------------------------------------------------------------
echo -  Install new binaries, using One installer Unattended mode
echo -  Use settings in  %Response_file% 
echo -------------------------------------------------------------
pause
cd %SourceFolder%
call install.exe -varfile %Response_file% -q -dir %DestFolder% -splash Install_ARA -console

echo.
echo -------------------------------------------------------------
echo - One installer done. Check logfile etc
echo - Next, stop Service Manger service and IIS
echo -------------------------------------------------------------
pause

sc stop UC4.ServiceManager.Automic
sc stop W3SVC

echo -------------------------------------------------------------
echo -  Drop temp databases
echo -------------------------------------------------------------
pause
call sqlcmd -S localhost -U %SQLUser% -P %SQLPwd%  -v dbName=%AEdb% -i %ScriptFolder%drop_db.sql
call sqlcmd -S localhost -U %SQLUser% -P %SQLPwd%  -v dbName=%ARAdb% -i %ScriptFolder%drop_db.sql
pause

echo -------------------------------------------------------------
echo -  Restore database names
echo -------------------------------------------------------------
call sqlcmd -S localhost -U %SQLUser% -P %SQLPwd%  -v dbName=%AEdb% -i %ScriptFolder%restore_name_db.sql
call sqlcmd -S localhost -U %SQLUser% -P %SQLPwd%  -v dbName=%ARAdb% -i %ScriptFolder%restore_name_db.sql

echo -------------------------------------------------------------
echo -  Copy and Compare old AE config files
echo -------------------------------------------------------------
pause

Set Utility_bin=\Automation.Platform\Utility\bin
cd %BakFolder%%Utility_bin%
copy ucybdbar.ini 	%DestFolder%%Utility_bin%\ucybdbar.ini_bak
copy ucybdbld.ini	%DestFolder%%Utility_bin%\ucybdbld.ini_bak
copy ucybdbre.ini	%DestFolder%%Utility_bin%\ucybdbre.ini_bak
copy ucybdbrr.ini	%DestFolder%%Utility_bin%\ucybdbrr.ini_bak
copy ucybdbrt.ini	%DestFolder%%Utility_bin%\ucybdbrt.ini_bak
copy ucybdbun.ini	%DestFolder%%Utility_bin%\ucybdbun.ini_bak
copy ucybdbcc.ini	%DestFolder%%Utility_bin%\ucybdbcc.ini_bak
fc 	%DestFolder%%Utility_bin%\ucybdbld.ini	%DestFolder%%Utility_bin%\ucybdbld.ini_bak


Set SM_bin=\Automation.Platform\ServiceManager\bin
cd %BakFolder%%SM_bin%
copy ucybsmgr.ini 	%DestFolder%%SM_bin%\ucybsmgr.ini_bak
copy uc4.smc 		%DestFolder%%SM_bin%\uc4.smc_bak
copy UC4.smd 		%DestFolder%%SM_bin%\UC4.smd_bak
fc	%DestFolder%%SM_bin%\UC4.smd 	%DestFolder%%SM_bin%\UC4.smd_bak

Set SMD_bin=\Automation.Platform\ServiceManagerDialog\bin
cd %BakFolder%%SMD_bin%
copy UCYBSMDi.ini 	%DestFolder%%SMD_bin%\UCYBSMDi.ini_bak

Set SOAP-agent_bin=\Automation.Platform\Agents\rapidautomation\WEBSERVICESOAP01\bin
IF EXIST %BakFolder%%SOAP-agent_bin% (
	cd %BakFolder%%SOAP-agent_bin%
	copy ucxjcitx.ini 	%DestFolder%%SOAP-agent_bin%\ucxjcitx.ini_bak
)

Set REST-agent_bin=\Automation.Platform\Agents\rapidautomation\WEBSERVICEREST01\bin
IF EXIST %BakFolder%%REST-agent_bin% (
	cd %BakFolder%%REST-agent_bin%
	copy ucxjcitx.ini 	%DestFolder%%REST-agent_bin%\ucxjcitx.ini_bak
)

set FTP-agent_bin=\Automation.Platform\Agents\rapidautomation\FTPAGENT01\bin
IF EXIST %BakFolder%%FTP-agent_bin% (
	cd %BakFolder%%FTP-agent_bin%
	copy ucxjcitx.ini 	%DestFolder%%FTP-agent_bin%\ucxjcitx.ini_bak
)
	
Set WIN-agent_bin=\Automation.Platform\Agents\windows\bin
IF EXIST %BakFolder%%WIN-agent_bin% (
	cd %BakFolder%%WIN-agent_bin%
	copy UCXJWX6.ini 	%DestFolder%%WIN-agent_bin%\UCXJWX6.ini_bak
	IF EXIST win02.ini (copy win02.ini 		%DestFolder%%WIN-agent_bin%\win02.ini_bak)
	IF EXIST win03.ini (copy win03.ini 		%DestFolder%%WIN-agent_bin%\win03.ini_bak)
	REM fc 	%DestFolder%%WIN-agent_bin%\UCXJWX6.ini		%DestFolder%%WIN-agent_bin%\UCXJWX6.ini_bak
)

set AE_bin=\Automation.Platform\AutomationEngine\bin
cd %BakFolder%%AE_bin%
copy ucsrv.ini 	%DestFolder%%AE_bin%\ucsrv.ini_bak
rem fc 	%DestFolder%%AE_bin%\ucsrv.ini 		%DestFolder%%AE_bin%\ucsrv.ini_bak

echo -------------------------------------------------------------
echo -  Copy AWI config files
echo -------------------------------------------------------------
pause

cd %BakFolder%%ApacheFolder%\webapps\awi\config
copy uc4config.xml 				%DestFolder%%ApacheFolder%\webapps\awi\config\uc4config.xml_bak
copy configuration.properties	%DestFolder%%ApacheFolder%\webapps\awi\config\configuration.properties_bak
fc %DestFolder%%ApacheFolder%\webapps\awi\config\uc4config.xml %DestFolder%%ApacheFolder%\webapps\awi\config\uc4config.xml_bak

cd %BakFolder%%ApacheFolder%\webapps\awi\config\webui-plugin-bond
copy connection.properties 		%DestFolder%%ApacheFolder%\webapps\awi\config\webui-plugin-bond\connection.properties_bak

cd %BakFolder%%ApacheFolder%\webapps\awi\config\\webui-plugin-actionbuilder
copy actionbuilder.properties 	%DestFolder%%ApacheFolder%\webapps\awi\config\webui-plugin-actionbuilder\actionbuilder.properties_bak

cd %BakFolder%%ApacheFolder%\webapps\awi\config\\webui-plugin-pluginmanager
copy pluginmanager.properties	%DestFolder%%ApacheFolder%\webapps\awi\config\webui-plugin-pluginmanager\pluginmanager.properties_bak

echo -------------------------------------------------------------
echo -  Copy ARA config files
echo -------------------------------------------------------------
pause

cd %BakFolder%%ARAFolder%\WebUI
copy customer.config 			%DestFolder%%ARAFolder%\WebUI\customer.config_bak
copy web.config 				%DestFolder%%ARAFolder%\WebUI\web.config_bak
fc %DestFolder%%ARAFolder%\WebUI\customer.config %DestFolder%%ARAFolder%\WebUI\customer.config_bak
fc %DestFolder%%ARAFolder%\WebUI\web.config 	%DestFolder%%ARAFolder%\WebUI\web.config_bak

cd %BakFolder%%ARAFolder%\WebUI\config
copy integration.config 			%DestFolder%%ARAFolder%\WebUI\integration.config_bak

cd %BakFolder%%ARAFolder%\Utilities\DataMigrator
copy DataMigrator.exe.config 	%DestFolder%%ARAFolder%\Utilities\DataMigrator\DataMigrator.exe.config_bak
fc %DestFolder%%ARAFolder%\Utilities\DataMigrator\DataMigrator.exe.config 	%DestFolder%%ARAFolder%\Utilities\DataMigrator\DataMigrator.exe.config_bak

cd %BakFolder%%ARAFolder%\Utilities\DBCleanup
copy  DB-Cleanup.exe.config 	%DestFolder%%ARAFolder%\Utilities\DBCleanup\DB-Cleanup.exe.config_bak

echo.
echo -------------------------------------------------------------
echo - config files OK ? Press any key to continue dbload (upgrade db)
echo -------------------------------------------------------------
pause 

echo -------------------------------------------------------------
echo -  Run DBLOAD 
echo -------------------------------------------------------------
cd %DestFolder%%Utility_bin%
call ucybdbld -B -EREPLACE -X..\db\general\%DBUpgradeVersion%\UC_UPD.TXT

echo -------------------------------------------------------------
echo -  Update ARA Database 
echo -------------------------------------------------------------
pause
cd %DestFolder%%ARAFolder%\Utilities\DataMigrator
:: start notepad %DestFolder%%ARAFolder%\WebUI\customer.config
call DataMigrator.exe -con "Data Source=tcp:localhost,1433;Initial Catalog=%ARAdb%;User ID=%SQLUser%;Password=%SQLPwd%"


echo -------------------------------------------------------------
echo -  Start services 
echo -------------------------------------------------------------
sc start UC4.ServiceManager.Automic
sc start W3SVC

echo -------------------------------------------------------------
echo -   Update Action Packs....
echo -------------------------------------------------------------
pause
:: C:\Automic\Tools\Package.Manager\conf\login_dat.xml
:: login_dat.xml, pmconfig.xml, uc4config.xml
cd %APMBinFolder%
call apm update -y
call apm upgrade -y -c %AEClient% -u %AEUserDep% -pw %AEPwd%

cd %ScriptFolder%

echo.
echo -------------------------------------------------------------
echo - Done 
echo - Clear your browser cache 
echo -------------------------------------------------------------
exit /B 0






