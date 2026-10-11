.PHONY: all shaders link preview check perf clean

QT6_BIN := $(firstword $(wildcard /usr/lib/qt6/bin /usr/lib64/qt6/bin))
QSB ?= $(if $(QT6_BIN),$(QT6_BIN)/qsb,qsb)
QSB_FLAGS := --glsl "100 es,120,150" --hlsl 50 --msl 12
FRAGS := $(wildcard skins/*/shaders/*.frag)
SKINS_DIR ?= $(or $(XDG_DATA_HOME),$(HOME)/.local/share)/speshell/skins
SKIN ?= fire
SCENE ?= launcher
SKIN_NAMES := $(notdir $(patsubst %/,%,$(wildcard skins/*/)))
# Speshell checkout or install whose WallpaperView hosts the wallpaper scene.
SPESHELL_DIR ?= $(abspath $(firstword $(wildcard ../speshell /usr/share/speshell)))
export SPESHELL_DIR

all: shaders

shaders: $(FRAGS:.frag=.frag.qsb)

%.frag.qsb: %.frag lib/common.glsl
	$(QSB) $(QSB_FLAGS) -o $@ $<

# Symlink every skin into Speshell's skin directory for development.
link: shaders
	mkdir -p "$(SKINS_DIR)"
	for dir in skins/*/; do ln -sfn "$(CURDIR)/$$dir" "$(SKINS_DIR)/$$(basename "$$dir")"; done

# Render one skin and scene offscreen into lab/out/<skin>-<scene>.mp4 (needs a Wayland session).
preview: shaders
	lab/preview.sh "$(SKIN)" "$(SCENE)"

# Render every skin and scene; fail on QML errors, warnings, or a transition that never finishes.
check: shaders
	lab/check.sh $(SKIN_NAMES)

# Estimate one skin and scene's GPU time per frame at 1080p (needs a Wayland session).
perf: shaders
	lab/perf.sh "$(SKIN)" "$(SCENE)"

clean:
	rm -f skins/*/shaders/*.qsb
	rm -rf lab/out
