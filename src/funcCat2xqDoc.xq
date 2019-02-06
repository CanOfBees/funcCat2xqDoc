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
declare variable $ref-doc external := fn:doc("resources/function-catalog.xhtml");

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
	local:rules($nodes/fos:rules) || out:nl() ||
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
 : Serialize a function's rules.
 : @param $nodes as node()*
 : @return xs:string*
 :)
declare %private function local:rules(
	$nodes as node()*
) as xs:string* {
	for $p in $nodes/p
	return(
		' : ' || local:condense-text($p) || out:nl() ||
		' : ' || out:nl()
	)
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
		case element(specref) return local:spec-heading($node)
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

declare %private function local:spec-heading(
	$node as node()*
) as xs:string* {
	(:' [ INSERT HEADING FOR ' || $node/@ref/data() || ']',:)
	(:' [ INSERT HEADING FOR ' || $ref-doc//a[@shape='rect'][fn:contains(@href/data(), $node/@ref/data())]//text()[1] || ']' || out:nl(),:)
	(:for $s in $ref-doc//a[@shape='rect'][fn:contains(@href/data(), $node/@ref/data())]/span[@class]:)
	(:let $s := ($ref-doc//a[@shape='rect'][fn:contains(@href/data(), $node/@ref/data())]/span[@class]):)
	(:
	return(
		(:$s[1]/text() || ' ' || $s[2]/text() || '???',:)
		(:fn:string(count($s)),:)
		(:fn:string-join($s, '<->'):)
		(:fn:string(count($s)),:)
		(:$node/@ref/data():)
		(:'abc':)
	)
	:)
};

for $func in fn:doc($func-doc)//fos:function[@prefix='fn']
order by $func/@name/data() ascending
return(
	(:local:header($func):)
	(:local:rules($func[@name='abs']/fos:rules):)
	local:spec-heading($func[@name='abs']/fos:rules/p[1]/specref)
)