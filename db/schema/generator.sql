-- FOOD-102, FOOD-103

set search_path to trofimov_food, exts;

create or replace procedure insert_test_data(value int) as $$
declare
	v_first_month date = date_trunc('month', current_date)::date - interval '5 month';
	v_kinds text[] = array['Супы', 'Салаты', 'Горячее', 'Гарниры', 'Выпечка', 'Десерты', 'Напитки', 'Завтраки', 'Закуски', 'Соусы'];
	v_food text[] = array['Солянка', 'Уха', 'Греческий салат', 'Оливье', 'Стейк', 'Жаркое', 'Пюре', 'Гречка с грибами', 'Сырники', 'Морс'];
	v_cafe text[] = array['Корица', 'Ложка', 'Самовар', 'Хлебница', 'Мангал', 'Плюшка', 'Бульон', 'Гастроном', 'Буфет', 'Кухня на районе'];
	v_street text[] = array['Мира', 'Ленина', 'Сибирская', 'Уральская', 'Комсомольская', 'Советская', 'Пушкина', 'Гоголя', 'Островского', 'Куйбышева'];
	v_fio text[] = array['Кузьмин Андрей Викторович', 'Лебедев Павел Олегович', 'Носов Артур Ильич', 'Ершов Глеб Романович', 'Тихонов Степан Юрьевич',
		'Медведев Лев Антонович', 'Баранов Олег Петрович', 'Гусев Матвей Денисович', 'Пахомов Ярослав Ильич', 'Сорокин Даниил Евгеньевич'];
	v_notes text[] = array['Позвонить заранее', 'Не звонить в дверь', 'Оставить у двери', 'Без приборов', 'Нужна сдача',
		'Домофон не работает', 'Код подъезда 25', 'Этаж 3', 'Побыстрее', 'Без лука'];
	v_opinions text[] = array['Всё вкусно', 'Привезли быстро', 'Курьер вежливый', 'Еда остыла', 'Маленькая порция',
		'Закажу ещё', 'Нормально', 'Перепутали блюдо', 'Отлично', 'Дороговато'];
	v_no int;
	v_pay_no int;
	v_id uuid;
	v_addr uuid;
	v_cat uuid[] = '{}';
	v_rest uuid[] = '{}';
	v_cli uuid[] = '{}';
	v_cli_addr uuid[] = '{}';
	v_extra uuid[] = '{}';
	v_cour uuid[] = '{}';
	v_cour_end date[] = '{}';
	v_prod uuid[] = '{}';
	v_price numeric[] = '{}';
	v_items uuid[];
	v_cost numeric[];
	v_qty numeric[];
	v_q numeric;
	v_ci int;
	v_r int;
	v_k int;
	v_t int;
	v_must int;
	v_ts timestamp;
	v_end date;
	v_sum numeric;
	v_login text;
	v_phone text;
	v_status order_state;
	v_attempt attempt_state;
begin
	if value is null or value <= 0 then
		raise exception 'insert_test_data: value должно быть положительным, получено %', value;
	end if;

	select count(*) into v_no from product_category;
	for i in 1..value loop
		v_no = v_no + 1;
		while exists (select 1 from product_category where product_category_name = v_kinds[(v_no - 1) % 10 + 1] || ' ' || v_no) loop
			v_no = v_no + 1;
		end loop;
		v_id = exts.uuid_generate_v4();
		insert into product_category (product_category_id, product_category_name)
		values (v_id, v_kinds[(v_no - 1) % 10 + 1] || ' ' || v_no);
		v_cat = v_cat || v_id;
	end loop;

	for i in 1..value loop
		if i > 1 and random() < 0.25 then
			v_end = v_first_month + 1 + floor(random() * (current_date - v_first_month - 1))::int;
		else
			v_end = null;
		end if;
		v_id = exts.uuid_generate_v4();
		insert into courier (courier_id, fio, phone_number, status, hire_date, dismissal_date)
		values (v_id,
			v_fio[floor(random() * 10)::int + 1],
			'+7' || (9500000000 + floor(random() * 99999999))::bigint,
			case when v_end is null then (enum_range(null::courier_state))[floor(random() * 3)::int + 1] else 'уволен' end,
			v_first_month,
			v_end);
		v_cour = v_cour || v_id;
		v_cour_end = v_cour_end || v_end;
	end loop;

	select count(*) into v_no from restaurant;
	for i in 1..value loop
		v_addr = exts.uuid_generate_v4();
		insert into address (address_id, street, house_number, apartment_office)
		values (v_addr,
			'ул. ' || v_street[floor(random() * 10)::int + 1],
			(floor(random() * 90) + 1)::text,
			case when random() < 0.3 then 'оф. ' || (floor(random() * 20) + 1) end);

		v_id = exts.uuid_generate_v4();
		insert into restaurant (restaurant_id, restaurant_name, address_id, description, work_start, work_end, company_details, status)
		values (v_id,
			'Кафе «' || v_cafe[floor(random() * 10)::int + 1] || '» №' || (v_no + i),
			v_addr,
			'Домашняя кухня, доставка от ' || (floor(random() * 4) + 2) * 10 || ' минут',
			'10:00'::time - floor(random() * 3) * interval '1 hour',
			'21:00'::time + floor(random() * 3) * interval '1 hour',
			concat_ws('; ',
				'ИНН ' || (7700000000 + floor(random() * 99999999))::bigint,
				'КПП ' || (770100000 + floor(random() * 99999))::bigint,
				'р/с 40702810' || (500000000000 + floor(random() * 99999999999))::bigint),
			(enum_range(null::restaurant_state))[floor(random() * 2)::int + 1]);
		v_rest = v_rest || v_id;

		for j in 1..5 loop
			v_id = exts.uuid_generate_v4();
			v_q = floor(random() * 26) * 50 + 150;
			insert into product (product_id, product_name, product_category_id, price, restaurant_id, photo_url, status, description)
			values (v_id,
				v_food[floor(random() * 10)::int + 1],
				v_cat[floor(random() * value)::int + 1],
				v_q,
				v_rest[i],
				case when random() < 0.5 then 'https://foodexpress.ru/menu/' || md5(random()::text) || '.webp' end,
				(enum_range(null::product_state))[floor(random() * 3)::int + 1],
				'Порция ' || (floor(random() * 30) * 10 + 150) || ' г');
			v_prod = v_prod || v_id;
			v_price = v_price || v_q;
		end loop;
	end loop;

	select count(*) into v_no from client;
	for i in 1..value loop
		loop
			v_no = v_no + 1;
			v_login = 'user' || v_no;
			v_phone = '+7' || (9200000000 + v_no);
			exit when not exists (select 1 from client where login = v_login or phone_number = v_phone);
		end loop;
		v_id = exts.uuid_generate_v4();
		insert into client (client_id, login, password, phone_number)
		values (v_id, v_login, md5(random()::text), v_phone);
		v_cli = v_cli || v_id;

		for j in 1..4 loop
			v_addr = exts.uuid_generate_v4();
			insert into address (address_id, street, house_number, apartment_office)
			values (v_addr,
				'ул. ' || v_street[floor(random() * 10)::int + 1],
				(floor(random() * 90) + 1)::text,
				case when random() < 0.65 then (floor(random() * 200) + 1)::text end);
			insert into client_address (client_id, address_id)
			values (v_id, v_addr);
			v_cli_addr = v_cli_addr || v_addr;
		end loop;
	end loop;

	for i in 1..value loop
		if value > 1 and i % 3 = 0 then
			v_addr = v_cli_addr[(i % value) * 4 + floor(random() * 4)::int + 1];
			insert into client_address (client_id, address_id)
			values (v_cli[i], v_addr);
			v_extra = v_extra || v_addr;
		else
			v_extra = v_extra || null::uuid;
		end if;
	end loop;

	select count(*) into v_pay_no from payment;
	for i in 1..value * 5 loop
		v_ci = floor(random() * value)::int + 1;
		v_r = floor(random() * value)::int + 1;
		v_k = floor(random() * value)::int + 1;

		if v_extra[v_ci] is not null and random() < 0.2 then
			v_addr = v_extra[v_ci];
		else
			v_addr = v_cli_addr[(v_ci - 1) * 4 + floor(random() * 4)::int + 1];
		end if;

		v_end = coalesce(v_cour_end[v_k], current_date - 1);
		v_ts = v_first_month + floor(random() * (v_end - v_first_month + 1))::int + '10:00'::time + random() * interval '11 hours';

		v_status = case when random() < 0.7 then 'доставлен' else (enum_range(null::order_state))[floor(random() * 5)::int + 1] end;
		if v_status in ('создан', 'отменён') then
			v_attempt = (enum_range(null::attempt_state))[floor(random() * 3)::int + 1];
		else
			v_attempt = 'успех';
		end if;

		v_must = floor(random() * 5)::int + 1;
		v_items = '{}';
		v_cost = '{}';
		v_qty = '{}';
		v_sum = 0;
		for j in 1..5 loop
			if j = v_must or random() < 0.4 then
				v_q = floor(random() * 3) + 1;
				v_items = v_items || v_prod[(v_r - 1) * 5 + j];
				v_cost = v_cost || v_price[(v_r - 1) * 5 + j];
				v_qty = v_qty || v_q;
				v_sum = v_sum + v_q * v_price[(v_r - 1) * 5 + j];
			end if;
		end loop;
		while v_sum * 1.1 < 1000 loop
			v_qty[1] = v_qty[1] + 1;
			v_sum = v_sum + v_cost[1];
		end loop;

		v_id = exts.uuid_generate_v4();
		insert into "order" (order_id, client_id, address_id, restaurant_id, courier_id, order_timestamp, delivery_timestamp,
			order_amount, status, description)
		values (v_id,
			v_cli[v_ci],
			v_addr,
			v_rest[v_r],
			v_cour[v_k],
			v_ts,
			case when v_status = 'доставлен' then v_ts + (25 + floor(random() * 75)) * interval '1 minute' end,
			v_sum,
			v_status,
			v_notes[floor(random() * 10)::int + 1]);

		for k in 1..cardinality(v_items) loop
			insert into order_structure (order_id, product_id, quantity)
			values (v_id, v_items[k], v_qty[k]);
		end loop;

		loop
			v_pay_no = v_pay_no + 1;
			exit when not exists (select 1 from payment where transaction_ref = 'PAY-' || v_pay_no);
		end loop;
		insert into payment (order_id, pay_method, amount, transaction_ref, transaction_timestamp, status)
		values (v_id,
			(enum_range(null::pay_kind))[floor(random() * 3)::int + 1],
			v_sum + round(v_sum * 0.1, 2),
			'PAY-' || v_pay_no,
			v_ts + interval '3 minute',
			v_attempt);

		v_t = floor(random() * 3)::int + 1;
		insert into review (client_id, order_id, entity_type, entity_id, review_timestamp, description, photo_url, rating)
		values (v_cli[v_ci],
			v_id,
			(enum_range(null::review_target))[v_t],
			(array[v_items[floor(random() * cardinality(v_items))::int + 1], v_rest[v_r], v_id])[v_t],
			v_ts + random() * (localtimestamp - v_ts),
			v_opinions[floor(random() * 10)::int + 1],
			case when random() < 0.3 then 'https://foodexpress.ru/reviews/' || md5(random()::text) || '.jpg' end,
			floor(random() * 5) + 1);
	end loop;

	with recursive m as (
		select c.courier_id, c.dismissal_date, v_first_month ms, 0.1::numeric coef
		from courier c
		where not exists (select 1 from courier_pay cp where cp.courier_id = c.courier_id)
		union all
		select m.courier_id, m.dismissal_date, (m.ms + interval '1 month')::date,
			case
				when m.dismissal_date < m.ms + interval '1 month' then m.coef
				else (
					select
						case
							when count(*) <= 150 then 0.1
							when count(*) <= 250 then 0.2
							when count(*) <= 500 then 0.3
							else 0.5
						end
					from "order" o
					where o.courier_id = m.courier_id
						and o.status = 'доставлен'
						and o.order_timestamp >= m.ms
						and o.order_timestamp < m.ms + interval '1 month')
			end
		from m
		where m.ms <= date_trunc('month', current_date)),
	ins as (
		insert into courier_pay (year, month, courier_id, amount, coefficient_used)
		select date_part('year', m.ms),
			date_part('month', m.ms),
			m.courier_id,
			round(m.coef * (
				select coalesce(sum(o.commission), 0)
				from "order" o
				where o.courier_id = m.courier_id
					and o.status = 'доставлен'
					and o.order_timestamp >= m.ms
					and o.order_timestamp < m.ms + interval '1 month'), 2),
			m.coef
		from m
		where m.ms <= date_trunc('month', current_date)
		returning courier_id)
	update courier c
	set coefficient = (
		select m.coef
		from m
		where m.courier_id = c.courier_id
			and m.ms = (date_trunc('month', current_date) + interval '1 month')::date)
	where c.courier_id in (select courier_id from ins);

	raise notice 'insert_test_data: клиентов %, ресторанов %, заказов %', value, value, value * 5;
end;
$$ language plpgsql;

create or replace procedure erase_test_data() as $$
begin
	truncate table address, client, courier, product_category cascade;
end;
$$ language plpgsql;
