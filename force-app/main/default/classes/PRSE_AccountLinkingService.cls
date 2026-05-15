public without sharing class PRSE_AccountLinkingService {
    
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('PRSE_AccountLinkingService');
    
    public class TransferInput {
        @InvocableVariable(required=true)
        public String legacyAccountId;
        
        @InvocableVariable(required=true)
        public String newAccountId;
        
        @InvocableVariable(required=true)
        public String newOwnerId;
    }
    
    public class TransferOutput {
        @InvocableVariable 
        public Integer recordsTransferred;
        
        @InvocableVariable 
        public String status;
        
        @InvocableVariable 
        public String message;
    }
    
    @InvocableMethod(
        label='Transfer Exemption Ownership'
        category='PRS Exemption Register'
    )
    public static List<TransferOutput> transferExemptions(List<TransferInput> inputs) {
        List<TransferOutput> results = new List<TransferOutput>();
        
        for (TransferInput input : inputs) {
            TransferOutput output = new TransferOutput();
            output.recordsTransferred = 0;
            
            try {
                // Input validation
                if (String.isBlank(input.legacyAccountId)) {
                    throw new IllegalArgumentException('Legacy Account ID is required');
                }
                if (String.isBlank(input.newAccountId)) {
                    throw new IllegalArgumentException('New Account ID is required');
                }
                if (String.isBlank(input.newOwnerId)) {
                    throw new IllegalArgumentException('New Owner ID is required');
                }
                
                // Query exemptions for the legacy account
                List<Exemption__c> exemptions = [
                    SELECT Id, OwnerId, Account__c
                    FROM Exemption__c
                    WHERE Account__c = :input.legacyAccountId
                ];
                
                // Handle case where no exemptions exist
                if (exemptions.isEmpty()) {
                    output.status = 'Success';
                    output.message = 'No exemption records found for the legacy account';
                    results.add(output);
                    continue;
                }
                
                // Update ownership and account lookup
                for (Exemption__c exemption : exemptions) {
                    exemption.OwnerId = input.newOwnerId;
                    exemption.Account__c = input.newAccountId;
                }
                
                // Save changes with error handling
                Database.SaveResult[] saveResults = Database.update(exemptions, false);
                
                // Check for partial failures
                Integer successCount = 0;
                List<String> errors = new List<String>();
                Set<Id> successfulExemptionIds = new Set<Id>();
                for (Integer i = 0; i < saveResults.size(); i++) {
                    if (saveResults[i].isSuccess()) {
                        successCount++;
                        successfulExemptionIds.add(exemptions[i].Id);
                    } else {
                        for (Database.Error err : saveResults[i].getErrors()) {
                            errors.add('Exemption ' + exemptions[i].Id + ': ' + err.getMessage());
                        }
                    }
                }

                if (!successfulExemptionIds.isEmpty()) {

                    // Collect exemption IDs plus child Exemption_Type_Link__c IDs
                    Set<Id> allLinkedEntityIds = new Set<Id>(successfulExemptionIds);
                    for (Exemption_Type_Link__c tl : [
                        SELECT Id 
                        FROM Exemption_Type_Link__c 
                        WHERE Exemption__c IN :successfulExemptionIds
                    ]) {
                        allLinkedEntityIds.add(tl.Id);
                    }

                    // Get all ContentDocumentIds linked to exemptions and child exemptions
                    Set<Id> contentDocumentIds = new Set<Id>();
                    for (ContentDocumentLink cdl : [
                        SELECT ContentDocumentId 
                        FROM ContentDocumentLink 
                        WHERE LinkedEntityId IN :allLinkedEntityIds
                    ]) {
                        contentDocumentIds.add(cdl.ContentDocumentId);
                    }

                    // Create new User-level CDLs for the new owner
                    if (!contentDocumentIds.isEmpty()) {
                        List<ContentDocumentLink> newUserLinks = new List<ContentDocumentLink>();
                        for (Id docId : contentDocumentIds) {
                            newUserLinks.add(new ContentDocumentLink(
                                ContentDocumentId = docId,
                                LinkedEntityId    = input.newOwnerId,
                                ShareType         = 'V',
                                Visibility        = 'AllUsers'
                            ));
                        }
                        Database.SaveResult[] linkResults = Database.insert(newUserLinks, false);
                        for (Integer i = 0; i < linkResults.size(); i++) {
                            if (!linkResults[i].isSuccess()) {
                                for (Database.Error err : linkResults[i].getErrors()) {
                                    errors.add('Insert CDL ' + newUserLinks[i].ContentDocumentId + ': ' + err.getMessage());
                                }
                            }
                        }
                    }
                }
                
                if (!errors.isEmpty()) {
                    String errorMessage = 'Partial failure: ' + successCount + ' of ' + exemptions.size() + ' records transferred. Errors: ' + String.join(errors, '; ');
                    
                    errorLoggingService.setLogCode('PARTIAL_TRANSFER_FAILURE')
                        .setTriggeringAutomationName('transferExemptions')
                        .setMessage(errorMessage)
                        .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                        .publish();
                    
                    output.recordsTransferred = successCount;
                    output.status = 'Partial Success';
                    output.message = errorMessage;
                } else {
                    output.recordsTransferred = exemptions.size();
                    output.status = 'Success';
                    output.message = 'Successfully transferred ' + exemptions.size() + ' exemption records';
                }
                
                results.add(output);
                
            } catch (IllegalArgumentException ex) {
                output.status = 'Error';
                output.message = 'Validation failed: ' + ex.getMessage();
                
                errorLoggingService.setLogCode('VALIDATION_ERROR')
                    .setTriggeringAutomationName('transferExemptions')
                    .setMessage(ex.getMessage())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
                
                results.add(output);
                
            } catch (QueryException ex) {
                output.status = 'Error';
                output.message = 'Query failed: ' + ex.getMessage();
                
                errorLoggingService.setLogCode('QUERY_ERROR')
                    .setTriggeringAutomationName('transferExemptions')
                    .setMessage(ex.getMessage())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
                
                results.add(output);
                
            } catch (DmlException ex) {
                output.status = 'Error';
                output.message = 'Transfer failed: ' + ex.getDmlMessage(0);
                
                errorLoggingService.setLogCode('DML_ERROR')
                    .setTriggeringAutomationName('transferExemptions')
                    .setMessage(ex.getMessage())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
                
                results.add(output);
                
            } catch (Exception ex) {
                output.status = 'Error';
                output.message = 'Transfer failed: ' + ex.getMessage();
                
                errorLoggingService.setLogCode('UNEXPECTED_ERROR')
                    .setTriggeringAutomationName('transferExemptions')
                    .setMessage(ex.getMessage() + ' | Stack Trace: ' + ex.getStackTraceString())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
                
                results.add(output);
            }
        }
        
        return results;
    }
}