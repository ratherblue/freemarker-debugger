<#ftl strip_text=true />

<#---
  @author      Evangelia Dendramis <edendramis@gmail.com>
  @homepage    https://github.com/edendramis/freemarker-debugger/
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

  <div class="${settings.styleClassPrefix}-wrapper">
    <@debugTable
        debugObject=debugObject
        depth=depth />
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
      <#if debugQuery?contains("[")>
        <#-- allow the ability to traverse back up -->
        <#local parentQuery = debugQuery?substring(0, debugQuery?last_index_of("[")) />
        <#local currentQuery = debugQuery?substring(debugQuery?last_index_of("[")) />
      </#if>
      <div class="${settings.styleClassPrefix}-debug-title">
        <a href="${baseUrl() + settings.queryParamKey + "=" + (parentQuery!'')?url}">.data_model${parentQuery?xhtml}</a><#-- prevent white space
        -->${(currentQuery!'')?xhtml}: <#-- prevent injection -->
      </div>

      <#attempt>
        <@debugTable
            debugObject=(".data_model" + debugQuery?j_string)?eval <#-- #yolo -->
            depth=depth
            dynamic=true />
      <#recover>
        <div class="${settings.styleClassPrefix}-error">
          <strong>Error:</strong> Unable to parse ${debugQuery?xhtml}
          <p><strong>Error code:</strong> ${.error}</p>
        </div>
      </#attempt>

    <#else>
      <@debugTable
          debugObject=.data_model
          depth=depth
          dynamic=true />
    </#if>
  </div>
</#macro>

<#---
  Prints out expandable objects (hash_ex, sequences) in tabular form
  @param debugObject	Object to expand
  @param depth	How deep to expand the object
  @param dynamic	Boolean to make expandable objects a link to quickly drill-down into data
  @param queryParam Parameter used in query string for direct debugging
-->
<#macro debugTable debugObject depth dynamic=false queryParam="">

  <#if isComplexObject(debugObject)>
    <@tableWrapper>
      <#if debugObject?is_hash_ex>
        <#list debugObject?keys?sort as key>
          <@properties
              key=key
              value=(debugObject[key])!""
              depth=depth
              dynamic=dynamic
              queryParam=queryParam />
        </#list>
      <#elseif debugObject?is_sequence>
        <#list debugObject as obj>
          <@properties
              key=obj_index
              value=obj!""
              depth=depth
              dynamic=dynamic
              queryParam=queryParam />
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

      .${classPrefix}-debug-title {
        display: block;
        font-size: 16px;
        font-weight: bold;
      }

      .${classPrefix}-debug-title a {
        display: inline-block;
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

      .${classPrefix}-table tr:hover td {
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

      .${classPrefix}-empty {
        color: #999;
      }

      .${classPrefix}-truncate {
        display: block;
      }

      .${classPrefix}-expanded a {
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
-->
<#macro tableWrapper>
  <#compress>
    <table class="${settings.styleClassPrefix}-table">
      <thead>
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
    <td class="${settings.styleClassPrefix}-col-left">${key}</td>
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
      date

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
      ${truncateString(value?xhtml)}<#-- prevent injection -->
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
<#function debugUrl queryParam>

  <#local url = baseUrl() />

  <#if debugQuery?has_content>
    <#local url = url + settings.queryParamKey + "=" + debugQuery?xhtml + queryParam />
  <#else>
    <#local url = url + settings.queryParamKey + "=" + queryParam />
  </#if>

  <#return url />

</#function>


<#---
  Determine the base debug url
  @returns string
-->
<#function baseUrl>
  <#local urlBase = "?" />

  <#if RequestParameters?has_content>
    <#list RequestParameters?keys as paramKey>
      <#if paramKey != settings.queryParamKey>
        <#local urlBase = urlBase + paramKey + "=" + RequestParameters[paramKey] + "&" />
      </#if>
    </#list>
  </#if>

  <#return urlBase?xhtml /><#-- prevent injection -->

</#function>

<#---
  Builds the parameter to use in the query string for debugging
  @param key
  @param debugQueryPrefix
  @returns string
-->
<#function buildQueryParam key debugQueryPrefix="">

  <#local urlParam = "[" + (key?is_number)?string(key?url, "'" + key?url + "'") + "]" />

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

  <#if (depth > 1) && (value?has_content)>
    <@debugTable
        debugObject=value
        depth=(depth - 1)
        dynamic=dynamic
        queryParam=buildQueryParam(key, queryParam) />
  <#else>
    <#local staticValue = (value?is_hash_ex)?string("hash_ex", "sequence") + "(" + value?size + ")" />

    <#-- show class name for hash_ex -->
    <#if value?is_string && value?is_hash_ex>
      <#local staticValue = staticValue + " " + value?xhtml /><#-- prevent injection -->
    </#if>

    <#-- truncate really long names, but show full name in source -->
    <#if (staticValue?length > 100)>
      <!-- ${staticValue!} -->
      <#local staticValue = truncateString(staticValue) />
    </#if>

    <#if dynamic>
      <a href="${debugUrl(buildQueryParam(key, queryParam))}">${staticValue}</a>
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