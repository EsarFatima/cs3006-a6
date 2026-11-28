package cos418_hw1_1

import (
	"bufio"
	"io"
	"os"
	"strconv"
)

// Sum numbers from channel `nums` and output sum to `out`.
// You should only output to `out` once.
// Do NOT modify function signature.
func sumWorker(nums chan int, out chan int) {
	total := 0

	for value := range nums {
		total += value
	}

	// Send exactly one partial sum.
	out <- total
}

// Read integers from the file `fileName` and return sum of all values.
// This function must launch `num` go routines running
// `sumWorker` to find the sum of the values concurrently.
// You should use `checkError` to handle potential errors.
// Do NOT modify function signature.
func sum(num int, fileName string) int {
	if num <= 0 {
		return 0
	}

	// Open and read the input file.
	file, err := os.Open(fileName)
	checkError(err)
	defer file.Close()

	values, err := readInts(file)
	checkError(err)

	// Create buffered channels.
	nums := make(chan int, len(values))
	out := make(chan int, num)

	// Launch the requested number of workers.
	for i := 0; i < num; i++ {
		go sumWorker(nums, out)
	}

	// Distribute the numbers among the workers.
	for _, value := range values {
		nums <- value
	}

	// Tell workers that no more numbers are coming.
	close(nums)

	// Collect all partial sums.
	total := 0
	for i := 0; i < num; i++ {
		total += <-out
	}

	return total
}

// Read a list of integers separated by whitespace from `r`.
// Return the integers successfully read with no error, or
// an empty slice of integers and the error that occurred.
// Do NOT modify this function.
func readInts(r io.Reader) ([]int, error) {
	scanner := bufio.NewScanner(r)
	scanner.Split(bufio.ScanWords)

	var elems []int
	for scanner.Scan() {
		val, err := strconv.Atoi(scanner.Text())
		if err != nil {
			return elems, err
		}
		elems = append(elems, val)
	}

	return elems, nil
}
