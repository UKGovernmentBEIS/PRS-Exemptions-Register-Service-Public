/**
 * @description Unit tests for PRSE_ADSendNotificationController.
 *              Covers all execution paths including email, SMS, letter,
 *              single and multiple exemptions, and error conditions.
 */
@isTest(IsParallel=true)
private class PRSE_ADSendNotificationControllerTest {

    // ─── Mock ──────────────────────────────────────────────────────────────────

    /**
     * @description Mock implementation of GovNotifyInteractionService.API
     *              to prevent actual callouts during testing.
     */
    private class GovNotifyMock implements GovNotifyInteractionService.API {
        
        public Boolean emailCalled = false;
        public Boolean smsCalled = false;
        public Boolean letterCalled = false;
        public Integer emailCallCount = 0;
        public String lastTemplateId;
        public String lastJson;

        /**
         * @description Mock sendEmail implementation.
         * @param request The email request.
         * @return A successful NotifyResponse.
         */
        public GovNotifyInteractionService.NotifyResponse sendEmail(GovNotifyInteractionService.NotifyRequest request) {
            emailCalled = true;
            emailCallCount++;
            lastTemplateId = request.templateId;
            lastJson = request.personalisationJson;
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Success';
            response.message = 'Email sent';
            return response;
        }

        /**
         * @description Mock sendSms implementation.
         * @param request The SMS request.
         * @return A successful NotifyResponse.
         */
        public GovNotifyInteractionService.NotifyResponse sendSms(GovNotifyInteractionService.SmsRequest request) {
            smsCalled = true;
            lastTemplateId = request.templateId;
            lastJson = request.personalisationJson;
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Success';
            response.message = 'SMS sent';
            return response;
        }

        /**
         * @description Mock sendLetter implementation.
         * @param request The letter request.
         * @return A successful NotifyResponse.
         */
        public GovNotifyInteractionService.NotifyResponse sendLetter(GovNotifyInteractionService.LetterRequest request) {
            letterCalled = true;
            lastTemplateId = request.templateId;
            lastJson = request.personalisationJson;
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Success';
            response.message = 'Letter sent';
            return response;
        }
    }

    /**
     * @description Mock that returns an error response to test error handling.
     */
    private class GovNotifyErrorMock implements GovNotifyInteractionService.API {

        /**
         * @description Mock sendEmail that returns an error response.
         * @param request The email request.
         * @return An error NotifyResponse.
         */
        public GovNotifyInteractionService.NotifyResponse sendEmail(GovNotifyInteractionService.NotifyRequest request) {
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Error';
            response.message = 'Template not found';
            return response;
        }

        /**
         * @description Mock sendSms that returns an error response.
         * @param request The SMS request.
         * @return An error NotifyResponse.
         */
        public GovNotifyInteractionService.NotifyResponse sendSms(GovNotifyInteractionService.SmsRequest request) {
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Error';
            response.message = 'Template not found';
            return response;
        }

        /**
         * @description Mock sendLetter that returns an error response.
         * @param request The letter request.
         * @return An error NotifyResponse.
         */
        public GovNotifyInteractionService.NotifyResponse sendLetter(GovNotifyInteractionService.LetterRequest request) {
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Error';
            response.message = 'Template not found';
            return response;
        }
    }

    /**
     * @description Mock that captures the template ID, email address, and personalisation
     *              JSON from the first and second sendEmail calls separately, allowing
     *              tests to assert on the applicant and local authority calls independently.
     *              Also captures SMS and letter calls so all comm pref tests can use this mock.
     */
    private class CaptureAllEmailsMock implements GovNotifyInteractionService.API {

        public String firstTemplateId;
        public String firstEmail;
        public String firstJson;
        public String secondTemplateId;
        public String secondEmail;
        public String secondJson;
        public Boolean smsCalled = false;
        public String smsTemplateId;
        public String smsJson;
        public Boolean letterCalled = false;
        public String letterTemplateId;
        public String letterJson;
        private Integer callCount = 0;

        public GovNotifyInteractionService.NotifyResponse sendEmail(GovNotifyInteractionService.NotifyRequest request) {
            callCount++;
            if (callCount == 1) {
                firstTemplateId = request.templateId;
                firstEmail = request.email;
                firstJson = request.personalisationJson;
            } else {
                secondTemplateId = request.templateId;
                secondEmail = request.email;
                secondJson = request.personalisationJson;
            }
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Success';
            response.message = 'Email sent';
            return response;
        }

        public GovNotifyInteractionService.NotifyResponse sendSms(GovNotifyInteractionService.SmsRequest request) {
            smsCalled = true;
            smsTemplateId = request.templateId;
            smsJson = request.personalisationJson;
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Success';
            response.message = 'SMS sent';
            return response;
        }

        public GovNotifyInteractionService.NotifyResponse sendLetter(GovNotifyInteractionService.LetterRequest request) {
            letterCalled = true;
            letterTemplateId = request.templateId;
            letterJson = request.personalisationJson;
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Success';
            response.message = 'Letter sent';
            return response;
        }
    }

    private static final String TEST_CUSTODIAN_CODE = '520';

    /**
     * @description Creates a test Account with all required person account fields.
     * @param commPref The communication preference to set on the account.
     * @return The inserted Account record.
     */
    private static Account createTestAccount(String commPref) {
        Account acc = new Account(
            FirstName = 'Mark',
            LastName = 'Brown',
            PersonEmail = 'mark@test.com',
            Phone = '07700900000',
            PersonMailingStreet = '12 Caxton Road',
            PersonMailingCity = 'Nottingham',
            PersonMailingPostalCode = 'NG5 1RH',
            Communication_Preference__c = commPref,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsPersonType = true LIMIT 1].Id
        );
        insert acc;
        return acc;
    }

    /**
     * @description Creates a test local authority Account with the shared custodian code
     *              and both notification mailbox addresses populated.
     * @return The inserted local authority Account record.
     */
    private static Account createLocalAuthorityAccount() {
        Account la = new Account(
            Name = 'Test Local Authority',
            Local_Custodian_Code__c = TEST_CUSTODIAN_CODE,
            DomesticNotificationsMailbox__c = 'domestic@localauthority.gov.uk',
            NonDomesticNotificationsMailbox__c = 'nondomestic@localauthority.gov.uk'
        );
        insert la;
        return la;
    }

    /**
     * @description Creates a test Exemption__c record linked to the given account.
     *              Defaults PropertyType__c to Residential.
     * @param accountId The ID of the Account to link the exemption to.
     * @return The inserted Exemption__c record.
     */
    private static Exemption__c createTestExemption(Id accountId) {
        return createTestExemption(accountId, 'Residential');
    }

    /**
     * @description Creates a test Exemption__c record linked to the given account
     *              with the specified property type.
     * @param accountId The ID of the Account to link the exemption to.
     * @param propertyType 'Residential' or 'Commercial'.
     * @return The inserted Exemption__c record.
     */
    private static Exemption__c createTestExemption(Id accountId, String propertyType) {
        Exemption__c exemption = new Exemption__c(
            Account__c = accountId,
            PropertyType__c = propertyType,
            Local_Custodian_Code__c = TEST_CUSTODIAN_CODE,
            PropertyAddress__c = '12 Caxton Road',
            PropertyCity__c = 'Nottingham',
            PropertyPostcode__c = 'NG5 1RH'
        );
        insert exemption;
        return exemption;
    }

    /**
     * @description Creates a single Exemption_Type__c and Exemption_Type_Link__c for the given exemption.
     * @param exemptionId The ID of the parent Exemption__c record.
     */
    private static void createSingleExemptionLink(Id exemptionId) {
        Exemption_Type__c exemptionType = new Exemption_Type__c(
            Name = 'Wall insulation',
            Code__c = 'D01'
        );
        insert exemptionType;

        Exemption_Type_Link__c link = new Exemption_Type_Link__c(
            Exemption__c = exemptionId,
            Exemption_Type__c = exemptionType.Id
        );
        insert link;
    }

    /**
     * @description Creates two Exemption_Type__c and Exemption_Type_Link__c records for the given exemption.
     * @param exemptionId The ID of the parent Exemption__c record.
     */
    private static void createMultipleExemptionLinks(Id exemptionId) {
        Exemption_Type__c type1 = new Exemption_Type__c(
            Name = 'Wall insulation',
            Code__c = 'D01'
        );
        Exemption_Type__c type2 = new Exemption_Type__c(
            Name = 'High cost',
            Code__c = 'D02'
        );
        insert new List<Exemption_Type__c>{ type1, type2 };

        insert new List<Exemption_Type_Link__c>{
            new Exemption_Type_Link__c(
                Exemption__c = exemptionId,
                Exemption_Type__c = type1.Id
            ),
            new Exemption_Type_Link__c(
                Exemption__c = exemptionId,
                Exemption_Type__c = type2.Id
            )
        };
    }

    /**
     * @description Tests sendNotification with email preference and single exemption
     *              calls sendEmail on the service with the single email template ID.
     */
    @isTest
    static void sendNotification_withEmailPrefSingleExemption_callsSendEmailWithSingleTemplate() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assertEquals(true, mock.firstEmail != null, 'sendEmail should have been called');
        System.assertEquals('5ffc60d5-43f8-45e4-867b-f8f242374823', mock.firstTemplateId, 'Single email template ID should be used');
    }

    /**
     * @description Tests sendNotification with email preference and multiple exemptions
     *              calls sendEmail on the service with the multiple email template ID.
     */
    @isTest
    static void sendNotification_withEmailPrefMultipleExemptions_callsSendEmailWithMultipleTemplate() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createMultipleExemptionLinks(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assertEquals(true, mock.firstEmail != null, 'sendEmail should have been called');
        System.assertEquals('fbc2002f-aec1-4dfe-8614-995c769fd832', mock.firstTemplateId, 'Multiple email template ID should be used');
    }

    /**
     * @description Tests sendNotification with text preference and single exemption
     *              calls sendSms on the service with the single SMS template ID.
     */
    @isTest
    static void sendNotification_withTextPrefSingleExemption_callsSendSmsWithSingleTemplate() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Text');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assertEquals(true, mock.smsCalled, 'sendSms should have been called');
        System.assertEquals('853e11e9-d53f-4769-b205-be0083f981bb', mock.smsTemplateId, 'Single SMS template ID should be used');
    }

    /**
     * @description Tests sendNotification with text preference and multiple exemptions
     *              calls sendSms on the service with the multiple SMS template ID.
     */
    @isTest
    static void sendNotification_withTextPrefMultipleExemptions_callsSendSmsWithMultipleTemplate() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Text');
        Exemption__c exemption = createTestExemption(acc.Id);
        createMultipleExemptionLinks(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assertEquals(true, mock.smsCalled, 'sendSms should have been called');
        System.assertEquals('cde1a5bd-5803-4e9a-9a0b-b71fc744d245', mock.smsTemplateId, 'Multiple SMS template ID should be used');
    }

    /**
     * @description Tests sendNotification with letter preference and single exemption
     *              calls sendLetter on the service with the single letter template ID.
     */
    @isTest
    static void sendNotification_withLetterPrefSingleExemption_callsSendLetterWithSingleTemplate() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Letter');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assertEquals(true, mock.letterCalled, 'sendLetter should have been called');
        System.assertEquals('f674ecaa-8874-4405-bbc2-01fcf94679a5', mock.letterTemplateId, 'Single letter template ID should be used');
    }

    /**
     * @description Tests sendNotification with letter preference and multiple exemptions
     *              calls sendLetter on the service with the multiple letter template ID.
     */
    @isTest
    static void sendNotification_withLetterPrefMultipleExemptions_callsSendLetterWithMultipleTemplate() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Letter');
        Exemption__c exemption = createTestExemption(acc.Id);
        createMultipleExemptionLinks(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assertEquals(true, mock.letterCalled, 'sendLetter should have been called');
        System.assertEquals('0f724fec-077a-4f7f-9e0e-2f9ec9c576eb', mock.letterTemplateId, 'Multiple letter template ID should be used');
    }

    /**
     * @description Tests sendNotification with single exemption produces JSON
     *              containing exemption type and reference number nodes.
     */
    @isTest
    static void sendNotification_withSingleExemption_jsonContainsExemptionTypeAndReferenceNumber() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assert(mock.firstJson.contains('"exemption type"'), 'JSON should contain exemption type node');
        System.assert(mock.firstJson.contains('"reference number"'), 'JSON should contain reference number node');
        System.assert(!mock.firstJson.contains('"exemptioninfo"'), 'JSON should not contain exemptioninfo array for single');
    }

    /**
     * @description Tests sendNotification with multiple exemptions produces JSON
     *              containing exemptioninfo array node.
     */
    @isTest
    static void sendNotification_withMultipleExemptions_jsonContainsExemptionInfoArray() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createMultipleExemptionLinks(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assert(mock.firstJson.contains('"exemptioninfo"'), 'JSON should contain exemptioninfo array');
        System.assert(!mock.firstJson.contains('"reference number"'), 'JSON should not contain reference number for multiple');
    }

    /**
     * @description Tests sendNotification with letter preference produces JSON
     *              containing address line nodes.
     */
    @isTest
    static void sendNotification_withLetterPref_jsonContainsAddressLines() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Letter');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assert(mock.letterJson.contains('"address_line_1"'), 'JSON should contain address_line1');
        System.assert(mock.letterJson.contains('"address_line_2"'), 'JSON should contain address_line2');
        System.assert(mock.letterJson.contains('"address_line_3"'), 'JSON should contain address_line3');
        System.assert(mock.letterJson.contains('NG5 1RH'), 'JSON should contain postcode in address_line3');
    }

    /**
     * @description Tests sendNotification with email preference produces JSON
     *              without address line nodes.
     */
    @isTest
    static void sendNotification_withEmailPref_jsonDoesNotContainAddressLines() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assert(!mock.firstJson.contains('"address_line1"'), 'JSON should not contain address lines for email');
    }

    /**
     * @description Tests sendNotification with no communication preference set
     *              logs error with appropriate message.
     */
    @isTest
    static void sendNotification_withNoCommunicationPreference_logsError() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount(null);
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        GovNotifyMock mock = new GovNotifyMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendNotification', 'No communication preference set on this account');
    }

    /**
     * @description Tests sendNotification when the notify service returns an error response
     *              logs error with the service error message.
     */
    @isTest
    static void sendNotification_withServiceErrorResponse_logsErrorWithServiceMessage() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        GovNotifyErrorMock errorMock = new GovNotifyErrorMock();
        GovNotifyInteractionServiceLayer.instance = errorMock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendNotification', 'Notification failed: Template not found');
    }

    /**
     * @description Tests that sendNotification sends two emails in total — one to the
     *              applicant and one to the local authority — when the comm pref is Email.
     */
    @isTest
    static void sendNotification_always_callsSendEmailTwiceForEmailPref() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        GovNotifyMock mock = new GovNotifyMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assertEquals(2, mock.emailCallCount, 'sendEmail should be called twice — once for applicant, once for local authority');
    }

    /**
     * @description Tests that the local authority email uses the correct template ID.
     */
    @isTest
    static void sendNotification_localAuthorityEmail_usesCorrectTemplateId() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assertEquals('c80567f2-0d35-41c0-8747-41ce6253d66d', mock.secondTemplateId,
            'Local authority email should use the correct template ID');
    }

    /**
     * @description Tests that the local authority email for a Residential exemption
     *              is sent to the DomesticNotificationsMailbox address.
     */
    @isTest
    static void sendNotification_withResidentialExemption_localAuthorityEmailSentToDomesticMailbox() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assertEquals('domestic@localauthority.gov.uk', mock.secondEmail,
            'Residential exemption should route to DomesticNotificationsMailbox');
    }

    /**
     * @description Tests that the local authority email for a Commercial exemption
     *              is sent to the NonDomesticNotificationsMailbox address.
     */
    @isTest
    static void sendNotification_withCommercialExemption_localAuthorityEmailSentToNonDomesticMailbox() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id, 'Commercial');
        createSingleExemptionLink(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assertEquals('nondomestic@localauthority.gov.uk', mock.secondEmail,
            'Commercial exemption should route to NonDomesticNotificationsMailbox');
    }

    /**
     * @description Tests that the local authority personalisation JSON contains
     *              the local authority name and exemption reference number.
     */
    @isTest
    static void sendNotification_localAuthorityEmail_jsonContainsLocalAuthorityNameAndRefNumber() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        CaptureAllEmailsMock mock = new CaptureAllEmailsMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        System.assert(mock.secondJson.contains('"local authority"'),
            'Local authority JSON should contain local authority key');
        System.assert(mock.secondJson.contains('Test Local Authority'),
            'Local authority JSON should contain the account name');
        System.assert(mock.secondJson.contains('"number"'),
            'Local authority JSON should contain number key');
    }

    /**
     * @description Tests that sendNotification logs error when no
     *              local authority account matches the exemption custodian code.
     */
    @isTest
    static void sendNotification_withNoMatchingLocalAuthorityAccount_logsError() {
        // Deliberately do NOT create a local authority account
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        GovNotifyMock mock = new GovNotifyMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendLocalAuthorityNotification', 'No local authority account found for Local Custodian Code: 520');
    }

    /**
     * @description Tests that sendNotification logs an error when the
     *              local authority account has no mailbox address configured.
     */
    @isTest
    static void sendNotification_withBlankLocalAuthorityMailbox_logsError() {
        Account la = new Account(
            Name = 'Empty Mailbox Authority',
            Local_Custodian_Code__c = TEST_CUSTODIAN_CODE,
            DomesticNotificationsMailbox__c = null,
            NonDomesticNotificationsMailbox__c = null
        );
        insert la;

        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        GovNotifyMock mock = new GovNotifyMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        String expectedError = 'No notification mailbox address configured on local authority account: ' + la.Name;
        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendLocalAuthorityNotification', expectedError);
    }    

    /**
     * @description Tests sendNotification with a null recordId and logs an error.
     */
    @isTest
    static void sendNotification_withNullRecordId_logsError() {
        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(null);
        Test.stopTest();

        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendNotification', 'Exemption Id is required');
    }

    /**
     * @description Tests sendNotification with an unrecognised communication preference and logs an error.
     */
    @isTest
    static void sendNotification_withInvalidCommunicationPreference_logsError() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);
        GovNotifyMock mock = new GovNotifyMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendNotification', 'No communication preference set on this account');
    }

    /**
     * @description Tests sendNotification with Text preference when the notify service
     *              returns an error response logs error.
     */
    @isTest
    static void sendNotification_withSmsServiceErrorResponse_logsError() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Text');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        GovNotifyErrorMock errorMock = new GovNotifyErrorMock();
        GovNotifyInteractionServiceLayer.instance = errorMock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendNotification', 'Notification failed: Template not found');
    }

    /**
     * @description Tests sendNotification with Letter preference when the notify service
     *              returns an error response logs an error
     */
    @isTest
    static void sendNotification_withLetterServiceErrorResponse_logsError() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Letter');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        GovNotifyErrorMock errorMock = new GovNotifyErrorMock();
        GovNotifyInteractionServiceLayer.instance = errorMock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendNotification', 'Notification failed: Template not found');
    }

    /**
     * @description Tests that when the local authority notify call returns an error,
     *              an error is logged even though the applicant call succeeded.
     *              Uses a mock that succeeds on the first sendEmail call and errors on the second.
     */
    @isTest
    static void sendNotification_withLocalAuthorityServiceError_logsError() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');
        Exemption__c exemption = createTestExemption(acc.Id);
        createSingleExemptionLink(exemption.Id);

        // Succeeds for applicant, errors for local authority
        PartialErrorMock mock = new PartialErrorMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendLocalAuthorityNotification', 'Local authority notification failed: Local authority template not found');
    }

    /**
     * @description Tests sendLocalAuthorityNotification logs error
     *              when PropertyType__c is not Residential or Commercial.
     */
    @isTest
    static void sendNotification_withBlankPropertyType_logsError() {
        createLocalAuthorityAccount();
        Account acc = createTestAccount('Email');

        // Insert exemption with an invalid PropertyType__c value
        Exemption__c exemption = new Exemption__c(
            Account__c = acc.Id,
            Local_Custodian_Code__c = TEST_CUSTODIAN_CODE,
            PropertyAddress__c = '12 Caxton Road',
            PropertyCity__c = 'Nottingham',
            PropertyPostcode__c = 'NG5 1RH'
        );
        insert exemption;
        createSingleExemptionLink(exemption.Id);

        GovNotifyMock mock = new GovNotifyMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendLocalAuthorityNotification', 'Unrecognised PropertyType__c value: null');
    }
        
    /**
     * @description Tests sendNotification logs error when the
     *              exemption has no Local Custodian Code set, hitting the null
     *              guard in sendLocalAuthorityNotification.
     */
    @isTest
    static void sendNotification_withNullLocalCustodianCode_logsError() {
        Account acc = createTestAccount('Email');

        Exemption__c exemption = new Exemption__c(
            Account__c = acc.Id,
            PropertyType__c = 'Residential',
            PropertyAddress__c = '12 Caxton Road',
            PropertyCity__c = 'Nottingham',
            PropertyPostcode__c = 'NG5 1RH'
            // Local_Custodian_Code__c intentionally omitted
        );
        insert exemption;
        createSingleExemptionLink(exemption.Id);

        GovNotifyMock mock = new GovNotifyMock();
        GovNotifyInteractionServiceLayer.instance = mock;

        Test.startTest();
        PRSE_ADSendNotificationController.sendNotification(exemption.Id);
        Test.stopTest();

        ErrorLogChecker.checkErrorForServiceAndMethod('PRSE_ADSendNotificationController', 'sendLocalAuthorityNotification', 'Exemption record must have a Local Custodian Code to send local authority notification');
    }   
        
    /**
     * @description Mock that succeeds on the first sendEmail call and returns an error
     *              on the second, simulating a local authority notification failure.
     */
    private class PartialErrorMock implements GovNotifyInteractionService.API {
        private Integer callCount = 0;

        public GovNotifyInteractionService.NotifyResponse sendEmail(GovNotifyInteractionService.NotifyRequest request) {
            callCount++;
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            if (callCount == 1) {
                response.status = 'Success';
                response.message = 'Email sent';
            } else {
                response.status = 'Error';
                response.message = 'Local authority template not found';
            }
            return response;
        }

        public GovNotifyInteractionService.NotifyResponse sendSms(GovNotifyInteractionService.SmsRequest request) {
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Success';
            return response;
        }

        public GovNotifyInteractionService.NotifyResponse sendLetter(GovNotifyInteractionService.LetterRequest request) {
            GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
            response.status = 'Success';
            return response;
        }
    }
    
}
