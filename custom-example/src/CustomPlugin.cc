/****************************************************************************
 *
 * (c) 2009-2019 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 *   @brief Custom QGCCorePlugin Implementation
 *   @author Gus Grubba <gus@auterion.com>
 */

#include <QtQml>
#include <QQmlEngine>
#include <QDateTime>
#include "QGCSettings.h"
#include "MAVLinkLogManager.h"

#include "CustomPlugin.h"
#include "CustomQuickInterface.h"
#include "CustomVideoManager.h"
#include "CustomBattery.h"
#include "QGroundControlQmlGlobal.h"

#include "MultiVehicleManager.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "AppMessages.h"
#include "QmlComponentInfo.h"
#include "QGCPalette.h"

#include "AccessTypeConfig.h"
#include "PasscodeMenu/PasscodeManager.h"

#include <iostream>
#include <string>




CustomVideoReceiver::CustomVideoReceiver(QObject *parent)
        : VideoReceiver(parent) {
#if defined(QGC_GST_STREAMING)
    //-- Shorter RTSP test interval
    _restart_time_ms = 1000;
#endif
}

CustomVideoReceiver::~CustomVideoReceiver() {
}

//-----------------------------------------------------------------------------
static QObject *
customQuickInterfaceSingletonFactory(QQmlEngine *, QJSEngine *) {
    CustomQuickInterface *pIFace = new CustomQuickInterface();
    auto *pPlug = qobject_cast<CustomPlugin *>(qgcApp()->toolbox()->corePlugin());
    if (pPlug) {
        pIFace->init();
    } else {
        qCritical() << "Error obtaining instance of CustomPlugin";
    }
    return pIFace;
}


static QObject *
customBatterySingletonFactory(QQmlEngine *engine, QJSEngine *scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    // We create this object as a QGCTool even though it isn't in the toolbox
    CustomBattery *pBatt = new CustomBattery();

    return pBatt;
}


//-----------------------------------------------------------------------------
CustomOptions::CustomOptions(CustomPlugin *, QObject *parent)
        : QGCOptions(parent) {
}

//-----------------------------------------------------------------------------
bool
CustomOptions::showFirmwareUpgrade() const {
    return qgcApp()->toolbox()->corePlugin()->showAdvancedUI();
}

QColor
CustomOptions::toolbarBackgroundLight() const {
    return CustomPlugin::_windowShadeEnabledLightColor;
}

QColor
CustomOptions::toolbarBackgroundDark() const {
    return CustomPlugin::_windowShadeEnabledDarkColor;
}

//-----------------------------------------------------------------------------
CustomPlugin::CustomPlugin(QGCApplication *app, QGCToolbox *toolbox)
        : QGCCorePlugin(app, toolbox) {
    _pOptions = new CustomOptions(this, this);
    _showAdvancedUI = false;
}

//-----------------------------------------------------------------------------
CustomPlugin::~CustomPlugin() {
}

//-----------------------------------------------------------------------------
void
CustomPlugin::setToolbox(QGCToolbox *toolbox) {
    QGCCorePlugin::setToolbox(toolbox);
    qmlRegisterSingletonType<CustomQuickInterface>("CustomQuickInterface", 1, 0, "CustomQuickInterface",
                                                   customQuickInterfaceSingletonFactory);
    qmlRegisterSingletonType<CustomBattery>("QGroundControl.CustomBattery", 1, 0, "CustomBattery",
                                            customBatterySingletonFactory);
    //  qmlRegisterType<CustomBattery>("QGroundControl.CustomBattery",1,0,"CustomBattery");


    //-- Disable automatic logging
    toolbox->mavlinkLogManager()->setEnableAutoStart(false);
    toolbox->mavlinkLogManager()->setEnableAutoUpload(false);
    connect(qgcApp()->toolbox()->corePlugin(), &QGCCorePlugin::showAdvancedUIChanged, this,
            &CustomPlugin::_advancedChanged);
}


//-----------------------------------------------------------------------------
void
CustomPlugin::_advancedChanged(bool changed) {
    //-- We are now in "Advanced Mode" (or not)
    emit
    _pOptions->showFirmwareUpgradeChanged(changed);
}

void CustomPlugin::_addSettingsEntry(const QString &title, const char *qmlFile, const char *iconFile, bool show) {
    Q_CHECK_PTR(qmlFile);
    // 'this' instance will take ownership on the QmlComponentInfo instance
    _customSettingsList.append(QVariant::fromValue(
            new QmlComponentInfo(title,
                                 QUrl::fromUserInput(qmlFile),
                                 iconFile == nullptr ? QUrl() : QUrl::fromUserInput(iconFile),
                                 this, true)));
}

AccessType CustomPlugin::returnAccess() {
    return getInitialUserAccessType();
}

void CustomPlugin::setAccessType(QString qAccessType) {
    std::cout << "SET ACCESS TYPE IS BEING CALLED" << std::endl;
    std::string newAccessType = qAccessType.toStdString();
    std::cout << "TRYING TO SET: " << newAccessType << std::endl;
    if (newAccessType == accessTypeString(AccessType::Basic)) {
        this->_accessType = AccessType::Basic;
        _showAdvancedUI = false;
        std::cout << "Setting to Basic" << std::endl;
    } else if (newAccessType == accessTypeString(AccessType::Expert)) {
        this->_accessType = AccessType::Expert;
        _showAdvancedUI = true;
        std::cout << "Setting to Expert" << std::endl;
    } else if (newAccessType == accessTypeString(AccessType::Factory)) {
        this->_accessType = AccessType::Factory;
        std::cout << "Setting to Factory" << std::endl;
    } /*else {
        this->_accessType = AccessType::Basic;
        std::cout << "Setting to Basic in Else" << std::endl;
    }*/

    setUserAccessType(this->_accessType);
}

void CustomPlugin::updateFlightModes() {
    std::cout << "updating flight modes" << std::endl;
//   px4FirmwarePlugin->updateFlightModes();
}

//-----------------------------------------------------------------------------
QGCOptions *
CustomPlugin::options() {
    return _pOptions;
}

//-----------------------------------------------------------------------------
QString
CustomPlugin::brandImageIndoor(void) const {
    return QStringLiteral("/custom/img/void.png");
}

//-----------------------------------------------------------------------------
QString
CustomPlugin::brandImageOutdoor(void) const {
    return QStringLiteral("/custom/img/void.png");
}

//-----------------------------------------------------------------------------
bool
CustomPlugin::overrideSettingsGroupVisibility(QString name) {
    if (name == BrandImageSettings::name) {
        return false;
    }
    return true;
}

//-----------------------------------------------------------------------------
VideoManager *
CustomPlugin::createVideoManager(QGCApplication *app, QGCToolbox *toolbox) {
    return new CustomVideoManager(app, toolbox);
}

//-----------------------------------------------------------------------------
VideoReceiver *
CustomPlugin::createVideoReceiver(QObject *parent) {
    return new CustomVideoReceiver(parent);
}

//-----------------------------------------------------------------------------
QQmlApplicationEngine *
CustomPlugin::createRootWindow(QObject *parent) {
    QQmlApplicationEngine *pEngine = new QQmlApplicationEngine(parent);
    AccessType currentAccessType = getInitialUserAccessType();
    this->setAccessType(
            QString::fromStdString(accessTypeString(currentAccessType)));
    PasscodeManager *passcodeManager = new PasscodeManager();

    pEngine->addImportPath("qrc:/qml");
    pEngine->addImportPath("qrc:/Custom/Widgets");
    pEngine->addImportPath("qrc:/Custom/Camera");
    pEngine->rootContext()->setContextProperty("joystickManager", qgcApp()->toolbox()->joystickManager());
    pEngine->rootContext()->setContextProperty("debugMessageModel", AppMessages::getModel());
    pEngine->rootContext()->setContextProperty("CustomCorePlugin", this);
    pEngine->rootContext()->setContextProperty("PasscodeManager", passcodeManager);
    pEngine->load(QUrl(QStringLiteral("qrc:/qml/MainRootWindow.qml")));
    return pEngine;
}

//-----------------------------------------------------------------------------
bool
CustomPlugin::adjustSettingMetaData(const QString &settingsGroup, FactMetaData &metaData) {
    bool parentResult = QGCCorePlugin::adjustSettingMetaData(settingsGroup, metaData);
    if (settingsGroup == AppSettings::settingsGroup) {
        if (metaData.name() == AppSettings::appFontPointSizeName) {
#if defined(Q_OS_LINUX)
            int defaultFontPointSize = 11;
            metaData.setRawDefaultValue(defaultFontPointSize);
#endif
        } else if (metaData.name() == AppSettings::indoorPaletteName) {
            QVariant indoorPalette = 1;
            metaData.setRawDefaultValue(indoorPalette);
            parentResult = true;
        }
    }
    return parentResult;
}

const QColor     CustomPlugin::_windowShadeEnabledLightColor("#FFFFFF");
const QColor     CustomPlugin::_windowShadeEnabledDarkColor("#212529");

//-----------------------------------------------------------------------------
void
CustomPlugin::paletteOverride(QString colorName, QGCPalette::PaletteColorInfo_t &colorInfo) {
    if (colorName == QStringLiteral("window")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#212529");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#f8f9fa");
    } else if (colorName == QStringLiteral("windowShade")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#343a40");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#343a40");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#f1f3f5");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#d9d9d9");
    } else if (colorName == QStringLiteral("windowShadeDark")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#1a1c1f");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#1a1c1f");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#e9ecef");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#bdbdbd");
    } else if (colorName == QStringLiteral("text")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#777c89");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#9d9d9d");
    } else if (colorName == QStringLiteral("warningText")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#e03131");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#e03131");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#cc0808");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#cc0808");
    } else if (colorName == QStringLiteral("button")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#495057");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#495057");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#ffffff");
    } else if (colorName == QStringLiteral("buttonText")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#777c89");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#9d9d9d");
    } else if (colorName == QStringLiteral("buttonHighlight")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#2a6ba2");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#495057");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#aeebd0");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#e4e4e4");
    } else if (colorName == QStringLiteral("buttonHighlightText")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#777c89");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#2c2c2c");
    } else if (colorName == QStringLiteral("primaryButton")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#2a6ba2");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#495057");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#aeebd0");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#585858");
    } else if (colorName == QStringLiteral("primaryButtonText")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#cad0d0");
    } else if (colorName == QStringLiteral("textField")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#495057");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#f1f3f5");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#ffffff");
    } else if (colorName == QStringLiteral("textFieldText")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#777c89");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#808080");
    } else if (colorName == QStringLiteral("mapButton")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#000000");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#585858");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#585858");
    } else if (colorName == QStringLiteral("mapButtonHighlight")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#2a6ba2");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#585858");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#be781c");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#585858");
    } else if (colorName == QStringLiteral("mapIndicator")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#9dda4f");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#585858");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#be781c");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#585858");
    } else if (colorName == QStringLiteral("mapIndicatorChild")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#527942");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#585858");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#766043");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#585858");
    } else if (colorName == QStringLiteral("colorGreen")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#27bf89");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#0ca678");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#009431");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#009431");
    } else if (colorName == QStringLiteral("colorOrange")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#f7b24a");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#f6921e");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#b95604");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#b95604");
    } else if (colorName == QStringLiteral("colorRed")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#e1544c");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#e03131");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#ed3939");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#ed3939");
    } else if (colorName == QStringLiteral("colorGrey")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#8b90a0");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#8b90a0");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#808080");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#808080");
    } else if (colorName == QStringLiteral("colorBlue")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#228be6");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#228be6");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#1a72ff");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#1a72ff");
    } else if (colorName == QStringLiteral("alertBackground")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#d4b106");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#d4b106");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#fffb8f");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#b45d48");
    } else if (colorName == QStringLiteral("alertBorder")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#876800");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#876800");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#808080");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#808080");
    } else if (colorName == QStringLiteral("alertText")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#000000");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#fff9ed");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#fff9ed");
    } else if (colorName == QStringLiteral("missionItemEditor")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#0b1420");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#585858");
    } else if (colorName == QStringLiteral("hoverColor")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#2a6ba2");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#33c494");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#aeebd0");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#464f5a");
    } else if (colorName == QStringLiteral("mapWidgetBorderLight")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#ffffff");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#f1f3f5");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#ffffff");
    } else if (colorName == QStringLiteral("mapWidgetBorderDark")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#000000");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#000000");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#212529");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#000000");
    } else if (colorName == QStringLiteral("brandingPurple")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#4a2c6d");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#4a2c6d");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#4a2c6d");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#4a2c6d");
    } else if (colorName == QStringLiteral("brandingBlue")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor("#6045c5");
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor("#48d6ff");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor("#6045c5");
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor("#48d6ff");
    }
}

//-----------------------------------------------------------------------------
QVariantList &CustomPlugin::settingsPages() {
    if (_customSettingsList.isEmpty()) {
        _addSettingsEntry(tr("General"), "qrc:/qml/GeneralSettings.qml", "qrc:/res/gear-white.svg");
        _addSettingsEntry(tr("Change Role"), "qrc:/qml/PasswordSettings.qml", "qrc:/res/gear-white.svg");
        _addSettingsEntry(tr("Comm Links"), "qrc:/qml/LinkSettings.qml", "qrc:/res/waves.svg");
        _addSettingsEntry(tr("Offline Maps"), "qrc:/qml/OfflineMap.qml", "qrc:/res/waves.svg");
        _addSettingsEntry(tr("MAVLink"), "qrc:/qml/MavlinkSettings.qml", "qrc:/res/waves.svg");
        _addSettingsEntry(tr("Console"), "qrc:/qml/QGroundControl/Controls/AppMessages.qml", nullptr);
        _addSettingsEntry(tr("Mock Link"), "qrc:/qml/MockLink.qml", nullptr);
        _addSettingsEntry(tr("Remote ID"), "qrc:/qml/RemoteIDSettings.qml", nullptr);
        _addSettingsEntry(tr("Mock Link"), "qrc:/qml/MockLink.qml", nullptr);
        _addSettingsEntry(tr("Debug"), "qrc:/qml/DebugWindow.qml", nullptr);
        _addSettingsEntry(tr("Palette Test"), "qrc:/qml/QmlTest.qml", nullptr);
        _addSettingsEntry(tr("Help"), "qrc:/qml/HelpSettings.qml", nullptr);
    }
    return _customSettingsList;
}
