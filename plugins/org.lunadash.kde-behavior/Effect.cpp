#include "core/plugins/PluginApi.h"

#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRect>
#include <QSet>
#include <QString>
#include <algorithm>

namespace LunaDash {
namespace {
QHash<QString, int> rememberedWorkspace;
QHash<int, int> cascadeSerial;
QSet<qint64> placedWindows;

int writeObject(const QJsonObject &object, char *response, size_t capacity) {
  const auto bytes = QJsonDocument(object).toJson(QJsonDocument::Compact);
  return ludash_plugin_write_json(bytes.constData(), response, capacity);
}

int processWindowLayout(const QJsonObject &input, char *response,
                        size_t capacity) {
  const auto builtin = input.value("builtin").toObject();
  const auto context = input.value("context").toObject();
  const auto settings = input.value("settings").toObject();
  auto windows = builtin.value("windows").toArray();
  const auto freshValues = context.value("newWindows").toArray();
  const auto areaObject = context.value("area").toObject();
  const QRect area(areaObject.value("x").toInt(), areaObject.value("y").toInt(),
                   areaObject.value("width").toInt(),
                   areaObject.value("height").toInt());
  if (!area.isValid())
    return writeObject(builtin, response, capacity);

  QSet<qint64> fresh;
  for (const auto &value : freshValues)
    fresh.insert(value.toInteger());

  const QString placement = settings.value("placement").toString("cascade");
  const int offset =
      std::clamp(settings.value("cascadeOffset").toInt(28), 0, 80);
  const int workspace = context.value("workspace").toInt();

  for (int index = 0; index < windows.size(); ++index) {
    auto item = windows[index].toObject();
    const qint64 id = item.value("id").toInteger();
    if (!fresh.contains(id))
      continue;

    const int width = std::clamp(item.value("width").toInt(), 1, area.width());
    const int height =
        std::clamp(item.value("height").toInt(), 1, area.height());
    int x = area.x() + (area.width() - width) / 2;
    int y = area.y() + (area.height() - height) / 2;

    if (placement == "cascade") {
      int serial = cascadeSerial.value(workspace, 0);
      if (!placedWindows.contains(id)) {
        placedWindows.insert(id);
        cascadeSerial[workspace] = serial + 1;
      } else {
        serial = std::max(0, serial - 1);
      }
      const int slot = serial % 7;
      const int originX = area.x() + std::min(48, std::max(0, area.width() / 10));
      const int originY = area.y() + std::min(48, std::max(0, area.height() / 10));
      x = originX + slot * offset;
      y = originY + slot * offset;
      x = std::clamp(x, area.x(), area.right() - width + 1);
      y = std::clamp(y, area.y(), area.bottom() - height + 1);
    }

    item["x"] = x;
    item["y"] = y;
    item["width"] = width;
    item["height"] = height;
    windows[index] = item;
  }

  return writeObject(QJsonObject{{"windows", windows}}, response, capacity);
}

int processWindowRules(const QJsonObject &input, char *response,
                       size_t capacity) {
  const auto builtin = input.value("builtin").toObject();
  const auto context = input.value("context").toObject();
  const auto settings = input.value("settings").toObject();

  int workspace = builtin.value("workspace").toInt();
  const QString policy =
      settings.value("workspacePolicy").toString("current");
  const QString appId = context.value("appId").toString();

  if (policy == "first") {
    workspace = 0;
  } else if (policy == "remember" && !appId.isEmpty()) {
    if (rememberedWorkspace.contains(appId))
      workspace = rememberedWorkspace.value(appId);
    else
      rememberedWorkspace.insert(appId, workspace);
  }

  const bool maximized =
      settings.value("maximizeNewWindows").toBool(false)
          ? true
          : builtin.value("maximized").toBool(false);

  return writeObject(
      QJsonObject{{"workspace", workspace}, {"maximized", maximized}},
      response, capacity);
}

int processWindowAnimation(const QJsonObject &input, char *response,
                           size_t capacity) {
  const auto settings = input.value("settings").toObject();
  return writeObject(
      QJsonObject{
          {"duration", settings.value("duration").toInt(180)},
          {"enterOffset", settings.value("enterOffset").toInt(6)},
          {"focusOpacity", settings.value("focusOpacity").toDouble(0.96)},
          {"exitScale", settings.value("exitScale").toDouble(0.97)},
          {"easing", settings.value("easing").toString("outCubic")}},
      response, capacity);
}
} // namespace

extern "C" int ludash_plugin_process(const char *request, char *response,
                                     size_t capacity) {
  if (!request)
    return -1;
  const auto document = QJsonDocument::fromJson(request);
  if (!document.isObject())
    return -1;
  const auto input = document.object();
  const auto target = input.value("target").toString();

  if (target == "window-layout")
    return processWindowLayout(input, response, capacity);
  if (target == "window-rules")
    return processWindowRules(input, response, capacity);
  if (target == "window-animation")
    return processWindowAnimation(input, response, capacity);
  return -1;
}

} // namespace LunaDash
