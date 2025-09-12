trigger ProductTrigger on Product2 (after insert, after update) {
   
    System.debug('Product Trigger Start => ' + Trigger.operationType);
   
    ProductTriggerHandler handler = new ProductTriggerHandler(
        Trigger.old,
        Trigger.new,
        Trigger.oldMap,
        Trigger.newMap
    );

    if(ProductTriggerHandler.IsTriggerEnabled()){
   
        switch on Trigger.operationType {
   
            when AFTER_INSERT{
   
                handler.afterInsert();
   
            }
   
            When AFTER_UPDATE{
   
                handler.afterUpdate();
   
            }
        }
    }
}