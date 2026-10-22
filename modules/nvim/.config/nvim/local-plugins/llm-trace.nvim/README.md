# llm-trace.nvim (POC)

Step through a **simulated** run of a Python function. Gemini invents fake but consistent inputs, "executes" the function
in its head, and returns a trace that is rendered as virtual text, like a debugger without running anything.

## Usage

```
export GEMINI_API_KEY=...
```

1. Put the cursor inside a (sync, non-generator) Python function.
2. `:LlmTrace` for the happy path, or `:LlmTrace user is under 18` to steer the branch.
3. `n` / `p` step forward / back, `i` toggles the fake-input window, `q` quits and clears everything.

Editing the buffer also clears the trace, since its line numbers would no longer match.

## Options

```lua
opts = {
  model = "gemini-3.8-flash",
  api_key_env = "GEMINI_API_KEY",
  timeout = 120000,
  max_context_lines = 1500, -- bigger files send only the target function
  keys = { next = "n", prev = "p", quit = "q", input = "i" },
}
```

Highlights: `LlmTraceCurrentLine`, `LlmTraceValue`, `LlmTraceCurrentValue`, `LlmTraceNote`, `LlmTraceLabel`.

## Limits

- The trace is the model's guess: values can be wrong, especially for arithmetic-heavy or library-heavy code.
- Does not step into callees; their return values are assumed and listed in the input window.
