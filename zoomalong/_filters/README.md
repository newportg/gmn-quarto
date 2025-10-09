inline-plantuml-input.lua

Purpose
- Preprocessor Lua filter for Quarto that inlines external PlantUML `.puml` files into `plantuml` code blocks.

Usage
- Add the filter file to `_filters/inline-plantuml-input.lua` in your Quarto project (already present).
- Reference external `.puml` files in a code block either with an attribute or a single-line directive:
  - Attribute: ```{.plantuml filename: "/images/foo.puml"}```
  - Directive inside the block: ```plantuml\n%%| filename: /images/foo.puml\n```
- Leading-slash paths (e.g. `/images/foo.puml`) are treated as project-root relative.

Debugging
- To write a dump of the inlined PlantUML for inspection, set the environment variable `INLINE_PLANTUML_DEBUG=1` when running `quarto render`.
- When enabled the filter writes `.quarto/inline-plantuml-dump-FINDME.puml` and prints debug lines to stdout so you can locate the dump in Quarto logs.

Notes
- The filter expands `!include` directives recursively up to a depth limit and protects against include cycles.
- Debug writes are gated behind the `INLINE_PLANTUML_DEBUG` env var and will not run during normal builds.
