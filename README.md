# svgerber
it's got vectors and it's in alpha

## what?
svgerber is a browser based Gerber/drill file to SVG converter. Everything is converted locally using the [gerber-to-svg](https://github.com/mcous/gerber-to-svg) node package.

## why?
'Cause.

## when?
Right now, it's able to convert most Gerber files I can find. If you've got Gerbers that use the step and repeat command things could get dicey, but everything else should be there. If you try it out with a file and get errors, let me know in [the issues](https://github.com/mcous/svgerber/issues).

## how?
Go to [svgerber.cousins.io](http://svgerber.cousins.io).

### local dev server
This project uses [gulp](http://gulpjs.com) to build and serve the app.

1. `$ npm install  # install dev and app dependencies`
2. `$ bower install  # install webpage dependencies`
2. `$ gulp serve   # start the server / file watcher / live reload server`
3. surf the web at http://localhost:8080

## huh?
Yeah.
