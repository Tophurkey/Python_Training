/*
SQL Queries to analyze data from https://github.com/owid/covid-19-data/tree/master/public/data on 21-JUL-2021.
The original data was split into two tables dbo.vaccinations and dbo.case_death_hosp to make it easier to work with.
A common ID column was added to the table before splitting called Table_ID.
All data is hosted on a local copy of SQL Express and imported from excel files to populate the Tables.
*/

--======_First Table_=============================================================================================

--======_VIEWS_===================================================================================================
--Creating a view so that I can manipulate and use the data from these queries later without the execution.
CREATE VIEW SumCaseDeathPat AS

--======_CTE_===================================================================================================== 
--Create a Common Table Expression to execute the New Increases Percentages and streamline the nested Alias Tables
WITH cte AS (
SELECT location
,year
,month
,monthyear
,sumnewcase
,sumtotcase
--NULLIF handles the divide by zero errors by not providing a percent increase if none is reported.
,(sumnewcase/NULLIF(LAG(sumnewcase) OVER (ORDER BY year, month),0)*100) AS caseinc
,sumnewdeath
,sumtotdeath
--LAG function is used to see the percent increase month over month
,(sumnewdeath/NULLIF(LAG(sumnewdeath) OVER (ORDER BY year, month),0)*100) AS deathinc
,sumicupat
,sumhosppat
,((sumicupat+sumhosppat)/NULLIF(LAG(sumicupat) OVER (ORDER BY year, month) + LAG(sumhosppat) OVER (ORDER BY year, month),0)*100) AS patinc
FROM(

--======_Alias_====================================================================================================
--Created an alias in order to perform aggregate SUM functions on newly cast columns
SELECT location
--Pulling out the year and month for easy sorting later on and creating monthyear for easy X-Axis in Tableau data.
,DATEPART(year, newdate) AS year
,DATEPART(month, newdate) AS month
,CONVERT(varchar(7), newdate, 120) AS monthyear
--Creating all SUM aggregate functions to turn daily data into monthly data.
,SUM(new_cases) AS sumnewcase
,SUM(total_cases) AS sumtotcase
,SUM(newdeath) AS sumnewdeath
,SUM(totdeath) AS sumtotdeath
,SUM(icupat) AS sumicupat
,SUM(hosppat) AS sumhosppat
FROM (

--======_Cleaning_===================================================================================================
--Need to CAST nvarchar columns as float in order to perform SUM aggregation functions or any other numeric functions
SELECT location
,CAST(case_death_hosp.date AS date) AS newdate 
,new_cases
,total_cases
,CAST(new_deaths AS float) AS newdeath
,CAST(total_deaths AS float) AS totdeath
,CAST(icu_patients AS float) AS icupat
,CAST(hosp_patients AS float) AS hosppat
FROM ProjectsDatabase.dbo.case_death_hosp
--Excluding the Continent only data to allow the country data to be analyzed instead
WHERE continent IS NOT NULL) as alias
--Only looking at February to June as July data was not complete at time of file download
WHERE newdate between '2020-02-01' AND '2021-06-30'
GROUP BY DATEPART(year, newdate), DATEPART(month, newdate), convert(varchar(7), newdate, 120), location) as sum_alias
)
SELECT *
FROM cte
GO

--======_Second Table_============================================================================================

--======_Temp Table_==============================================================================================
--Creating a temp table for manipulating data after the Join and also to cast nvarchar columns to float for SUM.
--Need to Drop Table before creating to prevent endless runtime due to existing table still in memory.
DROP Table if exists #TempCovidTable
Create Table #TempCovidTable
(
[continent] nvarchar(255)
      ,[location] nvarchar(255)
      ,[date] nvarchar(255)
      ,[total_vaccinations] numeric
      ,[people_vaccinated] numeric
      ,[people_fully_vaccinated] numeric
      ,[new_vaccinations] numeric
      ,[population] numeric
	  ,[total_cases] numeric
      ,[new_cases] numeric
      ,[total_deaths] numeric
      ,[new_deaths] numeric
      ,[icu_patients] numeric
      ,[hosp_patients] numeric
)
--Populate the temp table with the joined data
INSERT INTO #TempCovidTable
SELECT
vac.[continent]
      ,vac.[location]
      ,vac.[date]
      ,[total_vaccinations]
      ,[people_vaccinated]
      ,[people_fully_vaccinated]
      ,[new_vaccinations]
      ,vac.[population]
	  ,[total_cases]
      ,[new_cases]
      ,[total_deaths]
      ,[new_deaths]
      ,[icu_patients]
      ,[hosp_patients]
FROM vaccinations vac

--======_JOIN_=====================================================================================================================
--Performing a join on the common ID column to look at data across both tables; could have used the location and date columns alternatively
--Using a LEFT JOIN since we only care about looking at data where both vaccine and other factors can be observed at the Same Time
	LEFT JOIN case_death_hosp AS cdh ON vac.Table_ID = cdh.Table_ID;

SELECT DISTINCT continent
,location
--Calculating a Pearson's R coefficient of Correlation over time by country
,((SUM(x * y) OVER(PARTITION BY location) - (SUM(x) OVER(PARTITION BY location) * SUM(y) OVER(PARTITION BY location)) / NULLIF(COUNT(*) OVER(PARTITION BY location), 0)))
	/ NULLIF(NULLIF((SQRT(SUM(x * x) OVER(PARTITION BY location) - (SUM(x) OVER(PARTITION BY location) * SUM(x) OVER(PARTITION BY location)) /
	NULLIF(COUNT(*) OVER(PARTITION BY location),0))),0) * SQRT(SUM(y * y) OVER(PARTITION BY location) - (SUM(y) OVER(PARTITION BY location) * 
	SUM(y) OVER(PARTITION BY location)) / NULLIF(COUNT(*) OVER(PARTITION BY location),0)),0) AS 'Pearsons r'
FROM(
SELECT location
,continent
,DATEPART(year, date) AS year
,DATEPART(month, date) AS month
--Comparing the Total number of Vaccinations to the number of new cases to check for a correlation
,SUM(total_vaccinations) as x
,SUM(new_cases) as y
FROM #TempCovidTable
GROUP BY continent, location, DATEPART(year, date), DATEPART(month, date)) as vaxalias
ORDER BY [Pearsons r] ASC