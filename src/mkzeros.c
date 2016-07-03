#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
#include <err.h>

static unsigned int blocksize = 128*1024;
static unsigned int ratio = 100;
static unsigned long long size_bytes = (8ULL)*(1024*1024*1024);
static unsigned long long size_blocks;
static char fill = 1;

static unsigned int numfiles = 0;
static char **files;

static unsigned long long wtotal=0;
static unsigned long long wzeroed=0;

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
	if (should_use_garbage()) {
		memset(nonzeros, fill++, blocksize);
		if (!fill)
			fill = 1;
		return nonzeros;
	}
	return zeros;
}

static int write_file(const char *filename, char *zero_buf, char *nonzero_buf)
{
	int i, fd, count, ret = 0;
	char *buf;

	printf("Write file \"%s\"\n", filename);

	fd = open(filename, O_WRONLY|O_CREAT, 0644);
	if (fd < 0) {
		warn("Error while opening %s", filename);
		return errno;
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
	garbage = malloc(blocksize);
	if (!garbage) {
		free(zeros);
		return ENOMEM;
	}

	for (i = 0; i < numfiles; i++) {
		err = write_file(files[i], zeros, garbage);
		if (err)
			return err;
	}

	return 0;
}

static void usage(void)
{
	printf("Usage information\n");
}

static int parse_opts(int argc, char **argv)
{
	int c;

	while ((c = getopt(argc, argv, "b:r:s:")) != -1) {
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

	printf("blocksize: %u, ratio: %u, numfiles: %u\n", blocksize, ratio,
	       numfiles);
	ret = create_files();

	printf("Wrote %llu blocks, %llu zeroed, actual ratio: %f\n", wtotal,
	       wzeroed, (double)wzeroed/wtotal);

	return ret;
}
