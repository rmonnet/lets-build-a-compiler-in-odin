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

	expect_output(t, "1", "1\n")
}

@(test)
test_add :: proc(t: ^testing.T) {

	expect_output(t, "1+2", "3\n")
}

@(test)
test_sub :: proc(t: ^testing.T) {

	expect_output(t, "1-2", "-1\n")
}

@(test)
test_unary :: proc(t: ^testing.T) {

	expect_output(t, "-1+1", "0\n")
}

@(test)
test_mul :: proc(t: ^testing.T) {

	expect_output(t, "2*3", "6\n")
}

@(test)
test_div :: proc(t: ^testing.T) {

	expect_output(t, "6/4", "1\n")
}

@(test)
test_precedence :: proc(t: ^testing.T) {

	expect_output(t, "1+2*3", "7\n")
}

@(test)
test_multi_digit_number :: proc(t: ^testing.T) {

	expect_output(t, "123*456", "56088\n")
}

@(test)
test_paren :: proc(t: ^testing.T) {

	expect_output(t, "2*(3+4)", "14\n")
}

