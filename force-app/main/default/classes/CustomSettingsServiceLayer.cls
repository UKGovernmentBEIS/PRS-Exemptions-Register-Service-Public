public without sharing class CustomSettingsServiceLayer implements CustomSettingsService.API {

    @TestVisible
    private static CustomSettingsService.API instance;

    // Default values (used if metadata is missing or fields are null)
    private static final Integer DEFAULT_EXEMPTIONS_PAGE_SIZE = 20;
    private static final Integer DEFAULT_PENALTIES_PAGE_SIZE  = 20;

    // Cached metadata record
    @TestVisible
    private static PRSE_Configuration__mdt cfg {
        get {
            if (cfg == null) {
                cfg = PRSE_Configuration__mdt.getInstance('Portal_Settings');
            }
            return cfg;
        }
        private set;
    }

    //Public Methods
    public static CustomSettingsService.API getInstance() {
        if(instance == null) {
            instance = new CustomSettingsServiceLayer();
        } 
        return instance;
    }

    public String getOSPlacesAPIKey() {  
        return getAPICredentialByNameAndKey('PRSE_OS_Places_Key', 'PRSE_OS_Key');
    }

    public String getGovNotifyAPIKey() {
        return getAPICredentialByNameAndKey('PRSE_Gov_Notify_Key', 'PRSE_Gov_Notify_Key');
    }
    
    public String getUserTokenEncryptionKey() {
        return getAPICredentialByNameAndKey('PRSE_User_Token', 'EncryptionSecret');
    }

    public String getEPCAPIUsername() {
        return getAPICredentialByNameAndKey('PRSE_EPC_API_Username', 'PRSE_EPC_API_Username');
    }
    
    public String getEPCAPIKey() {
        return getAPICredentialByNameAndKey('PRSE_EPC_API_Key', 'PRSE_EPC_API_Key');
    }

    public String getOneLoginPublicKey() {
       return getAPICredentialByNameAndKey('PRSE_One_Login_Key', 'PRSE_One_Login_Key');
    }

    public String getAPICredentialByNameAndKey(String name, String key) {
        digitalmodus__API_Credentials__c credential;
        try {
            credential = [
                    SELECT Id, Name, digitalmodus__Key__c, digitalmodus__Value__c 
                    FROM digitalmodus__API_Credentials__c
                    WHERE Name = :name AND digitalmodus__Key__c = :key
                    LIMIT 1
                ];
        } catch(Exception e) {
            if(e.getMessage() == 'List has no rows for assignment to SObject') {
                throw new Exceptions.QueryException('Missing ' + name + ' custom setting, please ensure this is set up before proceeding.');
            } else {
                throw e;
            }
        }
            
        return credential.digitalmodus__Value__c;
    }

    /**
     * @description Page size for Public Exemptions search results
     */
    public static Integer getPublicExemptionsPageSize() {
        return (cfg != null && cfg.Public_Exemptions_Search_Results_Page__c != null)
            ? Integer.valueOf(cfg.Public_Exemptions_Search_Results_Page__c) : DEFAULT_EXEMPTIONS_PAGE_SIZE;
    }

    /**
     * @description Page size for Public Penalties search results
     */
    public static Integer getPublicPenaltiesPageSize() {
        return (cfg != null && cfg.Public_Penalties_Search_Results_Page__c != null)
            ? Integer.valueOf(cfg.Public_Penalties_Search_Results_Page__c) : DEFAULT_PENALTIES_PAGE_SIZE;
    }

    /**
     * @description Flag controlling which GOV EPC endpoint is used
     */
    public static Boolean useNewGovEpcEndpoint() {
        return cfg != null && cfg.Use_new_gov_EPC_endpoint__c;
    }
}