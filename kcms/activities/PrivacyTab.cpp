/*
 *   Copyright (C) 2012 - 2016 by Ivan Cukic <ivan.cukic@kde.org>
 *
 *   This program is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU General Public License as
 *   published by the Free Software Foundation; either version 2 of
 *   the License or (at your option) version 3 or any later version
 *   accepted by the membership of KDE e.V. (or its successor approved
 *   by the membership of KDE e.V.), which shall act as a proxy
 *   defined in Section 14 of version 3 of the license.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "PrivacyTab.h"
#include "kactivitymanagerd_settings.h"
#include "kactivitymanagerd_plugins_settings.h"

#include <QMenu>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QDBusPendingCall>

#include <QQuickWidget>

#include <KConfigGroup>
#include <KSharedConfig>
#include <KMessageWidget>

#include "ui_PrivacyTabBase.h"
#include "BlacklistedApplicationsModel.h"

#include <utils/d_ptr_implementation.h>

#include "kactivities-kcm-features.h"

#include "common/dbus/common.h"

class PrivacyTab::Private : public Ui::PrivacyTabBase {
public:
    KActivityManagerdSettings *mainConfig;
    KActivityManagerdPluginsSettings *pluginConfig;

    BlacklistedApplicationsModel *blacklistedApplicationsModel;

    Private(QObject *parent)
        : mainConfig(new KActivityManagerdSettings(parent))
        , pluginConfig(new KActivityManagerdPluginsSettings(parent))
    {
    }
};

KCoreConfigSkeleton *PrivacyTab::pluginConfig()
{
    return d->pluginConfig;
}

PrivacyTab::PrivacyTab(QWidget *parent)
    : QWidget(parent)
    , d(this)
{
    d->setupUi(this);

    // Keep history initialization

    d->kcfg_keepHistoryFor->setRange(0, INT_MAX);
    d->kcfg_keepHistoryFor->setSpecialValueText(i18nc("unlimited number of months", "Forever"));

    connect(d->kcfg_keepHistoryFor, SIGNAL(valueChanged(int)),
            this, SLOT(spinKeepHistoryValueChanged(int)));
    spinKeepHistoryValueChanged(0);

    // Clear recent history button

    auto menu = new QMenu(this);

    connect(menu->addAction(i18n("Forget the last hour")), &QAction::triggered,
            this, &PrivacyTab::forgetLastHour);
    connect(menu->addAction(i18n("Forget the last two hours")), &QAction::triggered,
            this, &PrivacyTab::forgetTwoHours);
    connect(menu->addAction(i18n("Forget a day")), &QAction::triggered,
            this, &PrivacyTab::forgetDay);
    connect(menu->addAction(i18n("Forget everything")), &QAction::triggered,
            this, &PrivacyTab::forgetAll);

    d->buttonClearRecentHistory->setMenu(menu);

    // Blacklist applications

    d->blacklistedApplicationsModel = new BlacklistedApplicationsModel(this);
    connect(d->blacklistedApplicationsModel, &BlacklistedApplicationsModel::changed, this, &PrivacyTab::blackListModelChanged);
    connect(d->blacklistedApplicationsModel, &BlacklistedApplicationsModel::defaulted, this, &PrivacyTab::blackListModelDefaulted);

    d->viewBlacklistedApplications->setClearColor(QGuiApplication::palette().window().color());
    d->viewBlacklistedApplications->rootContext()->setContextProperty(
        QStringLiteral("applicationModel"), d->blacklistedApplicationsModel);
    d->viewBlacklistedApplications->setSource(QUrl::fromLocalFile(KAMD_KCM_DATADIR  + QStringLiteral("/qml/privacyTab/BlacklistApplicationView.qml")));

    // React to changes

    connect(d->radioRememberSpecificApplications, &QAbstractButton::toggled,
            d->blacklistedApplicationsModel, &BlacklistedApplicationsModel::setEnabled);
    d->blacklistedApplicationsModel->setEnabled(false);

    d->messageWidget->setVisible(false);
}

PrivacyTab::~PrivacyTab()
{
}

void PrivacyTab::defaults()
{
    d->blacklistedApplicationsModel->defaults();
}

void PrivacyTab::load()
{
    d->blacklistedApplicationsModel->load();
}

void PrivacyTab::save()
{
    d->blacklistedApplicationsModel->save();
    
    const auto whatToRemember =
        d->radioRememberSpecificApplications->isChecked() ? SpecificApplications :
        d->radioDontRememberApplications->isChecked()     ? NoApplications :
        /* otherwise */                                     AllApplications;
    
    d->mainConfig->setResourceScoringEnabled(whatToRemember != NoApplications);
    d->mainConfig->save();
}

void PrivacyTab::forget(int count, const QString &what)
{
    KAMD_DBUS_DECL_INTERFACE(rankingsservice, Resources/Scoring,
                             ResourcesScoring);

    rankingsservice.asyncCall(QStringLiteral("DeleteRecentStats"), QString(), count, what);

    d->messageWidget->animatedShow();
}

void PrivacyTab::forgetLastHour()
{
    forget(1, QStringLiteral("h"));
}

void PrivacyTab::forgetTwoHours()
{
    forget(2, QStringLiteral("h"));
}

void PrivacyTab::forgetDay()
{
    forget(1, QStringLiteral("d"));
}

void PrivacyTab::forgetAll()
{
    forget(0, QStringLiteral("everything"));
}

void PrivacyTab::spinKeepHistoryValueChanged(int value)
{
    static auto months = ki18ncp("unit of time. months to keep the history",
                                 " month", " months");

    if (value) {
        d->kcfg_keepHistoryFor->setPrefix(
            i18nc("for in 'keep history for 5 months'", "For "));
        d->kcfg_keepHistoryFor->setSuffix(months.subs(value).toString());
    }
}
