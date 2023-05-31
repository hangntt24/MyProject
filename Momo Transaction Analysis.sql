--I. EDA
--Transid: Mã định danh giao dịch (Primary key)
--Transaction_date: Ngày thực hiện GD
--Customer_id: Mã định danh KH 
--Product_type: Loại Giao dịch
--Transaction_amt: Giá trị GD
--Status_code: trạng thái GD
--Numeric (Định lượng): Transaction_amt
--Categorical (Định tính): Product type, status_code

select 
	Product_type,
	min(Transaction_amt)MIN_AMT, 
	max(Transaction_amt)MAX_AMT,
	avg(Transaction_amt)AVG_AMT,
	var(Transaction_amt)VAR_AMT,
	STDEV(Transaction_amt)STDV_AMT,
	count(*)TRANS_NUM
from [dbo].[trans_data]
group by Product_type;

 --> Statistics, transaction amount are not dramatically different among 3 product types;
 --> Maximum and minimum values of a transaction are 499913 and 20472, respectively.

select min(Transaction_date)DATA_FROM, max(Transaction_date)DATA_TO
from [dbo].[trans_data]
 --> Data ranging from 02-01 -> 31-01-2022

--II. Fearture Engineering 
--Building master table with level Customer (each line matches a distinct customer)

--Favourite product type of customer (Productype with the most number of transaction)
select Customer_id, Product_type FAV_PRODUCT_TYPE, TRANS_NUM HIGHEST_TRANS_NUM from
(
	select Customer_id,Product_type, count(*)TRANS_NUM,
	ROW_NUMBER () over (partition by Customer_id order by count(*) desc)row_
	from trans_data
	group by Customer_id, Product_type
) t
where row_ = 1; 

--The cycle of having transaction (unit: day) and transaction age of each customer 
select Customer_id, round(avg(cast(INTERVAL_TRANS_DAY as float)),2) CYCLE_TRANS_DAY,
DATEDIFF(day, min(Transaction_date), max(Transaction_date)) CUSTOMER_AGE
from 
(
	select Customer_id, Transaction_date,
	lead(Transaction_date,1) over (partition by Customer_id order by Transaction_date)
	Next_transaction_date,
	DATEDIFF(day,Transaction_date,
	lead(Transaction_date,1) over (partition by Customer_id order by Transaction_date))INTERVAL_TRANS_DAY
	from trans_data
) t
where INTERVAL_TRANS_DAY is not null 
group by Customer_id;

--Status of customer (active/inactive)
select Customer_id,
	case when max(Transaction_date) > dateadd(day,-1, (select max(Transaction_date)
	from trans_data)) then 'active'
	else 'inactive' end STATUS
from trans_data
group by Customer_id
order by 1

--III. Combining these feartures into a master table
drop table  if exists master_table_customer_level
;

select t0.Customer_id, t0.MAX_TRANS_AMT, t0.MIN_TRANS_AMT,t0.TRANS_NUM,t0.AVG_TRANS_AMT,
t1.FAV_PRODUCT_TYPE, t1.HIGHEST_TRANS_NUM, t2.CYCLE_TRANS_DAY, t2.CUSTOMER_AGE, t3.STATUS
into master_table_customer_level 
from 
(
	select Customer_id,
	count(*) TRANS_NUM,
	max(Transaction_amt) MAX_TRANS_AMT,
	min(Transaction_amt) MIN_TRANS_AMT,
	round(AVG(Transaction_amt),2) AVG_TRANS_AMT 
	from trans_data
	group by Customer_id
) t0
left join 
(
	select Customer_id, Product_type FAV_PRODUCT_TYPE, TRANS_NUM HIGHEST_TRANS_NUM from
	(
		select Customer_id,Product_type, count(*)TRANS_NUM,
		ROW_NUMBER () over (partition by Customer_id order by count(*) desc)row_
		from trans_data
		group by Customer_id, Product_type
	) t
	where row_ = 1
)t1 on t0.Customer_id = t1.Customer_id
left join
(
	select Customer_id, round(avg(cast(INTERVAL_TRANS_DAY as float)),2) CYCLE_TRANS_DAY,
	DATEDIFF(day, min(Transaction_date), max(Transaction_date)) CUSTOMER_AGE
	from 
	(
		select Customer_id, Transaction_date,
		lead(Transaction_date,1) over (partition by Customer_id order by Transaction_date)
		Next_transaction_date,
		DATEDIFF(day,Transaction_date,
		lead(Transaction_date,1) over (partition by Customer_id order by Transaction_date))INTERVAL_TRANS_DAY
		from trans_data
	) t
	where INTERVAL_TRANS_DAY is not null 
	group by Customer_id
) t2 on t0.Customer_id = t2.Customer_id
left join 
(
	select Customer_id,
	case when max(Transaction_date) > dateadd(day,-1, (select max(Transaction_date)
	from trans_data)) then 'active'
	else 'inactive' end STATUS
from trans_data
group by Customer_id
)t3 on t0.Customer_id = t3.Customer_id
;




