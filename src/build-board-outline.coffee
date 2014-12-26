# function to create a board of the exact shape as defined by the outline
# takes in an svg path data array and spits out an svg path data array

# helper class: line or arc segment
class Segment
  # constructor and methods for adding arc properties and an endpoint
  constructor: (@start) ->
  addArc: (@radius, @largeArc, @sweep) ->
  addEnd: (@end) ->
  # spit out the command to draw to the given endpoint
  # this assumes that the pen is already at the other enpoint
  drawTo: (point) ->
    # check to see if we're drawing to one of our endpoints
    if point[0] is @start[0] and point[1] is @start[1] then toStart = true
    else if point[0] is @end[0] and point[1] is @end[1] then toEnd = true
    # if we're a line, we really only care if it's going somewhere we can
    if not @radius? and (toStart or toEnd) then "L #{point[0]} #{point[1]}"
    # else if we're an arc going to our normal end, nothing changes
    else if @radius? and toEnd
      "A #{@radius} #{@radius} 0 #{@largeArc} #{@sweep} #{point[0]} #{point[1]}" 
    # else if we're an arc going to our start, we need to flip the @sweep flag
    else if @radius? and toStart
      sw = if @sweep is 1 then 0 else 1
      "A #{@radius} #{@radius} 0 #{@largeArc} #{sw} #{point[0]} #{point[1]}"
    # else this isn't going to work out, so don't draw
    else
      console.log "#{point[0]}, #{point[1]} is not an endpoint of this segment}"
      ''
  # debug print
  debugPrint: ->
    string = ''
    string += if @radius? then 'arc' else 'line'
    string += " from #{@start[0]}, #{@start[1]} to #{@end[0]}, #{@end[1]}"
    if @radius? then string += "
      with radius #{@radius},
      large arc flag: #{@largeArc},
      sweep flag: #{@sweep}"
    console.log string
      
module.exports = (outline) ->
  # sanity check: first command should be a move to
  if outline[0] isnt 'M' then console.log "didn't start with 'M'"; return []
  loopStart = [ outline[1], outline[2] ]
  
  # going to do a good old-fashioned while loop for this one
  segments = []
  i = 0
  while i < outline.length - 1
    # check out current character to get our starting point
    # M and L have a point directly after them
    if outline[i] is 'M' or outline[i] is 'L'
      seg = new Segment [ outline[i+1], outline[i+2] ]
      i += 3
    # A (arc) has some other params we need to get by
    else if outline[i] is 'A'
      seg = new Segment [ outline[i+6], outline[i+7] ]
      i += 8
    # Z is an end of the path, so le'ts just move along
    else if outline[i] is 'Z'
      i++
      continue
    
    # check to make sure we're not out of bounds
    if i >= outline.length then seg = null; break
    
    # check our current character again to get the end of the segment
    if outline[i] is 'L' then seg.addEnd [ outline[i+1], outline[i+2] ]
    else if outline[i] is 'A'
      seg.addEnd [ outline[i+6], outline[i+7] ]
      seg.addArc outline[i+2], outline[i+4], outline[i+5]
    # M means a new path, so delete the segment and continue
    if outline[i] is 'M' then seg = null; continue 
    # Z is an end of the path, so draw a line directly to the start
    else if outline[i] is 'Z' then seg.addEnd loopStart
    
    # push this segment to the segments array
    segments.push seg
    
  # debug: print all our segments
  s.debugPrint() for s in segments
  # return segments
  segments
