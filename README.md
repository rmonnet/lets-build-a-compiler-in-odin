# Let's Build a Compiler in Odin

This repository contains an Odin implementation of the code in Jack Crenshaw [Let's Build a Compiler](https://compilers.iecc.com/crenshaw/).
If you find the original text hard to read, there is a nice MDBook version available [here](https://xmonader.github.io/letsbuildacompiler-pretty).

The original code is in Pascal and, as I was following along, I implemented it in [Odin](odin-lang.org).
The translation is as close to the original code as possible, not because this is the best style for Odin, but because it helps follow along.
Odin is a imperative language which borrows a lot from Pascal and C, you should not have any problem following along without learning the language first.

## Prerequisite

If you want to compile the code, you will need to install the [Odin compiler](https://odin-lang.org/docs/install/).
There are releases for Windows, MacOs, and Linux.

There are extensions for VSCode, vim, and Zed if you are interested.

## Copyright and License

The original [text and code](https://compilers.iecc.com/crenshaw/) is copyrighted (c) 1988 Jack Crenshaw.

I couldn't find a license for the original work so I am releasing the Odin code under the [Creative Common](LICENSE) license.
The Odin code is copyrighted (c) 2026 Robert Monnet.

## Code Organization

Each chapter has its own sub-directory, since Odin packages correspond to a directory, you can just `cd` into the appropriate chapter directory and type `odin run .` to run the main driver for that chapter.
