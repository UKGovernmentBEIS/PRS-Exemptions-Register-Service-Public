public without sharing class FileUploadHelper {
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('FileUploadHelper');
    
    @AuraEnabled
    public static List<FileInfo> saveFiles(List<Object> filesToInsert, String strRecId) {
        List<Id> contentVersionIds = new List<Id>();
        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        List<FileInfo> files = new List<FileInfo>();
        try {
            for (Object objFile : filesToInsert) {
                FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(objFile), FileInfo.class);

                ContentVersion singleContentVersion = new ContentVersion();
                singleContentVersion.PathOnClient = fileData.name;
                singleContentVersion.Title = fileData.name;
                singleContentVersion.VersionData = fileData.fileContents;

                contentVersionsToInsert.add(singleContentVersion);
                files.add(fileData);
            }

            if(!contentVersionsToInsert.isEmpty()) {
                List<Database.SaveResult> res = Database.insert(contentVersionsToInsert);

                Integer i = 0;
                for (Database.SaveResult saveResult : res) {
                    if(saveResult.isSuccess()) {
                        Id cvId = saveResult.getId();
                        contentVersionIds.add(cvId);

                        files[i].contentVersionId = cvId;
                    }
                    i++;
                }

                List<ContentDocumentLink> contentDocumentLinksToInsert = getContentDocumentLinks(contentVersionIds, strRecId);
                if(!contentDocumentLinksToInsert.isEmpty()) {
                    insert contentDocumentLinksToInsert;
                }
            }
        } catch (Exception ex) {
            errorLoggingService.setLogCode('FileUploadHelper')
                .setTriggeringAutomationName('saveFiles')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
            throw new AuraHandledException(
                'Could not insert document to database. Check user permissions ' + ex.getMessage()
            );
        }

        return files;
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(List<Id> contentVersionIds, String strRecordId) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        if(!contentVersionIds.isEmpty()) {
            if(ContentVersion.SObjectType.getDescribe().isAccessible()) {
                List<ContentVersion> contentVersions = [
                    SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIds
                ];

                for(ContentVersion singleContentVersion : contentVersions) {
                    ContentDocumentLink singleContentDocumentLink = new ContentDocumentLink();
                    singleContentDocumentLink.ContentDocumentId = singleContentVersion.ContentDocumentId;
                    singleContentDocumentLink.LinkedEntityId = strRecordId;
                    singleContentDocumentLink.ShareType = 'I';
                    singleContentDocumentLink.Visibility  = 'AllUsers';
                    contentDocumentLinks.add(singleContentDocumentLink);
                }
            }
        }
        return contentDocumentLinks;
    }

    @AuraEnabled
    public static void deleteContentDoc(String versId) {
        try {
            ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :versId LIMIT 1];
            ContentDocument cd = new ContentDocument(Id = cv.ContentDocumentId);
            delete cd;
        } catch (Exception ex) {
            errorLoggingService.setLogCode('FileUploadHelper')
                .setTriggeringAutomationName('deleteContentDoc')
                .setMessage(ex.getMessage())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
            throw new AuraHandledException(
                'Could not delete document. Check user permissions ' + ex.getMessage()
            );
        }
    }

   @AuraEnabled
    public static List<FileInfo> getExistingFiles(String recordId) {
        Map<Id, FileInfo> files = new Map<Id, FileInfo>();
        try {
            for(ContentDocumentLink link : [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
                FileInfo file = new FileInfo();
                file.name = link.ContentDocument.Title;
                file.documentId = link.ContentDocumentId;
                files.put(link.ContentDocumentId, file);
            }
            for(ContentVersion vers : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :files.keyset() AND IsLatest = TRUE]) {
                files.get(vers.ContentDocumentId).contentVersionId = vers.Id;
            }
        } catch (Exception ex) {
            errorLoggingService.setLogCode('FileUploadHelper')
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
        public Blob fileContents;

        @AuraEnabled
        public String documentId;

        @AuraEnabled
        public String contentVersionId;
    }
}