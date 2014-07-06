# svgerber
it's got vectors and it's in alpha

## what?
svgerber is a browser based gerber file to SVG converter. Everything is converted locally using the [svg.js](http://www.svgjs.com) library.

## why?
'Cause.

## when?
Right now, it's able to render certain gerber files (specifically: mine that I generate from KiCad). Several gerber commands are missing, but it's got enough to render circular and rectangular pads, traces made with circular apertures, and fills. If you try it out with a file and get errors, let me know.

## how?
Go to [svgerber.cousins.io](http://svgerber.cousins.io).

### local dev server
If you want to run it locally and play around, run the dev server. Thanks to @hcwiley (who I'm pretty sure copied it from @zever) for the initial setup that has since morphed into what I have now.

This project uses [gulp.js](http://gulpjs.com/) to build and serve the app.

1. `$ npm install  # install dev dependencies`
2. `$ bower install  # install app dependencies`
2. `$ gulp serve   # start the server / file watcher / live reload`
3. surf the web at http://localhost:8080

## test?
svgerber uses jasmine for unit testing. The tests live in the `spec` directory. To run the tests:

1. `$ npm install        # install dependencies`
2. `$ scripts/testwatch  # start the tester / file watcher`

Jasmine will watch the files and the specs and rerun the tests if anything changes.

## huh?
Yeah.
