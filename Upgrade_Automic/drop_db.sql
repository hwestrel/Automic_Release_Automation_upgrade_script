
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'$(dbName)'
GO
USE [master]
GO
ALTER DATABASE [$(dbName)] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
USE [master]
GO
/****** Object:  Database $(dbName)]    Script Date: 2017-03-04 01:04:52 ******/
DROP DATABASE [$(dbName)]
GO