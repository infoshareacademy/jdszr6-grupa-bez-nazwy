select * from county_facts

select * from county_facts_dictionary
where column_name = 'PST045214' or column_name = 'POP010210' or column_name = 'POP060210'


create temp table dane_populacja as 
select state,county,  party, candidate, votes, fraction_votes , 
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g³_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g³_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g³_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g³_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g³_stan_partia,
PST045214 as estymacyjna_pop_2014_hr, 
round(sum(PST045214) over (partition by state), 2) as estymacyjna_pop_2014_stan,
POP010210 as pop_2010_real_hr,
round(sum(POP010210) over (partition by state), 2) as pop_2010_real_stan,
POP060210 as zageszczenie_2010_hr,
round(avg(POP060210 ) over (partition by state), 2) as zageszczenie_2010_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips
order by PST045214 desc

--WOE i IV dla populacji w 2010 roku --

/* sprawdzenie ile wyników bêdzie w danej grupie*/


select wielkoœæ_hrabstwa,  count(*) from /*OK*/
(select distinct county, state,
case when pop_2010_real_hr < 10000 then '0 - 10 tyœ'
when pop_2010_real_hr < 30000 then '10 - 30 tyœ'
when pop_2010_real_hr < 50000 then '30 - 50 tyœ'
when pop_2010_real_hr < 100000 then '50 - 100 tyœ'
when pop_2010_real_hr < 300000 then '100 - 300 tyœ'
else 'powy¿ej 300 tyœ'
end as wielkoœæ_hrabstwa
from dane_populacja)x
group by wielkoœæ_hrabstwa

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_populacj as
with rep as
(select distinct party, wielkoœæ_hrabstwa, sum(votes) over (partition by party, wielkoœæ_hrabstwa) as liczba_g³_republikanie,
sum (votes) over (partition by party) as suma_ca³kowita_partia_rep from
(select party, votes, 
case when pop_2010_real_hr < 10000 then '0 - 10 tyœ'
when pop_2010_real_hr < 30000 then '10 - 30 tyœ'
when pop_2010_real_hr < 50000 then '30 - 50 tyœ'
when pop_2010_real_hr < 100000 then '50 - 100 tyœ'
when pop_2010_real_hr < 300000 then '100 - 300 tyœ'
else 'powy¿ej 300 tyœ'
end as wielkoœæ_hrabstwa
from dane_populacja
group by party, votes, pop_2010_real_hr
order by wielkoœæ_hrabstwa)m
where party = 'Republican'),
dem as
(select distinct party, wielkoœæ_hrabstwa, sum(votes) over (partition by party, wielkoœæ_hrabstwa) as liczba_g³_demokraci,
sum (votes) over (partition by party) as suma_ca³kowita_partia_dem from
(select party, votes, 
case when pop_2010_real_hr < 10000 then '0 - 10 tyœ'
when pop_2010_real_hr < 30000 then '10 - 30 tyœ'
when pop_2010_real_hr < 50000 then '30 - 50 tyœ'
when pop_2010_real_hr < 100000 then '50 - 100 tyœ'
when pop_2010_real_hr < 300000 then '100 - 300 tyœ'
else 'powy¿ej 300 tyœ'
end as wielkoœæ_hrabstwa
from dane_populacja
group by party, votes, pop_2010_real_hr
order by wielkoœæ_hrabstwa)m
where party = 'Democrat')
select rep.wielkoœæ_hrabstwa, liczba_g³_republikanie, liczba_g³_demokraci,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as WOE,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as dr_dd,
(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) * ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.wielkoœæ_hrabstwa = dem.wielkoœæ_hrabstwa



select *
from v_iv_populacj 
order by wielkoœæ_hrabstwa;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_populacj /*œredni predyktor - 0.152*/

-- analiza w podziale na podgrupy -- dane do u¿ycia

/* wykaz hrabstw stosunek procentowy g³osów na dan¹ patiê (w podziale na grupy iloœciowe) - do pokazania na mapie*/

with stany as
(select county, state, party, wielkoœæ_hrabstwa from
(select  distinct county, state, party,
case when pop_2010_real_hr < 10000 then '0 - 10 tyœ'
when pop_2010_real_hr < 30000 then '10 - 30 tyœ'
when pop_2010_real_hr < 50000 then '30 - 50 tyœ'
when pop_2010_real_hr < 100000 then '50 - 100 tyœ'
when pop_2010_real_hr < 300000 then '100 - 300 tyœ'
else 'powy¿ej 300 tyœ'
end as wielkoœæ_hrabstwa
from dane_populacja)x) 
select county, state, party, stany.wielkoœæ_hrabstwa,
liczba_g³_republikanie, liczba_g³_demokraci,
case when liczba_g³_republikanie  > liczba_g³_demokraci
then 'Republikanie'
when liczba_g³_republikanie  < liczba_g³_demokraci
then 'Demokraci'
end as winner
from stany
join v_iv_populacj vip
on stany.wielkoœæ_hrabstwa = vip.wielkoœæ_hrabstwa /*poprawne*/





--WOE i IV dla zagêszczenia w 2010 roku --

/* sprawdzenie ile wyników bêdzie w danej grupie*/

select zagêszczenie_hrabstwa, count(*) from
(select party, votes, county,
case when zageszczenie_2010_hr < 50 then '0 - 50'
when zageszczenie_2010_hr < 100 then '50 - 100'
when zageszczenie_2010_hr < 200 then '100 - 200'
when zageszczenie_2010_hr < 500 then '200 - 500'
when zageszczenie_2010_hr< 1000 then '500 - 1000'
else '1000 +'
end as zagêszczenie_hrabstwa
from dane_populacja)x
group by zagêszczenie_hrabstwa

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_zageszczenie as
with rep as
(select distinct party, zagêszczenie_hrabstwa, sum(votes) over (partition by party, zagêszczenie_hrabstwa) as liczba_g³_republikanie,
sum (votes) over (partition by party) as suma_ca³kowita_partia_rep from
(select party, votes, 
case when zageszczenie_2010_hr < 50 then '0 - 50'
when zageszczenie_2010_hr < 100 then '50 - 100'
when zageszczenie_2010_hr < 200 then '100 - 200'
when zageszczenie_2010_hr < 500 then '200 - 500'
when zageszczenie_2010_hr< 1000 then '500 - 1000'
else '1000 +'
end as zagêszczenie_hrabstwa
from dane_populacja
group by party, votes, zageszczenie_2010_hr
order by zagêszczenie_hrabstwa)m
where party = 'Republican'),
dem as
(select distinct party, zagêszczenie_hrabstwa, sum(votes) over (partition by party, zagêszczenie_hrabstwa) as liczba_g³_demokraci,
sum (votes) over (partition by party) as suma_ca³kowita_partia_dem from
(select party, votes, 
case when zageszczenie_2010_hr < 50 then '0 - 50'
when zageszczenie_2010_hr < 100 then '50 - 100'
when zageszczenie_2010_hr < 200 then '100 - 200'
when zageszczenie_2010_hr < 500 then '200 - 500'
when zageszczenie_2010_hr< 1000 then '500 - 1000'
else '1000 +'
end as zagêszczenie_hrabstwa
from dane_populacja
group by party, votes, zageszczenie_2010_hr
order by zagêszczenie_hrabstwa)m
where party = 'Democrat')
select rep.zagêszczenie_hrabstwa, liczba_g³_republikanie, liczba_g³_demokraci,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as WOE,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as dr_dd,
(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) * ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.zagêszczenie_hrabstwa = dem.zagêszczenie_hrabstwa


select *
from v_iv_zageszczenie
order by zagêszczenie_hrabstwa;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_zageszczenie /*œredni predyktor - 0.191*/

/* wykaz hrabstw stosunek procentowy g³osów na dan¹ patiê (w podziale na grupy iloœciowe)*/

with stany as
(select county, state, party, zagêszczenie_hrabstwa from
(select  distinct county, state, party,
case when zageszczenie_2010_hr < 50 then '0 - 50'
when zageszczenie_2010_hr < 100 then '50 - 100'
when zageszczenie_2010_hr < 200 then '100 - 200'
when zageszczenie_2010_hr < 500 then '200 - 500'
when zageszczenie_2010_hr< 1000 then '500 - 1000'
else '1000 +'
end as zagêszczenie_hrabstwa
from dane_populacja)x) 
select county, state, party, stany.zagêszczenie_hrabstwa,
liczba_g³_republikanie, liczba_g³_demokraci,
case when liczba_g³_republikanie  > liczba_g³_demokraci
then 'Republikanie'
when liczba_g³_republikanie  < liczba_g³_demokraci
then 'Demokraci'
end as winner
from stany
join v_iv_zageszczenie vig
on stany.zagêszczenie_hrabstwa = vig.zagêszczenie_hrabstwa /*poprawne*/



/*Zestawienie sumaryczne - partia ze wzglêdu na wygrane stany*/


with real_2010 as 
(select distinct party, round(avg(pop_2010_real_stan),  2) as œr_populac_2010_real, 
sum(pop_2010_real_stan) as il_ludzi_real_2010,
count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, pop_2010_real_stan
from
(select distinct state, party, prct_g³_stan_all,  pop_2010_real_stan
from dane_populacja
)dem
group by party, state, pop_2010_real_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
zageszczenie_2010 as 
(select distinct party, round(avg(zageszczenie_2010_stan),  2) as œr_zageszczenie_2010, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, zageszczenie_2010_stan
from
(select distinct state, party, prct_g³_stan_all,  zageszczenie_2010_stan
from dane_populacja
)dem
group by party, state, zageszczenie_2010_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party)
select real_2010.party, œr_populac_2010_real,il_ludzi_real_2010,œr_zageszczenie_2010,  real_2010.liczba_wygranych
from real_2010
join zageszczenie_2010
on real_2010.party = zageszczenie_2010.party




 /*b) zale¿noœæ - g³ na partiê - (uœrednione wyniki ca³oœciowe) - statystyka nic nie znacz¹ca*//
 
select distinct party, sum(votes) over (partition by party) as liczba_g³_partia, 
round(avg(pop_2010_real_hr) over (partition by party), 2) as œr_pop_rzeczywista,
round(avg(zageszczenie_2010_hr) over (partition by party), 2) as œr_zageszczenie_2010
from dane_populacja
group by party, votes, pop_2010_real_hr, zageszczenie_2010_hr
order by sum(votes) over (partition by party) desc



/*b) wybór partii, wygrane hrabstwa*/


with wielkosc as
(select party, round(avg(pop_2010_real_hr),  2) as œrednia_wielkoœæ_populacji, count (*) as liczba_wygranych from
(select state, county,liczba_g³osów_partia, party, pop_2010_real_hr,
dense_rank () over (partition by county, state order by liczba_g³osów_partia desc) as ranking from
(select distinct state, county, party, 
sum(votes) as liczba_g³osów_partia, 
pop_2010_real_hr
from dane_populacja dp 
group by party, county, pop_2010_real_hr, state
order by county)rkg)naj
where ranking = 1
group by  party),
zageszczenie as 
(select party, round(avg(zageszczenie_2010_hr),  2) as œrednia_zageszczenie_populacji, count (*) as liczba_wygranych from
(select state, county,liczba_g³osów_partia, party, zageszczenie_2010_hr,
dense_rank () over (partition by county, state order by liczba_g³osów_partia desc) as ranking from
(select distinct state, county, party, 
sum(votes) as liczba_g³osów_partia, 
zageszczenie_2010_hr
from dane_populacja dp 
group by party, county, zageszczenie_2010_hr, state
order by county)rkg)naj
where ranking = 1
group by  party)
select wielkosc.party, œrednia_wielkoœæ_populacji, œrednia_zageszczenie_populacji, wielkosc.liczba_wygranych
from wielkosc
join zageszczenie
on wielkosc.party = zageszczenie.party



-- badanie korelacji pomiêdzy g³osami populacji, a parti¹

select party, 
corr(votes, pop_2010_real_hr) as korelacja_populacja_2010,
corr(votes, zageszczenie_2010_hr) as korelacja_zageszczenie_2010
from dane_populacja
group by party
order by corr(votes, pop_2010_real_hr) desc



