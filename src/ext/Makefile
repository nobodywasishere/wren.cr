CFLAGS=-Iwren/src/include/ -Iwren/src/optional/ -Iwren/src/vm/
CC=gcc

SRC_VM = $(wildcard wren/src/vm/*.c)
OBJ_VM = $(SRC_VM:.c=.o)

SRC_OPT = $(wildcard wren/src/optional/*.c)
OBJ_OPT = $(SRC_OPT:.c=.o)

all: wren.a

wren.a: $(OBJ_VM) $(OBJ_OPT)
	ar rcs $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	find . -name "*.o" -type f -delete
	rm -f wren.a

download:
	-git clone https://github.com/wren-lang/wren/
