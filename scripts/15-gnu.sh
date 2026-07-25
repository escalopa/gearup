#!/usr/bin/env bash
# 15-gnu.sh — GNU coreutils on macOS so sed/awk/find/date/tar behave like Linux.
# On Linux these are already GNU, so this step is a no-op there. The gnubin dirs
# are prepended to PATH by the gearup shell block (config/shell/gearup.sh).

if [[ "$GEARUP_OS" != "macos" ]]; then
  skip "GNU coreutils (Linux already ships GNU userland)"
else
  # Each formula ships GNU versions under <prefix>/opt/<formula>/libexec/gnubin.
  # ensure_brew is idempotent (brew list) and honors GEARUP_ONLY (keyed by formula).
  ensure_brew coreutils    # ls, cat, cp, date, du, sort, head, tail, ...
  ensure_brew findutils    # find, xargs, locate
  ensure_brew gnu-sed      # sed  (GNU regex, -i without arg)
  ensure_brew gawk         # awk  (GNU awk)
  ensure_brew gnu-tar      # tar  (GNU long options)
  ensure_brew grep         # grep, egrep (GNU -P perl regex)
  ensure_brew gnu-getopt   # getopt (long-option parsing in scripts)
  ensure_brew make         # gmake / recent GNU make
  ensure_brew wget         # wget (curl's GNU sibling)
  ensure_brew watch        # watch (repeat a command)
  ensure_brew moreutils    # sponge, ts, vidir, parallel, ...
fi
