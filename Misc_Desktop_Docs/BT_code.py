count = 0
for beg in pd.date_range('2020-01-01', '2021-02-28', freq='MS'):
    start_date = beg.strftime("%Y-%m-%d")
    end_date = (beg + MonthEnd(1)).strftime("%Y-%m-%d")
    print('Start date of the month-',start_date)
    print('End date of the month-',end_date)
    
    if (count==0):
        count = count + 1
        q = """Call pp_monitor.drop_table('pp_scratch.BT_LP_data');
        create multiset table pp_scratch.BT_LP_data
        as
        (
        with bt_data as (
        select 
        entity_id,
        prnt_sf_acct_name,
        merch_seg,
        fpa_rev_lvl3,
        (extract(year from min((lead_pass_assigned_dt))) - 1900)*12 + extract(month from min((lead_pass_assigned_dt))) lead_pass_mnth,
        (extract(year from min((TGT_LTS_DT))) - 1900)*12 + extract(month from min((TGT_LTS_DT))) revenue_mnth                
        from pp_oap_summry_t.jmr_lead_pass_new
        where lead_pass_assigned_dt between '2020-01-01' and '2021-02-28'
        and TGT_LTS_DT between '2020-01-01' and '2021-12-31'
        --and ENTITY_ID = '0012E00001iClp3QAC'
        and snapshot_hist_dt = (sel max(snapshot_hist_dt) from pp_oap_summry_t.jmr_lead_pass_new)
        group by 1,2,3,4),
        bt_entity_cust_id as (
        select 
        b.CUST_ID,
        a.*
        from bt_data a
        inner join pp_ent_anlytcs_views.Dim_Busn_Type_Merch_snap b
        on a.entity_id = b.entity_id
        where mth_id = ((EXTRACT(YEAR FROM CURRENT_DATE)-1900)*12)+EXTRACT(MONTH FROM CURRENT_DATE) - 1
        )
        select
        a.*,
        --time data
        dim.mth_id,
        dim.year_id AS year_id,
        
        --Product flows & groups 
        'Braintree FS' AS  peak_product_grp, --products groups from peak,
        'Braintree FS' AS essbase_product_grp, --products groups to match essbase,
        'Braintree FS' AS l1_products_grp, --products groups (level 1),
        'Braintree FS' AS l2_products_grp, -- products groups (level 2),
        
        coalesce(SUM(b.NTPV_PLN_USD_AMT),0.0) AS tpv,
        coalesce(SUM(b.NET_REV_PLN_USD_EST),0.0) AS seller_fee
        
        from bt_entity_cust_id as a
        
        join PP_ENT_ANLYTCS_VIEWS.FACT_BT_FIN_DLY_SNAP as b
        ON a.cust_id = b.Merch_Acct_ID
        
        JOIN pp_discovery_views.dim_calendar_day AS dim 
        ON b.cal_dt = dim.cal_dt
        
        where dim.cal_dt between '"""+start_date+"""' and '"""+end_date+"""' 
        and b.cal_dt BETWEEN  '"""+start_date+"""' and '"""+end_date+"""'
        AND LOWER(b.PMT_TYP) not in ('paypalheredetail','paypaldetail')
        group by 1,2,3,4,5,6,7,8,9,10,11,12
        ) with data unique primary index (CUST_ID,peak_product_grp,essbase_product_grp,
        l1_products_grp,mth_id,l2_products_grp,year_id)
        
        """

        %teradata_simba $q
    
    else: 
        q = """Insert into pp_scratch.BT_LP_data
        with bt_data as (
        select 
        entity_id,
        prnt_sf_acct_name,
        merch_seg,
        fpa_rev_lvl3,
        (extract(year from min((lead_pass_assigned_dt))) - 1900)*12 + extract(month from min((lead_pass_assigned_dt))) lead_pass_mnth,
        (extract(year from min((TGT_LTS_DT))) - 1900)*12 + extract(month from min((TGT_LTS_DT))) revenue_mnth                
        from pp_oap_summry_t.jmr_lead_pass_new
        where lead_pass_assigned_dt between '2020-01-01' and '2021-02-28'
        and TGT_LTS_DT between '2020-01-01' and '2021-12-31'
        --and ENTITY_ID = '0012E00001iClp3QAC'
        and snapshot_hist_dt = (sel max(snapshot_hist_dt) from pp_oap_summry_t.jmr_lead_pass_new)
        group by 1,2,3,4),
        bt_entity_cust_id as (
        select 
        b.CUST_ID,
        a.*
        from bt_data a
        inner join pp_ent_anlytcs_views.Dim_Busn_Type_Merch_snap b
        on a.entity_id = b.entity_id
        where mth_id = ((EXTRACT(YEAR FROM CURRENT_DATE)-1900)*12)+EXTRACT(MONTH FROM CURRENT_DATE) - 1
        )
        select
        a.*,
        --time data
        dim.mth_id,
        dim.year_id AS year_id,
        
        --Product flows & groups 
        'Braintree FS' AS  peak_product_grp, --products groups from peak,
        'Braintree FS' AS essbase_product_grp, --products groups to match essbase,
        'Braintree FS' AS l1_products_grp, --products groups (level 1),
        'Braintree FS' AS l2_products_grp, -- products groups (level 2),
        
        coalesce(SUM(b.NTPV_PLN_USD_AMT),0.0) AS tpv,
        coalesce(SUM(b.NET_REV_PLN_USD_EST),0.0) AS seller_fee
        from bt_entity_cust_id as a
        join PP_ENT_ANLYTCS_VIEWS.FACT_BT_FIN_DLY_SNAP as b
        ON a.cust_id = b.Merch_Acct_ID
        
        JOIN pp_discovery_views.dim_calendar_day AS dim 
        ON b.cal_dt = dim.cal_dt
        
        where dim.cal_dt between '"""+start_date+"""' and '"""+end_date+"""' 
        and b.cal_dt BETWEEN  '"""+start_date+"""' and '"""+end_date+"""'
        AND LOWER(b.PMT_TYP) not in ('paypalheredetail','paypaldetail')
        group by 1,2,3,4,5,6,7,8,9,10,11,12
        
        """
        %teradata_simba $q
    print("Query Ended - Please check the Data")
    
    # PayPal data
    SELECT 
a.cust_id, 
a.entity_id,
a.entity_name,
a.sales_seg,
a.acct_id_src,
a.cntry_code,
a.sub_market,
a.market,
a.sales_seg_name,
a.merch_seg,
Cast('#n/a' AS VARCHAR(20))  AS acquirers_bt,

-- time frame
dim.wk_id, 
dim.retail_wk_end_dt AS retail_wk_end_dt, 
dim.mth_id  AS mth_id,
dim.mth_mon_yyyy_name AS mth_name, 
dim.year_id AS year_id,	

--Product flows & groups 
prod_hier_desc AS  peak_product_grp, --products groups from peak 	
	CASE 
		WHEN flow_fmly_desc  = 'MS FF PayPal Here'  THEN Cast('MS FF PayPal Here'  AS VARCHAR(30))
		WHEN prod_hier_desc  =  'MS Others' THEN 'MS_Core_Others'
		WHEN prod_hier_desc  =  'P2P-F&F' THEN 'P2P_F&F'
		WHEN prod_hier_desc  =  'P2P-G&S' THEN 'P2P_G&S'
		ELSE prod_hier_desc 
	end essbase_product_grp, --products groups to match essbase
	CASE 
		WHEN prod_hier_desc  IN ( 'MS EC Recurring', 'MS EC Non Recurring','WPS Recurring', 'WPS Non Recurring') THEN 'Branded Checkout' 
		WHEN prod_hier_desc  IN ( 'P2P-F&F', 'P2P-G&S', 'Invoicing') THEN 'Email Payments' 
		WHEN prod_hier_desc  IN ( 'Pro DCC', 'MS Unbranded Others') THEN 'Unbranded Checkout' 
		WHEN prod_hier_desc  IN ( 'eBay', 'PPFM') THEN 'Market Places' 
		ELSE prod_hier_desc  
	end AS l1_products_grp, --products groups (level 1)
	CASE 
		WHEN prod_hier_desc  IN ( 'MS EC Recurring', 'MS EC Non Recurring') THEN 'Branded Checkout - EC' 
		WHEN prod_hier_desc  IN ( 'WPS Recurring', 'WPS Non Recurring') THEN 'Branded Checkout - WPS' 
		WHEN prod_hier_desc  IN ( 'P2P-F&F') THEN 'Send & Request Money - F&F' 
		WHEN prod_hier_desc  IN ( 'P2P-G&S') THEN 'Send & Request Money - G&S' 
		WHEN prod_hier_desc  IN ( 'Pro DCC') THEN 'Pro DCC' 
		WHEN flow_fmly_desc  IN ('MS FF Hosted Sole Solution') THEN 'HSS'    
		WHEN flow_fmly_desc  IN ('MS FF PayPal Plus') THEN 'PP Plus'    
		WHEN flow_fmly_desc  IN ('MS FF Virtual Terminal') THEN 'VT'    
		WHEN flow_fmly_desc  = 'MS FF PayPal Here'  THEN 'PayPal Here'
		WHEN prod_hier_desc  = 'Retail' THEN 'POS'
		ELSE prod_hier_desc  
	end AS l2_products_grp, -- products groups (level 2)

--sender cntry
b.sndr_cntry_code,
trade_flow AS  cross_brdr_pmt_flag,  --> cast for 3 letters atleast
is_mobile_pmt_y_n AS mobile_pmt_y_n ,	--> cast for 3 letters atleast 
b.prtnr_name,
b.prtnr_y_n,   

-- Revenue rptg side 	
'R' AS rev_payer_flag, 

Sum(ntpv_pln_usd_amt) AS rtpv,      
Sum(net_ch_fmx_pp_cr_pln_usd_amt) AS ppc_rtpv,   
Sum(net_cnt) AS rtxns,    	
Sum(net_rev_tot_fx_rcv_pln_usd_amt +  net_calc_ba_rev_pln_usd_amt +  net_rev_pmt_tot_xb_pln_usd_amt + other_net_rev_pln_usd_amt) AS rrevenue ,   
Sum(net_calc_ba_rev_pln_usd_amt) AS rrev_ba,    
Sum(net_rev_pmt_tot_xb_pln_usd_amt ) AS rrev_xb,    
Sum(net_rev_tot_fx_rcv_pln_usd_amt) AS rrev_fx,    
Sum(other_net_rev_pln_usd_amt) AS rrev_other, 	 
Sum(ach_cost_pln_usd_amt + cc_cost_pln_usd_amt) AS rexpense,    
Sum(net_atc_pp_loss_pln_usd_amt) AS rloss,    
rrevenue + rexpense + rloss AS rmargin	

FROM pp_oap_anchhabra_t.global_all_Base AS a
JOIN pp_ent_anlytcs_views.fact_rcvr_cohort_pmt_dly AS b
ON a.cust_id = b.rcvr_id
JOIN pp_discovery_views.dim_calendar_day AS dim  
ON b.cal_dt = dim.cal_dt
WHERE  b.prod_hier_desc <> 'Multi-Tenant' 
AND b.cal_dt BETWEEN '2020-01-01' AND '2020-03-31'
AND dim.cal_dt BETWEEN '2020-01-01' AND '2020-03-31'
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26