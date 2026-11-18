/*
 * pico8-hotkey - force-restart a frozen PICO-8.
 *
 * Watches every input device (keyboards and gamepads, hotplug included) and
 * kills the running PICO-8 when one of these is pressed on a single device:
 *
 *   Ctrl + Alt + Backspace            (keyboard)
 *   SELECT + START held for 3 seconds (gamepad; generic HID pads that
 *                                      report BASE3/BASE4 instead too)
 *
 * and opens a 90 s Bluetooth pairing window (pico8-btpair) on
 *
 *   Ctrl + Alt + P                    (keyboard)
 *
 * and restarts PICO-8 into the PICO8-OS settings cart on
 *
 *   Ctrl + Alt + S                    (keyboard)
 *   SELECT held alone for 2 seconds   (gamepad; BASE3 on generic pads)
 *
 * init's respawn of pico8-session then starts PICO-8 again. Stalled wget
 * children (Splore downloads) are killed too.
 *
 * SDL does not grab evdev devices, so these events are seen even while
 * PICO-8 has the keyboard.
 *
 *   pico8-hotkey [-f]          run (daemonizes unless -f)
 *   pico8-hotkey --reset-vt T  un-mute the keyboard of VT T and put it back
 *                              in text mode (after PICO-8 was killed while
 *                              SDL had the console keyboard switched off)
 */
#define _GNU_SOURCE
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/input.h>
#include <linux/kd.h>
#include <poll.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>

#ifndef KDSKBMUTE
#define KDSKBMUTE 0x4B51
#endif

#define MAX_DEVS 32
#define PAD_HOLD_MS 3000
#define SETTINGS_HOLD_MS 2000
#define NEXT_CART "/run/pico8os/next-cart"
#define COOLDOWN_MS 4000
#define RESCAN_MS 2000
#define LOGFILE "/data/logs/pico8.log"
#define BTPAIR "/usr/bin/pico8-btpair"

#define NBITS(x) ((((x) - 1) / (sizeof(unsigned long) * 8)) + 1)
#define TEST_BIT(bit, arr) \
	((arr[(bit) / (sizeof(unsigned long) * 8)] >> ((bit) % (sizeof(unsigned long) * 8))) & 1UL)

struct dev {
	int fd;
	char path[64];
	unsigned char down[KEY_MAX / 8 + 1];
	int64_t pad_since; /* ms when SELECT+START became held, 0 = not held */
	int64_t sel_since; /* ms when SELECT alone became held, 0 = not held */
};

static struct dev devs[MAX_DEVS];
static int ndevs;

static int64_t now_ms(void)
{
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

static void note(const char *fmt, ...)
{
	char msg[256];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(msg, sizeof(msg), fmt, ap);
	va_end(ap);
	syslog(LOG_NOTICE, "%s", msg);

	FILE *f = fopen(LOGFILE, "a");
	if (f) {
		char ts[32];
		time_t t = time(NULL);
		strftime(ts, sizeof(ts), "%F %T", localtime(&t));
		fprintf(f, "=== %s pico8-hotkey: %s\n", ts, msg);
		fclose(f);
	}
}

static int is_down(const struct dev *d, int code)
{
	return code >= 0 && code <= KEY_MAX && (d->down[code / 8] >> (code % 8)) & 1;
}

static void set_down(struct dev *d, int code, int on)
{
	if (code < 0 || code > KEY_MAX)
		return;
	if (on)
		d->down[code / 8] |= (unsigned char)(1u << (code % 8));
	else
		d->down[code / 8] &= (unsigned char)~(1u << (code % 8));
}

static int already_open(const char *path)
{
	for (int i = 0; i < ndevs; i++)
		if (strcmp(devs[i].path, path) == 0)
			return 1;
	return 0;
}

static void close_dev(int i)
{
	close(devs[i].fd);
	devs[i] = devs[--ndevs];
}

/* Open new /dev/input/event* devices that report keys or buttons. */
static void rescan(void)
{
	DIR *dir = opendir("/dev/input");
	if (!dir)
		return;
	struct dirent *e;
	while ((e = readdir(dir)) && ndevs < MAX_DEVS) {
		if (strncmp(e->d_name, "event", 5) != 0)
			continue;
		char path[64];
		snprintf(path, sizeof(path), "/dev/input/%s", e->d_name);
		if (already_open(path))
			continue;
		int fd = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
		if (fd < 0)
			continue;
		unsigned long evbits[NBITS(EV_MAX + 1)] = { 0 };
		if (ioctl(fd, EVIOCGBIT(0, sizeof(evbits)), evbits) < 0 || !TEST_BIT(EV_KEY, evbits)) {
			close(fd);
			continue;
		}
		struct dev *d = &devs[ndevs++];
		memset(d, 0, sizeof(*d));
		d->fd = fd;
		snprintf(d->path, sizeof(d->path), "%s", path);
		/* Pick up keys already held when the device appeared. */
		unsigned long keys[NBITS(KEY_MAX + 1)] = { 0 };
		if (ioctl(fd, EVIOCGKEY(sizeof(keys)), keys) >= 0)
			for (int c = 0; c <= KEY_MAX; c++)
				if (TEST_BIT(c, keys))
					set_down(d, c, 1);
	}
	closedir(dir);
}

static int read_comm(const char *pid, char *out, size_t len)
{
	char path[64];
	snprintf(path, sizeof(path), "/proc/%s/comm", pid);
	FILE *f = fopen(path, "r");
	if (!f)
		return -1;
	if (!fgets(out, (int)len, f)) {
		fclose(f);
		return -1;
	}
	fclose(f);
	out[strcspn(out, "\n")] = '\0';
	return 0;
}

/* pico8, pico8_dyn, pico8_64, pico8_gpio - but not pico8-session or us. */
static int is_pico8_binary(const char *comm)
{
	return strcmp(comm, "pico8") == 0 || strncmp(comm, "pico8_", 6) == 0;
}

/* Signal every PICO-8 process (and, if wget_sig, every wget). Returns count. */
static int signal_procs(int pico_sig, int wget_sig)
{
	int n = 0;
	DIR *dir = opendir("/proc");
	if (!dir)
		return 0;
	struct dirent *e;
	while ((e = readdir(dir))) {
		if (!isdigit((unsigned char)e->d_name[0]))
			continue;
		char comm[32];
		if (read_comm(e->d_name, comm, sizeof(comm)) < 0)
			continue;
		pid_t pid = (pid_t)atoi(e->d_name);
		if (is_pico8_binary(comm)) {
			if (pico_sig && kill(pid, pico_sig) == 0)
				n++;
			else if (!pico_sig)
				n++;
		} else if (wget_sig && strcmp(comm, "wget") == 0) {
			kill(pid, wget_sig);
		}
	}
	closedir(dir);
	return n;
}

static void restart_pico8(const char *why)
{
	int n = signal_procs(SIGTERM, SIGKILL);
	note("%s -> restarting PICO-8 (%d process%s)", why, n, n == 1 ? "" : "es");
	/* A frozen PICO-8 may ignore SIGTERM: give it 2 s, then SIGKILL. */
	for (int i = 0; i < 20 && signal_procs(0, 0) > 0; i++)
		usleep(100 * 1000);
	if (signal_procs(0, 0) > 0)
		signal_procs(SIGKILL, SIGKILL);
}

static int keyboard_combo(const struct dev *d)
{
	return (is_down(d, KEY_LEFTCTRL) || is_down(d, KEY_RIGHTCTRL)) &&
	       (is_down(d, KEY_LEFTALT) || is_down(d, KEY_RIGHTALT)) &&
	       is_down(d, KEY_BACKSPACE);
}

static int pad_combo(const struct dev *d)
{
	/* Standard gamepads (xpad, hid-sony/playstation, hid-nintendo, ...) */
	if (is_down(d, BTN_SELECT) && is_down(d, BTN_START))
		return 1;
	/* Generic HID pads (cheap USB/SNES style) report SELECT/START as
	 * BASE3/BASE4 and never send BTN_SELECT/BTN_START. */
	return is_down(d, BTN_BASE3) && is_down(d, BTN_BASE4) &&
	       !is_down(d, BTN_SELECT) && !is_down(d, BTN_START);
}

/* SELECT (or generic BASE3) held without START (or BASE4). */
static int select_alone(const struct dev *d)
{
	if (is_down(d, BTN_SELECT))
		return !is_down(d, BTN_START);
	return is_down(d, BTN_BASE3) && !is_down(d, BTN_BASE4) && !is_down(d, BTN_START);
}

static int settings_combo(const struct dev *d)
{
	return (is_down(d, KEY_LEFTCTRL) || is_down(d, KEY_RIGHTCTRL)) &&
	       (is_down(d, KEY_LEFTALT) || is_down(d, KEY_RIGHTALT)) &&
	       is_down(d, KEY_S);
}

static void open_settings(const char *why)
{
	FILE *f = fopen(NEXT_CART, "w");
	if (!f)
		return;
	fputs("settings\n", f);
	fclose(f);
	restart_pico8(why);
}

static int pair_combo(const struct dev *d)
{
	return (is_down(d, KEY_LEFTCTRL) || is_down(d, KEY_RIGHTCTRL)) &&
	       (is_down(d, KEY_LEFTALT) || is_down(d, KEY_RIGHTALT)) &&
	       is_down(d, KEY_P);
}

static void start_pairing(void)
{
	if (access(BTPAIR, X_OK) != 0)
		return;
	note("Ctrl+Alt+P -> Bluetooth pairing window (90 s)");
	pid_t pid = fork();
	if (pid == 0) {
		/* Double fork: the pairing script outlives us without a zombie. */
		if (fork() == 0) {
			setsid();
			execl(BTPAIR, BTPAIR, "90", (char *)NULL);
		}
		_exit(0);
	}
	if (pid > 0)
		waitpid(pid, NULL, 0);
}

static int reset_vt(const char *tty)
{
	int fd = open(tty, O_RDWR | O_NOCTTY | O_CLOEXEC);
	if (fd < 0) {
		fprintf(stderr, "pico8-hotkey: %s: %s\n", tty, strerror(errno));
		return 1;
	}
	ioctl(fd, KDSKBMUTE, 0);         /* SDL mutes the VT keyboard ... */
	ioctl(fd, KDSKBMODE, K_UNICODE); /* ... or switches it to K_OFF */
	ioctl(fd, KDSETMODE, KD_TEXT);   /* and the VT to graphics mode */
	close(fd);
	return 0;
}

int main(int argc, char **argv)
{
	int foreground = 0;
	for (int i = 1; i < argc; i++) {
		if (strcmp(argv[i], "--reset-vt") == 0 && i + 1 < argc)
			return reset_vt(argv[i + 1]);
		if (strcmp(argv[i], "-f") == 0)
			foreground = 1;
		else {
			fprintf(stderr, "usage: %s [-f] | --reset-vt /dev/ttyN\n", argv[0]);
			return 2;
		}
	}

	openlog("pico8-hotkey", LOG_PID, LOG_DAEMON);
	if (!foreground && daemon(0, 0) < 0) {
		perror("daemon");
		return 1;
	}
	signal(SIGPIPE, SIG_IGN);

	int64_t cooldown_until = 0, next_scan = 0;
	for (;;) {
		int64_t t = now_ms();
		if (t >= next_scan) {
			rescan();
			next_scan = t + RESCAN_MS;
		}

		struct pollfd pfd[MAX_DEVS];
		for (int i = 0; i < ndevs; i++) {
			pfd[i].fd = devs[i].fd;
			pfd[i].events = POLLIN;
			pfd[i].revents = 0;
		}
		/* Wake at least every 250 ms to time the gamepad hold. */
		poll(pfd, (nfds_t)ndevs, 250);
		t = now_ms();

		for (int i = ndevs - 1; i >= 0; i--) {
			struct dev *d = &devs[i];
			if (pfd[i].revents & (POLLERR | POLLHUP | POLLNVAL)) {
				close_dev(i); /* unplugged */
				continue;
			}
			if (pfd[i].revents & POLLIN) {
				struct input_event ev[64];
				ssize_t r = read(d->fd, ev, sizeof(ev));
				if (r < 0 && errno != EAGAIN && errno != EINTR) {
					close_dev(i);
					continue;
				}
				for (ssize_t k = 0; r > 0 && k < r / (ssize_t)sizeof(ev[0]); k++)
					if (ev[k].type == EV_KEY && ev[k].value != 2)
						set_down(d, ev[k].code, ev[k].value != 0);
			}

			if (pad_combo(d)) {
				if (!d->pad_since)
					d->pad_since = t;
			} else {
				d->pad_since = 0;
			}
			/* Pressing START at any point cancels the settings hold. */
			if (select_alone(d)) {
				if (!d->sel_since)
					d->sel_since = t;
			} else {
				d->sel_since = 0;
			}

			if (t < cooldown_until)
				continue;
			if (keyboard_combo(d)) {
				restart_pico8("Ctrl+Alt+Backspace");
				cooldown_until = now_ms() + COOLDOWN_MS;
			} else if (pair_combo(d)) {
				start_pairing();
				cooldown_until = now_ms() + COOLDOWN_MS;
			} else if (settings_combo(d)) {
				open_settings("Ctrl+Alt+S");
				cooldown_until = now_ms() + COOLDOWN_MS;
			} else if (d->sel_since && t - d->sel_since >= SETTINGS_HOLD_MS) {
				open_settings("SELECT held");
				d->sel_since = 0;
				cooldown_until = now_ms() + COOLDOWN_MS;
			} else if (d->pad_since && t - d->pad_since >= PAD_HOLD_MS) {
				restart_pico8("SELECT+START held");
				d->pad_since = 0;
				cooldown_until = now_ms() + COOLDOWN_MS;
			}
		}
	}
}
