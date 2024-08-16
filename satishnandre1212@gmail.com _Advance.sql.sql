--SQL Advance Case Study


--Q1--BEGIN 

select L.[State],T.[Date] from [dbo].[DIM_LOCATION] L
inner join [dbo].[FACT_TRANSACTIONS] T on L.[IDLocation]=T.[IDLocation]
inner join [dbo].[DIM_MODEL] T2 on T.IDMODEL= T2.IDMODEL
where T.[Date] between '01-01-2005' and GETDATE();

--Q1--END



--Q2--BEGIN
	select top 1
[State],SUM([Quantity]) as number_of_qty from [dbo].[DIM_LOCATION] L
inner join [dbo].[FACT_TRANSACTIONS] T on L.[IDLocation]=T.[IDLocation]
inner join [dbo].[DIM_MODEL] D on T.IDMODEL = D.IDMODEL
inner join [dbo].[DIM_MANUFACTURER] M on M.IDMANUFACTURER= D.IDMANUFACTURER
where [Manufacturer_Name] = 'Samsung'
group by [Quantity],[State]
order by SUM([Quantity]) desc;

--Q2--END



--Q3--BEGIN      

select [Model_Name], [ZipCode],[State], count([IDCustomer]) as NO_OF_TRANSACTIONS from [dbo].[DIM_MODEL] M
inner join [dbo].[FACT_TRANSACTIONS] T on M.[IDModel]=T.[IDModel]
inner join [dbo].[DIM_LOCATION] L on T.[IDLocation] = L.[IDLocation]
group by [Model_Name], [ZipCode],[State];
	
--Q3--END



--Q4--BEGIN

select top 1
[IDModel],[Model_Name],[Unit_price] from [dbo].[DIM_MODEL]
order by [Unit_price];

--Q4--END



--Q5--BEGIN

select [Model_Name], avg([Unit_price]) as AVERAGE_PRICE from [dbo].[DIM_MODEL] M
inner join [dbo].[DIM_MANUFACTURER] A on A.[IDManufacturer]=M.[IDManufacturer]
where [Manufacturer_Name] in
(
select top 5 [Manufacturer_Name] from [dbo].[FACT_TRANSACTIONS] T1
inner join [dbo].[DIM_MODEL] M1 on T1.[IDModel]=M1.[IDModel]
inner join [dbo].[DIM_MANUFACTURER] F on F.[IDManufacturer]=M1.[IDManufacturer]
group by [Manufacturer_Name]
order by sum([Quantity])
)
group by [Model_Name]
order by avg([Unit_price]) desc;

--Q5--END



--Q6--BEGIN

select [Customer_Name],
avg([TotalPrice]) as AVERAGE_AMOUNT from [dbo].[DIM_CUSTOMER] C
inner join [dbo].[FACT_TRANSACTIONS] T on C.[IDCustomer]=T.[IDCustomer]
where year([Date])=2009
group by [Customer_Name]
having 
avg([TotalPrice])>500;

--Q6--END
	



--Q7--BEGIN  

select  [Model_Name]
from [dbo].[DIM_MODEL] M
inner join [dbo].[FACT_TRANSACTIONS] T on M.IDModel = T.IDModel
where year([Date]) IN ('2008', '2009', '2010')
group by [Model_Name]
having sum(QUANTITY) >= all (
  select top 5 sum(QUANTITY) as Top5Quantity
   from [dbo].[FACT_TRANSACTIONS] T
    inner join [dbo].[DIM_MODEL] M on T.IDModel = M.IDModel
    where year([Date]) IN ('2008', '2009', '2010')
    group by T.IDMODEL
    order by Top5Quantity desc);

--Q7--END

---Q7:Use intersect to find the common model in 3 years.
-- Query to find models that are in the top 5 for 2008
SELECT M.Model_Name
FROM dbo.DIM_MODEL M
INNER JOIN dbo.FACT_TRANSACTIONS T ON M.IDModel = T.IDModel
WHERE YEAR(T.Date) = 2008
GROUP BY M.Model_Name
HAVING SUM(T.Quantity) >= (
    SELECT MIN(Top5Quantity)
    FROM (
        SELECT TOP 5 SUM(T.Quantity) AS Top5Quantity
        FROM dbo.FACT_TRANSACTIONS T
        WHERE YEAR(T.Date) = 2008
        GROUP BY T.IDModel
        ORDER BY Top5Quantity DESC
    ) AS Top5In2008
)

INTERSECT

-- Query to find models that are in the top 5 for 2009
SELECT M.Model_Name
FROM dbo.DIM_MODEL M
INNER JOIN dbo.FACT_TRANSACTIONS T ON M.IDModel = T.IDModel
WHERE YEAR(T.Date) = 2009
GROUP BY M.Model_Name
HAVING SUM(T.Quantity) >= (
    SELECT MIN(Top5Quantity)
    FROM (
        SELECT TOP 5 SUM(T.Quantity) AS Top5Quantity
        FROM dbo.FACT_TRANSACTIONS T
        WHERE YEAR(T.Date) = 2009
        GROUP BY T.IDModel
        ORDER BY Top5Quantity DESC
    ) AS Top5In2009
)

INTERSECT

-- Query to find models that are in the top 5 for 2010
SELECT M.Model_Name
FROM dbo.DIM_MODEL M
INNER JOIN dbo.FACT_TRANSACTIONS T ON M.IDModel = T.IDModel
WHERE YEAR(T.Date) = 2010
GROUP BY M.Model_Name
HAVING SUM(T.Quantity) >= (
    SELECT MIN(Top5Quantity)
    FROM (
        SELECT TOP 5 SUM(T.Quantity) AS Top5Quantity
        FROM dbo.FACT_TRANSACTIONS T
        WHERE YEAR(T.Date) = 2010
        GROUP BY T.IDModel
        ORDER BY Top5Quantity DESC
    ) AS Top5In2010
);

----Q7---END



--Q8--BEGIN

WITH ManufacturerSales AS (
    SELECT 
        [Manufacturer_Name],
        YEAR([Date]) AS [Year],
        SUM([Quantity]) AS TotalSales,
        DENSE_RANK() OVER (PARTITION BY YEAR([Date]) ORDER BY SUM([Quantity]) DESC) AS SalesRank
    FROM 
        [dbo].[FACT_TRANSACTIONS] T
    JOIN 
        [dbo].[DIM_MODEL] M ON T.IDModel = M.IDModel
    JOIN 
        [dbo].[DIM_MANUFACTURER] MF ON M.IDManufacturer = MF.IDManufacturer
    WHERE 
        YEAR([Date]) IN (2009, 2010)
    GROUP BY
        [Manufacturer_Name], YEAR([Date])
)
SELECT 
    [Manufacturer_Name],
    [Year],
    TotalSales
FROM 
    ManufacturerSales
WHERE 
    SalesRank = 2;


--Q8--END


--Q9--BEGIN
	
select [Manufacturer_Name] from [dbo].[DIM_MANUFACTURER] M
inner join [dbo].[DIM_MODEL] L on M.IDManufacturer=L.IDManufacturer
inner join [dbo].[FACT_TRANSACTIONS] T on L.IDModel=T.IDModel
where year([Date]) = 2010
except
select [Manufacturer_Name] from [dbo].[DIM_MANUFACTURER] M
inner join [dbo].[DIM_MODEL] L on M.IDManufacturer=L.IDManufacturer
inner join [dbo].[FACT_TRANSACTIONS] T on L.IDModel=T.IDModel
where year([Date]) = 2009;

--Q9--END



--Q10--BEGIN
	
select top 10 [IDCustomer],
year([Date]) as Years,avg([TotalPrice]) as spend,avg([Quantity]) as qty,
--lag(avg([TotalPrice])) over (partition by IDCustomer order by year([Date])) as lag_avg
(avg([TotalPrice]))-lag(avg([TotalPrice])) over (partition by IDCustomer order by year([Date]))/ nullif(lag(avg([TotalPrice]))
over (partition by IDCustomer order by year([Date])),0)*100 as per_spend
from [dbo].[FACT_TRANSACTIONS] as F
where [IDCustomer] in
(select [IDCustomer] from (select top 10 [IDCustomer],sum([TotalPrice]) as spend
from [dbo].[FACT_TRANSACTIONS]
group by [IDCustomer]
order by sum([TotalPrice]) desc)a)
group by [IDCustomer],year([Date]);

--Q10--END
	