import 'dart:ffi' show Abi;

import 'cpu_arch.dart';

CpuArch currentCpuArch() {
  switch (Abi.current()) {
    case Abi.linuxX64:
    case Abi.macosX64:
    case Abi.windowsX64:
      return CpuArch.x64;
    case Abi.linuxArm64:
    case Abi.macosArm64:
      return CpuArch.arm64;
    default:
      return CpuArch.unknown;
  }
}
