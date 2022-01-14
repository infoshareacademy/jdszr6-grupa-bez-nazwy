select * from county_facts

select * from county_facts_dictionary
where column_name  like 'SEX%'


/* tworzenie tabeli pomocniczej zawieraj¹cej wszystkie dane potrzebne do analizy*/
create temp table dane_p³eæ as 
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


/*Zestawienie sumaryczne - kandydat ze wzglêdu na wygrane stany*/

with kobiety as 
(select distinct candidate, round(avg(kobiety_stan),  2) as prct_kobiety, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g³_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, kobiety_stan
from
(select distinct state, candidate, prct_g³_stan_all,  kobiety_stan
from dane_p³eæ
)dem
group by candidate, state, kobiety_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by candidate),
mê¿czyŸni as 
(select distinct candidate, round(avg(mê¿czyŸni_stan),  2) as prct_mê¿czyŸni, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g³_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, mê¿czyŸni_stan
from
(select distinct state, candidate, prct_g³_stan_all,  mê¿czyŸni_stan
from dane_p³eæ
)dem
group by candidate, state, mê¿czyŸni_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by candidate)
select kobiety.candidate, prct_kobiety, prct_mê¿czyŸni, kobiety.liczba_wygranych
from kobiety
join mê¿czyŸni
on kobiety.candidate = mê¿czyŸni.candidate


/*Zestawienie sumaryczne - partia ze wzglêdu na wygrane stany*/

with kobiety as 
(select distinct party, round(avg(kobiety_stan),  2) as prct_kobiety, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, kobiety_stan
from
(select distinct state, party, prct_g³_stan_all,  kobiety_stan
from dane_p³eæ
)dem
group by party, state, kobiety_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
mê¿czyŸni as 
(select distinct party, round(avg(mê¿czyŸni_stan),  2) as prct_mê¿czyŸni, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, mê¿czyŸni_stan
from
(select distinct state, party, prct_g³_stan_all,  mê¿czyŸni_stan
from dane_p³eæ
)dem
group by party, state, mê¿czyŸni_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party)
select kobiety.party, prct_kobiety, prct_mê¿czyŸni, kobiety.liczba_wygranych
from kobiety
join mê¿czyŸni
on kobiety.party = mê¿czyŸni.party


/*sprawdzanie zale¿noœci:
 a) zale¿noœæ - g³ na kandydata - (uœrednione wyniki ca³oœciowe)*/
 
select distinct candidate, sum(votes) over (partition by candidate) as liczba_g³_kandydat, 
round(avg(kobiety_hr) over (partition by candidate), 2) as œr_prct_kobiety,
round(avg(mê¿czyŸni_hr) over (partition by candidate), 2) as œr_mê¿czyŸni
from dane_p³eæ
group by candidate, votes, kobiety_hr, mê¿czyŸni_hr
order by sum(votes) over (partition by candidate) desc


 /*b) zale¿noœæ - g³ na partiê - (uœrednione wyniki ca³oœciowe)*/
 
select distinct party, sum(votes) over (partition by party) as liczba_g³_kandydat, 
round(avg(kobiety_hr) over (partition by party), 2) as œr_prct_kobiety,
round(avg(mê¿czyŸni_hr) over (partition by party), 2) as œr_mê¿czyŸni
from dane_p³eæ
group by party, votes, kobiety_hr, mê¿czyŸni_hr
order by sum(votes) over (partition by party) desc

/* Zestawienie ze wzglêdu na wygrane w hrabstwach */

/*a) wybór kandydata */

with kobiety as 
(select distinct candidate, round(avg(kobiety_hr),  2) as prct_kobiety, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, kobiety_hr
from
(select distinct county, candidate, prct_g³_hrabstwo_all,  kobiety_hr
from dane_p³eæ
)dem
group by candidate, county, kobiety_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by candidate),
mê¿czyŸni as 
(select distinct candidate, round(avg(mê¿czyŸni_hr),  2) as prct_mê¿czyŸni, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, mê¿czyŸni_hr
from
(select distinct county, candidate, prct_g³_hrabstwo_all,  mê¿czyŸni_hr
from dane_p³eæ
)dem
group by candidate, county, mê¿czyŸni_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by candidate)
select kobiety.candidate, prct_kobiety, prct_mê¿czyŸni, kobiety.liczba_wygranych
from kobiety
join mê¿czyŸni
on kobiety.candidate = mê¿czyŸni.candidate

/*b) wybór partii */

with kobiety as 
(select distinct party, round(avg(kobiety_hr),  2) as prct_kobiety, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, kobiety_hr
from
(select distinct county, party, prct_g³_hrabstwo_all,  kobiety_hr
from dane_p³eæ
)dem
group by party, county, kobiety_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
mê¿czyŸni as 
(select distinct party, round(avg(mê¿czyŸni_hr),  2) as prct_mê¿czyŸni, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, mê¿czyŸni_hr
from
(select distinct county, party, prct_g³_hrabstwo_all,  mê¿czyŸni_hr
from dane_p³eæ
)dem
group by party, county, mê¿czyŸni_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party)
select kobiety.party, prct_kobiety, prct_mê¿czyŸni, kobiety.liczba_wygranych
from kobiety
join mê¿czyŸni
on kobiety.party = mê¿czyŸni.party

-- badanie korelacji pomiêdzy g³osami danej p³ci, a kandydatem 

select candidate, 
corr(votes, kobiety_hr) as korelacja_g³osy_kobiet,
corr(votes, mê¿czyŸni_hr) as korelacja_g³osy_mê¿czyzn
from dane_p³eæ
group by candidate
order by corr(votes, kobiety_hr) desc

-- badanie korelacji pomiêdzy g³osami danej p³ci, a kandydatem  - podzia³ na stany
select candidate, state,
corr(votes, kobiety_hr) as korelacja_g³osy_kobiet,
corr(votes, mê¿czyŸni_hr) as korelacja_g³osy_mê¿czyzn
from dane_p³eæ
group by candidate, state
order by corr(votes, kobiety_hr) desc



-- badanie korelacji pomiêdzy g³osami danej p³ci, a parti¹

select party, 
corr(votes, kobiety_hr) as korelacja_g³_kobiet,
corr(votes, mê¿czyŸni_hr) as korelacja_g³_mê¿czyzn
from dane_p³eæ
group by party
order by corr(votes, kobiety_hr) desc

-- badanie korelacji pomiêdzy g³osami danej p³ci, a parti¹  - podzia³ na stany
select party, state,
corr(votes, kobiety_hr) as korelacja_g³_kobiet,
corr(votes, mê¿czyŸni_hr) as korelacja_g³_mê¿czyzn
from dane_p³eæ
group by party, state
order by corr(votes, kobiety_hr) desc

-- dodatkowe -- 
/* iloœæ hrabstw wygranych przez danego kandydata, gdzie g³osowali na niego w przewadze mê¿czyŸni */
select candidate,  count(candidate) as iloœæ_hrabstw_wygranych from
(select * , rank() over (partition by county order by fraction_votes desc) as ranking
from
(select *,
case when kobiety_hr > mê¿czyŸni_hr then 'wiêcej kobiet'
when kobiety_hr = mê¿czyŸni_hr then 'podzia³ p³ci'
else 'wiêcej mê¿czyzn'
end as p³eæ_dominuj¹ca
from dane_p³eæ)x 
where p³eæ_dominuj¹ca like '%mê¿%')p 
where ranking = 1
group by candidate

/* iloœæ hrabstw wygranych przez danego kandydata, gdzie g³osowali na niego w przewadze kobiety */
select candidate,  count(candidate) as iloœæ_hrabstw_wygranych from
(select * , rank() over (partition by county order by fraction_votes desc) as ranking
from
(select *,
case when kobiety_hr > mê¿czyŸni_hr then 'wiêcej kobiet'
when kobiety_hr = mê¿czyŸni_hr then 'podzia³ p³ci'
else 'wiêcej mê¿czyzn'
end as p³eæ_dominuj¹ca
from dane_p³eæ)x 
where p³eæ_dominuj¹ca like '%kob%')p 
where ranking = 1
group by candidate


