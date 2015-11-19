<# Module Name:     MTSVNXePerformance.psm1
## Author:          David Muegge
## Purpose:         Provides cmdlets for : Retieval of performance and usage information from VNXe SQLite database
##																					
## 
####################################################################################################
## Disclaimer
## ****************************************************************
## * THE (MTSVNXePerformance PowerShell Module)                   *
## * IS PROVIDED WITHOUT WARRANTY OF ANY KIND.                    *
## *                                                              *
## * This module is licensed under the terms of the MIT license.  *
## * See license.txt in the root of the github project            *
## *                                                              *
## **************************************************************** 
###################################################################################################>
# Load SQL Lite .Net Assembly default installation path - Change if required
if(Test-Path -Path "C:\Program Files\System.Data.SQLite\2013\bin"){$AssemblyPath = "C:\Program Files\System.Data.SQLite\2013\bin\System.Data.SQLite.dll"}
if(Test-Path -Path "C:\Program Files\System.Data.SQLite\2010\bin"){$AssemblyPath = "C:\Program Files\System.Data.SQLite\2010\bin\System.Data.SQLite.dll"}


# -- Do not make changes below this line ---------------------------
Add-Type -Path $AssemblyPath 

# Non-Exported functions
#region SQLite Database Functions

function Get-TableDetail{
<#
.SYNOPSIS
    Selects all records from provided SQLite table and returns as powershell object

.DESCRIPTION
    Selects all records from provided SQLite table and returns as array of PSObjects representing table row

.PARAMETER Path
    Path to location of SQLite Database files. 

.PARAMETER Filename
    Filename of SQLite database to be used

.PARAMETER Tablename
    Table to be returned from file

.INPUTS
    Required SQLite database information

.OUTPUTS
    SQLite table returned as array of PSObjects representing table row

.EXAMPLE
    Get-TableDetail -Path "C:\Temp" -Filename "capacity.db" -Tablename "system_totals"

.NOTES

#>

	[CmdletBinding()]
	
	param ( 
		[Parameter(Mandatory=$True)][string[]]$path, `
		[Parameter(Mandatory=$True)][string[]]$filename, `
		[Parameter(Mandatory=$True)][string[]]$tablename, `
		[Parameter(Mandatory=$false)][string[]]$sqltext=("select * from " + $tablename) `
	)
	
		# Get system totals information from capacity database
		$conn = New-Object -TypeName System.Data.SQLite.SQLiteConnection
		$connstring = "Data Source=" + $path + "\" + $filename 
		$conn.ConnectionString = $connstring
		$conn.Open()
		$command = $conn.CreateCommand()
		$command.CommandText = $sqltext
		$adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $command
		$dataset = New-Object System.Data.DataSet
		[void]$adapter.Fill($dataset)
		$tableinfo = $dataset.Tables[0].rows	
				
		$Result = @()
		foreach($row in $tableinfo){
			
			$tablerow = New-Object PSObject
			foreach($column in $row.Table.Columns  ){
				$columnname = $column.columnname
				$fieldvalue = $row."$columnname"
				$tablerow | add-member Noteproperty $columnname $fieldvalue
			}
			$result += $tablerow
		}
		
		$conn.Close()
		$result	
} # Get-TableDetail

#endregion


# Exported Functions
#region Configuration Functions

function Set-VNXeSQLiteLocation{
<#

.SYNOPSIS
Defines the location of SQLite database files

.DESCRIPTION
Defines the folder location of SQLite database files. This function define a module variable and should be called prior to using any get functions in the module.

.PARAMETER Path
The fullpath to the folder location containing the SQLite database files

.INPUTS
Path to SQLite database location

.OUTPUTS
None

.EXAMPLE
Set-VNXeSQLiteLocation -path "C:\Temp"

.NOTES

#>

	[CmdletBinding()]
	
	param ( 
		[Parameter(Mandatory=$True)]
		[string[]]$Path	
	)
	
	PROCESS {
		$Script:DBInputPath = $Path
	}
}

#endregion

#region Capacity Details Functions

# Capacity - capacity.db
# application_totals  init_time           pools
# applications        pool_totals         system_totals

function Get-VNXeCapacityStats{
<#
.SYNOPSIS
Returns a psobject for the SQLite stats_basic_summary tables

.DESCRIPTION
Returns a psobject for the SQLite stats_basic_summary tables

.PARAMETER Table

.INPUTS
None, Only requires set-SQLiteLocation to be called prior in session

.OUTPUTS
Array of PSObjects representing table records



.EXAMPLE 
$detailrecords = Get-VNXeBasicSummaryDetail

.NOTES

#>
	
	[CmdletBinding()]

	param ([String]$TableName)
	
	PROCESS{
		$path = $Script:DBInputPath
		$filename = "capacity.db"
		Get-TableDetail -path $path -filename $filename -tablename $TableName
	}
	
	
}

function Get-PoolNames{
<#
.SYNOPSIS
    

.DESCRIPTION


.PARAMETER Table

.INPUTS


.OUTPUTS


.EXAMPLE 


.NOTES

#>
	
	[CmdletBinding()]

	param ([String]$TableName="pools")
	
	PROCESS{
		$path = $Script:DBInputPath
		$filename = "capacity.db"
        $Query = "Select Distinct(pool_id) from pools"
		Get-TableDetail -path $path -filename $filename -tablename $TableName -sqltext $Query
	}
	
}

function Get-PoolStats{


[CmdletBinding()]
	
	param ( 
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$false)]$InputObject
	)

    $AllPoolStats = @()
    $RecordCount = 0
    foreach($Inst in $InputObject){

        $PoolStats = New-Object -TypeName PSObject
        $PoolStats | Add-Member -MemberType NoteProperty -Name TimeStamp -Value $Inst.timestamp
        $PoolStats | Add-Member -MemberType NoteProperty -Name total_space -Value $Inst.total_space
        $PoolStats | Add-Member -MemberType NoteProperty -Name allocated_space -Value $Inst.allocated_space
        $PoolStats | Add-Member -MemberType NoteProperty -Name pool_id -Value $Inst.pool_id

        $AllPoolStats += $PoolStats
    }
    
    Return $AllPoolStats
}

#endregion

#region Basic Summary Details Functions

# Basic Summary - stats_basic_summary.db
# dart2      flare_spa  gms_spa    os_spa
# dart3      flare_spb  gms_spb    os_spb

function Get-VNXeBasicSummaryStats{
<#
.SYNOPSIS
Returns a psobject for the SQLite stats_basic_summary tables

.DESCRIPTION
Returns a psobject for the SQLite stats_basic_summary tables

.PARAMETER Table

.INPUTS
None, Only requires set-SQLiteLocation to be called prior in session

.OUTPUTS
Array of PSObjects representing table records



.EXAMPLE 
$detailrecords = Get-VNXeBasicSummaryDetail

.NOTES

#>
	
	[CmdletBinding()]

	param ([String]$TableName)
	
	PROCESS{
		$path = $Script:DBInputPath
		$filename = "stats_basic_summary.db"
		Get-TableDetail -path $path -filename $filename -tablename $TableName
	}
	
	
}

function Get-VNXeOldBasicSummaryStats{
<#
.SYNOPSIS
Returns a psobject for the SQLite stats_basic_summary tables

.DESCRIPTION
Returns a psobject for the SQLite stats_basic_summary tables

.PARAMETER Table

.INPUTS
None, Only requires set-SQLiteLocation to be called prior in session

.OUTPUTS
Array of PSObjects representing table records



.EXAMPLE 
$detailrecords = Get-VNXeBasicSummaryDetail

.NOTES

#>
	
	[CmdletBinding()]

	param ([String]$TableName)
	
	PROCESS{
		$path = $Script:DBInputPath
		$filename = "old.stats_basic_summary.db"
		Get-TableDetail -path $path -filename $filename -tablename $TableName
	}
	
	
}

function Get-OSStats{
<#
.SYNOPSIS
Adds disk IO per second properties to the object BasicSummaryFlareSPx object

.DESCRIPTION
Adds disk IO per second properties to the object BasicSummaryFlareSPx object

The following properties are calculated and added dynamically upon data retrieval

LUNDiskReadsPerSec
LUNDiskWritesPerSec

.PARAMETER InputObject
PSObject returned from Get-VNXeBasicSummaryFlareSPADetail

.INPUTS


.OUTPUTS

.EXAMPLE 
$VNXeBasicSummaryFlareSPADetail = Get-VNXeBasicSummaryFlareSPADetail
Add-BasicSummaryFlareIOPerSec -InputObject $VNXeBasicSummaryFlareSPADetail


#>

	[CmdletBinding()]
	
	param ( 
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$false)]$InputObject
	)


    $AllOSStats = @()
    $RecordCount = 0
    foreach($Inst in $InputObject){

        # Add initial record
	    if($RecordCount -lt 1){

            [DateTime]$LastTimestamp = $Inst.stored_timestamp
		    $LastID = $Inst.id
		    $LastbusySystemTicks = $Inst.busySystemTicks
		    $LastbusyUserTicks = $Inst.busyUserTicks
            $LastidleTicks = $Inst.idleTicks
            $LastwaitTicks = $Inst.waitTicks
            $LastMemTotalKB = $Inst.MemTotalKB
            $LastMemFree = $Inst.MemFree
                    
            
        }
        Else{

            # If Rollover
            if($Inst.SysClockUnixms -eq 0){        
                $RolloverFlag = $true 
            }
            else{

                $OSStats = New-Object -TypeName PSObject

                # Get new values       	
		        [DateTime]$NewTimestamp = $Inst.stored_timestamp
		        $NewID = $Inst.id
                $ElapsedSeconds = $NewTimestamp.Subtract($LastTimestamp).TotalSeconds
                $OSStats | Add-Member -MemberType NoteProperty -Name TimeStamp -Value $NewTimestamp

                if($RolloverFlag){
                                    
                    
                    $NewbusySystemTicks = $Inst.busySystemTicks
		            $NewbusyUserTicks = $Inst.busyUserTicks
                    $NewidleTicks = $Inst.idleTicks
                    $NewwaitTicks = $Inst.waitTicks
                    $NewMemTotalKB = $Inst.MemTotalKB
                    $NewMemFree = $Inst.MemFree

                                        							    
                    $OSStats | Add-Member -MemberType NoteProperty -Name PercentCPUBusy -Value $PercentCPUBusy
                    $OSStats | Add-Member -MemberType NoteProperty -Name PercentCPUIdle -Value $PercentCPUIdle
                    $OSStats | Add-Member -MemberType NoteProperty -Name PercentCPUWait -Value $PercentCPUWait
                    $OSStats | Add-Member -MemberType NoteProperty -Name MemoryTotalKB -Value $MemoryTotalKB
                    $OSStats | Add-Member -MemberType NoteProperty -Name MemoryFree -Value $MemoryFree
                    
                    $RolloverFlag = $false

                    
                }
                else{

                    $NewbusySystemTicks = $Inst.busySystemTicks
		            $NewbusyUserTicks = $Inst.busyUserTicks
                    $NewidleTicks = $Inst.idleTicks
                    $NewwaitTicks = $Inst.waitTicks
                    $NewMemTotalKB = $Inst.MemTotalKB
                    $NewMemFree = $Inst.MemFree
                                        
		
			        $busySystemTicksChange = $NewbusySystemTicks - $LastbusySystemTicks
                    $busyUserTicksChange = $NewbusyUserTicks - $LastbusyUserTicks
                    $IdleTicksChange = $NewidleTicks - $LastidleTicks
                    $WaitTicksChange = $NewwaitTicks - $LastwaitTicks
                    $TotatTicksChange = $busySystemTicksChange + $busyUserTicksChange + $IdleTicksChange + $WaitTicksChange


			        if($TotatTicksChange -gt 0){[Int64]$PercentCPUBusy = (($busySystemTicksChange + $busyUserTicksChange) / $TotatTicksChange) * 100
                    }else{[Int64]$PercentCPUBusy = 0}
                    $OSStats | Add-Member -MemberType NoteProperty -Name PercentCPUBusy -Value $PercentCPUBusy

                    if($TotatTicksChange -gt 0){[Int64]$PercentCPUIdle = ($IdleTicksChange / $TotatTicksChange) * 100
                    }else{[Int64]$PercentCPUIdle = 0}
                    $OSStats | Add-Member -MemberType NoteProperty -Name PercentCPUIdle -Value $PercentCPUIdle

                    if($TotatTicksChange -gt 0){[Int64][Int64]$PercentCPUWait = ($WaitTicksChange / $TotatTicksChange) * 100
                    }else{[Int64]$PercentCPUWait = 0}
                    $OSStats | Add-Member -MemberType NoteProperty -Name PercentCPUWait -Value $PercentCPUWait

                    $OSStats | Add-Member -MemberType NoteProperty -Name MemTotalKB -Value $NewMemTotalKB
                    $OSStats | Add-Member -MemberType NoteProperty -Name MemFree -Value $NewMemFree
                    
                }

                $AllOSStats += $OSStats
			
            }

            # Increment Values
		    $LastTimestamp = $NewTimestamp 
		    $LastID = $NewID
            
            $LastbusySystemTicks = $NewbusySystemTicks
		    $LastbusyUserTicks = $NewbusyUserTicks
            $LastidleTicks = $NewidleTicks
            $LastwaitTicks = $NewwaitTicks
            $LastMemTotalKB = $NewMemTotalKB
            $LastMemFree = $NewMemFree

        }
        $RecordCount ++
    }


    Return $AllOSStats	


}

function Get-DartStoreStats{
<#
.SYNOPSIS
Adds disk IO per second properties to the object BasicSummaryFlareSPx object

.DESCRIPTION
Adds disk IO per second properties to the object BasicSummaryFlareSPx object

The following properties are calculated and added dynamically upon data retrieval

LUNDiskReadsPerSec
LUNDiskWritesPerSec

.PARAMETER InputObject
PSObject returned from Get-VNXeBasicSummaryFlareSPADetail

.INPUTS


.OUTPUTS

.EXAMPLE 
$VNXeBasicSummaryFlareSPADetail = Get-VNXeBasicSummaryFlareSPADetail
Add-BasicSummaryFlareIOPerSec -InputObject $VNXeBasicSummaryFlareSPADetail


#>

	[CmdletBinding()]
	
	param ( 
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$false)]$InputObject
	)


    $AllStoreStats = @()
    $RecordCount = 0
    foreach($Inst in $InputObject){

        # Add initial record
	    if($RecordCount -lt 1){

            [DateTime]$LastTimestamp = $Inst.stored_timestamp
		    $LastID = $Inst.id
		    $LastStoreReadRequests = $Inst.StoreReadRequests
		    $LastStoreWriteRequests = $Inst.StoreWriteRequests
            $LastStoreReadBytes = $Inst.StoreReadBytes
            $LastStoreWriteBytes = $Inst.StoreWriteBytes
            $LastNetInBytes = $Inst.NetBasicBytesIn
            $LastNetOutBytes = $Inst.NetBasicBytesOut
                    
            $LastISCSIBasicReads = $Inst.iSCSIBasicReads
            $LastISCSIBasicWrites = $Inst.iSCSIBasicWrites
            $LastISCSIReadBytes = $Inst.iSCSIReadBytes
            $LastISCSIWriteBytes = $Inst.iSCSIWriteBytes

            $LastCifsActiveConnections = $Inst.CifsActiveConnections
            $LastCifsTotalConnections = $Inst.CifsTotalConnections
            $LastCifsBasicReadBytes = $Inst.CifsBasicReadBytes
            $LastCifsBasicReadOpCount = $Inst.CifsBasicReadOpCount
            $LastCifsBasicWriteBytes = $Inst.CifsBasicWriteBytes
            $LastCifsBasicWriteOpCount = $Inst.CifsBasicWriteOpCount

            $LastNfsActiveConnections = $Inst.NfsActiveConnections
            $LastNfsBasicReadBytes = $Inst.NfsBasicReadBytes
            $LastNfsBasicReadOpCount = $Inst.NfsBasicReadOpCount
            $LastNfsBasicWriteBytes = $Inst.NfsBasicWriteBytes
            $LastNfsBasicWriteOpCount = $Inst.NfsBasicWriteOpCount

        }
        Else{

            # If Rollover
            if($Inst.SysClockUnixms -eq 0){        
                $RolloverFlag = $true 
            }
            else{

                $StoreStats = New-Object -TypeName PSObject

                # Get new values       	
		        if($Inst.stored_timestamp -ne $null){[DateTime]$NewTimestamp = $Inst.stored_timestamp}else{[DateTime]$NewTimestamp = $LastTimestamp}
		        $NewID = $Inst.id
                $ElapsedSeconds = $NewTimestamp.Subtract($LastTimestamp).TotalSeconds
                $StoreStats | Add-Member -MemberType NoteProperty -Name TimeStamp -Value $NewTimestamp

                if($RolloverFlag){
                                    
                    $NewStoreReadRequests = $Inst.StoreReadRequests
		            $NewStoreWriteRequests = $Inst.StoreWriteRequests
                    $NewStoreReadBytes = $Inst.StoreReadBytes
                    $NewStoreWriteBytes = $Inst.StoreWriteBytes
                    $NewNetInBytes = $Inst.NetBasicBytesIn
                    $NewNetOutBytes = $Inst.NetBasicBytesOut
                    
                    $NewISCSIBasicReads = $Inst.iSCSIBasicReads
                    $NewISCSIBasicWrites = $Inst.iSCSIBasicWrites
                    $NewISCSIReadBytes = $Inst.iSCSIReadBytes
                    $NewISCSIWriteBytes = $Inst.iSCSIWriteBytes

                    $NewCifsActiveConnections = $Inst.CifsActiveConnections
                    $NewCifsTotalConnections = $Inst.CifsTotalConnections
                    $NewCifsBasicReadBytes = $Inst.CifsBasicReadBytes
                    $NewCifsBasicReadOpCount = $Inst.CifsBasicReadOpCount
                    $NewCifsBasicWriteBytes = $Inst.CifsBasicWriteBytes
                    $NewCifsBasicWriteOpCount = $Inst.CifsBasicWriteOpCount

                    $NewNfsActiveConnections = $Inst.NfsActiveConnections
                    $NewNfsBasicReadBytes = $Inst.NfsBasicReadBytes
                    $NewNfsBasicReadOpCount = $Inst.NfsBasicReadOpCount
                    $NewNfsBasicWriteBytes = $Inst.NfsBasicWriteBytes
                    $NewNfsBasicWriteOpCount = $Inst.NfsBasicWriteOpCount

                                        							    
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadsPerSec -Value $StoreReadsPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWritesPerSec -Value $StoreWritesPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadMBPerSec -Value $StoreReadMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWriteMBPerSec -Value $StoreWriteMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetInMBPerSec -Value $NetInMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetOutMBPerSec -Value $NetOutMBPerSec

                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIReadsPerSec -Value $ISCSIReadsPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIWritesPerSec -Value $ISCSIWritesPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIReadMBPerSec -Value $ISCSIReadMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIWriteMBPerSec -Value $ISCSIWriteMBPerSec

                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsActiveConnections -Value $CifsActiveConnections
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsTotalConnections -Value $CifsTotalConnections
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsReadMBPerSec -Value $CifsReadMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsWriteMBPerSec -Value $CifsWriteMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsReadsPerSec -Value $CifsReadsPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsWritesPerSec -Value $CifsWritesPerSec

                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsActiveConnections -Value $NfsActiveConnections
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsReadMBPerSec -Value $NfsReadMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsWriteMBPerSec -Value $NfsWriteMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsReadsPerSec -Value $NfsReadsPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsWritesPerSec -Value $NfsWritesPerSec

                    $RolloverFlag = $false

                    
                }
                else{

                    $NewStoreReadRequests = $Inst.StoreReadRequests
		            $NewStoreWriteRequests = $Inst.StoreWriteRequests
                    $NewStoreReadBytes = $Inst.StoreReadBytes
                    $NewStoreWriteBytes = $Inst.StoreWriteBytes
                    $NewNetInBytes = $Inst.NetBasicBytesIn
                    $NewNetOutBytes = $Inst.NetBasicBytesOut
                    
                    $NewISCSIBasicReads = $Inst.iSCSIBasicReads
                    $NewISCSIBasicWrites = $Inst.iSCSIBasicWrites
                    $NewISCSIReadBytes = $Inst.iSCSIReadBytes
                    $NewISCSIWriteBytes = $Inst.iSCSIWriteBytes

                    $NewCifsActiveConnections = $Inst.CifsActiveConnections
                    $NewCifsTotalConnections = $Inst.CifsTotalConnections
                    $NewCifsBasicReadBytes = $Inst.CifsBasicReadBytes
                    $NewCifsBasicReadOpCount = $Inst.CifsBasicReadOpCount
                    $NewCifsBasicWriteBytes = $Inst.CifsBasicWriteBytes
                    $NewCifsBasicWriteOpCount = $Inst.CifsBasicWriteOpCount

                    $NewNfsActiveConnections = $Inst.NfsActiveConnections
                    $NewNfsBasicReadBytes = $Inst.NfsBasicReadBytes
                    $NewNfsBasicReadOpCount = $Inst.NfsBasicReadOpCount
                    $NewNfsBasicWriteBytes = $Inst.NfsBasicWriteBytes
                    $NewNfsBasicWriteOpCount = $Inst.NfsBasicWriteOpCount

                    		
                    # Store		
			        $StoreReadRequestsChange = $NewStoreReadRequests - $LastStoreReadRequests
			        if($ElapsedSeconds -gt 0){[Int64]$StoreReadsPerSec = $StoreReadRequestsChange / $ElapsedSeconds
                    }else{[Int64]$StoreReadsPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadsPerSec -Value $StoreReadsPerSec

                    $StoreWriteRequestsChange = $NewStoreWriteRequests - $LastStoreWriteRequests
                    if($ElapsedSeconds -gt 0){[Int64]$StoreWritesPerSec = $StoreWriteRequestsChange / $ElapsedSeconds
                    }else{[Int64]$StoreWritesPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWritesPerSec -Value $StoreWritesPerSec

                    $StoreReadBytesChange = $NewStoreReadBytes - $LastStoreReadBytes
                    if($ElapsedSeconds -gt 0){[Int64]$StoreReadMBPerSec = ($StoreReadBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$StoreReadMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadMBPerSec -Value $StoreReadMBPerSec
                    
                    $StoreWriteBytesChange = $NewStoreWriteBytes - $LastStoreWriteBytes
                    if($ElapsedSeconds -gt 0){[Int64]$StoreWriteMBPerSec = ($StoreWriteBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$StoreWriteMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWriteMBPerSec -Value $StoreWriteMBPerSec

                    $NetInBytesChange = $NewNetInBytes - $LastNetInBytes
                    if($ElapsedSeconds -gt 0){[Int64]$NetInMBPerSec = ($NetInBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$NetInMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetInMBPerSec -Value $NetInMBPerSec
                    
                    $NetOutBytesChange = $NewNetOutBytes - $LastNetOutBytes
                    if($ElapsedSeconds -gt 0){[Int64]$NetOutMBPerSec = ($NetOutBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$NetOutMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetOutMBPerSec -Value $NetOutMBPerSec


                    # iSCSI
                    $ISCSIBasicReadsChange = $NewISCSIBasicReads - $LastISCSIBasicReads
                    if($ElapsedSeconds -gt 0){[Int64]$ISCSIReadsPerSec = $ISCSIBasicReadsChange / $ElapsedSeconds
                    }else{[Int64]$ISCSIReadsPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIReadsPerSec -Value $ISCSIReadsPerSec

                    $ISCSIBasicWritesChange = $NewISCSIBasicWrites - $LastISCSIBasicWrites
                    if($ElapsedSeconds -gt 0){[Int64]$ISCSIWritesPerSec = $ISCSIBasicWritesChange / $ElapsedSeconds
                    }else{[Int64]$ISCSIWritesPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIWritesPerSec -Value $ISCSIWritesPerSec

                    $ISCSIReadBytesChange = $NewISCSIReadBytes - $LastISCSIReadBytes
                    if($ElapsedSeconds -gt 0){[Int64]$ISCSIReadMBPerSec = ($ISCSIReadBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$ISCSIReadMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIReadMBPerSec -Value $ISCSIReadMBPerSec

                    $ISCSIWriteBytesChange = $NewISCSIWriteBytes - $LastISCSIWriteBytes
                    if($ElapsedSeconds -gt 0){[Int64]$ISCSIWriteMBPerSec = ($ISCSIWriteBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$ISCSIWriteMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIWriteMBPerSec -Value $ISCSIWriteMBPerSec

                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsActiveConnections -Value $NewCifsActiveConnections
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsTotalConnections -Value $NewCifsTotalConnections

                    # CIFS
                    $CifsReadBytesChange = $NewCifsBasicReadBytes - $LastCifsBasicReadBytes
                    if($ElapsedSeconds -gt 0){[Int64]$CifsReadMBPerSec = ($CifsReadBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$CifsReadMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsReadMBPerSec -Value $CifsReadMBPerSec

                    $CifsWriteBytesChange = $NewCifsBasicWriteBytes - $LastCifsBasicWriteBytes
                    if($ElapsedSeconds -gt 0){[Int64]$CifsWriteMBPerSec = ($CifsWriteBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$CifsWriteMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsWriteMBPerSec -Value $CifsWriteMBPerSec
                    
                    $CifsBasicReadOpCountChange = $NewCifsBasicReadOpCount - $LastCifsBasicReadOpCount
                    if($ElapsedSeconds -gt 0){[Int64]$CifsReadsPerSec = $CifsBasicReadOpCountChange / $ElapsedSeconds
                    }else{[Int64]$CifsReadsPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsReadsPerSec -Value $CifsReadsPerSec

                    $CifsBasicWriteOpCountChange = $NewCifsBasicWriteOpCount - $LastCifsBasicWriteOpCount
                    if($ElapsedSeconds -gt 0){[Int64]$CifsWritesPerSec = $CifsBasicWriteOpCountChange / $ElapsedSeconds
                    }else{[Int64]$CifsWritesPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsWritesPerSec -Value $CifsWritesPerSec

                    # NFS
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsActiveConnections -Value $NewNfsActiveConnections

                    $NfsReadBytesChange = $NewNfsBasicReadBytes - $LastNfsBasicReadBytes
                    if($ElapsedSeconds -gt 0){[Int64]$NfsReadMBPerSec = ($NfsReadBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$NfsReadMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsReadMBPerSec -Value $NfsReadMBPerSec
                    
                    $NfsWriteBytesChange = $NewNfsBasicWriteBytes - $LastNfsBasicWriteBytes
                    if($ElapsedSeconds -gt 0){[Int64]$NfsWriteMBPerSec = ($NfsWriteBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$NfsWriteMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsWriteMBPerSec -Value $NfsWriteMBPerSec
                    
                    $NfsBasicReadOpCountChange = $NewNfsBasicReadOpCount - $LastNfsBasicReadOpCount
                    if($ElapsedSeconds -gt 0){[Int64]$NfsReadsPerSec = $NfsBasicReadOpCountChange / $ElapsedSeconds
                    }else{[Int64]$NfsReadsPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsReadsPerSec -Value $NfsReadsPerSec
                    
                    $NfsBasicWriteOpCountChange = $NewNfsBasicWriteOpCount - $LastNfsBasicWriteOpCount
                    if($ElapsedSeconds -gt 0){[Int64]$NfsWritesPerSec = $NfsBasicWriteOpCountChange / $ElapsedSeconds
                    }else{[Int64]$NfsWritesPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsWritesPerSec -Value $NfsWritesPerSec

                }

                $AllStoreStats += $StoreStats
			
            }

            # Increment Values
		    $LastTimestamp = $NewTimestamp 
		    $LastID = $NewID
            
            $LastStoreReadRequests = $NewStoreReadRequests
		    $LastStoreWriteRequests = $NewStoreWriteRequests
            $LastStoreReadBytes = $NewStoreReadBytes
            $LastStoreWriteBytes = $NewStoreWriteBytes
            $LastNetInBytes = $NewNetInBytes
            $LastNetOutBytes = $NewNetOutBytes
                    
            $LastISCSIBasicReads = $NewISCSIBasicReads
            $LastISCSIBasicWrites = $NewISCSIBasicWrites
            $LastISCSIReadBytes = $NewISCSIReadBytes
            $LastISCSIWriteBytes = $NewISCSIWriteBytes

            $LastCifsActiveConnections = $NewCifsActiveConnections
            $LastCifsTotalConnections = $NewCifsTotalConnections
            $LastCifsBasicReadBytes = $NewCifsBasicReadBytes
            $LastCifsBasicReadOpCount = $NewCifsBasicReadOpCount
            $LastCifsBasicWriteBytes = $NewCifsBasicWriteBytes
            $LastCifsBasicWriteOpCount = $NewCifsBasicWriteOpCount

            $LastNfsActiveConnections = $NewNfsActiveConnections
            $LastNfsBasicReadBytes = $NewNfsBasicReadBytes
            $LastNfsBasicReadOpCount = $NewNfsBasicReadOpCount
            $LastNfsBasicWriteBytes = $NewNfsBasicWriteBytes
            $LastNfsBasicWriteOpCount = $NewNfsBasicWriteOpCount


        }
        $RecordCount ++
    }


    Return $AllStoreStats	


}


function Get-DartBasicStats{
<#
.SYNOPSIS
Adds disk IO per second properties to the object BasicSummaryFlareSPx object

.DESCRIPTION
Adds disk IO per second properties to the object BasicSummaryFlareSPx object

The following properties are calculated and added dynamically upon data retrieval

LUNDiskReadsPerSec
LUNDiskWritesPerSec

.PARAMETER InputObject
PSObject returned from Get-VNXeBasicSummaryFlareSPADetail

.INPUTS


.OUTPUTS

.EXAMPLE 
$VNXeBasicSummaryFlareSPADetail = Get-VNXeBasicSummaryFlareSPADetail
Add-BasicSummaryFlareIOPerSec -InputObject $VNXeBasicSummaryFlareSPADetail


#>

	[CmdletBinding()]
	
	param ( 
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$false)]$InputObject
	)


    $AllStoreStats = @()
    $RecordCount = 0
    foreach($Inst in $InputObject){

        # Add initial record
	    if($RecordCount -lt 1){

            [DateTime]$LastTimestamp = $Inst.stored_timestamp
		    $LastID = $Inst.id
		    $LastStoreReadRequests = $Inst.StoreReadRequests
		    $LastStoreWriteRequests = $Inst.StoreWriteRequests
            $LastStoreReadBytes = $Inst.StoreReadBytes
            $LastStoreWriteBytes = $Inst.StoreWriteBytes
            $LastNetInBytes = $Inst.NetBasicBytesIn
            $LastNetOutBytes = $Inst.NetBasicBytesOut
                    

        }
        Else{

            # If Rollover
            if($Inst.SysClockUnixms -eq 0){        
                $RolloverFlag = $true 
            }
            else{

                $StoreStats = New-Object -TypeName PSObject

                # Get new values       	
		        if($Inst.stored_timestamp -ne $null){[DateTime]$NewTimestamp = $Inst.stored_timestamp}else{[DateTime]$NewTimestamp = $LastTimestamp}
		        $NewID = $Inst.id
                $ElapsedSeconds = $NewTimestamp.Subtract($LastTimestamp).TotalSeconds
                $StoreStats | Add-Member -MemberType NoteProperty -Name TimeStamp -Value $NewTimestamp

                if($RolloverFlag){
                                    
                    $NewStoreReadRequests = $Inst.StoreReadRequests
		            $NewStoreWriteRequests = $Inst.StoreWriteRequests
                    $NewStoreReadBytes = $Inst.StoreReadBytes
                    $NewStoreWriteBytes = $Inst.StoreWriteBytes
                    $NewNetInBytes = $Inst.NetBasicBytesIn
                    $NewNetOutBytes = $Inst.NetBasicBytesOut
                    
                    
                                        							    
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadsPerSec -Value $StoreReadsPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWritesPerSec -Value $StoreWritesPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadMBPerSec -Value $StoreReadMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWriteMBPerSec -Value $StoreWriteMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetInMBPerSec -Value $NetInMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetOutMBPerSec -Value $NetOutMBPerSec

                    
                    $RolloverFlag = $false

                    
                }
                else{

                    $NewStoreReadRequests = $Inst.StoreReadRequests
		            $NewStoreWriteRequests = $Inst.StoreWriteRequests
                    $NewStoreReadBytes = $Inst.StoreReadBytes
                    $NewStoreWriteBytes = $Inst.StoreWriteBytes
                    $NewNetInBytes = $Inst.NetBasicBytesIn
                    $NewNetOutBytes = $Inst.NetBasicBytesOut
                    
                                       		
                    # Store		
			        $StoreReadRequestsChange = $NewStoreReadRequests - $LastStoreReadRequests
			        if($ElapsedSeconds -gt 0){[Int64]$StoreReadsPerSec = $StoreReadRequestsChange / $ElapsedSeconds
                    }else{[Int64]$StoreReadsPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadsPerSec -Value $StoreReadsPerSec

                    $StoreWriteRequestsChange = $NewStoreWriteRequests - $LastStoreWriteRequests
                    if($ElapsedSeconds -gt 0){[Int64]$StoreWritesPerSec = $StoreWriteRequestsChange / $ElapsedSeconds
                    }else{[Int64]$StoreWritesPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWritesPerSec -Value $StoreWritesPerSec

                    $StoreReadBytesChange = $NewStoreReadBytes - $LastStoreReadBytes
                    if($ElapsedSeconds -gt 0){[Int64]$StoreReadMBPerSec = ($StoreReadBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$StoreReadMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadMBPerSec -Value $StoreReadMBPerSec
                    
                    $StoreWriteBytesChange = $NewStoreWriteBytes - $LastStoreWriteBytes
                    if($ElapsedSeconds -gt 0){[Int64]$StoreWriteMBPerSec = ($StoreWriteBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$StoreWriteMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWriteMBPerSec -Value $StoreWriteMBPerSec

                    $NetInBytesChange = $NewNetInBytes - $LastNetInBytes
                    if($ElapsedSeconds -gt 0){[Int64]$NetInMBPerSec = ($NetInBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$NetInMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetInMBPerSec -Value $NetInMBPerSec
                    
                    $NetOutBytesChange = $NewNetOutBytes - $LastNetOutBytes
                    if($ElapsedSeconds -gt 0){[Int64]$NetOutMBPerSec = ($NetOutBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$NetOutMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetOutMBPerSec -Value $NetOutMBPerSec


                    
                }

                $AllStoreStats += $StoreStats
			
            }

            # Increment Values
		    $LastTimestamp = $NewTimestamp 
		    $LastID = $NewID
            
            $LastStoreReadRequests = $NewStoreReadRequests
		    $LastStoreWriteRequests = $NewStoreWriteRequests
            $LastStoreReadBytes = $NewStoreReadBytes
            $LastStoreWriteBytes = $NewStoreWriteBytes
            $LastNetInBytes = $NewNetInBytes
            $LastNetOutBytes = $NewNetOutBytes
                    
        }
        $RecordCount ++
    }


    Return $AllStoreStats	


} # Get-DartBasicStats

function Get-DartSummaryStats{
<#
.SYNOPSIS
Adds disk IO per second properties to the object BasicSummaryFlareSPx object

.DESCRIPTION
Adds disk IO per second properties to the object BasicSummaryFlareSPx object

The following properties are calculated and added dynamically upon data retrieval

LUNDiskReadsPerSec
LUNDiskWritesPerSec

.PARAMETER InputObject
PSObject returned from Get-VNXeBasicSummaryFlareSPADetail

.INPUTS


.OUTPUTS

.EXAMPLE 
$VNXeBasicSummaryFlareSPADetail = Get-VNXeBasicSummaryFlareSPADetail
Add-BasicSummaryFlareIOPerSec -InputObject $VNXeBasicSummaryFlareSPADetail


#>

	[CmdletBinding()]
	
	param ( 
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$false)]$InputObject
	)


    $AllStoreStats = @()
    $RecordCount = 0
    foreach($Inst in $InputObject){

        # Add initial record
	    if($RecordCount -lt 1){

            [DateTime]$LastTimestamp = $Inst.stored_timestamp
		    $LastID = $Inst.id
		    $LastStoreReadRequests = $Inst.StoreReadRequests
		    $LastStoreWriteRequests = $Inst.StoreWriteRequests
            $LastStoreReadBytes = $Inst.StoreReadBytes
            $LastStoreWriteBytes = $Inst.StoreWriteBytes
            $LastNetInBytes = $Inst.NetBasicBytesIn
            $LastNetOutBytes = $Inst.NetBasicBytesOut
                    
            $LastISCSIBasicReads = $Inst.iSCSIBasicReads
            $LastISCSIBasicWrites = $Inst.iSCSIBasicWrites
            $LastISCSIReadBytes = $Inst.iSCSIReadBytes
            $LastISCSIWriteBytes = $Inst.iSCSIWriteBytes

            $LastCifsActiveConnections = $Inst.CifsActiveConnections
            $LastCifsTotalConnections = $Inst.CifsTotalConnections
            $LastCifsBasicReadBytes = $Inst.CifsBasicReadBytes
            $LastCifsBasicReadOpCount = $Inst.CifsBasicReadOpCount
            $LastCifsBasicWriteBytes = $Inst.CifsBasicWriteBytes
            $LastCifsBasicWriteOpCount = $Inst.CifsBasicWriteOpCount

            $LastNfsActiveConnections = $Inst.NfsActiveConnections
            $LastNfsBasicReadBytes = $Inst.NfsBasicReadBytes
            $LastNfsBasicReadOpCount = $Inst.NfsBasicReadOpCount
            $LastNfsBasicWriteBytes = $Inst.NfsBasicWriteBytes
            $LastNfsBasicWriteOpCount = $Inst.NfsBasicWriteOpCount

        }
        Else{

            # If Rollover
            if($Inst.SysClockUnixms -eq 0){        
                $RolloverFlag = $true 
            }
            else{

                $StoreStats = New-Object -TypeName PSObject

                # Get new values       	
		        if($Inst.stored_timestamp -ne $null){[DateTime]$NewTimestamp = $Inst.stored_timestamp}else{[DateTime]$NewTimestamp = $LastTimestamp}
		        $NewID = $Inst.id
                $ElapsedSeconds = $NewTimestamp.Subtract($LastTimestamp).TotalSeconds
                $StoreStats | Add-Member -MemberType NoteProperty -Name TimeStamp -Value $NewTimestamp

                if($RolloverFlag){
                                    
                    $NewStoreReadRequests = $Inst.StoreReadRequests
		            $NewStoreWriteRequests = $Inst.StoreWriteRequests
                    $NewStoreReadBytes = $Inst.StoreReadBytes
                    $NewStoreWriteBytes = $Inst.StoreWriteBytes
                    $NewNetInBytes = $Inst.NetBasicBytesIn
                    $NewNetOutBytes = $Inst.NetBasicBytesOut
                    
                    $NewISCSIBasicReads = $Inst.iSCSIBasicReads
                    $NewISCSIBasicWrites = $Inst.iSCSIBasicWrites
                    $NewISCSIReadBytes = $Inst.iSCSIReadBytes
                    $NewISCSIWriteBytes = $Inst.iSCSIWriteBytes

                    $NewCifsActiveConnections = $Inst.CifsActiveConnections
                    $NewCifsTotalConnections = $Inst.CifsTotalConnections
                    $NewCifsBasicReadBytes = $Inst.CifsBasicReadBytes
                    $NewCifsBasicReadOpCount = $Inst.CifsBasicReadOpCount
                    $NewCifsBasicWriteBytes = $Inst.CifsBasicWriteBytes
                    $NewCifsBasicWriteOpCount = $Inst.CifsBasicWriteOpCount

                    $NewNfsActiveConnections = $Inst.NfsActiveConnections
                    $NewNfsBasicReadBytes = $Inst.NfsBasicReadBytes
                    $NewNfsBasicReadOpCount = $Inst.NfsBasicReadOpCount
                    $NewNfsBasicWriteBytes = $Inst.NfsBasicWriteBytes
                    $NewNfsBasicWriteOpCount = $Inst.NfsBasicWriteOpCount

                                        							    
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadsPerSec -Value $StoreReadsPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWritesPerSec -Value $StoreWritesPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadMBPerSec -Value $StoreReadMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWriteMBPerSec -Value $StoreWriteMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetInMBPerSec -Value $NetInMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetOutMBPerSec -Value $NetOutMBPerSec

                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIReadsPerSec -Value $ISCSIReadsPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIWritesPerSec -Value $ISCSIWritesPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIReadMBPerSec -Value $ISCSIReadMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIWriteMBPerSec -Value $ISCSIWriteMBPerSec

                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsActiveConnections -Value $CifsActiveConnections
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsTotalConnections -Value $CifsTotalConnections
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsReadMBPerSec -Value $CifsReadMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsWriteMBPerSec -Value $CifsWriteMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsReadsPerSec -Value $CifsReadsPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsWritesPerSec -Value $CifsWritesPerSec

                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsActiveConnections -Value $NfsActiveConnections
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsReadMBPerSec -Value $NfsReadMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsWriteMBPerSec -Value $NfsWriteMBPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsReadsPerSec -Value $NfsReadsPerSec
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsWritesPerSec -Value $NfsWritesPerSec

                    $RolloverFlag = $false

                    
                }
                else{

                    $NewStoreReadRequests = $Inst.StoreReadRequests
		            $NewStoreWriteRequests = $Inst.StoreWriteRequests
                    $NewStoreReadBytes = $Inst.StoreReadBytes
                    $NewStoreWriteBytes = $Inst.StoreWriteBytes
                    $NewNetInBytes = $Inst.NetBasicBytesIn
                    $NewNetOutBytes = $Inst.NetBasicBytesOut
                    
                    $NewISCSIBasicReads = $Inst.iSCSIBasicReads
                    $NewISCSIBasicWrites = $Inst.iSCSIBasicWrites
                    $NewISCSIReadBytes = $Inst.iSCSIReadBytes
                    $NewISCSIWriteBytes = $Inst.iSCSIWriteBytes

                    $NewCifsActiveConnections = $Inst.CifsActiveConnections
                    $NewCifsTotalConnections = $Inst.CifsTotalConnections
                    $NewCifsBasicReadBytes = $Inst.CifsBasicReadBytes
                    $NewCifsBasicReadOpCount = $Inst.CifsBasicReadOpCount
                    $NewCifsBasicWriteBytes = $Inst.CifsBasicWriteBytes
                    $NewCifsBasicWriteOpCount = $Inst.CifsBasicWriteOpCount

                    $NewNfsActiveConnections = $Inst.NfsActiveConnections
                    $NewNfsBasicReadBytes = $Inst.NfsBasicReadBytes
                    $NewNfsBasicReadOpCount = $Inst.NfsBasicReadOpCount
                    $NewNfsBasicWriteBytes = $Inst.NfsBasicWriteBytes
                    $NewNfsBasicWriteOpCount = $Inst.NfsBasicWriteOpCount

                    		
                    # Store		
			        $StoreReadRequestsChange = $NewStoreReadRequests - $LastStoreReadRequests
			        if($ElapsedSeconds -gt 0){[Int64]$StoreReadsPerSec = $StoreReadRequestsChange / $ElapsedSeconds
                    }else{[Int64]$StoreReadsPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadsPerSec -Value $StoreReadsPerSec

                    $StoreWriteRequestsChange = $NewStoreWriteRequests - $LastStoreWriteRequests
                    if($ElapsedSeconds -gt 0){[Int64]$StoreWritesPerSec = $StoreWriteRequestsChange / $ElapsedSeconds
                    }else{[Int64]$StoreWritesPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWritesPerSec -Value $StoreWritesPerSec

                    $StoreReadBytesChange = $NewStoreReadBytes - $LastStoreReadBytes
                    if($ElapsedSeconds -gt 0){[Int64]$StoreReadMBPerSec = ($StoreReadBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$StoreReadMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreReadMBPerSec -Value $StoreReadMBPerSec
                    
                    $StoreWriteBytesChange = $NewStoreWriteBytes - $LastStoreWriteBytes
                    if($ElapsedSeconds -gt 0){[Int64]$StoreWriteMBPerSec = ($StoreWriteBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$StoreWriteMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name StoreWriteMBPerSec -Value $StoreWriteMBPerSec

                    $NetInBytesChange = $NewNetInBytes - $LastNetInBytes
                    if($ElapsedSeconds -gt 0){[Int64]$NetInMBPerSec = ($NetInBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$NetInMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetInMBPerSec -Value $NetInMBPerSec
                    
                    $NetOutBytesChange = $NewNetOutBytes - $LastNetOutBytes
                    if($ElapsedSeconds -gt 0){[Int64]$NetOutMBPerSec = ($NetOutBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$NetOutMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NetOutMBPerSec -Value $NetOutMBPerSec


                    # iSCSI
                    $ISCSIBasicReadsChange = $NewISCSIBasicReads - $LastISCSIBasicReads
                    if($ElapsedSeconds -gt 0){[Int64]$ISCSIReadsPerSec = $ISCSIBasicReadsChange / $ElapsedSeconds
                    }else{[Int64]$ISCSIReadsPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIReadsPerSec -Value $ISCSIReadsPerSec

                    $ISCSIBasicWritesChange = $NewISCSIBasicWrites - $LastISCSIBasicWrites
                    if($ElapsedSeconds -gt 0){[Int64]$ISCSIWritesPerSec = $ISCSIBasicWritesChange / $ElapsedSeconds
                    }else{[Int64]$ISCSIWritesPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIWritesPerSec -Value $ISCSIWritesPerSec

                    $ISCSIReadBytesChange = $NewISCSIReadBytes - $LastISCSIReadBytes
                    if($ElapsedSeconds -gt 0){[Int64]$ISCSIReadMBPerSec = ($ISCSIReadBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$ISCSIReadMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIReadMBPerSec -Value $ISCSIReadMBPerSec

                    $ISCSIWriteBytesChange = $NewISCSIWriteBytes - $LastISCSIWriteBytes
                    if($ElapsedSeconds -gt 0){[Int64]$ISCSIWriteMBPerSec = ($ISCSIWriteBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$ISCSIWriteMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name ISCSIWriteMBPerSec -Value $ISCSIWriteMBPerSec

                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsActiveConnections -Value $NewCifsActiveConnections
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsTotalConnections -Value $NewCifsTotalConnections

                    # CIFS
                    $CifsReadBytesChange = $NewCifsBasicReadBytes - $LastCifsBasicReadBytes
                    if($ElapsedSeconds -gt 0){[Int64]$CifsReadMBPerSec = ($CifsReadBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$CifsReadMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsReadMBPerSec -Value $CifsReadMBPerSec

                    $CifsWriteBytesChange = $NewCifsBasicWriteBytes - $LastCifsBasicWriteBytes
                    if($ElapsedSeconds -gt 0){[Int64]$CifsWriteMBPerSec = ($CifsWriteBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$CifsWriteMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsWriteMBPerSec -Value $CifsWriteMBPerSec
                    
                    $CifsBasicReadOpCountChange = $NewCifsBasicReadOpCount - $LastCifsBasicReadOpCount
                    if($ElapsedSeconds -gt 0){[Int64]$CifsReadsPerSec = $CifsBasicReadOpCountChange / $ElapsedSeconds
                    }else{[Int64]$CifsReadsPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsReadsPerSec -Value $CifsReadsPerSec

                    $CifsBasicWriteOpCountChange = $NewCifsBasicWriteOpCount - $LastCifsBasicWriteOpCount
                    if($ElapsedSeconds -gt 0){[Int64]$CifsWritesPerSec = $CifsBasicWriteOpCountChange / $ElapsedSeconds
                    }else{[Int64]$CifsWritesPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name CifsWritesPerSec -Value $CifsWritesPerSec

                    # NFS
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsActiveConnections -Value $NewNfsActiveConnections

                    $NfsReadBytesChange = $NewNfsBasicReadBytes - $LastNfsBasicReadBytes
                    if($ElapsedSeconds -gt 0){[Int64]$NfsReadMBPerSec = ($NfsReadBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$NfsReadMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsReadMBPerSec -Value $NfsReadMBPerSec
                    
                    $NfsWriteBytesChange = $NewNfsBasicWriteBytes - $LastNfsBasicWriteBytes
                    if($ElapsedSeconds -gt 0){[Int64]$NfsWriteMBPerSec = ($NfsWriteBytesChange / $ElapsedSeconds) / 1024 / 1024
                    }else{[Int64]$NfsWriteMBPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsWriteMBPerSec -Value $NfsWriteMBPerSec
                    
                    $NfsBasicReadOpCountChange = $NewNfsBasicReadOpCount - $LastNfsBasicReadOpCount
                    if($ElapsedSeconds -gt 0){[Int64]$NfsReadsPerSec = $NfsBasicReadOpCountChange / $ElapsedSeconds
                    }else{[Int64]$NfsReadsPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsReadsPerSec -Value $NfsReadsPerSec
                    
                    $NfsBasicWriteOpCountChange = $NewNfsBasicWriteOpCount - $LastNfsBasicWriteOpCount
                    if($ElapsedSeconds -gt 0){[Int64]$NfsWritesPerSec = $NfsBasicWriteOpCountChange / $ElapsedSeconds
                    }else{[Int64]$NfsWritesPerSec = 0}
                    $StoreStats | Add-Member -MemberType NoteProperty -Name NfsWritesPerSec -Value $NfsWritesPerSec

                }

                $AllStoreStats += $StoreStats
			
            }

            # Increment Values
		    $LastTimestamp = $NewTimestamp 
		    $LastID = $NewID
            
            $LastStoreReadRequests = $NewStoreReadRequests
		    $LastStoreWriteRequests = $NewStoreWriteRequests
            $LastStoreReadBytes = $NewStoreReadBytes
            $LastStoreWriteBytes = $NewStoreWriteBytes
            $LastNetInBytes = $NewNetInBytes
            $LastNetOutBytes = $NewNetOutBytes
                    
            $LastISCSIBasicReads = $NewISCSIBasicReads
            $LastISCSIBasicWrites = $NewISCSIBasicWrites
            $LastISCSIReadBytes = $NewISCSIReadBytes
            $LastISCSIWriteBytes = $NewISCSIWriteBytes

            $LastCifsActiveConnections = $NewCifsActiveConnections
            $LastCifsTotalConnections = $NewCifsTotalConnections
            $LastCifsBasicReadBytes = $NewCifsBasicReadBytes
            $LastCifsBasicReadOpCount = $NewCifsBasicReadOpCount
            $LastCifsBasicWriteBytes = $NewCifsBasicWriteBytes
            $LastCifsBasicWriteOpCount = $NewCifsBasicWriteOpCount

            $LastNfsActiveConnections = $NewNfsActiveConnections
            $LastNfsBasicReadBytes = $NewNfsBasicReadBytes
            $LastNfsBasicReadOpCount = $NewNfsBasicReadOpCount
            $LastNfsBasicWriteBytes = $NewNfsBasicWriteBytes
            $LastNfsBasicWriteOpCount = $NewNfsBasicWriteOpCount


        }
        $RecordCount ++
    }


    Return $AllStoreStats	


} # Get-DartSummaryStats


#endregion

#region Basic Default Details Functions

# Basic Default - stats_basic_default.db"
# dart2           flare_spa       os_spa_default
# dart3           flare_spb       os_spb_default

function Get-VNXeBasicDefaultStats{
<#
.SYNOPSIS
Returns a psobject for the SQLite stats_basic_summary tables

.DESCRIPTION
Returns a psobject for the SQLite stats_basic_summary tables

.PARAMETER Table

.INPUTS
None, Only requires set-SQLiteLocation to be called prior in session

.OUTPUTS
Array of PSObjects representing table records



.EXAMPLE 
$detailrecords = Get-VNXeBasicSummaryDetail

.NOTES

#>
	
	[CmdletBinding()]

	param ([String]$TableName)
	
	PROCESS{
		$path = $Script:DBInputPath
		$filename = "stats_basic_default.db"
		Get-TableDetail -path $path -filename $filename -tablename $TableName
	}
	
	
}

function Get-VNXeOldBasicDefaultStats{
<#
.SYNOPSIS
Returns a psobject for the SQLite stats_basic_summary tables

.DESCRIPTION
Returns a psobject for the SQLite stats_basic_summary tables

.PARAMETER Table

.INPUTS
None, Only requires set-SQLiteLocation to be called prior in session

.OUTPUTS
Array of PSObjects representing table records



.EXAMPLE 
$detailrecords = Get-VNXeBasicSummaryDetail

.NOTES

#>
	
	[CmdletBinding()]

	param ([String]$TableName)
	
	PROCESS{
		$path = $Script:DBInputPath
		$filename = "old.stats_basic_default.db"
		Get-TableDetail -path $path -filename $filename -tablename $TableName
	}
	
	
}


#endregion


# Configuration functions
Export-ModuleMember Set-VNXeSQLiteLocation

# SQL Lite data retieval
Export-ModuleMember Get-TableDetail

# Detail functions
# Capacity
Export-ModuleMember Get-VNXeCapacityStats
Export-ModuleMember Get-PoolNames
Export-ModuleMember Get-PoolStats

# Basic Summary
Export-ModuleMember Get-VNXeBasicSummaryStats
Export-ModuleMember Get-VNXeOldBasicSummaryStats

#Basic Default
Export-ModuleMember Get-VNXeBasicDefaultStats
Export-ModuleMember Get-VNXeOldBasicDefaultStats

Export-ModuleMember Get-OSStats
Export-ModuleMember Get-DartStoreStats
Export-ModuleMember Get-DartBasicStats
Export-ModuleMember Get-DartSummaryStats


# Data formatting
Export-ModuleMember Get-PHDSQLFieldNames
Export-ModuleMember Get-PHDSQLColumnListValue


