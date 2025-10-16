
@isTest
private class OrderCallout_Test {


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
                    Name = 'State B',
                    Country__c = countryList[1].Id
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
                    State__c = stateList[1].Id
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

        Account AccountB = (Account) testFactory.createSObject(
            new Account(
                Name = 'Account B',
                AccountGroup__c = AccountGroupA.Id
        ));
        insert AccountB;


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
                PaymentCondition__c = paymentConditionDefault.Id,
                DistributionCenter__c = distributionCenterA.Id,
                Pricebook2Id = pricebookId,
                AccountAddress__c = AccountAddressDefault.Id,
                Contact__c = contactDefault.Id,
                Status = 'New'
            )
        );

        insert orderDefault;

        PricebookEntry pricebookEntry = [
                SELECT Id, UnitPrice 
                FROM PricebookEntry 
                WHERE Pricebook2Id = :orderDefault.Pricebook2Id 
                AND Product2Id = :productList[0].Id 
                LIMIT 1
        ];

        OrderItem orderItemDefault = new OrderItem(
            OrderId = orderDefault.Id,
            Quantity = 2,
            Product2Id = productList[0].Id,
            PricebookEntryId = pricebookEntry.Id,
            UnitPrice = pricebookEntry.UnitPrice
        );

        insert orderItemDefault;


    }

    @isTest
    static void calloutTest(){

        Order order = [select Id from Order where Name = 'Order A' limit 1];

        List<Id> orderIds = new List<Id>{order.Id};


        Test.startTest();
        
            OrderOutbound.orderCalloult(orderIds);

        Test.stopTest();

    }
}