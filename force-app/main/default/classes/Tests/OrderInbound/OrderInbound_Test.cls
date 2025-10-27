
@isTest
private class OrderInbound_Test {
    @TestSetup
    static void makeData(){
        TestFactorySObject testFactory = TestFactorySObject.getInstance();
        
        Id pricebookId = TestFactorySObject.getStandardPricebookId();

        ProductHierarchy__c productHierarchy = (ProductHierarchy__c) testFactory.createSObject(new ProductHierarchy__c());
        insert productHierarchy;

        List<Product2> productList = new List<Product2>{
            (Product2) testFactory.createSObject(new Product2(
                Name = 'Product A',
                ExternalId__c = 'ascac',
                ProductHierarchy__c = productHierarchy.Id
                

            )),
            (Product2) testFactory.createSObject(new Product2(
                Name = 'Product B',
                ExternalId__c = 'asfda',
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
                Name = 'Distribution Center A',
                ExternalId__c = '13131dsa'
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
                ExternalId__c = 'asda1',
                AccountGroup__c = AccountGroupA.Id
        ));
        insert AccountA;

        Account AccountB = (Account) testFactory.createSObject(
            new Account(
                Name = 'Account B',
                ExternalId__c = 'wa2asfa',
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

        PaymentCondition__c paymentConditionDefault = (PaymentCondition__c) testFactory.createSObject(new PaymentCondition__c(
            ExternalId__c = '1'

        ));
        insert paymentConditionDefault;

        AccountAddress__c AccountAddressDefault = (AccountAddress__c) testFactory.createSObject(
            new AccountAddress__c(
                Account__c = AccountA.Id,
                City__c = cityList[0].Id,
                ExternalId__c = '1'

            )
        );
        insert AccountAddressDefault;

        Contact contactDefault = (Contact) testFactory.createSObject(new Contact());
        insert contactDefault;



    }


    @isTest
    static void inboundTest() {

        TestFactorySObject testFactory = TestFactorySObject.getInstance();

        Account accountDefault = [SELECT Id, ExternalId__c FROM Account WHERE Name = 'Account A' LIMIT 1];

        PaymentCondition__c paymentConditionDefault = [SELECT Id, ExternalId__c FROM PaymentCondition__c LIMIT 1];

        Product2 productA = [SELECT Id, ExternalId__c FROM Product2 WHERE Name = 'Product A' LIMIT 1];

        AccountAddress__c AccountAddressDefault = [SELECT Id, ExternalId__c FROM AccountAddress__c LIMIT 1];

        DistributionCenter__c distributionCenterA = [SELECT Id, ExternalId__c FROM DistributionCenter__c LIMIT 1];

        Wrappers.OrderItemWrapper orderItemWrapper = new Wrappers.OrderItemWrapper();
        orderItemWrapper.itemCode = 'Item A';
        orderItemWrapper.productCode = productA.ExternalId__c;
        orderItemWrapper.unitPrice = 1;
        orderItemWrapper.quantity = 1;
        orderItemWrapper.listPrice = 1;
        orderItemWrapper.orderCode = 'Order A';
        orderItemWrapper.totvsItem = true;

        Wrappers.OrderWrapper orderWrapper = new Wrappers.OrderWrapper();
        orderWrapper.orderCode = 'Order A';
        orderWrapper.orderItems = new List<Wrappers.OrderItemWrapper>();
        orderWrapper.orderItems.add(orderItemWrapper);
        orderWrapper.accountCode = accountDefault.ExternalId__c;
        orderWrapper.paymentCode = paymentConditionDefault.ExternalId__c;
        orderWrapper.distributionCenterCode = distributionCenterA.ExternalId__c;
        orderWrapper.addressCode = AccountAddressDefault.ExternalId__c;
        orderWrapper.freightType = 'Cif';
        orderWrapper.obs = 'Test';
        orderWrapper.status = 'New';
        orderWrapper.effectiveDate = Date.today();
        orderWrapper.deliveryDate = Date.today();

        System.debug('Order: ' + orderWrapper);

        List<Wrappers.OrderWrapper> ordersWrapper = new List<Wrappers.OrderWrapper>();
        ordersWrapper.add(orderWrapper);

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = '/services/apexrest/orders/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');

        String jsonBody = JSON.serialize(new Map<String, List<Wrappers.OrderWrapper>>{
            'request' => ordersWrapper
        });

        System.debug('Body: ' + jsonBody);

        request.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
            List<InResponse> responseList = OrderInbound.createOrder();
        Test.stopTest();

        System.debug('Responta: ' + responseList);

        System.Assert.areEqual(false, responseList[0].hasError , 'Deveria ter retornado uma resposta sem erros');
        

    }
}