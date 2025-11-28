#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$ROOT_DIR/src"
LIB_DIR="$ROOT_DIR/lib"
BUILD_DIR="$ROOT_DIR/build/classes"
JAR_OUT_DIR="$ROOT_DIR/DingNetExe"
JAR_PATH="$JAR_OUT_DIR/DingNet.jar"

echo "[build] Cleaning and preparing directories"
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR" "$JAR_OUT_DIR"

CP="$LIB_DIR/*"

echo "[build] Compiling sources"
(
  cd "$SRC_DIR"
  find . \
    -path './GUI' -prune -o \
    -path './javadoc' -prune -o \
    -path './test' -prune -o \
    -path './IotDomain/Simulation.java' -prune -o \
    -path './IotDomain/InputProfile.java' -prune -o \
    -path './Simulation/ScatteredSimulation.java' -prune -o \
    -name "*.java" -print0 \
    | xargs -0 javac -source 1.8 -target 1.8 -Xlint:deprecation -cp "$CP" -processorpath "$LIB_DIR/lombok.jar" -d "$BUILD_DIR"
)

echo "[build] Creating manifest with Main-Class and Class-Path"
MANIFEST_FILE="$ROOT_DIR/MANIFEST.MF"
{
  echo "Manifest-Version: 1.0"
  echo "Main-Class: HTTPServer"
  echo -n "Class-Path: "
  first=1
  for j in "$LIB_DIR"/*.jar; do
    if [[ $first -eq 1 ]]; then
      printf "lib/%s" "$(basename "$j")"
      first=0
    else
      printf " lib/%s" "$(basename "$j")"
    fi
  done
  echo
} > "$MANIFEST_FILE"

echo "[build] Packaging JAR -> $JAR_PATH"
jar cfm "$JAR_PATH" "$MANIFEST_FILE" -C "$BUILD_DIR" .

echo "[build] Done. JAR at $JAR_PATH"