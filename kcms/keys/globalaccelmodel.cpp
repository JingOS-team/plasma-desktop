/*
 * Copyright (C) 2020  David Redondo <david@david-redondo.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "globalaccelmodel.h"

#include <QIcon>
#include <QDBusPendingCallWatcher>

#include <KConfigGroup>
#include <KGlobalAccel>
#include <kglobalaccel_interface.h>
#include <kglobalaccel_component_interface.h>
#include <KGlobalShortcutInfo>
#include <KLocalizedString>
#include <KService>
#include <KServiceTypeTrader>

#include "kcmkeys_debug.h"

static QStringList buildActionId(const QString &componentUnique, const QString &componentFriendly,
                              const QString &actionUnique, const QString &actionFriendly)
{
    QStringList actionId{"", "", "", ""};
    actionId[KGlobalAccel::ComponentUnique] = componentUnique;
    actionId[KGlobalAccel::ComponentFriendly] = componentFriendly;
    actionId[KGlobalAccel::ActionUnique] = actionUnique;
    actionId[KGlobalAccel::ActionFriendly] = actionFriendly;
    return actionId;
}


GlobalAccelModel::GlobalAccelModel(KGlobalAccelInterface *interface, QObject *parent)
 : BaseModel(parent)
 , m_globalAccelInterface{interface}
{
}

QVariant GlobalAccelModel::data(const QModelIndex &index, int role) const
{
    if (role == SupportsMultipleKeysRole) {
        return false;
    }
    return BaseModel::data(index, role);
}

void GlobalAccelModel::load()
{
    if (!m_globalAccelInterface->isValid()) {
        return;
    }
    beginResetModel();
    m_components.clear();
    auto componentsWatcher = new  QDBusPendingCallWatcher( m_globalAccelInterface->allComponents());
    connect(componentsWatcher, &QDBusPendingCallWatcher::finished, this, [this] (QDBusPendingCallWatcher *componentsWatcher) {
        QDBusPendingReply<QList<QDBusObjectPath>> componentsReply = *componentsWatcher;
        componentsWatcher->deleteLater();
        if (componentsReply.isError()) {
            genericErrorOccured(QStringLiteral("Error while calling allComponents()"), componentsReply.error());
            endResetModel();
            return;
        }
        const QList<QDBusObjectPath> componentPaths = componentsReply.value();
        int *pendingCalls = new int;
        *pendingCalls = componentPaths.size();
        for (const auto &componentPath : componentPaths) {
            const QString path = componentPath.path();
            KGlobalAccelComponentInterface component(m_globalAccelInterface->service(), path, m_globalAccelInterface->connection());
            auto watcher = new QDBusPendingCallWatcher(component.allShortcutInfos());
            connect(watcher, &QDBusPendingCallWatcher::finished, this, [path, pendingCalls, this] (QDBusPendingCallWatcher *watcher){
                QDBusPendingReply<QList<KGlobalShortcutInfo>> reply = *watcher;
                if (reply.isError()) {
                    genericErrorOccured(QStringLiteral("Error while calling allShortCutInfos of") + path, reply.error());
                } else {
                    m_components.push_back(loadComponent(reply.value()));
                }
                watcher->deleteLater();
                if (--*pendingCalls == 0) {
                    QCollator collator;
                    collator.setCaseSensitivity(Qt::CaseInsensitive);
                    collator.setNumericMode(true);
                    std::sort(m_components.begin(), m_components.end(), [&](const Component &c1, const Component &c2){
                        return c1.type != c2.type ? c1.type < c2.type : collator.compare(c1.displayName, c2.displayName) < 0;
                    });
                    endResetModel();
                    delete pendingCalls;
                }
            });
        }
    });
}

Component GlobalAccelModel::loadComponent(const QList<KGlobalShortcutInfo> &info)
{
    const QString &componentUnique = info[0].componentUniqueName();
    const QString &componentFriendly = info[0].componentFriendlyName();
    KService::Ptr service = KService::serviceByStorageId(componentUnique);
    if (!service) {
        // Do we have an application with that name?
        const KService::List apps = KServiceTypeTrader::self()->query(QStringLiteral("Application"),
                QStringLiteral("Name == '%1' or Name == '%2'").arg(componentUnique, componentFriendly));
        if(!apps.isEmpty()) {
            service = apps[0];
        }
    }
    const QString type = service && service->isApplication() ? i18n("Applications") : i18n("System Services");
    QString icon;

    static const QHash<QString, QString> hardCodedIcons = {
        {"ActivityManager", "preferences-desktop-activities"},
        {"KDE Keyboard Layout Switcher", "input-keyboard"},
        {"krunner.desktop", "krunner"},
        {"org_kde_powerdevil", "preferences-system-power-management"}
    };

    if(service && !service->icon().isEmpty()) {
        icon = service->icon();
    } else if (hardCodedIcons.contains(componentUnique)) {
        icon = hardCodedIcons[componentUnique];
    } else {
        icon = componentUnique;
    }

    Component c{componentUnique, componentFriendly, type, icon, {}, false, false};
    for (const auto &actionInfo : info) {
        const QString &actionUnique = actionInfo.uniqueName();
        const QString &actionFriendly = actionInfo.friendlyName();
        Action action;
        action.id = actionUnique;
        action.displayName = actionFriendly;
        const QList<QKeySequence> defaultShortcuts = actionInfo.defaultKeys();
        for (const auto  &keySequence : defaultShortcuts) {
            if (!keySequence.isEmpty()) {
                action.defaultShortcuts.insert(keySequence);
            }
        }
        const QList<QKeySequence> activeShortcuts = actionInfo.keys();
        for (const QKeySequence &keySequence : activeShortcuts) {
            if (!keySequence.isEmpty()) {
                action.activeShortcuts.insert(keySequence);
            }
        }
        action.initialShortcuts = action.activeShortcuts;
        c.actions.push_back(action);
    }
    QCollator collator;
    collator.setCaseSensitivity(Qt::CaseInsensitive);
    collator.setNumericMode(true);
    std::sort(c.actions.begin(), c.actions.end(), [&] (const Action &s1, const Action &s2) {
        return collator.compare(s1.displayName, s2.displayName) < 0;
    });
    return c;
}

void GlobalAccelModel::save()
{
    for (auto it = m_components.rbegin(); it != m_components.rend(); ++it) {
        if (it->pendingDeletion) {
            removeComponent(*it);
            continue;
        }
        for (auto& action : it->actions) {
            if (action.initialShortcuts != action.activeShortcuts) {
                const QStringList actionId = buildActionId(it->id, it->displayName,
                        action.id, action.displayName);
                //operator int of QKeySequence
                QList<int> keys(action.activeShortcuts.cbegin(), action.activeShortcuts.cend());
                qCDebug(KCMKEYS) << "Saving" << actionId << action.activeShortcuts << keys;
                auto reply = m_globalAccelInterface->setForeignShortcut(actionId, keys);
                reply.waitForFinished();
                if (!reply.isValid()) {
                    qCCritical(KCMKEYS) << "Error while saving";
                    if (reply.error().isValid()) {
                        qCCritical(KCMKEYS) << reply.error().name() << reply.error().message();
                    }
                    emit errorOccured(i18nc("%1 is the name of the component, %2 is the action for which saving failed",
                        "Error while saving shortcut %1: %2", it->displayName, it->displayName));
                } else {
                    action.initialShortcuts = action.activeShortcuts;
                }
            }
        }
    }
}

void GlobalAccelModel::exportToConfig(const KConfigBase &config)
{
    for (const auto& component : m_components) {
        if (component.checked) {
            KConfigGroup mainGroup(&config, component.id);
            KConfigGroup group(&mainGroup, "Global Shortcuts");
            for (const auto& action : component.actions) {
                const QList<QKeySequence> shortcutsList(action.activeShortcuts.cbegin(), action.activeShortcuts.cend());
                group.writeEntry(action.id, QKeySequence::listToString(shortcutsList));
            }
        }
    }
}

void GlobalAccelModel::importConfig(const KConfigBase &config)
{
    for (const auto componentGroupName : config.groupList()) {
        auto component = std::find_if(m_components.begin(), m_components.end(), [&] (const Component &c) {
            return c.id == componentGroupName;
        });
        if (component == m_components.end()) {
            qCWarning(KCMKEYS) << "Ignoring unknown component" << componentGroupName;
            continue;
        }
        KConfigGroup componentGroup(&config, componentGroupName);
        if (!componentGroup.hasGroup("Global Shortcuts")) {
            qCWarning(KCMKEYS) << "Group" << componentGroupName << "has no shortcuts group";
            continue;
        }
        KConfigGroup shortcutsGroup(&componentGroup, "Global Shortcuts");
        for (const auto& key : shortcutsGroup.keyList()) {
            auto action = std::find_if(component->actions.begin(), component->actions.end(), [&] (const Action &a) {
                return a.id == key;
            });
            if (action == component->actions.end()) {
                qCWarning(KCMKEYS) << "Ignoring unknown action" << key;
                continue;
            }
            const auto shortcuts = QKeySequence::listFromString(shortcutsGroup.readEntry(key));
            const QSet<QKeySequence> shortcutsSet(shortcuts.cbegin(), shortcuts.cend());
            if (shortcutsSet != action->activeShortcuts) {
                action->activeShortcuts = shortcutsSet;
                const QModelIndex i = index(action - component->actions.begin(), 0, index(component-m_components.begin(), 0));
                Q_EMIT dataChanged(i, i, {CustomShortcutsRole, ActiveShortcutsRole});
            }
        }
    }
}

void GlobalAccelModel::addApplication(const QString &desktopFileName, const QString &displayName)
{
    // Register a dummy action to trigger kglobalaccel to parse the desktop file
    QStringList actionId = buildActionId(desktopFileName, displayName, QString(), QString());
    m_globalAccelInterface->doRegister(actionId);
    m_globalAccelInterface->unRegister(actionId);
    QCollator collator;
    collator.setCaseSensitivity(Qt::CaseInsensitive);
    collator.setNumericMode(true);
    auto pos = std::lower_bound(m_components.begin(), m_components.end(), displayName, [&] (const Component &c, const QString &name) {
        return c.type != i18n("System Services") &&  collator.compare(c.displayName, name) < 0;
    });
    auto watcher = new QDBusPendingCallWatcher(m_globalAccelInterface->getComponent(desktopFileName));
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [=] {
        QDBusPendingReply<QDBusObjectPath> reply = *watcher;
        watcher->deleteLater();
        if (!reply.isValid()) {
            genericErrorOccured(QStringLiteral("Error while calling objectPath of added application") + desktopFileName, reply.error());
            return;
        }
        KGlobalAccelComponentInterface component(m_globalAccelInterface->service(), reply.value().path(), m_globalAccelInterface->connection());
        auto infoWatcher = new QDBusPendingCallWatcher(component.allShortcutInfos());
        connect(infoWatcher, &QDBusPendingCallWatcher::finished, this, [=] {
            QDBusPendingReply<QList<KGlobalShortcutInfo>> infoReply = *infoWatcher;
            infoWatcher->deleteLater();
            if (!infoReply.isValid()) {
                genericErrorOccured(QStringLiteral("Error while calling allShortCutInfos on new component") + desktopFileName, infoReply.error());
                return;
            }
            qCDebug(KCMKEYS) << "inserting at " << pos - m_components.begin();
            emit beginInsertRows(QModelIndex(), pos - m_components.begin(),  pos - m_components.begin());
            auto c = loadComponent(infoReply.value());
            m_components.insert(pos, c);
            emit endInsertRows();
        });
    });
}

void GlobalAccelModel::removeComponent(const Component &component)
{
    const QString &uniqueName = component.id;
    auto componentReply = m_globalAccelInterface->getComponent(uniqueName);
    componentReply.waitForFinished();
    if (!componentReply.isValid()) {
        genericErrorOccured(QStringLiteral("Error while calling objectPath of component") + uniqueName, componentReply.error());
        return;
    }
    KGlobalAccelComponentInterface componentInterface(m_globalAccelInterface->service(), componentReply.value().path(), m_globalAccelInterface->connection());
    qCDebug(KCMKEYS) << "Cleaning up component at" << componentReply.value();
    auto cleanUpReply = componentInterface.cleanUp();
    cleanUpReply.waitForFinished();
    if (!cleanUpReply.isValid()) {
        genericErrorOccured(QStringLiteral("Error while calling cleanUp of component") + uniqueName, cleanUpReply.error());
        return;
    }
    auto it =  std::find_if(m_components.begin(), m_components.end(), [&](const Component &c) {
        return c.id == uniqueName;
    });
    const int row = it - m_components.begin();
    beginRemoveRows(QModelIndex(), row, row);
    m_components.remove(row);
    endRemoveRows();
}

void GlobalAccelModel::genericErrorOccured(const QString &description, const QDBusError &error)
{
    qCCritical(KCMKEYS) << description;
    if (error.isValid()) {
        qCCritical(KCMKEYS) << error.name() << error.message();
    }
    emit this->errorOccured(i18n("Error while communicating with the global shortcuts service"));
}
