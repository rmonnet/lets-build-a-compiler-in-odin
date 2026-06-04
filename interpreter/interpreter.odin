package interpreter

import p "../pascal"
import "core:crypto"
import "core:crypto/aead"
import "core:thread"

/*
Cradle code
*/

// ---------------------------------------------------------------------------------------
// Constant Declarations

TAB :: '\t'
CR :: '\r'
LF :: '\n'
TAB_STR :: "    "

// ---------------------------------------------------------------------------------------
// Define a Table of Variables where Variables names are a single uppercase character.
// Note: In Odin, an array of int is initialized to 0 so we don't need the `init_table`
// procedure.
Table :: [26]int

// ---------------------------------------------------------------------------------------
// Variables Declarations
// We wrap the compiler state into a compiler object
// to allow multi-threaded Odin tests.
Cradle :: struct {
	look:      rune,
	io:        p.IO,
	variables: Table,
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
get_name :: proc(c: ^Cradle) -> rune {
	if !is_alpha(c.look) {expected(c, "Name")}
	ident := p.upcase(c.look)
	get_char(c)
	skip_white(c)
	return ident
}

// ---------------------------------------------------------------------------------------
// Get a Number
get_num :: proc(c: ^Cradle) -> int {
	value := 0
	if !is_digit(c.look) {expected(c, "Integer")}
	for is_digit(c.look) {
		value = 10 * value + int(c.look - '0')
		get_char(c)
	}
	skip_white(c)
	return value
}

/*
The Interpreter code
*/

// ---------------------------------------------------------------------------------------
// Odin doesn't need forward declarations.
// expression :: proc(c: ^Cradle) -> int

// ---------------------------------------------------------------------------------------
// Parse and Compute a Factor
factor :: proc(c: ^Cradle) -> int {
	value: int
	if c.look == '(' {
		match(c, '(')
		value = expression(c)
		match(c, ')')
	} else if is_alpha(c.look) {
		value = c.variables[get_name(c) - 'A']
	} else {
		value = get_num(c)
	}
	return value
}

// ---------------------------------------------------------------------------------------
// Parse and Compute a Term
term :: proc(c: ^Cradle) -> int {
	value := factor(c)
	for p.in_set(c.look, '*', '/') {
		switch c.look {
		case '*':
			match(c, '*')
			value = value * factor(c)
		case '/':
			match(c, '/')
			value = value / factor(c)
		}
	}
	return value
}

// ---------------------------------------------------------------------------------------
// Parse and Compute an Expression
expression :: proc(c: ^Cradle) -> int {
	value: int
	if is_addop(c.look) {
		// Note how this gives us unary +/- for free.
		// It appends a 0 in front of any add/sub operator.
		value = 0
	} else {
		value = term(c)
	}
	for is_addop(c.look) {
		switch c.look {
		case '+':
			match(c, '+')
			value = value + term(c)
		case '-':
			match(c, '-')
			value = value - term(c)
		}
	}
	return value
}

// ---------------------------------------------------------------------------------------
// Parse and Compute an Assignment
// This version returns the variable assigned to.
assignment :: proc(c: ^Cradle) -> rune {
	var := get_name(c)
	match(c, '=')
	c.variables[var - 'A'] = expression(c)
	return var
}

// ---------------------------------------------------------------------------------------
// Initialize
init :: proc(c: ^Cradle) {
	// Since c.variables is initialized by Odin to 0, there is no need to call init_table().
	get_char(c)
	skip_white(c)
}

// ---------------------------------------------------------------------------------------
// Recognize and Skip Over a Newline
new_line :: proc(c: ^Cradle) {
	if c.look == CR {
		get_char(c)
		match(c, LF)
	} else if c.look == LF {
		get_char(c)
	}
}

// ---------------------------------------------------------------------------------------
// Input Routine
input :: proc(c: ^Cradle) -> rune {
	match(c, '?')
	// Note: Crenshaw's original code use Pascal's `Read()` which is a powerful
	// procedure that can read (and convert) pretty much anything.
	// In this case, Crenshaw has it read and parse an integer.
	// We will instead use the Parser facilities to explicitly read
	// an integer.
	var := get_name(c)
	if !is_digit(c.look) {
		expected(c, "Number")
		return var
	}
	c.variables[var - 'A'] = get_num(c)
	return var
}

// ---------------------------------------------------------------------------------------
// Output Routine
output :: proc(c: ^Cradle) {
	match(c, '!')
	p.writeln(&c.io, c.variables[get_name(c) - 'A'])
}

// ---------------------------------------------------------------------------------------
// The Interpreter Itself
interpret :: proc(c: ^Cradle) {
	// Note: This interpreter doesn't handle properly the case "c+1".
	// This would require a look-ahead to check if the character after the
	// variable name is a '=' operator.
	// We will leave it alone for now since there is more in the following chapters
	// and this was not in scope of Crenshaw's original example.
	init(c)
	for c.look != '.' {
		switch {
		case c.look == '?':
			var := input(c)
			p.writeln(&c.io, "> ", var, " = ", c.variables[var - 'A'])
		case c.look == '!':
			output(c)
		case is_alpha(c.look):
			var := assignment(c)
			p.writeln(&c.io, "> ", var, " = ", c.variables[var - 'A'])
		case:
			value := expression(c)
			p.writeln(&c.io, "> ", value)
		}
		new_line(c)
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

