-- next lot
go
---------------<use master to drop TombolaDB>---------------
use master
---------------<drop database if not exits>-----------------
if DB_ID('TombolaDB') is not null drop database TombolaDB
---------------<create database if  exits>------------------
if DB_ID('TombolaDB') is null create database TombolaDB
---------------<start using principal database>-------------
use TombolaDB
---------------<Create app User table>----------------------
create table AppConnections
(
Id int not null primary key identity,
Name varchar(50) not null, 
Email varchar(100) not null unique, 
Password varchar(300) not null,
AccessToken varchar(300) not null unique,
)
---------------<Create app FaceBook table>----------------------
create table FaceBookConnections
(
Id int not null primary key identity,
FbId varchar(max) not null,
AccessToken varchar(300) not null unique
)
---------------<Create user table>--------------------------
create table Users 
(
Id int not null primary key identity,
Amount money not null default 0,
AvailableAmount money not null default 0, 
IdAppUserConnection int null foreign key references AppConnections(Id), 
IdFaceBookUserConnection int null foreign key references FaceBookConnections(Id),
Validated bit default 0,
check(Amount >=0 and AvailableAmount >=0),
check(Amount >= AvailableAmount)
)
---------------<Create items table>--------------------------
create table Items
(
Id int not null primary key identity, 
Name varchar(50) not null, 
Description text not null,
Raffler int foreign key references Users(Id) null,
RafflePrice money not null,
CurrentAmount money default 0,
Terminated bit default 0,
Deleted bit default 0,
check(RafflePrice > 0 and CurrentAmount >= 0)
)
---------------<Create transaction table>--------------------------
create table TransactionTable
(
Id int not null primary key identity, 
ItemId int not null foreign key references Items(Id),
Donor  int null foreign key references Users(Id),
Amount money not null,
Status char default null,
unique(Id,ItemId,Donor, Status), 
check(Amount > 0),
check (Status is null or Status = 'r' or Status = 'd' or Status = 'w')
)
---------------<Create Winner table>--------------------------
create table WinnerTable
(
Id int not null primary key identity, 
ItemId int not null foreign key references Items(Id),
Winner int null foreign key references Users(Id),
Confirmed bit default 0,
unique(ItemId)
)
---------------<Create Messages table>--------------------------
create table Messages
(
Id int not null primary key identity, 
Sender int not null foreign key references Users(Id),
Receiver int not null foreign key references Users(Id),
Message text not null
)
-------------<table for texts>-------------
create table Texts
(
Id int not null primary key identity, 
Language varchar(2) not null, 
Text text not null
)
-------------<table for profits>-------------
create table Profits
(
ItemId int not null primary key foreign key references Items(Id),
Percentage varchar(3) not null, 
check(RIGHT(Percentage,1) = '%')
)
-- next lot 
go 
-------------------------------<function to calculate profit based on a percentage>-------------------------------
create or alter function CalculateProfit(@itemId int, @percentage varchar(3)) returns money as 
-- begin function 
begin
-- check if item does not exists
if not exists (select * from Items where Id = @itemId) return 0.00 
-- else 
else
    -- begin else  
    begin 
	-- get raffle price 
	declare @price money = (select RafflePrice from Items where Id = @itemId)
	-- create int 
	declare @percentageInt int
	-- if length == 3
	if len(@percentage) = 3  set @percentageInt = convert(int,substring(@percentage,1,2))
	-- if length == 2 
	if len(@percentage) = 2  set @percentageInt = convert(int,substring(@percentage,1,1))
	-- if length == 1
	if len(@percentage) = 1 return 0.00
	-- return profit
	return convert(money,round((@price / 100) * @percentageInt ,2))
	-- end else 
	end  
-- return 0.00 if error
return 0.00 
-- end function
end 
-- next lot 
go 
-------------------------------<View to get TransactionTable With Raffler>------------------
create view TransactionTableWithRaffler as select T.Id, I.Raffler,T.Donor,T.ItemId, T.Amount, T.Status  from TransactionTable T join Items I on T.ItemId = I.Id 
-- next lot 
go  
-------------------------------<View to get number of text per language>------------------
create view TextPerLanguage as select Language, Text, ROW_NUMBER() over( partition by Language Order by Language) as LanguageNumber from Texts 
-- next lot 
go 
-------------------------------<View to get facebook users>-------------------------------
create view FacebookUsers as select u.Id, u.Amount, u.AvailableAmount, f.AccessToken from  Users u join FaceBookConnections f on f.Id = u.IdFaceBookUserConnection 
-- next lot 
go 
-------------------------------<View to get real app users>-------------------------------
create view AppUsers as select u.Id, u.Amount, u.AvailableAmount, a.Name, a.Email, a.Password, a.AccessToken from  Users u join AppConnections a on a.Id = u.IdAppUserConnection
-- next lot
go
-------------------------------<View to get winner and donor at same record>-------------------------------
create view MessageWinners as select W.Id, W.ItemId, W.Winner,I.Raffler from WinnerTable W join Items I on W.ItemId = I.Id
-- next lot
go
-------------------------------<View to get profit in money value>-------------------------------
create view profitsInMoneyValue as select p.ItemId, p.Percentage, dbo.CalculateProfit(p.ItemId,p.Percentage) as profit from Profits p
-- next lot
go
-------------------------------<procedure to send money after item has been won>-------------------------------
-- return -1 == item does not exists
create or alter procedure ConfirmPayment(@itemId int) as 
-- begin procedure
begin
-- check if item exists 
if not exists (select * from Items where Id = @itemId) return -1
-- get total of sum from payments 
declare @totalSum  money = (select sum(Amount) from TransactionTable where ItemId = @itemId)
-- get rafflePrice from item
declare @totalItem money = (select RafflePrice from Items where Id = @itemId)
-- check if total equals amount of item
if @totalItem = @totalSum 

-- begin if
begin
           -- begin try block
           begin try
		   -- begin transaction block 
		   begin transaction
		   ---- create id Int 
           declare @id int 
		   ---- create cursors 
           declare db_cursor cursor local for select id from TransactionTable where ItemId = @itemId
		   ---- open cursor 
           open db_cursor  
		   ---- get first entry 
           fetch next from db_cursor into @id  
           ---- loop trough cursor 
           while @@FETCH_STATUS = 0  
		   ---- begin while 
           begin 
		   -- get amount 
		   declare @amount money = (select Amount from TransactionTable where Id =@id)
		   -- get donor 
		   declare  @donor int = (select Donor from TransactionTable where Id = @id)
		   -- update users table 
		   update Users set Amount = Amount - @amount where Id =  @donor
		   -- get next entry 
           fetch next from db_cursor into @id 
		   ---- end while 
           end
		   -------------------<To be continued>-------------------
		   -- get raffler 
		   declare @raffler int = (select Raffler from Items where Id = @itemId)
		   -- get profit 
		   declare @profit money
		   -- percentage 
		   declare @percentage varchar(3) =  '10%'
		   -- get profit 
		   exec @profit = dbo.CalculateProfit @itemId, @percentage
		   -- insert into profit if not exists 
	       if not exists (select * from Profits where ItemId = @itemId) insert into Profits values (@itemId,@percentage)
		   -- update saldo amount 
		   update Users set Amount = Amount + @totalSum, AvailableAmount = AvailableAmount + @totalSum where Id = @raffler
		   -- commit sql 
		   commit 
	       -- end try block 
	       end try 
		   -- rollback
		   begin catch rollback  raiserror('Error while throwing money away from userAccounts, very weird error !',16,1)   end catch
		   -- erase profit
		   update Users set Amount = Amount - @profit, AvailableAmount = AvailableAmount - @profit where Id = @raffler
		   -- update winner table 
		   update WinnerTable set Confirmed = 1 where ItemId = @itemId
		   -- update 
		   update TransactionTable set Status = 'w' where ItemId = @itemId
-- end if 
end 
-- raise weird error
else raiserror('Total of payments should be equal to itemRafflePrice, very weird error !',16,1) 
-- end procedure 
end 
-- next lot
go
----------------------------<procedure to add a user in system>--------------------------
-- return  0 == user correctly created  
-- return -1 == not a correct UserType 
-- return -2 == user chose for app user and didn't give username, password, email
-- return -4 == facebookId is null and shouldn't be null
-- return -5 == User already exists 
create or alter procedure AddUser(@AccessToken varchar(300), @UserType char, @Username varchar(50) = null, @Email varchar(100) = null, @Password varchar(300) = null, @FacebookId varchar(300) = null) as
-- begin procedure 
begin
-- check for UserType 
if @UserType != 'f' and @UserType != 'a' return -1 
-- if app user
if @UserType = 'a' 
-- begin if
begin 
     -- check if user already exists 
     if exists (select * from AppConnections where Email = @Email)  return -5
     -- check if credentials are correct 
     if @Username is null or @Email is null or @Password is null return -2 
	 -- if not insert into appUsers 
	 else insert into AppConnections values (@Username, @Email, @Password, @AccessToken)
	 -- return good signal
	 return 0
-- end if    
end 
-- else
else 
-- check if FacebookId is null 
if @FacebookId is null return -4 
-- else 
else
-- begin else  
begin 
    -- insert into facebook users
    insert into FaceBookConnections values (@FacebookId, @AccessToken)
	-- then create user 
	insert into Users values (0,0,null,SCOPE_IDENTITY(), 0)
	-- return good signal
	return 0
-- end else 
end 
-- end procedure  
end 
-- next lot
go
----------------------------<procedure to pick random winner>----------------------------
-- return -1 == item bestaat niet 
create or alter procedure ChoseRandomWinner(@itemId int,@rafflePrice float) as 
-- begin procedure 
begin
-- check if item exists 
if not exists (select * from Items where Id = @itemId) return -1
-- change status of terminated 
update Items set Terminated = 1 where Id = @itemId
-- create table var 
declare @myTable TABLE (id int, Amount money)
-- populate our table var 
insert into @myTable select Donor, Amount from TransactionTable where ItemId = @itemId and Donor is not null and Status is null
---- create id Int 
declare @id int 
-- declare money var 
declare @minValue money = 0.00
-- create random to get a random winner 
declare @random money = Round(RAND()*(@rafflePrice-0+1)+0,2)
---- create cursors 
declare db_cursor cursor local for select id from @myTable
---- open cursor 
open db_cursor  
---- get first entry 
fetch next from db_cursor into @id  
---- loop trough cursor 
while @@FETCH_STATUS = 0  
---- begin while 
begin 
        -- get max value 
        declare @maxValue money = (select Amount from @myTable where id = @id)
		-- update max value 
		set @maxValue = @minValue + @maxValue
		-- check if he's a winner or not 
		if @random >= @minValue and @random < @maxValue insert into WinnerTable values (@itemId,@id, 0)
		-- update value in table var 
		update @myTable set Amount = @maxValue where id = @id
		-- update min value 
		set @minValue = @maxValue
        -- get next entry 
        fetch next from db_cursor into @id 
---- end while 
end
-- end procedure 
end 
-- next lot
go
---------------<procedure to add or update transaction table>--------------------------
-- return 1 == updated
-- return 2 == inserted
create or alter procedure ModifyTransaction(@itemId int, @userId int, @amount money) as 
-- begin procedure 
begin
-- check if exists 
if exists (select * from TransactionTable where ItemId = @itemId and Donor = @userId) begin update TransactionTable set Amount = Amount + @amount where ItemId = @itemId and Donor = @userId return 1 end
-- if not 
insert into TransactionTable values (@itemId,@userId,@amount, null) return 2 
-- end procedure 
end 
-- next lot 
go 
----------------------<procedure used in trigger to check if amount is correct>----------------------
create or alter procedure CheckAmount(@id int,@itemId int,@currentAmount money,@newAmount  money,@rafflePrice money,@Donor int, @uAmount money = 0) as 
-- begin procedure
begin
	-- create updated amount 
	declare @updatedAmount money 
	-- normal update
	if @uAmount = 0 begin set @updatedAmount = @newAmount + @currentAmount  update Users set AvailableAmount = AvailableAmount - @newAmount where Id = @Donor end
	-- special update
	else begin set @updatedAmount = @uAmount + @currentAmount update Users set AvailableAmount = AvailableAmount - @uAmount where Id = @Donor  end 
	-- check if we can update the current amount 
	if @updatedAmount <= @rafflePrice begin update Items set CurrentAmount = @updatedAmount where Id = @itemId end 
	-- if we can't, raise error and delete transaction record
	else 
	-- begin else 
	begin 
	-- delete from transaction table 
	delete from TransactionTable where Id = @id raiserror('UpdatedAmount cannot be bigger than RafflePrice',16,1) 
	-- begin end 
	end 
	-- check if we need to call a procecure to get random winner 
	if @updatedAmount = @rafflePrice begin exec dbo.ChoseRandomWinner @itemId,@rafflePrice  end 
-- end procedure 
end 
-- next lot
go
-- next lot
go
---------------<trigger to check if user is allowed to send message to other user>----------
create or alter trigger BeforeMessage on Messages instead of insert as 
-- begin trigger 
begin
---- create id Int 
declare @id int 
---- create cursors 
declare db_cursor cursor local for select id from inserted
---- open cursor 
open db_cursor  
---- get first entry 
fetch next from db_cursor into @id  
---- loop trough cursor 
while @@FETCH_STATUS = 0  
---- begin while 
begin 
        -- sender var
        declare @sender int = (select Sender  from inserted where Id = @id)
		-- receiver var 
		declare @receiver int = (select Receiver from inserted where Id = @id)
		-- message var
		declare @message varchar(max) = (select Message from inserted where Id = @id)
		-- check if sender is not sending if message to himself
		if @sender = @receiver raiserror('you can not send a message to yourself',16,1) 
		-- insert if you're allowed to
        if exists (select * from MessageWinners where (Raffler = @sender and Winner = @receiver) or (Raffler = @receiver and Winner = @sender)) insert into Messages values (@sender,@receiver,@message)
		-- if not raise error
		else raiserror('you are not allowed to send to that person',16,1) 
        -- get next entry 
        fetch next from db_cursor into @id 
---- end while 
end
-- end trigger  
end 
-- next lot
go
---------------<trigger after insert on Users table>----------------------------
create or alter trigger AfterUser on Users after insert as 
-- begin trigger 
begin
---- create id Int 
declare @id int 
---- create cursors 
declare db_cursor cursor local for select Id from inserted
---- open cursor 
open db_cursor  
---- get first entry 
fetch next from db_cursor into @id  
---- loop trough cursor 
while @@FETCH_STATUS = 0  
---- begin while 
begin 
     -- get IdAppUserConnection
	 declare @idAppUser int = (select IdAppUserConnection from inserted where Id = @id)
	 -- get IdFaceBookUserConnection
	 declare @idFaceBook int = (select IdFaceBookUserConnection from inserted where Id = @id)
	 -- violation check 
	 if @idAppUser is null and @idFaceBook is null
	 -- give error and delete user 
	 begin delete from Users where Id = @id raiserror('User has to be app or facebook user',16,1) end
	 -- violation check 
	 if @idAppUser is not null and @idFaceBook is not null
	 -- give error and delete user 
	 begin delete from Users where Id = @id raiserror('User can not be an AppUser and a Facebook user at the same time',16,1) end
	 -- get next entry 
    fetch next from db_cursor into @id 
---- end while 
end
-- end trigger
end
-- next lot
go
---------------<trigger after insert on transaction table>----------------------------
create or alter trigger BeforeTransactionI on TransactionTable after insert as 
-- begin trigger
begin
---- create id Int 
declare @id int 
---- create cursors 
declare db_cursor cursor local for select Id from inserted
---- open cursor 
open db_cursor  
---- get first entry 
fetch next from db_cursor into @id  
---- loop trough cursor 
while @@FETCH_STATUS = 0  
---- begin while 
begin 
    -- get itemiD 
	declare @itemId int = (select ItemId from inserted where Id = @id)
    -- get current amount of product
    declare @currentAmount money = (select CurrentAmount from Items where Id = @itemId)
	-- get raffleprice of product
	declare @rafflePrice money = (select RafflePrice from Items where Id = @itemId)
	-- create new amount 
	declare @newAmount  money = (select Amount from inserted where Id = @id)
	-- get donor 
	declare @Donor money = (select Donor from inserted where Id = @id)
	-- use procedure 
	exec CheckAmount @id, @itemId, @currentAmount,@newAmount,@rafflePrice,@Donor
	-- get next entry 
    fetch next from db_cursor into @id 
---- end while 
end 
-- end trigger  
end  
-- next lot
go
---------------<trigger after insert on transaction table>----------------------------
create or alter trigger BeforeTransactionU on TransactionTable after update as 
-- begin trigger
begin
---- create id Int 
declare @id int 
---- create cursors 
declare db_cursor cursor local for select Id from inserted
---- open cursor 
open db_cursor  
---- get first entry 
fetch next from db_cursor into @id  
---- loop trough cursor 
while @@FETCH_STATUS = 0  
---- begin while 
begin 
    -- get donor 
	declare @Donor int = (select Donor from inserted where Id = @id)
	-- get Canceled
	declare @Status char = (select Status from inserted where Id = @id)
    -- only if donor is not null 
	if @donor is not null and @Status is null
	-- begin if
	begin 
	    -- get itemiD 
	    declare @itemId int = (select ItemId from inserted where Id = @id)
		-- get current amount of product
		declare @currentAmount money = (select CurrentAmount from Items where Id = @itemId)
		-- get raffleprice of product
		declare @rafflePrice money = (select RafflePrice from Items where Id = @itemId)
		-- old amount 
		declare @oldAmount money = (select Amount from deleted where Id = @id)
		-- create new amount 
		declare @newAmount  money = (select Amount from inserted where Id = @id)
		-- calculate updated amount
		declare @calculation money = @newAmount - @oldAmount
		-- use procedure 
		exec CheckAmount @id, @itemId, @currentAmount,@newAmount,@rafflePrice,@Donor, @calculation
	-- end if
	end 
	-- get next entry 
    fetch next from db_cursor into @id 
---- end while 
end 
-- end trigger  
end 
-- next lot
go 
---------------<trigger before insert on transaction table>----------------------------
create or alter trigger beforeAppConnection on AppConnections instead of insert as 
-- begin trigger
begin
---- create id Int 
declare @id int 
---- create cursors 
declare db_cursor cursor local for select Id from inserted
---- open cursor 
open db_cursor  
---- get first entry 
fetch next from db_cursor into @id  
---- loop trough cursor 
while @@FETCH_STATUS = 0  
---- begin while 
begin  
	-- get name 
	declare @name varchar(50) = (select replace(lower(Name), ' ', '') from inserted where Id = @id)
	-- get email
	declare @email varchar(80) = (select replace(lower(Email), ' ', '') from inserted where Id = @id)
	-- get password
	declare @password varchar(50) = (select lower(Password) from inserted where Id = @id)
	-- get access token
	declare @accessToken varchar(300) = (select AccessToken from inserted where Id = @id)
	-- insert into table 
	insert into AppConnections values (@name, @email, @password, @accessToken)
	-- then create user 
	insert into Users values (0,0,SCOPE_IDENTITY(),null,0)
	-- get next entry 
    fetch next from db_cursor into @id
---- end while 
end 
-- end trigger  
end 
-- next lot
go
---------------<trigger before deleting user>----------------------------
create or alter trigger deleteUser on Users instead of delete as 
-- begin trigger
begin
---- create id Int 
declare @id int 
---- create cursors 
declare db_cursor cursor local for select Id from deleted
---- open cursor 
open db_cursor  
---- get first entry 
fetch next from db_cursor into @id  
---- loop trough cursor 
while @@FETCH_STATUS = 0  
---- begin while 
begin  
    -- loop trough items 
	while 1=1
	-- begin while  
	begin
	    -- stop loop if does not exists
	    if not exists (select top 1 ItemId from TransactionTable where Donor = @id) break
		-- if exists 
		else 
		-- begin else
		begin 
		     -- declare itemId
		     declare @itemId int = (select top 1 ItemId from TransactionTable where Donor = @id)
			 -- delete from row if not terminated
			 if exists (select * from Items where Id = @itemId and Terminated = 0) 
			 -- begin if
			 begin 
			       -- delete if needed
			       if exists (select * from TransactionTable where Donor = @id and ItemId = @itemId and Status is null) delete from TransactionTable where Donor = @id and ItemId = @itemId
				   -- if not update
				   else update TransactionTable set Donor = null where Donor = @id and ItemId = @itemId
			 -- end if
			 end
			 -- check if terminated 
			 if exists (select * from Items where Id = @itemId and Terminated = 1) 
			 -- begin if
			 begin
			      -- delete if not exits 
			      if not exists (select * from WinnerTable where Winner = @id and ItemId = @itemId) 
				  -- begin if
				  begin 
				        -- get amount
				        declare @amount money = (select Amount from TransactionTable where Donor = @id)
						-- update items
						update Items set CurrentAmount = CurrentAmount - @amount, Terminated = 0 where Id = @itemId
						-- update transaction table
				        update TransactionTable set Donor = null where Donor = @id
				  -- else if
				  end
				  -- else 
				  else
				     -- begin else
				     begin 
					      -- get bit
					      declare @confirmed bit = (select Confirmed from WinnerTable where ItemId = @itemId)
					      -- update status
					      if @confirmed = 0  update TransactionTable set Donor = null, Status = 'r' where Donor = @id else update TransactionTable set Donor = null where Donor = @id
						  -- if not confirmed
						  if @confirmed != 1
						  -- begin if
						  begin 
						  	  -- update items
						      update Items set CurrentAmount = 0 , Terminated = 0 where Id = @itemId
						      -- endless loop
						      while 1=1 
						      -- begin while
						      begin
						            -- break loop if needed
						            if not exists (select top 1 * from TransactionTable where ItemId = @itemId and Status is null) break  
							        -- get transaction Id
							        declare @tId int = (select top 1 Id from TransactionTable where ItemId = @itemId and Status is null) 
							        -- get transaction amount 
							        declare @amountT money = (select Amount from TransactionTable where Id = @tId)
							        -- get transaction amount 
							        declare @donorT money = (select Donor from TransactionTable where Id = @tId)
							        -- send money back to User 
							        update Users set AvailableAmount = AvailableAmount + @amountT where Id = @donorT 
							        -- cancel transaction
							        update TransactionTable set Status = 'r' where Id = @tId
							        -- delete from WinnerTable 
							        delete from WinnerTable where Winner = @id
						     -- end while 
						     end
						  -- end if
						  end  	
					 -- end else   
				     end
			 -- end if 
			 end
		-- end else 
		end 
	-- end while
	end
	-- endless loop
	while 1=1 
	-- begin while 
	begin
	     -- stop loop if not exits
	     if not exists (select top 1 Id from TransactionTableWithRaffler where Raffler = @id and Status is null) break 
		 -- get Id
		 declare @tRId int = (select top 1 Id from TransactionTableWithRaffler where Raffler = @id and Status is null)
		 -- get Item
		 declare @itemIdTr int = (select ItemId from TransactionTable where Id = @tRId)
		 -- update 
		 update TransactionTable set Status = 'd' where Id = @tRId
		 -- only send money back if needed
		 if not exists (select * from WinnerTable where ItemId = @itemIdTr and Confirmed = 1)
		 -- begin if
		 begin
				-- get amount 
				declare @amountTr money = (select Amount from TransactionTable where Id = @tRId)
				-- get donor
				declare @donorTr int = (select Donor from TransactionTable where Id = @tRId)
				-- update 
				update Users set AvailableAmount = AvailableAmount + @amountTr where Id = @donorTr
		 -- end if
		 end
	-- end while  
	end
	-- delete item 
	delete from Items where Id = @itemIdTr
	-- remove user
	update WinnerTable set Winner = null where Winner = @id
	-- remove from messages 
	delete from Messages where Sender = @id or Receiver = @id
	-- remove raffler
	update Items set Raffler = null, Deleted = 1 where Raffler = @id
	-- remove user
	delete from Users where Id = @id
    -- get next entry
    fetch next from db_cursor into @id
---- end while 
end 
---- end while 
end 
-- next lot 
go
---------------<trigger before deleting user>----------------------------
create or alter trigger deleteItem on Items instead of delete as 
-- begin trigger
begin 
---- create id Int 
declare @id int 
---- create cursors 
declare db_cursor cursor local for select Id from deleted
---- open cursor 
open db_cursor  
---- get first entry 
fetch next from db_cursor into @id  
---- loop trough cursor 
while @@FETCH_STATUS = 0  
---- begin while 
begin
    -- endless loop
	while 1=1
	-- begin while
	begin 
	    -- break loop if needed
	    if not exists (select top 1 Id from TransactionTable where Status is null and ItemId = @id) break
		-- remove raffler
		update Items set Raffler = null, Deleted = 1 where Id = @id
		-- get id of transaction
		declare @idT int = (select top 1 Id from TransactionTable where Status is null and ItemId = @id)
		-- get donor
		declare @donor int = (select Donor from TransactionTable where Id = @idT)
		-- get amount
		declare @amount money = (select Amount from TransactionTable where Id = @idT)
		-- update status
		update TransactionTable set Status = 'd' where Id = @idT
		-- send money back
		update Users set AvailableAmount = AvailableAmount + @amount where Id = @donor
	-- end while
	end
    -- get next entry
    fetch next from db_cursor into @id  
---- end while 
end
-- end trigger 
end 
-- next lot
go
-----------------------<Test values>-----------------------
exec AddUser 'AERZOT', 'a', 'Logan', 'bogaertlogan@gmail.com', 'test123', null 
exec AddUser 'AERZO', 'a', 'Jarno', 'bogaertjarno@gmail.com', 'test123', null 
exec AddUser 'AERZOJ', 'a', 'Jeremy', 'bogaertjeremy@gmail.com', 'test123', null 


update Users set Amount = 500, AvailableAmount = 500 where Id = 2 or Id = 3

insert into Items values ('Ipad', 'last ipad', 1, 500, 0,0,0)

insert into TransactionTable values (1,2,499, null)

--insert into TransactionTable values (1,3,1, null)

delete from Users where Id = 1

select * from TransactionTableWithRaffler

select * from Users
select * from Items

/*insert into TransactionTable values (1,3,1)

select * from WinnerTable

--delete from Users where Id = 2

select * from TransactionTable
*/

/*exec ConfirmPayment 1

--select * from TransactionTable

/*select * from Users

*/
select * from Items
select * from AppUsers
*/
-- next lot
go
