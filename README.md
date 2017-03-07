# Automic_ARA_installer

Automic Release Automation - Upgrade Script

The main purpose for this script is to automate the upgrade procedure for ARA sandbox installations.
Not suitable for Production use. Only for sandbox/non-prod installations.
Use-as-is. Not Supported by Automic. 

The script does following:
- Backup existing Automic folder and AE and ARA MSSQL databases
- Rename existing AE and ARA MSSQL databases
- Creates temp AE and ARA databases
- Install new AE, ARA, Analytics and Agent binaries, using One installer Unattended mode
- Drops temp databases
- Run DBLOAD, upgrade AE database
- Run ARA DataMigrator, upgrade ARA database
- Update existing Action Packs, if needed

PreReq:
- an "working" Automic ARA installation and AE/ARA databases exist on one Windows machine
- a valid license file
- a MSSQL server on "localhost"
- one common dbowner user for both AE and ARA databases 

ToDo:
- Download the solution and unzip on the ARA sandbox server 
- Replace license.txt with a valid Automic license
- Upgrade_ARA.cmd: Update the environment specific variables
- Download new ARA binaries (from downloads.automic.com) and unzip 

Usage:
Start a windows shell as Adminstrator and run the upgrade script
c:\Upgrade_Automic\Upgrade_ARA.cmd  [Automic Source unzipped folder]

Example
Upgrade_ARA.cmd c:\temp\Automic.Release.Automation_12.1.0_2017-03-07




