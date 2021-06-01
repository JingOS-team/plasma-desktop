/*
 *   Copyright (C) 2015 - 2016 by Ivan Cukic <ivan.cukic@kde.org>
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

#include "dialog.h"

#include <QAction>
#include <QDialogButtonBox>
#include <QKeySequence>
#include <QPushButton>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickView>
#include <QQuickWidget>
#include <QString>
#include <QTabWidget>
#include <QTimer>
#include <QVBoxLayout>
#include <QGuiApplication>

#include <KLocalizedString>
#include <KGlobalAccel>
#include <KMessageWidget>

#include "../kactivities-kcm-features.h"

#include "kactivities/info.h"
#include "kactivities/controller.h"
#include "features_interface.h"

#include "common/dbus/common.h"
#include "utils/continue_with.h"
#include "utils/d_ptr_implementation.h"

class Dialog::Private {
public:
    Private(Dialog *parent)
        : q(parent)
        , activityName(QStringLiteral("activityName"))
        , activityDescription(QStringLiteral("activityDescription"))
        , activityIcon(QStringLiteral("activityIcon"))
        , activityWallpaper(QStringLiteral("activityWallpaper"))
        , activityIsPrivate(true)
        , activityShortcut(QStringLiteral("activityShortcut"))
        , features(new KAMD_DBUS_CLASS_INTERFACE(Features, Features, q))
    {
    }

    Dialog *const q;
    QVBoxLayout *layout;
    QTabWidget  *tabs;

    QQuickWidget *tabGeneral;
    KMessageWidget *message;
    QDialogButtonBox *buttons;
    QString defaultOKText;

    QQuickWidget *createTab(const QString &title, const QString &file)
    {
        auto view = new QQuickWidget();

        view->setResizeMode(QQuickWidget::SizeRootObjectToView);

        view->setClearColor(QGuiApplication::palette().window().color());

        view->rootContext()->setContextProperty(QStringLiteral("dialog"), q);

        const QString sourceFile = QStringLiteral(KAMD_KCM_DATADIR) +"qml/activityDialog/" + file;

        if (QFile::exists(sourceFile)) {
            view->setSource(QUrl::fromLocalFile(sourceFile));
            tabs->addTab(view, title);
        } else {
            message->setText(i18n("Error loading the QML files. Check your installation.\nMissing %1",
                                  sourceFile));
            message->setVisible(true);
        }

        return view;
    }

    void setFocus(QQuickWidget *widget)
    {
        // TODO: does not work...
        widget->setFocus();
        auto root = widget->rootObject();

        if (!root) return;

        QMetaObject::invokeMethod(widget->rootObject(), "setFocus",
                                  Qt::DirectConnection);
    }

    QString activityId;

    QString activityName;
    QString activityDescription;
    QString activityIcon;
    QString activityWallpaper;
    bool activityIsPrivate;
    QString activityShortcut;

    KActivities::Controller activities;
    org::kde::ActivityManager::Features *features;
};

void Dialog::showDialog(const QString &id)
{
    static Dialog *dialog = nullptr;

    // If we use the regular singleton here (static value instead of static ptr),
    // we will crash on exit because of Qt...
    if (!dialog) {
        dialog = new Dialog();
    }

    dialog->init(id);
    dialog->show();
}

Dialog::Dialog(QObject *parent)
    : QDialog()
    , d(this)
{
    resize(550, 400);

    d->layout = new QVBoxLayout(this);

    // Message widget for showing errors
    d->message = new KMessageWidget(this);
    d->message->setMessageType(KMessageWidget::Error);
    d->message->setVisible(false);
    d->message->setWordWrap(true);
    d->layout->addWidget(d->message);

    // Tabs
    d->tabs = new QTabWidget(this);
    d->layout->addWidget(d->tabs);
    d->tabGeneral = d->createTab(i18n("General"), QStringLiteral("GeneralTab.qml"));

    // Buttons
    d->buttons = new QDialogButtonBox(
        QDialogButtonBox::Ok | QDialogButtonBox::Cancel, this);
    d->layout->QLayout::addWidget(d->buttons);

    connect(d->buttons->button(QDialogButtonBox::Ok), &QAbstractButton::clicked,
            this, &Dialog::save);
    connect(d->buttons, &QDialogButtonBox::rejected,
            this, &Dialog::close);

    d->defaultOKText = d->buttons->button(QDialogButtonBox::Ok)->text();
}

void Dialog::init(const QString &activityId)
{
    setWindowTitle(activityId.isEmpty() ? i18nc("@title:window", "Create a New Activity")
                                        : i18nc("@title:window", "Activity Settings"));

    d->buttons->button(QDialogButtonBox::Ok)->setText(
                    activityId.isEmpty() ? i18nc("@action:button", "Create")
                                         : d->defaultOKText);

    d->tabs->setCurrentIndex(0);

    setActivityId(activityId);
    setActivityName(QString());
    setActivityDescription(QString());
    setActivityIcon(QStringLiteral("activities"));
    setActivityIsPrivate(false);

    setActivityShortcut(QKeySequence());

    if (!activityId.isEmpty()) {
        KActivities::Info activityInfo(activityId);

        setActivityName(activityInfo.name());
        setActivityDescription(activityInfo.description());
        setActivityIcon(activityInfo.icon());

        // finding the key shortcut
        const auto shortcuts = KGlobalAccel::self()->globalShortcut(
            QStringLiteral("ActivityManager"), QStringLiteral("switch-to-activity-") + activityId);
        setActivityShortcut(shortcuts.isEmpty() ? QKeySequence() : shortcuts.first());

        // is private?
        auto result = d->features->GetValue(
            QStringLiteral("org.kde.ActivityManager.Resources.Scoring/isOTR/") + activityId);

        auto watcher = new QDBusPendingCallWatcher(result, this);

        QObject::connect(watcher, &QDBusPendingCallWatcher::finished, this,
                         [&] (QDBusPendingCallWatcher *watcher) mutable {
                             QDBusPendingReply<QDBusVariant> reply = *watcher;
                             setActivityIsPrivate(reply.value().variant().toBool());
                             watcher->deleteLater();
                         });
    }
}

Dialog::~Dialog()
{
}

void Dialog::showEvent(QShowEvent *event)
{
    Q_UNUSED(event);
    // Setting the focus
    d->setFocus(d->tabGeneral);
}

#define IMPLEMENT_PROPERTY(Scope, Type, PType, PropName)                       \
    Type Dialog::activity##PropName() const                                    \
    {                                                                          \
        auto root = d->tab##Scope->rootObject();                               \
                                                                               \
        if (!root) {                                                           \
            qDebug() << "Root does not exist";                                 \
            return Type();                                                     \
        }                                                                      \
                                                                               \
        return root->property("activity" #PropName).value<Type>();             \
    }                                                                          \
                                                                               \
    void Dialog::setActivity##PropName(PType value)                            \
    {                                                                          \
        auto root = d->tab##Scope->rootObject();                               \
                                                                               \
        if (!root) {                                                           \
            qDebug() << "Root does not exist";                                 \
            return;                                                            \
        }                                                                      \
                                                                               \
        root->setProperty("activity" #PropName, value);                        \
    }

IMPLEMENT_PROPERTY(General, QString,      const QString &,      Id)
IMPLEMENT_PROPERTY(General, QString,      const QString &,      Name)
IMPLEMENT_PROPERTY(General, QString,      const QString &,      Description)
IMPLEMENT_PROPERTY(General, QString,      const QString &,      Icon)
IMPLEMENT_PROPERTY(General, QString,      const QString &,      Wallpaper)
IMPLEMENT_PROPERTY(General, QKeySequence, const QKeySequence &, Shortcut)
IMPLEMENT_PROPERTY(General, bool,         bool,                 IsPrivate)
#undef IMPLEMENT_PROPERTY

void Dialog::save()
{
    if (activityId().isEmpty()) {
        create();

    } else {
        saveChanges(activityId());

    }
}

void Dialog::create()
{
    using namespace kamd::utils;
    continue_with(
        d->activities.addActivity(activityName()),
        [this](const optional_view<QString> &activityId) {
            if (activityId.is_initialized()) {
                saveChanges(activityId.get());
            }
        });
}

void Dialog::saveChanges(const QString &activityId)
{
    d->activities.setActivityName(activityId, activityName());
    d->activities.setActivityDescription(activityId, activityDescription());
    d->activities.setActivityIcon(activityId, activityIcon());

    // setting the key shortcut
    QAction action(nullptr);
    action.setProperty("isConfigurationAction", true);
    action.setProperty("componentName", QStringLiteral("ActivityManager"));
    action.setObjectName(QStringLiteral("switch-to-activity-") + activityId);
    KGlobalAccel::self()->setShortcut(&action, {activityShortcut()}, KGlobalAccel::NoAutoloading);

    // is private?
    d->features->SetValue(QStringLiteral("org.kde.ActivityManager.Resources.Scoring/isOTR/")
                              + activityId,
                          QDBusVariant(activityIsPrivate()));

    close();
}
