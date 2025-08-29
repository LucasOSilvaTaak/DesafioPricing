public with sharing class MarginTriggerHelper {
    public static void HandleInsertMargin(List<Margin__c> newList){
        VerifyDuplicity(newList);

    }

    public static void HandleUpdateMargin(List<Margin__c> oldList, List<Margin__c> newList){
        VerifyDuplicity(newList);
    }

    private static void VerifyDuplicity(List<Margin__c> records){
        Set<String> keys = new Set<String>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> productHierarchyIds = new Set<Id>();

        for(Margin__c iMargin : records){

            String temp = MakeKey(iMargin);
            if(keys.contains(temp))iMargin.addError('Duplicate in batch');
            else keys.add(temp);
            
   

            if(iMargin.Product__c != null) productIds.add(iMargin.Product__c);
            if(iMargin.ProductHierarchy__c != null) productHierarchyIds.add(iMargin.ProductHierarchy__c);

        }
        
        List<Margin__c> MarginList = [select Id, Product__c, ProductHierarchy__c, City__c, State__c, Country__c 
                                    from Margin__c
                                    where ProductHierarchy__c in :productHierarchyIds
                                    and Product__c in :productIds
                                ];

        Map<String, Margin__c> marginMap = new Map<String, Margin__c>();

        for(Margin__c iMargin : MarginList){
            marginMap.put(MakeKey(iMargin), iMargin);
        }

        for(Margin__c iMargin : records){
            if(marginMap.containsKey(MakeKey(iMargin))){
                iMargin.addError('Margin already exists');
            }
        }



    }



    private static String MakeKey(Margin__c margin){
        return String.valueOf(margin.Product__c) + '-' +
               String.valueOf(margin.ProductHierarchy__c) + '-' +
               String.valueOf(margin.City__c) + '-' +
               String.valueOf(margin.State__c) + '-' +
               String.valueOf(margin.Country__c);
    }

}