---
allowed-tools: Bash(git diff:*), Bash(git log:*)
description: Perform a comprehensive code review of recent changes
---

## Context

- Current git status: !`git status`
- Recent changes: !`git diff HEAD~1`
- Recent commits: !`git log --oneline -5`
- Current branch: !`git branch --show-current`

## Your task

First analyze the codebase to recognize what language it is in. Then perform a comprehensive code review focusing on:

1. **Code Quality**: Check for readability, maintainability, and adherence to best practices and any specific requirements you might find in this project's @README.md file
2. **Security**: Look for potential vulnerabilities or security issues
3. **Performance**: Identify potential performance bottlenecks
4. **Testing(Low Priority)**: Assess test coverage and quality. Integration tests over unit tests and coverage is not a factor
5. **Documentation(Low Priority)**: Look for cumbersome or "clever" code that might not have comments. If a documentation tool is being used, report any approaches that would be better

Provide specific, actionable feedback. Also give an option to create a markdown file, called `claude-code-review.md` with all feedback for review. If the file already exists, overwrite it.
