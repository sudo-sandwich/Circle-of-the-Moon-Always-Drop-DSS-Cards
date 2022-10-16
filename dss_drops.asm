.gba
.open "cotm.gba","cotm_modified.gba",0x8000000

.definelabel HackAddress,0x8013d90
.definelabel ReturnAddress,0x8013d98
.definelabel UnusedAddress,0x87f0000
.definelabel NormalRngAddress,0x8005820
.definelabel MysteryAddress1,0x80c389c
.definelabel MysteryAddress2,0x80c3824

.definelabel RngVal,0x0

.org HackAddress
.area ReturnAddress - HackAddress				; we are going to overwrite some instructions in the rom, so we need to make sure we don't accidentally overwrite too much
	ldr		r0,=UnusedAddress+1
	bx		r0

.pool
.endarea

; custom instructions, this is where the magic happens
.org UnusedAddress
CustomRng:
	push	{ r5 }								; we're going to need this register but we don't want to delete its contents. we will restore it at the end
	mov		r0,r10								; get common_id
	cmp		r0,0x36								; check if it's a dss card
	bhi		HasCommonDssDrop
	ldr		r0,[sp,0x8]							; get rare_id. because we pushed r5 to the stack, we need to offset this by an additional 0x4 (0x4 + 0x4)
	cmp		r0,0x36								; check if it's a dss card
	bhi		HasRareDssDrop
	; continue to NormalRng

NormalRng:
	ldr		r0,=0x2710							; store 10000 as the max value for the rng
	ldr		r1,=PostNormalRng+1					; store lr. normally we use bl to get to rng_capped, but it's too far away so we need to use bx and store lr manually
	mov		r14,r1
	ldr		r1,=NormalRngAddress+1				; prepare to jump to rng_capped
	bx		r1

HasCommonDssDrop:
	sub		r0,0x37								; simplify the dss id
	lsl		r0,r0,0x10							; (r0 & 0xffff)
	lsr		r5,r0,0x10
	add		r0,r5,0x0
	mov		r1,0xa
	ldr		r7,=@@LrAddress1+1					; store lr
	mov		r14,r7
	ldr		r7,=MysteryAddress1+1				; yeah i have no clue what this function does, but we need it to make this work
	bx		r7
@@LrAddress1:
	add		r4,r0,0x0							; save value of mystery function 1
	lsl		r4,r4,0x10							; (r4 & 0xffff)
	lsr		r4,r4,0x10
	add		r0,r5,0x0
	mov		r1,0xa
	ldr		r7,=@@LrAddress2+1					; store lr
	mov		r14,r7
	ldr		r7,=MysteryAddress2+1				; don't know what this function does either
	bx		r7
@@LrAddress2:
	lsl		r0,r0,0x10							; (r0 & 0xffff)
	lsr		r0,r0,0x10
	lsl		r1,r0,0x2							; i would imagine i would understand what is going on here better if i knew what mystery fuction 1 and 2 were for
	add		r1,r1,r0
	lsl		r1,r1,0x1
	add		r4,r4,r1
	ldr		r2,[sp,0x4]							; because we pushed r5 to the stack, we need to offset this by 0x4
	mov		r1,0xc3
	lsl		r1,r1,0x2
	add		r0,r2,r1
	add		r4,r4,r0
	ldrb	r0,[r4]								; all that just to load the player's dss card data
	cmp		r0,0x1								; check if the player has the dss card
	beq		@@PlayerCantGetDssDrop
	add		r0,r2,0x0
	add		r0,0x8c
	mov		r2,0x0
	ldrsh	r0,[r0,r2]							; get player class
	cmp		r0,0x3								; check if the player is using the fighter class
	bne		@@PlayerNeedsDssDrop
@@PlayerCantGetDssDrop:
	b		NormalRng							; use normal item drop rates
@@PlayerNeedsDssDrop:
	ldr		r1,=0x0								; force common item drop, guaranteed to be a dss card
	b		FinishedCustomRng

; mostly the same as HasCommonDssDrop
HasRareDssDrop:
	sub		r0,0x37								; simplify the dss id
	lsl		r0,r0,0x10							; (r0 & 0xffff)
	lsr		r5,r0,0x10
	add		r0,r5,0x0
	mov		r1,0xa
	ldr		r7,=@@LrAddress1+1					; store lr
	mov		r14,r7
	ldr		r7,=MysteryAddress1+1				; still don't know what this function does
	bx		r7
@@LrAddress1:
	add		r4,r0,0x0
	lsl		r4,r4,0x10							; (r0 & 0xffff)
	lsr		r4,r4,0x10
	add		r0,r5,0x0
	mov		r1,0xa
	ldr		r7,=@@LrAddress2+1					; store lr
	mov		r14,r7
	ldr		r7,=MysteryAddress2+1				; don't know what this function does either
	bx		r7
@@LrAddress2:
	lsl		r0,r0,0x10							; (r0 & 0xffff)
	lsr		r0,r0,0x10
	lsl		r1,r0,0x2
	add		r1,r1,r0
	lsl		r1,r1,0x1
	add		r4,r4,r1
	ldr		r1,[sp,0x4]							; because we pushed r5 to the stack, we need to offset this by 0x4
	mov		r2,0xc3
	lsl		r2,r2,0x2
	add		r0,r1,r2
	add		r4,r4,r0
	ldrb	r0,[r4]								; load the player's dss card data
	cmp		r0,0x1								; check if the player has the dss card
	beq		@@PlayerCantGetDssDrop
	add		r0,r1,0x0
	add		r0,0x8c
	mov		r1,0x0
	ldrsh	r1,[r0,r1]							; get player class
	cmp		r0,0x3								; check if the player is using the fighter class
	bne		@@PlayerNeedsDssDrop
@@PlayerCantGetDssDrop:
	b		NormalRng
@@PlayerNeedsDssDrop:
	add		r1,r6
	b		FinishedCustomRng

PostNormalRng:
	add		r1,r0,0x0							; move random value stored in r0 to r1

FinishedCustomRng:
	pop		{ r5 }								; restore the original value of r5
	ldr		r0,=ReturnAddress+1					; jump back to where we started from
	bx		r0
	
.pool

.close