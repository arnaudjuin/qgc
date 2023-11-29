#include "PasscodeManager.h"
#include <iostream>
#include <fstream>
#include <string>
#include <QDebug>

#include <filesystem> // delete this pls

using namespace std;

PasscodeManager::PasscodeManager() {
    this->setConfigFile("userAccessConfig.txt");
}

PasscodeManager::~PasscodeManager() {}

list <QString> PasscodeManager::getPasscodes() {
    return this->_passcodes;
}

void PasscodeManager::setConfigFile(string fileName) {
//    this->_configFile = fileName;
//    std::cout << "Setting config file name to: " << this->_configFile << std::endl;
//    this->_initPasscodes();
}

void PasscodeManager::_initPasscodes() {
//    fstream passcodeConfigFile;
//
//    std::filesystem::path cwd = std::filesystem::current_path();
//    std::cout << "CWD: " << cwd << std::endl;
//
//    passcodeConfigFile.open(this->_configFile, ios::in);
//    string line;
//    int i = 0;
//    std::cout << "INITPASSCODES() CALLED" << std::endl;
//    while(getline(passcodeConfigFile, line)) {
//        std::cout << "READ IN LINE: " << line << std::endl;
//        this->_passcodes.push_back(QString::fromStdString(line));
//        i++;
//    }
//    passcodeConfigFile.close();
//    qDebug() << "Passcodes Loaded:";
//    qDebug() << this->_passcodes.size();
}

//QGCOptions *
//CustomPlugin::options() {
//    return _pOptions;
//}

QString PasscodeManager::submitPasscode(QString passcode) {
//    QString accessLevels[] = {
//            "Expert",
//            "Factory",
//            "Basic"
//    };
//    int i = 0;
//    for (list<QString>::iterator iter = this->_passcodes.begin(); iter != this->_passcodes.end(); iter++) {
//        if (passcode == *iter) {
//            return accessLevels[i];
//        }
//        i++;
//    }
    return "";
}
