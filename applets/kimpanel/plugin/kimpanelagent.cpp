/***************************************************************************
 *   Copyright (C) 2009 by Wang Hoi <zealot.hoi@gmail.com>                 *
 *   Copyright (C) 2011 by CSSlayer <wengxt@gmail.com>                     *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

#include "kimpanelagent.h"
#include "impaneladaptor.h"

// Qt
#include <QByteArray>
#include <QList>
#include <QMap>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QDBusServiceWatcher>

int PanelAgent::m_connectionIndex = 0;

PanelAgent::PanelAgent(QObject *parent)
    : QObject(parent)
    ,m_adaptor(new ImpanelAdaptor(this))
    ,m_adaptor2(new Impanel2Adaptor(this))
    ,m_watcher(new QDBusServiceWatcher(this))
    ,m_connection(QDBusConnection::connectToBus(QDBusConnection::SessionBus, QStringLiteral("kimpanel_bus_%0").arg(++m_connectionIndex)))
{
    m_watcher->setConnection(QDBusConnection::sessionBus());
    m_watcher->setWatchMode(QDBusServiceWatcher::WatchForUnregistration);
    m_connection.registerObject(QStringLiteral("/org/kde/impanel"), this);
    m_connection.registerService(QStringLiteral("org.kde.impanel"));

    // directly connect to corresponding signal
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("Enable"), this, SIGNAL(enable(bool)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("ShowPreedit"), this, SIGNAL(showPreedit(bool)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("ShowAux"), this, SIGNAL(showAux(bool)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("ShowLookupTable"), this, SIGNAL(showLookupTable(bool)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("UpdateLookupTableCursor"), this, SIGNAL(updateLookupTableCursor(int)));

    // do some serialization
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("UpdateLookupTable"), this, SLOT(UpdateLookupTable(QStringList,
                                                                                           QStringList, QStringList, bool, bool)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("UpdatePreeditCaret"), this, SIGNAL(updatePreeditCaret(int)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("UpdatePreeditText"), this, SLOT(UpdatePreeditText(QString, QString)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("UpdateAux"), this, SLOT(UpdateAux(QString, QString)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("UpdateSpotLocation"), this, SIGNAL(updateSpotLocation(int, int)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("UpdateScreen"), this, SLOT(UpdateScreen(int)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("UpdateProperty"), this, SLOT(UpdateProperty(QString)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("RegisterProperties"), this, SLOT(RegisterProperties(QStringList)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("ExecDialog"), this, SLOT(ExecDialog(QString)));
    m_connection.connect(QString(), QString(), QStringLiteral("org.kde.kimpanel.inputmethod"),
                         QStringLiteral("ExecMenu"), this, SLOT(ExecMenu(QStringList)));

    connect(m_watcher, &QDBusServiceWatcher::serviceUnregistered, this, &PanelAgent::serviceUnregistered);
}

PanelAgent::~PanelAgent()
{
    // destructor
    QDBusConnection::disconnectFromBus(m_connection.name());
}

void PanelAgent::serviceUnregistered(const QString& service)
{
    if (service == m_currentService) {
        m_watcher->setWatchedServices(QStringList());
        m_cachedProps.clear();
        m_currentService = QString();
        emit showAux(false);
        emit showPreedit(false);
        emit showLookupTable(false);
        emit registerProperties(QList<KimpanelProperty>());
    }
}

void PanelAgent::configure()
{
    emit Configure();
}

void PanelAgent::lookupTablePageDown()
{
    emit LookupTablePageDown();
}

void PanelAgent::lookupTablePageUp()
{
    emit LookupTablePageUp();
}

void PanelAgent::movePreeditCaret(int pos)
{
    emit MovePreeditCaret(pos);
}

void PanelAgent::triggerProperty(const QString& key)
{
    emit TriggerProperty(key);
}

void PanelAgent::selectCandidate(int idx)
{
    emit SelectCandidate(idx);
}


static QList<TextAttribute> String2AttrList(const QString &str)
{
    QList<TextAttribute> result;
    if (str.isEmpty()) {
        return result;
    }
    foreach(const QString & s, str.split(QLatin1Char(';'))) {
        TextAttribute attr;
        QStringList list = s.split(QLatin1Char(':'));
        if (list.size() < 4)
            continue;
        switch (list.at(0).toInt()) {
        case 0:
            attr.type = TextAttribute::None;
            break;
        case 1:
            attr.type = TextAttribute::Decorate;
            break;
        case 2:
            attr.type = TextAttribute::Foreground;
            break;
        case 3:
            attr.type = TextAttribute::Background;
            break;
        default:
            attr.type = TextAttribute::None;
        }
        attr.start = list.at(1).toInt();
        attr.length = list.at(2).toInt();
        attr.value = list.at(3).toInt();
        result << attr;
    }
    return result;
}

static KimpanelProperty String2Property(const QString &str)
{
    KimpanelProperty result;

    QStringList list = str.split(QLatin1Char(':'));

    if (list.size() < 4)
        return result;

    result.key = list.at(0);
    result.label = list.at(1);
    result.icon = list.at(2);
    result.tip = list.at(3);
    result.hint = list.size() > 4 ? list.at(4) : QString();

    return result;
}

static KimpanelLookupTable Args2LookupTable(const QStringList &labels, const QStringList &candis, const QStringList &attrs, bool has_prev, bool has_next)
{
    Q_ASSERT(labels.size() == candis.size());
    Q_ASSERT(labels.size() == attrs.size());

    KimpanelLookupTable result;

    for (int i = 0; i < labels.size(); i++) {
        KimpanelLookupTable::Entry entry;

        entry.label = labels.at(i);
        entry.text = candis.at(i);
        entry.attr = String2AttrList(attrs.at(i));

        result.entries << entry;
    }

    result.has_prev = has_prev;
    result.has_next = has_next;
    return result;
}

void PanelAgent::created()
{
    emit PanelCreated();
    emit PanelCreated2();
}

void PanelAgent::exit()
{
    emit Exit();
}

void PanelAgent::reloadConfig()
{
    emit ReloadConfig();
}

void PanelAgent::UpdateLookupTable(const QStringList &labels,
                                   const QStringList &candis,
                                   const QStringList &attrlists,
                                   bool has_prev, bool has_next)
{
    emit updateLookupTable(Args2LookupTable(labels, candis, attrlists, has_prev, has_next));
}

void PanelAgent::UpdatePreeditText(const QString &text, const QString &attr)
{
    emit updatePreeditText(text, String2AttrList(attr));
}

void PanelAgent::UpdateAux(const QString &text, const QString &attr)
{
    emit updateAux(text, String2AttrList(attr));
}

void PanelAgent::UpdateScreen(int screen_id)
{
    Q_UNUSED(screen_id);
}

void PanelAgent::UpdateProperty(const QString &prop)
{
    emit updateProperty(String2Property(prop));
}

void PanelAgent::RegisterProperties(const QStringList &props)
{
    const QDBusMessage& msg = message();
    if (msg.service() != m_currentService) {
        m_watcher->removeWatchedService(m_currentService);
        if (m_currentService.isEmpty()) {
            emit PanelRegistered();
        }
        m_currentService = msg.service();
        m_watcher->addWatchedService(m_currentService);
    }
    if (m_cachedProps != props) {
        m_cachedProps = props;
        QList<KimpanelProperty> list;
        foreach(const QString & prop, props) {
            list << String2Property(prop);
        }

        emit registerProperties(list);
    }
}

void PanelAgent::ExecDialog(const QString &prop)
{
    emit execDialog(String2Property(prop));
}

void PanelAgent::ExecMenu(const QStringList &entries)
{
    QList<KimpanelProperty> list;
    foreach(const QString & entry, entries) {
        list << String2Property(entry);
    }

    emit execMenu(list);
}

void PanelAgent::SetSpotRect(int x, int y, int w, int h)
{
    emit updateSpotRect(x, y, w, h);
}

void PanelAgent::SetLookupTable(const QStringList& labels, const QStringList& candis, const QStringList& attrlists, bool hasPrev, bool hasNext, int cursor, int layout)
{
    emit updateLookupTableFull(Args2LookupTable(labels, candis, attrlists, hasPrev, hasNext), cursor, layout);
}
