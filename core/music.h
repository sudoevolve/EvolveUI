// core/music.h
#ifndef CORE_MUSIC_H
#define CORE_MUSIC_H

// 仅声明：实现位于 core/music.cpp
#include <QObject>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <QMediaMetaData>

class QMediaPlayer;
class QAudioOutput;
class QFileInfo;

// 合并：音频元数据读取
class AudioMetadata : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString artist READ artist NOTIFY artistChanged)
    Q_PROPERTY(QString album READ album NOTIFY albumChanged)
    Q_PROPERTY(QUrl coverImageUrl READ coverImageUrl NOTIFY coverImageUrlChanged)
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(int duration READ duration NOTIFY durationChanged)

public:
    explicit AudioMetadata(QObject *parent = nullptr);
    ~AudioMetadata() override;

    QString title() const { return m_title; }
    QString artist() const { return m_artist; }
    QString album() const { return m_album; }
    QUrl coverImageUrl() const { return m_coverImageUrl; }
    QString source() const { return m_source; }
    int duration() const { return m_duration; }

    Q_INVOKABLE void setSource(const QString &source);
    Q_INVOKABLE void loadMetadata();

signals:
    void titleChanged();
    void artistChanged();
    void albumChanged();
    void coverImageUrlChanged();
    void sourceChanged();
    void durationChanged();
    void metadataLoaded();

private slots:
    void onMetaDataChanged();
    void onDurationChanged(qint64 duration);

private:
    void extractCoverArt();
    QString extractFileNameTitle(const QString &filePath);

    QMediaPlayer *m_mediaPlayer;
    QAudioOutput *m_audioOutput;
    QString m_title;
    QString m_artist;
    QString m_album;
    QUrl m_coverImageUrl;
    QString m_source;
    int m_duration;
    QString m_tempCoverPath;
};

// 合并：音乐库扫描
class MusicLibrary : public QObject
{
    Q_OBJECT
public:
    explicit MusicLibrary(QObject *parent = nullptr);

    Q_INVOKABLE QStringList scanMusicFiles(const QString &rootPath, bool recursive = true);
    Q_INVOKABLE QString defaultProjectRoot();
    Q_INVOKABLE QStringList scanDefaultProjectMusic(bool recursive = true);

private:
    QString findProjectRootFromAppDir() const;
};

#endif // CORE_MUSIC_H