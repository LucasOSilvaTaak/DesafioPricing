public with sharing class TaxTriggerHelper {
    
    private static Set<String> fields = new Set<String>{
        'State__c',
        'Product__c'
    };
    
    public static void handleInsertTax(List<Tax__c> newList){
     
        verifyDuplicity(newList);

    }

    public static void handleUpdateTax(List<Tax__c> oldList, List<Tax__c> newList){
     
        List<Tax__c> changedRecords = new List<Tax__c>();
     
        for(Integer i = 0; i < newList.size(); i++){
     
            if(!newList[i].equals(oldList[i])) changedRecords.add(newList[i]);
     
        }
     
        if(!changedRecords.isEmpty()) verifyDuplicity(changedRecords);    
    }

    private static void verifyDuplicity(List<Tax__c> records){
     
        Set<String> keys = new Set<String>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> StateIds = new Set<Id>();

        for(Tax__c iTax : records){
     
            String temp = MakeKeys.makeKey(iTax,fields);
     
            if(keys.contains(temp))iTax.addError('Duplicate in batch');
     
            else keys.add(temp);

            if(iTax.Product__c != null) productIds.add(iTax.Product__c);
     
            if(iTax.State__c != null) StateIds.add(iTax.State__c);
        }

        List<Tax__c> TaxList = [
            SELECT Id, Product__c, State__c 
            FROM Tax__c
            WHERE Product__c in :productIds
            AND State__c in :StateIds
        ];
                                

        Map<String, Id> TaxMap = MakeKeys.makeKeyMap(TaxList,fields);

        for(Tax__c iTax : records){
     
            String key = MakeKeys.makeKey(iTax,fields);

            if(TaxMap.containsKey(key)){

                if(TaxMap.get(key) != iTax.Id){
     
                    iTax.addError('Tax already exists');
     
                }

            }
        }
    }
}