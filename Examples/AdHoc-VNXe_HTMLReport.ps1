<#
.SYNOPSIS 
    Build HTML Full Performance Report
 
.DESCRIPTION 
    Utilizes MTSAssessment SQL Database to build report in HTML

    Report contains Inventory, Performance Summary and Rollup informaion by performance category and by host

    Data can be filtered and sorted to provide various views of data

    Host detail information can be viewed from file or web srver


.EXAMPLE
    AdHoc-VNXe_HTMLReport.ps1    
        

  Disclaimer
  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************     
#>
[CmdletBinding()]
Param()

Import-Module MTSVNXePerformance
Import-Module MTSHTML
Import-Module MTSPerfAnalysis
Import-Module MTSMSSQL
Import-Module MTSChart

#region Functions

function New-PNGChart{

    Param($InputObject,$YValues,$ChartType,$ChartFullPath,$ChartTitle)
    
    
    out-MTSChart -InputObject $InputObject -YValues $YValues -XValue 'TimeStamp' `
    -width 800 -height 400 `
    -chartTitle $ChartTitle -ChartType $ChartType `
    -XInterval 40 `
    -ChartFullPath $ChartFullPath -LegendOn
    

}

function Set-HTMLSectionHeader{

[CmdletBinding()]
param ([Parameter(Mandatory=$True,ValueFromPipeline=$false)]$Reportfile,[Parameter(Mandatory=$True,ValueFromPipeline=$false)]$SectionTitle)

    "<tr><td><H3>$SectionTitle</H3></td></tr>" | Out-File -FilePath $Reportfile -append
}

function Set-HTMLReportSection{


[CmdletBinding()]
param ( 

		[Parameter(Mandatory=$True,ValueFromPipeline=$false)]$Stats,
        [Parameter(Mandatory=$True,ValueFromPipeline=$false)]$YValues,
        [Parameter(Mandatory=$True,ValueFromPipeline=$false)]$Reportfile,
        [Parameter(Mandatory=$True,ValueFromPipeline=$false)]$ChartType,
        [Parameter(Mandatory=$True,ValueFromPipeline=$false)]$ChartTitle,
        [Parameter(Mandatory=$True,ValueFromPipeline=$false)]$AbsChartpath,
        [Parameter(Mandatory=$True,ValueFromPipeline=$false)]$RelChartpath

	)
     

    New-PNGChart -YValues $YValues -ChartType $ChartType -ChartTitle $ChartTitle -ChartFullPath $AbsChartpath -InputObject $Stats | Out-Null
    "<tr><td><img src=""$RelChartpath""/></td></tr>" | Out-File -FilePath $Reportfile -Append

    $PFields = $YValues.Split(',')
    foreach($f in $PFields){
        Get-SeriesRollup -InputObject $Stats -Property $f | Select-Object Property,Average,Median,95thPercentile,99thPercentile,Maximum | ConvertTo-Html -Fragment -As List | Out-File -FilePath $Reportfile -Append
    }
    '<tr><td><HR></td></tr>' | Out-File -FilePath $Reportfile -append
    '<tr><td></td></tr>' | Out-File -FilePath $Reportfile -append

}

function Set-HTMLSectionFooter{
[CmdletBinding()]
param ( [Parameter(Mandatory=$True,ValueFromPipeline=$false)]$Reportfile)


    '<tr><td><HR></td></tr>' | Out-File -FilePath $Reportfile -append
    '<tr><td></td></tr>' | Out-File -FilePath $Reportfile -append
    

}

function Set-HTMLImage{
[CmdletBinding()]
param ( [Parameter(Mandatory=$True,ValueFromPipeline=$false)]$Reportfile,[Parameter(Mandatory=$True,ValueFromPipeline=$false)]$imgsrc)

    "<tr><td><img src=""$imgsrc""/></td></tr>" | Out-File -FilePath $Reportfile -Append
}

#endregion


#region MAIN ##

        # Configuration Information ***        
        $VNXeHOstName = 'APM0011'
        $VNXeDataPath = 'C:\Data\VNXe_Test\APM0011'
        $ErrorLogPath = 'C:\Data\VNXe_Test'
        $ReportPath = 'C:\Data\VNXe_Test\APM0011\Report'
        # ************************************************


                

        # Setup error log
        $errorfile = Get-logNameFromDate -path $ErrorLogPath -suffix 'txt' -name 'VNXeHTMLReport_Error_' -Create
        Write-Verbose -Message ((Get-TimeStampString) + ' : Error log file created ' + $errorfile)
        

            # Set Location of SQite database files
            Set-VNXeSQLiteLocation -Path $VNXeDataPath

            # Create Rport Directory
            if(!(Test-Path -Path ($ReportPath))){New-Item -Path ($ReportPath) -ItemType Directory -Force}

            # Write Index page
            New-HTMLDocumentFrameIndex -HTMLIndexfile ($ReportPath + '\' + 'index.html') -HTMLMenufile ('menu.html')
        
            # Write Home page
            $HomePage = $ReportPath + '\' + 'Home.html'
            Set-HTMLDocumentStart -Reportfile $HomePage

            # Write Menu page
            $MenuPage = $ReportPath + '\' + 'Menu.html'
            Set-HTMLDocumentStart -Reportfile $MenuPage
            '<tr><td><A target="main" href="Home.html">Home</A></td></tr>' | Out-File -FilePath $MenuPage -append

            # Create charts directory
            $AbsChartPath = ($ReportPath + '\Charts')
            if(!(Test-Path -Path ($ReportPath + '\Charts'))){New-Item -Path ($ReportPath + '\Charts') -ItemType Directory -Force}
            $RelChartPath = 'Charts'

            # Get Pool names
            $PoolNames = Get-PoolNames

            # Get all capacity data
            $PoolsCapacity = Get-VNXeCapacityStats 'pools'

            # Filter returned data and output report info
            $PoolStats = Get-PoolStats -InputObject $PoolsCapacity
                       
            
            #region Pools Capacity 
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Pools_Capacity.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Pools_Capacity.html' + '">'+ $VNXeHOstName + '_Pools_Capacity' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'Pools Capacity'
            foreach($Pool in $PoolNames){
                $ImageAbsPath = ($AbsChartPath + '\' + $VNXeHOstName + '_Capacity_' + (($pool.pool_id).ToString().Replace(' ','_')) + '_Pool.png')
                $ImgRelPath = ('Charts\' + $VNXeHOstName + '_Capacity_' + (($pool.pool_id).ToString().Replace(' ','_')) + '_Pool.png')
                New-PNGChart -YValues 'allocated_space,total_space' -ChartType 'Line' -ChartTitle ($pool.pool_id) -ChartFullPath $ImageAbsPath -InputObject ($PoolStats | Where-Object pool_id -EQ ($pool.pool_id)) | Out-Null
                Set-HTMLImage -Reportfile $ReportFile -imgsrc $ImgRelPath
                Get-SeriesRollup -InputObject ($PoolStats | Where-Object pool_id -EQ ($pool.pool_id)) -Property allocated_space | Select-Object Property,Average,Median,95thPercentile,99thPercentile,Maximum | ConvertTo-Html -Fragment -As List | Out-File -FilePath $Reportfile -Append
                Set-HTMLSectionFooter -Reportfile $ReportFile
            }
            #endregion


            #region OS Basic Default SPA
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_OS_SPA_Default.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_OS_SPA_Default.html' + '">'+ $VNXeHOstName + '_OS_SPA_Default' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $OSStats = $null
            $OSSPA = $null
            $OSSPA = Get-VNXeBasicDefaultStats 'os_spa_default'
            $OSStats = Get-OSStats -InputObject $OSSPA
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'OS SPA Basic Default'
            Set-HTMLReportSection -Stats $OSStats -YValues 'PercentCPUBusy,PercentCPUIdle,PercentCPUWait' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'SPA CPU' -AbsChartpath ($AbsChartPath + '\VNXe_OS_Default_SPA_CPU.png') -RelChartpath ($RelChartPath + '/VNXe_OS_Default_SPA_CPU.png')
            
            #endregion
            
            #region OS Basic Default SPB
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_OS_SPB_Default.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_OS_SPB_Default.html' + '">'+ $VNXeHOstName + '_OS_SPB_Default' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $OSStats = $null
            $OSSPB = $null
            $OSSPB = Get-VNXeBasicDefaultStats 'os_spb_default'
            $OSStats = Get-OSStats -InputObject $OSSPB
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'OS SPB Basic Default'
            Set-HTMLReportSection -Stats $OSStats -YValues 'PercentCPUBusy,PercentCPUIdle,PercentCPUWait' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'SPB CPU' -AbsChartPath ($AbsChartPath + '\VNXe_OS_Default_SPB_CPU.png') -RelChartpath ($RelChartPath + '/VNXe_OS_Default_SPB_CPU.png')
            
            #endregion
            
            #region OS Old Basic Default SPA
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Old_OS_SPA_Default.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Old_OS_SPA_Default.html' + '">'+ $VNXeHOstName + '_Old_OS_SPA_Default' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $OSStats = $null
            $OSSPA = $null
            $OSSPA = Get-VNXeOldBasicDefaultStats 'os_spa_default'
            $OSStats = Get-OSStats -InputObject $OSSPA
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'OS SPA Old Basic Default'
            Set-HTMLReportSection -Stats $OSStats -YValues 'PercentCPUBusy,PercentCPUIdle,PercentCPUWait' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'SPA CPU' -AbsChartPath ($AbsChartPath + '\VNXe_OS_Old_Default_SPA_CPU.png') -RelChartpath ($RelChartPath + '/VNXe_OS_Old_Default_SPA_CPU.png')
            
            #endregion

            #region OS Old Basic Default SPB
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Old_OS_SPB_Default.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Old_OS_SPB_Default.html' + '">'+ $VNXeHOstName + '_Old_OS_SPB_Default' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $OSStats = $null
            $OSSPB = $null
            $OSSPB = Get-VNXeOldBasicDefaultStats 'os_spb_default'
            $OSStats = Get-OSStats -InputObject $OSSPB
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'OS SPB Old Basic Default'
            Set-HTMLReportSection -Stats $OSStats -YValues 'PercentCPUBusy,PercentCPUIdle,PercentCPUWait' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'SPB CPU' -AbsChartPath ($AbsChartPath + '\VNXe_OS_Old_Default_SPB_CPU.png') -RelChartpath ($RelChartPath + '/VNXe_OS_Old_Default_SPB_CPU.png')
            
            #endregion


            #region OS Summary SPA
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_OS_SPA_Basic_Summary.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_OS_SPA_Basic_Summary.html' + '">'+ $VNXeHOstName + '_OS_SPA_Basic_Summary' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $OSStats = $null
            $OSSPASummary = $null
            $OSSPASummary = Get-VNXeBasicSummaryStats 'os_spa'
            $OSStats = Get-OSStats -InputObject $OSSPASummary
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'OS SPA Basic Summary'
            $ImgFullPath = ($AbsChartPath + '\' + 'VNXe_OS_Summary_SPA_Memory.png')
            New-PNGChart -YValues 'MemTotalKB,MemFree' -ChartType 'Line' -ChartTitle 'SPA Memory' -ChartFullPath $ImgFullPath -InputObject $OSStats | Out-Null
            Set-HTMLImage -Reportfile $ReportFile -imgsrc $ImgFullPath
            Set-HTMLReportSection -Stats $OSStats -YValues 'PercentCPUBusy,PercentCPUIdle,PercentCPUWait' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'SPA CPU' -AbsChartPath ($AbsChartPath + '\VNXe_OS_Summary_SPA_CPU.png') -RelChartpath ($RelChartPath + '/VNXe_OS_Summary_SPA_CPU.png')
            #endregion

            #region OS Summary SPB
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_OS_SPB_Basic_Summary.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_OS_SPB_Basic_Summary.html' + '">'+ $VNXeHOstName + '_OS_SPB_Basic_Summary' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $OSStats = $null
            $OSSPBSummary = $null
            $OSSPBSummary = Get-VNXeBasicSummaryStats 'os_spb'
            $OSStats = Get-OSStats -InputObject $OSSPBSummary
            $ImgFullPath = ($AbsChartPath + '\' + 'VNXe_OS_Summary_SPB_Memory.png')
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'OS SPB Basic Summary'
            New-PNGChart -YValues 'MemTotalKB,MemFree' -ChartType 'Line' -ChartTitle 'SPB Memory' -ChartFullPath $ImgFullPath -InputObject $OSStats | Out-Null
            Set-HTMLImage -Reportfile $ReportFile -imgsrc $ImgFullPath
            Set-HTMLReportSection -Stats $OSStats -YValues 'PercentCPUBusy,PercentCPUIdle,PercentCPUWait' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'SPB CPU' -AbsChartPath ($AbsChartPath + '\VNXe_OS_Summary_SPB_CPU.png') -RelChartpath ($RelChartPath + '/VNXe_OS_Summary_SPB_CPU.png')
            
            #endregion
            
            #region OS Old Basic Summary SPA
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_OS_SPA_Old_Basic_Summary.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_OS_SPA_Old_Basic_Summary.html' + '">'+ $VNXeHOstName + '_OS_SPA_Old_Basic_Summary' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $OSStats = $null
            $OSSPASummary = $null
            $OSSPASummary = Get-VNXeOldBasicSummaryStats 'os_spa'
            $OSStats = Get-OSStats -InputObject $OSSPASummary
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'OS SPA Old Basic Summary'
            $ImgFullPath = ($AbsChartPath + '\' + 'VNXe_OS_Old_Summary_SPA_Memory.png')
            New-PNGChart -YValues 'MemTotalKB,MemFree' -ChartType 'Line' -ChartTitle 'SPA Memory' -ChartFullPath $ImgFullPath -InputObject $OSStats | Out-Null
            Set-HTMLImage -Reportfile $ReportFile -imgsrc $ImgFullPath
            Set-HTMLReportSection -Stats $OSStats -YValues 'PercentCPUBusy,PercentCPUIdle,PercentCPUWait' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'SPA CPU' -AbsChartPath ($AbsChartPath + '\VNXe_OS_Old_Summary_SPA_CPU.png') -RelChartpath ($RelChartPath + '/VNXe_OS_Old_Summary_SPA_CPU.png')
            #endregion

            #region OS Old BasicSummary SPB
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_OS_SPB_Old_Basic_Summary.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_OS_SPB_Old_Basic_Summary.html' + '">'+ $VNXeHOstName + '_OS_SPB_Old_Basic_Summary' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $OSStats = $null
            $OSSPBSummary = $null
            $OSSPBSummary = Get-VNXeOldBasicSummaryStats 'os_spb'
            $OSStats = Get-OSStats -InputObject $OSSPBSummary
            $ImgFullPath = ($AbsChartPath + '\' + 'VNXe_OS_Old_Summary_SPB_Memory.png')
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'OS SPB Old Basic Summary'
            New-PNGChart -YValues 'MemTotalKB,MemFree' -ChartType 'Line' -ChartTitle 'SPB Memory' -ChartFullPath $ImgFullPath -InputObject $OSStats | Out-Null
            Set-HTMLImage -Reportfile $ReportFile -imgsrc $ImgFullPath
            Set-HTMLReportSection -Stats $OSStats -YValues 'PercentCPUBusy,PercentCPUIdle,PercentCPUWait' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'SPB CPU' -AbsChartPath ($AbsChartPath + '\VNXe_OS_Old_Summary_SPB_CPU.png') -RelChartpath ($RelChartPath + '/VNXe_OS_Old_Summary_SPB_CPU.png')
            
            #endregion
        

            #region Dart 2 Basic Default
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Dart2_Basic_Default.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Dart2_Basic_Default.html' + '">'+ $VNXeHOstName + '_Dart2_Basic_Default' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $DartStoreStats = $null
            $Dart2 = $null
            $Dart2 = Get-VNXeBasicDefaultStats 'dart2'
            $DartStoreStats = Get-DartStoreStats -InputObject $Dart2
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'Dart2 Basic Default'
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadsPerSec,StoreWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart2 Store IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Default_Store_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Default_Store_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadMBPerSec,StoreWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart2 Store Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Default_Store_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Default_Store_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NetInMBPerSec,NetOutMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart2 Network Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Default_Net_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Default_Net_Bandwidth.png')
            
            #endregion

            #region Dart 3 Basic Default
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Dart3_Basic_Default.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Dart3_Basic_Default.html' + '">'+ $VNXeHOstName + '_Dart3_Basic_Default' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $DartStoreStats = $null
            $Dart3 = $null
            $Dart3 = Get-VNXeBasicDefaultStats 'dart3'
            $DartStoreStats = Get-DartStoreStats -InputObject $Dart3
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'Dart3 Basic Default'
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadsPerSec,StoreWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart3 Store IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Default_Store_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Default_Store_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadMBPerSec,StoreWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart3 Store Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Default_Store_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Default_Store_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NetInMBPerSec,NetOutMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart3 Network Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Default_Net_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Default_Net_Bandwidth.png')
            
            #endregion
            
            #region Dart 2 Old Basic Default
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Dart2_Old_Basic_Default.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Dart2_Old_Basic_Default.html' + '">'+ $VNXeHOstName + '_Dart2_Old_Basic_Default' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $DartStoreStats = $null
            $Dart2 = $null
            $Dart2 = Get-VNXeOldBasicDefaultStats 'dart2'
            $DartStoreStats = Get-DartStoreStats -InputObject $Dart2
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'Dart2 Old Basic Default'
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadsPerSec,StoreWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart2 Store IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Default_Store_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Default_Store_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadMBPerSec,StoreWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart2 Store Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Default_Store_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Default_Store_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NetInMBPerSec,NetOutMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart2 Network Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Default_Net_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Default_Net_Bandwidth.png')
            
            #endregion

            #region Dart 3 Old Basic Default
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Dart3_Old_Basic_Default.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Dart3_Old_Basic_Default.html' + '">'+ $VNXeHOstName + '_Dart3_Old_Basic_Default' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $DartStoreStats = $null
            $Dart3 = $null
            $Dart3 = Get-VNXeOldBasicDefaultStats 'dart3'
            $DartStoreStats = Get-DartStoreStats -InputObject $Dart3
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'Dart3 Old Basic Default'
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadsPerSec,StoreWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart3 Store IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Default_Store_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Default_Store_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadMBPerSec,StoreWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart3 Store Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Default_Store_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Default_Store_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NetInMBPerSec,NetOutMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart3 Network Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Default_Net_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Default_Net_Bandwidth.png')
            
            #endregion


            #region Dart 2 Basic Summary
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Dart2_Basic_Summary.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Dart2_Basic_Summary.html' + '">'+ $VNXeHOstName + '_Dart2_Basic_Summary' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $DartStoreStats = $null
            $Dart2Summary = $null
            $Dart2Summary = Get-VNXeBasicSummaryStats 'dart2'
            $DartStoreStats = Get-DartStoreStats -InputObject $Dart2Summary
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'Dart 2 Basic Summary'
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadsPerSec,StoreWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Summary_Store_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Summary_Store_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadMBPerSec,StoreWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Summary_Store_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Summary_Store_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NetInMBPerSec,NetOutMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 Network Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Summary_Network_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Summary_Network_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'ISCSIReadsPerSec,ISCSIWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 iSCSI IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Summary_ISCSI_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Summary_ISCSI_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'ISCSIReadMBPerSec,ISCSIWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 iSCSI Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Summary_ISCSI_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Summary_ISCSI_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsActiveConnections,CifsTotalConnections' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 CIFS Connections' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_CIFS_Connections.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_CIFS_Connections.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsReadsPerSec,CifsWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 CIFS IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Summary_CIFS_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Summary_CIFS_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsReadMBPerSec,CifsWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 CIFS Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Summary_CIFS_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Summary_CIFS_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsActiveConnections' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 NFS Connections' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Summary_NFS_Connections.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Summary_NFS_Connections.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsReadsPerSec,NfsWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 NFS IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Summary_NFS_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Summary_NFS_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsReadMBPerSec,NfsWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 NFS Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Summary_NFS_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Summary_NFS_Bandwidth.png')
            
            #endregion

            #region Dart 3 Basic Summary
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Dart3_Basic_Summary.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Dart3_Basic_Summary.html' + '">'+ $VNXeHOstName + '_Dart3_Basic_Summary' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $DartStoreStats = $null
            $Dart3Summary = $null
            $Dart3Summary = Get-VNXeBasicSummaryStats 'dart3'
            $DartStoreStats = Get-DartStoreStats -InputObject $Dart3Summary
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'Dart 3 Basic Summary'
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadsPerSec,StoreWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_Store_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_Store_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadMBPerSec,StoreWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_Store_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_Store_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NetInMBPerSec,NetOutMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 Network Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_Network_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_Network_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'ISCSIReadsPerSec,ISCSIWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 iSCSI IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_ISCSI_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_ISCSI_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'ISCSIReadMBPerSec,ISCSIWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 iSCSI Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_ISCSI_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_ISCSI_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsActiveConnections,CifsTotalConnections' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 CIFS Connections' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_CIFS_Connections.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_CIFS_Connections.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsReadsPerSec,CifsWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 CIFS IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_CIFS_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_CIFS_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsReadMBPerSec,CifsWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 CIFS Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_CIFS_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_CIFS_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsActiveConnections' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 NFS Connections' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_NFS_Connections.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_NFS_Connections.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsReadsPerSec,NfsWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 NFS IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_NFS_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_NFS_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsReadMBPerSec,NfsWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 NFS Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Summary_NFS_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Summary_NFS_Bandwidth.png')
            
            #endregion

            #region Dart 2 Old Basic Summary
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Dart2_Old_Basic_Summary.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Dart2_Old_Basic_Summary.html' + '">'+ $VNXeHOstName + '_Dart2_Old_Basic_Summary' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $DartStoreStats = $null
            $Dart2Summary = $null
            $Dart2Summary = Get-VNXeOldBasicSummaryStats 'dart2'
            $DartStoreStats = Get-DartStoreStats -InputObject $Dart2Summary
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'Dart2 Old Basic Summary'
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadsPerSec,StoreWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Summary_Store_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_Store_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadMBPerSec,StoreWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Summary_Store_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_Store_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NetInMBPerSec,NetOutMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 Network Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Summary_Network_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_Network_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'ISCSIReadsPerSec,ISCSIWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 iSCSI IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Summary_ISCSI_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_ISCSI_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'ISCSIReadMBPerSec,ISCSIWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 iSCSI Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Summary_ISCSI_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_ISCSI_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsActiveConnections,CifsTotalConnections' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 CIFS Connections' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Summary_CIFS_Connections.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_CIFS_Connections.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsReadsPerSec,CifsWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 CIFS IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Summary_CIFS_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_CIFS_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsReadMBPerSec,CifsWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 CIFS Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Summary_CIFS_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_CIFS_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsActiveConnections' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 NFS Connections' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Summary_NFS_Connections.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_NFS_Connections.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsReadsPerSec,NfsWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 NFS IOPS' -AbsChartPath ($ChartPath + '\VNXe_Dart2_Old_Summary_NFS_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_NFS_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsReadMBPerSec,NfsWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 2 NFS Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart2_Old_Summary_NFS_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart2_Old_Summary_NFS_Bandwidth.png')
            
            #endregion

            #region Dart 3 Old Basic Summary
            $ReportFile = $ReportPath + '\' + $VNXeHOstName + '_Dart3_Old_Basic_Summary.html'
            '<tr><td><A target="main" href="' + $VNXeHOstName + '_Dart3_Old_Basic_Summary.html' + '">'+ $VNXeHOstName + '_Dart3_Old_Basic_Summary' + '</A></td></tr>' | Out-File -FilePath $MenuPage -append
            $DartStoreStats = $null
            $Dart3Summary = $null
            $Dart3Summary = Get-VNXeOldBasicSummaryStats 'dart3'
            $DartStoreStats = Get-DartStoreStats -InputObject $Dart3Summary
            Set-HTMLSectionHeader -Reportfile $ReportFile -SectionTitle 'Dart3 Old Basic Summary'
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadsPerSec,StoreWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_Store_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_Store_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'StoreReadMBPerSec,StoreWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_Store_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_Store_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NetInMBPerSec,NetOutMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 Network Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_Network_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_Network_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'ISCSIReadsPerSec,ISCSIWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 iSCSI IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_ISCSI_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_ISCSI_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'ISCSIReadMBPerSec,ISCSIWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 iSCSI Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_ISCSI_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_ISCSI_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsActiveConnections,CifsTotalConnections' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 CIFS Connections' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_CIFS_Connections.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_CIFS_Connections.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsReadsPerSec,CifsWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 CIFS IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_CIFS_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_CIFS_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'CifsReadMBPerSec,CifsWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 CIFS Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_CIFS_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_CIFS_Bandwidth.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsActiveConnections' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 NFS Connections' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_NFS_Connections.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_NFS_Connections.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsReadsPerSec,NfsWritesPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 NFS IOPS' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_NFS_IOPS.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_NFS_IOPS.png')
            Set-HTMLReportSection -Stats $DartStoreStats -YValues 'NfsReadMBPerSec,NfsWriteMBPerSec' -Reportfile $ReportFile -ChartType 'Line' -ChartTitle 'Dart 3 NFS Bandwidth' -AbsChartPath ($AbsChartPath + '\VNXe_Dart3_Old_Summary_NFS_Bandwidth.png') -RelChartpath ($RelChartPath + '/VNXe_Dart3_Old_Summary_NFS_Bandwidth.png')
            
            #endregion

        

        # Close Pages
        Set-HTMLDocumentEnd -Reportfile $HomePage
        Set-HTMLDocumentEnd -Reportfile $MenuPage  



#endregion
