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
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<Id> countryIds = new Set<Id>();

        //Monta chaves e coleta IDs
        for(Freight__c iFreight : records){
            String temp = MakeKey(iFreight);

            if(keys.contains(temp)){
                iFreight.addError('Duplicate in batch');
            } else {
                keys.add(temp);
            }

            if(iFreight.Product__c != null) productIds.add(iFreight.Product__c);
            if(iFreight.ProductHierarchy__c != null) productHierarchyIds.add(iFreight.ProductHierarchy__c);
            if(iFreight.City__c != null) cityIds.add(iFreight.City__c);
            if(iFreight.State__c != null) stateIds.add(iFreight.State__c);
            if(iFreight.Country__c != null) countryIds.add(iFreight.Country__c);
        }

        // Busca fretes já existentes no banco
        List<Freight__c> freightList = [
            select Id, Product__c, ProductHierarchy__c, City__c, State__c, Country__c
            from Freight__c
            where (Product__c IN :productIds OR ProductHierarchy__c IN :productHierarchyIds)
            and (City__c IN :cityIds OR State__c IN :stateIds OR Country__c IN :countryIds)
        ];

        Map<String, Freight__c> freightMap = new Map<String, Freight__c>();
        for(Freight__c iFreight : freightList){
            freightMap.put(MakeKey(iFreight), iFreight);
        }

        // Valida duplicidade
        for(Freight__c iFreight : records){
            if(freightMap.containsKey(MakeKey(iFreight)) && freightMap.get(MakeKey(iFreight)).Id != iFreight.Id){
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
