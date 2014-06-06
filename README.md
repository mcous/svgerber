# svgerber
Get it?

## what?
It's a coffeescript based client-side gerber file to svg converter.

## why?
'Cause.

## when?
Right now, it's able to read the gerber file, identify the format of the file, and identify a selection of apertures. So it's a work in progress.

## how?
Run the dev server. Thanks to @hcwiley (who I'm pretty sure copied it from @zever) for the initial setup that has since morphed into what I have now.

This project (for now) uses cake (Coffeescript make) to build and serve the app.

1. `$ npm install  # install dependencies`
2. `$ cake serve   # start the server / file watcher`
3. surf the web at http://localhost:8080

## test?
svgerber uses jasmine for unit testing. The tests live in the `spec` directory. To run the tests:

1. `$ npm install        # install dependencies`
2. `$ scripts/testwatch  # start the tester / file watcher`

Jasmine will watch the files and the specs and rerun the tests if anything changes.

## well it depends
The Cakefile builds the multiple source files of the project into one `app.js`. To ensure the files get concatenated in the right order, any file that requires another file should put a line in the coffeescript source that says:

``` coffeescript
# any of these lines will accomplish your goal
#require 'dependecy'
#require 'dependency.coffee'
#require "dependency"
#require "dependency.litcoffee"
```

## huh?
Yeah.
