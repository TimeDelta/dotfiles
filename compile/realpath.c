#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
 
int main (int argc, char *argv[]) {
	char* instr;
	char outstr[PATH_MAX];
 	
	instr = argv[1];
	
	if (!realpath(instr, outstr)) {
		printf("Usage: %s path\n", argv[0]);
		return 1;
	}
	printf("%s\n", outstr);
	return 0;
}
