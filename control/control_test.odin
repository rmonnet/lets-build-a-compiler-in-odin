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
	input :: "a b c e\n"
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

@(test)
test_if :: proc(t: ^testing.T) {
	input :: "a i b e c e"
	expected :: `    A
    <condition>
    BEQ L0
    B
L0:
    C
    END
`
	expect_output(t, input, expected)
}

@(test)
test_if_else :: proc(t: ^testing.T) {
	input :: "a i b l c e z e"
	expected :: `    A
    <condition>
    BEQ L0
    B
    BRA L1
L0:
    C
L1:
    Z
    END
`
	expect_output(t, input, expected)
}

@(test)
test_while :: proc(t: ^testing.T) {
	input :: "w a e b e"
	expected :: `L0:
    <condition>
    BEQ L1
    A
    BRA L0
L1:
    B
    END
`
	expect_output(t, input, expected)
}

@(test)
test_loop :: proc(t: ^testing.T) {
	input :: "p a e b e"
	expected :: `L0:
    A
    BRA L0
    B
    END
`
	expect_output(t, input, expected)
}

@(test)
test_repeat :: proc(t: ^testing.T) {
	input :: "r b c u z e"
	expected :: `L0:
    B
    C
    <condition>
    BEQ L0
    Z
    END
`
	expect_output(t, input, expected)
}

@(test)
test_for :: proc(t: ^testing.T) {
	input :: "f n = a b e z e"
	expected :: `    <expr>
    SUBQ #1, D0
    LEA N(PC), A0
    MOVE D0, (A0)
    <expr>
    MOVE D0, -(SP)
L0:
    LEA N(PC), A0
    MOVE (A0), D0
    ADDQ #1, D0
    MOVE D0, (A0)
    CMP (SP), D0
    BGT L1
    A
    B
    BRA L0
L1:
    ADDQ #2, SP
    Z
    END
`
	expect_output(t, input, expected)
}

@(test)
test_do :: proc(t: ^testing.T) {
	input :: "d a e b e"
	expected :: `    <expr>
    SUBQ #1, D0
L0:
    MOVE D0, -(SP)
    A
    MOVE (SP)+, D0
    DBRA D0, L0
    END
`
	expect_output(t, input, expected)
}

