public without sharing class PRSE_RetrieveExemptionTypes {

    public class ExemptionTypeData {
        @InvocableVariable(label='D01 Name')
        public String D01_Name;
        @InvocableVariable(label='D02 Name')
        public String D02_Name;
        @InvocableVariable(label='D03 Name')
        public String D03_Name;
        @InvocableVariable(label='D04 Name')
        public String D04_Name;
        @InvocableVariable(label='D05 Name')
        public String D05_Name;
        @InvocableVariable(label='D06 Name')
        public String D06_Name;
        @InvocableVariable(label='ND01 Name')
        public String ND01_Name;
        @InvocableVariable(label='ND02 Name')
        public String ND02_Name;
        @InvocableVariable(label='ND03 Name')
        public String ND03_Name;
        @InvocableVariable(label='ND04 Name')
        public String ND04_Name;
        @InvocableVariable(label='ND05 Name')
        public String ND05_Name;
        @InvocableVariable(label='ND06 Name')
        public String ND06_Name;

        @InvocableVariable(label='D01 Required Evidence')
        public String D01_RequiredEvidence;
        @InvocableVariable(label='D02 Required Evidence')
        public String D02_RequiredEvidence;
        @InvocableVariable(label='D03 Required Evidence')
        public String D03_RequiredEvidence;
        @InvocableVariable(label='D04 Required Evidence')
        public String D04_RequiredEvidence;
        @InvocableVariable(label='D05 Required Evidence')
        public String D05_RequiredEvidence;
        @InvocableVariable(label='D06 Required Evidence')
        public String D06_RequiredEvidence;
        @InvocableVariable(label='ND01 Required Evidence')
        public String ND01_RequiredEvidence;
        @InvocableVariable(label='ND02 Required Evidence')
        public String ND02_RequiredEvidence;
        @InvocableVariable(label='ND03 Required Evidence')
        public String ND03_RequiredEvidence;
        @InvocableVariable(label='ND04 Required Evidence')
        public String ND04_RequiredEvidence;
        @InvocableVariable(label='ND05 Required Evidence')
        public String ND05_RequiredEvidence;
        @InvocableVariable(label='ND06 Required Evidence')
        public String ND06_RequiredEvidence;

        @InvocableVariable(label='D01 Additional Information')
        public String D01_AdditionalInformation;
        @InvocableVariable(label='D02 Additional Information')
        public String D02_AdditionalInformation;
        @InvocableVariable(label='D03 Additional Information')
        public String D03_AdditionalInformation;
        @InvocableVariable(label='D04 Additional Information')
        public String D04_AdditionalInformation;
        @InvocableVariable(label='D05 Additional Information')
        public String D05_AdditionalInformation;
        @InvocableVariable(label='D06 Additional Information')
        public String D06_AdditionalInformation;
        @InvocableVariable(label='ND01 Additional Information')
        public String ND01_AdditionalInformation;
        @InvocableVariable(label='ND02 Additional Information')
        public String ND02_AdditionalInformation;
        @InvocableVariable(label='ND03 Additional Information')
        public String ND03_AdditionalInformation;
        @InvocableVariable(label='ND04 Additional Information')
        public String ND04_AdditionalInformation;
        @InvocableVariable(label='ND05 Additional Information')
        public String ND05_AdditionalInformation;
        @InvocableVariable(label='ND06 Additional Information')
        public String ND06_AdditionalInformation;
    }

    @InvocableMethod(label='Get Exemption Type Data' description='Returns Name, RequiredEvidence and AdditionalInformation for all 12 Exemption Type codes (D01-D06, ND01-ND06)')
    public static List<ExemptionTypeData> getExemptionTypeData() {
        List<String> expectedCodes = new List<String>{
            'D01','D02','D03','D04','D05','D06',
            'ND01','ND02','ND03','ND04','ND05','ND06'
        };

        List<Exemption_Type__c> records = [
            SELECT Code__c, Name, RequiredEvidence__c, AdditionalInformation__c
            FROM Exemption_Type__c
            WHERE Code__c IN :expectedCodes
        ];

        Map<String, Exemption_Type__c> recordsByCode = new Map<String, Exemption_Type__c>();
        for (Exemption_Type__c rec : records) {
            recordsByCode.put(rec.Code__c, rec);
        }

        ExemptionTypeData result = new ExemptionTypeData();

        for (String code : expectedCodes) {
            Exemption_Type__c rec = recordsByCode.get(code);
            String name       = (rec != null) ? rec.Name                     : null;
            String evidence   = (rec != null) ? rec.RequiredEvidence__c      : null;
            String additional = (rec != null) ? rec.AdditionalInformation__c : null;

            if      (code == 'D01')  { result.D01_Name  = name; result.D01_RequiredEvidence  = evidence; result.D01_AdditionalInformation  = additional; }
            else if (code == 'D02')  { result.D02_Name  = name; result.D02_RequiredEvidence  = evidence; result.D02_AdditionalInformation  = additional; }
            else if (code == 'D03')  { result.D03_Name  = name; result.D03_RequiredEvidence  = evidence; result.D03_AdditionalInformation  = additional; }
            else if (code == 'D04')  { result.D04_Name  = name; result.D04_RequiredEvidence  = evidence; result.D04_AdditionalInformation  = additional; }
            else if (code == 'D05')  { result.D05_Name  = name; result.D05_RequiredEvidence  = evidence; result.D05_AdditionalInformation  = additional; }
            else if (code == 'D06')  { result.D06_Name  = name; result.D06_RequiredEvidence  = evidence; result.D06_AdditionalInformation  = additional; }
            else if (code == 'ND01') { result.ND01_Name = name; result.ND01_RequiredEvidence = evidence; result.ND01_AdditionalInformation = additional; }
            else if (code == 'ND02') { result.ND02_Name = name; result.ND02_RequiredEvidence = evidence; result.ND02_AdditionalInformation = additional; }
            else if (code == 'ND03') { result.ND03_Name = name; result.ND03_RequiredEvidence = evidence; result.ND03_AdditionalInformation = additional; }
            else if (code == 'ND04') { result.ND04_Name = name; result.ND04_RequiredEvidence = evidence; result.ND04_AdditionalInformation = additional; }
            else if (code == 'ND05') { result.ND05_Name = name; result.ND05_RequiredEvidence = evidence; result.ND05_AdditionalInformation = additional; }
            else if (code == 'ND06') { result.ND06_Name = name; result.ND06_RequiredEvidence = evidence; result.ND06_AdditionalInformation = additional; }
        }

        return new List<ExemptionTypeData>{ result };
    }
}