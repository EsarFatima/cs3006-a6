#!/usr/bin/env bash
# CS3006 Fall 2026 -- Programming Assignment 6 -- run every test and keep the logs.
# Replaces the starter's main/test-mr.sh, which does not work with Go modules.
# Run from the top of your repository:   bash checkall.sh
# Logs go to logs/ (ignored by Git); logs/summary.txt is the one-page result.

top=$(pwd)
if [ ! -d "$top/assignment1-1" ] || [ ! -d "$top/assignment1-2/src" ] || [ ! -d "$top/assignment1-3/src" ]; then
  echo "run this from the top of your cs3006-a6 repository"; exit 2
fi
mkdir -p "$top/logs"
L="$top/logs"
: > "$L/summary.txt"

line() { printf '%-38s %s\n' "$1" "$2" | tee -a "$L/summary.txt"; }

# gotest <label> <dir> <logfile> <args...>
gotest() {
  local label=$1 dir=$2 log=$3; shift 3
  ( cd "$dir" && go test -count=1 "$@" ) > "$L/$log" 2>&1
  local rc=$?
  if grep -q "panic: test timed out" "$L/$log"; then line "$label" "TIMEOUT -- probable deadlock (see logs/$log)"
  elif [ $rc -eq 0 ] && grep -q "^ok" "$L/$log"; then line "$label" "PASS"
  elif grep -q "no tests to run" "$L/$log"; then line "$label" "NO TESTS FOUND"
  else line "$label" "FAIL (see logs/$log)"; fi
}

# script test <label> <dir> <script> <logfile>
scripttest() {
  local label=$1 dir=$2 script=$3 log=$4
  ( cd "$dir" && rm -f mrtmp.* diff.out && timeout 300 bash "$script" ) > "$L/$log" 2>&1
  if grep -q "^PASSED test" "$L/$log"; then line "$label" "PASS"; else line "$label" "FAIL (see logs/$log)"; fi
  ( cd "$dir" && rm -f mrtmp.* diff.out )
}

{
  echo "CS3006 A6 checkall -- $(date '+%Y-%m-%d %H:%M %Z')"
  echo "go: $(go env GOVERSION)   commit: $(git rev-parse --short HEAD 2>/dev/null || echo none)"
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then echo "working tree: UNCOMMITTED CHANGES"; else echo "working tree: clean"; fi
  echo
} | tee -a "$L/summary.txt"

A11="$top/assignment1-1"
A12="$top/assignment1-2/src"
A13="$top/assignment1-3/src"

echo "== 1-1  Intro to Go" | tee -a "$L/summary.txt"
gotest "1-1 Q1 TestSimple"                    "$A11" a11_q1_simple.txt -v -timeout 2m -run '^TestSimple$' .
gotest "1-1 Q1 TestDeclarationOfIndependence" "$A11" a11_q1_doi.txt    -v -timeout 2m -run '^TestDeclarationOfIndependence$' .
gotest "1-1 Q2 Test1..Test4"                  "$A11" a11_q2.txt        -v -timeout 2m -run '^Test[1-4]$' .

echo "== 1-2  Sequential MapReduce" | tee -a "$L/summary.txt"
gotest "1-2 TestSequentialSingle"             "$A12" a12_seq_single.txt -v -timeout 3m -run '^TestSequentialSingle$' ./mapreduce/
gotest "1-2 TestSequentialMany"               "$A12" a12_seq_many.txt   -v -timeout 3m -run '^TestSequentialMany$' ./mapreduce/
scripttest "1-2 test-wc.sh"                   "$A12/main" test-wc.sh a12_wc.txt

echo "== 1-3  Distributed MapReduce" | tee -a "$L/summary.txt"
if [ ! -f "$A13/mapreduce/schedule.go" ]; then
  line "1-3" "NOT STARTED (copy assignment1-2/src/{main,mapreduce} into assignment1-3/src)"
else
  gotest "1-3 TestBasic"                      "$A13" a13_basic.txt    -v -timeout 3m -run '^TestBasic$' ./mapreduce/
  gotest "1-3 TestOneFailure"                 "$A13" a13_one.txt      -v -timeout 3m -run '^TestOneFailure$' ./mapreduce/
  gotest "1-3 TestManyFailures"               "$A13" a13_many.txt     -v -timeout 5m -run '^TestManyFailures$' ./mapreduce/
  scripttest "1-3 test-ii.sh"                 "$A13/main" test-ii.sh a13_ii.txt
  ( cd "$A13/mapreduce" && rm -f mrtmp.* 824-mrinput-*.txt )
fi
( cd "$A12/mapreduce" && rm -f mrtmp.* 824-mrinput-*.txt )

git log --format='%h %ad %s' --date=format:'%Y-%m-%d %H:%M' > "$L/gitlog.txt" 2>/dev/null
echo | tee -a "$L/summary.txt"
echo "full output in logs/  (not submitted)" | tee -a "$L/summary.txt"
