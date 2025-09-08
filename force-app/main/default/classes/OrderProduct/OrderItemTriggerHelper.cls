public with sharing class OrderItemTriggerHelper {
    public static void HANDleBeforeInsertOrderProduct(List<OrderItem> newList){
        fillValues(newList);
    }

    public static void HANDleBeforeUpdateOrderProduct(List<OrderItem> oldList , List<OrderItem> newList){
        fillValues(newList);
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

    
    
    private static void fillValues(List<OrderItem> newList){
        
        //preenche os masps e sets para a busca
        fillMaps(newList);
        
        //impede qualque modificação após pedido sair de draft
        draftOnly(newList);
        
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
            
            ajustFreight(newList, freightList);

            ajustTax(newList, taxList);

            ajustMargin(newList, marginList);
            
            //Calcular os valores de cada orderm produto
            calculateValues(newList);
                    
                    
    }
                
                
    private static void fillMaps(List<OrderItem> newList){
        orderIds   = new Set<Id>();
        productIds = new Set<Id>();

        for (OrderItem iOrderItem : newList) {
            if (iOrderItem.OrderId != null)    orderIds.add(iOrderItem.OrderId);
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
    private static void draftOnly(List<OrderItem> newList){

        for(OrderItem iOrderProduct : newList){
            if(orderMap.get(iOrderProduct.OrderId).Status != 'Draft') iOrderProduct.addError('You can only change the value of the order product when the order is in draft status');
        }
    }
        
    
    private static void ajustFreight(List<OrderItem> newList, List<Freight__c> freightList){
        
        for(OrderItem iOrderProduct : newList){
            iOrderProduct.CostFreight__c = null;
            Integer bestScore = -1;
                        
    
            //PegANDo os ids para filtar
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = productToHierarchy.get(productId);
            Id cityId = addressToCity.get(orderToAddress.get(iOrderProduct.OrderId));
            Id stateId = cityToState.get(cityId);
            Id countryId = stateToCountry.get(stateId);
    
            for (Freight__c iFreight : freightList){
                integer score = -1;

    
                if(iFreight.Product__c == productId){
                    score += 100;
                }
                else {
                    if(iFreight.ProductHierarchy__c == productHierarchyId){
                        score += 50;
                    }
                    else{

                        continue;
                    }
                }
    
                if(iFreight.City__c == cityId){
                    score += 10;
                }
                else{
                    if(iFreight.State__c == stateId){
                        score += 5;
                    }
                    else{
                        if(iFreight.Country__c == countryId) {
                            score += 1;
                        }
                        else{

                            continue;
                        }
                    }
                }

                if(score > bestScore){
                    bestScore = score;
                    iOrderProduct.CostFreight__c = iFreight.Value__c;
                }
                
            }
            
        }
        
    }
    
    private static void ajustTax(List<OrderItem> newList, List<Tax__c> taxList){
        
        for(OrderItem iOrderProduct : newList){
            iOrderProduct.TaxPercentage__c = null;
            Integer bestScore = -1;

    
            //PegANDo os ids para filtar
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = productToHierarchy.get(productId);
            Id cityId = addressToCity.get(orderToAddress.get(iOrderProduct.OrderId));
            Id stateId = cityToState.get(cityId);
            
            for (Tax__c iTax : taxList){
                if(iTax.Product__c == productId && iTax.State__c == stateId){
                    iOrderProduct.TaxPercentage__c = iTax.TaxOnCost__c;
                    break;
                }

            }

        }
    }

    private static void ajustMargin(List<OrderItem> newList, List<Margin__c> marginList){
        for(OrderItem iOrderProduct : newList){
            iOrderProduct.MarginPercentage__c = null;
            Integer bestScore = -1;

    
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = productToHierarchy.get(productId);
            Id cityId = addressToCity.get(orderToAddress.get(iOrderProduct.OrderId));
            Id stateId = cityToState.get(cityId);
            Id countryId = stateToCountry.get(stateId);
            Id AccountId = addressToAccount.get(orderToAddress.get(iOrderProduct.OrderId));
            Id AccountGroupId = AccountToAccountGroup.get(AccountId);

            for (Margin__c iMargin : marginList){
                integer score = -1;

    
                if(iMargin.Product__c == productId){
                    score += 1000;
                }
                else {
                    if(iMargin.ProductHierarchy__c == productHierarchyId){
                        score += 500;
                    }
                    else{

                        continue;
                    }
                }

                if(iMargin.Account__c == AccountId){
                    score += 100;
                }
                else{
                    if(iMargin.AccountGroup__c  == AccountGroupId){
                        score += 50;
                    }
                    else{
                        continue;
                    }
                }
    
                if(iMargin.City__c == cityId){
                    score += 10;
                }
                else{
                    if(iMargin.State__c == stateId){
                        score += 5;
                    }
                    else{
                        if(iMargin.Country__c == countryId) {
                            score += 1;
                        }
                        else{

                            continue;
                        }
                    }
                }

                if(score > bestScore){
                    bestScore = score;
                    iOrderProduct.MarginPercentage__c = iMargin.Value__c;
                }
    
            }

        }

    }
        

    private static void calculateValues(List<OrderItem> newList){
        
        map<Id, Product2> productList = new map<Id,Product2>( 
            [SELECT Id, ProductionCost__c FROM Product2 WHERE Id IN :productIds] 
        );
        for(OrderItem iOrderIten : newList){
            if(iOrderIten.CostFreight__c == null || iOrderIten.TaxPercentage__c == null || iOrderIten.MarginPercentage__c == null){
                iOrderIten.addError('The sale of this product is not authorized due to lack of parameters, please contact the pricing team');
                continue;
            }            
            iOrderIten.NoMarginPrice__c = (productList.get(iOrderIten.Product2Id).ProductionCost__c + iOrderIten.CostFreight__c) * (1 + iOrderIten.TaxPercentage__c/100);
            iOrderIten.Final__c = iOrderIten.NoMarginPrice__c * (1 + iOrderIten.MarginPercentage__c/100);
            iOrderIten.Discount__c = (iOrderIten.Final__c - iOrderIten.UnitPrice)/iOrderIten.Final__c;

        }
    } 
    

    
}