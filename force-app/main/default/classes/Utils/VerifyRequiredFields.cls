public with sharing class VerifyRequiredFields {

    public static Set<String> verifyRequiredFields(SObject record, Set<String> fields){

        Set<String> missingFields = new Set<String>();

        Map<String,Object> fieldMap = record.getPopulatedFieldsAsMap();

        for(String field : fields){
            Object value = fieldMap.get(field);

            if(value == null || value == '') missingFields.add(field);
            
        }

        return missingFields;
    }

    
    public static Set<String> getAllExternalIds(String SObjectName){

        String query = 'SELECT ExternalId__c FROM ' + SObjectName;

        List<SObject> results = Database.query(query);
    
        Set<String> externalIds = new Set<String>();

        for(SObject record : results){
            externalIds.add((String)record.get('ExternalId__c'));
        }

        return externalIds;
    
    }

    public static Boolean verifyLookupFields(Set<String> externalIds, String value ){
        
        return externalIds.contains(value);

    }


    
}