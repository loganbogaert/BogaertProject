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
---------------<Create user table>--------------------------
create table Users 
(
Id int not null primary key identity,
Name varchar(50) not null, 
Email varchar(80) not null, 
Password varchar(50) not null, 
Amount money not null,
AvailableAmount money not null, 
check(Amount >=0 and AvailableAmount >=0)
)
---------------<Create items table>--------------------------
create table Items
(
Id int not null primary key identity, 
Name varchar(50) not null, 
Description text not null,
Raffler int foreign key references Users(Id) not null,
RafflePrice money not null,
CurrentAmount money default 0,
check(RafflePrice > 0 and CurrentAmount >= 0)
)
---------------<Create transaction table>--------------------------
create table TransactionTable
(
Id int not null primary key identity, 
ItemId int not null foreign key references Items(Id),
Donor int not null foreign key references Users(Id),
Amount money not null,
unique(ItemId,Donor)
)
---------------<Create Winner table>--------------------------
create table WinnerTable
(
Id int not null primary key identity, 
ItemId int not null foreign key references Items(Id),
Winner int not null foreign key references Users(Id),
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
-- next lot
go
-------------------------------<View to get winner and donor at same record>-------------------------------
create view MessageWinners as select W.Id, W.ItemId, W.Winner,I.Raffler from WinnerTable W join Items I on W.ItemId = I.Id
-- next lot
go
----------------------------<procedure to pick random winner>----------------------------
-- return -1 == item bestaat niet 
create or alter procedure ChoseRandomWinner(@itemId int,@rafflePrice float) as 
-- begin procedure 
begin
-- check if item exists 
if not exists (select * from Items where Id = @itemId) return -1
-- create table var 
declare @myTable TABLE (id int, Amount money)
-- populate our table var 
insert into @myTable select Donor, Amount from TransactionTable where ItemId = @itemId
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
		if @random >= @minValue and @random < @maxValue insert into WinnerTable values (@itemId,@id)
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
insert into TransactionTable values (@itemId,@userId,@amount) return 2 

-- end procedure 
end 
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
---------------<trigger before insert on transaction table>----------------------------
create or alter trigger BeforeTransaction on TransactionTable after insert as 
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
	-- delete money from Account 
	update Users set AvailableAmount = AvailableAmount - @newAmount where Id = @Donor
	-- create updated amount 
	declare @updatedAmount money set @updatedAmount = @newAmount + @currentAmount
	-- check if we can update the current amount 
	if @updatedAmount <= @rafflePrice update Items set CurrentAmount = @updatedAmount where Id = @itemId 
	-- if we can't, raise error and delete transaction record
	else 
	-- begin else 
	begin 
	-- delete from transaction table 
	delete from TransactionTable where Id = @id raiserror('CurrentAmount cannot be bigger than RafflePrice',16,1) 
	-- begin end 
	end 
	-- check if we need to call a procecure to get random winner 
	if @updatedAmount = @rafflePrice exec dbo.ChoseRandomWinner @itemId,@rafflePrice
	-- get next entry 
    fetch next from db_cursor into @id 
---- end while 
end 
-- end trigger  
end  
-- next lot
go
-----------------------<Test values>-----------------------
insert into Users values ('logan','bogaertlogan@gmail.com','test123',300.00,300.00), ('jarno','bogaertjarno@gmail.com','test123',300.00,300.00), ('Jeremy','bogaertjeremy@gmail.com','test123',300.00,300.00)
insert into Items values ('Iphone','Never used Iphone',1,200.00,0)
exec ModifyTransaction 1,2,110.00
exec ModifyTransaction 1,3,90.00

--select * from Messages
select * from MessageWinners
insert into Messages values (3,1,'lol')

select * from Messages