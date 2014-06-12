# svgerber
Get it?

## what?
It's a browser based client-side gerber file to svg converter.

## why?
'Cause.

## when?
Right now, it's able to render certain gerber files (specifically: mine that I generate from KiCad). Several gerber commands are missing, but it's got enough to render circular and rectangular pads, traces made with circular apertures, and fills. If you try it out with a file and get errors, let me know.

## how?
Go to [cousins.io/svgerber](http://cousins.io/svgerber).

### local dev server
If you want to run it locally and play around, run the dev server. Thanks to @hcwiley (who I'm pretty sure copied it from @zever) for the initial setup that has since morphed into what I have now.

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
