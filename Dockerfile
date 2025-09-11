# -----------------------------
# Base image
# -----------------------------
FROM archlinux:latest

# -----------------------------
# Ensure multilib is enabled (robustly) and update repos
# -----------------------------
RUN if ! grep -q '^\[multilib\]' /etc/pacman.conf; then \
      printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf; \
    fi && \
    pacman -Syu --noconfirm

# -----------------------------
# Install core packages (no explicit wine-mono / wine-gecko)
# -----------------------------
RUN pacman -Syu --needed --noconfirm \
        sudo git base-devel python python-pip ffms2 vim wget gcc \
        vapoursynth ffmpeg x264 x265 lame flac opus-tools sox \
        mplayer mpv x11vnc xorg-server-xvfb unzip cabextract wine \
        lib32-alsa-lib lib32-libpng lib32-libjpeg-turbo \
        rust unrar \
    && pacman -Sc --noconfirm

# -----------------------------
# Create non-root builder user for AUR/building
# -----------------------------
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder

# -----------------------------
# Fix permissions and Jupyter runtime dirs
# -----------------------------
RUN mkdir -p /home/builder/.local /home/builder/.cache /home/builder/.config \
    && chown -R builder:builder /home/builder \
    && mkdir -p /tmp/jupyter_runtime /tmp/jupyter_config /tmp/jupyter_data

ENV JUPYTER_RUNTIME_DIR=/tmp/jupyter_runtime
ENV JUPYTER_CONFIG_DIR=/tmp/jupyter_config
ENV JUPYTER_DATA_DIR=/tmp/jupyter_data

USER builder
WORKDIR /home/builder

# -----------------------------
# Install yay (AUR helper) as builder
# -----------------------------
RUN git clone https://aur.archlinux.org/yay.git /home/builder/yay && \
    cd /home/builder/yay && \
    makepkg --noconfirm --noprogressbar -si && \
    cd /home/builder && rm -rf /home/builder/yay

# -----------------------------
# Optionally install VapourSynth AUR plugins (best-effort; failures don't abort)
# -----------------------------
RUN mkdir -p /tmp/aur && cd /tmp/aur && \
    for pkg in \
        vapoursynth-plugin-bestsource-git \
        vapoursynth-plugin-mvtools-git \
        vapoursynth-plugin-removegrain-git \
        vapoursynth-plugin-rekt-git \
        vapoursynth-plugin-remapframes-git \
        vapoursynth-plugin-fillborders-git \
        vapoursynth-plugin-havsfunc-git \
        vapoursynth-plugin-awsmfunc-git \
        vapoursynth-plugin-eedi3m-git \
        vapoursynth-plugin-continuityfixer-git \
        vapoursynth-plugin-d2vsource-git \
        vapoursynth-plugin-subtext-git \
        vapoursynth-plugin-imwri-git \
        vapoursynth-plugin-misc-git \
        vapoursynth-plugin-ocr-git \
        vapoursynth-plugin-vivtc-git \
        vapoursynth-plugin-lsmashsource-git; do \
        git clone https://aur.archlinux.org/$pkg.git || true; \
        cd $pkg 2>/dev/null || continue; \
        makepkg --noconfirm -si || true; \
        cd ..; \
    done && rm -rf /tmp/aur

# -----------------------------
# Switch to root for global pip installs and system-level tasks
# -----------------------------
USER root
WORKDIR /

# -----------------------------
# Python packages (system-wide)
# -----------------------------
RUN pip install --no-cache-dir --upgrade pip setuptools yuuno jupyterlab deew --break-system-packages

# -----------------------------
# Optional helper Python tooling from repos
# -----------------------------
RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git /tmp/vs-jetpack && \
    pip install --no-cache-dir /tmp/vs-jetpack --break-system-packages && rm -rf /tmp/vs-jetpack || true

RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/muxtools.git /tmp/muxtools && \
    pip install --no-cache-dir /tmp/muxtools --break-system-packages && rm -rf /tmp/muxtools || true

RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git /tmp/vs-muxtools && \
    pip install --no-cache-dir /tmp/vs-muxtools --break-system-packages && rm -rf /tmp/vs-muxtools || true

# -----------------------------
# Setup Wine environment properly
# -----------------------------
ENV WINEDEBUG=-all
ENV WINEDLLOVERRIDES="mscoree,mshtml="
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

RUN mkdir -p /tmp/runtime-root && \
    chmod 700 /tmp/runtime-root && \
    Xvfb :99 -screen 0 1024x768x16 -nolisten tcp &>/dev/null & \
    XVFB_PID=$! && \
    export DISPLAY=:99 && \
    sleep 2 && \
    timeout 10 winecfg /v win7 2>/dev/null || true && \
    kill $XVFB_PID 2>/dev/null || true

# -----------------------------
# Install eac3to manually
# -----------------------------
RUN mkdir -p /opt/eac3to && \
    cd /opt/eac3to && \
    wget -O eac3to.rar "https://www.videohelp.com/download-wRsSRMSGlWHx/eac3to_3.52.rar" 2>/dev/null || \
    echo "Download failed. Please manually add eac3to files to /opt/eac3to/" && \
    if [ -f eac3to.rar ]; then \
        unrar x eac3to.rar 2>/dev/null || echo "Extraction failed"; \
        rm -f eac3to.rar; \
    fi

# -----------------------------
# Create the fixed wrapper script
# -----------------------------
RUN cat > /usr/local/bin/eac3to << 'EOFSCRIPT'
#!/usr/bin/env bash
# ... your full eac3to wrapper script here ...
EOFSCRIPT

RUN chmod +x /usr/local/bin/eac3to

# -----------------------------
# Create helper script for testing
# -----------------------------
RUN cat > /usr/local/bin/eac3to-test << 'EOFTEST'
#!/bin/bash
echo "Testing eac3to with various argument formats..."
echo ""
echo "Test 1: Simple help"
eac3to -h 2>/dev/null | head -5
echo ""
echo "Test 2: Version info"
eac3to 2>/dev/null | head -2
echo ""
echo "To test with a file:"
echo '  eac3to "input.mkv"'
echo '  eac3to "input.mkv" 1)'
echo '  eac3to input.mkv "1)" output.mkv'
EOFTEST

RUN chmod +x /usr/local/bin/eac3to-test

# -----------------------------
# Test script + minimal VapourSynth snippet
# -----------------------------
RUN mkdir -p /test && \
    echo -e 'import vapoursynth as vs\ncore = vs.core\nclip = core.std.BlankClip(width=640,height=360,length=48,fpsnum=24,fpsden=1)\nclip.set_output()' > /test/test.vpy && \
    echo '{"cells":[{"cell_type":"code","metadata":{},"source":["!vspipe /test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4"],"execution_count":null,"outputs":[]}],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}' > /test/test_vapoursynth.ipynb

# -----------------------------
# Cleanup pacman cache & temp files
# -----------------------------
USER root
RUN pacman -Scc --noconfirm || true && rm -rf /tmp/* /root/.cache /home/builder/.cache || true

# -----------------------------
# Default working dir and CMD (run as builder)
# -----------------------------
USER builder
WORKDIR /home/builder
EXPOSE 8888
CMD ["jupyter", "lab", "--allow-root", "--port=8888", "--no-browser", "--ip=0.0.0.0"]




