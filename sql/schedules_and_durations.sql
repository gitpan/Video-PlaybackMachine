SELECT
	ID,
	TITLE,
	START_TIME,
	AVFILE_DURATION(TITLE) AS DURATION
FROM CONTENT_SCHEDULE
WHERE SCHEDULE='BayCon 2006'
LIMIT 10;
