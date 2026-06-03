package interpreter

import p "../pascal"

/*
Cradle code
*/

// ---------------------------------------------------------------------------------------
// Constant Declarations

TAB :: '\t'
CR :: '\r'
TAB_STR :: "    "

// ---------------------------------------------------------------------------------------
// Variables Declarations
// We wrap the compiler state into a compiler object
// to allow multi-threaded Odin tests.
Cradle :: struct {
	look: rune,
	io:   p.IO,
}

// ---------------------------------------------------------------------------------------
// Read New Character From Input Stream
get_char :: proc(c: ^Cradle) {
	c.look = p.read(&c.io)
}

// ---------------------------------------------------------------------------------------
// Report an error
error :: proc(c: ^Cradle, args: ..any) {
	p.writeln(&c.io)
	p.write(&c.io, "Error: ")
	p.write(&c.io, ..args)
	p.writeln(&c.io, ".")
}

// ---------------------------------------------------------------------------------------
// Report Error and Halt
abort :: proc(c: ^Cradle, args: ..any) {
	error(c, ..args)
	p.halt(&c.io)
}

// ---------------------------------------------------------------------------------------
// Report What Was Expected
expected :: proc(c: ^Cradle, what: string) {
	abort(c, what, " Expected")
}

// ---------------------------------------------------------------------------------------
// Recognize an Alpha Character
is_alpha :: proc(ch: rune) -> bool {
	uc := p.upcase(ch)
	return 'A' <= uc && uc <= 'Z'
}

// ---------------------------------------------------------------------------------------
// Recognize a Decimal Digit
is_digit :: proc(ch: rune) -> bool {
	return '0' <= ch && ch <= '9'
}

// ---------------------------------------------------------------------------------------
// Recognize an Alphanumeric
is_alnum :: proc(ch: rune) -> bool {
	return is_alpha(ch) || is_digit(ch)
}

// ---------------------------------------------------------------------------------------
// Recognize an Addop
is_addop :: proc(c: rune) -> bool {
	return p.in_set(c, '+', '-')
}

// ---------------------------------------------------------------------------------------
// Recognize White Space
is_white :: proc(c: rune) -> bool {
	return p.in_set(c, ' ', TAB)
}

// ---------------------------------------------------------------------------------------
// Skip Over Leading White Space
skip_white :: proc(c: ^Cradle) {
	for is_white(c.look) {
		get_char(c)
	}
}

// ---------------------------------------------------------------------------------------
// Match a Specific Input Character
match :: proc(c: ^Cradle, ch: rune) {
	if c.look != ch {
		expected(c, p.str_cat("'", p.to_str(ch), "'"))
		return
	}
	get_char(c)
	skip_white(c)
}

// ---------------------------------------------------------------------------------------
// Get a Number
get_num :: proc(c: ^Cradle) -> int {
	if !is_digit(c.look) {expected(c, "Integer")}
	num := int(c.look - '0')
	get_char(c)
	return num
}

/*
The Interpreter code
*/

// ---------------------------------------------------------------------------------------
// Parse and Translate an Expression
expression :: proc(c: ^Cradle) -> int {
	value: int
	if is_addop(c.look) {
		value = 0
	} else {
		value = get_num(c)
	}
	for is_addop(c.look) {
		switch c.look {
		case '+':
			match(c, '+')
			value = value + get_num(c)
		case '-':
			match(c, '-')
			value = value - get_num(c)
		}
	}
	return value
}

// ---------------------------------------------------------------------------------------
// Initialize
init :: proc(c: ^Cradle) {
	get_char(c)
}

// ---------------------------------------------------------------------------------------
// The Interpreter Itself
interpret :: proc(c: ^Cradle) {
	init(c)
	p.writeln(&c.io, expression(c))
	// On Windows, a line ends with "...\r\n", so the last character read is '\r'.
	// On MacOs/Linux, a line ends with "...\n" so the last character read is 0.
	// Once we were properly skip spaces, they should both end in 0.
	if c.look != CR && c.look != p.EOF {
		expected(c, "Newline")
	}
}

// ---------------------------------------------------------------------------------------
// Main Program
main :: proc() {
	c: Cradle
	interpret(&c)
	// Only needed when reading from stdin on Git for Windows terminal.
	p.drain_term_buffer()
}

