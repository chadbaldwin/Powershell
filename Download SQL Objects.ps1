$sqlInstance = ""
$database = "";
$query = @"
SELECT y.ObjName, y.ObjSchema, x.FileNameAppend, x.Folder
	, FileHeader =
		'USE '+y.DBName+';'+y.CRLF
		+'GO'+y.CRLF
		+'IF OBJECT_ID('''+y.ObjSchema+'.'+y.ObjName+''') IS NOT NULL DROP '+x.DropType+' '+y.ObjSchema+'.'+y.ObjName+';'+y.CRLF
		+'GO'
	, ObjDef = y.ObjDef
FROM sys.objects o
	JOIN (VALUES ('P','StoredProcedure','StoredProcedures','PROCEDURE')
				,  ('FN','UserDefinedFunction','Functions\Scalar-valued Functions','FUNCTION')
				,  ('IF','UserDefinedFunction','Functions\Table-valued Functions','FUNCTION')
				,  ('TF','UserDefinedFunction','Functions\Table-valued Functions','FUNCTION')
				,  ('V','View','Views','VIEW')
				,  ('TR','Trigger','Triggers','TRIGGER')
	) x (TypeCode, FileNameAppend, Folder, DropType) ON o.[type] = x.TypeCode
	CROSS APPLY (SELECT	ObjName		= OBJECT_NAME(o.[object_id])
					,   ObjSchema	= OBJECT_SCHEMA_NAME(o.[object_id])
					,	DBName		= DB_NAME()
					,	ObjDef		= OBJECT_DEFINITION(o.[object_id])
					,	CRLF		= CHAR(13)+CHAR(10)
	) y
"@;

$result = Invoke-DbaQuery -SqlInstance $sqlInstance -Database $database -Query $query;

$result | % {
	$contents = $_.ObjDef;
	$contents = $contents.Trim("`r","`n"); # trim leading/traling newlines
	$contents = $_.FileHeader+"`r`n"+$contents; # add the header (drop create, etc)
	$contents = $contents+"`r`nGO"; # end the file with a GO
	
	# create the path where the file will go
	$newPath = ".\$($_.Folder)\$($_.ObjSchema).$($_.ObjName).$($_.FileNameAppend).sql";

	# write the file
	New-Item -Force -Path $newPath -Value $contents -ItemType File;
} | Out-Null;