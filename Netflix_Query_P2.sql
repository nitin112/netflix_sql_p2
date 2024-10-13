-- Netflix Project --

create table netflix
(  
	show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);

-- Basic EDA --

select * from netflix;

select count(1) "Total Content" from netflix;

select distinct type from netflix;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Business Questions/Problems --


-- 1. Count the number of Movies vs TV Shows

select type , count(*)"Total Count" from netflix 
group by 1;

-- or --
SELECT 
    type,
    COUNT(*) AS "Total Count",
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflix)), 2) AS "Percentage Distribution"
FROM 
    netflix
GROUP BY 
    type;


-- 2. Find the most common rating for movies and TV shows

SELECT 
    type, 
    rating, 
    t1.counts AS "Counts"
FROM 
    (
        SELECT 
            type, 
            rating, 
            COUNT(*) AS "counts", 
            RANK() OVER (PARTITION BY type ORDER BY COUNT(*) DESC) AS ranking
        FROM 
            netflix
        GROUP BY 
            type, rating
    ) AS t1
WHERE 
    ranking = 1;



-- 3. List all movies released in a specific year (e.g., 2020)

select title from netflix
	where type = 'Movie' and  release_year = 2020;

-- 4. Find the top 5 countries with the most content on Netflix

select 
unnest(string_to_array(country, ',')) "New Country", -- To convert string to array where multiple countries were in a single string
count(*) as "Most Content"  
	from netflix
	group by 1 
	order by 2 desc
	limit 5;

-- 5. Identify the longest movie

WITH duration_t AS (
    SELECT
        title,
        type,
        CAST(SPLIT_PART(duration, ' ', 1) AS INT) AS duration_minutes -- spliting number from text
    FROM 
        netflix
    WHERE
        type = 'Movie'
)
SELECT title,    duration_minutes
FROM duration_t
WHERE duration_minutes IS NOT NULL
ORDER BY duration_minutes DESC
LIMIT 1;

-- without CTE --

SELECT type , title, duration_minutes
FROM (
    SELECT 
        type, title, 
        CAST(SPLIT_PART(duration, ' ', 1) AS INT) AS duration_minutes
    FROM netflix
    WHERE type = 'Movie'
) AS duration_t
where duration_minutes is not null
ORDER BY duration_minutes DESC
LIMIT 1;



-- 6. Find content added in the last 5 years

select * , to_date(date_added, 'Month DD, YYYY') -- extracting date format
from netflix
where to_date(date_added, 'Month DD, YYYY')  >= current_date - interval '5 years';


-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!

select * from netflix 
where director like '%Rajiv Chilaka%';

-- 8. List all TV shows with more than 5 seasons

select * , (SPLIT_PART(duration, ' ', 1):: numeric ) AS seasonss 
from netflix
where SPLIT_PART(duration, ' ', 1):: numeric  >= 5 and type = 'TV Show';


-- 9. Count the number of content items in each genre

select 
unnest(string_to_array(listed_in, ',')) "Genre", -- To convert string to array where multiple genre were in a single string
count(*) as "Most Content"  
	from netflix
	group by 1 ;

-- 10.Find each year and the average numbers of content release in India on netflix. return top 5 year with highest avg content release!


select 
-- unnest(string_to_array(country, ',')) "Country",-- To convert string to array where multiple countries were in a single string
country,
extract(year from to_date(date_added, 'Month DD, YYYY')) "Year"
,count(*) as "Most Content"  , 
round(count(*)::numeric/(select count(*) from netflix where country = 'India') *100,2) as  "Avg_content_per_Year" -- converted to numeric for cal
	from netflix
	where country = 'India'
	group by 1,2
	order by 4 desc
	limit 5;


-- 11. List all movies that are documentaries

select * from netflix 
where listed_in ilike '%documentaries%'



-- 12. Find all content without a director

select * from netflix where director is null;


-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

select casts , type, count(*) from netflix
where casts ilike '%Salman Khan%'
--and release_year > extract(year from current_date) - 10
group by 1,2;


-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

select unnest(string_to_array(casts, ',')) "Actors" , count(*) "Movie Counts"
from netflix
where  country ilike '%India%'
group by 1
order by 2 desc limit 10;


--15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field.
--Label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category.

with cte as 
(
select * , (case when description ilike '%kill%' or description ilike '%violence%' then 'Bad_Content'
else 'Good_Content' end) as category from netflix
)
select category , count(*) "Count" 
from cte 
group by 1
