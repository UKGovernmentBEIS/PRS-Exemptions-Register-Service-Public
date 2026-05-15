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

    @isTest
    static void sendEmail_withMultipleRequest_returnsMultipleResponse() {
        //Arrange
        GovNotifyInteractionService.NotifyRequest request1 = new GovNotifyInteractionService.NotifyRequest();
        request1.email = 'test@test.com';
        request1.templateId = '123';
        request1.personalisationJson = 'definitely an object 1';

        GovNotifyInteractionService.NotifyRequest request2 = new GovNotifyInteractionService.NotifyRequest();
        request2.email = 'test@test.com';
        request2.templateId = '123';
        request2.personalisationJson = 'definitely an object 2';

        MockProvider mockProvider = new MockProvider();
        GovNotifyInteractionService.API mockLayer = (GovNotifyInteractionService.API) mockProvider.createMock(GovNotifyInteractionServiceLayer.class);
        GovNotifyInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.sendEmail(request1)).thenReturn(createMockResponse());
        mockProvider.when(mockLayer.sendEmail(request2)).thenReturn(createMockResponse());

        //Act
        List<GovNotifyInteractionService.NotifyResponse> responses = PRSE_SendEmailAction.sendEmail(
            new List<GovNotifyInteractionService.NotifyRequest>{ 
                request1, request2 
            }
        );

        //Assert
        Assert.areEqual(2, responses.size(), 'Incorrect number of responses returned');
        Assert.areEqual('OK', responses[0].status, 'Incorrect status returned');
        Assert.areEqual('Email sent successfully', responses[0].message, 'Incorrect message returned');
        Assert.areEqual('OK', responses[1].status, 'Incorrect status returned');
        Assert.areEqual('Email sent successfully', responses[1].message, 'Incorrect message returned');
    }
    
    public static GovNotifyInteractionService.NotifyResponse createMockResponse() {
        GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
        response.status = 'OK';
        response.message = 'Email sent successfully';
        return response;
    }
}