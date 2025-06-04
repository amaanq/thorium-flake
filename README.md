# Thorium Browser Nix Flake

Nix flake for [Thorium Browser](https://thorium.rocks/) with support for Linux *and* macOS.

## Quick Start

```bash
# Run directly (x86 Linux)
nix run github:amaanq/thorium-flake#thorium-avx2

# Install to profile
nix profile add github:amaanq/thorium-flake#thorium-avx2
```

## Available Variants

- `thorium-avx`: AVX build for Linux x86_64 systems.
- `thorium-avx2`: AVX2 build for Linux x86_64 systems.
- `thorium-sse3`: SSE3 build for Linux x86_64 systems.
- `thorium-sse4`: SSE4 build for Linux x86_64 systems.
- `thorium-arm`: ARM64 build for macOS aarch64 systems.
- `thorium-x64`: x64 build for macOS x86_64 systems.
