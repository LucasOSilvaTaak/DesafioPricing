public with sharing class WrappersService {

    public static Set<String> getAllExternalIds(List<Wrappers.Wrapper> wrapperList){

        Set<String> externalIds = new Set<String>();

        for(Wrappers.Wrapper iWrapper : wrapperList)
            externalIds.add(iWrapper.getExternalId());

        return externalIds;
    }

}