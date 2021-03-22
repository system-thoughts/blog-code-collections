ordering: ordering.cpp
	gcc -o ordering -O2 ordering.cpp -lpthread
affi-no-ordering: ordering.cpp
	gcc -o affi-no-ordering -O2 -DUSE_SINGLE_HW_THREAD ordering.cpp -lpthread
cpu-no-ordering: ordering.cpp
	gcc -o cpu-no-ordering -O2 -DUSE_CPU_FENCE ordering.cpp -lpthread
clean:
	rm -f ordering affi-no-ordering cpu-no-ordering
