USE master
GO
ALTER DATABASE $(dbName)_bak
SET SINGLE_USER 
WITH ROLLBACK IMMEDIATE
GO
EXEC master..sp_renamedb '$(dbName)_bak','$(dbName)'
GO
ALTER DATABASE $(dbName)
SET MULTI_USER 
GO

