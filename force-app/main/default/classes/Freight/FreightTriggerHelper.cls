public with sharing class FreightTriggerHelper {
    public static void HandleInsertFreight(List<Freight__c> newList){
        VerifyDuplicity(newList);

    }

    public static void HandleUpdateFreight(List<Freight__c> oldList, List<Freight__c> newList){
        VerifyDuplicity(newList);

    }

    private static void VerifyDuplicity(List<Freight__c> records){
        Set<String> keys = new Set<String>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> productHierarchyIds = new Set<Id>();
        

        for(Freight__c iFreight : records){
            String temp = MakeKey(iFreight);
                        
            if(keys.contains(temp))iFreight.addError('Duplicate in batch');
            else keys.add(temp);

            if(iFreight.Product__c != null) productIds.add(iFreight.Product__c);
            if(iFreight.ProductHierarchy__c != null) productHierarchyIds.add(iFreight.ProductHierarchy__c);
        }

        List<Freight__c> freightList = [select Id, Product__c, ProductHierarchy__c, City__c, State__c, Country__c 
                                    from Freight__c
                                    where ProductHierarchy__c in :productHierarchyIds
                                    and Product__c in :productIds
                                ];

        Map<String, Freight__c> freightMap = new Map<String, Freight__c>();


        for(Freight__c iFreight : freightList){
            freightMap.put(MakeKey(iFreight), iFreight);
        }

        for(Freight__c iFreight : records){
            if(freightMap.containsKey(MakeKey(iFreight))){
                iFreight.addError('Freight already exists');
            }
        }



    }



    private static String MakeKey(Freight__c freight){
        return String.valueOf(freight.Product__c) + '-' +
               String.valueOf(freight.ProductHierarchy__c) + '-' +
               String.valueOf(freight.City__c) + '-' +
               String.valueOf(freight.State__c) + '-' +
               String.valueOf(freight.Country__c);
    }

}