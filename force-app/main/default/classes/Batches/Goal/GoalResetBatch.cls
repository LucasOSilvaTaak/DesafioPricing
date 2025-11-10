global with sharing class GoalResetBatch implements Database.Batchable<SObject>{

    Map<Id, Goal__c> goalsMap = new Map<Id, Goal__c>();
    Map<Id, Decimal> goalSalesValueMap = new Map<Id, Decimal>();

    global Iterable<SObject> start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT Id, SalesValue__c
            FROM Goal__c
            WHERE Year__c = :Date.today().year()
        ]);
    }


    global void execute(Database.BatchableContext bc, List<SObject > scope){
        
        for( SObject iSObject : scope){

            Goal__c iGoal = (Goal__c) iSObject;

            iGoal.SalesValue__c = 0;
        }

        Database.update(scope, false);


    }

    global void finish(Database.BatchableContext bc){
        Database.executeBatch(new GoalSalesValueBatch(), 200);

    }

}