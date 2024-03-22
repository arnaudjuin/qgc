#include "GlobalSignals.h"

GlobalSignals* GlobalSignals::_instance = nullptr;

GlobalSignals::GlobalSignals(QObject* parent) : QObject(parent) {
    // Inicializações adicionais necessárias aqui
}

GlobalSignals* GlobalSignals::instance() {
    if (_instance == nullptr) {
        _instance = new GlobalSignals();
    }
    return _instance;
}

