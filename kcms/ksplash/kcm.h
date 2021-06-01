/*
   Copyright (c) 2014 Marco Martin <mart@kde.org>
   Copyright (c) 2014 Vishesh Handa <me@vhanda.in>
   Copyright (c) 2019 Cyril Rossi <cyril.rossi@enioka.com>

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License version 2 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, write to
   the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _KCM_SEARCH_H
#define _KCM_SEARCH_H

#include <KPackage/Package>
#include <KQuickAddons/ManagedConfigModule>

class QStandardItemModel;
class SplashScreenSettings;
class SplashScreenData;

class KCMSplashScreen : public KQuickAddons::ManagedConfigModule
{
    Q_OBJECT
    Q_PROPERTY(SplashScreenSettings *splashScreenSettings READ splashScreenSettings CONSTANT)
    Q_PROPERTY(QStandardItemModel *splashModel READ splashModel CONSTANT)
    Q_PROPERTY(bool testing READ testing NOTIFY testingChanged)

public:
    enum Roles {
        PluginNameRole = Qt::UserRole +1,
        ScreenshotRole,
        DescriptionRole
    };

    KCMSplashScreen(QObject* parent, const QVariantList& args);

    SplashScreenSettings *splashScreenSettings() const;
    QStandardItemModel *splashModel() const;
    bool testing() const;

    Q_INVOKABLE int pluginIndex(const QString &pluginName) const;

public Q_SLOTS:
    void ghnsEntriesChanged(const QQmlListReference &changedEntries);
    void save() override;
    void test(const QString &plugin);

Q_SIGNALS:
    void testingChanged();
    void testingFailed();

private:
    void loadModel();
    QList<KPackage::Package> availablePackages(const QString &component);

    SplashScreenData *m_data;
    QStandardItemModel *m_model;

    QProcess *m_testProcess = nullptr;
};

#endif
