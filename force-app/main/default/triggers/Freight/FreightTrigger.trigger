trigger FreightTrigger on Freight__c (before insert, before Update) {
    System.debug('Order Product Trigger Start => ' + Trigger.operationType);
    FreightTriggerHandler handler = new FreightTriggerHandler(
        Trigger.old,
        Trigger.new,
        Trigger.oldMap,
        Trigger.newMap
    );

    if(FreightTriggerHandler.IsTriggerEnabled()){
        switch on Trigger.operationType {
            when BEFORE_INSERT{
                handler.BeforeInsert();
            }
            when BEFORE_UPDATE{
                handler.BeforeUpdate();
            }
        }
    }
}