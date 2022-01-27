select * from county_facts

select * from county_facts_dictionary
where column_name  = 'VET605213'


create temp table dane_weterani as 
select state,county,  party, candidate, votes, fraction_votes ,
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g³_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g³_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g³_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g³_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g³_stan_partia,
VET605213 as weterani_hr,
round(sum(VET605213) over (partition by state), 2) as weterani_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips

/* sprawdzenie ile wyników bêdzie w danej grupie*/


select liczba_weteranów, count(*) from
(select distinct county, state,
case  
when weterani_hr < 1000 then '0 - 1 tyœ'
when weterani_hr < 2000 then '1 - 2 tyœ'
when weterani_hr < 3000 then '2 - 5 tyœ'
when weterani_hr < 5000 then '3 - 5 tyœ'
when weterani_hr < 10000 then '5 - 10 tyœ'
when weterani_hr < 20000 then '10 - 20 tyœ'
else 'powy¿ej 20 tyœ'
end as liczba_weteranów
from dane_weterani)x
group by liczba_weteranów

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_obliczenia_iv_weterani as
with rep as
(select distinct party, liczba_weteranów, sum(votes) over (partition by party, liczba_weteranów) as liczba_g³_republikanie,
sum (votes) over (partition by party) as suma_ca³kowita_partia_rep from
(select party, votes, 
case  
when weterani_hr < 1000 then '0 - 1 tyœ'
when weterani_hr < 2000 then '1 - 2 tyœ'
when weterani_hr < 3000 then '2 - 5 tyœ'
when weterani_hr < 5000 then '3 - 5 tyœ'
when weterani_hr < 10000 then '5 - 10 tyœ'
when weterani_hr < 20000 then '10 - 20 tyœ'
else 'powy¿ej 20 tyœ'
end as liczba_weteranów
from dane_weterani
group by party, votes, weterani_hr
order by liczba_weteranów)m
where party = 'Republican'),
dem as 
(select distinct party, liczba_weteranów, sum(votes) over (partition by party, liczba_weteranów ) as liczba_g³_demokraci,
sum (votes) over (partition by party) as suma_ca³kowita_partia_dem from
(select party, votes, 
case  
when weterani_hr < 1000 then '0 - 1 tyœ'
when weterani_hr < 2000 then '1 - 2 tyœ'
when weterani_hr < 3000 then '2 - 5 tyœ'
when weterani_hr < 5000 then '3 - 5 tyœ'
when weterani_hr < 10000 then '5 - 10 tyœ'
when weterani_hr < 20000 then '10 - 20 tyœ'
else 'powy¿ej 20 tyœ'
end as liczba_weteranów
from dane_weterani
group by party, votes, weterani_hr
order by liczba_weteranów)m
where party = 'Democrat')
select distinct  dem.liczba_weteranów, liczba_g³_republikanie, liczba_g³_demokraci, 
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as WOE,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as dr_dd,
(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) * ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as dr_dd_woe
from rep 
join dem 
on dem.liczba_weteranów= rep.liczba_weteranów


select *
from v_obliczenia_iv_weterani;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_obliczenia_iv_weterani /*œredni predyktor - 0.123*/


-- analiza w podziale na podgrupy -- dane do u¿ycia

/* wykaz hrabstw stosunek procentowy g³osów na dan¹ patiê (w podziale na grupy iloœciowe) - do pokazania na mapie*/

with stany as
(select county, state,party, liczba_weteranów from
(select  distinct county, state, party,
case  
when weterani_hr < 1000 then '0 - 1 tyœ'
when weterani_hr < 2000 then '1 - 2 tyœ'
when weterani_hr < 3000 then '2 - 5 tyœ'
when weterani_hr < 5000 then '3 - 5 tyœ'
when weterani_hr < 10000 then '5 - 10 tyœ'
when weterani_hr < 20000 then '10 - 20 tyœ'
else 'powy¿ej 20 tyœ'
end as liczba_weteranów
from dane_weterani)x) 
select county, state, party, stany.liczba_weteranów,
liczba_g³_republikanie, liczba_g³_demokraci
from stany
join v_obliczenia_iv_weterani viw
on stany.liczba_weteranów = viw.liczba_weteranów
order by stany.liczba_weteranów




/*Zestawienie sumaryczne - partia ze wzglêdu na wygrane stany*/


select distinct party, round(avg(weterani_stan),  2) as œr_liczba_weteranów_na_stan, 
sum(weterani_stan) as liczba_wszystkich_weteranów_w_stanie,
count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, weterani_stan
from
(select distinct state, party, prct_g³_stan_all,  weterani_stan
from dane_weterani dw 
)dem
group by party, state, weterani_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party




 /*b) zale¿noœæ - g³ na partiê - (uœrednione wyniki ca³oœciowe) - statystyka nic nie znacz¹ca*//
 
select distinct party, sum(votes) over (partition by party) as liczba_g³_partia, 
round(avg(weterani_hr) over (partition by party), 2) as œr_liczba_weteranów
from dane_weterani
group by party, votes, weterani_hr
order by sum(votes) over (partition by party) desc



/*b) wybór partii, wygrane hrabstwa*/


select party, round(avg(weterani_hr),  2) as œrednia_liczba_weteranów, count (*) as liczba_wygranych from
(select state, county,liczba_g³osów_partia, party, weterani_hr,
dense_rank () over (partition by county, state order by liczba_g³osów_partia desc) as ranking from
(select distinct state, county, party, 
sum(votes) as liczba_g³osów_partia, 
weterani_hr
from dane_weterani 
group by party, county, weterani_hr, state
order by county)rkg)naj
where ranking = 1
group by  party



-- badanie korelacji pomiêdzy g³osami weteranów, a parti¹

select party, 
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by party
order by corr(votes, weterani_hr) desc


-- badanie korelacji pomiêdzy g³osami weteranów, a parti¹ - przeliczenie na stany

select party, state,
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by party, state
order by corr(votes, weterani_hr) desc


--- dodatkowo ---

--WOE i IV dla populacji w 2010 roku -- w pzeliczeniu na stany

/* sprawdzenie ile wyników bêdzie w danej grupie*/

select weterani_stan
from dane_weterani dw 
order by weterani_stan asc

select liczba_weteranów_stan, count(*) from
(select distinct state,
case  
when weterani_stan < 500000 then '0 - 0,5 mln'
when weterani_stan < 1500000 then '0,5 - 1,5 mln'
when weterani_stan < 2000000 then '1,5 - 2 mln'
when weterani_stan < 3000000 then '2 - 3 mln'
when weterani_stan < 5000000 then '3 - 5 mln'
when weterani_stan < 7000000 then '5 - 7 mln'
else 'powy¿ej 7 mln'
end as liczba_weteranów_stan
from dane_weterani)x
group by liczba_weteranów_stan

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_obliczenia_iv_weterani_stan as
with rep as
(select distinct party, liczba_weteranów_stan, sum(votes) over (partition by party, liczba_weteranów_stan) as liczba_g³_republikanie,
sum (votes) over (partition by party) as suma_ca³kowita_partia_rep from
(select party, votes, 
case  
when weterani_stan < 500000 then '0 - 0,5 mln'
when weterani_stan < 1500000 then '0,5 - 1,5 mln'
when weterani_stan < 2000000 then '1,5 - 2 mln'
when weterani_stan < 3000000 then '2 - 3 mln'
when weterani_stan < 5000000 then '3 - 5 mln'
when weterani_stan < 7000000 then '5 - 7 mln'
else 'powy¿ej 7 mln'
end as liczba_weteranów_stan
from dane_weterani
group by party, votes, weterani_stan
order by liczba_weteranów_stan)m
where party = 'Republican'),
dem as 
(select distinct party, liczba_weteranów_stan, sum(votes) over (partition by party, liczba_weteranów_stan ) as liczba_g³_demokraci,
sum (votes) over (partition by party) as suma_ca³kowita_partia_dem from
(select party, votes, 
case  
when weterani_stan < 500000 then '0 - 0,5 mln'
when weterani_stan < 1500000 then '0,5 - 1,5 mln'
when weterani_stan < 2000000 then '1,5 - 2 mln'
when weterani_stan < 3000000 then '2 - 3 mln'
when weterani_stan < 5000000 then '3 - 5 mln'
when weterani_stan < 7000000 then '5 - 7 mln'
else 'powy¿ej 7 mln'
end as liczba_weteranów_stan
from dane_weterani
group by party, votes, weterani_stan
order by liczba_weteranów_stan)m
where party = 'Democrat')
select distinct  dem.liczba_weteranów_stan, liczba_g³_republikanie, liczba_g³_demokraci, 
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as WOE,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as dr_dd,
(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) * ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as dr_dd_woe
from rep 
join dem 
on dem.liczba_weteranów_stan= rep.liczba_weteranów_stan

select *
from v_obliczenia_iv_weterani_stan;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_obliczenia_iv_weterani_stan /*s³aby predyktor - 0.020* = brak dalszej analizy*/


-- hrabstwa vs weterani - g³osy --

select state, county, party, weterani_hr, 
sum(votes) as liczba_glosow
from dane_weterani dw
where party = 'Republican'
group by state, county, party, weterani_hr

select state, county, party, weterani_hr,
sum(votes) as liczba_glosow
from dane_weterani dw
where party = 'Democrat'
group by state, county, party, weterani_hr

