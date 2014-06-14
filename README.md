# freemarker-debugger

Debugging in Freemarker made easy. Manually or dynamically traverse through objects from the data model sent to the freemarker view.

## Usage


    <#import "/freemarker-debugger/debugger.ftl" as debugger />
    
    <#-- Basic usage. Creates a table of the top-level data model objects -->
    <@debugger.debug />
    
    <#-- Adds links to traversable elements -->
    <@debugger.debugDynamic />


## License

Copyright 2014 Evangelia Dendramis

Licensed under the MIT License: http://opensource.org/licenses/MIT
