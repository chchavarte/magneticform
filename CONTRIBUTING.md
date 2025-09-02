# Contributing to Flutter Magnetic Form Builder

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## 🚀 Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/yourusername/flutter-magnetic-form-builder.git
   ```
3. **Create a branch** for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 🏗️ Development Setup

1. **Install Flutter** (3.7.2 or higher)
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run tests** to ensure everything works:
   ```bash
   flutter test
   ```

## 📝 Code Guidelines

### Architecture
- Follow the existing **Clean Architecture** pattern
- Place new features in the `lib/features/` directory
- Use the established folder structure (data/domain/presentation)

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add documentation for public APIs
- Keep functions small and focused

### Testing
- Write tests for new functionality
- Maintain or improve test coverage
- Run `flutter test` before submitting

### Logging
- Use the `Logger` class instead of `print()` statements
- Follow the existing logging patterns:
  ```dart
  Logger.preview('Your message here');
  Logger.drag('Drag operation details');
  ```

## 🎯 Areas for Contribution

### High Priority
- [ ] Replace remaining `print()` statements with proper logging
- [ ] Add more comprehensive tests
- [ ] Improve documentation with code examples
- [ ] Add performance benchmarks

### Medium Priority
- [ ] Add more field types (date picker, dropdown, etc.)
- [ ] Implement undo/redo functionality
- [ ] Add keyboard shortcuts
- [ ] Improve accessibility features

### Low Priority
- [ ] Add themes and customization options
- [ ] Create demo videos/GIFs
- [ ] Add internationalization support
- [ ] Performance optimizations

## 🐛 Bug Reports

When reporting bugs, please include:
- **Flutter version** (`flutter --version`)
- **Platform** (iOS, Android, Web, etc.)
- **Steps to reproduce** the issue
- **Expected behavior**
- **Actual behavior**
- **Screenshots** if applicable

## ✨ Feature Requests

For new features:
- **Describe the problem** you're trying to solve
- **Explain your proposed solution**
- **Consider alternatives** you've thought about
- **Provide mockups** or examples if helpful

## 📋 Pull Request Process

1. **Update documentation** if needed
2. **Add tests** for new functionality
3. **Ensure all tests pass**:
   ```bash
   flutter test
   ```
4. **Update the README** if you've added features
5. **Create a clear PR description** explaining your changes

### PR Title Format
- `feat: add new field type support`
- `fix: resolve collision detection bug`
- `docs: update API documentation`
- `test: add preview system tests`
- `refactor: improve animation performance`

## 🔍 Code Review

All submissions require review. We look for:
- **Code quality** and adherence to guidelines
- **Test coverage** for new functionality
- **Documentation** updates
- **Performance** considerations
- **Backward compatibility**

## 🎉 Recognition

Contributors will be:
- Added to the README acknowledgments
- Mentioned in release notes for significant contributions
- Invited to join the core team for exceptional contributions

## 📞 Questions?

- Open an issue for discussion
- Check existing issues and PRs
- Review the codebase for examples

Thank you for contributing! 🙏