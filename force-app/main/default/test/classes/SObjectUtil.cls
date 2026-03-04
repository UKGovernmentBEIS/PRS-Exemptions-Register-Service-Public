@isTest
public class SObjectUtil {
    public static SObject makeSObject(SObjectType sObjType, Map<String, Object> fieldValues) {
        Map<String, Object> jsonMap = new Map<String, Object>();
        Map<String, Object> attributes = new Map<String, Object>();
        attributes.put('type', sObjType.getDescribe().getName());
        jsonMap.put('attributes', attributes);
        
        for (String field : fieldValues.keySet()) {
            jsonMap.put(field, fieldValues.get(field));
        }
        
        String jsonString = JSON.serialize(jsonMap);
        
        List<SObject> results = (List<SObject>) JSON.deserialize(
            '[' + jsonString + ']', 
            List<SObject>.class
        );
        
        return results[0];
    }

    public static SObject updateSObject(SObject objectInstance, Map<String, Object> fieldValues) {
        String jsonString = JSON.serialize(objectInstance);
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        
        for (String field : fieldValues.keySet()) {
            Object value = fieldValues.get(field);
            if (field.endsWith('__r') && value != null) {
                String valueJson = JSON.serialize(value);
                List<Object> records = (List<Object>) JSON.deserializeUntyped(valueJson);
                
                Map<String, Object> queryResult = new Map<String, Object>{
                    'totalSize' => records.size(),
                    'done' => true,
                    'records' => records
                };
                
                jsonMap.put(field, queryResult);
            } else {
                String valueJson = JSON.serialize(value);
                Object deserializedValue = JSON.deserializeUntyped(valueJson);
                jsonMap.put(field, deserializedValue);
            }
        }
        
        String updatedJson = JSON.serialize(jsonMap);
        List<SObject> results = (List<SObject>) JSON.deserialize(
            '[' + updatedJson + ']', 
            List<SObject>.class
        );
        
        return results[0];
    }


    public static String generateIdForType(String typeName) {
        List<DescribeSObjectResult> describes = Schema.describeSObjects(new List<String> { typeName }, SObjectDescribeOptions.DEFERRED);
        String idPrefix = describes[0].getKeyPrefix();

        Integer randomInt = Math.abs(Crypto.getRandomInteger());
        String paddedPart = String.valueOf(randomInt).leftPad(12, '0');

        return idPrefix + paddedPart;
    }

}
