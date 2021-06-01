/*
 * Copyright 2020  Dimitris Kardarakos <dimkard@posteo.net>
 * Copyright 2021  Wang Rui <wangrui@jingos.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "pointer.h"

#include <KAboutData>
#include <KLocalizedString>
#include <KPluginFactory>
#include <unistd.h>
#include <QDebug>
#include <QDBusInterface>
#include <QDBusConnection>

#include "../mouse/backends/x11/evdev_settings.h"

#include "inputbackend.h"

K_PLUGIN_CLASS_WITH_JSON(Pointer, "pointer.json")

QVariant Pointer::getDeviceList(InputBackend *backend)
{
    // qDebug() << "--------getDeviceList-------::: " << (backend->getDevices().toList().length()); 
    m_deviceModel = QVariant::fromValue(backend->getDevices().toList());
    emit deviceModelChanged();
    return m_deviceModel;
}

Pointer::Pointer(QObject *parent, const QVariantList &args)
: KQuickAddons::ConfigModule(parent, args)
{
    KLocalizedString::setApplicationDomain("kcm_pointer");
    KAboutData *about = new KAboutData("kcm_pointer", i18n("Pointer"), "1.0", QString(), KAboutLicense::GPL);
    about->addAuthor(i18n("Jake Wu"), QString(), "jake@jingos.com");
    setAboutData(about);

    initDevices();

    m_backend = InputBackend::implementation(parent);
    
    m_deviceModel = getDeviceList(m_backend);

    load();
}

void Pointer::initDevices() {
    m_deviceManager = new QDBusInterface (QStringLiteral("org.kde.KWin"),
                                          QStringLiteral("/org/kde/KWin/InputDevice"),
                                          QStringLiteral("org.kde.KWin.InputDeviceManager"),
                                          QDBusConnection::sessionBus(),
                                          this);

    findDevices();

    m_deviceManager->connection().connect(QStringLiteral("org.kde.KWin"),
                                          QStringLiteral("/org/kde/KWin/InputDevice"),
                                          QStringLiteral("org.kde.KWin.InputDeviceManager"),
                                          QStringLiteral("deviceAdded"),
                                          this,
                                          SLOT(onDeviceAdded(QString)));
    m_deviceManager->connection().connect(QStringLiteral("org.kde.KWin"),
                                          QStringLiteral("/org/kde/KWin/InputDevice"),
                                          QStringLiteral("org.kde.KWin.InputDeviceManager"),
                                          QStringLiteral("deviceRemoved"),
                                          this,
                                          SLOT(onDeviceRemoved(QString)));
}


void Pointer::findDevices()
{
    QStringList devicesSysNames;
    const QVariant reply = m_deviceManager->property("devicesSysNames");
    if (reply.isValid()) {
        qDebug() << "Devices list received successfully from KWin.";
        devicesSysNames = reply.toStringList();
    }
    else {
        qDebug() << "Error on receiving device list from KWin.";
        return;
    }

    for (QString sn : devicesSysNames) {
        // qDebug()<< "找到设备: "<<sn ; 
        QDBusInterface deviceIface(QStringLiteral("org.kde.KWin"),
                                    QStringLiteral("/org/kde/KWin/InputDevice/") + sn,
                                    QStringLiteral("org.kde.KWin.InputDevice"),
                                    QDBusConnection::sessionBus(),
                                    this);
        QVariant reply = deviceIface.property("pointer");
        if (reply.isValid() && reply.toBool()) {
            reply = deviceIface.property("touchpad");
            if (reply.isValid() && reply.toBool()) {
                continue;
            }

        }
    }
}

void Pointer::load() {

    bool result = m_backend->getConfig();
    qDebug()<< "get config result : "<< result;

}

void Pointer::save(){
    bool result = m_backend->applyConfig();
    qDebug()<< "save config result : "<< result;
    load();
}





#include "pointer.moc"
