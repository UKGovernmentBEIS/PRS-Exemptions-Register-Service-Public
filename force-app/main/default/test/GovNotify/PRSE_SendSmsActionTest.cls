@isTest
private class PRSE_SendSmsActionTest {
    @isTest
    static void sendSms_withNullRequests_throwsException() {
        //Arrange, Act
        try {
            PRSE_SendSmsAction.sendSms(null);
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            //Assert
            Assert.areEqual('System.IllegalArgumentException', ex.getTypeName(), 'Expected to throw an IllegalArgumentException');
            Assert.areEqual('Request not provided', ex.getMessage(), 'Should return request not provided message.');
        }
    }
    
    @isTest
    static void sendSms_withEmptyRequests_throwsException() {
        //Arrange, Act
        try {
            PRSE_SendSmsAction.sendSms(new List<GovNotifyInteractionService.SmsRequest>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            //Assert
            Assert.areEqual('System.IllegalArgumentException', ex.getTypeName(), 'Expected to throw an IllegalArgumentException');
            Assert.areEqual('Request not provided', ex.getMessage(), 'Should return request not provided message.');
        }
    }
    
    @isTest
    static void sendSms_withRequest_returnsResponse() {
        //Arrange
        GovNotifyInteractionService.SmsRequest request = new GovNotifyInteractionService.SmsRequest();
        request.phoneNumber = '+447700900123';
        request.templateId = '123';
        request.personalisationJson = 'definitely an object';
        MockProvider mockProvider = new MockProvider();
        GovNotifyInteractionService.API mockLayer = (GovNotifyInteractionService.API) mockProvider.createMock(GovNotifyInteractionServiceLayer.class);
        GovNotifyInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.sendSms(request)).thenReturn(createMockResponse());
        
        //Act
        List<GovNotifyInteractionService.NotifyResponse> responses = PRSE_SendSmsAction.sendSms(
            new List<GovNotifyInteractionService.SmsRequest>{ 
                request 
            }
        );
        
        //Assert
        Assert.areEqual(1, responses.size(), 'Incorrect number of responses returned');
        Assert.areEqual('OK', responses[0].status, 'Incorrect status returned');
        Assert.areEqual('SMS sent successfully', responses[0].message, 'Incorrect message returned');
    }
    
    public static GovNotifyInteractionService.NotifyResponse createMockResponse() {
        GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
        response.status = 'OK';
        response.message = 'SMS sent successfully';
        return response;
    }
}