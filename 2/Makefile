AS = /usr/bin/nasm
LD = /usr/bin/ld

ASFLAGS = -g -f elf64
LDFLAGS = -static

SRCS = lab.asm
OBJ_DIR = obj
OBJS = $(addprefix $(OBJ_DIR)/, $(SRCS:.asm=.o))

EXE = bin

all: asc


asc: $(SRCS) $(EXE)
	@echo "Compiled in ascending order"

desc: ASFLAGS += -D SORT_ORDER
desc: $(SRCS) $(EXE)
	@echo "Compiled in descending order"

clean:
	rm -rf $(EXE) $(OBJ_DIR)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@

$(OBJ_DIR)/%.o: %.asm | $(OBJ_DIR)
	$(AS) $(ASFLAGS) $< -o $@