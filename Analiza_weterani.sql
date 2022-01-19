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


select czas_dojazdu, count(*) from
(select party, votes, county,
case  
when weterani_hr < 1000 then '0 - 1 tyœ'
when weterani_hr < 2000 then '1 - 2 tyœ'
when weterani_hr < 3000 then '2 - 5 tyœ'
when weterani_hr < 5000 then '3 - 5 tyœ'
when weterani_hr < 10000 then '5 - 10 tyœ'
when weterani_hr < 20000 then '10 - 20 tyœ'
else 'powy¿ej 20 tyœ'
end as czas_liczba_weteranów
from dane_weterani)x
group by czas_dojazdu

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
from v_obliczenia_iv_weterani /*œredni predyktor - 0.122*/


-- analiza w podziale na podgrupy -- dane do u¿ycia

/* wykaz hrabstw stosunek procentowy g³osów na dan¹ patiê (w podziale na grupy iloœciowe) - do pokazania na mapie*/

with stany as
(select county, state, liczba_weteranów from
(select  distinct county, state, 
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
select county, state, stany.liczba_weteranów,
round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2) as prct_g³osów_republikanie,
100 - round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2) as prct_g³osów_demokraci,
case when round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2) > 100 - round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2)
then 'Republikanie'
when round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2) < 100 - round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2)
then 'Demokraci'
end as winner
from stany
join v_obliczenia_iv_weterani viw
on stany.liczba_weteranów = viw.liczba_weteranów
order by stany.liczba_weteranów





/* wykaz hrabstw stosunek procentowy g³osów na dan¹ patiê (w podziale na grupy iloœciowe)*/

with stany as
(select county, state, zagêszczenie_hrabstwa from
(select  distinct county, state, 
case when zageszczenie_2010_hr < 50 then '0 - 50'
when zageszczenie_2010_hr < 100 then '50 - 100'
when zageszczenie_2010_hr < 200 then '100 - 200'
when zageszczenie_2010_hr < 500 then '200 - 500'
when zageszczenie_2010_hr< 1000 then '500 - 1000'
else '1000 +'
end as zagêszczenie_hrabstwa
from dane_populacja)x) 
select county, state, stany.zagêszczenie_hrabstwa,
round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2) as prct_g³osów_republikanie,
100 - round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2) as prct_g³osów_demokraci,
case when round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2) > 100 - round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2)
then 'Republikanie'
when round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2) < 100 - round(liczba_g³_republikanie * 100 / (liczba_g³_republikanie + liczba_g³_demokraci), 2)
then 'Demokraci'
end as winner
from stany
join v_iv_zageszczenie vig
on stany.zagêszczenie_hrabstwa = vig.zagêszczenie_hrabstwa



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



