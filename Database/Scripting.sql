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
Amount money not null
)

