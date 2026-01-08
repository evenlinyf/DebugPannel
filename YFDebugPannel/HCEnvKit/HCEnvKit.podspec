Pod::Spec.new do |s|
  s.name             = "HCEnvKit"
  s.version          = "0.1.0"
  s.summary          = "HCEnvKit DebugPannel builder component."
  s.description      = <<-DESC
  HCEnvKit provides environment configuration models and builders that help
  external callers assemble a DebugPannel page.
  DESC
  s.homepage         = "https://example.com/envkit"
  s.license          = { :type => "MIT" }
  s.author           = { "Codex" => "codex@example.com" }
  s.source           = { :path => "." }

  s.ios.deployment_target = "12.0"
  s.module_name = "HCEnvKit"

  s.source_files = [
    "EnvKit/**/*.{h,m}",
    "DebugPanel/**/*.{h,m}",
    "Utilities/**/*.{h,m}"
  ]

  s.public_header_files = [
    "EnvKit/EnvKit.h",
    "DebugPanel/Builders/HCEnvBuilder.h",
    "DebugPanel/Builders/HCEnvPanelBuilder.h",
    "DebugPanel/Models/HCCellItem.h",
    "DebugPanel/Models/HCEnvKit.h",
    "DebugPanel/Models/HCEnvSection.h"
  ]
end
