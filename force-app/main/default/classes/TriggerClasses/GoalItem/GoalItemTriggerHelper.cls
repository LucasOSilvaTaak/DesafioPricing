public with sharing class GoalItemTriggerHelper {

    public static void beforeInsertGoalItem(List<GoalItem__c> newList){
        updateType(newList);
        
    }
    public static void beforeUpdateGoalItem(List<GoalItem__c> oldList, List<GoalItem__c> newList){
        
        updateType(newList);

        cleanOldLookupsInRecordType(oldList, newList);
        
    }

    private static Map<Id, String> recordTypeMap;

    static {
        
        recordTypeMap = new Map<Id, String>();

        Map<String, Schema.RecordTypeInfo> recordTypeInfos = Schema.SObjectType.GoalItem__c.getRecordTypeInfosByDeveloperName();

        if (recordTypeInfos.containsKey('Performance'))
            recordTypeMap.put(recordTypeInfos.get('Performance').getRecordTypeId(), 'Performance');

        if (recordTypeInfos.containsKey('Product2'))
            recordTypeMap.put(recordTypeInfos.get('Product2').getRecordTypeId(), 'Product2');

        if (recordTypeInfos.containsKey('PaymentCondition'))
            recordTypeMap.put(recordTypeInfos.get('PaymentCondition').getRecordTypeId(), 'PaymentCondition');

        if (recordTypeInfos.containsKey('ProductHierarchy'))
            recordTypeMap.put(recordTypeInfos.get('ProductHierarchy').getRecordTypeId(), 'ProductHierarchy');

    }
    

    private static void updateType(List<GoalItem__c> newList){

        for(GoalItem__c iGoalItem : newList)
            iGoalItem.Type__c = recordTypeMap.get(iGoalItem.RecordTypeId);

    }

    private static void cleanOldLookupsInRecordType(List<GoalItem__c> oldList,List<GoalItem__c> newList){

        for (Integer i = 0; i < newList.size(); i++){
            
            if (newList[i].RecordTypeId != oldList[i].RecordTypeId){
                    
                String devName = recordTypeMap.get(newList[i].RecordTypeId);
                
                System.debug('devName: ' + devName);

                switch on devName {
                    when 'Product2' {
                        newList[i].ProductHierarchy__c = null;
                        newList[i].PaymentCondition__c = null;
                    }

                    when 'ProductHierarchy' {
                        newList[i].Product__c = null;
                        newList[i].PaymentCondition__c = null;
                    }
                    when 'Performance' {
                        newList[i].Product__c = null;
                        newList[i].ProductHierarchy__c = null;
                        newList[i].PaymentCondition__c = null;
                    }
                    when 'PaymentCondition' {
                        newList[i].Product__c = null;
                        newList[i].ProductHierarchy__c = null;
                    }
                        
                }
            }
        
        }

    }
}