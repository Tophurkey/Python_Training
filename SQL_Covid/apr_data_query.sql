SELECT apr_data.location, sum_new_cases, sum_tot_cases--, sum_new_death, sum_tot_death
FROM 
(SELECT TOP (1000)
      [location]
      ,SUM([total_cases]) as sum_tot_cases
      ,SUM(new_cases) as sum_new_cases
      --,SUM([total_deaths]) as sum_tot_death
      --,SUM([new_deaths]) as sum_new_death
  FROM [ProjectsDatabase].[dbo].[CovidMaster]
  WHERE date LIKE '2020-04-%' AND continent IS NOT NULL
  GROUP BY location) AS apr_data