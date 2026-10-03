# Software Name
PROGRAM = quake

# Platform specific
ifeq ($(platform), )
  INSTALLDIR ?= ./

  DEBUG_CFLAGS += -DDEBUG -g3
  OPT_CFLAGS += -Ofast
  EXTRA_LDFLAGS += -lm
else ifeq ($(platform), miyoo)
  LTO ?= 1
  INSTALLDIR ?= /mnt
  CHAINPREFIX  ?= /opt/miyoo
  CROSS_COMPILE ?= $(CHAINPREFIX)/usr/bin/arm-linux-

  USE_CODEC_WAVE = 1
  USE_CODEC_FLAC = 0
  USE_CODEC_MP3 = 1
  USE_CODEC_VORBIS = 0
  USE_CODEC_OPUS = 0
  USE_CODEC_UMX = 0
  USE_CODEC_MIKMOD = 1
  USE_CODEC_MODPLUG = 0

  CFLAGS += -DDINGUX -DELF
  DEBUG_CFLAGS += -g0
  OPT_CFLAGS += -Ofast -fdata-sections -ffunction-sections -fsingle-precision-constant \
					-fno-PIC
  EXTRA_LDFLAGS += -no-pie -s -Wl,--as-needed -Wl,--gc-sections
endif

ifeq ($(LTO),1)
	OPT_CFLAGS += -flto
	EXTRA_LDFLAGS += -flto
endif

# Compiler
CC := $(CROSS_COMPILE)gcc
CXX := $(CROSS_COMPILE)g++
STRIP := $(CROSS_COMPILE)strip
SYSROOT ?= $(shell $(CC) --print-sysroot)

# Using SDL as video/audio backend
PKGS = sdl

TYR_RELEASE := v0.62-pre
TYR_GIT := $(shell git describe --dirty 2> /dev/null)
TYR_VERSION := $(if $(TYR_GIT),$(TYR_GIT),$(TYR_RELEASE))
TYR_VERSION_NUM ?= $(patsubst v%,%,$(TYR_VERSION))

USE_CODEC_WAVE ?= 1
USE_CODEC_FLAC ?= 1
USE_CODEC_MP3 ?= 1
USE_CODEC_VORBIS ?= 1
USE_CODEC_OPUS ?= 1
USE_CODEC_UMX ?= 1
# either mikmod (preferred) or modplug, not both
USE_CODEC_MIKMOD ?= 1
USE_CODEC_MODPLUG ?= 0

ifeq ($(USE_CODEC_MIKMOD),1)
ifeq ($(USE_CODEC_MODPLUG),1)
$(error Invalid MOD codec setup, use single backend)
endif
endif

# which library to use for mp3 decoding: mad or mpg123
MP3LIB ?= mpg123
# which library to use for ogg decoding: vorbis or tremor
VORBISLIB ?= vorbis

ifneq ($(VORBISLIB),vorbis)
ifneq ($(VORBISLIB),tremor)
$(error Invalid VORBISLIB setting)
endif
endif
ifneq ($(MP3LIB),mpg123)
ifneq ($(MP3LIB),mad)
$(error Invalid MP3LIB setting)
endif
endif
ifeq ($(MP3LIB),mad)
lib_mp3dec=mad
endif
ifeq ($(MP3LIB),mpg123)
lib_mp3dec=libmpg123
endif
ifeq ($(VORBISLIB),vorbis)
cpp_vorbisdec=
lib_vorbisdec=vorbisfile vorbis ogg
endif
ifeq ($(VORBISLIB),tremor)
cpp_vorbisdec=-DVORBIS_USE_TREMOR
lib_vorbisdec=vorbisidec ogg
endif

CODECLIBS :=
ifeq ($(USE_CODEC_WAVE),1)
CFLAGS += -DUSE_CODEC_WAVE
endif
ifeq ($(USE_CODEC_FLAC),1)
CFLAGS += -DUSE_CODEC_FLAC
CODEC_PKGS += flac
endif
ifeq ($(USE_CODEC_OPUS),1)
CFLAGS += -DUSE_CODEC_OPUS
CODEC_PKGS += opusfile
endif
ifeq ($(USE_CODEC_VORBIS),1)
CFLAGS += -DUSE_CODEC_VORBIS $(cpp_vorbisdec)
CODEC_PKGS += $(lib_vorbisdec)
endif
ifeq ($(USE_CODEC_MP3),1)
CFLAGS += -DUSE_CODEC_MP3
CODEC_PKGS += $(lib_mp3dec)
endif
ifeq ($(USE_CODEC_MIKMOD),1)
CFLAGS += -DUSE_CODEC_MIKMOD
CODEC_PKGS += libmikmod
endif
ifeq ($(USE_CODEC_MODPLUG),1)
CFLAGS += -DUSE_CODEC_MODPLUG
CODEC_PKGS += libmodplug
endif
ifeq ($(USE_CODEC_UMX),1)
CFLAGS += -DUSE_CODEC_UMX
endif

PKGS_CFLAGS	:= $(shell $(SYSROOT)/../../usr/bin/pkg-config --cflags $(PKGS) $(CODEC_PKGS))
PKGS_LIBS	:= $(shell $(SYSROOT)/../../usr/bin/pkg-config --libs $(PKGS) $(CODEC_PKGS))

# Linker
LDFLAGS = $(PKGS_LIBS) $(EXTRA_LDFLAGS)
CFLAGS += $(OPT_CFLAGS) -fno-common -Wall $(PKGS_CFLAGS) \
			$(DEBUG_CFLAGS) -DNQ_HACK -DTYR_VERSION=$(TYR_VERSION_NUM) -DQBASEDIR="."

# Include
INCLUDES := 

NET_FOLDER = 

CFLAGS +=  -Isource
CFILES = 			source/host.c \
					source/menu.c \
					source/screen.c \
					source/net_loop.c \
					source/net_main.c \
					source/net_common.c \
					source/net_none.c \
					source/net_dgrm.c

ifeq ($(platform), )
CFILES	+=			source/vid_sdl.c
else ifeq ($(platform),miyoo)
CFILES	+=			source/vid_sdl_rs97.c
endif

CFILES +=			source/bgmusic.c \
					source/snd_codec.c					
ifeq ($(USE_CODEC_FLAC),1)
CFILES  +=			source/snd_flac.c
endif
ifeq ($(USE_CODEC_OPUS),1)
CFILES  +=			source/snd_opus.c
endif
ifeq ($(USE_CODEC_MIKMOD),1)
CFILES  +=			source/snd_mikmod.c
endif
ifeq ($(USE_CODEC_UMX),1)
CFILES  +=			source/snd_umx.c
endif
ifeq ($(USE_CODEC_MODPLUG),1)
CFILES  +=			source/snd_modplug.c
endif
ifeq ($(USE_CODEC_WAVE),1)
CFILES  +=			source/snd_wave.c
endif
ifeq ($(USE_CODEC_MP3),1)
ifeq ($(MP3LIB),mpg123)
CFILES  +=			source/snd_mpg123.c
else ifeq ($(MP3LIB),mad)
CFILES  +=			source/snd_mp3.c
endif
endif
ifeq ($(USE_CODEC_VORBIS),1)
CFILES  +=			source/snd_vorbis.c
endif

CFILES	+=			source/sv_main.c \
					source/pr_exec.c \
					source/sdl_common.c \
					source/vid_mode.c \
					source/rb_tree.c \
					source/cd_common.c \
					source/alias_model.c \
					source/r_model.c \
					source/pr_cmds.c \
					source/pr_edict.c \
					source/cd_null.c \
					source/shell.c \
					source/r_sprite.c \
					source/sprite_model.c \
					source/snd_sdl.c \
					source/sys_unix.c \
					source/chase.c \
					source/cl_demo.c \
					source/cl_input.c \
					source/cl_main.c \
					source/cl_parse.c \
					source/cl_tent.c \
					source/cmd.c \
					source/common.c \
					source/console.c \
					source/crc.c \
					source/cvar.c \
					source/d_edge.c \
					source/d_fill.c \
					source/d_init.c \
					source/d_modech.c \
					source/d_part.c \
					source/d_polyse.c \
					source/d_scan.c \
					source/d_sky.c \
					source/d_sprite.c \
					source/d_surf.c \
					source/d_vars.c \
					source/draw.c \
					source/host_cmd.c \
					source/keys.c \
					source/mathlib.c \
					source/model.c \
					source/nonintel.c \
					source/r_aclip.c \
					source/r_alias.c \
					source/r_bsp.c \
					source/r_draw.c \
					source/r_edge.c \
					source/r_efrag.c \
					source/r_light.c \
					source/r_main.c \
					source/r_misc.c \
					source/r_part.c \
					source/r_sky.c \
					source/r_surf.c \
					source/r_vars.c \
					source/sbar.c \
					source/snd_dma.c \
					source/snd_mix.c \
					source/sv_move.c \
					source/sv_phys.c \
					source/sv_user.c \
					source/snd_mem.c \
					source/view.c \
					source/wad.c \
					source/world.c \
					source/zone.c 

#
#========================================(Compile)
#

OFILES = $(SFILES:.S=.o) $(CFILES:.c=.o)

$(PROGRAM):	$(OFILES)
			$(CC) $(CFLAGS) $(OFILES) -o $@ $(LDFLAGS)

all: $(PROGRAM)

%.o: %.c
	 $(CC) $(ALL_INCLUDES) $(CFLAGS) -c $< -o $@

clean:
	 -rm -f $(OFILES) $(MAPFILE) $(PROGRAM)
