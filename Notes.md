# Notes on Crenshaw Let's Build a Compiler

## Crenshaw's Book

I am using the version that have been converted to a nice MDBook [here](https://xmonader.github.io/letsbuildacompiler-pretty).

## Motorola 68K ASM

There is an assembler for 68K on mac.
- install with `brew install vasm`.
- run with `vasmM68K_mot -Fbin -o <name>.bin <name>.s`

Use [Tricky68k](https://github.com/shysaur/Tricky68k) as the CPU emulator.
You need a tiny 20-line C wrapper to load your `.bin` file into a simulated
array of bytes (RAM) and run the emulation loop.

There is also a Windows IDE [EASy68K](http://www.easy68k.com/) and a Web IDE [ASM Editor](https://asm-editor.specy.app/).
