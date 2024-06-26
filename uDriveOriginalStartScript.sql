USE [master]
GO
/****** Object:  Database [uDrive_DB]    Script Date: 1/21/2022 12:17:10 PM ******/
CREATE DATABASE [uDrive_DB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'uDrive_DB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\uDrive_DB.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'uDrive_DB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\uDrive_DB_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [uDrive_DB] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [uDrive_DB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [uDrive_DB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [uDrive_DB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [uDrive_DB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [uDrive_DB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [uDrive_DB] SET ARITHABORT OFF 
GO
ALTER DATABASE [uDrive_DB] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [uDrive_DB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [uDrive_DB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [uDrive_DB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [uDrive_DB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [uDrive_DB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [uDrive_DB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [uDrive_DB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [uDrive_DB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [uDrive_DB] SET  ENABLE_BROKER 
GO
ALTER DATABASE [uDrive_DB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [uDrive_DB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [uDrive_DB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [uDrive_DB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [uDrive_DB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [uDrive_DB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [uDrive_DB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [uDrive_DB] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [uDrive_DB] SET  MULTI_USER 
GO
ALTER DATABASE [uDrive_DB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [uDrive_DB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [uDrive_DB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [uDrive_DB] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [uDrive_DB] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [uDrive_DB] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [uDrive_DB] SET QUERY_STORE = OFF
GO
USE [uDrive_DB]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_KmByRegNum]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

-- изминатите километри от всяко превозно средство
/*CREATE OR ALTER FUNCTION udf_PassedKilometers_v2(@startDate DATE, @endDate DATE)
RETURNS TABLE
AS 
RETURN
(
	SELECT rc.RegNum, v.Brand, v.Model, v.Category, (rc.MileageEnd-rc.MileageBegin) AS 'Изминати километри'
	FROM RentalContracts AS rc
	JOIN Vehicles AS v 
	ON rc.RegNum = v.RegNum
	WHERE HireDate >= @startDate AND ReturnDate <= @endDate
	GROUP BY rc.RegNum
	
	
	
)

GO

SELECT * FROM udf_PassedKilometers_v2('2021-01-01', '2021-03-01') */


CREATE   FUNCTION [dbo].[udf_KmByRegNum](@date DATE, @regNum NVARCHAR(20))
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
/****** Object:  UserDefinedFunction [dbo].[udf_PassedKilometers_v2_1]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   FUNCTION [dbo].[udf_PassedKilometers_v2_1](@startDate DATE, @endDate DATE)
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
/****** Object:  UserDefinedFunction [dbo].[udf_RentIncome]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_RentIncome](@regNum NVARCHAR(10))
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
/****** Object:  UserDefinedFunction [dbo].[udf_RentIncome_v2]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_RentIncome_v2](@category NVARCHAR(9))
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
	SUM((DATEDIFF(DAY, rc.HireDate, rc.ReturnDate) * rbc.DayRent) + ((rc.MileageEnd - rc.MileageBegin) * IIF(c.Company = N'Не', 0.9*v.PriceKm ,v.PriceKm)))
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

GO
/****** Object:  Table [dbo].[Vehicles]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Vehicles](
	[RegNum] [nvarchar](10) NOT NULL,
	[Brand] [nvarchar](10) NOT NULL,
	[Model] [nvarchar](16) NOT NULL,
	[Category] [nvarchar](9) NOT NULL,
	[PriceKm] [numeric](5, 4) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RegNum] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RentalContracts]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RentalContracts](
	[ContractNum] [nvarchar](6) NOT NULL,
	[RenterNum] [int] NOT NULL,
	[RegNum] [nvarchar](10) NOT NULL,
	[HireDate] [datetime] NOT NULL,
	[MileageBegin] [int] NOT NULL,
	[AdvancePayment] [int] NOT NULL,
	[ReturnDate] [datetime] NULL,
	[MileageEnd] [int] NULL,
 CONSTRAINT [PK_RentalContracts] PRIMARY KEY CLUSTERED 
(
	[ContractNum] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_PassedKilometers_v2]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

-- изминатите километри от всяко превозно средство
CREATE   FUNCTION [dbo].[udf_PassedKilometers_v2](@startDate DATE, @endDate DATE)
RETURNS TABLE
AS 
RETURN
(
	SELECT rc.RegNum --v.Brand, v.Model, v.Category, (rc.MileageEnd-rc.MileageBegin) AS 'Изминати километри'
	FROM RentalContracts AS rc
	JOIN Vehicles AS v 
	ON rc.RegNum = v.RegNum
	WHERE HireDate >= @startDate AND ReturnDate <= @endDate
	GROUP BY rc.RegNum
	
)

GO
/****** Object:  UserDefinedFunction [dbo].[udf_CountOfHiring]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

--по вид на превозното средство /Да се дооправи/
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
	SUM((DATEDIFF(DAY, rc.HireDate, rc.ReturnDate) * rbc.DayRent) + ((rc.MileageEnd - rc.MileageBegin) * IIF(c.Company = N'Не', 0.9*v.PriceKm ,v.PriceKm)) - rc.AdvancePayment)
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

GO

SELECT * FROM udf_RentIncome_v2(N'Микробус') */

CREATE FUNCTION [dbo].[udf_CountOfHiring](@stratDate DATE, @endDate DATE)
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
/****** Object:  Table [dbo].[Clients]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Clients](
	[RenterNum] [int] NOT NULL,
	[RenterName] [nvarchar](19) NOT NULL,
	[RenterAdress] [nvarchar](45) NOT NULL,
	[Company] [nvarchar](2) NOT NULL,
	[Phone] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_Clients] PRIMARY KEY CLUSTERED 
(
	[RenterNum] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RentByCategory]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RentByCategory](
	[Category] [nvarchar](9) NOT NULL,
	[DayRent] [int] NOT NULL,
 CONSTRAINT [PK_RentByCategory] PRIMARY KEY CLUSTERED 
(
	[Category] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_LastTenHiring]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

--по вид на превозното средство /Да се дооправи/
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
	SUM((DATEDIFF(DAY, rc.HireDate, rc.ReturnDate) * rbc.DayRent) + ((rc.MileageEnd - rc.MileageBegin) * IIF(c.Company = N'Не', 0.9*v.PriceKm ,v.PriceKm)) - rc.AdvancePayment)
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

GO

SELECT * FROM udf_RentIncome_v2(N'Микробус') */

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
CREATE FUNCTION [dbo].[udf_LastTenHiring]()
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
/****** Object:  UserDefinedFunction [dbo].[udf_FindVehicle]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[udf_FindVehicle](@kindOfVehicle NVARCHAR(9))
RETURNS TABLE 
AS 
RETURN
(
	SELECT RegNum, Brand, Model
	FROM Vehicles
	WHERE Category = @kindOfVehicle
)

GO
/****** Object:  UserDefinedFunction [dbo].[udf_FindVehicle_v2]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

CREATE   FUNCTION [dbo].[udf_FindVehicle_v2](@dayRent INT)
RETURNS TABLE
AS
RETURN
(
SELECT v.RegNum, v.Brand, v.Model, v.Category, c.DayRent
FROM RentByCategory AS c
JOIN Vehicles AS v ON c.Category = v.Category
WHERE DayRent = @dayRent
)
GO
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (1, N'Галена Малинова', N'Разград, ул. "Лудогорец" № 10', N'Не', N'0899101101')
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (2, N'Дафка Екатериновска', N'Чепеларе, ул. "Васил Левски" № 11', N'Не', N'0893203040')
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (3, N'Иванка Лилиева', N'Кубрат, ул. "Княз Борис" № 1 Б', N'Не', N'0876000111')
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (4, N'Никола Пенчев', N'Варна, ул. "Поп Ставри" № 31', N'Не', N'0874321123')
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (5, N'Панайот Владигеров', N'Добрич, ул. "Петко Стайнов" № 12', N'Не', N'0883288880')
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (6, N'Ради Руменов', N'Хасково, ул. "Речна" блок 13, вход А, ап. 3', N'Не', N'0877654321')
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (7, N'Сирма ООД', N'София, бул. "Цариградско шосе" № 234, ет. 10', N'Да', N'0884202404')
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (8, N'Сторми хилс', N'Габрово, ул. "Рачо ковача" № 1 Б', N'Да', N'0888001123')
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (9, N'Трифон Славев', N'Плевен, ул. "Цар Асен" блок 1, етаж 3', N'Не', N'0878121314')
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (10, N'Хепи холидейз', N'Тутракан, ул. "Иван Вазов" № 22, ет. 2', N'Да', N'0894100200')
INSERT [dbo].[Clients] ([RenterNum], [RenterName], [RenterAdress], [Company], [Phone]) VALUES (11, N'Хюве фарма', N'Разград, ул. "Лудогорец" № 21, ет. 13, офис 2', N'Да', N'0876543345')
GO
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0001', 7, N'СА 3456 СХ', CAST(N'2021-01-13T00:00:00.000' AS DateTime), 17340, 200, CAST(N'2021-01-15T00:00:00.000' AS DateTime), 18050)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0002', 10, N'СА 1783 ВА', CAST(N'2021-01-16T00:00:00.000' AS DateTime), 20108, 250, CAST(N'2021-01-23T00:00:00.000' AS DateTime), 22430)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0003', 9, N'В 1222 АВ', CAST(N'2021-01-24T00:00:00.000' AS DateTime), 55463, 300, CAST(N'2021-02-02T00:00:00.000' AS DateTime), 57234)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0004', 6, N'В 9786 ТА', CAST(N'2021-01-30T00:00:00.000' AS DateTime), 81210, 125, CAST(N'2021-02-04T00:00:00.000' AS DateTime), 83545)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0005', 11, N'В 1088 А', CAST(N'2021-02-01T00:00:00.000' AS DateTime), 30404, 175, CAST(N'2021-02-08T00:00:00.000' AS DateTime), 32120)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0006', 1, N'СА 3456 СХ', CAST(N'2021-03-19T00:00:00.000' AS DateTime), 18230, 500, CAST(N'2021-03-24T00:00:00.000' AS DateTime), 20223)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0007', 1, N'СВ 0102 АВ', CAST(N'2021-03-29T00:00:00.000' AS DateTime), 31456, 600, CAST(N'2021-04-05T00:00:00.000' AS DateTime), 33103)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0008', 8, N'СА 1783 ВА', CAST(N'2021-04-22T00:00:00.000' AS DateTime), 22870, 105, CAST(N'2021-04-25T00:00:00.000' AS DateTime), 23656)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0009', 9, N'В 9786 ТА', CAST(N'2021-04-23T00:00:00.000' AS DateTime), 84560, 100, CAST(N'2021-04-30T00:00:00.000' AS DateTime), 85044)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0010', 11, N'СВ 0102 АВ', CAST(N'2021-04-26T00:00:00.000' AS DateTime), 36789, 250, CAST(N'2021-04-29T00:00:00.000' AS DateTime), 37505)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0011', 8, N'В 0599 СН', CAST(N'2021-04-29T00:00:00.000' AS DateTime), 50133, 70, CAST(N'2021-05-01T00:00:00.000' AS DateTime), 51056)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0012', 10, N'В 1222 АВ', CAST(N'2021-04-30T00:00:00.000' AS DateTime), 57313, 250, CAST(N'2021-05-07T00:00:00.000' AS DateTime), 61033)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0013', 7, N'В 0599 СН', CAST(N'2021-05-24T00:00:00.000' AS DateTime), 52003, 105, CAST(N'2021-05-27T00:00:00.000' AS DateTime), 53255)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0014', 9, N'СА 1783 ВА', CAST(N'2021-05-27T00:00:00.000' AS DateTime), 24000, 210, CAST(N'2021-06-02T00:00:00.000' AS DateTime), 26056)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0015', 4, N'В 4501 Н', CAST(N'2021-06-07T00:00:00.000' AS DateTime), 32000, 400, CAST(N'2021-06-12T00:00:00.000' AS DateTime), 34567)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0016', 6, N'СА 3456 СХ', CAST(N'2021-06-24T00:00:00.000' AS DateTime), 20975, 300, CAST(N'2021-06-28T00:00:00.000' AS DateTime), 22500)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0017', 2, N'С 2222 РТ', CAST(N'2021-07-01T00:00:00.000' AS DateTime), 56789, 700, CAST(N'2021-07-07T00:00:00.000' AS DateTime), 57890)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0018', 9, N'СВ 0102 АВ', CAST(N'2021-07-10T00:00:00.000' AS DateTime), 42007, 1000, CAST(N'2021-07-21T00:00:00.000' AS DateTime), 44234)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0019', 9, N'В 0599 СН', CAST(N'2021-08-02T00:00:00.000' AS DateTime), 54011, 175, CAST(N'2021-08-07T00:00:00.000' AS DateTime), 56200)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0020', 11, N'СА 3456 СХ', CAST(N'2021-08-05T00:00:00.000' AS DateTime), 25300, 700, CAST(N'2021-08-12T00:00:00.000' AS DateTime), 26123)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0021', 9, N'СА 1783 ВА', CAST(N'2021-08-18T00:00:00.000' AS DateTime), 26340, 140, CAST(N'2021-08-22T00:00:00.000' AS DateTime), 27504)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0022', 3, N'В 4501 Н', CAST(N'2021-08-20T00:00:00.000' AS DateTime), 34804, 550, CAST(N'2021-08-27T00:00:00.000' AS DateTime), 37345)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0023', 2, N'В 1222 АВ', CAST(N'2021-08-24T00:00:00.000' AS DateTime), 61419, 230, CAST(N'2021-08-31T00:00:00.000' AS DateTime), 63599)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0024', 4, N'СА 1783 ВА', CAST(N'2021-08-29T00:00:00.000' AS DateTime), 27700, 230, CAST(N'2021-09-05T00:00:00.000' AS DateTime), 29355)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0025', 8, N'В 9786 ТА', CAST(N'2021-09-01T00:00:00.000' AS DateTime), 93567, 200, CAST(N'2021-09-10T00:00:00.000' AS DateTime), 94707)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0026', 4, N'В 1088 А', CAST(N'2021-09-13T00:00:00.000' AS DateTime), 32300, 220, CAST(N'2021-09-22T00:00:00.000' AS DateTime), 34512)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0027', 4, N'СА 2332 АС', CAST(N'2021-09-13T00:00:00.000' AS DateTime), 49023, 250, CAST(N'2021-09-24T00:00:00.000' AS DateTime), 50350)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0028', 8, N'В 1222 АВ', CAST(N'2021-09-26T00:00:00.000' AS DateTime), 63877, 215, CAST(N'2021-10-03T00:00:00.000' AS DateTime), 65274)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0029', 10, N'В 1088 А', CAST(N'2021-09-29T00:00:00.000' AS DateTime), 35208, 500, CAST(N'2021-10-20T00:00:00.000' AS DateTime), 38233)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0030', 2, N'В 9786 ТА', CAST(N'2021-09-29T00:00:00.000' AS DateTime), 96245, 80, CAST(N'2021-10-02T00:00:00.000' AS DateTime), 97000)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0031', 1, N'СА 1783 ВА', CAST(N'2021-09-30T00:00:00.000' AS DateTime), 30243, 95, CAST(N'2021-10-03T00:00:00.000' AS DateTime), 31026)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0032', 8, N'В 3313 С', CAST(N'2021-10-06T00:00:00.000' AS DateTime), 21133, 250, CAST(N'2021-10-16T00:00:00.000' AS DateTime), 22673)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0033', 5, N'СА 1783 ВА', CAST(N'2021-10-30T00:00:00.000' AS DateTime), 31500, 270, CAST(N'2021-11-06T00:00:00.000' AS DateTime), 33340)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0034', 1, N'В 4501 Н', CAST(N'2021-11-03T00:00:00.000' AS DateTime), 38053, 700, CAST(N'2021-11-13T00:00:00.000' AS DateTime), 41408)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0035', 10, N'В 1222 АВ', CAST(N'2021-11-13T00:00:00.000' AS DateTime), 65550, 250, CAST(N'2021-11-23T00:00:00.000' AS DateTime), 68277)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0036', 2, N'В 0599 СН', CAST(N'2021-11-17T00:00:00.000' AS DateTime), 57101, 150, CAST(N'2021-11-22T00:00:00.000' AS DateTime), 58890)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0037', 6, N'В 0599 СН', CAST(N'2021-11-25T00:00:00.000' AS DateTime), 59122, 140, CAST(N'2021-11-29T00:00:00.000' AS DateTime), 61335)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0038', 7, N'С 2222 РТ', CAST(N'2021-11-25T00:00:00.000' AS DateTime), 59003, 300, CAST(N'2021-11-29T00:00:00.000' AS DateTime), 59827)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0039', 11, N'В 3313 С', CAST(N'2021-12-03T00:00:00.000' AS DateTime), 23062, 200, CAST(N'2021-12-11T00:00:00.000' AS DateTime), 23994)
INSERT [dbo].[RentalContracts] ([ContractNum], [RenterNum], [RegNum], [HireDate], [MileageBegin], [AdvancePayment], [ReturnDate], [MileageEnd]) VALUES (N'Д-0040', 3, N'С 2222 РТ', CAST(N'2021-12-31T00:00:00.000' AS DateTime), 62454, 200, CAST(N'2022-01-02T00:00:00.000' AS DateTime), 62890)
GO
INSERT [dbo].[RentByCategory] ([Category], [DayRent]) VALUES (N'Комби', 35)
INSERT [dbo].[RentByCategory] ([Category], [DayRent]) VALUES (N'Лека кола', 25)
INSERT [dbo].[RentByCategory] ([Category], [DayRent]) VALUES (N'Лимузина', 100)
INSERT [dbo].[RentByCategory] ([Category], [DayRent]) VALUES (N'Микробус', 75)
GO
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'В 0599 СН', N'Рено', N'Меган', N'Комби', CAST(0.0450 AS Numeric(5, 4)))
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'В 1088 А', N'Фолксваген', N'Голф 4', N'Лека кола', CAST(0.0325 AS Numeric(5, 4)))
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'В 1222 АВ', N'Форд', N'Мондео', N'Комби', CAST(0.0500 AS Numeric(5, 4)))
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'В 3313 С', N'Тойота', N'Ярис', N'Лека кола', CAST(0.0300 AS Numeric(5, 4)))
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'В 4501 Н', N'Мерцедес', N'Спринтер', N'Микробус', CAST(0.0750 AS Numeric(5, 4)))
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'В 9786 ТА', N'Фиат', N'Стило', N'Лека кола', CAST(0.0350 AS Numeric(5, 4)))
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'С 2222 РТ', N'Порше', N'Panamera Turbo S', N'Лимузина', CAST(0.1050 AS Numeric(5, 4)))
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'СА 1783 ВА', N'Фолксваген', N'Пасат', N'Комби', CAST(0.0450 AS Numeric(5, 4)))
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'СА 2332 АС', N'Рено', N'Клио', N'Лека кола', CAST(0.0350 AS Numeric(5, 4)))
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'СА 3456 СХ', N'Мерцедес', N'S - 300 Long', N'Лимузина', CAST(0.0700 AS Numeric(5, 4)))
INSERT [dbo].[Vehicles] ([RegNum], [Brand], [Model], [Category], [PriceKm]) VALUES (N'СВ 0102 АВ', N'Ауди', N'A8 Quattro', N'Лимузина', CAST(0.0650 AS Numeric(5, 4)))
GO
ALTER TABLE [dbo].[RentalContracts]  WITH CHECK ADD  CONSTRAINT [FK_RentalContracts_Clients] FOREIGN KEY([RenterNum])
REFERENCES [dbo].[Clients] ([RenterNum])
GO
ALTER TABLE [dbo].[RentalContracts] CHECK CONSTRAINT [FK_RentalContracts_Clients]
GO
ALTER TABLE [dbo].[RentalContracts]  WITH CHECK ADD  CONSTRAINT [FK_RentalContracts_Vehicles] FOREIGN KEY([RegNum])
REFERENCES [dbo].[Vehicles] ([RegNum])
GO
ALTER TABLE [dbo].[RentalContracts] CHECK CONSTRAINT [FK_RentalContracts_Vehicles]
GO
ALTER TABLE [dbo].[Vehicles]  WITH CHECK ADD  CONSTRAINT [FK_Vehicles_RentByCategory] FOREIGN KEY([Category])
REFERENCES [dbo].[RentByCategory] ([Category])
GO
ALTER TABLE [dbo].[Vehicles] CHECK CONSTRAINT [FK_Vehicles_RentByCategory]
GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteClients]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_DeleteClients] 
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
WHERE RenterNum = @renterNum
GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteRentalContracts]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_DeleteRentalContracts]
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
GO
/****** Object:  StoredProcedure [dbo].[usp_DeleteVehicles]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_DeleteVehicles]
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
GO
/****** Object:  StoredProcedure [dbo].[usp_EditClients]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_EditClients]
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

GO
/****** Object:  StoredProcedure [dbo].[usp_EditRentalContracts]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_EditRentalContracts]
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

GO
/****** Object:  StoredProcedure [dbo].[usp_EditVehicles]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_EditVehicles]
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

GO
/****** Object:  StoredProcedure [dbo].[usp_InputClient]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InputClient]
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

GO
/****** Object:  StoredProcedure [dbo].[usp_InputRentalContracts]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_InputRentalContracts]
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
	INSERT INTO RentalContracts
	VALUES(@contractNum, @renterNum, @regNum, @hireDate, @mileageBegin, @advancePayment, @returnDate, @mileageEnd)

GO
/****** Object:  StoredProcedure [dbo].[usp_InputVehicles]    Script Date: 1/21/2022 12:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_InputVehicles]
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

GO
USE [master]
GO
ALTER DATABASE [uDrive_DB] SET  READ_WRITE 
GO
