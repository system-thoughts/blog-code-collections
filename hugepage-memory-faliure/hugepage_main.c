/*
 * Before running this application, make sure administrator has mounted the hugetlbfs filesystem
 * using the command mount -t hugetlbfs pagesize=1G,none /mnt/hugepage
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>

#define FILE_NAME "/mnt/hugepage/hugepagefile"
#define LEN (1024UL * 1024 * 1024)
#define PROTECTION (PROT_READ | PROT_WRITE)
#define FLAGS (MAP_SHARED)
// Bits 0-54  page frame number (PFN) if present
#define PM_PFRAME_MASK (0x007fffffffffffffull)
#define PAGE_PRESENT (1ull << 63)

static int pagesize;

/*
 * get information about address from /proc/{pid}/pagemap
 * Assumes target address is mapped as 4K (not hugepage)
 */
unsigned long long vtop(unsigned long long addr)
{
	unsigned long long pinfo;
	long offset = addr / pagesize * (sizeof pinfo);
	int fd;
	char	pagemapname[64];

	sprintf(pagemapname, "/proc/%d/pagemap", getpid());
	fd = open(pagemapname, O_RDONLY);
	if (fd == -1) {
		perror(pagemapname);
		exit(1);
	}
	if (pread(fd, &pinfo, sizeof pinfo, offset) != sizeof pinfo) {
		perror(pagemapname);
		exit(1);
	}
	close(fd);
	if ((pinfo & PAGE_PRESENT) == 0) {
		printf("page not present(addr = %llx)\n", addr);
		exit(1);
	}
	return ((pinfo & PM_PFRAME_MASK) * pagesize) + (addr & (pagesize - 1));
}

int main(void)
{
	void *addr;
	int fd, ret;
	unsigned long long phys;
	pagesize = getpagesize();

	fd = open(FILE_NAME, O_CREAT | O_RDWR, 0755);
	if (fd < 0) {
		perror("Open failed");
		exit(1);
	}

	addr = mmap(NULL, LEN, PROTECTION, FLAGS, fd, 0);
	if (addr == MAP_FAILED) {
		perror("mmap");
		unlink(FILE_NAME);
		exit(1);
	}

	// get the first pfn of the 1GB hugepage
	phys = vtop((unsigned long long)addr);

	printf("vtop(%llx) = %llx\n", (unsigned long long)addr, phys);
	getchar();
	
	munmap(addr, LEN);
	close(fd);
	unlink(FILE_NAME);

	return 0;
}
