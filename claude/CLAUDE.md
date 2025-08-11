# CLAUDE.md

This file provides comprehensive guidance to starting any new project. Here are some basic Rules

<style_guidelines>
## Default Style Guidelines

<default_standards>
For ALL projects, ALWAYS reference the core development standards at @~/.astral-os/core/instructions/standards/basic.md for fundamental coding principles including KISS, YAGNI, readability, and code structure guidelines.
</default_standards>

<project_type_detection>
<if condition="project_contains_python_files">
    <then>
        EXECUTE: @~/.astral-os/core/instructions/styles/python-styles.md
        EXECUTE: @~/.astral-os/core/instructions/tools/python-tools.md
    </then>
</if>

<if condition="project_contains_typescript_or_tsx_files">
    <then>
        EXECUTE: @~/.astral-os/core/instructions/styles/ts-tsx-styles.md
        EXECUTE: @~/.astral-os/core/instructions/tools/ts-tsx-tools.md
    </then>
</if>
</project_type_detection>

<instructions>
When working on any project:
1. ALWAYS apply @~/.astral-os/core/instructions/standards/basic.md first
2. Detect the project type by scanning for relevant file extensions
3. Conditionally apply language-specific style and tool guides based on detection
4. Follow ALL applicable guidelines strictly throughout development
</instructions>
</style_guidelines>