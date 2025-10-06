public with sharing class OrderTriggerHelper {

    public static void handleBeforeUpdate(List<Order> oldList, List<Order> newList){
        for(Integer i = 0; i < newList.size(); i++){
        
            if(oldList[i].AccountId != newList[i].AccountId) {
        
                newList[i].addError('The Account cannot be changed');
        
            }
        }

    }
    
    public static void handleAfterUpdate(List<Order> oldList, List<Order> newList){
      
        Set<Id> setIds = new Set<Id>();
      
        for(Integer i = 0; i < newList.size(); i++){
            System.debug(newList[i].Status);

            if(newList[i].Status == 'Activated'){
      
                System.debug(newList[i].Status);
      
                setIds.add(newList[i].Id);
      
            }
        }

        if(setIds.size() > 0){
            PrepareCallout.processIntegration(new List<Id>(setIds));
        }
            
    }

        


}
