WITH order_count_per_customer AS (
    SELECT 
        customer_id,
		COUNT(DISTINCT order_id) AS order_count,
		COUNT(DISTINCT CASE WHEN status IN ('Completed', 'Refunded') THEN order_id END) AS NC_order

FROM orders
GROUP BY customer_id
)
-- repeat rate computation
SELECT 
    c.channel,
    COUNT(occ.customer_id) AS total_customers,
    COUNT(CASE WHEN occ.order_count > 1 THEN occ.customer_id END) AS repeat_customer,		
    ROUND(COUNT(CASE WHEN occ.order_count > 1 THEN occ.customer_id END) / COUNT(occ.customer_id) * 100.00,2) AS All_order_RR,		
    ROUND(COUNT(CASE WHEN occ.NC_order > 1 THEN occ.customer_id END)/ COUNT(occ.customer_id) * 100.00,2) AS NC_Order_RR
	

FROM order_count_per_customer occ
JOIN customers c
    ON occ.customer_id = c.customer_id

GROUP BY c.channel
ORDER BY All_order_RR desc;


-- Percentage of yearly signups coming from Paid Social
SELECT YEAR(SIGNUP_DATE),
    count(signup_date) as total_signups,
    COUNT(CASE WHEN CHANNEL = 'Paid Social' then customer_id end) as customer_signups,
    round(COUNT(CASE WHEN CHANNEL = 'Paid Social' then customer_id end)/count(signup_date)*100.00,2) as signup_paid_social_percentage
from customers
group by YEAR(SIGNUP_DATE);

