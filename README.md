# Arduino-avr-tools-install
Given Windows with some version of Arduino installed, set the paths to allow using avr-gcc/etc from the command line.

With WINAVR becoming unmaintained, various people including myself are starting to think that the easiest
way of getting a basic set of avr-gcc tools installed on your Windows system is to install Arduino, and
use the tools that it includes.

But they're buried rather deeply, and a bit of a pain to get to.

The idea with this project it to provide a simple (hah) and easy-to-use batch file that will
automatically set the paths for you. Hopefully it will work with a bunch of different versions of
Windows, and a bunch of different versions of Arduino.

See also https://hackaday.io/project/19935 for blog-like status reports.
