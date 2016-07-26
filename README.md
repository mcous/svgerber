# svgerber (deprecated!)

[![David](https://img.shields.io/david/mcous/svgerber.svg?style=flat-square)](https://david-dm.org/mcous/svgerber)
[![David](https://img.shields.io/david/dev/mcous/svgerber.svg?style=flat-square)](https://david-dm.org/mcous/svgerber#info=devDependencies)

svgerber has been deprecated and is no longer maintained. Please try [tracespace viewer](http://viewer.tracespace.io) for all your web-based Gerber viewing needs.

## what?
svgerber is a browser based Gerber/drill file to SVG converter. Everything is converted locally (nothing gets sent to any server) using the [gerber-to-svg](https://github.com/mcous/gerber-to-svg) node package.

Given at least a top or bottom copper layer, it will render what your board is going to look like. Regardless, it will also render each individual layer separately.

Right now, it's able to convert most Gerber and drill files I can find. If you try it out with a file and get errors, let me know in [the issues](https://github.com/mcous/svgerber/issues).

## why?
It's a quick and easy way to visualize your board designs. Plus, you can download the SVGs and send them to all your friends. They'll be impressed.

## how?
Go to [svgerber.cousins.io](http://svgerber.cousins.io).

### local dev server
This project uses [gulp](http://gulpjs.com) to build and serve the app.

1. `$ npm install    # install dev and app dependencies`
2. `$ gulp           # start the server / file watcher / live reload server`
3. Your browser should surf to `http://localhost:8000` automatically
