# unit-os, server profile: the terminal half of the desktop, as a container.
#
# No compositor, no bar, no fonts -- just the shell, the editor, the tools,
# herdr as the workspace runtime, and ttyd so the whole thing is reachable
# from a browser tab. One of these per workspace; break it, delete it, boot
# another from the same image in a second or two.
#
#   docker build -t unit-os .
#   docker run -p 7681:7681 unit-os            # http://localhost:7681 -> herdr
#   docker run -it unit-os bash                # just a shell
#
# On Vercel Sandbox / Fly / Cloudflare Containers the same image boots with
# the port published; ttyd is what turns the TUI into a web client.

FROM archlinux:base-devel

# ---- packages: the server profile, nothing the desktop needs ---------------
COPY config/unit/pkglist-server.txt /tmp/pkglist-server.txt
RUN pacman -Syu --noconfirm --needed - < /tmp/pkglist-server.txt \
 && pacman -Scc --noconfirm \
 && rm -rf /var/cache/pacman/pkg/* /tmp/pkglist-server.txt

# ---- an ordinary user, like a real machine ---------------------------------
# install.sh writes to $HOME; herdr and Claude Code both refuse to run as root.
RUN useradd -m -s /bin/bash unit \
 && echo 'unit ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/unit
USER unit
WORKDIR /home/unit
ENV PATH="/home/unit/.local/bin:${PATH}" \
    TERM=xterm-256color

# ---- unit-os itself --------------------------------------------------------
COPY --chown=unit:unit . /home/unit/unit-os
RUN cd unit-os && ./install.sh --no-packages

# ---- the runtimes that are NOT packages (see docs/what-ships.md) -----------
# Both self-update, so they are fetched at build time rather than vendored.
# Either failing must not fail the image: a shell with the tools is still useful.
RUN curl -fsSL https://herdr.dev/install.sh | sh  || echo "herdr install failed (non-fatal)"
RUN curl -fsSL https://claude.ai/install.sh | bash || echo "claude install failed (non-fatal)"

# ---- the web client --------------------------------------------------------
# -W: writable. Put auth in front of it (`-c user:pass`, or the platform's own
# access control) before exposing this to the internet.
EXPOSE 7681
CMD ["ttyd", "-W", "-p", "7681", "-t", "fontSize=14", "herdr"]
