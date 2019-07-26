---
layout: post
title: Pretty Print XML
categories: [code]
tags: [python]
description: Pretty print XML in the console
---

Put this python file in your path to get the following:

![pretty printed xml](/assets/media/pxml.png)

{% highlight python %}
#!/usr/bin/env python

"""
Command-line tool to validate and pretty-print XML.

Based on `pjson` but without the crap.

Usage::

    $ echo '&lt;bunk atr="hello"&gt;world&lt;/bunk&gt;' | pxml
  &lt;?xml version="1.0" ?&gt;
  &lt;bunk atr="hello"&gt;
    world
  &lt;/bunk&gt;

Original Author: Igor Guerrero &lt;igfgt1@gmail.com&gt;, 2012
Contributor: Matthew Gill, 2012
"""

import xml.dom.minidom
import sys

from pygments import highlight
from pygments.formatters import TerminalFormatter
from pygments.lexers import XmlLexer

def format_xml_code(code):
    """
    Parses XML and formats it
    """
    x = xml.dom.minidom.parseString(code)
    return x.toprettyxml()

def color_yo_shit(code):
    """
    Calls pygments.highlight to color yo shit
    """
    return highlight(code, XmlLexer(), TerminalFormatter())

if __name__ == '__main__':
    code = format_xml_code(sys.stdin.read())
    print color_yo_shit(code)
{% endhighlight %}
The original can be found <a href="https://github.com/igorgue/pjson">here
(https://github.com/igorgue/pjson)</a>
