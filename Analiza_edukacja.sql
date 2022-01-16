select * from county_facts

select * from county_facts_dictionary
where column_name  like 'EDU%'

/* tworzenie tabeli pomocniczej zawieraj¹cej wszystkie dane potrzebne do analizy*/
create temp table dane_edukacj as 
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




/*Zestawienie sumaryczne - partia ze wzglêdu na wygrane stany*/

with œrednie as 
(select distinct party, round(avg(osoby_wykszta³cenie_œrednie_stan),  2) as prct_wykszta³cenie_œrednie, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, osoby_wykszta³cenie_œrednie_stan
from
(select distinct party, state, prct_g³_stan_all,  osoby_wykszta³cenie_œrednie_stan
from dane_edukacj
)dem
group by party, state, osoby_wykszta³cenie_œrednie_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
wy¿sze as 
(select distinct party, round(avg(osoby_wykszta³cenie_wy¿sze_stan), 2) as prct_wykszta³cenie_wy¿sze, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, osoby_wykszta³cenie_wy¿sze_stan
from
(select distinct state, party, prct_g³_stan_all,  osoby_wykszta³cenie_wy¿sze_stan
from dane_edukacj
)dem
group by party, state, osoby_wykszta³cenie_wy¿sze_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
bez_wykszta³cenia as 
( select distinct party, round(avg(osoby_bez_wykszta³cenia_stan), 2) as prct_bez_wykszta³cenia, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, osoby_bez_wykszta³cenia_stan
from
(select distinct state, party, prct_g³_stan_all,  osoby_bez_wykszta³cenia_stan
from dane_edukacj
)dem
group by party, state, osoby_bez_wykszta³cenia_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party)
select œrednie.party, prct_wykszta³cenie_œrednie, prct_wykszta³cenie_wy¿sze, prct_bez_wykszta³cenia,  œrednie.liczba_wygranych
from œrednie
join wy¿sze
on œrednie.party = wy¿sze.party
join bez_wykszta³cenia
on œrednie.party = bez_wykszta³cenia.party





 /*b) zale¿noœæ - g³ na partiê - (uœrednione wyniki ca³oœciowe)*/
 

select distinct party, sum(votes) over (partition by party) as liczba_g³_kandydat, 
round(avg(wykszta³cenie_min_œrednie_hr) over (partition by party), 2) as œr_prct_min_œrednie,
round(avg(wykszta³cenie_min_wy¿sze_hr) over (partition by party), 2) as œr_prct_min_wy¿sze,
round(avg(brak_wykszta³cenia_hr) over (partition by party), 2) as œr_prct_brak_wykszta³cenia
from dane_edukacj
group by party, votes, wykszta³cenie_min_œrednie_hr, wykszta³cenie_min_wy¿sze_hr, brak_wykszta³cenia_hr
order by sum(votes) over (partition by party) desc


-- analiza wzglêdem wygranych hrabstw --







---

/*b) wybór partii*/

with œrednie as 
(select distinct party, round(avg(wykszta³cenie_min_œrednie_hr),  2) as prct_wykszta³cenie_œrednie, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, wykszta³cenie_min_œrednie_hr
from
(select distinct county, party, prct_g³_hrabstwo_all,  wykszta³cenie_min_œrednie_hr
from dane_edukacj
)dem
group by party, county, wykszta³cenie_min_œrednie_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
wy¿sze as 
(select distinct party, round(avg(wykszta³cenie_min_wy¿sze_hr), 2) as prct_wykszta³cenie_wy¿sze, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, wykszta³cenie_min_wy¿sze_hr
from
(select distinct county, party, prct_g³_hrabstwo_all,  wykszta³cenie_min_wy¿sze_hr
from dane_edukacj
)dem
group by party, county, wykszta³cenie_min_wy¿sze_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
bez_wykszta³cenia as 
( select distinct party, round(avg(brak_wykszta³cenia_hr), 2) as prct_bez_wykszta³cenia, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g³_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, brak_wykszta³cenia_hr
from
(select distinct county, party, prct_g³_hrabstwo_all,  brak_wykszta³cenia_hr
from dane_edukacj
)dem
group by party, county, brak_wykszta³cenia_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party)
select œrednie.party, prct_wykszta³cenie_œrednie, prct_wykszta³cenie_wy¿sze, prct_bez_wykszta³cenia,  œrednie.liczba_wygranych
from œrednie
join wy¿sze
on œrednie.party = wy¿sze.party
join bez_wykszta³cenia
on œrednie.party = bez_wykszta³cenia.party




-- badanie korelacji pomiêdzy g³osami danej grupy wiekowej, a parti¹

select party, 
corr(votes, wykszta³cenie_min_œrednie_hr) as korelacja_œrednie,
corr(votes, wykszta³cenie_min_wy¿sze_hr) as korelacja_wy¿sze,
corr(votes, brak_wykszta³cenia_hr) as korelacja_brak_wykszta³cenia
from dane_edukacj
group by party

-- badanie korelacji pomiêdzy g³osami danej grupy wiekowej, a parti¹  - podzia³ na stany
select party, state,
corr(votes, wykszta³cenie_min_œrednie_hr) as korelacja_œrednie,
corr(votes, wykszta³cenie_min_wy¿sze_hr) as korelacja_wy¿sze,
corr(votes, brak_wykszta³cenia_hr) as korelacja_brak_wykszta³cenia
from dane_edukacj
group by party, state
order by corr(votes, wykszta³cenie_min_wy¿sze_hr) desc





