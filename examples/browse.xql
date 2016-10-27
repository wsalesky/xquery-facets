xquery version "3.0";
(:~  
 : Builds browse pages for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists, browse by type, browse by date, map browse. 
 :
 : @see lib/global.xqm for global variables
 : @see lib/paging.xqm for paging functionality
 : @see lib/geojson.xqm for map generation
 : @see browse-spear.xqm for additional SPEAR browse functions 
 :)

declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace facet="http://expath.org/ns/facet" at "../facet.xqm";
declare option exist:serialize "method=html5 media-type=text/html omit-xml-declaration=yes indent=yes";

<html lang="en">
    <head>
        <meta charset="utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title>Sample XQuery Facets</title>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous"/>
        <link rel="stylesheet" href="facet.css"/>
    </head>
    <body>
        <div class="container">
            <h1>Facets POC</h1>

                {
                let $facet-defs := doc('facet-defs.xml')
                let $hits := util:eval(concat("collection('/db/apps/srophe-data/data/persons/tei')//tei:TEI",facet:facet-filter($facet-defs/child::*)))
                return 
                    (<p>Results ({count($hits)})</p>,
                    
                    <div class="row">
                        <div class="col-md-4">
                            {facet:html-list-facets-as-buttons(facet:count($hits, $facet-defs//facet:facet-definition))}
                        </div>
                        <div class="col-md-8">
                            <p>FILTER: {facet:facet-filter($facet-defs/child::*)}</p>
                            {
                                for $hit in subsequence($hits,1,25)
                                let $title := $hit/descendant::tei:title[1]
                                return 
                                    <div style="padding:.5em; border-bottom: 1px solid #eee;">{$title/text()}</div>
                            }
                        </div>
                    </div>    
                    )
                }

            
            <p class="small pull-right">Styles by Bootstrap</p>
        </div>
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>
    </body>
</html>