q = """select 
acct_id as sf_acct_id,
opprtnty_id, 
Opty_Target_Pdt
from PP_oap_anchhabra_t.ES_optys_2021_Target_Pdt
group by 1,2,3

"""
results = %teradata_simba $q
df =  results.DataFrame()

df['Opty_Target_Pdt'] = df['Opty_Target_Pdt'].str.strip()
df_acct = df[['sf_acct_id','Opty_Target_Pdt']]
df_acct = df_acct.dropna() #removing missing products categories
df_acct = df.drop_duplicates() #removing duplicate records

df_acct[df_acct['sf_acct_id'] =='0018000001Ab4zwAAB']

# Link existing flows/products and target products to Product Families and Feature Categories
product_families_features = {
    'Invoicing' : {'base' : ['standard pp.com invoicing','invoicing api']},
    'Payouts' : {'base' : ['payouts','payouts api','mass pay','pay an invoice']},
    'Other Branded' : {'base' : []},
    'Express Checkout': {'base' :['paypal checkout','express checkout','express checkout in context',
                                  'branded xo','ecm','express checkout mark','express checkout ( ecs & ecm)',
                                  'braintree direct - paypal (v.zero)', 'paypal (v.zero)','braintree with paypal',
                                  'connected path branded xo',],
                         'SPB' : ['spb','apms','smart payment button synch api','smart payment button',
                                  'smart payment button shortcut','smart payment button mark'],
                         'ECS' : ['ecs','express checkout ( ecs & ecm)','express checkout shortcut',],
                         'New Payment' : ['ppc','payin3','payin4', 'installments','paypal credit financing banners (legacy)',
                                  'paypal credit 2nd button (legacy)','paypal pay later',],
                         'Venmo' : ['venmo','venmo billing agreements','pay with venmo',], # ??
                         'QRC' : ['qr code ? integrated','qr code – integrated',],
                         'Fraud' : ['risk controls'], # any other?
                         'Other' : ['dispute api',],
                         'MAM' : ['multiple account managment (mam)'],
                        }, 
     'ACDC' : {'base' : ['payflow pro','payflow','paypal payments pro', # ACDC = new term for DCC/UCC
                         'payflow connector','unbranded xo','virtual terminal (vt)','payflow link',],
                     'Fraud' : ['risk controls','fraud management filters',],
                    },  
     'Marketplace' : {'base' : ['paypal commerce platform','connected path branded xo',
                               'pp marketplace','connected path', 'managed path'],
                     # add-ons from Express Checkout list are added replicated below
                     },
     'Gateway Only': {'base': ['gateway','network tokenization'],
                  'other' : ['3d secure'],}, # additional authentication layer - on top of other fraud tools
     'Braintree' : {'base' : ['braintree direct','braintere direct','braintree','braintree with paypal',
                              'merchant onboarding','braintree marketplace','payflow connector',], # ** marketplace, pf connector
                    'Fraud' : ['fraud protection','simility on braintree','kount','simility',],
                    'Extend' : ['braintree extend','extend',], # only if not specified as grant, vault, forward 
                    'Extend - Grant' : ['grant api',],
                    'Extend - Vault' : ['shared vault',],
                    'Extend - Forward' : ['forward api',],
                    'Pay Fast' : ['pay fast',],
                    'New Payment' : ['new payment','apple pay', 'google pay','alternate payment method',
                                    'alternate payment methods'], # *
                    'other' : ['3d secure']},
     'BT Enterprise In-Store' : {'base' : ['enterprise in store','enterprise instore']
                                # any add-ons to copy?
                                },
     'Hyperwallet' : {'base' : ['hyperwallet']},
     'Expansion' : {'base' : ['brand expansion (existing pp id)',
                              'geo expansion', # *
                              'brand expansion', # *
                              'geo expansion (existing pp id)',
                              'presentment currencies',]},
     #'No_Target_Product' : {'base' : ['#', 'NA', 'Unknown', '']},
}
for family in ['Marketplace']:
    for category in [cat for cat in product_families_features['Express Checkout'].keys() if cat is not 'base']
        product_families_features[family][category] = product_families_features['Express Checkout'][category]