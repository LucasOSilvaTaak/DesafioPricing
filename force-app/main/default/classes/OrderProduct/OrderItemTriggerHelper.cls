public with sharing class OrderItemTriggerHelper {
    
    //Classes publicas para serem usadas nos triggers
    public static void HandleBeforeInsertOrderProduct(List<OrderItem> newList){
        FillValues(newList);
    }

    public static void HandleBeforeUpdateOrderProduct(List<OrderItem> oldList , List<OrderItem> newList){
        FillValues(newList);
    }


    
    private static Set<Id> productIds = new Set<Id>();
    private static Set<Id> productHierarchyIds = new Set<Id>();
    private static Set<Id> cityIds = new Set<Id>();
    private static Set<Id> stateIds = new Set<Id>();
    private static Set<Id> countryIds = new Set<Id>();
    private static Set<Id> AccountIds = new Set<Id>();
    private static Set<Id> AccountGroupIds = new Set<Id>();

    
    //Impede que quando o status do pedido for diferente de draft ele impede o update
    private static void DraftOnly(List<OrderItem> newList){

        for(OrderItem iOrderProduct : newList){
            if(iOrderProduct.Order.Status != 'Draft') iOrderProduct.addError('You can only change the value of the order product when the order is in draft status');
        }
    }
        
    

    private static void FillValues(List<OrderItem> newList){

        //preenche os masps e sets para a busca
        FillMaps(newList);

        //impede qualque modificação após pedido sair de draft
        DraftOnly(newList);

        //Busca final de todas as freights citadas
        List<Freight__c> freightList = [
            select Value__c, Product__c, ProductHierarchy__c, City__c, State__c, Country__c, Status__c
            from Freight__c
            where (Product__c in :productIds 
            or ProductHierarchy__c in :productHierarchyIds)
            and (City__c in :cityIds
            or State__c in :stateIds
            or Country__c in :countryIds)
            and Status__c = 'Approved'
        
        ];
        
        List<Tax__c> taxList = [
            select TaxOnCost__c, State__c, Product__c, Status__c
            from Tax__c
            where Status__c = 'Approved'
            and State__c in :stateIds
            and Product__c in :productIds
        ];

        List<Margin__c> marginList = [
            select Product__c, ProductHierarchy__c, Account__c, 
                AccountGroup__c, City__c, State__c, Country__c, Status__c, Value__c
            from Margin__c
            where Status__c = 'Approved'
            and (Product__c in :productIds or ProductHierarchy__c in :productHierarchyIds)
            and (Account__c in :AccountIds or AccountGroup__c in :AccountGroupIds)
            and (City__c in :cityIds or State__c in :stateIds or Country__c in :countryIds)
        ];

        AjustFreight(newList, freightList);
        AjustTax(newList, taxList);
        AjustMargin(newList, marginList);

        //Calcular os valores de cada orderm produto
        CalculateValues(newList);


    }
    
    
    private static void AjustFreight(List<OrderItem> newList, List<Freight__c> freightList){
        
        for(OrderItem iOrderProduct : newList){
            iOrderProduct.CostFreight__c = null;
            Integer bestScore = -1;

    
            //Pegando os ids para filtar
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = iOrderProduct.Product2.ProductHierarchy__c;
            Id cityId = iOrderProduct.Order.AccountAddress__r.City__c;
            Id stateId = iOrderProduct.Order.AccountAddress__r.City__r.State__c;
            Id countryId = iOrderProduct.Order.AccountAddress__r.City__r.State__r.Country__c;
    
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

    private static void AjustTax(List<OrderItem> newList, List<Tax__c> taxList){
         
        for(OrderItem iOrderProduct : newList){
            iOrderProduct.TaxPercentage__c = null;
            Integer bestScore = -1;

    
            Id productId = iOrderProduct.Product2Id;
            Id stateId = iOrderProduct.Order.AccountAddress__r.City__r.State__c;

            
            for (Tax__c iTax : taxList){
                if(iTax.Product__c == productId && iTax.State__c == stateId){
                    iOrderProduct.TaxPercentage__c = iTax.TaxOnCost__c;
                    break;
                }

            }

        }
    }

    private static void AjustMargin(List<OrderItem> newList, List<Margin__c> marginList){
        for(OrderItem iOrderProduct : newList){
            iOrderProduct.MarginPercentage__c = null;
            Integer bestScore = -1;

    
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = iOrderProduct.Product2.ProductHierarchy__c;
            Id cityId = iOrderProduct.Order.AccountAddress__r.City__c;
            Id stateId = iOrderProduct.Order.AccountAddress__r.City__r.State__c;
            Id countryId = iOrderProduct.Order.AccountAddress__r.City__r.State__r.Country__c;
            Id AccountId = iOrderProduct.Order.AccountAddress__r.Account__c;
            Id AccountGroupId = iOrderProduct.Order.AccountAddress__r.Account__r.AccountGroup__c;

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
        
    private static void FillMaps(List<OrderItem> newList){
        Set<Id> orderIds   = new Set<Id>();
        Set<Id> productIds = new Set<Id>();

        for (OrderItem iOrderItem : newList) {
            if (iOrderItem.OrderId != null)    orderIds.add(iOrderItem.OrderId);
            if (iOrderItem.Product2Id != null) productIds.add(iOrderItem.Product2Id);
        }

        //Cria um map com todos os lookups de ordem
        Map<Id,Order>  orderMap = new Map<Id, Order>(
            [
                select Id,
                    AccountAddress__c,
                    AccountAddress__r.City__c,
                    AccountAddress__r.City__r.State__c,
                    AccountAddress__r.City__r.State__r.Country__c,
                    AccountAddress__r.Account__c,
                    AccountAddress__r.Account__r.AccountGroup__c,
                    Status
                from Order
                where Id IN :orderIds
            ]
        );
        
        Map<Id, Id> productToHierarchy = new Map<Id, Id>();
        for (Product2 p : [select Id, ProductHierarchy__c from Product2 where Id in :productIds]) {
            productToHierarchy.put(p.Id, p.ProductHierarchy__c);
        }
                    System.debug(newList.size());

        for (OrderItem iOrderItem : newList) {

            Order tempOrder = orderMap.get(iOrderItem.OrderId);
            System.debug(tempOrder.AccountAddress__c);
            Id tempProductHierarchyId = productToHierarchy.get(iOrderItem.Product2Id);

            //Populando os valores de cada Order Item
            iOrderItem.Order.AccountAddress__c = tempOrder.AccountAddress__c;
            iOrderItem.Order.AccountAddress__r.City__c = tempOrder.AccountAddress__r.City__c;
            iOrderItem.Order.AccountAddress__r.City__r.State__c = tempOrder.AccountAddress__r.City__r.State__c;
            iOrderItem.Order.AccountAddress__r.City__r.State__r.Country__c = tempOrder.AccountAddress__r.City__r.State__r.Country__c;
            iOrderItem.Order.AccountAddress__r.Account__c = tempOrder.AccountAddress__r.Account__c;
            iOrderItem.Order.AccountAddress__r.Account__r.AccountGroup__c = tempOrder.AccountAddress__r.Account__r.AccountGroup__c;
            iOrderItem.Product2.ProductHierarchy__c = tempProductHierarchyId;
            iOrderItem.Order.Status = tempOrder.Status;

            //Populando os sets para a busca
            productIds.add(iOrderItem.Product2Id);
            productHierarchyIds.add(tempProductHierarchyId);
            cityIds.add(tempOrder.AccountAddress__r.City__c);
            stateIds.add(tempOrder.AccountAddress__r.City__r.State__c);
            countryIds.add(tempOrder.AccountAddress__r.City__r.State__r.Country__c);
            AccountIds.add(tempOrder.AccountAddress__r.Account__c);
            AccountGroupIds.add(tempOrder.AccountAddress__r.Account__r.AccountGroup__c);

        }



    }
    

    private static void CalculateValues(List<OrderItem> newList){
        
        map<Id, Product2> productList = new map<Id,Product2>([select Id, ProductionCost__c from Product2 where Id in :productIds]);

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