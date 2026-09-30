This is a port of Quake for devices like the RS-97, Arcade Mini, PAP K3S... that rely on SDL 1.2.
(SDL 2.0 is too slow on those platforms)

It used to be based around sdlquake but that port had numerous crashes and issues so i rebased it around TyrQuake,
which was the only suitable base that was not Darkplaces.

TyrQuake only supported SDL2 so i had to reuse some of the sdlquake's code in there but it was mostly compatible with it.

It also runs pretty well on the said platforms, even on the PAP K3S with a screen resolution of 800x480.

## Building

The build system produces the `sdlquake` executable.

To build for the default host:
```sh
make -j$(nproc)
```

To cross-compile for specific platforms:
```sh
make -j$(nproc) platform=<target_name>
```
*(Supports `platform=miyoo` with Dingux specific video output & SDK integration).*

The Makefile uses `pkg-config` to automatically resolve shared or static library dependencies.

## Background Music (BGM) Support

Background music playback via external audio assets has been adopted from Quakespasm. External audio tracks can be played in various formats.

Codecs can be toggled in the `Makefile` using build flags:
- `USE_CODEC_WAVE`: WAV support (default: `0`)
- `USE_CODEC_MP3`: MP3 support (default: `1`, backend selectable via `MP3LIB=mpg123` or `MP3LIB=mad`)
- `USE_CODEC_VORBIS`: Ogg Vorbis support (default: `0`, backend selectable via `VORBISLIB=vorbis` or `VORBISLIB=tremor`)
- `USE_CODEC_FLAC`: FLAC support (default: `0`)
- `USE_CODEC_OPUS`: Opus support (default: `0`)
- `USE_CODEC_MIKMOD` / `USE_CODEC_MODPLUG`: Tracker music support (default: `0`)
- `USE_CODEC_UMX`: Unreal Music package support (default: `0`)
