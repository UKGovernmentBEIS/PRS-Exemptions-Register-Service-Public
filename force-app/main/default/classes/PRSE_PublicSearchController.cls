/**
 * @description       Controller used for public searches of Exemptions and Penalties.
 *                    Provides search and paginated search methods for UI use.
 * @group             PRS Public Search
 * @since             1.0
 */
public without sharing class PRSE_PublicSearchController {
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('PRSE_LocalAuthorityDashboardController');

    private static final Integer defaultPageSize = 20;

    /**
     * @description       Search property exemptions with pagination by postcode.
     * @param postcode    Postcode to search for.
     * @param pageSize    Number of records per page.
     * @param pageNumber  Page number to return.
     * @return            PaginatedExemptionResult containing records and metadata.
     * @throws AuraHandledException if postcode is blank.
     */
    @AuraEnabled(cacheable=true)
    public static PaginatedExemptionResult searchPropertyExemptionsPaginated(String postcode, Integer pageSize, Integer pageNumber) {
        try{
            if (String.isBlank(postcode)) {
                throw new AuraHandledException('Postcode is required.');
            }

            // Default values
            if (pageSize == null || pageSize <= 0) pageSize = defaultPageSize;
            if (pageNumber == null || pageNumber <= 0) pageNumber = 1;

            // Normalize postcode and add LIKE wildcard
            String pc = postcode.trim().toUpperCase() + '%';

            // --- Get total count ---
            Integer totalCount = [SELECT COUNT() 
                                FROM Exemption__c 
                                WHERE Property_Postcode_No_Spaces__c LIKE :pc
                                AND Status__c != 'Draft'];

            // --- Get paginated results ---
        
            List<Exemption__c> exemptions = [
                SELECT Id, Name, Status__c, Full_Property_Address__c, PropertyPostcode__c, LandlordBusinessName__c, Registered_Date__c
                FROM Exemption__c
                WHERE Property_Postcode_No_Spaces__c LIKE :pc
                AND Status__c != 'Draft'
            ];

            // --- Sort ALL records ---
            List<Exemption__c> sortedExemptions = sortExemptions(exemptions);

            // --- Manually paginate the sorted list ---
            Integer startIndex = (pageNumber - 1) * pageSize;
            Integer endIndex = Math.min(startIndex + pageSize, sortedExemptions.size());
            
            List<Exemption__c> pageRecords = new List<Exemption__c>();
            for (Integer i = startIndex; i < endIndex; i++) {
                pageRecords.add(sortedExemptions[i]);
            }

            // --- Wrap in paginated result ---
            PaginatedExemptionResult result = new PaginatedExemptionResult();
            result.records = pageRecords;
            result.totalRecords = totalCount;
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;

            return result;
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_PublicSearchController')
            .setTriggeringAutomationName('searchPropertyExemptionsPaginated')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error retrieving exemptions: ' + e.getMessage());
        }
        
    }


    /**
     * @description       Search property exemptions using multiple optional filters with pagination.
     */
    @AuraEnabled(cacheable=true)
    public static PaginatedExemptionResult searchPropertyExemptionsOtherWaysPaginated(String propertyAddress, String townOrCity, String landlordsName, String propertyType, String exemptionType, Integer pageSize, Integer pageNumber) {
        // Default values
        if (pageSize == null || pageSize <= 0) pageSize = defaultPageSize;
        if (pageNumber == null || pageNumber <= 0) pageNumber = 1;
        
        String whereClause = 'WHERE Id != NULL AND Status__c != \'Draft\'';

        if (String.isNotBlank(propertyAddress)) {
            whereClause += ' AND PropertyAddress__c = :propertyAddress';
        }
        
        if (String.isNotBlank(townOrCity)) {
            whereClause += ' AND PropertyCity__c = :townOrCity';
        }
        
        if (String.isNotBlank(landlordsName)) {
            whereClause += ' AND LandlordBusinessName__c LIKE \'%' + sanitizeForLike(landlordsName) + '%\'';
        }

        if (String.isNotBlank(propertyType) && propertyType != 'All Properties') {
            whereClause += ' AND PropertyType__c = :propertyType';
        }
        
        if (String.isNotBlank(exemptionType) && exemptionType != 'All types') {
            whereClause += ' AND Id IN (' +
                           ' SELECT Exemption__c FROM Exemption_Type_Link__c ' +
                           ' WHERE Exemption_Type__r.Name = :exemptionType' +
                           ')';
        }

        // --- Get total count ---
        String countQuery =
            'SELECT COUNT() FROM Exemption__c ' +
            whereClause;

        String dataQuery = 'SELECT '
                    + 'Id, Name, Status__c, '
                    + 'Full_Property_Address__c, PropertyPostcode__c, LandlordBusinessName__c, '
                    + 'Registered_Date__c, PropertyType__c '
                    + 'FROM Exemption__c '
                    + whereClause; 

        PaginatedExemptionResult result = new PaginatedExemptionResult();       

        try {

            // Validate that at least one search criteria is provided
            if (String.isBlank(propertyAddress) && String.isBlank(townOrCity) && 
                String.isBlank(landlordsName) && String.isBlank(propertyType) && 
                String.isBlank(exemptionType)) {
                throw new QueryException('At least one search criteria must be provided');
            }

            result.totalRecords = Database.countQuery(countQuery);

            List<Exemption__c> allExemptions = Database.query(dataQuery);

            // Sort ALL exemptions
            List<Exemption__c> sortedExemptions = sortExemptions(allExemptions);

            // --- Manually paginate the sorted list ---
            Integer startIndex = (pageNumber - 1) * pageSize;
            Integer endIndex = Math.min(startIndex + pageSize, sortedExemptions.size());
            
            List<Exemption__c> pageRecords = new List<Exemption__c>();
            for (Integer i = startIndex; i < endIndex; i++) {
                pageRecords.add(sortedExemptions[i]);
            }
            result.records = pageRecords;
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;
            return result;
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_PublicSearchController')
            .setTriggeringAutomationName('searchPropertyExemptionsOtherWaysPaginated')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error retrieving exemptions: ' + e.getMessage());
        }
    }


    /**
     * @description       Search property penalties with pagination by postcode (partial match).
     */
    @AuraEnabled(cacheable=true)
    public static PaginatedPenaltyResult searchPropertyPenaltiesPaginated(String postcode, Integer pageSize, Integer pageNumber) {
        try {
            if (String.isBlank(postcode)) {
                throw new AuraHandledException('Postcode is required.');
            }

            String pc = postcode.trim().toUpperCase();
            pc = pc + '%'; // for LIKE operator for partial matching

            // Default values
            if (pageSize == null || pageSize <= 0) pageSize = defaultPageSize;
            if (pageNumber == null || pageNumber <= 0) pageNumber = 1;

            PaginatedPenaltyResult result = new PaginatedPenaltyResult();

            Integer totalRecords = [
                SELECT COUNT()
                FROM Penalty__c
                WHERE Property_Postcode_No_Spaces__c LIKE :pc
                AND Published__c = true
                AND (Exemption__c = NULL OR Exemption__r.Status__c != 'Draft')
                
            ];

            List<Penalty__c> rawPenalties = [
                SELECT Id,
                    Published__c,
                    Full_Property_Address__c,
                    LandlordBusinessName__c,
                	Exemption__c,
                	Exemption__r.Status__c                
                FROM Penalty__c
                WHERE Property_Postcode_No_Spaces__c LIKE :pc
                AND Published__c = true
                AND (Exemption__c = NULL OR Exemption__r.Status__c != 'Draft')
                
            ];            
            
            // --- Sort ALL penalties ---
            List<Penalty__c> sortedPenalties = sortPenalties(rawPenalties);

            // --- Manually paginate the sorted list ---
            Integer startIndex = (pageNumber - 1) * pageSize;
            Integer endIndex = Math.min(startIndex + pageSize, sortedPenalties.size());
            
            List<Penalty__c> pageRecords = new List<Penalty__c>();
            for (Integer i = startIndex; i < endIndex; i++) {
                pageRecords.add(sortedPenalties[i]);
            }

            result.records = pageRecords;
            result.totalRecords = totalRecords;
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;

            return result;

        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_PublicSearchController')
            .setTriggeringAutomationName('searchPropertyPenaltiesPaginated')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error retrieving penalties: ' + e.getMessage());
        }
    }


    /**
     * @description       Search property penalties by multiple optional filters with pagination.
     */
    @AuraEnabled(cacheable=true)
    public static PaginatedPenaltyResult searchPropertyPenaltiesOtherWaysPaginated(String propertyAddress, String townOrCity, String landlordsName, String propertyType, String penaltyType, Integer pageSize, Integer pageNumber) {

        // Default values
        if (pageSize == null || pageSize <= 0) pageSize = defaultPageSize;
        if (pageNumber == null || pageNumber <= 0) pageNumber = 1;

        String whereClause = 'WHERE Id != NULL AND (Exemption__c = NULL OR Exemption__r.Status__c != \'Draft\')';

        if (String.isNotBlank(propertyAddress)) {
            whereClause += ' AND PropertyAddress__c = :propertyAddress';
        }
        
        if (String.isNotBlank(townOrCity)) {
            whereClause += ' AND PropertyCity__c = :townOrCity';
        }
        
        if (String.isNotBlank(landlordsName)) {
            whereClause += ' AND LandlordBusinessName__c LIKE \'%' + sanitizeForLike(landlordsName) + '%\'';
        }

        if (String.isNotBlank(propertyType) && propertyType != 'All Properties') {
            whereClause += ' AND PropertyType__c = :propertyType';
        }
        
        if (String.isNotBlank(penaltyType) && penaltyType != 'All types') {
            whereClause += ' AND Penalty_Type__r.Code__c = :penaltyType';
        }

        whereClause += ' AND Published__c = true';

        String countQuery =
            'SELECT COUNT() ' +
            'FROM Penalty__c ' +
            whereClause;

        String dataQuery =
            'SELECT ' +
            'Id, Full_Property_Address__c, LandlordBusinessName__c,Published__c ' +
            'FROM Penalty__c ' +
            whereClause;

        PaginatedPenaltyResult result = new PaginatedPenaltyResult();

        try {
            // Validate that at least one search criteria is provided
            if (String.isBlank(propertyAddress) && String.isBlank(townOrCity) && 
                String.isBlank(landlordsName) && String.isBlank(propertyType) && 
                String.isBlank(penaltyType)) {
                throw new QueryException('At least one search criteria must be provided');
            }

            Integer totalRecords = (Integer)Database.countQuery(countQuery);

            // Get ALL penalties
            List<Penalty__c> allPenalties = Database.query(dataQuery);

            // Sort ALL penalties
            List<Penalty__c> sortedPenalties = sortPenalties(allPenalties);

            // --- Manually paginate the sorted list ---
            Integer startIndex = (pageNumber - 1) * pageSize;
            Integer endIndex = Math.min(startIndex + pageSize, sortedPenalties.size());
            
            List<Penalty__c> pageRecords = new List<Penalty__c>();
            for (Integer i = startIndex; i < endIndex; i++) {
                pageRecords.add(sortedPenalties[i]);
            }

            result.records = pageRecords;
            result.totalRecords = totalRecords;
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;

            return result;

        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_PublicSearchController')
            .setTriggeringAutomationName('searchPropertyPenaltiesOtherWaysPaginated')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error retrieving penalties: ' + e.getMessage());
        }
    }


    // --- helpers ---
    /**
     * @description Sanitizes user input for safe use in SOQL LIKE clauses by escaping 
     *              single quotes and SOQL wildcard characters to prevent SQL injection 
     *              and unintended pattern matching.
     * @param input The user-provided string to sanitize
     * @return The sanitized string safe for use in dynamic SOQL LIKE clauses, or the 
     *         original input if blank
     * @example
     * String userInput = 'O\'Reilly%';
     * String safe = sanitizeForLike(userInput);
     * String query = 'SELECT Id FROM Account WHERE Name LIKE \'%' + safe + '%\'';
     */
    public static String sanitizeForLike(String input) {
        if (String.isBlank(input)) {
            return input;
        }
        
        return String.escapeSingleQuotes(input)
            .replace('\\', '\\\\')
            .replace('%', '\\%')
            .replace('_', '\\_');
    }

    /**
     * @description       Normalizes a raw postcode by trimming, uppercasing, and ensuring a space before the last 3 characters.
     * @param raw         The raw postcode string.
     * @return            Normalized postcode string.
     */
    private static String normalisePostcode(String raw) {
        String s = (raw == null) ? '' : raw.trim().toUpperCase();
        s = s.replaceAll('\\s+', '');
        if (s.length() > 3) {
            s = s.substring(0, s.length() - 3) + ' ' + s.substring(s.length() - 3);
        }
        return s;
    }


    /**
     * @description       Retrieves all exemption types.
     * @return            List of Exemption_Type__c records including Id, Name, and IsCommercial__c flag.
     */
    @AuraEnabled(cacheable=true)
    public static List<Exemption_Type__c> getExemptionTypes(){
        return [
            SELECT Id, Name, IsCommercial__c
            FROM Exemption_Type__c
        ];
    }


    /**
     * @description       Retrieves all penalty types.
     * @return            List of Penalty_Type__c records including Id, Name, and Code__c
     */
    @AuraEnabled(cacheable=true)
    public static List<Penalty_Type__c> getPenaltyTypes(){
        return [
            SELECT Id, Name, Code__c
            FROM Penalty_Type__c
        ];
    }    


    // Wrapper class to hold SObject + flattened address
    public class PropertyWrapper {
        public SObject record;
        public String address;

        public PropertyWrapper(SObject r) {
            this.record = r;

            if (r instanceof Exemption__c) {
                this.address = safeString(((Exemption__c)r).Full_Property_Address__c);
            } else if (r instanceof Penalty__c) {
                Penalty__c p = (Penalty__c)r;
                this.address = safeString(p.Full_Property_Address__c);
            } else {
                this.address = '';
            }
        }

        // Helper to convert null → empty string
        private String safeString(String s) {
            return s == null ? '' : s;
        }
    }

    // Comparator for sorting by numeric then alphabetical order
    public class AddressComparator implements System.Comparator<PropertyWrapper> {
        public Integer compare(PropertyWrapper a, PropertyWrapper b) {
            String addrA = a.address != null ? a.address : '';
            String addrB = b.address != null ? b.address : '';

            Integer numA = extractLeadingNumber(addrA);
            Integer numB = extractLeadingNumber(addrB);

            // Both have numbers → numeric compare
            if (numA != null && numB != null) {
                if (numA < numB) return -1;
                if (numA > numB) return 1;
                // numbers equal → fall through to alphabetical
            }

            // Only one has number → number comes first
            if (numA != null && numB == null) return -1;
            if (numA == null && numB != null) return 1;

            // Neither has number or numbers equal → alphabetical
            return addrA.toLowerCase().compareTo(addrB.toLowerCase());
        }

        private Integer extractLeadingNumber(String addr) {
            if (String.isBlank(addr)) return null;
            Matcher m = Pattern.compile('^(\\d+)').matcher(addr.trim());
            if (m.find()) return Integer.valueOf(m.group(1));
            return null;
        }
    }


    private static List<Exemption__c> sortExemptions(List<Exemption__c> exemptions) {
        // 1. Wrap
        List<PropertyWrapper> wrappers = new List<PropertyWrapper>();
        for(Exemption__c ex : exemptions){
            wrappers.add(new PropertyWrapper(ex));
        }

        // 2. Sort wrappers
        wrappers.sort(new AddressComparator());

        // 3. Extract sorted Exemption__c
        List<Exemption__c> sortedExemptions = new List<Exemption__c>();
        for(PropertyWrapper w : wrappers){
            if(w.record instanceof Exemption__c){
                sortedExemptions.add((Exemption__c)w.record);
            }
        }

        return sortedExemptions;
    }

    private static List<Penalty__c> sortPenalties(List<Penalty__c> penalties) {
        // 1. Wrap
        List<PropertyWrapper> wrappers = new List<PropertyWrapper>();
        for(Penalty__c pn : penalties){
            wrappers.add(new PropertyWrapper(pn));
        }

        // 2. Sort wrappers
        wrappers.sort(new AddressComparator());

        // 3. Extract sorted Penalty__c
        List<Penalty__c> sortedPenalties = new List<Penalty__c>();
        for(PropertyWrapper w : wrappers){
            if(w.record instanceof Penalty__c){
                sortedPenalties.add((Penalty__c)w.record);
            }
        }

        return sortedPenalties;
    }


    /**
     * @description       Wrapper for paginated exemption results.
     */
    public class PaginatedExemptionResult {
        @AuraEnabled public List<Exemption__c> records { get; set; }
        @AuraEnabled public Integer totalRecords { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
    }

    /**
     * @description       Wrapper for paginated penalty results.
     */
    public class PaginatedPenaltyResult {
        @AuraEnabled public List<Penalty__c> records { get; set; }
        @AuraEnabled public Integer totalRecords { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
    }

}