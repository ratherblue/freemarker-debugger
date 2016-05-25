<#ftl strip_text=true />

<#---
  @homepage    https://github.com/ratherblue/freemarker-debugger/
  @license     MIT
  @version     1.0

  @name        freemarker-debugger
  @description Macros and functions used to generate a tabular view of the .locals, .main, and .data model.

  @see				 http://freemarker.org/docs/ref_specvar.html

  @namespace   debugger

  Default usage (expands the top-level properties from .data_model):

    <#import "debugger.ftl" as debugger />

    <@debugger.debug />

  More examples:

    Expands first and second-level properties for the .locals (local variables and macro parameters)
    <@debugger.debug debugObject=.locals depth=2 />


    <@debugger.debugDynamic debugObject=.locals depth=2 />


-->


<#---
  Settings for the debugger
-->
<#assign settings = {
  "styleClassPrefix": "freemarker-debug",
  "queryParamKey":    "debugQuery",
  "includeStyles":    true,
  "ignoredKeys":      ["class"], <#-- Ignore keys that exactly match these values. Case-sensitive -->
  "ignoredPatterns":  ["org.springframework."] <#-- Ignore keys that start with these values. Case-sensitive -->
} />


<#---
  Value of parameter used when dynamically expanding objects through links
-->
<#assign debugQuery = (RequestParameters[settings.queryParamKey]!'')?trim />


<#---
  @param debugObject	Object to expand
  @param depth	How deep to expand the object
-->
<#macro debug debugObject=.data_model depth=1>

  <#-- include optional table styling -->
  <#if settings.includeStyles>
    <@tableStyles />
  </#if>

  <#local title = varClass(debugObject) />

  <div class="${settings.styleClassPrefix}-wrapper">
    <@debugTable
        debugObject=debugObject
        depth=depth
        title=title!'' />
  </div>
</#macro>


<#---
  Shortcut for enabling links on expandable objects

  @param depth
-->
<#macro debugDynamic depth=1>

  <#-- include optional table styling -->
  <#if settings.includeStyles>
    <@tableStyles />
  </#if>

  <div class="${settings.styleClassPrefix}-wrapper">
    <#if debugQuery?has_content>

      <#local root = getDebugRoot(debugQuery) />
      <#local debugObject = debugObjectFromUrl(root.object, debugQuery) />

      <#if debugObject?is_number && debugObject == -1>
        <div class="${settings.styleClassPrefix}-error">
          <strong>Error:</strong> Unable to parse ${debugQuery?xhtml}
        </div>
      <#else>
        <@debugTable
            debugObject=debugObject
            depth=depth
            dynamic=true
            title=getTitleLink(debugQuery) />
      </#if>
    <#else>
      <@debugTable
          debugObject=.data_model
          depth=depth
          dynamic=true
          title=[{"title": ".data_model", "url": ""}]
          queryParam=".data_model" />
    </#if>
  </div>
</#macro>


<#---
  Prints out expandable objects (hash_ex, sequences) in tabular form
  @param debugObject	Object to expand
  @param depth	How deep to expand the object
  @param dynamic	Boolean to make expandable objects a link to quickly drill-down into data
  @param queryParam Parameter used in query string for direct debugging
  @param title Title of the section
-->
<#macro debugTable debugObject depth dynamic=false queryParam="" title="">

  <#if isComplexObject(debugObject)>
    <@tableWrapper title=title titleUrl=getDebugUrl(queryParam)>
      <#if debugObject?is_hash_ex>
        <#list debugObject?keys?sort as key>
          <@properties
              key=key
              value=(debugObject[key])!""
              depth=depth
              dynamic=dynamic
              queryParam=buildQueryParam(key, queryParam, dynamic) />
        </#list>
      <#elseif debugObject?is_sequence>
        <#list debugObject as obj>
          <@properties
              key=obj_index
              value=obj!""
              depth=depth
              dynamic=dynamic
              queryParam=buildQueryParam(obj_index, queryParam, dynamic) />
        </#list>
      </#if>
    </@tableWrapper>
  <#else>
    <@simpleValue value=debugObject />
  </#if>

</#macro>


<#---
  Basic styles for the debug table
  @param classPrefix Customizable class prefix used to give basic styles to the debug table.
-->
<#macro tableStyles classPrefix=settings.styleClassPrefix>
  <#compress>
    <style type="text/css">
      .${classPrefix}-wrapper {
        color: #000;
        background-color: #FFF; <#-- ensure that regardless of styles the content is visible -->
        padding: 10px;
      }

      .${classPrefix}-wrapper a {
        color: #00F;
        text-decoration: none;
      }

      .${classPrefix}-wrapper a:hover {
        text-decoration: underline;
      }

      .${classPrefix}-table {
        border-spacing: 0;
        border-collapse: collapse;
        border: 1px solid #000;
        width: 100%;
        max-width: 100%;
        font-size: 12px;
        font-weight: normal;
        font-family: sans-serif;
        color: #000;
        background-color: #FFF;
        margin: 10px 0;

      }

      .${classPrefix}-table .${classPrefix}-table  {
        margin: 0;
      }

      .${classPrefix}-table tr:hover > td {
        background-color: rgba(0, 0, 255, .1);
      }

      .${classPrefix}-table th {
        text-align: left;
        font-weight: bold;
        background-color: #EEE;
      }

      .${classPrefix}-table th,
      .${classPrefix}-table td {
        padding: 4px 8px;
        vertical-align: top;
        border: 1px solid #000;
      }

      .${classPrefix}-table td {
        background-color: #FFF;
      }


      .${classPrefix}-table td.${classPrefix}-expanded {
        padding: 0;
      }

      .${classPrefix}-table td.${classPrefix}-expanded > .${classPrefix}-table {
        border: 0;
      }

      .${classPrefix}-table td.${classPrefix}-expanded > .${classPrefix}-table th {
        border-top: 0;
      }

      .${classPrefix}-table td.${classPrefix}-expanded > .${classPrefix}-table tr:last-child td {
        border-bottom: 0;
      }

      .${classPrefix}-table td.${classPrefix}-expanded > .${classPrefix}-table .${classPrefix}-col-left {
        border-left: 0;
      }

      .${classPrefix}-table td.${classPrefix}-expanded > .${classPrefix}-table .${classPrefix}-col-right {
        border-right: 0;
      }

      .${classPrefix}-col-left {
          width: 15%;
      }

      .${classPrefix}-table a {
        display: block;
      }

      .${classPrefix}-table .${classPrefix}-top-link a {
        display: inline-block;
      }

      .${classPrefix}-empty {
        color: #999;
      }

      .${classPrefix}-truncate {
        display: block;
      }

      .${classPrefix}-expanded > a {
        padding: 4px 8px;
      }

      .${classPrefix}-error {
        color: #C00;
        margin: 5px 0;
      }

      .${classPrefix}-error p {
        font-size: 14px;
      }

    </style>
  </#compress>
</#macro>


<#---
  Shortcut for table structure
  @param title
  @param titleUrl
  FIXME: this is ugly
-->
<#macro tableWrapper title="" titleUrl="">
  <#compress>
    <table class="${settings.styleClassPrefix}-table">
      <thead>
        <#if title?has_content>
          <tr>
            <th class="${settings.styleClassPrefix}-col-left" colspan="2">
              <#-- TODO: ugly logic, fix -->
              <#if title?is_sequence>
                <div class="${settings.styleClassPrefix}-top-link">
                  <#list title as x>
                    <#if x_has_next>
                      <a href="${x.url?xhtml}">${x.title?xhtml}</a><#t/>
                    <#else>
                      ${x.title?xhtml}<#t/>
                    </#if>
                  </#list>
                </div>
              <#elseif titleUrl?has_content>
                <a href='${titleUrl?xhtml}'>
                  ${title?xhtml}
                </a>
              <#else>
                ${title?xhtml}
              </#if>
            </th>
          </tr>
        </#if>
        <tr>
          <th class="${settings.styleClassPrefix}-col-left">Key</th>
          <th class="${settings.styleClassPrefix}-col-right">Value</th>
        </tr>
      </thead>
      <tbody>
        <#nested />
      </tbody>
    </table>
  </#compress>
</#macro>



<#---
  Determines if a value is a sequence or a hash_ex and can be expanded. Ignores objects that are both sequence+method.
  @param object	Object to determine if it is a hash_ex or sequence
  @returns boolean
-->
<#function isComplexObject object>

  <#if (object?is_sequence && object?is_method)>
    <#return false />
  <#elseif (object?is_hash_ex || object?is_sequence)>
    <#return true />
  </#if>

  <#return false />

</#function>


<#---

  @param key
  @param value
  @param depth	How deep to expand the object
  @param dynamic	Boolean to make expandable objects a link to quickly drill-down into data
  @param queryParam Parameter used in query string for direct debugging
-->
<#macro properties key value depth dynamic queryParam="">
  <#-- ignore spring framework properties -->
  <#if ignoreKey(key)>
    <#return />
  </#if>

  <#local isComplex = isComplexObject(value) />

  <#if isComplex>
    <#if ((depth > 1) || dynamic) && value?has_content>
      <#local expandedClass = " " + settings.styleClassPrefix + "-expanded" />
    </#if>
  </#if>

  <tr>
    <td class="${settings.styleClassPrefix}-col-left">${key?xhtml}</td>
    <td class="${settings.styleClassPrefix}-col-right${expandedClass!}">
      <#if isComplex>
        <@complexValue
            key=key
            value=value
            depth=depth
            dynamic=dynamic
            queryParam=queryParam />
      <#else>
        <@simpleValue value=value />
      </#if>
    </td>
  </tr>
</#macro>


<#---
  Determines if a key should be ignored according to the settings.
  @param key
  @returns boolean
-->
<#function ignoreKey key>

  <#if key?is_string>
    <#if settings.ignoredKeys?seq_contains(key)>
      <#return true />
    </#if>

    <#list settings.ignoredPatterns as pattern>
      <#if key?starts_with(pattern)>
        <#return true />
      </#if>
    </#list>
  </#if>

  <#return false />

</#function>

<#---
  Displays a simple value (not hash_ex or sequence)
  @param value
-->
<#macro simpleValue value>

  <#-- METHOD -->
  <#-- check first because ?has_content doesn't work on methods -->
  <#-- TODO: See what methods can be expanded -->
  <#if value?is_method>
    method()

  <#-- MACRO/FUNCTIONS -->
  <#-- ?has_content evaluates to false for these -->
  <#elseif value?is_macro>
    macro/function

  <#elseif value?has_content>

    <#-- NUMBER -->
    <#if value?is_number>
      ${value?c}<#-- prevent number formatting -->

    <#-- DATE -->
    <#-- TODO: format -->
    <#elseif value?is_date>
      date: ${value?date}

    <#-- BOOLEAN -->
    <#elseif value?is_boolean>
      <em>${value?string("TRUE","FALSE")}</em>

    <#-- HASH -->
    <#-- TODO: Look into how to expand this -->
    <#elseif value?is_hash>
      hash

    <#-- STRING -->
    <#-- always check string last since some objects will evaluate
         to string as well as another type -->
    <#elseif value?is_string>
      <#-- show full value in source -->
      <!-- ${value?xhtml} -->
      ${truncateString(value)?xhtml}<#-- prevent injection -->
    </#if>

  <#else>
    <em class="${settings.styleClassPrefix}-empty">(empty)</em>
  </#if>
</#macro>


<#---
  Function to determine what the debug url will be
  @param queryParam Parameter used in query string for direct debugging
  @returns string
-->
<#function getDebugUrl queryParam>

  <#local url = getBaseUrl() />

  <#if debugQuery?has_content>
    <#local url = url + debugQuery + queryParam />
  <#else>
    <#local url = url + queryParam />
  </#if>

  <#return url />

</#function>


<#---
  Determine the base debug url
  @returns string
-->
<#function getBaseUrl>

  <#local url = "?" />

  <#if RequestParameters?has_content>
    <#list RequestParameters?keys as paramKey>
      <#if paramKey != settings.queryParamKey>
        <#local url = url + paramKey + "=" + RequestParameters[paramKey] + "&" />
      </#if>
    </#list>
  </#if>

  <#return (url + settings.queryParamKey + "=") />

</#function>

<#---
  Builds the parameter to use in the query string for debugging
  @param key
  @param debugQueryPrefix
  @param dynamic
  @returns string
-->
<#function buildQueryParam key debugQueryPrefix="" dynamic=false>

  <#-- only build if it is debugDynamic -->
  <#if !dynamic>
    <#return "" />
  </#if>

  <#local urlParam = "[" + (key?is_number)?string(key, '"' + key + '"') + "]" />

  <#return (debugQueryPrefix + urlParam) />

</#function>


<#---
  Handles the output of hash_ex and sequences
  @param key
  @param value
  @param depth	How deep to expand the object
  @param dynamic	Boolean to make expandable objects a link to quickly drill-down into data
  @param queryParam Parameter used in query string for direct debugging
-->
<#macro complexValue key value depth dynamic queryParam="">

  <#-- store class name -->
  <#if value?is_string && value?is_hash_ex>
    <#local className = varClass(value) />
    <#local fullValue = value /><#-- prevent injection -->
    <#local shortValue = truncateString(value) /><#-- prevent injection -->
  </#if>

  <#if (depth > 1) && (value?has_content)>
    <@debugTable
        debugObject=value
        depth=(depth - 1)
        dynamic=dynamic
        queryParam=queryParam
        title=className!'' />
  <#else>

    <#local staticValue = (value?is_hash_ex)?string("hash_ex", "sequence") + "(" + value?size + ")" />

    <#-- show class name for hash_ex -->
    <#if value?is_string && value?is_hash_ex>
      <#-- show full value in source -->
      <!-- ${fullValue!} -->
      <#local staticValue = staticValue + " " + (shortValue!'') />
    </#if>

    <#if dynamic>
      <a href='${getDebugUrl(queryParam)?xhtml}'>${staticValue}</a>
    <#else>
      ${staticValue}
    </#if>
  </#if>

</#macro>


<#---
  Truncates large strings
  @param string
  @param maxLength The length to truncate the string to
  @returns string
-->
<#function truncateString string maxLength=100>

  <#if string?is_string && (string?length > maxLength)>
    <#return string?substring(0, 100) + "…" />
  </#if>

  <#return string />

</#function>


<#---
  Helper macro that outputs a variable type
  @param var
-->
<#macro variableType var>
  ${var?is_string?string("is_string<br/>", "")}
  ${var?is_number?string("is_number<br/>", "")}
  ${var?is_boolean?string("is_date<br/>", "")}
  ${var?is_date?string("is_date<br/>", "")}
  ${var?is_method?string("is_method<br/>", "")}
  ${var?is_transform?string("is_transform<br/>", "")}
  ${var?is_macro?string("is_macro<br/>", "")}
  ${var?is_hash?string("is_hash<br/>", "")}
  ${var?is_hash_ex?string("is_hash_ex<br/>", "")}
  ${var?is_sequence?string("is_sequence<br/>", "")}
  ${var?is_collection?string("is_collection<br/>", "")}
  ${var?is_enumerable?string("is_enumerable<br/>", "")}
  ${var?is_indexable?string("is_indexable<br/>", "")}
  ${var?is_directive?string("is_directive<br/>", "")}
  ${var?is_node?string("is_node<br/>", "")}
  ${var?has_content?string("has_content<br/>", "")}
</#macro>


<#---
  Gets the class of a var if applicable
  @param value
  @returns string
-->
<#function varClass value>

  <#if value?is_hash_ex && ((value.class)??)>
    <#return value.class />
  </#if>

  <#return "" />

</#function>


<#---
  Rebuild the debug object from the url parameter.
  @param root
  @param query
-->
<#function debugObjectFromUrl root query>

    <#local convertedArray = convertArray(query) />

    <#return validObject(root, convertedArray) />

</#function>


<#---
  Determine the debug root information based on the query

  @param query
  @returns object
-->
<#function getDebugRoot query>

  <#-- default to data_model -->
  <#local object = .data_model />
  <#local title = ".data_model" />

  <#-- .locals -->
  <#if query?starts_with(".locals")>
    <#local object = .locals />
    <#local title = ".locals" />

  <#-- .main -->
  <#elseif query?starts_with(".main")>
    <#local object = .main />
    <#local title = ".main" />

  <#-- .namespace -->
  <#elseif query?starts_with(".namespace")>
    <#local object = .namespace />
    <#local title = ".namespace" />

  </#if>

  <#return { "object": object, "title": title } />

</#function>


<#---
  Converts the debug query into an array of strings and numbers

  @param query
  @returns array
-->
<#function convertArray query>

  <#if query?contains("[") && query?contains("]")>
    <#-- chop off front and back brackets, then split on '][' to form array -->
    <#local query = query?substring(
        query?index_of("[") + 1,
        query?last_index_of("]")
      ) />

    <#if query?contains("][")>
      <#local queryArray = query?split("][") />
     <#else>
       <#local queryArray = [query] />
    </#if>

    <#-- remove quotes for strings, convert others to numbers -->
    <#local convertedArray = [] />
    <#list queryArray as q>
      <#if q?starts_with('"')>
        <#local str = q?substring(1, q?length - 1) />
        <#local convertedArray = convertedArray + [str?j_string] />
      <#else>
        <#local convertedArray = convertedArray + [q?number] />
      </#if>
    </#list>

    <#return convertedArray />

  <#else>
    <#return [] />
  </#if>

</#function>


<#---
  Function to check if the value we're debugging exists
  @param debugParent
  @param array
  @returns boolean
-->
<#function validObject debugParent array>

  <#local obj = debugParent />

  <#list array as x>
    <#if (obj[x]??)>
      <#local obj = obj[x] />
    <#else>
      <#return -1 />
    </#if>
  </#list>

  <#return obj />

</#function>


<#---
  Builds a top-level list of links for easier traversal
  @param query
  @returns array
-->
<#function getTitleLink query>

  <#local root = getDebugRoot(query) />
  <#local convertedArray = convertArray(query) />

  <#local url = getBaseUrl() + root.title />

  <#local urlList = [{
      "title": root.title,
      "url": url
    }] />

  <#list convertedArray as k>
    <#if k?is_string>
      <#local title = '["' + k + '"]' />
    <#else>
      <#local title = '[' + k?string + ']' />
    </#if>

    <#local url = url + title />

    <#local urlList = urlList + [{
        "title": title,
        "url": url
      }] />
  </#list>

  <#return urlList />

</#function>
