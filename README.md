About
=====

This is a lightweight JSON library for Objective-C. It works on the iPhone and on the desktop. Most JSON parsers are NSScanner based which has a fair amount of overhead. I don't claim that this is the absolute fastest, but it is very lightweight.

The parser is written as a recursive descent parser, meaning that if you have extremely nested JSON, it is possible to run out of stack space. It is possible to convert this to a stack based parser instead of recursion, but all of my uses are from trusted sources. Additionally, at least two of the other popular JSON libraries also hinge on recursion.

This library currently does not have a JSON Generator, but that will be coming soon.

License
=======

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