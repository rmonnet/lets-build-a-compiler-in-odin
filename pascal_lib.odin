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
*/

// Pascal: Read(var v1, v2, ...: AnySimpleType)
// Reads from standard input.
read :: proc() -> rune {

	buf: [1]byte
	n, err := os.read(os.stdin, buf[:])
	if err != nil || n == 0 {
		return 0
	}
	return rune(buf[0])
}

// Pascal: Write(p1, p2, ...:AnyTypeOrLiteral)
// Write the arguments to standard output.
write :: proc(fragments: ..any) {
	for f in fragments {
		fmt.print(f)
	}
}

// Pascal: Writeln(p1, p2, ...:AnyTypeOrLiteral)
// Write the arguments to standard output followed by a newline.
writeln :: proc(fragments: ..any) {
	write(..fragments)
	write('\n')
}

// Pascal:: Halt() or Halt(errCode)
// Exit the program back to the OS
halt :: proc(err_code := 0) {
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
st_cat :: proc(strs: ..string) -> string {
	buf := strings.builder_make(context.temp_allocator)
	for str in strs {
		strings.write_string(&buf, str)
	}
	return strings.to_string(buf)
}

// Pascal: string | char
// This is used in: string + char + string
ch_to_st :: proc(c: rune) -> string {
	buf := strings.builder_make(context.temp_allocator)
	strings.write_rune(&buf, c)
	return strings.to_string(buf)
}

// Pascal: Char in [...]
// Test if a character is in a list
ch_in :: proc(c: rune, list: ..rune) -> bool {
	for cand in list {
		if c == cand {return true}
	}
	return false
}
