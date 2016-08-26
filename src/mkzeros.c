#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <malloc.h>

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
#include <err.h>

static unsigned int blocksize = 128*1024;
static unsigned int ratio = 40;
static unsigned long long size_bytes = (8ULL)*(1024*1024*1024);
static unsigned long long size_blocks;
static unsigned long long fill;

static unsigned int numfiles = 0;
static char **files;

static unsigned long long wtotal=0;
static unsigned long long wzeroed=0;

static int quiet = 0;

#define qprintf(args...)        if (!quiet) printf(args)

/* Not that this changes often but it felt better than a bare '8' */
#define	ull_bytes sizeof(unsigned long long)

static void init_fill(void)
{
	unsigned long long low = rand(), high = rand();
	fill = low | (high << 32);
}

static int should_use_garbage(void)
{
	wtotal++;
	if ((rand() % 100) > ratio)
		return 1;
	wzeroed++;
	return 0;
}

static char *select_buf(char *zeros, char *nonzeros)
{
	int i;
	unsigned long long *g = (unsigned long long *)nonzeros;

	if (should_use_garbage()) {
		for(i = 0; i < blocksize / ull_bytes; i++)
			g[i] = fill;
		fill++;
		return nonzeros;
	}
	return zeros;
}

static int write_file(const char *filename, char *zero_buf, char *nonzero_buf)
{
	int i, fd, count, ret = 0;
	char *buf;

	init_fill();

	qprintf("Write file \"%s\"\n", filename);

	fd = open(filename, O_WRONLY|O_CREAT, 0644);
	if (fd < 0) {
		ret = errno;
		warn("Error while opening %s", filename);
		return ret;
	}

	for (i = 0; i < size_blocks; i++) {
		buf = select_buf(zero_buf, nonzero_buf);
		count = write(fd, buf, blocksize);
		if (count < blocksize) {
			if (count >= 0) {
				ret = EIO;
				fprintf(stderr, "Short write from file %s\n",
					filename);
			} else {
				ret = errno;
				warn("While writing %s", filename);
			}
			goto out_close;
		}
	}

out_close:
	close(fd);
	return ret;
}

static int create_files(void)
{
	int i, err;
	char *zeros, *garbage;

	zeros = calloc(1, blocksize);
	if (!zeros)
		return ENOMEM;
	garbage = aligned_alloc(ull_bytes, blocksize);
	if (!garbage) {
		free(zeros);
		return ENOMEM;
	}

	for (i = 0; i < numfiles; i++) {
		err = write_file(files[i], zeros, garbage);
		if (err)
			goto out;
	}

	err = 0;
out:
	free(zeros);
	free(garbage);
	return err;
}

static void usage(void)
{
	printf("mkzeros -b blocksize -r ratio -s size -q filelist\n");
}

static int parse_opts(int argc, char **argv)
{
	int c;

	while ((c = getopt(argc, argv, "b:r:s:q")) != -1) {
		switch (c) {
		case 'b':
			blocksize = atoi(optarg);
			break;
		case 'r':
			ratio = atoi(optarg);
			break;
		case 's':
			size_bytes = strtoull(optarg, NULL, 0);
			break;
		case 'q':
			quiet = 1;
			break;
		default:
			fprintf(stderr, "Invalid argument: %s\n\n", optarg);
			return -1;
		}
	}

	numfiles = argc - optind;
	if (!numfiles) {
		fprintf(stderr, "No file list provided.\n");
		return 1;
	}
	files = &argv[optind];
	size_blocks = size_bytes / blocksize;

	return 0;
}

int main(int argc, char **argv)
{
	int ret;

	if (parse_opts(argc, argv)) {
		usage();
		return 1;
	}

	srand(time(NULL));

	qprintf("blocksize: %u, ratio: %u, numfiles: %u\n", blocksize, ratio,
		numfiles);
	ret = create_files();

	qprintf("Wrote %llu blocks, %llu zeroed, actual ratio: %f\n", wtotal,
		wzeroed, (double)wzeroed/wtotal);

	return ret;
}
