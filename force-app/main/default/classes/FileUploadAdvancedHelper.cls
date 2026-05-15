public without sharing class FileUploadAdvancedHelper {
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('FileUploadAdvancedHelper');
    
    @AuraEnabled(cacheable = true)
    public static String getKey() {
        String encodedKey = '';
        try {
            Blob key = Crypto.generateAesKey(256);
            encodedKey = EncodingUtil.base64Encode(key);
        } catch (Exception ex) {
            errorLoggingService.setLogCode('FileUploadAdvancedHelper')
                .setTriggeringAutomationName('getKey')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return encodedKey;
    }
    
    @AuraEnabled(cacheable = true)
    public static String encrypt(String recordId, String encodedKey) {
        String encodedValue = '';
        try {
            Blob key = EncodingUtil.base64Decode(encodedKey);
            Blob value = Crypto.encryptWithManagedIV('AES256', key, Blob.valueOf(recordId));
            encodedValue = EncodingUtil.base64Encode(value);
        } catch (Exception ex) {
            errorLoggingService.setLogCode('FileUploadAdvancedHelper')
                .setTriggeringAutomationName('encrypt')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
        return encodedValue;
    }
    
    @AuraEnabled
    public static void createContentDocLink(List<String> versIds, String encodedKey){
        try {
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for(ContentVersion vers : [SELECT Id, ContentDocumentId, uxgovuk__Guest_Record_fileupload__c FROM ContentVersion WHERE Id IN :versIds]){
                String grf = decrypt(vers.uxgovuk__Guest_Record_fileupload__c, encodedKey);
                ContentDocumentLink link = new ContentDocumentLink(
                    ContentDocumentId = vers.ContentDocumentId,
                    LinkedEntityId = decrypt(vers.uxgovuk__Guest_Record_fileupload__c, encodedKey),
                    ShareType = 'I',
                    Visibility  = 'AllUsers'
                );
                links.add(link);
            }

            if(!links.isEmpty()){
                insert links;
            }
            
        } catch (Exception ex) {
            errorLoggingService.setLogCode('FileUploadAdvancedHelper')
                .setTriggeringAutomationName('createContentDocLink')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
    }

    @AuraEnabled
    public static void updateFileName(List<String> versIds, String fileName) {
        try {
            List<ContentDocument> docs = new List<ContentDocument>();
            for(ContentVersion vers : [SELECT Id, ContentDocumentId, ContentDocument.Title FROM ContentVersion WHERE Id IN :versIds]){
                if(vers.ContentDocument.Title != fileName){
                    ContentDocument doc = new ContentDocument(
                        Id = vers.ContentDocumentId,
                        Title = fileName
                    );
                    docs.add(doc);
                }
            }
            if(!docs.isEmpty()){
                update docs;
            }
        } catch (Exception ex) {
            errorLoggingService.setLogCode('FileUploadAdvancedHelper')
                .setTriggeringAutomationName('updateFileName')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
    }

    @AuraEnabled
    public static void deleteContentDoc(String versId) {
        try {
            ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :versId LIMIT 1];
            ContentDocument cd = new ContentDocument(Id=cv.ContentDocumentId);
            delete cd;
        } catch (Exception ex) {
            errorLoggingService.setLogCode('FileUploadAdvancedHelper')
                .setTriggeringAutomationName('deleteContentDoc')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
        }
    }

    @AuraEnabled
    public static List<FileInfo> getExistingFiles(String recordId) {
        if(String.isBlank(recordId)) {
            return new List<FileInfo>();
        }
        
        Map<Id, FileInfo> files = new Map<Id, FileInfo>();
        try {
            for(ContentDocumentLink link : [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
                FileInfo file = new FileInfo();
                file.name = link.ContentDocument.Title + '.' + link.ContentDocument.FileExtension;
                file.documentId = link.ContentDocumentId;
                file.fileExtension = link.ContentDocument.FileExtension;
                files.put(link.ContentDocumentId, file);
            }
            for(ContentVersion vers : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :files.keyset() AND IsLatest = TRUE]) {
                files.get(vers.ContentDocumentId).contentVersionId = vers.Id;
            }
        } catch (Exception ex) {
            errorLoggingService.setLogCode('FileUploadAdvancedHelper')
                .setTriggeringAutomationName('getExistingFiles')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
            throw new AuraHandledException(
                'Could not retrieve existing documents. Check user permissions ' + ex.getMessage()
            );
        }
        
        return files.values();
    }

    public class FileInfo {
        @AuraEnabled
        public String name;

        @AuraEnabled
        public String documentId;

        @AuraEnabled
        public String contentVersionId;

        @AuraEnabled
        public String fileExtension;
    }

    public class Input{
        @InvocableVariable(
            label='Collection of Content Version Ids'
            required=true
        )
        public List<Id> versIds;

        @InvocableVariable(
            label='Related Record Id'
            required=true
        )
        public Id recordId;

        @InvocableVariable(
            label='Visible to All Users?'
        )
        public Boolean visibleToAllUsers;
    }

    private static String decrypt(String encodedValue, String encodedKey) {
        Blob key = EncodingUtil.base64Decode(encodedKey);
        Blob value = EncodingUtil.base64Decode(encodedValue);
    	Blob decryptedBlob = Crypto.decryptWithManagedIV('AES256', key, value);
    	String recordId = decryptedBlob.toString();
        return recordId;
    }
}