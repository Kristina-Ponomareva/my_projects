--- 1. Select the 10 users who put in the most votes of the Close type.
SELECT user_id, COUNT(id)
FROM stackoverflow.votes
WHERE vote_type_id IN (SELECT id
                        FROM stackoverflow.vote_types
                        WHERE name = 'Close')
GROUP BY user_id
ORDER BY COUNT(id) DESC, user_id DESC; 

--- 2. Calculate the average score that each user's post receives.
SELECT title, user_id, score,
        ROUND(AVG(score) OVER (PARTITION BY user_id))
FROM stackoverflow.posts
WHERE title IS NOT NULL AND score != 0;

--- 3. Display the titles of posts written by users who have received more than 1000 badges.
SELECT title
FROM stackoverflow.posts
WHERE user_id IN (
            SELECT user_id
            FROM stackoverflow.badges
            GROUP BY user_id
            HAVING count(id) > 1000)
AND title IS NOT NULL;

--- 4. Retrieve data about users from the United States,
--- dividing them into three groups based on the number of profile views. 
--- Display the leaders of each group – users who have accumulated the maximum number of views within their respective groups.
WITH a  AS (SELECT *, 
        MAX(views) OVER (PARTITION BY rank) AS max_value
FROM (SELECT id, views, 
        CASE
            WHEN views < 100 THEN 3
            WHEN views < 350 THEN 2
            ELSE 1           
        END AS rank
FROM stackoverflow.users
WHERE location LIKE '%%United States%%' AND views > 0) AS info)

SELECT id, rank, views
FROM a
WHERE max_value = views
ORDER BY views DESC, id;

--- 4. For each user who has written at least one post, 
--- find the interval between the registration time and the time of creating their first post.
WITH a AS (SELECT DISTINCT user_id,
        FIRST_VALUE(creation_date) OVER (PARTITION BY user_id ORDER BY creation_date) AS first_post
FROM stackoverflow.posts)

SELECT a.user_id, 
         first_post - creation_date
FROM a
LEFT JOIN stackoverflow.users AS u ON a.user_id = u.id;

--- 5. Output the number of posts for the year 2008, categorized by months.
--- Select posts from users who registered in September 2008 and made at least one post in December of the same year.
SELECT CAST (DATE_TRUNC ('month' , creation_date) AS date),
        COUNT(id)
FROM stackoverflow.posts
WHERE user_id IN (SELECT u.id
FROM stackoverflow.users AS u
JOIN stackoverflow.posts AS p ON u.id = p.user_id
WHERE CAST (DATE_TRUNC ('month' , u.creation_date) AS date) = '2008-09-01' 
        AND CAST (DATE_TRUNC ('month' , p.creation_date) AS date) = '2008-12-01')
GROUP BY CAST (DATE_TRUNC ('month' , creation_date) AS date)
ORDER BY CAST (DATE_TRUNC ('month' , creation_date) AS date) DESC;

--- 6. Calculate the average number of days users interacted with the platform during the period from December 1st to December 7th, 2008, inclusive. 
--- For each user, select the days on which they published at least one post.
SELECT ROUND(AVG(days))
FROM ( SELECT user_id, COUNT(day) AS days
        FROM (SELECT DISTINCT user_id,
                creation_date::date AS day,
                  FIRST_VALUE(creation_date::date) OVER (PARTITION BY user_id,creation_date::date )
            FROM stackoverflow.posts
            WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07') t1
GROUP BY user_id) t2;

--- 7. For each user who has written at least one post, find the interval between the registration time and the time of creating their first post.
WITH a AS (SELECT DISTINCT user_id,
        FIRST_VALUE(creation_date) OVER (PARTITION BY user_id ORDER BY creation_date) AS first_post
FROM stackoverflow.posts)

SELECT a.user_id, 
         first_post - creation_date
FROM a
LEFT JOIN stackoverflow.users AS u ON a.user_id = u.id;

--- 8. Retrieve the activity data for the user who posted the most in October 2008.
SELECT EXTRACT (WEEK FROM creation_date), MAX(creation_date)
FROM stackoverflow.posts
WHERE user_id IN (SELECT user_id
                    FROM stackoverflow.posts
                    GROUP BY user_id
                    ORDER BY  COUNT(id) DESC
                    LIMIT 1)
AND CAST (DATE_TRUNC ('month', creation_date) AS date) = '2008-10-01'
GROUP BY EXTRACT (WEEK FROM creation_date);

--- 9. What percentage changed each month between September 1st and December 31st, 2008?
SELECT *, 
        ROUND((((posts::numeric) /  LAG(posts) OVER (ORDER BY month) *100)-100),2)
FROM (SELECT EXTRACT(MONTH FROM creation_date) AS month, 
        COUNT(id) posts
FROM stackoverflow.posts
WHERE CAST (DATE_TRUNC ('day' , creation_date) AS date) BETWEEN '2008-09-01' AND '2008-12-31'
GROUP BY EXTRACT(MONTH FROM creation_date)) t1;

--- 10. Select 10 users by the number of badges received between November 15 and December 15, 2008 inclusive.
WITH a AS (SELECT user_id, COUNT(id) AS badges
FROM stackoverflow.badges
WHERE creation_date:: date BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY user_id)
SELECT *,
        DENSE_RANK() OVER (ORDER BY badges DESC)
FROM a
LIMIT 10;
