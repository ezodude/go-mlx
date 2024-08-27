package main

import "C"
import (
	"fmt"
	"unsafe"
)

/*
#cgo CFLAGS: -I${SRCDIR}
#cgo LDFLAGS: -F${SRCDIR}/.build/release/PackageFrameworks -framework LLMLocalWrapper -Wl,-rpath,${SRCDIR}/.build/release/PackageFrameworks
#include <stdlib.h>
#include <stdbool.h>
#include "include/LLMLocalWrapper.h"
*/
import "C"

func main() {
	llm := C.initialize_llm()
	defer C.free_llm(llm)

	if !C.load_model(llm) {
		fmt.Println("Failed to load model")
		return
	}

	prompt := C.CString("Tell me a short story about a robot learning to paint.")
	defer C.free(unsafe.Pointer(prompt))

	result := C.generate_text(llm, prompt)
	defer C.free_text(result)

	if result != nil {
		fmt.Println(C.GoString(result))
	} else {
		fmt.Println("Failed to generate text")
	}
}
