public with sharing class ProductTriggerHelper {

    public static void handleAfterInsertOrder(List<Product2> newList){
       
        List<PricebookEntry>  pricebookEntryList = new List<PricebookEntry>();
       
        Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];

        for(Product2 iProduct: newList){
       
            pricebookEntryList.add(new PricebookEntry(
                Pricebook2Id = standardPriceBook.Id,
                Product2Id = iProduct.Id,
                UnitPrice = iProduct.ProductionCost__c,
                IsActive = true,
                CurrencyIsoCode = iProduct.CurrencyIsoCode 
            ));
        }

        if(pricebookEntryList.size()>0) insert pricebookEntryList;

    }

     public static void handleAfterUpdateOrder(List<Product2> oldList, List<Product2> newList){
        
        Set<Id> updatedProducts = new Set<Id>();

        for(Integer i = 0; i < newList.size(); i++){

            if(!oldList[i].equals(newList[i].ProductionCost__c)){

                updatedProducts.add(newList[i].Id);

            }
        }

        if(updatedProducts.isEmpty()) return;

        Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];

        List<PricebookEntry> pricebookEntriesToUpdate = [
            SELECT Id, Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Product2Id IN :updatedProducts
            AND Pricebook2Id = :standardPriceBook.Id
        ];

        Map<Id, Product2> productMap = new Map<Id, Product2>(newList);

        for(PricebookEntry iPricebookEntry : pricebookEntriesToUpdate){

            Product2 product = productMap.get(iPricebookEntry.Product2Id);

            if(product != null) iPricebookEntry.UnitPrice = product.ProductionCost__c;
            
        }

        if(!pricebookEntriesToUpdate.isEmpty()){
            
            update pricebookEntriesToUpdate;
        
        }
    }

}
