requires -Version 3.0 
#Assume sql server SMO is installed, https://msdn.microsoft.com/en-us/library/ms162189(v=sql.110).aspx
add-type -AssemblyName "Microsoft.SQLServer.Smo, Version=11.0.0.0, Culture=Neutral, PublicKeyToken=89845dcd8080cc91";
add-type -AssemblyName "Microsoft.SQLServer.SmoExtended, Version=11.0.0.0, Culture=Neutral, PublicKeyToken=89845dcd8080cc91";

[boolean] $debug =$true; # $true = print out the t-sql; $false = execute the restore

[string] $bkup_folder = 'c:\Backup\*' #the folder where the backup files are located. Can be a network share
[string] $sql_instance = 'TP_W520'; #this is the destination sql instance where the restore will occur. Change it to your own.

[string[]]$src_db= 'AdventureWorks2012', 'AdventureWorksDW2012', 'TestDB'; ; #src db list, separated by comma
[string[]]$dest_db= 'AdventureWorks2012', 'AdventureWorksDW2012', 'TestDB2'; #dest db can have different name

#This Save-DataTable is used to write a datatable into a sql server table
function Save-DataTable {
    param ( [parameter(Mandatory=$true)]
        [string] $SQLInstance,

        [parameter (Mandatory=$true)] [System.Data.DataTable]$SourceDataTable,

        [parameter (mandatory=$true)] [string] $DestinationDB,   

        [parameter (mandatory=$true)]
        [string] $DestinationTable,  # can be two-part naming convention, i.e. [schema_name].[table_name]

        [hashtable] $ColumnMapping=@{}
    )
    try {
            $conn = New-Object System.Data.SqlClient.SqlConnection ("Server=$SQLInstance; Database=$DestinationDB; trusted_connection=TRUE");
            $conn.Open();
            $bulkcopy = New-Object System.Data.SqlClient.SqlBulkCopy($conn);
 
            $bulkcopy.DestinationTableName=$DestinationTable; #you may change to your own table

            if ($ColumnMapping.count -gt 0) {
                $ColumnMapping.keys | % {$bc_mapping = new-object System.Data.SqlClient.SqlBulkCopyColumnMapping($_, $ColumnMapping[$_]); $bulkcopy.ColumnMappings.Add($bc_mapping); } | Out-Null;
            }# mapping columns needed

            $bulkcopy.WriteToServer($SourceDataTable);
    }
    catch {
        Write-Error $error[0].Message;
    }
    finally {
        $conn.Close();
    }
    return;
} # Save-DataTable


[string] $machine = $sql_instance.split('\')[0];

if ($src_db.Count -ne $dest_db.Count) {
    write-error 'source dbs mismatch destination dbs';
    return;
}

$srv = New-Object "microsoft.sqlserver.management.smo.Server" $sql_instance;
$rs = new-object "microsoft.sqlserver.management.smo.restore";


# make sure the $dest_db exists on the $sql_instance
$dest_db | 
% {
    if ($_ -notin $srv.databases.name) {
        Write-Error "The destination db [$_] does not exist on [$sql_instance], please create it first"; 
        break;
    }
}


## we first create a src-dest db name referece table, which will be deleted at the end of the script
[string]$qry = @"
if object_id('dbo.tblDB_Ref') is not null
    drop table dbo.tblDB_Ref;
create table dbo.tblDB_Ref
( Src_DBName varchar(60)
,  Dest_DBName varchar(60)
)
"@;

$srv.Databases['tempdb'].ExecuteNonQuery($qry);

#create a DataTable

$dt = new-object "system.data.DataTable";
$c = new-object "System.Data.DataColumn"('Src_DBName', [System.String]);
$dt.Columns.Add($c);
$c = new-object "System.Data.DataColumn"('Dest_DBName', [System.String]);
$dt.Columns.Add($c);

0..($src_db.count -1) | 
% {
    $r = $dt.NewRow();
    $r.Src_DBName= $src_db[$_];
    $r.Dest_DBName = $dest_db[$_];
    $dt.Rows.Add($r);
}

$col_mapping = @{};
$col_mapping.Add('Src_DBName','Src_DBName'); # in the format of (sourceColumn, destinationColumn)
$col_mapping.Add('Dest_DBName','Dest_DBName');

Save-DataTable -SQLInstance $sql_instance -SourceDataTable $dt -DestinationDB 'tempdb' -DestinationTable 'dbo.tblDB_Ref' -ColumnMapping $col_mapping;

[string]$dest_db_list ="'"+ [System.string]::join("','", $dest_db) + "'";

[string]$qry = @"
select DBName=db_name(database_id), LogicalName=name
, Physical_name
, Size=size*cast(8*1024 as bigint)
, FileType = case [type] when 0 then 'D' else 'L' end  
from master.sys.master_files
where db_name(database_id) in ($dest_db_list)
"@;

$ds = $srv.Databases['master'].ExecuteWithResults($qry);

$dt = $ds.Tables[0];


$qry = @"
if object_id('dbo.tblDB_Info') is not null
    drop table dbo.tblDB_Info;
create table dbo.tblDB_Info
( DBName varchar(60)
, LogicalName varchar(60)
, PhysicalName varchar(256)
, FileType char(1)
, Size bigint)
"@;

$srv.Databases['tempdb'].ExecuteNonQuery($qry);

$col_mapping = @{};
$col_mapping.Add('DBName','DBName'); # in the format of (sourceColumn, destinationColumn);
$col_mapping.Add('Physical_Name','PhysicalName');

$col_mapping.Add('LogicalName','LogicalName');
$col_mapping.Add('Size','Size');

$col_mapping.Add('FileType','FileType');

Save-DataTable -SQLInstance $sql_instance -SourceDataTable $dt -DestinationDB 'tempdb' -DestinationTable 'dbo.tblDB_Info' -ColumnMapping $col_mapping;


$dt = new-object "system.data.DataTable";
$c = new-object "System.Data.DataColumn"('DBName', [System.String]);
$dt.Columns.Add($c);

$c = new-object "System.Data.DataColumn"('LogicalName', [System.String]);
$dt.Columns.Add($c);

$c = new-object "System.Data.DataColumn"('BkupFile', [System.String]);
$dt.Columns.Add($c);

$c = new-object "System.Data.DataColumn"('FileType', [System.String]); # 'D' = Data File; 'L'= Log File
$dt.Columns.Add($c); 

$c = new-object "System.Data.DataColumn"('Size', [System.Int64]);
$dt.Columns.Add($c);


dir -path $bkup_folder -Include *.bak | 
% { 
    $rs.devices.AddDevice($_.fullname,[Microsoft.SqlServer.Management.Smo.DeviceType]::File );
    [string]$dbname = ($rs.ReadBackupHeader($srv)).databaseName;
    [string]$bkup_file = $_.FullName;
    $rs.ReadFileList($srv) | 
    % { 
        $r = $dt.NewRow(); 
        $r.DBName = $dbname;
        $r.LogicalName = $_.LogicalName; 
        $r.BkupFile =$bkup_file; 
        $r.size = $_.size; 
        $r.FileType = $_.Type;
        $dt.rows.Add($r);
    };
    $rs.Devices.RemoveAt(0);
}

$qry = @"
if object_id('dbo.tblBkup_Info') is not null
    drop table dbo.tblBkup_Info;
create table dbo.tblBkup_Info
( DBName varchar(60)
, LogicalName varchar(60)
, BkupFile varchar(200)
, FileType char(1)
, Size bigint)
"@;
$srv.Databases['tempdb'].ExecuteNonQuery($qry);

$col_mapping = @{};
$col_mapping.Add('DBName','DBName'); # in the format of (sourceColumn, destinationColumn)

$col_mapping.Add('LogicalName','LogicalName');
$col_mapping.Add('BkupFile','BkupFile');
$col_mapping.Add('Size','Size');
$col_mapping.Add('FileType','FileType');
 
Save-DataTable -SQLInstance $sql_instance -SourceDataTable $dt -DestinationDB 'tempdb' -DestinationTable 'dbo.tblBkup_Info' -ColumnMapping $col_mapping;

# create a disk info table
$qry = @"
if object_id('dbo.tblDisk_Info') is not null
    drop table dbo.tblDisk_Info;
create table dbo.tblDisk_Info
( Drive varchar(60)
, Size bigint
, FreeSpace bigint
)
"@;
$srv.Databases['tempdb'].ExecuteNonQuery($qry);

$dt = new-object "system.data.DataTable";
$c = new-object "System.Data.DataColumn"('DriveName', [System.String]);
$dt.Columns.Add($c);

$c = new-object "System.Data.DataColumn"('DiskSize', [System.Int64]);
$dt.Columns.Add($c);
$c = new-object "System.Data.DataColumn"('FreeSpace', [System.Int64]);
$dt.Columns.Add($c);


gwmi -class win32_volume -ComputerName $machine | 
? { ($_.name -match '^\w.+') -and ($_.Capacity -gt 0)} | 
SELECT NAME, Capacity, FreeSpace  |
% { 
    $r = $dt.NewRow();
    $r.DriveName = $_.name;
    $r.DiskSize = $_.capacity;
    $r.FreeSpace=$_.FreeSpace;
    $dt.Rows.Add($r);
}


#dump $dt to dbo.tblDisk_Info
$col_mapping = @{};
$col_mapping.Add('DriveName','Drive'); # in the format of (sourceColumn, destinationColumn)

$col_mapping.Add('DiskSize','Size');
$col_mapping.Add('FreeSpace','FreeSpace');

Save-DataTable -SQLInstance $sql_instance -SourceDataTable $dt -DestinationDB 'tempdb' -DestinationTable 'dbo.tblDisk_Info' -ColumnMapping $col_mapping;

#we need to check whether the [disk free space] + [existing db occupied space] > [the needed space for the restore]
[string]$qry = @"
-- in a folder we may have lots backup files for many different dbs
-- while we may use only a few of them for the restore.
-- Since we scanned all backup files, we have to delete those that are not used
delete from b
from dbo.tblBkup_info b
where dbname not in ( select src_dbname from dbo.tblDB_Ref)


-- CTE c will link [PhysicalName] with [Drive]
-- c1 will get the real drive for each PhysicalName using [ml] (which is max(len(d.drive))
-- at the end, we need to make sure any drive that has [Space_After_Restore] column to be positive
-- if [Space_After_Restore] > 0, it means there is no enough space
; with c as (
select db.DBname, db.LogicalName, db.physicalname, NewFileSize=b.Size, db.size, ml=max(len(d.drive)) 
from dbo.tblDB_info db
inner join dbo.tblDisk_info d
on db.physicalname like (d.drive + '%')
inner join dbo.tblDB_Ref r
on r.Dest_DBName=db.DBName
inner join dbo.tblBkup_Info b
on b.DBName = r.Src_DBName
and b.LogicalName = db.LogicalName
group by db.DBName, db.LogicalName, db.PhysicalName, b.size, db.size
) 
, c1 as (
select  d.drive, FreeSpace_MB=d.FreeSpace/1024/1024, NeededSpace_MB=sum(c.NewFileSize)/1014/1024
, ExistingSpace_MB=sum(c.size)/1024/1024
from c
inner join dbo.tblDisk_info d
on c.physicalName like (d.drive + '%')
and c.ml = len(d.Drive) 
group by d.drive, d.FreeSpace
) select drive, Space_After_Restore=freeSpace_mb+ExistingSpace_MB - NeededSpace_mb 
from c1;
"@


$ds = $srv.Databases['tempdb'].ExecuteWithResults($qry);

$dt = $ds.Tables[0];

# loop through each row (each row contains one unique disk drive) and see whether there is any space left after restore
# if the value is negative, it means no space left, and thus should return error and exit
foreach ($r in $dt.rows)
{
    if ($r.Space_After_Restore -lt 0)
    {
        Write-Error "The drive [$($r.Drive)] does not have enough space, it lacks [$($r.Space_After_Restore)] MB free space."; 
        if (-not $debug)
        { return; }
    }
}

# if disk freespace is OK,we can proceed with the restore

$qry = @"
declare @sqlcmd varchar(max), @crlf char(2)=char(0x0d) + char(0x0a);
declare @db varchar(100), @bkupfile varchar(200);
declare @sqlcmd2 varchar(max)='';

declare curD cursor for
select distinct DBName=r.Dest_DBName, BkupFile 
from dbo.tblBkup_Info b
inner join dbo.tblDB_Ref r
on r.Src_DBName = b.DBName
; 
open curD;
fetch next from curD into @db, @bkupfile;
while (@@fetch_status = 0)
begin
 set @sqlcmd ='';

 select @sqlcmd = @sqlcmd + 'move ''' + d.logicalName + ''' to ''' + d.PhysicalName + ''',' + @crlf
 from dbo.tblDB_Info d
 where d.dbname=@db;
 set @sqlcmd = 'restore database ' + @db + ' from disk = ''' + @bkupfile + ''' ' + @crlf + 'with ' + @sqlcmd + 'replace;' + @crlf;
 set @sqlcmd2 = @sqlcmd2 + @sqlcmd;
 fetch next from curD into @db, @bkupfile;
 
end
close curD;
deallocate curD;
select SQLCMD = @sqlcmd2;
"@;
$ds = $srv.Databases['tempdb'].ExecuteWithResults($qry);

[string]$sqlcmd= $ds.Tables[0].rows[0].sqlcmd;

if ($debug)
{ write-output "-- the restore script is: `r`n$($sqlcmd)";
}
else
{
  $srv.Databases['master'].ExecuteNonQuery($sqlcmd);
}

## cleanup the temp tables
$qry = @"
if object_id('dbo.tblDB_Ref') is not null
    drop table dbo.tblDB_Ref;

if object_id('dbo.tblDB_Info') is not null
    drop table dbo.tblDB_Info;

if object_id('dbo.tblDisk_Info') is not null
    drop table dbo.tblDisk_Info;

if object_id('dbo.tblBkup_Info') is not null
    drop table dbo.tblBkup_Info;
"@;
$srv.databases['tempdb'].ExecuteNonQuery($qry);