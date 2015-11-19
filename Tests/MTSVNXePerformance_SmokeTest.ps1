<#

MTSVNXePerformance Smoke Test code

Used to test all MTSVNXePerformance PowerShell module functionality


DO NOT RUN THIS SCRIPT ON PRODUCTION ARRAYS
DO NOT USE IF YOU DO NOT UNDERSTAND THIS CODE. IT WILL CREATE AND DELETE OBJECTS!!

Script has not yet beened designed to run and complete automated tests.
Is meant to be used for manual testing.

#>

Import-Module MTSVNXePerformance


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
    $ImgFullPath = ($ChartPath + '\' + $VNXeHOstName + '_Capacity_' + (($pool.pool_id).ToString().Replace(' ','_')) + '_Pool.png')
    New-PNGChart -YValues 'allocated_space,total_space' -ChartType 'Line' -ChartTitle ($pool.pool_id) -ChartFullPath $ImgFullPath -InputObject ($PoolStats | Where-Object pool_id -EQ ($pool.pool_id)) | Out-Null
    iex $ImgFullPath
    Get-SeriesRollup -InputObject ($PoolStats | Where-Object pool_id -EQ ($pool.pool_id)) -Property allocated_space | Select-Object Property,Average,Median,95thPercentile,99thPercentile,Maximum | ConvertTo-Html -Fragment -As List | Out-File -FilePath $Reportfile -Append
    
}
