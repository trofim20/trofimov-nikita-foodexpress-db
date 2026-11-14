-- FOOD-101

set search_path to trofimov_food, exts;

alter table address add constraint pk_address primary key (address_id);

alter table client add constraint pk_client primary key (client_id);
alter table client add constraint uq_client_login unique (login);
alter table client add constraint uq_client_phone unique (phone_number);
alter table client add constraint ck_client_password check (char_length(password) = 32);
alter table client add constraint ck_client_phone check (left(phone_number, 2) = '+7' and char_length(phone_number) = 12);

alter table client_address add constraint pk_client_address primary key (client_id, address_id);
alter table client_address add constraint fk_client_address_client foreign key (client_id) references client (client_id);
alter table client_address add constraint fk_client_address_address foreign key (address_id) references address (address_id);

alter table restaurant add constraint pk_restaurant primary key (restaurant_id);
alter table restaurant add constraint fk_restaurant_address foreign key (address_id) references address (address_id);
alter table restaurant add constraint uq_restaurant_address unique (address_id);
alter table restaurant add constraint ck_restaurant_rating check (rating between 0 and 5);
alter table restaurant add constraint ck_restaurant_hours check (work_end > work_start);

alter table courier add constraint pk_courier primary key (courier_id);
alter table courier add constraint ck_courier_phone check (left(phone_number, 2) = '+7' and char_length(phone_number) = 12);
alter table courier add constraint ck_courier_coefficient check (coefficient between 0.1 and 0.5);
alter table courier add constraint ck_courier_dismissed check (status != 'уволен' or dismissal_date is not null);
alter table courier add constraint ck_courier_dates check (dismissal_date >= hire_date);

alter table courier_pay add constraint pk_courier_pay primary key (year, month, courier_id);
alter table courier_pay add constraint fk_courier_pay_courier foreign key (courier_id) references courier (courier_id);
alter table courier_pay add constraint ck_courier_pay_month check (month between 1 and 12);
alter table courier_pay add constraint ck_courier_pay_amount check (amount >= 0);
alter table courier_pay add constraint ck_courier_pay_coefficient check (coefficient_used between 0.1 and 0.5);

alter table product_category add constraint pk_product_category primary key (product_category_id);
alter table product_category add constraint uq_product_category_name unique (product_category_name);

alter table product add constraint pk_product primary key (product_id);
alter table product add constraint fk_product_category foreign key (product_category_id) references product_category (product_category_id);
alter table product add constraint fk_product_restaurant foreign key (restaurant_id) references restaurant (restaurant_id);
alter table product add constraint ck_product_price check (price >= 0);
alter table product add constraint ck_product_rating check (rating between 0 and 5);

alter table "order" add constraint pk_order primary key (order_id);
alter table "order" add constraint fk_order_client foreign key (client_id) references client (client_id);
alter table "order" add constraint fk_order_address foreign key (address_id) references address (address_id);
alter table "order" add constraint fk_order_restaurant foreign key (restaurant_id) references restaurant (restaurant_id);
alter table "order" add constraint fk_order_courier foreign key (courier_id) references courier (courier_id);
alter table "order" add constraint fk_order_client_address foreign key (client_id, address_id) references client_address (client_id, address_id);
alter table "order" add constraint uq_order_client unique (order_id, client_id);
alter table "order" add constraint ck_order_sums check (commission = round(order_amount * 0.1, 2) and total_amount = order_amount + commission);
alter table "order" add constraint ck_order_minimum check (total_amount >= 1000);
alter table "order" add constraint ck_order_delivery_time check (delivery_timestamp >= order_timestamp);
alter table "order" add constraint ck_order_delivered check (status != 'доставлен' or delivery_timestamp is not null);

alter table order_structure add constraint pk_order_structure primary key (order_id, product_id);
alter table order_structure add constraint fk_order_structure_order foreign key (order_id) references "order" (order_id);
alter table order_structure add constraint fk_order_structure_product foreign key (product_id) references product (product_id);
alter table order_structure add constraint ck_order_structure_quantity check (quantity > 0);

alter table payment add constraint pk_payment primary key (payment_id);
alter table payment add constraint fk_payment_order foreign key (order_id) references "order" (order_id);
alter table payment add constraint uq_payment_transaction unique (transaction_ref);

create unique index uq_payment_success on payment (order_id) where status = 'успех';

alter table review add constraint pk_review primary key (review_id);
alter table review add constraint fk_review_order foreign key (order_id) references "order" (order_id);
alter table review add constraint fk_review_client foreign key (client_id) references client (client_id);
alter table review add constraint fk_review_order_client foreign key (order_id, client_id) references "order" (order_id, client_id);
alter table review add constraint uq_review_object unique (order_id, entity_type, entity_id);
alter table review add constraint ck_review_rating check (rating between 1 and 5);
alter table review add constraint ck_review_order_target check (entity_type != 'заказ' or entity_id = order_id);

create index ix_review_entity on review (entity_id, entity_type);
create index ix_order_courier on "order" (courier_id);
create index ix_order_delivered on "order" (order_timestamp) where status = 'доставлен';
create index ix_product_restaurant on product (restaurant_id);
create index ix_payment_order on payment (order_id);
