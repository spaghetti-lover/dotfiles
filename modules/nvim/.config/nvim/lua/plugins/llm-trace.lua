return {
  {
    -- Local POC: step through an LLM-simulated run of a Python function. Needs $GEMINI_API_KEY.
    dir = vim.fn.stdpath("config") .. "/local-plugins/llm-trace.nvim",
    name = "llm-trace.nvim",
    main = "llm_trace",
    cmd = { "LlmTrace", "LlmTraceStop" },
    opts = {},
  },
}
