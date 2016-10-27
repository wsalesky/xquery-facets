xquery version "3.0";
(:~ 
 : Partial facet implementation for eXist-db based on the EXPath specifications (http://expath.org/spec/facet)
 : 
 : Uses the following eXist-db specific functions:
 :      util:eval 
 :      request:get-parameter
 :      request:get-parameter-names()
 : 
 : @author Winona Salesky
 : @version 1.0 
 :
 : @see http://expath.org/spec/facet   
 : 
 : TODO: 
 :  Support for hierarchical facets
 :)

module namespace facet = "http://expath.org/ns/facet";
import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: External facet parameters :)
declare variable $facet:fq {request:get-parameter('fq', '') cast as xs:string};

(:~
 : Given a result sequence, and a sequence of facet definitions, count the facet-values for each facet defined by the facet definition(s).
 : Accepts one or more facet:facet-definition elements
 : Signiture: 
    facet:count($results as item()*,
        $facet-definitions as element(facet:facet-definition)*) as element(facet:facets)
 : @param $results results node to be faceted on.
 : @param $facet-definitions one or more facet:facet-definition element
:) 
declare function facet:count($results as item()*, $facet-definitions as element(facet:facet-definition)*) as element(facet:facets){
<facets xmlns="http://expath.org/ns/facet">
    {   
    for $facet in $facet-definitions
    return 
    <facet name="{$facet/@name}" show="{$facet/descendant::facet:max-values/@show}" max="{$facet/descendant::facet:max-values/text()}">
        {
        let $max := if($facet/descendant::facet:max-values/text()) then $facet/descendant::facet:max-values/text() else 100
        for $facets at $i in subsequence(facet:facet($results, $facet),1,$max)
        return $facets
        }
    </facet>
    }
</facets>  
};

(:~
 : Given a result sequence, and a facet definition, count the facet-values for each facet defined by the facet definition. 
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
(:  TODO: Handle nested facet-definition  :)
declare function facet:facet($results as item()*, $facet-definitions as element(facet:facet-definition)?) as item()*{
    if($facet-definitions/facet:range) then
        facet:group-by-range($results, $facet-definitions)
    else if ($facet-definitions/facet:group-by/@function) then
        util:eval(concat($facet-definitions/facet:group-by/@function,'($results,$facet-definitions)'))
    else facet:group-by($results, $facet-definitions)
};

(:~
 : Given a result sequence, and a facet definition, count the facet-values for each facet defined by the facet definition. 
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
(: TODO: Need to be able to switch out descending with ascending based on facet-def/order-by/@direction:)
declare function facet:group-by($results as item()*, $facet-definitions as element(facet:facet-definition)?) as element(facet:key)*{
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definitions/facet:order-by
    for $f in util:eval($path)
    group by $facet-grp := $f
    order by 
        if($sort/text() = 'value') then $f[1]
        else count($f)
        descending
    return <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$f[1]}" label="{$f[1]}"/>
};

(:~
 : Faceting on arrays 
 : Assumes space as separator, could add additional param to have dynamic separator. 
 : Syriaca.org uses this for handling multiple values in tei:relation attributes
 : @see 'Literary Connection' in facet-definition
:)
declare function facet:group-by-array($results as item()*, $facet-definitions as element(facet:facet-definition)?){
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text()) 
    let $sort := $facet-definitions/facet:order-by
    let $d := tokenize(string-join(util:eval($path),' '),' ')
    for $f in $d
    group by $facet-grp := tokenize($f,' ')
    order by 
        if($sort/text() = 'value') then $f[1]
        else count($f)
        descending
    return <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$f[1]}" label="{$f[1]}"/>
};


(:~
 : Given a result sequence, and a facet definition, count the facet-values for each range facet defined by the facet definition. 
 : Range values defined by: range and range/bucket elements
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
 : @see 'Date' in facet-definition
:) 
declare function facet:group-by-range($results as item()*, $facet-definitions as element(facet:facet-definition)*) as element(facet:key)*{
    let $ranges := $facet-definitions/facet:range
    let $sort := $facet-definitions/facet:order-by
    for $range in $ranges/facet:bucket
    let $path := concat('$results/',$facet-definitions/descendant::facet:sub-path/text(),'[. gt "', facet:type($range/@gt, $ranges/@type),'" and . lt "',facet:type($range/@lt, $ranges/@type),'"]')
    let $f := util:eval($path)
    order by 
            if($sort/text() = 'value') then $f[1]
            else count($f)
        descending
    return 
         <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{string($range/@name)}" label="{string($range/@name)}"/>
};

(:~
 : Adds type casting when type is specified facet:facet:group-by/@type
 : @param $value of xpath
 : @param $type value of type attribute
:)
declare function facet:type($value as item()*, $type as xs:string?) as item()*{
    if($type != '') then  
        if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:decimal') then xs:decimal($value)
        else if($type = 'xs:integer') then xs:integer($value)
        else if($type = 'xs:long') then xs:long($value)
        else if($type = 'xs:int') then xs:int($value)
        else if($type = 'xs:short') then xs:short($value)
        else if($type = 'xs:byte') then xs:byte($value)
        else if($type = 'xs:float') then xs:float($value)
        else if($type = 'xs:double') then xs:double($value)
        else if($type = 'xs:dateTime') then xs:dateTime($value)
        else if($type = 'xs:date') then xs:date($value)
        else if($type = 'xs:gYearMonth') then xs:gYearMonth($value)        
        else if($type = 'xs:gYear') then xs:gYear($value)
        else if($type = 'xs:gMonthDay') then xs:gMonthDay($value)
        else if($type = 'xs:gMonth') then xs:gMonth($value)        
        else if($type = 'xs:gDay') then xs:gDay($value)
        else if($type = 'xs:duration') then xs:duration($value)        
        else if($type = 'xs:anyURI') then xs:anyURI($value)
        else if($type = 'xs:Name') then xs:Name($value)
        else $value
    else $value
};

(:~
 : XPath filter to be passed to main query
 : creates XPath based on facet:facet-definition//facet:sub-path.
 : @param $facet-def facet:facet-definition element
 : NOTE: need to do type checking here
:)
declare function facet:facet-filter($facet-definitions as node()*)  as item()*{
    if($facet:fq != '') then
        string-join(
        for $facet in tokenize($facet:fq,';fq-')
        let $facet-name := substring-before($facet,':')
        let $facet-value := normalize-space(substring-after($facet,':'))
        return 
            for $facet in $facet-definitions/facet:facet-definition[@name = $facet-name]
            let $path := 
                         if(matches($facet/descendant::facet:sub-path/text(), '^/@')) then concat('descendant::*/',substring($facet/descendant::facet:sub-path/text(),2))
                         else $facet/descendant::facet:sub-path/text()
            return 
            if($facet-value != '') then 
                if($facet/facet:range) then
                    concat('[',$path,'[string(.) gt "', facet:type($facet/facet:range/facet:bucket[@name = $facet-value]/@gt, $facet/facet:range/facet:bucket[@name = $facet-value]/@type),'" and string(.) lt "',facet:type($facet/facet:range/facet:bucket[@name = $facet-value]/@lt, $facet/facet:range/facet:bucket[@name = $facet-value]/@type),'"]]')
                else if($facet/facet:group-by[@function="facet:group-by-array"]) then 
                    concat('[',$path,'[matches(., "',$facet-value,'(\W|$)")]',']')                    
                else concat('[',$path,'[string(.) = "',$facet-value,'"]',']')
            else(),'')    
    else () 
};

(:~ 
 : Builds new facet params for html links.
 : Uses request:get-parameter-names() to get all current params 
 :)
declare function facet:url-params(){
    string-join(
    for $param in request:get-parameter-names()
    return 
        if($param = 'fq') then ()
        else if($param = 'start') then '&amp;start=1'
        else if(request:get-parameter($param, '') = ' ') then ()
        else concat('&amp;',$param, '=',request:get-parameter($param, '')),'')
};

(: HTML display functions :)

(:~
 : Create 'Remove' button 
 : Constructs new URL for user action 'remove facet'
:)
declare function facet:selected-facets-display(){
    for $facet in tokenize($facet:fq,';fq-')
    let $value := substring-after($facet,':')
    let $new-fq := string-join(
                    for $facet-param in tokenize($facet:fq,';fq-') 
                    return 
                        if($facet-param = $facet) then ()
                        else concat(';fq-',$facet-param),'')
    let $href := if($new-fq != '') then concat('?fq=',replace(replace($new-fq,';fq- ',''),';fq-;fq-',';fq-'),facet:url-params()) else ()
    return 
        if($facet != '') then 
            <span class="label label-facet" title="Remove {$value}">
                {$value} <a href="{$href}" class="facet icon"> x</a>
            </span>
        else()
};


(:~
 : Create 'Add' button 
 : Constructs new URL for user action 'Add facet'
:)
declare function facet:html-list-facets-as-buttons($facets as node()*){
(
for $facet in tokenize($facet:fq,';fq-')
let $facet-name := substring-before($facet,':')
let $new-fq := string-join(
                for $facet-param in tokenize($facet:fq,';fq-') 
                return 
                    if($facet-param = $facet) then ()
                    else concat(';fq-',$facet-param),'')
let $href := if($new-fq != '') then concat('?fq=',replace(replace($new-fq,';fq- ',''),';fq-;fq-',';fq-'),facet:url-params()) else ()
return
    if($facet != '') then
        for $f in $facets/facet:facet[@name = $facet-name]
        let $fn := string($f/@name)
        let $label := string($f/facet:key[@value = substring-after($facet,concat($facet-name,':'))]/@label)
        return 
                <span class="btn btn-default" title="Remove {$label}">
                    {concat($fn,': ', $label)} <a href="{$href}" class="facet icon"> x</a>
                </span>
    else(),
for $f in $facets/facet:facet
let $count := count($f/facet:key)
return 
    if($count gt 0) then 
    <div class="facet-grp">
        <h4>{string($f/@name)}</h4>
            <div class="facet-list show">{
                for $key at $l in subsequence($f/facet:key,1,$f/@show)
                let $facet-query := replace(replace(concat(';fq-',string($f/@name),':',string($key/@value)),';fq-;fq-;',';fq-'),';fq- ','')
                let $new-fq := 
                    if($facet:fq) then concat('fq=',$facet:fq,$facet-query)
                    else concat('fq=',normalize-space($facet-query))
                let $active := if(contains($facet:fq,concat(';fq-',string($f/@name),':',string($key/@value)))) then 'active' else ()    
                return <a href="?{$new-fq}{facet:url-params()}" class="facet-label btn btn-default {$active}">{string($key/@label)} <span class="count"> ({string($key/@count)})</span></a> 
                }
            </div>
            <div class="facet-list collapse" id="{concat('show',replace(string($f/@name),' ',''))}">{
                for $key at $l in subsequence($f/facet:key,$f/@show + 1,$f/@max)
                let $facet-query := replace(replace(concat(';fq-',string($f/@name),':',string($key/@value)),';fq-;fq-;',';fq-'),';fq- ','')
                let $new-fq := 
                    if($facet:fq) then concat('fq=',$facet:fq,$facet-query)
                    else concat('fq=',$facet-query)
                return <a href="?{$new-fq}{facet:url-params()}" class="facet-label btn btn-default">{string($key/@label)} <span class="count"> ({string($key/@count)})</span></a>
                }
            </div>
            {if($count gt ($f/@show - 1)) then 
                <a class="facet-label togglelink btn btn-info" 
                data-toggle="collapse" data-target="#{concat('show',replace(string($f/@name),' ',''))}" href="#{concat('show',replace(string($f/@name),' ',''))}" 
                data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
            else()}
    </div>
    else()
)    
};