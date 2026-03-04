@isTest(IsParallel=true)
private class GovNotifyInteractionServiceTest {
        
    @isTest
    static void sendEmail_callsLayer_returnsResponse() {
        //Arrange
        Map<String, String> personalisation = new Map<String, String>();
        personalisation.put('first name', 'test');
        personalisation.put('url', 'www.google.com');
        GovNotifyInteractionService.NotifyRequest singleRequest = new GovNotifyInteractionService.NotifyRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.email = 'test@test.com';
        singleRequest.personalisationJson = JSON.serialize(personalisation);
        MockProvider mockProvider = new MockProvider();
        GovNotifyInteractionService.API mockLayer = (GovNotifyInteractionService.API) mockProvider.createMock(GovNotifyInteractionServiceLayer.class);
        GovNotifyInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.sendEmail(singleRequest)).thenReturn(createMockResponse('Email'));
        
        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionService.sendEmail(singleRequest);
        
        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('OK', response.status, 'Incorrect status returned');
        Assert.areEqual('Email sent successfully', response.message, 'Incorrect message returned');
    }
    
    @isTest
    static void sendSms_callsLayer_returnsResponse() {
        //Arrange
        Map<String, String> personalisation = new Map<String, String>();
        personalisation.put('name', 'test');
        personalisation.put('code', '123456');
        GovNotifyInteractionService.SmsRequest singleRequest = new GovNotifyInteractionService.SmsRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.phoneNumber = '+447700900123';
        singleRequest.personalisationJson = JSON.serialize(personalisation);
        MockProvider mockProvider = new MockProvider();
        GovNotifyInteractionService.API mockLayer = (GovNotifyInteractionService.API) mockProvider.createMock(GovNotifyInteractionServiceLayer.class);
        GovNotifyInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.sendSms(singleRequest)).thenReturn(createMockResponse('SMS'));
        
        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionService.sendSms(singleRequest);
        
        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('OK', response.status, 'Incorrect status returned');
        Assert.areEqual('SMS sent successfully', response.message, 'Incorrect message returned');
    }
    
    @isTest
    static void sendLetter_callsLayer_returnsResponse() {
        //Arrange
        Map<String, String> personalisation = new Map<String, String>();
        personalisation.put('address_line_1', '123 Test Street');
        personalisation.put('address_line_2', 'Test Town');
        personalisation.put('postcode', 'TE1 1ST');
        GovNotifyInteractionService.LetterRequest singleRequest = new GovNotifyInteractionService.LetterRequest();
        singleRequest.templateId = '4442133123';
        singleRequest.personalisationJson = JSON.serialize(personalisation);
        MockProvider mockProvider = new MockProvider();
        GovNotifyInteractionService.API mockLayer = (GovNotifyInteractionService.API) mockProvider.createMock(GovNotifyInteractionServiceLayer.class);
        GovNotifyInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.sendLetter(singleRequest)).thenReturn(createMockResponse('Letter'));
        
        //Act
        GovNotifyInteractionService.NotifyResponse response = GovNotifyInteractionService.sendLetter(singleRequest);
        
        //Assert
        Assert.isNotNull(response, 'Expected Response to be returned.');
        Assert.areEqual('OK', response.status, 'Incorrect status returned');
        Assert.areEqual('Letter sent successfully', response.message, 'Incorrect message returned');
    }
    
    public static GovNotifyInteractionService.NotifyResponse createMockResponse(String notificationType) {
        GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
        response.status = 'OK';
        response.message = notificationType + ' sent successfully';
        return response;
    }
}