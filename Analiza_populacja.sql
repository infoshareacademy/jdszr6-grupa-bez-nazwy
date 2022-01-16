select * from county_facts

select * from county_facts_dictionary
where column_name = 'PST045214' or column_name = 'POP010210' or column_name = 'POP060210'


create temp table dane_populacja as 
select state,county,  party, candidate, votes, fraction_votes , 
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g³_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g³_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g³_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g³_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g³_stan_partia,
PST045214 as estymacyjna_pop_2014_hr, 
round(sum(PST045214) over (partition by state), 2) as estymacyjna_pop_2014_stan,
POP010210 as pop_2010_real_hr,
round(sum(POP010210) over (partition by state), 2) as pop_2010_real_stan,
POP060210 as zageszczenie_2010_hr,
round(avg(POP060210 ) over (partition by state), 2) as zageszczenie_2010_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips
order by PST045214 desc




/*Zestawienie sumaryczne - partia ze wzglêdu na wygrane stany*/

with est_2014 as 
(select distinct party, round(avg(estymacyjna_pop_2014_stan),  2) as œr_populac_est_2014, 
sum(estymacyjna_pop_2014_stan) as il_ludzi_est_2014,
count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, estymacyjna_pop_2014_stan
from
(select distinct state, party, prct_g³_stan_all,  estymacyjna_pop_2014_stan
from dane_populacja
)dem
group by party, state, estymacyjna_pop_2014_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
real_2010 as 
(select distinct party, round(avg(pop_2010_real_stan),  2) as œr_populac_2010_real, 
sum(pop_2010_real_stan) as il_ludzi_real_2010,
count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, pop_2010_real_stan
from
(select distinct state, party, prct_g³_stan_all,  pop_2010_real_stan
from dane_populacja
)dem
group by party, state, pop_2010_real_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
zageszczenie_2010 as 
(select distinct party, round(avg(zageszczenie_2010_stan),  2) as œr_zageszczenie_2010, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g³_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g³_stan_all) desc) as miejsce, zageszczenie_2010_stan
from
(select distinct state, party, prct_g³_stan_all,  zageszczenie_2010_stan
from dane_populacja
)dem
group by party, state, zageszczenie_2010_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party)
select est_2014.party, œr_populac_2010_real,il_ludzi_real_2010,œr_zageszczenie_2010,œr_populac_est_2014, il_ludzi_est_2014, est_2014.liczba_wygranych
from est_2014
join real_2010
on est_2014.party = real_2010.party
join zageszczenie_2010
on est_2014.party = zageszczenie_2010.party




 /*b) zale¿noœæ - g³ na partiê - (uœrednione wyniki ca³oœciowe)*/
 
select distinct party, sum(votes) over (partition by party) as liczba_g³_partiat, 
round(avg(pop_2010_real_hr) over (partition by party), 2) as œr_pop_rzeczywista,
round(avg(zageszczenie_2010_hr) over (partition by party), 2) as œr_zageszczenie_2010,
round(avg(estymacyjna_pop_2014_hr) over (partition by party), 2) as œr_pop_estymacyjna_2014
from dane_populacja
group by party, votes, pop_2010_real_hr, zageszczenie_2010_hr, estymacyjna_pop_2014_hr
order by sum(votes) over (partition by party) desc


-- analiza wzglêdem wygranych hrabstw --



-- analiza wzglêdem wygranych hrabstw --

/*b) wybór partii*/

with est_2014 as 
(select distinct party, round(avg(estymacyjna_pop_2014_hr),  2) as œr_populac_est_2014, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g³_hrabstwo_all) as prct_partia_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, estymacyjna_pop_2014_hr
from
(select distinct county, party, prct_g³_hrabstwo_all,  estymacyjna_pop_2014_hr
from dane_populacja
)dem
group by party, county, estymacyjna_pop_2014_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
real_2010 as 
(select distinct party, round(avg(pop_2010_real_hr),  2) as œr_populac_2010_real, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g³_hrabstwo_all) as prct_partia_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, pop_2010_real_hr
from
(select distinct county, party, prct_g³_hrabstwo_all,  pop_2010_real_hr
from dane_populacja
)dem
group by party, county, pop_2010_real_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party),
zageszczenie_2010 as 
(select distinct party, round(avg(zageszczenie_2010_hr),  2) as œr_zageszczenie_2010, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g³_hrabstwo_all) as prct_partia_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g³_hrabstwo_all) desc) as miejsce, zageszczenie_2010_hr
from
(select distinct county, party, prct_g³_hrabstwo_all,  zageszczenie_2010_hr
from dane_populacja
)dem
group by party, county, zageszczenie_2010_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra³a*/
group by party)
select est_2014.party, œr_populac_2010_real,œr_zageszczenie_2010, œr_populac_est_2014,  est_2014.liczba_wygranych
from est_2014
join real_2010
on est_2014.party = real_2010.party
join zageszczenie_2010
on est_2014.party = zageszczenie_2010.party





-- badanie korelacji pomiêdzy g³osami populacji, a parti¹

select party, 
corr(votes, pop_2010_real_hr) as korelacja_populacja_2010,
corr(votes, zageszczenie_2010_hr) as korelacja_zageszczenie_2010,
corr(votes, estymacyjna_pop_2014_hr) as korelacja_poulacja_estymacja_2014
from dane_populacja
group by party
order by corr(votes, pop_2010_real_hr) desc

-- badanie korelacji pomiêdzy g³osami danej grupy wiekowej, a parti¹  - podzia³ na stany
select party, state,
corr(votes, pop_2010_real_hr) as korelacja_populacja_2010,
corr(votes, zageszczenie_2010_hr) as korelacja_zageszczenie_2010,
corr(votes, estymacyjna_pop_2014_hr) as korelacja_poulacja_estymacja_2014
from dane_populacja
group by party, state
order by corr(votes, pop_2010_real_hr) desc


