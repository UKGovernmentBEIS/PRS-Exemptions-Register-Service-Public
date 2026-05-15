trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert) {
    if (Trigger.isInsert) {
        ExemptionFileService.updateContentDocumentLinkVisibility(Trigger.new);
    }
}