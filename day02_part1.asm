.var input_ptr		= $39			// input data pointer on ZP, initialised by line number in basic header
.var num_ptr		= $2			// Temp placehol
.var num1		= $10
.var num2		= $20
.var num1_length	= $1f
.var half_length	= $1e
.var line_ptr		= $d1			// Pointer to the beginning of the current screen line

* = $0801 "Basic Header"

			.wo init, input; .by $9e; .te "2061"; .by 0,0,0

* = * "Sum of invalid IDs within ranges" ; code_start:
init:			sei
			lda #'0'
			ldx #0
			ldy #15
		!:	sta ($d1),y
			stx $2,y
			dey
			bpl !-

next_range:		lda #num1		// Load to num1 location on ZP
			jsr next_num
			cpx #0			// X = 0 indicates end of input data. Is it?
			bne !+			// If X<>0, continue
			rts			// If X=0, we're done all ranges, stop here
		!:	sta num1_length		// Store number length (last index plus 1)
			lsr			// Divide by 2
			bcc next_num2		// If C=0 (lsb was not set), num1 = even, we can continue
			// Num1 length is odd, increase to next even length number, e.g. 992 -> 1000
			ldx #0			// Set digits to 0
		!:	stx num1,y		// Y already pointing to last index + 1
			dey
			bpl !-
			inc num1		// Set 1st digit to 1
			inc num1_length
			adc #0			// 0+C = 1

next_num2:		sta half_length
			lda #num2		// Load to num2 location on ZP
			jsr next_num
			cmp num1_length		// Compare num2_length to (possibly originally odd) num1 length
			bcc next_range		// If num1_length>num2_length, range was all odd nums of same length
			lsr
			bcc find_1st_pair	// If num2 = even, we can continue
			// Num2 length is odd, decrease to next even length number, e.g. 10123 -> 9999
			ldx #9			// Set digits to 9
		!:	dey
			stx num2,y		// Y pointing to last index
			bne !-

find_1st_pair:		ldx #$ff
			ldy half_length
			dey
		!:	inx
			iny
			cpy num1_length		// Have all numbers in 1st and 2nd half matched?
			beq add_to_sum		// If yes, range start is obvs within range -> add it to sum
			lda num1,y		// Compare next number pair from 1st and 2nd halfs
			cmp num1,x
			beq !-			// If they are the same, check next number
			bcc copy_1st_half	// 1st half is larger than 2nd half, thus 1st half duplicated is within range

			tya			// A number in 2nd half is larger
			tax
		!loop:	dey
			bmi !zeroes+
			lda num1,y
			adc #0
			cmp #10
			bcc !+
			sbc #10
		!:	sta num1,y
			bcs !loop-
		!zeroes:lda #0
		!:	sta num1,x
			inx
			cpx num1_length
			bne !-
			beq find_1st_pair

copy_1st_half:		ldy num1_length
			ldx half_length
		!:	lda num1-1,x
			sta num1-1,y
			dey
			dex
			bne !-

validate_range:		ldx #$ff
		!:	inx
			cpx num1_length
			beq add_to_sum
			lda num2,x
			cmp num1,x
			beq !-			// If numbers match, check next number
			bcs add_to_sum		// If num2 is larger, we're in range -> add to sum
	do_next:	jmp next_range		// Num1 is no longer within range - move on to next range

add_to_sum:		clc
			ldx num1_length
			ldy #$10
		!loop:	dex
			dey
			beq inc_num1
			lda ($d1),y
			adc num1,x
			cmp #$3a
			bcc !+
			sbc #10
		!:	sta ($d1),y
			bne !loop-

inc_num1:		sec
			ldx half_length
		!loop:	dex
			bmi do_next
			lda num1,x
			adc #0
			cmp #10
			bne !+
			sbc #10
		!:	sta num1,x
			bcs !loop-
			bcc copy_1st_half

next_num:		sta num_ptr
			ldy #$ff
		!:	iny
			lax (input_ptr),y
			beq !+				// If 0, we've processed all input
			and #$0f
			sta (num_ptr),y
			cmp #10
			bcc !-
		!:	tya				// Update input pointer
			sec
			adc input_ptr
			sta input_ptr
			bcc !+
			inc input_ptr+1
		!:	tya
			rts


.print "CODE SIZE : " + toIntString(* - code_start) + " BYTES"

* = * "Input Data"
input:
			.import binary "input/day02_input.txt"
			// .import binary "input/day02_input_example.txt" // 1227775554
			.by 0,0 // End of input data
