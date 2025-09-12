@isTest
private class OrderTrigger_Test {

    @TestSetup
    static void makeData(){
        TestFactorySObject testFactory = TestFactorySObject.getInstance();
        
        Id pricebookId = TestFactorySObject.getStandardPricebookId();

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
        Insert countryList;

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

        Insert stateList;

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
        Insert cityList;

        DistributionCenter__c distributionCenterA = (DistributionCenter__c) testFactory.createSObject(
            new DistributionCenter__c(
                Name = 'Distribution Center A'
            )
        );
        Insert distributionCenterA;


        AccountGroup__c AccountGroupA = (AccountGroup__c) testFactory.createSObject(
            new AccountGroup__c()
        );
        Insert AccountGroupA;

        List<Account> accounts = new List<Account>{
            (Account) testFactory.createSObject(
                new Account(
                    Name = 'Account A',
                    AccountGroup__c = AccountGroupA.Id
                )
            ),
            
            (Account) testFactory.createSObject(
                new Account(
                    Name = 'Account B',
                    AccountGroup__c = AccountGroupA.Id
                )
            )
        };
        Insert accounts;
        
        Contact contactDefault = (Contact) testFactory.createSObject(new Contact());
        Insert contactDefault;

        AccountAddress__c AccountAddressDefault = (AccountAddress__c) testFactory.createSObject(
            new AccountAddress__c(
                Account__c = accounts[0].Id,
                City__c = cityList[0].Id
            )
        );
        Insert AccountAddressDefault;

        Contract contractDefault = (Contract) testFactory.createSObject(
            new Contract(
                AccountId = accounts[0].Id
            )
        );
        Insert contractDefault;


        PaymentCondition__c paymentConditionDefault = (PaymentCondition__c) testFactory.createSObject(new PaymentCondition__c());
        Insert paymentConditionDefault;
        
        Order orderDefault = (Order) testFactory.createSObject(
            new Order (
                Name = 'Order A',
                AccountId = accounts[0].Id,
                ContractId = contractDefault.Id,
                PaymentCondition__c = paymentConditionDefault.Id,
                DistributionCenter__c = distributionCenterA.Id,
                Pricebook2Id = pricebookId,
                AccountAddress__c = AccountAddressDefault.Id,
                Contact__c = contactDefault.Id
            )
        );
        Insert orderDefault;
    }

    @isTest
    static void testCantChangeAccount(){
        
        Order orderDefault = [SELECT Id, AccountId FROM Order where Name='Order A' LIMIT 1];
        Account accountB = [SELECT Id FROM Account WHERE Name = 'Account B' LIMIT 1];

        orderDefault.AccountId = accountB.Id;
        
        Test.startTest();
        
        Database.SaveResult result = Database.update(orderDefault, false);

        Test.stopTest();
        Order orderUpdate = [SELECT Id, AccountId FROM Order LIMIT 1];
        
        System.debug('Order: ' + orderDefault);
        System.debug('New Account: ' + accountB);
        System.debug('Order: ' + orderUpdate);


        Assert.areEqual(false, result.success, 'Cannot change order account after create');
        
    }

    @isTest
    static void testTriggerEnabled(){
        
        OrderTriggerHandler.disableTrigger();
        OrderTriggerHandler.enableTrigger();

        Assert.areEqual(true, OrderTriggerHandler.isTriggerEnabled(), 'Trigger should be enabled');

    }
    
}