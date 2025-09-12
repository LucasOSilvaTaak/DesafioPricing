@isTest
private class OrderItemTrigger_Test {

    @TestSetup
    static void makeData(){
        
        TestFactorySObject testFactory = TestFactorySObject.getInstance();
        
        Id pricebookId = TestFactorySObject.getStandardPricebookId();
        

        ProductHierarchy__c productHierarchy = (ProductHierarchy__c) testFactory.createSObject(new ProductHierarchy__c());
        insert productHierarchy;

        List<Product2> productList = new List<Product2>{
            (Product2) testFactory.createSObject(new Product2(
                Name = 'Product A',
                ProductHierarchy__c = productHierarchy.Id

            )),
            (Product2) testFactory.createSObject(new Product2(
                Name = 'Product B',
                ProductHierarchy__c = productHierarchy.Id

            ))
        };
        insert productList;
        
        List<Country__c> countryList = new List<Country__c>{
            (Country__c) testFactory.createSObject(
                new Country__c(
                    Name = 'Country A'
                )
            ),
            (Country__c) testFactory.createSObject(
                new Country__c(
                    Name = 'Country B'
                )
            )

        };

        insert countryList;

        List<State__c> stateList = new List<State__c>{
            (State__c) testFactory.createSObject(
                new State__c(
                    Name = 'State A',
                    Country__c = countryList[0].Id
                )
            ),
            (State__c) testFactory.createSObject(
                new State__c(
                    Name = 'State A',
                    Country__c = countryList[0].Id
                )
            )
        };

        insert stateList;

        List<City__c> cityList = new List<City__c>{
            (City__c) testFactory.createSObject(
                new City__c(
                    Name = 'City A',
                    State__c = stateList[0].Id
                )
            ),
            (City__c) testFactory.createSObject(
                new City__c(
                    Name = 'City B',
                    State__c = stateList[0].Id
                )
            )

        };

        insert cityList;
        
        DistributionCenter__c distributionCenterA = (DistributionCenter__c) testFactory.createSObject(
            new DistributionCenter__c(
                Name = 'Distribution Center A'
            )
        );
        insert distributionCenterA;


        AccountGroup__c AccountGroupA = (AccountGroup__c) testFactory.createSObject(
            new AccountGroup__c()
        );
        insert AccountGroupA;

        Account AccountA = (Account) testFactory.createSObject(
            new Account(
                Name = 'Account A',
                AccountGroup__c = AccountGroupA.Id
        ));
        insert AccountA;


        Margin__c MarginDefault = new Margin__c(
            Name = 'Margin Default',
            Product__c = productList[0].Id,
            State__c = stateList[0].id,
            Value__c = 1,
            distributionCenter__c = distributionCenterA.Id,
            Account__c = AccountA.Id
            
        );
        insert MarginDefault;


        Tax__c taxDefault = new Tax__c(
            Name = 'Tax Default',
            Product__c = productList[0].Id,
            State__c = stateList[0].id,
            TaxOnCost__c = 1,
            distributionCenter__c = distributionCenterA.Id
        );
        insert taxDefault;

        Freight__c FreightTest = new Freight__c(
            Name = 'Freight Test',
            Product__c = productList[0].Id,
            State__c = stateList[0].Id,
            Value__c = 1,
            distributionCenter__c = distributionCenterA.Id
            
        );
        insert FreightTest;

        Contract contractDefault = (Contract) testFactory.createSObject(
            new Contract(
                AccountId = AccountA.Id
            )
        );
        insert contractDefault;

        PaymentCondition__c paymentConditionDefault = (PaymentCondition__c) testFactory.createSObject(new PaymentCondition__c());
        insert paymentConditionDefault;

        AccountAddress__c AccountAddressDefault = (AccountAddress__c) testFactory.createSObject(
            new AccountAddress__c(
                Account__c = AccountA.Id,
                City__c = cityList[0].Id
            )
        );
        insert AccountAddressDefault;

        Contact contactDefault = (Contact) testFactory.createSObject(new Contact());
        insert contactDefault;

        Order orderDefault = (Order) testFactory.createSObject(
            new Order (
                Name = 'Order A',
                AccountId = AccountA.Id,
                ContractId = contractDefault.Id,
                PaymentCondition__c = paymentConditionDefault.Id,
                DistributionCenter__c = distributionCenterA.Id,
                Pricebook2Id = pricebookId,
                AccountAddress__c = AccountAddressDefault.Id,
                Contact__c = contactDefault.Id
            )
        );
        insert orderDefault;


    }

    @isTest
    static void testCreatingOrderItem() {
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Product A' LIMIT 1];
        Order order = [SELECT Id, Pricebook2Id FROM Order WHERE Name = 'Order A' LIMIT 1];

        // Recuperar o PricebookEntry correspondente
        PricebookEntry pricebookEntry = [SELECT Id, UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :order.Pricebook2Id 
                            AND Product2Id = :product.Id 
                            LIMIT 1];

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 2,
            UnitPrice = pricebookEntry.UnitPrice
        );

        Test.startTest();

        Database.SaveResult result = Database.insert(orderItem, false);

        Test.stopTest();

        Assert.areEqual(true, result.success, 'Product have all parameters so it should have been created');
    }
    
    @isTest
    static void testCreatingOrderItemFailed() {
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Product B' LIMIT 1];
        Order order = [SELECT Id, Pricebook2Id FROM Order WHERE Name = 'Order A' LIMIT 1];

        // Recuperar o PricebookEntry correspondente
        PricebookEntry pricebookEntry = [SELECT Id, UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :order.Pricebook2Id 
                            AND Product2Id = :product.Id 
                            LIMIT 1];

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 2,
            UnitPrice = pricebookEntry.UnitPrice
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(orderItem, false);
        Test.stopTest();

        Assert.areEqual(false, result.success, 'Product dont have a margin, tax and Freight, so should not be created');
    }


    @isTest
    static void testUpdateOrderItem() {
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Product A' LIMIT 1];
        Order order = [SELECT Id, Pricebook2Id FROM Order WHERE Name = 'Order A' LIMIT 1];

        // Recuperar o PricebookEntry correspondente
        PricebookEntry pricebookEntry = [SELECT Id, UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :order.Pricebook2Id 
                            AND Product2Id = :product.Id 
                            LIMIT 1];

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 2,
            UnitPrice = pricebookEntry.UnitPrice
        );
        Insert orderItem;

        Freight__c changedFreight = [SELECT Id, Value__c FROM Freight__c LIMIT 1];
        changedFreight.Value__c = 5;
        Update changedFreight;

        

        OrderItem oldOrderItem = [SELECT Final__c FROM OrderItem WHERE Id = :orderItem.Id LIMIT 1];
        orderItem.Quantity = 5;

        Test.startTest();
        
        Update orderItem;
        
        Test.stopTest();

        OrderItem newOrderItem = [SELECT Final__c FROM OrderItem WHERE Id = :orderItem.Id LIMIT 1];

        Assert.areNotEqual(oldOrderItem.Final__c, newOrderItem.Final__c, 'The old Price( ' + oldOrderItem.Final__c + ') should be different from the new Price( ' + newOrderItem.Final__c + ')');
    }

    

}