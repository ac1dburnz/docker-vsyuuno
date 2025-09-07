# -----------------------------
# Base image
# -----------------------------
FROM archlinux:latest

# -----------------------------
# System dependencies
# -----------------------------
RUN pacman -Syu --needed --noconfirm \
        sudo git base-devel python python-pip ffms2 wget gcc \
        vapoursynth ffmpeg x264 x265 lame flac opus-tools sox \
        mplayer mpv mkvtoolnix-cli unzip cabextract wine rust \
        nano \
    && pacman -Sc --noconfirm

# -----------------------------
# Create non-root user
# -----------------------------
RUN useradd -m -d /home/user -s /bin/bash user \
    && passwd --lock user \
    && echo "user ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/allow_user_pacman \
    && echo "root ALL=(ALL) CWD=* ALL" > /etc/sudoers.d/permissive_root_chdir

USER user
WORKDIR /tmp

# -----------------------------
# Install yay (AUR helper)
# -----------------------------
RUN set -e; \
    for i in 1 2 3; do \
        git clone https://aur.archlinux.org/yay.git /tmp/yay && break || sleep 5; \
    done; \
    cd /tmp/yay && makepkg -si --noconfirm --noprogressbar; \
    cd /tmp && rm -rf /tmp/yay

# -----------------------------
# VapourSynth plugins
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
# Python packages + deew
# -----------------------------
USER root
RUN pip install --no-cache-dir --break-system-packages --upgrade \
        pip setuptools \
        yuuno jupyterlab deew \
        git+https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git \
        git+https://github.com/Jaded-Encoding-Thaumaturgy/muxtools.git \
        git+https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git

# -----------------------------
# eac3to via Wine
# -----------------------------
RUN mkdir -p /opt/eac3to \
    && wget -O /opt/eac3to/eac3to.zip https://www.videohelp.com/download/eac3to.zip \
    && unzip /opt/eac3to/eac3to.zip -d /opt/eac3to \
    && rm /opt/eac3to/eac3to.zip \
    && echo '#!/bin/bash\nwine /opt/eac3to/eac3to.exe "$@"' > /usr/local/bin/eac3to \
    && chmod +x /usr/local/bin/eac3to

# -----------------------------
# Optional encoding repos
# -----------------------------
USER user
WORKDIR /home/user/repos
RUN for repo in \
    https://github.com/OpusGang/EncodeScripts.git \
    https://github.com/Ichunjo/encode-scripts.git \
    https://github.com/LightArrowsEXE/Encoding-Projects.git \
    https://github.com/Beatrice-Raws/encode-scripts.git \
    https://github.com/Setsugennoao/Encoding-Scripts.git \
    https://github.com/RivenSkaye/Encoding-Progress.git \
    https://github.com/Moelancholy/Encode-Scripts.git; do \
    https://github.com/Ichunjo/encode-scripts.git; do \
        git clone "$repo" || true; \
    done
# -----------------------------
# Test VapourSynth script & notebook
# -----------------------------
WORKDIR /home/user/test
RUN echo 'import vapoursynth as vs\ncore = vs.core\nclip = core.std.BlankClip(width=1280,height=720,length=240,fpsnum=24,fpsden=1,color=[128])\nclip = core.text.Text(clip,"Hello VapourSynth in Docker!")\nclip.set_output()' > test.vpy

RUN echo '{"cells":[{"cell_type":"code","metadata":{},"source":["!vspipe /home/user/test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4"],"execution_count":null,"outputs":[]}],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}' > test_vapoursynth.ipynb

# -----------------------------
# Cleanup
# -----------------------------
RUN pacman -Scc --noconfirm && rm -rf /tmp/* /root/.cache /home/user/.cache || true

# -----------------------------
# Working dir, ports, CMD
# -----------------------------
WORKDIR /home/user
EXPOSE 8888
CMD ["jupyter", "lab", "--allow-root", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
