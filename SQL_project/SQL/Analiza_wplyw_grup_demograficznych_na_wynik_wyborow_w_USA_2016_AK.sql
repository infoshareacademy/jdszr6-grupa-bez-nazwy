/*General data*/


with dem as
	(select 
		sum(votes) as suma_g�_Demokraci, 
		party
	from primary_results_usa pru
	where party = 'Democrat'
	group by party),
rep as
	(select 
		sum(votes) as suma_g�_Republikan, 
		party
	from primary_results_usa pru
	where party = 'Republican'
	group by party),
suma as
	(select 
		sum(votes) as suma
	from primary_results_usa pru)
select 
round(suma_g�_Demokraci*100 / suma, 2) as prct_Demokraci,
round(suma_g�_Republikan*100 / suma, 2) as prct_Republikan
from rep
cross join suma
cross join dem



/*USA election 2016 primary results - analysis*/

/*1. Data anaylysis for veterans*/


select * from county_facts

select * from county_facts_dictionary
where column_name  = 'VET605213'


/* We create table, which includes data needed for veterans impact on United States Election in 2016*/
create table dane_weterani as 
select 
	state,county,  
	party, 
	candidate, 
	votes, 
	fraction_votes ,
	round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
	round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
	sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
	round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
	round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,
	VET605213 as weterani_hr,
	round(sum(VET605213) over (partition by state), 2) as weterani_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips


/* Start of anaylysis - analysis of no. of veterans per county. We check how many counties are assigned to each group */

select 
	liczba_weteran�w, 
	count(*) from
		(select distinct county, 
						state,
						case  
							when weterani_hr < 1000 then '0 - 1 ty�'
							when weterani_hr < 2000 then '1 - 2 ty�'
							when weterani_hr < 3000 then '2 - 5 ty�'
							when weterani_hr < 5000 then '3 - 5 ty�'
							when weterani_hr < 10000 then '5 - 10 ty�'
							when weterani_hr < 20000 then '10 - 20 ty�'
							else 'powy�ej 20 ty�'
						end as liczba_weteran�w
		from dane_weterani)x
	group by liczba_weteran�w


/* Next step - calcualtion of WOE and IV - checking real impact on election*/
	
create view v_obliczenia_iv_weterani_ as
	with rep as
		(select distinct party, 
						liczba_weteran�w, 
						sum(votes) over (partition by party, liczba_weteran�w) as liczba_g�_republikanie,
						sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
							(select party, 	
									votes, 
									case  
										when weterani_hr < 1000 then '0 - 1 ty�'
										when weterani_hr < 2000 then '1 - 2 ty�'
										when weterani_hr < 3000 then '2 - 5 ty�'
										when weterani_hr < 5000 then '3 - 5 ty�'
										when weterani_hr < 10000 then '5 - 10 ty�'
										when weterani_hr < 20000 then '10 - 20 ty�'
										else 'powy�ej 20 ty�'
									end as liczba_weteran�w
								from dane_weterani
								group by party, votes, weterani_hr
								order by liczba_weteran�w)m
								where party = 'Republican'),
	dem as 
		(select distinct party, 
						liczba_weteran�w, 
						sum(votes) over (partition by party, liczba_weteran�w ) as liczba_g�_demokraci,
						sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
							(select party, 
									votes, 
									case  
										when weterani_hr < 1000 then '0 - 1 ty�'
										when weterani_hr < 2000 then '1 - 2 ty�'
										when weterani_hr < 3000 then '2 - 5 ty�'
										when weterani_hr < 5000 then '3 - 5 ty�'
										when weterani_hr < 10000 then '5 - 10 ty�'
										when weterani_hr < 20000 then '10 - 20 ty�'
										else 'powy�ej 20 ty�'
									end as liczba_weteran�w
								from dane_weterani
								group by party, votes, weterani_hr
								order by liczba_weteran�w)m
								where party = 'Democrat')
select distinct  
	dem.liczba_weteran�w, 
	liczba_g�_republikanie, 
	liczba_g�_demokraci, 
	round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
	round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
	ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
	round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
	(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep 
join dem 
on dem.liczba_weteran�w= rep.liczba_weteran�w


/* Data saved as view. Then calcualtion of IV*/
select *
from v_obliczenia_iv_weterani_;
select sum(dd_dr_woe) as IV_weterani 
from v_obliczenia_iv_weterani_ /*predyktor - 0.179*/


/* Detailed analysis: */


/*list of counties in each group of veterns - usable to show on map*/

with stany as
	(select county, 
			state,party, 
			liczba_weteran�w from
				(select  distinct 
						county, 
						state, 
						party,
						case  
							when weterani_hr < 1000 then '0 - 1 ty�'
							when weterani_hr < 2000 then '1 - 2 ty�'
							when weterani_hr < 3000 then '2 - 5 ty�'
							when weterani_hr < 5000 then '3 - 5 ty�'
							when weterani_hr < 10000 then '5 - 10 ty�'
							when weterani_hr < 20000 then '10 - 20 ty�'
							else 'powy�ej 20 ty�'
						end as liczba_weteran�w
					from dane_weterani)x) 
select 
	county, 
	state, 
	party, 
	stany.liczba_weteran�w,
	liczba_g�_republikanie, 
	liczba_g�_demokraci
from stany
join v_obliczenia_iv_weterani viw
on stany.liczba_weteran�w = viw.liczba_weteran�w
order by stany.liczba_weteran�w


/* Average of no. of veterans per state. Calcuclation was done per states, where particulat party won*/

select distinct 
party, 
round(avg(weterani_stan),  2) as �r_liczba_weteran�w_na_stan, 
sum(weterani_stan) as liczba_wszystkich_weteran�w_w_stanie,
count(*) as liczba_wygranych
from  
	(select 
		party, 
		state, 
		sum(prct_g�_stan_all) as prct_partia_stan, 
		dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, weterani_stan
		from
			(select distinct 
				state, 
				party, 
				prct_g�_stan_all,  
				weterani_stan
			from dane_weterani dw )dem
	group by party, state, weterani_stan
	order by state) miejs
where miejsce = 1 /*filtering by won state*/
group by party




/* Average of no. of veterans per county. Calcuclation was done per counties, where particular party won*/

select 
party, 
round(avg(weterani_hr),  2) as �rednia_liczba_weteran�w, 
count (*) as liczba_wygranych 
from
	(select 
		state, 
		county,
		liczba_g�os�w_partia, 
		party, 
		weterani_hr,
		dense_rank () over (partition by county, state order by liczba_g�os�w_partia desc) as ranking 
			from
			(select distinct 
				state, 
				county, 
				party, 
				sum(votes) as liczba_g�os�w_partia, 
				weterani_hr
			from dane_weterani 
			group by party, county, weterani_hr, state
			order by county)rkg)naj
where ranking = 1
group by  party



/* correlation between all votes and party selection in veterans group*/

select 
	party, 
	corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by party



/* correlation between all votes in state and party selection in veterans group*/

select 
party, 
state, 
corr(suma_g�os�w_stan, weterani_hr) as korelacja_weterani 
from
	(select distinct 
		party, 
		sum(votes) over (partition by party, county) as suma_g�os�w_stan, 
		state, 
		county, 
		weterani_hr
	from dane_weterani dw 
	group by state, state, party, weterani_hr, votes, county)x
group by party,state





/* Checking the same relations grouped by states*/

/* Next step - calcualtion of WOE and IV - checking real impact on election*/

/* Start of anaylysis - analysis of no. of veterans per cstate. We check how many states are assigned to each group */


select 
liczba_weteran�w_stan, 
count(*) 
from
	(select distinct 
		state,
		case  
			when weterani_stan < 500000 then '0 - 0,5 mln'
			when weterani_stan < 1500000 then '0,5 - 1,5 mln'
			when weterani_stan < 2000000 then '1,5 - 2 mln'
			when weterani_stan < 3000000 then '2 - 3 mln'
			when weterani_stan < 5000000 then '3 - 5 mln'
			when weterani_stan < 7000000 then '5 - 7 mln'
			else 'powy�ej 7 mln'
		end as liczba_weteran�w_stan
	from dane_weterani)x
group by liczba_weteran�w_stan

/*WOE and IV:*/
create view v_obliczenia_iv_weterani_stan_ as
with rep as
	(select distinct 
		party, 
		liczba_weteran�w_stan, 
		sum(votes) over (partition by party, liczba_weteran�w_stan) as liczba_g�_republikanie,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
		from
			(select 
				party, 
				votes, 
				case  
					when weterani_stan < 500000 then '0 - 0,5 mln'
					when weterani_stan < 1500000 then '0,5 - 1,5 mln'
					when weterani_stan < 2000000 then '1,5 - 2 mln'
					when weterani_stan < 3000000 then '2 - 3 mln'
					when weterani_stan < 5000000 then '3 - 5 mln'
					when weterani_stan < 7000000 then '5 - 7 mln'
					else 'powy�ej 7 mln'
				end as liczba_weteran�w_stan
			from dane_weterani
			group by party, votes, weterani_stan
			order by liczba_weteran�w_stan)m
			where party = 'Republican'),
dem as 
	(select distinct 
		party, 
		liczba_weteran�w_stan, 
		sum(votes) over (partition by party, liczba_weteran�w_stan ) as liczba_g�_demokraci,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
		from
			(select 
			party, 
			votes, 
			case  
				when weterani_stan < 500000 then '0 - 0,5 mln'
				when weterani_stan < 1500000 then '0,5 - 1,5 mln'
				when weterani_stan < 2000000 then '1,5 - 2 mln'
				when weterani_stan < 3000000 then '2 - 3 mln'
				when weterani_stan < 5000000 then '3 - 5 mln'
				when weterani_stan < 7000000 then '5 - 7 mln'
				else 'powy�ej 7 mln'
			end as liczba_weteran�w_stan
			from dane_weterani
			group by party, votes, weterani_stan
			order by liczba_weteran�w_stan)m
		where party = 'Democrat')
select distinct  
dem.liczba_weteran�w_stan, 
liczba_g�_republikanie, 
liczba_g�_demokraci, 
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep 
join dem 
on dem.liczba_weteran�w_stan= rep.liczba_weteran�w_stan

/*Created view and IV calcyaltion on data*/
select *
from v_obliczenia_iv_weterani_stan_;
select sum(dd_dr_woe) as information_value 
from v_obliczenia_iv_weterani_stan_ /*predyktor - 0.063 - no detailed analysis*/


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*2. Data anaylysis for population and population per square mile*/


select * from county_facts

select * from county_facts_dictionary
where column_name = 'PST045214' or column_name = 'POP010210' or column_name = 'POP060210'



/* We create table, which includes data needed for population impact on United States Election in 2016*/

create table dane_populacja as 
select 
	state,
	county,  
	party, 
	candidate, 
	votes, 
	fraction_votes , 
	round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
	round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
	sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
	round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
	round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,
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



/* Start of anaylysis - analysis of population per county. We check how many counties are assigned to each group */

select 
wielko��_hrabstwa,  
count(*) 
from 
	(select distinct 
		county, 
		state,
		case 
			when pop_2010_real_hr < 10000 then '0 - 10 ty�'
			when pop_2010_real_hr < 30000 then '10 - 30 ty�'
			when pop_2010_real_hr < 50000 then '30 - 50 ty�'
			when pop_2010_real_hr < 100000 then '50 - 100 ty�'
			when pop_2010_real_hr < 300000 then '100 - 300 ty�'
			else 'powy�ej 300 ty�'
		end as wielko��_hrabstwa
		from dane_populacja)x
group by wielko��_hrabstwa

/* Next step - calcualtion of WOE and IV - checking real impact on election*/

create view v_iv_populacj_ as
	with rep as
		(select distinct 
			party, 
			wielko��_hrabstwa, 
			sum(votes) over (partition by party, wielko��_hrabstwa) as liczba_g�_republikanie,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
			from
				(select 
					party, 
					votes, 
					case
						when pop_2010_real_hr < 10000 then '0 - 10 ty�'
						when pop_2010_real_hr < 30000 then '10 - 30 ty�'
						when pop_2010_real_hr < 50000 then '30 - 50 ty�'
						when pop_2010_real_hr < 100000 then '50 - 100 ty�'
						when pop_2010_real_hr < 300000 then '100 - 300 ty�'
						else 'powy�ej 300 ty�'
					end as wielko��_hrabstwa
				from dane_populacja
				group by party, votes, pop_2010_real_hr
				order by wielko��_hrabstwa)m
			where party = 'Republican'),
dem as
	(select distinct 
		party, 
		wielko��_hrabstwa, 
		sum(votes) over (partition by party, wielko��_hrabstwa) as liczba_g�_demokraci,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
		from
			(select 
				party, 
				votes, 
				case 
					when pop_2010_real_hr < 10000 then '0 - 10 ty�'
					when pop_2010_real_hr < 30000 then '10 - 30 ty�'
					when pop_2010_real_hr < 50000 then '30 - 50 ty�'
					when pop_2010_real_hr < 100000 then '50 - 100 ty�'
					when pop_2010_real_hr < 300000 then '100 - 300 ty�'
					else 'powy�ej 300 ty�'
				end as wielko��_hrabstwa
				from dane_populacja
				group by party, votes, pop_2010_real_hr
				order by wielko��_hrabstwa)m
		where party = 'Democrat')
select 
rep.wielko��_hrabstwa, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.wielko��_hrabstwa = dem.wielko��_hrabstwa


/* Data saved as view. Then calcualtion of IV*/
select *
from v_iv_populacj_ 
order by wielko��_hrabstwa;
select sum(dd_dr_woe) as information_value 
from v_iv_populacj_ /* predyktor - 0.206*/



/* Detailed analysis: */

/*list of counties in each group of population - usable to show on map*/

with stany as
	(select 
		county, 
		state, 
		party, 
		wielko��_hrabstwa 
		from
			(select  distinct 
				county, 
				state, 
				party,
				case 
					when pop_2010_real_hr < 10000 then '0 - 10 ty�'
					when pop_2010_real_hr < 30000 then '10 - 30 ty�'
					when pop_2010_real_hr < 50000 then '30 - 50 ty�'
					when pop_2010_real_hr < 100000 then '50 - 100 ty�'
					when pop_2010_real_hr < 300000 then '100 - 300 ty�'
					else 'powy�ej 300 ty�'
				end as wielko��_hrabstwa
			from dane_populacja)x) 
select 
county, 
state, 
party, 
stany.wielko��_hrabstwa,
liczba_g�_republikanie, 
liczba_g�_demokraci
from stany
join v_iv_populacj vip
on stany.wielko��_hrabstwa = vip.wielko��_hrabstwa 



/* Next step - calcualtion of WOE and IV - checking real impact of population per mile ^2 on election*/

/* Start of anaylysis - analysis of population per mile ^2 per county. We check how many counties are assigned to each group */


select 
zag�szczenie_hrabstwa, 
count(*) 
from
	(select distinct 
	county, 
	state,
	case 
		when zageszczenie_2010_hr < 50 then '0 - 50'
		when zageszczenie_2010_hr < 100 then '50 - 100'
		when zageszczenie_2010_hr < 200 then '100 - 200'
		when zageszczenie_2010_hr < 500 then '200 - 500'
		when zageszczenie_2010_hr< 1000 then '500 - 1000'
		else '1000 +'
	end as zag�szczenie_hrabstwa
	from dane_populacja)x
group by zag�szczenie_hrabstwa


/*WOW and iV calcualtion*/
create view v_iv_zageszczenie_ as
with rep as
	(select distinct 
		party, 
		zag�szczenie_hrabstwa, 
		sum(votes) over (partition by party, zag�szczenie_hrabstwa) as liczba_g�_republikanie,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
		from
			(select 
				party, 
				votes, 
				case 
					when zageszczenie_2010_hr < 50 then '0 - 50'
					when zageszczenie_2010_hr < 100 then '50 - 100'
					when zageszczenie_2010_hr < 200 then '100 - 200'
					when zageszczenie_2010_hr < 500 then '200 - 500'
					when zageszczenie_2010_hr< 1000 then '500 - 1000'
					else '1000 +'
				end as zag�szczenie_hrabstwa
				from dane_populacja
				group by party, votes, zageszczenie_2010_hr
				order by zag�szczenie_hrabstwa)m
		where party = 'Republican'),
dem as
	(select distinct 
	party, 
	zag�szczenie_hrabstwa, 
	sum(votes) over (partition by party, zag�szczenie_hrabstwa) as liczba_g�_demokraci,
	sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
	from
		(select 
		party, 
		votes, 
		case 
			when zageszczenie_2010_hr < 50 then '0 - 50'
			when zageszczenie_2010_hr < 100 then '50 - 100'
			when zageszczenie_2010_hr < 200 then '100 - 200'
			when zageszczenie_2010_hr < 500 then '200 - 500'
			when zageszczenie_2010_hr< 1000 then '500 - 1000'
			else '1000 +'
		end as zag�szczenie_hrabstwa
		from dane_populacja
		group by party, votes, zageszczenie_2010_hr
		order by zag�szczenie_hrabstwa)m
	where party = 'Democrat')
select 
rep.zag�szczenie_hrabstwa, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.zag�szczenie_hrabstwa = dem.zag�szczenie_hrabstwa

/*Created view only to reduce code lines*/
select *
from v_iv_zageszczenie_
order by zag�szczenie_hrabstwa;
select sum(dd_dr_woe) as information_value 
from v_iv_zageszczenie_ /*predyktor - 0.246*/

/*list of counties in each group of population per square mile - usable to show on map*/

with stany as
	(select 
		county, 
		state, 
		party, 
		zag�szczenie_hrabstwa 
		from
			(select  distinct 
				county, 
				state, 
				party,
				case 
					when zageszczenie_2010_hr < 50 then '0 - 50'
					when zageszczenie_2010_hr < 100 then '50 - 100'
					when zageszczenie_2010_hr < 200 then '100 - 200'
					when zageszczenie_2010_hr < 500 then '200 - 500'
					when zageszczenie_2010_hr< 1000 then '500 - 1000'
					else '1000 +'
				end as zag�szczenie_hrabstwa
			from dane_populacja)x) 
select county, state, party, stany.zag�szczenie_hrabstwa, liczba_g�_republikanie, liczba_g�_demokraci
from stany
join v_iv_zageszczenie vig
on stany.zag�szczenie_hrabstwa = vig.zag�szczenie_hrabstwa 



/* Average of no. of population per state. Calcuclation was done per states, where particular party won*/


with real_2010 as 
	(select distinct 
		party, 
		round(avg(pop_2010_real_stan),  2) as �r_populac_2010_real, 
		sum(pop_2010_real_stan) as il_ludzi_real_2010,
		count(*) as liczba_wygranych
		from  
			(select party, 
			state, 
			sum(prct_g�_stan_all) as prct_partia_stan, 
			dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, 
			pop_2010_real_stan
			from
				(select distinct 
					state, 
					party, 
					prct_g�_stan_all,  
					pop_2010_real_stan
				from dane_populacja)dem
			group by party, state, pop_2010_real_stan
			order by state) miejs
		where miejsce = 1 
		group by party),
zageszczenie_2010 as 
	(select distinct 
		party, 
		round(avg(zageszczenie_2010_stan),  2) as �r_zageszczenie_2010, 
		count(*) as liczba_wygranych
		from  
			(select 
				party, 
				state, 
				sum(prct_g�_stan_all) as prct_partia_stan, 
				dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, 
				zageszczenie_2010_stan
				from
					(select distinct 
						state, 
						party, 
						prct_g�_stan_all,  
						zageszczenie_2010_stan
					from dane_populacja)dem
					group by party, state, zageszczenie_2010_stan
					order by state) miejs
				where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
				group by party)
select real_2010.party, �r_populac_2010_real,il_ludzi_real_2010,�r_zageszczenie_2010,  real_2010.liczba_wygranych
from real_2010
join zageszczenie_2010
on real_2010.party = zageszczenie_2010.party




 /* Average of no. of population per county. Calcuclation was done per counties, where particular party won*/
 
with wielkosc as
	(select 
		party, 
		round(avg(pop_2010_real_hr),  2) as �rednia_wielko��_populacji, 
		count (*) as liczba_wygranych 
		from
			(select 
			state, 
			county,
			liczba_g�os�w_partia, 
			party, 
			pop_2010_real_hr,
			dense_rank () over (partition by county, state order by liczba_g�os�w_partia desc) as ranking 
			from
				(select distinct 
					state, 
					county, 
					party, 
					sum(votes) as liczba_g�os�w_partia, 
					pop_2010_real_hr
				from dane_populacja dp 
				group by party, county, pop_2010_real_hr, state
				order by county)rkg)naj
		where ranking = 1
		group by  party),
zageszczenie as 
	(select 
		party, 
		round(avg(zageszczenie_2010_hr),  2) as �rednia_zageszczenie_populacji, 
		count (*) as liczba_wygranych 
		from
			(select 
				state, 
				county,liczba_g�os�w_partia, 
				party, 
				zageszczenie_2010_hr,
				dense_rank () over (partition by county, state order by liczba_g�os�w_partia desc) as ranking 
				from
					(select distinct 
						state, 
						county, 
						party, 
						sum(votes) as liczba_g�os�w_partia, 
						zageszczenie_2010_hr
					from dane_populacja dp 
					group by party, county, zageszczenie_2010_hr, state
					order by county)rkg)naj
			where ranking = 1
			group by  party)
select wielkosc.party, �rednia_wielko��_populacji, �rednia_zageszczenie_populacji, wielkosc.liczba_wygranych
from wielkosc
join zageszczenie
on wielkosc.party = zageszczenie.party



/* correlation between all votes and party selection in veterans group*/

select 
party, 
corr(votes, pop_2010_real_hr) as korelacja_populacja_2010,
corr(votes, zageszczenie_2010_hr) as korelacja_zageszczenie_2010
from dane_populacja
group by party
order by corr(votes, pop_2010_real_hr) desc

/* correlation between all votes in state and party selection in veterans group*/
select 
party, 
state, 
corr(suma_g�os�w_stan, pop_2010_real_hr) as korelacja_liczebno��,
corr(suma_g�os�w_stan, zageszczenie_2010_hr) as korelacja_zageszczenie
from
	(select distinct 
		party, 
		sum(votes) over (partition by party, county) as suma_g�os�w_stan, 
		state, 
		county, 
		pop_2010_real_hr, 
		zageszczenie_2010_hr
	from dane_populacja
	group by state, state, party, pop_2010_real_hr, votes, county, zageszczenie_2010_hr)x
group by party,state
order by corr(suma_g�os�w_stan, pop_2010_real_hr)  desc


/* Checking the same relations grouped by states*/

/* Next step - calcualtion of WOE and IV - checking real impact on election*/

/* Start of anaylysis - analysis of no. of populationper state. We check how many states are assigned to each group */


select 
wielko��_stanu,  
count(*) 
from 
	(select distinct 
		state,
		case 
			when pop_2010_real_stan < 5000000 then '0 - 5 mln'
			when pop_2010_real_stan < 10000000 then '5 - 10 mln'
			when pop_2010_real_stan < 15000000 then '10 - 15 mln'
			when pop_2010_real_stan < 20000000 then '15 - 20 mln'
			when pop_2010_real_stan < 30000000 then '20 - 30 mln'
			when pop_2010_real_stan < 40000000 then '30 - 40 mln'
			else 'powy�ej 40 mln'
		end as wielko��_stanu
	from dane_populacja)x
group by wielko��_stanu

/*WOE and IV calcualtion*/
create view v_iv_populacja_stan_ as
	with rep as
		(select distinct 
			party, 
			wielko��_stanu, 
			sum(votes) over (partition by party, wielko��_stanu) as liczba_g�_republikanie,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
				(select 
					party, 
					votes, 
					case 
						when pop_2010_real_stan < 5000000 then '0 - 5 mln'
						when pop_2010_real_stan < 10000000 then '5 - 10 mln'
						when pop_2010_real_stan < 15000000 then '10 - 15 mln'
						when pop_2010_real_stan < 20000000 then '15 - 20 mln'
						when pop_2010_real_stan < 30000000 then '20 - 30 mln'
						when pop_2010_real_stan < 40000000 then '30 - 40 mln'
						else 'powy�ej 40 mln'
					end as wielko��_stanu
					from dane_populacja
					group by party, votes, pop_2010_real_stan
					order by wielko��_stanu)m
		where party = 'Republican'),
dem as
	(select distinct 
		party, 
		wielko��_stanu, 
		sum(votes) over (partition by party, wielko��_stanu) as liczba_g�_demokraci,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
		from
			(select 
				party, 
				votes, 
				case 
					when pop_2010_real_stan < 5000000 then '0 - 5 mln'
					when pop_2010_real_stan < 10000000 then '5 - 10 mln'
					when pop_2010_real_stan < 15000000 then '10 - 15 mln'
					when pop_2010_real_stan < 20000000 then '15 - 20 mln'
					when pop_2010_real_stan < 30000000 then '20 - 30 mln'
					when pop_2010_real_stan < 40000000 then '30 - 40 mln'
					else 'powy�ej 40 mln'
				end as wielko��_stanu
				from dane_populacja
				group by party, votes, pop_2010_real_stan
				order by wielko��_stanu)m
			where party = 'Democrat')
select 
rep.wielko��_stanu, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.wielko��_stanu = dem.wielko��_stanu



select *
from v_iv_populacja_stan_ ;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_populacja_stan_ /*predyktor - 0.093 - no detailed analysis*/


/*The same calulation for population per mile ^2 in states*/

/* Calculation no. of states in group*/


select 
zag�szczenie_stanu, 
count(*) 
from
	(select distinct 
		state,
		case 
		when zageszczenie_2010_stan < 50 then '0 - 50'
		when zageszczenie_2010_stan < 100 then '50 - 100'
		when zageszczenie_2010_stan < 150 then '100 - 150'
		when zageszczenie_2010_stan < 200 then '150 - 200'
		when zageszczenie_2010_stan < 500 then '200 - 500'
		when zageszczenie_2010_stan < 1000 then '500 - 1000'
		else '1000 +'
	end as zag�szczenie_stanu
	from dane_populacja)x
group by zag�szczenie_stanu

/*Calculation of WOE and IV*/
create view v_iv_zageszczenie_stan_ as
	with rep as
	(select distinct 
		party, 
		zag�szczenie_stanu, 
		sum(votes) over (partition by party, zag�szczenie_stanu) as liczba_g�_republikanie,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
		from
			(select 
				party, 
				votes, 
				case 
					when zageszczenie_2010_stan < 50 then '0 - 50'
					when zageszczenie_2010_stan < 100 then '50 - 100'
					when zageszczenie_2010_stan < 150 then '100 - 150'
					when zageszczenie_2010_stan < 200 then '150 - 200'
					when zageszczenie_2010_stan < 500 then '200 - 500'
					when zageszczenie_2010_stan < 1000 then '500 - 1000'
					else '1000 +'
				end as zag�szczenie_stanu
				from dane_populacja
				group by party, votes, zageszczenie_2010_stan
				order by zag�szczenie_stanu)m
				where party = 'Republican'),
dem as
	(select distinct 
		party, 
		zag�szczenie_stanu, 
		sum(votes) over (partition by party, zag�szczenie_stanu) as liczba_g�_demokraci,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
		from
			(select 
				party, 
				votes, 
				case 
					when zageszczenie_2010_stan < 50 then '0 - 50'
					when zageszczenie_2010_stan < 100 then '50 - 100'
					when zageszczenie_2010_stan < 150 then '100 - 150'
					when zageszczenie_2010_stan < 200 then '150 - 200'
					when zageszczenie_2010_stan < 500 then '200 - 500'
					when zageszczenie_2010_stan < 1000 then '500 - 1000'
					else '1000 +'
				end as zag�szczenie_stanu
				from dane_populacja
				group by party, votes, zageszczenie_2010_stan
				order by zag�szczenie_stanu)m
				where party = 'Democrat')
select 
rep.zag�szczenie_stanu, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.zag�szczenie_stanu = dem.zag�szczenie_stanu


select *
from v_iv_zageszczenie_stan_;
select sum(dd_dr_woe) as information_value 
from v_iv_zageszczenie_stan_ /*predyktor - 0.204*/


/*list of states in each group*/

with stany as
	(select  
		state, 
		party, 
		zag�szczenie_stanu 
			from
				(select  distinct 
					state, 
					party,
					case 
						when zageszczenie_2010_stan < 50 then '0 - 50'
						when zageszczenie_2010_stan < 100 then '50 - 100'
						when zageszczenie_2010_stan < 150 then '100 - 150'
						when zageszczenie_2010_stan < 200 then '150 - 200'
						when zageszczenie_2010_stan < 500 then '200 - 500'
						when zageszczenie_2010_stan < 1000 then '500 - 1000'
						else '1000 +'
					end as zag�szczenie_stanu
					from dane_populacja)x) 
select  state, party, stany.zag�szczenie_stanu,
liczba_g�_republikanie, liczba_g�_demokraci
from stany
join v_iv_zageszczenie_stan vis
on stany.zag�szczenie_stanu = vis.zag�szczenie_stanu 


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*3. Data anaylysis for age group*/


select * from county_facts

select * from county_facts_dictionary
where column_name like 'AGE%'

/* We create table, which includes data needed for age group impact on United States Election in 2016*/
create table dane_wiekowe as 
select 
state,
county,  
party, 
candidate, 
votes,
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,
AGE135214 as osoby_poni�ej_5_hr,
round(avg(AGE135214) over (partition by state), 2) as osoby_poni�ej_5_stan,
AGE295214 as osoby_poni�ej_18_hr, 
round(avg(AGE295214) over (partition by state), 2) as osoby_poni�ej_18_stan,
AGE775214 as osoby_min_65_hr,
round(avg(AGE775214 ) over (partition by state), 2) as osoby_min_65_stan,
100 - (AGE295214 + AGE775214) as osoby_18_do_65_hr,
round(avg(100 - (AGE295214 + AGE775214)) over (partition by state), 2) as osoby_18_do_65_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips



/* Start of anaylysis - analysis of no. of group gae 18-65 per county. We check how many counties are assigned to each group */

select 
procent_wiek_�redni,  
count(*) 
from 
	(select distinct 
		county, 
		state,
		case 
			when osoby_18_do_65_hr < 55 then '0 - 55 %'
			when osoby_18_do_65_hr < 58 then '55 - 58 %'
			when osoby_18_do_65_hr < 60 then '58 - 60 %'
			when osoby_18_do_65_hr < 63 then '60 - 63 %'
			else 'powy�ej 63 %'
		end as procent_wiek_�redni
		from dane_wiekowe)x
group by procent_wiek_�redni


/*Calcualtion of WOE i IV*/
create view v_iv_wieku_18_65_ as
	with rep as
		(select distinct 
			party, 
			procent_wiek_�redni, sum(votes) over (partition by party, procent_wiek_�redni) as liczba_g�_republikanie,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
			from
				(select 
					party, 
					votes, 
					case 
						when osoby_18_do_65_hr < 55 then '0 - 55 %'
						when osoby_18_do_65_hr < 58 then '55 - 58 %'
						when osoby_18_do_65_hr < 60 then '58 - 60 %'
						when osoby_18_do_65_hr < 63 then '60 - 63 %'
						else 'powy�ej 63 %'
					end as procent_wiek_�redni
					from dane_wiekowe
					group by party, votes, osoby_18_do_65_hr)m
			where party = 'Republican'),
dem as
	(select distinct 
		party, 
		procent_wiek_�redni, 
		sum(votes) over (partition by party, procent_wiek_�redni) as liczba_g�_demokraci,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
		from
			(select 
				party, 
				votes, 
				case 
					when osoby_18_do_65_hr < 55 then '0 - 55 %'
					when osoby_18_do_65_hr < 58 then '55 - 58 %'
					when osoby_18_do_65_hr < 60 then '58 - 60 %'
					when osoby_18_do_65_hr < 63 then '60 - 63 %'
					else 'powy�ej 63 %'
				end as procent_wiek_�redni
				from dane_wiekowe
				group by party, votes, osoby_18_do_65_hr)m
		where party = 'Democrat')
select 
rep.procent_wiek_�redni, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_wiek_�redni = dem.procent_wiek_�redni



select *
from v_iv_wieku_18_65_;
select sum(dd_dr_woe) as information_value 
from v_iv_wieku_18_65_ /*�redni predyktor - 0.202*/

/* list of cunties assigned to each group */
with stany as
	(select 
	county, 
	state, 
	party, 
	procent_wiek_�redni 
	from
		(select  distinct 
			county, 
			state, 
			party,
			case 
				when osoby_18_do_65_hr < 55 then '0 - 55 %'
				when osoby_18_do_65_hr < 58 then '55 - 58 %'
				when osoby_18_do_65_hr < 60 then '58 - 60 %'
				when osoby_18_do_65_hr < 63 then '60 - 63 %'
				else 'powy�ej 63 %'
			end as procent_wiek_�redni
			from dane_wiekowe)x) 
select 
county, 
state, 
party, 
stany.procent_wiek_�redni,
liczba_g�_republikanie, liczba_g�_demokraci
from stany
join v_iv_wiek_18_65 vi�
on stany.procent_wiek_�redni = vi�.procent_wiek_�redni 

/* Average of no. of goup ages 18-65 per state. Calcuclation was done per states, where particulat party won*/



select distinct 
	party, 
	round(avg(osoby_18_do_65_stan),  2) as �r_procent_18_do_65, 
	count(*) as liczba_wygranych
	from  
		(select 
		party, 
		state, 
		sum(prct_g�_stan_all) as prct_partia_stan, 
		dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_18_do_65_stan
		from
			(select distinct 
			state, 
			party, 
			prct_g�_stan_all,  
			osoby_18_do_65_stan
			from dane_wiekowe)dem
		group by party, state, osoby_18_do_65_stan
		order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party



 /* Average of no. of group 18-65 per county. Calcuclation was done per counties, where particular party won*/
 

select 
party,
round(avg(osoby_18_do_65_hr),  2) as �redni_udzia�_18_do_65, 
count (*) as liczba_wygranych 
from
	(select 
	state, 
	county,
	liczba_g�os�w_partia, 
	party, 
	osoby_18_do_65_hr,
	dense_rank () over (partition by county, state order by liczba_g�os�w_partia desc) as ranking 
	from
		(select distinct 
		state, 
		county, 
		party, 
		sum(votes) as liczba_g�os�w_partia, 
		osoby_18_do_65_hr
		from dane_wiekowe
		group by party, county, osoby_18_do_65_hr, state
		order by county)rkg)naj
where ranking = 1
group by  party




/* correlation between all votes and party selection in 18-65group*/

select 
party, 
corr(votes, osoby_18_do_65_hr) as korelacja_18_do_65
from dane_wiekowe
group by party

/* correlation between all votes in state and party selection in 18-65 group*/
select 
party, 
state, 
corr(suma_g�os�w_stan, osoby_18_do_65_hr) as korelacja_grupa_18_do_65 
from
	(select distinct 
		party, 
		sum(votes) over (partition by party, county) as suma_g�os�w_stan, 
		state, 
		county, 
		osoby_18_do_65_hr
	from dane_wiekowe dw 
	group by state, state, party, osoby_18_do_65_hr, votes, county)x
group by party,state
order by corr(suma_g�os�w_stan, osoby_18_do_65_hr)  desc


/* Checking the same relations grouped by states*/

/* Next step - calcualtion of WOE and IV - checking real impact on election*/

/* Start of anaylysis - analysis of group 19-65 age per state. We check how many states are assigned to each group */

select 
procent_wiek_�redni_stan,  
count(*) 
from 
	(select distinct 
		state,
		case 
			when osoby_18_do_65_stan < 57 then '0 - 57 %'
			when osoby_18_do_65_stan < 58 then '57 - 58 %'
			when osoby_18_do_65_stan < 59 then '58 - 59 %'
			when osoby_18_do_65_stan < 60 then '59 - 60 %'
			when osoby_18_do_65_stan < 61 then '60 - 61 %'
			when osoby_18_do_65_stan < 62 then '61 - 62 %'
			else 'powy�ej 62 %'
		end as procent_wiek_�redni_stan
		from dane_wiekowe)x
group by procent_wiek_�redni_stan

/*Calculation of WOE i IV*/
create view v_iv_wiek_18_65_stan_ as
with rep as
(select distinct 
party, 
procent_wiek_�redni_stan, 
sum(votes) over (partition by party, procent_wiek_�redni_stan) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
from
	(select 
		party, 
		votes, 
		case 
		when osoby_18_do_65_stan < 57 then '0 - 57 %'
		when osoby_18_do_65_stan < 58 then '57 - 58 %'
		when osoby_18_do_65_stan < 59 then '58 - 59 %'
		when osoby_18_do_65_stan < 60 then '59 - 60 %'
		when osoby_18_do_65_stan < 61 then '60 - 61 %'
		when osoby_18_do_65_stan < 62 then '61 - 62 %'
		else 'powy�ej 62 %'
		end as procent_wiek_�redni_stan
	from dane_wiekowe
	group by party, votes, osoby_18_do_65_stan)m
where party = 'Republican'),
dem as
	(select distinct 
		party, 
		procent_wiek_�redni_stan, 
		sum(votes) over (partition by party, procent_wiek_�redni_stan) as liczba_g�_demokraci,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
		from
			(select 
				party, 
				votes, 
				case 
					when osoby_18_do_65_stan < 57 then '0 - 57 %'
					when osoby_18_do_65_stan < 58 then '57 - 58 %'
					when osoby_18_do_65_stan < 59 then '58 - 59 %'
					when osoby_18_do_65_stan < 60 then '59 - 60 %'
					when osoby_18_do_65_stan < 61 then '60 - 61 %'
					when osoby_18_do_65_stan < 62 then '61 - 62 %'
					else 'powy�ej 62 %'
				end as procent_wiek_�redni_stan
				from dane_wiekowe
				group by party, votes, osoby_18_do_65_stan)m
	where party = 'Democrat')
select 
rep.procent_wiek_�redni_stan, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_wiek_�redni_stan = dem.procent_wiek_�redni_stan



select *
from v_iv_wiek_18_65_stan_;
select sum(dd_dr_woe) as information_value 
from v_iv_wiek_18_65_stan_ /*predyktor - 0.197*/

/* list of states grouped per each group */
with stany as
	(select 
		state, 
		party, 
		procent_wiek_�redni_stan 
		from
			(select  distinct 
				state, 
				party,
				case 
					when osoby_18_do_65_stan < 57 then '0 - 57 %'
					when osoby_18_do_65_stan < 58 then '57 - 58 %'
					when osoby_18_do_65_stan < 59 then '58 - 59 %'
					when osoby_18_do_65_stan < 60 then '59 - 60 %'
					when osoby_18_do_65_stan < 61 then '60 - 61 %'
					when osoby_18_do_65_stan < 62 then '61 - 62 %'
					else 'powy�ej 62 %'
					end as procent_wiek_�redni_stan
				from dane_wiekowe)x) 
select 
state, 
party, 
stany.procent_wiek_�redni_stan,
liczba_g�_republikanie, liczba_g�_demokraci
from stany
join v_iv_wiek_18_65_stan viss
on stany.procent_wiek_�redni_stan = viss.procent_wiek_�redni_stan 

-----------------------------------------------------------------------------------------

/*The same calcualtions for age > 65 - WOE + IV */

select 
procent_wiek_senior,  
count(*) from 
	(select distinct 
		county, 
		state,
		case 
			when osoby_min_65_hr < 12 then '0 - 12 %'
			when osoby_min_65_hr < 16 then '12 - 16 %'
			when osoby_min_65_hr < 18 then '16 - 18 %'
			when osoby_min_65_hr < 20 then '18 - 20 %'
			when osoby_min_65_hr < 25 then '20 - 25 %'
			else 'powy�ej 25 %'
		end as procent_wiek_senior
		from dane_wiekowe)x
group by procent_wiek_senior


create view v_iv_min_65_ as
	with rep as
		(select distinct 
			party, 
			procent_wiek_senior, 
			sum(votes) over (partition by party, procent_wiek_senior) as liczba_g�_republikanie,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
			from
			(select 
				party, 
				votes, 
				case 
					when osoby_min_65_hr < 12 then '0 - 12 %'
					when osoby_min_65_hr < 16 then '12 - 16 %'
					when osoby_min_65_hr < 18 then '16 - 18 %'
					when osoby_min_65_hr < 20 then '18 - 20 %'
					when osoby_min_65_hr < 25 then '20 - 25 %'
					else 'powy�ej 25 %'
				end as procent_wiek_senior
				from dane_wiekowe
				group by party, votes, osoby_min_65_hr)m
		where party = 'Republican'),
	dem as
		(select distinct 
			party, 
			procent_wiek_senior,
			sum(votes) over (partition by party, procent_wiek_senior) as liczba_g�_demokraci,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
			from
				(select 
					party, 
					votes, 
					case 
						when osoby_min_65_hr < 12 then '0 - 12 %'
						when osoby_min_65_hr < 16 then '12 - 16 %'
						when osoby_min_65_hr < 18 then '16 - 18 %'
						when osoby_min_65_hr < 20 then '18 - 20 %'
						when osoby_min_65_hr < 25 then '20 - 25 %'
						else 'powy�ej 25 %'
					end as procent_wiek_senior
					from dane_wiekowe
					group by party, votes, osoby_min_65_hr)m
			where party = 'Democrat')
select 
rep.procent_wiek_senior, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_wiek_senior = dem.procent_wiek_senior



select *
from v_iv_min_65_;
select sum(dd_dr_woe) as information_value /
from v_iv_min_65_ /*predyktor - 0.111 - not considered as real impact for election*/

/*-Checking WOE and IV for age group under 5 years*/

select
procent_wiek_do_5,  
count(*) 
from 
	(select distinct 
		county, 
		state,
		case 
			when osoby_poni�ej_5_hr < 5 then '0 - 5 %'
			when osoby_poni�ej_5_hr < 6 then '5 - 6 %'
			when osoby_poni�ej_5_hr < 7 then '6 - 7 %'
			when osoby_poni�ej_5_hr < 8 then '7 - 8 %'
			else 'powy�ej 8 %'
		end as procent_wiek_do_5
		from dane_wiekowe)x
group by procent_wiek_do_5

/*WOE i IV*/
create view v_iv_do_5_ as
with rep as
	(select distinct 
	party, 
	procent_wiek_do_5, sum(votes) over (partition by party, procent_wiek_do_5) as liczba_g�_republikanie,
	sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
	from
		(select 
		party, 
		votes, 
		case 
			when osoby_poni�ej_5_hr < 5 then '0 - 5 %'
			when osoby_poni�ej_5_hr < 6 then '5 - 6 %'
			when osoby_poni�ej_5_hr < 7 then '6 - 7 %'
			when osoby_poni�ej_5_hr < 8 then '7 - 8 %'
		else 'powy�ej 8 %'
		end as procent_wiek_do_5
		from dane_wiekowe
		group by party, votes, osoby_poni�ej_5_hr)m
	where party = 'Republican'),
dem as
	(select distinct 
	party, 
	procent_wiek_do_5, 
	sum(votes) over (partition by party, procent_wiek_do_5) as liczba_g�_demokraci,
	sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
	from
		(select 
		party, 
		votes, 
		case 
			when osoby_poni�ej_5_hr < 5 then '0 - 5 %'
			when osoby_poni�ej_5_hr < 6 then '5 - 6 %'
			when osoby_poni�ej_5_hr < 7 then '6 - 7 %'
			when osoby_poni�ej_5_hr < 8 then '7 - 8 %'
			else 'powy�ej 8 %'
		end as procent_wiek_do_5
		from dane_wiekowe
		group by party, votes, osoby_poni�ej_5_hr)m
	where party = 'Democrat')
select 
rep.procent_wiek_do_5, 
liczba_g�_republikanie,
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_wiek_do_5 = dem.procent_wiek_do_5



select *
from v_iv_do_5_;
select sum(dd_dr_woe) as information_value 
from v_iv_do_5_ /*predyktor - 0.063 */

/*The same calcualation for group descrined as under 18 years*/


select 
procent_wiek_do_18,  
count(*) 
from 
	(select distinct 
		county, 
		state,
		case 
			when osoby_poni�ej_18_hr < 20 then '0 - 20 %'
			when osoby_poni�ej_18_hr < 23 then '20 - 23 %'
			when osoby_poni�ej_18_hr < 25 then '23 - 25 %'
			when osoby_poni�ej_18_hr < 27 then '25 - 27 %'
			else 'powy�ej 27 %'
		end as procent_wiek_do_18
		from dane_wiekowe)x
group by procent_wiek_do_18

/*WOE i IV*/
create view v_iv_do_18_ as
	with rep as
		(select distinct 
			party, 
			procent_wiek_do_18, sum(votes) over (partition by party, procent_wiek_do_18) as liczba_g�_republikanie,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
			from
				(select 
					party, 
					votes, 
					case 
						when osoby_poni�ej_18_hr < 20 then '0 - 20 %'
						when osoby_poni�ej_18_hr < 23 then '20 - 23 %'
						when osoby_poni�ej_18_hr < 25 then '23 - 25 %'
						when osoby_poni�ej_18_hr < 27 then '25 - 27 %'
						else 'powy�ej 27 %'
					end as procent_wiek_do_18
					from dane_wiekowe
					group by party, votes, osoby_poni�ej_18_hr)m
		where party = 'Republican'),
	dem as
		(select distinct 
			party, 
			procent_wiek_do_18, 
			sum(votes) over (partition by party, procent_wiek_do_18) as liczba_g�_demokraci,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
			from
				(select 
					party, 
					votes, 
					case 
						when osoby_poni�ej_18_hr < 20 then '0 - 20 %'
						when osoby_poni�ej_18_hr < 23 then '20 - 23 %'
						when osoby_poni�ej_18_hr < 25 then '23 - 25 %'
						when osoby_poni�ej_18_hr < 27 then '25 - 27 %'
						else 'powy�ej 27 %'
					end as procent_wiek_do_18
					from dane_wiekowe
					group by party, votes, osoby_poni�ej_18_hr)m
		where party = 'Democrat')
select 
rep.procent_wiek_do_18, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_wiek_do_18 = dem.procent_wiek_do_18



select *
from v_iv_do_18_;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_do_18_ /*predyktor - 0.079 */

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*4. Data anaylysis for gender*/


select * from county_facts

select * from county_facts_dictionary
where column_name  like 'SEX%'


/* tworzenie tabeli pomocniczej zawieraj�cej wszystkie dane potrzebne do analizy*/
create table dane_p�e� as 
select state,county,  party, candidate, votes, round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,fraction_votes ,
SEX255214 as kobiety_hr,
round(avg(SEX255214)  over (partition by state), 2) as kobiety_stan,
100 - SEX255214 as m�czy�ni_hr,
round(avg(100 - SEX255214) over (partition by state), 2) as m�czy�ni_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips


--WOE i IV women--

/* Start of anaylysis - analysis of women % per county. We check how many counties are assigned to each group */


select 
procent_kobiet,  
count(*) from 
	(select distinct 
		county,
		state,
		case 
			when kobiety_hr < 48 then '0 - 48 %'
			when kobiety_hr < 49 then '48 - 49 %'
			when kobiety_hr < 50 then '49 - 50 %'
			when kobiety_hr < 51 then '50 - 51 %'
			when kobiety_hr < 52 then '51 - 52 %'
			else 'powy�ej 52%'
		end as procent_kobiet
		from dane_p�e�)x
group by procent_kobiet

/*Calculation of WOE i IV*/
create view v_iv_kobiety_ as
	with rep as
		(select distinct 
			party, 
			procent_kobiet, 
			sum(votes) over (partition by party, procent_kobiet) as liczba_g�_republikanie,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
			from
				(select 
					party, 
					votes, 
					case 
						when kobiety_hr < 48 then '0 - 48 %'
						when kobiety_hr < 49 then '48 - 49 %'
						when kobiety_hr < 50 then '49 - 50 %'
						when kobiety_hr < 51 then '50 - 51 %'
						when kobiety_hr < 52 then '51 - 52 %'
						else 'powy�ej 52%'
					end as procent_kobiet
					from dane_p�e�
					group by party, votes, kobiety_hr
					order by procent_kobiet)m
		where party = 'Republican'),
	dem as
		(select distinct 
			party, 
			procent_kobiet, 
			sum(votes) over (partition by party, procent_kobiet) as liczba_g�_demokraci,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
			from
				(select 
					party, 
					votes, 
					case 
						when kobiety_hr < 48 then '0 - 48 %'
						when kobiety_hr < 49 then '48 - 49 %'
						when kobiety_hr < 50 then '49 - 50 %'
						when kobiety_hr < 51 then '50 - 51 %'
						when kobiety_hr < 52 then '51 - 52 %'
						else 'powy�ej 52%'
					end as procent_kobiet
					from dane_p�e�
					group by party, votes, kobiety_hr
					order by procent_kobiet)m
			where party = 'Democrat')
select 
rep.procent_kobiet, 
liczba_g�_republikanie,
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_kobiet = dem.procent_kobiet



select *
from v_iv_kobiety_;
select sum(dd_dr_woe) as information_value 
from v_iv_kobiety_ /*predyktor - 0.098*/


--WOE i IV men--

/* Start of anaylysis - analysis of women % per county. We check how many counties are assigned to each group */


select 
procent_m�czyzn,  
count(*) from 
	(select distinct 
		county, 
		state,
		case 
			when m�czy�ni_hr < 48 then '0 - 48 %'
			when m�czy�ni_hr < 49 then '48 - 49 %'
			when m�czy�ni_hr < 50 then '49 - 50 %'
			when m�czy�ni_hr < 51 then '50 - 51 %'
			when m�czy�ni_hr < 52 then '51 - 52 %'
			else 'powy�ej 52%'
		end as procent_m�czyzn
		from dane_p�e�)x
group by procent_m�czyzn

/*Calculation of WOE i IV*/
create view v_iv_mezczyzni_ as
	with rep as
		(select distinct 
			party, 
			procent_m�czyzn, 
			sum(votes) over (partition by party, procent_m�czyzn) as liczba_g�_republikanie,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
			from
				(select
					party,
					votes, 
					case 
						when m�czy�ni_hr < 48 then '0 - 48 %'
						when m�czy�ni_hr < 49 then '48 - 49 %'
						when m�czy�ni_hr < 50 then '49 - 50 %'
						when m�czy�ni_hr < 51 then '50 - 51 %'
						when m�czy�ni_hr < 52 then '51 - 52 %'
						else 'powy�ej 52%'
					end as procent_m�czyzn
					from dane_p�e�
					group by party, votes, m�czy�ni_hr
					order by procent_m�czyzn)m
		where party = 'Republican'),
	dem as
		(select distinct 
			party, 
			procent_m�czyzn, 
			sum(votes) over (partition by party, procent_m�czyzn) as liczba_g�_demokraci,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
			from
				(select 
					party, 
					votes, 
					case 
						when m�czy�ni_hr < 48 then '0 - 48 %'
						when m�czy�ni_hr < 49 then '48 - 49 %'
						when m�czy�ni_hr < 50 then '49 - 50 %'
						when m�czy�ni_hr < 51 then '50 - 51 %'
						when m�czy�ni_hr < 52 then '51 - 52 %'
						else 'powy�ej 52%'
					end as procent_m�czyzn
					from dane_p�e�
					group by party, votes, m�czy�ni_hr
					order by procent_m�czyzn)m
		where party = 'Democrat')
select 
rep.procent_m�czyzn, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_m�czyzn = dem.procent_m�czyzn



select *
from v_iv_mezczyzni_;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_mezczyzni_ /*predyktor- 0.100*/

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*5. Data anaylysis for mean travel time to work*/

select * from county_facts

select * from county_facts_dictionary
where column_name  = 'LFE305213'

/* We create table, which includes data needed for  impact on United States Election in 2016 (factor - mean travel time to work)*/
create table dane_dojazd as 
select 
state,
county,  
party, 
candidate, 
votes, 
fraction_votes ,
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,
LFE305213 as �redni_czas_dojazdu_min_praca_hr,
round(avg(LFE305213) over (partition by state), 2) as �redni_czas_dojazdu_min_praca_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips

/* Start of anaylysis - We check how many counties are assigned to each group */



select czas_dojazdu, 
count(*) 
from 
	(select distinct 
		county, 
		state,
		case  
			when �redni_czas_dojazdu_min_praca_hr < 15 then '0 - 15 min'
			when �redni_czas_dojazdu_min_praca_hr < 20 then '15 - 20 min'
			when �redni_czas_dojazdu_min_praca_hr < 25 then '20 - 25 min'
			else '25 + min'
		end as czas_dojazdu
		from dane_dojazd)x
group by czas_dojazdu

/*Calculations of WOE i IV*/
create view v_obliczenia_iv_dojazd_ as
	with rep as
		(select distinct 
			party, 
			czas_dojazdu, 
			sum(votes) over (partition by party, czas_dojazdu) as liczba_g�_republikanie,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
			from
				(select 
					party, 
					votes, 
					case
						when �redni_czas_dojazdu_min_praca_hr < 15 then '0 - 15 min'
						when �redni_czas_dojazdu_min_praca_hr < 20 then '15 - 20 min'
						when �redni_czas_dojazdu_min_praca_hr < 25 then '20 - 25 min'
						else '25 + min'
					end as czas_dojazdu
					from dane_dojazd
					group by party, votes, �redni_czas_dojazdu_min_praca_hr
					order by czas_dojazdu)m
			where party = 'Republican'),
	dem as 
		(select distinct 
			party, 
			czas_dojazdu, 
			sum(votes) over (partition by party, czas_dojazdu ) as liczba_g�_demokraci,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
			from
				(select 
					party, 
					votes, 
					case
						when �redni_czas_dojazdu_min_praca_hr < 15 then '0 - 15 min'
						when �redni_czas_dojazdu_min_praca_hr < 20 then '15 - 20 min'
						when �redni_czas_dojazdu_min_praca_hr < 25 then '20 - 25 min'
						else '25 + min'
						end as czas_dojazdu
					from dane_dojazd
					group by party, votes, �redni_czas_dojazdu_min_praca_hr
					order by czas_dojazdu)m
				where party = 'Democrat')
select distinct 
dem.czas_dojazdu, 
liczba_g�_republikanie, 
liczba_g�_demokraci, 
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep 
join dem 
on dem.czas_dojazdu = rep.czas_dojazdu


select *
from v_obliczenia_iv_dojazd_;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_obliczenia_iv_dojazd_ /*predyktor - 0.074.*/

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*6. Data anaylysis for mean travel time to work*/

select * from county_facts

select * from county_facts_dictionary
where column_name  like 'EDU%'

/* We create table, which includes data needed for investigation of education group for impact on United States Election in 2016*/
create table dane_edukacj as 
select 
state,
county,  
party, 
candidate, 
votes,
fraction_votes ,
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,
EDU635213 as wykszta�cenie_min_�rednie_hr,
round(avg(EDU635213) over (partition by state), 2) as osoby_wykszta�cenie_�rednie_stan,
EDU685213 as wykszta�cenie_min_wy�sze_hr, 
round(avg(EDU685213) over (partition by state), 2) as osoby_wykszta�cenie_wy�sze_stan,
100 - EDU635213 as brak_wykszta�cenia_hr,
round(avg(100 - EDU635213) over (partition by state), 2) as osoby_bez_wykszta�cenia_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips


/* Start of anaylysis - analysis of group with high school graduation per county. We check how many counties are assigned to each group */


select 
procent_wykszta�cenie_�rednie,  
count(*) from 
	(select distinct 
		county, 
		state,
		case 
			when wykszta�cenie_min_�rednie_hr < 75 then '0 - 75 %'
			when wykszta�cenie_min_�rednie_hr < 80 then '75 - 80 %'
			when wykszta�cenie_min_�rednie_hr < 85 then '80 - 85 %'
			when wykszta�cenie_min_�rednie_hr < 90 then '85 - 90 %'
			else 'powy�ej 90%'
		end as procent_wykszta�cenie_�rednie
		from dane_edukacj)x
group by procent_wykszta�cenie_�rednie

/*Calcualtion of WOE and IV*/
create view v_iv_wyk_�rednie_ as
	with rep as
		(select distinct 
			party,
			procent_wykszta�cenie_�rednie, 
			sum(votes) over (partition by party, procent_wykszta�cenie_�rednie) as liczba_g�_republikanie,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
			from
				(select 
					party, 
					votes, 
					case 
						when wykszta�cenie_min_�rednie_hr < 75 then '0 - 75 %'
						when wykszta�cenie_min_�rednie_hr < 80 then '75 - 80 %'
						when wykszta�cenie_min_�rednie_hr < 85 then '80 - 85 %'
						when wykszta�cenie_min_�rednie_hr < 90 then '85 - 90 %'
						else 'powy�ej 90%'
					end as procent_wykszta�cenie_�rednie
					from dane_edukacj
					group by party, votes, wykszta�cenie_min_�rednie_hr
					order by procent_wykszta�cenie_�rednie)m
			where party = 'Republican'),
	dem as
		(select distinct 
			party, 
			procent_wykszta�cenie_�rednie, 
			sum(votes) over (partition by party, procent_wykszta�cenie_�rednie) as liczba_g�_demokraci,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
			from
				(select 
					party, 
					votes, 
					case 
						when wykszta�cenie_min_�rednie_hr < 75 then '0 - 75 %'
						when wykszta�cenie_min_�rednie_hr < 80 then '75 - 80 %'
						when wykszta�cenie_min_�rednie_hr < 85 then '80 - 85 %'
						when wykszta�cenie_min_�rednie_hr < 90 then '85 - 90 %'
						else 'powy�ej 90%'
					end as procent_wykszta�cenie_�rednie
					from dane_edukacj
					group by party, votes, wykszta�cenie_min_�rednie_hr
					order by procent_wykszta�cenie_�rednie)m
				where party = 'Democrat')
select 
rep.procent_wykszta�cenie_�rednie, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_wykszta�cenie_�rednie = dem.procent_wykszta�cenie_�rednie


select *
from v_iv_wyk_�rednie_ ;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_wyk_�rednie_ /*nieu�yteczny predyktor - 0.067*/



/*The same analysis for bachelor status achieved*/


select 
procent_wykszta�cenie_wy�sze,  
count(*) from 
	(select distinct 
		county, 
		state,
		case 
			when wykszta�cenie_min_wy�sze_hr < 10 then '0 - 10 %'
			when wykszta�cenie_min_wy�sze_hr < 15 then '10 - 15 %'
			when wykszta�cenie_min_wy�sze_hr < 20 then '15 - 20 %'
			when wykszta�cenie_min_wy�sze_hr < 25 then '20 - 25 %'
			when wykszta�cenie_min_wy�sze_hr  < 30 then '25 - 30 %'
			when wykszta�cenie_min_wy�sze_hr  < 35 then '30 - 35 %'
			else 'powy�ej 35%'
		end as procent_wykszta�cenie_wy�sze
from dane_edukacj)x
group by procent_wykszta�cenie_wy�sze

/* WOE  IV*/
create view v_iv_wyk_wyzsze_ as
	with rep as
		(select distinct 
			party, 
			procent_wykszta�cenie_wy�sze, 
			sum(votes) over (partition by party, procent_wykszta�cenie_wy�sze) as liczba_g�_republikanie,
			sum (votes) over (partition by party) as suma_ca�kowita_partia_rep
			from
				(select 
					party,
					votes, 
					case 
						when wykszta�cenie_min_wy�sze_hr < 10 then '0 - 10 %'
						when wykszta�cenie_min_wy�sze_hr < 15 then '10 - 15 %'
						when wykszta�cenie_min_wy�sze_hr < 20 then '15 - 20 %'
						when wykszta�cenie_min_wy�sze_hr < 25 then '20 - 25 %'
						when wykszta�cenie_min_wy�sze_hr  < 30 then '25 - 30 %'
						when wykszta�cenie_min_wy�sze_hr  < 35 then '30 - 35 %'
						else 'powy�ej 35%'
					end as procent_wykszta�cenie_wy�sze
					from dane_edukacj
					group by party, votes, wykszta�cenie_min_wy�sze_hr
					order by procent_wykszta�cenie_wy�sze)m
				where party = 'Republican'),
dem as
	(select distinct 
		party, 
		procent_wykszta�cenie_wy�sze, 
		sum(votes) over (partition by party, procent_wykszta�cenie_wy�sze) as liczba_g�_demokraci,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
		from
			(select 
				party, 
				votes, 
				case 
					when wykszta�cenie_min_wy�sze_hr < 10 then '0 - 10 %'
					when wykszta�cenie_min_wy�sze_hr < 15 then '10 - 15 %'
					when wykszta�cenie_min_wy�sze_hr < 20 then '15 - 20 %'
					when wykszta�cenie_min_wy�sze_hr < 25 then '20 - 25 %'
					when wykszta�cenie_min_wy�sze_hr  < 30 then '25 - 30 %'
					when wykszta�cenie_min_wy�sze_hr  < 35 then '30 - 35 %'
					else 'powy�ej 35%'
				end as procent_wykszta�cenie_wy�sze
				from dane_edukacj
				group by party, votes, wykszta�cenie_min_wy�sze_hr
				order by procent_wykszta�cenie_wy�sze)m
			where party = 'Democrat')
select 
rep.procent_wykszta�cenie_wy�sze, 
liczba_g�_republikanie,
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_wykszta�cenie_wy�sze = dem.procent_wykszta�cenie_wy�sze


select *
from v_iv_wyk_wyzsze_ ;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_wyk_wyzsze_ /*�redni predyktor - 0.135*/

/*list of counties in each group of 'Bachelors' - usable to show on map*/

with stany as
(select 
county, 
state,party, 
procent_wykszta�cenie_wy�sze 
from
	(select  distinct 
		county, 
		state, 
		party,
		case 
			when wykszta�cenie_min_wy�sze_hr < 10 then '0 - 10 %'
			when wykszta�cenie_min_wy�sze_hr < 15 then '10 - 15 %'
			when wykszta�cenie_min_wy�sze_hr < 20 then '15 - 20 %'
			when wykszta�cenie_min_wy�sze_hr < 25 then '20 - 25 %'
			when wykszta�cenie_min_wy�sze_hr  < 30 then '25 - 30 %'
			when wykszta�cenie_min_wy�sze_hr  < 35 then '30 - 35 %'
			else 'powy�ej 35%'
		end as procent_wykszta�cenie_wy�sze
		from dane_edukacj)x) 
select 
county, 
state, 
party, 
stany.procent_wykszta�cenie_wy�sze,
liczba_g�_republikanie, 
liczba_g�_demokraci
from stany
join v_iv_wyk_wyzsze_ ive
on stany.procent_wykszta�cenie_wy�sze = ive.procent_wykszta�cenie_wy�sze
order by stany.procent_wykszta�cenie_wy�sze




/* Average of no. of 'Bachelors' per state. Calcuclation was done per states, where particulat party won*/


select distinct 
party, 
round(avg(osoby_wykszta�cenie_wy�sze_stan),  2) as �r_prct_wykszta�cenie_wy�sze,
count(*) as liczba_wygranych
from  
	(select 
	party, 
	state,
	sum(prct_g�_stan_all) as prct_partia_stan, 
	dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, 
	osoby_wykszta�cenie_wy�sze_stan
	from
		(select distinct 
		state, 
		party, 
		prct_g�_stan_all,  
		osoby_wykszta�cenie_wy�sze_stan
		from dane_edukacj de)dem
	group by party, state, osoby_wykszta�cenie_wy�sze_stan
	order by state) miejs
where miejsce = 1 
group by party




/* Average of no. of 'Bachelors' per county. Calcuclation was done per counties, where particular party won*/


select 
party, 
round(avg(wykszta�cenie_min_wy�sze_hr),  2) as �redni_prct_wykszta�cenie_wy�sze, 
count (*) as liczba_wygranych 
from
	(select 
		state, 
		county,
		liczba_g�os�w_partia, 
		party, 
		wykszta�cenie_min_wy�sze_hr,
		dense_rank () over (partition by county, state order by liczba_g�os�w_partia desc) as ranking 
			from
				(select distinct 
				state, 
				county, 
				party, 
				sum(votes) as liczba_g�os�w_partia, 
				wykszta�cenie_min_wy�sze_hr
				from dane_edukacj
				group by party, county, wykszta�cenie_min_wy�sze_hr, state
				order by county)rkg)naj
where ranking = 1
group by  party



/*Correlation between votes and no. of 'bachelors'*/

select party, 
corr(votes, wykszta�cenie_min_wy�sze_hr) as korelacja_weterani
from dane_edukacj
group by party
order by corr(votes, wykszta�cenie_min_wy�sze_hr) desc


/*Correlation between votes and no. of 'bachelors per each state'*/

select 
party, 
state, 
corr(suma_g�os�w_stan, wykszta�cenie_min_wy�sze_hr) as korelacja_wykszta�cenie_wy�sze 
from
	(select distinct 
		party, 
		sum(votes) over (partition by party, county) as suma_g�os�w_stan, 
		state, 
		county, 
		wykszta�cenie_min_wy�sze_hr
		from dane_edukacj
		group by state, state, party, wykszta�cenie_min_wy�sze_hr, votes, county)x
group by party,state
order by corr(suma_g�os�w_stan, wykszta�cenie_min_wy�sze_hr)  desc

/*the same analysis per states for 'bachelors'*/

select 
procent_wykszta�cenie_wy�sze, 
count(*) 
from
	(select distinct state,
	case 
		when osoby_wykszta�cenie_wy�sze_stan < 15 then '0 - 15 %'
		when osoby_wykszta�cenie_wy�sze_stan < 17 then '15 - 17 %'
		when osoby_wykszta�cenie_wy�sze_stan < 19 then '17 - 19 %'
		when osoby_wykszta�cenie_wy�sze_stan < 21 then '19 - 21 %'
		when osoby_wykszta�cenie_wy�sze_stan  < 23 then '21 - 23 %'
		when osoby_wykszta�cenie_wy�sze_stan  < 25 then '23 - 25 %'
		else 'powy�ej 25%'
	end as procent_wykszta�cenie_wy�sze
	from dane_edukacj)x
group by procent_wykszta�cenie_wy�sze

/* WOE and IV*/
create view v_obliczenia_iv_wy�sze_stan_ as
with rep as
	(select distinct 
		party, 
		procent_wykszta�cenie_wy�sze, 
		sum(votes) over (partition by party, procent_wykszta�cenie_wy�sze) as liczba_g�_republikanie,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
		from
			(select 
				party, 
				votes, 
				case 
					when osoby_wykszta�cenie_wy�sze_stan < 15 then '0 - 15 %'
					when osoby_wykszta�cenie_wy�sze_stan < 17 then '15 - 17 %'
					when osoby_wykszta�cenie_wy�sze_stan < 19 then '17 - 19 %'
					when osoby_wykszta�cenie_wy�sze_stan < 21 then '19 - 21 %'
					when osoby_wykszta�cenie_wy�sze_stan  < 23 then '21 - 23 %'
					when osoby_wykszta�cenie_wy�sze_stan  < 25 then '23 - 25 %'
					else 'powy�ej 25%'
				end as procent_wykszta�cenie_wy�sze
				from dane_edukacj
				group by party, votes, osoby_wykszta�cenie_wy�sze_stan
				order by procent_wykszta�cenie_wy�sze)m
	where party = 'Republican'),
dem as 
	(select distinct 
		party, 
		procent_wykszta�cenie_wy�sze, 
		sum(votes) over (partition by party, 
		procent_wykszta�cenie_wy�sze ) as liczba_g�_demokraci,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
		from
			(select 
				party, 
				votes, 
				case 
					when osoby_wykszta�cenie_wy�sze_stan < 15 then '0 - 15 %'
					when osoby_wykszta�cenie_wy�sze_stan < 17 then '15 - 17 %'
					when osoby_wykszta�cenie_wy�sze_stan < 19 then '17 - 19 %'
					when osoby_wykszta�cenie_wy�sze_stan < 21 then '19 - 21 %'
					when osoby_wykszta�cenie_wy�sze_stan  < 23 then '21 - 23 %'
					when osoby_wykszta�cenie_wy�sze_stan  < 25 then '23 - 25 %'
					else 'powy�ej 25%'
				end as procent_wykszta�cenie_wy�sze
				from dane_edukacj
				group by party, votes, osoby_wykszta�cenie_wy�sze_stan
				order by procent_wykszta�cenie_wy�sze)m
	where party = 'Democrat')
select distinct  
dem.procent_wykszta�cenie_wy�sze, 
liczba_g�_republikanie, 
liczba_g�_demokraci, 
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep 
join dem 
on dem.procent_wykszta�cenie_wy�sze= rep.procent_wykszta�cenie_wy�sze

select *
from v_obliczenia_iv_wy�sze_stan_;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_obliczenia_iv_wy�sze_stan_ /*�redni predyktor (do�� mocny) - 0.286*/

/*list of states - usabel to show in map*/

with stany as
	(select  state, party, procent_wykszta�cenie_wy�sze 
		from
		(select  distinct 
			state, 
			party,
			case 
				when osoby_wykszta�cenie_wy�sze_stan < 15 then '0 - 15 %'
				when osoby_wykszta�cenie_wy�sze_stan < 17 then '15 - 17 %'
				when osoby_wykszta�cenie_wy�sze_stan < 19 then '17 - 19 %'
				when osoby_wykszta�cenie_wy�sze_stan < 21 then '19 - 21 %'
				when osoby_wykszta�cenie_wy�sze_stan  < 23 then '21 - 23 %'
				when osoby_wykszta�cenie_wy�sze_stan  < 25 then '23 - 25 %'
				else 'powy�ej 25%'
			end as procent_wykszta�cenie_wy�sze
			from dane_edukacj)x) 
select  
state, 
party, 
stany.procent_wykszta�cenie_wy�sze,
liczba_g�_republikanie,
liczba_g�_demokraci
from stany
join v_obliczenia_iv_wy�sze_stan_ vos
on stany.procent_wykszta�cenie_wy�sze = vos.procent_wykszta�cenie_wy�sze 



/*No education*/


select 
procent_brak_wykszta�cenia,  
count(*) 
from 
	(select distinct 
		county, 
		state,
		case 
			when brak_wykszta�cenia_hr < 10 then '0 - 10 %'
			when brak_wykszta�cenia_hr < 15 then '10 - 15 %'
			when brak_wykszta�cenia_hr < 20 then '15 - 20 %'
			when brak_wykszta�cenia_hr < 25 then '20 - 25 %'
			else 'powy�ej 25%'
		end as procent_brak_wykszta�cenia
		from dane_edukacj)x
group by procent_brak_wykszta�cenia

/*WOE and IV*/
create view v_iv_brak_wyk_ as
with rep as
	(select distinct 
		party, 
		procent_brak_wykszta�cenia, 
		sum(votes) over (partition by party, procent_brak_wykszta�cenia) as liczba_g�_republikanie,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_rep 
		from
			(select 
				party, 
				votes, 
				case 
					when brak_wykszta�cenia_hr < 10 then '0 - 10 %'
					when brak_wykszta�cenia_hr < 15 then '10 - 15 %'
					when brak_wykszta�cenia_hr < 20 then '15 - 20 %'
					when brak_wykszta�cenia_hr < 25 then '20 - 25 %'
					else 'powy�ej 25%'
				end as procent_brak_wykszta�cenia
				from dane_edukacj
				group by party, votes, brak_wykszta�cenia_hr
				order by procent_brak_wykszta�cenia)m
		where party = 'Republican'),
dem as
	(select distinct 
		party, 
		procent_brak_wykszta�cenia, 
		sum(votes) over (partition by party, procent_brak_wykszta�cenia) as liczba_g�_demokraci,
		sum (votes) over (partition by party) as suma_ca�kowita_partia_dem 
		from
			(select 
				party, 
				votes, 
				case 
					when brak_wykszta�cenia_hr < 10 then '0 - 10 %'
					when brak_wykszta�cenia_hr < 15 then '10 - 15 %'
					when brak_wykszta�cenia_hr < 20 then '15 - 20 %'
					when brak_wykszta�cenia_hr < 25 then '20 - 25 %'
					else 'powy�ej 25%'
				end as procent_brak_wykszta�cenia
				from dane_edukacj
				group by party, votes, brak_wykszta�cenia_hr
				order by procent_brak_wykszta�cenia)m
		where party = 'Democrat')
select 
rep.procent_brak_wykszta�cenia, 
liczba_g�_republikanie, 
liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_brak_wykszta�cenia = dem.procent_brak_wykszta�cenia


select *
from v_iv_brak_wyk_ ;
select sum(dd_dr_woe) as information_value 
from v_iv_brak_wyk_ /*predyktor - 0.066*/











