@isTest
private class ContentDocumentLinkTriggerTest {

    @isTest
    static void testTrigger_setsVisibilityOnInsert() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test content');
        cv.FirstPublishLocationId = acc.Id;
        insert cv;

        ContentVersion insertedCv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = [
            SELECT Id, Visibility 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :insertedCv.ContentDocumentId
            AND LinkedEntityId = :acc.Id
        ];

        System.assertEquals('AllUsers', cdl.Visibility, 
            'Trigger should have set Visibility to AllUsers on insert');
    }

    @isTest
    static void testTrigger_bulk() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        List<ContentVersion> versions = new List<ContentVersion>();
        for (Account acc : accounts) {
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document ' + acc.Name;
            cv.PathOnClient = 'TestDocument.pdf';
            cv.VersionData = Blob.valueOf('Test content');
            cv.FirstPublishLocationId = acc.Id;
            versions.add(cv);
        }
        insert versions;

        List<Id> cvIds = new List<Id>();
        for (ContentVersion cv : versions) {
            cvIds.add(cv.Id);
        }

        List<ContentDocumentLink> cdls = [
            SELECT Id, Visibility 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId IN (
                SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :cvIds
            )
            AND LinkedEntityId IN :accountIds
        ];

        System.assertEquals(200, cdls.size(), 'Expected 200 ContentDocumentLinks');
        for (ContentDocumentLink cdl : cdls) {
            System.assertEquals('AllUsers', cdl.Visibility,
                'Trigger should have set Visibility to AllUsers for all records');
        }
    }
}