package compiler

import p "../pascal"
import "core:testing"

expect_output :: proc(t: ^testing.T, input: string, expected: string, loc := #caller_location) {

	c: Cradle
	p.wire_for_test(&c.io, input)
	defer p.io_destroy(&c.io)

	compile(&c)
	actual := p.io_output(c.io)
	defer delete(actual)

	testing.expect_value(t, actual, expected, loc = loc)
}

@(test)
test_num :: proc(t: ^testing.T) {
	input :: "z=1"
	expected :: `    MOVE #1, D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_add :: proc(t: ^testing.T) {
	input :: "z=1+2"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    ADD (SP)+, D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_sub :: proc(t: ^testing.T) {
	input :: "z=1-2"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    SUB (SP)+, D0
    NEG D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_mul :: proc(t: ^testing.T) {
	input :: "z=1*2"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    MULS (SP)+, D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_div :: proc(t: ^testing.T) {
	input :: "z=1/2"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    MOVE (SP)+, D1
    EXG D0, D1
    EXS.L D0
    DIVS D1, D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_add_mul_precedence :: proc(t: ^testing.T) {
	input :: "z=1+2*3"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    MOVE D0, -(SP)
    MOVE #3, D0
    MULS (SP)+, D0
    ADD (SP)+, D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_grouping :: proc(t: ^testing.T) {
	input :: "z=(1+2)*3"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    ADD (SP)+, D0
    MOVE D0, -(SP)
    MOVE #3, D0
    MULS (SP)+, D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_unary_minus_start_of_expr :: proc(t: ^testing.T) {
	input :: "z=-1+2"
	expected :: `    CLR D0
    MOVE D0, -(SP)
    MOVE #1, D0
    SUB (SP)+, D0
    NEG D0
    MOVE D0, -(SP)
    MOVE #2, D0
    ADD (SP)+, D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_unary_minus_after_plus :: proc(t: ^testing.T) {
	input :: "z=1+-2"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)

Error: Integer Expected.
`
	expect_output(t, input, expected)
}

@(test)
test_unary_minus_after_paren :: proc(t: ^testing.T) {
	input :: "z=1+(-2)"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    CLR D0
    MOVE D0, -(SP)
    MOVE #2, D0
    SUB (SP)+, D0
    NEG D0
    ADD (SP)+, D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_variable :: proc(t: ^testing.T) {
	input :: "z=1+a"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE A(PC), D0
    ADD (SP)+, D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_call :: proc(t: ^testing.T) {
	input :: "z=1+a()"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    BSR A
    ADD (SP)+, D0
    LEA Z(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_incomplete_call :: proc(t: ^testing.T) {
	input :: "z=1+a("
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)

Error: ')' Expected.
`
	expect_output(t, input, expected)
}

@(test)
test_line_fully_consumed :: proc(t: ^testing.T) {
	input :: "z=1+2 3+4"
	expected :: `    MOVE #1, D0
    MOVE D0, -(SP)
    MOVE #2, D0
    ADD (SP)+, D0
    LEA Z(PC)A0
    MOVE D0, (A0)

Error: Newline Expected.
`
	expect_output(t, input, expected)
}

@(test)
test_multichar_identifier_and_number :: proc(t: ^testing.T) {
	input :: "abc=123"
	expected :: `    MOVE #123, D0
    LEA ABC(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

@(test)
test_whitespace :: proc(t: ^testing.T) {
	input :: "\t abc\t =\t 123"
	expected :: `    MOVE #123, D0
    LEA ABC(PC)A0
    MOVE D0, (A0)
`
	expect_output(t, input, expected)
}

