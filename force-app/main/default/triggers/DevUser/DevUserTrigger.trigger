trigger DevUserTrigger on DevUser__c (after insert) {
     
    System.debug('DevUser Trigger Start => ' + Trigger.operationType);
    
    DevUserTriggerHandler handler = new DevUserTriggerHandler(
        Trigger.old,
        Trigger.new,
        Trigger.oldMap,
        Trigger.newMap
    );

    if(DevUserTriggerHandler.isTriggerEnabled()){
        
        switch on Trigger.operationType {
        
            when AFTER_INSERT{
        
                handler.afterInsert();
        
            }
        }
    }
}