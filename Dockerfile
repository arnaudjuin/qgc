 FROM ubuntu:latest

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    libqt5widgets5 \
    libqt5gui5 \
    libqt5network5 \
    libqt5serialport5 \
    libqt5sql5 \
    libqt5xml5 \
    libqt5opengl5 \
    libqt5opengl5-dev \
    libqt5multimedia5 \
    libqt5multimedia5-plugins \
    libqt5printsupport5 \
    libqt5positioning5 \
    libqt5websockets5 \
    libqt5charts5 \
    libqt5webengine-data \
    libqt5webengine5 \
    libudev1 \
    libusb-1.0-0

# Copy QGroundControl AppImage
COPY CustomQGC.AppImage /usr/local/bin/QGC.AppImage

# Make it executable
RUN chmod +x /usr/local/bin/CustomQGC.AppImage

# Expose QGroundControl port (if needed)
EXPOSE 14550

# Start QGroundControl
CMD ["/usr/local/bin/CustomQGC.AppImage"]