/*
USE MASTER
DROP DATABASE PROJEKT_BAZY_DANYCH

CREATE DATABASE PROJEKT_BAZY_DANYCH

USE PROJEKT_BAZY_DANYCH

SET XACT_ABORT ON
*/

--IF OBJECT_ID('[OSOBA]', 'U') IS NOT NULL DROP TABLE [OSOBA]
CREATE TABLE [OSOBA] (
  [ID_OSOBY] INT,
  [IMIE] VarChar(25),
  [NAZWISKO] VarChar(25),
  [TELEFON] INT,
  [ADRES] VarChar(40),
  [ROK URODZENIA] INT,
  PRIMARY KEY ([ID_OSOBY])
);

--IF OBJECT_ID('[Pielegnacje]', 'U') IS NOT NULL DROP TABLE [Pielegnacje]
CREATE TABLE [Pielegnacje] (
  [ID_OBIEKTU] INT,
  [ID_pielegnacji] INT,
  PRIMARY KEY ([ID_pielegnacji])
);

CREATE TABLE TYP_WEJSCIOWKI (
	[ID_WEJSCIOWKI] INT PRIMARY KEY,
	[OPIS] VARCHAR(20)
);

--IF OBJECT_ID('[CENNIK]', 'U') IS NOT NULL DROP TABLE [CENNIK]
CREATE TABLE [CENNIK] (
  [ID_KARNETU] INT PRIMARY KEY,
  [ID_OBIEKTU] INT,
  [TYP_WEJSCIOWKI] INT FOREIGN KEY REFERENCES TYP_WEJSCIOWKI(ID_WEJSCIOWKI) ON DELETE CASCADE ON UPDATE CASCADE,
  [CENA] INT
);

CREATE TABLE KLIENT(
ID_KLIENTA INT PRIMARY KEY REFERENCES OSOBA(ID_OSOBY) ON DELETE CASCADE ON UPDATE CASCADE,
PRO_STATUS BIT NULL,
MAIL VARCHAR(40) NOT NULL,
HASH_HASLA VARCHAR(60) NOT NULL
)

--IF OBJECT_ID('[WYPOSAZENIE OBIEKTU]', 'U') IS NOT NULL DROP TABLE [WYPOSAZENIE OBIEKTU]
CREATE TABLE [WYPOSAZENIE OBIEKTU] (
  [ID_OBIEKTU] INT,
  [NAZWA_WYPOSAZENIA] VarChar(30),
  [ILOSC] INT,
  [STAN_WYPOSAZENIA] VarChar(15),
  [MARKA] VarChar(30),
  PRIMARY KEY ([NAZWA_WYPOSAZENIA], [ID_OBIEKTU])
);

CREATE TABLE [KLIENT-KARNET] (
  [ID_KLIENTA] INT,
  [ID_KARNETU] INT,
  [DATA KUPNA] DATE
  PRIMARY KEY ([ID_KLIENTA], [ID_KARNETU], [DATA KUPNA])
);

--IF OBJECT_ID('[Wejscia na obiekty]', 'U') IS NOT NULL DROP TABLE [Wejscia na obiekty]
CREATE TABLE [Wejscia na obiekty] (
  [ID_KLIENTA] INT,
  [ID_OBIEKTU] INT,
  [DATA] DATETIME,
  PRIMARY KEY ([ID_KLIENTA],[ID_OBIEKTU],[DATA])
);

--IF OBJECT_ID('[URLOPY]', 'U') IS NOT NULL DROP TABLE [URLOPY]
CREATE TABLE [URLOPY] (
  [ID_PRACOWNIKA] INT,
  [DATA_URLOPU] DATE,
  [CZAS_TRWANIA] INT
  PRIMARY KEY ([DATA_URLOPU], [ID_PRACOWNIKA])
);


--IF OBJECT_ID('[GODZINY OTWARCIA]', 'U') IS NOT NULL DROP TABLE [GODZINY OTWARCIA]
CREATE TABLE [GODZINY OTWARCIA] (
  [ID_OBIEKTU] INT PRIMARY KEY,
  [PONIEDZIALEK] VarChar(15),
  [WTOREK] VarChar(15),
  [SRODA] VarChar(15),
  [CZWARTEK] VarChar(15),
  [PIATEK] VarChar(15),
  [SOBOTA] VarChar(15),
  [NIEDZIELA] VarChar(15),
  [SWIETA] VarChar(15)
);

--IF OBJECT_ID('[Podwykonawcy]', 'U') IS NOT NULL DROP TABLE [Podwykonawcy]
CREATE TABLE [Podwykonawcy] (
  [ID_podwykonawcy] INT,
  [Nazwa] VarChar(15),
  [Adres] VarChar(15),
  [NR_Telefonu] varchar(12),
  PRIMARY KEY ([ID_podwykonawcy])
);

--IF OBJECT_ID('[Prowadzacy_grupy]', 'U') IS NOT NULL DROP TABLE [Prowadzacy_grupy]
CREATE TABLE [Prowadzacy_grupy] (
  [ID_Prowadzacego] INT PRIMARY KEY,
  [ID_OBIEKTU] INT
);

--IF OBJECT_ID('[Grafik_Grup]', 'U') IS NOT NULL DROP TABLE [Grafik_Grup]
CREATE TABLE [Grafik_Grup] (
  [ID_Grupy] INT,
  [Data] DATE,
  [Godzina] INT,
  PRIMARY KEY ([ID_Grupy])
);

--IF OBJECT_ID('[Szczegoly_Pielegnacji]', 'U') IS NOT NULL DROP TABLE [Szczegoly_Pielegnacji]
CREATE TABLE [Szczegoly_Pielegnacji] (
  [ID_PIELEGNACJI] INT,
  [Data_PPielegnacji] Date,
  [Data_ZPielegnacji] Date,
  [Rodzaj_pielegnacji] INT,
  [Cena_pielegnacji] INT,
  [Ocena_pielegnacji(1-5)] INT,
  [WYKONAWCA] INT,
  PRIMARY KEY ([ID_PIELEGNACJI])
);

--IF OBJECT_ID('[KLIENT-TRENER]', 'U') IS NOT NULL DROP TABLE [KLIENT-TRENER]
CREATE TABLE [KLIENT-TRENER] (
  [ID_KLIENTA] INT,
  [ID_TRENERA] INT,
  [TRENINGI W TYGODNIU] INT
  PRIMARY KEY([ID_KLIENTA],[ID_TRENERA])
);

--IF OBJECT_ID('[OBIEKTY]', 'U') IS NOT NULL DROP TABLE [OBIEKTY]
CREATE TABLE [OBIEKTY] (
  [ID_Obiektu] INT,
  [Nazwa] VarChar(20),
  [Adres] VarChar(20),
  PRIMARY KEY ([ID_Obiektu])
);

--IF OBJECT_ID('[TRENERZY PERSONALNI]', 'U') IS NOT NULL DROP TABLE [TRENERZY PERSONALNI]
CREATE TABLE [TRENERZY PERSONALNI] (
  [ID_TRENERA] INT PRIMARY KEY,
  [ID_OBIEKTU] INT
);

--IF OBJECT_ID('[OPINIE KLIENTOW]', 'U') IS NOT NULL DROP TABLE [OPINIE KLIENTOW]
CREATE TABLE [OPINIE KLIENTOW] (
  [ID_KLIENTA] INT,
  [ID_OBIEKTU] INT,
  [OCENA(1-10)] INT,
  [OPINIA] VarChar(300)
  PRIMARY KEY([ID_KLIENTA],[ID_OBIEKTU])
);

--IF OBJECT_ID('[ZABIEGI SPA]', 'U') IS NOT NULL DROP TABLE [ZABIEGI SPA]
CREATE TABLE [ZABIEGI SPA] (
  [ID_ZABIEGU] INT PRIMARY KEY,
  [ID_OBIEKTU] INT,
  [NAZWA_ZABIEGU] VarChar(30),
  [CENA_ZABIEGU] INT,
  [CZAS_TRWANIA] INT,
  [ID_PRACOWNIKA] INT
);

--IF OBJECT_ID('[MANAGEROWIE]', 'U') IS NOT NULL DROP TABLE [MANAGEROWIE]
CREATE TABLE [MANAGEROWIE] (
  [ID_MANAGERA] INT,
  [ID_OBIEKTU] INT
  PRIMARY KEY([ID_MANAGERA],[ID_OBIEKTU])
);

--IF OBJECT_ID('[PRACOWNIK]', 'U') IS NOT NULL DROP TABLE [PRACOWNIK]
CREATE TABLE [PRACOWNIK] (
  [ID_PRACOWNIKA] int,
  [PREMIA(%)] FLOAT,
  [ID_OBIEKTU] INT,
  [WYNAGRODZENIE] INT,
  [STANOWISKO] VarChar(15),
  PRIMARY KEY ([ID_PRACOWNIKA])
);

--IF OBJECT_ID('[OFERTY SPECJALNE]', 'U') IS NOT NULL DROP TABLE [OFERTY SPECJALNE]
CREATE TABLE [OFERTY SPECJALNE] (
  [ID_OFERTY] INT,
  [ID_Obiektu] INT,
  [Nazwa_oferty] VarChar(30),
  [Termin] Date,
  PRIMARY KEY ([ID_OFERTY])
);

--IF OBJECT_ID('[Grupy_zajeciowe]', 'U') IS NOT NULL DROP TABLE [Grupy_zajeciowe]
CREATE TABLE [Grupy_zajeciowe] (
  [ID_OBIEKTU] INT,
  [ID_Grupy] INT,
  [Nazwa_Grupy] VarChar(50),
  [Prowadzacy_Grupe] INT,
  [Ilosc_osob_w_grupie] INT,
  PRIMARY KEY ([ID_Grupy])
);

CREATE TABLE BILANS(
ID_OBIEKTU INT REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE,
DATA DATE NOT NULL,
MIASTO VARCHAR(20) NOT NULL,
RODZAJ_OBIEKTU VARCHAR(20) NOT NULL,
PRZYCHOD INT NOT NULL,
WYDATKI INT NOT NULL
)

CREATE TABLE GRAFIK(
ID_PRACOWNIKA INT NOT NULL REFERENCES PRACOWNIK(ID_PRACOWNIKA) ON DELETE CASCADE ON UPDATE CASCADE,
DATA DATE NOT NULL,
POCZATEK INT NOT NULL,
ILOSC_GODZIN INT NOT NULL
)

CREATE TABLE SPRZEDAZE_DNIA(
ID_OBIEKTU INT REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE,
ILOSC_SPRZEDARZY INT NOT NULL,
RODZAJ_KARNETU INT NOT NULL 
)

ALTER TABLE [TRENERZY PERSONALNI]
ADD FOREIGN KEY (ID_OBIEKTU) REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE

ALTER TABLE [TRENERZY PERSONALNI]
ADD FOREIGN KEY (ID_TRENERA) REFERENCES PRACOWNIK(ID_PRACOWNIKA) ON DELETE CASCADE ON UPDATE CASCADE

Alter table [Wejscia na obiekty]
ADD FOREIGN KEY (ID_KLIENTA) REFERENCES KLIENT(ID_KLIENTA) ON DELETE CASCADE ON UPDATE CASCADE

Alter table [KLIENT-TRENER]
ADD FOREIGN KEY (ID_KLIENTA) REFERENCES KLIENT(ID_KLIENTA) ON DELETE CASCADE ON UPDATE CASCADE

Alter table [KLIENT-TRENER]
ADD FOREIGN KEY (ID_TRENERA) REFERENCES [TRENERZY PERSONALNI](ID_TRENERA) ON DELETE CASCADE ON UPDATE CASCADE

Alter table [Wejscia na obiekty]
ADD FOREIGN KEY (ID_OBIEKTU) REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE

Alter table [KLIENT]
ADD FOREIGN KEY (ID_KLIENTA) REFERENCES OSOBA(ID_OSOBY) -- ON DELETE CASCADE ON UPDATE CASCADE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Alter table [PRACOWNIK]
ADD FOREIGN KEY (ID_PRACOWNIKA) REFERENCES OSOBA(ID_OSOBY) --ON DELETE CASCADE ON UPDATE CASCADE

Alter table [OPINIE KLIENTOW]
ADD FOREIGN KEY (ID_KLIENTA) REFERENCES KLIENT(ID_KLIENTA) ON DELETE CASCADE ON UPDATE CASCADE

Alter table [OPINIE KLIENTOW]
ADD FOREIGN KEY (ID_OBIEKTU) REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE

Alter table MANAGEROWIE
ADD FOREIGN KEY (ID_OBIEKTU) REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE

Alter table MANAGEROWIE
ADD FOREIGN KEY (ID_MANAGERA) REFERENCES PRACOWNIK(ID_PRACOWNIKA) ON DELETE CASCADE ON UPDATE CASCADE

Alter table [grupy_zajeciowe]
ADD FOREIGN KEY (Prowadzacy_grupe) REFERENCES [prowadzacy_grupy](ID_prowadzacego) ON DELETE CASCADE ON UPDATE CASCADE

Alter table [prowadzacy_grupy]
ADD FOREIGN KEY (ID_prowadzacego) REFERENCES PRACOWNIK(ID_PRACOWNIKA) ON DELETE CASCADE ON UPDATE CASCADE

Alter table URLOPY
ADD FOREIGN KEY (ID_pracownika) REFERENCES PRACOWNIK(ID_PRACOWNIKA) ON DELETE CASCADE ON UPDATE CASCADE

Alter table [wyposazenie obiektu]
ADD FOREIGN KEY (ID_OBIEKTU) REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE

ALTER TABLE SZCZEGOLY_PIELEGNACJI
ADD CONSTRAINT CHECK_OCENA_BETWEEN_1_5 CHECK ( [Ocena_pielegnacji(1-5)] BETWEEN 1 AND 5)

ALTER TABLE CENNIK
ADD FOREIGN KEY (ID_OBIEKTU) REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE

ALTER TABLE [OFERTY SPECJALNE]
ADD FOREIGN KEY (ID_OBIEKTU) REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE

ALTER TABLE [GRAFIK_GRUP]
ADD FOREIGN KEY (ID_GRUPY) REFERENCES GRUPY_ZAJECIOWE(ID_GRUPY) ON DELETE CASCADE ON UPDATE CASCADE

ALTER TABLE [GODZINY OTWARCIA]
ADD FOREIGN KEY (ID_OBIEKTU) REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE

ALTER TABLE PIELEGNACJE
ADD FOREIGN KEY (ID_OBIEKTU) REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE

ALTER TABLE [ZABIEGI SPA]
ADD FOREIGN KEY (ID_OBIEKTU) REFERENCES OBIEKTY(ID_OBIEKTU) ON DELETE CASCADE ON UPDATE CASCADE

ALTER TABLE [ZABIEGI SPA]
ADD FOREIGN KEY (ID_PRACOWNIKA) REFERENCES PRACOWNIK(ID_PRACOWNIKA) ON DELETE CASCADE ON UPDATE CASCADE

ALTER TABLE SZCZEGOLY_PIELEGNACJI
ADD FOREIGN KEY (ID_PIELEGNACJI) REFERENCES PIELEGNACJE(ID_PIELEGNACJI) ON DELETE CASCADE ON UPDATE CASCADE

ALTER TABLE SZCZEGOLY_PIELEGNACJI
ADD FOREIGN KEY (WYKONAWCA) REFERENCES PODWYKONAWCY(ID_PODWYKONAWCY) ON DELETE CASCADE ON UPDATE CASCADE
