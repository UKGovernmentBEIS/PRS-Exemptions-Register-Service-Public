/**
 * @class PRSE_LAViewExemptionHelper
 * @description
 * This helper class provides utility methods for working with Local Authority
 * related exemptions in the PRSE application. Currently, it contains a method
 * to check whether a given Exemption__c record belongs to any Local Authorities
 * associated with the current user.
 *
 * @note This class is defined as "without sharing" to ensure that it can access
 * all necessary Account and Exemption__c records regardless of the running user's
 * sharing rules. Be aware of security implications when using without sharing.
 */
public without sharing class PRSE_LAViewExemptionHelper {

    @TestVisible
    private static PRSE_LAViewExemptionHelper instance = new PRSE_LAViewExemptionHelper();

    public static Boolean checkExemption(Id exemptionId) {
        return instance.checkExemptionInstance(exemptionId);
    }

    public static Boolean checkPenalty(Id penaltyId) {
        return instance.checkPenaltyInstance(penaltyId);
    }

    /**
     * Checks whether a given Exemption__c record belongs to one of the Local Authorities
     * linked to the current user's Contact.
     *
     * @param exemptionId The Id of the Exemption__c record to check.
     * @return Boolean Returns true if the exemption belongs to at least one Local Authority
     *                 associated with the current user's Contact; false otherwise.
     *
     * @example
     * <code>
     * Id exemptionId = 'a0B3h00000Xyz123';
     * Boolean isAllowed = PRSE_LAViewExemptionHelper.checkExemption(exemptionId);
     * System.debug('Exemption belongs to user’s Local Authorities: ' + isAllowed);
     * </code>
     *
     * @implementation
     * Steps performed by this method:
     *   1. Validates that the provided exemptionId is not null.
     *   2. Queries the current User record to retrieve the associated ContactId.
     *      Returns false if ContactId is null.
     *   3. Queries the RecordType object to get the Id of the "Local Authority"
     *      RecordType for Accounts.
     *   4. Queries all AccountContactRelation records for this ContactId where the
     *      linked Account has the Local Authority RecordType. Builds a Set of
     *      Local_Custodian_Code__c values from the linked Accounts.
     *   5. If no Local Authority codes are found, returns false.
     *   6. Queries Exemption__c with the given Id and checks if its Local_Custodian_Code__c
     *      is in the Set of Local Authority codes. Returns true if found, otherwise false.
     *
     * @limits
     *   - 3 SOQL queries are executed (User, RecordType, AccountContactRelation, Exemption__c).
     *   - Single exemptionId is processed per method call.
     */
    public virtual Boolean checkExemptionInstance(Id exemptionId) {
        // Return false immediately if input is null
        if (exemptionId == null) {
            return false;
        }     

        // Step 1: Get the current user's ContactId
        //Id contactId = '003Pv000010KeNOIA0';
        Id contactId = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ].ContactId;
        if (contactId == null) {
            return false;
        }

        // Step 2: Get Local Authority RecordType Id for Accounts
        Id laRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
              AND Name = 'Local Authority'
            LIMIT 1
        ].Id;
        
        // Step 3: Get all Local Authorities linked to this user's contact
        List<AccountContactRelation> relations = [
            SELECT Id, ContactId, AccountId, 
                   Account.Id, Account.Name, Account.Local_Custodian_Code__c, Account.RecordTypeId
            FROM AccountContactRelation
            WHERE ContactId = :contactId
              AND Account.RecordTypeId = :laRecordTypeId
        ];

        // Build a set of all Local Authority custodian codes
        Set<String> localAuthorityCodes = new Set<String>();
        for (AccountContactRelation acr : relations) {
            if (acr.Account.Local_Custodian_Code__c != null) {
                localAuthorityCodes.add(acr.Account.Local_Custodian_Code__c);
            }
        }

        // If no Local Authority codes found, the exemption cannot belong to any
        if (localAuthorityCodes.isEmpty()) {
            return false;
        }

        // Step 4: Check if the Exemption__c record belongs to one of the Local Authorities
        List<Exemption__c> matching = [
            SELECT Id
            FROM Exemption__c
            WHERE Id = :exemptionId
              AND Local_Custodian_Code__c IN :localAuthorityCodes
            LIMIT 1
        ];

        return !matching.isEmpty();
    }

    public virtual Boolean checkPenaltyInstance(Id penaltyId) {
        // Return false immediately if input is null
        if (penaltyId == null) {
            return false;
        }     

        // Step 1: Get the current user's ContactId
        Id contactId = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ].ContactId;
        if (contactId == null) {
            return false;
        }

        // Step 2: Get Local Authority RecordType Id for Accounts
        Id laRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
              AND Name = 'Local Authority'
            LIMIT 1
        ].Id;
        
        // Step 3: Get all Local Authorities linked to this user's contact
        List<AccountContactRelation> relations = [
            SELECT Id, ContactId, AccountId, 
                   Account.Id, Account.Name, Account.Local_Custodian_Code__c, Account.RecordTypeId
            FROM AccountContactRelation
            WHERE ContactId = :contactId
              AND Account.RecordTypeId = :laRecordTypeId
        ];

        // Build a set of all Local Authority custodian codes
        Set<String> localAuthorityCodes = new Set<String>();
        for (AccountContactRelation acr : relations) {
            if (acr.Account.Local_Custodian_Code__c != null) {
                localAuthorityCodes.add(acr.Account.Local_Custodian_Code__c);
            }
        }

        // If no Local Authority codes found, the exemption cannot belong to any
        if (localAuthorityCodes.isEmpty()) {
            return false;
        }

        // Step 4: Check if the Penalty__c record belongs to one of the Local Authorities
        List<Penalty__c> matching = [
            SELECT Id
            FROM Penalty__c
            WHERE Id = :penaltyId
              AND Local_Custodian_Code__c IN :localAuthorityCodes
            LIMIT 1
        ];

        return !matching.isEmpty();
    }
}