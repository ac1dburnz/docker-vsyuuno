# -----------------------------
# Base image
# -----------------------------
FROM archlinux:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# -----------------------------
# Install essential packages
# -----------------------------
RUN pacman -Syu --needed --noconfirm \
        sudo git base-devel python python-pip ffms2 vim wget gcc \
        vapoursynth ffmpeg x264 x265 lame flac opus-tools sox \
        mplayer mpv x11vnc xorg-server-xvfb unzip cabextract wine \
        rust cargo unrar unrar \
    && pacman -Sc --noconfirm

# -----------------------------
# Create temporary user for yay (AUR)
# -----------------------------
RUN useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder

USER builder
WORKDIR /home/builder

# -----------------------------
# Install yay (AUR helper)
# -----------------------------
RUN git clone https://aur.archlinux.org/yay.git /tmp/yay && \
    cd /tmp/yay && makepkg --noconfirm --noprogressbar -si && \
    cd / && rm -rf /tmp/yay

# -----------------------------
# Install VapourSynth plugins via yay
# -----------------------------
RUN yay -S --needed --noconfirm \
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
        vapoursynth-plugin-lsmashsource-git \
    && yay -Sc --noconfirm

# -----------------------------
# Switch to root for system-wide installs
# -----------------------------
USER root
WORKDIR /

# -----------------------------
# Install Python packages system-wide
# -----------------------------
RUN pip install --no-cache-dir --upgrade pip setuptools yuuno jupyterlab deew

# -----------------------------
# Install vs-jetpack & vs-muxtools
# -----------------------------
RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git /tmp/vs-jetpack && \
    pip install --no-cache-dir /tmp/vs-jetpack --break-system-packages && \
    rm -rf /tmp/vs-jetpack

RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git /tmp/vs-muxtools && \
    pip install --no-cache-dir /tmp/vs-muxtools --break-system-packages && \
    rm -rf /tmp/vs-muxtools

# -----------------------------
# Install eac3to via Wine
# -----------------------------
# Must place files/eac3to_3.52.rar next to Dockerfile
COPY files/eac3to_3.52.rar /opt/eac3to/
RUN mkdir -p /opt/eac3to && \
    unrar x /opt/eac3to/eac3to_3.52.rar /opt/eac3to/ && \
    rm /opt/eac3to/eac3to_3.52.rar && \
    echo -e '#!/bin/bash\nwine /opt/eac3to/eac3to.exe "$@"' > /usr/local/bin/eac3to && \
    chmod +x /usr/local/bin/eac3to

# -----------------------------
# Add test VapourSynth script & notebook
# -----------------------------
RUN mkdir -p /test && \
    echo 'import vapoursynth as vs\ncore = vs.core\nclip = core.std.BlankClip(width=1280,height=720,length=240,fpsnum=24,fpsden=1,color=[128])\nclip = core.text.Text(clip,"Hello VapourSynth in Docker!")\nclip.set_output()' > /test/test.vpy && \
    echo '{"cells":[{"cell_type":"code","metadata":{},"source":["!vspipe /test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4"],"execution_count":null,"outputs":[]}],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}' > /test/test_vapoursynth.ipynb

# -----------------------------
# Cleanup
# -----------------------------
RUN pacman -Scc --noconfirm && rm -rf /tmp/* /root/.cache /home/builder/.cache || true

# -----------------------------
# Default working dir and CMD
# -----------------------------
WORKDIR /
EXPOSE 8888
CMD ["jupyter", "lab", "--allow-root", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
