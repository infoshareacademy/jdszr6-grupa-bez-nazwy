select * from county_facts

select * from county_facts_dictionary
where column_name  like 'SEX%'


/* tworzenie tabeli pomocniczej zawieraj¹cej wszystkie dane potrzebne do analizy*/
create table dane_p³eæ as 
select state,county,  party, candidate, votes, round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g³_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g³_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g³_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g³_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g³_stan_partia,fraction_votes ,
SEX255214 as kobiety_hr,
round(avg(SEX255214)  over (partition by state), 2) as kobiety_stan,
100 - SEX255214 as mê¿czyŸni_hr,
round(avg(100 - SEX255214) over (partition by state), 2) as mê¿czyŸni_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips


--WOE i IV kobiety--

/* sprawdzenie ile wyników bêdzie w danej grupie*/


select procent_kobiet,  count(*) from /*OK*/
(select distinct county, state,
case when kobiety_hr < 48 then '0 - 48 %'
when kobiety_hr < 49 then '48 - 49 %'
when kobiety_hr < 50 then '49 - 50 %'
when kobiety_hr < 51 then '50 - 51 %'
when kobiety_hr < 52 then '51 - 52 %'
else 'powy¿ej 52%'
end as procent_kobiet
from dane_p³eæ)x
group by procent_kobiet

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_kobiety_ as
with rep as
(select distinct party, procent_kobiet, sum(votes) over (partition by party, procent_kobiet) as liczba_g³_republikanie,
sum (votes) over (partition by party) as suma_ca³kowita_partia_rep from
(select party, votes, 
case when kobiety_hr < 48 then '0 - 48 %'
when kobiety_hr < 49 then '48 - 49 %'
when kobiety_hr < 50 then '49 - 50 %'
when kobiety_hr < 51 then '50 - 51 %'
when kobiety_hr < 52 then '51 - 52 %'
else 'powy¿ej 52%'
end as procent_kobiet
from dane_p³eæ
group by party, votes, kobiety_hr
order by procent_kobiet)m
where party = 'Republican'),
dem as
(select distinct party, procent_kobiet, sum(votes) over (partition by party, procent_kobiet) as liczba_g³_demokraci,
sum (votes) over (partition by party) as suma_ca³kowita_partia_dem from
(select party, votes, 
case when kobiety_hr < 48 then '0 - 48 %'
when kobiety_hr < 49 then '48 - 49 %'
when kobiety_hr < 50 then '49 - 50 %'
when kobiety_hr < 51 then '50 - 51 %'
when kobiety_hr < 52 then '51 - 52 %'
else 'powy¿ej 52%'
end as procent_kobiet
from dane_p³eæ
group by party, votes, kobiety_hr
order by procent_kobiet)m
where party = 'Democrat')
select rep.procent_kobiet, liczba_g³_republikanie, liczba_g³_demokraci,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g³_demokraci/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_republikanie/suma_ca³kowita_partia_dem, 3)) as WOE,
round(liczba_g³_demokraci/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_republikanie/suma_ca³kowita_partia_dem, 3) as dd_dr,
(round(liczba_g³_demokraci/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_republikanie/suma_ca³kowita_partia_dem, 3)) * ln(round(liczba_g³_demokraci/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_republikanie/suma_ca³kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_kobiet = dem.procent_kobiet



select *
from v_iv_kobiety_;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_kobiety_ /*s³aby predyktor - 0.098*/


--WOE i IV mê¿czyŸni--

/* sprawdzenie ile wyników bêdzie w danej grupie*/


select procent_mê¿czyzn,  count(*) from /*OK*/
(select distinct county, state,
case when mê¿czyŸni_hr < 48 then '0 - 48 %'
when mê¿czyŸni_hr < 49 then '48 - 49 %'
when mê¿czyŸni_hr < 50 then '49 - 50 %'
when mê¿czyŸni_hr < 51 then '50 - 51 %'
when mê¿czyŸni_hr < 52 then '51 - 52 %'
else 'powy¿ej 52%'
end as procent_mê¿czyzn
from dane_p³eæ)x
group by procent_mê¿czyzn

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_mezczyzni_ as
with rep as
(select distinct party, procent_mê¿czyzn, sum(votes) over (partition by party, procent_mê¿czyzn) as liczba_g³_republikanie,
sum (votes) over (partition by party) as suma_ca³kowita_partia_rep from
(select party, votes, 
case when mê¿czyŸni_hr < 48 then '0 - 48 %'
when mê¿czyŸni_hr < 49 then '48 - 49 %'
when mê¿czyŸni_hr < 50 then '49 - 50 %'
when mê¿czyŸni_hr < 51 then '50 - 51 %'
when mê¿czyŸni_hr < 52 then '51 - 52 %'
else 'powy¿ej 52%'
end as procent_mê¿czyzn
from dane_p³eæ
group by party, votes, mê¿czyŸni_hr
order by procent_mê¿czyzn)m
where party = 'Republican'),
dem as
(select distinct party, procent_mê¿czyzn, sum(votes) over (partition by party, procent_mê¿czyzn) as liczba_g³_demokraci,
sum (votes) over (partition by party) as suma_ca³kowita_partia_dem from
(select party, votes, 
case when mê¿czyŸni_hr < 48 then '0 - 48 %'
when mê¿czyŸni_hr < 49 then '48 - 49 %'
when mê¿czyŸni_hr < 50 then '49 - 50 %'
when mê¿czyŸni_hr < 51 then '50 - 51 %'
when mê¿czyŸni_hr < 52 then '51 - 52 %'
else 'powy¿ej 52%'
end as procent_mê¿czyzn
from dane_p³eæ
group by party, votes, mê¿czyŸni_hr
order by procent_mê¿czyzn)m
where party = 'Democrat')
select rep.procent_mê¿czyzn, liczba_g³_republikanie, liczba_g³_demokraci,
round(liczba_g³_republikanie/suma_ca³kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g³_demokraci/suma_ca³kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g³_demokraci/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_republikanie/suma_ca³kowita_partia_dem, 3)) as WOE,
round(liczba_g³_demokraci/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_republikanie/suma_ca³kowita_partia_dem, 3) as dd_dr,
(round(liczba_g³_demokraci/suma_ca³kowita_partia_rep, 3) - round(liczba_g³_republikanie/suma_ca³kowita_partia_dem, 3)) * ln(round(liczba_g³_demokraci/suma_ca³kowita_partia_rep, 3)/round(liczba_g³_republikanie/suma_ca³kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_mê¿czyzn = dem.procent_mê¿czyzn



select *
from v_iv_mezczyzni_;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_mezczyzni_ /*s³aby predyktor (jako, ¿e wynik u biet jest porównywarny) - 0.100*/


/*zarówno wœród mê¿czyzn jak i kobiet wspó³cznik iV jest s³abym predyktorem - nie przeprowadzono dalszej analizy*/


