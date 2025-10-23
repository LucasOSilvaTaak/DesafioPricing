public with sharing class GetIdsFromList {

    public static Set<Id> getSObjectIds(List<SObject> SObjectList){

        Set<Id> idSet = new Set<Id>();

        for(SObject iSObject : SObjectList){
                
            idSet.add(iSObject.Id);  
            
        }

        return idSet;
    }
}