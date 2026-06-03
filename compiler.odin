package compiler

/*
Cradle code
*/

// ---------------------------------------------------------------------------------------
// Constant Declarations

TAB :: '\t'
CR :: '\r'
EOF :: 0
TAB_STR :: "    "

// ---------------------------------------------------------------------------------------
// Variables Declarations
// We wrap the compiler state into a compiler object
// to allow multi-threaded Odin tests.
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
// Recognize an Alphanumeric
is_alnum :: proc(ch: rune) -> bool {
	return is_alpha(ch) || is_digit(ch)
}

// ---------------------------------------------------------------------------------------
// Recognize an Addop
is_addop :: proc(c: rune) -> bool {
	return in_set(c, '+', '-')
}

// ---------------------------------------------------------------------------------------
// Recognize White Space
is_white :: proc(c: rune) -> bool {
	return in_set(c, ' ', TAB)
}

// ---------------------------------------------------------------------------------------
// Skip Over Leading White Space
skip_white :: proc(c: ^Compiler) {
	for is_white(c.look) {
		get_char(c)
	}
}

// ---------------------------------------------------------------------------------------
// Match a Specific Input Character
match :: proc(c: ^Compiler, ch: rune) {
	if c.look != ch {
		expected(c, str_cat("'", to_str(ch), "'"))
		return
	}
	get_char(c)
	skip_white(c)
}

// ---------------------------------------------------------------------------------------
// Get an Identifier
get_name :: proc(c: ^Compiler) -> string {
	token: PString
	if !is_alpha(c.look) {expected(c, "Name")}
	for is_alnum(c.look) {
		pstr_append(&token, upcase(c.look))
		get_char(c)
	}
	skip_white(c)
	return pstr_to_str(token)
}

// ---------------------------------------------------------------------------------------
// Get a Number
get_num :: proc(c: ^Compiler) -> string {
	value: PString
	if !is_digit(c.look) {expected(c, "Integer")}
	for is_digit(c.look) {
		pstr_append(&value, c.look)
		get_char(c)
	}
	skip_white(c)
	return pstr_to_str(value)
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

/*
The Parser code
*/

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

// Odin doesn't need forward declarations
// expression :: proc() ---

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
	emitln(c, "EXS.L D0") // <-- Crucial fix: Preps 32-bit dividend
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
// Parse and Translate an Expression
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
// Parse and Translate an Assignment Statement
assignment :: proc(c: ^Compiler) {
	name := get_name(c)
	match(c, '=')
	expression(c)
	emitln(c, "LEA ", name, "(PC)A0")
	emitln(c, "MOVE D0, (A0)")
}

// ---------------------------------------------------------------------------------------
// Initialize
init :: proc(c: ^Compiler) {
	get_char(c)
	skip_white(c)
}

// ---------------------------------------------------------------------------------------
// The Compiler Itself
compile :: proc(c: ^Compiler) {
	init(c)
	assignment(c)
	// On Windows, a line ends with "...\r\n", so the last character read is '\r'.
	// On MacOs/Linux, a line ends with "...\n" so the last character read is 0.
	// Once we were properly skip spaces, they should both end in 0.
	if c.look != CR && c.look != EOF {
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

