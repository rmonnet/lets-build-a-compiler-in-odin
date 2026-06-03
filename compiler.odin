package compiler

// ---------------------------------------------------------------------------------------
// Constant Declarations

TAB :: '\t'
TAB_STR :: "    "

// ---------------------------------------------------------------------------------------
// Variables Declarations
Compiler :: struct {
	look: rune,
	io:   IO,
}

// ---------------------------------------------------------------------------------------
// Read New Character From Input Stream
get_char :: proc(c: ^Compiler) {
	c.look = read(&c.io)
}

// ---------------------------------------------------------------------------------------
// Report an error
error :: proc(c: ^Compiler, strs: ..string) {
	writeln(&c.io)
	write(&c.io, "Error: ")
	write(&c.io, ..strs)
	writeln(&c.io, ".")
}

// ---------------------------------------------------------------------------------------
// Report Error and Halt
abort :: proc(c: ^Compiler, strs: ..string) {
	error(c, ..strs)
	halt(&c.io)
}

// ---------------------------------------------------------------------------------------
// Report What Was Expected
expected :: proc(c: ^Compiler, what: string) {
	abort(c, what, " Expected")
}

// ---------------------------------------------------------------------------------------
// Match a Specific Input Character
match :: proc(c: ^Compiler, ch: rune) {
	if c.look == ch {
		get_char(c)
	} else {
		expected(c, str_cat("'", to_str(ch), "'"))
	}
}

// ---------------------------------------------------------------------------------------
// Recognize an Alpha Character
is_alpha :: proc(ch: rune) -> bool {
	uc := upcase(ch)
	return 'A' <= uc && uc <= 'Z'
}

// ---------------------------------------------------------------------------------------
// Recognize a Decimal Digit
is_digit :: proc(ch: rune) -> bool {
	return '0' <= ch && ch <= '9'
}

// ---------------------------------------------------------------------------------------
// Get an Identifier
get_name :: proc(c: ^Compiler) -> string {
	if !is_alpha(c.look) {expected(c, "Name")}
	name := upcase(c.look)
	get_char(c)
	return to_str(name)
}

// ---------------------------------------------------------------------------------------
// Get a Number
get_num :: proc(c: ^Compiler) -> string {
	if !is_digit(c.look) {expected(c, "Integer")}
	num := c.look
	get_char(c)
	return to_str(num)
}

// ---------------------------------------------------------------------------------------
// Output a String with Tab
emit :: proc(c: ^Compiler, strs: ..string) {
	write(&c.io, TAB_STR)
	write(&c.io, ..strs)
}

// ---------------------------------------------------------------------------------------
// Output a String with Tab and CRLF
emitln :: proc(c: ^Compiler, strs: ..string) {
	emit(c, ..strs)
	writeln(&c.io)
}

// ---------------------------------------------------------------------------------------
// Initialize
init :: proc(c: ^Compiler) {
	get_char(c)
}

// Odin doesn't need forward declarations
// expression :: proc() ---

// ---------------------------------------------------------------------------------------
// Parse and Translate an Identifier
ident :: proc(c: ^Compiler) {
	name := get_name(c)
	if c.look == '(' {
		match(c, '(')
		match(c, ')')
		emitln(c, "BSR ", name)
	} else {
		emitln(c, "MOVE ", name, "(PC), D0")
	}
}

// ---------------------------------------------------------------------------------------
// Parse and Translate a Math Factor
factor :: proc(c: ^Compiler) {
	// <factor> ::= <number> | (<expression>) | <variable>
	if c.look == '(' {
		match(c, '(')
		expression(c)
		match(c, ')')
	} else if is_alpha(c.look) {
		ident(c)
	} else {
		emitln(c, "MOVE #", get_num(c), ", D0")
	}
}

// ---------------------------------------------------------------------------------------
// Recognize and Translate a Multiply
multiply :: proc(c: ^Compiler) {
	match(c, '*')
	factor(c)
	emitln(c, "MULS (SP)+, D0")
}

// ---------------------------------------------------------------------------------------
// Recognize and Translate a Divide
divide :: proc(c: ^Compiler) {
	match(c, '/')
	factor(c)
	emitln(c, "MOVE (SP)+, D1")
	emitln(c, "EXG D0, D1") // <-- Crucial fix: Swap them so A is in D0
	emitln(c, "EXT.L D0") // <-- Crucial fix: Preps 32-bit dividend
	emitln(c, "DIVS D1, D0") // Calculates D0 (A) / D1 (B)
}

// ---------------------------------------------------------------------------------------
// Parse and Translate a Math Term
term :: proc(c: ^Compiler) {
	// <term> ::= <factor>  [ <mulop> <factor ]*
	factor(c)
	for in_set(c.look, '*', '/') {
		emitln(c, "MOVE D0, -(SP)")
		switch c.look {
		case '*':
			multiply(c)
		case '/':
			divide(c)
		}
	}
}

// ---------------------------------------------------------------------------------------
// Recognize and Translate an Add
add :: proc(c: ^Compiler) {
	match(c, '+')
	term(c)
	emitln(c, "ADD (SP)+, D0")
}

// ---------------------------------------------------------------------------------------
// Recognize and Translate a Subtract
subtract :: proc(c: ^Compiler) {
	match(c, '-')
	term(c)
	// TODO: why are we not using the same technic as in divide?
	emitln(c, "SUB (SP)+, D0")
	emitln(c, "NEG D0")
}

// ---------------------------------------------------------------------------------------
// Recognize an Addop
is_addop :: proc(c: rune) -> bool {
	return in_set(c, '+', '-')
}

// ---------------------------------------------------------------------------------------
// Parse and Translate a Math Expression
expression :: proc(c: ^Compiler) {
	// <expression> ::= [<unaryop>] <term> [<addop> <term>]*

	// Note: The unary ops are only allowed at the beginning of an expression in this compiler.
	// I.E. "-1+2" is allowed but "2+-1" is not. To express this we would need to type "2+(-1)".
	// If we wanted to allow "2+-1", we would need to move unary ops at the beginning of factor
	// to increase their priority.
	if is_addop(c.look) {
		emitln(c, "CLR D0")
	} else {
		term(c)
	}
	for is_addop(c.look) {
		emitln(c, "MOVE D0, -(SP)")
		switch c.look {
		case '+':
			add(c)
		case '-':
			subtract(c)
		}
	}
}

// ---------------------------------------------------------------------------------------
// The Compiler Itself
compile :: proc(c: ^Compiler) {
	init(c)
	expression(c)
	// On Windows, a line ends with "...\r\n", so the last character read is '\r'.
	// On MacOs/Linux, a line ends with "...\n" so the last character read is 0.
	// Once we were properly skip spaces, they should both end in 0.
	if c.look != '\r' && c.look != 0 {
		expected(c, "Newline")
	}
}

// ---------------------------------------------------------------------------------------
// Main Program
main :: proc() {
	c: Compiler
	compile(&c)
	// Only needed when reading from stdin on Git for Windows terminal.
	drain_term_buffer()
}

