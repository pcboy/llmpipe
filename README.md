# llmpipe

A Ruby-based CLI for building composable LLM workflows using the Unix pipe philosophy.

## Overview

`llmp` treats LLM prompts as Unix commands that can be chained together. Each pipe is defined by a YAML configuration file and communicates via standard input/output.

```bash
llmp summarize < article.txt | llmp translate > output.md
```

## Installation

```bash
gem install llmp
```

With Nix:

```bash
nix run github:pcboy/llmpipe -- <pipe_name_or_path> [args...] [options]
```

## Why llmp? You could just do `agent <<< 'my prompt'` and be done with it?

Yes, you could just do `qwen <<< 'my prompt'` and call it a day. That works fine for one-offs.

But you'll miss out on:

- **Caching** : llmp responses are automatically cached by content hash. Same input = instant result, no API call.
- **Single source of truth** : Prompts live in YAML files under one folder, can easily be version controlled
- **Composability** : Chain pipes together like Unix commands, with each step reusable and testable.

It's for sure nothing world-changing. It's just a nice way for me to work with quick LLMs operations from the command line.

## Quick Start

### 1. Configure RubyLLM

Create `~/.config/llmp/config.yml`:

```yaml
# API key for your LLM provider
openai_api_key: your-api-key

# Custom endpoint (for Ollama, vLLM, LiteLLM, etc.)
openai_api_base: http://localhost:11434/v1
```

Any configuration key supported by RubyLLM can be used here. The complete list of available options is documented at [rubyllm.com/configuration](https://rubyllm.com/configuration/).

### 2. Create a Pipe

Create for instance a `translate.yml` in your project directory, or globally at `$XDG_CONFIG_HOME/llmp/pipes/translate.yml`:

```yaml
provider: openai
model: qwen3.5
temperature: 0.6

system_prompt: |
  Detect the language of the input.
  If it's English, translate to Japanese, otherwise translate to English.
  Preserve the original formatting and tone.
```

### 3. Run the Pipeline

```bash
➜  echo "Hello, world" | llmp translate
こんにちは、世界
```

## CLI Usage

```bash
llmp <pipe_name_or_path> [args...] [options]
```

### Arguments

Pipe arguments are available in prompts as `$1`, `$2`, `$3`, etc., and `$*` for all arguments joined:

```bash
# $1 = "ruby", $2 = "performance"
llmp review ruby performance < code.rb

# $* = "security audit"
llmp analyze "security audit" < code.rb
```

```yaml
# In your YAML:
system_prompt: |
  Review this code for $1 issues.
  Focus on: $2
  All args: $*
```

### Options

| Option          | Description                     |
| --------------- | ------------------------------- |
| `-f, --force`   | Bypass cache and force LLM call |
| `-h, --help`    | Show help message               |
| `-v, --version` | Print version                   |

### Pipe Resolution

When you run `llmp summarize`, the framework resolves the YAML file using this priority:

1. **Direct path** — If argument contains `/` or ends with `.yml`/`.yaml`
2. **Current directory** — Looks for `summarize.yml` or `summarize.yaml`
3. **Environment variable** — Checks `$LLMP_PIPES_PATH/summarize.yml`
4. **Global fallback** — XDG config directory (`$XDG_CONFIG_HOME/llmp/pipes/summarize.yml`)

## Pipe Definition (YAML Schema)

```yaml
# Required: Provider and model
provider: openai # or anthropic, google, etc.
model: qwen3.5

# Optional: Model parameters
temperature: 0.7

# Required: System prompt
system_prompt: |
  Find Job Title in the given JD
```

## Configuration

### RubyLLM Configuration

The configuration file is stored following the XDG Base Directory specification:

- **Location**: `$XDG_CONFIG_HOME/llmp/config.yml` (defaults to `~/.config/llmp/config.yml`)

All keys in this file are passed directly to `RubyLLM.configure`:

```yaml
# Authentication
openai_api_key: your-api-key

# Custom endpoints
openai_api_base: http://localhost:11434/v1

# Optional settings
openai_organization: your-org-id
openai_timeout: 30
openai_extra_headers:
  X-Custom-Header: value

# Logging
log_level: info
log_errors: true
```

Any configuration key supported by RubyLLM can be used here. The complete list of available options is documented at [rubyllm.com/configuration](https://rubyllm.com/configuration/).

## Examples

### Basic Pipeline

```bash
# Do a code review on current branch, and apply the necessary changes
git diff master | llmp code-review | qwen -y && \
  git commit -a -m `git diff | llmp commit-message`
```

### Everything is cached

```bash
# First run - cache miss, calls LLM
llmp summarize < input.txt

# Second run - cache hit, instant result
llmp summarize < input.txt

# Force refresh - bypass cache
llmp summarize --force < input.txt
```

### Custom Pipe Path

```bash
# Use pipe from current directory (my_pipe.yml)
llmp my_pipe

# Use pipe from specific path
llmp ./pipes/custom.yml

# Use pipe from global config directory
llmp translate  # resolves to ~/.config/llmp/translate.yml
```

## Caching

`llmp` automatically caches LLM responses to save time and API costs.

- **Cache key**: SHA256 hash of (YAML content + input data)
- **Cache location**: `.llmp/cache/`
- **Cache invalidation**: Automatic when YAML or input changes
- **Bypass cache**: Use `--force` flag

Cache storage: `$XDG_CACHE_HOME/llmp/` (defaults to `~/.cache/llmp/`)
Config files: `$XDG_CONFIG_HOME/llmp/` (defaults to `~/.config/llmp/`)

## Environment Variables

| Variable          | Description                          |
| ----------------- | ------------------------------------ |
| `LLMP_PIPES_PATH` | Custom directory for pipe YAML files |

## License

MIT
