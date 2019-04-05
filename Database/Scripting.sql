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
Password varchar(50) not null
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
check(RafflePrice > 0 and CurrentAmount > 0)
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
declare @myTable TABLE (id int, percentage float)
-- populate our table var 
insert into @myTable select Donor, convert(float,(Amount / @rafflePrice) * 100) from TransactionTable where ItemId = @itemId
-- end procedure 
end 
-- next lot
go
---------------<trigger before insert on transaction table>--------------------------
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
	declare @rafflePrice   money = (select RafflePrice from Items where Id = @itemId)
	-- create new amount 
	declare @newAmount     money = (select Amount from inserted where Id = @id)
	-- create updated amount 
	declare @updatedAmount money set @updatedAmount = @newAmount + @currentAmount
	-- check if we can update the current amount 
	if @updatedAmount <= @rafflePrice update Items set CurrentAmount = @updatedAmount where Id = @itemId 
	-- if we can't, raise error and delete transaction record
	else 
	-- begin else 
	begin 
	-- delete from transaction table 
	delete from TransactionTable where Id = @id raiserror(10,10,1,'CurrentAmount cannot be bigger than RafflePrice') 
	-- begin end 
	end 
	-- check if we need to call a procecure to get random winner 
	if @currentAmount = @rafflePrice exec dbo.ChoseRandomWinner
	-- get next entry 
    fetch next from db_cursor into @id 
---- end while 
end 
-- end trigger  
end  
-----------------------<Test values>-----------------------
