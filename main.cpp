#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <QIcon>
#include "core/music.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 设置应用程序图标
    app.setWindowIcon(QIcon(":/new/prefix1/fonts/icon.ico"));

    // 注册C++类型到QML
    qmlRegisterType<AudioMetadata>("AudioMetadata", 1, 0, "AudioMetadata");
    qmlRegisterType<MusicLibrary>("MusicLibrary", 1, 0, "MusicLibrary");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("EvolveUI", "Main");

    return app.exec();
}
