# QGroundControl Ground Control Station

[![Releases](https://img.shields.io/github/release/mavlink/QGroundControl.svg)](https://github.com/mavlink/QGroundControl/releases)

*QGroundControl* (QGC) is an intuitive and powerful ground control station (GCS) for UAVs.

The primary goal of QGC is ease of use for both first time and professional users.
It provides full flight control and mission planning for any MAVLink enabled drone, and vehicle setup for both PX4 and ArduPilot powered UAVs. Instructions for *using QGroundControl* are provided in the [User Manual](https://docs.qgroundcontrol.com/en/) (you may not need them because the UI is very intuitive!)

All the code is open-source, so you can contribute and evolve it as you want.
The [Developer Guide](https://dev.qgroundcontrol.com/en/) explains how to [build](https://dev.qgroundcontrol.com/en/getting_started/) and extend QGC.


Key Links:
* [Website](http://qgroundcontrol.com) (qgroundcontrol.com)
* [User Manual](https://docs.qgroundcontrol.com/en/)
* [Developer Guide](https://dev.qgroundcontrol.com/en/)
* [Discussion/Support](https://docs.qgroundcontrol.com/en/Support/Support.html)
* [Contributing](https://dev.qgroundcontrol.com/en/contribute/)
* [License](https://github.com/mavlink/qgroundcontrol/blob/master/COPYING.md)




QGC MASTERCLASS
1.	Pre-requirements 
2.	Understand the architecture 
3.	Custom Module 
4.	(Run simulator)
5.	Deploy for other platform 
6.	Transfer to the Herelink 





Pre-requirements
1.	Use a fresh installation of ubuntu 22
2.	Install QT 
3.	Install VSCode
4.	Clone 
4.1. git clone --recursive -j8 -b masterclass git@github.com:hural-dynamics/rover-app.git

5.	Install submodules
5.1 sudo apt install qt6-base-dev qt6-base-private-dev qt6-declarative-dev qt6-declarative-private-dev qt6-tools-dev qt6-tools-private-dev qt6-scxml-dev qt6-documentation-tools libqt6core5compat6-dev qt6-tools-dev-tools qt6-l10n-tools qt6-shader-baker libqt6shadertools6-dev qt6-quick3d-dev qt6-quick3d-dev-tools libqt6svg6-dev libqt6quicktimeline6-dev libqt6serialport6-dev
5.2 sudo apt install libgl1-mesa-dev libvulkan-dev libxcb-xinput-dev libxcb-xinerama0-dev libxkbcommon-dev libxkbcommon-x11-dev libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxcb-xkb1 libxcb-randr0 libxcb-icccm4
5.3 sudo apt-get install speech-dispatcher libudev-dev libsdl2-dev patchelf build-essential
6.	Build 
If have any problems with qmake try: 
6.1 nano ~/.bashrc
6.2 export PATH="/opt/Qt/6.6.2/gcc_64/bin/:$PATH"
6.3 source ~/.bashrc
6.4 try qmake ../qgroundcontrol.pro if doesnt work try make -j8 and it'll start the build
6.5 sudo usermod -a -G dialout $USER and sudo apt-get remove modemmanager


If have any problems with qmake try: 
6.1 nano ~/.bashrc
6.2 export PATH="/opt/Qt/6.6.2/gcc_64/bin/:$PATH"
6.3 source ~/.bashrc
6.4 create a dir build
    mkdir build
    cd build
6.5 building
    qmake ../qgroundcontrol.pro
    make -j8 and it'll 
6.5 sudo usermod -a -G dialout $USER and sudo apt-get remove modemmanager


7.	Launch locally 



8. Install adb
sudo apt -y install android-tools-adb
9. Install APK
adb install path_to_apk
















Architecture















Custom Build 
















Simulator

























Deploy



















Herelink

