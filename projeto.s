.data 
signal1: .word 0 #signal of num1
signal2: .word 0 #signal of num2
mantissa1: .word 0 #mantissa of num1
mantissa2: .word 0 #mantissa of num2
exp1: .word 0 #exponent of num1 
exp2: .word 0 #exponent of num2
num1: .word 0xc20a0000 #mem space for num1
num2: .word 0xc1200000 #mem space for num2
mult_exp: .word 0 #mem space for mult_exp
mult_sign: .word 0 #mem space for mult_sign
masks: .word 0x7F800000, 0x007FFFFF, 0x7FFFFFFF, 0x80000000, 0x00800000 #load an array with the masks
result: .word 0 #result in memory
.text
    lw a0, num1 #load number 1
    jal ra, signal #jump to signal function with number 1 as input
    la t6, signal1 #load adress of signal1
    sw a0, 0(t6) #store the result of the function call for the signal of number 1 in signal1
    lw a0, num2 #load number 2 as a0 (function input)
    jal ra, signal #jump to signal function with num2 as input
    la t6, signal2 #load the adsress of signal2 in memory
    sw a0, 0(t6) #store the result in the adress
    lw a0, num1 #load num1 as input
    jal ra, realexponent #run the realexponent function on number 1 (a0 both as input variable and output variable)
    la t6, exp1 #load the adress of exp1
    sw a0, 0(t6) #store the result of realexponent of number 1 in exp1
    lw a0, num2 #load num2
    jal ra, realexponent #execute realexponent on num2
    la t6 exp2 #get the address of exp2
    sw a0, 0(t6) #store the result in the address
    lw a0, num1 #load num1
    jal ra, mantissa #execute the mantissa function on num1
    la t6 mantissa1 #load the address of mantissa1
    sw a0, 0(t6) #store the result in mantissa1
    lw a0, num2 
    jal ra, mantissa
    la t6, mantissa2 
    sw a0, 0(t6) #same process as above, only with num2 as input
    j addition #we have all the information we need, with this jump we can choose which operation to execute (addition/subtraction/multiplication)

subtraction: #in this function we are going to swap around the signal of num2, and perform addition, which is what subtraction is
    lw t0, signal2 #load signal of num2
    li t1, 1 #load the immediate
    xor t0, t0, t1 #when we xor 1 and the signal bit, it is the same as the negation of the signal bit
    la t6, signal2 #load the adress for signal 2
    sw t0, 0(t6) #store the result
    j addition #now we have all we need and can just perform regular addition

addition: #in this function we perform the addition of both numbers
    lw a1, num1 #load number 1
    lw a2,num2 #load number 2
    beq x0, a1, num1_z #if number 1 is 0, the result will be number 2
    beq x0,a2, num2_z #if number 2 is 0, the result will be number 0
    jal ra normalize #before we operate on the numbers, we need to normalize them first
    lw t1, signal1 #load signal1
    lw t2, signal2 #load signal2 
    beq t1, t2, equal_sign
    bne t1, t2, dif_sign #we have 2 cases, same signal or different signal, with same signal we add the absolutes and different we subtract

signal:
    srli a0, a0, 31 #transform msb into lsb, with 0 being positive num and 1 being negative num (rest of numbers are 0)
    ret #return to main text

equal_sign: #same signal numbers, just add absolutes and correct the exponent
    lw t0, signal1 #load signal1, will be the result signal
    slli t0, t0, 31 #shift the signal bit to the correct position
    lw t1, mantissa1 #load mantissa1 (biggest number)
    lw t2, mantissa2 #load mantissa2 (smallest number)
    srli t1, t1, 1 #shift them both right once, to account for overflow
    srli t2, t2, 1
    add t3, t1, t2 #add the numbers
    srli t4, t3, 31 #t4 accounts for the overflow, it will add 1 to the exponent in case there is overflow, otherwise it will maintain
    slli t3, t3, 1 #left shift t3 to remove the overflow
    srli t3, t3, 9 #right shift 9 places, to make space for both the exponent and the signal
    lw t5, exp1 #load the exponent of largest number
    add t5, t4, t5 #in case of overflow, add 1, otherwise it wont add anything
    addi t5, t5, 127 #add 127 to the number in order to get the correct representation
    slli t5, t5, 23 #left shift to the correct position in order to make place for the mantissa
    add t5, t5, t0 #adding the numbers won't change anything, there is no overlap, so all we are doing is combining the pieces
    add t5, t5, t3 #same thing, with the mantissa
    la t6, result #load result address
    sw t5, 0(t6) #store result
    j end #we have a result, we can end
    
dif_sign: #different signal numbers, just subtract absolutes, maintaining num1 correcting exponent
    lw t1, mantissa1 #load mantissa1 (biggest number)
    lw t2, mantissa2 #load mantissa2 (smallest number)
    sub t3, t1, t2 #subtract the numbers
    la t6, mantissa1 #load address of mantissa1
    sw t3, 0(t6) #store the result mantissa in mantissa1, to use in normalization function
    lw t5, exp1 #loads exponent 
    addi t5, t5, 127 #add 127 to the number in order to get the correct representation
    la t6, exp1
    sw t5, 0(t6)
    jal ra, normalization_neg  #execute function
    lw t5, exp1 #load the exponent of largest number after normalization_neg
    lw t1, mantissa1 #load mantissa after normalization_neg function
    slli t1, t1, 1 #shift left 1 to remove the leading 1
    srli t1, t1, 9 #shifts mantissa to correct position
    lw t0, signal1 #load signal1, will be the result signal
    slli t0, t0, 31 #shift the signal bit to the correct position
    lw t5, exp1 #loads exponent again, now corrected
    slli t5, t5, 23 #left shift to the correct position in order to make place for the mantissa
    add t5, t5, t0 #adding the numbers won't change anything, there is no overlap, so all we are doing is combining the pieces
    add t5, t5, t1 #same thing, adding now the exponent part
    la t6, result #load result address
    sw t5, 0(t6) #store result
    j end #we have a result, we can end

normalization_neg: #sees if msb is 1, if it isnt, left shifts and takes 1 from exponent, until we get correct mantissa
    lw t0, mantissa1 #loads mantissa corrected
    srli t1, t0, 31 #only cares about msb
    or t2, t1, x0 #checks if its 1
    beq x0, t2, exp_add #if its 0, perform exp_add
    ret #return to the function

exp_add: #removes 1 from exponent and left shifts the mantissa by 1
    lw t0, exp1 #load exp1
    addi t0, t0, -1 #-1 to the exp1
    la t6, exp1 #loads address
    sw t0, 0(t6) #stores new exponent
    lw t0, mantissa1 #load mantissa1
    la t6, mantissa1  #load addres of mantissa1
    slli t0, t0, 1 #shifts mantissa by 1 to left
    sw t0, 0(t6) #stores new mantissa
    beq x0, x0, normalization_neg #returns to the function (loop will only finish when we have a leading 1)

realexponent:
    slli a0, a0, 1
    srli a0, a0, 24 #do the required shifts in order to get the number representing the exponent
    addi a0, a0, -127 #subtract 127 to get the real exponent, not the representation
    ret #return to main text

mantissa:
    la t0, masks #load masks
    lw t1, 4(t0) #load the 0x007FFFFF mask
    and a0, a0, t1 #turn first 9 bits into 0 with mask
    lw t1, 16(t0) #load the 0x00800000 mask
    or a0, a0, t1 #turn the bit before mantissa into 1 with mask
    slli a0, a0, 8 #left-shift to obtain the correct number (notice that is is 8 places, not 9, since we have the leading 1 now)
    ret #return to main text

normalize:
    lw t1, exp1 #load the exponent of num1
    lw t2, exp2 #load the exponent of num2
    blt t1, t2, t1_smaller #if t1 is smaller, go to t1_smaller
    blt t2, t1, t2_smaller # if 2 is smaller, got to t2_smaller
    beq t1, t2, exp_equal #if they are the same, go to exp_equal
    #we don't need ret because in normalize we have all the cases, only the subcases of normalize need the return 

t1_smaller: #we want to make the normalization and then switch the numbers, so that 1 is the biggest absolute (switch num1 with num2, and all the memory values)
    lw t1, exp1 #load exp1
    lw t2, exp2 #load exp2
    sub t0, t2, t1 #get their difference
    lw t3, mantissa1 #get the mantissa of 1
    srl t3, t3, t0 #right shift the mantissa the ammount of digits that is the difference of the exponents, in order to normalize
    la t6, exp1 #get the address of exp1
    sw t2, 0(t6) #store the exp2 in exp1 (switch the exp)
    la t6, exp2 #address of exp2
    sw t1, 0(t6) #store exp1 in 2
    lw t4, mantissa2 #load the mantissa 2
    la t6, mantissa2 #load the address of mantissa2
    sw t3, 0(t6) #store the previous mantissa1 in address of mantissa2
    la t6, mantissa1 #get the address of mantissa1
    sw t4, 0(t6) #store the previous value of mantissa2 in mantissa1, we have switched the mantissas
    lw t1, signal1 #load value of signal1
    lw t2, signal2 #load value of signal2 
    la t6, signal2 #get address of signal2
    sw t1, 0(t6) #store signal 1 in address of signal2
    la t6, signal1 #get address of signal1
    sw t2, 0(t6) #store signal2 in address of 1, we have switched the values
    ret #normalization is finished, return to addition

t2_smaller: #simpler case, we only need to do the right shifting of num2
    lw t1, exp1 #load exp1
    lw t2, exp2 #load exp2
    sub t0, t1, t2 #get their difference
    lw t4, mantissa2 #load mantissa2
    srl t4, t4, t0 #do the correct right shifting
    la t6, mantissa2 #get the address for mantissa2
    sw t4, 0(t6) #store the value in mantissa2
    ret #return to addition

exp_equal: #in the case where the exponent is equal, we compare mantissas, and swap them around in case mantissa2 is bigger
    lw t1, mantissa1 #load mantissa1
    lw t2, mantissa2 #load mantissa2
    blt t1,t2, swap #check if 1 is less than 2, if so, go to swap
    ret #finished normalization if not

swap: #switch all values 
    lw t1, exp1 #load exp1
    lw t2, exp2 #load exp2
    lw t3, mantissa1 #get the mantissa of 1
    la t6, exp1 #get the address of exp1
    sw t2, 0(t6) #store the exp2 in exp1 (switch the exp)
    la t6, exp2 #address of exp2
    sw t1, 0(t6) #store exp1 in 2
    lw t4, mantissa2 #load the mantissa 2
    la t6, mantissa2 #load the address of mantissa2
    sw t3, 0(t6) #store the previous mantissa1 in address of mantissa2
    la t6, mantissa1 #get the address of mantissa1
    sw t4, 0(t6) #store the previous value of mantissa2 in mantissa1, we have switched the mantissas
    lw t1, signal1 #load value of signal1
    lw t2, signal2 #load value of signal2 
    la t6, signal2 #get address of signal2
    sw t1, 0(t6) #store signal 1 in address of signal2
    la t6, signal1 #get address of signal1
    sw t2, 0(t6) #store signal2 in address of 1, we have switched the values
    ret #normalize finished

mult_signal:
    lw t0, signal1
    lw t1, signal2
    xor a0, t0, t1 #the multiplication signal is the same as XOR operator of the 2 signals
    sw a0, mult_sign, x0 #store in mult_sign the operator
    ret

mult_exponent:
    lw t0, exp1 
    lw t1, exp2
    add a0, t0, t1 #the exponent of the multiplication is the sum of the exponents of the numbers
    sw a0, mult_exp, x0 #store the value
    ret 

num1_z:
    add a0, a2, x0 #if 1 is 0, return adress will be 2 for addition
    j end #no more to be done in addition

num2_z:
    add a0, a1, x0 #if 2 if 0, return address will be 1 for addition
    j end #no more to be done in addition

end:
    nop 