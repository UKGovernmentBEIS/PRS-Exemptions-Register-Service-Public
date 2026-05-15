public class LocalCustodianCodeAssignmentJob implements Queueable, Database.AllowsCallouts {
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('LocalCustodianCodeAssignmentJob');

    private static final Integer CHUNK_SIZE = 100;

    public void execute(QueueableContext context) {
        List<Exemption__c> chunk = [
            SELECT Id, Local_Custodian_Code__c, PropertyUPRN__c, Full_Property_Address__c
            FROM Exemption__c
            WHERE Local_Custodian_Code__c = null 
            AND PropertyAddress__c != NULL 
            AND Status__c = 'Received' 
            AND Ref_Legacy__c != NULL
            LIMIT :CHUNK_SIZE
        ];

        if (chunk.isEmpty()) {
            System.debug('LocalCustodianCodeAssignmentJob: All records processed.');
            return;
        }

        List<Exemption__c> toUpdate = new List<Exemption__c>();

        for (Exemption__c record : chunk) {
            try {
                DeliveryPointAddress dpaForExemption = OSPlacesInteractionService.matchAddressForEnglandOrWalesOnly(record.Full_Property_Address__c)[0];
                record.Local_Custodian_Code__c = String.valueOf(dpaForExemption.LOCAL_CUSTODIAN_CODE);
                if(String.isBlank(record.PropertyUPRN__c)) {
                    record.PropertyUPRN__c = String.valueOf(dpaForExemption.UPRN);
                }
                toUpdate.add(record);
            } catch (Exception ex) {
                errorLoggingService.setLogCode('LocalCustodianCodeAssignmentJob')
                    .setTriggeringAutomationName('execute')
                    .setMessage('execute for record ' + record.Id + ' with error: ' + ex.getMessage())
                    .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                    .publish();
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        if (chunk.size() < CHUNK_SIZE) {
            System.debug('LocalCustodianCodeAssignmentJob: Final batch processed, stopping.');
            return;
        }

        System.enqueueJob(new LocalCustodianCodeAssignmentJob(), 1);
    }
}