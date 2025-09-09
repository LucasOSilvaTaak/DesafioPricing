//CLASSE QUE CRIA CHAVES UNICAS COM BASE NOS CAMPOS
public with sharing class MakeKeys {

    //CRIA UMA CHAVE UNICA COM BASE NOS CAMPOS INFORMADOS
    public static String makeKey(SObject record, Set<String> fields){
        
        String key = '';

        Map<String,Object> fieldaMap = record.getPopulatedFieldsAsMap();

        for(String iString : fields){

            string value = String.valueOf(fieldaMap.get(iString));

            if(fields.contains(iString)){

                key += (value == null) ? '' : (value + '-');

            }
            

        }

        if(key.endsWith('-')){

            key = key.substring(0, key.length() - 1);

        }

        return key;
    }

    //GERA UMA MAPA DE CHAVES UNICAS COM BASE NOS CAMPOS INFORMADOS A PARTIR DE UMA LISTA DE REGISTROS
    public static Map<String,Id> makeKeyMap(List<SObject> records,  Set<String> fields){

        Map<String,Id> keyMap = new Map<String,Id>();
        
        for(SObject iRecord : records){
        
            keyMap.put(makeKey(iRecord,fields), iRecord.Id);
        
        }
        
        return keyMap;
    }


}