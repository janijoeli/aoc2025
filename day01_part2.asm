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
			lda (input_ptr),y		// Read ones
			and #$0f			// Convert char to a number
			sta clicks
			lda #0
			dey
			beq do_math			// Skip reading next if there are no tens
			lda (input_ptr),y
			asl				// Shift tens to hi nybble
			asl
			asl
			asl
			clc
			adc clicks			// Combine with ones
			sta clicks			// Store number of clicks from 0-99 (ignore hundreds)

			dey
			beq do_math			// If there are no hundreds, go do math
			lda (input_ptr),y		// Read hundreds
			and #$0f			// Convert char to a number
			adc countlo			// Add number of hundreds (ie. zero crossings) to count
			sta countlo
			bcc do_math
			inc counthi

		do_math:sed
			lda dial:#$50			// Dial starts at 50 in decimal mode
			ldx #'R'-1
			cpx direction
			bcs sub				// If direction char is less than R, subtract clicks
			adc clicks			// Otherwise, add clicks
			bcs inc_count			// If we crossed 99 -> 0 or more, increment zero count
			bcc update_dial			// If we didn't, just update the dial
		sub:	sbc clicks			// Subtract clicks
			beq inc_count			// If we landed on 0, increment zero count
			bcs update_dial			// If we didn't cross zero, skip incrementing count
			ldx dial			// Check what dial was pointing to previously.
			beq update_dial			// If zero, no crossing happened.

	inc_count:	inc countlo			// If any other value, increment count
			bne update_dial
			inc counthi

	update_dial:	sta dial			// Store new position of dial

			cld				// Switch back to hex mode and update input pointer
			pla				// A = Y
			sec				// +1
			adc input_ptr			// Sum Y+1 with old input pointer value = next line in file
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
			// .import binary "input/day01_input_part2_example.txt" // 6
			
			// .import binary "input/day01_input_test.txt"
			.by 0 // End of input data
