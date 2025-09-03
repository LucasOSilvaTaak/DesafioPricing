public with sharing class ProductTriggerHelper {

    public static void HandleAfterInsertOrder(List<Product2> newList){
        List<PricebookEntry>  pricebookEntryList = new List<PricebookEntry>();
        Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];

        for(Product2 iProduct: newList){
            pricebookEntryList.add(new PricebookEntry(
                Pricebook2Id = standardPriceBook.Id,
                Product2Id = iProduct.Id,
                UnitPrice = iProduct.ProductionCost__c,
                IsActive = true

            ));
        }

        if(pricebookEntryList.size()>0) insert pricebookEntryList;

    }

     public static void HandleAfterUpdateOrder(List<Product2> oldList, List<Product2> newList){
        Set<Id> productIdsToUpdate = new Set<Id>();
        for(Integer i = 0; i < newList.size(); i++){
            if(oldList[i].ProductionCost__c != newList[i].ProductionCost__c){
                productIdsToUpdate.add(newList[i].Id);
            }
        }

        if(productIdsToUpdate.isEmpty()){
            return;
        }

        Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];

        List<PricebookEntry> pricebookEntriesToUpdate = [
            SELECT Id, Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Product2Id IN :productIdsToUpdate
            AND Pricebook2Id = :standardPriceBook.Id
        ];

        Map<Id, Product2> productMap = new Map<Id, Product2>(newList);

        for(PricebookEntry pbe : pricebookEntriesToUpdate){
            Product2 prod = productMap.get(pbe.Product2Id);
            if(prod != null){
                pbe.UnitPrice = prod.ProductionCost__c;
            }
        }

        if(!pricebookEntriesToUpdate.isEmpty()){
            update pricebookEntriesToUpdate;
        }
    }


    

}
