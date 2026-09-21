-- Setting up charge_count buckets
WITH CHARGES_PER_MEMBER AS ( 
SELECT 
	MEMBER_ID,
	COUNT(CHARGE_ID) AS CHARGE_COUNT,
	COUNT(CASE WHEN STATUS IN ('Success','Refunded') THEN CHARGE_ID END) AS NC_CHARGE_COUNT
FROM CHARGES
GROUP BY MEMBER_ID)


-- finding repeat rate percentage for each category
SELECT 
	M.PLAN_TYPE,
	COUNT(CPM.MEMBER_ID) AS TOTAL_MEMBERS,
    COUNT(CASE WHEN CPM.CHARGE_COUNT >1 THEN CPM.MEMBER_ID END) AS REPEAT_CUSTOMERS,
    ROUND(COUNT(CASE WHEN CHARGE_COUNT >1 THEN CPM.MEMBER_ID END)/COUNT(CPM.MEMBER_ID)*100.00,2) AS REPEAT_RATE,
    ROUND(COUNT(CASE WHEN NC_CHARGE_COUNT >1 THEN CPM.MEMBER_ID END)/COUNT(CPM.MEMBER_ID)*100.00,2)  AS NC_REPEAT_RATE
FROM CHARGES_PER_MEMBER CPM
JOIN MEMBERS M 
ON CPM.MEMBER_ID = M.MEMBER_ID 
GROUP BY M.PLAN_TYPE;


-- signup comparison for trail plan
SELECT 
	YEAR(SIGNUP_DATE) AS YEARS,
	COUNT(SIGNUP_DATE) AS TOTAL_SIGNUPS,
    COUNT(CASE WHEN PLAN_TYPE = 'Trial' then signup_date end) as trail_signups,
	round(COUNT(CASE WHEN PLAN_TYPE = 'Trial' then signup_date end)/COUNT(SIGNUP_DATE)*100.00,2) as trail_signup_conversion
FROM MEMBERS
GROUP BY YEARS
order by years; 	



-- cancelled vs failed charges for trail plantype
SELECT 
    c.status,
    count(c.charge_id) AS Charge_count
FROM charges c
JOIN members m 
    ON c.member_id = m.member_id
WHERE m.plan_type = 'Trial'
GROUP BY  c.status
having c.status in ('Cancelled','Failed')
order by c.status;

-- cancelled vs failed charges for premium and basic plantype
SELECT 
    c.status,
    count(case when m.plan_type = 'Premium' then c.charge_id end ) AS Premium_Charge_count,
    count(case when m.plan_type = 'Basic' then c.charge_id end) as basic_charge_count
FROM charges c
JOIN members m 
    ON c.member_id = m.member_id
WHERE m.plan_type in ('Premium','Basic')
GROUP BY  c.status
having c.status in ('Cancelled','Failed')
order by c.status;

select distinct(plan_type) from members;
    