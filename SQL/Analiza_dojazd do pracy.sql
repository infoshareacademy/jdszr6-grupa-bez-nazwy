select * from county_facts

select * from county_facts_dictionary
where column_name  = 'LFE305213'


create temp table dane_dojazd as 
select state,county,  party, candidate, votes, fraction_votes ,
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g³_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g³_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g³_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g³_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g³_stan_partia,
LFE305213 as œredni_czas_dojazdu_min_praca_hr,
round(avg(LFE305213) over (partition by state), 2) as œredni_czas_dojazdu_min_praca_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips

--WOE i IV - czas dojazdu --

/* sprawdzenie ile wyników bêdzie w danej grupie*/



select czas_dojazdu, count(*) from /*do sprawdzenia*/
(select distinct county, state,
case  
when œredni_czas_dojazdu_min_praca_hr < 15 then '0 - 15 min'
when œredni_czas_dojazdu_min_praca_hr < 20 then '15 - 20 min'
when œredni_czas_dojazdu_min_praca_hr < 25 then '20 - 25 min'
else '25 + min'
end as czas_dojazdu
from dane_dojazd)x
group by czas_dojazdu

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_obliczenia_iv_dojazd as
with rep as
(select distinct party, czas_dojazdu, sum(votes) over (partition by party, czas_dojazdu) as liczba_g³_republikanie,
sum (votes) over (partition by party) as suma_ca³kowita_partia_rep from
(select party, votes, 
case
when œredni_czas_dojazdu_min_praca_hr < 15 then '0 - 15 min'
when œredni_czas_dojazdu_min_praca_hr < 20 then '15 - 20 min'
when œredni_czas_dojazdu_min_praca_hr < 25 then '20 - 25 min'
else '25 + min'
end as czas_dojazdu
from dane_dojazd
group by party, votes, œredni_czas_dojazdu_min_praca_hr
order by czas_dojazdu)m
where party = 'Republican'),
dem as 
(select distinct party, czas_dojazdu, sum(votes) over (partition by party, czas_dojazdu ) as liczba_g³_demokraci,
sum (votes) over (partition by party) as suma_ca³kowita_partia_dem from
(select party, votes, 
case
when œredni_czas_dojazdu_min_praca_hr < 15 then '0 - 15 min'
when œredni_czas_dojazdu_min_praca_hr < 20 then '15 - 20 min'
when œredni_czas_dojazdu_min_praca_hr < 25 then '20 - 25 min'
else '25 + min'
end as czas_dojazdu
from dane_dojazd
group by party, votes, œredni_czas_dojazdu_min_praca_hr
order by czas_dojazdu)m
where party = 'Democrat')
select distinct  dem.czas_dojazdu, liczba_g³_republikanie, liczba_g³_demokraci, 
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as WOE,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as dr_dd,
(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) * ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as dr_dd_woe
from rep 
join dem 
on dem.czas_dojazdu = rep.czas_dojazdu


select *
from v_obliczenia_iv_dojazd;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_obliczenia_iv_dojazd /*nieu¿yteczny predyktor - 0.02. Czas dojazdu do pracy nie ma wp³ywu na preferencje wyborców*/






