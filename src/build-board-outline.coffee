# function to create a board of the exact shape as defined by the outline
# takes in an svg path data array and spits out an svg path data array

find = require 'lodash/collection/find'
remove = require 'lodash/array/remove'

# helper class: point
class Point
  # constructor takes an x and a y and contructs a segment array
  # each point should have two segments
  constructor: (@x, @y) -> @segments = []
  # add a segment to the segment array
  addSegment: (seg, rel) -> @segments.push { seg: seg, rel: rel }

# helper class: line or arc segment
class Segment
  # constructor adds self to the start and end point's segment array
  constructor: (@start, @end) ->
    @start.addSegment @, 'start'
    #@start = { x: start.x, y: start.y }
    @end.addSegment @, 'end'
    #@end = { x: end.x, y: end.y }
  # adds arc properties to the segment
  addArc: (@radius, @largeArc, @sweep) ->
  # spit out the command to draw to the given endpoint
  # this assumes that the pen is already at the other enpoint
  drawTo: (point) ->
    # check to see if we're drawing to one of our endpoints
    if point is @start then toStart=true else if point is @end then toEnd=true
    # if we're a line, we really only care if it's going somewhere we can
    if not @radius? and (toStart or toEnd) then [ 'L', point.x, point.y ]
    # else if we're an arc going to our normal end, nothing changes
    else if @radius? and toEnd
      [ 'A', @radius, @radius, 0, @largeArc, @sweep, point.x, point.y ]
    # else if we're an arc going to our start, we need to flip the @sweep flag
    else if @radius? and toStart
      sw = if @sweep is 1 then 0 else 1
      [ 'A' ,@radius, @radius, 0, @largeArc, sw, point.x, point.y ]
    # else this isn't going to work out, so don't draw
    else return []

module.exports = (outline) ->
  # sanity check: first command should be a move to
  if outline[0] isnt 'M' then console.log "didn't start with 'M'"; return []

  # we're going to save points rather than segments
  pathStart = null
  points = []
  # going to do a good old-fashioned while loop for this one
  i = 0
  while i < outline.length - 1
    # check out current character to get our starting point
    # M and L have a point directly after them
    if outline[i] is 'M' or outline[i] is 'L'
      x = outline[i+1]
      y = outline[i+2]
      i += 3
    # A (arc) has some other params we need to get by
    else if outline[i] is 'A'
      x = outline[i+6]
      y = outline[i+7]
      i += 8
    # Z is an end of the path, so le'ts just move along
    else if outline[i] is 'Z' then i++; continue

    # check to make sure we're not out of bounds
    if i >= outline.length then break
    else
      start = find points, { x: x, y: y }
      if not start? then newStart = true; start = new Point x, y

    # check our current character again to get the end of the segment
    if outline[i] is 'L'
      x = outline[i+1]
      y = outline[i+2]
      r = null
    else if outline[i] is 'A'
      x = outline[i+6]
      y = outline[i+7]
      r = outline[i+2]
      lrgArc = outline[i+4]
      sweep = outline[i+5]
    # M means a new path, so just continue
    else if outline[i] is 'M' then continue

    # Z is an end of the path, so draw a line directly to the start
    if outline[i] is 'Z'
      end = pathStart
      pathStart = null
    else
      # set the path start if ncessary
      if not pathStart? then pathStart = start
      end = find points, { x: x, y: y }
      if not end? then newEnd = true; end = new Point x, y

    # we've got a start and an end, so create the segment and push the points
    seg = new Segment start, end
    if r? then seg.addArc r, lrgArc, sweep
    if newStart then newStart = false; points.push start
    if newEnd then newEnd = false; points.push end

  # now that we're out of the loop, we should have all our points
  # let's traverse them, drawing as we go
  newPath = []
  while points.length
    startPoint = points.pop()
    nextSegObj = startPoint.segments.pop()
    nextPoint = null
    newPath.push 'M', startPoint.x, startPoint.y
    while nextPoint isnt startPoint
      # remove nextPoint from the points array
      remove points, (p) -> p is nextPoint
      # go along the segment to get the next point
      nextSeg = nextSegObj.seg
      nextSegRel = nextSegObj.rel
      nextPointRel = if nextSegRel is 'start' then 'end' else 'start'
      nextPoint = nextSeg[nextPointRel]
      # draw the segment and remove it
      newPath.push p for p in nextSeg.drawTo nextPoint
      remove nextPoint.segments, (sO) -> sO.seg is nextSeg
      # set the next segment object by popping the other segment in the array
      nextSegObj = nextPoint.segments.pop()

  # return the new path
  newPath
