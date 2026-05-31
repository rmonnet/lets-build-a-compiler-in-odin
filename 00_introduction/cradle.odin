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
	writeln('a', "Error: ", s, ".")
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
	abort(str_cat(s, " Expected"))
}

// ---------------------------------------------------------------------------------------
// Match a Specific Input Character
match :: proc(x: rune) {
	if look == x {
		getchar()
	} else {
		expected(str_cat("'", char_to_str(x), "'"))
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

// ---------------------------------------------------------------------------------------
// Main Program
main :: proc() {
	init()
}
