public with sharing class PRSE_LADashboardPenaltiesController {
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('PRSE_LADashboardPenaltiesController');

    @AuraEnabled
    public static Boolean hasAccessToParentExemption(String parentExemptionId) {
        Boolean hasAccess = false;
        try {
            hasAccess = PRSE_LAViewExemptionHelper.checkExemption(parentExemptionId);
        } catch (Exception ex) {
            errorLoggingService.setLogCode('PRSE_LADashboardPenaltiesController')
                .setTriggeringAutomationName('hasAccessToParentExemption')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return hasAccess;
    }

    @AuraEnabled
    public static List<Exemption_Type_Link__c> getAssociatedChildExemptions(String parentExemptionId) {
        List<Exemption_Type_Link__c> childExemptions = new List<Exemption_Type_Link__c>();
        if(String.isBlank(parentExemptionId)) {
            return childExemptions;
        }
        try {
            if(!PRSE_LAViewExemptionHelper.checkExemption(parentExemptionId)) {
                throw new AuraHandledException('You do not have permission to view this exemption');
            }
            Map<String, Object> bindMap = new Map<String, Object> { 'parentExemptionId' => parentExemptionId };
            childExemptions = ((List<Exemption_Type_Link__c>) DatabaseWrapper.getInstance()
                .queryWithBinds(
                    'SELECT Id, Child_Exemption_Ref__c, End_Date__c, Name ' +
                    'FROM Exemption_Type_Link__c ' +
                    'WHERE Exemption__c  = :parentExemptionId AND End_Date__c = NULL', 
                    bindMap
                ));
        } catch (Exception ex) {
            errorLoggingService.setLogCode('PRSE_LADashboardPenaltiesController')
                .setTriggeringAutomationName('getAssociatedChildExemptions')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
       
        return childExemptions;
    }

    @AuraEnabled
    public static PaginatedResult getAssociatedPenaltiesForLocalAuthorities( 
        String filters,
        Integer pageSize, 
        Integer pageNumber
        ) {
        PaginatedResult result = new PaginatedResult();
        result.records = new List<Penalty>();
        result.totalRecords = 0;
        result.pageSize = 30;
        result.pageNumber = 1;

        try {
            Filters filtersToApply = (Filters) JSON.deserialize(filters, Filters.class);
            if(filtersToApply.localAuthorityCodes == null || filtersToApply.localAuthorityCodes.isEmpty()) {
                return result;
            }

            if (pageSize == null || pageSize <= 0) {
                pageSize = 30;
            }
            if (pageNumber == null || pageNumber <= 0) {
                pageNumber = 1;
            }
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;

            Integer offsetValue = (pageNumber - 1) * pageSize;
            result.totalRecords = getAssociatedPenaltiesCountWithFilters(filtersToApply);
            result.records = getAssociatedPenaltiesWithFilters(
                filtersToApply, 
                pageSize, 
                offsetValue
            );
        } catch (Exception ex) {
            errorLoggingService.setLogCode('PRSE_LADashboardPenaltiesController')
                .setTriggeringAutomationName('getAssociatedPenaltiesForLocalAuthorities')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }

        return result;
    }

    @AuraEnabled
    public static PaginatedResult getAssociatedPenalties(
        String parentExemptionId,
        Integer pageSize, 
        Integer pageNumber
    ) {
        PaginatedResult result = new PaginatedResult();
        result.records = new List<Penalty>();
        result.totalRecords = 0;
        result.pageSize = 30;
        result.pageNumber = 1;

        if(String.isBlank(parentExemptionId)) {
            return result;
        }

        try {
            if(!PRSE_LAViewExemptionHelper.checkExemption(parentExemptionId)) {
                throw new AuraHandledException('You do not have permission to view this exemption');
            }
            Filters filtersToApply = new Filters();
            filtersToApply.parentExemptionId = parentExemptionId;

            if (pageSize == null || pageSize <= 0) {
                pageSize = 30;
            }
            if (pageNumber == null || pageNumber <= 0) {
                pageNumber = 1;
            }
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;

            Integer offsetValue = (pageNumber - 1) * pageSize;
            result.totalRecords = getAssociatedPenaltiesCountWithFilters(filtersToApply);
            result.records = getAssociatedPenaltiesWithFilters(
                filtersToApply, 
                pageSize, 
                offsetValue
            );
        } catch (Exception ex) {
            errorLoggingService.setLogCode('PRSE_LADashboardPenaltiesController')
                .setTriggeringAutomationName('getAssociatedPenalties')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return result;
    }

    private static Integer getAssociatedPenaltiesCountWithFilters(Filters filters) {
        Integer count = 0;
        Map<String, Object> bindMap = new Map<String, Object>();
        String query = 'SELECT COUNT() FROM Penalty__c WHERE ';

        if(filters.localAuthorityCodes != null && !filters.localAuthorityCodes.isEmpty()) {
            query += 'Local_Custodian_Code__c IN :localAuthorityCodes';
            bindMap.put('localAuthorityCodes', filters.localAuthorityCodes);
        } else if (String.isNotBlank(filters.parentExemptionId)) {
            query += 'Exemption__c = :parentExemptionId';
            bindMap.put('parentExemptionId', filters.parentExemptionId);
        }

        if(filters.penaltyTypeCodes != null && !filters.penaltyTypeCodes.isEmpty()) {
            query += ' AND Penalty_Type__r.Code__c IN :penaltyTypeCodes';
            bindMap.put('penaltyTypeCodes', filters.penaltyTypeCodes);
        }

        if(String.isNotBlank(filters.propertyType)) {
            query += ' AND PropertyType__c = :propertyType';
            bindMap.put('propertyType', filters.propertyType);
        }

        if(String.isNotBlank(filters.searchTerm)) {
            List<String> fieldsToSearchOn = new List<String> {
                'Penalty_Reference__c',
                'LandlordFirstName__c',
                'LandlordLastName__c',
                'LandlordBusinessName__c',
                'PropertyAddress__c',
                'PropertyCity__c',
                'PropertyCounty__c',
                'PropertyPostcode__c'
            };
            query += buildLikeClauses(bindMap, fieldsToSearchOn, filters.searchTerm);
        }

        return DatabaseWrapper.getInstance().countQueryWithBinds(query, bindMap);
    }

    private static List<Penalty> getAssociatedPenaltiesWithFilters(
        Filters filters, Integer pageSize, Integer offsetValue
    ) {
        Map<String, Object> bindMap = new Map<String, Object>{
            'pageSize' => pageSize,
            'offsetValue' => offsetValue
        };
        String whereClause = '';

        if(filters.localAuthorityCodes != null && !filters.localAuthorityCodes.isEmpty()) {
            whereClause += 'Local_Custodian_Code__c IN :localAuthorityCodes';
            bindMap.put('localAuthorityCodes', filters.localAuthorityCodes);
        } else if (String.isNotBlank(filters.parentExemptionId)) {
            whereClause += 'Exemption__c = :parentExemptionId';
            bindMap.put('parentExemptionId', filters.parentExemptionId);
        }

        if(filters.penaltyTypeCodes != null && !filters.penaltyTypeCodes.isEmpty()) {
            whereClause += ' AND Penalty_Type__r.Code__c IN :penaltyTypeCodes';
            bindMap.put('penaltyTypeCodes', filters.penaltyTypeCodes);
        }

        if(String.isNotBlank(filters.propertyType)) {
            whereClause += ' AND PropertyType__c = :propertyType';
            bindMap.put('propertyType', filters.propertyType);
        }

        if(String.isNotBlank(filters.searchTerm)) {
            List<String> fieldsToSearchOn = new List<String> {
                'Penalty_Reference__c',
                'LandlordFirstName__c',
                'LandlordLastName__c',
                'LandlordBusinessName__c',
                'PropertyAddress__c',
                'PropertyCity__c',
                'PropertyCounty__c',
                'PropertyPostcode__c'
            };
            whereClause += buildLikeClauses(bindMap, fieldsToSearchOn, filters.searchTerm);
        }
        String query =                 
            'SELECT Id, Exemption__c, Penalty_Reference__c, Exemption_Type_Link__c, Exemption_Type_Link__r.Name, ' +
            'Penalty_Type__c, Penalty_Type__r.Name, Issued_Date__c, Unpublish_Date__c, Published__c, Penalty_Amount__c, ' +
            'LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
            'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, PropertyType__c, Full_Property_Address__c ' +
            'FROM Penalty__c ' +
            'WHERE ' + whereClause + ' ' +
            'ORDER BY Issued_Date__c DESC ' +
            'LIMIT :pageSize ' +
            'OFFSET :offsetValue';

        List<Penalty__c> queriedPenalties = DatabaseWrapper.getInstance().queryWithBinds(query, bindMap);

        List<Penalty> penaltiesToReturn = new List<Penalty>();
        for(Penalty__c singlePenalty : queriedPenalties) {
            Penalty penalty = new Penalty(singlePenalty);
            penalty.build();
            penaltiesToReturn.add(penalty);
        }
        return penaltiesToReturn;
    }

    @AuraEnabled
    public static Id upsertPenalty(String penaltyAsJSON) {
        Id upsertedPenaltyId = null;
        if(String.isNotBlank(penaltyAsJSON)) {
            try {
                Penalty penaltyToCreate = (Penalty) JSON.deserialize(penaltyAsJSON, Penalty.class);
                Penalty__c penaltyToInsert = new Penalty__c();

                penaltyToInsert.Exemption__c = penaltyToCreate.exemptionId;
                penaltyToInsert.Exemption_Type_Link__c = penaltyToCreate.exemptionTypeId;

                List<String> issuedDateParts = penaltyToCreate.dateIssued.split('/');
                Date issuedDate = Date.newInstance(
                    Integer.valueOf(issuedDateParts[2]),
                    Integer.valueOf(issuedDateParts[1]),
                    Integer.valueOf(issuedDateParts[0])
                );
                penaltyToInsert.Issued_Date__c = issuedDate;

                penaltyToInsert.Penalty_Amount__c = penaltyToCreate.penaltyAmount;
                penaltyToInsert.Penalty_Reference__c = penaltyToCreate.reference;
                penaltyToInsert.Penalty_Type__c = penaltyToCreate.penaltyTypeId;
                penaltyToInsert.Published__c = penaltyToCreate.published;

                if(String.isNotBlank(penaltyToCreate.unpublishDate) && penaltyToCreate.unpublishDate != 'Not published') {
                    List<String> unpublishDateParts = penaltyToCreate.unpublishDate.split('/');
                    Date unpublishDate = Date.newInstance(
                        Integer.valueOf(unpublishDateParts[2]),
                        Integer.valueOf(unpublishDateParts[1]),
                        Integer.valueOf(unpublishDateParts[0])
                    );
                    penaltyToInsert.Unpublish_Date__c = unpublishDate;
                } else {
                    penaltyToInsert.Unpublish_Date__c = null;
                }
                penaltyToInsert.Id = String.isNotBlank(penaltyToCreate.penaltyId) ? penaltyToCreate.penaltyId : null;

                Exemption__c associatedExemption = getExemption(penaltyToCreate.exemptionId);
                penaltyToInsert.LandlordBusinessName__c = associatedExemption.LandlordBusinessName__c;
                penaltyToInsert.LandlordFirstName__c = associatedExemption.LandlordFirstName__c;
                penaltyToInsert.LandlordLastName__c = associatedExemption.LandlordLastName__c;
                penaltyToInsert.PropertyAddress__c = associatedExemption.PropertyAddress__c;
                penaltyToInsert.PropertyCity__c = associatedExemption.PropertyCity__c;
                penaltyToInsert.PropertyCounty__c = associatedExemption.PropertyCounty__c;
                penaltyToInsert.PropertyPostcode__c = associatedExemption.PropertyPostcode__c;
                penaltyToInsert.PropertyType__c = associatedExemption.PropertyType__c;
                penaltyToInsert.Local_Custodian_Code__c = associatedExemption.Local_Custodian_Code__c;
                penaltyToInsert.PropertyUPRN__c = associatedExemption.PropertyUPRN__c;

                upsertedPenaltyId = processUpsertResult(
                    DatabaseWrapper.getInstance().upsertRecord(penaltyToInsert)
                );
            } catch (Exception ex) {
                errorLoggingService.setLogCode('PRSE_LADashboardPenaltiesController')
                    .setTriggeringAutomationName('upsertPenalty')
                    .setMessage(ex.getMessage())
                    .setFullMessage(ex.getStackTraceString())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
            }
        }
        return upsertedPenaltyId;
    }

    @AuraEnabled
    public static Id upsertPenaltyWithoutExemption(String penaltyAsJSON) {
        Id upsertedPenaltyId = null;
        if(String.isNotBlank(penaltyAsJSON)) {
            try {
                Penalty penaltyToCreate = (Penalty) JSON.deserialize(penaltyAsJSON, Penalty.class);
                Penalty__c penaltyToInsert = new Penalty__c();

                String penaltyAddress = penaltyToCreate.propertyAddress + ', ' + penaltyToCreate.propertyCity + ', ' + penaltyToCreate.propertyPostcode;
                List<DeliveryPointAddress> directPostalAddresses = OSPlacesInteractionService.matchAddressForEnglandOrWalesOnly(penaltyAddress);
                if(directPostalAddresses != null && directPostalAddresses.size() > 0) {
                    DeliveryPointAddress highestMatchedAddress = directPostalAddresses[0];
                    penaltyToInsert.Local_Custodian_Code__c = String.valueOf(highestMatchedAddress.LOCAL_CUSTODIAN_CODE);
                    penaltyToInsert.PropertyUPRN__c = String.valueOf(highestMatchedAddress.UPRN);
                }
                penaltyToInsert.PropertyAddress__c = penaltyToCreate.propertyAddress;
                penaltyToInsert.PropertyCity__c = penaltyToCreate.propertyCity;
                penaltyToInsert.PropertyPostcode__c = penaltyToCreate.propertyPostcode;
                penaltyToInsert.PropertyCounty__c = penaltyToCreate.propertyCounty;
                penaltyToInsert.PropertyType__c = penaltyToCreate.propertyType;

                List<String> issuedDateParts = penaltyToCreate.dateIssued.split('/');
                Date issuedDate = Date.newInstance(
                    Integer.valueOf(issuedDateParts[2]),
                    Integer.valueOf(issuedDateParts[1]),
                    Integer.valueOf(issuedDateParts[0])
                );
                penaltyToInsert.Issued_Date__c = issuedDate;

                penaltyToInsert.Penalty_Amount__c = penaltyToCreate.penaltyAmount;
                penaltyToInsert.Penalty_Reference__c = penaltyToCreate.reference;
                penaltyToInsert.Penalty_Type__c = penaltyToCreate.penaltyTypeId;
                penaltyToInsert.Published__c = penaltyToCreate.published;

                if(String.isNotBlank(penaltyToCreate.unpublishDate) && penaltyToCreate.unpublishDate != 'Not published') {
                    List<String> unpublishDateParts = penaltyToCreate.unpublishDate.split('/');
                    Date unpublishDate = Date.newInstance(
                        Integer.valueOf(unpublishDateParts[2]),
                        Integer.valueOf(unpublishDateParts[1]),
                        Integer.valueOf(unpublishDateParts[0])
                    );
                    penaltyToInsert.Unpublish_Date__c = unpublishDate;
                } else {
                    penaltyToInsert.Unpublish_Date__c = null;
                }
                penaltyToInsert.Id = String.isNotBlank(penaltyToCreate.penaltyId) ? penaltyToCreate.penaltyId : null;

                penaltyToInsert.LandlordBusinessName__c = penaltyToCreate.landlordBusinessName;
                penaltyToInsert.LandlordFirstName__c = penaltyToCreate.landlordFirstName;
                penaltyToInsert.LandlordLastName__c = penaltyToCreate.landlordLastName;

                upsertedPenaltyId = processUpsertResult(
                    DatabaseWrapper.getInstance().upsertRecord(penaltyToInsert)
                );
            } catch (Exception ex) {
                errorLoggingService.setLogCode('PRSE_LADashboardPenaltiesController')
                    .setTriggeringAutomationName('upsertPenaltyWithoutExemption')
                    .setMessage(ex.getMessage())
                    .setFullMessage(ex.getStackTraceString())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
            }
        }
        return upsertedPenaltyId;
    }

    @AuraEnabled
    public static void deletePenalty(String penaltyId) {
        if(String.isNotBlank(penaltyId)) {
            try {
                Boolean hasAccess = PRSE_LAViewExemptionHelper.checkPenalty(penaltyId);
                if(hasAccess) {
                    processDeleteResult(
                        DatabaseWrapper.getInstance().deleteRecordWithId(penaltyId)
                    );
                }

            } catch (Exception ex) {
                errorLoggingService.setLogCode('PRSE_LADashboardPenaltiesController')
                    .setTriggeringAutomationName('deletePenalty')
                    .setMessage(ex.getMessage())
                    .setFullMessage(ex.getStackTraceString())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
            }
        }
    }

    @AuraEnabled
    public static List<Penalty_Type__c> getPenaltyTypes() {
        List<Penalty_Type__c> penaltyTypesToReturn = new List<Penalty_Type__c>();
        try {
            penaltyTypesToReturn = ((List<Penalty_Type__c>) DatabaseWrapper.getInstance()
                .query(
                    'SELECT Id, Name, Code__c FROM Penalty_Type__c ORDER BY Code__C ASC'
                ));
        } catch (Exception ex) {
            errorLoggingService.setLogCode('PRSE_LADashboardPenaltiesController')
                .setTriggeringAutomationName('getPenaltyTypes')
                .setMessage(ex.getMessage())
                .setFullMessage(ex.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return penaltyTypesToReturn;
    }

    private static String buildAddress(DeliveryPointAddress addressRecord) {
        List<String> addressParts = new List<String>();
        
        if (String.isNotBlank(addressRecord.ORGANISATION_NAME)) {
            addressParts.add(addressRecord.ORGANISATION_NAME);
        }
        
        if (String.isNotBlank(addressRecord.SUB_BUILDING_NAME)) {
            addressParts.add(addressRecord.SUB_BUILDING_NAME);
        }
        
        if (String.isNotBlank(addressRecord.BUILDING_NAME)) {
            addressParts.add(addressRecord.BUILDING_NAME);
        }
        
        if (addressRecord.BUILDING_NUMBER != null) {
            addressParts.add(String.valueOf(addressRecord.BUILDING_NUMBER));
        }
        
        if (String.isNotBlank(addressRecord.THOROUGHFARE_NAME)) {
            addressParts.add(addressRecord.THOROUGHFARE_NAME);
        }
        
        return String.join(addressParts, ', ');
    }


    private static Exemption__c getExemption(String exemptionId) {
        Exemption__c toReturn;
        Map<String, Object> bindMap = new Map<String, Object> { 
            'exemptionId' => exemptionId
        };
        List<Exemption__c> queriedExemption = ((List<Exemption__c>) DatabaseWrapper.getInstance().queryWithBinds(
            'SELECT Id, LandlordBusinessName__c, LandlordFirstName__c, LandlordLastName__c, ' +
            'PropertyAddress__c, PropertyCity__c, PropertyCounty__c, PropertyPostcode__c, ' +
            'PropertyType__c, Local_Custodian_Code__c, PropertyUPRN__c ' +
            'FROM Exemption__c ' +
            'WHERE Id = :exemptionId ' +
            'LIMIT 1', 
            bindMap
        ));
        
        if(queriedExemption.size() > 0) {
            toReturn = queriedExemption[0];
        }
        return toReturn;
    }

    private static Id processUpsertResult(Database.UpsertResult upsertResult) {
        if(upsertResult == null || !upsertResult.isSuccess()) {
             List<String> allErrors = new List<String>();
            for(Database.Error singleError :upsertResult.getErrors()) {
                allErrors.add(singleError.getMessage());
            }
            errorLoggingService.setLogCode('PRSE_LADashboardPenaltiesController')
                .setTriggeringAutomationName('upsertPenalty')
                .setMessage('Failed to upsert penalty')
                .setFullMessage(String.join(allErrors, ', '))
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
            return null;
        } else {
            return upsertResult.getId();
        }
    }

    private static void processDeleteResult(Database.DeleteResult deleteResult) {
        if(!deleteResult.isSuccess()) {
            List<String> allErrors = new List<String>();
            for(Database.Error singleError :deleteResult.getErrors()) {
                allErrors.add(singleError.getMessage());
            }
            errorLoggingService.setLogCode('PRSE_LADashboardPenaltiesController')
                .setTriggeringAutomationName('deletePenalty')
                .setMessage('Failed to delete penalty')
                .setFullMessage(String.join(allErrors, ', '))
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
    }

    private static String buildLikeClauses(Map<String, Object> bindMapToAddTo, List<String> fieldsToAddFor, String filterSearchTerm) {
        String escapedSearchTerm = String.escapeSingleQuotes(filterSearchTerm).trim();
        String trimmedAndEscapedSearchTerm = String.escapeSingleQuotes(filterSearchTerm).remove(' ');
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
        public List<String> localAuthorityCodes;
        public List<String> penaltyTypeCodes;
        public String searchTerm;
        public String propertyType;
        public String parentExemptionId;
    }

    public class PaginatedResult {
        @AuraEnabled 
        public List<Penalty> records { get; set; }
        @AuraEnabled 
        public Integer totalRecords { get; set; }
        @AuraEnabled 
        public Integer pageSize { get; set; }
        @AuraEnabled 
        public Integer pageNumber { get; set; }
    }

    public class Penalty {
        private Penalty__c penalty;
        @AuraEnabled
        public String penaltyId;

        @AuraEnabled
        public String reference;

        @AuraEnabled
        public String exemptionId;

        @AuraEnabled
        public String exemptionType;
        @AuraEnabled
        public String exemptionTypeId;

        @AuraEnabled
        public String penaltyType;
        @AuraEnabled
        public String penaltyTypeId;

        @AuraEnabled
        public String dateIssued;
        @AuraEnabled
        public String unpublishDate;

        @AuraEnabled
        public Boolean published;

        @AuraEnabled
        public Decimal penaltyAmount;

        @AuraEnabled
        public String landlordBusinessName;

        @AuraEnabled
        public String landlordFirstName;

        @AuraEnabled
        public String landlordLastName;

        @AuraEnabled
        public String landlordType;

        @AuraEnabled
        public String fullPropertyAddress;

        @AuraEnabled
        public String propertyAddress;

        @AuraEnabled
        public String propertyCity;

        @AuraEnabled
        public String propertyCounty;

        @AuraEnabled
        public String propertyPostcode;

        @AuraEnabled
        public String propertyType;

        public Penalty() {}

        public Penalty(Penalty__c penalty) {
            this.penalty = penalty;
            this.penaltyId = penalty.Id;
        }

        private void withReferenceNumber() {
            this.reference = penalty.Penalty_Reference__c;
        }

        private void withExemptionType() {
            this.exemptionType = penalty.Exemption_Type_Link__r.Name;
            this.exemptionTypeId = penalty.Exemption_Type_Link__c;
        }

        private void withPenaltyType() {
            this.penaltyType = penalty.Penalty_Type__r.Name;
            this.penaltyTypeId = penalty.Penalty_Type__c;
        }

        private void withIssueDate() {
            String issueDate = '';
            if(penalty.Issued_Date__c != null) {
                issueDate = penalty.Issued_Date__c?.day() + '/' 
                          + penalty.Issued_Date__c?.month() + '/' 
                          + penalty.Issued_Date__c?.year();
            }
            this.dateIssued = issueDate;
        }

        private void withUnpublishDate() {
            String unpublishDate = '';
            if(penalty.Unpublish_Date__c != null) {
                unpublishDate = penalty.Unpublish_Date__c.day() + '/' 
                              + penalty.Unpublish_Date__c.month() + '/' 
                              + penalty.Unpublish_Date__c.year();
            }

            this.unpublishDate = unpublishDate;
        }

        private void withPublished() {
            this.published = penalty.Published__c;
        }

        private void withPenaltyAmount() {
            this.penaltyAmount = penalty.Penalty_Amount__c;
        }

        private void withExemptionId() {
            this.exemptionId = penalty.Exemption__c;
        }

        private void withLandlord() {
            this.landlordBusinessName = penalty.LandlordBusinessName__c;
            this.landlordFirstName = penalty.LandlordFirstName__c;
            this.landlordLastName = penalty.LandlordLastName__c;
            this.landlordType = String.isNotBlank(penalty.LandlordBusinessName__c) ? 'An organisation or business' : 'A person';
        }

        public void withFullPropertyAddress() {
            this.fullPropertyAddress = penalty.Full_Property_Address__c;
        }

        private void withPropertyAddress() {
            this.propertyAddress = penalty.PropertyAddress__c;
        }

        private void withPropertyCity() {
            this.propertyCity = penalty.PropertyCity__c;
        }

        private void withPropertyCounty() {
            this.propertyCounty = penalty.PropertyCounty__c;
        }

        private void withPropertyPostcode() {
            this.propertyPostcode = penalty.PropertyPostcode__c;
        }

        private void withPropertyType() {
            this.propertyType = penalty.PropertyType__c;
        }

        public Penalty build() {
            withReferenceNumber();
            withExemptionType();
            withPenaltyType();
            withIssueDate();
            withUnpublishDate();
            withPublished();
            withPenaltyAmount();
            withExemptionId();
            withLandlord();
            withFullPropertyAddress();
            withPropertyAddress();
            withPropertyCity();
            withPropertyCounty();
            withPropertyPostcode();
            withPropertyType();
            return this;
        }
    }
}