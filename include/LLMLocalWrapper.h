#ifndef LLM_LOCAL_WRAPPER_H
#define LLM_LOCAL_WRAPPER_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void* initialize_llm();
bool load_model(void* llm);
char* generate_text(void* llm, const char* prompt);
void free_llm(void* llm);
void free_text(char* text);

#ifdef __cplusplus
}
#endif

#endif // LLM_LOCAL_WRAPPER_H
