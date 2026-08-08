/*
 * Copyright (C) 2012 The CyanogenMod Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

/* Read device NVRAM and set the Wifi MAC address accordingly */

int main() {

	FILE *fd1;
	int fd2;
	int macbyte;
	int addrcount = 0;
	char macaddr[18] = { 0 };
	int pos = 0;
	int i;

	fd1 = fopen("/data/misc/wifi/config", "w");
	fd2 = open("/dev/block/platform/omap/omap_hsmmc.1/by-name/nv", O_RDONLY);
	if (!fd1 || fd2 < 0) {
		if (fd1)
			fclose(fd1);
		if (fd2 >= 0)
			close(fd2);
		return 1;
	}

	for (i = 0; i<12; i++) {
		macbyte = 0;
		lseek(fd2, i + 7680, SEEK_SET);
		read(fd2, &macbyte, 1);
		addrcount += macbyte;
		if (i % 2 == 0 && i != 0)
			macaddr[pos++] = ':';
		macaddr[pos++] = macbyte;
	}
	macaddr[pos] = '\0';

	close(fd2);

	if (!addrcount) {
		macbyte = rand() % 255;
		/* least significant bit must be off, else it's multicast */
		if (macbyte & 1)
			macbyte--;
		sprintf(macaddr, "02:ad:c0:ff:ef:%02x", macbyte);
	}

	fprintf(fd1, "cur_etheraddr=%s", macaddr);
	fclose(fd1);
	return 0;
}
