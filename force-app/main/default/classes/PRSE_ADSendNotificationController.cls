/**
 * @description Controller class for the PRSE Assisted Digital Send Notification LWC component.
 *              Handles sending GOV.UK Notify notifications (email, SMS, letter) for a given
 *              exemption record based on the associated account's communication preference.
 *              Also sends a notification to the relevant local authority mailbox.
 * @author PRSE Development Team
 */
public without sharing class PRSE_ADSendNotificationController {

    final static digitalmodus.SystemLogService errorLoggingService = new digitalmodus.SystemLogService('PRSE_ADSendNotificationController');

    /**
     * @description Sends a GOV.UK Notify notification for the given exemption record.
     *              Determines the communication channel and template based on the account's
     *              communication preference and number of child exemption links.
     *              Also triggers a local authority email notification.
     * @param recordId The Salesforce ID of the Exemption__c record to send a notification for.
     */
    @AuraEnabled
    public static void sendNotification(Id recordId) {

        try {
            if (recordId == null) {
                throw new Exceptions.InvalidArgumentException('Exemption Id is required');
            }
        
            // Query exemption and related account - includes local authority fields
            Exemption__c exemption = [
                SELECT Id, Ref_Number__c, Full_Property_Address__c,
                    Local_Custodian_Code__c, PropertyType__c,
                    Account__r.FirstName, Account__r.LastName,
                    Account__r.BusinessName__c,
                    Account__r.PersonEmail,
                    Account__r.Phone,
                    Account__r.PersonMailingStreet,
                    Account__r.PersonMailingCity,
                    Account__r.PersonMailingPostalCode,
                    Account__r.Communication_Preference__c
                FROM Exemption__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            List<Exemption_Type_Link__c> exemptionLinks = [
                SELECT Id, Name, Child_Exemption_Ref__c
                FROM Exemption_Type_Link__c
                WHERE Exemption__c = :recordId
            ];

            String commPref = exemption.Account__r.Communication_Preference__c;
            String json = buildJson(exemption, exemptionLinks, commPref);
    
        
            GovNotifyInteractionService.NotifyResponse response;
            
            if (commPref == 'Email') {
                GovNotifyInteractionService.NotifyRequest request = new GovNotifyInteractionService.NotifyRequest();                            
                request.templateId = getTemplateId(commPref, exemptionLinks.size());
                request.email = exemption.Account__r.PersonEmail;
                request.personalisationJson = json;
                response = GovNotifyInteractionService.sendEmail(request);
            } else if (commPref == 'Text') {
                GovNotifyInteractionService.SmsRequest request = new GovNotifyInteractionService.SmsRequest();
                request.templateId = getTemplateId(commPref, exemptionLinks.size());
                request.phoneNumber = exemption.Account__r.Phone;
                request.personalisationJson = json;
                response = GovNotifyInteractionService.sendSms(request);
            } else if (commPref == 'Letter') {
                GovNotifyInteractionService.LetterRequest request = new GovNotifyInteractionService.LetterRequest();
                request.templateId = getTemplateId(commPref, exemptionLinks.size());
                request.personalisationJson = json;
                response = GovNotifyInteractionService.sendLetter(request);
            } else {
                throw new Exceptions.InvalidArgumentException('No communication preference set on this account');
            }
            
            if (response != null && response.status == 'Error') {
                throw new Exceptions.InvalidArgumentException('Notification failed: ' + response.message);
            }

            // Send local authority notification in the same transaction
            sendLocalAuthorityNotification(exemption);
            

        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_ADSendNotificationController')
            .setTriggeringAutomationName('sendNotification')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
        }
    }

    /**
     * @description Sends a GOV.UK Notify email notification to the relevant local authority
     *              mailbox for the given exemption record. The local authority Account is
     *              identified by matching Local_Custodian_Code__c on both the Account and
     *              Exemption__c records. The destination mailbox is chosen based on whether
     *              the exemption's PropertyType__c is Residential (domestic) or Commercial
     *              (non-domestic).
     * @param exemption The already-queried Exemption__c record including Local_Custodian_Code__c
     *                  and PropertyType__c fields.
     */
    private static void sendLocalAuthorityNotification(Exemption__c exemption) {
        try {
            if (exemption == null || exemption.Local_Custodian_Code__c == null) {
                throw new Exceptions.InvalidArgumentException('Exemption record must have a Local Custodian Code to send local authority notification');
            }

            // Find the local authority Account whose custodian code matches the exemption
            List<Account> localAuthorityAccounts = [
                SELECT Id, Name, DomesticNotificationsMailbox__c, NonDomesticNotificationsMailbox__c
                FROM Account
                WHERE Local_Custodian_Code__c = :exemption.Local_Custodian_Code__c
                LIMIT 1
            ];

            if (localAuthorityAccounts.isEmpty()) {
                throw new Exceptions.InvalidArgumentException(
                    'No local authority account found for Local Custodian Code: ' + exemption.Local_Custodian_Code__c
                );
            }

            Account localAuthority = localAuthorityAccounts[0];

            // Choose the mailbox based on property type
            String toEmail;
            if (exemption.PropertyType__c == 'Residential') {
                toEmail = localAuthority.DomesticNotificationsMailbox__c;
            } else if (exemption.PropertyType__c == 'Commercial') {
                toEmail = localAuthority.NonDomesticNotificationsMailbox__c;
            } else {
                throw new Exceptions.InvalidArgumentException(
                    'Unrecognised PropertyType__c value: ' + exemption.PropertyType__c
                );
            }

            if (String.isBlank(toEmail)) {
                throw new Exceptions.InvalidArgumentException(
                    'No notification mailbox address configured on local authority account: ' + localAuthority.Name
                );
            }

            // Build personalisation JSON
            String personalisationJson =
                '{"local authority":"' + localAuthority.Name + '",' +
                '"number":"' + exemption.Ref_Number__c + '"}';

            GovNotifyInteractionService.NotifyRequest request = new GovNotifyInteractionService.NotifyRequest();
            request.templateId          = 'c80567f2-0d35-41c0-8747-41ce6253d66d';
            request.email               = toEmail;
            request.personalisationJson = personalisationJson;

            GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionService.sendEmail(request);

            if (response != null && response.status == 'Error') {
                throw new Exceptions.InvalidArgumentException('Local authority notification failed: ' + response.message);
            }

        } catch (Exception e) {
            errorLoggingService.setLogCode('PRSE_ADSendNotificationController')
            .setTriggeringAutomationName('sendLocalAuthorityNotification')
            .setMessage(e.getMessage())
            .setFullMessage(e.getStackTraceString())
            .setLogSourceCategory(digitalmodus.SystemLogService.LogSourceCategory.APEX_CLASS)
            .publish();
        }
    }

    /**
     * @description Returns the GOV.UK Notify template ID based on the communication preference
     *              and whether there is a single or multiple child exemption links.
     * @param commPref The communication preference value (Email, Text, or Letter).
     * @param exemptionCount The number of child Exemption_Type_Link__c records.
     * @return The GOV.UK Notify template ID string.
     */    
    private static String getTemplateId(String commPref, Integer exemptionCount) {
        Boolean isSingle = exemptionCount == 1;
        String returnValue;
        if (commPref == 'Email') {
            returnValue= isSingle ? '5ffc60d5-43f8-45e4-867b-f8f242374823' : 'fbc2002f-aec1-4dfe-8614-995c769fd832';
        } else if (commPref == 'Text') {
            returnValue= isSingle ? '853e11e9-d53f-4769-b205-be0083f981bb' : 'cde1a5bd-5803-4e9a-9a0b-b71fc744d245';
        } else if (commPref == 'Letter') {
            returnValue= isSingle ? 'f674ecaa-8874-4405-bbc2-01fcf94679a5' : '0f724fec-077a-4f7f-9e0e-2f9ec9c576eb';
        }
        return returnValue;
    }    

    /**
     * @description Builds the GOV.UK Notify personalisation JSON string for the notification.
     *              For single exemptions, includes exemption type and reference number.
     *              For multiple exemptions, includes an array of exemption info strings.
     *              For letter communications, appends postal address lines.
     * @param exemption The Exemption__c record including related Account fields.
     * @param links The list of Exemption_Type_Link__c child records.
     * @param commPref The communication preference value (Email, Text, or Letter).
     * @return A JSON string containing the personalisation data for the notification.
     */
    private static String buildJson(Exemption__c exemption, List<Exemption_Type_Link__c> links, String commPref) {

        Boolean isSingle = links.size() == 1;
        String fullName = exemption.Account__r.FirstName + ' ' + exemption.Account__r.LastName;
        
        String json = '{"full name":"' + fullName + '",';
        
        if (isSingle) {
            json += '"exemption type":"' + links[0].Name + '",' +
                    '"reference number":"' + exemption.Ref_Number__c + '"';
        } else {
            json += '"exemptioninfo":[';
            for (Integer i = 0; i < links.size(); i++) {
                json += '"' + links[i].Name + ' : ' + links[i].Child_Exemption_Ref__c + '"';
                if (i < links.size() - 1) {
                    json += ',';
                }
            }
            json += ']';
        }
        
        if (commPref == 'Letter') {
            json += ',"address_line_1":"' + fullName + '",' +
                    '"address_line_2":"' + exemption.Account__r.PersonMailingStreet + ', ' + exemption.Account__r.PersonMailingCity + '",' +
                    '"address_line_3":"' + exemption.Account__r.PersonMailingPostalCode + '"';
        }
        
        json += '}';
        
        return json;

    }
}