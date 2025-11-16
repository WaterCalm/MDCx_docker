FROM ubuntu:24.04

# for the VNC connection
EXPOSE 5900
# for the browser VNC client
EXPOSE 5901
# Use environment variable to allow custom VNC passwords
ENV VNC_PASSWD=123456
ENV TZ=Asia/Shanghai
ENV DISPLAY=:0

# Make sure the dependencies are met
ENV APT_INSTALL_PRE="apt -o Acquire::ForceIPv4=true update && DEBIAN_FRONTEND=noninteractive apt -o Acquire::ForceIPv4=true install -y --no-install-recommends"
ENV APT_INSTALL_POST="&& apt clean -y && rm -rf /var/lib/apt/lists/*"
# Make sure the dependencies are met
RUN eval ${APT_INSTALL_PRE} tigervnc-standalone-server tigervnc-common tigervnc-tools fluxbox eterm xterm git net-tools python3 python3-numpy ca-certificates scrot pulseaudio-utils fonts-noto-cjk thunar ${APT_INSTALL_POST}

# Install VNC. Requires net-tools, python and python-numpy
RUN git clone --branch v1.4.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC
RUN git clone --branch v0.11.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify
RUN ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Add menu entries to the container
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus

# Add in a health status
HEALTHCHECK --start-period=10s CMD bash -c "if [ \"`pidof -x Xtigervnc | wc -l`\" == "1" ]; then exit 0; else exit 1; fi"

# Copy various files to their respective places
COPY scripts/container_startup.sh /opt/container_startup.sh
COPY scripts/x11vnc_entrypoint.sh /opt/x11vnc_entrypoint.sh
RUN chmod +x /opt/container_startup.sh /opt/x11vnc_entrypoint.sh
# Subsequent images can put their scripts to run at startup here
RUN mkdir /opt/startup_scripts

# MDCx
RUN mkdir -p /app /data
COPY app/MDCx /app/MDCx
COPY app/MDCx.config /app/MDCx.config
RUN chmod +x /app/MDCx
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"MDCx\" command=\"/app/MDCx\"" >> /usr/share/menu/custom-docker && update-menus
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Files Manager\" command=\"thunar\"" >> /usr/share/menu/custom-docker && update-menus

WORKDIR /app
ENTRYPOINT ["/opt/container_startup.sh"]