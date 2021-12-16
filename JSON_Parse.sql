declare @col nvarchar(max)
declare @p nvarchar(max)
declare @colName nvarchar(max)
declare @colType nvarchar(max)



select [colType]         = 
    CASE 
      WHEN tp.[name] IN ('varchar', 'char') THEN tp.[name] + '(' + IIF(c.max_length = -1, 'max', CAST(c.max_length AS VARCHAR(25))) + ')' 
      WHEN tp.[name] IN ('nvarchar','nchar') THEN tp.[name] + '(' + IIF(c.max_length = -1, 'max', CAST(c.max_length / 2 AS VARCHAR(25)))+ ')'      
      WHEN tp.[name] IN ('decimal', 'numeric') THEN tp.[name] + '(' + CAST(c.[precision] AS VARCHAR(25)) + ', ' + CAST(c.[scale] AS VARCHAR(25)) + ')'
      WHEN tp.[name] IN ('datetime2') THEN tp.[name] + '(' + CAST(c.[scale] AS VARCHAR(25)) + ')'
      ELSE tp.[name]
    END
	,[Name]         = c.[name]
into #Type
from sys.columns c
INNER JOIN sys.types tp
    ON tp.system_type_id = c.system_type_id
where OBJECT_ID=OBJECT_ID(@tableName)


SELECT 
   [key] as colName
into #Res
FROM OPENJSON (@jsonFile, '$[0]')



if (select count(r.colName)
from #Res as r
inner join #Type as t on r.colName = t.Name collate Ukrainian_CI_AS
where t.colType != 'sysname') > 0
begin
	declare my_cur CURSOR FOR
	select r.colName, t.colType
	from #Res as r
	inner join #Type as t on r.colName = t.Name collate Ukrainian_CI_AS
	where t.colType != 'sysname'
	
	open my_cur 
	fetch next from my_cur into 
									@colName
									,@colType
		while @@FETCH_STATUS = 0
		begin
		print('Ok')
			set @col = concat(@col, QUOTENAME(@colName), N',')
			set @p = concat(@p, CONCAT(QUOTENAME(@colName), N' '+ cast(@colType as nvarchar(max)) +' ''$."', @colName, '"'''), N',')
	
		fetch next from my_cur into 
									@colName
									,@colType
		end
		set @col = left(@col, len(@col)-1)
		set @p = left(@p, len(@p)-1)
	
		close my_cur
		deallocate my_cur
	
	declare @sql nvarchar(max) = 
	   'INSERT INTO [DB].[dbo].['+ @tableName +'] ('+ @col +') 
	   SELECT ' + @col +'
	   FROM OPENJSON('+''''+ @jsonFile +''''+')
	   WITH ('+ @p +')
	 '
	exec(@sql)
	
end
else if (select count(r.colName)
from #Res as r
inner join #Type as t on r.colName = t.Name collate Ukrainian_CI_AS
where t.colType != 'sysname') = 0
begin
	select 1
end

		if(OBJECT_ID('tempdb..#Res') Is Not Null)
	begin
	    drop table #Res
	end

		if(OBJECT_ID('tempdb..#Type') Is Not Null)
	begin
	    drop table #Type
	end