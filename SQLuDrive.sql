 -- търсене на превозно средство
/*CREATE OR ALTER FUNCTION udf_FindVehicle(@kindOfVehicle NVARCHAR(9))
RETURNS TABLE 
AS 
RETURN
(
	SELECT RegNum, Brand, Model
	FROM Vehicles
	WHERE Category = @kindOfVehicle
)

GO

SELECT * FROM dbo.udf_FindVehicle('Лимузина') */

/*CREATE OR ALTER FUNCTION udf_FindVehicle_v2(@dayRent INT)
RETURNS TABLE
AS
RETURN
(
	SELECT v.RegNum, v.Brand, v.Model, c.DayRent
	FROM RentByCategory AS c
	JOIN Vehicles AS v ON c.Category = v.Category
	WHERE DayRent = @dayRent
)
GO

SELECT * FROM udf_FindVehicle_v2(25) */

--изминатите километри от всяко превозно средство - ежедневно (чрез зададена като параметър дата):
/*CREATE OR ALTER FUNCTION udf_PassedKilometers(@date DATE)
RETURNS @tbPassedKilometers TABLE 
(
	RegNum NVARCHAR(10),
	Brand NVARCHAR(10),
	Model NVARCHAR(16),
	Category NVARCHAR(9),
	Kilometers INT
)
AS
BEGIN
	INSERT INTO @tbPassedKilometers
	(
		RegNum, Brand, Model, Category, Kilometers
	) 
	SELECT rc.RegNum AS [Рег. номер], 
		v.Brand AS [Марка], 
		v.Model AS [Модел], 
		v.Category AS [Категория],
		MAX(rc.MileageEnd) AS [Километри]
	FROM RentalContracts AS rc
	JOIN Vehicles AS v ON rc.RegNum = v.RegNum
	WHERE rc.ReturnDate <= @date
	GROUP BY rc.RegNum, v.Brand, v.Model, v.Category
	RETURN
END

GO

SELECT * FROM udf_PassedKilometers('2021-04-01')
GO  */

-- изминатите километри от всяко превозно средство за определен период от време
/*CREATE OR ALTER FUNCTION udf_KmByRegNum(@date DATE, @regNum NVARCHAR(20))
RETURNS INT AS 
BEGIN 
	DECLARE @res INT
	SELECT @res = MAX(rc.MileageEnd) 
	FROM RentalContracts AS rc
	WHERE rc.ReturnDate <= @date AND rc.RegNum = @regNum
	GROUP BY rc.RegNum
	RETURN @res
END

GO

CREATE OR ALTER FUNCTION udf_PassedKilometers_v2_1(@startDate DATE, @endDate DATE)
RETURNS 
	@tblPassedKm TABLE
	(
		RegNum NVARCHAR(10),
		Brand NVARCHAR(10),
		Model NVARCHAR(16),
		Category NVARCHAR(9),
		Kilometers INT
	)
AS 
BEGIN 
	
	
	INSERT INTO @tblPassedKm
	(
		RegNum, Brand, Model, Category, Kilometers
	)
	SELECT rc.RegNum,
	v.Brand,
	v.Model,
	v.Category,
	MAX(rc.MileageEnd) 
	FROM RentalContracts AS rc
	JOIN Vehicles AS v 
	ON rc.RegNum = v.RegNum
	WHERE rc.ReturnDate <= @endDate
	GROUP BY rc.RegNum, v.Brand, v.Model, v.Category
	
	UPDATE @tblPassedKm 
	SET Kilometers = Kilometers - ISNULL(dbo.udf_KmByRegNum(@startDate, RegNum), 0)
	
RETURN
END

GO

SELECT * FROM udf_PassedKilometers_v2_1('2021-09-01', '2021-10-01') */

--получените приходи от отдаване на превозно средство под наем:
--по превозно средство (според рег. номер, зададен като параметър)
/*CREATE OR ALTER FUNCTION udf_RentIncome(@regNum NVARCHAR(10))
RETURNS @tbRentIncome TABLE
(
	RegNum NVARCHAR(10),
	Brand NVARCHAR(10),
	Model NVARCHAR(16),
	Category NVARCHAR(9),
	Price INT
)
AS
BEGIN
	INSERT INTO @tbRentIncome
	(
		RegNum, Brand, Model, Category, Price
	)
	SELECT rc.RegNum,
	v.Brand,
	v.Model,
	v.Category,
	SUM((DATEDIFF(DAY, rc.HireDate, rc.ReturnDate) * rbc.DayRent) + ((rc.MileageEnd - rc.MileageBegin) * v.PriceKm))
	FROM RentalContracts AS rc
	JOIN Vehicles AS v 
	ON rc.RegNum = v.RegNum
	JOIN RentByCategory AS rbc 
	ON rbc.Category = v.Category
	WHERE @regNum = rc.RegNum
	GROUP BY rc.RegNum, v.Brand, v.Model, v.Category
	RETURN
END

GO

SELECT * FROM udf_RentIncome(N'В 1222 АВ')*/

--SELECT * FROM udf_RentIncome(N'В 4501 Н')

--по вид на превозното средство 
/*CREATE OR ALTER FUNCTION udf_RentIncome_v2(@category NVARCHAR(9))
RETURNS @tbRentIncome_v2 TABLE
(
	Category NVARCHAR(9),
	Price INT
)
AS
BEGIN
	
	INSERT INTO @tbRentIncome_v2
	(
		 Category, Price
	)
	SELECT v.Category,
	SUM((DATEDIFF(DAY, rc.HireDate, rc.ReturnDate) * rbc.DayRent) + 
		((rc.MileageEnd - rc.MileageBegin) * IIF(c.Company = N'Не', 0.9*v.PriceKm ,v.PriceKm)))
	FROM RentalContracts AS rc
	JOIN Vehicles AS v
	ON rc.RegNum = v.RegNum
	JOIN Clients AS c
	ON c.RenterNum = rc.RenterNum
	JOIN RentByCategory AS rbc 
	ON rbc.Category = v.Category
	WHERE rbc.Category = @category
	GROUP BY v.Category

	RETURN
END

GO */

--SELECT * FROM udf_RentIncome_v2(N'Лимузина') 

--по клиент(по част от името на клиента)
/*CREATE OR ALTER FUNCTION udf_RentIncome_v3(@rentName NVARCHAR(19))
RETURNS @tbRentIncome_v3 TABLE
(
	RenterName NVARCHAR(19),
	Company NVARCHAR(2),
	Price INT
)
AS
BEGIN	
	INSERT INTO @tbRentIncome_v3
	(
		RenterName, Company, Price
	)
	SELECT cl.RenterName,
		cl.Company,
		SUM((DATEDIFF(DAY, rc.HireDate, rc.ReturnDate) * rbc.DayRent) + ((rc.MileageEnd - rc.MileageBegin) * IIF(cl.Company = N'НЕ', 0.9 * v.PriceKm, v.PriceKm)))
	FROM RentalContracts AS rc
	JOIN Vehicles AS v ON rc.RegNum = v.RegNum
	JOIN RentByCategory AS rbc ON rbc.Category = v.Category
	JOIN Clients AS cl ON cl.RenterNum = rc.RenterNum
	WHERE RenterName LIKE CONCAT('%', @rentName, '%')
	GROUP BY cl.RenterName, cl.Company
	RETURN
END

GO

SELECT * FROM udf_RentIncome_v3(N'а') */
--GO

--извеждане на авансово платена сума и остатък за доплащане по всеки договор
/*CREATE OR ALTER FUNCTION udf_RestBalance(@contrNum NVARCHAR(6))
RETURNS TABLE 
AS
RETURN
(
	SELECT rc.ContractNum,
		rc.AdvancePayment,
		SUM((DATEDIFF(DAY, rc.HireDate, rc.ReturnDate) * rbc.DayRent) + 
		((rc.MileageEnd - rc.MileageBegin) * IIF(cl.Company = N'НЕ', 0.9 * v.PriceKm, v.PriceKm)) - rc.AdvancePayment) as RestPrice
	FROM RentalContracts AS rc
	JOIN Vehicles AS v ON rc.RegNum = v.RegNum
	JOIN RentByCategory AS rbc ON rbc.Category = v.Category
	JOIN Clients AS cl ON cl.RenterNum = rc.RenterNum
	WHERE @contrNum = rc.ContractNum
	GROUP BY rc.ContractNum, rc.AdvancePayment
)

GO

SELECT * FROM udf_RestBalance(N'Д-0001') */

--извеждане на броя на наеманията на превозно средство за период
/*CREATE FUNCTION udf_CountOfHiring(@stratDate DATE, @endDate DATE)
RETURNS TABLE
AS 
RETURN
(
	SELECT RegNum, COUNT(*) AS 'Брой наемания за периода'
	FROM RentalContracts
	WHERE HireDate >= @stratDate AND ReturnDate <= @endDate
	GROUP BY RegNum
)

GO

SELECT * FROM udf_CountOfHiring('2021-01-01', '2021-05-01')*/

-- извеждане на последните 10 наемания, подредени по дата на наемане
/*CREATE FUNCTION udf_LastTenHiring()
RETURNS TABLE
AS
RETURN 
(
	SELECT TOP(10) rc.ContractNum, cl.RenterName, rc.RegNum, v.Brand, v.Category, rc.HireDate, rc.ReturnDate
	FROM RentalContracts AS rc
	JOIN Vehicles AS v 
	ON rc.RegNum = v.RegNum
	JOIN RentByCategory AS rbc
	ON rbc.Category = v.Category
	JOIN Clients AS cl
	ON cl.RenterNum = rc.RenterNum
	ORDER BY rc.HireDate DESC
)

GO

SELECT * FROM udf_LastTenHiring() */


-- Въвеждане на данни:
-- за въвеждане на клиент
/*CREATE PROCEDURE usp_InputClient
	(
		@renterNum INT,
		@renterName NVARCHAR(19), 
		@renterAdress NVARCHAR(45), 
		@company NVARCHAR(2), 
		@phone NVARCHAR(10)
	)
AS 
	INSERT INTO Clients
	VALUES(@renterNum, @renterName, @renterAdress, @company, @phone)

GO */

--EXEC usp_InputClient 12, 'Петър Иванов', 'Варна, ул."Царевец" № 15', 'Не', '0887694531'

-- за въвеждане на автомобил
/*CREATE PROCEDURE usp_InputVehicles
	(
		@regNum NVARCHAR(10), 
		@brand NVARCHAR(10),
		@model NVARCHAR(16),
		@category NVARCHAR(9),
		@priceKm NUMERIC(5, 4)
	)
AS
	INSERT INTO Vehicles
	VALUES (@regNum, @brand, @model, @category, @priceKm)

GO*/
--EXEC usp_InputVehicles 'В 6969 ГВ', 'Порше', '911 Turbo S', 'Лека кола', 0.1569

-- за сключване на нов договор
/*CREATE PROC usp_InputRentalContracts
	(
		@contractNum NVARCHAR(6),
		@renterNum INT, 
		@regNum NVARCHAR(10),
		@hireDate DATE,
		@mileageBegin INT,  -- Да е след последният регистриран mileageEnd
		@advancePayment INT,
		@returnDate DATE, -- Да е след hireDate
		@mileageEnd INT  -- Да е след mileageBegin
	)
AS
	INSERT INTO RentalContracts
	VALUES(@contractNum, @renterNum, @regNum, @hireDate, @mileageBegin, @advancePayment, @returnDate, @mileageEnd)

GO */
--EXEC usp_InputRentalContracts N'Д-0041', 5, 'В 1088 А', '2022-01-17', 17000, 500, '2022-01-21', 18000


--Редактиране на данни: 
-- на клиент
/*CREATE PROC usp_EditClients
	(
		@renterNum INT, 
		@renterName NVARCHAR(19), 
		@renterAdress NVARCHAR(45), 
		@company NVARCHAR(2), 
		@phone NVARCHAR(10)
	)
AS
	IF NOT EXISTS
		(
			SELECT *
			FROM Clients
			WHERE RenterNum = @renterNum
		)
	BEGIN
		PRINT'Клиент с такъв номер не съществува. Моля опитайте с друг номер!'
		RETURN
	END

	UPDATE Clients 
	SET RenterName = ISNULL(@renterName, RenterName), 
		RenterAdress = ISNULL(@renterAdress, RenterAdress),
		Company = ISNULL(@company, Company),
		Phone = ISNULL(@phone, Phone)

	WHERE RenterNum = @renterNum

GO */

--EXEC usp_EditClients 12, 'Петър Младенов', 'Варна, ул."Прилеп" № 11', 'Не', '0887694531'

-- редактиране на автомобил 
/*CREATE PROC usp_EditVehicles
(
	@regNum NVARCHAR(10),
	@brand NVARCHAR(10),
	@model NVARCHAR(16),
	@category NVARCHAR(9),
	@priceKm numeric(5, 4)
)
AS
IF NOT EXISTS
	(
		SELECT *
		FROM Vehicles
		WHERE RegNum = @regNum
	)
BEGIN
	PRINT 'Автомобил с такъв номер не съществува. Моля опитайте с друг номер!'
	RETURN
END
	UPDATE Vehicles
	SET RegNum = ISNULL(@regNum, RegNum),
		Brand = ISNULL(@brand, Brand),
		Model = ISNULL(@model, Model),
		Category = ISNULL(@category, Category),
		PriceKm = ISNULL(@priceKm, PriceKm)

	WHERE RegNum = @regNum

GO */

--EXEC usp_EditVehicles 'В 6969 ГВ', 'Порше', '817 Spyder', 'Лека кола', 0.0690

-- редактиране на договор
/*CREATE PROC usp_EditRentalContracts
(
	@contractNum NVARCHAR(6),
	@renterNum INT,
	@regNum NVARCHAR(10),
	@hireDate DATE,
	@mileageBegin INT,
	@advancePayment INT,
	@returnDate DATE,
	@mileageEnd INT
)
AS 
IF NOT EXISTS
	(
		SELECT *
		FROM RentalContracts
		WHERE ContractNum = @contractNum
	)
BEGIN
	PRINT 'Договор с такъв номер не съществува. Моля опитайте с друг номер!'
	RETURN
END

	UPDATE RentalContracts
	SET ContractNum = ISNULL(@contractNum, ContractNum),
		RenterNum = ISNULL(@renterNum, RenterNum),
		RegNum = ISNULL(@regNum, RegNum),
		HireDate = ISNULL(@hireDate, HireDate),
		MileageBegin = ISNULL(@mileageBegin, MileageBegin),
		AdvancePayment = ISNULL(@advancePayment, AdvancePayment),
		ReturnDate = ISNULL(@returnDate, ReturnDate),
		MileageEnd = ISNULL(@mileageEnd, MileageEnd)

	WHERE ContractNum = @contractNum

GO */

--EXEC usp_EditRentalContracts N'Д-0041', 6, 'В 1088 А', '2022-01-17', 35000, 500, '2022-01-21', 38000


-- Изтриване на данни: 
	-- изриване на клиент
/*CREATE PROC usp_DeleteClients 
	(
		@renterNum INT
	)
AS 
IF NOT EXISTS
	(
		SELECT *
		FROM Clients
		WHERE RenterNum = @renterNum
	)
BEGIN
	PRINT'Клиент с такъв номер не съществува. Моля опитайте с друг номер!'
	RETURN
END

IF EXISTS
	(
		SELECT *
		FROM RentalContracts
		WHERE RenterNum = @renterNum
	)
BEGIN
	PRINT'Записът не може да бъде изтрит, защото участва в други записи'
	RETURN
END

DELETE 
FROM Clients
WHERE RenterNum = @renterNum */

--EXEC usp_DeleteClients 12

	--изтриване на автомобил
/*CREATE PROC usp_DeleteVehicles
(
	@regNum NVARCHAR(10)
)
AS
IF NOT EXISTS
	(
		SELECT *
		FROM Vehicles
		WHERE RegNum = @regNum
	)
BEGIN
	PRINT 'Автомобил с такъв номер не съществува. Моля опитайте с друг номер!'
	RETURN
END

IF EXISTS
	(
		SELECT *
		FROM RentalContracts
		WHERE RegNum = @regNum
	)
BEGIN
	PRINT 'Засписът не може да бъде изтрит, защото участва в други записи!'
	RETURN
END

DELETE
FROM Vehicles
WHERE RegNum = @regNum 
GO*/
--EXEC usp_DeleteVehicles 'В 6969 ГВ'

	--изтриване на договор
/*CREATE PROC usp_DeleteRentalContracts
(
	@contractNum NVARCHAR(6)
)
AS
IF NOT EXISTS
	(
		SELECT *
		FROM RentalContracts
		WHERE ContractNum = @contractNum
	)
BEGIN
	PRINT 'Договор с такъв номер не съществува. Моля опитайте с друг номер!'
	RETURN
END

DELETE
FROM RentalContracts
WHERE ContractNum = @contractNum
GO */
--EXEC usp_DeleteRentalContracts 'Д-0041'
