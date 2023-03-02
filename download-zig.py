#!/usr/bin/env python
"""This command downloads a Zig release, checking the file integrity and
printing the name of the downloaded file to stdout, so that the parent process
can install it.
"""

import argparse
import hashlib
import json
import os.path
import platform
import sys
import urllib.parse
import urllib.request


BUF_SIZE = 4 * 1024
SPOOL = "spool"
ZIG_DOWNLOAD_URL = "https://ziglang.org/download/index.json"


class Progress:
    """Progress implements a simple download progress.

    It uses standard ECMA-48 escape codes and two private VT220 escape codes
    supported by Linux.
    """

    def __init__(self, file):
        self._file = file

    def update(self, msg):
        # Simply use CR instead of ESC [ n D.
        print(msg, end="\r", file=self._file)

    def refresh(self):
        print("\x1b[0K", end="", file=self._file)

    def finish(self):
        print("\x1b[2K\x1b[?25h", end="", file=self._file, flush=True)

    def show_cursor(self):
        print("\x1b[?25h", end="", file=self._file)

    def hide_cursor(self):
        print("\x1b[?25l", end="", file=self._file)

    # Context manager support.

    def __enter__(self):
        self.hide_cursor()

        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.finish()
        self.show_cursor()

        return False


# zig_target returns the zig target tuple.
def zig_target():
    # TODO: the code has been tested only for x86_64-linux.
    arch = platform.machine()
    if arch is None:
        raise Exception("arch cannot be determined")

    name = platform.system()
    if name is None:
        raise Exception("os cannot be determined")
    os = name.lower()

    return arch + "-" + os


# zig_release returns the zig release for the specified version and target.
def zig_release(version, target):
    with urllib.request.urlopen(ZIG_DOWNLOAD_URL) as f:
        data = f.read()

    releases = json.loads(data)
    info = releases.get(version)
    if info is None:
        raise Exception(f"zig version '{version}' not found")

    release = info.get(target)
    if release is None:
        raise Exception(f"zig target '{target}' not found")

    # Add the local path to the release info.
    url = urllib.parse.urlparse(release["tarball"])
    path = urllib.request.url2pathname(url.path)
    release["tarball_path"] = os.path.basename(path)

    return release


# zig_get_release downloads the specified zig release to output.  It shows the
# download progress.
def zig_get_release(release, output):
    total_size = int(release["size"])
    size = 0
    url = release["tarball"]
    shasum = hashlib.new("sha256")
    with urllib.request.urlopen(url) as f:
        with Progress(sys.stderr) as p:
            buf = bytearray(BUF_SIZE)
            while True:
                rate = (size / total_size) * 100
                p.update(f"{rate:.0f}%")
                n = f.readinto(buf)
                if n == 0:
                    break

                size += n
                data = buf[:n]
                shasum.update(data)
                output.write(data)
                p.refresh()

    output.flush()
    if size != total_size:
        raise Exception("file size mismatch")
    if shasum.hexdigest() != release["shasum"]:
        raise Exception("checksum mismatch")


def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("-v", "--version", default="master", help="zig version")
    args = parser.parse_args()

    # 1. Detect zig target
    try:
        target = zig_target()
    except Exception as err:
        print(err.args[0], file=sys.stderr)
        sys.exit(1)

    # 2. Get zig release info
    try:
        release = zig_release(args.version, target)
    except Exception as err:
        print(err.args[0], file=sys.stderr)
        sys.exit(1)

    # 3. Download the specified zig release
    path = os.path.join(SPOOL, release["tarball_path"])
    url = release["tarball"]
    print(f"downloading {url}", file=sys.stderr)
    with open(path, "wb") as output:
        zig_get_release(release, output)

    # 4. Delegate unpack and install to the shell script.
    print(path, file=sys.stdout)


main()
