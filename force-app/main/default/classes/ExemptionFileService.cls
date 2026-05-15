public class ExemptionFileService {
    public static void updateContentDocumentLinkVisibility(List<ContentDocumentLink> links) {
        for (ContentDocumentLink cdl : links) {
            if (cdl.Visibility != 'AllUsers') {
                cdl.Visibility = 'AllUsers';
            }
        }
    }
}