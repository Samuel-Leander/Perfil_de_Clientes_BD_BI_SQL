--Criação da tabela profissões
create table temp_tables.profissoes (
	professional_status varchar,
	status_profissional varchar
);

insert into temp_tables.profissoes
(professional_status, status_profissional)

values
('freelancer', 'freelancer'),
('retired', 'aposentado(a)'),
('clt', 'clt'),
('self_employed', 'autônomo(a)'),
('other', 'outro'),
('businessman', 'empresário(a)'),
('civil_servant', 'funcionário público(a)'),
('student', 'estudante')

insert into temp_tables.profissoes (professional_status, status_profissional)
values
('unemployed','desempregado'),
('trainee','estagiário')

-- Criando a função datediff
create function datediff(unidade varchar, data_inicial date, data_final date)
returns integer
language sql

as

$$

	select
		case
			when unidade in ('d', 'day', 'days') then (data_final - data_inicial)
			when unidade in ('w', 'week', 'weeks') then (data_final - data_inicial)/7
			when unidade in ('m', 'month', 'months') then (data_final - data_inicial)/30
			when unidade in ('y', 'year', 'years') then (data_final - data_inicial)/365
			end as diferenca

$$

select datediff('years', '2001-02-04', current_date)

-- Query 1: gênero dos leads
select
	case
		when ibge.gender = 'male' then 'homens'
		when ibge.gender = 'female' then 'mulheres'
		end as "gênero",
	count(*) as "leads (#)"
from sales.customers as cus
left join temp_tables.ibge_genders as ibge
	on lower(cus.first_name) = lower(ibge.first_name)
group by ibge.gender

--Query 2: status profissional
select 
	prof.status_profissional,
	count(*) as "tipo de profissão"
from temp_tables.profissoes as prof
full join sales.customers as cus
	on lower(prof.professional_status) = lower(cus.professional_status)
group by status_profissional

select * from temp_tables.profissoes

--Query 3:  faixa etária
select
	case
		when datediff('years', birth_date, current_date) < 20 then '0-20'
		when datediff('years', birth_date, current_date) < 40 then '20-40'
		when datediff('years', birth_date, current_date) < 60 then '40-60'
		when datediff('years', birth_date, current_date) < 80 then '60-80'
		else '80+' end "faixa etária",
		count(*)::float/(select count(*) from sales.customers) as "leads(%)"
from sales.customers
group by "faixa etária"
order by "faixa etária"

--Query 4: faixa salarial
select
	case
		when income < 5000 then '0-5000'
		when income < 1000 then '5000-10000'
		when income < 15000 then '10000-15000'
		when income < 20000 then '15000-20000'
		else '20000+' end "faixa salarial",
		count(*)::float/(select count(*) from sales.customers) as "leads(%)"
from sales.customers
group by "faixa salarial"
order by "faixa salarial"

--Query 5: veículos visitados (novos e seminovos)
with
	classificacao_veiculos as (

		select
			fun.visit_page_date,
			prod.model_year,
			extract('year' from visit_page_date) - prod.model_year::int as idade_veiculo,
			case
				when (extract('year' from visit_page_date) - prod.model_year::int) <=2 then 'novo'
				else 'seminovo'
				end as "classificação do veículo"

		from sales.funnel as fun
		left join sales.products as prod
			on fun.product_id = prod.product_id
	)
select
	"classificação do veículo",
	count(*) as "veículos visitados"
from classificacao_veiculos
group by "classificação do veículo"

-- Query 6: idade dos veículos
with
	idade_veiculos as (

		select
			fun.visit_page_date,
			prod.model_year,
			extract('year' from visit_page_date) - prod.model_year::int as idade_veiculo,
			case
				when (extract('year' from visit_page_date) - prod.model_year::int) <=2 then 'até 2 anos'
				when (extract('year' from visit_page_date) - prod.model_year::int) <=4 then 'de 2 à 4 anos'
				when (extract('year' from visit_page_date) - prod.model_year::int) <=6 then 'de 4 à 6 anos'
				when (extract('year' from visit_page_date) - prod.model_year::int) <=8 then 'de 6 à 8 anos'
				when (extract('year' from visit_page_date) - prod.model_year::int) <=10 then 'de 8 à 10 anos'
				else 'mais de 10 anos'
				end as "idade do veículo"
								
		from sales.funnel as fun
		left join sales.products as prod
			on fun.product_id = prod.product_id
	)
select
	"idade do veículo",
	count(*)::float/(select count(*) from sales.funnel) as "veículos visitados"
from idade_veiculos
group by "idade do veículo"
order by "idade do veículo"

--Query 7: modelos mais visitados por marca
select
	prod.brand,
	prod.model,
	count(*) as "visitas"
	
from sales.funnel as fun
left join sales.products as prod
	on fun.product_id = prod.product_id
group by prod.brand, prod.model
order by prod.brand, prod.model, "visitas"