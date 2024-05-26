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
set @avg_family = (select avg(family)
                   from happiness);
set @avg_health = (select avg(health)
                   from happiness);
set @avg_freedom = (select avg(freedom)
                    from happiness);
set @avg_trust = (select avg(trust)
                  from happiness);
set @avg_generosity = (select avg(generosity)
                       from happiness);
set @avg_dystopia_residual = (select avg(dystopia_residual)
                              from happiness);

set @std_dev_happiness_score =
        (select sqrt(avg(happiness_score * happiness_score) - avg(happiness_score) * avg(happiness_score))
         from happiness);
set @std_dev_economy = (select sqrt(avg(economy * economy) - avg(economy) * avg(economy))
                        from happiness);
set @std_dev_family = (select sqrt(avg(family * family) - avg(family) * avg(family))
                       from happiness);
set @std_dev_health = (select sqrt(avg(health * health) - avg(health) * avg(health))
                       from happiness);
set @std_dev_freedom = (select sqrt(avg(freedom * freedom) - avg(freedom) * avg(freedom))
                        from happiness);
set @std_dev_trust = (select sqrt(avg(trust * trust) - avg(trust) * avg(trust))
                      from happiness);
set @std_dev_generosity = (select sqrt(avg(generosity * generosity) - avg(generosity) * avg(generosity))
                           from happiness);
set @std_dev_dystopia_residual = (select sqrt(avg(dystopia_residual * dystopia_residual) - avg(dystopia_residual) *
                                                                                           avg(dystopia_residual))
                                  from happiness);


select country,
       region,
       happiness_rank,
       (happiness_score - @avg_happiness_score) / @std_dev_happiness_score       as z_score_happiness_score,
       (economy - @avg_economy) / @std_dev_economy                               as z_score_economy,
       (family - @avg_family) / @std_dev_family                                  as z_score_family,
       (health - @avg_health) / @std_dev_health                                  as z_score_health,
       (freedom - @avg_freedom) / @std_dev_freedom                               as z_score_freedom,
       (trust - @avg_trust) / @std_dev_trust                                     as z_score_trust,
       (generosity - @avg_generosity) / @std_dev_generosity                      as z_score_generosity,
       (dystopia_residual - @avg_dystopia_residual) / @std_dev_dystopia_residual as z_score_dystopia_residual
from happiness;



####################################
############ Problem 03 ############
####################################

set @row_num = (select count(*)
                from happiness);


set @max_economy = (select max(economy)
                    from happiness);
set @min_economy = (select min(economy)
                    from happiness
                    where economy != 0);
update happiness
set economy = (select (@max_economy - @min_economy) * happiness_rank / @row_num + @min_economy)
where economy = 0;


set @max_family = (select max(family)
                   from happiness);
set @min_family = (select min(family)
                   from happiness
                   where family != 0);
update happiness
set family = (select (@max_family - @min_family) * happiness_rank / @row_num + @min_family)
where family = 0;


set @max_health = (select max(health)
                   from happiness);
set @min_health = (select min(health)
                   from happiness
                   where health != 0);
update happiness
set health = (select (@max_health - @min_health) * happiness_rank / @row_num + @min_health)
where health = 0;


set @max_freedom = (select max(freedom)
                    from happiness);
set @min_freedom = (select min(freedom)
                    from happiness
                    where freedom != 0);
update happiness
set freedom = (select (@max_freedom - @min_freedom) * happiness_rank / @row_num + @min_freedom)
where freedom = 0;


set @max_trust = (select max(trust)
                  from happiness);
set @min_trust = (select min(trust)
                  from happiness
                  where trust != 0);
update happiness
set trust = (select (@max_trust - @min_trust) * happiness_rank / @row_num + @min_trust)
where trust = 0;


set @max_generosity = (select max(generosity)
                       from happiness);
set @min_generosity = (select min(generosity)
                       from happiness
                       where generosity != 0);
update happiness
set generosity = (select (@max_generosity - @min_generosity) * happiness_rank / @row_num + @min_generosity)
where generosity = 0;


set @max_dystopia_residual = (select max(dystopia_residual)
                              from happiness);
set @min_dystopia_residual = (select min(dystopia_residual)
                              from happiness
                              where dystopia_residual != 0);
update happiness
set dystopia_residual = (select (@max_dystopia_residual - @min_dystopia_residual) * happiness_rank / @row_num +
                                @min_dystopia_residual)
where dystopia_residual = 0;
