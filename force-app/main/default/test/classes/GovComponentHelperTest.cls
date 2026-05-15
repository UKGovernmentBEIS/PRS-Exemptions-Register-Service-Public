@isTest(IsParallel=true)
private class GovComponentHelperTest {

    @isTest
    static void getDefaultMenuItems_blankName_returnsEmpty() {
        //Arrange, Act
        List<NavigationMenuItem> result = GovComponentHelper.getDefaultMenuItems('');

        //Assert
        System.assertEquals(0, result.size(), 'Should return empty list for blank name');
    }

    @isTest
    static void getDefaultMenuItems_nullName_returnsEmpty() {
        //Arrange, Act
        List<NavigationMenuItem> result = GovComponentHelper.getDefaultMenuItems(null);

        //Assert
        System.assertEquals(0, result.size(), 'Should return empty list for null name');
    }

    @isTest
    static void getDefaultMenuItems_validNonExistentName_returnsEmpty() {
        //Arrange, Act
        List<NavigationMenuItem> result = GovComponentHelper.getDefaultMenuItems('NonExistentMenuDevName_XYZ');

        //Assert
        System.assertNotEquals(null, result, 'Result should never be null');
        System.assertEquals(0, result.size(), 'Should return empty list for non-existent menu');
    }

    @isTest
    static void getPicklistValuesMapByObjectField_validField_returnsValues() {
        //Arrange, Act
        Map<String, String> result = GovComponentHelper.getPicklistValuesMapByObjectField('Account.Type');

        //Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return picklist values for Account.Type');
    }

    @isTest
    static void getPicklistValuesMapByObjectField_blankInput_returnsEmpty() {
        //Arrange, Act
        Map<String, String> result = GovComponentHelper.getPicklistValuesMapByObjectField('');

        //Assert
        System.assertEquals(0, result.size(), 'Should return empty map for blank input');
    }

    @isTest
    static void getPicklistValuesMapByObjectField_nullInput_returnsEmpty() {
        //Arrange, Act
        Map<String, String> result = GovComponentHelper.getPicklistValuesMapByObjectField(null);

        //Assert
        System.assertEquals(0, result.size(), 'Should return empty map for null input');
    }

    @isTest
    static void getPicklistValuesMapByObjectField_keysAreLabels() {
        //Arrange, Act
        Map<String, String> result = GovComponentHelper.getPicklistValuesMapByObjectField('Account.Type');

        //Assert
        for (String label : result.keySet()) {
            System.assertNotEquals(null, label, 'Label key should not be null');
            System.assertNotEquals(null, result.get(label), 'API value should not be null');
        }
    }

    @isTest
    static void getPicklistValuesMapByObjectField_invalidField_throwsException() {
        try {
            //Arrange, Act
            GovComponentHelper.getPicklistValuesMapByObjectField('Account.NonExistentField_XYZ');
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception e) {
            //Assert
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
    }

    @isTest
    static void getPicklistValuesByObjectField_validField_returnsValues() {
        //Arrange, Act
        List<String> result = GovComponentHelper.getPicklistValuesByObjectField('Account.Type');

        //Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return picklist values for Account.Type');
    }

    @isTest
    static void getPicklistValuesByObjectField_blankInput_returnsEmpty() {
        //Arrange, Act
        List<String> result = GovComponentHelper.getPicklistValuesByObjectField('');

        //Assert
        System.assertEquals(0, result.size(), 'Should return empty list for blank input');
    }

    @isTest
    static void getPicklistValuesByObjectField_nullInput_returnsEmpty() {
        //Arrange, Act
        List<String> result = GovComponentHelper.getPicklistValuesByObjectField(null);

        //Assert
        System.assertEquals(0, result.size(), 'Should return empty list for null input');
    }

    @isTest
    static void getPicklistValuesByObjectField_returnsLabels() {
        //Arrange, Act
        List<String> result = GovComponentHelper.getPicklistValuesByObjectField('Account.Type');

        //Assert
        for (String label : result) {
            System.assertNotEquals(null, label, 'Each returned label should not be null');
            System.assertNotEquals('', label, 'Each returned label should not be empty');
        }
    }

    @isTest
    static void getPicklistValuesByObjectField_invalidField_throwsException() {
        try {
            //Arrange, Act
            GovComponentHelper.getPicklistValuesByObjectField('Account.NonExistentField_XYZ');
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception e) {
            //Assert
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
        }
    }

    @isTest
    static void getPicklistValuesByObjectField_countMatchesMap() {
        //Arrange, Act
        List<String> listResult = GovComponentHelper.getPicklistValuesByObjectField('Account.Type');
        Map<String, String> mapResult = GovComponentHelper.getPicklistValuesMapByObjectField('Account.Type');

        //Assert
        System.assertEquals(listResult.size(), mapResult.size(), 'List and map should have same count for same field');
    }
}
