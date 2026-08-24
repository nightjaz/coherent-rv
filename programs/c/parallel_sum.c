/* Algorithm mirrored by tb/soc/parallel_sum_tb.sv; bare-metal startup is testbench supplied. */
int parallel_sum_half(const int *a, int begin, int end) { int s=0; for(int i=begin;i<end;i++) s+=a[i]; return s; }
