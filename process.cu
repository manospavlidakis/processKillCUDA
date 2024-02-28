#include <unistd.h>     /* Symbolic Constants */
#include <iostream>
#include <sys/types.h>  /* Primitive System Data Types */
#include <errno.h>      /* Errors */
#include <stdio.h>      /* Input/Output */
#include <sys/wait.h>   /* Wait for Process Termination */
#include <stdlib.h>     /* General Utilities */
#include <semaphore.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <vector>
#include <limits>
#include <iomanip>
struct timeval cuda_st, cuda_end;
using namespace std;
vector<pid_t> pidChild;
#define cudaCheckErrors(msg) \
	do { \
		cudaError_t __err = cudaGetLastError(); \
		if (__err != cudaSuccess) { \
			fprintf(stderr, "Fatal error: %s (%s at %s:%d)\n", \
					msg, cudaGetErrorString(__err), \
					__FILE__, __LINE__); \
			fprintf(stderr, "*** FAILED - ABORTING\n"); \
			exit(1); \
		} \
	} while (0)


__global__ void addkernel(int *data){
	for (int i=0; i<5000000000; i++)
		*data += 1;
}
void signalHandler(int signum)
{
	if (signum == SIGTERM)
	{
		std::cerr<<"Termination signal!"<<std::endl;
		exit(signum);
	}
}
void Malloc_Memcpy_Krnl()
{
	cudaError_t err;
	int *h_a, *d_a;
	h_a = (int *)malloc(sizeof(int));
	err = cudaMalloc(&d_a, sizeof(int));
	if (err != cudaSuccess)
	{	
		cerr<<"Error malloc"<<endl;
	}
	*h_a = 1;
	err = cudaMemcpy(d_a, h_a, sizeof(int), cudaMemcpyHostToDevice);
	if (err != cudaSuccess)
	{
		cerr<<"Error memcpy"<<endl;
	}

	addkernel<<<1,1>>>(d_a);
	cudaMemcpy(h_a, d_a, sizeof(int), cudaMemcpyDeviceToHost);
	cudaFree(d_a);
}

int main()
{
	pid_t childpid; /* variable to store the child's pid */
	int status;  
	for(int i=0; i<4; i++)
	{
		childpid = fork();
		pidChild.push_back(childpid);
		if (childpid == 0) /* fork() returns 0 to the child process */
		{
			gettimeofday(&cuda_st,NULL);
			// gets time in us (convert sec -> us)
			double t1 = cuda_st.tv_sec  * 1000000 +  cuda_st.tv_usec;

			cerr << fixed << showpoint << setprecision(1)<< t1 <<" (usec) I am child wiht pid : "<<getpid()<<" assigned to device: "<<0<<endl;

			cudaSetDevice(0);
			sleep(5);
			signal(SIGTERM, signalHandler);

			Malloc_Memcpy_Krnl();
		}
		else
		{
			usleep(1000);	
			cout<<"Parent: "<<getpid()<<" kill: "<<childpid<<endl;
			kill(childpid, SIGTERM);

			wait(&status);

			gettimeofday(&cuda_end,NULL);
			double t2 = cuda_end.tv_sec  * 1000000 +  cuda_end.tv_usec;
			cerr << fixed << showpoint << setprecision(1) <<"Done with kernel at "<< t2 <<" (usec)"<<endl;
		}
	}

}	

