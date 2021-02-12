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
		SET @ID_TRENERA = (SELECT ID_TRENERA FROM DELETED)
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
@MAIL VARCHAR(30), @HASH_HASLA VARCHAR(40), @PRO BIT
)
as
begin
	DECLARE @ID INT 
	SET @ID = (SELECT TOP 1 ID_OSOBY FROM OSOBA ORDER BY ID_OSOBY DESC)
	SET @ID = @ID+1
	INSERT INTO OSOBA (ID_OSOBY,IMIE,NAZWISKO,TELEFON,ADRES,[ROK URODZENIA])
	VALUES  (@ID, @IMIE, @NAZWISKO,@TELEFON, @ADRES,@rokUrodzenia)
	INSERT INTO KLIENT --(ID_KLIENTA, [RODZAJ CZLONKOWSTWA],PRO_STATUS,NR_SZAFKI,POSIADANY_KARNET)
	VALUES  (@ID,@PRO,@MAIL,@HASH_HASLA);
END
--------------------------------------------------------------
IF OBJECT_ID('PODSUMOWANIE_DNIA', 'P') IS NOT NULL DROP PROC PODSUMOWANIE_DNIA
GO
CREATE PROCEDURE PODSUMOWANIE_DNIA(@ID_OBIEKTU INT) AS -- W ADRESIE MIASTO MUSI BY� PIERWSZE
BEGIN
	DECLARE @WYDATKI INT
	DECLARE @PRZYCHODY INT
	SET @WYDATKI = (SELECT SUM(WYNAGRODZENIE*ILOSC_GODZIN)
	FROM GRAFIK G JOIN PRACOWNIK P ON G.ID_PRACOWNIKA = P.ID_PRACOWNIKA
	WHERE P.ID_OBIEKTU = @ID_OBIEKTU) 
	SET @PRZYCHODY = (SELECT SUM(CENA*ILOSC_SPRZEDARZY) 
	FROM SPRZEDARZE_DNIA S JOIN CENNIK C ON S.RODZAJ_KARNETU = C.TYP_WEJSCIOWKI  
	WHERE S.ID_OBIEKTU = @ID_OBIEKTU)
	DELETE FROM SPRZEDARZE_DNIA WHERE ID_OBIEKTU = @ID_OBIEKTU
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
	PRINT @GODZINA_WEJSCIA

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





	
