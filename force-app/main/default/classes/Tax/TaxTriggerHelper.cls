public with sharing class TaxTriggerHelper {
    public static void HandleInsertTax(List<Tax__c> newList){
        VerifyDuplicity(newList);

    }

    public static void HandleUpdateTax(List<Tax__c> oldList, List<Tax__c> newList){
        VerifyDuplicity(newList);
        System.debug('Houve update');

    }

    private static void VerifyDuplicity(List<Tax__c> records){
        Set<String> keys = new Set<String>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> productionCenterIds = new Set<Id>();
        Set<Id> StateIds = new Set<Id>();

        for(Tax__c iTax : records){
            String temp = MakeKey(iTax);
            if(keys.contains(temp))iTax.addError('Duplicate in batch');
            else keys.add(temp);

            if(iTax.Product__c != null) productIds.add(iTax.Product__c);
            if(iTax.ProductionCenter__c != null) productionCenterIds.add(iTax.ProductionCenter__c);
            if(iTax.State__c != null) StateIds.add(iTax.State__c);
        }

        List<Tax__c> TaxList = [select Id, Product__c, ProductionCenter__c, State__c 
                                    from Tax__c
                                    where ProductionCenter__c in :productionCenterIds
                                    and Product__c in :productIds
                                    and State__c in :StateIds
                                ];
                                

        Map<String, Tax__c> TaxMap = new Map<String, Tax__c>();
        for(Tax__c iTax : TaxList){
            TaxMap.put(MakeKey(iTax), iTax);
        }

        for(Tax__c iTax : records){
            if(TaxMap.containsKey(MakeKey(iTax))){
                iTax.addError('Tax already exists');
            }
        }



    }



    private static String MakeKey(Tax__c tax){
        return String.valueOf(tax.Product__c) + '-' +
               String.valueOf(tax.ProductionCenter__c) + '-' +
               String.valueOf(tax.State__c);
    }
}