@isTest
private class PRSE_SendLetterActionTest {
    @isTest
    static void sendLetter_withNullRequests_throwsException() {
        //Arrange, Act
        try {
            PRSE_SendLetterAction.sendLetter(null);
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            //Assert
            Assert.areEqual('System.IllegalArgumentException', ex.getTypeName(), 'Expected to throw an IllegalArgumentException');
            Assert.areEqual('Request not provided', ex.getMessage(), 'Should return request not provided message.');
        }
    }
    
    @isTest
    static void sendLetter_withEmptyRequests_throwsException() {
        //Arrange, Act
        try {
            PRSE_SendLetterAction.sendLetter(new List<GovNotifyInteractionService.LetterRequest>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            //Assert
            Assert.areEqual('System.IllegalArgumentException', ex.getTypeName(), 'Expected to throw an IllegalArgumentException');
            Assert.areEqual('Request not provided', ex.getMessage(), 'Should return request not provided message.');
        }
    }
    
    @isTest
    static void sendLetter_withRequest_returnsResponse() {
        //Arrange
        GovNotifyInteractionService.LetterRequest request = new GovNotifyInteractionService.LetterRequest();
        request.templateId = '123';
        request.personalisationJson = '{"address_line_1": "123 Test Street"}';
        MockProvider mockProvider = new MockProvider();
        GovNotifyInteractionService.API mockLayer = (GovNotifyInteractionService.API) mockProvider.createMock(GovNotifyInteractionServiceLayer.class);
        GovNotifyInteractionServiceLayer.instance = mockLayer;
        mockProvider.when(mockLayer.sendLetter(request)).thenReturn(createMockResponse());
        
        //Act
        List<GovNotifyInteractionService.NotifyResponse> responses = PRSE_SendLetterAction.sendLetter(
            new List<GovNotifyInteractionService.LetterRequest>{ 
                request 
            }
        );
        
        //Assert
        Assert.areEqual(1, responses.size(), 'Incorrect number of responses returned');
        Assert.areEqual('OK', responses[0].status, 'Incorrect status returned');
        Assert.areEqual('Letter sent successfully', responses[0].message, 'Incorrect message returned');
    }
    
    public static GovNotifyInteractionService.NotifyResponse createMockResponse() {
        GovNotifyInteractionService.NotifyResponse response = new GovNotifyInteractionService.NotifyResponse();
        response.status = 'OK';
        response.message = 'Letter sent successfully';
        return response;
    }
}