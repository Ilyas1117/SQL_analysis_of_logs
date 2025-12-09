SELECT * FROM LOGIN_LOGS LIMIT 5000

ALTER TABLE LOGIN_LOGS
ADD COLUMN device_type VARCHAR,
ADD COLUMN ip_group VARCHAR;

UPDATE LOGIN_LOGS
SET device_type = CASE
    WHEN user_agent LIKE '%Android%' THEN 'Android'
    WHEN user_agent LIKE '%iPhone%' THEN 'iPhone'
    WHEN user_agent LIKE '%iPad%' THEN 'iPad'
    WHEN user_agent LIKE '%Windows NT%' THEN 'Windows PC'
    WHEN user_agent LIKE '%Macintosh%' THEN 'Mac'
    WHEN user_agent LIKE '%Linux%' THEN 'Linux PC'
    ELSE 'Other'
END;

UPDATE LOGIN_LOGS
SET ip_group = SUBSTRING_INDEX(ip_address, '.', 1);



-- Users count
SELECT 
	COUNT(DISTINCT user_id) 
FROM LOGIN_LOGS

-- Every user attempt , success/failure
SELECT 
    user_id,
    COUNT(*) AS count_u,
    COUNT(CASE WHEN login_status = 1 THEN 1 END) AS log_true_count,
    COUNT(CASE WHEN login_status = 0 THEN 1 END) AS log_false_count
FROM LOGIN_LOGS
GROUP BY user_id
ORDER BY count_u DESC
LIMIT 10;

-- Ip_group unique device count
SELECT
	ip_group , COUNT(DISTINCT user_ip) as count_ip
FROM LOGIN_LOGS 
GROUP BY ip_group
ORDER BY count_ip DESC
LIMIT 10

-- Overall device counts,percentages per year from 2016 to 2024
SELECT 
	EXTRACT(YEAR FROM log_date) as year_date , 
	device_type , 
	COUNT(DISTINCT device_info) as device_count,
	SUM(COUNT(DISTINCT device_info)) OVER (PARTITION BY EXTRACT(YEAR FROM log_date))
	AS total_per_year,
    ROUND(
     COUNT(DISTINCT device_info) * 100.0 / SUM(COUNT(DISTINCT device_info)) 
		OVER (PARTITION BY EXTRACT(YEAR FROM log_date)),2
    ) AS percent_of_year
FROM LOGIN_LOGS
GROUP BY EXTRACT(YEAR FROM log_date) , device_type 
ORDER BY year_date , device_count

-- The classification of other category in devices 
SELECT 
	CASE 
	WHEN device_info like 'python%' then 'Python_scripts' 
	WHEN device_info like '%SDUPortal%' then 'SDU_app'
	ELSE 'Other'
	END as non_web_class,
	count(DISTINCT device_info) as device_count
FROM LOGIN_LOGS 
WHERE device_type = 'Other'
GROUP BY non_web_class
ORDER BY device_count DESC
	
-- The Device count for each ip 
SELECT ip_group , COUNT(DISTINCT device_info) as ip_count
FROM LOGIN_LOGS
GROUP BY ip_group
ORDER BY ip_count DESC
LIMIT 5


-- The device count of each user
SELECT 
    user_id,
    COUNT(DISTINCT device_info) AS num_devices
FROM LOGIN_LOGS
GROUP BY user_id
ORDER BY num_devices DESC
LIMIT 10;

-- Failed attemtps percentage for every device 
SELECT 
    device_type,
    COUNT(*) AS total_attempts,
    COUNT(CASE WHEN login_status = 0 THEN 1 END) AS failed_attempts,
    ROUND(COUNT(CASE WHEN login_status = 0 THEN 1 END) * 100.0 / COUNT(*), 2) AS fail_rate_percent
FROM LOGIN_LOGS
GROUP BY device_type
ORDER BY fail_rate_percent DESC;

-- Most common IPs per device type
WITH ranked_ips AS (
    SELECT
        device_type,
        ip_group,
        COUNT(*) AS login_count,
        ROW_NUMBER() OVER (PARTITION BY device_type ORDER BY COUNT(*) DESC) AS rn
    FROM LOGIN_LOGS
    GROUP BY device_type, ip_group
)
SELECT
    device_type,
    ip_group,
    login_count
FROM ranked_ips
WHERE rn <= 2
ORDER BY device_type, login_count DESC;

