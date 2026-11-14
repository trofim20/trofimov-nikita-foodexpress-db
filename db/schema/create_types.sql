-- FOOD-101

create schema if not exists exts;
create extension if not exists "uuid-ossp" with schema exts;

create schema trofimov_food;

set search_path to trofimov_food, exts;

create type restaurant_state as enum (
	'активен',
	'неактивен');

create type product_state as enum (
	'доступно',
	'нет_в_наличии',
	'архив');

create type courier_state as enum (
	'свободен',
	'занят',
	'на_доставке',
	'уволен');

create type order_state as enum (
	'создан',
	'готовится',
	'в_доставке',
	'доставлен',
	'отменён');

create type order_payment_state as enum (
	'ожидает',
	'оплачен',
	'ошибка');

create type attempt_state as enum (
	'успех',
	'ошибка',
	'в_обработке');

create type pay_kind as enum (
	'карта',
	'наличные',
	'безнал');

create type review_target as enum (
	'блюдо',
	'ресторан',
	'заказ');
