-- FOOD-101

set search_path to trofimov_food, exts;

create table address (
	address_id uuid not null default exts.uuid_generate_v4(),
	street varchar(120) not null,
	house_number varchar(12) not null,
	apartment_office varchar(12)
);

create table client (
	client_id uuid not null default exts.uuid_generate_v4(),
	login varchar(40) not null,
	password varchar(32) not null,
	phone_number char(12) not null
);

create table client_address (
	client_id uuid not null,
	address_id uuid not null
);

create table restaurant (
	restaurant_id uuid not null default exts.uuid_generate_v4(),
	restaurant_name varchar(120) not null,
	address_id uuid not null,
	description text not null,
	work_start time not null,
	work_end time not null,
	company_details text not null,
	rating numeric(5, 2),
	status restaurant_state not null default 'активен'
);

create table courier (
	courier_id uuid not null default exts.uuid_generate_v4(),
	fio varchar(120) not null,
	phone_number char(12) not null,
	status courier_state not null default 'свободен',
	hire_date date not null default current_date,
	dismissal_date date,
	coefficient numeric(3, 1) not null default 0.1
);

create table courier_pay (
	year int4 not null,
	month int2 not null,
	courier_id uuid not null,
	amount numeric(14, 2) not null,
	coefficient_used numeric(3, 1) not null
);

create table product_category (
	product_category_id uuid not null default exts.uuid_generate_v4(),
	product_category_name varchar(80) not null
);

create table product (
	product_id uuid not null default exts.uuid_generate_v4(),
	product_name varchar(120) not null,
	product_category_id uuid not null,
	price numeric(14, 2) not null,
	restaurant_id uuid not null,
	photo_url text,
	rating numeric(5, 2),
	status product_state not null default 'доступно',
	description text not null
);

create table "order" (
	order_id uuid not null default exts.uuid_generate_v4(),
	client_id uuid not null,
	address_id uuid not null,
	restaurant_id uuid not null,
	courier_id uuid not null,
	order_timestamp timestamp not null default localtimestamp,
	delivery_timestamp timestamp,
	order_amount numeric(14, 2) not null,
	commission numeric(14, 2) not null,
	total_amount numeric(14, 2) not null,
	status order_state not null default 'создан',
	pay_status order_payment_state not null default 'ожидает',
	description text not null
);

create table order_structure (
	order_id uuid not null,
	product_id uuid not null,
	quantity numeric(7, 2) not null
);

create table payment (
	payment_id uuid not null default exts.uuid_generate_v4(),
	order_id uuid not null,
	pay_method pay_kind not null,
	amount numeric(14, 2) not null,
	transaction_ref varchar(40) not null,
	transaction_timestamp timestamp not null default localtimestamp,
	status attempt_state not null default 'в_обработке'
);

create table review (
	review_id uuid not null default exts.uuid_generate_v4(),
	client_id uuid not null,
	order_id uuid not null,
	entity_type review_target not null,
	entity_id uuid not null,
	review_timestamp timestamp not null default localtimestamp,
	description text not null,
	photo_url text,
	rating numeric(1) not null
);
