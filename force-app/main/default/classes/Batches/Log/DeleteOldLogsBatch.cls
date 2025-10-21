global with sharing class DeleteOldLogsBatch implements Database.Batchable<IntegrationLog__c> {

    global Iterable<IntegrationLog__c> start(Database.BatchableContext bc){

        
        DevParameters_c__mdt maxNumberMonthsOrder = [SELECT Value__c FROM DevParameters_c__mdt WHERE DeveloperName = 'MaxNumberMonthsOrder' limit 1];

        Date maxDate = Date.today().addMonths(- Integer.valueOf(maxNumberMonthsOrder.Value__c));

        return [Select Id from IntegrationLog__c where CreatedDate < :maxDate];
    }

    global void execute(Database.BatchableContext bc, List<IntegrationLog__c > scope){
        delete scope;
    }



   global void finish(Database.BatchableContext bc){

   }
}