global with sharing class DeleteOldOrdersBatch implements Database.Batchable<Order> {

    global Iterable<Order> start(Database.BatchableContext bc){

        
        DevParameters_c__mdt maxNumberMonthsOrder = [SELECT Value__c FROM DevParameters_c__mdt WHERE DeveloperName = 'MaxNumberMonthsOrder' limit 1];

        Date maxDate = Date.today().addMonths(-Integer.valueOf(maxNumberMonthsOrder.Value__c));

        return [Select Id from Order where CreatedDate < :maxDate];
    }

    global void execute(Database.BatchableContext bc, List<Order> scope){
        delete scope;
    }



   global void finish(Database.BatchableContext bc){

   }
}