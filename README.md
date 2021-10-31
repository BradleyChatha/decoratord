# Overview

Decorator is a simple library for adding comments onto lines of text, primarily aimed at user-friendly error messages.

The colouring abilities are powered by [JANSI](https://github.com/BradleyChatha/jansi), a betterC compatible ANSI library.

For example:

![image](https://user-images.githubusercontent.com/3835574/138582615-02f3edb5-51ba-4af3-9edf-03fc901d2d8e.png)

The above output was generated from the following code:

```d
import core.stdc.stdio;
DecoratorBC!(1, 1, 1, 3) d;

d.addLine("printf(\"%s\", 400)", "main.c", 5);
d.colourLine(0, 0, 6, AnsiStyleSet.init.fg(Ansi4BitColour.yellow));
d.colourLine(0, 7, 11, AnsiStyleSet.init.fg(Ansi4BitColour.magenta));
d.colourLine(0, 13, 16, AnsiStyleSet.init.fg(Ansi4BitColour.cyan));

d.addTopComment(0, 8, "%s was specified.");
d.colourTopComment(0, 0, 0, 3, AnsiStyleSet.init.fg(Ansi4BitColour.green));

d.addBotComment(0, 13, "But a %d value was passed");
d.colourBotComment(0, 0, 6, 8, AnsiStyleSet.init.fg(Ansi4BitColour.red));

d.toString((const(char)[] str){ printf("%.*s", cast(int)str.length, str.ptr); });
```
