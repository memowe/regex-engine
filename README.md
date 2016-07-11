REE - Regular Expression Engine
===============================

This is a toy project to get a better understanding of how regular expression
engines work. REE can build parse trees and compile working NFA representations
of (simple) regular expressions. This can be accessed via a simple public
interface.

## Usage Example

    use feature 'say';
    use REE;

    # matching
    my $ree     = REE->new(regex => '(foo|bar)*baz');
    my $string  = "foobarbaz";
    say "$string matches" if $ree->match($string);

    # meta information
    say 'canonical regex: ' . $ree->canonical_regex;
    say 'NFA representation: ';
    say $ree->nfa_representation;

## Current Limitations

REE is currently missing support for the *optional quantifier* `?`.

## Web Interface

There is a simple [web interface for REE](https://algo-git.uni-muenster.de/memowe/regex-engine-web).

## License and Copyright

Copyright 2016 Mirko Westermeier.

This program is distributed under the [MIT (X11) License](http://www.opensource.org/licenses/mit-license.php) 

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
