WITH cte AS (
SELECT location
,year
,month
,monthyear
,sumnewcase
,sumtotcase
,(sumnewcase/NULLIF(LAG(sumnewcase) OVER (ORDER BY year, month),0)*100) AS caseinc
,sumnewdeath
,sumtotdeath
,(sumnewdeath/NULLIF(LAG(sumnewdeath) OVER (ORDER BY year, month),0)*100) AS deathinc
,sumicupat
,sumhosppat
,((sumicupat+sumhosppat)/NULLIF(LAG(sumicupat) OVER (ORDER BY year, month) + LAG(sumhosppat) OVER (ORDER BY year, month),0)*100) AS patinc
,sumnewvacc
,sumpartvacc
,sumfullvacc
,(sumnewvacc / NULLIF(LAG(sumnewvacc) OVER (ORDER BY year, month),0)*100) AS vaccinc
FROM(
SELECT location
,DATEPART(year, newdate) AS year
,DATEPART(month, newdate) AS month
,CONVERT(varchar(7), newdate, 120) AS monthyear
,SUM(new_cases) AS sumnewcase
,SUM(total_cases) AS sumtotcase
,SUM(newdeath) AS sumnewdeath
,SUM(totdeath) AS sumtotdeath
,SUM(icupat) AS sumicupat
,SUM(hosppat) AS sumhosppat
,SUM(newvacc) AS sumnewvacc
,SUM(partvacc) AS sumpartvacc
,SUM(fullvacc) AS sumfullvacc
FROM (
SELECT location
,CAST(CovidMaster.date AS date) AS newdate 
,new_cases
,total_cases
,CAST(new_deaths AS float) AS newdeath
,CAST(total_deaths AS float) AS totdeath
,CAST(icu_patients AS float) AS icupat
,CAST(hosp_patients AS float) AS hosppat
,CAST(new_vaccinations AS float) AS newvacc
,CAST(people_vaccinated AS float) AS partvacc
,CAST(people_fully_vaccinated AS float) AS fullvacc
FROM ProjectsDatabase.dbo.CovidMaster
WHERE continent IS NOT NULL) as alias
WHERE newdate between '2020-02-01' AND '2021-06-30'
GROUP BY DATEPART(year, newdate), DATEPART(month, newdate), convert(varchar(7), newdate, 120), location) as sum_alias
)
SELECT *
FROM cte
ORDER BY year, month