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

/*Zestawienie sumaryczne - kandydat ze wzglêdu na wygrane stany*/

select distinct candidate, round(avg(œredni_czas_dojazdu_min_praca_stan),  2) as czas_dojazdu_min, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g³_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, œredni_czas_dojazdu_min_praca_stan
from
(select distinct state, candidate, prct_g³_stan_all,  œredni_czas_dojazdu_min_praca_stan
from dane_dojazd
)dem
group by candidate, state, œredni_czas_dojazdu_min_praca_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by candidate

/*Zestawienie sumaryczne - partia ze wzglêdu na wygrane stany*/

select distinct party, round(avg(œredni_czas_dojazdu_min_praca_stan),  2) as czas_dojazdu_min, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, œredni_czas_dojazdu_min_praca_stan
from
(select distinct state, party, prct_g³_stan_all,  œredni_czas_dojazdu_min_praca_stan
from dane_dojazd
)dem
group by party, state, œredni_czas_dojazdu_min_praca_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party

/*sprawdzanie zale¿noœci:
 a) zale¿noœæ - g³ na kandydata - (uœrednione wyniki ca³oœciowe)*/
 
select distinct candidate, sum(votes) over (partition by candidate) as liczba_g³_kandydat, 
round(avg(œredni_czas_dojazdu_min_praca_hr) over (partition by candidate), 2) as œr_czas_dojazdu_min
from dane_dojazd
group by candidate, votes, œredni_czas_dojazdu_min_praca_hr
order by sum(votes) over (partition by candidate) desc


 /*b) zale¿noœæ - g³ na partiê - (uœrednione wyniki ca³oœciowe)*/
 

select distinct party, sum(votes) over (partition by party) as liczba_g³_kandydat, 
round(avg(œredni_czas_dojazdu_min_praca_hr) over (partition by party), 2) as œr_czas_dojazdu_min
from dane_dojazd
group by party, votes, œredni_czas_dojazdu_min_praca_hr
order by sum(votes) over (partition by party) desc

-- analiza wzglêdem wygranych hrabstw --

/*a) wybór kandydata*/

select distinct candidate, round(avg(œredni_czas_dojazdu_min_praca_hr),  2) as œr_czas_dojazdu_min, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, œredni_czas_dojazdu_min_praca_hr
from
(select distinct county, candidate, prct_g³_hrabstwo_all, œredni_czas_dojazdu_min_praca_hr
from dane_dojazd
)dem
group by candidate, county, œredni_czas_dojazdu_min_praca_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by candidate

/*b) wybór partii*/

select distinct party, round(avg(œredni_czas_dojazdu_min_praca_hr),  2) as œr_czas_dojazdu_min, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, œredni_czas_dojazdu_min_praca_hr
from
(select distinct county, party, prct_g³_hrabstwo_all, œredni_czas_dojazdu_min_praca_hr
from dane_dojazd
)dem
group by party, county, œredni_czas_dojazdu_min_praca_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party

-- badanie korelacji pomiêdzy dojazd do pracy, a kandydatem 

select candidate, 
corr(votes, œredni_czas_dojazdu_min_praca_hr) as korelacja_weterani
from dane_dojazd
group by candidate
order by corr(votes, œredni_czas_dojazdu_min_praca_hr) desc

-- badanie korelacji pomiêdzy g³osami dojazd do pracy  - podzia³ na stany
select candidate, state,
corr(votes, œredni_czas_dojazdu_min_praca_hr) as korelacja_weterani
from dane_dojazd
group by candidate, state
order by corr(votes, œredni_czas_dojazdu_min_praca_hr) desc


-- badanie korelacji pomiêdzy g³osami dojazd do pracy a parti¹

select party, 
corr(votes, œredni_czas_dojazdu_min_praca_hr) as korelacja_weterani
from dane_dojazd
group by party
order by corr(votes, œredni_czas_dojazdu_min_praca_hr) desc

-- badanie korelacji pomiêdzy g³osami dojazd do pracy - podzia³ na stany
select party, state,
corr(votes, œredni_czas_dojazdu_min_praca_hr) as korelacja_weterani
from dane_dojazd
group by party, state
order by corr(votes, œredni_czas_dojazdu_min_praca_hr) desc






