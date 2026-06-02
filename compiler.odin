package compiler

// ---------------------------------------------------------------------------------------
// Constant Declarations

TAB :: '\t'
TAB_STR :: "\t"
BELL_STR :: "\a"

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
error :: proc(c: ^Compiler, msg: string) {
	writeln(&c.io)
	writeln(&c.io, str_cat("Error: ", msg, "."))
}

// ---------------------------------------------------------------------------------------
// Report Error and Halt
abort :: proc(c: ^Compiler, msg: string) {
	error(c, msg)
	halt(&c.io)
}

// ---------------------------------------------------------------------------------------
// Report What Was Expected
expected :: proc(c: ^Compiler, what: string) {
	abort(c, str_cat(what, " Expected"))
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
get_name :: proc(c: ^Compiler) -> rune {
	if !is_alpha(c.look) {expected(c, "Name")}
	name := upcase(c.look)
	get_char(c)
	return name
}

// ---------------------------------------------------------------------------------------
// Get a Number
get_num :: proc(c: ^Compiler) -> rune {
	if !is_digit(c.look) {expected(c, "Integer")}
	num := c.look
	get_char(c)
	return num
}

// ---------------------------------------------------------------------------------------
// Output a String with Tab
emit :: proc(c: ^Compiler, s: string) {
	write(&c.io, TAB_STR, s)
}

// ---------------------------------------------------------------------------------------
// Output a String with Tab and CRLF
emitln :: proc(c: ^Compiler, s: string) {
	emit(c, s)
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
// Parse and Translate a Math Factor
factor :: proc(c: ^Compiler) {
	// <factor> ::= (<expression>)
	if c.look == '(' {
		match(c, '(')
		expression(c)
		match(c, ')')
	} else {
		emitln(c, str_cat("MOVE #", to_str(get_num(c)), ", D0"))
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
		case:
			expected(c, "Mulop")
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
		emitln(c, "CLR DO")
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
		case:
			expected(c, "Addop")
		}
	}
}

// ---------------------------------------------------------------------------------------
// The Compiler Itself
compile :: proc(c: ^Compiler) {
	init(c)
	expression(c)
}

// ---------------------------------------------------------------------------------------
// Main Program
main :: proc() {
	c: Compiler
	compile(&c)
	// Only needed when reading from stdin on Git for Windows terminal.
	drain_term_buffer()
}

