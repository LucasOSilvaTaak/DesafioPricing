@isTest
private class ProductTrigger_Test {

    @TestSetup
    static void makeData(){
        
        TestFactorySObject testFactory = TestFactorySObject.getInstance();

        ProductHierarchy__c productHierarchy = (ProductHierarchy__c) testFactory.createSObject(new ProductHierarchy__c());
        insert productHierarchy;
   
    }

    @isTest
    static void testCreatePricebookEntryTrigger() {
        
        Id pricebookId = TestFactorySObject.getStandardPricebookId();

        ProductHierarchy__c productHierarchy = [SELECT Id FROM ProductHierarchy__c LIMIT 1];

        Product2 product1 = new Product2(
            Name = 'Product 1',
            Code__c = 'Code',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            ProductionCost__c = 100,
            ProductHierarchy__c = productHierarchy.Id
        );

        Test.startTest();

        insert product1;

        PricebookEntry pricebookEntry = [
            SELECT Id
            FROM PricebookEntry 
            WHERE Product2Id = :product1.Id
            AND Pricebook2Id = :pricebookId
            LIMIT 1
        ];

        Test.stopTest();

        Assert.isNotNull(pricebookEntry, 'PricebookEntry was not created');

    }
   
    @isTest
    static void testUpdatePricebookEntryTrigger() {
        
        Id pricebookId = TestFactorySObject.getStandardPricebookId();

        ProductHierarchy__c productHierarchy = [SELECT Id FROM ProductHierarchy__c LIMIT 1];

        Product2 product1 = new Product2(
            Name = 'Product 1',
            Code__c = 'Code',
            CurrencyIsoCode = 'BRL',
            IsActive = true,
            ProductionCost__c = 100,
            ProductHierarchy__c = productHierarchy.Id
        );

        Test.startTest();

        insert product1;

        PricebookEntry pricebookEntry = [
            SELECT Id, UnitPrice
            FROM PricebookEntry 
            WHERE Product2Id = :product1.Id
            AND Pricebook2Id = :pricebookId
            LIMIT 1
        ];
        
        product1.ProductionCost__c = 200;
        update product1;

        PricebookEntry pricebookEntryUpdated = [
            SELECT Id, UnitPrice
            FROM PricebookEntry 
            WHERE Product2Id = :product1.Id
            AND Pricebook2Id = :pricebookId
            LIMIT 1
        ];

        Test.stopTest();

        Assert.areNotEqual(pricebookEntry.UnitPrice, pricebookEntryUpdated.UnitPrice, 'PricebookEntry was not updated');

    }
}