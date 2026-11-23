#pragma once

#include "GridLayout.h"

#include <QPointF>
#include <QRectF>
#include <QSize>
#include <QString>
#include <QStringList>
#include <QtCore/qnamespace.h>

#include <cstddef>
#include <cstdint>
#include <optional>
#include <vector>

namespace gs::app {

class GridCells
{
public:
    struct Sync {
        QString role;
        int tone = -1;
        int followers = 0;
        QString leader;

        friend bool operator==(const Sync&, const Sync&) = default;
    };

    struct Cell {
        QString serial;
        QString name;
        QString remark;
        QString tone;
        QString status;
        double aspect = 0;
        double rate = -1;
        Sync sync;
        bool separate = false;
        bool checked = true;
        QRectF area;
        QRectF footer;
        QRectF view;
    };

    struct Metrics {
        double footer = 32;
        double gap = 8;
        double margin = 8;
        double inset = 2;
    };

    enum class Action : std::uint8_t { Outside, None, Forward, Toggle, Chrome, OwnWindow, BackToGrid };

    struct Press {
        Action action = Action::Outside;
        QString serial;
    };

    bool add(const QString& serial, const QString& name, double aspect, bool separate);
    bool remove(const QString& serial);
    [[nodiscard]] const std::vector<Cell>& cells() const noexcept { return m_cells; }
    [[nodiscard]] const Cell* find(const QString& serial) const;
    [[nodiscard]] QStringList serials() const;
    bool reorder(const QStringList& order);
    bool setAspect(const QString& serial, double aspect);
    bool setLabel(const QString& serial, const QString& name, const QString& tone, const QString& status);
    bool setRemark(const QString& serial, const QString& remark);
    bool setRate(const QString& serial, double framesPerSecond);
    bool setSync(const QString& serial, const Sync& sync);
    bool setChecked(const QString& serial, bool checked);
    bool setSeparate(const QString& serial, bool separate);
    [[nodiscard]] const QString& target() const noexcept { return m_target; }
    bool setTarget(const QString& serial);
    [[nodiscard]] GridShape shape() const noexcept { return m_shape; }
    [[nodiscard]] std::size_t knownAspects() const;
    void layout(const QRectF& area, const Metrics& metrics);
    [[nodiscard]] QSize windowSize(QSize workArea, double top, const Metrics& metrics, double heightShare) const;
    void setDoubleClick(std::int64_t intervalMs, double distance);
    [[nodiscard]] Press press(QPointF at, Qt::MouseButton button, std::int64_t timeMs);

private:
    struct LastPress {
        QString serial;
        QPointF at;
        std::int64_t timeMs = 0;
        bool view = false;
    };

    [[nodiscard]] Cell* cellOf(const QString& serial);
    [[nodiscard]] std::vector<GridItem> items(const Metrics& metrics) const;
    [[nodiscard]] bool repeats(const QString& serial, QPointF at, Qt::MouseButton button, std::int64_t timeMs) const;
    void remember(const Cell& cell, QPointF at, Qt::MouseButton button, std::int64_t timeMs, bool view);

    std::vector<Cell> m_cells;
    QString m_target;
    GridShape m_shape;
    std::int64_t m_doubleClickMs = 400;
    double m_doubleClickDistance = 5;
    std::optional<LastPress> m_last;
};

struct GridHints {
    QString serial;
    bool keyHints = false;
    bool wheel = false;

    friend bool operator==(const GridHints&, const GridHints&) = default;
};

[[nodiscard]] GridHints gridHints(const GridCells& cells, bool keymap, bool textInput, bool foreground,
                                  const QString& wheelSerial);

}
