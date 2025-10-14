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
}