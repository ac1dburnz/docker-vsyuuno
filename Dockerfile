FROM archlinux:latest

# -----------------------------
# System setup
# -----------------------------
RUN pacman -Syu --needed --noconfirm sudo git base-devel wget vim python-pip \
    ffmpeg mkvtoolnix-cli mkvtoolnix-gui && \
    pacman -Sc --noconfirm

# Create user
RUN useradd user --system --shell /bin/bash --create-home --home-dir /home/user
RUN passwd --lock user
RUN echo "user ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/allow_user_to_pacman

USER user
WORKDIR /home/user

# -----------------------------
# AUR helper (yay)
# -----------------------------
RUN git clone https://aur.archlinux.org/yay.git /tmp/yay && \
    cd /tmp/yay && \
    makepkg -si --noconfirm && \
    cd /home/user && rm -rf /tmp/yay

# -----------------------------
# Install VapourSynth + Plugins
# -----------------------------
RUN sudo pacman -Syu --needed --noprogressbar --noconfirm vapoursynth \
    vapoursynth-plugin-bestsource vapoursynth-plugin-mvtools ffms2 && \
    yay -Syu --overwrite "*" --noconfirm \
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
    dee-git \
    && yay -Sc --noconfirm

# -----------------------------
# Python tools
# -----------------------------
RUN pip install --no-cache-dir --upgrade pip --break-system-packages
RUN pip install --no-cache-dir yuuno jupyterlab --break-system-packages

# -----------------------------
# Clone VS & Encoding tools
# -----------------------------
RUN mkdir -p /home/user/tools /home/user/encode-scripts

WORKDIR /home/user/tools
RUN git clone https://github.com/Irrational-Encoding-Wizardry/vs-preview.git
RUN git clone https://github.com/YomikoR/VapourSynth-Editor.git
RUN git clone https://github.com/quietvoid/vspreview-rs.git
RUN git clone https://github.com/yuuno-project/yuuno.git
RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git
RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git

WORKDIR /home/user/encode-scripts
RUN git clone https://github.com/Ichunjo/encode-scripts.git
RUN git clone https://github.com/LightArrowsEXE/Encoding-Projects.git
RUN git clone https://github.com/Setsugennoao/Encoding-Scripts.git
RUN git clone https://github.com/RivenSkaye/Encoding-Progress.git
RUN git clone https://github.com/Moelancholy/Encode-Scripts.git

# -----------------------------
# Setup helper scripts
# -----------------------------
WORKDIR /home/user
RUN mkdir -p helpers
COPY helpers/menu.sh helpers/menu.sh
RUN chmod +x helpers/menu.sh

# -----------------------------
# Cleanup
# -----------------------------
RUN rm -rf /tmp/* /root/.cache /home/user/.cache

EXPOSE 8888

CMD ["/home/user/helpers/menu.sh"]