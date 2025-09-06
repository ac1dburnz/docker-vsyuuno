FROM archlinux:latest

# -----------------------------
# SYSTEM SETUP
# -----------------------------
RUN pacman -Syu --needed --noconfirm sudo git base-devel vim wget curl xorg-xhost xorg-xrandr xorg-xset xorg-xdpyinfo \
    gtk3 qt5-base python python-pip ffmpeg lame flac opus-tools && \
    pacman -Sc --noconfirm

# Create user
RUN useradd -m -s /bin/bash user && passwd -l user
RUN echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user

USER user
WORKDIR /home/user

# -----------------------------
# Install yay (AUR helper) with retries
# -----------------------------
USER user
WORKDIR /tmp

# Retry cloning yay up to 5 times
RUN set -e; \
    for i in 1 2 3 4 5; do \
        echo "Attempt $i to clone yay..."; \
        git clone https://aur.archlinux.org/yay.git /tmp/yay && break || sleep 5; \
    done; \
    cd /tmp/yay && \
    makepkg --noconfirm -si && \
    cd /home/user && \
    rm -rf /tmp/yay

# -----------------------------
# Install VapourSynth + plugins
# -----------------------------
RUN sudo pacman -Syu --needed --noconfirm vapoursynth ffms2 python-pip && \
    yay -S --needed --noconfirm \
        vapoursynth-plugin-bestsource \
        vapoursynth-plugin-mvtools \
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
        vapoursynth-plugin-lsmashsource-git

# -----------------------------
# Install vs-jetpack & vs-muxtools
# -----------------------------
RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git /home/user/vs-jetpack && \
    cd /home/user/vs-jetpack && \
    pip install --user . --break-system-packages

RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git /home/user/vs-muxtools && \
    cd /home/user/vs-muxtools/vsmuxtools && \
    pip install --user . --break-system-packages

# -----------------------------
# Install DEEW, MKVToolNix GUI, EAC3to, QAAC alternatives
# -----------------------------
RUN yay -S --needed --noconfirm deew-git mkvtoolnix-gui eac3to-git

# -----------------------------
# Clone helpful encoding repos
# -----------------------------
RUN git clone https://github.com/Irrational-Encoding-Wizardry/vspreview.git /home/user/vspreview && \
    git clone https://github.com/YomikoR/VapourSynth-Editor.git /home/user/vsedit && \
    git clone https://github.com/LightArrowsEXE/Encoding-Projects.git /home/user/encode-scripts

# -----------------------------
# Install JupyterLab + Yuuno
# -----------------------------
RUN pip install --user --break-system-packages jupyterlab yuuno setuptools

# -----------------------------
# Supervisord setup
# -----------------------------
USER root
RUN pacman -S --needed --noconfirm supervisor
COPY supervisord.conf /etc/supervisord.conf

# -----------------------------
# Cleanup
# -----------------------------
RUN rm -rf /tmp/* /var/cache/pacman/pkg/*

# -----------------------------
# Expose ports for JupyterLab/Yuuno and VNC if used
# -----------------------------
EXPOSE 8888 5900

USER user
WORKDIR /home/user
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]