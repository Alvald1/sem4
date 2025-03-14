# Matrix Anti-Diagonal Sorting Program

This assembly program sorts each anti-diagonal (lines perpendicular to the main diagonal) of a matrix using insertion sort with binary search. This document provides a detailed explanation of how the program works.

## Program Overview

The program processes a matrix stored in memory and sorts each anti-diagonal line. The matrix is stored as a 1D array but represents a 2D square matrix.

## Data Structures

- `size`: Stores the size of the matrix (4×4 in this case)
- `matrix`: The actual matrix data stored as a 1D array
- `temp`: Temporary storage used during the sorting process

## Registers Usage

- `r12`: Matrix size
- `r13`: Current diagonal number (0 to 2*size-2)
- `r14`: Current diagonal length
- `r15`: Starting position of the current diagonal in the matrix

## How Anti-Diagonals Work

In a matrix, anti-diagonals (lines perpendicular to the main diagonal) have the following pattern:

```
a b c d
e f g h
i j k l
m n o p
```

The anti-diagonals (d-g-j-m) are:
1. d (top-right corner)
2. c-h (above main diagonal)
3. b-g-l (above main diagonal)
4. a-f-k-p (main diagonal itself)
5. e-j-o (below main diagonal)
6. i-n (below main diagonal)
7. m (bottom-left corner)

Total number of anti-diagonals: 2*size - 1 = 7

## Program Execution Flow

1. Get the matrix size from memory
2. Initialize diagonal counter (r13) to 0
3. For each diagonal (0 to 2*size-2):
   - Calculate diagonal length and starting position
   - If diagonal length > 1, sort the diagonal
   - Move to next diagonal
4. Exit the program

## Calculating Diagonal Information

The function `calculate_diagonal_info` determines:
- The length of the current diagonal
- The starting position of the diagonal in the matrix

### First Half (including main diagonal)
If diagonal number < (size-1):
- Length = diagonal number + 1
- Starting position = (0, diagonal number)

### Second Half
If diagonal number ≥ (size-1):
- Length = 2*size - 1 - diagonal number
- Starting position = (diagonal_num-size+1, size-1)

## Sorting Algorithm: Insertion Sort with Binary Search

The implementation uses insertion sort with a binary search optimization:

1. For each element in the diagonal (starting from the second element):
   - Save the current element value in `temp`
   - Use binary search to find the insertion point in the already sorted portion
   - Shift elements to make room for insertion
   - Insert the element at the correct position

### Binary Search Implementation

The binary search algorithm finds the correct insertion point:
1. Initialize left = 0, right = current position - 1
2. Loop while left ≤ right:
   - Calculate mid = (left + right) / 2
   - If array[mid] equals key, stop
   - If array[mid] > key, move right boundary: right = mid - 1
   - If array[mid] < key, move left boundary: left = mid + 1
3. The insertion point is determined by the final value of left

## Element Position Calculation

The function `get_diagonal_element_pos` calculates the actual position of a diagonal element in the 1D array:

- All diagonals parallel to main diagonal: position = start + index * (size+1)

This formula accounts for how the elements along the main diagonal have indices that increase by size+1 for each element.

## Example

For a 4×4 matrix:
```
 5  6  7  1
15 13 14 10
16  2  3 11
12  4  8  9
```

Anti-diagonals (from top-right to bottom-left):
1. 1 (single element, already sorted)
2. 7-10 (already sorted)
3. 6-14-11 → sort to 6-11-14 (already sorted)
4. 5-13-3-9 → sort to 3-5-9-13 (main diagonal)
5. 15-2-8 → sort to 2-8-15
6. 16-4 → sort to 4-16 (already sorted)
7. 12 (single element, already sorted)

After sorting each anti-diagonal:
```
 5  6  7  1
15 13 14 10
16  2  3 11
12  4  8  9
```
(Note: The visual representation may not change much for this example as several diagonals are already sorted)

## Code Explanation

### Program Initialization
```nasm
_start:
    movzx r12, byte [size]   ; Load matrix size into r12, zero-extending to 64 bits
    mov r13, 0               ; Initialize diagonal counter to 0
```
This section loads the matrix size from memory and initializes the diagonal counter.

### Diagonal Loop
```nasm
diagonal_loop:
    ; Check if we've processed all diagonals
    mov rax, r12
    add rax, r12
    sub rax, 1               ; Calculate 2*size - 1 (total number of diagonals)
    cmp r13, rax
    jge program_end          ; If r13 >= 2*size-1, exit program
```
This loop iterates through each diagonal. The comparison checks if we've processed all diagonals.

### Calculating Diagonal Information
```nasm
calculate_diagonal_info:
    ; Determine which half of the matrix we're in
    mov rax, r12
    dec rax                  ; size-1
    cmp r13, rax
    jg  second_half          ; If diagonal_num > size-1, it's in the second half
```
This function determines the diagonal properties based on whether we're in the first or second half of the matrix:
- First half: Diagonals start from the first column and increase in length
- Second half: Diagonals start from somewhere in the first row and decrease in length

```nasm
    ; First half calculations
    mov r14, r13             ; Length = diagonal_num + 1 
    inc r14
    mov r15, r13             ; Starting position = diagonal_num
```
For the first half, the length increases with the diagonal number, and the starting position is directly related to the diagonal number.

```nasm
    ; Second half calculations
    mov r14, r12
    add r14, r12
    dec r14
    sub r14, r13             ; Length = 2*size - 1 - diagonal_num
    
    mov  r15, r13
    sub  r15, r12
    inc  r15
    imul r15, r12            ; Convert row to offset
    add  r15, r12
    dec  r15                 ; Add column offset
```
For the second half, we calculate the length which decreases as diagonal number increases. The starting position calculation is more complex as it involves computing the offset in the 1D array.

### Insertion Sort Implementation
```nasm
sort_diagonal:
    mov rcx, 1               ; Start from the second element
    
outer_loop:
    cmp rcx, r14             ; Compare with diagonal length
    jge sort_done            ; If we've sorted all elements, we're done
```
The insertion sort starts from the second element (index 1) and iterates through all elements in the diagonal.

```nasm
    ; Get current element
    mov   rsi, rcx
    call  get_diagonal_element_pos   ; Get actual position in the matrix
    movzx rbx, byte [matrix + rax]   ; Load element value
    mov   byte [temp], bl            ; Save to temporary storage
```
This section loads the current element to be inserted into the sorted portion.

### Binary Search
```nasm
    ; Binary search to find insertion point
    mov r8, 0                ; Left bound = 0
    mov r9, rcx              ; Right bound = current position
    dec r9
    
binary_search:
    cmp r8, r9
    jg  binary_done          ; If left > right, search is done
    
    mov rax, r8
    add rax, r9
    shr rax, 1               ; Calculate mid = (left + right) / 2
```
The binary search algorithm efficiently finds the insertion point for the current element within the already sorted portion.

```nasm
    ; Compare array[mid] with key
    mov   rsi, rax
    call  get_diagonal_element_pos
    movzx rdx, byte [matrix + rax]   ; Load mid element
    
    cmp dl, byte [temp]              ; Compare with current element
    je  binary_done                  ; Equal: insertion point found
    jg  move_left                    ; Greater: search left half
    
    ; Less: search right half
    inc rax
    mov r8, rax                      ; Update left bound
    jmp binary_search
```
This part compares the middle element with the current element and decides which half to search next.

### Element Shifting and Insertion
```nasm
shift_loop:
    cmp rdx, r8                      ; Compare current index with insertion point
    jl  shift_done                   ; If below insertion point, we're done shifting
    
    ; Shift elements to make room
    mov  rsi, rdx
    call get_diagonal_element_pos
    mov  rdi, rax                    ; Source position
    
    mov  rsi, rdx
    inc  rsi
    call get_diagonal_element_pos
    mov  rsi, rax                    ; Destination position
    
    movzx rdx, byte [matrix + rdi]   ; Get element value
    mov   byte [matrix + rsi], dl    ; Move to next position
```
This section shifts elements to make room for the insertion. Elements are moved one position to the right until the insertion point is reached.

```nasm
    ; Insert the element at position r8
    mov   rsi, r8
    call  get_diagonal_element_pos
    movzx edx, byte [temp]           ; Get saved element
    mov   byte [matrix + rax], dl    ; Insert at correct position
```
Finally, the element is inserted at the computed position.

### Position Calculation
```nasm
get_diagonal_element_pos:
    ; For diagonals parallel to main diagonal
    mov rax, r12
    inc rax                         ; size+1
    imul rsi, rax                   ; index * (size+1)
    add rsi, r15                    ; start + index*(size+1)
    mov rax, rsi
    ret
```
This function calculates the actual position in the 1D array for elements along diagonals parallel to the main diagonal. The formula uses (size+1) as the step size because each element in a diagonal parallel to the main diagonal is separated by (size+1) positions in the 1D array.

## Assembly Instructions Explained

- `mov`: Copies data from source to destination
- `movzx`: Moves with zero extension (fills higher bits with zeros)
- `add/sub/inc/dec`: Arithmetic operations
- `imul`: Integer multiplication
- `cmp`: Compares two values, setting flags for conditional jumps
- `jg/jge/jl/jle/je`: Conditional jumps based on comparison results
- `shr`: Shift right (divides by powers of 2)
- `call`: Calls a subroutine/function
- `ret`: Returns from a subroutine/function
