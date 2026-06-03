# Let's Build a Compiler in Odin

This repository contains an Odin implementation of the code in Jack Crenshaw [Let's Build a Compiler](https://compilers.iecc.com/crenshaw/).
If you find the original text hard to read, there is a nice MDBook version available [here](https://xmonader.github.io/letsbuildacompiler-pretty).

## Deviations From the Original

The original code is in Pascal and, as I was following along, I implemented it in [Odin](odin-lang.org).
The translation is as close to the original code as possible, not because this is the best style for Odin, but because it helps follow along.
Odin is a imperative language which borrows a lot from Pascal and C, you should have no problem following along without learning the language first.

Where I had to deviate from the original code:

- I built a minimal Pascal library (in `pascal/pascal_lib.odin`) for functions provided by the pascal compiler such as `Read`.
- Because Odin test runner is multi-threaded, I had to remove the global state and move it into a `Compiler` object which is passed to each parsing procedure.
- Also to be able to test, I needed to redirect the compiler input and output from `stdin`/`stdout` to a `string` and a `strings.Builder` (string buffer) respectively.
  This is wrapped into an `IO` object in the Pascal pseudo-library and each Pascal `IO` function uses it to determine how to direct the input and output streams.

## Prerequisite

If you want to compile the code, you will need to install the [Odin compiler](https://odin-lang.org/docs/install/).
There are releases for Windows, MacOs, and Linux.

I use The [Just](https://github.com/casey/just) package manager to gather all my commands into one script (`Justfile`). The commands are self-explanatory if you don't want to use it, just look in `Justfile`.
You can install just with you favorite package manager (brew on macOs, scoop on Windows, your distro package manager on Linux).

There are Odin language server extensions for VSCode, vim, and Zed if you are interested.

## Copyright and License

The original [text and code](https://compilers.iecc.com/crenshaw/) is copyrighted (c) 1988 Jack Crenshaw.

I couldn't find a license for the original work so I am releasing the Odin code under the [Creative Common](LICENSE) license.
The Odin code is copyrighted (c) 2026 Robert Monnet.

## Code Organization

The code can be found under the repository root.
- `compiler/compiler.odin` contains the compiler.
- `compiler/compiler_test.odin` contains the compiler tests.
- `interpreter/interpreter.odin` contains the interpreter from chapter 4.
- `interpreter/interpreter_test.odin` contains the interpreter tests.
- `pascal/pascal_lib.odin` contains Odin emulation for the procedures from the original Pascal library.

Each chapter correspond to a git tag and can be retrieved by typing `git checkout <chapter>`.
- `01-Introduction`
- `02-Expression-Parsing`
- `03-More-Expressions`
- `04-Interpreters`

If you plan to play with the code, the best way to keep your changes isolated to a chapter is to create your own branch: `git checkout -b <review-chapter> <chapter>`.
