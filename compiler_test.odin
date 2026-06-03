package compiler

import "core:testing"

expect_output :: proc(t: ^testing.T, input: string, expected: string, loc := #caller_location) {

	c: Compiler
	wire_for_test(&c.io, input)
	defer io_destroy(&c.io)

	compile(&c)
	actual := io_output(c.io)
	defer delete(actual)

	testing.expect_value(t, actual, expected, loc = loc)
}

@(test)
test_num :: proc(t: ^testing.T) {
	expect_output(t, "1", "    MOVE #1, D0\n")
}

@(test)
test_add :: proc(t: ^testing.T) {
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    ADD (SP)+, D0
`
	expect_output(t, "1+2", expected)
}

@(test)
test_sub :: proc(t: ^testing.T) {
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    SUB (SP)+, D0
    NEG D0
`
	expect_output(t, "1-2", expected)
}

@(test)
test_mul :: proc(t: ^testing.T) {
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    MULS (SP)+, D0
`
	expect_output(t, "1*2", expected)
}

@(test)
test_div :: proc(t: ^testing.T) {
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    MOVE (SP)+, D1
    EXG D0, D1
    EXT.L D0
    DIVS D1, D0
`
	expect_output(t, "1/2", expected)
}

@(test)
test_add_mul_precedence :: proc(t: ^testing.T) {
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    MOVE D0, -(SP)
    MOVE #3, D0
    MULS (SP)+, D0
    ADD (SP)+, D0
`
	expect_output(t, "1+2*3", expected)
}

@(test)
test_grouping :: proc(t: ^testing.T) {
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    ADD (SP)+, D0
    MOVE D0, -(SP)
    MOVE #3, D0
    MULS (SP)+, D0
`
	expect_output(t, "(1+2)*3", expected)
}

@(test)
test_unary_minus_start_of_expr :: proc(t: ^testing.T) {
	expected :: `    CLR D0
    MOVE D0, -(SP)
    MOVE #1, D0
    SUB (SP)+, D0
    NEG D0
    MOVE D0, -(SP)
    MOVE #2, D0
    ADD (SP)+, D0
`
	expect_output(t, "-1+2", expected)
}

@(test)
test_unary_minus_after_plus :: proc(t: ^testing.T) {
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)

Error: Integer Expected.
`
	expect_output(t, "1+-2", expected)
}

@(test)
test_unary_minus_after_paren :: proc(t: ^testing.T) {
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    CLR D0
    MOVE D0, -(SP)
    MOVE #2, D0
    SUB (SP)+, D0
    NEG D0
    ADD (SP)+, D0
`
	expect_output(t, "1+(-2)", expected)
}

