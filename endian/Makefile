
CFLAGS = -Wall -Wextra -std=c99
OBJ = endian.o

test_endian: test_endian.c $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

.PHONY: clean
clean:
	-rm $(OBJ) test_endian
