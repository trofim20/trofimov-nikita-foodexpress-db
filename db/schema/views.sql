-- FOOD-108

set search_path to trofimov_food, exts;

create or replace view how_much_money as
with recursive sales as (
	select date_part('year', order_timestamp)::int y,
		date_part('month', order_timestamp)::int m,
		sum(order_amount) no_comm,
		sum(total_amount) with_comm
	from "order"
	where status = 'доставлен'
	group by 1, 2),
months (n, last_n) as (
	select min(y * 12 + m - 1), max(y * 12 + m - 1)
	from sales
	having count(*) > 0
	union all
	select n + 1, last_n
	from months
	where n < last_n),
pay as (
	select year, month, sum(amount) total_pay
	from courier_pay
	group by year, month),
report as (
	select mo.n,
		coalesce(s.no_comm, 0) no_comm,
		coalesce(s.with_comm, 0) with_comm,
		coalesce(p.total_pay, 0) total_pay
	from months mo
	left join sales s on s.y * 12 + s.m - 1 = mo.n
	left join pay p on p.year * 12 + p.month - 1 = mo.n)
select concat(r.n / 12, '-', case when r.n % 12 + 1 < 10 then '0' end, r.n % 12 + 1) year_month,
	r.no_comm sum_no_commission,
	r.with_comm sum_with_commission,
	r.with_comm - r.no_comm commission,
	lag(r.with_comm - r.no_comm) over w prev_commission,
	r.with_comm - r.no_comm - lag(r.with_comm - r.no_comm) over w commission_diff,
	r.total_pay courier_pay,
	r.with_comm - r.no_comm - r.total_pay net_profit
from report r
window w as (order by r.n)
order by r.n;
