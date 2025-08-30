# 🚀 Astral OS

The operating system for the age of artificial intelligence.

The future will be controlled by companies that deploy artificial intelligence at organizational scale. This repository contains the systematic capabilities that make this inevitable within our codebases.

## What This Is

This is our complete development philosophy, architectural standards, and implementation guidelines for building intelligent systems.

## The Lightweight Files

The `ai_stuff/lightweight/` directory contains our core implementation guidelines that we've personally pasted into Cursor's rules system. These are the fundamental principles that govern every line of code we write.

**To access these in Cursor:**
1. Click the settings icon in the top right
2. Navigate to "Rules and Memories" 
3. Scroll to "User Rules"

These files are `.txt` format because they're designed to be copy-pasted directly into Cursor's rule system. Each file represents a core pillar of our development approach:

- **`core.txt`** - Our fundamental development philosophy: Keep it simple, build only when needed, write for humans first
- **`deps.txt`** - Dependencies philosophy: Don't reinvent what already exists, choose proven libraries
- **`docstrings.txt`** - Documentation standards
- **`error_handling.txt`** - Error handling principles: Fail fast and simple, validate only uncertain inputs

**These aren't suggestions.**

## The Philosophy Files

The `ai_stuff/philosophy/` directory contains our high-level architectural thinking.

**`architecture.mdc`** - Our layered feature architecture that enables parallel development. Every project follows this pattern: build in isolation, integrate through interfaces. Each feature beyond the shared foundation can be built independently by a single developer, ensuring clear ownership and faster delivery.

**`core.mdc`** - The universal principles that govern all development. Write code with absolute clarity as the top priority. Choose the most straightforward solution that any developer can understand at first glance.

## Using Our Philosophy Files

**Important:** The architecture and philosophy files are NOT automatically attached to queries. You need to explicitly "@" mention them when relevant.

**Recommended Workflow for New Features:**
1. Use Cursor's "Ask More" or Claude's plan mode to outline your feature
2. "@" mention both `architecture.mdc` and `core.mdc` to provide context about our beliefs and patterns
3. Request a detailed folder structure and implementation todo list based on our architectural principles

This approach ensures the AI understands our layered feature architecture and development philosophy when designing new systems, rather than defaulting to generic patterns.

## Personal Setup Command

I've created a custom shell command `cursor-rules-setup` that automatically populates my Cursor rules configuration. When run, it sets up the following structure within my codebase. Note that `.cursor` is typically where cursor users store rules, and nesting is possible. See docs [here](https://docs.cursor.com/en/context/rules#best-practices).

```
.cursor/rules
├── architecture.mdc
├── core.mdc  
├── python-rules.mdc
└── ts-tsx-rules.mdc
```

Note: The lightweight files (`core.txt`, `deps.txt`, `docstrings.txt`, `error_handling.txt`) are not included in this setup because they're already stored in my Cursor user memories and apply globally across all projects.

## Language-Specific Rules

The `ai_stuff/lang_specific/` directory contains detailed implementation guidelines for specific programming languages. If you're using Cursor, these are automatically configured to be attached when dealing with that particular language.

**`python-rules.mdc`** - Complete Python development standards including Pydantic v2 for validation, function-first design patterns, and async handling. Configured to activate automatically when working with `.py` files.

**`ts-tsx-rules.mdc`** - TypeScript and React guidelines optimized for modern development. Includes Zod for runtime validation, React 19 patterns, and performance considerations. Auto-applies to `.ts` and `.tsx` files.


**Once again, these are NOT suggestions**

## The Astral Way

These stripped-down principles allow us to move rapidly and prioritize simplicity at scale. We believe in the maxim: **simplicity scales**. Whenever we find ourselves getting too complex, we're doing something wrong. We are relentless about simplification.

We have limited bandwidth and a lot of projects. Maintaining rigorous devotion to these principles ensures we do not need to relearn systems from scratch. Instead, we understand the paradigms and know exactly where to look. Agents get the same experience - they can jump into any astral codebase and immediately understand the patterns, the structure, the intent.

