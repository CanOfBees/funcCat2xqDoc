xquery version "3.1" encoding "UTF-8";

(:~
 : Parse function doc blocks from the w3.org function-catalog.xml
 : @see https://www.w3.org/TR/2017/REC-xpath-functions-31-20170321/function-catalog.xml
 :
 : Written using BaseX-specific output functions.
 :
 : @author Bridger Dyson-Smith
 : @version 0.1.0
 :)

(:~
 :
 : TODO trim string length to ~n~ characters
 : TODO verify namespace prefixes
 :
 :)

(: namespaces and variables :)
import module namespace functx = "http://www.functx.com";
declare namespace fos = "http://www.w3.org/xpath-functions/spec/namespace";
declare variable $func-doc external := "resources/function-catalog.xml";

(:~
 : Serialize the xqDoc doc block
 : @param $xml as node()*
 : @return xs:string*
 :)
declare %private function local:header(
	$nodes as node()*
) as xs:string* {
	'(:~ ' || out:nl() ||
	' : ' || local:summary($nodes/fos:summary) || out:nl() ||
	' : ' || out:nl() ||
	' :)' || out:nl()
};

(:~
 : Serialize a function's summary.
 : @param $nodes as node()*
 : @return xs:string*
 :)
declare %private function local:summary(
 $nodes as node()*
) as xs:string* {
	local:condense-text($nodes)
};

(:~
 : Try to automatically correct whitespace issues.
 : @param $nodes as node()*
 : @return xs:string*
 :)
declare %private function local:condense-text(
	$nodes as node()*
) as xs:string* {
	fn:normalize-space(fn:string-join(local:extract-text($nodes)))
};

(:~
 : Select text() nodes from a sub-tree
 : @param $nodes as node()*
 : @return xs:string*
 :)
declare %private function local:extract-text(
	$nodes as node()*
) as xs:string* {
	for $node in $nodes
	return typeswitch($node)
		case text() return local:munge-text($node)
		default return local:extract-text($node/node())
};

(:~
 : Whitespace helper function; i.e. trying to address ' .' or ' ,'
 : @param $text as item()*
 : @return xs:string*
 :)
declare %private function local:munge-text(
	$text as item()*
) as xs:string* {
	for $t in $text
	return(
		if (fn:matches($t, '\p{P}'))
		then (fn:normalize-space($t))
		else ("  " || $t || "  ")
	)
};

for $func in fn:doc($func-doc)//fos:function[@prefix='fn']
order by $func/@name/data() ascending
return(
	local:header($func)
)