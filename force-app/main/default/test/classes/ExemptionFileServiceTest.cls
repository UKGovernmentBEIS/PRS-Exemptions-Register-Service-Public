@isTest
private class ExemptionFileServiceTest {
    
    @isTest
    static void testUpdateContentDocumentLinkVisibility_setsAllUsers() {
        ContentDocumentLink cdl1 = new ContentDocumentLink();
        cdl1.Visibility = 'InternalUsers';
        
        ContentDocumentLink cdl2 = new ContentDocumentLink();
        cdl2.Visibility = 'SharedUsers';
        
        ContentDocumentLink cdl3 = new ContentDocumentLink();
        cdl3.Visibility = 'AllUsers';
        
        List<ContentDocumentLink> links = new List<ContentDocumentLink>{ cdl1, cdl2, cdl3 };
        
        ExemptionFileService.updateContentDocumentLinkVisibility(links);
        
        for (ContentDocumentLink cdl : links) {
            System.assertEquals('AllUsers', cdl.Visibility, 
                'Expected Visibility to be AllUsers for all links');
        }
    }
    
    @isTest
    static void testUpdateContentDocumentLinkVisibility_emptyList() {
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        
        ExemptionFileService.updateContentDocumentLinkVisibility(links);
        
        System.assertEquals(0, links.size(), 'Expected empty list to remain empty');
    }
    
    @isTest
    static void testUpdateContentDocumentLinkVisibility_alreadyAllUsers() {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.Visibility = 'AllUsers';
        
        List<ContentDocumentLink> links = new List<ContentDocumentLink>{ cdl };
        
        ExemptionFileService.updateContentDocumentLinkVisibility(links);
        
        System.assertEquals('AllUsers', cdl.Visibility, 
            'Expected Visibility to remain AllUsers when already set');
    }
}