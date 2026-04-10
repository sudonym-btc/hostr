# Escrow CLI demo
#
# Build the image (from repo root):
#   docker build --target vhs -f escrow/Dockerfile -t escrow-vhs .
#
# Run (with daemon running on the host):
#   docker run --rm \
#     -v $PWD/escrow:/vhs \
#     -v $TMPDIR/escrow_daemon.sock:/tmp/escrow_daemon.sock \
#     -e ESCROW_SOCKET=/tmp/escrow_daemon.sock \
#     escrow-vhs demo.tape

Output escrow-cli.gif

Set Shell "bash"
Set FontSize 14
Set Width 1000
Set Height 600
Set Theme "Catppuccin Mocha"
Set Padding 20
Set TypingSpeed 60ms

# ── Start the CLI ─────────────────────────────────────────────────────
Type "escrow-cli"
Enter
Sleep 2s

# ── Main menu ─────────────────────────────────────────────────────────
Screenshot escrow-cli.png
Sleep 500ms

# ── 1. Pending trades ────────────────────────────────────────────────
Enter
Sleep 2s
Sleep 1s
# Go back (press q — reliable in Docker PTY)
Type "q"
Sleep 1s

# ── 2. Threads ───────────────────────────────────────────────────────
Down
Enter
Sleep 3s

# Select the first thread
Enter
Sleep 3s

# ── Thread detail: view messages, then type a reply ──────────────────
Type "Looks good, releasing funds now."
Sleep 500ms
Enter
Sleep 4s

# Thread reloaded with new reply prompt — leave blank to exit reply loop
Enter
Sleep 1s

# SelectOrBack "Next" in thread detail — q to go back to thread list
Type "q"
Sleep 2s

# Thread list — q to go back to main menu
Type "q"
Sleep 1s

# ── 3. Services ──────────────────────────────────────────────────────
Down
Down
Enter
Sleep 2s

# Go back
Type "q"
Sleep 1s

# ── 4. Daemon status ────────────────────────────────────────────────
Down
Down
Down
Down
Down
Enter
Sleep 2s

# ── Back at main menu, exit ──────────────────────────────────────────
Sleep 500ms
Down
Down
Down
Down
Down
Down
Enter
Sleep 1s
