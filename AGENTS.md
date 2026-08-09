# AGENTS.md

## Build & Development Commands

# Standard build
make package

### Reference & Build

| Path | Purpose |
|------|---------|
| `packages/` | Build output (.deb files) |
| `control` | Debian package metadata (name, version, depends) |
| `Makefile` | Theos build config;

## Theos & Logos Conventions

- Use Logos directives (`%hook`, `%orig`, `%group`, `%ctor`) for runtime patches
- Keep related hooks grouped together
- **`%orig` passes original arguments**: `%orig;` always calls the original method with the original captured arguments, even if you've reassigned the local parameter variables. To pass modified values, use explicit arguments: `%orig(arg1, modifiedArg2, arg3)`.
- **`MSHookIvar` only works inside `%hook` blocks**: It's a Logos macro. In static helper functions, use `class_getInstanceVariable` + `object_getIvar` from the ObjC runtime instead.
- **Avoid layout-driving writes inside `layoutSubviews` hooks**: Writing `frame`, `bounds`, `layoutMargins`, `separatorInset`, stack spacing, or other Auto Layout inputs from `layoutSubviews` can loop during rotation. Do one-shot row/cell prep from non-layout entry points

No automated test suite, must be validated manually.