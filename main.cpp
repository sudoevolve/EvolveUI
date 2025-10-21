#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include "core/music.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

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
