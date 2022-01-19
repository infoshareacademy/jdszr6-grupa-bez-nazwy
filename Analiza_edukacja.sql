select * from county_facts

select * from county_facts_dictionary
where column_name  like 'EDU%'

/* tworzenie tabeli pomocniczej zawieraj¹cej wszystkie dane potrzebne do analizy*/
create table dane_edukacj as 
select state,county,  party, candidate, votes, fraction_votes ,
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g³_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g³_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g³_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g³_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g³_stan_partia,
EDU635213 as wykszta³cenie_min_œrednie_hr,
round(avg(EDU635213) over (partition by state), 2) as osoby_wykszta³cenie_œrednie_stan,
EDU685213 as wykszta³cenie_min_wy¿sze_hr, 
round(avg(EDU685213) over (partition by state), 2) as osoby_wykszta³cenie_wy¿sze_stan,
100 - EDU635213 as brak_wykszta³cenia_hr,
round(avg(100 - EDU635213) over (partition by state), 2) as osoby_bez_wykszta³cenia_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips


--WOE i IV dla edukacji - wykszta³cenie œrednie --

/* sprawdzenie ile wyników bêdzie w danej grupie*/


select procent_wykszta³cenie_œrednie,  count(*) from /*OK*/
(select distinct county, state,
case when wykszta³cenie_min_œrednie_hr < 75 then '0 - 75 %'
when wykszta³cenie_min_œrednie_hr < 80 then '75 - 80 %'
when wykszta³cenie_min_œrednie_hr < 85 then '80 - 85 %'
when wykszta³cenie_min_œrednie_hr < 90 then '85 - 90 %'
else 'powy¿ej 90%'
end as procent_wykszta³cenie_œrednie
from dane_edukacj)x
group by procent_wykszta³cenie_œrednie

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_wyk_œrednie as
with rep as
(select distinct party, procent_wykszta³cenie_œrednie, sum(votes) over (partition by party, procent_wykszta³cenie_œrednie) as liczba_g³_republikanie,
sum (votes) over (partition by party) as suma_ca³kowita_partia_rep from
(select party, votes, 
case when wykszta³cenie_min_œrednie_hr < 75 then '0 - 75 %'
when wykszta³cenie_min_œrednie_hr < 80 then '75 - 80 %'
when wykszta³cenie_min_œrednie_hr < 85 then '80 - 85 %'
when wykszta³cenie_min_œrednie_hr < 90 then '85 - 90 %'
else 'powy¿ej 90%'
end as procent_wykszta³cenie_œrednie
from dane_edukacj
group by party, votes, wykszta³cenie_min_œrednie_hr
order by procent_wykszta³cenie_œrednie)m
where party = 'Republican'),
dem as
(select distinct party, procent_wykszta³cenie_œrednie, sum(votes) over (partition by party, procent_wykszta³cenie_œrednie) as liczba_g³_demokraci,
sum (votes) over (partition by party) as suma_ca³kowita_partia_dem from
(select party, votes, 
case when wykszta³cenie_min_œrednie_hr < 75 then '0 - 75 %'
when wykszta³cenie_min_œrednie_hr < 80 then '75 - 80 %'
when wykszta³cenie_min_œrednie_hr < 85 then '80 - 85 %'
when wykszta³cenie_min_œrednie_hr < 90 then '85 - 90 %'
else 'powy¿ej 90%'
end as procent_wykszta³cenie_œrednie
from dane_edukacj
group by party, votes, wykszta³cenie_min_œrednie_hr
order by procent_wykszta³cenie_œrednie)m
where party = 'Democrat')
select rep.procent_wykszta³cenie_œrednie, liczba_g³_republikanie, liczba_g³_demokraci,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as WOE,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as dr_dd,
(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) * ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.procent_wykszta³cenie_œrednie = dem.procent_wykszta³cenie_œrednie


select *
from v_iv_wyk_œrednie ;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_wyk_œrednie /*nieu¿yteczny predyktor - 0.015*/



--WOE i IV dla edukacji - wykszta³cenie wy¿sze --

/* sprawdzenie ile wyników bêdzie w danej grupie*/


select procent_wykszta³cenie_wy¿sze,  count(*) from /*OK*/
(select distinct county, state,
case when wykszta³cenie_min_wy¿sze_hr < 10 then '0 - 10 %'
when wykszta³cenie_min_wy¿sze_hr < 15 then '10 - 15 %'
when wykszta³cenie_min_wy¿sze_hr < 20 then '15 - 20 %'
when wykszta³cenie_min_wy¿sze_hr < 25 then '20 - 25 %'
when wykszta³cenie_min_wy¿sze_hr  < 30 then '25 - 30 %'
when wykszta³cenie_min_wy¿sze_hr  < 35 then '30 - 35 %'
else 'powy¿ej 35%'
end as procent_wykszta³cenie_wy¿sze
from dane_edukacj)x
group by procent_wykszta³cenie_wy¿sze

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_wyk_wyzsze as
with rep as
(select distinct party, procent_wykszta³cenie_wy¿sze, sum(votes) over (partition by party, procent_wykszta³cenie_wy¿sze) as liczba_g³_republikanie,
sum (votes) over (partition by party) as suma_ca³kowita_partia_rep from
(select party, votes, 
case when wykszta³cenie_min_wy¿sze_hr < 10 then '0 - 10 %'
when wykszta³cenie_min_wy¿sze_hr < 15 then '10 - 15 %'
when wykszta³cenie_min_wy¿sze_hr < 20 then '15 - 20 %'
when wykszta³cenie_min_wy¿sze_hr < 25 then '20 - 25 %'
when wykszta³cenie_min_wy¿sze_hr  < 30 then '25 - 30 %'
when wykszta³cenie_min_wy¿sze_hr  < 35 then '30 - 35 %'
else 'powy¿ej 35%'
end as procent_wykszta³cenie_wy¿sze
from dane_edukacj
group by party, votes, wykszta³cenie_min_wy¿sze_hr
order by procent_wykszta³cenie_wy¿sze)m
where party = 'Republican'),
dem as
(select distinct party, procent_wykszta³cenie_wy¿sze, sum(votes) over (partition by party, procent_wykszta³cenie_wy¿sze) as liczba_g³_demokraci,
sum (votes) over (partition by party) as suma_ca³kowita_partia_dem from
(select party, votes, 
case when wykszta³cenie_min_wy¿sze_hr < 10 then '0 - 10 %'
when wykszta³cenie_min_wy¿sze_hr < 15 then '10 - 15 %'
when wykszta³cenie_min_wy¿sze_hr < 20 then '15 - 20 %'
when wykszta³cenie_min_wy¿sze_hr < 25 then '20 - 25 %'
when wykszta³cenie_min_wy¿sze_hr  < 30 then '25 - 30 %'
when wykszta³cenie_min_wy¿sze_hr  < 35 then '30 - 35 %'
else 'powy¿ej 35%'
end as procent_wykszta³cenie_wy¿sze
from dane_edukacj
group by party, votes, wykszta³cenie_min_wy¿sze_hr
order by procent_wykszta³cenie_wy¿sze)m
where party = 'Democrat')
select rep.procent_wykszta³cenie_wy¿sze, liczba_g³_republikanie, liczba_g³_demokraci,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as WOE,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as dr_dd,
(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) * ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.procent_wykszta³cenie_wy¿sze = dem.procent_wykszta³cenie_wy¿sze


select *
from v_iv_wyk_wyzsze ;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_wyk_wyzsze /*s³aby predyktor - 0.083*/


--WOE i IV dla edukacji - brak wykszta³cenia --

/* sprawdzenie ile wyników bêdzie w danej grupie*/



select procent_brak_wykszta³cenia,  count(*) from /*OK*/
(select distinct county, state,
case when brak_wykszta³cenia_hr < 10 then '0 - 10 %'
when brak_wykszta³cenia_hr < 15 then '10 - 15 %'
when brak_wykszta³cenia_hr < 20 then '15 - 20 %'
when brak_wykszta³cenia_hr < 25 then '20 - 25 %'
else 'powy¿ej 25%'
end as procent_brak_wykszta³cenia
from dane_edukacj)x
group by procent_brak_wykszta³cenia

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_brak_wyk as
with rep as
(select distinct party, procent_brak_wykszta³cenia, sum(votes) over (partition by party, procent_brak_wykszta³cenia) as liczba_g³_republikanie,
sum (votes) over (partition by party) as suma_ca³kowita_partia_rep from
(select party, votes, 
case when brak_wykszta³cenia_hr < 10 then '0 - 10 %'
when brak_wykszta³cenia_hr < 15 then '10 - 15 %'
when brak_wykszta³cenia_hr < 20 then '15 - 20 %'
when brak_wykszta³cenia_hr < 25 then '20 - 25 %'
else 'powy¿ej 25%'
end as procent_brak_wykszta³cenia
from dane_edukacj
group by party, votes, brak_wykszta³cenia_hr
order by procent_brak_wykszta³cenia)m
where party = 'Republican'),
dem as
(select distinct party, procent_brak_wykszta³cenia, sum(votes) over (partition by party, procent_brak_wykszta³cenia) as liczba_g³_demokraci,
sum (votes) over (partition by party) as suma_ca³kowita_partia_dem from
(select party, votes, 
case when brak_wykszta³cenia_hr < 10 then '0 - 10 %'
when brak_wykszta³cenia_hr < 15 then '10 - 15 %'
when brak_wykszta³cenia_hr < 20 then '15 - 20 %'
when brak_wykszta³cenia_hr < 25 then '20 - 25 %'
else 'powy¿ej 25%'
end as procent_brak_wykszta³cenia
from dane_edukacj
group by party, votes, brak_wykszta³cenia_hr
order by procent_brak_wykszta³cenia)m
where party = 'Democrat')
select rep.procent_brak_wykszta³cenia, liczba_g³_republikanie, liczba_g³_demokraci,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as WOE,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as dr_dd,
(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) * ln(round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.procent_brak_wykszta³cenia = dem.procent_brak_wykszta³cenia


select *
from v_iv_brak_wyk ;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_brak_wyk /*nieu¿yteczny predyktor - 0.014*/

