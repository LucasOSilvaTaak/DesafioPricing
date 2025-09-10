
@isTest
private class TaxTrigger_Test {

    @TestSetup
    static void makeData(){
        
        Id pricebookId = TestFactorySObject.getStandardPricebookId();
        
        TestFactorySObject testFactory = TestFactorySObject.getInstance();
        
        ProductHierarchy__c productHierarchy = (ProductHierarchy__c) testFactory.createSObject(new ProductHierarchy__c());
        insert productHierarchy;

        Product2 productA = (Product2)testFactory.createSObject(new Product2(
            Name = 'Product A',
            ProductHierarchy__c = productHierarchy.Id
        ));
        insert productA;

        Product2 productB = (Product2) testFactory.createSObject(new Product2(
            Name = 'Product B',
            ProductHierarchy__c = productHierarchy.Id

        ));
        insert productB;
        
        Country__c countryA = (Country__c) testFactory.createSObject(
            new Country__c(
                Name = 'Country A'
            )
        );
        insert countryA;

        State__c stateA = (State__c) testFactory.createSObject(
            new State__c(
                Name = 'State A',
                Country__c = countryA.Id
            )
        );
        insert stateA;
        
        Country__c countryB = (Country__c) testFactory.createSObject(
            new Country__c(
                Name = 'Country B'
            )
        );
        insert countryB;

        State__c stateB = (State__c) testFactory.createSObject(
            new State__c(
                Name = 'State B',
                Country__c = countryB.Id
            )
        );
        insert stateB;
        
        DistributionCenter__c distributionCenterA = (DistributionCenter__c) testFactory.createSObject(
            new DistributionCenter__c(
                Name = 'Distribution Center A'
            )
        );
        insert distributionCenterA;

        Tax__c taxDefault = new Tax__c(
            Name = 'Tax Default',
            Product__c = productA.Id,
            State__c = stateA.id,
            TaxOnCost__c = 1,
            distributionCenter__c = distributionCenterA.Id
        );
        insert taxDefault;

    }

    @isTest
    static void testVerifyDuplicityFail() {

        Product2 productA = [SELECT Id FROM Product2 WHERE Name = 'Product A' LIMIT 1];
        State__c stateA = [SELECT Id FROM State__c WHERE Name = 'State A' LIMIT 1];
        DistributionCenter__c distributionCenterA = [SELECT Id FROM distributionCenter__c WHERE Name = 'Distribution Center A' LIMIT 1];

        Tax__c taxTest = new Tax__c(
            Name = 'Tax test',
            Product__c = productA.Id,
            State__c = stateA.Id,
            TaxOnCost__c = 1,
            distributionCenter__c = distributionCenterA.Id
        );

        Test.startTest();
            Database.SaveResult result = Database.insert(taxTest, false);
        Test.stopTest();

        Assert.areEqual(result.success, false, 'Test failed: Tax record was not inserted: '+ result.errors + '.');
    }

    @isTest
    static void testVerifyUpdateDuplicityPass() {

        Product2 productA = [SELECT Id FROM Product2 WHERE Name = 'Product A' LIMIT 1];
        Product2 productB = [SELECT Id FROM Product2 WHERE Name = 'Product B' LIMIT 1];
        State__c stateA = [SELECT Id FROM State__c WHERE Name = 'State A' LIMIT 1];
        State__c stateB = [SELECT Id FROM State__c WHERE Name = 'State B' LIMIT 1];
        DistributionCenter__c distributionCenterA = [SELECT Id FROM distributionCenter__c WHERE Name = 'Distribution Center A' LIMIT 1];

        Tax__c taxTest = new Tax__c(
            Name = 'Tax test',
            Product__c = productA.Id,
            State__c = stateB.Id,
            TaxOnCost__c = 1,
            distributionCenter__c = distributionCenterA.Id
        );
        insert taxTest;

        taxTest.Product__c = productB.Id;

        Test.startTest();
            Database.SaveResult result = Database.update(taxTest, false);
        Test.stopTest();

        Assert.areEqual(result.success, true, 'Test failed: Tax record was not inserted: '+ result.errors + '.');
    }
    @isTest
    static void testVerifyUpdateDuplicityFailed() {

        Product2 productA = [SELECT Id FROM Product2 WHERE Name = 'Product A' LIMIT 1];
        Product2 productB = [SELECT Id FROM Product2 WHERE Name = 'Product B' LIMIT 1];
        State__c stateA = [SELECT Id FROM State__c WHERE Name = 'State A' LIMIT 1];
        State__c stateB = [SELECT Id FROM State__c WHERE Name = 'State B' LIMIT 1];
        DistributionCenter__c distributionCenterA = [SELECT Id FROM distributionCenter__c WHERE Name = 'Distribution Center A' LIMIT 1];

        Tax__c taxTest = new Tax__c(
            Name = 'Tax test',
            Product__c = productA.Id,
            State__c = stateB.Id,
            TaxOnCost__c = 1,
            distributionCenter__c = distributionCenterA.Id
        );
        insert taxTest;

        taxTest.State__c = stateA.Id;

        Test.startTest();
            Database.SaveResult result = Database.update(taxTest, false);
        Test.stopTest();

        Assert.areEqual(result.success, false, 'Test failed: Tax record was not inserted: ' + result.errors + '.');
    }
}