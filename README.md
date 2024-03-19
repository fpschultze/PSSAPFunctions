# PsSapFunctions

The PsSapFunctions PowerShell module originates from the phase of my first experiences in the automation of SAP basis tasks such as starting and stopping SAP systems, instances etc.

The module was intended for use in an automation framework to realize SAP-related tasks within complex processes such as OS patching of an SAP landscape.

But, PsSapFunctions is also suitable for daily work on the PowerShell console. However, most SAP admins are used to sapcontrol and saphostcontrol commands and will certainly not be enthusiastic about this module, especially since SAP systems are usually based on Linux.

PsSapFunctions consists mainly of wrapper functions for sapcontrol.exe and saphostcontrol.exe calls. The functions (or CmdLets) evaluate the return values and inspect text outputs, e.g. to return rich objects for simple further processing of the results. This is the real added value of this module.

After the first experience with this module, I preferred to access directly the SOAP APIs of SapControl/SapHostControl and wrote corresponding PowerShell modules for it. Therefore I did not develop the PsSapFunctions module further and provide it "as is" for study and own experiments.

the module exposes the following script CmdLets:

Get-PsSapDatabases

- Gets status information of SAP instances, databases, and components
- Wrapper for "saphostctrl.exe -function ListDatabases"

Get-PsSapDBType

- (unfinished) Returns the SAP database type (ADA, MSS, ORA, or SYB)

Get-PsSapInstanceProperty

- Provides some meta information about a given instance, which allows a client to display only information relevant for the actual instance type and version.
- Wrapper for "sapcontrol.exe -nr INSTANCE_NUMBER -function GetInstanceProperties"

Get-PsSapInstances

- Gets status information of SAP instances
- Wrapper for "saphostctrl.exe -function ListInstances [-running (list running instances only) | -stopped (list stopped instances only)]"

Get-PsSapMSSQLServices

- Returns the MSSQL named instance or default instance service names

Get-PsSapProcessList

- Gets status information of SAP processes
- Wrapper for "sapcontrol.exe -host HOST_NAME -nr INSTANCE_NUMBER -function GetProcessList"

Get-PsSapStartServices

- Returns the SAP start service names

Get-PsSapSybaseServices

- Returns the Sybase service names

Get-PsSapSystemInstanceList

- Provides a list of all instances of the system with its assigned priority level.
- Wrapper for "sapcontrol.exe -nr INSTANCE_NUMBER -function GetSystemInstanceList"

Repair-PsSapStartService

- Ensures the desired SAP start services status (Running) and start type (Automatic).

Restart-PsSapHostAgent

- Restarts SAP services
- Wrapper for "saphostexec.exe -restart"

Start-PsSapMaxDB

- Starts MaxDB, this is: first "dbmcli -U c -d SID db_online" and afterwards the XServer service

Start-PsSapMSSQL

- Starts MSSQL, this is: first the SQLAgent$SID service and afterwards the MSSQL$SID service

Start-PsSapOracle

- Starts Oracle, that is: first start the listener and afterwards the database

Start-PsSapSybase

- Starts Sybase, that is: first the SYBSQL_UPPERSID service and afterwards SYBBCK_UPPERSID_BS

Start-PsSapSystem

- Starts a SAP system
- Wrapper for "sapcontrol.exe -host HOST_NAME -nr INSTANCE_NUMBER -function StartSystem ALL"

Stop-PsSapHostAgent

- Stops SAP services
- Wrapper for "saphostexec.exe -stop"

Stop-PsSapMaxDB

- Stops MaxDB services, that is: first "dbmcli -U c -d SID db_offline" and afterwards the XServer service

Stop-PsSapMSSQL

- Stops MSSQL services, that is: first the MSSQL$SID or MSSQLSERVER service and afterwards the SQLAgent$SID or SQLSERVERAGENT service

Stop-PsSapOracle

- Stops Oracle services, that is: first the database and afterwards the listener

Stop-PsSapStartService

- Stops the SAP start services

Stop-PsSapSybase

- Stops Sybase services, that is: first the SYBSQL_UPPERSID service and afterwards SYBBCK_UPPERSID_BS

Stop-PsSapSystem

- Stops a SAP system
- Wrapper for "sapcontrol.exe -host HOST_NAME -nr INSTANCE_NUMBER -function StopSystem ALL"

Test-PsSapHostAgent

- Gets status information of SAP instances, databases, and components
- Wrapper for "saphostexec.exe -status"

Test-PsSapStartService

- Tests the desired SAP start services status (Running) and start type (Automatic).

Wait-PsSapSystem

- Waits for a SAP system to be started or stopped
- Wrapper for "sapcontrol.exe -host HOST_NAME -nr INSTANCE_NUMBER -function WaitforStarted 360 0"
