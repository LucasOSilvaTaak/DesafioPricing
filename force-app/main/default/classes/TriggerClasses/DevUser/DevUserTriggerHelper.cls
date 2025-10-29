public with sharing class DevUserTriggerHelper {
    public static void handleAfterInsert(List<DevUser__c> newRecordList){
        
        updateValuesBatch(newRecordList);

    }

    private static void updateValuesBatch(List<DevUser__c> devUsersToUpdate){
        Set<String> logins = new Set<String>();

        for(DevUser__c devUser : devUsersToUpdate){
            logins.add(devUser.Login__c);
        }

        Database.executeBatch(new DevUserInsertBatch(logins), 100);
        
    }
}