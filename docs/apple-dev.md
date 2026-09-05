# Apple Development Environment in Neovim

Complete guide to set up Swift/iOS/macOS development environment in Neovim using this dotfiles configuration.

## Prerequisites

### 1. Install Neovim 0.11.6

Neovim 0.12 has compatibility issues with some plugins. Use 0.11.6:

```bash
# Download and install Neovim 0.11.6
cd /tmp
curl -sL "https://github.com/neovim/neovim/releases/download/v0.11.6/nvim-macos-arm64.tar.gz" -o nvim.tar.gz
tar xzf nvim.tar.gz
mv nvim-macos-arm64 ~/.local/nvim

# Add to PATH in ~/.zshrc
echo 'export PATH="$HOME/.local/nvim/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify
nvim --version  # Should show v0.11.6
```

### 2. Install Required Packages

#### Homebrew Packages

```bash
# Install from Brewfile
cd ~/dotfiles/others
make brew-install  # or: brew bundle install --file=Brewfile

# Key Apple dev packages included:
# - xcbeautify      # Xcode build output formatter
# - xcode-build-server  # Xcode build server for LSP
# - xcp             # Xcode cache cleaner
# - cocoapods       # CocoaPods dependency manager
# - flutter         # Flutter SDK (for cross-platform)
```

#### Tree-sitter CLI (for compiling parsers)

```bash
# Install via cargo (version 0.25 for compatibility)
cargo install tree-sitter-cli@0.25.0

# Add to PATH in ~/.zshrc
echo 'export PATH="$HOME/.local/nvim/bin:$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify
tree-sitter --version  # Should show 0.25.0
```

## Plugin Configuration

### Overview

The dotfiles already include these Apple development plugins:

| Plugin            | Purpose                     |
| ----------------- | --------------------------- |
| `xcodebuild.nvim` | Xcode build/test runner     |
| `sourcekit-lsp`   | Swift/Apple language server |
| `nvim-treesitter` | Swift syntax highlighting   |
| `nvim-dap`        | Debugger                    |
| `nvim-dap-go`     | Go debugger                 |

### SourceKit-LSP Setup

The LSP configuration in `lsp-configs.lua` uses macOS built-in `sourcekit-lsp`:

```lua
-- Located in: lua/plugins/lsp-configs.lua
-- apple development
            local default_inlay_hint_handler = vim.lsp.handlers["textDocument/inlayHint"]

            vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
                if err then
                    local msg = err.message or ""
                    if string.match(msg, "inlay hints failed") or err.code == -32802 or err.code == -32001 then
                        return
                    end
                end

                if default_inlay_hint_handler then
                    return default_inlay_hint_handler(err, result, ctx, config)
                end
            end

            local is_mac = vim.fn.has("mac") == 1
            if is_mac then
                vim.lsp.config["rust_analyzer"] = {
                    capabilities = capabilities,
                    root_dir = require("lspconfig.util").root_pattern(
                        "Package.swift",
                        ".git",
                        "*.xcodeproj",
                        "*.xcworkspace"
                    ),
                    cmd = { "xcrun", "sourcekit-lsp" },
                    on_attach = function(client, bufnr)
                        if vim.lsp.inlay_hint then
                            vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
                        end
                        client.server_capabilities.inlayHintProvider = false
                    end,
                }
            end
            -- apple development
```

**No additional installation needed** - `sourcekit-lsp` comes with Xcode command line tools.

```bash
# Verify sourcekit-lsp is available
xcrun sourcekit-lsp
```

### Tree-Sitter Parsers

#### Auto-install (recommended)

```vim
# In Neovim, run:
:TSUpdateSync swift
```

#### Manual install (if auto fails)

Some parsers require manual compilation due to version compatibility:

```bash
# Swift parser
mkdir -p ~/.local/share/nvim/tree-sitter-swift
cd ~/.local/share/nvim/tree-sitter-swift
git clone --depth 1 https://github.com/alex-pinkus/tree-sitter-swift.git .
tree-sitter generate
cc -shared -fPIC -I./src -o ~/.local/share/nvim/lazy/nvim-treesitter/parser/swift.so src/parser.c src/scanner.c
```

Add swift to `ensure_installed` in `treesitter.lua`:

```lua
-- lua/plugins/treesitter.lua
ensure_installed = {
    "swift",  -- Add this
    "c",
    "lua",
    -- ... other parsers
}
```

## Xcodebuild.nvim Configuration

### Key Features

- Build, test, and run Xcode projects from Neovim
- View build logs and code coverage
- Select devices/simulators

### Default Keybindings

| Keybinding   | Command                  |
| ------------ | ------------------------ |
| `<leader>xl` | Toggle Xcodebuild Logs   |
| `<leader>xb` | Build Project            |
| `<leader>xr` | Build & Run              |
| `<leader>xt` | Run Tests                |
| `<leader>xT` | Run This Test Class      |
| `<leader>xd` | Select Device/Simulator  |
| `<leader>xp` | Select Project/Workspace |

### Configuration Location

`lua/plugins/apple.lua` - customize the setup function:

```lua
require("xcodebuild").setup({
    show_build_progress_bar = true,
    logs = {
        auto_open_on_success_tests = false,
        auto_open_on_failed_tests = false,
        auto_open_on_success_build = false,
        auto_open_on_failed_build = true,
        auto_focus = false,
        auto_close_on_app_launch = true,
    },
    code_coverage = {
        enabled = true,
    },
})
```

## Debugging

### DAP Setup

The dotfiles include nvim-dap and nvim-dap-ui for debugging:

```vim
" In Neovim, check DAP status
:DapStatus
:DapUiToggle  " Toggle DAP UI
```

### LLDB Commands in Neovim

| Command      | Description          |
| ------------ | -------------------- |
| `<leader>dl` | Continue             |
| `<leader>ds` | Step over            |
| `<leader>di` | Step into            |
| `<leader>do` | Step out             |
| `<leader>db` | Toggle breakpoint    |
| `<leader>dh` | Show hover variables |

## Troubleshooting

### "sourcekit-lsp not found"

```bash
# Install Xcode command line tools
xcode-select --install

# Or specify path manually in lsp-configs.lua
cmd = { "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp" }
```

### "tree-sitter CLI not found"

```bash
# Ensure tree-sitter is in PATH
which tree-sitter
tree-sitter --version

# If not found, add to PATH
export PATH="$HOME/.cargo/bin:$PATH"
```

### "Could not create tree-sitter-swift-tmp"

```bash
# Remove stale temp directory
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter/parser/tree-sitter-swift-tmp

# Then retry
nvim +TSUpdateSync +qa
```

### Swift syntax highlighting not working

```vim
" In Neovim:
:TSInstallSync swift
:TSUpdateSync

" Check installed parsers
:TSInstallInfo
```

## Workflow Tips

### Typical Swift Project Workflow

1. Open project in Neovim

   ```bash
   cd ~/Projects/MyApp
   nvim .
   ```

2. Select project/workspace

   ```
   <leader>xp
   ```

3. Select simulator

   ```
   <leader>xd
   ```

4. Build and run

   ```
   <leader>xr
   ```

5. Run tests
   ```
   <leader>xt
   ```

### Using with Xcode

Neovim complements Xcode:

- Use Xcode for UI design and interface builder
- Use Neovim for code editing with LSP, treesitter, and your preferred plugins
- Build/test can be done in either

## Additional Tools

### Recommended macOS Tools

```bash
# From Brewfile already included:
brew install xcbeautify  # Pretty Xcode build output
brew install xcode-build-server  # For LSP support
brew install xcp  # Xcode cache cleaner

# Optional:
brew install --cask qlmarkdown  # Quick Look plugins for .md files
brew install --cask qlstephen   # Quick Look for .swift files
```

### Peripherals

```bash
# Flutter integration (already in Brewfile)
brew install --cask flutter

# For iOS simulators
open -a Simulator
```

## Quick Setup Checklist

- [ ] Neovim 0.11.6 installed
- [ ] PATH configured in ~/.zshrc
- [ ] tree-sitter 0.25.0 installed
- [ ] Xcode command line tools installed (`xcode-select --install`)
- [ ] `:Lazy sync` run in Neovim
- [ ] `:TSUpdateSync swift` run in Neovim
- [ ] Test with `nvim Package.swift`
- [ ] Init project
- [ ] Run `xcode-build-server config -scheme <XXX> -project *.xcodeproj` to generate `buildServer.json` file
- [ ] Open project with nvim and check
