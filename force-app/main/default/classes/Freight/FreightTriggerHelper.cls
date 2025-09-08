public with sharing class FreightTriggerHelper {
    public static void HandleInsertFreight(List<Freight__c> newList){
        VerifyDuplicity(newList);
    }

    public static void HandleUpdateFreight(List<Freight__c> oldList, List<Freight__c> newList){
        List<Freight__c> changedRecords = new List<Freight__c>();
        for(Integer i = 0; i < newList.size(); i++){
            if(!newList[i].equals(oldList[i])) changedRecords.add(newList[i]);
        }
        if(!changedRecords.isEmpty()) VerifyDuplicity(newList);

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
            String temp = MakeKeys.makeKey(iFreight);

            if(keys.contains(temp)) iFreight.addError('Freight already exists');
            

            else keys.add(temp);


            if(iFreight.Product__c != null) productIds.add(iFreight.Product__c);
            if(iFreight.ProductHierarchy__c != null) productHierarchyIds.add(iFreight.ProductHierarchy__c);
            if(iFreight.City__c != null) cityIds.add(iFreight.City__c);
            if(iFreight.State__c != null) stateIds.add(iFreight.State__c);
            if(iFreight.Country__c != null) countryIds.add(iFreight.Country__c);
        }

        // Busca fretes já existentes no banco
        List<Freight__c> freightList = [
            SELECT Id, Product__c, ProductHierarchy__c, City__c, State__c, Country__c
            FROM Freight__c
            WHERE (Product__c IN :productIds OR ProductHierarchy__c IN :productHierarchyIds)
            AND (City__c IN :cityIds OR State__c IN :stateIds OR Country__c IN :countryIds)
        ];

        Map<String, Id> freightMap = MakeKeys.makeKeyMap(freightList);

        // Valida duplicidade
        for(Freight__c iFreight : records){
            string key = MakeKeys.makeKey(iFreight);
            if(freightMap.containsKey(key) && freightMap.get(key) != iFreight.Id){
                iFreight.addError('Freight already exists');
            }
        }
    }


}
