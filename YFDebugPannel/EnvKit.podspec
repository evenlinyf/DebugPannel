Pod::Spec.new do |s|
  s.name             = "EnvKit"
  s.version          = "0.1.0"
  s.summary          = "EnvKit DebugPannel builder component."
  s.description      = <<-DESC
  EnvKit provides environment configuration models and builders that help
  external callers assemble a DebugPannel page.
  DESC
  s.homepage         = "https://example.com/envkit"
  s.license          = { :type => "MIT" }
  s.author           = { "Codex" => "codex@example.com" }
  s.source           = { :path => "." }

  s.ios.deployment_target = "12.0"
  s.module_name = "EnvKit"

  s.source_files = [
    "EnvKit/**/*.{h,m}",
    "YFDebugPannel/DebugPanel/**/*.{h,m}",
    "YFDebugPannel/Utilities/**/*.{h,m}"
  ]

  s.public_header_files = [
    "EnvKit/EnvKit.h",
    "YFDebugPannel/DebugPanel/Builders/HCEnvBuilder.h",
    "YFDebugPannel/DebugPanel/Builders/HCEnvPanelBuilder.h",
    "YFDebugPannel/DebugPanel/Models/HCCellItem.h",
    "YFDebugPannel/DebugPanel/Models/HCEnvKit.h",
    "YFDebugPannel/DebugPanel/Models/HCEnvSection.h"
  ]
end
