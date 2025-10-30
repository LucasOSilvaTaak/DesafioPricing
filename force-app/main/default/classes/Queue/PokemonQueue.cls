public with sharing class PokemonQueue implements Queueable, Finalizer, Database.AllowsCallouts{

    private Integer offset;
    private Integer limitSearch = 20;
    private Boolean endSearch = false;


    public PokemonQueue(Integer offset){
        this.offset = offset;
    }

    private List<Pokemon__c> weGottaCacthThemAll(Integer offset){

        List<FilledObjects.FilledObject> filledPokemonList = PokemonApiGet.PokemonApiGet(offset, limitSearch);

        return FilledObjectServices.getAllSobjects(filledPokemonList);
    }


    public void execute(QueueableContext context){
        System.attachFinalizer(this);

        List<Pokemon__c> pokemonList = weGottaCacthThemAll(offset);

        if(!pokemonList.isEmpty()) Database.insert(pokemonList, false);

        
        else endSearch = true;



    }

    public void execute(FinalizerContext context){
        System.debug('Chegou no finalizer');
        if(endSearch){
            System.debug('No more pokemon to catch');
            return;
        }

        else{
            offset += limitSearch;
            System.enqueueJob(new PokemonQueue(offset));

        }
    }


}
