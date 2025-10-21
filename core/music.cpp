// 实现文件：AudioMetadata 与 MusicLibrary 的实现
#include "core/music.h"

#include <QMediaPlayer>
#include <QAudioOutput>
#include <QCoreApplication>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDirIterator>
#include <QStandardPaths>
#include <QImage>
#include <QPixmap>

// ---------------------- AudioMetadata ----------------------
AudioMetadata::AudioMetadata(QObject *parent)
    : QObject(parent)
    , m_mediaPlayer(new QMediaPlayer(this))
    , m_audioOutput(new QAudioOutput(this))
    , m_duration(0)
{
    m_mediaPlayer->setAudioOutput(m_audioOutput);
    connect(m_mediaPlayer, &QMediaPlayer::metaDataChanged,
            this, &AudioMetadata::onMetaDataChanged);
    connect(m_mediaPlayer, &QMediaPlayer::durationChanged,
            this, &AudioMetadata::onDurationChanged);
}

AudioMetadata::~AudioMetadata()
{
    if (!m_tempCoverPath.isEmpty()) {
        QFile::remove(m_tempCoverPath);
    }
}

void AudioMetadata::setSource(const QString &source)
{
    if (m_source != source) {
        m_source = source;
        emit sourceChanged();

        m_title.clear();
        m_artist.clear();
        m_album.clear();
        m_coverImageUrl.clear();
        m_duration = 0;

        if (!m_tempCoverPath.isEmpty()) {
            QFile::remove(m_tempCoverPath);
            m_tempCoverPath.clear();
        }

        loadMetadata();
    }
}

void AudioMetadata::loadMetadata()
{
    if (m_source.isEmpty()) return;

    // 设置媒体源
    if (m_source.startsWith("qrc:/")) {
        m_mediaPlayer->setSource(QUrl(m_source));
    } else {
        m_mediaPlayer->setSource(QUrl::fromLocalFile(m_source));
    }
}

void AudioMetadata::onMetaDataChanged()
{
    const QMediaMetaData metaData = m_mediaPlayer->metaData();

    // 标题
    if (metaData.value(QMediaMetaData::Title).isValid()) {
        m_title = metaData.value(QMediaMetaData::Title).toString();
    } else {
        m_title = extractFileNameTitle(m_source);
    }
    emit titleChanged();

    // 艺术家
    if (metaData.value(QMediaMetaData::AlbumArtist).isValid()) {
        m_artist = metaData.value(QMediaMetaData::AlbumArtist).toString();
    } else if (metaData.value(QMediaMetaData::ContributingArtist).isValid()) {
        m_artist = metaData.value(QMediaMetaData::ContributingArtist).toString();
    } else {
        m_artist = QStringLiteral("未知艺术家");
    }
    emit artistChanged();

    // 专辑
    if (metaData.value(QMediaMetaData::AlbumTitle).isValid()) {
        m_album = metaData.value(QMediaMetaData::AlbumTitle).toString();
    } else {
        m_album = QStringLiteral("未知专辑");
    }
    emit albumChanged();

    // 封面
    extractCoverArt();
    emit metadataLoaded();
}

void AudioMetadata::onDurationChanged(qint64 duration)
{
    m_duration = static_cast<int>(duration / 1000);
    emit durationChanged();
}

void AudioMetadata::extractCoverArt()
{
    const QMediaMetaData metaData = m_mediaPlayer->metaData();
    QVariant coverData;

    if (metaData.value(QMediaMetaData::CoverArtImage).isValid()) {
        coverData = metaData.value(QMediaMetaData::CoverArtImage);
    } else if (metaData.value(QMediaMetaData::ThumbnailImage).isValid()) {
        coverData = metaData.value(QMediaMetaData::ThumbnailImage);
    }

    if (coverData.isValid()) {
        QImage coverImage;
        if (coverData.canConvert<QImage>()) {
            coverImage = coverData.value<QImage>();
        } else if (coverData.canConvert<QPixmap>()) {
            coverImage = coverData.value<QPixmap>().toImage();
        } else if (coverData.canConvert<QByteArray>()) {
            QByteArray imageData = coverData.toByteArray();
            coverImage.loadFromData(imageData);
        }

        if (!coverImage.isNull()) {
            QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
            m_tempCoverPath = tempDir + "/music_cover_" + QString::number(QCoreApplication::applicationPid()) + ".png";
            if (coverImage.save(m_tempCoverPath, "PNG")) {
                m_coverImageUrl = QUrl::fromLocalFile(m_tempCoverPath);
                emit coverImageUrlChanged();
            }
        }
    } else {
        m_coverImageUrl = QUrl("qrc:/new/prefix1/fonts/pic/01.jpg");
        emit coverImageUrlChanged();
    }
}

QString AudioMetadata::extractFileNameTitle(const QString &filePath)
{
    QFileInfo fileInfo(filePath);
    QString baseName = fileInfo.baseName();
    if (baseName.contains(" - ")) {
        QStringList parts = baseName.split(" - ");
        if (parts.size() >= 2) return parts.last().trimmed();
    }
    return baseName;
}

// ---------------------- MusicLibrary ----------------------
MusicLibrary::MusicLibrary(QObject *parent)
    : QObject(parent)
{}

QStringList MusicLibrary::scanMusicFiles(const QString &rootPath, bool recursive)
{
    QStringList results;
    if (rootPath.isEmpty()) return results;

    QStringList extensions = {"*.mp3", "*.m4a", "*.flac", "*.wav", "*.ogg", "*.aac"};

    if (recursive) {
        QDirIterator it(rootPath, extensions, QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            const QString filePath = it.next();
            results << QFileInfo(filePath).absoluteFilePath();
        }
    } else {
        QDir dir(rootPath);
        QFileInfoList files = dir.entryInfoList(extensions, QDir::Files);
        for (const QFileInfo &fi : files) {
            results << fi.absoluteFilePath();
        }
    }

    return results;
}

QString MusicLibrary::defaultProjectRoot()
{
    return findProjectRootFromAppDir();
}

QStringList MusicLibrary::scanDefaultProjectMusic(bool recursive)
{
    return scanMusicFiles(defaultProjectRoot(), recursive);
}

QString MusicLibrary::findProjectRootFromAppDir() const
{
    QString dirPath = QCoreApplication::applicationDirPath();
    QDir dir(dirPath);
    for (int i = 0; i < 6; ++i) {
        if (dir.exists("src.qrc") || dir.exists("components")) {
            return dir.absolutePath();
        }
        if (!dir.cdUp()) break;
    }
    return QCoreApplication::applicationDirPath();
}