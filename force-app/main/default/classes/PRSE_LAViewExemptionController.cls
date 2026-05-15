/**
 * @description       Controller used by Lightning Web Components to retrieve exemption details,
 *                    landlord information, agent information, document evidence, and child exemption data.
 * @group             PRS Exemptions
 * @since             v1.0
 */
public without sharing class PRSE_LAViewExemptionController {
    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('PRSE_LAViewExemptionController');
    
    /**
     * @description Returns a single Exemption__c record by Id.
     * @param exemptionId The Id of the Exemption__c record.
     * @return Exemption__c The matched exemption.
     */
    @AuraEnabled(cacheable=true)
    public static Exemption__c getExemption(String exemptionId) {
        try {
            if (exemptionId == null) {
                throw new AuraHandledException('Exemption Id is required');
            }

            if(!PRSE_LAViewExemptionHelper.checkExemption(exemptionId)) {
                throw new AuraHandledException('You do not have permission to view this exemption');
            }

            return [
                SELECT Id, Ref_Number__c, Full_Property_Address__c, Account__r.Landlord_Type__c
                FROM Exemption__c
                WHERE Id = :exemptionId
                LIMIT 1
            ];
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_LAViewExemptionController')
            .setTriggeringAutomationName('getExemption')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error retrieving exemption: ' + e.getMessage());
        }
    }


    /**
     * @description Returns landlord details for an exemption, including Person Account data (if available).
     * @param exemptionId The Id of the exemption.
     * @return ExemptionWrapper Wrapper containing landlord info.
     * @throws AuraHandledException If exemptionId is null.
     */
    @AuraEnabled(cacheable=true)
    public static ExemptionWrapper getExemptionLandlordDetails(Id exemptionId) {
        ExemptionWrapper wrapper = new ExemptionWrapper();

        try {
            if (exemptionId == null) {
                throw new AuraHandledException('Exemption Id is required');
            }

            if(!PRSE_LAViewExemptionHelper.checkExemption(exemptionId)) {
                throw new AuraHandledException('You do not have permission to view this exemption');
            }

            Exemption__c exemptionRecord = [
                SELECT Id,
                    Account__c,
                    Account__r.Landlord_Type__c,
                    Account__r.BusinessName__c,
                    LandlordFirstName__c,
                    LandlordLastName__c,
                    LandlordBusinessName__c,
                    LandlordAddress__c,
                    LandlordCity__c,
                    LandlordPostcode__c,
                    LandlordPhone__c,
                    LandlordEmail__c,                    
                    DigitallyAssisted__c,
                    ReasonForCallingADRoute__c,
                    OwnerId
                FROM Exemption__c
                WHERE Id = :exemptionId
                LIMIT 1
            ];
            
            wrapper.Id = exemptionRecord.Id;
            wrapper.LandlordFirstName = exemptionRecord.LandlordFirstName__c;
            wrapper.LandlordLastName = exemptionRecord.LandlordLastName__c;
            wrapper.LandlordBusinessName = exemptionRecord.LandlordBusinessName__c;
            wrapper.personAccountBusinessName = exemptionRecord.Account__r.BusinessName__c;
            wrapper.LandlordAddress = exemptionRecord.LandlordAddress__c + ', ' + 
                                      exemptionRecord.LandlordCity__c + ', ' +  
                                      exemptionRecord.LandlordPostcode__c;
            wrapper.LandlordPhone = exemptionRecord.LandlordPhone__c;
            wrapper.LandlordEmail = exemptionRecord.LandlordEmail__c;
            wrapper.DigitallyAssisted = exemptionRecord.DigitallyAssisted__c;
            wrapper.ReasonForCallingADRoute = exemptionRecord.ReasonForCallingADRoute__c;
            wrapper.LandlordType = exemptionRecord.Account__r?.Landlord_Type__c;

        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_LAViewExemptionController')
            .setTriggeringAutomationName('getExemptionLandlordDetails')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error retrieving landlord details: ' + e.getMessage());
        }

        return wrapper;
    }


    /**
     * @description Returns agent account details for the exemption.
     * @param exemptionId The Id of the exemption.
     * @return Account Account representing the agent or null if no agent is assigned.
     * @throws AuraHandledException If exemptionId is null.
     */
    @AuraEnabled(cacheable=true)
    public static AgentWrapper getExemptionAgentDetails(Id exemptionId) { 
        AgentWrapper wrapper = new AgentWrapper();

        try {
            if (exemptionId == null) {
                throw new AuraHandledException('Exemption Id is required');
            }

            if(!PRSE_LAViewExemptionHelper.checkExemption(exemptionId)) {
                throw new AuraHandledException('You do not have permission to view this exemption');
            }

            Exemption__c exemption = [
                SELECT Account__c,
                        DigitallyAssisted__c,
                        ReasonForCallingADRoute__c
                FROM Exemption__c
                WHERE Id = :exemptionId
                LIMIT 1
            ];

            Account agent = [
                SELECT FirstName,
                    LastName,
                    Name,
                    BusinessName__c,
                    PersonMailingAddress,
                    Phone,
                    PersonEmail,
                    Landlord_Type__c
                FROM Account
                WHERE Id = :exemption.Account__c
                LIMIT 1
            ];

            if(agent.Landlord_Type__c != 'Agent') {
                return null;
            }

            wrapper.Id = agent.Id;
            wrapper.FirstName = agent.FirstName;
            wrapper.LastName = agent.LastName;
            wrapper.Name = agent.Name;
            wrapper.BusinessName = agent.BusinessName__c;
            Address addr = agent.PersonMailingAddress;
            List<String> parts = new List<String>();

            if (addr.street != null) {
                String street = addr.street.trim();

                // remove trailing comma if present
                if (street.endsWith(',')) {
                    street = street.substring(0, street.length() - 1);
                }

                parts.add(street);
            }
            if (addr.city != null) parts.add(addr.city);
            if (addr.state != null) parts.add(addr.state);
            if (addr.postalCode != null) parts.add(addr.postalCode);
            if (addr.country != null) parts.add(addr.country);

            wrapper.Address = String.join(parts, ', ');
            wrapper.Phone = agent.Phone;
            wrapper.Email = agent.PersonEmail;
            wrapper.LandlordType = agent.Landlord_Type__c;

            wrapper.DigitallyAssisted = exemption.DigitallyAssisted__c;
            wrapper.ReasonForCallingADRoute = exemption.ReasonForCallingADRoute__c;

        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_LAViewExemptionController')
            .setTriggeringAutomationName('getExemptionAgentDetails')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error retrieving agent details: ' + e.getMessage());
        }

        return wrapper;
    }


    /**
     * @description Returns the parent exemption and all related child exemption records.
     * @param exemptionId The Id of the parent exemption.
     * @return ExemptionDetailsWrapper Wrapper containing parent exemption and children.
     */
    @AuraEnabled(cacheable=true)
    public static ExemptionDetailsWrapper getExemptionDetails(Id exemptionId) {
        ExemptionDetailsWrapper detailsWrapper = new ExemptionDetailsWrapper();

        try {
            if (exemptionId == null) {
                throw new AuraHandledException('Exemption Id is required');
            }
            
            if(!PRSE_LAViewExemptionHelper.checkExemption(exemptionId)) {
                throw new AuraHandledException('You do not have permission to view this exemption');
            }

            Exemption__c exemptionRecord = [
                SELECT Id,
                    Status__c,
                    Ref_Number__c,
                    Registered_Date__c,
                    Full_Property_Address__c,
                    PropertyPostcode__c,
                    PropertyUPRN__c,
                    PropertyType__c,
                    AdditionalInformation__c,
                    Local_Authority_Notes__c,
                    (SELECT Id,
                            End_Date__c,
                            End_Reason__c,
                            Additional_End_Reason__c,
                            Exemption_Type_Code__c,
                            Exemption_Type__c,
                            Exemption_Type__r.Name
                        FROM ExemptionTypeLinks__r
                     	ORDER BY Exemption_Type_Code__c
                    )
                FROM Exemption__c
                WHERE Id = :exemptionId
                LIMIT 1
            ];
            
            detailsWrapper.parentExemption = exemptionRecord;
            detailsWrapper.childExemptions = new List<ChildExemptionWrapper>();

            for (Exemption_Type_Link__c link : exemptionRecord.ExemptionTypeLinks__r) {
                ChildExemptionWrapper child = new ChildExemptionWrapper();
                child.Id = link.Id;
                child.TypeName = link.Exemption_Type__r.Name + ': ' + exemptionRecord.Ref_Number__c + link.Exemption_Type_Code__c;
                child.EndDate = link.End_Date__c;
                child.EndReason = link.End_Reason__c;
                child.AdditionalEndReason = link.Additional_End_Reason__c;
                if(link.End_Date__c != null) {
                    child.Status = link.Additional_End_Reason__c == 'Exemption Expired by System' ? 'Expired' : 'Ended';
                } else {
                    child.Status = 'Active';
                }
                detailsWrapper.childExemptions.add(child);
            }
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_LAViewExemptionController')
            .setTriggeringAutomationName('getExemptionDetails')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error retrieving exemption details: ' + e.getMessage());
        }

        return detailsWrapper;
    }


    /**
     * @description Updates the Status__c field of an Exemption__c record.
     * @param exemptionId The Id of the Exemption__c record to update.
     * @param status The new status value to set on the exemption.
     * @return void
     * @throws AuraHandledException If exemptionId or status is null, or if the update fails.
     */
    @AuraEnabled
    public static void updateExemptionStatus(Id exemptionId, String status) {
        try {
            if (exemptionId == null || status == null) {
                throw new AuraHandledException('Exemption Id and status are required.');
            }

            Exemption__c ex = [SELECT Id, Status__c FROM Exemption__c WHERE Id = :exemptionId LIMIT 1];
            ex.Status__c = status;
            update ex;
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_LAViewExemptionController')
            .setTriggeringAutomationName('updateExemptionStatus')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error updating exemption status: ' + e.getMessage());
        }
    }

    
    /**
     * @description Retrieves all available picklist values for the Status__c field on Exemption__c.
     * @return List<String> A list of picklist values representing possible exemption statuses.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getExemptionStatusOptions() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Exemption__c.Status__c.getDescribe();
        for (Schema.PicklistEntry pe : fieldResult.getPicklistValues()) {
            options.add(pe.getValue());
        }

        return options;
    }


    /**
     * @description Returns evidence documents grouped by exemption type for an exemption.
     * @param exemptionId The Id of the exemption.
     * @return List<Map<String, Object>> List of grouped document info.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getExemptionEvidenceDocumentsGrouped(Id exemptionId) {
        List<Map<String, Object>> groupedResults = new List<Map<String, Object>>();

        try {
            if (exemptionId == null) {
                throw new AuraHandledException('Exemption Id is required');
            }
            
            if(!PRSE_LAViewExemptionHelper.checkExemption(exemptionId)) {
                throw new AuraHandledException('You do not have permission to view this exemption');
            }

            List<Exemption_Type_Link__c> linkRecords = [
                SELECT Id, Name, Exemption_Type__r.Name,
                    (SELECT ContentDocumentId,
                            ContentDocument.Title,
                            ContentDocument.FileExtension,
                            ContentDocument.CreatedDate
                        FROM ContentDocumentLinks
                        ORDER BY ContentDocument.CreatedDate DESC)
                FROM Exemption_Type_Link__c
                WHERE Exemption__c = :exemptionId
                ORDER BY Exemption_Type_Code__c
            ];

            Map<String, List<Map<String, String>>> typeMap = new Map<String, List<Map<String, String>>>();

            for (Exemption_Type_Link__c link : linkRecords) {
                String typeName = link.Exemption_Type__r != null ? link.Exemption_Type__r.Name : 'Unknown type';

                if (!typeMap.containsKey(typeName)) {
                    typeMap.put(typeName, new List<Map<String, String>>());
                }

                if (link.ContentDocumentLinks.isEmpty()) {
                    typeMap.get(typeName).add(new Map<String, String>{
                        'DocumentTitle' => 'No document attached',
                        'ContentDocumentId' => '',
                        'CreatedDate'   => ''
                    });
                } else {
                    for (ContentDocumentLink cdl : link.ContentDocumentLinks) {
                        typeMap.get(typeName).add(new Map<String, String>{
                            'DocumentTitle' => cdl.ContentDocument.Title + (cdl.ContentDocument.FileExtension != null ? '.' + cdl.ContentDocument.FileExtension.toLowerCase() : ''),
                            'ContentDocumentId' => cdl.ContentDocumentId,
                            'CreatedDate'   => String.valueOf(cdl.ContentDocument.CreatedDate)
                        });
                    }
                }
            }

            for (String typeName : typeMap.keySet()) {
                groupedResults.add(new Map<String, Object>{
                    'ExemptionType' => typeName,
                    'Documents'     => typeMap.get(typeName)
                });
            }
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_LAViewExemptionController')
            .setTriggeringAutomationName('getExemptionEvidenceDocumentsGrouped')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error retrieving exemption evidence documents: ' + e.getMessage());
        }
        return groupedResults;
    }


    /**
     * @description Returns the Local_Authority_Notes__c field for the given exemption.
     * @param exemptionId The Id of the Exemption__c record.
     * @return String The exemption notes, or empty string if none.
     * @throws AuraHandledException If exemptionId is null.
     */
    @AuraEnabled(cacheable=true)
    public static String getExemptionNotes(Id exemptionId) {
        Exemption__c ex;

        try {
            if (exemptionId == null) {
                throw new AuraHandledException('Exemption Id is required');
            }

            if(!PRSE_LAViewExemptionHelper.checkExemption(exemptionId)) {
                throw new AuraHandledException('You do not have permission to view this exemption');
            }

            ex = [
                SELECT Local_Authority_Notes__c
                FROM Exemption__c
                WHERE Id = :exemptionId
                LIMIT 1
            ];
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_LAViewExemptionController')
            .setTriggeringAutomationName('getExemptionNotes')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error retrieving exemption notes: ' + e.getMessage());
        }

        return ex.Local_Authority_Notes__c != null ? ex.Local_Authority_Notes__c : '';
    }


    /**
     * @description Updates the Local_Authority_Notes__c field for the given exemption.
     * @param exemptionId The Id of the Exemption__c record.
     * @param notes The text to save to Local_Authority_Notes__c.
     * @return Boolean True if save succeeds.
     * @throws AuraHandledException If exemptionId is null.
     */
    @AuraEnabled
    public static Boolean saveExemptionNotes(Id exemptionId, String notes) {
        try {
            if (exemptionId == null) {
                throw new AuraHandledException('Exemption Id is required');
            }

            if(!PRSE_LAViewExemptionHelper.checkExemption(exemptionId)) {
                throw new AuraHandledException('You do not have permission to view this exemption');
            }

            Exemption__c ex = new Exemption__c(
                Id = exemptionId,
                Local_Authority_Notes__c = notes
            );
            update ex;
        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_LAViewExemptionController')
            .setTriggeringAutomationName('saveExemptionNotes')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
            throw new AuraHandledException('Error saving exemption notes: ' + e.getMessage());
        }
        return true;
    }

    /**
     * @description Returns a link to the EPC certificate if present, otherwise a Salesforce File URL if one is attached.
     * @param exemptionId The Id of the Exemption__c record.
     * @return String The URL to the EPC or file, or null if none exists.
     */
    @AuraEnabled(cacheable=true)
    public static EpcLinkWrapper  getExemptionEpcOrFile(Id exemptionId, String UPRN, String propertyType) {
        //File check on Exemption -> EPC_Certificate__c URL building -> GET Request
        EpcLinkWrapper result = new EpcLinkWrapper();
        result.sourceType = 'none';
        try {
            if (exemptionId == null || propertyType == null) {
                throw new AuraHandledException('Exemption Id and propertyType are required');
            }

            List<ContentDocumentLink> cdls = [
                SELECT 
                    ContentDocumentId,
                    ContentDocument.Title,
                    ContentDocument.FileExtension
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :exemptionId
                ORDER BY ContentDocument.CreatedDate DESC
                LIMIT 1
            ];
            if (!cdls.isEmpty()) {
                result.url = '/sfc/servlet.shepherd/document/download/' + cdls[0].ContentDocumentId;
                result.sourceType = 'file';
                result.fileName = cdls[0].ContentDocument.Title + (cdls[0].ContentDocument.FileExtension != null ? '.' + cdls[0].ContentDocument.FileExtension.toLowerCase() : '');
                result.contentDocumentId = cdls[0].ContentDocumentId;
                return result;
            }

            Exemption__c ex = [
                SELECT EPC_Certificate__c
                FROM Exemption__c
                WHERE Id = :exemptionId
                LIMIT 1
            ];

            if (!String.isBlank(ex.EPC_Certificate__c)) {
                result.url = 'https://find-energy-certificate.service.gov.uk/energy-certificate/' + ex.EPC_Certificate__c;
                result.sourceType = 'certificate';
                return result;
            }

            if(!String.isBlank(UPRN)) {
                // Build a single EPCRequest for the new endpoint
                PRSE_RetrieveEPCInfoAction.EPCRequest req = new PRSE_RetrieveEPCInfoAction.EPCRequest();
                req.uprn = UPRN;
                req.propertyType = propertyType;

                // Wrap in a list
                List<PRSE_RetrieveEPCInfoAction.EPCRequest> requests = new List<PRSE_RetrieveEPCInfoAction.EPCRequest>{ req };

                // Call the new EPC method directly
                List<PRSE_RetrieveEPCInfoAction.EPCResponse> responses = PRSE_RetrieveEPCInfoAction.fetchEPCData(requests);

                Boolean errorResponse = false;
                if(responses[0].address == 'Error') {
                    errorResponse = true;
                    result.url = null;
                    result.sourceType = 'none';
                } else if(String.isNotBlank(responses[0].certificateNumber) && responses[0].isExpired == false) {
                    result.url = 'https://find-energy-certificate.service.gov.uk/energy-certificate/' + responses[0].certificateNumber;
                    result.sourceType = 'api';
                }
            }
            return result;
        } catch (Exception e) {
            errorLoggingService
                .setLogCode('PRSE_LAViewExemptionController')
                .setTriggeringAutomationName('getExemptionEpcOrFile')
                .setMessage(e.getMessage())
                .setFullMessage(e.getStackTraceString())
                .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
                .publish();
            throw new AuraHandledException('Error retrieving EPC or file: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper DTO for returning EPC data.
     */
    public class EpcLinkWrapper {
        @AuraEnabled public String url;           // the actual link
        @AuraEnabled public String sourceType;    // 'certificate', 'file', or 'none'
        @AuraEnabled public String fileName;      // optional, for Salesforce file
        @AuraEnabled public Id contentDocumentId; // new field for Salesforce file
        public EpcLinkWrapper() {}
    }


    /**
     * @description Wrapper DTO for returning landlord data.
     */
    public class ExemptionWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String LandlordFirstName;
        @AuraEnabled public String LandlordLastName;
        @AuraEnabled public String LandlordBusinessName;
        @AuraEnabled public String personAccountBusinessName;
        @AuraEnabled public String LandlordAddress;
        @AuraEnabled public String LandlordPhone;
        @AuraEnabled public String LandlordEmail;
        @AuraEnabled public Boolean DigitallyAssisted;
        @AuraEnabled public String ReasonForCallingADRoute;
        @AuraEnabled public String LandlordType;
    }


    /**
     * @description Wrapper DTO for returning agent data.
     */
    public class AgentWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String FirstName;
        @AuraEnabled public String LastName;
        @AuraEnabled public String Name;
        @AuraEnabled public String BusinessName;
        @AuraEnabled public String Address;
        @AuraEnabled public String Phone;
        @AuraEnabled public String Email;
        @AuraEnabled public String LandlordType;
        @AuraEnabled public Boolean DigitallyAssisted;
        @AuraEnabled public String ReasonForCallingADRoute;
    }


    /**
     * @description Wrapper for parent exemption and child exemption list.
     */
    public class ExemptionDetailsWrapper {
        @AuraEnabled public Exemption__c parentExemption;
        @AuraEnabled public List<ChildExemptionWrapper> childExemptions;
    }

    /**
     * @description Wrapper for child exemption data.
     */
    public class ChildExemptionWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String TypeName;
        @AuraEnabled public String Status;
        @AuraEnabled public DateTime EndDate;
        @AuraEnabled public String EndReason;
        @AuraEnabled public String AdditionalEndReason;
    }

}