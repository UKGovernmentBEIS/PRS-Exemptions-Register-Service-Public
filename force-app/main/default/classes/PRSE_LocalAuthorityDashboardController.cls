public with sharing class PRSE_LocalAuthorityDashboardController {
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('PRSE_LocalAuthorityDashboardController');

    @AuraEnabled(cacheable=true)
    public static String getUserDisplayName() {
        String displayName = '';        
        try {
            String userId = UserInfo.getUserId();
            Map<String, Object> bindMap = new Map<String, Object> { 'userId' => userId };
            User currentUser = ((List<User>) DatabaseWrapper.getInstance()
            .queryWithBinds(
                'SELECT Id, Name, ContactId FROM User WHERE Id = :userId', 
                bindMap
            ))[0];
            Id effectiveContactId = currentUser.contactId;
            //Id effectiveContactId = '003Pv000010KeNOIA0';

            bindMap = new Map<String, Object>{
                'contactId' => effectiveContactId
            };

            List<Account> accounts = ((List<Account>) DatabaseWrapper.getInstance()
                .queryWithBinds(
                    'SELECT Id, Name FROM Account WHERE PersonContactId = :contactId', 
                    bindMap
                ));
            if(accounts.isEmpty()) {
                displayName = currentUser.Name;
            } else {
                displayName = accounts[0]?.Name;
            }
        } catch(Exception ex) {
            errorLoggingService.setLogCode('PRSE_LocalAuthorityDashboardController')
                .setTriggeringAutomationName('getUserDisplayName')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }

        return displayName;
    }

    @AuraEnabled
    public static Map<String, String> getAssociatedLocalAuthorities() {
        Map<String, String> localAuthorities = new Map<String, String>();

        try {
            Map<String, Object> bindMap = new Map<String, Object> { 'userId' => UserInfo.getUserId() };
            Id contactId = ((List<User>) DatabaseWrapper.getPrivilegedInstance()
                .queryWithBinds(
                    'SELECT ContactId FROM User WHERE Id = :userId', 
                    bindMap)
                )[0]?.ContactId;

            Id localAuthorityRecordTypeId = ((List<RecordType>) DatabaseWrapper.getPrivilegedInstance()
                .query(
                    'SELECT Id, Name, SOBjectType FROM RecordType WHERE SOBjectType = \'Account\' AND Name = \'Local Authority\' LIMIT 1'
                ))[0]?.Id;
            
            Id effectiveContactId = contactId;
            //Id effectiveContactId = '003Pv000010KeNOIA0';

            bindMap = new Map<String, Object>{
                'contactId' => effectiveContactId,
                'localAuthorityRecordTypeId' => localAuthorityRecordTypeId
            };

            List<AccountContactRelation> accountContactRelations = (List<AccountContactRelation>) DatabaseWrapper.getPrivilegedInstance()
            .queryWithBinds(
                'SELECT Id, Account.Name, Account.Local_Custodian_Code__c ' +
                'FROM AccountContactRelation ' +
                'WHERE ContactId = :contactId ' +
                'AND Account.RecordTypeId = :localAuthorityRecordTypeId',
                bindMap
            );

            for(AccountContactRelation singleRelation :accountContactRelations) {
                localAuthorities.put(singleRelation.Account.Local_Custodian_Code__c, singleRelation.Account.Name);
            }
        } catch(Exception ex) {
            errorLoggingService.setLogCode('PRSE_LocalAuthorityDashboardController')
                .setTriggeringAutomationName('getAssociatedLocalAuthorities')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }

        return localAuthorities;
    }

    @AuraEnabled
    public static Integer getAssociatedExemptionsCount(List<String> localAuthorityCodes, String propertyType, String filters) {
        Integer count = 0;
        if((localAuthorityCodes == null || localAuthorityCodes.isEmpty()) || String.isBlank(propertyType)) {
            return count;
        }
        try {
            Filters filtersToApply = (Filters) JSON.deserialize(filters, Filters.class);
            Map<String, Object> bindMap = new Map<String, Object> {
                'localAuthorityCodes' => localAuthorityCodes,
                'propertyType' => propertyType
            };
            String query = 
                'SELECT COUNT_DISTINCT(Exemption__c) parentCount ' +
                'FROM Exemption_Type_Link__c ' +
                'WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes ' +
                'AND Exemption__r.PropertyType__c = :propertyType';

            if(filtersToApply.statuses != null && !filtersToApply.statuses.isEmpty()) {
                query += ' AND Exemption__r.Status__c IN :statuses';
                bindMap.put('statuses', filtersToApply.statuses);
            } else {
                query += ' AND Exemption__r.Status__c != \'Draft\'';
            }
            
            if(filtersToApply.exemptionTypeCodes != null && !filtersToApply.exemptionTypeCodes.isEmpty()) {
                query += ' AND Exemption_Type_Code__c IN :exemptionTypeCodes';
                bindMap.put('exemptionTypeCodes', filtersToApply.exemptionTypeCodes);
            }
            if(!String.isBlank(filtersToApply.searchTerm)) {
                List<String> fieldsToSearchOn = new List<String> {
                    'Exemption__r.Ref_Number__c',
                    'Exemption__r.Name',
                    'Exemption__r.LandlordFullName__c',
                    'Exemption__r.LandlordBusinessName__c',
                    'Exemption__r.PropertyAddress__c',
                    'Exemption__r.PropertyCity__c',
                    'Exemption__r.PropertyCounty__c',
                    'Exemption__r.PropertyCountry__c',
                    'Exemption__r.PropertyPostcode__c'
                };
                query += buildLikeClauses(bindMap, fieldsToSearchOn, filtersToApply.searchTerm);
            }
            count = Integer.valueOf(DatabaseWrapper.getInstance().queryWithBinds(
                query,
                bindMap
            )[0].get('parentCount'));
        } catch (Exception ex) {
            errorLoggingService.setLogCode('PRSE_LocalAuthorityDashboardController')
                .setTriggeringAutomationName('getAssociatedExemptionsCount')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return count;
    }

    @AuraEnabled
    public static Integer getAssociatedExemptionsNeedingReviewCount(List<String> localAuthorityCodes, String propertyType) {
        Integer count = 0;
        if((localAuthorityCodes == null || localAuthorityCodes.isEmpty()) || String.isBlank(propertyType)) {
            return count;
        }
        try {
            Map<String, Object> bindMap = new Map<String, Object> {
                'localAuthorityCodes' => localAuthorityCodes,
                'propertyType' => propertyType
            };
            count = DatabaseWrapper.getInstance().countQueryWithBinds(
                'SELECT COUNT() FROM Exemption__c WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND Status__c IN (\'Updated\', \'Received\') AND PropertyType__c = :propertyType',
                bindMap
            );
        } catch (Exception ex) {
            errorLoggingService.setLogCode('PRSE_LocalAuthorityDashboardController')
                .setTriggeringAutomationName('getAssociatedExemptionsNeedingReviewCount')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return count;
    }

    @AuraEnabled
    public static PaginatedResult getAssociatedExemptionsForLocalAuthorities(
        List<String> localAuthorityCodes, 
        String propertyType, 
        Integer pageSize, 
        Integer pageNumber,
        String filters
    ) {
        PaginatedResult result = new PaginatedResult();
        result.records = new List<Exemption>();
        result.totalRecords = 0;
        result.pageSize = 30;
        result.pageNumber = 1;

        if((localAuthorityCodes == null || localAuthorityCodes.isEmpty()) || String.isBlank(propertyType)) {
            return result;
        }
        try {
            Filters filtersToApply = (Filters) JSON.deserialize(filters, Filters.class);
            if (pageSize == null || pageSize <= 0) {
                pageSize = 30;
            }
            if (pageNumber == null || pageNumber <= 0) {
                pageNumber = 1;
            }

            Integer offsetValue = (pageNumber - 1) * pageSize;
            Integer totalCount = getAssociatedParentExemptionsCountWithFilters(localAuthorityCodes, propertyType, filtersToApply);

            List<Exemption> exemptions = getAssociatedExemptionsForLocalAuthoritiesWithOffsetAndFilters(
                localAuthorityCodes, 
                propertyType, 
                pageSize, 
                offsetValue, 
                filtersToApply
            );

            result.records = exemptions;
            result.totalRecords = totalCount;
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;
        } catch (Exception ex) {
            errorLoggingService.setLogCode('PRSE_LocalAuthorityDashboardController')
                .setTriggeringAutomationName('getAssociatedExemptionsForLocalAuthorities')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
       
        return result;
    }

    private static Integer getAssociatedParentExemptionsCount(List<String> localAuthorityCodes, String propertyType) {
        Integer count = 0;
        Map<String, Object> bindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };
        count = DatabaseWrapper.getInstance().countQueryWithBinds(
            'SELECT COUNT() FROM Exemption__c WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND PropertyType__c = :propertyType AND Status__c != \'Draft\'',
            bindMap
        );
        return count;
    }
    
    private static Integer getAssociatedParentExemptionsCountWithFilters(List<String> localAuthorityCodes, String propertyType, Filters filters) {
        Integer count = 0;
        Map<String, Object> bindMap = new Map<String, Object> {
            'localAuthorityCodes' => localAuthorityCodes,
            'propertyType' => propertyType
        };

        String query = 
            'SELECT COUNT() ' +
            'FROM Exemption__c ' +
            'WHERE Id IN (' +
                'SELECT Exemption__c ' +
                'FROM Exemption_Type_Link__c ' +
                'WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes ' +
                'AND Exemption__r.PropertyType__c = :propertyType';

        if(filters.statuses != null && !filters.statuses.isEmpty()) {
            query += ' AND Exemption__r.Status__c IN :statuses';
            bindMap.put('statuses', filters.statuses);
        } else {
            query += ' AND Exemption__r.Status__c != \'Draft\'';
        }

        if(filters.exemptionTypeCodes != null && !filters.exemptionTypeCodes.isEmpty()) {
            query += ' AND Exemption_Type_Code__c IN :exemptionTypeCodes';
            bindMap.put('exemptionTypeCodes', filters.exemptionTypeCodes);
        }
        if(!String.isBlank(filters.searchTerm)) {
            List<String> fieldsToSearchOn = new List<String> {
                'Exemption__r.Ref_Number__c',
                'Exemption__r.Name',
                'Exemption__r.LandlordFullName__c',
                'Exemption__r.LandlordBusinessName__c',
                'Exemption__r.PropertyAddress__c',
                'Exemption__r.PropertyCity__c',
                'Exemption__r.PropertyCounty__c',
                'Exemption__r.PropertyCountry__c',
                'Exemption__r.PropertyPostcode__c'
            };
            query += buildLikeClauses(bindMap, fieldsToSearchOn, filters.searchTerm);
        }
        query += ')';
        count = DatabaseWrapper.getInstance().countQueryWithBinds(
            query,
            bindMap
        );
        return count;
    }

    private static List<Exemption> getAssociatedExemptionsForLocalAuthoritiesWithOffsetAndFilters(
        List<String> localAuthorityCodes, 
        String propertyType, 
        Integer pageSize, 
        Integer offsetValue,
        Filters filters
    ) {
        List<Exemption> exemptions = new List<Exemption>();
        List<Exemption__c> parentExemptions = new List<Exemption__c>();

        Map<String, Object> bindMap = new Map<String, Object> {
            'propertyType' => propertyType,
            'localAuthorityCodes' => localAuthorityCodes,
            'pageSize' => pageSize,
            'offsetValue' => offsetValue
        };

        String parentWhereClause = 'WHERE PropertyType__c = :propertyType AND Local_Custodian_Code__c IN :localAuthorityCodes';
        if(filters.statuses != null && !filters.statuses?.isEmpty()) {
            parentWhereClause += ' AND Status__c IN :statuses ';
            bindMap.put('statuses', filters.statuses);
        } else {
            parentWhereClause += ' AND Status__c != \'Draft\' ';
        }
        if(!String.isBlank(filters.searchTerm)) {
            List<String> fieldsToSearchOn = new List<String> {
                'Ref_Number__c',
                'LandlordFullName__c',
                'LandlordBusinessName__c',
                'PropertyAddress__c',
                'PropertyCity__c',
                'PropertyCounty__c',
                'PropertyCountry__c',
                'PropertyPostcode__c',
                'Name'
            };
            parentWhereClause += buildLikeClauses(bindMap, fieldsToSearchOn, filters.searchTerm);
        }

        String childWhereSubQuery = '(SELECT Exemption__c FROM Exemption_Type_Link__c';
        if(filters.exemptionTypeCodes != null && !filters.exemptionTypeCodes.isEmpty()) {
            childWhereSubQuery += ' WHERE Exemption_Type_Code__c IN :exemptionTypeCodes';
            bindMap.put('exemptionTypeCodes', filters.exemptionTypeCodes);
        }
        childWhereSubQuery += ') ';
        parentExemptions = (List<Exemption__c>) DatabaseWrapper.getInstance().queryWithBinds(
                'SELECT Id, Ref_Number__c, LandlordFirstName__c, LandlordLastName__c, LandlordBusinessName__c, ' + 
                'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyCountry__c, PropertyPostcode__c, ' + 
                'PropertyType__c, Status__c, Registered_Date__c, ' +
                '(SELECT Id, Exemption__c, Exemption_Type__r.Name FROM ExemptionTypeLinks__r) ' +
                'FROM Exemption__c ' + parentWhereClause +
                'AND Id IN ' + childWhereSubQuery +
                'ORDER BY Status__c DESC, Registered_Date__c DESC ' + 
                'LIMIT :pageSize ' +
                'OFFSET :offsetValue',
                bindMap
            );

        for(Exemption__c parentExemption : parentExemptions) {
            Exemption exemption = new Exemption(parentExemption);
            List<Exemption_Type_Link__c> childRecords = parentExemption.ExemptionTypeLinks__r;
            if(childRecords != null && !childRecords.isEmpty()) {
                for(Exemption_Type_Link__c childExemption : childRecords) {
                    exemption.addChildExemptionType(childExemption.Exemption_Type__r?.Name);
                }
                exemption.build();
                exemptions.add(exemption);
            }
        }

        return exemptions;
    }

    @AuraEnabled
    public static Map<String, Integer> getExemptionsByStatus(List<String> localAuthorityCodes, String propertyType) {
        Map<String, Integer> exemptionsByStatus = new Map<String, Integer>();
        try {
            List<String> statuses = new List<String>();
            DescribeFieldResult fieldResult = Exemption__c.Status__c.getDescribe();
            List<PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            for(PicklistEntry singleEntry :picklistEntries) {
                exemptionsByStatus.put(singleEntry.getValue(), 0);
            }
            Map<String, Object> bindMap = new Map<String, Object> {
                'localAuthorityCodes' => localAuthorityCodes,
                'propertyType' => propertyType
            };
            List<AggregateResult> resultsByStatus = DatabaseWrapper.getInstance().queryWithBinds(
                'SELECT count(Id) numberOfRecords, Status__c ' +
                'FROM Exemption__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes AND PropertyType__c = :propertyType ' +
                'GROUP BY Status__c',
                bindMap
            );
            for(AggregateResult singleResult :resultsByStatus) {
                exemptionsByStatus.put((String) singleResult.get('Status__c'), (Integer) singleResult.get('numberOfRecords'));
            }
            return exemptionsByStatus;
        } catch (Exception ex) {
             errorLoggingService.setLogCode('PRSE_LocalAuthorityDashboardController')
                .setTriggeringAutomationName('getExemptionsByStatus')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return exemptionsByStatus;
    }

    @AuraEnabled
    public static List<RecordTypeInfo> getExemptionsByType(List<String> localAuthorityCodes, String propertyType) {
        Map<String, RecordTypeInfo> exemptionTypesMap = new Map<String, RecordTypeInfo>();
        try {
            Boolean isCommercial = propertyType == 'Commercial';
            Map<String, Object> exemptionTypesListBindMap = new Map<String, Object> {
                'isCommercial' => isCommercial
            };
            List<Exemption_Type__c> exemptionTypesList = DatabaseWrapper.getInstance().queryWithBinds(
                'SELECT Name, Code__c FROM Exemption_Type__c WHERE IsCommercial__c = :isCommercial ORDER BY Code__c',
                exemptionTypesListBindMap
            );
            
            for(Exemption_Type__c singleExemptionType :exemptionTypesList) {
                exemptionTypesMap.put(
                    singleExemptionType.Name, 
                    new RecordTypeInfo(
                        singleExemptionType.Name, 
                        singleExemptionType.Code__c, 
                        0
                    )
                );
            }
            Map<String, Object> resultsByTypeBindMap = new Map<String, Object> {
                'localAuthorityCodes' => localAuthorityCodes,
                'propertyType' => propertyType
            };
            List<AggregateResult> resultsByType = DatabaseWrapper.getInstance().queryWithBinds(
                'Select count(Id) numberOfRecords, Exemption_Type__r.Name, Exemption_Type__r.Code__c ' + 
                'FROM Exemption_Type_Link__c ' + 
                'WHERE Exemption__r.Local_Custodian_Code__c IN :localAuthorityCodes ' +
                'AND Exemption__r.PropertyType__c = :propertyType ' +
                'AND Exemption__r.Status__c != \'Draft\'' +
                'GROUP BY Exemption_Type__r.Name, Exemption_Type__r.Code__c ' +
                'ORDER BY Exemption_Type__r.Code__c',
                resultsByTypeBindMap
            );
            for(AggregateResult singleResult :resultsByType) {
                exemptionTypesMap.get((String) singleResult.get('Name')).numberOfRecords = (Integer) singleResult.get('numberOfRecords');
            }
            return exemptionTypesMap.values();
        } catch (Exception ex) {
             errorLoggingService.setLogCode('PRSE_LocalAuthorityDashboardController')
                .setTriggeringAutomationName('getExemptionsByType')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return exemptionTypesMap.values();
    }

    @AuraEnabled
    public static List<RecordTypeInfo> getPenaltiesByType(List<String> localAuthorityCodes) {
        Map<String, RecordTypeInfo> penaltyTypesMap = new Map<String, RecordTypeInfo>();
        try {
            List<Penalty_Type__c> penaltyTypesList = DatabaseWrapper.getInstance().query(
                'SELECT Name, Code__c FROM Penalty_Type__c ORDER BY Code__c'
            );
            for(Penalty_Type__c singlePenaltyType :penaltyTypesList) {
                penaltyTypesMap.put(
                    singlePenaltyType.Name, 
                    new RecordTypeInfo(
                        singlePenaltyType.Name,
                        singlePenaltyType.Code__c,
                        0
                    )
                );
            }
            Map<String, Object> resultsByTypeBindMap = new Map<String, Object> {
                'localAuthorityCodes' => localAuthorityCodes
            };
            List<AggregateResult> resultsByType = DatabaseWrapper.getInstance().queryWithBinds(
                'SELECT COUNT(Id) numberOfRecords, Penalty_Type__r.Name ' +
                'FROM Penalty__c ' +
                'WHERE Local_Custodian_Code__c IN :localAuthorityCodes ' +
                'GROUP BY Penalty_Type__r.Name',
                resultsByTypeBindMap
            );
            for(AggregateResult singleResult :resultsByType) {
                penaltyTypesMap.get((String) singleResult.get('Name')).numberOfRecords = (Integer) singleResult.get('numberOfRecords');
            }
            return penaltyTypesMap.values();
        } catch (Exception ex) {
             errorLoggingService.setLogCode('PRSE_LocalAuthorityDashboardController')
                .setTriggeringAutomationName('getPenaltiesByType')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return penaltyTypesMap.values();
    }

    private static String buildLikeClauses(Map<String, Object> bindMapToAddTo, List<String> fieldsToAddFor, String filterSearchTerm) {
        String escapedSearchTerm = String.escapeSingleQuotes(filterSearchTerm);
        String trimmedAndEscapedSearchTerm = String.escapeSingleQuotes(filterSearchTerm).trim().remove(' ');
        String searchTerm = '%' + escapedSearchTerm + '%';
        String trimmedSearchTerm = '%' + trimmedAndEscapedSearchTerm + '%';
        String likeClauses = ' AND (';
        if(fieldsToAddFor != null && !fieldsToAddFor.isEmpty()) {
            for(String field : fieldsToAddFor) {
                likeClauses += field + ' LIKE :searchTerm OR ' + field  + ' LIKE :trimmedSearchTerm OR ';
            }
            likeClauses = likeClauses.removeEnd(' OR ');
            likeClauses += ')';
            bindMapToAddTo.put('searchTerm', searchTerm);
            bindMapToAddTo.put('trimmedSearchTerm', trimmedSearchTerm);
        }
        return likeClauses;
    }

    private class Filters {
        public List<String> statuses;
        public List<String> exemptionTypeCodes;
        public String searchTerm;
    }

    public class RecordTypeInfo {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String code;
        @AuraEnabled
        public Integer numberOfRecords;

        public RecordTypeInfo(String name, String code, Integer numberOfRecords) {
            this.name = name;
            this.code = code;
            this.numberOfRecords = numberOfRecords;
        }
    }

    public class PaginatedResult {
        @AuraEnabled 
        public List<Exemption> records { get; set; }
        @AuraEnabled 
        public Integer totalRecords { get; set; }
        @AuraEnabled 
        public Integer pageSize { get; set; }
        @AuraEnabled 
        public Integer pageNumber { get; set; }
    }

    public class Exemption {
        private Exemption__c exemption;
        @AuraEnabled
        public String referenceNumber;
        @AuraEnabled
        public String landlordName;
        @AuraEnabled
        public String propertyAddress;
        @AuraEnabled
        public String exemptionTypes = '';
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String registeredDate;
        @AuraEnabled
        public Id exemptionId;

        public Exemption(Exemption__c exemption) {
            this.exemption = exemption;
            this.exemptionId = exemption.Id;
        }

        public void withReferenceNumber() {
            this.referenceNumber = exemption.Ref_Number__c;
        }

        public void withLandlordName() {
            this.landlordName = String.isBlank(exemption.LandlordBusinessName__c) 
                ? exemption.LandlordFirstName__c + ' ' + exemption.LandlordLastName__c 
                : exemption.LandlordBusinessName__c;
        }

        public void withPropertyAddress() {
            String county = String.isBlank(exemption.PropertyCounty__c) ? '' : exemption.PropertyCounty__c + ', ';
            this.propertyAddress = exemption.PropertyAddress__c + ', ' + 
                exemption.PropertyCity__c + ', ' + 
                county + 
                exemption.PropertyCountry__c + ', ' + 
                exemption.PropertyPostcode__c;
        }

        public void withStatus() {
            this.status = exemption.Status__c;
        }

        public void withRegisteredDate() {
            this.registeredDate = exemption.Registered_Date__c?.format('dd/M/yyyy');
        }

        public Exemption addChildExemptionType(String exemptionType) {
            this.exemptionTypes += exemptionType + ', ';
            return this;
        }

        public Exemption build() {
            withReferenceNumber();
            withLandlordName();
            withPropertyAddress();
            withStatus();
            withRegisteredDate();
            this.exemptionTypes = exemptionTypes.removeEnd(', ');
            return this;
        }
    }
}