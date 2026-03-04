public with sharing class PRSE_RetrieveCountriesAction {

    public class Response {
        
        @InvocableVariable
        public String concatenatedCountries;

        public Response(String concatenatedCountries) {
            this.concatenatedCountries = concatenatedCountries;
        }
    }

    @InvocableMethod(
        label='Get countries from global value set' 
        description='Returns available countries for account registration.'
        category='PRS Exemption Register'
    )
    public static List<Response> getCountries() {
        DescribeFieldResult fieldResult = Exemption__c.LandlordCountry__c.getDescribe();
        List<PicklistEntry> values = fieldResult.getPicklistValues();
        String concatenatedCountries = '';
        for(PicklistEntry value :values) {
            concatenatedCountries += value.getValue() + '|';
        }
        return new List<Response>{ 
            new Response(
                concatenatedCountries.removeEnd('|')
            ) 
        };
    }
}