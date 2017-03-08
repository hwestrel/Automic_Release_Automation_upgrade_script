# Automic Release Automation - Upgrade Script

The main purpose for this script is to automate the upgrade procedure for ARA sandbox installations.
Not suitable for Production use. Only for sandbox/non-prod installations.
Use-as-is. Not Supported by Automic. 

The script does following:
- Backup existing Automic folder and AE and ARA MSSQL databases
- Rename existing AE and ARA MSSQL databases
- Creates temp AE and ARA databases
- Install new AE, ARA, Analytics and Agent binaries, One installer Unattended mode (1)
- Copies old config file and compares with the new. (No auto merge!)
- Drops temp databases
- Restore AE and ARA database names
- Run DBLOAD, upgrade AE database
- Run ARA DataMigrator, upgrade ARA database
- Update existing Action Packs, if needed

PreReq:
- a "working" Automic ARA installation and AE/ARA databases exist on one single Windows machine
- a valid license file
- a MSSQL server on "localhost"
- a common db_owner sql user for both AE and ARA databases
- make sure the sql user has a non-automic db as default db (ex "master")
- make sure the sql user has enough privileges to rename, drop, set single user mode etc. (i.e ServerRole=sysadmin)
- Powershell enabled


ToDo:
- Download the solution and unzip on the ARA sandbox server 
- Replace license.txt with a valid Automic license
- Upgrade_ARA.cmd: Update ALL the environment specific variables
- Download new ARA binaries (from downloads.automic.com) and unzip 

Usage:
- Start a windows shell as Adminstrator and run the upgrade script
c:\Upgrade_Automic\Upgrade_ARA.cmd  [Automic Source unzipped folder]

Example
- Upgrade_ARA.cmd c:\temp\Automic.Release.Automation_12.1.0_2017-03-07

Known Issues
- The Analytics datastore is replaced. The One Installer creates a new datastore.

Note (1) The One Installer installs following components:
- Automation Engine (5xWP/2xCP/1xJWP)
- ServiceManager 
- ServiceManager dialog
- Tomcat
- Automic Web Interface, ARA Plugin for AWI
- ARA
- Analytics (backend and Postgresql)
- Utilities
- Oracle Java
- Package Manager
- Windows Agent
- RA Web Service REST, RA Web Service SOAP, FTP Agents



