package control

import p "../pascal"
import "core:testing"

expect_output :: proc(t: ^testing.T, input: string, expected: string, loc := #caller_location) {

	c: Cradle
	p.wire_for_test(&c.io, input)
	defer p.io_destroy(&c.io)

	control(&c)
	actual := p.io_output(c.io)
	defer delete(actual)

	testing.expect_value(t, actual, expected, loc = loc)
}

@(test)
test_program :: proc(t: ^testing.T) {
	input :: "a b c end"
	expected :: `    A
    B
    C
    END
`
	expect_output(t, input, expected)
}

@(test)
test_missing_end :: proc(t: ^testing.T) {
	input :: "a b c\n"
	expected :: `    A
    B
    C

Error: Name Expected.
`
	expect_output(t, input, expected)
}

