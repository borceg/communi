#include <QApplication>
#include "qmlapplicationviewer.h"

#include <QtDeclarative>
#include "messageformatter.h"
#include "messagehandler.h"
#include "commandparser.h"
#include "sessionmanager.h"
#include "sessionitem.h"

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QApplication> app(createApplication(argc, argv));
    QScopedPointer<QmlApplicationViewer> viewer(QmlApplicationViewer::create());

    qmlRegisterType<MessageFormatter>("Communi", 1, 0, "MessageFormatter");
    qmlRegisterType<MessageHandler>("Communi", 1, 0, "MessageHandler");

    CommandParser parser;
    viewer->rootContext()->setContextProperty("CommandParser", &parser);

    SessionManager manager(viewer->rootContext());
    viewer->rootContext()->setContextProperty("SessionManager", &manager);
    qmlRegisterUncreatableType<SessionItem>("Communi", 1, 0, "SessionItem", "");

    viewer->setOrientation(QmlApplicationViewer::ScreenOrientationAuto);
    viewer->setMainQmlFile(QLatin1String("qml/communi/main.qml"));
    viewer->showExpanded();

    return app->exec();
}