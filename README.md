# svgerber
giving gerber files the web-based vector love they deserve

## what?
svgerber is a browser based Gerber/drill file to SVG converter. Everything is converted locally (nothing gets sent to any server) using the [gerber-to-svg](https://github.com/mcous/gerber-to-svg) node package.

Given at least a top or bottom copper layer, it will render what your board is going to look like. Regardless, it will also render each individual layer separately.

Right now, it's able to convert most Gerber and drill files I can find. If you have Gerbers that use the step and repeat command with overlapping clears (a practice that the Gerber file spec recommends against, so it's unlikely your Gerbers do), it will render an incorrect image. If you try it out with a file and get errors, let me know in [the issues](https://github.com/mcous/svgerber/issues).

## why?
It's a quick and easy way to visualize your board designs. Plus, you can download the SVGs and send them to all your friends. They'll be impressed.

## how?
Go to [svgerber.cousins.io](http://svgerber.cousins.io).

### local dev server
This project uses [gulp](http://gulpjs.com) to build and serve the app.

1. `$ npm install    # install dev and app dependencies`
2. `$ bower install  # install webpage dependencies`
2. `$ gulp           # start the server / file watcher / live reload server`
3. surf the web at http://localhost:8000
