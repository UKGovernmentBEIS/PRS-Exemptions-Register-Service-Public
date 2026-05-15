@isTest
public class FileUploadAdvancedHelperTest {
    @TestSetup
    static void makeData() {
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
    public static void change_file_name() {
        //Arrange
        ContentVersion cv = getCV();
        String fileName = 'https://www.linkedin.com/in/rygramer/';

        //Act
        FileUploadAdvancedHelper.updateFileName(new List<String>{cv.Id}, fileName);

        //Assert
        cv = getCV();
        Assert.areEqual(fileName, cv.ContentDocument.Title);
    }

    @isTest
    public static void delete_test(){
        //Arrange, Act
        ContentVersion cv = getCV();

        //Assert
        FileUploadAdvancedHelper.deleteContentDoc(cv.Id);  
    }

    @isTest
    static void getKey_returnsNonBlankString() {
        //Arrange, Act
        String key = FileUploadAdvancedHelper.getKey();

        //Assert
        Assert.isNotNull(key, 'Key should not be null');
        Assert.areNotEqual('', key, 'Key should not be blank');
    }

    @isTest
    static void getKey_returnsValid256BitKey() {
        //Arrange, Act
        String key = FileUploadAdvancedHelper.getKey();

        //Assert
        Blob decoded = EncodingUtil.base64Decode(key);
        Assert.areEqual(32, decoded.size(), 'AES-256 key should decode to 32 bytes');
    }

    @isTest
    static void getKey_returnsUniqueKeysEachCall() {
        //Arrange, Act
        String key1 = FileUploadAdvancedHelper.getKey();
        String key2 = FileUploadAdvancedHelper.getKey();

        //Assert
        Assert.areNotEqual(key1, key2, 'Each call should produce a unique key');
    }

    @isTest
    static void encrypt_validInput_returnsEncryptedString() {
        //Arrange
        String key = FileUploadAdvancedHelper.getKey();
        String recordId = getCon().Id;

        //Act
        String encrypted = FileUploadAdvancedHelper.encrypt(recordId, key);

        //Assert
        Assert.isNotNull(encrypted, 'Encrypted value should not be null');
        Assert.areNotEqual('', encrypted, 'Encrypted value should not be blank');
        Assert.areNotEqual(recordId, encrypted, 'Encrypted value should differ from input');
    }

    @isTest
    static void encrypt_invalidKey_returnsEmpty() {
        //Arrange, Act
        String encrypted = FileUploadAdvancedHelper.encrypt('someValue', 'notAValidBase64Key!!');

        //Assert
        Assert.areEqual('', encrypted, 'Invalid key should be caught and return empty string');
    }

    @isTest
    static void encrypt_nullRecordId_returnsEmpty() {
        //Arrange
        String key = FileUploadAdvancedHelper.getKey();

        //Act
        String encrypted = FileUploadAdvancedHelper.encrypt(null, key);

        //Assert
        Assert.areEqual('', encrypted, 'Null recordId should be caught and return empty string');
    }

    @isTest
    static void encrypt_nullKey_returnsEmpty() {
        //Arrange, Act
        String encrypted = FileUploadAdvancedHelper.encrypt(getCon().Id, null);

        //Assert
        Assert.areEqual('', encrypted, 'Null key should be caught and return empty string');
    }

    @isTest
    static void getExistingFiles_withLinkedFile_returnsFileInfo() {
        //Arrange
        Contact con = getCon();
        ContentVersion cv = getCV();

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = con.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        //Act
        List<FileUploadAdvancedHelper.FileInfo> files = FileUploadAdvancedHelper.getExistingFiles(con.Id);

        //Assert
        Assert.areEqual(1, files.size(), 'Should return one file');
        Assert.isNotNull(files[0].name, 'File name should be populated');
        Assert.isNotNull(files[0].documentId, 'Document Id should be populated');
        Assert.isNotNull(files[0].contentVersionId, 'Content Version Id should be populated');
        Assert.areEqual(cv.ContentDocumentId, files[0].documentId, 'Document Id should match the inserted ContentDocument');
    }


    @isTest
    static void getExistingFiles_noFiles_returnsEmptyList() {
        //Arrange
        Contact con = getCon();

        //Act
        List<FileUploadAdvancedHelper.FileInfo> files = FileUploadAdvancedHelper.getExistingFiles(con.Id);

        //Assert
        Assert.areEqual(0, files.size(), 'Should return empty list when no files linked');
    }

    @isTest
    static void getExistingFiles_nullRecordId_returnsEmptyList() {
        //Arrange, Act

        List<FileUploadAdvancedHelper.FileInfo> returnedResults = FileUploadAdvancedHelper.getExistingFiles(null);

        //Assert
        Assert.areEqual(new List<FileUploadAdvancedHelper.FileInfo>(), returnedResults, 'Incorrect results returned');
    }

    @isTest
    static void getExistingFiles_fileNameConcatenated() {
        //Arrange
        Contact con = getCon();
        ContentVersion cv = getCV();

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = con.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        //Act
        List<FileUploadAdvancedHelper.FileInfo> files = FileUploadAdvancedHelper.getExistingFiles(con.Id);

        //Assert
        Assert.isTrue(files[0].name.contains('.'), 'File name should contain a dot separator');
    }

    @isTest
    static void updateFileName_sameTitle_skipsDml() {
        //Arrange
        ContentVersion cv = getCV();
        String currentTitle = cv.ContentDocument.Title;

        //Act
        FileUploadAdvancedHelper.updateFileName(new List<String>{ cv.Id }, currentTitle);

        //Assert
        ContentVersion after = getCV();
        Assert.areEqual(currentTitle, after.ContentDocument.Title, 'Title should be unchanged');
    }

    @isTest
    static void updateFileName_emptyList_noError() {
        //Arrange, Act
        FileUploadAdvancedHelper.updateFileName(new List<String>(), 'SomeTitle');

        //Assert
        Assert.isTrue(true, 'Empty list should not throw an error');
    }

    @isTest
    static void deleteContentDoc_invalidId_handledGracefully() {
        //Arrange, Act
        FileUploadAdvancedHelper.deleteContentDoc('068000000000001AAA');

        //Assert
        Assert.isTrue(true, 'Invalid Id should be caught silently');
    }

    @isTest
    static void createContentDocLink_emptyList_noError() {
        //Arrange
        String key = FileUploadAdvancedHelper.getKey();

        //Act
        FileUploadAdvancedHelper.createContentDocLink(new List<String>(), key);

        //Assert
        Assert.isTrue(true, 'Empty list should not throw an error');
    }

    @isTest
    static void createContentDocLink_withValidEncryptedField() {
        //Arrange
        Contact con = getCon();
        String key = FileUploadAdvancedHelper.getKey();
        String encryptedRecordId = FileUploadAdvancedHelper.encrypt(con.Id, key);
        ContentVersion cv = getCV();
        cv.uxgovuk__Guest_Record_fileupload__c = encryptedRecordId;
        update cv;
        ContentVersion refreshed = [SELECT Id FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        //Act
        FileUploadAdvancedHelper.createContentDocLink(new List<String>{ refreshed.Id }, key);

        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId = :con.Id
        ];

        //Assert
        Assert.areEqual(1, links.size(), 'A ContentDocumentLink to the decrypted record should be created');
    }

    private static ContentVersion getCV(){
        return [SELECT Id, uxgovuk__Guest_Record_fileupload__c, ContentDocument.Title, ContentDocumentId, VersionData FROM ContentVersion LIMIT 1];
    }

    private static Contact getCon(){
        return [SELECT Id FROM Contact];
    }
}