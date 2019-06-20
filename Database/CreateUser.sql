-- correct database 
use TombolaDB
-- check if user exists 
if not exists (select * from sys.database_principals where name = 'TombolaAdmin')
-- begin if 
begin 
     -- create user 
	 create user TombolaAdmin for login TombolaAdmin 
	 -- rights for AppConnections 
	 grant select, insert, update, delete on dbo.AppConnections to TombolaAdmin 
	 -- rights for FaceBookConnections
	 grant select, insert, update, delete on dbo.FaceBookConnections to TombolaAdmin 
	 -- rights for Items
	 grant select, insert, update, delete on dbo.Items to TombolaAdmin 
	 -- rights for Messages
	 grant select, insert on dbo.Messages to TombolaAdmin 
	 -- rights for Messages
	 grant select, insert, delete on dbo.Profits to TombolaAdmin
	 -- rights for Texts
	 grant select, insert, delete, update on dbo.Texts to TombolaAdmin
	 -- rights for TransactionTable
	 grant select, insert, delete, update on dbo.TransactionTable to TombolaAdmin
	 -- rights for Users
	 grant select, insert, delete, update on dbo.Users to TombolaAdmin
	 -- rights for WinnerTable
	 grant select, insert, delete, update on dbo.WinnerTable to TombolaAdmin
	 -- rights for AppUsers
	 grant select on dbo.AppUsers to TombolaAdmin
	 -- rights for FacebookUsers
	 grant select on dbo.FacebookUsers to TombolaAdmin
	 -- rights for MessageWinners
	 grant select on dbo.MessageWinners to TombolaAdmin
	 -- rights for profitsInMoneyValue
	 grant select on dbo.profitsInMoneyValue to TombolaAdmin
	 -- rights for TextPerLanguage
	 grant select on dbo.TextPerLanguage to TombolaAdmin
	 -- rights for procedure 
	 grant execute on dbo.AddUser to TombolaAdmin
	 -- rights for procedure 
	 grant execute on dbo.CheckAmount to TombolaAdmin
	 -- rights for procedure 
	 grant execute on dbo.ChoseRandomWinner to TombolaAdmin
	 -- rights for procedure 
	 grant execute on dbo.ConfirmPayment to TombolaAdmin
	 -- rights for procedure 
	 grant execute on dbo.ModifyTransaction to TombolaAdmin
         -- rights for procedure 
	 grant execute on dbo.CalculateProfit to TombolaAdmin
-- end if 
end