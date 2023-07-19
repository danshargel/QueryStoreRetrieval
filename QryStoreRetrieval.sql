
SELECT t.query_sql_text,
	   q.query_id,
	   p.plan_id,
	   p.is_forced_plan,
	   p.force_failure_count,
	   p.plan_forcing_type_desc,
	   s.last_execution_time AT TIME ZONE 'UTC' AT TIME ZONE 'Mountain Standard Time' AS last_execution_time,
	   q.last_compile_start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Mountain Standard Time' AS last_compile_start_time,
	   OBJECT_NAME(q.object_id) AS parent_object,
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
	   q.initial_compile_start_time,
	   q.last_compile_start_time
FROM sys.query_store_query_text t
	JOIN sys.query_store_query q
		ON t.query_text_id = q.query_text_id
	JOIN sys.query_store_plan p
		ON q.query_id = p.query_id
	JOIN sys.query_store_runtime_stats s
		ON p.plan_id = s.plan_id
WHERE OBJECT_NAME(q.object_id) = '<PROCEDURE NAME>'
-- and q.query_id = <QueryID IF You Know It>
--	  AND
--	  (
--		  t.query_sql_text LIKE '%%'
--		 -- OR t.query_sql_text LIKE '%%'
--	  )
--ORDER BY s.last_execution_time DESC;
ORDER BY q.query_id,
		 p.plan_id;