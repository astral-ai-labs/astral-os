# 🚀 Astral OS

A powerful collection of standards, tools, and instructions for building agentic code with Claude.

## Installation

### Interactive Installation (Recommended)

1) Install Astral OS
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/astral-ai-labs/astral-os/main/setup.sh)"
```

2) Set up Claude integration (see Step 2 message printed after install)
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/astral-ai-labs/astral-os/main/setup-claude.sh)"
```

### Direct commands (skip menu)

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/astral-ai-labs/astral-os/main/setup.sh | bash -s install

# Status
curl -fsSL https://raw.githubusercontent.com/astral-ai-labs/astral-os/main/setup.sh | bash -s status

# Update
curl -fsSL https://raw.githubusercontent.com/astral-ai-labs/astral-os/main/setup.sh | bash -s update
```

## What Gets Installed

Astral OS installs to `~/.astral-os` with the following structure:

```
~/.astral-os/
├── setup.sh          # Local management script
├── setup-claude.sh   # Claude migration utility
├── claude/           # Claude-specific configurations
│   ├── CLAUDE.md
│   ├── agents/
│   ├── commands/
│   └── settings.json
└── core/             # Core instructions and tools
    ├── instructions/
    │   ├── standards/
    │   ├── styles/
    │   └── tools/
    └── commands/
```

## Requirements

- OS: macOS, Linux, or WSL
- Tools: `curl` or `wget`
- Shell: Bash

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please open an issue on GitHub.
