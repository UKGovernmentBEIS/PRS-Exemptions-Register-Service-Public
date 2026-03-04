@isTest
private class PRSE_SendEmailActionTest {

    @isTest
    static void sendEmail_withNullRequests_throwsException() {
        //Arrange, Act
        try {
            PRSE_SendEmailAction.sendEmail(null);
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            //Assert
            Assert.areEqual('System.IllegalArgumentException', ex.getTypeName(), 'Expected to throw an IllegalArgumentException');
            Assert.areEqual('Request not provided', ex.getMessage(), 'Should return request not provided message.');
        }
    }

    @isTest
    static void sendEmail_withEmptyRequests_throwsException() {
        //Arrange, Act
        try {
            PRSE_SendEmailAction.sendEmail(new List<GovNotifyInteractionService.NotifyRequest>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            //Assert
            Assert.areEqual('System.IllegalArgumentException', ex.getTypeName(), 'Expected to throw an IllegalArgumentException');
            Assert.areEqual('Request not provided', ex.getMessage(), 'Should return request not provided message.');
        }
    }

    @isTest
    static void sendEmail_withRequest_returnsResponse() {
        //Arrange
        GovNotifyInteractionService.NotifyRequest request = new GovNotifyInteractionService.NotifyRequest();
        request.email = 'test@test.com';
        request.templateId = '123';
        request.personalisationJson = 'definitely an object';

        MockProvider mockProvider = new MockProvider();
        GovNotifyInteractionService.API mockLayer = (GovNotifyInteractionService.API) mockProvider.createMock(GovNotifyInteractionServiceLayer.class);
        GovNotifyInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.sendEmail(request)).thenReturn(createMockResponse());

        //Act
        List<GovNotifyInteractionService.NotifyResponse> responses = PRSE_SendEmailAction.sendEmail(
            new List<GovNotifyInteractionService.NotifyRequest>{ 
                request 
            }
        );

        //Assert
        Assert.areEqual(1, responses.size(), 'Incorrect number of responses returned');
        Assert.areEqual('OK', responses[0].status, 'Incorrect status returned');
        Assert.areEqual('Email sent successfully', responses[0].message, 'Incorrect message returned');
    }
    
    public static GovNotifyInteractionService.NotifyResponse createMockResponse() {
        GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
        response.status = 'OK';
        response.message = 'Email sent successfully';
        return response;
    }
}