# -----------------------------
# Base image
# -----------------------------
FROM archlinux:latest

# -----------------------------
# Enable multilib and update repos (necessary for lib32 packages)
# -----------------------------
RUN sed -i '/\[multilib\]/,/^Include/ s/^#//' /etc/pacman.conf && \
    pacman -Syu --noconfirm

# -----------------------------
# Install core packages (no wine-mono / wine-gecko here)
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
# Install eac3to (download + extract) and add wrapper
# -----------------------------
RUN mkdir -p /opt/eac3to && \
    wget -O /opt/eac3to/eac3to_3.52.rar "https://www.videohelp.com/download-wRsSRMSGlWHx/eac3to_3.52.rar" || true && \
    if [ -f /opt/eac3to/eac3to_3.52.rar ]; then unrar x /opt/eac3to/eac3to_3.52.rar /opt/eac3to/ && rm /opt/eac3to/eac3to_3.52.rar; fi && \
    echo -e '#!/bin/bash\nexec xvfb-run -a wine /opt/eac3to/eac3to.exe "$@"' > /usr/local/bin/eac3to && \
    chmod +x /usr/local/bin/eac3to && \
    chown -R builder:builder /opt/eac3to || true

# -----------------------------
# Pre-initialize Wine prefix as builder (creates ~/.wine, lets Wine fetch mono/gecko)
# -----------------------------
USER builder
ENV WINEPREFIX=/home/builder/.wine
RUN mkdir -p /home/builder/.wine && xvfb-run -a winecfg || true

# -----------------------------
# Test script + minimal test vapoursynth snippet
# -----------------------------
RUN mkdir -p /test && \
    echo 'import vapoursynth as vs\ncore = vs.core\nclip = core.std.BlankClip(width=640,height=360,length=48,fpsnum=24,fpsden=1)\nclip.set_output()' > /test/test.vpy && \
    echo '{"cells":[{"cell_type":"code","metadata":{},"source":["!vspipe /test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4"],"execution_count":null,"outputs":[]}],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}' > /test/test_vapoursynth.ipynb

# -----------------------------
# Cleanup pacman cache & temp files
# -----------------------------
USER root
RUN pacman -Scc --noconfirm && rm -rf /tmp/* /root/.cache /home/builder/.cache || true

# -----------------------------
# Default working dir and CMD (run as builder)
# -----------------------------
USER builder
WORKDIR /home/builder
EXPOSE 8888
CMD ["jupyter", "lab", "--allow-root", "--port=8888", "--no-browser", "--ip=0.0.0.0"]


