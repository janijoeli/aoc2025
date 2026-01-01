.var direction		= $2
.var clicks		= $3
.var input_ptr		= $39				// input data pointer on ZP, initialised by line number in basic header
.var counthi		= $62
.var countlo		= $63

.const LF		= $0a				// ASCII code for Line Feed

* = $0801 "Basic Header"

			.wo next_line, input; .by $9e; .te "2061"; .by 0,0,0

* = * "Calculate number of times when dial is at zero after turning it"

next_line:		ldy #0
			lda (input_ptr),y
			beq print_result		// If 0, we've processed all input
			sta direction			// Store direction of rotation to zp
		find_lf:iny				// Find the next line feed char
			lda (input_ptr),y
			cmp #LF
			bne find_lf
			tya
			pha				// Y to stack (Y+1 will be added to input_ptr later)
			dey
			lax (input_ptr),y		// Read ones
			sbx #$30			// Convert char to a number
			stx clicks
			lda #0
			dey
			beq no_tens			// Skip reading next if there are no tens
			lda (input_ptr),y
			asl				// Shift tens to hi nybble
			asl
			asl
			asl
			clc
			adc clicks			// Combine with ones
			sta clicks			// Store number of clicks from 0-99 (ignore hundreds)

		no_tens:sed
			lda dial:#$50			// Dial starts at 50 in decimal mode
			ldx #'R'-1
			cpx direction
			bcs sub				// If direction char is less than R, subtract clicks
			adc clicks			// Otherwise, add clicks
			.by $0c				// NOP abs (skips next two bytes)
		sub:	sbc clicks
			sta dial			// Store new position of dial
			cld
			cmp #0				// Does it point to 0? (CMP needed as decimal mode doesn't set Z flag)
			bne update_input_ptr
			inc countlo			// If it does, increment 16bit zero counter
			bne update_input_ptr
			inc counthi
update_input_ptr:	pla				// Input_ptr += Y+1 (points to next line in file)
			sec
			adc input_ptr
			sta input_ptr
			bcc next_line
			inc input_ptr+1
			bcs next_line

print_result:		jsr $bdd1			// Prints 16bit sum in $62(hi) and $63(lo) on screen as decimal
			rts				// All done, back to BASIC!

.print "CODE SIZE : " + toIntString(* - next_line) + " BYTES"

* = * "Input Data"
input:
			.import binary "input/day01_input.txt"
			// .import binary "input/day01_input_test.txt"
			.by 0 // End of input data
