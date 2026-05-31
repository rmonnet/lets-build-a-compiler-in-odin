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

## Crenshaw's Text

There is an error in chapter 2 for the code generation association with `A / B`.

The code in the original text:

```pascal
procedure Divide;
begin
   Match('/');
   Factor;
   EmitLn('MOVE (SP)+,D1');
   EmitLn('DIVS D1,D0');
end;
```

`A` is in the stack and `B` is in `D0`, `DIVS D1, D0` translates to `D0 = D1 / D0` which is `B = B / A` but we really want `A / B`, plus the result is in `D1` instead of `D0`.

The correct code is:

```pascal
procedure Divide;
begin
   Match('/');
   Factor;
   EmitLn('MOVE (SP)+,D1');
   EmitLn('EXG D0,D1');      // <-- Crucial fix: Swap them so A is in D0
   EmitLn('EXT.L D0');       // <-- Crucial fix: Preps 32-bit dividend
   EmitLn('DIVS D1,D0');     // Calculates D0 (A) / D1 (B)
end;
```

Which does `D1 = A, swap(A,B) (D0=A, D1=B), A = B / A` which is what we want.

## Optimization

There are different types of optimizations:

- peephole optimization looks at the generated code and clean it up.
- generate better code during parsing results in more code in the parser functions but can be done incrementally, **after** we got the compiler to work.
- use more registers to reduce stack manipulation, this can be done with CPUs that have more than a couple of registers (68000 has eight).
