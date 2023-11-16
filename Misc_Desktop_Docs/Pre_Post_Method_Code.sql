%%teradata_simba
drop table pp_scratch.big_bet_camp2;
create table pp_scratch.big_bet_camp2 as 
(select cust_id,
 OPPRTNTY_ID,
 lead_src,
 OPPRTNTY_CLOSE_DATE,
 region,
 mth_id,
 opprtnty_close_mth_id as lts_mth_id,
 1 as mth_index,sum(tpv) as tpv,sum(revenue) as rev 
,Row_Number () Over (PARTITION BY cust_id ORDER BY mth_id) AS row_num
from pp_oap_asrajagopalan_t.big_bet_camp_res a 
 --where cust_id ='1857846674212228365'
group by 1,2,3,4,5,6,7,8)  with data unique primary index(cust_id,row_num)

%%teradata_simba
CALL pp_monitor.drop_table('pp_scratch.big_bet_camp3');
CREATE MULTISET TABLE pp_scratch.big_bet_camp3 AS
(
with temp as 
(SELECT 
cust_id,
OPPRTNTY_ID,
lead_src,
OPPRTNTY_CLOSE_DATE,
region,
lts_mth_id,
Min(mth_id) AS min_mth,
Max(mth_id) AS max_mth
FROM pp_scratch.big_bet_camp2
GROUP BY 1,2,3,4,5,6)
select a.*,
(lts_mth_id - min_mth) AS min_tenure,
(max_mth-lts_mth_id) AS max_tenure,
CASE WHEN min_tenure > max_tenure THEN max_tenure ELSE min_tenure end AS tenure
from temp a
) WITH DATA UNIQUE PRIMARY INDEX(cust_id);

%%teradata_simba
CALL pp_monitor.drop_table('pp_scratch.big_bet_camp4');
CREATE MULTISET TABLE pp_scratch.big_bet_camp4 AS
(
SELECT
a.CUST_ID,
    a.OPPRTNTY_ID,
    a.lead_src,
    a.OPPRTNTY_CLOSE_DATE,
    a.region,
    a.lts_mth_id,
    min_mth,
    max_mth,
    min_tenure,
    max_tenure,tenure,
Extract(DAY From Last_Day(a.OPPRTNTY_CLOSE_DATE)) AS last_day_of_lts_date_mth,
(Extract(DAY From a.OPPRTNTY_CLOSE_DATE)) AS LTS_day_of_mth,

Sum(CASE WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure = min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id - tenure AND a.lts_mth_id THEN a.mth_index
        WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure<>min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id - tenure + 1 AND a.lts_mth_id THEN a.mth_index
        WHEN (LTS_day_of_mth < last_day_of_lts_date_mth - 6) AND
            mth_id BETWEEN a.lts_mth_id - tenure AND a.lts_mth_id - 1 THEN a.mth_index ELSE 0 end) AS Month_Sum,

Sum(CASE WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure=min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id - tenure AND a.lts_mth_id THEN TPV
        WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure<>min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id - tenure + 1 AND a.lts_mth_id THEN TPV
        WHEN (LTS_day_of_mth < last_day_of_lts_date_mth - 6) AND
            mth_id BETWEEN a.lts_mth_id - tenure AND a.lts_mth_id - 1 THEN TPV ELSE 0 end) AS Pre_Tpv,
            
Sum(CASE WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure=min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id - tenure AND a.lts_mth_id THEN REV
        WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure<>min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id - tenure + 1 AND a.lts_mth_id THEN REV
        WHEN (LTS_day_of_mth < last_day_of_lts_date_mth - 6) AND
            mth_id BETWEEN a.lts_mth_id - tenure AND a.lts_mth_id - 1 THEN REV ELSE 0 end) AS Pre_REV,
            
Sum(CASE WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure=min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id-12 - tenure AND a.lts_mth_id-12 THEN a.mth_index
        WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure<>min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id-12 - tenure + 1 AND a.lts_mth_id-12 THEN a.mth_index
        WHEN (LTS_day_of_mth < last_day_of_lts_date_mth - 6) AND
            mth_id BETWEEN a.lts_mth_id-12 - tenure AND a.lts_mth_id-12 - 1 THEN a.mth_index ELSE 0 end) AS Month_Sum_365,
            
Sum(CASE WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure=min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id - tenure - 12 AND a.lts_mth_id - 12 THEN TPV
        WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure<>min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id - tenure + 1 - 12 AND a.lts_mth_id -12 THEN TPV
        WHEN (LTS_day_of_mth < last_day_of_lts_date_mth - 6) AND
            mth_id BETWEEN a.lts_mth_id - tenure - 12 AND a.lts_mth_id - 1 - 12 THEN TPV ELSE 0 end) AS Pre_Tpv_365,
            
Sum(CASE WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure=min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id - tenure -12 AND a.lts_mth_id - 12 THEN REV
        WHEN (LTS_day_of_mth >= last_day_of_lts_date_mth - 6) AND max_tenure<>min_tenure+1 AND
                mth_id BETWEEN a.lts_mth_id - tenure + 1 - 12 AND a.lts_mth_id - 12 THEN REV
        WHEN (LTS_day_of_mth < last_day_of_lts_date_mth - 6) AND
            mth_id BETWEEN a.lts_mth_id - tenure - 12 AND a.lts_mth_id - 1 - 12 THEN REV ELSE 0 end) AS Pre_REV_365

FROM pp_scratch.big_bet_camp2 AS a
JOIN pp_scratch.big_bet_camp3 AS b
ON a.cust_id = b.cust_id
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
) WITH DATA UNIQUE PRIMARY INDEX(cust_id);

%%teradata_simba
call pp_monitor.drop_table('pp_scratch.big_bet_camp5');
CREATE MULTISET TABLE pp_scratch.big_bet_camp5 AS
(
SELECT
a.CUST_ID,
    a.OPPRTNTY_ID,
    a.lead_src,
    a.OPPRTNTY_CLOSE_DATE,
    a.region,
    a.lts_mth_id,
    min_mth,
    max_mth,
    min_tenure,
    max_tenure,tenure,
Extract(DAY From Last_Day(a.OPPRTNTY_CLOSE_DATE)) AS last_day_of_lts_date_mth,
(Extract(DAY From a.OPPRTNTY_CLOSE_DATE)) AS LTS_day_of_mth,

Sum(CASE WHEN LTS_day_of_mth <= 7 AND min_tenure=max_tenure+1  AND (mth_id BETWEEN a.lts_mth_id AND Month_Sum + a.lts_mth_id ) THEN TPV
    WHEN lts_day_of_mth <= 7 AND min_tenure<>max_tenure+1 AND (mth_id BETWEEN a.lts_mth_id AND Month_Sum + a.lts_mth_id - 1)  THEN TPV
    WHEN LTS_day_of_mth > 7 AND (mth_id BETWEEN a.lts_mth_id + 1 AND Month_Sum + a.lts_mth_id ) THEN TPV
    ELSE 0 end) AS Post_Tpv,

Sum(CASE WHEN LTS_day_of_mth <= 7 AND min_tenure=max_tenure+1  AND (mth_id BETWEEN a.lts_mth_id AND Month_Sum + a.lts_mth_id ) THEN REV
    WHEN lts_day_of_mth <= 7 AND min_tenure<>max_tenure+1 AND (mth_id BETWEEN a.lts_mth_id AND Month_Sum + a.lts_mth_id - 1)  THEN REV
    WHEN LTS_day_of_mth > 7 AND (mth_id BETWEEN a.lts_mth_id + 1 AND Month_Sum + a.lts_mth_id ) THEN REV
    ELSE 0 end) AS Post_REV,

Sum(CASE WHEN LTS_day_of_mth <= 7 AND min_tenure=max_tenure+1  AND (mth_id BETWEEN a.lts_mth_id - 12 AND Month_Sum + a.lts_mth_id - 12 ) THEN TPV
    WHEN lts_day_of_mth <= 7 AND min_tenure<>max_tenure+1 AND (mth_id BETWEEN a.lts_mth_id - 12 AND Month_Sum + a.lts_mth_id - 12 - 1)  THEN TPV
    WHEN LTS_day_of_mth > 7 AND (mth_id BETWEEN a.lts_mth_id - 12 + 1 AND Month_Sum + a.lts_mth_id - 12 ) THEN TPV
    ELSE 0 end) AS Post_Tpv_365,

Sum(CASE WHEN LTS_day_of_mth <= 7 AND min_tenure=max_tenure+1  AND (mth_id BETWEEN a.lts_mth_id - 12 AND Month_Sum + a.lts_mth_id - 12) THEN REV
    WHEN lts_day_of_mth <= 7 AND min_tenure<>max_tenure+1 AND (mth_id BETWEEN a.lts_mth_id - 12 AND Month_Sum + a.lts_mth_id - 12 - 1)  THEN REV
    WHEN LTS_day_of_mth > 7 AND (mth_id BETWEEN a.lts_mth_id - 12 + 1 AND Month_Sum + a.lts_mth_id - 12 ) THEN REV
    ELSE 0 end) AS Post_REV_365

FROM pp_scratch.big_bet_camp2 AS a
JOIN pp_scratch.big_bet_camp4 AS b
ON a.cust_id = b.cust_id
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
) WITH DATA UNIQUE PRIMARY INDEX(cust_id);

%%teradata_simba
call pp_monitor.drop_table('pp_scratch.big_bet_camp6');
CREATE MULTISET TABLE pp_scratch.big_bet_camp6 AS
(
SELECT
a.CUST_ID,
    a.OPPRTNTY_ID,
    a.lead_src,
    a.OPPRTNTY_CLOSE_DATE,
    a.region,
    a.lts_mth_id,
    a.min_mth,
    a.max_mth,
    a.min_tenure,
    a.max_tenure,a.tenure,
a.Month_Sum
,a.Pre_Tpv
,a.Pre_rev
,a.last_day_of_lts_date_mth
,a.LTS_day_of_mth
,b.Post_Tpv
,b.Post_rev

,((b.post_tpv - a.pre_tpv)/NullIfZero(a.pre_tpv)) AS nominal_tpv_lift
,((b.post_rev - a.Pre_rev)/NullIfZero(a.Pre_rev)) AS nominal_rev_lift
--(nominal_tpv_lift/NullIfZero(b.post_tpv)) *100 as perc_incr_tpv,
--(nominal_rev_lift/b.post_rev) *100 as perc_incr_rev

FROM pp_scratch.big_bet_camp4 AS a
JOIN pp_scratch.big_bet_camp5 AS b
ON a.cust_id = b.cust_id

) WITH DATA UNIQUE PRIMARY INDEX(cust_id)