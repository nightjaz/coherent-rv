/* Strongly ordered V1 message-passing algorithm. */
void produce(volatile int *data, volatile int *flag, int value) { *data=value; *flag=1; }
int consume(volatile int *data, volatile int *flag) { while(!*flag) {} return *data; }
