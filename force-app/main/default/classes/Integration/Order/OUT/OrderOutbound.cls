global with sharing class DevUserInsertBatch implements Database.Batchable<DevUser__c>, Database.AllowsCallouts {

    private Set<String> logins;
    private List<DevUser__c> toUpdate = new List<DevUser__c>();

    global DevUserInsertBatch(Set<String> logins){
        this.logins = logins;
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, Login__c FROM DevUser__c WHERE Login__c IN :logins]);
    }

    global void execute(Database.BatchableContext bc, List<DevUser__c> scope){
        List<DevUser__c> updatedUsers = GetLoginsToUpdate.getValues(scope);

        toUpdate.addAll(updatedUsers);
    }

    global void finish(Database.BatchableContext bc){
        if(!toUpdate.isEmpty()){

            System.enqueueJob(new DevUserUpdateAfterCalloutQueueable(toUpdate));
            
        }
    }
}
