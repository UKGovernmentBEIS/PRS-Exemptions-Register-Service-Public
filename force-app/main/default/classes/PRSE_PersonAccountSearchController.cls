public without sharing class PRSE_PersonAccountSearchController {

    @AuraEnabled
    public static List<Account> searchPersonAccounts(String searchKey) {
        System.debug('DEBUG - key = '+searchKey);

        if(String.isBlank(searchKey)){
            return new List<Account>();
        }

        // Handle nulls and trim whitespace
        if (searchKey != null) {
            searchKey = searchKey.trim();
        }

        // Prevent very short searches (performance)
        if (String.isBlank(searchKey) || searchKey.length() < 4) {
            return new List<Account>();
        }

        return [
            SELECT Id, Name, PersonEmail,Phone,FirstName,LastName,BusinessName__c
            FROM Account
            WHERE IsPersonAccount = TRUE
            AND(
            Name LIKE :('%' + searchKey + '%')
            OR PersonEmail LIKE :('%' + searchKey + '%')
            OR Phone LIKE :('%' + searchKey + '%')
            OR FirstName LIKE :('%' + searchKey + '%')
            OR LastName LIKE :('%' + searchKey + '%')
            OR BusinessName__c LIKE :('%' + searchKey + '%')
            )
            ORDER BY Name
            LIMIT 10
        ];
    }
}