FROM archlinux:latest

# -----------------------------
# Base system & user
# -----------------------------
RUN pacman -Syu --needed --noconfirm sudo git base-devel vim wget python-pip gcc && \
    pacman -Sc --noconfirm

RUN useradd user --system --shell /bin/bash --create-home --home-dir /var/user
RUN passwd --lock user
RUN echo "user ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/allow_user_to_pacman
RUN echo "root ALL=(ALL) CWD=* ALL" > /etc/sudoers.d/permissive_root_Chdir_Spec

# -----------------------------
# Install essential packages
# -----------------------------
RUN pacman -Syu --needed --noprogressbar --noconfirm \
        ffms2 \
        vapoursynth \
        vapoursynth-plugin-bestsource \
        vapoursynth-plugin-mvtools \
        python-pip \
        wget \
        git \
        base-devel \
        gcc \
        vim && \
    pacman -Sc --noconfirm

USER user
WORKDIR /tmp

# -----------------------------
# Install yay with retries
# -----------------------------
RUN set -e; \
    for i in 1 2 3 4 5; do \
        echo "Attempt $i to clone yay..."; \
        git clone https://aur.archlinux.org/yay.git && break || sleep 5; \
    done; \
    cd yay && \
    makepkg --noconfirm --noprogressbar -si && \
    yay --afterclean --removemake --save && cd -

# -----------------------------
# Install VapourSynth plugins from AUR
# -----------------------------
RUN yay -Syu --overwrite "*" --noconfirm --noprogressbar --needed \
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
    vapoursynth-plugin-lsmashsource-git && \
    yay -Sc --noconfirm

# -----------------------------
# Install vs-jetpack
# -----------------------------
RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git /tmp/vs-jetpack && \
    cd /tmp/vs-jetpack && \
    pip install --no-cache-dir . --break-system-packages && \
    python -m vsjetpack --help || true

# -----------------------------
# Install vs-muxtools
# -----------------------------
RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git /tmp/vs-muxtools && \
    cd /tmp/vs-muxtools/vsmuxtools && \
    pip install --no-cache-dir . --break-system-packages && \
    python -m vsmuxtools --help || true

# -----------------------------
# Install Deew, MKVToolNix GUI, other remuxers
# -----------------------------
RUN yay -S --noconfirm --needed \
    deew-git \
    mkvtoolnix-gui \
    ffmpeg \
    lame \
    flac \
    x264 \
    x265 \
    aacgain \
    faac \
    opus-tools \
    sox

# -----------------------------
# Install Python projects
# -----------------------------
USER root
RUN pip install --no-cache-dir --upgrade pip --break-system-packages && \
    pip install --no-cache-dir --upgrade yuuno setuptools --break-system-packages

# -----------------------------
# Install JupyterLab
# -----------------------------
RUN pip install --no-cache-dir jupyterlab --break-system-packages

# -----------------------------
# Final cleanup
# -----------------------------
WORKDIR /
RUN rm -rf /tmp/yay /tmp/vs-jetpack /tmp/vs-muxtools /root/.cache /home/user/.cache

EXPOSE 8888

CMD ["jupyter", "lab", "--allow-root", "--port=8888", "--no-browser", "--ip=0.0.0.0"]