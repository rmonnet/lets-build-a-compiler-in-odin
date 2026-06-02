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
	expect_output(t, "1", "\tMOVE #1, D0\n")
}

@(test)
test_add :: proc(t: ^testing.T) {
	expected :: "\tMOVE #1, D0\n" + "\tMOVE D0, -(SP)\n" + "\tMOVE #2, D0\n" + "\tADD (SP)+, D0\n"
	expect_output(t, "1+2", expected)
}

@(test)
test_sub :: proc(t: ^testing.T) {
	expected ::
		"\tMOVE #1, D0\n" +
		"\tMOVE D0, -(SP)\n" +
		"\tMOVE #2, D0\n" +
		"\tSUB (SP)+, D0\n" +
		"\tNEG D0\n"
	expect_output(t, "1-2", expected)
}

@(test)
test_mul :: proc(t: ^testing.T) {
	expected :: "\tMOVE #1, D0\n" + "\tMOVE D0, -(SP)\n" + "\tMOVE #2, D0\n" + "\tMULS (SP)+, D0\n"
	expect_output(t, "1*2", expected)
}

@(test)
test_div :: proc(t: ^testing.T) {
	expected ::
		"\tMOVE #1, D0\n" +
		"\tMOVE D0, -(SP)\n" +
		"\tMOVE #2, D0\n" +
		"\tMOVE (SP)+, D1\n" +
		"\tEXG D0, D1\n" +
		"\tEXT.L D0\n" +
		"\tDIVS D1, D0\n"
	expect_output(t, "1/2", expected)
}

@(test)
test_add_mul_precedence :: proc(t: ^testing.T) {
	expected ::
		"\tMOVE #1, D0\n" +
		"\tMOVE D0, -(SP)\n" +
		"\tMOVE #2, D0\n" +
		"\tMOVE D0, -(SP)\n" +
		"\tMOVE #3, D0\n" +
		"\tMULS (SP)+, D0\n" +
		"\tADD (SP)+, D0\n"
	expect_output(t, "1+2*3", expected)
}

@(test)
test_grouping :: proc(t: ^testing.T) {
	expected ::
		"\tMOVE #1, D0\n" +
		"\tMOVE D0, -(SP)\n" +
		"\tMOVE #2, D0\n" +
		"\tADD (SP)+, D0\n" +
		"\tMOVE D0, -(SP)\n" +
		"\tMOVE #3, D0\n" +
		"\tMULS (SP)+, D0\n"
	expect_output(t, "(1+2)*3", expected)
}

@(test)
test_unary_minus_start_of_expr :: proc(t: ^testing.T) {
	expected ::
		"\tCLR DO\n" +
		"\tMOVE D0, -(SP)\n" +
		"\tMOVE #1, D0\n" +
		"\tSUB (SP)+, D0\n" +
		"\tNEG D0\n" +
		"\tMOVE D0, -(SP)\n" +
		"\tMOVE #2, D0\n" +
		"\tADD (SP)+, D0\n"
	expect_output(t, "-1+2", expected)
}

@(test)
test_unary_minus_after_plus :: proc(t: ^testing.T) {
	expected :: "\tMOVE #1, D0\n" + "\tMOVE D0, -(SP)\n" + "\nError: Integer Expected.\n"
	expect_output(t, "1+-2", expected)
}

@(test)
test_unary_minus_after_paren :: proc(t: ^testing.T) {
	expected ::
		"\tMOVE #1, D0\n" +
		"\tMOVE D0, -(SP)\n" +
		"\tCLR DO\n" +
		"\tMOVE D0, -(SP)\n" +
		"\tMOVE #2, D0\n" +
		"\tSUB (SP)+, D0\n" +
		"\tNEG D0\n" +
		"\tADD (SP)+, D0\n"
	expect_output(t, "1+(-2)", expected)
}

