create database EcommerceCustomerAnalytics;
use EcommerceCustomerAnalytics;

select count(*) as years_2009_2010 from dbo.[Year 2009-2010];
select count(*) as years_2010_2011 from dbo.[Year 2010-2011];

-- COMBINING BOTH YEARS AND CONVERTING DATA TYPES SAFELY
drop table if exists dbo.RetailCombined;
go

select 
	Invoice, 
	StockCode, 
	Description, 
	Quantity,
	coalesce(
		try_convert(datetime2, InvoiceDate, 120),
		try_convert(datetime2, InvoiceDate, 105)
	) as InvoiceDate,
	Try_convert(decimal(10,2), Price) as Price,
	customer_ID, 
	Country, 
	'2009-2010' as SourceSheet
into dbo.RetailCombined
from dbo.[Year 2009-2010]

union all

select 
	Invoice, 
	StockCode, 
	Description,
	Quantity,
	coalesce(
		try_convert(datetime2, InvoiceDate, 120),
		try_convert(datetime2, InvoiceDate, 105)
	) as InvoiceDate,
	Try_convert(decimal(10,2), Price) as Price,
	customer_ID, 
	Country, 
	'2010-2011' as SourceSheet
from dbo.[Year 2010-2011]
go
	

select * from dbo.[RetailCombined];
select count(*) as total_rows from dbo.[RetailCombined];
select count(*) as failed_dates from dbo.RetailCombined where InvoiceDate is null;
select count(*) as failed_prices from dbo.RetailCombined where Price is null;

-- EXPLORATORY DATA ANALYSIS --

-- Missing Customer IDs
select count(*) as misssing_customer_IDs 
from dbo.RetailCombined
where customer_ID is null;

-- Negative & Zero Quantity
select count(*) as negative_zero_qty
from dbo.RetailCombined
where Quantity <= 0;

-- missing description
select count(*) as missing_description
from dbo.RetailCombined
where Description is null;

-- exact duplicate rows
select
	Invoice,
	StockCode,
	Description,
	Quantity,
	InvoiceDate,
	Price,
	Customer_ID,
	Country,
	count(*) as exact_dup_count
from dbo.RetailCombined
group by Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
having count(*) > 1;

-- deduplicating and creating the final clean table

WITH Deduped AS (
	SELECT *, 
		ROW_NUMBER() OVER (
			PARTITION BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, customer_ID, Country
			ORDER BY (SELECT NULL)
		) AS RowNum
	FROM dbo.RetailCombined
)
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, customer_ID, Country, SourceSheet
INTO dbo.RetailCleaned
FROM Deduped
where RowNum = 1;

select count(*) as total_rows from dbo.RetailCleaned;