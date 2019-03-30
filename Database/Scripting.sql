-- create database if not exists 
use [master]
if db_id('Stock') is not null drop database [Stock]
go 
create database [Stock]
go
set nocount on
-- use Database
use [Stock]
-------------------------------------------------<tabellen aanmaken>-------------------------------------------------
-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Gebruikers')
create table Gebruikers 
(
	GebruikersId int not null identity primary key, 
	GebruikersNaam varchar(20) not null unique,
	Telefoonnummer varchar(20) not null unique,
	Email varchar(20) not null unique,
	Geslacht varchar(1) not null,
	Wachtwoord varchar(20) not null
)

-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Jobs')
create table Jobs
(
	JobsId int not null identity primary key, 
	JobsNaam varchar(20) not null unique,
	Rechten varchar(20),
	check(Rechten = 'vestigingAdmin' or Rechten = 'a' or Rechten = 'writerLevering' or Rechten = 'writerStocktelling' or rechten = 'r') 
)

-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Vestigingen')
create table Vestigingen
(
	VestigingsId int not null identity primary key, 
	Locatienaam varchar(20) not null unique,
	Locatie varchar(20) not null,
	check (LocatieNaam != '' and Locatie != '')
)

-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'JobGebruikers')
create table JobGebruikers
(
	JobGebruikersId int not null identity primary key, 
	JobsId int not null foreign key references Jobs(JobsId),
	GebruikersId int not null foreign key references Gebruikers(GebruikersId),
	unique(JobsId,GebruikersId,VestigingsId),
	VestigingsId int not null foreign key references Vestigingen(VestigingsId)
)

-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Stocktellingen')
create table Stocktellingen
(
	StocktellingsId int not null identity primary key, 
	Datum datetime not null,
	GebruikersId int not null foreign key references Gebruikers(GebruikersId),
	VestigingsId int not null foreign key references Vestigingen(VestigingsId)
)

-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Categorien')
create table Categorien 
(
	CategorieId int not null identity primary key,
	CategorieNaam varchar(20) not null unique,
	LigtIn int foreign key references Categorien(CategorieId),
	check(CategorieNaam != '')
)

-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Producten')
create table Producten
(
	ProductId int not null identity primary key,
	ProductNaam varchar(10) not null, 
	CategorieId int foreign key references Categorien(CategorieId),
	check(ProductNaam != '')
)

-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Adressen')
create table Adressen
(
	AdressenId int not null identity primary key,
	AdressenNaam varchar(50) not null,
	AdressenNummer varchar(5) not null,
	check (AdressenNaam != '' and AdressenNummer != '')
)

-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Leveranciers')
create table Leveranciers
(
	LeveranciersId int not null identity primary key,
	LeveranciersNaam varchar(50) not null,
	AdressenId int not null foreign key references Adressen(AdressenId),
	TelefoonNummer varchar(20) not null unique,
	EmailAdress varchar(50) not null unique,
	check (LeveranciersNaam != '' and TelefoonNummer != '' and EmailAdress != '')
)

-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Huidigestocktellingen')
create table Huidigestocktellingen
(
	HuidigestocktellingsId int not null identity primary key,
	Aantal int not null,
	ProductId int not null foreign key references Producten(ProductId) unique,
	check (Aantal != 0)
)

-- create table if not exists 
if not exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'AantalInVoorraadPerProduct')
create table AantalInVoorraadPerProduct
(
	AantalInVoorraadPerProductId int not null identity primary key,
	ProductId int not null foreign key references Producten(ProductId),
	LeveranciersId int not null foreign key references Leveranciers(LeveranciersId),
	Aantal int not null,
	LeverDatum datetime not null,
	VestigingsId int not null foreign key references Vestigingen(VestigingsId),
	unique(ProductId,LeveranciersId,VestigingsId)
)

go

-------------------------------------------------<stored procedures>----------------------------------------------------
-- return  0  ==  alles is goed verlopen 
-- return -1  ==  product bestaat niet
-- return -2  ==  Negatief aantal in voorraad
-- return -4  ==  Start met negatief aantal

create or alter procedure PasStockAan(@productId int,@aantal int,@leveranciersId int, @leverDatum datetime, @vestiginsId int) as 
begin 
	-- check if product exsits 
	if not exists (select * from Producten where ProductId = @productId) return -1
	-- tonen als die vestigingen bestaan, als die vestigingen niet bestaan return -5
	if not exists (select * from Vestigingen where VestigingsId = @vestiginsId) return -5
	-- query
	declare @SQLString nvarchar(max) 
	-- aantal 
	declare @aantal2 int
	-- query 
	set @SQLString = N'select @aantal2 = count(*) from AantalInVoorraadPerProduct' + CONVERT(varchar,@vestiginsId)  + ' where ProductId = ' + convert(varchar,@productId) + ' and LeveranciersId = ' + convert(varchar,@leveranciersId)
	-- execute 
	execute sp_executesql @SQLString, @params = N'@aantal2 int output', @aantal2 = @aantal2 output 
	-- query 
	declare @SQLString2 nvarchar(max) = N'insert into AantalInVoorraadPerProduct' + convert(varchar,@vestiginsId)+ ' values(' + convert(varchar,@productId) +','+ convert(varchar,@leveranciersId) + ',' + convert(varchar,@aantal) + ',' + '''' + convert(varchar,@leverDatum, 120)+ '''' + ',' + convert(varchar,@vestiginsId) + ')'
	-- execute procedure 
	if @aantal2 = 0 begin if @aantal > 0 execute(@SQLString2) else return -4 end
	-- if not
	else 
	-- begin else
	begin
	-- declare int 
	declare @aantal3 int
	-- create sqlstring 
	declare @SQLString3 nvarchar(max) = N'select @aantal3 = Aantal from AantalInVoorraadPerProduct' + convert(varchar,@vestiginsId) + ' where ProductId = ' + convert(varchar,@productId) + ' and LeveranciersId = ' + convert(varchar,@leveranciersId)
	-- execute sql string
	execute sp_executesql @SQLString3, @params = N'@aantal3 int output', @aantal3 = @aantal3 output 
	-- create new aantal
	declare @nieuweAantal int = @aantal3 + @aantal
	-- create string
	declare @SQLString4 nvarchar(max) = N'update AantalInVoorraadPerProduct' + convert(varchar,@vestiginsId) + ' set Aantal = ' + convert(varchar,@nieuweAantal)  +' where ProductId = ' + convert(varchar,@ProductId) + ' and LeveranciersId = ' + convert(varchar,@leveranciersId)
	-- execute string 
	if @nieuweAantal >= 0 execute(@SQLString4) else return -2
	-- end else 
	end 
	-- return 0
	return 0 
end

go

--------------------procedure maken om een categorie aan te maken
-- return  0  ==  alles is goed verlopen 
-- return -1  ==  constraint violation
create or alter procedure VoegCategorieToe(@categorieNaam varchar(20), @ligtIn int = null) as 
begin
--    -- begin try
	  begin try 
--	    -- check if int is null 
		if @ligtIn is not null insert into Categorien values (@categorieNaam, @ligtIn) else insert into Categorien(CategorieNaam) values(@categorieNaam)
--		-- return 
		return 0
	-- end try
	end try 
--	-- give error
	begin catch return -1 end catch
---- end procedure 
end 
----go 
go 
--------------------procedure om een leverancier aan te maken 
-- return  0  == alles is goed verlopen 
-- return -1  == check violate 
-- return -2  == adress bestaat niet 
create or alter procedure VoegLeverancierToe(@name varchar(20), @adresId int, @telefoonNummer varchar(20), @emailAdress varchar(50)) as 
---- begin procedure  
begin 
   if not exists (select * from Adressen where AdressenId = @adresId) return -2
--   -- try insert 
   begin try insert into Leveranciers values (@name,@adresId,@telefoonNummer,@emailAdress) return 0 end try 
--   -- give error int (violate check)
   begin catch return -1 end catch
---- end procedure 
end 
-- go
go
--------------------procedure om een adres aan te maken 
create or alter procedure VoegAdresToe(@name varchar(20), @nummer varchar(5)) as 
---- begin procedure  
begin 
--   -- try insert 
   begin try insert into Adressen values (@name,@nummer) return 0 end try 
--   -- give error int (violate check)
   begin catch return -1 end catch
---- end procedure 
end 
--go 
go
--------------------procedure om een product aan te maken 
create or alter procedure VoegProductToe(@name varchar(20), @categorieId int) as 
---- begin procedure  
begin 
   if not exists (select * from Categorien where CategorieId = @categorieId) return -2
--   -- try insert 
   begin try insert into Producten values (@name,@categorieId) return 0 end try 
--   -- give error int (violate check)
   begin catch return -1 end catch
---- end procedure 
end 
--go 
go
--------------------procedure maken om een gebruiker aan te maken
create or alter procedure VoegGebruikerToe(@name varchar(20), @telefoonnummer varchar(20), @email varchar (20), @geslacht varchar(1), @wachtwoord varchar(20)) as 
begin 
   begin try insert into Gebruikers values (@name, @telefoonnummer, @email, @geslacht,@wachtwoord) return 0 end try 
--   -- give error int (violate check)
   begin catch return -1 end catch
---- end procedure 
end 
--go 
go
--------------------procedure maken om een jobs aan te maken
create or alter procedure VoegJobToe(@name varchar(20), @rechten varchar(20)) as 
begin 
   begin try insert into Jobs values (@name, @rechten) return 0 end try 
--   -- give error int (violate check)
   begin catch return -1 end catch
---- end procedure 
end 
--go 
go
--------------------procedure maken om een vestiging aan te maken
create or alter procedure VoegVestigingToe(@locatienaam varchar(20), @locatie varchar(20)) as 
begin 
   begin try insert into Vestigingen values (@locatienaam, @locatie) return 0 end try 
--   -- give error int (violate check)
   begin catch return -1 end catch
---- end procedure 
end 
--go 
go
--------------------procedure maken om een jobgebruikers aan te maken
create or alter procedure VoegJobGebruikerToe(@jobsnaam varchar(20), @gebruikerId int, @vestigingsId int) as 
begin 
	declare @jobId int = (select JobsId from Jobs where JobsNaam = @jobsnaam)
   begin try insert into JobGebruikers values (@jobId, @gebruikerId, @vestigingsId) return 0 end try 
--   -- give error int (violate check)
   begin catch return -1 end catch
---- end procedure 
end 
--go 
go
-------------------------------------------------<triggers>----------------------------------------------------
--go 
go
---- trigger om de velden met waarde 0 er uit te halen 
create or alter trigger dbo.CheckVoorLegeProducten on AantalInVoorraadPerProduct after update as 
---- begin trigger 
begin
---- create id Int 
declare @id int 
---- create cursors 
declare db_cursor cursor local for select AantalInVoorraadPerProductId from inserted
---- open cursor 
open db_cursor  
---- get first entry 
fetch next from db_cursor into @id  
---- loop trough cursor 
while @@FETCH_STATUS = 0  
---- begin while 
begin 
--    -- get aantal of id 
	declare @aantal int = (select Aantal from inserted where AantalInVoorraadPerProductId = @id)
--	-- delete if 0 
	if @aantal = 0 delete from AantalInVoorraadPerProduct where AantalInVoorraadPerProductId = @id
--	-- get next entry 
    fetch next from db_cursor into @id 
---- end while 
end 
---- end trigger 
end
go

-- trigger die dynamisch views gaat maken om automatisch rechten aan gebruikers te geven
create or alter trigger dbo.auteurIsToegevoegd on Vestigingen after insert as
-- begin trigger
begin
---- create id Int 
declare @id int 
---- create cursors 
declare db_cursor cursor local for select VestigingsId from inserted
---- open cursor 
open db_cursor  
	---- get first entry 
	fetch next from db_cursor into @id  
	---- loop trough cursor 
	while @@FETCH_STATUS = 0  
	-- begin while
	begin 
		-- create sql string to execute afterwards 
		declare @SQLString varchar(max) = 'CREATE VIEW StockTellingen' + convert(varchar,@id)
		-- create sql string to execute afterwards 
		set @SQLString = @SQLString + ' AS SELECT * FROM Stocktellingen WHERE VestigingsId = ' + convert(varchar,@id)
		-- create sql string to execute afterwards 
		set @SQLString = @SQLString + ' WITH CHECK OPTION'
		-- execute
		EXECUTE (@SQLString)
		-- create sql string to execute afterwards 
		declare @SQLString2 varchar(max) = 'CREATE VIEW AantalInVoorraadPerProduct' + convert(varchar,@id)
		-- create sql string to execute afterwards 
		set @SQLString2 = @SQLString2 + ' AS SELECT * FROM AantalInVoorraadPerProduct WHERE VestigingsId = ' + convert(varchar,@id)
		-- create sql string to execute afterwards 
		set @SQLString2 = @SQLString2 + ' WITH CHECK OPTION'
		-- execute
		EXECUTE (@SQLString2)
		-- create admin login
		declare @SQLString3 varchar(max) = 'create login vestigingAdmin' + convert(varchar,@id) + ' with password = ' + '''' + 'a' + ''''
		-- execute
		EXECUTE (@SQLString3)
		-- create writer login
		set @SQLString3 = 'create login writerLevering' + convert(varchar,@id) + ' with password = ' + '''' + 'w' + ''''
		-- execute
		EXECUTE (@SQLString3)
		-- create writer login
		set @SQLString3 = 'create login writerStocktelling' + convert(varchar,@id) + ' with password = ' + '''' + 'w' + ''''
		-- execute
		EXECUTE (@SQLString3)
		-- create reader login
		set @SQLString3 = 'create login reader' + convert(varchar,@id) + ' with password = ' + '''' + 'r' + ''''
		-- execute
		EXECUTE (@SQLString3)
		-- create admin user
		declare @SQLString4 varchar(max) = 'create user vestigingAdmin' + convert(varchar,@id) + ' for login vestigingAdmin' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLString4)
		-- create writer user
		set @SQLString4 = 'create user writerLevering' + convert(varchar,@id) + ' for login writerLevering' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLString4)
		-- create writer user
		set @SQLString4 = 'create user writerStocktelling' + convert(varchar,@id) + ' for login writerStocktelling' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLString4)
		-- create reader user
		set @SQLString4 = 'create user reader' + convert(varchar,@id) + ' for login reader' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLString4)
		-- grant select r1
		declare @SQLStringGrant varchar(max) = 'grant select on dbo.AantalInVoorraadPerProduct' + convert(varchar,@id) + ' to reader' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant select r1
		set @SQLStringGrant = 'grant select on dbo.StockTellingen' + convert(varchar,@id) + ' to reader' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to admin
		set @SQLStringGrant = 'grant select, insert, update, delete on dbo.AantalInVoorraadPerProduct' + convert(varchar,@id) + ' to vestigingAdmin' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to admin
		set @SQLStringGrant = 'grant select, insert, update, delete on dbo.Producten to vestigingAdmin' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to admin
		set @SQLStringGrant = 'grant select on dbo.Leveranciers to vestigingAdmin' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to admin
		set @SQLStringGrant = 'grant execute on dbo.PasStockAan to vestigingAdmin' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to admin
		set @SQLStringGrant = 'grant select, insert, update, delete on dbo.StockTellingen' + convert(varchar,@id) + ' to vestigingAdmin' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to writer
		set @SQLStringGrant = 'grant select, update on dbo.AantalInVoorraadPerProduct' + convert(varchar,@id) + ' to writerStocktelling' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to writer
		set @SQLStringGrant = 'grant select, update on dbo.StockTellingen' + convert(varchar,@id) + ' to writerStocktelling' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to writer
		set @SQLStringGrant = 'grant select, insert on dbo.AantalInVoorraadPerProduct' + convert(varchar,@id) + ' to writerLevering' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to writer
		set @SQLStringGrant = 'grant select, insert on dbo.StockTellingen' + convert(varchar,@id) + ' to writerLevering' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to vestigingsAdmin 
		set @SQLStringGrant = 'grant select on dbo.Producten' + ' to writerLevering' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to vestigingsAdmin 
		set @SQLStringGrant = 'grant select on dbo.Producten' + ' to writerStocktelling' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to vestigingsAdmin 
		set @SQLStringGrant = 'grant select on dbo.Producten' + ' to vestigingAdmin' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- grant to vestigingsAdmin 
		set @SQLStringGrant = 'grant select on dbo.Producten' + ' to reader' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- simple grant 
		set @SQLStringGrant = 'grant select on dbo.Leveranciers' + ' to reader' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- simple grant 
		set @SQLStringGrant = 'grant select on dbo.Leveranciers' + ' to writerLevering' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- simple grant 
		set @SQLStringGrant = 'grant select on dbo.Leveranciers' + ' to writerStocktelling' + convert(varchar,@id)
		-- execute
		EXECUTE (@SQLStringGrant)
		-- get next entry 
		fetch next from db_cursor into @id
	-- end while 
	end
-- end trigger 
end

go
-------------------------------------------------<test procedures, functions, views...>------------------------------------------------------
exec dbo.VoegAdresToe 'negenbunderstraat' , '70'
exec dbo.VoegLeverancierToe 'logan',1,'0478796743','logan.bogaert@student.odisee.be'
exec dbo.VoegLeverancierToe 'ggg',2,'gggg','ggg'

exec dbo.VoegCategorieToe 'dranken'
exec dbo.VoegCategorieToe 'alcohol', 1

exec dbo.VoegProductToe 'gin gordon', 2
exec dbo.VoegProductToe 'fanta', 1
exec dbo.VoegProductToe'cola', 1
exec VoegGebruikerToe 'Thierry','87642874','UET','M','test123'
exec VoegGebruikerToe 'Logan','87643874','UzT','M','test123'
select * from Gebruikers
exec VoegJobToe 'Beheerder', 'vestigingAdmin'
exec VoegJobToe 'Admin', 'a'
exec VoegJobToe 'Leveraar', 'writerLevering'
select * from Jobs

--select * from Stocktellingen1

exec VoegVestigingToe 'MacdoBrussel', 'Brussel'
exec VoegVestigingToe 'MacdoAalst', 'Aalst'
select * from Vestigingen

exec VoegJobGebruikerToe 'Beheerder', 1, 1
exec VoegJobGebruikerToe 'Leveraar', 2, 1
--select * from JobGebruikers

/*exec dbo.PasStockAan 1, 10, 1, '2007-05-08 12:35:29', 1
exec dbo.PasStockAan 1, 10, 1, '2007-05-08 12:35:29', 1
exec dbo.PasStockAan 2, 30, 1, '2007-05-08 12:35:29', 2
exec dbo.PasStockAan 3, 40, 1, '2007-05-08 12:35:29', 1*/

--exec dbo.PasStockAan 1, -10, 1, '2007-05-08 12:35:29', 1

--select * from AantalInVoorraadPerProduct

--select * from AantalInVoorraadPerProduct1

--select * from Leveranciers

-------------------------------------------------<users,roles maken en verwijderen>---------------------------------------------------------
go

if not exists(SELECT name FROM sys.sql_logins WHERE name='a')
begin
	-- print message
	print 'Admin login created' 
	-- create login 
	create login a with password = 'a' 
	-- create user 
	create user a for login a
	exec sp_addrolemember 'db_owner', 'a'
end 

go 

if not exists(SELECT name FROM sys.sql_logins WHERE name='r')
begin
	-- print message
	print 'Reader login created' 
	-- create login 
	create login r with password = 'r' 
	-- create user 
	create user r for login r
end 

go 


--alle logins verwijderen
declare @sql_command varchar(max);
--set @sql_command = '';

--select @sql_command += 'drop login [' + name + ']' + char(13)
--from [master].[dbo].[syslogins] 
--where isntgroup = 0 and isntuser = 0 and sysadmin = 0 and name != 'sa' and name not like '##%'
--print 'Alle logins zijn verwijderd'

--declare @sql_command2 varchar(max);
--set @sql_command2 = '';

----alle gebruikers van logins verwijderen
--select @sql_command2 += 'drop user [' + name + ']' + char(13)
--from [Stock].[dbo].[sysusers] 
--where name not in('dbo','guest','INFORMATION_SCHEMA','sys','public') and left(name,3) <> 'db_'
--print 'Alle gebruikers van logins zijn verwijderd'

--exec (@sql_command);
--exec (@sql_command2);

-------------------------------------------------<tabellen en database verwijderen>-------------------------------------------------
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Huidigestocktellingen') drop table Huidigestocktellingen
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'AantalInVoorraadPerProduct') drop table AantalInVoorraadPerProduct
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'JobGebruikers') drop table JobGebruikers
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Jobs') drop table Jobs
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Stocktellingen') drop table Stocktellingen
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Gebruikers') drop table Gebruikers
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Vestigingen') drop table Vestigingen
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Leveranciers') drop table Leveranciers
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Adressen') drop table Adressen
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Producten') drop table Producten
------ delete if exists 
--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Categorien') drop table Categorien
	
---- naar master database gaan 
use [master]
go
--database laten veranderd worden met update optie (het lezen en veranderen in database)
alter database[Stock] set READ_WRITE 
go