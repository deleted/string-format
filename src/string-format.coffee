# vim: ts=2:sw=2:expandtab
###
Source code and build tools for this file are available at:
https://github.com/deleted/string-format

This project attempts to implement python-style string formatting, as documented here:
http://docs.python.org/2/library/string.html#format-string-syntax

The format spec part is not complete, but it can handle field padding, float precision, and such
###
format = String::format = (args...) ->

  if args.length is 0
    return (args...) => @format args...

  idx = 0
  explicit = implicit = no
  message = 'cannot switch from {} to {} numbering'.format()

  @replace \
  /([{}])\1|[{](.*?)(?:!([^:]+?)?)?(?::(.+?))?[}]/g,
  (match, literal, key, transformer, formatSpec) ->
    return literal if literal

    if key.length
      explicit = yes
      throw new Error message 'implicit', 'explicit' if implicit
      value = lookup(args, key) ? ''
    else
      implicit = yes
      throw new Error message 'explicit', 'implicit' if explicit
      value = args[idx++] ? ''

    if formatSpec
      value = applyFormat value,  formatSpec
    else
      value = "#{value}"
    if fn = format.transformers[transformer] then fn.call(value) ? ''
    else value

lookup = (object, key) ->
  unless /^(\d+)([.]|$)/.test key
    key = '0.' + key
  while match = /(.+?)[.](.+)/.exec key
    object = resolve object, match[1]
    key = match[2]
  resolve object, key

resolve = (object, key) ->
  value = object[key]
  if typeof value is 'function' then value.call object else value

# An implementation of http://docs.python.org/2/library/string.html#format-specification-mini-language
applyFormat = (value, formatSpec) ->
  pattern = ///
    ([^{}](?=[<>=^]))?([<>=^])? # fill & align
    ([-+\x20])? # sign
    (\#)? # integer base specifier
    (0)? # zero-padding
    (\d+)? # width
    (,)? # use a comma thousands-seperator
    (?:\.(\d+))? # precision
    ([bcdeEfFgGnosxX%])? # type
  ///
  [fill, align, sign, hash, zeropad, width, comma, precision, type] = formatSpec.match(pattern)[1..]
  if zeropad
    fill or= '0'
    align or= '='
  align or= '>'
  fill or= ' '

  switch type
    when 'b', 'c', 'd', 'o', 'x', 'X', 'n' # integer
      isNumeric = yes
      value = '' + parseInt(value, 10)
    when 'e','E','f','F','g','G','n','%' # float
      isNumeric = true
      value = parseFloat(value)
      if precision
        value = value.toFixed(parseInt(precision))
      else
        value = "#{value}"
    when 's' #string
      isNumeric = false
      value = "#{value}"

  if isNumeric and sign
    if sign in ["+"," "]
        if value[0] != '-'
          value = sign + value
  
  ###
  if isNumeric and value.charAt(0) in "+-"
    memoSign = value.charAt 0
    value = value.substr 1
  ###

  if fill
    value = ''+value
    while value.length < parseInt(width)
      switch align
        when '='
          # Forces the padding to be placed after the sign (if any) but before the digits.
          if value.charAt(0) in "+- "
            value = value.charAt(0) + fill + value[1..]
          else
            value = fill + value
        when '<'
          # Forces the field to be left-aligned within the available space (this is the default for most objects).
          value = value + fill
        when '>'
          # Forces the field to be right-aligned within the available space (this is the default for numbers).
          value = fill + value
        when '^'
          throw new Error("Not implemented")

    #value = if memoSign then "#{memoSign}#{value}" else value

  return value

format.transformers or= {}

format.version = '0.2.1'
