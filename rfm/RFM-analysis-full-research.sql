-- RFM-анализ клиентов аптечной сети (by Va1errCa - Жидков Валерий)
--
-- RFM-анализа или RFM-классификации клиентской базы - инструмент, предоставляющий бизнес-подразделению
-- возможность более точно, более адресно, более оптимизированно проводить маркетинговые 
-- мероприятия и активности, исходя из понимания к какому сегменту, кластеру принадлежит конкретный клиент. 
-- Понимание отличий между сегментами дает возможность подобрать для каждого из них набор ортимальных 
-- маркетинговых активностей выработать стратегию взаимодействия с каждым сегментом, в частности, в рамках рекламной 
-- активности, позволяет более точно сформилировать идею и посыл рекламной компании, способы продвижения и 
-- размещения рекламного контента.
-- При этом конечная цель RFM-анализа - повышение эффективности взаимодействия бизнеса с существующими клиентами, 
-- содействие улучшению клиентского опыта и повышению удовлетворенности клиентов, кумулятивным эффектом от чего 
-- становится привлечение новых клиентов откликающихся на позитивный экспириенс их коллег, друзей и родственников.
--
-- В основе RFM-анализа работа с 3я основными метриками характеризующими взаимодействие с клиентом:  
-- 1.недавность - насколько давно или нет клиент взаимодействовал с бизнесом
-- 2.частота - насколько часто клиент взаимодействует с бизнесом (покупает у нас)
-- 3.денежность - насколько велик чек клиента
-- Правильная интерпретация результатов RFM-классификации помогает нам понять что за клиент перед нами и как с ним 
-- взаимодействовать более эффективно.
--
-- Таблица для анализа - bonuscheques (таблица с информацией о транзакциях по бонусной системе) 
-- Дата анализа - дата последней операции в базе
--
-- Общая статистика
-- Анализируемый период: 12.07.2021 - 09.06.2022 
select min(datetime)::date as first_date, max(datetime)::date as last_date
from bonuscheques b 

-- Количество идентифицированных клиентов (корректных уникальных номеров карт): 5926  (далее "КЛИЕНТЫ") 
select count(distinct card) as total_good_cards
from bonuscheques b 
where length(card) = 13

-- Общее количество покупок в базе: 38486
--         в т.ч. покупок клиентов: 21075
--  процент неидентифицированных покупок: 45.24%
select 
	count(*) as total_receipts, 
	count(*) filter(where length(card) = 13) as card_receipts,
	round(100.0*count(*) filter(where length(card) > 13) / count(*), 2) as incorrect_rc_ratio
from bonuscheques b 

-- Общая сумма покупок в базе: 32 202 608= 
--    в т.ч. покупок клиентов: 19 196 840=
--  процент неидентифицированных сумм: 40.39%
select 
	sum(summ) as total_amount, 
	sum(summ) filter(where length(card) = 13) as card_amount,
	round(100.0*sum(summ) filter(where length(card) > 13) / sum(summ), 2) as incorrect_am_ratio
from bonuscheques b 

-- Альтернативный вариант
select 
    'Не идентифицирован' as type_tr,
	count(*)  as cnt_receipts, 
	sum(summ) as amount 
from bonuscheques
where length(card) != 13
union
select 
    'Идентифицирован' as type_tr,
	count(*)  as cnt_receipts, 
	sum(summ) as amount
from bonuscheques
where length(card) = 13



-- Размер аптечной сети: 8 аптек
select count(distinct shop) as total_shops
from bonuscheques b 

-- Количество клиентов покупавших более чем в одной аптеке сети: 561
-- 										процент от общего числа: 9.47%
select 
	count(*) as total_few_shops_cards,
	round(100.0*count(*) / (select count(distinct card) 
				  	  		from bonuscheques b 
					  		where length(card) = 13), 2) as few_shops_cards_ratio  
from (select count(distinct shop) as cnt
	  from bonuscheques b
	  where length(card) = 13
	  group by card ) t
where cnt > 1

-- Распределение клиентов по количеству посещенных аптек
select
	cnt as shops_visited,
	count(*) as unique_cards
from (select count(distinct shop) as cnt
	  from bonuscheques b
	  where length(card) = 13
	  group by card ) t
group by cnt

-- Общая статистика в разрезе аптек (Часть1):
select 
	-- аптека
	shop,
	-- общее количество покупок в аптеке
	count(*) as total_receipts,
	-- общее количество покупок клиентов в аптеке  
	count(*) filter (where length(card) = 13) as card_receipts,
	-- процент неидентифицированных покупок в аптеке
	round(100.0*count(*) filter (where length(card) != 13) / count(*), 2) as incorrect_rc_ratio,
	-- общая сумма покупок в аптеке
	sum(summ) as total_amount, 
	-- общая сумма покупок клиентов в аптеке
	sum(summ) filter (where length(card) = 13) as card_amount,
	-- процент неидентифицированных сумм в аптеке
	round(100.0*sum(summ) filter (where length(card) != 13) / sum(summ), 2) as incorrect_am_ratio,
	-- средний чек по аптеке
	round(avg(summ), 2) as avg_receipt,
	-- средний чек по клиентам по аптеке
	round(avg(summ) filter (where length(card) != 13), 2) as avg_card_receipt
from bonuscheques b
group by shop
order by split_part(shop, ' ', 2)::integer

-- Общая статистика в разрезе аптек (Часть2):
select 
	-- аптека
	shop,
	-- минимальная сумма чека,
	min(summ) as min_amount, 
	-- максимальная сумма чека,
	max(summ) as max_amount, 
	-- средняя сумма чека по клиентам по аптеке
	round(avg(summ) filter (where length(card) = 13), 2) as avg_card_receipt,
	-- средняя сумма чека по аптеке
	round(avg(summ), 2) as avg_receipt,
	-- медиана суммы чека по аптеке
	percentile_disc(0.50) within group (order by summ) as percentile_50,
	-- 30й процентиль суммы чека по аптеке 
	percentile_disc(0.25) within group (order by summ) as percentile_25,
	-- 80й процентиль суммы чека по аптеке
	percentile_disc(0.80) within group (order by summ) as percentile_80	
from bonuscheques b
group by shop
order by split_part(shop, ' ', 2)::integer


-- Исследования для определения порогов метрик R(недавность)-F(частота)-M(размер чека)
-- для каждой метрики планируем использовать по 3 грейда
--
-- Метрика Recency
-- Статистики расчитываются только по клиентам (поскольку в случаях некорректного номера карты невозможно сопоставить 
-- операцию (ее дату) с клиентом)
-- Предполагаем, исходя из вида бмзнеса - аптеки, что разумно относить недавность покупки в 1ю категорию - "недавние", 
-- при совершении покупки клиентом в течение месяца (или, возможно, 2х - 3х недель) до даты анализа
-- во 2ю категорию - "спящие", при совершении покупки в период не ранее порога категории "недавние", но не позже 2х-3х 
-- месяцев от даты анализа
-- в 3ю категорию - "давние", при более поздней покупке чем предыдущие грейды

-- Распределение давностей последней операции клиента
with days_ago as (
	select 
		card, 
		max(max(datetime::date)) over () - max(datetime::date) as days
	from bonuscheques b 
	where length(card) = 13 
	group by card
)
select 
	count(*) as total_users,
	-- дней от последней покупки клиента до даты анализа
	min(days) as min_days,
	-- дней от первой покупки клиента до даты анализа
	max(days) as max_days,
	-- средняя дистанция в днях от покупки до даты анализа
	round(avg(days)) as avg_days,
	-- медиана дистанции в днях от покупки до даты анализа
	percentile_disc(0.50) within group (order by days) as median,
	-- 20й процентиль дистанции в днях от покупки до даты анализа
	percentile_disc(0.20) within group (order by days) as percentile_20,
	-- 40й процентиль дистанции в днях от покупки до даты анализа
	percentile_disc(0.40) within group (order by days) as percentile_40
from days_ago	

-- Проверим численность грейдов метрики Recency, если в качестве пороговых значений будут выбраны:
-- 1-"недавние": в пределах значения 20го процентиля дистанции в днях от покупки до даты анализа - 21 день
-- 2-"спящие": в пределах значений от 20го по 40й процентиль дистанции в днях от покупки до даты анализа - с 22го по 61й день
-- 3-"давние": более значения 40го процентиля дистанции в днях от покупки до даты анализа - более 61го дня 
with days_ago as (
	select 
		card, 
		max(max(datetime::date)) over () - max(datetime::date) as days
	from bonuscheques b 
	where length(card) = 13 
	group by card
), thresholds as (
	select 
		-- 20й процентиль дистанции в днях от покупки до даты анализа
		percentile_disc(0.20) within group (order by days) as percentile_20,
		-- 40й процентиль дистанции в днях от покупки до даты анализа
		percentile_disc(0.40) within group (order by days) as percentile_40
	from days_ago
)	
select 
	-- всего клиентов
	count(*) as total_users,
	-- количества и доля клиентов 1го грейда
	count(*) filter (where days <= (select percentile_20 from thresholds)) as cnt_less_prc_20,
	round(100.0*count(*) filter (where days <= (select percentile_20 from thresholds)) /
	 			count(*), 2) as less_prc_20_ratio,
 	-- количества и доля клиентов 2го грейда
	count(*) filter (where days > (select percentile_20 from thresholds) and
						   days <= (select percentile_40 from thresholds)) as cnt_betw_prc_20_40,
	round(100.0*count(*) filter (where days > (select percentile_20 from thresholds) and
						   days <= (select percentile_40 from thresholds)) /
	 			count(*), 2) as betw_prc_20_40_ratio,	 			
 	-- количества и доля клиентов 3го грейда
	count(*) filter (where days > (select percentile_40 from thresholds)) as cnt_more_prc_40,
	round(100.0*count(*) filter (where days > (select percentile_40 from thresholds)) /
	 			count(*), 2) as more_prc_40_ratio,
	-- последконтроль вичислений (суммарная доля)
	round(100.0*count(*) filter (where days <= (select percentile_20 from thresholds)) / count(*), 2) +
	round(100.0*count(*) filter (where days > (select percentile_20 from thresholds) and
						   days <= (select percentile_40 from thresholds)) / count(*), 2) +	 			
	round(100.0*count(*) filter (where days > (select percentile_40 from thresholds)) /	
				count(*), 2) as control_ratio	 			
from days_ago
-- Разбивка по 20му и 40му процентилю дает приемлемую численность первых двух групп: примерно 20, 20%%, однако размер 3й группы - 60%
-- или 3547 клиентов требует уточнения.

-- разбивка по децилям
with days_ago as (
	select 
		card, 
		max(max(datetime::date)) over () - max(datetime::date) as days
	from bonuscheques b 
	where length(card) = 13 
	group by card
)
select 
    percent,
	percentile_disc(percent) within group (order by days) as days
from generate_series(0.1, 1.0, 0.1) as percent
cross join days_ago
group by percent


-- Добавим новый грейд, для чего произведем расчет периода оттока клиента.
-- Период оттока - время, по прошестивии которого клиент, как правило, уже не возвращается в сеть за покупками. 
with time_diffs as (
	select
		datetime::date as dt,
		lag(datetime::date, 1) over (partition by card order by datetime::date),
		datetime::date - lag(datetime::date, 1) over (partition by card order by datetime::date) as diff	
	from bonuscheques b
	where length(card) = 13
)
select 
	percentile_disc(0.95) within group (order by diff) as drop_time
from time_diffs
-- Расчет показывает, что после 105 дней перерыва между покупками только 5% клиентов возможно совершат покупку в нашей аптечной сети.
-- Принимаем это значение как период оттока.

-- Добавим в метрику Recency новый грейд - "ушедшие", произведем подсчет численности (емкости) грейдов.
with time_diffs as (
	select
		datetime::date as dt,
		lag(datetime::date, 1) over (partition by card order by datetime::date),
		datetime::date - lag(datetime::date, 1) over (partition by card order by datetime::date) as diff	
	from bonuscheques b
	where length(card) = 13
), drop_time as (
	select 
		-- период оттока 
		percentile_disc(0.95) within group (order by diff) as drop_time
	from time_diffs
), days_ago as (
	select 
		card, 
		max(max(datetime::date)) over () - max(datetime::date) as days
	from bonuscheques b 
	where length(card) = 13 
	group by card 
), thresholds as (
	select 
		-- 20й процентиль дистанции в днях от покупки до даты анализа
		percentile_disc(0.20) within group (order by days) as percentile_20,
		-- 40й процентиль дистанции в днях от покупки до даты анализа
		percentile_disc(0.40) within group (order by days) as percentile_40
	from days_ago
)	
select 
	-- всего клиентов
	count(*) as total_users,
	-- количества и доля клиентов 1го грейда
	count(*) filter (where days <= (select percentile_20 from thresholds)) as cnt_less_prc_20,
	round(100.0*count(*) filter (where days <= (select percentile_20 from thresholds)) /
	 			count(*), 2) as less_prc_20_ratio,
	-- количества и доля клиентов 2го грейда
	count(*) filter (where days > (select percentile_20 from thresholds) and
						   days <= (select percentile_40 from thresholds)) as cnt_betw_prc_20_40,
	round(100.0*count(*) filter (where days > (select percentile_20 from thresholds) and
						   days <= (select percentile_40 from thresholds)) /
	 			count(*), 2) as betw_prc_20_40_ratio,	 			
	-- количества и доля клиентов 3го грейда
	count(*) filter (where days > (select percentile_40 from thresholds) and
						   days <= (select drop_time from drop_time)) as cnt_betw_prc_40_drop,	
	round(100.0*count(*) filter (where days > (select percentile_40 from thresholds) and
						   days <= (select drop_time from drop_time)) / 
				count(*), 2) as betw_prc_40_drop_ratio,	
	-- количества и доля клиентов 4го грейда
	count(*) filter (where days > (select drop_time from drop_time)) as cnt_more_drop,
	round(100.0*count(*) filter (where days > (select drop_time from drop_time)) /
	 			count(*), 2) as more_drop_ratio,
	-- последконтроль вычислений(суммарная доля)
	round(100.0*count(*) filter (where days <= (select percentile_20 from thresholds)) / count(*), 2) +
	round(100.0*count(*) filter (where days > (select percentile_20 from thresholds) and
						   days <= (select percentile_40 from thresholds)) / count(*), 2) +	 			
	round(100.0*count(*) filter (where days > (select percentile_40 from thresholds)) /	
				count(*), 2) as control_ratio	 			
from days_ago

-- второй вариант под визуализацию:
-- Добавим в метрику Recency новый грейд - "ушедшие", произведем подсчет численности (емкости) грейдов.
with time_diffs as (
	select
		datetime::date as dt,
		lag(datetime::date, 1) over (partition by card order by datetime::date),
		datetime::date - lag(datetime::date, 1) over (partition by card order by datetime::date) as diff	
	from bonuscheques b
	where length(card) = 13
), drop_time as (
	select 
		-- период оттока (для 95% клиентов)
		percentile_disc(0.95) within group (order by diff) as drop_time
	from time_diffs
), days_ago as (
	select 
		card, 
		max(max(datetime::date)) over () - max(datetime::date) as days
	from bonuscheques b 
	where length(card) = 13 
	group by card 
), thresholds as (
	select 
		-- 20й процентиль дистанции в днях от покупки до даты анализа
		percentile_disc(0.20) within group (order by days) as percentile_20,
		-- 40й процентиль дистанции в днях от покупки до даты анализа
		percentile_disc(0.40) within group (order by days) as percentile_40
	from days_ago
)	
select 
	-- емкость 1го грейда
	1 as r, 'недавние' as name,
	count(*) filter (where days <= (select percentile_20 from thresholds)) as grade1
from days_ago
union
select
	-- емкость 2го грейда
	2 as r, 'спящие' as name,
	count(*) filter (where days > (select percentile_20 from thresholds) and
						   days <= (select percentile_40 from thresholds)) as grade2
from days_ago
union
select	
	-- емкость 3го грейда
	3 as r, 'давние' as name,
	count(*) filter (where days > (select percentile_40 from thresholds) and
						   days <= (select drop_time from drop_time)) as grade3
from days_ago
union
select							   
	-- емкость 4го грейда
	4 as r,'ушедшие' as name,
	count(*) filter (where days > (select drop_time from drop_time)) as grade4
from days_ago
order by r


-- В результате получены грейды по метрике Recency:
-- 1-"недавние": последняя покупка не ранее 21 дня до даты анализа - 20% численности
-- 2-"спящие": последняя покупка от 21го до 61го дня до даты анализа - 20% 
-- 3-"давние": последняя покупка от 61го до 105ти дней до даты анализа - 15%
-- 4-"ушедшие": последняя покупка более расчитанного периода оттока - 105 дней до даты анализа - 45% 
-- Полученные грейды позволят более точно сегментировать клиентов и, как следствие, более адресно провести маркетинговые 
-- мероприятия и оптимизировать расходование бюджета на эти цели (после завершения классификации).



-- Метрика Frequency
-- Уточним некоторые моменты:
-- 1) Под частотой будем понимать отношение общего числа покупок клиента к периоду активности клиента измеренному
-- в базовых временных интервалах 
-- 2) Периодом активности клиента, будем считать промежуток времени от первой до последней покупки клиента в аптечной сети, 
-- увеличенный на период оттока (105 дней) приведенный к базовому временному интервалу. 
-- 3) Учитывая особенности аптечной торговли в качестве базового временного интервала возьмем верхнюю границу грейда "недавние" 
-- показателя Recency (21 день). 
-- 4) Если покупка была одна, датой последней покупки для такого клиента будем считать дату единственной покупки.
-- 5) Если дата первой покупки в пределах одного базового временного интервала от даты анализа (не более 21 дня) за временной интервал принимаем 1. 
-- 6) Если расчетная верхняя граница периода активности клиента превышает дату анализа, за эту границу принимаем дату анализа
-- 7) Будем проектировать 3 грейда: "частые" (покупки), "редкие" и "разовые". 
--
-- Расчитаем частотные характеристики для всех клиентов
with time_periods as (
	select
		card,
		min(datetime)::date as first_user_date,
		max(datetime)::date as last_user_date,
		-- начальная дата периода активности клиента
		case 
			when (min(datetime)::date + 21) > max(max(datetime::date)) over () then max(max(datetime::date)) over () - 21
			else min(datetime)::date
		end	as start_activity,
		-- конечная дата периода активности клиента
		case 
			when (max(datetime)::date + 105) > max(max(datetime::date)) over () then max(max(datetime::date)) over ()
			else max(datetime)::date + 105
		end	as stop_activity,
		count(*) as purchases
	from bonuscheques b
	where length(card) = 13
	group by card
)
select 
	card,
	first_user_date,
	last_user_date,
	start_activity,
	stop_activity,
	round(1.0*(stop_activity - start_activity) / 21, 2) as intervals_activity,	
	purchases,
	-- частота
	round((purchases*21)::numeric / (stop_activity - start_activity), 2) as frequency,
	-- лояльность
	round((purchases*purchases*21)::numeric / (stop_activity - start_activity), 2) as loyalty
from time_periods
order by frequency desc

--\ Немного рассуждений о параметре Frequency.
--\ Как показывает анализ расчетных значений количества покупок и частоты покупок, по-отдельности эти параметрв не дают полноценной картины
--\ об опыте взаимодецйствия клиента с нашей аптечной сетью. В первом случае, например, 2е покупки за последнюю неделю будут 
--\ равноценны 2м покупкам за весь анализируемый период, во втором случае, например, одна покупка за последнюю неделю будет
--\ оценена выше чем 33 покупки клиента за 34 прошедшие недели. Исходя из этого, предлагается использовать некий интегральный параметр,
--\ который я назвал "доказанной лояльностью" (proven loyalty) клиента. Он определяется как частота покупок клиента, расчитанная по методике
--\ описанной выше, мультиплицированная на абсолютное количество покупок колиента за весь анализируемый период.


-- Для границы 1го грейда "частые" метрики Frequence выберем значение частоты в окрестности  1, т.е. будем относить к 1му грейду
-- клиентов совершающих как минимум одну покупку примерно в 21 день. Оптимальный вариант - 85й процентиль, в этом случае граничная 
-- частота грейда составит 0.96 и емкость грейда 15%
-- Для границы 3го грейда "разовые" возьмем частоту, полученную для случая одной покупки для времени равном периоду оттока
-- (приведенного к базовому временному интервалу: 105 / 21), т.е.  1/5 = 0.2
-- Подтвердим наши предположения запросом
with time_periods as (
	select
		card,
		min(datetime)::date as first_user_date,
		max(datetime)::date as last_user_date,
		-- начальная дата периода активности клиента
		case 
			when (min(datetime)::date + 21) > max(max(datetime::date)) over () then max(max(datetime::date)) over () - 21
			else min(datetime)::date
		end	as start_activity,
		-- конечная дата периода активности клиента
		case 
			when (max(datetime)::date + 105) > max(max(datetime::date)) over () then max(max(datetime::date)) over ()
			else max(datetime)::date + 105
		end	as stop_activity,
		count(*) as purchases
	from bonuscheques b
	where length(card) = 13
	group by card
), loyalty_list as (
	select 
		card,
		first_user_date,
		last_user_date,
		start_activity,
		stop_activity,
		round(1.0*(stop_activity - start_activity) / 21, 2) as intervals_activity,	
		purchases,
		round((purchases*21)::numeric / (stop_activity - start_activity), 2) as frequency,
		round((purchases*purchases*21)::numeric / (stop_activity - start_activity), 2) as loyalty
	from time_periods
)
select 
	-- всего клиентов
	count(*) as total_user,
	min(frequency), 
	max(frequency),
	round(avg(frequency), 2) as avg,
	percentile_disc(0.85) within group (order by frequency) as procentile_85,
	-- количества и доля клиентов 1го грейда
	count(case when frequency >= 0.96 then 1 end) as often,
	round(100.0*count(case when frequency >= 0.96 then 1 end) / count(*), 2) as often_grade_ratio,
	-- количества и доля клиентов 2го грейда
	count(case when frequency > 0.2 and frequency < 0.96 then 1 end) as rarely,
	round(100.0*count(case when frequency > 0.2 and frequency < 0.96 then 1 end) / count(*), 2) as rarely_grade_retio,
	-- количества и доля клиентов 3го грейда
	count(case when frequency <= 0.2 then 1 end) as one_time_event,
	round(100.0*count(case when frequency <= 0.2 then 1 end) / count(*), 2)	as one_time_event_ratio,
	-- последконтроль вычислений(суммарная доля)
	round(100.0*count(case when frequency >= 0.96 then 1 end) / count(*), 2) +
	round(100.0*count(case when frequency > 0.2 and frequency < 0.96 then 1 end) / count(*), 2) +
	round(100.0*count(case when frequency <= 0.2 then 1 end) / count(*), 2)	as control_ratio
from loyalty_list
-- Таким образом для параметра Frequency получаем грейды:
-- 1-"частые": частота покупок клиента не менее 0.96 (емкость грейда 15%)
-- 2-"редкие": частота покупок клиента больше 0.2 но меньше 0.96  (емкость грейда 54%)
-- 3-"разовые": частота покупок клиента не более 0.2. (емкость грейда 31%)
 
-- второй вариант под визуализацию
with time_periods as (
	select
		card,
		min(datetime)::date as first_user_date,
		max(datetime)::date as last_user_date,
		-- начальная дата периода активности клиента
		case 
			when (min(datetime)::date + 21) > max(max(datetime::date)) over () then max(max(datetime::date)) over () - 21
			else min(datetime)::date
		end	as start_activity,
		-- конечная дата периода активности клиента
		case 
			when (max(datetime)::date + 105) > max(max(datetime::date)) over () then max(max(datetime::date)) over ()
			else max(datetime)::date + 105
		end	as stop_activity,
		count(*) as purchases
	from bonuscheques b
	where length(card) = 13
	group by card
), loyalty_list as (
	select 
		card,
		first_user_date,
		last_user_date,
		start_activity,
		stop_activity,
		round(1.0*(stop_activity - start_activity) / 21, 2) as intervals_activity,	
		purchases,
		round((purchases*21)::numeric / (stop_activity - start_activity), 2) as frequency,
		round((purchases*purchases*21)::numeric / (stop_activity - start_activity), 2) as loyalty
	from time_periods
)
select 
    unnest(array['1 - частота >= 0.96', '2 - чстота от 0.2 до 0.96', '3 - частота <= 0.2']) as graide,
    unnest(array[
	count(case when frequency >= 0.96 then 1 end),
	count(case when frequency > 0.2 and frequency < 0.96 then 1 end),
	count(case when frequency <= 0.2 then 1 end)]) as grade_size
-- или таблица
--    unnest(array[1, 2, 3]) as f,
--    unnest(array['частые', 'редкие', 'разовые']) as name,
--    unnest(array[count(case when frequency >= 0.96 then 1 end),
--    	        count(case when frequency > 0.2 and frequency < 0.96 then 1 end),
--    	        count(case when frequency <= 0.2 then 1 end)]) as size
from loyalty_list


-- Метрика Monetary
-- Статистики расчитывается по всем суммам (поскольку в случаях некорректного номера карты сумма чека присутствует 
-- и корректна используем все данные для расчета статистик)
select 
	-- минимальная сумма чека,
	min(summ) as min_amount,
	-- максимальная сумма чека,
	max(summ) as max_amount,
	-- средняя сумма чека
	round(avg(summ), 2) as avg_receipt,
	-- медиана суммы чека
	percentile_disc(0.50) within group (order by summ) as median,
	-- 40й процентиль суммы 
	percentile_disc(0.40) within group (order by summ) as percentile_40,
	-- 80й процентиль суммы
	percentile_disc(0.80) within group (order by summ) as percentile_80	
from bonuscheques b 
-- Можно отметить наличие выбросов в большую сторону по сумме чека ввиду существенного превышения средней суммы чека над медианым значением
-- Выбор в качестве границ значений 40го и 80го процентиля средней суммы чека представляется приемлемым.

-- Проверим численность групп клиентов если в качестве пороговых значений сумм будут установлены значения 40го и 80го процентиля
with thresholds as (
	select 
		percentile_disc(0.40) within group (order by summ) as percentile_40,
		percentile_disc(0.80) within group (order by summ) as percentile_80	
	from bonuscheques b 
)
select 
	-- всего клиентов
	count(*) as total_users,
	-- количества и доля клиентов 1го грейда
	count(*) filter (where summ > (select percentile_80 from thresholds)) as cnt_more_prc_80 ,
	round(100.0*count(*) filter (where summ > (select percentile_80 from thresholds)) /
	 			count(*), 2) as more_prc_80_ratio,
	-- количества и доля клиентов 2го грейда 			
	count(*) filter (where summ <= (select percentile_80 from thresholds) and
			    		   summ > (select percentile_40 from thresholds)) as cnt_betw_prc_40_80,
	round(100.0*count(*) filter (where summ <= (select percentile_80 from thresholds) and
			    			  		   summ > (select percentile_40 from thresholds)) /
				count(*), 2) as betw_prc_40_80_ratio,
	-- количества и доля клиентов 3го грейда			
	count(*) filter (where summ <= (select percentile_40 from thresholds)) as cnt_less_prc_40,
	round(100.0*count(*) filter (where summ <= (select percentile_40 from thresholds)) /
				count(*), 2) as less_prc_405_ratio,
	-- последконтроль вычислений(суммарная доля)
	round(100.0*count(*) filter (where summ > (select percentile_80 from thresholds)) /	count(*), 2) +
	round(100.0*count(*) filter (where summ <= (select percentile_80 from thresholds) and
			    			  		   summ > (select percentile_40 from thresholds)) /	count(*), 2) +
	round(100.0*count(*) filter (where summ <= (select percentile_40 from thresholds)) / count(*), 2) as control_ratio
	-- В расчет берется средняя	сумма чека по клиенту
from (select card, round(avg(summ)) as summ from bonuscheques b where length(card) = 13 group by card) t				
-- Разбивка по 40му и 80му процентилю дает приемлемую численность групп.
-- Таким образом получены грейды по параметру Monetary:
-- 1-"высокий чек": средний чек клиента более 1202 руб. (емкость грейда 24%)
-- 2-"средний чек": средний чек клиента более 446 руб., но не более 1202 руб. (емкость грейда 53%) 
-- 3-"низкий чек": средний чек клиента менее 446 руб. (емкость грейда 23%)
 		
-- второй вариант под визуализацию
-- Оцениваем емкость грейдов если в качестве пороговых границ будут установлены суммы 40го и 80го процентиля
with thresholds as (
	select 
		percentile_disc(0.40) within group (order by summ) as percentile_40,
		percentile_disc(0.80) within group (order by summ) as percentile_80	
	from bonuscheques
 	where length(card) = 13
)
select 
    unnest(array[1, 2, 3]) as m,
    unnest(array['высокий чек', 'средний чек', 'низкий чек']) as name,
    unnest(array[count(case when summ > (select percentile_80 from thresholds) then 1 end),
    	        count(case when summ > (select percentile_40 from thresholds) and summ <= (select percentile_80 from thresholds) then 1 end),
    	        count(case when summ <= (select percentile_40 from thresholds) then 1 end)]) as size
from (select card, round(avg(summ)) as summ from bonuscheques b where length(card) = 13 group by card) t	

-- Метрика Age
-- Для более точной сегментации целевой аудитории введем еще одну координату - "возраст" клиента (длительность периода 
-- сотрудничества с аптечной сетью)
-- Эмпирически выберем границы грейдов: 30 дней - новички, от 30 до 180 дней - опытные, свыше 180 дней - ветераны
-- Посмотрим распределение клиентов по данному параметру и при выбранных границах грейдов 
with age_cards as (
	select
		max(max(datetime::date)) over () - min(datetime)::date as age
	from bonuscheques b
	where length(card) = 13
	group by card	
)
select 
	-- всего клиентов
	count(*) as total_users,	
	min(age), 
	max(age),
	round(avg(age)) as avg,
	-- количества и доля клиентов 3го грейда
	count(case when age <= 30 then 1 end) as rookies,
	round(100.0*count(case when age <= 30 then 1 end) / count(*), 2) as rookies_ratio,
	-- количества и доля клиентов 2го грейда
	count(case when age > 30 and age <= 180 then 1 end) as experts,
	round(100.0*count(case when age > 30 and age <= 180 then 1 end) / count(*), 2) as experts_ratio,
	-- количества и доля клиентов 1го грейда
	count(case when age > 180 then 1 end) as veterans,
	round(100.0*count(case when age > 180 then 1 end) / count(*), 2) as veterans_ratio,
	percentile_disc(0.08) within group (order by age) as percentile_8,
	percentile_disc(0.46) within group (order by age) as percentile_46,	
	percentile_disc(0.50) within group (order by age) as mediana,
	-- последконтроль вычислений(суммарная доля)
	round(100.0*count(case when age <= 30 then 1 end) / count(*), 2) +
	round(100.0*count(case when age > 30 and age <= 180 then 1 end) / count(*), 2) +
	round(100.0*count(case when age > 180 then 1 end) / count(*), 2) as control_ratio
from age_cards
-- Распределение представляется приемлемым, нижняя и верхняя границы грейдов примерно соответствуют 8у и 46у процентилю.
-- На данном этапе принимаем эти границы по параметру Age:
-- 1 - "ветеран" - первая покупка более полугода до даты анализа (емкость грейда 53%)
-- 2 - "опытный" - первая покупка в период от 30ти до 180ти дней до даты анализа (емкость грейда 38%)
-- 3 - "новичок" - первая покупка в период не более 30 дней до даты анализа (емкость грейда 8%)

-- Резюме отобранных грейдов по метрикам Recency, Frequency, Monetary, Age
-- Recency: (1-"недавние":  <=21 дн; 2-"спящие": >21 <=61 дн; 3-"давние": >61 <=105 дн; 4-"ушедшие": >105 дн) 
-- Frequency: (1-"частые":  >=0.96; 2-"редкие": >0.2 <0.96; 3-"разовые": <=0.2.
-- Monetary: (1-"высокий чек": > 1202 руб.; 2-"средний чек": >446 руб., <=1202 руб.; 3-"низкий чек": <=446 руб.)
-- Age: (1-"ветеран": > 180 дн; 2-"опытный": >30  <= 180 дн, 3-"новичок": <=30 дн)


-- Для финальной RFMA-классификации нашей клиентской базы подготовоим базу кластеров(клиентский сегментов)
-- нумерация грейдов от 1 до 3(4) соответствует "от лучшего к худшему" 
select 
	r, f, m, a,
	concat(r,f,m,a) as segment,
	concat_ws('-', description_R, description_F, description_M, description_A) as description
from (select 1 as R, 'недавний' as description_R union select 2, 'спящий' union select 3, 'давний' union select 4, 'ушедший') t1
cross join (select 1 as F, 'частый' as description_F union select 2, 'редкий' union select 3, 'разовый') t2
cross join (select 1 as M, 'высокий_чек' as description_M union select 2, 'средний_чек' union select 3, 'низкий_чек') t3
cross join (select 1 as A, 'ветеран' as description_A union select 2, 'опытный' union select 3, 'новичок') t4
--where concat(r,f,m,a) not in ('1111', '2222', '3333', '4444')
order by r,f,m,a



-- Произведем финальную RFMA-классификацию клиентов
with rfma_schema as (
	select 
		r, f, m, a,
		concat(r,f,m,a) as segment,
		concat_ws('-', description_R, description_F, description_M, description_A) as description
	from (select 1 as R, 'недавний' as description_R union select 2, 'спящий' union select 3, 'давний' union select 4, 'ушедший') t1
	cross join (select 1 as F, 'частый' as description_F union select 2, 'редкий' union select 3, 'разовый') t2
	cross join (select 1 as M, 'высокий_чек' as description_M union select 2, 'средний_чек' union select 3, 'низкий_чек') t3
	cross join (select 1 as A, 'ветеран' as description_A union select 2, 'опытный' union select 3, 'новичок') t4
), time_diffs as (
	select
		-- разница для вычисления периода оттока
		datetime::date - lag(datetime::date, 1) over (partition by card order by datetime::date) as diff
	from bonuscheques b
	where length(card) = 13
), drop_time as (
	select 
		-- период оттока (верхняя граница Recency)
		percentile_disc(0.95) within group (order by diff) as drop_time
	from time_diffs	
), cards1 as (
	-- Агрегации по картам (клиентам) - левел 1
	select 		
		card, 
		-- дата 1й покупки клиента
		min(datetime)::date as first_user_date,
		-- дата последней покупки клиента
		max(datetime)::date as last_user_date,
		-- дней от даты анализа до последней активности клиента в аптечной сети
		max(max(datetime::date)) over () - max(datetime::date) as days,
		-- всего покупок совершенных клиентом
		count(*) as purchases,
		-- минимальный чек клиента
		min(summ) as min_sum,
		-- максимальный чек клиента
		max(summ) as max_sum,
		-- общая сумма покупок клиента
		sum(summ) as amount,
		-- средний чек клиента
		round(avg(summ)) as avg_sum,
		-- "возраста" клиента
		max(max(datetime::date)) over () - min(datetime)::date as age,
		-- дата анализа
		max(max(datetime::date)) over () as report_date
	from bonuscheques b 
	where length(card) = 13 
	group by card 
), thresholds_R as (	
	-- границы грейдов Recency
	select 
		-- нижняя граница 
		percentile_disc(0.20) within group (order by days) as low_border_R,
		-- верхняя граница
		percentile_disc(0.40) within group (order by days) as high_border_R
	from cards1	
), cards2 as (
	-- Агрегации по картам (клиентам) - левел 2
	select 		
		*,
		-- начальная дата периода активности клиента
		case 
			when (first_user_date + (select low_border_R from thresholds_R)) > report_date
			 	then report_date - (select low_border_R from thresholds_R)
			else first_user_date
		end	as start_activity,
		-- конечная дата периода активности клиента		
		case 
			when (last_user_date + (select drop_time from drop_time)) > report_date then report_date
			else last_user_date + (select drop_time from drop_time)
		end	as stop_activity
	from cards1 
), cards3 as (
	-- Агрегации по картам (клиентам) - левел 3
	select 		
		*,
		-- частота покупок на периоде активности клиента
		round((purchases*(select low_border_R from thresholds_R))::numeric / (stop_activity - start_activity), 2) as frequency
	from cards2 
), thresholds_F as (
	-- границы грейдов Frequency
	select			
		-- верхняя граница 
		percentile_disc(0.85) within group (order by frequency) as high_border_F,
		-- нижняя граница (частота одной покупки в течении периода оттока измеренного в базовых временных интервалах)	
		(select low_border_R from thresholds_R)::numeric / (select drop_time from drop_time) as low_border_F
	from cards3		
), thresholds_M as (
	-- границы грейдов Monetary
	select 
		-- нижняя граница
		percentile_disc(0.40) within group (order by summ) as low_border_M,
		-- средняя граница
		percentile_disc(0.80) within group (order by summ) as high_border_M	
	from bonuscheques b
), rfma as ( 
--, chck as (		-- стартя последконтроля
select 
	*,
--	card,
	-- классифицируем по Recency
	case 
		when days <= (select low_border_R from thresholds_R) then 1		--1й грейд
		when days <= (select high_border_R from thresholds_R) then 2	--2й грейд
  		when days <= (select drop_time from drop_time) then 3			--3й грейд
		else 4															--4й грейд
	end as R,
	-- классифицируем по Frequency		
	case 
		when frequency <= (select low_border_F from thresholds_F) then 3	--3й грейд
		when frequency < (select high_border_F from thresholds_F) then 2	--2й грейд
  		else 1																--1й грейд
	end	as F,
	-- классифицируем по Monetary
	case 
		when avg_sum <= (select low_border_M from thresholds_M) then 3		--3й грейд
		when avg_sum <= (select high_border_M from thresholds_M) then 2		--2й грейд
		else 1																--1й грейд
	end as M,	
	-- классифицируем по Age
	case 
		when age <= 30 then 3			--3й грейд
		when age <= 180 then 2			--2й грейд
		else 1							--1й грейд
	end as A,
	-- собираем в код сегмента
	concat(	case 					-- метрика R
				when days <= (select low_border_R from thresholds_R) then 1
				when days <= (select high_border_R from thresholds_R) then 2
		  		when days <= (select drop_time from drop_time) then 3
				else 4
			end,
			case 					-- метрика F
				when frequency <= (select low_border_F from thresholds_F) then 3
				when frequency < (select high_border_F from thresholds_F) then 2
		  		else 1
			end,
			case 					-- метрика M
				when avg_sum <= (select low_border_M from thresholds_M) then 3
				when avg_sum <= (select high_border_M from thresholds_M) then 2
				else 1
			end,	
			case 					-- метрика A
				when age <= 30 then 3
				when age <= 180 then 2
				else 1
			end ) as segment
from cards3
order by amount desc
), stat as (
select 
	r, f, m, a,
	segment, 
	coalesce(cnt, 0) as cnt, 
	description
from rfma_schema
left join (select segment, count(*) as cnt from rfma group by segment) t using(segment)
--order by segment
order by r,a,f,m
)
select 
	*
--	sum(cnt)
from stat
--where cnt != 0 and r = 4 --группировка "ушедшие" 
--where cnt != 0 and r = 4 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) 	--группа (41)
--where cnt != 0 and r = 4 and (f = 1 and m = 3 or f = 2 and (m = 2 or m = 3))	--группа (42)
--where cnt != 0 and r = 4 and f = 3											--группа (43)
--where cnt != 0 and r = 3 --группировка "давние" 
--where cnt != 0 and r = 3 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) 	--группа (31)
--where cnt != 0 and r = 3 and (f = 1 and m = 3 or f = 2 and (m = 2 or m = 3))	--группа (32)
--where cnt != 0 and r = 3 and f = 3											--группа (33)
--where cnt != 0 and r = 2 --группировка "спящие" 
--where cnt != 0 and r = 2 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) and (a = 1 or a =2) 	--группа (21)
--where cnt != 0 and r = 2 and (f = 1 and m = 3 or f = 2 and (m = 2 or m = 3)) and (a = 1 or a =2)	--группа (22)
--where cnt != 0 and r = 2 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) and a = 3		 	--группа (23)
--where cnt != 0 and r = 2 and (f = 1 and m = 3 or f = 2 and (m = 2 or m = 3)) and a = 3			--группа (24)
--where cnt != 0 and r = 2 and f = 3																--группа (25)
--where cnt != 0 and r = 1 --группировка "недавние" 
--where cnt != 0 and r = 1 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) and (a = 1 or a =2) 	--группа (11)
--where cnt != 0 and r = 1 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) and a = 1 	--группа (11)
--where cnt != 0 and r = 1 and (f = 1 and m = 3 or f = 2 and (m = 2 or m = 3)) and (a = 1 or a =2)	--группа (12)
--where cnt != 0 and r = 1 and m = 1 and a = 3		 												--группа (13)
--where cnt != 0 and r = 1 and (m = 2 or m = 3) and a = 3											--группа (14)
--where cnt != 0 and r = 1 and f = 3																--группа (15)
--

-- В результате построен классификатор:
--  всего классов - 108
--  в т.ч. не пустых - 72 
--            пустых - 36 ("вырожденные" вследствие непересечения по границам Recency - Age, с учетом Frequency)

-- Использовать 72 класса для дальнейшей работы с ними бизнес-подразделений нецелесообразно ввиду их большого числа, 
-- существенно разной емкости, возможной схожести при выборе более мягких критериев группировки, сложности администрирования
-- маркетинговой деятельности. 
-- Представляется оптимальным иметь не более 5-10 классов, для чего приступим к редукции

-- При группировке наших классов в укрупненные кластеры Будем исходить из возможных ответов на такие вопросы:
	-- как давно мы взаимодействовали с клиентом?
	-- лоялен ли он нам, или нет?
	-- каков его чек и как увеличить его чек?
	-- часто ли мы видимся с клиентом?

-- Первичную группировку произведем по метрике Recency поскольку она отвечает на главный вопрос: с нами клиент или ушел?
-- Соответсвенно, мы получаем два направления активностей: активности для улучшение клиентского опыта (повышения лояльности)
-- действующего клиента и активности для возврата и обратного привлечения ушедшего клиента. 


	-- Грейду 4 - "ушедший" соответствуют 15 не пустых классов нашего классификатора (2637 клиентов).
	-- Анализируя эти классы мы можем определить ценность для нас ушедших клиентов, соответственно настроить работу по их возврату.
	-- Итак, в 15 классах у нас присутствуют комбинации метрик:
			-- Frequency: "частый","редкий","разовый"
			-- Monetary: "высокий_чек","средний_чек","низкий_чек"
			-- Age: "ветеран","опытный"
	-- Сгруппируем наши подклассы исходя из предположения о наших ушедших клиента:
		-- группа "ушедший VIP"(41): 		Frequency: "частый", 	Monetary: "высокий_чек","средний_чек", 	Age: не важно 
										--  Frequency: "редкий", 	Monetary: "высокий_чек",				Age: не важно
		-- группа "ушедший середняк"(42):	Frequency: "частый", 	Monetary: "низкий_чек", 				Age: не важно 
								   		--  Frequency: "редкий", 	Monetary: "средний_чек", "низкий_чек"	Age: не важно							
		-- группа "ушедший случайный гость"(43):  	Frequency: "разовый", 	Monetary: не важно           			Age: не важно

		-- Емкость полученных групп: (41) - 212, (42) - 760, (43) - 1665 

	-- Грейду 3 - "давние" соответствуют 18 не пустых классов нашего классификатора (910 клиентов).
	-- Класс описывает еще не ушедших клиентов, но уже находящихся в группе риска оттока, соответственно, они требуют 
	-- внимания, какой-то стимулирующей и мотивирующей активности с нашей стороны.
 	-- Как и для класса 4 сгруппируем наши подклассы исходя из предположения о перспективности наших давних клиентов:
		-- группа "давний VIP"(31):			Frequency: "частый", 	Monetary: "высокий_чек","средний_чек", 	Age: не важно 
										--  Frequency: "редкий", 	Monetary: "высокий_чек",				Age: не важно
		-- группа "давний середняк"(32):	Frequency: "частый", 	Monetary: "низкий_чек", 				Age: не важно 
								   		--  Frequency: "редкий", 	Monetary: "средний_чек", "низкий_чек"	Age: не важно							
		-- группа "случайный гость"(33):  	Frequency: "разовый", 	Monetary: не важно           			Age: не важно

		-- Емкость полученных групп: (31) - 243, (32) - 595, (33) - 72

	-- Грейду 2 - "спящие" соответствуют 21 не пустой класс нашего классификатора (1187 клиентов).
	-- Класс описывает клиентов, у которых не было активности относительно не большой промежуток времени, соответственно, это наши клиенты,
	-- но им можно и нужно напомнить какие мы хорошие, чтобы простимулировать посещение любимой аптеки.
 	-- Сгруппируем наши подклассы исходя из предположения о качестве наших спящих клиентов:
		-- группа "спящий VIP"(21):				Frequency: "частый",	Monetary: "высокий_чек","средний_чек", 	Age: "ветеран", "опытный" 
									   	   --   Frequency: "редкий", 	Monetary: "высокий_чек",				Age: "ветеран", "опытный"
		-- группа "спящий середняк(22):			Frequency: "частый", 	Monetary: "низкий_чек",				 	Age: "ветеран", "опытный" 
									   	   --   Frequency: "редкий", 	Monetary: "средний_чек", "низкий_чек"	Age: "ветеран", "опытный"
		-- группа "добро пожаловать VIP"(23):	Frequency: "частый",	Monetary: "высокий_чек","средний_чек"	Age: "новичок" 
									   	   --   Frequency: "редкий", 	Monetary: "высокий_чек",				Age: "новичок" 
		-- группа "добро пожаловать"(24):		Frequency: "частый", 	Monetary: "низкий_чек",					Age: "новичок"
									   		--  Frequency: "редкий", 	Monetary: "средний_чек", "низкий_чек"	Age: "новичок"
		-- группа "случайный гость"(25):		Frequency: "разовый", 	Monetary: не важно, 					Age: не важно

		-- Емкость полученных групп: (21) - 318, (22) - 726, (23) - 35, (24) - 70, (25) - 38

	-- Грейду 1 - "недавние" соответствуют 18 не пустых подклассов нашего классификатора (1192 клиента).
	-- Грейд описывает клиентов, у которых была активность в самом недавнем прошлом, соответственно, в основном, это наши лучшие клиенты.
	-- Посмотрим, кто они.
 	-- Сгруппируем наши подклассы исходя из представлений о "лучшем клиенте":
		-- группа "VIP"(11):					Frequency: "частый",  Monetary: "высокий_чек", "средний_чек",	Age: "ветеран", "опытный" 
											--	Frequency: "редкий",  Monetary: "высокий_чек",				 	Age: "ветеран", "опытный"
		-- группа "середняк"(12): 				Frequency: "частый",  Monetary: "низкий_чек",				 	Age: "ветеран", "опытный" 
											--	Frequency: "редкий",  Monetary: "средний_чек", "низкий чек", 	Age: "ветеран", "опытный"
		-- группа "добро пожаловать VIP"(13):	Frequency: не важно,  Monetary: "высокий_чек"				 	Age: "новичок"
		-- группа "добро пожаловать"(14):		Frequency: не важно,  Monetary: "средний_чек", "низкий",	 	Age: "новичок"
		-- группа "случайный гость вернулся"(15):	Frequency: "разовый", Monetary: не важно 				 	Age: не важно 
		
		-- Емкость полученных групп: (11) - 336, (12) - 429, (13) - 108, (14) - 286, (15) - 33
		-- Примечание: в подгруппу 15 попали только клиенты с Age="ветеран" т.е.- это действительно вернувшиеся клиенты
	

-- Итак в результате редукции мы получили 16 подгрупп, которые также можно безболезненно укрупнить.

-- Примечание: В предложенной методике редукции грейды метрики Age использовались только в разбивке: 1- "ветеран"+"опытный" 
-- и 2 - "новичок". Т.е. смотрели на пользователей с точки зрения тех кто с нами не больше месяца и всех остальных. Если же, в перспективе, 
-- в какой-то маркетинговой активности мы захотим отметить длительность сотрудничества с клиентом, то можно будет осуществить 
-- более точную группировку с разбивкой по всем 3м грейдам метрики. 

-- Произведем прометку клиентов новыми подклассами


-- Произведем финальную RFMA-классификацию клиентов
with rfma_schema as (
	select 
		r, f, m, a,
		concat(r,f,m,a) as segment,
		concat_ws('-', description_R, description_F, description_M, description_A) as description
	from (select 1 as R, 'недавний' as description_R union select 2, 'спящий' union select 3, 'давний' union select 4, 'ушедший') t1
	cross join (select 1 as F, 'частый' as description_F union select 2, 'редкий' union select 3, 'разовый') t2
	cross join (select 1 as M, 'высокий_чек' as description_M union select 2, 'средний_чек' union select 3, 'низкий_чек') t3
	cross join (select 1 as A, 'ветеран' as description_A union select 2, 'опытный' union select 3, 'новичок') t4
), time_diffs as (
	select
		-- разница для вычисления периода оттока
		datetime::date - lag(datetime::date, 1) over (partition by card order by datetime::date) as diff
	from bonuscheques b
	where length(card) = 13
), drop_time as (
	select 
		-- период оттока (верхняя граница Recency)
		percentile_disc(0.95) within group (order by diff) as drop_time
	from time_diffs	
), cards1 as (
	-- Агрегации по картам (клиентам) - левел 1
	select 		
		card, 
		-- дата 1й покупки клиента
		min(datetime)::date as first_user_date,
		-- дата последней покупки клиента
		max(datetime)::date as last_user_date,
		-- дней от даты анализа до последней активности клиента в аптечной сети
		max(max(datetime::date)) over () - max(datetime::date) as days,
		-- всего покупок совершенных клиентом
		count(*) as purchases,
		-- минимальный чек клиента
		min(summ) as min_sum,
		-- максимальный чек клиента
		max(summ) as max_sum,
		-- общая сумма покупок клиента
		sum(summ) as amount,
		-- средний чек клиента
		round(avg(summ)) as avg_sum,
		-- "возраста" клиента
		max(max(datetime::date)) over () - min(datetime)::date as age,
		-- дата анализа
		max(max(datetime::date)) over () as report_date
	from bonuscheques b 
	where length(card) = 13 
	group by card 
), thresholds_R as (	
	-- границы грейдов Recency
	select 
		-- нижняя граница 
		percentile_disc(0.20) within group (order by days) as low_border_R,
		-- верхняя граница
		percentile_disc(0.40) within group (order by days) as high_border_R
	from cards1	
), cards2 as (
	-- Агрегации по картам (клиентам) - левел 2
	select 		
		*,
		-- начальная дата периода активности клиента
		case 
			when (first_user_date + (select low_border_R from thresholds_R)) > report_date
			 	then report_date - (select low_border_R from thresholds_R)
			else first_user_date
		end	as start_activity,
		-- конечная дата периода активности клиента		
		case 
			when (last_user_date + (select drop_time from drop_time)) > report_date then report_date
			else last_user_date + (select drop_time from drop_time)
		end	as stop_activity
	from cards1 
), cards3 as (
	-- Агрегации по картам (клиентам) - левел 3
	select 		
		*,
		-- частота покупок на периоде активности клиента
		round((purchases*(select low_border_R from thresholds_R))::numeric / (stop_activity - start_activity), 2) as frequency
	from cards2 
), thresholds_F as (
	-- границы грейдов Frequency
	select			
		-- верхняя граница 
		percentile_disc(0.85) within group (order by frequency) as high_border_F,
		-- нижняя граница (частота одной покупки в течении периода оттока измеренного в базовых временных интервалах)	
		(select low_border_R from thresholds_R)::numeric / (select drop_time from drop_time) as low_border_F
	from cards3		
), thresholds_M as (
	-- границы грейдов Monetary
	select 
		-- нижняя граница
		percentile_disc(0.40) within group (order by summ) as low_border_M,
		-- средняя граница
		percentile_disc(0.80) within group (order by summ) as high_border_M	
	from bonuscheques b
), rfma as ( 
	--, chck as (		-- старт последконтроля
	select 
		*,
	--	card,
		-- классифицируем по Recency
		case 
			when days <= (select low_border_R from thresholds_R) then 1		--1й грейд
			when days <= (select high_border_R from thresholds_R) then 2	--2й грейд
	  		when days <= (select drop_time from drop_time) then 3			--3й грейд
			else 4															--4й грейд
		end as R,
		-- классифицируем по Frequency		
		case 
			when frequency <= (select low_border_F from thresholds_F) then 3	--3й грейд
			when frequency < (select high_border_F from thresholds_F) then 2	--2й грейд
	  		else 1																--1й грейд
		end	as F,
		-- классифицируем по Monetary
		case 
			when avg_sum <= (select low_border_M from thresholds_M) then 3		--3й грейд
			when avg_sum <= (select high_border_M from thresholds_M) then 2		--2й грейд
			else 1																--1й грейд
		end as M,	
		-- классифицируем по Age
		case 
			when age <= 30 then 3			--3й грейд
			when age <= 180 then 2			--2й грейд
			else 1							--1й грейд
		end as A,
		-- собираем в код сегмента
		concat(	case 					-- метрика R
					when days <= (select low_border_R from thresholds_R) then 1
					when days <= (select high_border_R from thresholds_R) then 2
			  		when days <= (select drop_time from drop_time) then 3
					else 4
				end,
				case 					-- метрика F
					when frequency <= (select low_border_F from thresholds_F) then 3
					when frequency < (select high_border_F from thresholds_F) then 2
			  		else 1
				end,
				case 					-- метрика M
					when avg_sum <= (select low_border_M from thresholds_M) then 3
					when avg_sum <= (select high_border_M from thresholds_M) then 2
					else 1
				end,	
				case 					-- метрика A
					when age <= 30 then 3
					when age <= 180 then 2
					else 1
				end ) as segment
	from cards3
	order by amount desc
), stat_rfma as (
	select 
		r, f, m, a,
		segment, 
		coalesce(cnt, 0) as cnt, 
		description
	from rfma_schema
	left join (select segment, count(*) as cnt from rfma group by segment) t using(segment)
	order by r,a,f,m
), cluster_schema as (
	select
		41 as clust, 'ушедший VIP' as description, array[0, 0, 0, 1] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 1] a
	union select 41, 'ушедший VIP',   			   array[0, 0, 0, 1] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 1] a		 
    union select 42, 'ушедший середняк', 		   array[0, 0, 0, 1] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 1] a
    union select 42, 'ушедший середняк', 		   array[0, 0, 0, 1] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 1] a
    union select 43, 'ушедший случайный гость',    array[0, 0, 0, 1] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 1] a
	union select 31, 'давний VIP',   			   array[0, 0, 1, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 1] a
	union select 31, 'давний VIP',   			   array[0, 0, 1, 0] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 1] a
    union select 32, 'давний середняк', 		   array[0, 0, 1, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 1] a
    union select 32, 'давний середняк', 		   array[0, 0, 1, 0] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 1] a
    union select 33, 'давний случайный гость',     array[0, 0, 1, 0] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 1] a
	union select 21, 'спящий VIP',   			   array[0, 1, 0, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 0] a
	union select 21, 'спящий VIP',   			   array[0, 1, 0, 0] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 0] a
    union select 22, 'спящий середняк', 		   array[0, 1, 0, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 0] a
    union select 22, 'спящий середняк', 		   array[0, 1, 0, 0] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 0] a
	union select 23, 'спящий добро пожаловать VIP',array[0, 1, 0, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[0, 0, 1] a
	union select 23, 'спящий добро пожаловать VIP',array[0, 1, 0, 0] r, array[0, 1, 1] f, array[1, 0, 0] m, array[0, 0, 1] a	
	union select 24, 'спящий добро пожаловать',    array[0, 1, 0, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[0, 0, 1] a
   	union select 24, 'спящий добро пожаловать',    array[0, 1, 0, 0] r, array[0, 1, 1] f, array[0, 1, 1] m, array[0, 0, 1] a
    union select 25, 'случайный гость пробует вернуться', array[0, 1, 0, 0] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 0] a
	union select 11, 'VIP',			   			   array[1, 0, 0, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 0] a
	union select 11, 'VIP',			   			   array[1, 0, 0, 0] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 0] a
    union select 12, 'середняк',		 		   array[1, 0, 0, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 0] a
    union select 12, 'середняк', 				   array[1, 0, 0, 0] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 0] a
	union select 13, 'добро пожаловать VIP',   	   array[1, 0, 0, 0] r, array[1, 1, 1] f, array[1, 0, 0] m, array[0, 0, 1] a
	union select 14, 'добро пожаловать',   		   array[1, 0, 0, 0] r, array[1, 1, 1] f, array[0, 1, 1] m, array[0, 0, 1] a
    union select 15, 'случайный гость вернулся',   array[1, 0, 0, 0] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 1] a
), stat_cluster as (
	select
		*,
		(select min(clust) from cluster_schema where r[s.r]=1 and f[s.f]=1 and m[s.m]=1 and a[s.a]=1) as clust,
		(select min(description) from cluster_schema where r[s.r]=1 and f[s.f]=1 and m[s.m]=1 and a[s.a]=1) as clust_description
	from stat_rfma s
)
select
	clust, clust_description, sum(cnt)
from stat_cluster
group by clust, clust_description
order by clust


-- Финальная RFMA-классификация-кластеризация-регионы клиентов
with rfma_schema as (
	select 
		r, f, m, a,
		concat(r,f,m,a) as segment,
		concat_ws('-', description_R, description_F, description_M, description_A) as description
	from (select 1 as R, 'недавний' as description_R union select 2, 'спящий' union select 3, 'давний' union select 4, 'ушедший') t1
	cross join (select 1 as F, 'частый' as description_F union select 2, 'редкий' union select 3, 'разовый') t2
	cross join (select 1 as M, 'высокий_чек' as description_M union select 2, 'средний_чек' union select 3, 'низкий_чек') t3
	cross join (select 1 as A, 'ветеран' as description_A union select 2, 'опытный' union select 3, 'новичок') t4
), cluster_schema as (
	select
		41 as clust, 'ушедший VIP' as description, array[0, 0, 0, 1] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 1] a
	union select 41, 'ушедший VIP',   			   array[0, 0, 0, 1] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 1] a		 
    union select 42, 'ушедший середняк', 		   array[0, 0, 0, 1] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 1] a
    union select 42, 'ушедший середняк', 		   array[0, 0, 0, 1] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 1] a
    union select 43, 'ушедший случайный гость',    array[0, 0, 0, 1] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 1] a
	union select 31, 'давний VIP',   			   array[0, 0, 1, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 1] a
	union select 31, 'давний VIP',   			   array[0, 0, 1, 0] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 1] a
    union select 32, 'давний середняк', 		   array[0, 0, 1, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 1] a
    union select 32, 'давний середняк', 		   array[0, 0, 1, 0] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 1] a
    union select 33, 'давний случайный гость',     array[0, 0, 1, 0] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 1] a
	union select 21, 'спящий VIP',   			   array[0, 1, 0, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 0] a
	union select 21, 'спящий VIP',   			   array[0, 1, 0, 0] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 0] a
    union select 22, 'спящий середняк', 		   array[0, 1, 0, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 0] a
    union select 22, 'спящий середняк', 		   array[0, 1, 0, 0] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 0] a
	union select 23, 'спящий добро пожаловать VIP',array[0, 1, 0, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[0, 0, 1] a
	union select 23, 'спящий добро пожаловать VIP',array[0, 1, 0, 0] r, array[0, 1, 1] f, array[1, 0, 0] m, array[0, 0, 1] a	
	union select 24, 'спящий добро пожаловать',    array[0, 1, 0, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[0, 0, 1] a
   	union select 24, 'спящий добро пожаловать',    array[0, 1, 0, 0] r, array[0, 1, 1] f, array[0, 1, 1] m, array[0, 0, 1] a
    union select 25, 'случайный гость пробует вернуться', array[0, 1, 0, 0] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 0] a
	union select 11, 'VIP',			   			   array[1, 0, 0, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 0] a
	union select 11, 'VIP',			   			   array[1, 0, 0, 0] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 0] a
    union select 12, 'середняк',		 		   array[1, 0, 0, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 0] a
    union select 12, 'середняк', 				   array[1, 0, 0, 0] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 0] a
	union select 13, 'добро пожаловать VIP',   	   array[1, 0, 0, 0] r, array[1, 1, 1] f, array[1, 0, 0] m, array[0, 0, 1] a
	union select 14, 'добро пожаловать',   		   array[1, 0, 0, 0] r, array[1, 1, 1] f, array[0, 1, 1] m, array[0, 0, 1] a
    union select 15, 'случайный гость вернулся',   array[1, 0, 0, 0] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 1] a
), time_diffs as (
	select
		-- разница для вычисления периода оттока
		datetime::date - lag(datetime::date, 1) over (partition by card order by datetime::date) as diff
	from bonuscheques b
	where length(card) = 13
), drop_time as (
	select 
		-- период оттока (верхняя граница Recency)
		percentile_disc(0.95) within group (order by diff) as drop_time
	from time_diffs	
), cards1 as (
	-- Агрегации по картам (клиентам) - левел 1
	select 		
		card, 
		-- дата 1й покупки клиента
		min(datetime)::date as first_user_date,
		-- дата последней покупки клиента
		max(datetime)::date as last_user_date,
		-- дней от даты анализа до последней активности клиента в аптечной сети	
		max(max(datetime::date)) over () - max(datetime::date) as days,
		-- всего покупок совершенных клиентом
		count(*) as purchases,
		-- минимальный чек клиента
		min(summ) as min_sum,
		-- максимальный чек клиента
		max(summ) as max_sum,
		-- общая сумма покупок клиента
		sum(summ) as amount,
		-- средний чек клиента
		round(avg(summ)) as avg_sum,
		-- "возраста" клиента
		max(max(datetime::date)) over () - min(datetime)::date as age,
		-- дата анализа
		max(max(datetime::date)) over () as report_date
	from bonuscheques b 
	where length(card) = 13 
	group by card 
), thresholds_R as (	
	-- границы грейдов Recency
	select 
		-- нижняя граница 
		percentile_disc(0.20) within group (order by days) as low_border_R,
		-- верхняя граница
		percentile_disc(0.40) within group (order by days) as high_border_R
	from cards1	
), cards2 as (
	-- Агрегации по картам (клиентам) - левел 2
	select 		
		*,
		-- начальная дата периода активности клиента
		case 
			when (first_user_date + (select low_border_R from thresholds_R)) > report_date
			 	then report_date - (select low_border_R from thresholds_R)
			else first_user_date
		end	as start_activity,
		-- конечная дата периода активности клиента		
		case 
			when (last_user_date + (select drop_time from drop_time)) > report_date then report_date
			else last_user_date + (select drop_time from drop_time)
		end	as stop_activity
	from cards1 
), cards3 as (
	-- Агрегации по картам (клиентам) - левел 3
	select 		
		*,
		-- частота покупок на периоде активности клиента
		round((purchases*(select low_border_R from thresholds_R))::numeric / (stop_activity - start_activity), 2) as frequency
	from cards2 
), thresholds_F as (
	-- границы грейдов Frequency
	select			
		-- верхняя граница 
		percentile_disc(0.85) within group (order by frequency) as high_border_F,
		-- нижняя граница (частота одной покупки в течении периода оттока измеренного в базовых временных интервалах)	
		(select low_border_R from thresholds_R)::numeric / (select drop_time from drop_time) as low_border_F
	from cards3		
), thresholds_M as (
	-- границы грейдов Monetary
	select 
		-- нижняя граница
		percentile_disc(0.40) within group (order by summ) as low_border_M,
		-- средняя граница
		percentile_disc(0.80) within group (order by summ) as high_border_M	
	from bonuscheques b
), cards4 as ( 
    select 
    	*,
    	-- классифицируем по Recency
    	case 
    		when days <= (select low_border_R from thresholds_R) then 1		--1й грейд
    		when days <= (select high_border_R from thresholds_R) then 2	--2й грейд
      		when days <= (select drop_time from drop_time) then 3			--3й грейд
    		else 4															--4й грейд
    	end as R,
    	-- классифицируем по Frequency		
    	case 
    		when frequency <= (select low_border_F from thresholds_F) then 3	--3й грейд
    		when frequency < (select high_border_F from thresholds_F) then 2	--2й грейд
      		else 1																--1й грейд
    	end	as F,
    	-- классифицируем по Monetary
    	case 
    		when avg_sum <= (select low_border_M from thresholds_M) then 3		--3й грейд
    		when avg_sum <= (select high_border_M from thresholds_M) then 2		--2й грейд
    		else 1																--1й грейд
    	end as M,	
    	-- классифицируем по Age
    	case 
    		when age <= 30 then 3			--3й грейд
    		when age <= 180 then 2			--2й грейд
    		else 1							--1й грейд
    	end as A
    from cards3
    order by amount desc
), cards5 as (
    select
        *,
	    -- собираем в код сегмента
	    concat( r, f, m, a ) as segment
    from cards4
), rfma as (
    select 
        c.*,
    	r.description,
    	(select min(clust) from cluster_schema where r[c.r]=1 and f[c.f]=1 and m[c.m]=1 and a[c.a]=1) as clust,
		(select min(description) from cluster_schema where r[c.r]=1 and f[c.f]=1 and m[c.m]=1 and a[c.a]=1) as clust_description
    from cards5 c
    left join rfma_schema r using(segment)
)
    select
        *,
        case
            when clust in (11, 12) then 110 
            when clust in (12, 22) then 210
            when clust in (13, 14, 23, 24) then 220
            when clust in (15, 25) then 230
            when clust in (31, 32, 41, 42) then clust * 10
            when clust in (33, 43) then 510
        end as region,
        case
            when clust in (11, 12) then 'VIP'
            when clust in (12, 22) then 'сердняк'
            when clust in (13, 14, 23, 24) then 'добро пожаловать'
            when clust in (15, 25) then 'с возвращением'
            when clust in (31, 32, 41, 42) then clust_description
            when clust in (33, 43) then 'случайный гость'
        end as region_name   
    from rfma	
	
-- секция подсчета подгрупп при редукции	
--select	
--	*
--	Sum(cnt)
--from stat_rfma	
--where cnt != 0 and r = 4 --группировка "ушедшие" 
--where cnt != 0 and r = 4 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) 	--группа (41)
--where cnt != 0 and r = 4 and (f = 1 and m = 3 or f = 2 and (m = 2 or m = 3))	--группа (42)
--where cnt != 0 and r = 4 and f = 3											--группа (43)
--where cnt != 0 and r = 3 --группировка "давние" 
--where cnt != 0 and r = 3 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) 	--группа (31)
--where cnt != 0 and r = 3 and (f = 1 and m = 3 or f = 2 and (m = 2 or m = 3))	--группа (32)
--where cnt != 0 and r = 3 and f = 3											--группа (33)
--where cnt != 0 and r = 2 --группировка "спящие" 
--where cnt != 0 and r = 2 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) and (a = 1 or a =2) 	--группа (21)
--where cnt != 0 and r = 2 and (f = 1 and m = 3 or f = 2 and (m = 2 or m = 3)) and (a = 1 or a =2)	--группа (22)
--where cnt != 0 and r = 2 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) and a = 3		 	--группа (23)
--where cnt != 0 and r = 2 and (f = 1 and m = 3 or f = 2 and (m = 2 or m = 3)) and a = 3			--группа (24)
--where cnt != 0 and r = 2 and f = 3																--группа (25)
--where cnt != 0 and r = 1 --группировка "недавние" 
--where cnt != 0 and r = 1 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) and (a = 1 or a =2) 	--группа (11)
--where cnt != 0 and r = 1 and (f = 1 and (m = 1 or m = 2) or f = 2 and m = 1) and a = 1 	--группа (11)
--where cnt != 0 and r = 1 and (f = 1 and m = 3 or f = 2 and (m = 2 or m = 3)) and (a = 1 or a =2)	--группа (12)
--where cnt != 0 and r = 1 and m = 1 and a = 3		 												--группа (13)
--where cnt != 0 and r = 1 and (m = 2 or m = 3) and a = 3											--группа (14)
--where cnt != 0 and r = 1 and f = 3																--группа (15)
-- стоп секции подсчета подгрупп при редукции

-- секция последконтроля
)
, t as (
select 
	count(case when R = 1 then 1 end) as r1,
	count(case when R = 2 then 1 end) as r2,
	count(case when R = 3 then 1 end) as r3,
	count(case when R = 4 then 1 end) as r4,
	count(case when F = 1 then 1 end) as f1,
	count(case when F = 2 then 1 end) as f2,
	count(case when F = 3 then 1 end) as f3,
	count(case when M = 1 then 1 end) as m1,
	count(case when M = 2 then 1 end) as m2,
	count(case when M = 3 then 1 end) as m3,
	count(case when A = 1 then 1 end) as a1,
	count(case when A = 2 then 1 end) as a2,
	count(case when A = 3 then 1 end) as a3,
	count(*) as total
from chck
)
select
	total, r1+r2+r3+r4 as r,
	r1,	round(100.0*r1/total, 2) as r1p,
	r2, round(100.0*r2/total, 2) as r2p,
	r3, round(100.0*r3/total, 2) as r3p,
	r4, round(100.0*r4/total, 2) as r4p,
	f1+f2+f3 as f,
	f1, round(100.0*f1/total, 2) as f1p,
	f2, round(100.0*f2/total, 2) as f2p,
	f3, round(100.0*f3/total, 2) as f3p,
	m1+m2+m3 as m,
	m1, round(100.0*m1/total, 2) as m1p,
	m2, round(100.0*m2/total, 2) as m2p,
	m3, round(100.0*m3/total, 2) as m3p,
	a1+a2+a3 as m,
	a1, round(100.0*a1/total, 2) as a1p,
	a2, round(100.0*a2/total, 2) as a2p,
	a3, round(100.0*a3/total, 2) as a3p
from t
-- стоп последконтроля






-- Финальная RFMA-классификацию-кластеризаци-регионирование клиентов
with rfma_schema as (
	select 
		r, f, m, a,
		concat(r,f,m,a) as segment,
		concat_ws('-', description_R, description_F, description_M, description_A) as description
	from (select 1 as R, 'недавний' as description_R union select 2, 'спящий' union select 3, 'давний' union select 4, 'ушедший') t1
	cross join (select 1 as F, 'частый' as description_F union select 2, 'редкий' union select 3, 'разовый') t2
	cross join (select 1 as M, 'высокий_чек' as description_M union select 2, 'средний_чек' union select 3, 'низкий_чек') t3
	cross join (select 1 as A, 'ветеран' as description_A union select 2, 'опытный' union select 3, 'новичок') t4
), cluster_schema as (
	select
		41 as clust, 'ушедший VIP' as description, array[0, 0, 0, 1] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 1] a
	union select 41, 'ушедший VIP',   			   array[0, 0, 0, 1] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 1] a		 
    union select 42, 'ушедший середняк', 		   array[0, 0, 0, 1] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 1] a
    union select 42, 'ушедший середняк', 		   array[0, 0, 0, 1] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 1] a
    union select 43, 'ушедший случайный гость',    array[0, 0, 0, 1] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 1] a
	union select 31, 'давний VIP',   			   array[0, 0, 1, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 1] a
	union select 31, 'давний VIP',   			   array[0, 0, 1, 0] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 1] a
    union select 32, 'давний середняк', 		   array[0, 0, 1, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 1] a
    union select 32, 'давний середняк', 		   array[0, 0, 1, 0] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 1] a
    union select 33, 'давний случайный гость',     array[0, 0, 1, 0] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 1] a
	union select 21, 'спящий VIP',   			   array[0, 1, 0, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 0] a
	union select 21, 'спящий VIP',   			   array[0, 1, 0, 0] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 0] a
    union select 22, 'спящий середняк', 		   array[0, 1, 0, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 0] a
    union select 22, 'спящий середняк', 		   array[0, 1, 0, 0] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 0] a
	union select 23, 'спящий добро пожаловать VIP',array[0, 1, 0, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[0, 0, 1] a
	union select 23, 'спящий добро пожаловать VIP',array[0, 1, 0, 0] r, array[0, 1, 1] f, array[1, 0, 0] m, array[0, 0, 1] a	
	union select 24, 'спящий добро пожаловать',    array[0, 1, 0, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[0, 0, 1] a
   	union select 24, 'спящий добро пожаловать',    array[0, 1, 0, 0] r, array[0, 1, 1] f, array[0, 1, 1] m, array[0, 0, 1] a
    union select 25, 'случайный гость пробует вернуться', array[0, 1, 0, 0] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 0] a
	union select 11, 'VIP',			   			   array[1, 0, 0, 0] r, array[1, 0, 0] f, array[1, 1, 0] m, array[1, 1, 0] a
	union select 11, 'VIP',			   			   array[1, 0, 0, 0] r, array[0, 1, 0] f, array[1, 0, 0] m, array[1, 1, 0] a
    union select 12, 'середняк',		 		   array[1, 0, 0, 0] r, array[1, 0, 0] f, array[0, 0, 1] m, array[1, 1, 0] a
    union select 12, 'середняк', 				   array[1, 0, 0, 0] r, array[0, 1, 0] f, array[0, 1, 1] m, array[1, 1, 0] a
	union select 13, 'добро пожаловать VIP',   	   array[1, 0, 0, 0] r, array[1, 1, 1] f, array[1, 0, 0] m, array[0, 0, 1] a
	union select 14, 'добро пожаловать',   		   array[1, 0, 0, 0] r, array[1, 1, 1] f, array[0, 1, 1] m, array[0, 0, 1] a
    union select 15, 'случайный гость вернулся',   array[1, 0, 0, 0] r, array[0, 0, 1] f, array[1, 1, 1] m, array[1, 1, 1] a
), time_diffs as (
	select
		-- разница для вычисления периода оттока
		datetime::date - lag(datetime::date, 1) over (partition by card order by datetime::date) as diff
	from bonuscheques b
	where length(card) = 13
), drop_time as (
	select 
		-- период оттока (верхняя граница Recency)
		percentile_disc(0.95) within group (order by diff) as drop_time
	from time_diffs	
), cards1 as (
	-- Агрегации по картам (клиентам) - левел 1
	select 		
		card, 
		-- дата 1й покупки клиента
		min(datetime)::date as first_user_date,
		-- дата последней покупки клиента
		max(datetime)::date as last_user_date,
		-- дней от даты анализа до последней активности клиента в аптечной сети
		max(max(datetime::date)) over () - max(datetime::date) as days,
		-- всего покупок совершенных клиентом
		count(*) as purchases,
		-- минимальный чек клиента
		min(summ) as min_sum,
		-- максимальный чек клиента
		max(summ) as max_sum,
		-- общая сумма покупок клиента
		sum(summ) as amount,
		-- средний чек клиента
		round(avg(summ)) as avg_sum,
		-- "возраста" клиента
		max(max(datetime::date)) over () - min(datetime)::date as age,
		-- дата анализа
		max(max(datetime::date)) over () as report_date
	from bonuscheques b 
	where length(card) = 13 
	group by card 
), thresholds_R as (	
	-- границы грейдов Recency
	select 
		-- нижняя граница 
		percentile_disc(0.20) within group (order by days) as low_border_R,
		-- верхняя граница
		percentile_disc(0.40) within group (order by days) as high_border_R
	from cards1	
), cards2 as (
	-- Агрегации по картам (клиентам) - левел 2
	select 		
		*,
		-- начальная дата периода активности клиента
		case 
			when (first_user_date + (select low_border_R from thresholds_R)) > report_date
			 	then report_date - (select low_border_R from thresholds_R)
			else first_user_date
		end	as start_activity,
		-- конечная дата периода активности клиента		
		case 
			when (last_user_date + (select drop_time from drop_time)) > report_date then report_date
			else last_user_date + (select drop_time from drop_time)
		end	as stop_activity
	from cards1 
), cards3 as (
	-- Агрегации по картам (клиентам) - левел 3
	select 		
		*,
		-- частота покупок на периоде активности клиента
		round((purchases*(select low_border_R from thresholds_R))::numeric / (stop_activity - start_activity), 2) as frequency
	from cards2 
), thresholds_F as (
	-- границы грейдов Frequency
	select			
		-- верхняя граница 
		percentile_disc(0.85) within group (order by frequency) as high_border_F,
		-- нижняя граница (частота одной покупки в течении периода оттока измеренного в базовых временных интервалах)	
		(select low_border_R from thresholds_R)::numeric / (select drop_time from drop_time) as low_border_F
	from cards3		
), thresholds_M as (
	-- границы грейдов Monetary
	select 
		-- нижняя граница
		percentile_disc(0.40) within group (order by summ) as low_border_M,
		-- средняя граница
		percentile_disc(0.80) within group (order by summ) as high_border_M	
	from bonuscheques b
), cards4 as ( 
    select 
    	*,
    	-- классифицируем по Recency
    	case 
    		when days <= (select low_border_R from thresholds_R) then 1		--1й грейд
    		when days <= (select high_border_R from thresholds_R) then 2	--2й грейд
      		when days <= (select drop_time from drop_time) then 3			--3й грейд
    		else 4															--4й грейд
    	end as R,
    	-- классифицируем по Frequency		
    	case 
    		when frequency <= (select low_border_F from thresholds_F) then 3	--3й грейд
    		when frequency < (select high_border_F from thresholds_F) then 2	--2й грейд
      		else 1																--1й грейд
    	end	as F,
    	-- классифицируем по Monetary
    	case 
    		when avg_sum <= (select low_border_M from thresholds_M) then 3		--3й грейд
    		when avg_sum <= (select high_border_M from thresholds_M) then 2		--2й грейд
    		else 1																--1й грейд
    	end as M,	
    	-- классифицируем по Age
    	case 
    		when age <= 30 then 3			--3й грейд
    		when age <= 180 then 2			--2й грейд
    		else 1							--1й грейд
    	end as A
    from cards3
    order by amount desc
), cards5 as (
    select
        *,
	    -- собираем в код сегмента
	    concat( r, f, m, a ) as segment
    from cards4
), rfma as (
    select 
        c.*,
    	r.description,
    	(select min(clust) from cluster_schema where r[c.r]=1 and f[c.f]=1 and m[c.m]=1 and a[c.a]=1) as clust,
		(select min(description) from cluster_schema where r[c.r]=1 and f[c.f]=1 and m[c.m]=1 and a[c.a]=1) as clust_description
    from cards5 c
    left join rfma_schema r using(segment)
), regions as (
    select
        *,
        case
            when clust in (11, 21) then 110 
            when clust in (12, 22) then 210
            when clust in (13, 14, 23, 24) then 220
            when clust in (15, 25) then 230
            when clust in (31, 32, 41, 42) then clust * 10
            when clust in (33, 43) then 510
        end as region,
        case
            when clust in (11, 21) then 'VIP'
            when clust in (12, 22) then 'середняк'
            when clust in (13, 14, 23, 24) then 'добро пожаловать'
            when clust in (15, 25) then 'с возвращением'
            when clust in (31, 32, 41, 42) then clust_description
            when clust in (33, 43) then 'случайный гость'
        end as region_name   
    from rfma
)
select 
    count(distinct card) as totall_cards
from bonuscheques
left join regions using(card) 
where length(bonuscheques.card) = 13 
    [[ and region_name = split_part( {{region1}}, ' - ', 2)]]
    [[ and bonuscheques.datetime >= {{date1}} and bonuscheques.datetime <= {{date2}}]]

    

