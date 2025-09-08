public with sharing class MarginTriggerHelper {
    public static void handleInsertMargin(List<Margin__c> newList){
        verifyDuplicity(newList);
    }

    public static void handleUpdateMargin(List<Margin__c> oldList, List<Margin__c> newList){
        List<Margin__c> changedRecords = new List<Margin__c>();
        for(Integer i = 0; i < newList.size(); i++){
            if(!newList[i].equals(oldList[i])) changedRecords.add(newList[i]);
        }
        if(!changedRecords.isEmpty()) verifyDuplicity(changedRecords);    
    }

    private static void verifyDuplicity(List<Margin__c> records){
        Set<String> keys = new Set<String>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> productHierarchyIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> accountGroupIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<Id> countryIds = new Set<Id>();

        //Monta chaves e coleta IDs
        for(Margin__c iMargin : records){
            String temp = MakeKeys.makeKey(iMargin);

            if(keys.contains(temp)) iMargin.addError('Duplicate in batch');
            else keys.add(temp);
            

            if(iMargin.Product__c != null) productIds.add(iMargin.Product__c);
            if(iMargin.ProductHierarchy__c != null) productHierarchyIds.add(iMargin.ProductHierarchy__c);
            if(iMargin.Account__c != null) accountIds.add(iMargin.Account__c);
            if(iMargin.AccountGroup__c != null) accountGroupIds.add(iMargin.AccountGroup__c);
            if(iMargin.City__c != null) cityIds.add(iMargin.City__c);
            if(iMargin.State__c != null) stateIds.add(iMargin.State__c);
            if(iMargin.Country__c != null) countryIds.add(iMargin.Country__c);
        }

        //Busca margens já existentes no banco
        List<Margin__c> marginList = [
            SELECT Id, Product__c, ProductHierarchy__c, Account__c, AccountGroup__c,
                   City__c, State__c, Country__c
            FROM Margin__c
            WHERE (Product__c IN :productIds OR ProductHierarchy__c IN :productHierarchyIds)
            AND (Account__c IN :accountIds OR AccountGroup__c IN :accountGroupIds)
            AND (City__c IN :cityIds OR State__c IN :stateIds OR Country__c IN :countryIds)
        ];

        Map<String, Id> marginMap = MakeKeys.makeKeyMap(marginList);


        //Valida duplicidade
        for(Margin__c iMargin : records){
            string key = MakeKeys.makeKey(iMargin);


            if(marginMap.containsKey(key) && marginMap.get(key) != iMargin.Id){
                iMargin.addError('Margin already exists');
            }
        }
    }


}
