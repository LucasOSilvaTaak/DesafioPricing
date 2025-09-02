public with sharing class OrderItemTriggerHelper {
    public static void HandleBeforeInsertOrderProduct(List<OrderItem> newList){
        FillValues(newList);
    }

    public static void HandleBeforeUpdateOrderProduct(List<OrderItem> oldList , List<OrderItem> newList){
        FillValues(newList);
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


    private static void FillValues(List<OrderItem> newList){

        //preenche os masps e sets para a busca
        FillMaps(newList);

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
        
        List<Tax__c> taxList = [
            select TaxOnCost__c, State__c, Product__c, Status__c
            from Tax__c
            where Status__c = 'Approved'
            and State__c in :cityToState.values()
            and Product__c in :productIdS
        ];

        List<Margin__c> marginList = [
            select Product__c, ProductHierarchy__c, Account__c, 
                AccountGroup__c, City__c, State__c, Country__c, Status__c, Value__c
            from Margin__c
            where Status__c = 'Approved'
            and (Product__c in :productIds or ProductHierarchy__c in :productToHierarchy.values())
            and (Account__c in :addressToAccount.values() or AccountGroup__c in :AccountToAccountGroup.values())
            and (City__c in :addressToCity.values() or State__c in :cityToState.values() or Country__c in :stateToCountry.values())
        ];

        AjustFreight(newList, freightList);
        AjustTax(newList, taxList);
        AjustMargin(newList, marginList);

        //Calcular os valores de cada orderm produto
        CalculateValues(newList);


    }
    
    
    private static void ajustFreight(List<OrderItem> newList, List<Freight__c> freightList){
        
        for(OrderItem iOrderProduct : newList){
            iOrderProduct.CostFreight__c = null;
            Integer bestScore = -1;

    
            //Pegando os ids para filtar
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
            
            if(iOrderProduct.CostFreight__c == null){
                iOrderProduct.addError('The sale of this product is not authorized due to lack of parameters, please contact the pricing team');
            }
        }

    }

    private static void AjustTax(List<OrderItem> newList, List<Tax__c> taxList){
         
        for(OrderItem iOrderProduct : newList){
            iOrderProduct.TaxPercentage__c = null;
            Integer bestScore = -1;

    
            //Pegando os ids para filtar
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = productToHierarchy.get(productId);
            Id cityId = addressToCity.get(orderToAddress.get(iOrderProduct.OrderId));
            Id stateId = cityToState.get(cityId);
            Id countryId = stateToCountry.get(stateId);
            
            iOrderProduct.TaxPercentage__c = null;

            for (Tax__c iTax : taxList){
                if(iTax.Product__c == productId && iTax.State__c == stateId){
                    iOrderProduct.TaxPercentage__c = iTax.TaxOnCost__c;
                    break;
                }

            }
            if(iOrderProduct.TaxPercentage__c == null){
                iOrderProduct.addError('The sale of this product is not authorized due to lack of parameters, please contact the pricing team');
            }
        }
    }

    private static void AjustMargin(List<OrderItem> newList, List<Margin__c> marginList){
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
            
            if(iOrderProduct.MarginPercentage__c == null){
                iOrderProduct.addError('The sale of this product is not authorized due to lack of parameters, please contact the pricing team');
            }
        }

    }
        
    private static void FillMaps(List<OrderItem> newList){
                productIds = new Set<Id>();
        for(OrderItem iOrderProduct : newList){
            productIds.add(iOrderProduct.Product2Id);
            
            

        }

        //Busca uma hierarquia de produtos, pois sempre havera uma hieraquia, mas nem sempre havera um frete relacionado a hierarquia
        productToHierarchy = new Map<Id,Id>();
        for(Product2 iProduct : [select id, ProductHierarchy__c from Product2 where Id in :productIds]){
            productToHierarchy.put(iProduct.id ,iProduct.ProductHierarchy__c);
        }

        ////////////////////////////////////////////////////////////////////////////////Parte de produto e hierarquia

        //Busca todos os ids de Ordem para buscar AccountAddress
        orderIds = new Set<Id>();
        for(OrderItem iOrderProduct : newList){
            orderIds.add(iOrderProduct.OrderId);
        }

        //Busca todos os ids de Ordem para buscar AccountAddress
        orderToAddress = new Map<Id,id>();
        for(Order iOrder : [select Id, AccountAddress__c from Order where Id in :orderIds]){
            orderToAddress.put(iOrder.Id, iOrder.AccountAddress__c);
        }

        //faz um mapa com os ids de ambos AccountAddress e city
        addressToCity = new  Map<Id,Id>();
        for(AccountAddress__c iOrderAddress : [select Id, City__c from AccountAddress__c where Id in :orderToAddress.values()]){
            addressToCity.put(iOrderAddress.Id, iOrderAddress.City__c);
        }

        //Mapa de Ids de cidade e estado
        cityToState = new Map<Id,Id>();
        for (City__c iCity : [select Id, State__c from City__c where Id in :addressToCity.values()]){
            cityToState.put(iCity.Id, iCity.State__c);
        }

        //Mapa de Ids de estado e e pais
        stateToCountry = new Map<Id,Id>();
        for (State__c iState : [select Id, Country__c from State__c where Id in :cityToState.values()]){
            stateToCountry.put(iState.Id, iState.Country__c);
        }


        ////////////////////////////////////////////////////////////////////////////////////Parte de localizacao
        
        

        addressToAccount = new Map<Id,Id>();
        for(AccountAddress__c iAccountAddress : [select Id, Account__c from AccountAddress__c where Id in :orderToAddress.values()]){
            addressToAccount.put(iAccountAddress.Id, iAccountAddress.Account__c);
        }

        AccountToAccountGroup = new Map<Id,Id>();
        for(Account iAccount : [select Id, AccountGroup__c from Account where Id in :addressToAccount.values()]){
            AccountToAccountGroup.put(iAccount.Id, iAccount.AccountGroup__c);
        }

        ////////////////////////////////////////////////////////////////////////////////////Parte de Account


    }

    private static void CalculateValues(List<OrderItem> newList){
        for(OrderItem iOrderIten : newList){
            iOrderIten.NoMarginPrice__c = (iOrderIten.UnitPrice + iOrderIten.CostFreight__c) * (1 + iOrderIten.TaxPercentage__c/100);
            iOrderIten.Final__c = iOrderIten.NoMarginPrice__c * (1 + iOrderIten.MarginPercentage__c/100);
            iOrderIten.Discount__c = (iOrderIten.Final__c - iOrderIten.UnitPrice)/iOrderIten.Final__c;

        }
    }
    

    
}