public with sharing class DeliveryPointAddress {
    
        @AuraEnabled
        public Long UPRN;
        public Long UDPRN;
        @AuraEnabled
        public String ADDRESS { 
                get {
                       return capitaliseEveryWordInAddress(ADDRESS);
                } 
                set;
        }
        public String PO_BOX_NUMBER;
        @AuraEnabled
        public String ORGANISATION_NAME { 
                get {
                       return capitaliseEveryWord(ORGANISATION_NAME);
                } 
                set;
        }
        public String DEPARTMENT_NAME;
        @AuraEnabled
        public String SUB_BUILDING_NAME{ 
                get {
                       return capitaliseEveryWord(SUB_BUILDING_NAME);
                } 
                set;
        }
        @AuraEnabled
        public String BUILDING_NAME { 
                get {
                       return capitaliseEveryWord(BUILDING_NAME);
                } 
                set;
        }
        @AuraEnabled
        public Long BUILDING_NUMBER;
        public String DEPENDENT_THOROUGHFARE_NAME;
        @AuraEnabled
        public String THOROUGHFARE_NAME { 
                get {
                       return capitaliseEveryWord(THOROUGHFARE_NAME);
                } 
                set;
        }
        public String DOUBLE_DEPENDENT_LOCALITY;
        public String DEPENDENT_LOCALITY;
        @AuraEnabled
        public String POST_TOWN { 
                get {
                       return POST_TOWN?.toLowerCase().capitalize();
                } 
                set;
        }
        @AuraEnabled
        public String POSTCODE;
        public String RPC;
        public Decimal X_COORDINATE;
        public Decimal Y_COORDINATE;
        public Decimal LNG;
        public Decimal LAT;
        public String STATUS;
        public Long LOGICAL_STATUS_CODE;
        public String CLASSIFICATION_CODE;
        public String CLASSIFICATION_CODE_DESCRIPTION;
        @AuraEnabled
        public Long LOCAL_CUSTODIAN_CODE;
        public String LOCAL_CUSTODIAN_CODE_DESCRIPTION;
        @AuraEnabled
        public String COUNTRY_CODE;
        public String COUNTRY_CODE_DESCRIPTION;
        public String POSTAL_ADDRESS_CODE;
        public String POSTAL_ADDRESS_CODE_DESCRIPTION;
        public Long BLPU_STATE_CODE;
        public String BLPU_STATE_CODE_DESCRIPTION;
        public String TOPOGRAPHY_LAYER_TOID;
        public String WARD_CODE;
        public String PARISH_CODE;
        public Long PARENT_UPRN;
        public String LAST_UPDATE_DATE;
        public String ENTRY_DATE;
        public String LEGAL_NAME;
        public String BLPU_STATE_DATE;
        public String LANGUAGE;
        public DOUBLE MATCH;
        public String MATCH_DESCRIPTION;
        public String DELIVERY_POINT_SUFFIX;

        private String capitaliseEveryWord(String sentence) {
                if(String.isBlank(sentence)) {
                        return null;
                }
                List<String> words = sentence.toLowerCase().split(' ');
                List<String> capitalisedWords = new List<String>();
                for (Integer i = 0; i < words.size(); i++) {
                        capitalisedWords.add(words[i].capitalize());
                }
                return String.join(capitalisedWords, ' ');
        }
        private String capitaliseEveryWordInAddress(String sentence) {
                if(String.isBlank(sentence)) {
                        return null;
                }
                List<String> words = sentence.toLowerCase().split(' ');
                List<String> capitalisedWords = new List<String>();
                for (Integer i = 0; i < words.size() - 2; i++) {
                        capitalisedWords.add(words[i].capitalize());
                }
                capitalisedWords.add(words[words.size() - 2].toUpperCase());
                capitalisedWords.add(words[words.size() - 1].toUpperCase());
                return String.join(capitalisedWords, ' ');
        }
}