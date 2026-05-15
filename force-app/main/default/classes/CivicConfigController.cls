public with sharing class CivicConfigController {

    public Civic_Config_Wrapper civicConfig { get; private set; }

    @TestVisible
    private String extractSitePath() {
        String sitePrefix = Site.getPathPrefix();
        if(String.isBlank(sitePrefix)) {
            return '';
        }
        return sitePrefix.substring(1);
    }

    public CivicConfigController() {

        String sitePath = extractSitePath();

        List<Civic_Config__mdt> configs = [
            SELECT Id, ApiKey__c, Product__c, Enabled__c, InitialState__c, Site_Path__c
            FROM Civic_Config__mdt
            WHERE Enabled__c = TRUE
            LIMIT 1
        ];

        if(configs.isEmpty()) {
            civicConfig = new Civic_Config_Wrapper();
            return;
        }

        Civic_Config__mdt config = configs[0];

        civicConfig = new Civic_Config_Wrapper();
        civicConfig.apiKey = config.ApiKey__c;
        civicConfig.product = config.Product__c;
        civicConfig.enabled = config.Enabled__c;
        civicConfig.initialState = config.InitialState__c;
        civicConfig.sitePath = config.Site_Path__c;
        civicConfig.necessaryCookies = buildNecessaryCookies(config.Id);
        civicConfig.optionalCookies = buildOptionalCookies(config.Id);
    }

    public class Civic_Config_Wrapper {
        public String apiKey;
        public String product;
        public Boolean enabled;
        public String initialState;
        public String sitePath;
        public List<String> necessaryCookies;
        public List<Object> optionalCookies; 
    }

    @AuraEnabled(cacheable=true)
    public static String getCivicConfig() {
        CivicConfigController controller = new CivicConfigController();
        return JSON.serialize(controller.civicConfig);
    }

    public String getConfigJSON() {
        return JSON.serialize(civicConfig);
    }

    public List<String> buildNecessaryCookies(Id configId) {

        Civic_Category__mdt necessaryCookieCategory = [
            SELECT Id, DeveloperName, Active__c
            FROM Civic_Category__mdt
            WHERE Active__c = TRUE 
            AND Type__c = 'necessary' 
            AND Config__c = :configId
            LIMIT 1
        ];

        List<Civic_Cookie__mdt> necessaryCookieList = [
            SELECT Cookie_Name__c,
                   Category__c
            FROM Civic_Cookie__mdt
            WHERE Category__c = :necessaryCookieCategory.Id
            AND Active__c = TRUE
        ];

        List<String> necessaryCookies = new List<String>();

        if(necessaryCookieList.size() > 0) {
            for(Civic_Cookie__mdt cookie : necessaryCookieList) {
                necessaryCookies.add(cookie.Cookie_Name__c);
            }
        }

        return necessaryCookies;
    }

    public List<Object> buildOptionalCookies(Id configId) {

        List<Civic_Category__mdt> categories = [
            SELECT Id,
                   DeveloperName,
                   Label,
                   Description__c,
                   Order__c
            FROM Civic_Category__mdt
            WHERE Config__c = :configId
            AND Type__c != 'necessary'
            AND Active__c = TRUE
            ORDER BY Order__c
        ];

        if(categories.isEmpty()) {
            return new List<Object>();
        }

        List<Civic_Cookie__mdt> cookies = [
            SELECT Cookie_Name__c,
                   Category__c
            FROM Civic_Cookie__mdt
            WHERE Category__c IN :categories
            AND Active__c = TRUE
        ];

         Map<Id, List<String>> categoryCookieMap = new Map<Id, List<String>>();

        for (Civic_Cookie__mdt cookie : cookies) {
            if (!categoryCookieMap.containsKey(cookie.Category__c)) {
                categoryCookieMap.put(cookie.Category__c, new List<String>());
            }
            categoryCookieMap.get(cookie.Category__c).add(cookie.Cookie_Name__c);
        }

        List<Object> optionalCookies = new List<Object>();

        for (Civic_Category__mdt cat : categories) {

            Map<String, Object> catObj = new Map<String, Object>();

            catObj.put('name', cat.DeveloperName);
            catObj.put('label', cat.Label);
            catObj.put('description', cat.Description__c);
            catObj.put('cookies', categoryCookieMap.containsKey(cat.Id) ? categoryCookieMap.get(cat.Id) : new List<String>());

            optionalCookies.add(catObj);
        }

        return optionalCookies;
    }
}