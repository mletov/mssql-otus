/*
	Создание очереди

	Цель:
	В этом ДЗ вы научитесь:

	использовать очередь
	настраивать сервер для работы с очередями
	писать скрипты для создания и настройки очереди

	Описание/Пошаговая инструкция выполнения домашнего задания:
	Создание очереди в БД для фоновой обработки задачи в БД.
	Подумайте и реализуйте очередь в рамках своего проекта.
	Если в вашем проекте нет задачи, которая подходит под реализацию через очередь, то в качестве ДЗ:
	Реализуйте очередь для БД WideWorldImporters:

	Создайте очередь для формирования отчетов для клиентов по таблице Invoices. При вызове процедуры для создания отчета в очередь должна отправляться заявка.
	При обработке очереди создавайте отчет по количеству заказов (Orders) по клиенту за заданный период времени и складывайте готовый отчет в новую таблицу.
	Проверьте, что вы корректно открываете и закрываете диалоги и у нас они не копятся.

	Критерии оценки:
	Статус "Принято" ставится, если создана очередь
*/



-- Процедура, создающая таблицу с отчетом поп ользвоателю за период
-- Возвращает имя таблицы, в которую сложилась выборка
-- Вызывается при получении сообщения
ALTER PROCEDURE CreateUserOrdersReport 
(
    @UserId INT
  , @DateBegin DATETIME
  , @DateEnd DATETIME
  , @TableName AS NVARCHAR(MAX) OUTPUT
)  
AS  
BEGIN
	DECLARE @Query NVARCHAR(MAX), @params NVARCHAR(MAX);
	SET @TableName = CONCAT('Reports_', CAST(@UserId AS NVARCHAR(MAX)), '_', Convert(CHAR(8),@DateBegin,112), '_', Convert(CHAR(8), @DateEnd, 112))
	SET @Query = N'
	
	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''' + @TableName + ''' AND TABLE_SCHEMA = ''dbo'')
    DROP TABLE [dbo].[' + @TableName + '];
	
	SELECT *
	INTO ' + @TableName + '
	FROM
	(
		SELECT	
		      OrderDate
			, COUNT(OrderDate) AS CountOrders
		FROM [WideWorldImporters].[Sales].[Orders]
		WHERE CustomerID = @UserId
		AND OrderDate BETWEEN CAST(@DateBegin AS DATETIME) AND CAST(@DateEnd AS DATETIME)
		GROUP BY OrderDate
	) AS t1';
	SET @params = N'@UserId INT, @DateBegin DATETIME, @DateEnd DATETIME';
	EXEC sp_executesql @Query, @params, @UserId = @UserId, @DateBegin = @DateBegin, @DateEnd = @DateEnd;
	
	SELECT @TableName
	--RETURN @TableName
END



DECLARE @TableName NVARCHAR(MAX)
EXEC CreateUserOrdersReport  813, '2012-01-01', '2012-12-01', @TableName
PRINT @TableName




USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER  WITH NO_WAIT; 

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];
   
   
--Create Message Types for Request and Reply messages
USE WideWorldImporters
-- For Request
CREATE MESSAGE TYPE
[//WWI/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML;
-- For Reply
CREATE MESSAGE TYPE
[//WWI/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 

GO

CREATE CONTRACT [//WWI/SB/Contract]
      ([//WWI/SB/RequestMessage]
         SENT BY INITIATOR,
       [//WWI/SB/ReplyMessage]
         SENT BY TARGET
      );
GO


-- Создание очереди
CREATE QUEUE TargetQueueWWI;

CREATE SERVICE [//WWI/SB/TargetService]
       ON QUEUE TargetQueueWWI
       ([//WWI/SB/Contract]);
GO


CREATE QUEUE InitiatorQueueWWI;

CREATE SERVICE [//WWI/SB/InitiatorService]
       ON QUEUE InitiatorQueueWWI
       ([//WWI/SB/Contract]);
GO   

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE SendNewReport
	@UserId INT
  , @DateBegin DATETIME
  , @DateEnd DATETIME
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN 

	--Prepare the Message
	SELECT @RequestMessage = '<RequestMessage><Report UserId="' + CAST(@UserId AS NVARCHAR(MAX)) + '" DateBegin="' + Convert(CHAR(8),@DateBegin,112) + '" DateEnd="' + Convert(CHAR(8),@DateEnd,112) + '" /></RequestMessage>'; 
	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//WWI/SB/InitiatorService]
	TO SERVICE
	'//WWI/SB/TargetService'
	ON CONTRACT
	[//WWI/SB/Contract]
	WITH ENCRYPTION=OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//WWI/SB/RequestMessage]
	(@RequestMessage);
	SELECT @RequestMessage AS SentRequestMessage;
	COMMIT TRAN 
END
GO
   
   
   
CREATE PROCEDURE GetNewReport
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@UserId INT,
		    @DateBegin DATETIME,
		    @DateEnd DATETIME,
			@xml XML; 
	
	BEGIN TRAN; 

	--Receive message from Initiator
	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.TargetQueueWWI; 

	SELECT @Message;

	SET @xml = CAST(@Message AS XML);

	SELECT 
			@UserId = R.Iv.value('@UserId','INT')
			, @DateBegin = R.Iv.value('@DateBegin','DATETIME')
			, @DateEnd = R.Iv.value('@DateEnd','DATETIME')
	FROM @xml.nodes('/RequestMessage/Report') as R(Iv);

	DECLARE @TableName NVARCHAR(MAX)
	EXEC CreateUserOrdersReport  @UserId, @DateBegin, @DateEnd, @TableName OUTPUT
	PRINT @TableName
	
	SELECT @Message AS ReceivedRequestMessage, @MessageType AS MessageType; 
	
	-- Confirm and Send a reply
	IF @MessageType=N'//WWI/SB/RequestMessage'
	BEGIN
 		SET @ReplyMessage =N'<ReplyMessage> Message received. Report table is ' + @TableName + ' </ReplyMessage>'; 
		--SET @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>';
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//WWI/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; 

	COMMIT TRAN;
END   
   
   
CREATE PROCEDURE ConfirmReport
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueueWWI; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; 

	COMMIT TRAN; 
END
   
   
--Send message
EXEC SendNewReport 
	@UserId = 813, 
	@DateBegin = '2012-01-01', 
	@DateEnd = '2020-12-01'

SELECT CAST(message_body AS XML),*
FROM dbo.TargetQueueWWI;

SELECT CAST(message_body AS XML),*
FROM dbo.InitiatorQueueWWI;

--Target
EXEC GetNewReport;

--Initiator
EXEC ConfirmReport;  