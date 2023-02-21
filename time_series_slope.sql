/****** Script for calc. trends in time series - used for drought  ******/
--- info used: ---https://medium.com/analytics-vidhya/advanced-sql-time-series-analysis-fd40eaa08fa3


USE [ETC_ULS_Sandbox]
go

drop table if exists [ETC_ULS_Sandbox].[cubes].[C_DroughtImpact2022_assessment_version_v3_pivot_test_615]
go

SELECT CAST([year] as int) as [year]
      ,[AreaHa]
      ,[SMA -1 LINT-1 Area]
      ,[SMA-1 LINT0 Area]
      ,[CLC00]
      ,[SMA-1 Area]
      ,[Admin]
      ,[Env]
      ,[CLC18]
      ,[sma gs avg]
      ,[SMA-1 LINT-1]
      ,[SMA-1 LINT0]
      ,[CLC0018]
      ,[SMA-1 LINT-05]
      ,[SMA-1 LINT-05 Area]
      ,[LINT anom]
      ,[SMA-1]


	  into [ETC_ULS_Sandbox].[cubes].[C_DroughtImpact2022_assessment_version_v3_pivot_test_615]
  FROM [ETC_ULS_Sandbox].[cubes].[C_DroughtImpact2022_assessment_version_v3_pivot]
  where [Admin] =615

  go

  SELECT  
  [year]
      ,sum([AreaHa]) as Areaha
    ----  ,[SMA -1 LINT-1 Area]
    ----  ,[SMA-1 LINT0 Area]
    ----  ,[CLC00]
     ---- ,[SMA-1 Area]
      ,[Admin]
     ---- ,[Env]
    ----  ,[CLC18]
   ----   ,[sma gs avg]
   ----   ,[SMA-1 LINT-1]
    ----  ,[SMA-1 LINT0]
    ----  ,[CLC0018]
    ---  ,[SMA-1 LINT-05]
      ,sum([SMA-1 LINT-05 Area]) as SMA1LIN05Area
     ---- ,[LINT anom]
   ----   ,[SMA-1]
  into  [ETC_ULS_Sandbox].[cubes].[C_DroughtImpact2022_assessment_version_v3_pivot_test_615_2]
  FROM [ETC_ULS_Sandbox].[cubes].[C_DroughtImpact2022_assessment_version_v3_pivot_test_615]
  group by [Admin],[year]

  go

---https://medium.com/analytics-vidhya/advanced-sql-time-series-analysis-fd40eaa08fa3
--Linear Regression Formula: 
-- c = intercept--
--c is the constant value — this part of the function does not change.
--
--m = slope--
--m is the gradient of the line.





--# x_bar & y_bar
SELECT
        [year], AVG([year]) OVER() as x_bar,
        SMA1LIN05Area, AVG(SMA1LIN05Area) OVER() as y_bar
    FROM 
   
   [ETC_ULS_Sandbox].[cubes].[C_DroughtImpact2022_assessment_version_v3_pivot_test_615_2] order by [year];
go


---Second move, find intercept and slope values using this query.

  SELECT slope, 
            y_bar_max - x_bar_max * slope as intercept
    FROM
        (SELECT SUM(([year] - x_bar) * (SMA1LIN05Area - y_bar)) / SUM(([year] - x_bar) * ([year]- x_bar)) as slope,
                MAX(x_bar) as x_bar_max,
                MAX(y_bar) as y_bar_max
        FROM 
            (SELECT [year], AVG([year]) OVER() as x_bar,
                    SMA1LIN05Area, AVG(SMA1LIN05Area) OVER() as y_bar
            FROM [ETC_ULS_Sandbox].[cubes].[C_DroughtImpact2022_assessment_version_v3_pivot_test_615_2]
            ) data1
		
        ) data2 	

go
--- trendline

  WITH trend_line as
        (SELECT slope, 
                y_bar_max - x_bar_max * slope as intercept
         FROM
            (SELECT SUM(([year] - x_bar) * (SMA1LIN05Area - y_bar)) / SUM(([year] - x_bar) * ([year]- x_bar)) as slope,
                    MAX(x_bar) as x_bar_max,
                    MAX(y_bar) as y_bar_max
            FROM 
                (SELECT [year], AVG([year]) OVER() as x_bar,
                        SMA1LIN05Area, AVG(SMA1LIN05Area) OVER() as y_bar
                 FROM  [ETC_ULS_Sandbox].[cubes].[C_DroughtImpact2022_assessment_version_v3_pivot_test_615_2]
                ) data1
            ) data2
        )
    
    SELECT  [year],SMA1LIN05Area,
            ([year] * (SELECT slope FROM trend_line) + (SELECT intercept FROM trend_line)) as profit_trend_line
    FROM [ETC_ULS_Sandbox].[cubes].[C_DroughtImpact2022_assessment_version_v3_pivot_test_615_2]
	order by [year];
