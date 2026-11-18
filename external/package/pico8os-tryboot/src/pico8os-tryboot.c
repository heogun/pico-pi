/*
 * pico8os-tryboot - the Raspberry Pi firmware's one-shot tryboot flag.
 *
 *   pico8os-tryboot set     the next boot reads tryboot.txt, not config.txt
 *   pico8os-tryboot clear   the next boot reads config.txt
 *   pico8os-tryboot get     print 1 or 0
 *
 * The flag lives in the firmware, set through the mailbox property channel
 * (/dev/vcio, tag SET_REBOOT_FLAGS). The firmware clears it when it starts,
 * so it applies to exactly one boot: a hang, crash or reset after that
 * boots config.txt again. The kernel only writes these flags on a reboot
 * whose argument asks for tryboot, so a plain "reboot" keeps what is set
 * here and init still shuts the system down cleanly.
 *
 * Exit status: 0 done (set/clear read back as asked), 1 failed, 2 usage.
 */
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define VCIO_IOC_MAGIC 100
#define IOCTL_MBOX_PROPERTY _IOWR(VCIO_IOC_MAGIC, 0, char *)
#define TAG_GET_REBOOT_FLAGS 0x00030064u
#define TAG_SET_REBOOT_FLAGS 0x00038064u
#define MBOX_SUCCESS 0x80000000u
#define FLAG_TRYBOOT 0x1u

/* One property request with one 32-bit value; returns 0 and the value the
 * firmware answered with, or -1. */
static int mbox_u32(int fd, uint32_t tag, uint32_t in, uint32_t *out)
{
	uint32_t b[7] __attribute__((aligned(16)));

	b[0] = sizeof b;      /* total size in bytes */
	b[1] = 0;             /* process request */
	b[2] = tag;
	b[3] = 4;             /* value buffer size */
	b[4] = 0;             /* request */
	b[5] = in;
	b[6] = 0;             /* end tag */
	if (ioctl(fd, IOCTL_MBOX_PROPERTY, b) < 0)
		return -1;
	if (b[1] != MBOX_SUCCESS || !(b[4] & MBOX_SUCCESS))
		return -1;
	*out = b[5];
	return 0;
}

int main(int argc, char **argv)
{
	uint32_t v;
	int fd, rc = 1;
	const char *cmd = argc == 2 ? argv[1] : "";

	if (strcmp(cmd, "set") && strcmp(cmd, "clear") && strcmp(cmd, "get")) {
		fprintf(stderr, "usage: pico8os-tryboot set|clear|get\n");
		return 2;
	}
	fd = open("/dev/vcio", O_RDWR | O_CLOEXEC);
	if (fd < 0) {
		perror("pico8os-tryboot: /dev/vcio");
		return 1;
	}
	if (strcmp(cmd, "get") != 0) {
		uint32_t want = strcmp(cmd, "set") == 0 ? FLAG_TRYBOOT : 0;
		if (mbox_u32(fd, TAG_SET_REBOOT_FLAGS, want, &v) < 0)
			goto out;
	}
	/* read back: report success only if the firmware holds what we asked */
	if (mbox_u32(fd, TAG_GET_REBOOT_FLAGS, 0, &v) < 0)
		goto out;
	if (strcmp(cmd, "get") == 0) {
		printf("%u\n", (unsigned)(v & FLAG_TRYBOOT));
		rc = 0;
	} else {
		rc = ((v & FLAG_TRYBOOT) != 0) == (strcmp(cmd, "set") == 0) ? 0 : 1;
	}
out:
	if (rc == 1)
		fprintf(stderr, "pico8os-tryboot: %s failed\n", cmd);
	close(fd);
	return rc;
}
