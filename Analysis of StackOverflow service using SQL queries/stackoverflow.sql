--- 1. Select the 10 users who put in the most votes of the Close type.
SELECT user_id, COUNT(id)
FROM stackoverflow.votes
WHERE vote_type_id IN (SELECT id
                        FROM stackoverflow.vote_types
                        WHERE name = 'Close')
GROUP BY user_id
ORDER BY COUNT(id) DESC, user_id DESC; 
