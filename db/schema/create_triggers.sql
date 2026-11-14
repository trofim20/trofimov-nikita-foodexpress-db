-- FOOD-101, FOOD-105

set search_path to trofimov_food, exts;

create or replace function order_sums() returns trigger as $$
begin
	if tg_op = 'UPDATE' and new.order_amount != old.order_amount
		and exists (select 1 from payment where order_id = old.order_id) then
		raise exception 'по заказу % уже есть оплата, сумму менять нельзя', old.order_id;
	end if;
	new.commission = round(new.order_amount * 0.1, 2);
	new.total_amount = new.order_amount + new.commission;
	return new;
end;
$$ language plpgsql;

create trigger tg_order_sums
before insert or update of order_amount, commission, total_amount on "order"
for each row execute procedure order_sums();

create or replace function check_position() returns trigger as $$
begin
	if (select restaurant_id from product where product_id = new.product_id)
		!= (select restaurant_id from "order" where order_id = new.order_id) then
		raise exception 'блюдо % и заказ % из разных ресторанов', new.product_id, new.order_id;
	end if;
	return new;
end;
$$ language plpgsql;

create trigger tg_order_structure_position
before insert or update on order_structure
for each row execute procedure check_position();

create or replace function check_payment() returns trigger as $$
declare
	v_total numeric;
begin
	select total_amount into v_total
	from "order"
	where order_id = new.order_id;

	if new.amount is null then
		new.amount = v_total;
	elseif new.amount != v_total then
		raise exception 'сумма попытки % не совпадает с суммой заказа %', new.amount, v_total;
	end if;
	return new;
end;
$$ language plpgsql;

create trigger tg_payment_amount
before insert or update on payment
for each row execute procedure check_payment();

create or replace function refresh_pay_status() returns trigger as $$
declare
	v_oid uuid;
begin
	if tg_op = 'DELETE' then
		v_oid = old.order_id;
	else
		v_oid = new.order_id;
	end if;

	update "order"
	set pay_status =
		case
			when 'успех' in (select status from payment where order_id = v_oid) then 'оплачен'
			when 'в_обработке' in (select status from payment where order_id = v_oid) then 'ожидает'
			when 'ошибка' in (select status from payment where order_id = v_oid) then 'ошибка'
			else 'ожидает'
		end::order_payment_state
	where order_id = v_oid;
	return null;
end;
$$ language plpgsql;

create trigger tg_payment_pay_status
after insert or update or delete on payment
for each row execute procedure refresh_pay_status();

create or replace function review_object_check() returns trigger as $$
begin
	if new.entity_type = 'ресторан' and not exists (
		select 1 from "order" where order_id = new.order_id and restaurant_id = new.entity_id) then
		raise exception 'заказ % сделан не в ресторане %', new.order_id, new.entity_id;
	end if;
	if new.entity_type = 'блюдо' and not exists (
		select 1 from order_structure where order_id = new.order_id and product_id = new.entity_id) then
		raise exception 'в заказе % нет блюда %', new.order_id, new.entity_id;
	end if;
	return new;
end;
$$ language plpgsql;

create trigger tg_review_object
before insert or update on review
for each row execute procedure review_object_check();

create or replace function recalc_rating(p_type review_target, p_id uuid) returns void as $$
begin
	if p_type = 'блюдо' then
		update product
		set rating = (select round(avg(r.rating), 2) from review r where r.entity_type = p_type and r.entity_id = p_id)
		where product_id = p_id;
	elseif p_type = 'ресторан' then
		update restaurant
		set rating = (select round(avg(r.rating), 2) from review r where r.entity_type = p_type and r.entity_id = p_id)
		where restaurant_id = p_id;
	end if;
end;
$$ language plpgsql;

create or replace function rating_change() returns trigger as $$
begin
	if tg_op != 'INSERT' then
		perform recalc_rating(old.entity_type, old.entity_id);
	end if;
	if tg_op != 'DELETE' then
		perform recalc_rating(new.entity_type, new.entity_id);
	end if;
	return null;
end;
$$ language plpgsql;

create trigger tg_review_rating
after insert or update or delete on review
for each row execute procedure rating_change();
