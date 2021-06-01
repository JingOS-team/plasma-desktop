/**
 *  Copyright 2020 Cyril Rossi <cyril.rossi@enioka.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "launchfeedbacksettings.h"

class LaunchFeedbackSettingsStore : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool busyCursorDisabled READ busyCursorDisabled WRITE setBusyCursorDisabled)
    Q_PROPERTY(bool busyCursorStatic READ busyCursorStatic WRITE setBusyCursorStatic)
    Q_PROPERTY(bool busyCursorBlinking READ busyCursorBlinking WRITE setBusyCursorBlinking)
    Q_PROPERTY(bool busyCursorBouncing READ busyCursorBouncing WRITE setBusyCursorBouncing)

public:
    LaunchFeedbackSettingsStore(LaunchFeedbackSettings *parent = nullptr)
        : QObject(parent)
        , m_settings(parent)
    {
        setBusyCursorDisabled(!m_settings->busyCursor() && !m_settings->blinking() && !m_settings->bouncing());
        setBusyCursorStatic(m_settings->busyCursor() && !m_settings->blinking() && !m_settings->bouncing());
        setBusyCursorBlinking(m_settings->busyCursor() && m_settings->blinking() && !m_settings->bouncing());
        setBusyCursorBouncing(m_settings->busyCursor() && !m_settings->blinking() && m_settings->bouncing());
    }

    void setBusyCursorDisabled(bool busyCursorDisabled)
    {
        m_busyCursorDisabled = busyCursorDisabled;
    }
    bool busyCursorDisabled() const
    {
        return m_busyCursorDisabled;
    }
    bool busyCursorDisabledDefault() const
    {
        return !m_settings->defaultBusyCursorValue() && !m_settings->defaultBlinkingValue() && !m_settings->defaultBouncingValue();
    }

    void setBusyCursorStatic(bool busyCursorStatic)
    {
        m_busyCursorStatic = busyCursorStatic;
    }
    bool busyCursorStatic() const
    {
        return m_busyCursorStatic;
    }
    bool busyCursorStaticDefault()
    {
        return m_settings->defaultBusyCursorValue() && !m_settings->defaultBlinkingValue() && !m_settings->defaultBouncingValue();
    }

    void setBusyCursorBlinking(bool busyCursorBlinking)
    {
        m_busyCursorBlinking = busyCursorBlinking;
    }
    bool busyCursorBlinking() const
    {
        return m_busyCursorBlinking;
    }
    bool busyCursorBlinkingDefault()
    {
        return m_settings->defaultBusyCursorValue() && m_settings->defaultBlinkingValue() && !m_settings->defaultBouncingValue();
    }

    void setBusyCursorBouncing(bool busyCursorBouncing)
    {
        m_busyCursorBouncing = busyCursorBouncing;
    }
    bool busyCursorBouncing() const
    {
        return m_busyCursorBouncing;
    }
    bool busyCursorBouncingcDefault()
    {
        return m_settings->defaultBusyCursorValue() && !m_settings->defaultBlinkingValue() && m_settings->defaultBouncingValue();
    }

private:
    LaunchFeedbackSettings *m_settings;
    bool m_busyCursorDisabled;
    bool m_busyCursorStatic;
    bool m_busyCursorBlinking;
    bool m_busyCursorBouncing;
};

LaunchFeedbackSettings::LaunchFeedbackSettings(QObject *parent)
    : LaunchFeedbackSettingsBase(parent)
    , m_settingsStore(new LaunchFeedbackSettingsStore(this))
{
    addItemInternal("busyCursorDisabled", m_settingsStore->busyCursorDisabledDefault(), &LaunchFeedbackSettings::busyCursorDisabledChanged);
    addItemInternal("busyCursorStatic", m_settingsStore->busyCursorStaticDefault(), &LaunchFeedbackSettings::busyCursorStaticChanged);
    addItemInternal("busyCursorBlinking", m_settingsStore->busyCursorBlinkingDefault(), &LaunchFeedbackSettings::busyCursorBlinkingChanged);
    addItemInternal("busyCursorBouncing", m_settingsStore->busyCursorBouncingcDefault(), &LaunchFeedbackSettings::busyCursorBouncingChanged);
}

void LaunchFeedbackSettings::addItemInternal(const QByteArray &propertyName, const QVariant &defaultValue, NotifySignalType notifySignal)
{
    auto item = new KPropertySkeletonItem(m_settingsStore, propertyName, defaultValue);
    addItem(item, propertyName);
    item->setNotifyFunction([this, notifySignal] { emit (this->*notifySignal)(); });
}

bool LaunchFeedbackSettings::busyCursorDisabled() const
{
    return findItem("busyCursorDisabled")->property().toBool();
}

bool LaunchFeedbackSettings::busyCursorStatic() const
{
    return findItem("busyCursorStatic")->property().toBool();
}

bool LaunchFeedbackSettings::busyCursorBlinking() const
{
    return findItem("busyCursorBlinking")->property().toBool();
}

bool LaunchFeedbackSettings::busyCursorBouncing() const
{
    return findItem("busyCursorBouncing")->property().toBool();
}

void LaunchFeedbackSettings::setSelectedBusyCursor(QString selectedBusyCursor)
{
    setBusyCursorDisabled(QStringLiteral("busyCursorDisabled") == selectedBusyCursor);
    setBusyCursorStatic(QStringLiteral("busyCursorStatic") == selectedBusyCursor);
    setBusyCursorBlinking(QStringLiteral("busyCursorBlinking") == selectedBusyCursor);
    setBusyCursorBouncing(QStringLiteral("busyCursorBouncing") == selectedBusyCursor);

    setBusyCursor(!busyCursorDisabled());
    setBouncing(busyCursorBouncing());
    setBlinking(busyCursorBlinking());
}

void LaunchFeedbackSettings::setBusyCursorDisabled(bool busyCursorDisabled)
{
    findItem("busyCursorDisabled")->setProperty(busyCursorDisabled);
}

void LaunchFeedbackSettings::setBusyCursorStatic(bool busyCursorStatic)
{
    findItem("busyCursorStatic")->setProperty(busyCursorStatic);
}

void LaunchFeedbackSettings::setBusyCursorBlinking(bool busyCursorBlinking)
{
    findItem("busyCursorBlinking")->setProperty(busyCursorBlinking);
}

void LaunchFeedbackSettings::setBusyCursorBouncing(bool busyCursorBouncing)
{
    findItem("busyCursorBouncing")->setProperty(busyCursorBouncing);
}

#include "launchfeedbacksettings.moc"
