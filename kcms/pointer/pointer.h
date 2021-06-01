/*
 * Copyright 2020  Dimitris Kardarakos <dimkard@posteo.net>
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

// #include <KQuickAddons/ConfigModule>
#ifndef TRACKPAD_H
#define TRACKPAD_H

#include <KQuickAddons/ConfigModule>
#include <QObject>
#include <QDBusInterface>

#include "inputbackend.h"

class Pointer : public KQuickAddons::ConfigModule
{
    Q_OBJECT

    Q_PROPERTY(InputBackend* backend READ backend)
    Q_PROPERTY(QVariant deviceModel READ deviceModel NOTIFY deviceModelChanged)

public:
    Pointer(QObject *parent, const QVariantList &args);
    void load();
    void initDevices();
    void findDevices();
    Q_INVOKABLE QVariant getDeviceList(InputBackend *backend);

    // Q_INVOKABLE QString valueWriter(QString deviceName  , QVariant deviceValue);
    Q_INVOKABLE void save();

    InputBackend* backend() {
        return m_backend;
    }
    QVariant deviceModel() {
        return m_deviceModel;
    }

Q_SIGNALS:
    void deviceModelChanged();

private:
    InputBackend* m_backend;
    QVariant m_deviceModel;
    QDBusInterface* m_deviceManager;
};

#endif
