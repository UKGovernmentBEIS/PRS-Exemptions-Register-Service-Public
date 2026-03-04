@isTest(IsParallel=true)
public with sharing class DeliveryPointAddressTest {

    @isTest
    static void instantiation_WithAllFieldsPopulated_returnsFieldsWithProperCapitalisation() {
        //Arrange, Act
        DeliveryPointAddress address = new DeliveryPointAddress();
        address.UPRN = 1234;
        address.UDPRN = 5678;
        address.ADDRESS = 'DEPARTMENT OF CODE, CODE, ROOM 1, 33, ENGINEERING, ROAD XYZ, LONDON, AA3 1AB';
        address.PO_BOX_NUMBER = '1';
        address.ORGANISATION_NAME = 'DEPARTMENT OF CODE';
        address.DEPARTMENT_NAME = 'CODE';
        address.SUB_BUILDING_NAME = 'ROOM 1';
        address.BUILDING_NAME = 'ENGINEERING';
        address.BUILDING_NUMBER = 33;
        address.DEPENDENT_THOROUGHFARE_NAME = 'ROAD UVW';
        address.THOROUGHFARE_NAME = 'ROAD XYZ';
        address.DOUBLE_DEPENDENT_LOCALITY = '1';
        address.DEPENDENT_LOCALITY = '1';
        address.POSTCODE = 'AA3 1AB';
        address.RPC = '2';
        address.X_COORDINATE = 123123123;
        address.Y_COORDINATE = 123123123;
        address.LNG = 3;
        address.LAT = 4;
        address.STATUS = 'APPROVED';
        address.LOGICAL_STATUS_CODE = 1;
        address.CLASSIFICATION_CODE = '2';
        address.CLASSIFICATION_CODE_DESCRIPTION = 'This is a clasification code';
        address.LOCAL_CUSTODIAN_CODE = 4400;
        address.LOCAL_CUSTODIAN_CODE_DESCRIPTION = 'CITY OF LONDON';
        address.COUNTRY_CODE = 'E';
        address.COUNTRY_CODE_DESCRIPTION = 'This record is within England';
        address.POSTAL_ADDRESS_CODE = 'D';
        address.POSTAL_ADDRESS_CODE_DESCRIPTION = 'A record which is linked to PAF';
        address.BLPU_STATE_CODE = 2;
        address.BLPU_STATE_CODE_DESCRIPTION = 'In use';
        address.TOPOGRAPHY_LAYER_TOID = 'asdasd5521';
        address.WARD_CODE = 'E023123';
        address.PARISH_CODE = '4444';
        address.PARENT_UPRN = 1111;
        address.LAST_UPDATE_DATE = '04/08/2025';
        address.ENTRY_DATE = '04/08/2025';
        address.LEGAL_NAME = 'DEPARTMENT OF CODE';
        address.BLPU_STATE_DATE = '04/08/2025';
        address.LANGUAGE = 'EN';
        address.MATCH = 1.0;
        address.MATCH_DESCRIPTION = 'EXACT';
        address.DELIVERY_POINT_SUFFIX = '1A';

        //Assert
        Assert.areEqual(1234, address.UPRN, 'Incorrect UPRN');
        Assert.areEqual(5678, address.UDPRN, 'Incorrect UDPRN');
        Assert.areEqual('Department Of Code, Code, Room 1, 33, Engineering, Road Xyz, London, AA3 1AB', address.ADDRESS, 'Incorrect ADDRESS');
        Assert.areEqual('1', address.PO_BOX_NUMBER, 'Incorrect PO_BOX_NUMBER');
        Assert.areEqual('Department Of Code', address.ORGANISATION_NAME, 'Incorrect ORGANISATION_NAME');
        Assert.areEqual('CODE', address.DEPARTMENT_NAME, 'Incorrect DEPARTMENT_NAME');
        Assert.areEqual('Room 1', address.SUB_BUILDING_NAME, 'Incorrect SUB_BUILDING_NAME');
        Assert.areEqual('Engineering', address.BUILDING_NAME, 'Incorrect BUILDING_NAME');
        Assert.areEqual(33, address.BUILDING_NUMBER, 'Incorrect BUILDING_NUMBER');
        Assert.areEqual('ROAD UVW', address.DEPENDENT_THOROUGHFARE_NAME, 'Incorrect DEPENDENT_THOROUGHFARE_NAME');
        Assert.areEqual('Road Xyz', address.THOROUGHFARE_NAME, 'Incorrect THOROUGHFARE_NAME');
        Assert.areEqual('1', address.DOUBLE_DEPENDENT_LOCALITY, 'Incorrect DOUBLE_DEPENDENT_LOCALITY');
        Assert.areEqual('1', address.DEPENDENT_LOCALITY, 'Incorrect DEPENDENT_LOCALITY');
        Assert.areEqual('AA3 1AB', address.POSTCODE, 'Incorrect POSTCODE');
        Assert.areEqual('2', address.RPC, 'Incorrect RPC');
        Assert.areEqual(123123123, address.X_COORDINATE, 'Incorrect X_COORDINATE');
        Assert.areEqual(123123123, address.Y_COORDINATE, 'Incorrect Y_COORDINATE');
        Assert.areEqual(3, address.LNG, 'Incorrect LNG');
        Assert.areEqual(4, address.LAT, 'Incorrect LAT');
        Assert.areEqual('APPROVED', address.STATUS, 'Incorrect STATUS');
        Assert.areEqual(1, address.LOGICAL_STATUS_CODE, 'Incorrect LOGICAL_STATUS_CODE');
        Assert.areEqual('2', address.CLASSIFICATION_CODE, 'Incorrect CLASSIFICATION_CODE');
        Assert.areEqual('This is a clasification code', address.CLASSIFICATION_CODE_DESCRIPTION, 'Incorrect CLASSIFICATION_CODE_DESCRIPTION');
        Assert.areEqual(4400, address.LOCAL_CUSTODIAN_CODE, 'Incorrect LOCAL_CUSTODIAN_CODE');
        Assert.areEqual('CITY OF LONDON', address.LOCAL_CUSTODIAN_CODE_DESCRIPTION, 'Incorrect LOCAL_CUSTODIAN_CODE_DESCRIPTION');
        Assert.areEqual('E', address.COUNTRY_CODE, 'Incorrect COUNTRY_CODE');
        Assert.areEqual('This record is within England', address.COUNTRY_CODE_DESCRIPTION, 'Incorrect COUNTRY_CODE_DESCRIPTION');
        Assert.areEqual('D', address.POSTAL_ADDRESS_CODE, 'Incorrect POSTAL_ADDRESS_CODE');
        Assert.areEqual('A record which is linked to PAF', address.POSTAL_ADDRESS_CODE_DESCRIPTION, 'Incorrect POSTAL_ADDRESS_CODE_DESCRIPTION');
        Assert.areEqual(2, address.BLPU_STATE_CODE, 'Incorrect BLPU_STATE_CODE');
        Assert.areEqual('In use', address.BLPU_STATE_CODE_DESCRIPTION, 'Incorrect BLPU_STATE_CODE_DESCRIPTION');
        Assert.areEqual('asdasd5521', address.TOPOGRAPHY_LAYER_TOID, 'Incorrect TOPOGRAPHY_LAYER_TOID');
        Assert.areEqual('E023123', address.WARD_CODE, 'Incorrect WARD_CODE');
        Assert.areEqual('4444', address.PARISH_CODE, 'Incorrect PARISH_CODE');
        Assert.areEqual(1111, address.PARENT_UPRN, 'Incorrect PARENT_UPRN');
        Assert.areEqual('04/08/2025', address.LAST_UPDATE_DATE, 'Incorrect LAST_UPDATE_DATE');
        Assert.areEqual('04/08/2025', address.ENTRY_DATE, 'Incorrect ENTRY_DATE');
        Assert.areEqual('DEPARTMENT OF CODE', address.LEGAL_NAME, 'Incorrect LEGAL_NAME');
        Assert.areEqual('04/08/2025', address.BLPU_STATE_DATE, 'Incorrect BLPU_STATE_DATE');
        Assert.areEqual('EN', address.LANGUAGE, 'Incorrect LANGUAGE');
        Assert.areEqual(1.0, address.MATCH, 'Incorrect MATCH');
        Assert.areEqual('EXACT', address.MATCH_DESCRIPTION, 'Incorrect MATCH_DESCRIPTION');
        Assert.areEqual('1A', address.DELIVERY_POINT_SUFFIX, 'Incorrect DELIVERY_POINT_SUFFIX');
    }

    @isTest
    static void instantiation_withAllFieldsNull_returnsNullFields() {
        //Arrange, Act
        DeliveryPointAddress address = new DeliveryPointAddress();

        //Assert
        Assert.areEqual(null, address.UPRN, 'Incorrect UPRN');
        Assert.areEqual(null, address.UDPRN, 'Incorrect UDPRN');
        Assert.areEqual(null, address.ADDRESS, 'Incorrect ADDRESS');
        Assert.areEqual(null, address.PO_BOX_NUMBER, 'Incorrect PO_BOX_NUMBER');
        Assert.areEqual(null, address.ORGANISATION_NAME, 'Incorrect ORGANISATION_NAME');
        Assert.areEqual(null, address.DEPARTMENT_NAME, 'Incorrect DEPARTMENT_NAME');
        Assert.areEqual(null, address.SUB_BUILDING_NAME, 'Incorrect SUB_BUILDING_NAME');
        Assert.areEqual(null, address.BUILDING_NAME, 'Incorrect BUILDING_NAME');
        Assert.areEqual(null, address.BUILDING_NUMBER, 'Incorrect BUILDING_NUMBER');
        Assert.areEqual(null, address.DEPENDENT_THOROUGHFARE_NAME, 'Incorrect DEPENDENT_THOROUGHFARE_NAME');
        Assert.areEqual(null, address.THOROUGHFARE_NAME, 'Incorrect THOROUGHFARE_NAME');
        Assert.areEqual(null, address.DOUBLE_DEPENDENT_LOCALITY, 'Incorrect DOUBLE_DEPENDENT_LOCALITY');
        Assert.areEqual(null, address.DEPENDENT_LOCALITY, 'Incorrect DEPENDENT_LOCALITY');
        Assert.areEqual(null, address.POSTCODE, 'Incorrect POSTCODE');
        Assert.areEqual(null, address.RPC, 'Incorrect RPC');
        Assert.areEqual(null, address.X_COORDINATE, 'Incorrect X_COORDINATE');
        Assert.areEqual(null, address.Y_COORDINATE, 'Incorrect Y_COORDINATE');
        Assert.areEqual(null, address.LNG, 'Incorrect LNG');
        Assert.areEqual(null, address.LAT, 'Incorrect LAT');
        Assert.areEqual(null, address.STATUS, 'Incorrect STATUS');
        Assert.areEqual(null, address.LOGICAL_STATUS_CODE, 'Incorrect LOGICAL_STATUS_CODE');
        Assert.areEqual(null, address.CLASSIFICATION_CODE, 'Incorrect CLASSIFICATION_CODE');
        Assert.areEqual(null, address.CLASSIFICATION_CODE_DESCRIPTION, 'Incorrect CLASSIFICATION_CODE_DESCRIPTION');
        Assert.areEqual(null, address.LOCAL_CUSTODIAN_CODE, 'Incorrect LOCAL_CUSTODIAN_CODE');
        Assert.areEqual(null, address.LOCAL_CUSTODIAN_CODE_DESCRIPTION, 'Incorrect LOCAL_CUSTODIAN_CODE_DESCRIPTION');
        Assert.areEqual(null, address.COUNTRY_CODE, 'Incorrect COUNTRY_CODE');
        Assert.areEqual(null, address.COUNTRY_CODE_DESCRIPTION, 'Incorrect COUNTRY_CODE_DESCRIPTION');
        Assert.areEqual(null, address.POSTAL_ADDRESS_CODE, 'Incorrect POSTAL_ADDRESS_CODE');
        Assert.areEqual(null, address.POSTAL_ADDRESS_CODE_DESCRIPTION, 'Incorrect POSTAL_ADDRESS_CODE_DESCRIPTION');
        Assert.areEqual(null, address.BLPU_STATE_CODE, 'Incorrect BLPU_STATE_CODE');
        Assert.areEqual(null, address.BLPU_STATE_CODE_DESCRIPTION, 'Incorrect BLPU_STATE_CODE_DESCRIPTION');
        Assert.areEqual(null, address.TOPOGRAPHY_LAYER_TOID, 'Incorrect TOPOGRAPHY_LAYER_TOID');
        Assert.areEqual(null, address.WARD_CODE, 'Incorrect WARD_CODE');
        Assert.areEqual(null, address.PARISH_CODE, 'Incorrect PARISH_CODE');
        Assert.areEqual(null, address.PARENT_UPRN, 'Incorrect PARENT_UPRN');
        Assert.areEqual(null, address.LAST_UPDATE_DATE, 'Incorrect LAST_UPDATE_DATE');
        Assert.areEqual(null, address.ENTRY_DATE, 'Incorrect ENTRY_DATE');
        Assert.areEqual(null, address.LEGAL_NAME, 'Incorrect LEGAL_NAME');
        Assert.areEqual(null, address.BLPU_STATE_DATE, 'Incorrect BLPU_STATE_DATE');
        Assert.areEqual(null, address.LANGUAGE, 'Incorrect LANGUAGE');
        Assert.areEqual(null, address.MATCH, 'Incorrect MATCH');
        Assert.areEqual(null, address.MATCH_DESCRIPTION, 'Incorrect MATCH_DESCRIPTION');
        Assert.areEqual(null, address.DELIVERY_POINT_SUFFIX, 'Incorrect DELIVERY_POINT_SUFFIX');
    }
}