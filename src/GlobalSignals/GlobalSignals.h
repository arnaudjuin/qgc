#ifndef GLOBALSIGNALS_H
#define GLOBALSIGNALS_H

#include <QObject>

class GlobalSignals : public QObject {
    Q_OBJECT

public:
    explicit GlobalSignals(QObject *parent = nullptr);

    static GlobalSignals* instance();

signals:
    void showPanels();
    void hidePanels();
    void buttonArm();
    void buttonDisarm();

private:
    static GlobalSignals* _instance;
};

#endif // GLOBALSIGNALS_H
