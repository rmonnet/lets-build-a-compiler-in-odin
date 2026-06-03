package interpreter

import p "../pascal"
import "core:testing"

expect_output :: proc(t: ^testing.T, input: string, expected: string, loc := #caller_location) {

	c: Cradle
	p.wire_for_test(&c.io, input)
	defer p.io_destroy(&c.io)

	interpret(&c)
	actual := p.io_output(c.io)
	defer delete(actual)

	testing.expect_value(t, actual, expected, loc = loc)
}

@(test)
test_num :: proc(t: ^testing.T) {
	input :: "1"
	expected :: "1\n"

	expect_output(t, input, expected)
}

@(test)
test_add :: proc(t: ^testing.T) {
	input :: "1+2"
	expected :: "3\n"

	expect_output(t, input, expected)
}

@(test)
test_sub :: proc(t: ^testing.T) {
	input :: "1-2"
	expected :: "-1\n"

	expect_output(t, input, expected)
}

@(test)
test_unary :: proc(t: ^testing.T) {
	input :: "-1+1"
	expected :: "0\n"

	expect_output(t, input, expected)
}

