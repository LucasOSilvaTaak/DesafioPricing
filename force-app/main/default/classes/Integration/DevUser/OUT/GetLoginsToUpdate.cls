public with sharing class GetLoginsToUpdate {

    public static  List<DevUser__c> getDevUserApiValues(List<DevUser__c> devUsersToUpdate){
        
        return executeCallout(devUsersToUpdate);

    }

    @InvocableMethod
    public static  List<DevUser__c> retryUpdateDevUser(List<Id> devUsersToUpdate){
        
        List<DevUser__c> toUpdate = executeCallout([SELECT Id, Login__c FROM DevUser__c WHERE Id IN :devUsersToUpdate]);
        update toUpdate;
        return toUpdate;

    }



    private static  List<DevUser__c> executeCallout(List<DevUser__c> devUsersToUpdate){

        List<DevUser__c> devUsers = new List<DevUser__c>();

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setTimeout(10000);
    
        for(DevUser__c iDevUser : devUsersToUpdate){
            
            Boolean hasError = false;
            Boolean hasDeleted = false;
            String errorMessage = '';
            String endpoint = 'https://api.github.com/users/' + iDevUser.Login__c;
    
            request.setEndpoint(endpoint);
    
            HttpResponse response = http.send(request);
            
            Wrapper devUserWrapped;

            if(response.getStatusCode() == 200){
                System.debug('response body : ' + response.getBody());
                System.debug('response body deserialised : ' + (Wrapper)JSON.deserialize(response.getBody(), Wrapper.class));
                
                devUserWrapped = (Wrapper)JSON.deserialize(response.getBody(), Wrapper.class) ?? new Wrapper(iDevUser.Login__c, iDevUser.Type__c, iDevUser.Bio__c);


                DevUser__c toUpdate = devUserWrapped.deserialise();           
                toUpdate.Id = iDevUser.Id;

                devUsers.add(toUpdate);
            }
            else{
                hasError = true;
                errorMessage = 'Error: ' + response.getStatusCode();
                
            }
        }

        return devUsers;
    }

    private class Wrapper{
        String login;
        String type;
        String bio;
        String Id;

        public Wrapper(String login, String type, String bio){
            this.login = login;
            this.type = type;
            this.bio = bio;
        }

        public DevUser__c deserialise(){
            DevUser__c devUser = new DevUser__c(
                Login__c = login,
                Type__c = type,
                Bio__c = bio,
                ExternalId__c = Id
            );

            return devUser;
        }
    }
}