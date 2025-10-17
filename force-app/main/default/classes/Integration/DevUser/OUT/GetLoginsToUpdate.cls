public with sharing class GetLoginsToUpdate {

    public static  List<DevUser__c> getValues(List<DevUser__c> devUsersToUpdate){
        
        return executeCallout(devUsersToUpdate);

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
                devUserWrapped = (Wrapper)JSON.deserialize(response.getBody(), Wrapper.class);
                
                devUsers.add(devUserWrapped.deserialise());
            }
            else{
                                hasError = true;
                errorMessage = 'Error: ' + response.getStatusCode();
                
            }
            /*
    
            IntegrationLog.createLog(
                'DevUser', devUserWrapped?.id , 'Outbound', JSON.serialize(request.getBody()),
                JSON.serialize(response.getBody()), endpoint, hasError,
                false, errorMessage
            );
            */
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