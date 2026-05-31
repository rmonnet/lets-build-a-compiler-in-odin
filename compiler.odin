package compiler

// ---------------------------------------------------------------------------------------
// Constant Declarations

TAB :: '\t'
BELL :: '\a'

// ---------------------------------------------------------------------------------------
// Variables Declarations
look: rune

// ---------------------------------------------------------------------------------------
// Read New Character From Input Stream
getchar :: proc() {
	look = read()
}

// ---------------------------------------------------------------------------------------
// Report an error
error :: proc(s: string) {
	writeln()
	writeln(BELL, "Error: ", s, ".")
}

// ---------------------------------------------------------------------------------------
// Report Error and Halt
abort :: proc(s: string) {
	error(s)
	halt()
}

// ---------------------------------------------------------------------------------------
// Report What Was Expected
expected :: proc(s: string) {
	abort(st_cat(s, " Expected"))
}

// ---------------------------------------------------------------------------------------
// Match a Specific Input Character
match :: proc(x: rune) {
	if look == x {
		getchar()
	} else {
		expected(st_cat("'", ch_to_st(x), "'"))
	}
}

// ---------------------------------------------------------------------------------------
// Recognize an Alpha Character
is_alpha :: proc(c: rune) -> bool {
	uc := upcase(c)
	return 'A' <= uc && uc <= 'Z'
}

// ---------------------------------------------------------------------------------------
// Recognize a Decimal Digit
is_digit :: proc(c: rune) -> bool {
	return '0' <= c && c <= '9'
}

// ---------------------------------------------------------------------------------------
// Get an Identifier
get_name :: proc() -> rune {
	if !is_alpha(look) {expected("Name")}
	name := upcase(look)
	getchar()
	return name
}

// ---------------------------------------------------------------------------------------
// Get a Number
get_num :: proc() -> rune {
	if !is_digit(look) {expected("Integer")}
	num := look
	getchar()
	return num
}

// ---------------------------------------------------------------------------------------
// Output a String with Tab
emit :: proc(s: string) {
	write(TAB, s)
}

// ---------------------------------------------------------------------------------------
// Output a String with Tab and CRLF
emitln :: proc(s: string) {
	emit(s)
	writeln()
}

// ---------------------------------------------------------------------------------------
// Initialize
init :: proc() {
	getchar()
}

// Odin doesn't need forward declarations
// expression :: proc() ---

// ---------------------------------------------------------------------------------------
// Parse and Translate a Math Factor
factor :: proc() {
	// <factor> ::= (<expression>)
	if look == '(' {
		match('(')
		expression()
		match(')')
	} else {
		emitln(st_cat("MOVE #", ch_to_st(get_num()), ", D0"))
	}
}

// ---------------------------------------------------------------------------------------
// Recognize and Translate a Multiply
multiply :: proc() {
	match('*')
	factor()
	emitln("MULS (SP)+, D0")
}

// ---------------------------------------------------------------------------------------
// Recognize and Translate a Divide
divide :: proc() {
	match('/')
	factor()
	emitln("MOVE (SP)+,D1")
	emitln("EXG D0,D1") // <-- Crucial fix: Swap them so A is in D0
	emitln("EXT.L D0") // <-- Crucial fix: Preps 32-bit dividend
	emitln("DIVS D1,D0") // Calculates D0 (A) / D1 (B)
}

// ---------------------------------------------------------------------------------------
// Parse and Translate a Math Term
term :: proc() {
	// <term> ::= <factor>  [ <mulop> <factor ]*
	factor()
	for ch_in(look, '*', '/') {
		emitln("MOVE D0, -(SP)")
		switch look {
		case '*':
			multiply()
		case '/':
			divide()
		case:
			expected("Mulop")
		}
	}
}

// ---------------------------------------------------------------------------------------
// Recognize and Translate an Add
add :: proc() {
	match('+')
	term()
	emitln("ADD (SP)+, D0")
}

// ---------------------------------------------------------------------------------------
// Recognize and Translate a Subtract
subtract :: proc() {
	match('-')
	term()
	// TODO: why are we not using the same technic as in divide?
	emitln("SUB (SP)+, D0")
	emitln("NEG D0")
}

// ---------------------------------------------------------------------------------------
// Recognize an Addop
is_addop :: proc(c: rune) -> bool {
	return ch_in(c, '+', '-')
}

// ---------------------------------------------------------------------------------------
// Parse and Translate a Math Expression
expression :: proc() {
	// <expression> ::= <term> [<addop> <term>]*
	if is_addop(look) {
		emitln("CLR DO")
	} else {
		term()
	}
	for is_addop(look) {
		emitln("MOVE D0, -(SP)")
		switch look {
		case '+':
			add()
		case '-':
			subtract()
		case:
			expected("Addop")
		}
	}
}

// ---------------------------------------------------------------------------------------
// Main Program
main :: proc() {
	init()
	expression()
}
