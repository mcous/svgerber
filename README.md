# svgerber
it's got vectors and it's in alpha

## what?
svgerber is a browser based gerber file to SVG converter. Everything is converted locally using the [gerber-to-svg](https://github.com/mcous/gerber-to-svg) node package.

## why?
'Cause.

## when?
Right now, it's able to render certain gerber files (specifically: mine that I generate from KiCad). The step and repeat command could get dicey, but eveything else should be there. If you try it out with a file and get freezes or errors, let me know.

## how?
Go to [svgerber.cousins.io](http://svgerber.cousins.io).

### local dev server
If you want to run it locally and play around, run the dev server. Thanks to @hcwiley (who I'm pretty sure copied it from @zever) for the initial setup that has since morphed into what I have now.

This project uses [gulp](http://gulpjs.com) to build and serve the app.

1. `$ npm install  # install dev and app dependencies`
2. `$ bower install  # install webpage dependencies`
2. `$ gulp serve   # start the server / file watcher / live reload server`
3. surf the web at http://localhost:8080

## huh?
Yeah.
