// This excursion only deals with control statements.
package control

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
	look:    rune,
	l_count: int,
	io:      p.IO,
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
// Get an Identifier
get_name :: proc(c: ^Cradle) -> string {
	token: p.PString
	if !is_alpha(c.look) {
		expected(c, "Name")
		return ""
	}
	for is_alnum(c.look) {
		p.pstr_append(&token, p.upcase(c.look))
		get_char(c)
	}
	skip_white(c)
	return p.pstr_to_str(token)
}

// ---------------------------------------------------------------------------------------
// Get a Number
get_num :: proc(c: ^Cradle) -> string {
	value: p.PString
	if !is_digit(c.look) {
		expected(c, "Integer")
		return ""
	}
	for is_digit(c.look) {
		p.pstr_append(&value, c.look)
		get_char(c)
	}
	skip_white(c)
	return p.pstr_to_str(value)
}

// ---------------------------------------------------------------------------------------
// Output a String with Tab
emit :: proc(c: ^Cradle, args: ..any) {
	p.write(&c.io, TAB_STR)
	p.write(&c.io, ..args)
}

// ---------------------------------------------------------------------------------------
// Output a String with Tab and CRLF
emitln :: proc(c: ^Cradle, args: ..any) {
	emit(c, ..args)
	p.writeln(&c.io)
}

/*
The Control code
*/

// ---------------------------------------------------------------------------------------
// Generate a Unique Label
new_label :: proc(c: ^Cradle) -> string {
	c.l_count += 1
	return fmt.tprintf("L%d", c.l_count - 1)
}

// ---------------------------------------------------------------------------------------
// Post a Label to Output
post_label :: proc(c: ^Cradle, label: string) {
	p.writeln(&c.io, label, ':')
}

// ---------------------------------------------------------------------------------------
// Recognize and Translate an "Other"
other :: proc(c: ^Cradle) -> string {
	name := get_name(c)
	emitln(c, name)
	return name
}

// ---------------------------------------------------------------------------------------
// Recognize and Translate a Statement Block
block :: proc(c: ^Cradle) {
	for !p.in_set(c.look, 'e') {
		name := other(c)
		if name == "" {break}
	}
}
// ---------------------------------------------------------------------------------------
// Parse and Translate a Program
program :: proc(c: ^Cradle) {
	block(c)
	if c.look != 'e' {
		expected(c, "End")
		return
	}
	emitln(c, "END")
}

// ---------------------------------------------------------------------------------------
// Initialize
init :: proc(c: ^Cradle) {
	get_char(c)
	skip_white(c)
}

// ---------------------------------------------------------------------------------------
// The Control Scaffold Itself
control :: proc(c: ^Cradle) {
	init(c)
	program(c)
}

// ---------------------------------------------------------------------------------------
// Main Program
main :: proc() {
	c: Cradle
	control(&c)
	// Only needed when reading from stdin on Git for Windows terminal.
	p.drain_term_buffer()
}

