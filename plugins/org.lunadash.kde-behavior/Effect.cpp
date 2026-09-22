#include "core/plugins/PluginApi.h"

#include <QHash>
#include <QJsonDocument>
#include <QJsonObject>
#include <QString>

namespace LunaDash {
namespace {
QHash<QString, int> rememberedWorkspace;

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

  const auto output = QJsonDocument(
      QJsonObject{{"workspace", workspace}, {"maximized", maximized}})
                          .toJson(QJsonDocument::Compact);
  return ludash_plugin_write_json(output.constData(), response, capacity);
}

int processWindowAnimation(const QJsonObject &input, char *response,
                           size_t capacity) {
  const auto settings = input.value("settings").toObject();
  QJsonObject output{
      {"duration", settings.value("duration").toInt(220)},
      {"enterOffset", settings.value("enterOffset").toInt(8)},
      {"focusOpacity", settings.value("focusOpacity").toDouble(0.9)},
      {"exitScale", settings.value("exitScale").toDouble(0.96)},
      {"easing", settings.value("easing").toString("outCubic")}};

  const auto json = QJsonDocument(output).toJson(QJsonDocument::Compact);
  return ludash_plugin_write_json(json.constData(), response, capacity);
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

  if (target == "window-rules")
    return processWindowRules(input, response, capacity);
  if (target == "window-animation")
    return processWindowAnimation(input, response, capacity);
  return -1;
}

} // namespace LunaDash
