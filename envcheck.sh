#!/usr/bin/env bash
# CS3006 Fall 2026 -- Programming Assignment 6 -- environment check.
# Run from the top of your repository:   bash envcheck.sh
# It writes machine.txt (your Machine Declaration). Submit that file.

fail=0
ok()   { printf '  [ OK ] %s\n' "$1"; }
bad()  { printf '  [FAIL] %s\n' "$1"; fail=1; }
warn() { printf '  [WARN] %s\n' "$1"; }

echo "CS3006 A6 environment check"

# 1. Operating system
os=$(uname -s)
wsl=no
if grep -qi microsoft /proc/version 2>/dev/null; then wsl=yes; fi
case "$os" in
  Linux)  if [ "$wsl" = yes ]; then ok "Linux under WSL2"; else ok "Linux"; fi ;;
  Darwin) warn "macOS: allowed but not supported by course staff (declare it)" ;;
  *)      bad "unsupported OS '$os' -- native Windows cannot run the MapReduce tests; use WSL2" ;;
esac

# 2. Go toolchain (the starter go.mod files say 'go 1.17')
if command -v go >/dev/null 2>&1; then
  gv=$(go env GOVERSION 2>/dev/null)
  minor=$(echo "$gv" | sed -E 's/^go1\.([0-9]+).*/\1/')
  if [ -n "$minor" ] && [ "$minor" -ge 17 ] 2>/dev/null; then ok "Go $gv"; else bad "Go $gv is older than go1.17"; fi
else
  gv=none; bad "go not found on PATH"
fi

# 3. Git
if command -v git >/dev/null 2>&1; then ok "$(git --version)"; else bad "git not found"; fi

# 3b. Optional C compiler: 'go test -race' needs cgo, and cgo needs a C compiler
if command -v "$(go env CC 2>/dev/null || echo gcc)" >/dev/null 2>&1 && [ "$(go env CGO_ENABLED 2>/dev/null)" = 1 ]; then
  ok "C compiler present and cgo enabled (go test -race available)"
else
  warn "optional: no C compiler/cgo, so 'go test -race' is unavailable (Ubuntu: sudo apt install build-essential)"
fi

# 4. UNIX-domain sockets in /var/tmp (the distributed tests put every socket there)
if [ -d /var/tmp ] && [ -w /var/tmp ]; then
  ok "/var/tmp is writable"
  if [ "$gv" != none ]; then
    tdir=$(mktemp -d)
    cat > "$tdir/main.go" <<'EOF'
package main

import (
	"fmt"
	"net"
	"os"
)

func main() {
	p := fmt.Sprintf("/var/tmp/cs3006-envcheck-%d.sock", os.Getpid())
	l, err := net.Listen("unix", p)
	if err != nil {
		fmt.Println("listen:", err)
		os.Exit(1)
	}
	go func() {
		c, err := l.Accept()
		if err == nil {
			c.Write([]byte("x"))
			c.Close()
		}
	}()
	c, err := net.Dial("unix", p)
	if err != nil {
		fmt.Println("dial:", err)
		os.Exit(1)
	}
	b := make([]byte, 1)
	_, err = c.Read(b)
	c.Close()
	l.Close()
	os.Remove(p)
	if err != nil {
		fmt.Println("read:", err)
		os.Exit(1)
	}
}
EOF
    if (cd "$tdir" && GO111MODULE=off go run main.go) >"$tdir/out" 2>&1; then
      ok "UNIX-domain socket round trip in /var/tmp"
    else
      bad "cannot use UNIX-domain sockets in /var/tmp: $(cat "$tdir/out")"
    fi
    rm -rf "$tdir"
  fi
else
  bad "/var/tmp is missing or not writable"
fi

# 5. Where the repository lives
here=$(pwd)
case "$here" in
  /mnt/[a-z]/*) warn "repository is on the Windows drive ($here); move it under your Linux home (~) -- file I/O there is much slower" ;;
esac
if [ ! -d assignment1-1 ] || [ ! -d assignment1-2 ] || [ ! -d assignment1-3 ]; then
  warn "run this from the top of your cs3006-a6 repository (assignment1-1/2/3 not found here)"
fi

# 6. Machine Declaration
cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown)
{
  echo "CS3006 A6 Machine Declaration"
  echo "generated: $(date '+%Y-%m-%d %H:%M %Z')"
  echo "os:        $os $(uname -r)"
  echo "wsl2:      $wsl"
  if [ -r /etc/os-release ]; then echo "distro:    $(. /etc/os-release; echo "$PRETTY_NAME")"; fi
  echo "arch:      $(uname -m)"
  echo "cores:     $cores"
  echo "go:        $gv"
  echo "git:       $(git --version 2>/dev/null)"
  echo "machine:   (fill in: laptop/desktop model, or 'lab PC' and its number)"
} > machine.txt
echo "  wrote machine.txt -- open it and fill in the 'machine:' line"

if [ $fail -ne 0 ]; then
  echo "RESULT: FAIL -- fix the items above before writing any code"
  exit 1
fi
echo "RESULT: PASS"
