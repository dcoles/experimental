CFLAGS = -Wall -Werror
OBJ = bpf.o

bpf: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

.PHONY: clean
clean:
	-rm $(OBJ) bpf
