public with sharing class GetLoginsToUpdate {

    public static  List<FilledObjects.FilledObject> getDevUserApiValues(List<DevUser__c> devUsersToUpdate){
        
        return executeCallout(devUsersToUpdate);

    }

    @InvocableMethod
    public static void retryUpdateDevUser(List<Id> devUsersToUpdate){
        
        List<FilledObjects.FilledObject> toUpdate = executeCallout([SELECT Id, Login__c FROM DevUser__c WHERE Id IN :devUsersToUpdate]);
        Database.update(FilledObjectServices.getAllSobjects(toUpdate),false);

    }

    private static  List<FilledObjects.FilledObject> executeCallout(List<DevUser__c> devUsersToUpdate){

        List<FilledObjects.FilledObject> filledUserList = new List<FilledObjects.FilledObject>();        
        
        for(DevUser__c iDevUser : devUsersToUpdate){
            
            FilledObjects.FilledObject filledDevUser = new FilledObjects.FilledDevUser();

            HttpResponse response = ExecuteCallout.executeCalloutGet('https://api.github.com/users/' + iDevUser.Login__c);
            
            if(response.getStatusCode() == 200){
                
                System.debug('response body : ' + response.getBody());

                System.debug('response body deserialised : ' + (Wrappers.DevUserWrapper)JSON.deserialize(response.getBody(), Wrappers.DevUserWrapper.class));
                
                filledDevUser.wrapper = (Wrappers.DevUserWrapper)JSON.deserialize(response.getBody(), Wrappers.DevUserWrapper.class);


                filledDevUser.record = (DevUser__c) filledDevUser.wrapper.deserialize();  

                filledDevUser.record.Id = iDevUser.Id;

                filledUserList.add(filledDevUser);
            }
        }

        return filledUserList;
    }

}