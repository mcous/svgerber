# parse a standard github url into an github api url
module.exports = (url) ->
  # strip off the http and split by /
  url = url.match(/github\.com\S+/)?[0].split '/'
  if url?.length
    api = 'https://api.github.com/repos'
    owner = url[1]
    repo = url[2]
    branch = url[4]
    path = url[5..].join '/'
    url = "#{api}/#{owner}/#{repo}/contents/#{path}?ref=#{branch}"
  else
   false
