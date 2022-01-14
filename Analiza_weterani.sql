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
round(avg(VET605213) over (partition by state), 2) as weterani_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips


/*Zestawienie sumaryczne - kandydat ze wzglêdu na wygrane stany*/

with liczba as
(select distinct candidate, round(avg(weterani_stan),  2) as liczba_weteranów, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g³_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, weterani_stan
from
(select distinct state, candidate, prct_g³_stan_all,  weterani_stan
from dane_weterani
)dem
group by candidate, state, weterani_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by candidate),
ca³oœæ as 
(select sum(liczba_weteranów) as suma
from
liczba)
select candidate, round(liczba_weteranów*100/suma, 2) as prct_weteranów, liczba_wygranych
from liczba
cross join ca³oœæ

/*Zestawienie sumaryczne - partia ze wzglêdu na wygrane stany*/

with liczba as
(select distinct party, round(avg(weterani_stan),  2) as liczba_weteranów, count(*) as liczba_wygranych
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

/*sprawdzanie zale¿noœci:
 a) zale¿noœæ - g³ na kandydata - (uœrednione wyniki ca³oœciowe)*/
 
with liczba as
(select distinct candidate, sum(votes) over (partition by candidate) as liczba_g³_kandydat, 
round(avg(weterani_hr) over (partition by candidate), 2) as œr_liczba_weteranów
from dane_weterani
group by candidate, votes, weterani_hr
order by sum(votes) over (partition by candidate) desc),
ca³oœæ as 
(select sum(œr_liczba_weteranów) as suma from
liczba)
select candidate, round(œr_liczba_weteranów*100/suma, 2) as prct_weteranów
from liczba 
cross join ca³oœæ


 /*b) zale¿noœæ - g³ na partiê - (uœrednione wyniki ca³oœciowe)*/
 

with liczba as
(select distinct party, sum(votes) over (partition by party) as liczba_g³_kandydat, 
round(avg(weterani_hr) over (partition by party, 2)) as œr_liczba_weteranów
from dane_weterani
group by party, votes, weterani_hr
order by sum(votes) over (partition by party) desc),
ca³oœæ as 
(select sum(œr_liczba_weteranów) as suma from
liczba)
select party, round(œr_liczba_weteranów*100/suma, 2) as prct_weteranów
from liczba 
cross join ca³oœæ

-- analiza wzglêdem wygranych hrabstw --

/*a) wybór kandydata*/

with liczba as
(select distinct candidate, round(avg(weterani_hr),  2) as liczba_weteranów, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, weterani_hr
from
(select distinct county, candidate, prct_g³_hrabstwo_all,  weterani_hr
from dane_weterani
)dem
group by candidate, county, weterani_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by candidate),
ca³oœæ as 
(select sum(liczba_weteranów) as suma
from
liczba)
select candidate, round(liczba_weteranów*100/suma, 2) as prct_weteranów, liczba_wygranych
from liczba
cross join ca³oœæ

/*b) wybór partii*/

with liczba as
(select distinct party, round(avg(weterani_hr),  2) as liczba_weteranów, count(*) as liczba_wygranych
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

-- badanie korelacji pomiêdzy g³osami weteranów, a kandydatem 

select candidate, 
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by candidate
order by corr(votes, weterani_hr) desc

-- badanie korelacji pomiêdzy g³osami weteranów a kandydatem  - podzia³ na stany
select candidate, state,
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by candidate, state
order by corr(votes, weterani_hr) desc


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



