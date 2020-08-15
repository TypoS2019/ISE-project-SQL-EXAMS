USE HAN_SQL_EXAM_DATABASE
GO
CREATE OR ALTER PROCEDURE pr_drop_ddl
@exam_db_name VARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @startTC INT = @@TRANCOUNT;
    DECLARE @savepoint VARCHAR(128) = CAST(OBJECT_NAME(@@PROCID) AS VARCHAR(125)) + CAST(@@NESTLEVEL AS VARCHAR(3));
    BEGIN TRY
        BEGIN TRANSACTION
            SAVE TRANSACTION @savepoint;
			IF(@exam_db_name IS NULL) THROW 60004, 'exam_db_name cannot be null', 1;

			IF(NOT EXISTS(SELECT 1 FROM EXAM_DATABASE WHERE exam_db_name = @exam_db_name))
			THROW 60157, 'The provided database name does not exist', 1;

            DECLARE @prep NVARCHAR(MAX) = N'DROP DATABASE IF EXISTS ' + @exam_db_name
            EXEC sp_executesql @prep

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @startTC = 0
            ROLLBACK TRANSACTION;
        ELSE
            IF XACT_STATE() = 1
                BEGIN
                    ROLLBACK TRANSACTION @savepoint;
                    COMMIT TRANSACTION;
                END;
        DECLARE @errormessage VARCHAR(2000) =
                'Error occured in sproc ''' + OBJECT_NAME(@@procid) + '''. Original message: ''' + ERROR_MESSAGE() +
                '''';
        THROW 50000, @errormessage, 1;
    END CATCH;
END