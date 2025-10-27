public with sharing class FilledObjectServices {

    private static Map<String, Type> filledObjectsMap = new Map<String, Type>{
        'Order' => FilledObjects.FilledOrder.class,
        'OrderItem' => FilledObjects.FilledItem.class
    };

    public static List<FilledObjects.FilledObject> processRequiredFieldValidation (List<Wrappers.Wrapper> request){
        
        List<FilledObjects.FilledObject> filledList = new List<FilledObjects.FilledObject>();

        String type;

        for (Wrappers.Wrapper iWrapper : request) {
            
            type = type ?? iWrapper.deserialize().getSObjectType().getDescribe().getName();

            FilledObjects.FilledObject filledObject = (FilledObjects.FilledObject) filledObjectsMap.get(type).newInstance();

            SObject deserializedOrder = iWrapper.deserialize();
            
            Set<String> allFields = iWrapper.getRequiredFields();

            Set<String> missingFields = VerifyRequiredFields.verifyRequiredFields(deserializedOrder, allFields);

            if(!missingFields.isEmpty()){

                filledObject.hasError = true;
                filledObject.errorMessage = 'Missing required fields on ' + filledObject.record.getSObjectType().getDescribe().getName() + ' with code "'
                     + iWrapper.getExternalId() + '"  : ' + String.join(new List<String>(missingFields), ', ');
            
            }

            filledObject.wrapper = iWrapper;
            filledObject.record = deserializedOrder;
            filledObject.externalId = iWrapper.getExternalId();

            filledList.add(filledObject);
            
        }

        return filledList;
    }

    public static Boolean verifyHasErrors(List<FilledObjects.FilledObject> objects){
        
        for(FilledObjects.FilledObject iObject : objects){
            if(iObject.hasError){
                return true;
            }
        }

        return false;

    }

    public static List<FilledObjects.FilledObject> processRequiredLookUpsValidation(List<FilledObjects.FilledObject> filledObjectList){

        Wrappers.Wrapper tempWrapper = filledObjectList[0].wrapper;

        String type;

        for (String key : tempWrapper.getRequiredLookups().keySet()) {

            String field = tempWrapper.getRequiredLookups().get(key);

            Set<String> externalIds = VerifyFields.getAllExternalIds(field);

            for (FilledObjects.FilledObject iFilledObjects : filledObjectList) {

                Map<String, Object> wrapperMap = 
                    (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(iFilledObjects.wrapper));

                Object lookupValue = wrapperMap.get(key);

                if (!VerifyFields.verifyLookupFields(externalIds, String.valueOf(lookupValue))) {

                    iFilledObjects.hasError = true;

                    iFilledObjects.errorMessage += ' Invalid lookup field on order with order code "' +
                        iFilledObjects.wrapper.getExternalId() + '" : ' + field + '. ';
                }
            }
        }

        return filledObjectList;
    }

    public static List<FilledObjects.FilledObject> processRequiredsFullValidation(List<Wrappers.Wrapper> wrapperList){
        
        List<FilledObjects.FilledObject> filledList = new List<FilledObjects.FilledObject>();

        filledList = processRequiredFieldValidation(wrapperList);

        filledList = processRequiredLookUpsValidation(filledList);

        return filledList;

    }

    public static List<SObject> getAllSobjects (List<FilledObjects.FilledObject>  filledObjects){

        List<SObject> sobjects = new List<SObject>();


        for(FilledObjects.FilledObject iFilledObject : filledObjects)
            sobjects.add(iFilledObject.record);

        return sobjects;
    }

    public static List<Wrappers.Wrapper> getAllWrappers (List<FilledObjects.FilledObject>  filledObjects){

        List<Wrappers.Wrapper> wrappers = new List<Wrappers.Wrapper>();

        for(FilledObjects.FilledObject iFilledObject : filledObjects)
            wrappers.add(iFilledObject.wrapper);

        return wrappers;
    }

    public static List<String> getAllExternalIds (List<FilledObjects.FilledObject>  filledObjects){

        List<String> externalIds = new List<String>();

        for( FilledObjects.FilledObject iFilledObject : filledObjects)  
            externalIds.add(iFilledObject.externalId);
        

        return externalIds;

    }
}