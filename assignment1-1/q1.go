package cos418_hw1_1

import (
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"
)

// Find the top K most common words in a text document.
//
//	path: location of the document
//	numWords: number of words to return (i.e. k)
//	charThreshold: character threshold for whether a token qualifies as a word,
//	        e.g. charThreshold = 5 means "apple" is a word but "pear" is not.
//
// Matching is case insensitive, e.g. "Orange" and "orange" is considered the same word.
// A word comprises alphanumeric characters only. All punctuation and other characters
// are removed, e.g. "don't" becomes "dont".
// You should use `checkError` to handle potential errors.
func topWords(path string, numWords int, charThreshold int) []WordCount {
	if numWords <= 0 {
		return []WordCount{}
	}

	data, err := os.ReadFile(path)
	checkError(err)

	// Convert everything to lowercase.
	text := strings.ToLower(string(data))

	// Remove punctuation and all non-alphanumeric characters.
	re := regexp.MustCompile(`[^0-9a-zA-Z\s]+`)
	text = re.ReplaceAllString(text, "")

	// Split the text into words.
	words := strings.Fields(text)

	// Count qualifying words.
	counts := make(map[string]int)
	for _, word := range words {
		if len(word) >= charThreshold {
			counts[word]++
		}
	}

	// Convert the map into a slice.
	var result []WordCount
	for word, count := range counts {
		result = append(result, WordCount{
			Word:  word,
			Count: count,
		})
	}

	// Sort by descending frequency, then alphabetically.
	sortWordCounts(result)

	// Return at most numWords results.
	if len(result) > numWords {
		result = result[:numWords]
	}

	return result
}

// A struct that represents how many times a word is observed in a document.

type WordCount struct {
	Word  string
	Count int
}

func (wc WordCount) String() string {
	return fmt.Sprintf("%v: %v", wc.Word, wc.Count)
}

// This sorts by the count in decreasing order, breaking ties using the word.
func sortWordCounts(wordCounts []WordCount) {
	sort.Slice(wordCounts, func(i, j int) bool {
		wc1 := wordCounts[i]
		wc2 := wordCounts[j]
		if wc1.Count == wc2.Count {
			return wc1.Word < wc2.Word
		}
		return wc1.Count > wc2.Count
	})
}
