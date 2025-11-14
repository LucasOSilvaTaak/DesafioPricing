public with sharing class GoalItemTriggerHelper {

    public static void beforeInsertGoalItem(List<GoalItem__c> newList){

        setFieldType(newList);
        
        verifyRepeted(newList);
        
    }
    public static void beforeUpdateGoalItem(List<GoalItem__c> oldList, List<GoalItem__c> newList){
        
        cleanOldLookupsInRecordType(oldList, newList);
        
        setFieldType(newList);
        
        verifyRepeted(newList);

        
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
    

    private static void setFieldType(List<GoalItem__c> newList){

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

    private static void verifyRepeted(List<GoalItem__c> newList){

        Set<Id> newListIds = new Set<Id>();
        Set<Id> newListProducts = new Set<Id>();
        Set<Id> newListPaymentConditions = new Set<Id>();
        Set<Id> newListProductHierarchy = new Set<Id>();
        Set<Integer> newListYears = new Set<Integer>();
        Set<Id> newListGoals = new Set<Id>();
        Set<Id> newListRecordType = new Set<Id>();

        Set<String> fields = new Set<String>{
            'Product__c', 
            'ProductHierarchy__c', 
            'PaymentCondition__c',
            'Goal__c',
            'RecordTypeId'
        };

        for(GoalItem__c iGoalItem : newList){

            newListIds.add(iGoalItem.Id);
            newListGoals.add(iGoalItem.Goal__c);


            if (iGoalItem.Product__c != null)
                newListProducts.add(iGoalItem.Product__c);

            if (iGoalItem.ProductHierarchy__c != null)
                newListProductHierarchy.add(iGoalItem.ProductHierarchy__c);

            if (iGoalItem.PaymentCondition__c != null)
                newListPaymentConditions.add(iGoalItem.PaymentCondition__c);

            if (iGoalItem.RecordTypeId != null)
                newListRecordType.add(iGoalItem.RecordTypeId);

        }

        List<GoalItem__c> toCompareList = [
            Select 
                Id, 
                Name, 
                Product__c, 
                ProductHierarchy__c, 
                PaymentCondition__c,
                Goal__c,
                RecordTypeId
            From GoalItem__c
            Where (Product__c IN :newListProducts
            OR ProductHierarchy__c IN :newListProductHierarchy
            OR PaymentCondition__c IN :newListPaymentConditions 
            OR  RecordType.DeveloperName = 'Performance')
            AND Goal__c IN :newListGoals
            AND RecordTypeId IN :newListRecordType
        ];
        
        Map<String,Id> toCompareKeys = MakeKeys.makeKeyMap(toCompareList, fields);


        for(GoalItem__c iGoalItem : newList){
            
            String key = MakeKeys.makeKey(iGoalItem, fields);

            if (toCompareKeys.containsKey(key) && toCompareKeys.get(key) != iGoalItem.Id)
                iGoalItem.addError('This Goal Item already exists');
            
            System.debug(
                'key: ' + key + 
                ' toCompareKeys: ' + toCompareKeys
            );

        }


    }
}