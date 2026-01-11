# Contributing to Nostalgia OS

Thank you for your interest in contributing to Nostalgia OS! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Help others learn and grow
- Focus on what's best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites
- Basic knowledge of Linux, Docker/Podman, and shell scripting
- A Linux system with `podman`, `just`, and `qemu` for testing
- GitHub account

### Setting Up Development Environment

1. **Fork the repository**
   ```bash
   # On GitHub: Click "Fork" button
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/Nostalgia-OS.git
   cd Nostalgia-OS
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/descriptive-name
   # or
   git checkout -b fix/issue-description
   ```

4. **Keep your fork updated**
   ```bash
   git remote add upstream https://github.com/Nostalgia-Inc/Nostalgia-OS.git
   git fetch upstream
   git rebase upstream/main
   ```

## Types of Contributions

### Documentation
- Improve README and guides
- Fix typos and grammar
- Add code comments
- Create tutorials
- Update API documentation

**Impact**: High | Difficulty: Easy | Time: 30 min - 2 hours

### Bug Reports
- Test features and report issues
- Provide detailed error messages
- Include system information
- Suggest fixes if possible

**How**: Open a GitHub Issue with template

### Code Improvements
- Performance optimizations
- Code quality improvements
- Refactoring
- Adding features

**Impact**: High | Difficulty: Medium-Hard | Time: 1-3 days

### New Features
- New image variants
- Additional customizations
- Gaming/emulation support
- Development tools
- Hardware support

**Impact**: High | Difficulty: Hard | Time: 3+ days

### Testing
- Test builds on different hardware
- Verify features work as documented
- Report compatibility issues
- Create test plans

**Impact**: High | Difficulty: Medium | Time: 2-4 hours

### Design & Graphics
- Create wallpapers
- Design Plymouth themes
- Create GRUB themes
- Design logos/icons

**Impact**: Medium | Difficulty: Medium | Time: 2-4 hours

## Code Style & Standards

### Shell Scripts
```bash
# Use shellcheck: https://www.shellcheck.net/
shellcheck scripts/*.sh

# Format with shfmt
shfmt --write scripts/*.sh

# Code style:
# ✅ DO:
set -euo pipefail          # Error handling
[[ -f "$file" ]]           # Quote variables
echo "✓ Task complete"     # Use emoji for clarity
if [[ condition ]]; then   # Consistent formatting

# ❌ DON'T:
set -e                     # Incomplete error handling
rm -rf $dir                # Unquoted variables
echo "done"                # No clarity indicators
```

### Containerfile
```dockerfile
# Use hadolint: https://github.com/hadolint/hadolint
hadolint Containerfile

# Style:
# ✅ DO:
RUN set -eux; \
    command1 && \
    command2 && \
    ostree container commit

# ❌ DON'T:
RUN command1
RUN command2
```

### Documentation
```markdown
# ✅ DO:
# Clear, concise headings
# Code examples with language specified
# Proper spacing and formatting
# Active voice

# ❌ DON'T:
# vague headings
# Code without language
# Poor formatting
# Passive voice
```

## Testing Requirements

### Before Submitting PR

1. **Syntax Checks**
   ```bash
   just check      # Check Just syntax
   just lint       # Lint shell scripts
   just format     # Format code
   ```

2. **Build Test**
   ```bash
   just build-qcow2
   ```

3. **Boot Test**
   ```bash
   just run-vm-qcow2
   ```

4. **Feature Verification** (from TODO_CHECKLIST.md)
   - [ ] GRUB theme appears
   - [ ] Plymouth animation plays
   - [ ] Login works
   - [ ] Desktop loads
   - [ ] Wallpaper visible
   - [ ] Services complete
   - [ ] No errors in logs

### Testing Checklist

For each feature, verify:
- [ ] Builds without errors
- [ ] Boots successfully
- [ ] Feature works as documented
- [ ] No regressions
- [ ] Performance acceptable
- [ ] Services start correctly
- [ ] Logs show no critical errors

## Commit Guidelines

### Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, missing semicolons)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Build process, dependencies

### Examples
```bash
git commit -m "feat(arcade): add generic hardware tuning script

- Created nostalgia-arcade-tuning.sh
- Added Intel/AMD CPU detection
- Improved thermal management
- Backward compatible with existing code

Fixes #123"

git commit -m "docs: improve getting started guide

- Added prerequisites section
- Clarified build steps
- Added troubleshooting section"
```

### Include Co-author Line
```
git commit -m "feat: add feature description

[Description of changes]

Co-Authored-By: Contributor Name <email@example.com>"
```

## Pull Request Process

### Before You Start
1. Check existing PRs and issues to avoid duplicates
2. Read the ROADMAP.md to understand priorities
3. Discuss major changes in an issue first

### Creating a PR

1. **Ensure your branch is up to date**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push to your fork**
   ```bash
   git push origin feature/descriptive-name
   ```

3. **Create PR on GitHub**
   - Use descriptive title
   - Reference any related issues (`Fixes #123`)
   - Describe changes clearly
   - Include testing results

### PR Description Template
```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Performance improvement

## Testing
Describe testing performed:
- [ ] Built successfully
- [ ] Booted successfully
- [ ] Feature verified
- [ ] No regressions

## Related Issues
Fixes #(issue)

## Checklist
- [ ] Code follows style guidelines
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] Tests pass
- [ ] No new warnings generated
```

### Expectations
- Constructive feedback expected
- May need to make revisions
- Maintainers will review within 7 days
- Be responsive to review comments

## Review Process

### What Maintainers Look For
- ✅ Code quality and style compliance
- ✅ Functionality and correctness
- ✅ Documentation accuracy
- ✅ Test coverage
- ✅ No breaking changes
- ✅ Performance implications
- ✅ Security considerations

### Common Feedback
- "Please add error handling"
- "Can this be simplified?"
- "Document this behavior"
- "Add a test for this"
- "This might break existing code"

### Addressing Feedback
```bash
# Make requested changes
# Commit with descriptive message
git commit -m "Address review feedback: improve error handling"

# Push changes (same branch)
git push origin feature/descriptive-name

# Don't force push after review started
# Maintainers track the conversation
```

## Documentation Standards

### README Updates
- Keep it current
- Add features to feature list
- Update status as needed
- Link to detailed docs

### Code Comments
```bash
# Good: Explains "why" not "what"
# Use schedutil governor for dynamic frequency scaling
# This provides good balance between performance and power
cpu_governor="schedutil"

# Bad: Obvious from code
set_governor  # Set the governor
```

### Function Documentation
```bash
# Add header comments for scripts
# Script: nostalgia-setup.sh
# Purpose: Configure first-boot user setup
# Usage: Runs via systemd on first login
# Dependencies: kwriteconfig6, qdbus

# Add comments before complex sections
# Parse desktop containments from Plasma config
mapfile -t DESKTOP_CONTAINMENTS < <(...)
```

## Areas We Need Help With

### High Impact
- [ ] Testing on different hardware
- [ ] Nostalgia Arcade variant development
- [ ] Hardware detection system
- [ ] Documentation improvements

### Medium Impact
- [ ] Configuration system enhancements
- [ ] KDE Plasma customization
- [ ] Performance optimization
- [ ] CI/CD improvements

### Community-Friendly
- [ ] Documentation typos
- [ ] Adding comments to scripts
- [ ] Creating wallpaper/theme assets
- [ ] Testing and bug reports

## Questions?

- 📖 Check [ROADMAP.md](ROADMAP.md) for project overview
- 🐛 Open a GitHub Issue
- 💬 Discuss in PR comments
- 📧 Contact maintainers

## License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 License.

---

## First-Time Contributors

Start with:
1. Read [GETTING_STARTED.md](GETTING_STARTED.md)
2. Pick an "easy" task from the [Issues](https://github.com/Nostalgia-Inc/Nostalgia-OS/issues)
3. Follow the "Setting Up Development Environment" section
4. Make your changes
5. Test locally
6. Submit a PR

**Welcome to the Nostalgia OS community! 🎮**
