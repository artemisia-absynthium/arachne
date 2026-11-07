# The web — sites, web apps, and web content inside a native shell

No vendor guideline governs the web.

## Source order

1. **The project's design system**, when it has one: its components, tokens and patterns first.
2. **WCAG** (the current version) for accessibility: contrast, focus, target size, motion.
3. **MDN** for the platform's semantics and behaviour: the right element for the job, form
   behaviour, focus management, and what the browser already provides.

## What the designer most often needs

- **The browser is the platform.** Links are links and navigate; the back button works; a URL
  reflects the state worth sharing or reloading; everything works from the keyboard with a
  visible focus.
- **Layouts adapt to any width**, by content breakpoints, never by device name.
- **Never imitate a native app**: no phone tab bars, back chevrons, fake system sheets or pickers,
  gestures without a visible control, or a platform's typeface copied to look native.
- **Hybrid shells:** the content follows this reference; the shell's own chrome follows the native
  platform's reference.

## Verify (step 9) — in two engines, Safari's always one of them

Render the page at the target widths in **both**:

1. **Playwright**, through its MCP with vision (the `web` rules carry the details) — Chromium, the
   engine most pages are written against.
2. **Safari**, through Safari's MCP server. WebKit diverges from Chromium in layout, CSS support,
   form controls and media behaviour, and a page checked in Chromium alone ships broken to every
   Safari user — on Apple devices that includes every browser, which all use WebKit.

A page is not presented as working until it renders correctly in both.

When the Safari MCP is not available, stop and tell the owner how to turn it on, rather than
skipping the check (Apple: *Connecting an AI agent to Safari*):

1. In Safari, enable the web developer features (Safari › Settings › Advanced, "Show features for
   web developers").
2. Safari › Settings › Developer › check "Allow remote automation and external agents".
3. Register the server with the agent, for example in Claude Code:
   `claude mcp add --scope user safari-mcp -- /usr/bin/safaridriver --mcp` (user scope: one registration per machine, not per project)

The agent does not run step 3 itself: adding an MCP server changes the agent's configuration, and
that is the owner's to approve.
