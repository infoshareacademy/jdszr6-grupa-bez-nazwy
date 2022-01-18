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




/*Zestawienie sumaryczne - partia ze wzglêdu na wygrane stany*/

with liczba as
(select distinct party, round(sum(weterani_stan),  2) as liczba_weteranów, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, weterani_stan
from
(select distinct state, party, prct_g³_stan_all,  weterani_stan
from dane_weterani
)dem
group by party, state, weterani_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
ca³oœæ as 
(select sum(liczba_weteranów) as suma
from
liczba)
select party, round(liczba_weteranów*100/suma, 2) as prct_weteranów, liczba_wygranych
from liczba
cross join ca³oœæ

/*sprawdzanie zale¿noœci:*/
 


 /*b) zale¿noœæ - g³ na partiê - (uœrednione wyniki ca³oœciowe)*/
 

with liczba as
(select distinct party, sum(votes) over (partition by party) as liczba_g³_kandydat, 
round(sum(weterani_hr) over (partition by party, 2)) as liczba_weteranów
from dane_weterani
group by party, votes, weterani_hr
order by sum(votes) over (partition by party) desc),
ca³oœæ as 
(select sum(liczba_weteranów) as suma from
liczba)
select party, round(liczba_weteranów*100/suma, 2) as prct_weteranów
from liczba 
cross join ca³oœæ

-- analiza wzglêdem wygranych hrabstw --


/*b) wybór partii*/

with liczba as
(select distinct party, round(sum(weterani_hr),  2) as liczba_weteranów, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, weterani_hr
from
(select distinct county, party, prct_g³_hrabstwo_all,  weterani_hr
from dane_weterani
)dem
group by party, county, weterani_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
ca³oœæ as 
(select sum(liczba_weteranów) as suma
from
liczba)
select party, round(liczba_weteranów*100/suma, 2) as prct_weteranów, liczba_wygranych
from liczba
cross join ca³oœæ




-- badanie korelacji pomiêdzy g³osami weteranów, a parti¹

select party, 
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by party
order by corr(votes, weterani_hr) desc

-- badanie korelacji pomiêdzy g³osami weteranów - podzia³ na stany
select party, state,
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by party, state
order by corr(votes, weterani_hr) desc



