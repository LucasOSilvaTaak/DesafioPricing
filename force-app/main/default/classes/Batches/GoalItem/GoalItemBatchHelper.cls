public with sharing class GoalItemBatchHelper {

    
    public static Map<Id,GoalItem__c> getGoalItems(Set<id> sallers, Map<Id,GoalItem__c> goalItems){
        
        Set<Id> goalIds = new Set<Id>();
        
        for (Goal__c g : [
            SELECT Id
            FROM Goal__c
            WHERE OwnerId IN :sallers 
            AND Year__c = :Date.today().year()
        ]) {
            goalIds.add(g.Id);
        }
                
        for(GoalItem__c iGoalItem : [
            SELECT Id, recordTypeId, Type__c, Goal__c, Goal__r.Seller__c,
                Product__c, ProductHierarchy__c, PaymentCondition__c,
                ValueAchieved__c, NegotiatedValue__c, ProjectedValue__c
            FROM GoalItem__c 
            WHERE Goal__c IN :goalIds
        ]) {
            if (!goalItems.containsKey(iGoalItem.Id)) {
                goalItems.put(iGoalItem.Id, iGoalItem);
            }
        }

        return goalItems;
    }
}