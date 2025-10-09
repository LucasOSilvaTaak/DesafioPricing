public with sharing class OrderItemTriggerHelper {
    
    public static void handleBeforeInsert(List<OrderItem> newList){
       
        fillOrderItem(newList);
    
    }

    public static void handleBeforeUpdate(List<OrderItem> oldList , List<OrderItem> newList){
        
        List<OrderItem> changedList = new List<OrderItem>();
        
        for(Integer i = 0; i < newList.size(); i++){
        
            if(!CompareSObjects.equals(oldList[i], newList[i], new Set<String>{
                'Product2Id',
                'UnitPrice',
                'Quantity',
                'CostFreight__c',
                'TaxPercentage__c',
                'MarginPercentage__c'
            })) changedList.add(newList[i]);
            
        }

        if(!changedList.isEmpty()) fillOrderItem(changedList);

    }
    
    private static void fillOrderItem(List<OrderItem> records){
        
        //preenche os masps e sets para a busca
        fillOrderItensLockups(records);
        
        //Segue com apenas aqueles que podem ser alterados
        List<OrderItem> draftOrderItem = draftOnly(records);
        
        //se não tiver nenhum em rascunho para o processo 
        if(draftOrderItem.size() > 0){

            Set<Id> productIds = new Set<Id>();
            Set<Id> productHierarchyIds = new Set<Id>();
            Set<Id> cityIds = new Set<Id>();
            Set<Id> stateIds = new Set<Id>();
            Set<Id> countryIds = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();
            Set<Id> accountGroupIds = new Set<Id>();
    
            for(OrderItem iOrderItem : draftOrderItem){
    
                productIds.add(iOrderItem.Product2Id);
                productHierarchyIds.add(iOrderItem.Product2.ProductHierarchy__c);
                cityIds.add(iOrderItem.Order.AccountAddress__r.City__c);
                stateIds.add(iOrderItem.Order.AccountAddress__r.City__r.State__c);
                countryIds.add(iOrderItem.Order.AccountAddress__r.City__r.State__r.Country__c);
                accountIds.add(iOrderItem.Order.AccountAddress__r.Account__c);
                accountGroupIds.add(iOrderItem.Order.AccountAddress__r.Account__r.AccountGroup__c);
    
            }
            
            //Busca final de todas as freights citadas
            List<Freight__c> freightList = [
                SELECT Value__c, Product__c, ProductHierarchy__c, City__c, State__c, Country__c, Status__c
                FROM Freight__c
                WHERE (Product__c IN :productIds 
                    OR ProductHierarchy__c IN :productHierarchyIds)
                AND (City__c IN :cityIds 
                    OR State__c IN :stateIds
                    OR Country__c IN :countryIds)
                AND Status__c = 'Approved'            
            ];
            
            
            List<Tax__c> taxList = [
                SELECT TaxOnCost__c, State__c, Product__c, Status__c
                FROM Tax__c
                WHERE Status__c = 'Approved'
                AND State__c IN : stateIds
                AND Product__c IN :productIds
            ];
                
            List<Margin__c> marginList = [
                SELECT Product__c, ProductHierarchy__c, Account__c, 
                AccountGroup__c, City__c, State__c, Country__c, Status__c, Value__c
                FROM Margin__c
                WHERE Status__c = 'Approved'
                AND (Product__c IN :productIds 
                    OR ProductHierarchy__c IN : productHierarchyIds)
                AND (Account__c IN :accountIds 
                    OR AccountGroup__c IN :accountGroupIds)
                AND (City__c IN :cityIds 
                    OR State__c IN :stateIds 
                    OR Country__c IN : countryIds)
            ];
            
            
            //Funções que preenchem os valores de cada Order Item
            ajustFreight(draftOrderItem, freightList);
    
            ajustTax(draftOrderItem, taxList);
    
            ajustMargin(draftOrderItem, marginList);
                
            //Calcular os valores de cada orderm produto
            calculatePrices(draftOrderItem);
        }
                                      
    }
                
    //Tenho que arrumar esse metodo para usar menos maps
    private static void fillOrderItensLockups(List<OrderItem> records){

        //Sets ids de ordem e produto 
        Set<Id> orderIds   = new Set<Id>();
        Set<Id> productIds = new Set<Id>();

        //preenche todos os ids
        for (OrderItem iOrderItem : records) {
            
            orderIds.add(iOrderItem.OrderId);
            productIds.add(iOrderItem.Product2Id);
        
        }

        //Cria um map com todos os valores nescessarios de produto
        Map<Id, Product2> productMap = new Map<Id, Product2>(
            [SELECT Id, ProductHierarchy__c, ProductionCost__c FROM Product2 WHERE Id IN :productIds]
        );

        //Cria um map com todos os lookups de ordem
        Map<Id,Order>  orderMap = new Map<Id, Order>(
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
        
        //Preenche os lookups de cada ordem item
        for (OrderItem iOrderItem : records) {

            //Busca um valor temporario para cada ordem e produtos do map
            Order tempOrder = orderMap.get(iOrderItem.OrderId);
            Product2 tempProduct = productMap.get(iOrderItem.Product2Id);

            //Populando os valores de cada Order Item
            iOrderItem.Order = tempOrder;
            iOrderItem.Product2 = tempProduct;

        }

    }
    

    //Permite apenas alterações de pedidos em rascunhos e devolve a lista dos que podem ser alterados
    private static List<OrderItem> draftOnly(List<OrderItem> records){

        List<OrderItem> changedList = new List<OrderItem>();
        for(OrderItem iOrderProduct : records){
        
            if(iOrderProduct.Order.Status != 'Draft') iOrderProduct.addError('You can only change the value of the order product when the order is in draft status');
            else{
                changedList.add(iOrderProduct);
            }
        }
        return changedList;
    }
        
    
    private static void ajustFreight(List<OrderItem> records, List<Freight__c> freightList){

        for(OrderItem iOrderProduct : records){

            //PegANDo os ids para filtar
            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = iOrderProduct.Product2.ProductHierarchy__c;
            Id cityId = iOrderProduct.Order.AccountAddress__r.City__c;
            Id stateId = iOrderProduct.Order.AccountAddress__r.City__r.State__c;
            Id countryId = iOrderProduct.Order.AccountAddress__r.City__r.State__r.Country__c;

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
            Id stateId = iOrderProduct.Order.AccountAddress__r.City__r.State__c;            

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

            //Anula para que reculcule os dados em caso de update, pois se não achar e tiver !null ele aceita o antigo
            iOrderProduct.MarginPercentage__c = null;

            Id productId = iOrderProduct.Product2Id;
            Id productHierarchyId = iOrderProduct.Product2.ProductHierarchy__c;
            Id cityId = iOrderProduct.Order.AccountAddress__r.City__c;
            Id stateId = iOrderProduct.Order.AccountAddress__r.City__r.State__c;
            Id countryId = iOrderProduct.Order.AccountAddress__r.City__r.State__r.Country__c;
            Id AccountId = iOrderProduct.Order.AccountAddress__r.Account__c;
            Id AccountGroupId = iOrderProduct.Order.AccountAddress__r.Account__r.AccountGroup__c;

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
    private static void calculatePrices(List<OrderItem> records){
        
        for(OrderItem iOrderIten : records){

            if(verifyFieldsNotNull(iOrderIten)) continue; 
        
            iOrderIten.NoMarginPrice__c = (iOrderIten.Product2.ProductionCost__c + iOrderIten.CostFreight__c) * (1 + iOrderIten.TaxPercentage__c/100);
        
            iOrderIten.DiscountedPriceUnit__c = iOrderIten.NoMarginPrice__c * (1 + iOrderIten.MarginPercentage__c/100);
            iOrderIten.Final__c = iOrderIten.DiscountedPriceUnit__c * iOrderIten.Quantity;
        
            iOrderIten.Discount__c = 100 * ((iOrderIten.DiscountedPriceUnit__c - iOrderIten.UnitPrice)/iOrderIten.DiscountedPriceUnit__c);

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

    //Verifica se os campos nescessarios para os calculos foram achados
    private static Boolean verifyFieldsNotNull(OrderItem iOrderIten){
        
        String errorMessage = '';
        Boolean hasError = false;

        if(iOrderIten.CostFreight__c == null ){

            errorMessage += ' Freight cost not found. ';
        
            hasError = true;
            
        }
        
        if(iOrderIten.TaxPercentage__c == null ){
        
            errorMessage += ' Tax percentage not found. ';
        
            hasError = true;
            
        }
        
        if(iOrderIten.MarginPercentage__c == null ){
        
            errorMessage += ' Margin percentage not found. ';
        
            hasError = true;

        }

        if (hasError) iOrderIten.addError('The sale of this product is not authorized due to lack of parameters, please contact the pricing team: ' + errorMessage);
        return hasError;
    }

}