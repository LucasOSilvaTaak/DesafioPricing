global with sharing class GoalSalesValueBatch implements Database.Batchable<SObject> , Database.Stateful {

    Map<Id, Goal__c> goalsMap = new Map<Id, Goal__c>();
    Map<Id, Decimal> goalSalesValueMap = new Map<Id, Decimal>();

    global Iterable<SObject> start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT Id, ValueAchieved__c, Goal__c
            FROM GoalItem__c
            WHERE Goal__r.Year__c = :Date.today().year()
            ORDER BY Goal__c
        ]);
    }


    global void execute(Database.BatchableContext bc, List<SObject > scope){
        
        Map<Id,GoalItem__c> goalItemsMap = new Map<Id,GoalItem__c>();

        Set<Id> goalIds = new Set<Id>();

        for( SObject iSObject : scope){

            GoalItem__c iGoalItem = (GoalItem__c) iSObject;

            goalItemsMap.put(iGoalItem.Id,iGoalItem);

            goalIds.add(iGoalItem.Goal__c);

        }

        for (Goal__c iGoal : [
            SELECT Id, SalesValue__c
            FROM Goal__c
            WHERE Year__c = :Date.today().year()
            AND Id IN :goalIds
            ORDER BY Seller__c
        ]){
            if(!goalsMap.containsKey(iGoal.Id)){
                goalsMap.put(iGoal.Id,iGoal);
            }
        }
        
        For (GoalItem__c iGoalItem : goalItemsMap.values()){

            if (goalsMap.containsKey(iGoalItem.Goal__c)) {
                goalsMap.get(iGoalItem.Goal__c).SalesValue__c += iGoalItem.ValueAchieved__c;
            }
        }

        Database.update(goalsMap.values(), false);

    }

    global void finish(Database.BatchableContext bc){

    }

}