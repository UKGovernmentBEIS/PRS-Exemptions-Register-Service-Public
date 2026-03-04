@isTest
public class FileUploadAdvancedHelperTest {
    @TestSetup
    static void makeData(){
        Contact con = new Contact(
            LastName = 'Test'
        );
        insert con;
        
        ContentVersion cv = new ContentVersion(
        	Title = 'Test',
            PathOnClient = 'Test',
            VersionData = EncodingUtil.base64Decode('Test'),
            IsMajorVersion = FALSE
        );
        insert cv;
    }

    @isTest
    public static void change_file_name(){
        ContentVersion cv = getCV();
        String fileName = 'https://www.linkedin.com/in/rygramer/';

        system.test.startTest();
        FileUploadAdvancedHelper.updateFileName(new List<String>{cv.Id}, fileName);
        system.test.stopTest();

        cv = getCV();
        system.assertEquals(fileName, cv.ContentDocument.Title);
    }

    @isTest
    public static void delete_test(){
        ContentVersion cv = getCV();

        system.test.startTest();
            FileUploadAdvancedHelper.deleteContentDoc(cv.Id);
        system.test.stopTest();
        
    }

    private static ContentVersion getCV(){
        return [SELECT Id, uxgovuk__Guest_Record_fileupload__c, ContentDocument.Title, ContentDocumentId, VersionData FROM ContentVersion LIMIT 1];
    }

    private static Contact getCon(){
        return [SELECT Id FROM Contact];
    }
}