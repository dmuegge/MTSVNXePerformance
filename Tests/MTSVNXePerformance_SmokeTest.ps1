<#

MTSVNXePerformance Smoke Test code

Used to test all MTSVNXePerformance PowerShell module functionality


DO NOT RUN THIS SCRIPT ON PRODUCTION ARRAYS
DO NOT USE IF YOU DO NOT UNDERSTAND THIS CODE. IT WILL CREATE AND DELETE OBJECTS!!

Script has not yet beened designed to run and complete automated tests.
Is meant to be used for manual testing.

#>

Import-Module MTSVNXePerformance
Import-Module MTSChart


$ReportPath = "C:\Data\VNXe_Test\APM0011\Report"
$ChartPath = "C:\Data\VNXe_Test\APM0011\Report\Charts"
$VNXeHOstName = 'APM0011'


Set-VNXeSQLiteLocation -Path "C:\Data\VNXe_Test\APM0011"


# Get Pool info
$PoolNames = Get-PoolNames
$PoolsCapacity = Get-VNXeCapacityStats "pools"
$PoolStats = Get-PoolStats -InputObject $PoolsCapacity




if(-Not (Test-Path -Path $ReportPath)){New-Item -Path $ReportPath -ItemType Directory}
if(-Not (Test-Path -Path $ChartPath)){New-Item -Path $ChartPath -ItemType Directory}


foreach($Pool in $PoolNames){

    ($pool.pool_id)
    Get-SeriesRollup -InputObject ($PoolStats | Where-Object pool_id -EQ ($pool.pool_id)) -Property allocated_space | Select-Object Property,Average,Median,95thPercentile,99thPercentile,Maximum
    
}


$OSSPA = Get-VNXeBasicDefaultStats 'os_spa_default'
$OSStats = Get-OSStats -InputObject $OSSPA

$YValues = 'PercentCPUBusy,PercentCPUIdle,PercentCPUWait'

$PFields = $YValues.Split(',')
foreach($f in $PFields){
    Get-SeriesRollup -InputObject $OSStats -Property $f | Select-Object Property,Average,Median,95thPercentile,99thPercentile,Maximum | FT -AutoSize
}
$ImgFullPath = ($ChartPath + '\' + $VNXeHOstName + '_SPA-OS-Stats.png')
Out-MTSChart -InputObject $OSStats `
                 -XValue 'TimeStamp' `
                 -YValues $YValues `
                 -ChartType 'Line' `
                 -ChartTitle 'os_spa_default' `
                 -XInterval 20 `
                 -Height 600 `
                 -width 800 `
                 -ChartFileType 'png' `
                 -ChartFullPath $ImgFullPath

iex $ImgFullPath



$ImgFullPath = ($ChartPath + '\' + $VNXeHOstName + '_Dart2_IOPS.png')
$Dart2 = Get-VNXeBasicDefaultStats 'dart2'
$DartStoreStats2 = Get-DartStoreStats -InputObject $Dart2
Out-MTSChart -InputObject $DartStoreStats2 `
                 -XValue 'TimeStamp' `
                 -YValues 'StoreReadsPerSec,StoreWritesPerSec' `
                 -ChartType 'Line' `
                 -ChartTitle 'Dart 2 IOPS' `
                 -XInterval 20 `
                 -Height 600 `
                 -width 800 `
                 -ChartFileType 'png' `
                 -ChartFullPath $ImgFullPath `
                 -LegendOn | Out-Null


iex $ImgFullPath

$ImgFullPath = ($ChartPath + '\' + $VNXeHOstName + '_Dart3_IOPS.png')
$Dart3 = Get-VNXeBasicDefaultStats 'dart3'
$DartStoreStats3 = Get-DartStoreStats -InputObject $Dart3
Out-MTSChart -InputObject $DartStoreStats3 `
                 -XValue 'TimeStamp' `
                 -YValues 'StoreReadsPerSec,StoreWritesPerSec' `
                 -ChartType 'Line' `
                 -ChartTitle 'Dart 3 IOPS' `
                 -XInterval 20 `
                 -Height 600 `
                 -width 800 `
                 -ChartFileType 'png' `
                 -ChartFullPath $ImgFullPath `
                 -LegendOn | Out-Null


iex $ImgFullPath