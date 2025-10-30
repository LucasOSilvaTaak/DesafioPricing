public with sharing class PokemonQueue implements Queueable, Finalizer, Database.AllowsCallouts{

    private Integer offset;
    private Integer limitSearch;
    private Boolean endSearch = false;


    public PokemonQueue(Integer offset, Integer limitSearch){
        this.offset = offset;
        this.limitSearch = limitSearch;
    }

    private List<Pokemon__c> weGotatCacthThemAllweGottaCatchEmAll(Integer offset, Integer limitSearch){

        List<FilledObjects.FilledObject> filledPokemonList = PokemonApiGet.PokemonApiGet(offset, limitSearch);

        return FilledObjectServices.getAllSobjects(filledPokemonList);
    }


    public void execute(QueueableContext context){
        System.attachFinalizer(this);

        List<Pokemon__c> pokemonList = weGotatCacthThemAllweGottaCatchEmAll(offset, 50);

        Database.insert(pokemonList, false);

        endSearch = pokemonList.isEmpty();


    }

    public void execute(FinalizerContext context){
        System.debug('Chegou no finalizer');
        if(endSearch){
            System.debug('No more pokemon to catch');
            return;
        }

        else{
            offset += 50;
            System.enqueueJob(new PokemonQueue(offset, limitSearch));

        }
    }


}
