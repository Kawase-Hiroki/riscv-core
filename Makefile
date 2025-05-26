CC = iverilog
CFLAGS = 
Target = a.out
SRCS = code.v
OBJS = $(TARGET)


$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $(INCDIR) -o $@ $^

all: clean $(TARGET)

clean:
	-rm -f $(TARGET) *.vcd *.log