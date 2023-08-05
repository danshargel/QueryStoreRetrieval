USE [DBAdmin]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER   PROCEDURE [dbo].[uspQSFind]
    @vcDBName VARCHAR(100),
    @vcUSPName VARCHAR(100),
    @vcUSPSchema VARCHAR(100) = 'dbo',
    @vcUSPStatement VARCHAR(100) = '',
    @iQueryID INT = NULL,
    @iDaysBack INT = NULL,
    @vcOrderBy VARCHAR(100) = 'exectime', --@vcOrderBy must be "exectime" or "queryid" or "avgduration"
    @vcTimeZone VARCHAR(100) = 'Mountain Standard Time',
    @bOutputQry BIT = 0
AS
SET NOCOUNT ON;


----------------------------------------------------------
-- Validate a few of the parameters passed in
----------------------------------------------------------
DECLARE @vcVarErr VARCHAR(1000) = '';

IF @vcOrderBy NOT IN ( 'exectime', 'queryid', 'avgduration' )
BEGIN
    SELECT @vcVarErr
        = @vcOrderBy + ' is invalid. The value of @vcOrderBy must be "exectime" or "queryid" or "avgduration"';
    PRINT @vcVarErr;
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @vcDBName)
BEGIN
    SELECT @vcVarErr = @vcDBName + ' @vcDBName does not exist on this SQL instance';
    PRINT @vcVarErr;
    RETURN;
END;

----------------------------------------------------------
-- Default to 7 days if nothing passed in
----------------------------------------------------------
SELECT @iDaysBack = ISNULL(@iDaysBack, 7);



DECLARE @vcSQLSelect VARCHAR(3000)
    = '

SELECT TOP 1000 t.query_sql_text,
       q.query_id,
       p.plan_id,
       s.last_execution_time AT TIME ZONE ''UTC'' AT TIME ZONE ''' + @vcTimeZone
      + ''' AS last_execution_time,
       sch.name + ''.'' + usp.name AS parent_object,
	   --usp.name AS parent_object,
       query_plan,
       count_executions,
       ROUND(avg_duration / 1000, 2) AS avg_durationms,
       last_duration / 1000 AS last_durationms,
       min_duration / 1000 AS min_durationms,
       max_duration / 1000 AS max_durationms,
       ROUND(avg_logical_io_reads, 2) AS avg_logical_io_reads,
       last_logical_io_reads,
       min_logical_io_reads,
       max_logical_io_reads,
       ROUND(avg_physical_io_reads, 2) AS avg_physical_io_reads,
       last_physical_io_reads,
       min_physical_io_reads,
       max_physical_io_reads,
       avg_logical_io_writes,
       avg_query_max_used_memory,
       ROUND(avg_rowcount, 2) AS avg_rowcount,
       last_rowcount,
       min_rowcount,
       max_rowcount,
       avg_tempdb_space_used,
       query_hash,
	   p.is_forced_plan,
       p.force_failure_count,
       p.plan_forcing_type_desc,
	          q.last_compile_start_time AT TIME ZONE ''UTC'' AT TIME ZONE ''' + @vcTimeZone
      + ''' AS last_compile_start_time

  FROM ' + @vcDBName + '.sys.query_store_query_text t
  JOIN ' + @vcDBName + '.sys.query_store_query q
    ON t.query_text_id = q.query_text_id
  JOIN ' + @vcDBName + '.sys.query_store_plan p
    ON q.query_id      = p.query_id
  JOIN ' + @vcDBName + '.sys.query_store_runtime_stats s
    ON p.plan_id       = s.plan_id
  JOIN ' + @vcDBName + '.sys.procedures usp
   ON q.object_id = usp.object_id
  JOIN ' + @vcDBName + '.sys.schemas sch
   ON usp.schema_id = sch.schema_id
';


DECLARE @vcSQLWhere VARCHAR(500);

IF @iQueryID IS NULL
BEGIN
    SELECT @vcSQLWhere = ' WHERE usp.Name = ''' + @vcUSPName + '''
  AND t.query_sql_text LIKE ' + '''%' + @vcUSPStatement + '%''' + ' 
  AND sch.name = '''     + @vcUSPSchema + '''
  ' ;
END;
ELSE
BEGIN
    SELECT @vcSQLWhere = 'WHERE q.query_id = ' + CAST(@iQueryID AS VARCHAR(20)) + '
'   ;
END;

SELECT @vcSQLWhere
    = @vcSQLWhere + ' AND s.last_execution_time >= DATEADD(dd, -' + CAST(@iDaysBack AS VARCHAR(5)) + ', GetDate())
';


DECLARE @vcSQLOrder VARCHAR(500);

IF @vcOrderBy = 'exectime'
BEGIN
    SELECT @vcSQLOrder = 'ORDER BY s.last_execution_time DESC;';
END;

IF @vcOrderBy = 'queryid'
BEGIN
    SELECT @vcSQLOrder = 'ORDER BY q.query_id, p.plan_id;';
END;


IF @vcOrderBy = 'avgduration'
BEGIN
    SELECT @vcSQLOrder = 'ORDER BY avg_duration DESC;';
END;



DECLARE @vcSQL VARCHAR(MAX) = @vcSQLSelect + @vcSQLWhere + @vcSQLOrder;

IF @bOutputQry = 1
    PRINT @vcSQL;

EXEC (@vcSQL);
GO


