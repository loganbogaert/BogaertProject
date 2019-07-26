create table AppConnections
(
Id int not null primary key auto_increment,
Name varchar(50) not null, 
Email varchar(100) not null unique, 
Password varchar(300) not null,
AccessToken varchar(300) not null unique,
);
-- -------------<Create app FaceBook table>----------------------
create table FaceBookConnections
(
Id int not null primary key auto_increment,
FbId longtext not null,
AccessToken varchar(300) not null unique
);
-- -------------<Create user table>--------------------------
create table Users 
(
Id int not null primary key auto_increment,
Amount decimal(15,4) not null default 0,
AvailableAmount decimal(15,4) not null default 0, 
IdAppUserConnection int null foreign key references AppConnections(Id);, 
IdFaceBookUserConnection int null foreign key references FaceBookConnections(Id),
Validated bit default 0,
check(Amount >=0 and AvailableAmount >=0),
check(Amount >= AvailableAmount)
)
-- -------------<Create items table>--------------------------
create table Items
(
Id int not null primary key auto_increment, 
Name varchar(50) not null, 
Description longtext not null,
Raffler int foreign key references Users(Id); null,
RafflePrice money not null,
CurrentAmount money default 0,
Terminated bit default 0,
Deleted bit default 0,
check(RafflePrice > 0 and CurrentAmount >= 0)
)
-- -------------<Create transaction table>--------------------------
create table TransactionTable
(
Id int not null primary key auto_increment, 
ItemId int not null foreign key references Items(Id);,
Donor  int null foreign key references Users(Id),
Amount money not null,
Status char default null,
unique(Id,ItemId,Donor, Status), 
check(Amount > 0),
check (Status is null or Status = 'r' or Status = 'd' or Status = 'w')
)
-- -------------<Create Winner table>--------------------------
create table WinnerTable
(
Id int not null primary key auto_increment, 
ItemId int not null foreign key references Items(Id);,
Winner int null foreign key references Users(Id),
Confirmed bit default 0,
unique(ItemId)
)
-- -------------<Create Messages table>--------------------------
create table Messages
(
Id int not null primary key auto_increment, 
Sender int not null foreign key references Users(Id);,
Receiver int not null foreign key references Users(Id),
Message text not null
)
-- -----------<table for texts>-------------
create table Texts
(
Id int not null primary key auto_increment, 
Language varchar(2) not null, 
Text longtext not null
);
-- -----------<table for profits>-------------
create table Profits
(
ItemId int not null primary key foreign key references Items(Id);,
Percentage varchar(3) not null, 
check(RIGHT(Percentage,1) = '%')
)

create or alter delimiter //

create  function CalculateProfit(p_itemId int, p_percentage varchar(3)) returns decimal(15,4) 
-- begin function 
begin
-- check if item does not exists
if not exists (select * from Items where Id = p_itemId) then return 0.00;
end if; 
-- else 
else
    -- begin else  
	-- get raffle price 
	declare v_price decimal(15,4) default (select RafflePrice from Items where Id = p_itemId);
	-- create int 
	declare v_percentageInt int;
	
	declare v_substring1 varchar(3) default substring(p_percentage,1,2);
	declare v_substring2 varchar(3) default substring(p_percentage,1,1);
	
	-- if length == 3
	if char_length(rtrim(p_percentage)) = 3 then  set v_percentageInt = convert(int, v_substring1)
	
	end if;
	
	-- if length == 2 
	if char_length(rtrim(p_percentage)) = 2 then  set v_percentageInt = convert(int, v_substring2)
	
	end if;
	
	-- if length == 1
	if char_length(rtrim(p_percentage)) = 1 then return 0.00;
	
	end if;
	
	-- return profit
	return convert(money,round((v_price / 100) * v_percentageInt ,2));
	-- end else 
	end if;  
-- return 0.00 if error
return 0.00; 
-- end function
end;
//

delimiter ;



-- -----------------------------<View to get TransactionTable With Raffler>------------------
create view TransactionTableWithRaffler as select T.Id, I.Raffler,T.Donor,T.ItemId, T.Amount, T.Status  from TransactionTable T join Items I on T.ItemId = I.Id 
-- next lot 
go  
-- -----------------------------<View to get number of text per language>------------------
create view TextPerLanguage as select Language, Text, ROW_NUMBER() over( partition by Language Order by Language) as LanguageNumber from Texts 
-- next lot 
go 
-- -----------------------------<View to get facebook users>-------------------------------
create view FacebookUsers as select u.Id, u.Amount, u.AvailableAmount, f.AccessToken from  Users u join FaceBookConnections f on f.Id = u.IdFaceBookUserConnection 
-- next lot 
go 
-- -----------------------------<View to get real app users>-------------------------------
create view AppUsers as select u.Id, u.Amount, u.AvailableAmount, a.Name, a.Email, a.Password, a.AccessToken from  Users u join AppConnections a on a.Id = u.IdAppUserConnection
-- next lot
go
-- -----------------------------<View to get winner and donor at same record>-------------------------------
create view MessageWinners as select W.Id, W.ItemId, W.Winner,I.Raffler from WinnerTable W join Items I on W.ItemId = I.Id
-- next lot
go
-- -----------------------------<View to get profit in money value>-------------------------------
create view profitsInMoneyValue as select p.ItemId, p.Percentage, dbo.CalculateProfit(p.ItemId,p.Percentage) as profit from Profits p
-- next lot
go

create or alter delimiter //

create  procedure ConfirmPayment(p_itemId int)sp_lbl:
 
-- begin procedure
begin
declare not_found int default 0;
declare continue handler for not found set not_found = 1;
-- check if item exists 
if not exists (select * from Items where Id = p_itemId) then leave sp_lbl -1;
end if;
-- get total of sum from payments 
declare v_totalSum  decimal(15,4) default (select sum(Amount) from TransactionTable where ItemId = p_itemId);
-- get rafflePrice from item
declare v_totalItem decimal(15,4) default (select RafflePrice from Items where Id = p_itemId);
-- check if total equals amount of item
if v_totalItem = v_totalSum 

-- begin if
then
           -- begin try block
           begin try
		   -- begin transaction block 
		   start transaction;
		   -- -- create id Int 
           declare v_id int; 
		   -- -- create cursors 
           for select id from TransactionTable where ItemId = p_itemId
		   -- -- open cursor 
           open db_cursor;  
		   -- -- get first entry 
           fetch next from; db_cursor into v_id  
           -- -- loop trough cursor 
           while NOT_FOUND = 0  
		   -- -- begin while 
           do 
		   -- get amount 
		   declare v_amount decimal(15,4) default (select Amount from TransactionTable where Id =v_id);
		   -- get donor 
		   declare  v_donor int default (select Donor from TransactionTable where Id = v_id);
		   -- update users table 
		   update Users set Amount = Amount - v_amount where Id =  v_donor;
		   -- get next entry 
           fetch next from; db_cursor into v_id 
		   -- -- end while 
           end while;
		   -- -----------------<To be continued>-------------------
		   -- get raffler 
		   declare v_raffler int default (select Raffler from Items where Id = p_itemId);
		   -- get profit 
		   declare v_profit decimal(15,4);
		   -- percentage 
		   declare v_percentage varchar(3) default  '10%';
		   -- get profit 
		   set @stmt_str =  v_profit;
   		prepare stmt from @stmt_str;
   		execute stmt;
   		deallocate prepare stmt; = dbo.CalculateProfit p_itemId, v_percentage
		   -- insert into profit if not exists 
	       if not exists (select * from Profits where ItemId = p_itemId) then insert into Profits values (p_itemId,v_percentage);
       	end if;
		   -- update saldo amount 
		   update Users set Amount = Amount + v_totalSum, AvailableAmount = AvailableAmount + v_totalSum where Id = v_raffler;
		   -- commit sql 
		   commit; 
	       -- end try block 
	       end; try 
		   -- rollback
		   begin catch rollback  signal SQLSTATE '02000' SET MESSAGE_TEXT = 'Error while throwing money away from userAccounts, very weird error !'   end; catch
		   -- erase profit
		   update Users set Amount = Amount - v_profit, AvailableAmount = AvailableAmount - v_profit where Id = v_raffler;
		   -- update winner table 
		   update WinnerTable set Confirmed = 1 where ItemId = p_itemId;
		   -- update 
		   update TransactionTable set Status = 'w' where ItemId = p_itemId;
-- end if 
-- raise weird error
else signal SQLSTATE '02000' SET MESSAGE_TEXT = 'Total of payments should be equal to itemRafflePrice, very weird error !' 
end if;
-- end procedure 
end;
//

delimiter ;

