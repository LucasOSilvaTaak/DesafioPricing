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
        Set<Id> accountIds = new Set<Id>();
        Set<Id> accountGroupIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<Id> countryIds = new Set<Id>();

        //Monta chaves e coleta IDs
        for(Margin__c iMargin : records){
            String temp = MakeKey(iMargin);

            if(keys.contains(temp)){
                iMargin.addError('Duplicate in batch');
            } else {
                keys.add(temp);
            }

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
            select Id, Product__c, ProductHierarchy__c, Account__c, AccountGroup__c,
                   City__c, State__c, Country__c
            from Margin__c
            where (Product__c IN :productIds OR ProductHierarchy__c IN :productHierarchyIds)
              and (Account__c IN :accountIds OR AccountGroup__c IN :accountGroupIds)
              and (City__c IN :cityIds OR State__c IN :stateIds OR Country__c IN :countryIds)
        ];

        Map<String, Margin__c> marginMap = new Map<String, Margin__c>();
        for(Margin__c iMargin : marginList){
            marginMap.put(MakeKey(iMargin), iMargin);
        }

        // 3. Valida duplicidade
        for(Margin__c iMargin : records){
            if(marginMap.containsKey(MakeKey(iMargin))){
                iMargin.addError('Margin already exists');
            }
        }
    }

    private static String MakeKey(Margin__c margin){
        return String.valueOf(margin.Product__c) + '-' +
               String.valueOf(margin.ProductHierarchy__c) + '-' +
               String.valueOf(margin.Account__c) + '-' +
               String.valueOf(margin.AccountGroup__c) + '-' +
               String.valueOf(margin.City__c) + '-' +
               String.valueOf(margin.State__c) + '-' +
               String.valueOf(margin.Country__c);
    }
}
