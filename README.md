# Netflix Movies and TV Shows Data Analysis using SQL

![](https://github.com/najirh/netflix_sql_project/blob/main/logo.png)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
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
```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql

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

```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
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
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
select title from netflix
where type = 'Movie' and
release_year = 2020;
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
select 
unnest(string_to_array(country, ',')) "New Country", -- To convert string to array where multiple countries were in a single string
count(*) as "Most Content"  
	from netflix
	group by 1 
	order by 2 desc
	limit 5;
```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
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

```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
select * , to_date(date_added, 'Month DD, YYYY') -- extracting date format
from netflix
where to_date(date_added, 'Month DD, YYYY')  >= current_date - interval '5 years';
```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
SELECT *
FROM (
    SELECT 
        *,
        UNNEST(STRING_TO_ARRAY(director, ',')) AS director_name
    FROM netflix
) AS t
WHERE director_name = 'Rajiv Chilaka';

--oR

select * from netflix 
where director like '%Rajiv Chilaka%';


```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql

select * , (SPLIT_PART(duration, ' ', 1):: numeric ) AS seasonss 
from netflix
where SPLIT_PART(duration, ' ', 1):: numeric  >= 5 and type = 'TV Show';
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
select 
unnest(string_to_array(listed_in, ',')) "Genre", -- To convert string to array where multiple genre were in a single string
count(*) as "Most Content"  
	from netflix
	group by 1 ;
```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

```sql
select
country,extract(year from to_date(date_added, 'Month DD, YYYY')) "Year"
,count(*) as "Most Content"  , 
round(count(*)::numeric/(select count(*) from netflix where country = 'India') *100,2) as  "Avg_content_per_Year" -- converted to numeric for cal
	from netflix
	where country = 'India'
	group by 1,2
	order by 4 desc
	limit 5;
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql

select * from netflix 
where listed_in ilike '%documentaries%'

```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql

select * from netflix where director is null;

```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
select casts , type, count(*) from netflix
where casts ilike '%Salman Khan%'
and release_year > extract(year from current_date) - 10
group by 1,2;
```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql

select unnest(string_to_array(casts, ',')) "Actors" , count(*) "Movie Counts"
from netflix
where  country ilike '%India%'
group by 1
order by 2 desc limit 10;

```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
with cte as 
(
select * , (case when description ilike '%kill%' or description ilike '%violence%' then 'Bad_Content'
else 'Good_Content' end) as category from netflix
)
select category , count(*) "Count" 
from cte 
group by 1

```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.



## Author - Nitin Singh

This project is part of my portfolio, showcasing the SQL skills essential for data analyst roles. If you have any questions, feedback, or would like to collaborate, feel free to get in touch!

### Stay Updated and Join the Community

For more content on SQL, data analysis, and other data-related topics, make sure to follow me on social media and join our community:

- **LinkedIn**: [Connect with me professionally](https://www.linkedin.com/in/nitin-a-singh/)


Thank you for your support, and I look forward to connecting with you!
