USE PROJEKT_BAZY_DANYCH

IF OBJECT_ID('UrlopyCheckDate', 'TR') IS NOT NULL DROP TRIGGER UrlopyCheckDate
GO
CREATE TRIGGER UrlopyCheckDate on URLOPY -- dodawany urlop pracownika nie moze sie nakladac na juz posiadany
AFTER INSERT
AS
	IF EXISTS(
		SELECT * FROM URLOPY AS U_OLD -- urlopy stare 
		JOIN INSERTED AS U_NEW -- urlopy wstawione
		ON ((DATEADD(DAY,U_NEW.CZAS_TRWANIA, U_NEW.DATA_URLOPU) >= U_OLD.DATA_URLOPU)
			 AND (U_NEW.DATA_URLOPU <= DATEADD(DAY,U_OLD.CZAS_TRWANIA, U_OLD.DATA_URLOPU))
			 AND (U_OLD.ID_PRACOWNIKA = U_NEW.ID_PRACOWNIKA))
		WHERE NOT (U_OLD.ID_PRACOWNIKA = U_NEW.ID_PRACOWNIKA AND U_OLD.DATA_URLOPU = U_NEW.DATA_URLOPU)
	) BEGIN
		DELETE FROM URLOPY WHERE ((ID_PRACOWNIKA IN (SELECT ID_PRACOWNIKA FROM inserted)) AND (DATA_URLOPU IN (SELECT DATA_URLOPU FROM inserted)))
		PRINT 'NIE MOZNA WSTAWIC URLOPU! KOLIDUJE Z INNYM URLOPEM!'
	END

	ELSE

	BEGIN
		DECLARE @ID INT  = (SELECT ID_PRACOWNIKA FROM INSERTED)
		DECLARE @URLOP_START DATE = (SELECT DATA_URLOPU FROM INSERTED)
		DECLARE @CZAS_TRWANIA INT = (SELECT CZAS_TRWANIA FROM INSERTED)
		DELETE FROM GRAFIK WHERE ID_PRACOWNIKA = @ID AND DATA BETWEEN @URLOP_START AND DATEADD(DAY, @CZAS_TRWANIA, @URLOP_START)
	END
GO
--------------------------------------------------------------
IF OBJECT_ID('IloscTrenerow', 'FN') IS NOT NULL DROP FUNCTION IloscTrenerow
GO
CREATE FUNCTION IloscTrenerow()
RETURNS INT AS BEGIN
	DECLARE @ILOSC INT = (SELECT COUNT(*) FROM [TRENERZY PERSONALNI])
	RETURN @ILOSC
END
GO
--------------------------------------------------------------
IF OBJECT_ID('SpisPracownikowObiektu', 'P') IS NOT NULL DROP PROC SpisPracownikowObiektu
GO
CREATE PROCEDURE SpisPracownikowObiektu(@ID_OBJ INT) AS BEGIN
	SELECT IMIE, NAZWISKO FROM OSOBA O JOIN PRACOWNIK P ON (O.ID_OSOBY = P.ID_PRACOWNIKA)
	WHERE (P.ID_OBIEKTU = @ID_OBJ)
END
GO
--------------------------------------------------------------
IF OBJECT_ID('IloscPodopiecznych', 'FN') IS NOT NULL DROP FUNCTION IloscPodopiecznych
GO
CREATE FUNCTION IloscPodopiecznych(@ID_TRENERA INT) RETURNS INT
BEGIN
	DECLARE @ILOSC INT
	SET @ILOSC = (SELECT COUNT(*) FROM [KLIENT-TRENER] WHERE (ID_TRENERA = @ID_TRENERA))
	RETURN @ILOSC
END
GO
--------------------------------------------------------------
IF OBJECT_ID('PremiaIloscPodopiecznych', 'TR') IS NOT NULL DROP TRIGGER PremiaIloscPodopiecznych
GO
-- JESLI ILOSC PODOPIECZNYCH JEST WIEKSZA OD 4 TO ZA KAZDEGO KOLEJNEGO PODOPIECZNEGO TRENER DOSTAJE 10% PREMII
-- JESLI WARTOSC ZMIEJSZA SIE NA MNIEJSZA NIZ 4, ODEJMUJEMY PREMIE
CREATE TRIGGER PremiaIloscPodopiecznych ON [KLIENT-TRENER]
AFTER INSERT, DELETE AS
	DECLARE @ID_TRENERA INT
	DECLARE @IloscPodopiecznych INT
	IF EXISTS(SELECT * FROM INSERTED) BEGIN
		SET @ID_TRENERA = (SELECT ID_TRENERA FROM INSERTED)
		SET @IloscPodopiecznych = dbo.IloscPodopiecznych(@ID_TRENERA)
		IF(@IloscPodopiecznych > 4) BEGIN
			UPDATE PRACOWNIK SET [PREMIA(%)] += 0.1 WHERE ID_PRACOWNIKA = @ID_TRENERA
		END
	END

	IF EXISTS(SELECT * FROM DELETED) BEGIN
		SET @ID_TRENERA = (SELECT DISTINCT ID_TRENERA FROM DELETED)
		SET @IloscPodopiecznych = dbo.IloscPodopiecznych(@ID_TRENERA)
		IF(@IloscPodopiecznych >= 4) BEGIN
			UPDATE PRACOWNIK SET [PREMIA(%)] -= 0.1 WHERE ID_PRACOWNIKA = @ID_TRENERA
		END
	END
GO
--------------------------------------------------------------
IF OBJECT_ID('Dodaj_klienta', 'P') IS NOT NULL DROP PROC Dodaj_klienta
GO
create procedure Dodaj_klienta
(
@imie varchar(20),  @nazwisko varchar(20), @telefon varchar(20), @adres varchar(40), @rokUrodzenia INT,
@MAIL VARCHAR(30), @HASLO VARCHAR(40), @PRO BIT
)
as
begin
	DECLARE @HASH_HASLA VARCHAR(40)
	SET @HASH_HASLA  = HASHBYTES('SHA2_256',@HASLO)
	DECLARE @ID INT 
	SET @ID = (SELECT TOP 1 ID_OSOBY FROM OSOBA ORDER BY ID_OSOBY DESC)
	IF @ID IS NOT NULL
		SET @ID = @ID+1
	ELSE 
		SET @ID = 1
	INSERT INTO OSOBA (ID_OSOBY,IMIE,NAZWISKO,TELEFON,ADRES,[ROK URODZENIA])
	VALUES  (@ID, @IMIE, @NAZWISKO,@TELEFON, @ADRES,@rokUrodzenia)
	INSERT INTO KLIENT --(ID_KLIENTA, [RODZAJ CZLONKOWSTWA],PRO_STATUS,NR_SZAFKI,POSIADANY_KARNET)
	VALUES  (@ID,@PRO,@MAIL, @HASH_HASLA );
END
GO

--------------------------------------------------------------
IF OBJECT_ID('DODAJ_PRACOWNIKA', 'P') IS NOT NULL DROP PROC DODAJ_PRACOWNIKA
GO
create procedure DODAJ_PRACOWNIKA
(
@imie varchar(20),  @nazwisko varchar(20), @telefon varchar(20), @adres varchar(40), @rokUrodzenia INT,
@ID_OBIEKTU INT, @WYNAGRODZENIE INT, @STANOWISKO VarChar(15)
)
as
begin
	DECLARE @ID INT 
	SET @ID = (SELECT TOP 1 ID_OSOBY FROM OSOBA ORDER BY ID_OSOBY DESC)
	IF @ID IS NOT NULL
		SET @ID = @ID+1
	ELSE 
		SET @ID = 1
	INSERT INTO OSOBA (ID_OSOBY,IMIE,NAZWISKO,TELEFON,ADRES,[ROK URODZENIA])
	VALUES  (@ID, @IMIE, @NAZWISKO,@TELEFON, @ADRES,@rokUrodzenia)
	INSERT INTO PRACOWNIK
	VALUES  (@ID, 1.0, @ID_OBIEKTU, @WYNAGRODZENIE, @STANOWISKO);
END
GO
--------------------------------------------------------------
IF OBJECT_ID('USUN_PRACOWNIKA', 'P') IS NOT NULL DROP PROC USUN_PRACOWNIKA
GO
create procedure USUN_PRACOWNIKA (@ID INT)
AS BEGIN
	IF EXISTS (SELECT * FROM PRACOWNIK WHERE ID_PRACOWNIKA = @ID) BEGIN
		DELETE FROM PRACOWNIK WHERE ID_PRACOWNIKA = @ID
		DELETE FROM OSOBA WHERE ID_OSOBY = @ID
	END

	ELSE

	BEGIN
		PRINT 'BRAK PRACOWNIKA O PODANYM ID'
	END
END
GO
--------------------------------------------------------------
IF OBJECT_ID('USUN_KLIENTA', 'P') IS NOT NULL DROP PROC USUN_KLIENTA
GO
create procedure USUN_KLIENTA (@ID INT)
AS BEGIN
	IF EXISTS (SELECT * FROM KLIENT WHERE ID_KLIENTA = @ID) BEGIN
		DELETE FROM KLIENT WHERE ID_KLIENTA = @ID
		DELETE FROM OSOBA WHERE ID_OSOBY = @ID

	END

	ELSE

	BEGIN
		PRINT 'BRAK KLIENTA O PODANYM ID'
	END
END
GO
--------------------------------------------------------------
IF OBJECT_ID('WYDATKI_Z_DNIA', 'FN') IS NOT NULL DROP FUNCTION WYDATKI_Z_DNIA
GO
CREATE FUNCTION WYDATKI_Z_DNIA (@ID_OBIEKTU INT, @DATA DATE)
RETURNS INT
AS
BEGIN
DECLARE @Wydatki INT
SET @Wydatki = (SELECT SUM(WYNAGRODZENIE*ILOSC_GODZIN*[PREMIA(%)])
	FROM GRAFIK G JOIN PRACOWNIK P ON G.ID_PRACOWNIKA = P.ID_PRACOWNIKA
	WHERE P.ID_OBIEKTU = @ID_OBIEKTU) + 
	(SELECT SUM(S.Cena_pielegnacji) 
	FROM Pielegnacje P JOIN Szczegoly_Pielegnacji S ON P.ID_pielegnacji = S.ID_PIELEGNACJI 
	WHERE P.ID_OBIEKTU = @ID_OBIEKTU AND S.Data_ZPielegnacji = @DATA)
RETURN @Wydatki
END
GO
--------------------------------------------------------------
IF OBJECT_ID('PRZYCHODY_Z_DNIA', 'FN') IS NOT NULL DROP FUNCTION PRZYCHODY_Z_DNIA 
GO
CREATE FUNCTION PRZYCHODY_Z_DNIA (@ID_OBIEKTU INT)
RETURNS INT
AS
BEGIN
DECLARE @PRZYCHODY INT
SET @PRZYCHODY = (SELECT SUM(CENA*ILOSC_SPRZEDAZY) 
	FROM SPRZEDAZE_DNIA S JOIN CENNIK C ON S.RODZAJ_KARNETU = C.TYP_WEJSCIOWKI  
	WHERE S.ID_OBIEKTU = @ID_OBIEKTU)
RETURN @PRZYCHODY
END
GO
--------------------------------------------------------------
IF OBJECT_ID('PODSUMOWANIE_DNIA', 'P') IS NOT NULL DROP PROC PODSUMOWANIE_DNIA
GO
CREATE PROCEDURE PODSUMOWANIE_DNIA(@ID_OBIEKTU INT) AS -- W ADRESIE MIASTO MUSI BYĆ PIERWSZE
BEGIN
	DECLARE @WYDATKI INT = dbo.WYDATKI_Z_DNIA(@ID_OBIEKTU, GETDATE())
	DECLARE @PRZYCHODY INT = dbo.PRZYCHODY_Z_DNIA(@ID_OBIEKTU)

	DELETE FROM SPRZEDAZE_DNIA WHERE ID_OBIEKTU = @ID_OBIEKTU

	DECLARE @ADRES VARCHAR(20)
	SET @ADRES = (SELECT ADRES FROM OBIEKTY WHERE ID_OBIEKTU = @ID_OBIEKTU)
	INSERT INTO BILANS VALUES(@ID_OBIEKTU, GETDATE(), SUBSTRING(@ADRES, 1, CHARINDEX(' ', @ADRES) - 1), (SELECT NAZWA FROM OBIEKTY WHERE ID_OBIEKTU = @ID_OBIEKTU), @PRZYCHODY, @WYDATKI)
END
GO
--------------------------------------------------------------
IF OBJECT_ID('NIEAUTORYZOWANY_DOSTEP', 'TR') IS NOT NULL DROP TRIGGER NIEAUTORYZOWANY_DOSTEP
GO
CREATE TRIGGER NIEAUTORYZOWANY_DOSTEP ON [Wejscia na obiekty]
AFTER INSERT AS
	DECLARE @ID_KLIENTA INT = (SELECT ID_KLIENTA FROM INSERTED)
	DECLARE @ID_OBIEKTU INT = (SELECT ID_OBIEKTU FROM INSERTED)
	DECLARE @DATA DATETIME = (SELECT DATA FROM INSERTED)
	DECLARE @DZIEN_WEJSCIA VARCHAR(20) = (SELECT DATENAME(WEEKDAY, @Data))
	DECLARE @GODZINA_WEJSCIA INT = (SELECT DATEPART(HOUR, @DATA))

	SET @DZIEN_WEJSCIA = (
		CASE @DZIEN_WEJSCIA
			WHEN 'Monday' THEN 'Poniedzialek'
			WHEN 'Tuesday' THEN 'Wtorek'
			WHEN 'Wednesday' THEN 'Sroda'
			WHEN 'Thursday' THEN 'Czwartek'
			WHEN 'Friday' THEN 'Piatek'
			WHEN 'Saturday' THEN 'Sobota'
			WHEN 'Sunday' THEN 'Niedziela'
		END)

	DECLARE @ID VARCHAR(30) = (SELECT CAST(@ID_OBIEKTU as varchar(10)))

	DECLARE @GODZINA_OTWARCIA INT
	DECLARE @GODZINA_ZAMKNIECIA INT

	DECLARE @QUERY NVARCHAR(150) = 'SELECT @G_O = CAST(SUBSTRING('+@DZIEN_WEJSCIA +',1,1) AS INT), @G_Z = CAST(SUBSTRING('+@DZIEN_WEJSCIA +',3,2) AS INT)  FROM [GODZINY OTWARCIA] WHERE ID_OBIEKTU=' + @ID
	DECLARE @PARAMS NVARCHAR(150) = '@G_O INT OUTPUT, @G_Z INT OUTPUT, @DZIEN_WEJSCIA VARCHAR(20), @ID INT'
	EXECUTE SP_EXECUTESQL @QUERY, @PARAMS,@G_O = @GODZINA_OTWARCIA OUTPUT, @G_Z = @GODZINA_ZAMKNIECIA OUTPUT, @DZIEN_WEJSCIA = @DZIEN_WEJSCIA, @ID = @ID

	IF @GODZINA_WEJSCIA NOT BETWEEN @GODZINA_OTWARCIA AND @GODZINA_ZAMKNIECIA
		BEGIN
		PRINT 'WYKRYTO NIEAUTORYZOWANY DOSTEP!!!'
		PRINT CONCAT('GODZINY OTWARCIA OBIEKTU:', (@GODZINA_OTWARCIA), '-', @GODZINA_ZAMKNIECIA)
		PRINT CONCAT('GODZINA WEJSCIA: ',@GODZINA_WEJSCIA,' ID_KLIENTA: ', @ID_KLIENTA)
		END
GO
--------------------------------------------------------------
IF OBJECT_ID('ZLA_OPINIA', 'TR') IS NOT NULL DROP TRIGGER ZLA_OPINIA
GO
CREATE TRIGGER ZLA_OPINIA ON [OPINIE KLIENTOW]
AFTER INSERT AS
	DECLARE @OCENA INT = (SELECT [OCENA(1-10)] FROM INSERTED)
	DECLARE @MAIL VARCHAR(30) = (SELECT K.MAIL FROM INSERTED I JOIN KLIENT K ON I.ID_KLIENTA = K.ID_KLIENTA)
	IF @OCENA <= 3 
	BEGIN
		EXEC msdb.dbo.sp_send_dbmail
		@PROFILE_NAME = 'myEmail',
		@recipients = @MAIL,
		@body = 'Przykro nam ze nie spelnilismy oczekiwan',
		@subject = 'Negatywna opinia'
	END
		
GO
--------------------------------------------------------------
IF OBJECT_ID('SPIS_KLIENTOW_OBIEKT', 'IF') IS NOT NULL DROP FUNCTION SPIS_KLIENTOW_OBIEKT
GO
CREATE FUNCTION SPIS_KLIENTOW_OBIEKT (@ID_KLIENTA INT, @ID_OBIEKTU INT)
RETURNS TABLE AS RETURN(
	SELECT O.ID_OSOBY, O.IMIE, O.NAZWISKO, A.ID_OBIEKTU FROM OSOBA O JOIN
	(SELECT KK.ID_KLIENTA, C.ID_OBIEKTU  FROM [KLIENT-KARNET] KK JOIN CENNIK C ON KK.ID_KARNETU = C.ID_KARNETU WHERE KK.ID_KLIENTA = @ID_KLIENTA AND C.ID_OBIEKTU = @ID_OBIEKTU) A ON
	A.ID_KLIENTA = O.ID_OSOBY
)
GO
--------------------------------------------------------------
IF OBJECT_ID('SPIS_PRACOWNIKOW_OBIEKT', 'IF') IS NOT NULL DROP FUNCTION SPIS_PRACOWNIKOW_OBIEKT
GO
CREATE FUNCTION SPIS_PRACOWNIKOW_OBIEKT (@ID_OBIEKTU INT)
RETURNS TABLE AS RETURN(
	SELECT O.ID_OSOBY, O.IMIE, O.NAZWISKO FROM OSOBA O JOIN PRACOWNIK K ON O.ID_OSOBY = K.ID_OBIEKTU WHERE K.ID_OBIEKTU = @ID_OBIEKTU
)
GO
--------------------------------------------------------------
IF OBJECT_ID('DODAJ_GRAFIK_OKRES', 'P') IS NOT NULL DROP PROC DODAJ_GRAFIK_OKRES
GO
CREATE PROCEDURE DODAJ_GRAFIK_OKRES (@ID_PRACOWNIKA INT, @OD_DNIA DATE, @ILOSC_DNI INT, @START_PRACY INT, @ILOSC_GODZIN INT) AS
BEGIN
	
	DECLARE @I INT = 0
	WHILE @I < @ILOSC_DNI
	BEGIN
		INSERT INTO GRAFIK VALUES
		(@ID_PRACOWNIKA, DATEADD(DAY, @I, @OD_DNIA), @START_PRACY, @ILOSC_GODZIN)
		SET @I = @I+1
	END
END
GO
--------------------------------------------------------------
IF OBJECT_ID('DODAJ_PROWADZACEGO_GRUPY', 'P') IS NOT NULL DROP PROC DODAJ_PROWADZACEGO_GRUPY
GO
CREATE PROCEDURE DODAJ_PROWADZACEGO_GRUPY (@ID_PRACOWNIKA INT) AS
BEGIN
	INSERT INTO Prowadzacy_grupy VALUES
	(@ID_PRACOWNIKA, (SELECT ID_OBIEKTU FROM PRACOWNIK WHERE ID_PRACOWNIKA = @ID_PRACOWNIKA))
END
GO

--------------------------------------------------------------
IF OBJECT_ID('GRAFIK_GRUPY_NA_KOLEJNY_MIESIAC', 'P') IS NOT NULL DROP PROC GRAFIK_GRUPY_NA_KOLEJNY_MIESIAC
GO
CREATE PROCEDURE GRAFIK_GRUPY_NA_KOLEJNY_MIESIAC (@ID_GRUPY INT) AS
BEGIN
	SELECT B.ID_GRUPY, B.NAZWA_GRUPY, A.DATA, A.GODZINA FROM Grupy_zajeciowe B JOIN
	(SELECT ID_GRUPY, DATA, GODZINA FROM Grafik_Grup WHERE ID_Grupy = @ID_GRUPY AND DATA BETWEEN GETDATE() AND DATEADD(MONTH, 1, GETDATE())) AS A
	ON A.ID_Grupy = B.ID_Grupy
END
GO
--------------------------------------------------------------
IF OBJECT_ID('TOP_10_NAJBARDZIEJ_AKTYWNYCH_KLIENTOW_MIESIACA', 'P') IS NOT NULL DROP PROC TOP_10_NAJBARDZIEJ_AKTYWNYCH_KLIENTOW_MIESIACA
GO
CREATE PROCEDURE TOP_10_NAJBARDZIEJ_AKTYWNYCH_KLIENTOW_MIESIACA AS
BEGIN
	SELECT O.ID_OSOBY, O.IMIE, O.NAZWISKO, [ILOSC WEJSC] FROM 
	(SELECT TOP 10 ID_KLIENTA, COUNT(*) AS [ILOSC WEJSC] FROM [Wejscia na obiekty] WHERE DATA BETWEEN DATEADD(MONTH, -1, GETDATE()) AND GETDATE() GROUP BY ID_KLIENTA) A
	JOIN OSOBA O ON A.ID_KLIENTA = O.ID_OSOBY ORDER BY [ILOSC WEJSC] DESC
END
GO
--------------------------------------------------------------
IF OBJECT_ID('WALIDACJA_UZYTKOWNIKA') IS NOT NULL DROP FUNCTION WALIDACJA_UZYTKOWNIKA
GO
CREATE FUNCTION WALIDACJA_UZYTKOWNIKA (@LOGIN VARCHAR(30), @HASLO VARCHAR(40))
RETURNS BIT
AS
BEGIN
	DECLARE @HASH_HASLA VARCHAR(40)
	SET @HASH_HASLA = HASHBYTES('SHA2_256', @HASLO)
	DECLARE @RETURN_VALUE BIT
	IF EXISTS(SELECT * FROM KLIENT WHERE MAIL = @LOGIN AND HASH_HASLA = @HASH_HASLA)
		SET @RETURN_VALUE = 1
	ELSE SET @RETURN_VALUE = 0
	RETURN @RETURN_VALUE
END 
GO
--------------------------------------------------------------
IF OBJECT_ID('DODAJ_KARNET', 'P') IS NOT NULL DROP PROC DODAJ_KARNET
GO
CREATE PROCEDURE DODAJ_KARNET (@ID_KLIENTA INT, @ID_KARNETU INT) AS
BEGIN
	INSERT INTO [KLIENT-KARNET] VALUES (@ID_KLIENTA, @ID_KARNETU, GETDATE())
	DECLARE @ID_OBIEKTU INT = (SELECT ID_OBIEKTU FROM CENNIK WHERE ID_KARNETU = @ID_KARNETU)
	IF EXISTS (SELECT * FROM SPRZEDAZE_DNIA WHERE ID_OBIEKTU = @ID_OBIEKTU AND RODZAJ_KARNETU = @ID_KARNETU)
		UPDATE SPRZEDAZE_DNIA SET ILOSC_SPRZEDAZY += 1 WHERE ID_OBIEKTU = @ID_OBIEKTU AND RODZAJ_KARNETU = @ID_KARNETU
	ELSE
		INSERT INTO SPRZEDAZE_DNIA VALUES (@ID_OBIEKTU, 1, @ID_KARNETU)
END
GO