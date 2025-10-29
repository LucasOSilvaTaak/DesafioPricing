global with sharing class DevUserInsertBatch implements Database.Batchable<DevUser__c>, Database.AllowsCallouts {

   private Set<String> logins;
   private List<DevUser__c> toUpdate;

   global DevUserInsertBatch(Set<String> logins){
      this.logins = logins;
   }

   global Iterable<DevUser__c> start(Database.BatchableContext bc){
      return [SELECT Id, Login__c FROM DevUser__c WHERE Login__c  IN :logins];
   }
    

   global void execute(Database.BatchableContext bc, List<DevUser__c> scope){
      
      Map<String, DevUser__c> devUserMap = new Map<String, DevUser__c>();

      List<DevUser__c> toUpdate = GetLoginsToUpdate.getDevUserApiValues(scope);

      if(toUpdate.size() > 0){

         Database.update(toUpdate, false);

      }
      
   }

   global void finish(Database.BatchableContext bc){

   }
    

}