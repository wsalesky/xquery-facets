# xquery-facets
Partial facet implementation for eXist-db based on the EXPath specifications (http://expath.org/spec/facet)

Current implementation includes:
* facet:count - Count the facet-values for each facet defined by the facet definition(s)
* facet:group-by - Generates facet values from the original values. Default function if no function is declared in the facet-definition/group-by/@function
* facet:group-by-range - Count the facet-values for each range facet defined by the facet definition. [Custom function]
* facet:group-by-array - Faceting on arrays. Current implementation assumes space as separator. [Custom function]

Uses the following eXist-db specific functions:
* util:eval 
* request:get-parameter
* request:get-parameter-names()

Current tests use https://github.com/srophe/srophe-app-data for data. Advantages to using this data is that it is easily deployed in eXist and has the appropriate indexes already specified. 

##TODO: 
  Support for hierarchical facets
