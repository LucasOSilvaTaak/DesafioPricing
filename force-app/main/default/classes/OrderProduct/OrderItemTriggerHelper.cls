public with sharing class OrderItemTriggerHelper {
    public static void handleBeforeInsert(List<OrderItem> newList){
        fillOrderItem(newList);
    }

    public static void handleBeforeUpdate(List<OrderItem> oldList , List<OrderItem> records){
        
        List<OrderItem> changedList = new List<OrderItem>();
        
        for(Integer i =0; i < records.size(); i++){
        
            if(!records[i].equals(oldList[i])) changedList.add(records[i]);
        }

        if(!changedList.isEmpty()) fillOrderItem(changedList);

    }

    private static set<Id> productIds;
    private static Map<Id,Id> productToHierarchy;
    private static Set<Id> orderIds;
    private static Map<Id,Id> orderToAddress;
    private static Map<Id,Id> cityToState;
    private static Map<Id,Id> addressToCity;
    private static Map<Id,Id> stateToCountry;
    private static Map<Id,Id> addressToAccount;
    private static Map<Id,Id> AccountToAccountGroup;
    private static Map<Id, Order> orderMap;

    
    
    private static void fillOrderItem(List<OrderItem> records){
        
        //preenche os masps e sets para a busca
        fillOrderItensLockups(records);
        
        //impede qualque modificação após pedido sair de draft
        draftOnly(records);
        
        //Busca final de todas as freights citadas
        List<Freight__c> freightList = [
            SELECT Value__c, Product__c, ProductHierarchy__c, City__c, State__c, Country__c, Status__c
            FROM Freight__c
            WHERE (Product__c IN :productIds 
                OR ProductHierarchy__c IN :productToHierarchy.values())
            AND (City__c IN :addressToCity.values() 
                OR State__c IN :cityToState.values() 
                OR Country__c IN :stateToCountry.values())
            AND Status__c = 'Approved'
            
            ];
        
        List<Tax__c> taxList = [
            SELECT TaxOnCost__c, State__c, Product__c, Status__c
            FROM Tax__c
            WHERE Status__c = 'Approved'
            AND State__c IN :cityToState.values()
            AND Product__c IN :productIdS
        ];
            
        List<Margin__c> marginList = [
            SELECT Product__c, ProductHierarchy__c, Account__c, 
            AccountGroup__c, City__c, State__c, Country__c, Status__c, Value__c
            FROM Margin__c
            WHERE Status__c = 'Approved'
            AND (Product__c IN :productIds 
                OR ProductHierarchy__c IN :productToHierarchy.values())
            AND (Account__c IN :addressToAccount.values() 
                OR AccountGroup__c IN :AccountToAccountGroup.values())
            AND (City__c IN :addressToCity.values() 
                OR State__c IN :cityToState.values() or Country__c IN :stateToCountry.values())
        ];
            
            ajustFreight(records, freightList);

            ajustTax(records, taxList);

            ajustMargin(records, marginList);
            
            //Calcular os valores de cada orderm produto
            calculateValues(records);
                    
                    
    }
                
                
    private static void fillOrderItensLockups(List<OrderItem> records){
        orderIds   = new Set<Id>();
        productIds = new Set<Id>();

        for (OrderItem iOrderItem : records) {
            if (iOrderItem.OrderId != null) orderIds.add(iOrderItem.OrderId);
            if (iOrderItem.Product2Id != null) productIds.add(iOrderItem.Product2Id);
        }

        //Cria um map com todos os lookups de ordem
        orderMap = new Map<Id, Order>(
            [
                SELECT Id,
                    AccountAddress__c,
                    AccountAddress__r.City__c,
                    AccountAddress__r.City__r.State__c,
                    AccountAddress__r.City__r.State__r.Country__c,
                    AccountAddress__r.Account__c,
                    AccountAddress__r.Account__r.AccountGroup__c,
                    Status
                FROM Order
                WHERE Id IN :orderIds
            ]
        );


        orderToAddress = new Map<Id, Id>();
        addressToCity = new Map<Id, Id>();
        cityToState = new Map<Id, Id>();
        stateToCountry = new Map<Id, Id>();
        addressToAccount = new Map<Id, Id>();
        accountToAccountGroup = new Map<Id, Id>(); 

        for (Order iOrder : orderMap.values()) {
            Id addressId = iOrder.AccountAddress__c;
            Id cityId    = iOrder.AccountAddress__r?.City__c;
            Id stateId   = iOrder.AccountAddress__r?.City__r?.State__c;
            Id countryId = iOrder.AccountAddress__r?.City__r?.State__r?.Country__c;
            Id accountId = iOrder.AccountAddress__r?.Account__c;
            Id groupId   = iOrder.AccountAddress__r?.Account__r?.AccountGroup__c;

            orderToAddress.put(iOrder.Id, addressId);
            if (addressId != null && cityId != null)    addressToCity.put(addressId, cityId);
            if (cityId   != null && stateId != null)    cityToState.put(cityId, stateId);
            if (stateId  != null && countryId != null)  stateToCountry.put(stateId, countryId);
            if (addressId!= null && accountId != null)  addressToAccount.put(addressId, accountId);
            if (accountId!= null && groupId   != null)  accountToAccountGroup.put(accountId, groupId);
        }


        productToHierarchy = new Map<Id, Id>();
        for (Product2 p :   [SELECT Id, ProductHierarchy__c FROM Product2 where Id in :productIds]) {
            productToHierarchy.put(p.Id, p.ProductHierarchy__c);
        }
    }
                
    //Impede que quANDo o status do pedido for diferente de draft ele impede o update
    private static void draftOnly(List<OrderItem> records){

        for(OrderItem iOrderProduct : records){
            if(orderMap.get(iOrderProduct.OrderId).Status != 'Draft') iOrderProduct.addError('You can only change the value of the order product when the order is in draft status');
        }
    }
        
    
    private static void ajustFreight(List<OrderItem> records, List<Freight__c> freightList){
        
        
        
        for(OrderItem iOrderProduct : records){

            //PegANDo os ids para filtar
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = productToHierarchy.get(productId);
            Id cityId = addressToCity.get(orderToAddress.get(iOrderProduct.OrderId));
            Id stateId = cityToState.get(cityId);
            Id countryId = stateToCountry.get(stateId);
            
            Freight__c toFind = new Freight__c(
                Product__c = productId,
                ProductHierarchy__c = productHierarchyId,
                City__c = cityId,
                State__c = stateId,
                Country__c = countryId
            );


            iOrderProduct.CostFreight__c = null;
            
            Freight__c bestFreight = (Freight__c) findBestSpecificity(freightList, toFind);
            if(bestFreight != null) iOrderProduct.CostFreight__c = bestFreight.value__c;
            
        }
        
    }
    
    private static void ajustTax(List<OrderItem> records, List<Tax__c> taxList){
        
        for(OrderItem iOrderProduct : records){
            iOrderProduct.TaxPercentage__c = null;
            Integer bestScore = -1;

    
            //PegANDo os ids para filtar
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = productToHierarchy.get(productId);
            Id cityId = addressToCity.get(orderToAddress.get(iOrderProduct.OrderId));
            Id stateId = cityToState.get(cityId);

            //Não adicionar o findBestSpecificity por que é demais para algo tão simples
            
            for (Tax__c iTax : taxList){
                if(iTax.Product__c == productId && iTax.State__c == stateId){
                    iOrderProduct.TaxPercentage__c = iTax.TaxOnCost__c;
                    break;
                }

            }

        }
    }

    private static void ajustMargin(List<OrderItem> records, List<Margin__c> marginList){
        for(OrderItem iOrderProduct : records){
            iOrderProduct.MarginPercentage__c = null;

    
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = productToHierarchy.get(productId);
            Id cityId = addressToCity.get(orderToAddress.get(iOrderProduct.OrderId));
            Id stateId = cityToState.get(cityId);
            Id countryId = stateToCountry.get(stateId);
            Id AccountId = addressToAccount.get(orderToAddress.get(iOrderProduct.OrderId));
            Id AccountGroupId = AccountToAccountGroup.get(AccountId);

            Margin__c toFind = new Margin__c(
                Product__c = productId,
                ProductHierarchy__c = productHierarchyId,
                City__c = cityId,
                State__c = stateId,
                Country__c = countryId,
                Account__c = AccountId,
                AccountGroup__c = AccountGroupId
            );

            
            Margin__c bestMargin = (Margin__c) findBestSpecificity(marginList, toFind);
            if(bestMargin != null) iOrderProduct.MarginPercentage__c = bestMargin.value__c;


        }

    }
        

    //achar um jeito de retirar todos os maps
    private static void calculateValues(List<OrderItem> records){
        
        map<Id, Product2> productList = new map<Id,Product2>( 
            [SELECT Id, ProductionCost__c FROM Product2 WHERE Id IN :productIds] 
        );
        for(OrderItem iOrderIten : records){
            if(iOrderIten.CostFreight__c == null || iOrderIten.TaxPercentage__c == null || iOrderIten.MarginPercentage__c == null){
                iOrderIten.addError('The sale of this product is not authorized due to lack of parameters, please contact the pricing team');
                continue;
            }            
            iOrderIten.NoMarginPrice__c = (productList.get(iOrderIten.Product2Id).ProductionCost__c + iOrderIten.CostFreight__c) * (1 + iOrderIten.TaxPercentage__c/100);
            iOrderIten.Final__c = iOrderIten.NoMarginPrice__c * (1 + iOrderIten.MarginPercentage__c/100);
            iOrderIten.Discount__c = (iOrderIten.Final__c - iOrderIten.UnitPrice)/iOrderIten.Final__c;

        }
    } 
    
    private static SObject findBestSpecificity(List<SObject> records, SObject toFind){
        
        //Mapa de valor por campo
        Map<String, Integer> fieldsWeights = new Map<String, Integer>{
            'Product__c' => 1000,
            'ProductHierarchy__c' => 500,
            'Account__c' => 100,
            'AccountGroup__c' => 50,
            'City__c' => 10,
            'State__c' => 5,
            'Country__c' => 1
        };

        Integer bestScore = -1;
        SObject bestRecord;

        //Mapa dos campos do objeto que queremos
        Map<String,Object> toFindMap = toFind.getPopulatedFieldsAsMap();

        for(SObject record : records){
           
            Integer score = -1;

            //Mapa do objeto que temos agora
            Map<String,Object> recordMap = record.getPopulatedFieldsAsMap();

            //Calculando a pontuacao de cada um com base nos campos que temos
            for(String fieldName : fieldsWeights.keySet()){
                Object recordValue = recordMap.get(fieldName);
                Object toFindValue = toFindMap.get(fieldName);

                // Só soma peso se ambos não forem nulos e forem iguais
                if(recordValue != null && toFindValue != null && recordValue == toFindValue){
                    score += fieldsWeights.get(fieldName);
                }
            }

            if(score > bestScore){
                bestScore = score;
                bestRecord = record;
            }
        }

        // Retorna null se nenhum registro tiver correspondência
        return bestRecord;
    }

}