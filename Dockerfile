# -----------------------------
# Base image
# -----------------------------
FROM archlinux:latest

ENV DEBIAN_FRONTEND=noninteractive

# -----------------------------
# Install essential system packages
# -----------------------------
RUN pacman -Syu --needed --noconfirm \
        sudo git base-devel python python-pip ffms2 vim wget gcc \
        vapoursynth ffmpeg x264 x265 lame flac opus-tools sox \
        mplayer mpv x11vnc xorg-server-xvfb unzip cabextract wine \
        rust cargo unrar \
    && pacman -Sc --noconfirm

# -----------------------------
# Create non-root user for yay (AUR)
# -----------------------------
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder && \
    echo "root ALL=(ALL) CWD=* ALL" > /etc/sudoers.d/permissive_root_Chdir_Spec

USER builder
WORKDIR /home/builder

# -----------------------------
# Install yay (AUR helper)
# -----------------------------
RUN git clone https://aur.archlinux.org/yay.git && \
    cd yay && makepkg --noconfirm --noprogressbar -si && \
    cd .. && rm -rf yay

# -----------------------------
# Install VapourSynth plugins via yay
# -----------------------------
RUN yay -Syu --overwrite "*" --needed --noconfirm \
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
# Install Python packages & projects
# -----------------------------
RUN pip install --no-cache-dir --break-system-packages --upgrade \
        pip setuptools yuuno jupyterlab deew

# vs-jetpack
RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git /tmp/vs-jetpack && \
    pip install --no-cache-dir /tmp/vs-jetpack --break-system-packages && \
    rm -rf /tmp/vs-jetpack

# vs-muxtools
RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git /tmp/vs-muxtools && \
    pip install --no-cache-dir /tmp/vs-muxtools --break-system-packages && \
    rm -rf /tmp/vs-muxtools

# -----------------------------
# Switch to root for system-wide installs
# -----------------------------
USER root
WORKDIR /

# -----------------------------
# Install eac3to from local repo
# -----------------------------
COPY files/eac3to_3.52.rar /opt/eac3to/
RUN mkdir -p /opt/eac3to && \
    unrar x /opt/eac3to/eac3to_3.52.rar /opt/eac3to/ && \
    rm /opt/eac3to/eac3to_3.52.rar && \
    echo '#!/bin/bash\nwine /opt/eac3to/eac3to.exe "$@"' > /usr/local/bin/eac3to && \
    chmod +x /usr/local/bin/eac3to

# -----------------------------
# Clone encoding repos (optional)
# -----------------------------
RUN mkdir -p /repos && cd /repos && \
    for repo in \
        https://github.com/OpusGang/EncodeScripts.git \
        https://github.com/Ichunjo/encode-scripts.git \
        https://github.com/LightArrowsEXE/Encoding-Projects.git \
        https://github.com/Beatrice-Raws/encode-scripts.git \
        https://github.com/Setsugennoao/Encoding-Scripts.git \
        https://github.com/RivenSkaye/Encoding-Progress.git \
        https://github.com/Moelancholy/Encode-Scripts.git; do \
        echo "Cloning $repo ..."; \
        git clone "$repo" || echo "Failed to clone $repo, skipping."; \
    done

# -----------------------------
# Add test VapourSynth script & notebook
# -----------------------------
RUN mkdir -p /test && chown builder:builder /test && \
    echo 'import vapoursynth as vs\ncore = vs.core\nclip = core.std.BlankClip(width=1280,height=720,length=240,fpsnum=24,fpsden=1,color=[128])\nclip = core.text.Text(clip,"Hello VapourSynth in Docker!")\nclip.set_output()' > /test/test.vpy && \
    echo '{"cells":[{"cell_type":"code","metadata":{},"source":["!vspipe /test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4"],"execution_count":null,"outputs":[]}],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}' > /test/test_vapoursynth.ipynb

# -----------------------------
# Cleanup
# -----------------------------
RUN pacman -Scc --noconfirm && rm -rf /tmp/* /root/.cache /home/builder/.cache || true

# -----------------------------
# Default working dir and CMD
# -----------------------------
USER root
WORKDIR /
EXPOSE 8888
CMD ["jupyter", "lab", "--allow-root", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
