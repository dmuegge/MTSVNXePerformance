

# Load SQL Lite .Net Assembly
$AssemblyPath = "C:\Program Files\System.Data.SQLite\2010\bin\System.Data.SQLite.dll"
Add-Type -Path $AssemblyPath 




# Tables in capacity.db
# application_totals  init_time           pools
# applications        pool_totals         system_totals
# --------------------------------------------------------
# system_totals
#	timestamp            : 2011-05-03 23:59:15
#	closing_time         : 2011-05-03 23:59:15
#	allocated_space      : 0
#	total_space          : 0
#	free_space           : 0
#	allocated_protection : 0
#	total_protection     : 0
# --------------------------------------------------------
# Pools
#	pool_id         : performance
#	record_time     : 2011-09-25 23:37:40
#	timestamp       : 2011-09-25 23:37:40
#	closing_time    : 2011-09-26 00:00:00
#	used_space      : 0
#	allocated_space : 206971076608
#	total_space     : 939276632064
#	trend           : 4070162
# --------------------------------------------------------
# application_totals - Not used at this time
# --------------------------------------------------------
# init_time - Not used at this time
# --------------------------------------------------------
# applications - Not used at this time
# --------------------------------------------------------
# pool_totals - Not used at this time
# --------------------------------------------------------
	


function Get-TableDetail{

	[CmdletBinding()]
	param ( 
		[Parameter(Mandatory=$True)][string[]]$path, `
		[Parameter(Mandatory=$True)][string[]]$filename, `
		[Parameter(Mandatory=$True)][string[]]$tablename
	)
	
	# Get system totals information from capacity database
	$conn = New-Object -TypeName System.Data.SQLite.SQLiteConnection
	$connstring = "Data Source=" + $path + "\" + $filename 
	$conn.ConnectionString = $connstring
	$conn.Open()
	$command = $conn.CreateCommand()
	$sqltext = "select * from " + $tablename
	$command.CommandText = $sqltext
	$adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $command
	$dataset = New-Object System.Data.DataSet
	[void]$adapter.Fill($dataset)
	$tableinfo = $dataset.Tables[0].rows
	$conn.Close()
	
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
	$result	

}

#data table to hold results
Function out-DataTable 
{
  $dt = new-object Data.datatable  
  $First = $true  

  foreach ($item in $input){  
    $DR = $DT.NewRow()  
    $Item.PsObject.get_properties() | foreach {  
      if ($first) {  
        $Col =  new-object Data.DataColumn  
        $Col.ColumnName = $_.Name.ToString()  
        $DT.Columns.Add($Col)       }  
      if ($_.value -eq $null) {  
        $DR.Item($_.Name) = "[empty]"  
      }  
      elseif ($_.IsArray) {  
        $DR.Item($_.Name) =[string]::Join($_.value ,";")  
      }  
      else {  
        $DR.Item($_.Name) = $_.value  
      }  
    }  
    $DT.Rows.Add($DR)  
    $First = $false  
  } 

  return @(,($dt))

}

cls

$path = "C:\Users\dmuegge\Dropbox\Work\Analysis\Gray_Robinson\VNXe3300"
$filename = "capacity.db"
$tablename = "pools"


$dataTable = Get-TableDetail -path $path -filename $filename -tablename $tablename | out-DataTable
$connectionString = "Data Source=OBI-WAN; Integrated Security=True;Initial Catalog=GrayRob_VNXe;"
$bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $connectionString
$bulkCopy.DestinationTableName = "dbo.capacity"
$bulkCopy.WriteToServer($dataTable)