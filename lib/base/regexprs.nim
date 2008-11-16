#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Regular expression support for Nimrod.
## Currently this module is implemented by providing a wrapper around the
## `PRCE (Perl-Compatible Regular Expressions) <http://www.pcre.org>`_
## C library. This means that your application will depend on the PRCE
## library's licence when using this module, which should not be a problem
## though.
## PRCE's licence follows:
##
## .. include:: ../doc/regexprs.txt
##

# This is not just a convenient wrapper for the pcre library; the
# API will stay the same if the implementation should change.

import
  pcre, strutils

type
  EInvalidRegEx* = object of EInvalidValue
    ## is raised if the pattern is no valid regular expression.

const
  MaxSubpatterns* = 10
    ## defines the maximum number of subpatterns that can be captured.
    ## More subpatterns cannot be captured!

proc match*(s, pattern: string, matches: var openarray[string],
            start: int = 0): bool
  ## returns ``true`` if ``s`` matches the ``pattern[start..]`` and
  ## the captured substrings in the array ``matches``. If it does not
  ## match, nothing is written into ``matches`` and ``false`` is
  ## returned.

proc match*(s, pattern: string, start: int = 0): bool
  ## returns ``true`` if ``s`` matches the ``pattern`` beginning from ``start``.

proc matchLen*(s, pattern: string, matches: var openarray[string],
               start: int = 0): int
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, -1 is returned. Note that a match length
  ## of zero can happen.

proc find*(s, pattern: string, matches: var openarray[string],
           start: int = 0): bool
  ## returns ``true`` if ``pattern`` occurs in ``s`` and the captured
  ## substrings in the array ``matches``. If it does not match, nothing
  ## is written into ``matches``.
proc find*(s, pattern: string, start: int = 0): bool
  ## returns ``true`` if ``pattern`` occurs in ``s``.


proc rawCompile(pattern: string, flags: cint): PPcre =
  var
    msg: CString
    offset: int
    com = pcreCompile(pattern, flags, addr(msg), addr(offset), nil)
  if com == nil:
    var e: ref EInvalidRegEx
    new(e)
    e.msg = $msg & "\n" & pattern & "\n" & repeatChar(offset) & "^\n"
    raise e
  return com

proc matchOrFind(s: string, pattern: PPcre, matches: var openarray[string],
                 start: cint): cint =
  var
    rawMatches: array [0..maxSubpatterns * 3 - 1, cint]
    res = int(pcreExec(pattern, nil, s, len(s), start, 0,
      cast[ptr cint](addr(rawMatches)), maxSubpatterns * 3))
  dealloc(pattern)
  if res < 0: return res
  for i in 0..res-1:
    var
      a = rawMatches[i * 2]
      b = rawMatches[i * 2 + 1]
    if a >= 0'i32: matches[i] = copy(s, a, int(b)-1)
    else: matches[i] = ""
  return res

proc matchOrFind(s: string, pattern: PPcre, start: cint): cint =
  var
    rawMatches: array [0..maxSubpatterns * 3 - 1, cint]
    res = pcreExec(pattern, nil, s, len(s), start, 0,
                   cast[ptr cint](addr(rawMatches)), maxSubpatterns * 3)
  dealloc(pattern)
  return res

proc match(s, pattern: string, matches: var openarray[string],
           start: int = 0): bool =
  return matchOrFind(s, rawCompile(pattern, PCRE_ANCHORED),
                     matches, start) >= 0'i32

proc matchLen(s, pattern: string, matches: var openarray[string],
              start: int = 0): int =
  return matchOrFind(s, rawCompile(pattern, PCRE_ANCHORED), matches, start)

proc find(s, pattern: string, matches: var openarray[string],
          start: int = 0): bool =
  return matchOrFind(s, rawCompile(pattern, PCRE_MULTILINE),
                     matches, start) >= 0'i32

proc match(s, pattern: string, start: int = 0): bool =
  return matchOrFind(s, rawCompile(pattern, PCRE_ANCHORED), start) >= 0'i32

proc find(s, pattern: string, start: int = 0): bool =
  return matchOrFind(s, rawCompile(pattern, PCRE_MULTILINE), start) >= 0'i32
