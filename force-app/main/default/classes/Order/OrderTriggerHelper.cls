public with sharing class OrderTriggerHelper {

    public static void HandleUpdateOrder(List<Order> oldList, List<Order> newList){
        for(Integer i = 0; i < newList.size(); i++){
            if(oldList[i].AccountId != newList[i].AccountId) {
                newList[i].addError('The Account cannot be changed');
            }
        }
    }

}
