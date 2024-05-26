drop table if exists happiness;
create table if not exists happiness
(
    country           varchar(255) not null,
    region            varchar(255) not null,
    happiness_rank    int          not null,
    happiness_score   float        not null,
    standard_error    float        not null,
    economy           float        not null,
    family            float        not null,
    health            float        not null,
    freedom           float        not null,
    trust             float        not null,
    generosity        float        not null,
    dystopia_residual float        not null
);


####################################
############ Problem 01 ############
####################################

# average of happiness score
select avg(happiness_score) as avg_happiness_score
from happiness;

# average of economy
select avg(economy) as avg_economy
from happiness;

# maximum of all columns
select happiness_score as max_happiness_score, country
from happiness
where happiness_score in (select max(happiness_score) from happiness);

select economy as max_economy, country
from happiness
where economy in (select max(economy) from happiness);

select family as max_family, country
from happiness
where family in (select max(family) from happiness);

select health as max_health, country
from happiness
where health in (select max(health) from happiness);

select freedom as max_freedom, country
from happiness
where freedom in (select max(freedom) from happiness);

select trust as max_trust, country
from happiness
where trust in (select max(trust) from happiness);

select generosity as max_generosity, country
from happiness
where generosity in (select max(generosity) from happiness);

select dystopia_residual as max_dystopia_residual, country
from happiness
where dystopia_residual in (select max(dystopia_residual) from happiness);

# median of happiness score
select avg(mid_val) as median
from (select x.happiness_score as mid_val
      from (select @row_num := @row_num + 1 as row_num, happiness_score
            from happiness,
                 (select @row_num := 0) r
            order by happiness_score) x,
           (select count(*) as total_rows
            from happiness) total
      where x.row_num in (floor((total_rows + 1) / 2), floor((total_rows + 2) / 2))) mid;


# upper and lower quartiles of happiness score
select avg(mid_val) as lower_quartile
from (select x.happiness_score as mid_val
      from (select @row_num := @row_num + 1 as row_num, happiness_score
            from happiness,
                 (select @row_num := 0) r
            order by happiness_score) x,
           (select count(*) as total_rows
            from happiness) total
      where x.row_num in (floor((total_rows + 1) / 4), floor((total_rows + 2) / 4))) mid;

select avg(mid_val) as upper_quartile
from (select x.happiness_score as mid_val
      from (select @row_num := @row_num + 1 as row_num, happiness_score
            from happiness,
                 (select @row_num := 0) r
            order by happiness_score) x,
           (select count(*) as total_rows
            from happiness) total
      where x.row_num in (floor((total_rows + 1) / 4 * 3), floor((total_rows + 2) / 4 * 3))) mid;


# standard deviation of happiness score
select sqrt(avg(happiness_score * happiness_score) - avg(happiness_score) * avg(happiness_score)) as standard_deviation
from happiness;


# variance of happiness score
select avg(happiness_score * happiness_score) - avg(happiness_score) * avg(happiness_score) as variance
from happiness;


# distribution of happiness score
select '2-3' as happiness_score_range, count(*) as number_of_countries
from happiness
where happiness_score between 2 and 3
union
select '3-4' as happiness_score_range, count(*) as number_of_countries
from happiness
where happiness_score between 3 and 4
union
select '4-5' as happiness_score_range, count(*) as number_of_countries
from happiness
where happiness_score between 4 and 5
union
select '5-6' as happiness_score_range, count(*) as number_of_countries
from happiness
where happiness_score between 5 and 6
union
select '6-7' as happiness_score_range, count(*) as number_of_countries
from happiness
where happiness_score between 6 and 7
union
select '7-8' as happiness_score_range, count(*) as number_of_countries
from happiness
where happiness_score between 7 and 8;



####################################
############ Problem 02 ############
####################################

# max-min normalization
select country,
       region,
       happiness_rank,
       (happiness_score - (select min(happiness_score) from happiness)) /
       ((select max(happiness_score) from happiness) -
        (select min(happiness_score) from happiness))                                                     as normalized_happiness_score,
       (economy - (select min(economy) from happiness)) / ((select max(economy) from happiness) -
                                                           (select min(economy) from happiness))          as normalized_economy,
       (family - (select min(family) from happiness)) / ((select max(family) from happiness) -
                                                         (select min(family) from happiness))             as normalized_family,
       (health - (select min(health) from happiness)) / ((select max(health) from happiness) -
                                                         (select min(health) from happiness))             as normalized_health,
       (freedom - (select min(freedom) from happiness)) / ((select max(freedom) from happiness) -
                                                           (select min(freedom) from happiness))          as normalized_freedom,
       (trust - (select min(trust) from happiness)) / ((select max(trust) from happiness) -
                                                       (select min(trust) from happiness))                as normalized_trust,
       (generosity - (select min(generosity) from happiness)) / ((select max(generosity) from happiness) -
                                                                 (select min(generosity) from happiness)) as normalized_generosity,
       (dystopia_residual - (select min(dystopia_residual) from happiness)) /
       ((select max(dystopia_residual) from happiness) -
        (select min(dystopia_residual) from happiness))                                                   as normalized_dystopia_residual
from happiness;

# z-score normalization
set @avg_happiness_score = (select avg(happiness_score)
                            from happiness);
set @avg_economy = (select avg(economy)
                    from happiness);
