public with sharing class OrderTriggerHelper {

    public static void handleBeforeUpdate(List<Order> oldList, List<Order> newList){
        
        OrderTriggerUseCase.stopAccountChange(oldList, newList);
        
        OrderTriggerUseCase.statusController(oldList, newList);

        OrderTriggerUseCase.updateDiscount(newList);

        
    }
    
    
    public static void handleAfterUpdate(List<Order> oldList, List<Order> newList){
        
        OrderTriggerUseCase.verifyOneItem(newList);

        OrderTriggerUseCase.callApprovation(newList);

        OrderTriggerUseCase.activateCallout(newList);
    
    }







    
}