# Дашборд Redash для приложения доставки для метрик выручки и рентабельности

## Обзор проекта 

Схема базы данных:
![Схема](https://github.com/v-makarov-code/product-delivery-dashboard-profitability-revenue/blob/main/database_schema.jpg)

**Цель:** Разработать дашборд в Redash с метриками выручки и рентабельности  
**Задачи:**
1. Для каждого дня расчитать выручку, суммарную выручку, прирост выручки
2. Расчитать метрики: ARPU, ARPPU, AOV для каждого дня
3. Расчитать Running ARPU, Running ARPPU, Running AOV
4. Расчитать ARPU, ARPPU, AOV по дням недели
5. Расчитать ежедневную выручку с заказов новых пользователей, и их долю от общей выручки с заказов всех пользователей
6. Расчитать суммарную выручку по основным продуктам
7. Расчитать следующие показатели в одном запросе для каждого дня:
   - Выручку, полученную в этот день
   - Затраты, образовавшиеся в этот день
   - Сумму НДС с продажи товаров в этот день
   - Валовую прибыль в этот день
   - Суммарную выручку на текущий день
   - Суммарные затраты на текущий день
   - Суммарный НДС на текущий день
   - Суммарную валовую прибыль на текущий день
   - Долю валовой прибыли в выручке за этот день
   - Долю суммарной валовой прибыли в суммарной выручке на текущий день


## Стек

- Redash
- PostgreSQL

## Вид дашборда
[Ссылка на дашборд](https://redash.public.karpov.courses/public/dashboards/XiKbmG1ytqokwEUMjMD8x56RA5w1QQtrNrg2jdXb?org_slug=default)

![дашдорд1](https://github.com/v-makarov-code/product-delivery-dashboard-profitability-revenue/blob/main/dashboard1.png)
![дашдорд2](https://github.com/v-makarov-code/product-delivery-dashboard-profitability-revenue/blob/main/dashboard2.png)
![дашдорд3](https://github.com/v-makarov-code/product-delivery-dashboard-profitability-revenue/blob/main/dashboard3.png)
