public with sharing class PRSE_DashboardController {
    public class PaginatedResult {
        @AuraEnabled public List<sObject> records { get; set; }
        @AuraEnabled public Integer totalRecords { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getTotalExemptions(String status){

        if(status == 'draft'){
            return [
                SELECT COUNT()
                FROM Exemption__c
                WHERE (Status__c = 'Draft')
                AND OwnerId = :UserInfo.getUserId()
            ];
        } else if(status == 'registered'){
            return [
                SELECT COUNT() 
                FROM Exemption__c 
                WHERE (Status__c = 'Received' OR Status__c = 'Needs update' OR Status__c = 'Updated' OR Status__c = 'Penalty sent' OR Status__c = 'Approved')
                AND OwnerId = :UserInfo.getUserId()
            ];
        } else {
            return [
                SELECT COUNT() 
                FROM Exemption_Type_Link__c 
                WHERE End_Date__c != null
                AND Exemption__r.OwnerId = :UserInfo.getUserId()
            ];
        }
    }

    @AuraEnabled(cacheable=true)
    public static PaginatedResult getExemptionRecords(Integer pageSize, Integer pageNumber, String status) {
        if (pageSize == null || pageSize <= 0) {
            pageSize = 20;
        }
        if (pageNumber == null || pageNumber <= 0) {
            pageNumber = 1;
        }

        Integer offsetValue = (pageNumber - 1) * pageSize;

        Integer totalCount = getTotalExemptions(status);

        List<sObject> exemptionRecords = getExemptionRecordsByStatus(pageSize, offsetValue, status);

        PaginatedResult result = new PaginatedResult();
        result.records = exemptionRecords;
        result.totalRecords = totalCount;
        result.pageSize = pageSize;
        result.pageNumber = pageNumber;
        return result;
    }

    public static List<sObject> getExemptionRecordsByStatus(Integer pageSize, Integer offsetValue, String status){
        if(status == 'draft'){
            return [
                SELECT Id, Ref_Number__c, PropertyAddress__c, PropertyPostcode__c, CreatedDate
                FROM Exemption__c 
                WHERE (Status__c = 'Draft')
                AND OwnerId = :UserInfo.getUserId()
                ORDER BY CreatedDate DESC
                LIMIT :pageSize
                OFFSET :offsetValue
            ];
        } else if(status == 'registered'){
            List<Exemption__c> allRecords = [
                SELECT Id, Status__c, Ref_Number__c, PropertyAddress__c, PropertyPostcode__c, Registered_Date__c
                FROM Exemption__c 
                WHERE (Status__c = 'Received' OR Status__c = 'Needs update' OR Status__c = 'Updated' OR Status__c = 'Penalty sent' OR Status__c = 'Approved')
                AND OwnerId = :UserInfo.getUserId()
                ORDER BY Registered_Date__c DESC
            ];
            
            List<Exemption__c> needsUpdate = new List<Exemption__c>();
            List<Exemption__c> others = new List<Exemption__c>();
            
            for(Exemption__c record : allRecords) {
                if(record.Status__c == 'Needs update') {
                    needsUpdate.add(record);
                } else {
                    others.add(record);
                }
            }
            
            List<Exemption__c> sortedRecords = new List<Exemption__c>();
            sortedRecords.addAll(needsUpdate);
            sortedRecords.addAll(others);
            
            List<Exemption__c> paginatedRecords = new List<Exemption__c>();
            Integer startIndex = offsetValue;
            Integer endIndex = Math.min(offsetValue + pageSize, sortedRecords.size());
            
            for(Integer i = startIndex; i < endIndex; i++) {
                paginatedRecords.add(sortedRecords[i]);
            }
            
            return paginatedRecords;
        } else {
            return [
                SELECT Id, Exemption__r.PropertyAddress__c, Exemption__r.PropertyPostcode__c, Child_Exemption_Ref__c, End_Date__c
                FROM Exemption_Type_Link__c 
                WHERE End_Date__c != null
                AND Exemption__r.OwnerId = :UserInfo.getUserId()
                ORDER BY End_Date__c DESC
                LIMIT :pageSize
                OFFSET :offsetValue
            ];
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getUserDisplayName(){
        Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;

        Account personAccount = [
            SELECT Id, Name, BusinessName__c, Landlord_Type__c
            FROM Account
            WHERE PersonContactId = :contactId
            LIMIT 1
        ];

        if(personAccount.Landlord_Type__c == 'Individual' || personAccount.Landlord_Type__c == 'Agent'){
            return personAccount.Name;
        } else if(personAccount.Landlord_Type__c == 'Organisation') {
            return personAccount.BusinessName__c;
        } else {
            User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];

            return currentUser.Name;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Exemption_Type_Link__c getEndedExemption(String childExemptionId){
        Exemption_Type_Link__c exemptionTypeLink = [
            SELECT Id, Child_Exemption_Ref__c, Exemption__r.Registered_Date__c, End_Date__c, Exemption__r.Landlord__r.Landlord_Type__c, Exemption__r.LandlordFirstName__c, 
            Exemption__r.LandlordLastName__c, Exemption__r.LandlordEmail__c, Exemption__r.LandlordPhone__c, Exemption__r.LandlordAddress__c, Exemption__r.LandlordCity__c, Exemption__r.LandlordCounty__c, Exemption__r.LandlordPostcode__c,
            Exemption__r.PropertyAddress__c, Exemption__r.PropertyCity__c, Exemption__r.PropertyCounty__c, Exemption__r.PropertyCountry__c, Exemption__r.PropertyPostcode__c, Exemption__r.PropertyType__c, Exemption__r.EPC_Band__c, Exemption__r.EPC_Date__c,
            Exemption_Type__r.Name, Exemption_Type__r.Code__c, Exemption__r.AdditionalInformation__c, 
            (SELECT Id, ContentDocument.Title, ContentDocument.FileExtension FROM ContentDocumentLinks)
            FROM Exemption_Type_Link__c 
            WHERE Id = :childExemptionId
        ];

        return exemptionTypeLink;
    }
}