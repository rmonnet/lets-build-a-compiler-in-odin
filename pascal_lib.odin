// This file contains Odin equivalent for Crenshaw's Pascal Library Procedures.
package compiler

import "core:fmt"
import "core:os"
import "core:strings"

/*
The following are Pascal library procedure used in Crenshaw's original code.

In order to keep our code as close to the original as possible, we replicate as
best as possible the behavior of the original Pascal procedure here.

We, however, account for Odin difference:
- Pascal `char` are translated to Odin `rune`
- Pascal `var` parameters, when obviously meant as output as converted to return values.
- Names follow the Odin convention (snake_case).

We want to be able to transparently redirect `stdin` to a `string` and `stdout` to a
`strings.Builder` for testing and this to be thread safe so we introduce an `IO` object
that takes care of it. There is one independent IO object per test.
*/

IO :: struct {
	// The following fields are used to wire tests to redirect IO to a string and a Builder.
	test:       bool,
	input:      string,
	input_next: int,
	output:     ^strings.Builder,
	halted:     bool,
}

// Deallocate the memory used for test IO.
io_destroy :: proc(io: ^IO) {
	if !io.test {
		panic("io_destroy() should only be called when wire_for_test() was called.")
	}
	delete(io.input)
	strings.builder_destroy(io.output)
	free(io.output)
}

io_output :: proc(io: IO) -> string {
	if !io.test {
		panic("io_output should only be called when wire_for_test() was called.")
	}
	// We make a copy since the caller is expected to cleanup returned strings.
	// (Assumed transfer of ownership)
	return strings.clone(strings.to_string(io.output^))
}

// Wire the Pascal Library IO to take input from a `string`
// and output to a `strings.Builder` for use in Odin tests.
//
wire_for_test :: proc(io: ^IO, input: string) {
	io.test = true
	io.input = strings.clone(input)
	io.output = new(strings.Builder)
	strings.builder_init(io.output)
}

// Pascal: Read(var v1, v2, ...: AnySimpleType)
// Reads from standard input.
read :: proc(io: ^IO) -> rune {
	if io.test {
		if io.input_next >= len(io.input) {return 0}
		io.input_next += 1
		return rune(io.input[io.input_next - 1])
	} else {
		buf: [1]byte
		n, err := os.read(os.stdin, buf[:])
		if err != nil || n == 0 {return 0}
		return rune(buf[0])
	}
}

// Pascal: Write(p1, p2, ...:AnyTypeOrLiteral)
// Write the arguments to standard output.
write :: proc(io: ^IO, strs: ..string) {
	if io.test {
		if io.halted {return}
		for str in strs {
			strings.write_string(io.output, str)
		}
	} else {
		for str in strs {
			fmt.print(str)
		}
	}
}

// Pascal: Writeln(p1, p2, ...:AnyTypeOrLiteral)
// Write the arguments to standard output followed by a newline.
writeln :: proc(io: ^IO, strs: ..string) {
	write(io, ..strs)
	write(io, "\n")
}

// Pascal:: Halt() or Halt(errCode)
// Exit the program back to the OS
halt :: proc(io: ^IO, err_code := 0) {
	if io.test {
		io.halted = true
		return
	}
	drain_term_buffer()
	os.exit(err_code)
}

// Pascal: UpCase(c: Char): Char
// Converts lower case a-z to upper case, any other character is unchanged
upcase :: proc(c: rune) -> rune {
	// Could also use unicode.to_upper() but this is closer to the Pascal spirit.
	if c < 'a' || c > 'z' {return c}
	return c - 'a' + 'A'
}

/*
The following are procedures accounting for difference between Pascal and Odin.
They are used to keep the Odin code as close as possible to Crenshaw's original Pascal code.
*/

// Pascal: string1 + string2 + ...
// Concatenate the strings
str_cat :: proc(strs: ..string) -> string {
	buf := strings.builder_make(context.temp_allocator)
	for str in strs {
		strings.write_string(&buf, str)
	}
	return strings.to_string(buf)
}

// Pascal: string | char
// This is used in: string + char + string
to_str :: proc(c: rune) -> string {
	buf := strings.builder_make(context.temp_allocator)
	strings.write_rune(&buf, c)
	return strings.to_string(buf)
}

// Pascal: Char in [...]
// Test if a character is in a list
in_set :: proc(c: rune, list: ..rune) -> bool {
	for cand in list {
		if c == cand {return true}
	}
	return false
}

// This routine is only needed for the Git for Windows bash.
// because it doesn't properly drain the current terminal buffer.
//
// Without calling this routine, the compiler may trip on leftover
// characters from the previous activation and show an error message
// hinting at bad input syntax when you haven't entered anything yet.
// I haven't seen this behavior on any other terminal emulator so far.
drain_term_buffer :: proc() {
	buf: [1]byte
	for {
		n, err := os.read(os.stdin, buf[:])
		if err != nil || n == 0 {break}
		if buf[0] == '\n' {break}
	}
}

