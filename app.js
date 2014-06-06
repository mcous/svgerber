// Generated by CoffeeScript 1.7.1
(function() {
  var Aperture, fileToSVG, handleFileSelect, readFileToDiv, root;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  Aperture = (function() {
    function Aperture(code, shape, params) {
      this.code = code;
      this.shape = shape;
      this.params = params;
      console.log("Aperture " + this.code + " was created and is a " + this.shape);
    }

    return Aperture;

  })();

  root.Plotter = (function() {
    function Plotter(gerberFile) {
      this.zeroOmit = null;
      this.notation = null;
      this.leadDigits = null;
      this.trailDigits = null;
      this.units = null;
      this.apertures = [];
      this.iMode = null;
      this.aMode = null;
      this.gerber = gerberFile.split('\n');
      console.log("Plotter created");
    }

    Plotter.prototype.parseFormatSpec = function(fS) {
      var formatMatch, notationMatch, xDataMatch, xFormat, yDataMatch, yFormat, zeroMatch, _ref, _ref1;
      formatMatch = /^%FS.*\*%$/;
      zeroMatch = /[LT]/;
      notationMatch = /[AI]/;
      xDataMatch = /X+?\d{2}/;
      yDataMatch = /Y+?\d{2}/;
      if (!fS.match(formatMatch)) {
        throw "InputTo_parseFormatSpec_NotAFormatSpecError";
      }
      this.zeroOmit = fS.match(zeroMatch);
      if (this.zeroOmit != null) {
        this.zeroOmit = this.zeroOmit[0][0];
        console.log("zero omission set to: " + this.zeroOmit);
      } else {
        throw "NoZeroSuppressionInFormatSpecError";
      }
      this.notation = fS.match(notationMatch);
      if (this.notation != null) {
        this.notation = this.notation[0][0];
        console.log("notation set to: " + this.notation);
      } else {
        throw "NoCoordinateNotationInFormatSpecError";
      }
      xFormat = fS.match(xDataMatch);
      yFormat = fS.match(yDataMatch);
      if (xFormat != null) {
        xFormat = xFormat[0].slice(-2);
      } else {
        throw "MissingCoordinateFormatInFormatSpecError";
      }
      if (yFormat != null) {
        yFormat = yFormat[0].slice(-2);
      } else {
        throw "MissingCoordinateFormatInFormatSpecError";
      }
      if (xFormat === yFormat) {
        this.leadDigits = parseInt(xFormat[0], 10);
        this.trailDigits = parseInt(xFormat[1], 10);
      } else {
        throw "CoordinateFormatMismatchInFormatSpecError";
      }
      if (!(((0 < (_ref = this.leadDigits) && _ref < 8)) && ((0 < (_ref1 = this.trailDigits) && _ref1 < 8)))) {
        throw "InvalidCoordinateFormatInFormatSpecError";
      } else {
        return console.log("coordinate format set to: " + this.leadDigits + ", " + this.trailDigits);
      }
    };

    Plotter.prototype.parseUnits = function(u) {
      var unitMatch;
      unitMatch = /^%MO((MM)|(IN))\*%/;
      if (u.match(unitMatch)) {
        return this.units = u.slice(3, 5);
      } else {
        throw "NoValidUnitsGivenError";
      }
    };

    Plotter.prototype.parseAperture = function(a) {
      var apertureMatch, code, params, shape;
      apertureMatch = /^%AD.*$/;
      if (!a.match(apertureMatch)) {
        throw "InputTo_parseAperture_NotAnApertureError";
      }
      code = a.match(/D[1-9]\d+/);
      if (code != null) {
        code = parseInt(code[0].slice(1), 10);
      } else {
        throw "InvalidApertureToolCodeError";
      }
      shape = a.match(/[CROP].*(?=\*%$)/);
      if (shape != null) {
        shape = shape[0];
        params = ((function() {
          switch (shape[0]) {
            case "C":
            case "R":
            case "O":
              return this.parseBasicAperture(shape);
            case "P":
              throw "UnimplementedApertureError";
          }
        }).call(this));
        shape = shape[0];
      } else {
        throw "NoApertureShapeError";
      }
      return a = new Aperture(code, shape, params);
    };

    Plotter.prototype.parseBasicAperture = function(string) {
      var badInput, circle, circleMatch, i, obround, obroundMatch, p, params, rect, rectangleMatch, _i, _len;
      circleMatch = /^C,[\d\.]+(X[\d\.]+){0,2}$/;
      rectangleMatch = /^R,[\d\.]+X[\d\.]+(X[\d\.]+){0,2}$/;
      obroundMatch = /^O,[\d\.]+X[\d\.]+(X[\d\.]+){0,2}$/;
      badInput = true;
      if (((circle = string[0][0] === 'C') && string.match(circleMatch)) || ((rect = string[0][0] === 'R') && string.match(rectangleMatch)) || ((obround = string[0][0] === 'O') && string.match(obroundMatch))) {
        params = string.match(/[\d\.]+/g);
        for (i = _i = 0, _len = params.length; _i < _len; i = ++_i) {
          p = params[i];
          if (p.match(/^((\d+\.?\d*)|(\d*\.?\d+))$/)) {
            params[i] = parseFloat(p);
            badInput = false;
          } else {
            badInput = true;
            break;
          }
        }
      }
      if (badInput) {
        if (circle) {
          throw "BadCircleApertureError";
        } else if (rect) {
          throw "BadRectangleApertureError";
        } else if (obround) {
          throw "BadObroundApertureError";
        }
      }
      return params;
    };

    Plotter.prototype.parseGCode = function(s) {
      var code, match;
      match = s.match(/^G\d{1,2}(?=\D)/);
      if (!match) {
        throw "InputTo_parseGCode_NotAGCodeError";
      } else {
        match = match[0];
      }
      code = parseInt(match.slice(1), 10);
      switch (code) {
        case 1:
        case 2:
        case 3:
          this.iMode = code;
          break;
        case 4:
          console.log("found a comment");
          return "";
        case 74:
        case 75:
          this.aMode = code;
          break;
        case 54:
        case 55:
          console.log("deprecated G" + code + " found");
          break;
        case 70:
          if (this.units == null) {
            console.log("warning: deprecated G70 command used to set units to in");
            this.units = 'IN';
          }
          break;
        case 71:
          if (this.units == null) {
            console.log("warning: deprecated G71 command used to set units to mm");
            this.units = 'MM';
          }
          break;
        case 90:
          if (this.notation == null) {
            console.log("warning: deprecated G90 command used to set notation to abs");
            this.notation = 'A';
          }
          break;
        case 91:
          if (this.notation == null) {
            console.log("warning: deprecated G91 command used to set notation to inc");
            this.notation = 'I';
          }
          break;
        default:
          throw "G" + code + "IsUnimplementedGCodeError";
      }
      return s.slice(match.length);
    };

    Plotter.prototype.plot = function() {
      var ap, apertureMatch, fileEnd, formatMatch, gMatch, gotFormat, gotUnits, interpolationMode, line, quadrantMode, unitMatch, _i, _len, _ref;
      gotFormat = false;
      gotUnits = false;
      fileEnd = false;
      interpolationMode = null;
      quadrantMode = null;
      formatMatch = /^%FS.*\*%$/;
      unitMatch = /^%MO((MM)|(IN))\*%$/;
      apertureMatch = /^%AD.*\*%$/;
      gMatch = /^G.*\*$/;
      _ref = this.gerber;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        if ((!gotFormat) || (!gotUnits)) {
          if (line.match(formatMatch)) {
            this.parseFormatSpec(line);
            gotFormat = true;
          } else if (line.match(unitMatch)) {
            this.parseUnits(line);
            gotUnits = true;
          }
        } else {
          if (line.match(gMatch)) {
            line = this.parseGCode(line);
          }
          if ((line === "") || (line.match(/^\*$/))) {
            console.log("empty (or emptied) line");
          } else if (line.match(apertureMatch)) {
            ap = this.parseAperture(line);
            if (this.apertures[ap.code - 10] == null) {
              this.apertures[ap.code - 10] = ap;
            } else {
              throw "ApertureAlreadyExistsError";
            }
          } else {
            console.log("don't know what " + line + " means");
          }
        }
      }
      if (!gotFormat) {
        throw "NoFormatSpecGivenError";
      }
      if (!gotUnits) {
        throw "NoValidUnitsGivenError";
      }
    };

    return Plotter;

  })();

  fileToSVG = function(file) {
    var p;
    console.log('converting to svg');
    p = new Plotter(file);
    return p.plot();
  };

  readFileToDiv = function(event) {
    var textDiv;
    if (event.target.readyState === FileReader.DONE) {
      textDiv = document.createElement('p');
      textDiv.innerHTML = fileToSVG(event.target.result);
      return document.getElementById('file-contents').insertBefore(textDiv, null);
    }
  };

  handleFileSelect = function(event) {
    var f, importFiles, output, reader, _i, _j, _len, _len1, _results;
    importFiles = event.target.files;
    output = [];
    for (_i = 0, _len = importFiles.length; _i < _len; _i++) {
      f = importFiles[_i];
      output.push('<li><strong>', escape(f.name), '</li>');
    }
    document.getElementById('list').innerHTML = '<ul>' + output.join('') + '</ul>';
    _results = [];
    for (_j = 0, _len1 = importFiles.length; _j < _len1; _j++) {
      f = importFiles[_j];
      reader = new FileReader();
      reader.addEventListener('loadend', readFileToDiv, false);
      _results.push(reader.readAsText(f));
    }
    return _results;
  };

  document.getElementById('files').addEventListener('change', handleFileSelect, false);

}).call(this);

//# sourceMappingURL=app.map
