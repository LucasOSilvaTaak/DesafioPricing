public with sharing class PokemonApiGet {
    
    public static List<FilledObjects.FilledObject> PokemonApiGet(Integer offset, Integer limitSearch) {

        List<FilledObjects.FilledObject> filledPokemonList = executeCallout(offset, limitSearch);
        System.debug('filledPokemonList: ' + filledPokemonList);
        return filledPokemonList;
    }

    private class ResultsWrapper{
        
        public List<Wrappers.PokemonWrapper> results = new List<Wrappers.PokemonWrapper>();

    }

    private static List<FilledObjects.FilledObject> executeCallout(Integer offset, Integer limitSearch) {

        List<FilledObjects.FilledObject> filledPokemonList = new List<FilledObjects.FilledObject>();

        string endpoint = 'https://pokeapi.co/api/v2/pokemon?' + 'offset=' + offset + '&limit=' + limitSearch;

        HttpResponse response = ExecuteCallout.executeCalloutGet(endpoint);

        System.debug(response);

        Boolean hasError = false;
        String errorMessage = '';

        if(response.getStatusCode() == 200){
            
            ResultsWrapper resultWrapper = (ResultsWrapper)JSON.deserialize(response.getBody(), ResultsWrapper.class);
                
            filledPokemonList = FilledObjectServices.processRequiredFieldValidation(resultWrapper.results);
   
        }

        else hasError = true;
        

        hasError = !hasError ? FilledObjectServices.verifyHasErrors(filledPokemonList) : hasError;
        errorMessage = hasError ? 'The response status code is ' + response.getStatusCode() + ' and the body is ' + response.getBody() : errorMessage;

        IntegrationLogsBuilder.LogBuilder logBuilder = new IntegrationLogsBuilder.LogBuilder();
        logBuilder.setEndpoint(endpoint)
            .setPayloadIN('')
            .setPayloadOUT(response.getBody())
            .setHasAnyErrors(hasError)
            .setIntegrationName('Outbound', 'Pokemon')
            .setErrorMessage(errorMessage)
            .insertBuild();

        return filledPokemonList;


    }

}