public with sharing class OrderItemTriggerHelper {
    public static void HandleBeforeInsertOrderProduct(List<OrderItem> newList){
        FillValues(newList);
    }

    public static void HandleBeforeUpdateOrderProduct(List<OrderItem> oldList , List<OrderItem> newList){
        FillValues(newList);
    }

    private static void FillValues(List<OrderItem> newList){
        set<Id> productIds = new Set<Id>();
        for(OrderItem iOrderProduct : newList){
            productIds.add(iOrderProduct.Product2Id);
            
        }

        //Busca uma hierarquia de produtos, pois sempre havera uma hieraquia, mas nem sempre havera um frete relacionado a hierarquia
        Map<Id,Id> productToHierarchy = new Map<Id,Id>();
        for(Product2 iProduct : [select id, ProductHierarchy__c from Product2 where Id in :productIds]){
            productToHierarchy.put(iProduct.id ,iProduct.ProductHierarchy__c);
        }

        ////////////////////////////////////////////////////////////////////////////////Parte de produto e hierarquia

        //Busca todos os ids de Ordem para buscar AccountAddress
        Set<Id> orderIds = new Set<Id>();
        for(OrderItem iOrderProduct : newList){
            orderIds.add(iOrderProduct.OrderId);
        }

        //Busca todos os ids de Ordem para buscar AccountAddress
        Map<Id,Id> orderToAddress = new Map<Id,id>();
        for(Order iOrder : [select Id, AccountAddress__c from Order where Id in :orderIds]){
            orderToAddress.put(iOrder.Id, iOrder.AccountAddress__c);
        }

        //faz um mapa com os ids de ambos AccountAddress e city
        Map<Id,Id> addressToCity = new  Map<Id,Id>();
        for(AccountAddress__c iOrderAddress : [select Id, City__c from AccountAddress__c where Id in :orderToAddress.values()]){
            addressToCity.put(iOrderAddress.Id, iOrderAddress.City__c);
        }

        //Mapa de Ids de cidade e estado
        Map<Id,Id> cityToState = new Map<Id,Id>();
        for (City__c iCity : [select Id, State__c from City__c where Id in :addressToCity.values()]){
            cityToState.put(iCity.Id, iCity.State__c);
        }

        //Mapa de Ids de estado e e pais
        Map<Id,Id> stateToCountry = new Map<Id,Id>();
        for (State__c iState : [select Id, Country__c from State__c where Id in :cityToState.values()]){
            stateToCountry.put(iState.Id, iState.Country__c);
        }

        ////////////////////////////////////////////////////////////////////////////////////Parte de localizacao


        //buscar a order de cada order procuct para acessar Account Address para acessar cidade que pode acessar estado que acessa pais

        //Busca final de todas as freights citadas
        List<Freight__c> freightList = [
            select Value__c, Product__c, ProductHierarchy__c, City__c, State__c, Country__c, Status__c
            from Freight__c
            where (Product__c in :productIds 
            or ProductHierarchy__c in :productToHierarchy.values())
            and (City__c in :addressToCity.values()
            or State__c in :cityToState.values()
            or Country__c in :stateToCountry.values())
            and Status__c = 'Approved'
        
        ];

        for(OrderItem iOrderProduct : newList){
            
            Integer bestScore = -1;

            //Pegando os ids para filtar
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = productToHierarchy.get(productId);
            Id cityId = addressToCity.get(orderToAddress.get(iOrderProduct.OrderId));
            Id stateId = cityToState.get(cityId);
            Id countryId = stateToCountry.get(stateId);

            System.debug('freightList size = ' + freightList.size());
            for (Freight__c iFreight : freightList){
                integer score = -1;


                if(iFreight.Product__c == productId){
                    score += 100;
                }
                else if(iFreight.ProductHierarchy__c == productHierarchyId){
                    score += 50;
                }

                if(iFreight.City__c == cityId){
                    score += 10;
                }
                else{
                    if(iFreight.State__c == stateId){
                        score += 5;
                    }
                    else if(iFreight.Country__c == countryId) {
                        score += 1;
                    }
                }
                if(score > bestScore){
                    bestScore = score;
                    iOrderProduct.CostFreight__c = iFreight.Value__c;
                }
                

                }
                if(iOrderProduct.CostFreight__c == null){
                    iOrderProduct.addError('Freight not found');
                }

        }
    }

    
}