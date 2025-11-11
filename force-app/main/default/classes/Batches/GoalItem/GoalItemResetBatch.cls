global with sharing class GoalItemResetBatch implements Database.Batchable<SObject>{

    global Iterable<SObject> start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT Id
            FROM GoalItem__c
            WHERE Goal__r.Year__c = :Date.today().year()
            ORDER BY Goal__r.Seller__c
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject > scope){
    
        for( SObject iSObject : scope){

            GoalItem__c iGoalItem = (GoalItem__c) iSObject;

            iGoalItem.ValueAchieved__c = 0;
            iGoalItem.NegotiatedValue__c = 0;
            iGoalItem.ProjectedValue__c = 0;

        }

        update scope;
    }


    global void finish(Database.BatchableContext bc){
        Database.executeBatch(new GoalsOrderBatch(), 200);
        Database.executeBatch(new GoalOpportunityBatch(), 200);

    }


}